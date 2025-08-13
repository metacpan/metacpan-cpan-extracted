
# utilities for color value calculation

package Graphics::Toolkit::Color::Space::Util;
use v5.12;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw/round_int round_decimals real_mod min max apply_d65 remove_d65 mult_matrix3 is_nr/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

my $half      = 0.50000000000008;
my $tolerance = 0.00000000000008;

sub round_int {
    $_[0] >= 0 ? int ($_[0] + $half)
               : int ($_[0] - $half)
}

sub round_decimals {
    my ($nr, $precision) = @_;
    return round_int( $nr ) unless defined $precision and $precision;
    $precision = 10 ** $precision;
    return  round_int( $nr * $precision ) / $precision;
}


sub real_mod { # real value modulo
    return 0 unless defined $_[1] and $_[1];
    return  $_[0] - (int($_[0] / $_[1]) * $_[1]);
}

sub is_nr { $_[0] =~ /^\-?\d+(\.\d+)?$/ }

sub max {
    my $v = shift;
    for (@_) { next unless defined $_; $v = $_ if $v < $_ }
    return $v;
}

sub min {
    my $v = shift;
    for (@_) { next unless defined $_; $v = $_ if $v > $_ }
    return $v;
}

# change normalized RGB values to and from standard observer 2°
sub apply_d65  { $_[0] > 0.04045  ? ((($_[0] + 0.055) / 1.055 ) ** 2.4) : ($_[0] / 12.92) }
sub remove_d65 { $_[0] > 0.003131 ? ((($_[0]**(1/2.4)) * 1.055) - 0.055) : ($_[0] * 12.92) }

sub mult_matrix3 {
    my ($mat, $v1, $v2, $v3) = @_;
    return unless ref $mat eq 'ARRAY' and defined $v3;
    return ($v1 * $mat->[0][0] + $v2 * $mat->[0][1] + $v3 * $mat->[0][2]) ,
           ($v1 * $mat->[1][0] + $v2 * $mat->[1][1] + $v3 * $mat->[1][2]) ,
           ($v1 * $mat->[2][0] + $v2 * $mat->[2][1] + $v3 * $mat->[2][2]) ;
}


1;
