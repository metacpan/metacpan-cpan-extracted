use Test::More;
use FindBin;

use Graphics::Raylib '+family';

my $g = Graphics::Raylib->window(128, 128);
plan skip_all => 'No graphic device' if !$g or defined $ENV{NO_GRAPHICAL_TEST} or defined $ENV{NO_GRAPHICAL_TESTS};

$g->fps(60);
my $brick = Graphics::Raylib::Texture->new(
    file => "$FindBin::Bin/../share/brick.png",
    width => 32, height => 32,
);
$i = 0;
while (!$g->exiting && $i++ < 60) {
    $g->clear(WHITE);
    Graphics::Raylib::draw {
        for (my $i = 0; $i < 128; $i += 32) {
            for (my $j = 0; $j < 128; $j += 32) {
                $brick->draw(x => $i, y => $j);
            }
        }
    }
}
ok 1;
done_testing
