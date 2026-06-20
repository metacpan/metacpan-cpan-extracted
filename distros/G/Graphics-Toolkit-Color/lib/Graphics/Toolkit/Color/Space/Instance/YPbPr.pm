
# YUV color space specific code as in BT.601

package Graphics::Toolkit::Color::Space::Instance::YPbPr;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix_vector_3/;

sub from_ypp {
    my ($ypp) = shift;
    $ypp->[1] -= 0.5;
    $ypp->[2] -= 0.5;
    my (@rgb) =  mult_matrix_vector_3([[ 1,  0       ,  1.402   ],
                                       [ 1, -0.344136, -0.714136],
                                       [ 1,  1.772   ,  0       ]], @$ypp);
    return \@rgb;
}
sub to_ypp {
    my ($rgb) = shift;
    my (@ypp) =  mult_matrix_vector_3([[ 0.299   ,  0.587,     0.114    ],
                                       [-0.168736, -0.331264,  0.5      ],
                                       [ 0.5     , -0.418688, -0.081312 ]], @$rgb);
    $ypp[1] += 0.5;
    $ypp[2] += 0.5;
    return \@ypp;
}
Graphics::Toolkit::Color::Space->new(
         name => 'YPbPr',
   alias_name => 'YUV',
       family => 'LAB',   
        axis  => [qw/luma Pb Pr/], # luma, cyan-orange balance, magenta-green balance
       short  => [qw/y u v/],
         role => [qw/l a b/], 
        range => [1, [-.5, .5], [-.5, .5],],
      convert => {RGB => [\&from_ypp, \&to_ypp]},
);
