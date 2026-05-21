
# Display P3, D65, linear (no transfer)

package Graphics::Toolkit::Color::Space::Instance::DisplayP3Linear;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix_vector_3/;

my @D65 = (0.9504559271, 1, 1.0890577508);

sub from_xyz {
    my ($xyz) = shift;
    $xyz->[$_] *= $D65[ $_ ] for 0 .. 2;
    return [ mult_matrix_vector_3( [[  2.4934969119, -0.9313836179, -0.4027107845 ],
                                    [ -0.8294889696,  1.7626640603,  0.0236246858 ], 
                                    [  0.0358458302, -0.0761723893,  0.9568845240 ], ], @$xyz) ];
}
sub to_xyz {
	my ($lrgb) = shift;
    my @xyz = mult_matrix_vector_3([[ 0.4865709486, 0.2656676932, 0.1982172852 ],
                                    [ 0.2289745641, 0.6917385218, 0.0792869141 ],
                                    [ 0.0000000000, 0.0451133819, 1.0439443689 ], ], @$lrgb);
    $xyz[$_] /= $D65[ $_ ] for 0 .. 2;
    return \@xyz;
}
 
Graphics::Toolkit::Color::Space->new(
        name => 'display-p3-linear',
       alias => 'Linear Display P3',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {XYZ => [\&to_xyz, \&from_xyz]},
);
