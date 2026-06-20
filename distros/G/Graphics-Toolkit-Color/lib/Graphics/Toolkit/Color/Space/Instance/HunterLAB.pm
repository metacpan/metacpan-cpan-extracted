
# Hunter lab color space, pre CIELAB, for Illuminant D65 and Observer 2 degree

package Graphics::Toolkit::Color::Space::Instance::HunterLAB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/round_decimals/;

my @D65 = (0.95047, 1, 1.08883); # illuminant
my %K   = ( a => round_decimals(175.0 / 198.04 * ($D65[1] + $D65[0]) * 100, 5),
            b => round_decimals( 70.0 / 218.11 * ($D65[1] + $D65[2]) * 100, 5), );


sub from_lab {
    my ($lab) = shift;
    my $l = $lab->[0];
    my $a = ($lab->[1] - .5) * 2;
    my $b = ($lab->[2] - .5) * 2;
    my $y = $l ** 2;
    my $x = ($a * $l) + $y;
    my $z = $y - ($b * $l);
    return ([$x, $y, $z]);
}
sub to_lab {
    my ($xyz) = shift;
    my $l = sqrt $xyz->[1];
    my $a = $l ? (($xyz->[0] - $xyz->[1])/$l) : 0;
    my $b = $l ? (($xyz->[1] - $xyz->[2])/$l) : 0;
    $a = ($a / 2) + .5;
    $b = ($b / 2) + .5;
    return ([$l, $a, $b]);
}

Graphics::Toolkit::Color::Space->new(
         name => 'HunterLAB',
       family => 'LAB',
         axis => [qw/l a b/],  # same as short
        range => [100, [-$K{'a'}, $K{'a'}], [-$K{'b'}, $K{'b'}]], # cyan-orange, magenta-green
    precision => 3,
      convert => {XYZ => [\&from_lab, \&to_lab]},
);
