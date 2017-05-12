package File::Rsync::Mirror::Recentfile::FakeBigFloat;

# use warnings;
use strict;
use Data::Float qw(nextup);

# _bigfloat
sub _bigfloatcmp ($$);
sub _bigfloatge ($$);
sub _bigfloatgt ($$);
sub _bigfloatle ($$);
sub _bigfloatlt ($$);
sub _bigfloatmax ($$);
sub _bigfloatmin ($$);
sub _increase_a_bit ($;$);
sub _increase_a_bit_tail ($$);
sub _my_sprintf_float ($);

=encoding utf-8

=head1 NAME

File::Rsync::Mirror::Recentfile::FakeBigFloat - pseudo bigfloat support

=cut

use version; our $VERSION = qv('0.0.8');

use Exporter;
use base qw(Exporter);
our %EXPORT_TAGS;
our @EXPORT_OK = qw(
                    _bigfloatcmp
                    _bigfloatge
                    _bigfloatgt
                    _bigfloatle
                    _bigfloatlt
                    _bigfloatmax
                    _bigfloatmin
                    _increase_a_bit
                   );
$EXPORT_TAGS{all} = \@EXPORT_OK;

=head1 SYNOPSIS

  use File::Rsync::Mirror::Recentfile::FakeBigFloat qw(:all);

=head1 ONLY INTERNAL FUNCTIONS

These functions are not part of a public interface and can be
changed and go away any time without prior notice.

=head1 DESCRIPTION

We treat strings that look like floating point numbers. If the native
floating point support is good enough we use it. If it isn't we make
sure no two unequal numbers are treated the same and vice versa. Only
comparison operators are supported, no other math.

=head1 EXPORT

All functions are exported in the C<:all> tag.

=head2 _bigfloatcmp ( $l, $r )

Cmp function for floating point numbers that have a larger significand
than can be handled by native perl floats.

=cut
sub _bigfloatcmp ($$) {
    # my($l,$r) = @_;
    unless (defined $_[0] and defined $_[1]) {
        require Carp;
        for ($_[0],$_[1]) {
            $_ = defined $_ ? $_ : "UNDEF";
        }
        Carp::confess("_bigfloatcmp called with l[$_[0]]r[$_[1]]: but both must be defined");
    }
    # unequal is much more frequent than equal but let's get rid of these
    return  0 if $_[0] eq $_[1];
    my $can_rely_on_native = 0;
    if ($_[0] =~ /\./ || $_[1] =~ /\./) {
        # if one is a float, both must be, otherwise perl gets it wrong (see test)
        for ($_[0], $_[1]){
            $_ .= ".0" unless /\./;
        }
        return  1 if $_[0] -  $_[1] >  1;
        return -1 if $_[0] -  $_[1] < -1;
    } else {
        $can_rely_on_native = 1; # can we?
    }
    #### XXX bug in some perls, we cannot trust native comparison on floating point values:
    #### see Todo file entry on 2009-03-15
    my $native = $_[0] <=> $_[1];
    return $native if $can_rely_on_native && $native != 0;
    $_[0] =~ s/^/0/ while index($_[0],".") < index($_[1],".");
    $_[1] =~ s/^/0/ while index($_[1],".") < index($_[0],".");
    $_[0] cmp $_[1];
}

=head2 _bigfloatge ( $l, $r )

Same for ge

=cut
sub _bigfloatge ($$) {
    _bigfloatcmp($_[0],$_[1]) >= 0;
}

=head2 _bigfloatgt ( $l, $r )

Same for gt

=cut
sub _bigfloatgt ($$) {
    _bigfloatcmp($_[0],$_[1]) > 0;
}

=head2 _bigfloatle ( $l, $r )

Same for lt

=cut
sub _bigfloatle ($$) {
    _bigfloatcmp($_[0],$_[1]) <= 0;
}

=head2 _bigfloatlt ( $l, $r )

Same for lt

=cut
sub _bigfloatlt ($$) {
    _bigfloatcmp($_[0],$_[1]) < 0;
}

=head2 _bigfloatmax ( $l, $r )

Same for max (of two arguments)

=cut
sub _bigfloatmax ($$) {
    my($l,$r) = @_;
    return _bigfloatcmp($l,$r) >= 0 ? $l : $r;
}

=head2 _bigfloatmin ( $l, $r )

Same for min (of two arguments)

=cut
sub _bigfloatmin ($$) {
    my($l,$r) = @_;
    return _bigfloatcmp($l,$r) <= 0 ? $l : $r;
}

=head2 $big = _increase_a_bit ( $l, $r )

=head2 $big = _increase_a_bit ( $n )

The first form calculates a string that is between the two numbers,
closer to $l to prevent rounding effects towards $r. The second form
calculates the second number itself based on nextup() in
L<Data::Float>.

=cut
sub _my_sprintf_float ($) {
    my($x) = @_;
    my $r;
    require Config;
    my $nvsize = $Config::Config{nvsize} || 8;
    my $lom = 2*$nvsize; # "length of mantissa": nextup needs more digits
 NORMALIZE: while () {
        my $sprintf = "%." . $lom . "f";
        $r = sprintf $sprintf, $x;
        if ($r =~ /\.\d+0$/) {
            last NORMALIZE;
        } else {
            $lom *= 2;
        }
    }
    $r =~ s/(\d)0+$/$1/;
    return $r;
}
sub _increase_a_bit ($;$) {
    my($l,$r) = @_;
    unless (defined $l) {
        die "Alert: _increase_a_bit called with undefined first argument";
    }
    if (defined $r){
        if ($r eq $l){
            die "Alert: _increase_a_bit called with identical arguments";
        } elsif ($r > int($l)+1) {
            $r = int($l)+1;
        }
    } else {
        $r = _my_sprintf_float(Data::Float::nextup($l));
    }
    my $ret;
    if ($l == $r) {
    } else {
        # native try
        my $try = _my_sprintf_float(($l+$r)/2);
        if (_bigfloatlt($l,$try) && _bigfloatlt($try,$r) ) {
            $ret = $try;
        }
    }
    return $ret if $ret;
    return _increase_a_bit_tail($l,$r);
}
sub _increase_a_bit_tail ($$) {
    my($l,$r) = @_;
    my $ret;
    for ($l, $r){
        $_ .= ".0" unless /\./;
    }
    $l =~ s/^/0/ while index($l,".") < index($r,".");
    $r =~ s/^/0/ while index($r,".") < index($l,".");
    $l .= "0" while length($l) < length($r);
    $r .= "0" while length($r) < length($l);
    my $diffdigit;
  DIG: for (my $i = 0; $i < length($l); $i++) {
        if (substr($l,$i,1) ne substr($r,$i,1)) {
            $diffdigit = $i;
            last DIG;
        }
    }
    $ret = substr($l,0,$diffdigit);
    my $sl = substr($l,$diffdigit); # significant l
    my $sr = substr($r,$diffdigit);
    if ($ret =~ /\./) {
        $sl .= ".0";
        $sr .= ".0";
    }
    my $srlength = length $sr;
    my $srmantissa = $srlength - index($sr,".");
    # we want 1+$srlength because if l ends in 99999 and r in 00000,
    # we need one digit more
    my $fformat = sprintf "%%0%d.%df", 1+$srlength, $srmantissa;
    my $appe = sprintf $fformat, ($sl+$sr)/2;
    $appe =~ s/(\d)0+$/$1/;
    if ($ret =~ /\./) {
        $appe =~ s/\.//;
    }
    $ret .= $appe;
  CHOP: while () {
        my $try = substr($ret,0,length($ret)-1);
        if (_bigfloatlt($l,$try) && _bigfloatlt($try,$r)) {
            $ret = $try;
        } else {
            last CHOP;
        }
    }
    return $ret;
}

=head1 COPYRIGHT & LICENSE

Copyright 2008, 2009 Andreas König.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of File::Rsync::Mirror::Recentfile

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# End:
