
# Display P3, D65 same transfer function as SRGB

package Graphics::Toolkit::Color::Space::Instance::DisplayP3;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/spow/;

my $gamma = 2.4;

sub from_p3 {
	my ($rgb) = shift;
	return [ map { (abs($_) > 0.04045)  ? spow((($_ + 0.055) /  1.055 ), $gamma) 
                                        :       ($_          / 12.92)           } @$rgb ];
}
sub to_p3 {
    my ($lrgb) = shift;
    return [ map { (abs($_) > 0.0031308) ? ( (spow($_, 1/$gamma) *  1.055) - 0.055) 
		                                 :        ($_            * 12.92)          } @$lrgb ];
}
 
Graphics::Toolkit::Color::Space->new(
           name => 'display-p3',
     alias_name => 'P3',
         family => 'RGB',
           axis => [qw/red green blue/],
      precision => 6,
        convert => {'Display-P3-Linear' => [\&from_p3, \&to_p3]},
);
