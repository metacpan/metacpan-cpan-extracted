
# NCol color space (HWB with human readable hue values) / Karl Ewald Konstantin Hering (1834 - 1918)

package Graphics::Toolkit::Color::Space::Instance::NCol;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/min max/;

my $hsl_def = Graphics::Toolkit::Color::Space->new( name => 'NCol',
                                                    axis => [qw/hue whiteness blackness/],
                                                    type => [qw/angular linear linear/],
                                                   range => [600, 100, 100],  precision => 0,
                                              value_form => ['[RYGCBMrygcbm]\d{1,3}','\d{1,3}','\d{1,3}'],
                                                  suffix => ['', '%', '%'],
                                                  );

   $hsl_def->set_value_formatter( \&pre_value, \&post_value );
   $hsl_def->add_converter('RGB', \&to_rgb, \&from_rgb );

my @color_char = qw/R Y G C B M/;
my %char_value = (map { $color_char[$_] => $_ } 0 .. $#color_char);

sub pre_value {
    my $val = shift;
    my $hue = $char_value{ uc substr($val->[0], 0, 1) } * 100 + substr($val->[0], 1);
    return [$hue, $val->[1], $val->[2]];
}
sub post_value {
    my $val = shift;
    my $hue = ($val->[0] < 600) ? $val->[0] : 0;
    my $digit = int($hue / 100);
    my $hue_str = $color_char[ $digit ] . sprintf( "%u", ($hue - ($digit * 100)));
    return [$hue_str, $val->[1], $val->[2]];
}

sub from_rgb {
    my ($r, $g, $b) = @{$_[0]};
    my $vmax = max($r, $g, $b);
    my $white = my $vmin = min($r, $g, $b);
    return (0,1,0) if $white == 1;
    my $black = 1 - ($vmax);
    return (0,0,1) if $black == 1;

    my $d = $vmax - $vmin;
    my $s = $d / $vmax;
    my $h =     ($d == 0) ? 0 :
            ($vmax == $r) ? (($g - $b) / $d + ($g < $b ? 6 : 0)) :
            ($vmax == $g) ? (($b - $r) / $d + 2)
                          : (($r - $g) / $d + 4);
    return ($h/6, $white, $black);
}


sub to_rgb {
    my ($h, $w, $b) = @{$_[0]};
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

$hsl_def;
