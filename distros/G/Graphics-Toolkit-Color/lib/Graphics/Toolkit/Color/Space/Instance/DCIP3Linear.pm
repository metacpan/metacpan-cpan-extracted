
# DCI-P3, with original Theater-Whitepoint [0.89459, 1.0, 0.95442]

package Graphics::Toolkit::Color::Space::Instance::DCIP3Linear;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix_vector_3/;

my @D65 = (0.95047, 1, 1.08883);

sub from_xyz {
    my ($xyz) = shift;
    $xyz->[$_] *= $D65[ $_ ] for 0 .. 2;
    return [ mult_matrix_vector_3( [[  2.6901363967, -1.0940624767, -0.4250723022 ],
                                    [ -0.8200938994,  1.7505139921,  0.0265979630 ], 
                                    [  0.0362539300, -0.0785946720,  0.9589526318 ], ], @$xyz) ];
}
sub to_xyz {
	my ($lrgb) = shift;
    my @xyz = mult_matrix_vector_3([[ 0.4592758400,  0.2958171474,  0.1953770175 ],
                                    [ 0.2151608649,  0.7091342514,  0.0757048839 ],
                                    [ 0.0002710702,  0.0469362492,  1.0416226857 ], ], @$lrgb);
    $xyz[$_] /= $D65[ $_ ] for 0 .. 2;
    return \@xyz;
}

 
Graphics::Toolkit::Color::Space->new(
        name => 'dci-p3-linear',
       alias => 'Linear DCI-P3',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {XYZ => [\&to_xyz, \&from_xyz]},
);
