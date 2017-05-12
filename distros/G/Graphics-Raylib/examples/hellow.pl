use Graphics::Raylib;
use Graphics::Raylib::Text;
use Graphics::Raylib::Color;

my $g = Graphics::Raylib->window(120,20);
$g->fps(5);

my $text = Graphics::Raylib::Text->new(
    text => 'Hello World!',
    color => Graphics::Raylib::Color::DARKGRAY,
    size => 20,
);

my $i++;
while (!$g->exiting) {
    Graphics::Raylib::draw {
        $g->clear;

        $text->draw;
    };
}

