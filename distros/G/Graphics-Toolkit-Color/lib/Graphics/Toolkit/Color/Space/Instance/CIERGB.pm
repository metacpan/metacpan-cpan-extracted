
# CIE 1931 RGB (linear with illuminant E)

package Graphics::Toolkit::Color::Space::Instance::CIERGB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix_vector_3/;

sub from_xyz {
    [ mult_matrix_vector_3( [[  2.3706743, -0.9000405, -0.4706338 ],
                             [ -0.5138850,  1.4253036,  0.0885814 ], 
                             [  0.0052982, -0.0146949,  1.0093968 ]  ], @{$_[0]}) ];
}
sub to_xyz {
    [ mult_matrix_vector_3( [[ 0.4887180,  0.3106803,  0.2006017 ],
                             [ 0.1762044,  0.8129847,  0.0108109 ],
                             [ 0.0000000,  0.0102048,  0.9897952 ] ], @{$_[0]}) ];
}

Graphics::Toolkit::Color::Space->new(
        name => 'CIERGB',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {XYZ => [\&to_xyz, \&from_xyz]},
);
