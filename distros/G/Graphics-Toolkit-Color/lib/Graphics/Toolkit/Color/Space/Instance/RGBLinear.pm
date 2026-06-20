
# linear standard (S)RGB, RGB with removed gamma

package Graphics::Toolkit::Color::Space::Instance::RGBLinear;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/spow/;

my $gamma = 2.4;

sub from_lrgb {
    my ($lrgb) = shift;
    return [ map { (abs($_) > 0.0031308) ? ((spow($_, 1/$gamma) *  1.055) - 0.055) 
		                                 :       ($_            * 12.92)          } @$lrgb ];
}
sub to_lrgb {
    my ($rgb) = shift;
    return [ map {  (abs($_) > 0.04045)  ? spow((($_ + 0.055) /  1.055 ), $gamma) 
		                                 :       ($_          / 12.92)           } @$rgb ];
}

Graphics::Toolkit::Color::Space->new(
         name => 'LinearRGB',
   alias_name => 'linRGB',
       family => 'RGB',  
         axis => [qw/red green blue/],
    precision => 6,
      convert => {RGB => [\&from_lrgb, \&to_lrgb]},
);
