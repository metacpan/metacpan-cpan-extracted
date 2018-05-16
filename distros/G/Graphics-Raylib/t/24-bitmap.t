use Test::More;

use Graphics::Raylib '+family';

my $g = Graphics::Raylib->window(150, 150);
plan skip_all => 'No graphic device' if !$g or defined $ENV{NO_GRAPHICAL_TEST} or defined $ENV{NO_GRAPHICAL_TESTS};

$g->fps(180);
my $glider = Graphics::Raylib::Shape->bitmap(
    matrix => [
        [0, 0, 0, 0, 0],
        [0, 1, 0, 1, 0],
        [0, 1, 0, 1, 0],
        [0, 0, 1, 1, 0],
        [0, 0, 0, 0, 0],
    ],
    color => BLACK,
    transposed => 1,
);
while (!$g->exiting && $glider->rotation < 360) {
    $g->clear(WHITE);
    Graphics::Raylib::draw {
        $glider->rotation += 1;
        $glider->draw
    }
}
ok 1;
done_testing
