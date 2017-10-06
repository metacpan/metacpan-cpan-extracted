use Test::More;

BEGIN {
    use_ok 'Graphics::Raylib';
}

my $g = Graphics::Raylib->window(50,50);

$g->fps(40);

Graphics::Raylib::draw {
    $g->clear;

};

sleep(1);

done_testing
