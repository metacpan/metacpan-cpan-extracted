
# OK lab color space for Illuminant D65 and Observer 2 degree by Björn Ottosson 2020

package Graphics::Toolkit::Color::Space::Instance::OKLAB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix3/;

my @D65 = (0.95047, 1, 1.08883); # illuminant

sub from_xyz {
    my ($xyz) = shift;
    my @xyz = map {$xyz->[$_] * $D65[$_]} 0 .. 2;
    my @lms = mult_matrix3([[ 0.8189330101, 0.3618667424,-0.1288597137],
                            [ 0.0329845436, 0.9293118715, 0.0361456387],
                            [ 0.0482003018, 0.2643662691, 0.6338517070]], @xyz);

    @lms = map {$_ ** (1/3)} @lms;

    my @lab = mult_matrix3([[ 0.2104542553,  0.7936177850, -0.0040720468],
                            [ 1.9779984951, -2.4285922050,  0.4505937099],
                            [ 0.0259040371,  0.7827717662, -0.8086757660]], @lms);
    $lab[1] += .5;
    $lab[2] += .5;
    return \@lab;
}
sub to_xyz {
    my (@lab) = @{$_[0]};
    $lab[1] -= .5;
    $lab[2] -= .5;
    my @lms = mult_matrix3([[ 1,  0.396338 ,  0.215804  ],
                            [ 1, -0.105561 , -0.0638542 ],
                            [ 1, -0.0894842, -1.29149   ]], @lab);

    @lms = map {$_ ** 3} @lms;

    my @xyz = mult_matrix3([[ 1.22701  , -0.5578  , 0.281256 ],
                            [-0.0405802,  1.11226 ,-0.0716767],
                            [-0.0763813, -0.421482, 1.58616  ]], @lms);
    return [map {$xyz[$_] / $D65[$_]} 0 .. 2];
}

Graphics::Toolkit::Color::Space->new(
         name => 'OKLAB',       # no alias, short axis name eq long
         axis => [qw/L a b/],  # lightness, cyan-orange balance, magenta-green balance
        range => [1, [-.5, .5], [-.5, .5]],
    precision => 3,
      convert => {XYZ => [\&to_xyz, \&from_xyz]},
);
