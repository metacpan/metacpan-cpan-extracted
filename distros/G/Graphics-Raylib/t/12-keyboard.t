use Test::More;

BEGIN {
    use_ok 'Graphics::Raylib::Keyboard';
}

Graphics::Raylib::Keyboard::exit_key("<space>");
is Graphics::Raylib::Keyboard::exit_key(), "<SPACE>";

done_testing;
