
# OKHSL and OKHSV converter helper Copyright (c) 2021 Björn Ottosson, see LICENSE.OK

package Graphics::Toolkit::Color::Space::Instance::Helper::OK;
use v5.12;
use warnings;
use Exporter 'import';
use Graphics::Toolkit::Color::Space qw/min max spow mult_matrix_vector_3/;
our @EXPORT_OK = qw/toe toe_inv find_cusp to_ST get_Cs oklab_to_linear_srgb linear_srgb_to_oklab/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

my $toe_k1  = 0.206;
my $toe_k2  = 0.03;
my $toe_k3  = (1 + $toe_k1) / (1 + $toe_k2);

sub linear_srgb_to_oklab {
    my ($rgb) = @_;
    my @lms = mult_matrix_vector_3([[ 0.4122214708, 0.5363325363, 0.0514459929],
                                    [ 0.2119034982, 0.6806995451, 0.1073969566],
                                    [ 0.0883024619, 0.2817188376, 0.6299787005]], @$rgb);
    @lms = map {spow($_, (1/3))} @lms; 
    my @lab = mult_matrix_vector_3([[ 0.2104542553,  0.7936177850, -0.0040720468],
                                    [ 1.9779984951, -2.4285922050,  0.4505937099],
                                    [ 0.0259040371,  0.7827717662, -0.8086757660]], @lms);
	return \@lab;
}

sub oklab_to_linear_srgb {
    my ($lab) = @_;
    my @lms = mult_matrix_vector_3([[ 1,  0.3963377774,  0.2158037573],
                                    [ 1, -0.1055613458, -0.0638541728],
                                    [ 1, -0.0894841775, -1.2914855480]], @$lab);
    @lms = map {spow($_, 3)} @lms; 
    my @rgb = mult_matrix_vector_3([[  4.0767416621, -3.3077115913,  0.2309699292],
                                    [ -1.2684380046,  2.6097574011, -0.3413193965],
                                    [ -0.0041960863, -0.7034186147,  1.7076147010]], @lms);
	return \@rgb;
}

sub compute_max_saturation {
    my ($a, $b) = @_;  
    my (@k, @w);   # @k = Polynom-Koeffizienten, @w = oklab->lms Zeile fuer Halley
    if (-1.88170328 * $a - 0.80936493 * $b > 1) {          # Rot-Kanal zuerst
        @k = ( 1.19086277,  1.76576728,  0.59662641,  0.75515197,  0.56771245);
        @w = ( 4.0767416621, -3.3077115913, 0.2309699292);
    } elsif (1.81444104 * $a - 1.19445276 * $b > 1) {      # Gruen-Kanal zuerst
        @k = ( 0.73956515, -0.45954404,  0.08285427,  0.12541070,  0.14503204);
        @w = (-1.2684380046,  2.6097574011, -0.3413193965);
    } else {                                               # Blau-Kanal zuerst
        @k = ( 1.35733652, -0.00915799, -1.15130210, -0.50559606,  0.00692167);
        @w = (-0.0041960863, -0.7034186147, 1.7076147010);
    }

    # Stufe 1: Polynom-Schaetzung von S
    my $S = $k[0] + $k[1]*$a + $k[2]*$b + $k[3]*$a*$a + $k[4]*$a*$b;

    # Stufe 2: ein Halley-Schritt zur Verfeinerung
    my @k_lms = (0.3963377774 * $a + 0.2158037573 * $b, 
                -0.1055613458 * $a - 0.0638541728 * $b, 
                -0.0894841775 * $a - 1.2914855480 * $b);

    my @lms = map {1 + $S * $_} @k_lms;
	my @dS  = map {3 * $k_lms[$_] * $lms[$_]   * $lms[$_]} 0 .. 2;
	my @dS2 = map {6 * $k_lms[$_] * $k_lms[$_] * $lms[$_]} 0 .. 2;
    @lms    = map {spow($_, 3)} @lms;

    my $f  = $w[0]*$lms[0] + $w[1]*$lms[1] + $w[2]*$lms[2];
    my $f1 = $w[0]*$dS[0]  + $w[1]*$dS[1]  + $w[2]*$dS[2];
    my $f2 = $w[0]*$dS2[0] + $w[1]*$dS2[1] + $w[2]*$dS2[2];

    $S = $S - $f * $f1 / ($f1 * $f1 - 0.5 * $f * $f2);

    return $S;
}

sub find_cusp {
    my ($a, $b) = @_;                          # normalisiert: a**2 + b**2 == 1

    # buntester Punkt dieses Farbtons als Saettigung S = C/L
    my $S_cusp = compute_max_saturation($a, $b);

    # diese Oklab-Richtung nach linearem RGB, dann so skalieren,
    # dass der groesste Kanal genau 1 erreicht -> Gamut-Wand
    my $rgb = oklab_to_linear_srgb([1, $S_cusp * $a, $S_cusp * $b]);
    my $max_rgb = max(@$rgb);
    my $L_cusp = spow(1 / $max_rgb, 1/3);
    my $C_cusp = $L_cusp * $S_cusp;

    return ($L_cusp, $C_cusp);
}

sub get_ST_mid {
    my ($a, $b) = @_;                          # normalisiert: a**2 + b**2 == 1

    my $S = 0.11516993 + 1 / (
        + 7.44778970 + 4.15901240 * $b
        + $a * (-2.19557347 +  1.75198401 * $b
        + $a * (-2.13704948 - 10.02301043 * $b
        + $a * (-4.24894561 +  5.38770819 * $b + 4.69891013 * $a))));

    my $T = 0.11239642 + 1 / (
        + 1.61320320 - 0.68124379 * $b
        + $a * ( 0.40370612 + 0.90148123 * $b
        + $a * (-0.27087943 + 0.61223990 * $b
        + $a * ( 0.00299215 - 0.45399568 * $b - 0.14661872 * $a))));

    return ($S, $T);
}

sub to_ST {
    my ($L, $C) = @_;
    return ($C / $L, $C / (1 - $L));
}

sub find_gamut_intersection {
    my ($a, $b, $L1, $C1, $L0, $cusp_L, $cusp_C) = @_;
    my $t;

    if (($L1 - $L0) * $cusp_C - ($cusp_L - $L0) * $C1 <= 0) {
        # unterer (gerader) Schenkel: direkter Schnitt, keine Verfeinerung noetig
        $t = $cusp_C * $L0 / ($C1 * $cusp_L + $cusp_C * ($L0 - $L1));
    } else {
        # oberer (gekruemmter) Schenkel: erst grober Dreiecks-Schnitt ...
        $t = $cusp_C * ($L0 - 1) / ($C1 * ($cusp_L - 1) + $cusp_C * ($L0 - $L1));

        # ... dann ein Halley-Schritt auf den echten Gamutrand
        my $dL = $L1 - $L0;
        my $dC = $C1;
        my @k_lms = ( 0.3963377774 * $a + 0.2158037573 * $b,
                     -0.1055613458 * $a - 0.0638541728 * $b,
                     -0.0894841775 * $a - 1.2914855480 * $b);

        my @lms_dt = map { $dL + $dC * $_ } @k_lms;
        my $L = $L0 * (1 - $t) + $t * $L1;
        my $C = $t * $C1;
        my @lms  = map { $L + $C * $_ } @k_lms;                      # l_, m_, s_
        my @ldt  = map { 3 * $lms_dt[$_] * $lms[$_]    * $lms[$_] } 0 .. 2;
        my @ldt2 = map { 6 * $lms_dt[$_] * $lms_dt[$_] * $lms[$_] } 0 .. 2;
        @lms     = map { $_ * $_ * $_ } @lms;                        # kubiert

        # Matrix = oklab_to_linear_srgb (LMS -> linear sRGB), Rand bei Kanal == 1
        my $M = [[ 4.0767416621, -3.3077115913,  0.2309699292],
                 [-1.2684380046,  2.6097574011, -0.3413193965],
                 [-0.0041960863, -0.7034186147,  1.7076147010]];

        my @res  = map { $_ - 1 } mult_matrix_vector_3($M, @lms);
        my @res1 =                mult_matrix_vector_3($M, @ldt);
        my @res2 =                mult_matrix_vector_3($M, @ldt2);
        my $huge = 9**9**9;                                      # ersetzt FLT_MAX
        my @t_ch = map {
            my $u = $res1[$_] / ($res1[$_] * $res1[$_] - 0.5 * $res[$_] * $res2[$_]);
            $u >= 0 ? -$res[$_] * $u : $huge;
        } 0 .. 2;

        $t += min(@t_ch);
    }
    return $t;
}


sub get_Cs { # Chroma min mid max
    my ($L, $a, $b) = @_;                      # a, b normalisiert

    my ($L_cusp, $C_cusp) = find_cusp($a, $b);

    # C_max: exakter Gamutrand bei dieser Helligkeit
    my $C_max = find_gamut_intersection($a, $b, $L, 1, $L, $L_cusp, $C_cusp);

    # Cusp als Steigungen S = C/L (von Schwarz) und T = C/(1-L) (von Weiss)
    my ($S_max, $T_max) = to_ST($L_cusp, $C_cusp);

    # Skalierung der gekruemmten Gamut-Form
    my $k = $C_max / min($L * $S_max, (1 - $L) * $T_max);

    # C_mid: glatte mittlere Chroma aus der genaeherten Cusp-Lage
    my ($S_mid, $T_mid) = get_ST_mid($a, $b);
    my $C_a = $L * $S_mid;
    my $C_b = (1 - $L) * $T_mid;
    my $C_mid = 0.9 * $k * spow(1 / (1/$C_a**4 + 1/$C_b**4), 1/4);

    # C_0: innere Referenz, hue-unabhaengige Anker
    $C_a = $L * 0.4;
    $C_b = (1 - $L) * 0.8;
    my $C_0 = spow(1 / (1/$C_a**2 + 1/$C_b**2), 1/2);

    return ($C_0, $C_mid, $C_max);
}

sub toe { # korrigiert die Helligkeit
    my ($L) = @_;
    return 0.5 * ($toe_k3 * $L - $toe_k1
        + spow(($toe_k3 * $L - $toe_k1)**2 + 4 * $toe_k2 * $toe_k3 * $L, 1/2));
}

sub toe_inv {
    my ($L) = @_;
    return ($L*$L + $toe_k1 * $L) / ($toe_k3 * ($L + $toe_k2));
}


1;

__END__

linear_srgb_to_okhsl
├── linear_srgb_to_oklab      (fusionierte Björn-Matrix, roh — neu, siehe unten)
├── get_Cs
│   ├── find_cusp
│   │   ├── compute_max_saturation
│   │   └── oklab_to_linear_srgb   (fusionierte Björn-Inverse — neu, siehe unten)
│   ├── find_gamut_intersection
│   ├── to_ST
│   └── get_ST_mid
└── toe

okhsl_to_linear_srgb
├── toe_inv
├── get_Cs                     (identisch zum Hinweg)
│   ├── find_cusp
│   │   ├── compute_max_saturation
│   │   └── oklab_to_linear_srgb
│   ├── find_gamut_intersection
│   ├── to_ST
│   └── get_ST_mid
└── oklab_to_linear_srgb       (am Ende, fuer die finale Rueckwandlung)
