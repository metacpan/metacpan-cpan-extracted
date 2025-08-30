
# OK LCH cylindrical color space variant of OKLAB

package Graphics::Toolkit::Color::Space::Instance::OKLCH;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/round_decimals/;

my $TAU = 6.283185307;

sub from_lab {
    my ($lab) = shift;
    my $a = $lab->[1] - .5;
    my $b = $lab->[2] - .5;

    $a = 0 if round_decimals($a, 5) == 0;
    $b = 0 if round_decimals($b, 5) == 0;
    my $c = sqrt( ($a**2) + ($b**2));
    my $h = atan2($b, $a);
    $h += $TAU if $h < 0;
    return ([$lab->[0], $c * 2, $h / $TAU]);
}
sub to_lab {
    my ($lch) = shift;
    my $c = $lch->[1] / 2;
    my $a = $c * cos($lch->[2] * $TAU);
    my $b = $c * sin($lch->[2] * $TAU);
    return ([$lch->[0], $a + .5, $b + .5 ]);
}

Graphics::Toolkit::Color::Space->new(
        name => 'OKLCH',
        axis => [qw/luminance chroma hue/],
        type => [qw/linear linear angular/],
       range => [1, .5, 360],
   precision => [5,5,2],
     convert => { OKLAB => [\&to_lab, \&from_lab] },
);
