
# Apple RGB 1998 (illuminant D65, gamma 1.8)

package Graphics::Toolkit::Color::Space::Instance::AppleRGB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/spow mult_matrix_vector_3/;

my @D65   = (.95047, 1, 1.08883);
my $gamma = 1.8;

sub from_rgb {
	my $rgb = shift;
	$rgb = [map {spow($_, $gamma)} @$rgb];
    my @xyz = mult_matrix_vector_3( [[ 0.4497288,  0.3162486,  0.1844926 ],
                                     [ 0.2446525,  0.6720283,  0.0833192 ],
                                     [ 0.0251848,  0.1411824,  0.9224628 ] ], @$rgb);
    $xyz[$_] /= $D65[ $_ ] for 0 .. 2;
    return \@xyz;
}
sub to_rgb {
    my ($xyz) = [ @{$_[0]} ];
    $xyz->[$_] *= $D65[ $_ ] for 0 .. 2;
    my @rgb = mult_matrix_vector_3( [[  2.9515373, -1.2894116, -0.4738445 ],
                                     [ -1.0851093,  1.9908566,  0.0372026 ], 
                                     [  0.0854934, -0.2694964,  1.0912975 ]  ], @$xyz);
    return [map {spow($_, 1 / $gamma)} @rgb];
}
 
Graphics::Toolkit::Color::Space->new(
        name => 'AppleRGB',
      family => 'RGB',  
        axis => [qw/red green blue/],
   precision => 6,
     convert => {XYZ => [\&from_rgb, \&to_rgb]},
);
