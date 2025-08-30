
# HSB color space specific code

package Graphics::Toolkit::Color::Space::Instance::HSB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/min max/;

sub from_rgb {
    my ($r, $g, $b) = @{$_[0]};
    my $vmin = min($r, $g, $b);
    my $br = my $vmax = max($r, $g, $b);
    return ([0, 0, $br]) if $vmax == $vmin;

    my $d = $vmax - $vmin;
    my $s = $d / $vmax;
    my $h = ($vmax == $r) ? (($g - $b) / $d + ($g < $b ? 6 : 0)) :
            ($vmax == $g) ? (($b - $r) / $d + 2)
                          : (($r - $g) / $d + 4);
    return ([$h/6, $s, $br]);
}
sub to_rgb {
    my ($h, $s, $b) = @{$_[0]};
    return ([$b, $b, $b]) if $s == 0;
    my $hi = int( $h * 6 );
    my $f = ( $h * 6 ) - $hi;
    my $p = $b * (1 -  $s );
    my $q = $b * (1 - ($s * $f));
    my $t = $b * (1 - ($s * (1 - $f)));
    my @rgb = ($hi == 1) ? ($q, $b, $p)
            : ($hi == 2) ? ($p, $b, $t)
            : ($hi == 3) ? ($p, $q, $b)
            : ($hi == 4) ? ($t, $p, $b)
            : ($hi == 5) ? ($b, $p, $q)
            :              ($b, $t, $p);
    return \@rgb;
}

Graphics::Toolkit::Color::Space->new (
            axis => [qw/hue saturation brightness/],
           range => [360, 100, 100],
       precision => 0,
            type => [qw/angular linear linear/],
          suffix => ['', '%', '%'],
         convert => {RGB => [\&to_rgb, \&from_rgb]},
);
