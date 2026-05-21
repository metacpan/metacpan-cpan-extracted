
# DCI-P3, 

package Graphics::Toolkit::Color::Space::Instance::DCIP3;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/gamma_correct/;

my $gamma = 2.6;

sub from_dcip3l {
    my ($lrgb) = shift;
    return [ map { (abs($_) > 0.0031308) ? ( (gamma_correct($_, 1/$gamma) *  1.055) - 0.055) 
		                                 :                 ($_            * 12.92)          } @$lrgb ];
}
sub to_dcip3l {
	my ($rgb) = shift;
	return [ map { (abs($_) > 0.04045) ? gamma_correct((($_ + 0.055) /  1.055 ), $gamma) 
                                       :                ($_          / 12.92)           } @$rgb ];
}
 
Graphics::Toolkit::Color::Space->new(
        name => 'DCI-P3',
       alias => 'SMPTE P3',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {'dci-p3-linear' => [\&to_dcip3l, \&from_dcip3l]},
);
