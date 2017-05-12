use Test::More;

BEGIN {
    use_ok 'Graphics::Raylib';
    use_ok 'Graphics::Raylib::Shape';
    use_ok 'Graphics::Raylib::Color';
}

my $block_size = 50;

my $g = Graphics::Raylib->window($block_size*10, $block_size, "Test");

$g->fps(5);

my $rect = Graphics::Raylib::Shape->rectangle(
    pos => [0,0], size => [$block_size, $block_size],
    color => Graphics::Raylib::Color::DARKGREEN
);
my $i = 0;
while (!$g->exiting && $i != 20) {
    Graphics::Raylib::draw {
        $g->clear;

        $rect->draw;

    };

    $rect->{pos} = [(++$i % 10) * $block_size, 0];
}


done_testing;



