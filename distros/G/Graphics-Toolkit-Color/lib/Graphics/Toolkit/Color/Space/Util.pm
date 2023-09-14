use v5.12;
use warnings;

# utilities for any sub module of the distribution

package Graphics::Toolkit::Color::Space::Util;

use Exporter 'import';
our @EXPORT_OK = qw/round rmod close_enough min max/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

my $half      = 0.50000000000008;
my $tolerance = 0.00000000000008;

sub rgb_to_hue {
    my (@rgb) = @_;

}

sub max {
    my $v = shift;
    for (@_) { $v = $_ if $v < $_ }
    $v;
}

sub min {
    my $v = shift;
    for (@_) { $v = $_ if $v > $_ }
    $v;
}

sub round {
    $_[0] >= 0 ? int ($_[0] + $half)
               : int ($_[0] - $half)
}

# real value modulo
sub rmod {
    return 0 unless defined $_[1] and $_[1];
    $_[0] - (int($_[0] / $_[1]) * $_[1]);
}

sub close_enough { abs($_[0] - $_[1]) < 0.008 if defined $_[1]}

1;

# min(floor(val*256),255)
