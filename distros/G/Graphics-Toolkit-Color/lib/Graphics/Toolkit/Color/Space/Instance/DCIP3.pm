
# DCI-P3, 

package Graphics::Toolkit::Color::Space::Instance::DCIP3;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/spow/;

my $gamma = 2.6;

sub from_dcip3 {
	my ($rgb) = shift;
	return [ map { (abs($_) > 0.04045) ? spow((($_ + 0.055) /  1.055 ), $gamma) 
                                       :       ($_          / 12.92)           } @$rgb ];
}
sub to_dcip3 {
    my ($lrgb) = shift;
    return [ map { (abs($_) > 0.0031308) ? ((spow($_, 1/$gamma) *  1.055) - 0.055) 
		                                 :       ($_            * 12.92)          } @$lrgb ];
}
 
Graphics::Toolkit::Color::Space->new(
           name => 'DCI-P3',
     alias_name => 'SMPTE P3',
         family => 'RGB',
           axis => [qw/red green blue/],
      precision => 6,
        convert => {'dci-p3-linear' => [\&from_dcip3, \&to_dcip3]},
);
