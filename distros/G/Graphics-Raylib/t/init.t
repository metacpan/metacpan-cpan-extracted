use Test::More;

BEGIN {
    use_ok 'Graphics::Raylib';
}

ok(Graphics::Raylib->window(50,50));

done_testing;


