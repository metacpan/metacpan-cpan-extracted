#!/usr/bin/perl -w

#
# Fsdb::IO::Reader.pm
# $Id: 2a2f291dc6b6a5e06727ae853281470c6a663aef $
#
# Copyright (C) 2005-2015 by John Heidemann <johnh@isi.edu>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2, as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#


package Fsdb::IO::Reader;

=head1 NAME

Fsdb::IO::Reader - handle formatting reading from a fsdb file (handle) or queue

=cut

@ISA = qw(Fsdb::IO);
($VERSION) = 1.1;

use strict;
use IO::File;
use Carp;
use IO::Uncompress::AnyUncompress;

use Fsdb::IO;

=head1 SAMPLE CODE

Sample code reading an input stream:

    $in = new Fsdb::IO::Reader(-file => '-');
    $in->error and die "cannot open stdin as fsdb: " . $in->error . "\n";
    my @arow;
    while ($in->read_row_to_aref(\@arow) {
	# do something
    };
    $in->close;

=cut

=head1 METHODS

=head2 new

    $fsdb = new Fsdb::IO::Reader(-file => $filename);
    $fsdb = new Fsdb::IO::Reader(-header => "#fsdb -F t foo bar", -fh => $file_handle);

Creates a new reader object from FILENAME.
(FILENAME can also be a IO::Handle object,
or an hdfs: file.)
Always succeeds, but 
check the C<error> method to test for failure.

=head3 Options:

=over 4

=item B<other options>
See also the options in Fsdb::IO, including
C<-file>, C<-header>.

=item B<-file FILENAME>
Open and read the given filename.
Special filename "-" is standard input,
and files with hdfs: are read from Hadoop (but not with directory aggregation).

=item B<-comment_handler $ref>

Define how comments are handled.  If $REF is a Fsdb::IO::Writer
object, comments are written to that stream as they are encountered.
if $REF is a ref to a scalar, then we assume that scalar
will be filled in with a Fsdb::IO::Writer object later and treat
it the same.
If it is of type code, then it is assumed to be a callback function
of the form:

    sub comment_handler ($) { my $comment = @_; }

where the one argument will be a string with the unparsed comment
(with leading # and trailing newline).

By default, or if $ref is undef, comments are consumed.

A typical handler if you have an output Fsdb stream is:

    sub { $out->write_raw(@_); };

(That is the code created by  L<Fsdb::Filter::create_pass_comments_sub>.)

There are several support routines to handle comments in a pipeline;
see L<Fsdb::Filter::create_pass_comments_sub>,
L<Fsdb::Filter::create_tolerant_pass_comments_sub>,
L<Fsdb::Filter::create_delay_comments_sub>.

=back

User-specified -header arguments override a header provided in the input source.

=cut

sub new {
    my $class = shift @_;
    my $self = $class->SUPER::new(@_);
    bless $self, $class;
    #
    # new instance variables
    $self->{_unreadq} = [];
    # Could pass out the code so rowobj_sub propages down to fastpath.
    # Skip that for now.
    # $self->{_read_rowobj_code} = ' die; ';  # placeholders
    $self->{_read_rowobj_sub} = sub { die; };
    #
    $self->config(@_);
    #
    # setup:    
    if (! ($self->{_fh} || $self->{_queue})) {
	$self->{_error} //= "Fsdb::IO::Reader: cannot setup filehandle";
	return $self;
    };
    if ($self->{_fh} && ref($self->{_fh}) eq 'IO::Pipe') {
	# don't do this if we're IO::Pipe::End, since it's already been done
	$self->{_fh}->reader();
    };
    $self->comment_handler_to_sub;
    # Note: reader/writer difference: readers have io subs before headers; writers only after.
    $self->create_io_subs();

    if (!defined($self->{_headerrow})) {
	# get the header from the file (must not have been specified by the user)
	$self->read_headerrow;
	$self->parse_headerrow;
    };
    if (defined($self->{_headerrow})) {
	$self->{_header_set} = 1;   # go read-only
	# rebuild io subs in case the fscode changed
	$self->create_io_subs();
    } else {
	$self->{_error} = "no header line";
	return $self;
    };

    return $self;
}

=head2 config_one

documented in new

=cut
sub config_one {
    my($self, $aaref) = @_;
    if ($aaref->[0] eq '-file') {
	shift @$aaref;
	my($file) = shift @$aaref;
	my $fh;
	my $mode = $self->default_binmode();
	if ($file eq '-') {
	     $fh = new IO::Handle;
	     $fh->fdopen(fileno(STDIN),"<");
	     binmode $fh, $mode;
	} elsif ($file =~ /^hdfs:/) {
             my $hdfs_reader_pid = open($fh, '-|', "hdfs", "-cat", $file);
	     binmode $fh, $mode;
        } else {
	     $fh = new IO::File $file, "<$mode";
	};
	if ($fh) {
	    $self->{_fh} = $fh;
	} else {
	    $self->{_error} = "cannot open $file";
	};
    } elsif ($aaref->[0] eq '-comment_handler') {
	shift @$aaref;
	$self->{_comment_handler} = shift @$aaref;
	$self->comment_handler_to_sub;
    } else {
	$self->SUPER::config_one($aaref);
    };
}

=head2 comment_handler_to_sub;

internal use only: parses and sets up the comment handle callback.
(At input, _comment_sub is as given by -comment_handler,
but at exit it is always an anon function.

=cut
sub comment_handler_to_sub {
    my($self) = @_;
    if (!defined($self->{_comment_handler})) {
	# just consume comments
	$self->{_comment_sub} = sub {};
    } elsif (ref($self->{_comment_handler}) eq 'CODE') {
	# assume the user did the right thing passing in a sub
	$self->{_comment_sub} = $self->{_comment_handler};
    } elsif (ref($self->{_comment_handler}) =~ /^Fsdb::IO::Writer/) {
	# write a pass-through
	$self->{_comment_sub} = sub { $self->{_comment_handler}->write_raw(@_); }
    } elsif (ref($self->{_comment_handler}) eq 'SCALAR') {
	# write a pass-through, but with one level of indirection
	# (This trick is necessary because often the Writer
	# cannot be opened before the Reader is created.)
	$self->{_comment_sub} = sub { ${$self->{_comment_handler}}->write_raw(@_); }
    } else {
	croak "correct_comment_handler: invalid -comment_handler argument\n";
    };
}

=head2 _enable_compression

    $self->_enable_compression

internal use only: switch from uncompressed to compressed.

=cut
sub _enable_compression($) {
    my($self) = @_;
    return if (!$self->{_compression});

    my $phy_fh = $self->{_fh};
    binmode($phy_fh, ":raw");
    $self->{_fh} = new IO::Uncompress::AnyUncompress $phy_fh
	or croak "Fsdb::IO::Reader: cannot switch to compression " . $self->{_compression};
    # xxx: we now should push our encoding onto this new fh,
    # but not clear how IO::Uncompress handles that.
}


=head2 create_io_subs

    $self->create_io_subs()

internal use only: create a thunk that returns rowobjs.

=cut
sub create_io_subs() {
    my($self) = @_;
    return if ($self->{_error});
    croak "confusion: too many IO sources" if (defined($self->{_fh}) && defined($self->{_queue}));
    if (defined($self->{_fh})) {
	$self->_enable_compression() if ($self->{_compression} && $self->{_header_set});
	# need to unserialize data from a file handle
	if ($self->{_rscode} eq 'D') {
	    #
	    # Normal line-by-line (rowized) format.
	    # Carefully optimized.
	    #
	    my $fh = $self->{_fh};
	    my $fsre = $self->{_fsre};
	    $self->{_read_rowobj_sub} = sub {
		my $line = $fh->getline;
		return undef if (!defined($line));    # eof
		return $line if ($line =~ /^\s*\#/);  # comment, no longer chomped;
		chomp $line;
		# Note that, technically, the next line is meaningless
		# if we haven't yet parsed the header.
		# We assume read_headerrow will sort that out adequately.
		my @f = split(/$fsre/, $line);
		return \@f;   # a row
	    };
        } elsif ($self->{_rscode} eq 'C' || $self->{_rscode} eq 'I') {
	    #
	    # Colized-format.
	    # Not particularly optimized.
	    #
	    my $fh = $self->{_fh};
	    my $fsre = $self->{_fsre};
	    # set up buffers for partial objects
	    $self->{_rowize_eof} = undef;
	    $self->{_rowize_partial_row} =  [ ($self->{_empty}) x ($self->ncols) ];
	    $self->{_rowize_started_row} = undef;
	    $self->{_read_rowobj_sub} = sub {
		return undef if ($self->{_rowize_eof});
		# get a row
		for (;;) {
		    # get a line to build up a full row
		    my $line = $fh->getline;
		    if (!defined($line)) {
			$self->{_rowize_eof} = 1;
			last;  # exit infinite for
		    };    # eof
		    return $line if ($line =~ /^\s*\#/);  # comment is fast-path return
		    if ($line =~ /^\s*$/) {
			last if ($self->{_rowize_started_row});
			next;   # skip blank lines before content
		    };
		    # parse one field, carefully
		    my($key, $value) = ($line =~ /^([^:]+):\s+(.*)$/);
		    croak("unparsable line '$line' (format should be ''key: value''\n") if (!defined($key));
		    croak("contents of line contain column separator: <$line>, will correct\n") if ($value =~ /$fsre/);
		    $value = $self->{_empty} if (!defined($value) || $value eq '');
		    my $i = $self->{_cols_to_i}->{$key};
		    croak ("unknown column '$key' in '$line'.\n") if (!defined($i));
		    $self->{_rowize_partial_row}[$i] = $value;
		    $self->{_rowize_started_row} = 1;
		};
		# special case eof
		return undef if ($self->{_rowize_eof} && !$self->{_rowize_started_row});
		# now return the new row
		my @f = @{$self->{_rowize_partial_row}};  # copy (maybe not needed?)
		$self->{_rowize_partial_row} =  [ ($self->{_empty}) x ($self->ncols) ];  # reset
		$self->{_rowize_started_row} = undef;
		return \@f;
	    };
	} else {
	    croak "undefined rscode " . $self->{_rscode} . "\n";
	};
    } elsif (defined($self->{_queue})) {
	# data is preformatted from a queue
	my $queue = $self->{_queue};
	$self->{_read_rowobj_sub} = sub {
	    return $queue->dequeue;
	};
    } else {
	croak "confusion: no IO source\n";
    };
}


=head2 read_headerrow

internal use only; reads the header

=cut
sub read_headerrow {
    my($self) = @_;
    return if ($self->{_error});
    my $headerrow = &{$self->{_read_rowobj_sub}};
    # Note special case: if ref($headerrow) than read_rowobj_sub
    # parsed the line for us and it wasn't a comment.  Bad user!  No header!
    if (!defined($headerrow) || ref($headerrow)) {
	my $printable_hr = $headerrow;
	if (!defined($printable_hr)) {
	    $printable_hr = "[EOF]";
	} elsif (ref($printable_hr) ne 'SCALAR') {
	    $printable_hr = "$printable_hr";
	    $printable_hr =~ s/\(.*\)//;
	} else {
	    $printable_hr = substr($printable_hr, 0, 200) . " ..."
		if (length($printable_hr) > 200);
	    $printable_hr =~ s/[^[:print:]]+//g;
	};
	$self->{_error} = "no header line (saw: $printable_hr)";
	return;
    };
    # Note: internally, headers are newlineless.
    chomp $headerrow;
    $self->{_headerrow} = $headerrow;
};


# =head2 read_attributes
# 
# Read the attributes.  Called automatically to get attributes,
# if any.
# 
# =cut
# sub read_attributes {
#     my($self) = @_;
#     croak "double attribute read.\n" if ($self->{_attributes_set});
#     $self->{_attributes_set} = 1;
# 
#     my $fref;
#     while ($fref = $self->read_rowobj) {
# 	last if (!defined($fref));  # eof!
# 	last if (ref($fref));  # data (expected exit path)
# 	last if ($fref !~ /^#%\s+([^:])+:\s+(.*)$/);
# 	$self->{_attributes}{$1} = $2;
#     };
#     # put the last thing back
#     $self->unread_rowobj($fref);
#     # sigh, we now blown the fastpath :-(
# };
# 
# =head2 check_attributes
# 
# internal use only; check that attributes have been read.
# (for a writer, they always are)
# 
# =cut
# sub check_attributes {
#     return if ($self->{_attributes_set});
#     if (!defined($self->{_headerrow})) {
# 	$self->read_headerrow;
#         $self->parse_headerrow;
#     };
#     $self->read_attributes;
# }
# 



=head2 read_rowobj

    $rowobj = $fsdb->read_rowobj;

Reads a line of input and returns a "row object",
either a scalar string for a comment or header,
or an array reference for a row,
or undef on end-of-stream.
This routine is the fastest way to do full-featured fsdb-formatted IO.
(Although see also Fsdb::Reader::fastpath_sub.)

Unlike all the other routines (including fastpath_sub),
read_rowobj does not do comment processing (calling comment_sub).

=cut
sub read_rowobj {
    my($self) = @_;
    return undef if (defined($self->{_error}));

    # first, check unread
    if ($#{$self->{_unreadq}} >= 0) {
	my $frontref = shift @{$self->{_unreadq}};
	return $frontref;
    };

    return &{$self->{_read_rowobj_sub}};
}


=head2 read_row_to_aref

    $fsdb->read_row_to_aref(\@a);

Then $a[0] is the 0th column, etc.
Returns undef if the read fails, typically due to EOF.

=cut

sub read_row_to_aref {
    my($self, $aref) = @_;

    while (1) {
	my $rowobj = $self->read_rowobj;
	if (!defined($rowobj)) {
	    return undef; # eof
	} elsif (!ref($rowobj)) {
	    # comment
	    &{$self->{_comment_sub}}($rowobj);
	} else {
	    # assert(ref($rowobj) eq 'ARRAY');
	    @$aref = @$rowobj;
	    return 1;
	};
    };
}

=head2 unread_rowobj

    $fsdb->unread_rowobj($fref)

Put an fref back into the stream.

=cut

sub unread_rowobj {
    my($self, $fref) = @_;
    croak "unread_fref attempted with active fastpath\n"
	if ($self->{_fastpath_active});
    unshift @{$self->{_unreadq}}, $fref;
}

=head2 unread_row_from_aref

    $fsdb->unread_row_from_aref(\@a);

Put array @a back into the file.

=cut

sub unread_row_from_aref {
    my($self, $aref) = @_;
    croak "unread_row_from_aref attempted with active fastpath\n"
	if ($self->{_fastpath_active});
    my @a = @$aref;  # make a copy
    unshift @{$self->{_unreadq}}, \@a;
}

=head2 read_row_to_href

    $fsdb->read_row_to_href(\%h);

Read the next row into hash C<%h>.
Then $h{'colname'} is the value of that column.
Returns undef if the read fails, typically due to EOF.

=cut

sub read_row_to_href {
    my($self, $href) = @_;
    my @a;
    $self->read_row_to_aref(\@a) or return undef;
    foreach my $i (0..$#{$self->{_cols}}) {
	$href->{$self->{_cols}[$i]} = $a[$i];
    };
    return 1;
}

=head2 unread_row_from_href

    $fsdb->unread_row_from_href(\%h);

Put hash %h back into the file.

=cut

sub unread_row_from_href {
    my($self, $href) = @_;
    my @a = ('-' x $#{$self->{_cols}});  # null record
    foreach (keys %$href) {
	my($i) = $self->{_cols_to_i}->{$_};
	defined($i) or croak "column name $_ is not in current file";
	$a[$i] = $href->{$_};
    };
    $self->unread_row_from_aref(\@a);
}


=head2 fastpath_ok

    $fsdb->fastpath_ok();

Check if we can do fast-path IO
(post-header, no pending unread rows, no errors).

=cut
sub fastpath_ok {
    my($self) = @_;

    return undef if (defined($self->{_error}));
    return undef if (!defined($self->{_headerrow}));
    return undef if ($#{$self->{_unreadq}} >= 0);
    return 1;
}

=head2 fastpath_sub

    $sub = $fsdb->fastpath_sub()
    $row_aref = &$sub();

Return an anonymous sub that does read fast-path when called.
This code stub returns a new $aref
corresponding with a data line, 
and handles comments as specified by -comment_handler

=cut
sub fastpath_sub {
    my($self) = @_;

    $self->fastpath_ok or croak "not able to do read fastpath\n";
    $self->{_fastpath_active} = 1;
    # use lexical variables to emulate static to avoid object resolution
    {
	my $fh = $self->{_fh};
	my $fsre = $self->{_fsre};
	my $read_rowobj_sub = $self->{_read_rowobj_sub};
	my $comment_sub = $self->{_comment_sub};
	croak "Fsdb::IO::Reader::fastpath_sub missing comment handling subroutine.\n"
	    if (!defined($comment_sub));
	# xxx: this code should track read_row_to_aref
	my $fastpath = sub {
	    while (1) {
		my $rowobj = &$read_rowobj_sub;
		if (!defined($rowobj)) {
		    return undef; # eof
		} elsif (!ref($rowobj)) {
		    # comment
		    &$comment_sub($rowobj);
		} else {
		    # assert(ref($rowobj) eq 'ARRAY')
		    return $rowobj;
		};
            };
	};
	# for more visibility:
	# $fastpath = sub { my @a:shared; $self->read_row_to_aref(\@a); return \@a; };
	return $fastpath;
    }
}


1;
