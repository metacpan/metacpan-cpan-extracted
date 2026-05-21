
# Display P3, D65 same transfer function as SRGB

package Graphics::Toolkit::Color::Space::Instance::DisplayP3;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/gamma_correct/;

my $gamma = 2.4;

sub from_dp3l {
    my ($lrgb) = shift;
    return [ map { (abs($_) > 0.0031308) ? ( (gamma_correct($_, 1/$gamma) *  1.055) - 0.055) 
		                                 :                 ($_            * 12.92)          } @$lrgb ];
}
sub to_dp3l {
	my ($rgb) = shift;
	return [ map { (abs($_) > 0.04045)  ? gamma_correct((($_ + 0.055) /  1.055 ), $gamma) 
                                        :                ($_          / 12.92)           } @$rgb ];
}
 
Graphics::Toolkit::Color::Space->new(
        name => 'display-p3',
       alias => 'P3',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {'Display-P3-Linear' => [\&to_dp3l, \&from_dp3l]},
);
