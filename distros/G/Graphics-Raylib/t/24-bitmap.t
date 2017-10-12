use Test::More;

use Graphics::Raylib '+family';

my $g = Graphics::Raylib->window(150, 150); $g->fps(180);

my $glider = Graphics::Raylib::Shape->bitmap(
    matrix => [
                [0, 0, 0, 0, 0],
                [0, 1, 0, 1, 0],
                [0, 1, 0, 1, 0],
                [0, 0, 1, 1, 0],
                [0, 0, 0, 0, 0],
              ],
    color => BLACK,
    transposed => 1
    #x => 150, y => 150, # undocumented
);
$g->clear(WHITE);

while (!$g->exiting && $glider->rotation < 360) {
    Graphics::Raylib::draw {
        $glider->rotation += 1;
        $glider->draw
    }
}

ok 1;

done_testing;
