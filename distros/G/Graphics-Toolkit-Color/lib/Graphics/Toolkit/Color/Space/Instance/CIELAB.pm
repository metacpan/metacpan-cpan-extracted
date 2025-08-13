
# CIE LAB color space specific code based on XYZ for Illuminant D65 and Observer 2 degree

package Graphics::Toolkit::Color::Space::Instance::CIELAB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space;

my  $lab_def = Graphics::Toolkit::Color::Space->new( alias => 'CIELAB',        # space name LAB
                                                      axis => [qw/L* a* b*/],  # short l a b
                                                     range => [100, [-500, 500], [-200, 200]],
                                                 precision => 3 );             # lightness, cyan-orange balance, magenta-green balance

$lab_def->add_converter('XYZ', \&to_xyz, \&from_xyz );

my @D65 = (0.95047, 1, 1.08883); # illuminant
my $eta = 0.008856 ;
my $kappa = 903.3;

sub from_xyz {
    my ($xyz) = shift;
    my @xyz = map {($_ > $eta) ? ($_ ** (1/3)) : ((($kappa * $_) + 16) / 116)} @$xyz;
    my $l = (1.16 * $xyz[1]) - 0.16;
    my $a = ($xyz[0] - $xyz[1] + 1) / 2;
    my $b = ($xyz[1] - $xyz[2] + 1) / 2;
    return ($l, $a, $b);
}

sub to_xyz {
    my ($lab) = shift;
    my $fy = ($lab->[0] + 0.16) / 1.16;
    my $fx = $fy - 1 + ($lab->[1] * 2);
    my $fz = $fy + 1 - ($lab->[2] * 2);
    my @xyz = map {my $f3 = $_** 3; ($f3 > $eta) ? $f3 : (( 116 * $_ - 16 ) / $kappa) } $fx, $fy, $fz;
    return @xyz;
}

$lab_def;
