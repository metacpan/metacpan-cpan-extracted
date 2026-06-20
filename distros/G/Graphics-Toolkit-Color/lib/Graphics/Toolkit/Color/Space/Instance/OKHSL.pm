
# OKHSL, Conveter under Copyright (c) 2021 Björn Ottosson, see LICENSE.OK

package Graphics::Toolkit::Color::Space::Instance::OKHSL;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/spow/;
use Graphics::Toolkit::Color::Space::Instance::Helper::OK 
    qw/toe toe_inv get_Cs oklab_to_linear_srgb linear_srgb_to_oklab/;
my $PI      = 4 * atan2(1, 1);
my $mid     = 0.8;
my $mid_inv = 1.25;


sub from_hsl {
    my ($hsl) = @_;
    return [0, 0, 0] if $hsl->[2] <= 0; # black
    return [1, 1, 1] if $hsl->[2] >= 1; # white

    my $L = toe_inv($hsl->[2]);
    my $a = cos(2 * $PI * $hsl->[0]);       # Farbtonrichtung (Einheitsvektor)
    my $b = sin(2 * $PI * $hsl->[0]);
    my ($C_0, $C_mid, $C_max) = get_Cs($L, $a, $b);
    my $C;
    # Sattigung -> absolute Chroma (Vorwaerts-Interpolation, Inverse zum Hinweg)
if ($hsl->[1] < $mid) {
        my $t  = $hsl->[1] / $mid;
        my $k1 = $mid * $C_0;
        my $k2 = 1 - $k1 / $C_mid;
        my $den = 1 - $k2 * $t;
        $den = 1e-6 if $den < 1e-6 and $den >= 0;
        $den = -1e-6 if $den > -1e-6 and $den < 0;
        $C = $t * $k1 / $den;
    }
    else {
        my $t  = ($hsl->[1] - $mid) / (1 - $mid);
        my $k0 = $C_mid;
        my $k1 = (1 - $mid) * $C_mid * $C_mid * $mid_inv * $mid_inv / $C_0;
        my $k2 = 1 - $k1 / ($C_max - $C_mid);
        my $den = 1 - $k2 * $t;
        $den = 1e-6 if $den < 1e-6 and $den >= 0;
        $den = -1e-6 if $den > -1e-6 and $den < 0;
        $C = $k0 + $t * $k1 / $den;
    }

    return oklab_to_linear_srgb([$L, $C * $a, $C * $b]);
}

sub to_hsl {
    my ($rgb) = @_;                                  # bereits LINEARES sRGB, Arrayref
    my $lab = linear_srgb_to_oklab($rgb);            # roh, a/b um 0 zentriert
    my $C = spow($lab->[1]**2 + $lab->[2]**2, 1/2);  # Chroma
    return [0, 0, toe($lab->[0])] if $C < 1e-9;      # achromatisch: Hue undefiniert -> 0, keine Division durch 0

    my $a = $lab->[1] / $C;                          # Farbtonrichtung (Einheitsvektor)
    my $b = $lab->[2] / $C;
    my $h = (0.5 + 0.5 * atan2(-$lab->[2], -$lab->[1]) / $PI);# Hue in Grad
    my ($C_0, $C_mid, $C_max) = get_Cs($lab->[0], $a, $b);
    my $s;
    if ($C < $C_mid) {
        my $k1 = $mid * $C_0;
        my $k2 = 1 - $k1 / $C_mid;
        my $t  = $C / ($k1 + $k2 * $C);
        $s = $t * $mid;
    }
    else {
        my $k0 = $C_mid;
        my $k1 = (1 - $mid) * $C_mid * $C_mid * $mid_inv * $mid_inv / $C_0;
        my $k2 = 1 - $k1 / ($C_max - $C_mid);
        my $t  = ($C - $k0) / ($k1 + $k2 * ($C - $k0));
        $s = $mid + (1 - $mid) * $t;
    }

    return [$h, $s, toe($lab->[0])];
}

Graphics::Toolkit::Color::Space->new(
         name => 'OKHSL',
       family => 'HSL',
         axis => [qw/hue saturation lightness/], 
         type => [qw/angular linear linear/],
        range => [360, 1, 1],
    precision => 5,
      convert => {LinearRGB => [\&from_hsl, \&to_hsl]},
);
