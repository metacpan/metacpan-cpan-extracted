
# CIEXYZ color space specific code for Illuminant D65 and Observer 2°

package Graphics::Toolkit::Color::Space::Instance::CIEXYZ;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix3 apply_d65 remove_d65/;

my @range_max = (0.95047, 1, 1.088830);
my  $xyz_def = Graphics::Toolkit::Color::Space->new( alias => 'CIEXYZ',
                                                      axis => [qw/X Y Z/],
                                                     range => [map {$range_max[$_] * 100} 0 .. 2],
                                                 precision => 3, );

    $xyz_def->add_converter('RGB', \&to_rgb, \&from_rgb );

sub from_rgb {
    my ($rgb) = shift;
    my @rgb = map {apply_d65( $_ )} @$rgb;
    return [ mult_matrix3([[0.433949941, 0.37620977,  0.18984029], # conversion + normalisation
                          [0.2126729,   0.7151522,   0.0721750],
                          [0.017756583, 0.109467961, 0.872775456]], @rgb) ];


}

sub to_rgb {
    my ($xyz) = shift;
    my @rgb = mult_matrix3([[  3.07996,   -1.53714 , -0.542816 ],
                            [ -0.921259 ,  1.87601 ,  0.0452475],
                            [  0.0528874, -0.204026,  1.15114  ]], @$xyz);
    return [ map { remove_d65($_) } @rgb ];
}

$xyz_def;

