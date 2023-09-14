use v5.12;
use warnings;

# HSV color space specific code

package Graphics::Toolkit::Color::Space::Instance::HSV;
use Graphics::Toolkit::Color::Space::Util ':all';
use Graphics::Toolkit::Color::Space;

my $hsv_def = Graphics::Toolkit::Color::Space->new( axis => [qw/hue saturation value/],
                                                   range => [360, 100, 100],
                                                    type => [qw/angle linear linear/]);

   $hsv_def->add_converter('RGB', \&to_rgb, \&from_rgb );


sub from_rgb {
    my ($r, $g, $b) = @_;
    my $vmin = min($r, $g, $b);
    my $v = my $vmax = max($r, $g, $b);
    return (0, 0, $v) if $vmax == $vmin;

    my $d = $vmax - $vmin;
    my $s = $d / $vmax;
    my $h = ($vmax == $r) ? (($g - $b) / $d + ($g < $b ? 6 : 0)) :
            ($vmax == $g) ? (($b - $r) / $d + 2)
                          : (($r - $g) / $d + 4);
    return ($h/6, $s, $v);
}

sub to_rgb {
    my ($h, $s, $v) = @_;
    return ($v, $v, $v) if $s == 0;
    my $hi = int( $h * 6 );
    my $f = ( $h * 6 ) - $hi;
    my $p = $v * (1 -  $s );
    my $q = $v * (1 - ($s * $f));
    my $t = $v * (1 - ($s * (1 - $f)));
    my @rgb = ($hi == 1) ? ($q, $v, $p)
            : ($hi == 2) ? ($p, $v, $t)
            : ($hi == 3) ? ($p, $q, $v)
            : ($hi == 4) ? ($t, $p, $v)
            : ($hi == 5) ? ($v, $p, $q)
            :              ($v, $t, $p);
}

$hsv_def;
