
# CMYK color space specific code

package Graphics::Toolkit::Color::Space::Instance::CMYK;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space 'max';

sub from_rgb {
    my ($r, $g, $b) = @{$_[0]};
    my $km = max($r, $g, $b);
    return ([0,0,0,1]) unless $km; # prevent / 0
    return ( [($km - $r) / $km,
              ($km - $g) / $km,
              ($km - $b) / $km,
                 1 - $km ]
    );
}
sub to_rgb {
    my ($c, $m, $y, $k) = @{$_[0]};
    return ( [(1-$c) * (1-$k) ,
              (1-$m) * (1-$k) ,
              (1-$y) * (1-$k) ] );
}

Graphics::Toolkit::Color::Space->new (
       axis => [qw/cyan magenta yellow key/],
    convert => {RGB => [\&to_rgb, \&from_rgb]},

);
