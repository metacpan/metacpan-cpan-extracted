
# Rec.709  illuminant D65, 2° standard observer

package Graphics::Toolkit::Color::Space::Instance::Rec709;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/gamma_correct/;

sub from_lrgb {
	my $lrgb = shift;
    return [ map {(abs($_) < 0.018) ? ($_ * 4.5) : ((gamma_correct($_, 0.45) *  1.099) - 0.099)} @$lrgb];
}
sub to_lrgb {
	my $rgb = shift;
	return [ map {(abs($_) < 0.081) ? ($_ / 4.5) : gamma_correct(($_ + 0.099) / 1.099, 1 / 0.45)} @$rgb];

}
 
Graphics::Toolkit::Color::Space->new(
        name => 'Rec.709',
       alias => 'BT.709',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {LinearRGB => [\&to_lrgb, \&from_lrgb]},
);
