
# HSL color space specific code

package Graphics::Toolkit::Color::Space::Instance::HSL;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/min max real_mod/;

my $hsl_def = Graphics::Toolkit::Color::Space->new( axis => [qw/hue saturation lightness/],
                                                   range => [ 360, 100, 100 ],  precision => 0,
                                                    type => [qw/angular linear linear/],
                                                 # suffix => ['', '%', '%'],
                                                  );

   $hsl_def->add_converter('RGB', \&to_rgb, \&from_rgb );


sub from_rgb {
    my ($r, $g, $b) = @{$_[0]};
    my $vmax = max($r, $g, $b),
    my $vmin = min($r, $g, $b);
    my $l = ($vmax + $vmin) / 2;
    return ([0, 0, $l]) if $vmax == $vmin;
    my $d = $vmax - $vmin;
    my $s = ($l > 0.5) ? ($d / (2 - $vmax - $vmin)) : ($d / ($vmax + $vmin));
    my $h = ($vmax == $r) ? (($g - $b) / $d + ($g < $b ? 6 : 0)) :
            ($vmax == $g) ? (($b - $r) / $d + 2)
                          : (($r - $g) / $d + 4);
    return ([$h/6, $s, $l]);
}

sub to_rgb {
    my ($h, $s, $l) = @{$_[0]};
    $h *= 6;
    my $C = $s * (1 - abs($l * 2 - 1));
    my $X = $C * (1 - abs( real_mod($h, 2) - 1) );
    my $m = $l - ($C / 2);
    my @rgb = ($h < 1) ? ($C + $m, $X + $m,      $m)
            : ($h < 2) ? ($X + $m, $C + $m,      $m)
            : ($h < 3) ? (     $m, $C + $m, $X + $m)
            : ($h < 4) ? (     $m, $X + $m, $C + $m)
            : ($h < 5) ? ($X + $m,      $m, $C + $m)
            :            ($C + $m,      $m, $X + $m);
    return \@rgb;
}

$hsl_def;
