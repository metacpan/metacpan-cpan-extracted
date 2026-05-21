
# Rec.2020 slightly improved Rec.709

package Graphics::Toolkit::Color::Space::Instance::Rec2020;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/gamma_correct/;


my $alpha = 1.09929682680944;
my $beta  = 0.018053968510807; # 0.0180 - Rec709
my $lin_factor = 4.5;
my $beta_inv  = $lin_factor * $beta;
my $gamma = 0.45;

sub from_lrgb {
	my $lrgb = shift;
    return [ map {(abs($_) <= $beta) ? ($_ * $lin_factor) 
		                             : ((gamma_correct($_, $gamma) *  $alpha) - $alpha + 1)} @$lrgb];
}
sub to_lrgb {
	my $rgb = shift;
	return [ map {(abs($_) <= $beta_inv) ? ($_ / $lin_factor) 
		                                 : gamma_correct(($_ + $alpha - 1) / $alpha, 1 / $gamma)} @$rgb];
}
 
Graphics::Toolkit::Color::Space->new(
        name => 'Rec.2020',
       alias => 'BT.2020',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {LinearRGB => [\&to_lrgb, \&from_lrgb]},
);

# .001,.1,.999
