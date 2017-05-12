#!/usr/bin/perl -w

#
# Fsdb::IO.pm
# $Id: dac8ca3b6f469025184776b4fd18db3ba3c9b4a0 $
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

package Fsdb::IO;

=head1 NAME

Fsdb::IO - base class for Fsdb IO (FsdbReader and FsdbWriter)


=head1 EXAMPLES

There are several ways to do IO.  We look at several that compute 
the product of x and y for this input:

    #fsdb x y product
    1 10 -
    2 20 -

The following routes go from most easy-to-use to least,
and also from least efficient to most.
For IO-intensive work, if fastpath takes 1 unit of time,
then using hashes or arrays takes approximately 2 units of time,
all due to CPU overhead.

=head2 Using A Hash

    use Fsdb::IO::Reader;
    use Fsdb::IO::Writer;

    # preamble
    my $out;
    my $in = new Fsdb::IO::Reader(-file => '-', -comment_handler => \$out)
	or die "cannot open stdin as fsdb\n";
    $out = new Fsdb::IO::Writer(-file => '-', -clone => $in)
	or die "cannot open stdin as fsdb\n";

    # core starts here
    my %hrow;
    while ($in->read_row_to_href(\%hrow)) {
        $hrow{product} = $hrow{x} * $hrow{y};
        $out->write_row_from_href(\%hrow);    
    };

It can be convenient to use a hash because one can easily extract
fields using hash keys, but hashes can be slow.


=head2 Arrays Instead of Hashes

We can add a bit to end of the preamble:

    my $x_i = $in->col_to_i('x') // die "no x column.\n";
    my $y_i = $in->col_to_i('y') // die "no y column.\n";
    my $product_i = $in->col_to_i('product') // die "no product column.\n";

And then replace the core with arrays:

    my @arow;
    while ($in->read_row_to_aref(\@arow)) {
        $arow[$product_i] = $arow[$x_i] * $arow[$y_i];
	$out->write_row_from_aref(\@arow);    
    };

This code has two advantages over hrefs:
First, there is explicit error checking for presence of
the expected fields.
Second, arrays are likely a bit faster than hashes.


=head2 Objects Instead of Arrays

Keeping the same preamble as for arrays, 
we can directly get internal Fsdb "row objects"
with a new core:

    # core
    my $rowobj;
    while ($rowobj = $in->read_rowobj) {
        if (!ref($rowobj)) {
	    # comment
	    &{$in->{_comment_sub}}($rowobj);
	    next;
        };
        $rowobj->[$product_i] = $rowobj->[$x_i] * $rowobj->[$y_i];
        $out->write_rowobj($rowobj);    
    };

This code is a bit faster because we just return the internal
representation (a rowobj),
rather than copy into an array.

However, unfortunately it doesn't handle comment processing.


=head2 Fastpathing

To go really fast, we can build a custom thunk
(a chunk of code) that does exactly what we want.
This approach is called a "fastpath".

It requires a bit more in the preamble (building on the array version):

    my $in_fastpath_sub = $in->fastpath_sub();
    my $out_fastpath_sub = $out->fastpath_sub();

And it allows a shorter core (modeled on rowobjs),
since the fastpath includes comment processing:

    my $rowobj;
    while ($rowobj = &$in_fastpath_sub) {
	$rowobj->[$product_i] = $rowobj->[$x_i] * $rowobj->[$y_i];
	&$out_fastpath_sub($rowobj);
    };

This code is the fastest way to implement this block
without evaling code.


=head1 FUNCTIONS

=cut

@ISA = ();
$VERSION = 2.0;

use strict;
use IO::File;
use Carp;

=head2 new

    $fsdb = new Fsdb::IO;

Creates a new IO object.  Usually you should not create a FsdbIO object
directly, but instead create a C<FsdbReader> or C<FsdbWriter>.

Options:

=over 4

=item -fh FILE_HANDLE
Write IO to the given file handle.

=item -header HEADER_LINE
Force the header to the given HEADER_LINE
(should be verbatim, including #h or whatever).
=back

=item -fscode CODE
Define just the column (or field) separator fscode part of the header.
See L<dbfilealter> for a list of valid field separators.

=item -rscode CODE
Define just the row separator part of the header.
See L<dbfilealter> for a list of valid row separators.

=item -cols CODE
Define just the columns of the header.

=item -compression CODE
Define the compression mode for the file 
that will take effect after the header.

=item -clone $fsdb
Copy the stream's configuration from $FSDB, another Fsdb::IO object.

=back

=cut

sub new {
    my $class = shift @_;
    my $self = bless {
	# i/o source: one of:
	_fh => undef,	# filehandle to file
	_encoding => undef, # encoding (defaults to :utf8)
	_compression => undef,
	_queue => undef,# ref to queue

	_headerrow => undef,
	_header_set => undef,
	_header_prequel => undef,
# 	_attributes => {},   # arbitrary attributes for the file
# 	_attributes_set => undef,

	# field (i.e., column) separator
	_fscode => 'D',   # -C option code, (D=default)
        _fs => ' ',   # field separator
        _fsre => '\s+',   # field separator

	# row separators
	_rscode => 'D',  # -R (D=default, can be omitted; or R=rowized)

	_empty => '-',

	_cols => [],    # array of names of the columns (fields)
	_cols_to_i => {},  # reverse hash mapping names to offsets

	_fastpath_active => undef,   # track fastpathing to avoid breaking it

	_codifier_sub => undef,   # converting perl code with embedded column names

	_error => undef,  # error status (should NEVER end in a newline)
    }, $class;
    return $self;
}

=head2 _reset_cols

    $fsdb->_reset_cols

Internal: zero all the mappings in the curren schema.
=cut

sub _reset_cols {
    my($self) = @_;
    croak "Fsdb::IO::_reset_cols: attempted after _header_set\n"
	if ($self->{_header_set});
    $self->{_cols} = [];
    $self->{_cols_to_i} = {};
    $self->{_headerrow} = undef;
    $self->{_debug} = undef;
}

=head2 config_one

    $fsdb->config_one($arglist_aref);

Parse the first configuration option on the list, removing it.

Options are listed in new.

=cut

sub config_one {
    my($self, $aaref) = @_;
    if ($aaref->[0] eq '-fh') {
	shift @$aaref;
	$self->{_fh} = shift @$aaref;
	# should probably check ref to confirm IO::Handle
    } elsif ($aaref->[0] eq '-queue') {
	shift @$aaref;
	$self->{_queue} = shift @$aaref;
	croak "bad -queue argument" if (ref($self->{_queue}) !~ /^Fsdb::BoundedQueue/);
    } elsif ($aaref->[0] eq '-header') {
	shift @$aaref;
	$self->{_headerrow} = shift @$aaref;
	$self->parse_headerrow;   # fill in col mappings, etc.
    } elsif ($aaref->[0] eq '-fscode' || $aaref->[0] eq '-F') {
	shift @$aaref;
	my $code = shift @$aaref;
	$self->parse_fscode($code);
	$self->update_headerrow;
    } elsif ($aaref->[0] eq '-rscode' || $aaref->[0] eq '-C') {
	shift @$aaref;
	my $code = shift @$aaref;
	$self->parse_rscode($code);
	$self->update_headerrow;
    } elsif ($aaref->[0] eq '-cols') {
	shift @$aaref;
	my $col_ref = $aaref->[0];  shift @$aaref;
	$self->_reset_cols;
	foreach (@$col_ref) {
	    $self->_internal_col_create($_);
	};
	$self->update_headerrow;
    } elsif ($aaref->[0] eq '-clone') {
	shift @$aaref;
	my($clone) = shift @$aaref;
	$self->_reset_cols;
	$self->parse_fscode($clone->fscode());
	$self->parse_rscode($clone->rscode());
	foreach (@{$clone->cols()}) {
	    $self->_internal_col_create($_);
	};
	$self->{_encoding} = $clone->{_encoding};
	$self->{_compression} = $clone->{_compression};
	$self->update_headerrow;
    } elsif ($aaref->[0] eq '-encoding') {
	shift @$aaref;
	$self->{_encoding} = shift @$aaref;
    } elsif ($aaref->[0] eq '-compression') {
	shift @$aaref;
	$self->{_compression} = shift @$aaref;
	$self->{_compression} = undef if ($self->{_compression} && $self->{_compression} eq 'none');
	my(%valid_compressions) = qw(bz2 1 gz 1 xz 1);
	$self->{_error} = "bad compression mode: " . $self->{_compression}
	    if ($self->{_compression} && !defined($valid_compressions{$self->{_compression}}));
	$self->update_headerrow;
    } elsif ($aaref->[0] eq '-debug') {
	shift @$aaref;
	$self->{_debug} = shift @$aaref;
    } else {
	croak("unknown option: " . $aaref->[0]);
    };
}

=head2 config

    $fsdb->config(-arg1 => $value1, -arg2 => $value2);

Parse all options in the list.

=cut

sub config ($@) {
    my($self) = shift @_;
    my(@args) = @_;
    while ($#args >= 0) {
	$self->config_one(\@args);
    };
}

=head2 default_binmode

    $fsdb->default_binmode();

Set the file to the correct binmode,
either given by C<-encoding> at setup,
or defaulting from C<LC_CTYPE> or C<LANG>.

If the file is compressed, we will reset binmode after reading the header.

=cut

sub default_binmode($) {
    my($self) = shift @_;
    if (!defined($self->{_encoding})) {
#	foreach ($ENV{LC_CTYPE}, $ENV{LANG}, 'en.:utf8') {
	# as of perl v5.16.3, UTF-8 segfaults
	foreach ('en.:utf8') {
	    next if (!defined($_));
	    my($locale, $charset) = ($_ =~ /^([^\.]+)\.([^\.]+)/);
	    next if (!defined($charset));
	    $self->{_encoding} = $charset;
	    last;
	};
    };
    my $mode = $self->{_encoding};
    $mode = ":encoding($mode)" if ($mode !~ /^:/);
    return $mode;
}

=head2 compare

    $result = $fsdb->compare($other_fsdb)

Compares two Fsdb::IO objects, returning the strings
"identical" (same field separator, columns, and column order),
or maybe "compatible" (same field separator but different columns), or
undef if they differ.

=cut

sub compare ($$) {
    my($self, $other) = @_;
    return undef if ($self->{_error} || $other->{_error});
    return undef if ($self->{_fscode} ne $other->{_fscode});
    my @self_cols = @{$self->{_cols}};
    my @other_cols = @{$other->{_cols}};
    return "compatible" if ($#self_cols != $#other_cols);
    foreach (0..$#self_cols) {
	return "compatible" if ($self_cols[$_] ne $other_cols[$_]);
    };
    return 'identical';
}

=head2 close

    $fsdb->close;

Closes the file, frees open file handle, or sends an EOF signal
(and undef) down the open queue.

=cut

sub close {
    my($self) = @_;
    return if ($self->{_error});
    if (defined($self->{_fh})) {
        $self->{_fh}->close;
	delete $self->{_fh};   # help garbage collect auto-generated Symbols from IO::Handle
    };
    if (defined($self->{_queue})) {
	$self->{_queue}->enqueue(undef);
	delete $self->{_queue};
    };
    $self->{_error} = 'closed';
}

=head2 error

    $fsdb->error;

Returns a descriptive string if there is an error,
or undef if not.

The string will never end in a newline or punctuation.

=cut

sub error {
    my($self) = @_;
    return $self->{_error};
}

=head2 update_v1_headerrow

internal: create the header the internal schema

=cut
sub update_v1_headerrow {
    my $self = shift @_;
    my $h = "#h ";
    $h = "#L " if ($self->{_rscode} ne 'D');
    if ($self->{_fscode} && $self->{_fscode} ne 'D') {
	$h .= "-F" . $self->{_fscode} . " ";
    };
    if ($self->{_rscode} && $self->{_rscode} eq 'I') {  # xxx: should be ne 'D'
	$h .= "-R" . $self->{_rscode} . " ";
    };
    $h .= join(" ", @{$self->{_cols}});
    $self->{_headerrow} = $h;
}


=head2 parse_v1_headerrow

internal: interpet the header

=cut
sub parse_v1_headerrow ($) {
    my($self) = @_;
    return if ($self->{_error});
    my(@f) = split(/\s+/, $self->{_headerrow});
    my $tag = shift @f;
    if ($tag eq '#L') {
	$self->{_rscode} = 'C';
    } elsif ($tag ne "#h") {
        $self->{_error} = "header line is not fsdb format";
	return;
   };
   #
   # handle options
   #
   while ($#f >= 0 && $f[0] =~ /^-(.)(.*)/) {
       my($key, $value) = ($1, $2);
       shift @f;
       if ($key eq 'F') {
	   $self->parse_v1_fscode($value);
        }
    };

    # create them!
    foreach (@f) {
	$self->_internal_col_create($_);
    };
}

=head2 update_headerrow

internal: create the header the internal schema

=cut
sub update_headerrow {
    my $self = shift @_;
    my $h = "#fsdb ";
    if ($self->{_fscode} && $self->{_fscode} ne 'D') {
	$h .= "-F " . $self->{_fscode} . " ";
    };
    if ($self->{_rscode} && $self->{_rscode} ne 'D') {  # xxx: should be ne 'D'
	$h .= "-R " . $self->{_rscode} . " ";
    };
    if ($self->{_compression} && $self->{_compression} ne 'none') {  # xxx: should be ne 'D'
	$h .= "-Z " . $self->{_compression} . " ";
    };
    $self->{_header_prequel} = $h;   # save this aside for dbcolneaten
    $h .= join(" ", @{$self->{_cols}});
    $self->{_headerrow} = $h;
}


=head2 parse_headerrow

internal: interpet the v2 header.
Format is:

    #fsdb [-F x] [-R x] [-Z x] columns

All options must come first, start with dashes, and have an argument.
(More regular than the v1 header.)

=cut
sub parse_headerrow($) {
    my($self) = @_;
    return if ($self->{_error});
    my(@f) = split(/\s+/, $self->{_headerrow});
    my $tag = shift @f;
    if ($tag eq '#fsdb') {
	# fall through
    } elsif ($tag eq '#L' || $tag eq '#h') {
	return $self->parse_v1_headerrow;
    } else {
        $self->{_error} = "header line is not fsdb format";
	return;
    };

    #
    # handle options
    #
    while ($#f >= 0 && $f[0] =~ /^-/) {
        my($key) = shift @f;
        my($value) = shift @f;
        if ($key eq '-F') {
	    $self->parse_fscode($value);
        } elsif ($key eq '-R') {
	    $self->parse_rscode($value);
        } elsif ($key eq '-Z') {
	    $self->parse_compression($value);
	} else {
	    $self->{_error} = "header has unknown option " . $key;
	    return;
	};
    };

    # create them!
    foreach (@f) {
	$self->_internal_col_create($_);
    };

}


=head2 parse_v1_fscode

internal

=cut
sub parse_v1_fscode {
    my $self = shift @_;
    my $code = shift @_;
    if ($code =~ /^[DsSt]$/) {
	$self->parse_fscode($code);
    } else {
	# Ick.  Old way.  Not very safe.
	# Take char itself as code.
	$self->parse_fscode("C$code");
    };
}


=head2 parse_fscode

Parse the field separator.  
See L<dbfilealter> for a list of valid values.

=cut
sub parse_fscode {
    my $self = shift @_;
    my $code = shift @_;
    my ($fsre, $outfs);
    if (!defined($code) || $code eq 'D') {  # default
        $fsre = '\s+';  # "[ \t\n]+";
        $outfs = "\t";
	$code = 'D';   # always leave it defined so eq/ne work
    } elsif ($code eq 's') {   # single space
        $fsre = '\s+';
        $outfs = " ";
    } elsif ($code eq 'S') {   # double space
        $fsre = '\s\s+';
        $outfs = "  ";
    } elsif ($code eq 't') {   # single tab
        $fsre = "\t";
        $outfs = "\t";
    } elsif ($code =~ /^X(.*)$/) {   # hex value
	my $real_code = chr(hex($1));
	$fsre = "[$real_code]+";
	$outfs = $real_code;
    } elsif ($code =~ /^C(.)$/) {   # character value
	my $real_code = $1;
	$fsre = "[$real_code]+";
	$outfs = $real_code;
    } else {
	$self->{_error} = "bad field separator given ($code)";
	return;
    };
    $self->{_fscode} = $code;
    $self->{_fsre} = $fsre;
    $self->{_fs} = $outfs;
}


=head2 parse_rscode

Internal: Interpret rscodes.

See L<dbfilealter> for a list of valid values.

=cut
sub parse_rscode($$) {
    my($self, $code) = @_;
    $code = 'D' if (!defined($code));
    $self->{_error} = "invalid rscode: $code"
	if (!($code eq 'D' || $code eq 'C' || $code eq 'I'));
    $self->{_rscode} = $code;
}

=head2 parse_compression

Internal: Interpret compression.

See L<dbfilealter> for a list of valid values.

=cut
sub parse_compression($$) {
    my($self, $code) = @_;
    $code = 'none' if (!defined($code));
    $self->{_error} = "invalid compression: $code"
	if (!($code eq 'none' || $code eq 'gz' || $code eq 'xz' || $code eq 'bz2'));
    $self->{_compression} = $code;
}


=head2 establish_new_col_mapping

internal

=cut
sub establish_new_col_mapping {
    my($self, $colname) = @_;

    my $coli = $#{$self->{_cols}} + 1;
    $self->{_cols}->[$coli] = $colname;
    $self->{_cols_to_i}->{$colname} = $coli;
    # Old.pm also registers _$colname, but that seems Wrong. 
    $self->{_cols_to_i}->{"$coli"} = $coli;   # numeric synonym

    $self->{_codifier_sub} = undef;  # clear cache
}

=head2 col_create

    $fsdb->col_create($col_name)

Add a new column named $COL_NAME to the schema.
Returns undef on failure, or 1 if sucessful.
(Note: does I<not> return the column index on creation because
so that C<or> can be used for error checking,
given that the column number could be zero.)
Also, update the header row to reflect this column
(compare to C<_internal_col_create>).

=cut

sub col_create {
    my $self = shift @_;
    $self->_internal_col_create(@_) and
        $self->update_headerrow;
}

=head2 _internal_col_create

    $fsdb->_internal_col_create($col_name)

For internal C<Fsdb::IO> use only.
Create a new column $COL_NAME,
just like C<col_create>,
but do I<not> update the header row
(as that function does).

=cut

sub _internal_col_create {
    my($self, $colname) = @_;
    if ($self->{_header_set}) {
	$self->{_error} = "attempt to add column to frozen fsdb handle (reader or writer that's been written to): $colname";
	return undef;
    };
    if (defined($self->col_to_i($colname))) {
	$self->{_error} = "duplicate col definition: $colname";
	return undef;
    };
    $self->establish_new_col_mapping($colname);
    return 1;
}

=head2 field_contains_fs

    $boolean = $fsdb->field_contains_fs($field);

Determine if the $FIELD contains $FSDB's fscode
(in which case it is malformed).

=cut

sub field_contains_fs {
    my($self, $field) = @_;
    return ($field =~ /$self->{_fsre}/);
}

=head2 fref_contains_fs

    $boolean = $fsdb->fref_contains_fs($fref);

Determine if any field in $FREF contains $FSDB's fscode
(in which case it is malformed).

=cut

sub fref_contains_fs {
    my($self, $fref) = @_;
    foreach (@$fref) {
	return 1 if ($_ =~ /$self->{_fsre}/);
    };
    return 0;
}

=head2 correct_fref_containing_fs

    $boolean = $fsdb->correct_fref_containing_fs($fref);

Patch up any field in $FREF contains $FSDB's fscode, as best as possible,
but turning the field separator into underscores.
Updates $FREF in place, and returns if it was altered.
This function looses data.

=cut

sub correct_fref_containing_fs {
    my($self, $fref) = @_;
    my $changed = undef;
    foreach (0..$#$fref) {
	$changed = 1 if ($fref->[$_] =~ s/$self->{_fsre}/_/g);
    };
    return $changed;
}

=head2 fscode

    $fscode = $fsdb->fscode;

Returns the fscode of the given database.
(The encoded verison representing the field separator.)
See also fs to get the actual field separator.

=cut

sub fscode {
    my($self) = @_;
    return $self->{_fscode};
}

=head2 fs

    $fscode = $fsdb->fs;

Returns the field separator.
See C<fscode> to get the "encoded" version.

=cut

sub fs {
    my($self) = @_;
    return $self->{_fs};
}


=head2 rscode

    $rscode = $fsdb->rscode;

Returns the rscode of the given database.

=cut

sub rscode {
    my($self) = @_;
    return $self->{_rscode};
}


=head2 ncols

    @fields = $fsdb->ncols;

Return the number of columns.

=cut

sub ncols {
    my($self) = @_;
    return $#{$self->{_cols}} + 1;
}

=head2 cols

    $fields_aref = $fsdb->cols;

Returns the column headings (the field names) of the open database
as an aref.

=cut

sub cols {
    my($self) = @_;
    return $self->{_cols};
}
    

=head2 col_to_i

    @fields = $fsdb->col_to_i($column_name);

Returns the column index (0-based) of a given $COLUMN_NAME.

Note: tests for existence of columns must use C<defined>,
since the index can be 0 which would be interpreted as false.

=cut

sub col_to_i {
    my($self, $n) = @_;
    return $self->{_cols_to_i}->{$n};
}

=head2 i_to_col

    @fields = $fsdb->i_to_col($column_index);

Return the name of the COLUMN_INDEX-th (0-based) column.

=cut

sub i_to_col {
    my($self, $i) = @_;
    return $self->{_cols}->[$i];
}

# =head2 attributes
# 
#     %attributes = $fsdb->attributes;
# 
# Returns (a copy of) all attributes for the file (if any).
# 
# =cut
# 
# sub attributes() {
#     my $self = shift @_;
#     $self->check_attributes;
#     return %{$self->{_attributes}};
# }
# 
# =head2 attribute
# 
#     $an_attribute = $fsdb->attribute('empty');
# 
# Returns one attribute of the file (if any).
# 
# =cut
# 
# sub attribute() {
#     my $self = shift @_;
#     $self->check_attributes;
#     return $self->{_attributes}{$_[0]};
# }
# 
# =head2 set_attribute
# 
#     $fsdb->set_attribute('empty', '-');
# 
# Sets one attribute of the file.
# 
# =cut
# 
# sub set_attribute() {
#     my $self = shift @_;
#     $self->check_attributes;
#     $self->{_attributes}{$_[0]} = $_[1];
# }

=head2 fastpath_cancel

    $fsdb->fastpath_cancel();

Discard any active fastpath code and allow fastpath-incompatible operations.
=cut

sub fastpath_cancel {
    my $self = shift @_;
    # Just an honor code, we can't actually reach out and invalidate
    # the fastpath code. :-(
    $self->{_fastpath_active} = undef;
}

=head2 codify 

    ($code, $has_last_refs) = $self->codify($underscored_pseudocode);

Convert db-code C<$UNDERSCORED_PSEUDOCODE> into perl code
in the context of a given Fsdb stream.

We return a string of code C<$CODE>
that refs C<@{$fref}> and C<@{$lfref}>
for the current and prior row arrays,
and a flag C<$HAS_LAST_REFS> if C<@{$lfref}> is needed.
It is the callers job to set these up,
probably by evaling the returned string in the context of those variables.n

The conversion is a rename of all _foo's into
database fields.
For more perverse needs, _foo(N) means the Nth field after _foo.
Also, as of 29-Jan-00, _last_foo gives the last row's value
(_last_foo(N) is not supported).
To convert we eval $codify_code.

20-Feb-07: _FROMFILE_foo opens the file called _foo and includes it in place.

NEEDSWORK:  Should make some attempt to catch misspellings of column
names.

=cut

sub codify {
    my $self = shift @_;
    if (!defined($self->{_codifier_sub})) {
	#
	# Here we generate an anon sub that takes
	# its args (@_) as code and returns them 
	# as one string of fixed code that refs @{$fref} and @{$lfref}.
	#
	my $codify_code = "sub {\n" .
			    'my $has_lfrefs = undef;' . "\n" .
			    'my $c = join(";", @_);' . "\n";
        foreach (@{$self->cols}) {
# xxx:
#	    # indirect @_foo
#	    $codify_code .= 'if ($c =~ m/\b\_FROMFILE\(\_' . quotemeta($_) . '\)\b/) { ' .
##		    '  my $c = slurpfile($c[' . $colnametonum{$_} . ']); ' .
##		    '  my $c = "foo"; ' .
##		    '  s/\b\_FROMFILE\(\_' . quotemeta($_) . '\)\b/$c/g; ' .
#		    '  $c =~ s/\b\_FROMFILE\(\_' . quotemeta($_) . '\)\b/foo/g; ' .
#		    '};' . "\n";
#	    $codify_code .= '$c =~ s/\b\_FROMFILE\(\_' . quotemeta($_) . '\)\b/\$c\[' . $colnametonum{$_} . '\]/g;' . "\n";
	    # _foo(N) [perverse]
	    $codify_code .= "\t" . '$c =~ s/\b\_' . quotemeta($_) . '(\(.*\))/\$fref->\[' . $self->col_to_i($_) . '+$1\]/g;' . "\n";
	    # _foo
	    $codify_code .= "\t" . '$c =~ s/\b\_' . quotemeta($_) . '\b/\$fref->\[' . $self->col_to_i($_) . '\]/g;' . "\n";
	    $codify_code .= "\t" . '$has_lfrefs = 1 if ($c =~ /\b\_last\_' . quotemeta($_) . '\b/);' . "\n";
	    # _last_foo
	    $codify_code .= "\t" . '$c =~ s/\b\_last\_' . quotemeta($_) . '\b/\$lfref->\[' . $self->col_to_i($_) . '\]/g;' . "\n";
        };
	# print "CODE: $codify_code\n";
	$codify_code .= "\t" . 'return ($c, $has_lfrefs);' . "\n};\n";
	my $codify_sub;
	eval "\$codify_sub = $codify_code;";
	croak "cannot eval code:\n\t$@\n\t$codify_code\n" if ($@ ne '');
	$self->{_codifier_sub} = $codify_sub;
    };
    #
    # do it!
    #
    return &{$self->{_codifier_sub}}(@_);
}

=head2 clean_potential_columns

    @clean = Fsdb::IO::clean_potential_columns(@dirty);

Clean up user-provided column names.

=cut

sub clean_potential_columns {
    # normalize field names
    grep(s/^\s+//, @_);
    grep(s/\s+$//, @_);
    grep(s/\s+/_/g, @_);
    return @_;
}


1;
