
# OKHSV color space, converter under Copyright (c) 2021 Björn Ottosson, see LICENSE.OK

package Graphics::Toolkit::Color::Space::Instance::OKHSV;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/max spow/;
use Graphics::Toolkit::Color::Space::Instance::Helper::OK 
	qw/find_cusp to_ST toe toe_inv oklab_to_linear_srgb linear_srgb_to_oklab/;
my $PI      = 4 * atan2(1, 1);


sub from_hsv {
    my ($hsv) = @_;
    return [0, 0, 0] if $hsv->[2] <= 0;          # black (v == 0)

    my $a = cos(2 * $PI * $hsv->[0]);            # Farbtonrichtung
    my $b = sin(2 * $PI * $hsv->[0]);

    my ($L_cusp, $C_cusp) = find_cusp($a, $b);
    my ($S_max, $T_max)   = to_ST($L_cusp, $C_cusp);
    my $S_0 = 0.5;
    my $k   = 1 - $S_0 / $S_max;

    # L, C als waere das Gamut ein perfektes Dreieck (Werte bei v == 1)
    my $denom = $S_0 + $T_max - $T_max * $k * $hsv->[1];
    $denom = 1e-6 if $denom < 1e-6;

    my $L_v = 1 - $hsv->[1] * $S_0 / $denom;
    my $C_v = $hsv->[1] * $T_max * $S_0 / $denom;

    my $L = $hsv->[2] * $L_v;
    my $C = $hsv->[2] * $C_v;

    # Kompensation fuer toe und gekruemmte Dreiecksspitze
    my $L_vt = toe_inv($L_v);
    my $C_vt = $C_v * $L_vt / $L_v;

    my $L_new = toe_inv($L);
    $C = $C * $L_new / $L;
    $L = $L_new;

    my $rgb_scale = oklab_to_linear_srgb([$L_vt, $a * $C_vt, $b * $C_vt]);
    my $scale_L = spow(1 / max(@$rgb_scale, 0), 1/3);

    $L *= $scale_L;
    $C *= $scale_L;

    return oklab_to_linear_srgb([$L, $C * $a, $C * $b]);
}

sub to_hsv {
    my ($rgb) = @_;                                  # bereits LINEARES sRGB
    my $lab = linear_srgb_to_oklab($rgb);            # roh, a/b um 0 zentriert

    my $C = spow($lab->[1]**2 + $lab->[2]**2, 1/2);  # Chroma
    return [0, 0, toe($lab->[0])] if $C < 1e-9;      # achromatisch

    my $a = $lab->[1] / $C;                          # Farbtonrichtung
    my $b = $lab->[2] / $C;
    my $h = 0.5 + 0.5 * atan2(-$lab->[2], -$lab->[1]) / $PI;

    my ($L_cusp, $C_cusp) = find_cusp($a, $b);
    my ($S_max, $T_max)   = to_ST($L_cusp, $C_cusp);
    my $S_0 = 0.5;
    my $k   = 1 - $S_0 / $S_max;

    # L_v, C_v und ihre toe-kompensierten Varianten
    my $t   = $T_max / ($C + $lab->[0] * $T_max);
    my $L_v = $t * $lab->[0];
    my $C_v = $t * $C;

    my $L_vt = toe_inv($L_v);
    my $C_vt = $C_v * $L_vt / $L_v;

    my $rgb_scale = oklab_to_linear_srgb([$L_vt, $a * $C_vt, $b * $C_vt]);
    my $scale_L = spow(1 / max(@$rgb_scale, 0), 1/3);

    my $L = $lab->[0] / $scale_L;
    $C = $C / $scale_L;
    $C = $C * toe($L) / $L;
    $L = toe($L);

    my $s = ($S_0 + $T_max) * $C_v / ($T_max * $S_0 + $T_max * $k * $C_v);

    return [$h, $s, $L / $L_v];
}

Graphics::Toolkit::Color::Space->new(
         name => 'OKHSV',
       family => 'HSV',
         axis => [qw/hue saturation value/], 
         type => [qw/angular linear linear/],
        range => [360, 1, 1],
    precision => 5,
      convert => {LinearRGB => [\&from_hsv, \&to_hsv]},
);
