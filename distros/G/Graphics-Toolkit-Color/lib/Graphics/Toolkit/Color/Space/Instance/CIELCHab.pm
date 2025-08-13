
# CIE LCh(ab) cylindrical color space variant of CIELAB

package Graphics::Toolkit::Color::Space::Instance::CIELCHab;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/round_decimals/;

my  $hcl_def = Graphics::Toolkit::Color::Space->new( name => 'LCH', alias => 'CIELCHab',
                                                     axis => [qw/luminance chroma hue/],
                                                    range => [100, 539, 360],
                                                precision => 3 );

    $hcl_def->add_converter('LAB', \&to_lab, \&from_lab );

my $TAU = 6.283185307;

sub from_lab {
    my ($lab) = shift;
    my $a = $lab->[1] * 1000 - 500;
    my $b = $lab->[2] *  400 - 200;

    $a = 0 if round_decimals($a, 5) == 0;
    $b = 0 if round_decimals($b, 5) == 0;
    my $c = sqrt( ($a**2) + ($b**2));
    my $h = atan2($b, $a);
    $h += $TAU if $h < 0;
    return ($lab->[0], $c / 539, $h / $TAU);
}


sub to_lab {
    my ($lch) = shift;
    my $a = $lch->[1] * cos($lch->[2] * $TAU) * 539;
    my $b = $lch->[1] * sin($lch->[2] * $TAU) * 539;
    return ($lch->[0], ($a+500) / 1000, ($b+200) / 400 );
}

$hcl_def;
