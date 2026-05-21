
# Wide Gamut RGB, D50 (Adobe)

package Graphics::Toolkit::Color::Space::Instance::WideGamutRGB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/gamma_correct mult_matrix_vector_3/;

my @D50   = (0.96422, 1, 0.82521);
my @D65   = (0.95047, 1, 1.08883);
my $gamma = 563/256;

sub from_xyz {
    my ($xyz) = [ @{$_[0]} ];
    $xyz->[$_] *= $D65[ $_ ] for 0 .. 2;
    my @rgb = mult_matrix_vector_3( [[  1.5298411986, -0.1529595712, -0.2765432555 ],
                                     [ -0.5046114854,  1.4225435133,  0.0524182519 ],
                                     [  0.0218442230, -0.0757891912,  0.9689546693 ],  ], @$xyz);
    return [map {gamma_correct($_, (1/$gamma))} @rgb];
}
sub to_xyz {
	my $rgb = shift;
	$rgb = [map {gamma_correct($_, $gamma)} @$rgb];
    my @xyz = mult_matrix_vector_3( [[ 0.6783443412, 0.0830145686, 0.1891110902 ],
                                     [ 0.2404959276, 0.7303774055, 0.0291266669 ],
                                     [ 0.0035183140, 0.0552567894, 1.0300548966 ], ], @$rgb) ;
    $xyz[$_] /= $D65[ $_ ] for 0 .. 2;
    return \@xyz;
} 
 
Graphics::Toolkit::Color::Space->new(
        name => 'WideGamutRGB',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {XYZ => [\&to_xyz, \&from_xyz]},
);
