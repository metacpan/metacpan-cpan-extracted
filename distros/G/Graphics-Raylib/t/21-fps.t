use Test::More;

BEGIN {
    use_ok 'Graphics::Raylib';
    use_ok 'Graphics::Raylib::Text';
}

my $g = Graphics::Raylib->window(200,50);

$g->fps(40);

Graphics::Raylib::draw {
    $g->clear;

    Graphics::Raylib::Text::FPS->draw;
};
sleep 1;

done_testing
