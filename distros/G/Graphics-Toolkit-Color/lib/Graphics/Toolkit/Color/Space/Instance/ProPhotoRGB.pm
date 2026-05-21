
# Pro Photo RGB (illuminant D50, gamma 1.8)

package Graphics::Toolkit::Color::Space::Instance::ProPhotoRGB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/gamma_correct mult_matrix_vector_3/;

my @D50   = (0.96422, 1, 0.82521);
my @D65   = (0.95047, 1, 1.08883);
my $eta   =  0.001953;
my $gamma =  1.8;

sub from_xyz {
    my ($xyz) = [ @{$_[0]} ];
    $xyz->[$_] *= $D65[ $_ ] for 0 .. 2;
    my @rgb = mult_matrix_vector_3( [[  1.4032152559, -0.2231400792, -0.1015529925 ],
                                     [ -0.5262716028,  1.4816610921,  0.0170313058 ],
                                     [ -0.0111904728,  0.0182300474,  0.9114427432 ],  ], @$xyz);

    return [map { (abs($_) <= $eta) ? ($_ * 16) : gamma_correct($_, 1 / $gamma)} @rgb];
}
sub to_xyz {
	my @rgb = map { (abs($_) <= 16 * $eta) ? ($_ / 16) : gamma_correct( $_, $gamma ) } @{$_[0]};

    my @xyz = mult_matrix_vector_3( [[ 0.7556032668,  0.1127849127, 0.0820818412 ],
                                     [ 0.2683379836,  0.7151267757, 0.0165353036 ],
                                     [ 0.0039100028, -0.0129187254, 1.0978386769 ], ], @rgb);
    $xyz[$_] /= $D65[ $_ ] for 0 .. 2;
    return \@xyz;
}

Graphics::Toolkit::Color::Space->new(
        name => 'ProPhotoRGB',
       alias => 'ROMMRGB',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {XYZ => [\&to_xyz, \&from_xyz]},
);
