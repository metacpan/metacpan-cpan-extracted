#!/usr/bin/perl -w

#
# Fsdb::IO::Writer.pm
# $Id: fd415a455a6624afba5caf36461747a81c2d0186 $
#
# Copyright (C) 2005-2013 by John Heidemann <johnh@isi.edu>
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


package Fsdb::IO::Writer;

=head1 NAME

Fsdb::IO::Writer - handle formatting reading from a fsdb file (handle) or queue

=cut

@ISA = qw(Fsdb::IO);
($VERSION) = 1.1;

use strict;
use IO::File;
use Carp;

# do these only when needed:
# use IO::Compress::Bzip2;
# use IO::Compress::Gzip;
# use IO::Compress::Xz;

use Fsdb::IO;


=head2 new

    $fsdb = new Fsdb::IO::Writer(-file => $filename);
    $fsdb = new Fsdb::IO::Writer(-header => "#fsdb -F t foo bar",
				    -fh => $file_handle);
    $fsdb = new Fsdb::IO::Writer(-file => '-',
				    -fscode => 'S',
				    -cols => [qw(firstcol second)]);

Creates a new writer object.
Always succeeds, but 
check the C<error> method to test for failure.

Options:

=over 4

=item other options
See also the options in Fsdb::IO, including
C<-file>, C<-header>.

=item -file FILENAME
Open and write the given filename.
Special filename "-" is standard output,
and files with hdfs: are written to Hadoop.

=item -outputheader [now|delay|never|&format_sub]

If value is "now" (the default), the header is generated after option parsing.
If "delay", it is generated on first data record output.
If "never", no header is ever output, and output will then not be fsdb format.
If it is a perl subroutine, then the C<format_sub()> is called
to generate the header on the first data record output (like delay);
it should return the string for the header.

=back

=cut

sub new {
    my $class = shift @_;
    my $self = $class->SUPER::new(@_);
    bless $self, $class;
    #
    # new instance variables
    $self->{_write_rowobj_sub} = sub { croak "Fsdb::IO::Writer: attempt to write to unprepared stream\n"; };  # placeholder
    $self->{_autoflush} = 0;
    #
    $self->config(@_);
    return $self if ($self->{_error});
    #
    # setup:    
    if (! ($self->{_fh} || $self->{_queue})) {
	$self->{_error} //= "Fsdb::IO::Writer: failed to set up output stream";
	return $self;
    };
    if ($self->{_fh} && ref($self->{_fh}) eq 'IO::Pipe') {
	# don't do this if we're IO::Pipe::End, since it's already been done
	$self->{_fh}->writer();
    };
    if ($self->{_fh} && $self->{_autoflush}) {
	$self->{_fh}->autoflush(1);
    };
    # Default to agressively generating header.
    # Call it for never (!) so we call create_io_subs.
    $self->{_outputheader} = 'now' if (!defined($self->{_outputheader}));
    $self->write_headerrow unless (ref($self->{_outputheader}) eq 'CODE' || $self->{_outputheader} eq 'delay');

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
	     $fh->fdopen(fileno(STDOUT),">");
	     binmode $fh, $mode;
        } elsif ($file =~ /^hdfs:/) {
             my $hdfs_reader_pid = open($fh, '|-', "hdfs", "-put", "-", $file);
	     binmode $fh, $mode;
	} else {
	     $fh = new IO::File $file, ">$mode";
	};
	if ($fh) {
	    $self->{_fh} = $fh;
	} else {
	    $self->{_error} = "cannot open $file";
	};
    } elsif ($aaref->[0] eq '-autoflush') {
	shift @$aaref;
	my $af = shift @$aaref;
	$af //= 0;
	$self->{_autoflush} = $af;
	croak "autoflush must be 0 or undef, or 1.\n"
	    if (!($af == 0 || $af == 1));
    } elsif ($aaref->[0] eq '-outputheader') {
	shift @$aaref;
	my $oh = shift @$aaref;
	$self->{_outputheader} = $oh;
	croak "outputheader must be now, delay, never, or a sub.\n"
	    if (!(ref($oh) eq 'CODE' || $oh eq 'now' || $oh eq 'delay' || $oh eq 'never'));
    } else {
	$self->SUPER::config_one($aaref);
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
    $phy_fh->flush;
    binmode($phy_fh, ":raw");
    my $cooked_fh = undef;
    if ($self->{_compression} eq 'gz') {
	require IO::Compress::Gzip;
	# We use "Minimal" on next line, otherwise
	# we get a timestamp in the output,
	# making output non-repeatable.
	$cooked_fh = new IO::Compress::Gzip($phy_fh, time => 0, minimal => 1);
    } elsif ($self->{_compression} eq 'xz') {
	require IO::Compress::Xz;
	$cooked_fh = new IO::Compress::Xz $phy_fh;
    } elsif ($self->{_compression} eq 'bz2') {
	require IO::Compress::Bzip2;
	$cooked_fh = new IO::Compress::Bzip2 $phy_fh;
    } else {
	croak "Fsbb::IO::Writer:_enable_compression: unknown compression type.\n";
    };
    $cooked_fh or croak "Fsdb::IO::Reader: cannot switch to compression " . $self->{_compression};
    $self->{_fh} = $cooked_fh;
    # xxx: we now should push our encoding onto this new fh,
    # but not clear how IO::Uncompress handles that.
}


=head2 create_io_subs

    $self->create_io_subs($with_compression)

internal use only: create a thunk that writes rowobjs.

=cut
sub create_io_subs() {
    my($self) = @_;
    return if ($self->{_error});

    croak "confusion: too many IO sinks" if (defined($self->{_fh}) && defined($self->{_queue}));
    if (defined($self->{_fh})) {
	$self->_enable_compression() if ($self->{_compression} && $self->{_header_set});
	if ($self->{_rscode} eq 'D') {
	    my $fh = $self->{_fh};
	    my $fs = $self->{_fs};
	    croak "confusion: undefined _fs in Fsdb::IO::Writer::create_io_subs\n" if (!defined($fs));
	    $self->{_write_rowobj_sub} = sub {
		my $rowobj = $_[0];
		if (ref($rowobj) eq 'ARRAY') {
		    $fh->print(join($fs, @$rowobj) . "\n");
		} elsif (!defined($rowobj)) {
		    die;  # for now, don't allow undef => close
		} elsif (!ref($rowobj)) {
		    # raw comment
		    $fh->print($rowobj);
		} else {
		    die; # should never happen
		};
            };
        } elsif ($self->{_rscode} eq 'C' || $self->{_rscode} eq 'I') {
	    my $fh = $self->{_fh};
	    my $ncols = $#{$self->{_cols}};
	    my $always_print = ($self->{_rscode} eq 'C');
	    my $empty = $self->{_empty};
	    $self->{_write_rowobj_sub} = sub {
		my $rowobj = $_[0];
		if (ref($rowobj) eq 'ARRAY') {
		    # assert(ref($rowobj) eq 'ARRAY');
		    foreach (0..$ncols) {
			$fh->print($self->{_cols}[$_] . ": " . $rowobj->[$_] . "\n")
			    if ($always_print || $rowobj->[$_] ne $empty);
		    };
		    $fh->print("\n");
		} elsif (!defined($rowobj)) {
		    die;  # for now, don't allow undef => close
		} elsif (!ref($rowobj)) {
		    # raw comment
		    $fh->print($rowobj);
		} else {
		    die;
		};
            };
	} else {
	    croak "undefined rscode " . $self->{_rscode} . "\n";
	};
    } elsif (defined($self->{_queue})) {
	my $queue = $self->{_queue};
	$self->{_write_rowobj_sub} = sub {
	    $queue->enqueue(@_);
	};
    } else {
	croak "confusion: no IO sink\n";
    };
}


=head2 write_headerrow

internal use only; write the header.

As a side-effect, we also instantiate the _write_io_sub.

=cut
sub write_headerrow() {
    my($self) = @_;
    croak "double header write.\n" if ($self->{_header_set});

    # Note: reader/writer difference: readers have io subs before headers; writers only after.
    # We therefore make them here and immediately call them.
    $self->create_io_subs();

    return if ($self->{_outputheader} eq 'never');
    # Note, this is the default path when outputheader eq 'delay'.
    # generate it
    if (ref($self->{_outputheader}) eq 'CODE') {
	$self->{_headerrow} = &{$self->{_outputheader}}($self);
    };
    # write that header!
    die "internal error: Fsdb::IO::Writer undefined header.\n"
	if (!defined($self->{_headerrow}));
    &{$self->{_write_rowobj_sub}}($self->{_headerrow} . "\n");

    $self->{_header_set} = 1;
    # switch modes
    $self->create_io_subs() if ($self->{_compression});
};

# =head2 write_attributes
# 
# Write the attributes.  Called by interested clients
# if they have attributes.  Because attributes are I<not> guarnteed
# to be presevered across filters, interested clients
# must explicitly write them.
# 
# =cut
# sub write_attributes {
#     my($self) = @_;
#     croak "double attribute write.\n" if ($self->{_attributes_set});
#     $self->{_attributes_set} = 1;
# 
#     foreach my $key (sort keys %{$self->{_attributes}}) {
# 	my $value = $self->{_attributes}{$key};
#         &{$self->{_write_rowobj_sub}}("#% $key: $value\n");
#     };
# };
# 
# =head2 check_attributes
# 
# internal use only; check that attributes are set.
# (for a writer, they always are)
# 
# =cut
# sub check_attributes {
# }
# 

=head2 write_rowobj

    $fsdb->write_rowobj($rowobj);

Write a "row object" to an outpu stream.
Row objects are either a scalar string,
for a comment or header,
or an array reference for a row.
This routine is the fastest way to do full-featured fsdb-formatted IO.
(Although see also Fsdb::Writer::fastpath_sub.)

=cut
sub write_rowobj {
    my ($self, $rowobj) = @_;

    return if (defined($self->{_error}));
    $self->write_headerrow unless ($self->{_header_set});
    return &{$self->{_write_rowobj_sub}}($rowobj);
}


=head2 write_row_from_aref

    $fsdb->write_row_from_aref(\@a);

Write @a.

=cut

sub write_row_from_aref {
    my($self, $aref) = @_;

    $self->write_rowobj($aref);
}


=head2 write_row

    $fsdb->write_row($a1, $a2...);

Write args out.  Less efficient than write_row_from_aref.

=cut

sub write_row {
    my($self) = shift @_;

    $self->write_row_from_aref(\@_);
}

=head2 write_row_from_href

    $fsdb->write_row_from_href(\%h);

Write out %h, a hash of the row fields where each key is a field name.

=cut

sub write_row_from_href {
    my($self, $href) = @_;

    my @a;
    foreach (@{$self->{_cols}}) {
	my $v = $href->{$_};
	push(@a, defined($v) ? $v : $self->{_empty});
    };
    $self->write_row_from_aref(\@a);
}

=head2 fastpath_ok

    $fsdb->fastpath_ok();

Check if we can do fast-path IO
(header written, no errors).

=cut
sub fastpath_ok {
    my($self) = @_;

    $self->write_headerrow unless ($self->{_header_set});
    return undef if (defined($self->{_error}));
    return 1;
}

=head2 fastpath_sub

    $fsdb->fastpath_sub()

Return an anonymous sub that does fast-path rowobj writes when called.

=cut
sub fastpath_sub {
    my($self) = @_;

    $self->fastpath_ok or croak "not able to do write fastpath\n";
    $self->{_fastpath_active} = 1;
    # for writing, just the same as rowobj
    return $self->{_write_rowobj_sub};
}

=head2 close

    $fsdb->close;

Close the file and kill the saved writer sub.

=cut

sub close() {
    my($self) = @_;
    $self->{_write_rowobj_sub} = sub { die; };
    $self->SUPER::close(@_);
}



=head2 write_comment

    $fsdb->write_comment($c);

Write out $c as a comment.
($c should be just the text, without a "# " header or a newline trailer.

=cut

sub write_comment {
    my($self, $c) = @_;
    &{$self->{_write_rowobj_sub}}("# " . $c . "\n");
}

=head2 write_raw

    $fsdb->write_raw($c);

Write out $c as raw output,
typically because it's a comment that already has a "#" in front
and a newline at the rear.

=cut

sub write_raw {
    my($self, $c) = @_;
    &{$self->{_write_rowobj_sub}}($c);
}


#
# hack
#

=head2 format_fsdb_fields

    format_fsdb_fields(\%data, \@fields)

Returns a string representing double-space-separated, formatted version of
the hash'ed fields stored in %data, listed in @fields.
(This routine is a hack, there needs to be a FsdbWriter to do this properly,
but there isn't currently.

=cut

sub format_fsdb_fields {
    my($data_href, $fields_aref) = @_;
    my $out = '';
    foreach (@$fields_aref) {
	my $val = defined($data_href->{$_}) ? $data_href->{$_} : '-';
	$val =~ s/\n/\\n/g;   # fix newlines
	$val =~ s/  +/ /g;   # fix double spaces
	$out .= $val . "  ";
    };
    $out =~ s/  $//;   # trim trailing spaces
    return $out;
}


1;
