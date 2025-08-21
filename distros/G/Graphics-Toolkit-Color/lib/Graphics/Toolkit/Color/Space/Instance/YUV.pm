
# YUV color space specific code as in BT.601

package Graphics::Toolkit::Color::Space::Instance::YUV;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix3/;

                                                      # luma, cyan-orange balance, magenta-green balance
my  $yuv_def = Graphics::Toolkit::Color::Space->new( axis  => [qw/luma Pb Pr/], alias => 'YPbPr',
                                                     short => [qw/Y U V/],
                                                     range => [1, [-.5, .5], [-.5, .5],] );

    $yuv_def->add_converter('RGB', \&to_rgb, \&from_rgb );

sub from_rgb {
    my ($rgb) = shift;
    my (@yuv) =  mult_matrix3([[ 0.299   ,  0.587,     0.114    ],
                               [-0.168736, -0.331264,  0.5      ],
                               [ 0.5     , -0.418688, -0.081312 ]], @$rgb);
    $yuv[1] += 0.5;
    $yuv[2] += 0.5;
    return \@yuv;
}


sub to_rgb {
    my ($yuv) = shift;
    $yuv->[1] -= 0.5;
    $yuv->[2] -= 0.5;
    my (@rgb) =  mult_matrix3([[ 1,  0       ,  1.402   ],
                               [ 1, -0.344136, -0.714136],
                               [ 1,  1.772   ,  0       ]], @$yuv);
    return \@rgb;
}

$yuv_def;

