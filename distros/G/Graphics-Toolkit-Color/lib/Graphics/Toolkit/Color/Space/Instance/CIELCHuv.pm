
# CIE LCh(uv) cylindrical color space variant of CIELUV

package Graphics::Toolkit::Color::Space::Instance::CIELCHuv;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/round_decimals/;

my $TAU = 6.283185307;

sub from_lch {
    my ($lch) = shift;
    my $u = $lch->[1] * cos($lch->[2] * $TAU) * 261;
    my $v = $lch->[1] * sin($lch->[2] * $TAU) * 261;
    return ([$lch->[0], ($u+134) / 354, ($v+140) / 262 ]);
}
sub to_lch {
    my ($luv) = shift;
    my $u = $luv->[1] *  354 - 134;
    my $v = $luv->[2] *  262 - 140;
    $u = 0 if round_decimals($u, 5) == 0;
    $v = 0 if round_decimals($v, 5) == 0;
    my $c = sqrt( ($u**2) + ($v**2));
    my $h = atan2($v, $u);
    $h += $TAU if $h < 0;
    return ([$luv->[0], $c / 261, $h / $TAU ]);
}

Graphics::Toolkit::Color::Space->new(
           name => 'CIELCHuv',
     alias_name => 'LCHuv',
         family => 'HSL',
           axis => [qw/luminance chroma hue/],
           role => [qw/lightness saturation hue/],
           type => [qw/linear linear angular/],
          range => [100, 261, 360],
      precision => 3,
        convert => {LUV => [\&from_lch, \&to_lch]},
);
