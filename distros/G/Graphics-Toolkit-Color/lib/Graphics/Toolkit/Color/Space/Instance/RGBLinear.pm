
# linear standard (S)RGB, RGB with removed gamma

package Graphics::Toolkit::Color::Space::Instance::RGBLinear;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/gamma_correct/;

my $gamma = 2.4;

sub from_rgb {
    my ($rgb) = shift;
    return [ map {  (abs($_) > 0.04045)  ? gamma_correct((($_ + 0.055) /  1.055 ), $gamma) 
		                                 :                ($_          / 12.92)           } @$rgb ];
}
sub to_rgb {
    my ($lrgb) = shift;
    return [ map { (abs($_) > 0.0031308) ? ((gamma_correct($_, 1/$gamma) *  1.055) - 0.055) 
		                                 :                ($_            * 12.92)          } @$lrgb ];
}

Graphics::Toolkit::Color::Space->new(
        name => 'LinearRGB',
       alias => 'linRGB',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {RGB => [\&to_rgb, \&from_rgb]},
);
