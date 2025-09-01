
# utilities for color value calculation

package Graphics::Toolkit::Color::Space::Util;
use v5.12;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw/round_int round_decimals mod_real min max uniq mult_matrix_vector_3 is_nr/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

#### lists #############################################################
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

sub uniq {
    return undef unless @_;
    my %seen = ();
    grep {not $seen{$_}++} @_;
}

#### basic math ########################################################
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


sub mod_real { # real value modulo
    return 0 unless defined $_[1] and $_[1];
    return  $_[0] - (int($_[0] / $_[1]) * $_[1]);
}

sub is_nr { $_[0] =~ /^\-?\d+(\.\d+)?$/ }

#### color computation #################################################
sub mult_matrix_vector_3 {
    my ($mat, $v1, $v2, $v3) = @_;
    return unless ref $mat eq 'ARRAY' and defined $v3;
    return ($v1 * $mat->[0][0] + $v2 * $mat->[0][1] + $v3 * $mat->[0][2]) ,
           ($v1 * $mat->[1][0] + $v2 * $mat->[1][1] + $v3 * $mat->[1][2]) ,
           ($v1 * $mat->[2][0] + $v2 * $mat->[2][1] + $v3 * $mat->[2][2]) ;
}


1;
