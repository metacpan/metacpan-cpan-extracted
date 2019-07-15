#!/usr/bin/perl

#
# Support.pm
# Copyright (C) 1991-2007 by John Heidemann <johnh@isi.edu>
# $Id: 88483b6ffcd50120552f971d8e96d3f2e82f71dd $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Support;

=head1 NAME

Fsdb::Support - support routines for Fsdb

=head1 SYNOPSIS

This class contains the bits of Fsdb::Old that needed to be kept.

=head1 FUNCTIONS

=cut

@ISA = ();
($VERSION) = 1.0;

## Module import.
use Exporter 'import';
@EXPORT = qw();
@EXPORT_OK = qw(
    shell_quote
    code_prettify
    force_numeric
    fullname_to_sortkey
    progname
    $is_numeric_regexp
    ddmmmyy_to_iso
    int_to_metric
    );

#
# our libaries
#
use IO::Handle;
use IO::File;
use Carp qw(croak);

use Fsdb::IO::Reader;
use Fsdb::IO::Writer;

=head1 LOGGING REALTED FUNCTIONS

=head2 progname 

Generate the name of our program for error messages.

=cut
sub progname () {
    my($prog) = ($0);
    $prog =~ s@^.*/@@g;
    return $prog;
}

=head1 IO SETUP FUNCTIONS

=head2 default_in(@READER_OPTIONS)

Generate a default Fsdb::Reader object with the given READER_OPTIONS

=cut
sub default_in ($@) {
    my $in_fh = new IO::Handle;
    $in_fh->fdopen(fileno(STDIN), "r") or croak progname . ": cannot open input as fsdb.\n";
    my $in = new Fsdb::IO::Reader(-fh => $in_fh, @_);
    return $in;
#    $in->error and croak progname . ": cannot open input as fsdb.\n";
}

=head2 default_out(@WRITER_OPTIONS)

Generate a default Fsdb::Writer object with the given READER_OPTIONS

=cut
sub default_out ($@) {
    my $out_fh = new IO::Handle;
    $out_fh->fdopen(fileno(STDOUT), "w+") or croak progname . ": cannot open stdout.\n";
    my $out = new Fsdb::IO::Writer(-fh => $out_fh, @_);
    return $out;
#    $out->error and croak progname . ": cannot open STDOUT as fsdb.\n";
}

=head1 CONVERSION FUNCTIONS

=head2 code_prettify 

Convert db-code into "pretty code".

=cut
sub code_prettify (@) {
    my($prettycode) = join(";", @_);
    $prettycode =~ s/\n/ /g;   # newlines will break commenting
    return $prettycode;
}

=head2 shell_quote

Convert output to shell-like quoting

=cut
sub shell_quote(@) {
    my($s) = @_;
    if ($s =~ /\s/) {
	# should use String::ShellQuote, but don't want the dpeendency
	$s =~ s/\'/'\\\''/g;
	$s = "'" . $s . "'";
    };
    return $s;
}

=head1 CONVERSION FUNCTIONS

=head2 number_prettify 

Add-thousands-separators to numbers.

xxx: should consider locale.

(This code is from F<http://www.perlmonks.org/?node_id=653>,
contributed by Andrew Johnson from University of Alberta.)

=cut
sub number_prettify($) {
	my $input = shift;
        $input = reverse $input;
        $input =~ s<(\d\d\d)(?=\d)(?!\d*\.)><$1,>g;
        return reverse $input;
}

=head2 force_numeric

    my $x = force_numeric($s, $include_non_numeric)

Return C<$S> if it's numeric, or C<undef> if not.
If C<$INCLUDE_NON_NUMERIC>, then non-numeric values register as zero.

=cut
# note that we tolerate spaces before and after,
# since field splitting doesn't always kill them
# (see TEST/dbcolstats_trailing_spaces.in)
our $is_numeric_regexp = '^\s*[+-]?(\d+\.\d+|\d+\.|\.\d+|\d+)([eE][+-]?\d+)?\s*$';
sub force_numeric {
    my($value, $zero_non_numeric) = @_;
    # next re is almost copied from L<perlretut>
    if ($value =~ /$is_numeric_regexp/) {
        return $value + 0.0;   # force numeric
    } else {
	if ($ignore_non_numeric) {
	    return undef;
	    next;
	} else {
	    return 0.0;
	};
    };
}


=head2 fullname_to_sortkey 

    my $sortkey = fullname_to_sortkey("John Smith");

Convert "Firstname Lastname" to sort key "lastname, firstname".

=cut
sub fullname_to_sortkey {
    my($sort) = @_;
    $sort = lc($sort);
    my($first, $last) = ($sort =~ /^(.*)\s+(\S+)$/);
    $last = $sort if (!defined($last));
    $first = '' if (!defined($first));
    return "$last, $first";
}


=head2 ddmmmyy_to_iso

    my $iso_date = ddmmmyy_to_iso('1-Jan-10')

Converts a date in the form dd-mmm-yy to ISO-style yyyy-mm-dd.
Examples:

2-Jan-70 to 1970-01-02
2-Jan-99 to 1999-01-02
2-Jan-10 to 2010-01-02
2-Jan-69 to 2069-01-02
Jan-10 to 2010-01-00
99 to 1999-00-00

=cut
sub ddmmmyy_to_iso {
    my($orig) = @_;
    return $orig if ($orig eq '-');
    my(@parts) = split('-', $orig);
    unshift(@parts, '00') if ($#parts == 0);
    unshift(@parts, '00') if ($#parts == 1);
    my($dd, $mm, $yyyy) = @parts;
    $dd = '0' if ($dd eq '?');
    my(%map) = qw(jan 1 feb 2 mar 3 apr 4 may 5 jun 6 jul 7 aug 8 sep 9 oct 10 nov 11 dec 12);
    $mm = $map{lc($mm)};  $mm = 0 if (!defined($mm));  # sigh, for 5.008
    $yyyy += 1900 if ($yyyy >= 70 && $yyyy < 100);
    $yyyy += 2000 if ($yyyy < 70);
    return sprintf("%04d-%02d-%02d", $yyyy, $mm, $dd);
}

=head2 int_to_metric

    my $value_str = int_to_metric(1000000);

Converts an integer into a string with its metric abbreviation.

1000 => 1k
1000000 => 1M

=cut
sub int_to_metric {
    my($n) = @_;
    my($prefix) = " kMGTEP";
    while (length($prefix) > 1) {
        last if ($n < 10000);
        $n = int($n / 1000);
        $prefix = substr($prefix, 1);
    };
    return "$n" . substr($prefix, 0, 1);
}

1;
