use Test::More;

my $SIZE  = 200;
my $ITERS = 150;
my $STEP = $ENV{RAYLIB_FRACTAL_STEP} // 25;
my ($cX, $cY) = (-0.7, 0.27015);
my ($moveX, $moveY) = (0, 0);
my $zoom = 1;

use Graphics::Raylib '+family';

my $g = Graphics::Raylib->window($SIZE*4, $SIZE*2);
plan skip_all => 'No graphic device' if !$g or defined $ENV{NO_GRAPHICAL_TEST} or defined $ENV{NO_GRAPHICAL_TESTS};

my @julia      = map [(WHITE)x$SIZE], 0..$SIZE-1;
my @mandelbrot = map [(WHITE)x$SIZE], 0..$SIZE-1;
# coloring in the callback is reaaaaally slow, so we don't do it TODO find out why
my @args = (color => undef, width => $SIZE * 2, height => $SIZE * 2, y => 0);
my $julia      = Graphics::Raylib::Texture->new(matrix => \@julia,      x => 0, @args);
my $mandelbrot = Graphics::Raylib::Texture->new(matrix => \@mandelbrot, x => $SIZE*2, @args);
$g->fps(50);

for (my $y = 0; $y <= $SIZE; $y += $STEP) {
    $g->clear;
    $julia->matrix = \@julia;
    $mandelbrot->matrix = \@mandelbrot;

    Graphics::Raylib::draw {
        $julia->draw;
        $mandelbrot->draw;
    };

    for (my $i = $y; $i < $y + $STEP; $i++) {
        for (my $x = 0; $x < $SIZE; $x++) {
            $julia[$i][$x]      = julia($x, $i);
            $mandelbrot[$i][$x] = mandelbrot($x, $i);
        }
    }
}
sleep($ENV{RAYLIB_TEST_SLEEP_SECS} // 0);
sub julia {
    my ($x, $y) = @_;
    my $zx = (1.5 * ($x - $SIZE / 2) / (0.5 * $zoom * $SIZE) + $moveX);
    my $zy = (($y - $SIZE / 2) / (0.5 * $zoom * $SIZE) + $moveY);
    my $i = $ITERS;
    while ($zx**2 + $zy**2 < 4 and --$i >= 0) {
        ($zy, $zx) = (2 * $zx * $zy + $cY, $zx**2 - $zy**2 + $cX);
    }

    return Graphics::Raylib::Color::hsv(abs($i / $ITERS * 360), 1, $i > 0 ? 1 : 0);
}
sub mandelbrot {
    my ($x, $y) = @_;
    my ($cx, $cy) = (-2 + 2.5*$x/$SIZE, -1.25 + 2.5*$y/$SIZE);
    my ($zx, $zy) = ($cx, $cy);

    my $i = $ITERS;
    while ($zx**2 + $zy**2 < 16.0 and --$i >= 0) {
        ($zy, $zx) = (2 * $zx * $zy + $cy, $zx**2 - $zy**2 + $cx);
    }

    return Graphics::Raylib::Color::hsv(abs($i / $ITERS * 360), 1, $i > 0 ? 1 : 0);
}

ok 1;
done_testing
