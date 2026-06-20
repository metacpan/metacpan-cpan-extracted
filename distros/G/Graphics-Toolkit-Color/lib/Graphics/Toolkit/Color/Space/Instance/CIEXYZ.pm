
# CIEXYZ color space specific code for Illuminant D65 and Observer 2°

package Graphics::Toolkit::Color::Space::Instance::CIEXYZ;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix_vector_3/;

sub from_xyz {
	my @xyz = map { $_ / 100 } @{$_[0]};
    return [ mult_matrix_vector_3( [[  3.2404542361, -1.5371385128, -0.4985314095 ],
                                    [ -0.9692660305,  1.8760108456,  0.0415560173 ],
                                    [  0.0556434224, -0.2040258530,  1.0572251881 ] ], @xyz) ];
}
sub to_xyz {
    my @xyz = mult_matrix_vector_3( [[ 0.41245643909,  0.3575760776,  0.1804374833 ],
                                     [ 0.21267285141,  0.7151521858,  0.0721750628 ],
                                     [ 0.01933389558,  0.1191920257,  0.9503040785 ] ], @{$_[0]});
    return [map {$_ * 100} @xyz];
}

Graphics::Toolkit::Color::Space->new(
     alias_name => 'CIEXYZ',  # name is XYZ
         family => 'RGB',
           axis => [qw/X Y Z/],
           role => [qw/red green blue/],
          range => [95.047, 100, 108.883],
      precision => 3,
        convert => {LinearRGB => [\&from_xyz, \&to_xyz, {from => {in => 1}, to => {out => 1}} ] }, # flags are from and to lrgb
);
