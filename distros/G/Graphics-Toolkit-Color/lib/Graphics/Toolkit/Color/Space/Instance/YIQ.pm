
# YIQ color space specific code

package Graphics::Toolkit::Color::Space::Instance::YIQ;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix3/;

my ($i_max, $q_max)   = (0.5959, 0.5227);
my ($i_range_size, $q_range_size) = (2 * $i_max, 2 * $q_max);
                                                                    # cyan-orange balance, magenta-green balance
my  $yiq_def = Graphics::Toolkit::Color::Space->new( axis  => [qw/luminance in_phase quadrature/],
                                                     short => [qw/Y I Q/],
                                                     range => [1, [-$i_max, $i_max], [-$q_max, $q_max]] );

    $yiq_def->add_converter('RGB', \&to_rgb, \&from_rgb );

sub from_rgb {
    my ($rgb) = shift;
    my ($y, $i, $q) = mult_matrix3([[0.299,   0.587,   0.114 ],
                                    [0.5959, -0.2746, -0.3213],
                                    [0.2115, -0.5227,  0.3112]], @$rgb);
    $i = ($i + $i_max) / $i_range_size;
    $q = ($q + $q_max) / $q_range_size;
    return ($y, $i, $q);
}



sub to_rgb {
    my ($yiq) = shift;
    $yiq->[1] = $yiq->[1] * $i_range_size - $i_max;
    $yiq->[2] = $yiq->[2] * $q_range_size - $q_max;
    return mult_matrix3([[1,   0.95605,   0.620755],
                         [1,  -0.272052, -0.647206],
                         [1,  -1.1067,    1.70442 ]], @$yiq);
}

$yiq_def;
