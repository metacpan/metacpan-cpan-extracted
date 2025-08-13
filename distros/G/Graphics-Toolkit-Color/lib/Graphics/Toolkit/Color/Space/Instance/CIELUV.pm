
# CIE LUV color space specific code based on XYZ for Illuminant D65 and Observer 2 degree

package Graphics::Toolkit::Color::Space::Instance::CIELUV;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space;

my  $luv_def = Graphics::Toolkit::Color::Space->new(  alias => 'CIELUV',        # space name is LUV
                                                       axis => [qw/L* u* v*/],  # short l u v
                                                      range => [100, [-134, 220], [-140, 122]],
                                                  precision => 3 );

$luv_def->add_converter('XYZ', \&to_xyz, \&from_xyz );

my @D65 = (0.95047, 1, 1.08883); # illuminant
my $eta = 0.008856 ;
my $kappa = 903.3;

sub from_xyz {
    my ($xyz) = shift;
    my @XYZ = map { $xyz->[$_] * $D65[$_] } 0 .. 2;

    my $color_mix = $XYZ[0] + (15 * $XYZ[1]) + (3 * $XYZ[2]);
    my $u_color = $color_mix ? (4 * $XYZ[0] / $color_mix) : 0;
    my $v_color = $color_mix ? (9 * $XYZ[1] / $color_mix) : 0;

    my $white_mix = $D65[0] + (15 * $D65[1]) + (3 * $D65[2]); # 19.21696
    my $u_white = 0.197839825; # 4 * $D65[0] / $white_mix; #
    my $v_white = 0.468336303; # 9 * $D65[1] / $white_mix; #

    my $l = ($XYZ[1] > $eta) ? (($XYZ[1] ** (1/3)) * 116 - 16) : ($kappa * $XYZ[1]);
    my $u = 13 * $l * ($u_color - $u_white);
    my $v = 13 * $l * ($v_color - $v_white);

    return ( $l / 100 , ($u+134) / 354, ($v+140) / 262 );
}


sub to_xyz {
    my ($luv) = shift;
    my $l = $luv->[0] * 100;
    my $u = $luv->[1] * 354 - 134;
    my $v = $luv->[2] * 262 - 140;

    my $white_mix = $D65[0] + (15 * $D65[1]) + (3 * $D65[2]); # 19.21696
    my $u_white = 0.197839825; # 4 * $D65[0] / $white_mix; #
    my $v_white = 0.468336303; # 9 * $D65[1] / $white_mix; #

    my $u_color = $l ? (($u / 13 / $l) + $u_white) : 0;
    my $v_color = $l ? (($v / 13 / $l) + $v_white) : 0;

    my $y = ($l > $kappa * $eta) ? ((($l+16) / 116) ** 3) : ($l / $kappa);
    my $color_mix = $v_color ? (9 * $y / $v_color) : 0;
    my $x = $u_color * $color_mix / 4;
    my $z = ($color_mix - $x - (15 * $y)) / 3;
    my $XYZ = [$x, $y, $z];

    return map { $XYZ->[$_] / $D65[$_] } 0 .. 2;
}

$luv_def;
