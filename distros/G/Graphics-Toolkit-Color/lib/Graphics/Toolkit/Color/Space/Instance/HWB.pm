use v5.12;
use warnings;

# HWB color space specific code

package Graphics::Toolkit::Color::Space::Instance::HWB;
use Graphics::Toolkit::Color::Space::Util ':all';
use Graphics::Toolkit::Color::Space;

my $hwb_def = Graphics::Toolkit::Color::Space->new( axis => [qw/hue whiteness blackness/],
                                                   range => [360, 100, 100],
                                                    type => [qw/angle linear linear/]);

   $hwb_def->add_converter('RGB', \&to_rgb, \&from_rgb );


sub from_rgb {
    my ($r, $g, $b) = @_;
    my $vmax = max($r, $g, $b);
    my $white = my $vmin = min($r, $g, $b);
    my $black = 1 - ($vmax);

    my $d = $vmax - $vmin;
    my $s = $d / $vmax;
    my $h =     ($d == 0) ? 0 :
            ($vmax == $r) ? (($g - $b) / $d + ($g < $b ? 6 : 0)) :
            ($vmax == $g) ? (($b - $r) / $d + 2)
                          : (($r - $g) / $d + 4);
    return ($h/6, $white, $black);
}


sub to_rgb {
    my ($h, $w, $b) = @_;
    return (0, 0, 0) if $b == 1;
    return (1, 1, 1) if $w == 1;
    my $v = 1 - $b;
    my $s = 1 - ($w / $v);
    $s = 0 if $s < 0;
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

$hwb_def;
