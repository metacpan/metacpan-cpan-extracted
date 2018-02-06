use Test::More;


use Graphics::Raylib;
use Graphics::Raylib::Text;
use Graphics::Raylib::Shape;
use Graphics::Raylib::Color;

my $block_size = 50;

my $g = Graphics::Raylib->window($block_size*10, $block_size, "Test");
plan skip_all => 'No graphic device' if !$g or defined $ENV{NO_GRAPHICAL_TEST} or defined $ENV{NO_GRAPHICAL_TESTS};

$g->fps(30);

my $rect = Graphics::Raylib::Shape->rectangle(
    position => [0,0], size => [$block_size, $block_size],
    color => Graphics::Raylib::Color::SKYBLUE
);
my $i = 0;
while (!$g->exiting && $i != 60) {
    Graphics::Raylib::draw {
        $g->clear;
        $rect->draw;

        Graphics::Raylib::Text::FPS->draw;
    };

    $rect->{position} = [(++$i % 10) * $block_size, 0];
}
ok 1;
done_testing
