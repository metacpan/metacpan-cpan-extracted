
# Adobe RGB (1998) color space, D65 IEC 61966-2-5:2007, ISO 12640-4:2011

package Graphics::Toolkit::Color::Space::Instance::AdobeRGB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/spow mult_matrix_vector_3/;

my @D65   = (.95047, 1, 1.08883);
my $gamma = 563/256;

sub from_rgb {
	my $rgb = shift;
	$rgb = [map {spow($_, $gamma)} @$rgb];
    my @xyz = mult_matrix_vector_3( [[ 0.5767309,  0.1855540,  0.1881852 ],
                                     [ 0.2973769,  0.6273491,  0.0752741 ],
                                     [ 0.0270343,  0.0706872,  0.9911085 ] ], @$rgb);
    $xyz[$_] /= $D65[ $_ ] for 0 .. 2;
    return \@xyz;
} 
sub to_rgb {
    my ($xyz) = [ @{$_[0]} ];
    $xyz->[$_] *= $D65[ $_ ] for 0 .. 2;
    my @rgb = mult_matrix_vector_3( [[  2.0413690, -0.5649464, -0.3446944 ],
                                     [ -0.9692660,  1.8760108,  0.0415560 ], 
                                     [  0.0134474, -0.1183897,  1.0154096 ]  ], @$xyz);
    return [map {spow($_, 1 / $gamma)} @rgb];
}
 
Graphics::Toolkit::Color::Space->new(
        name => 'AdobeRGB',
  alias_name => 'opRGB',
      family => 'RGB',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {CIEXYZ => [\&from_rgb, \&to_rgb]},
);
