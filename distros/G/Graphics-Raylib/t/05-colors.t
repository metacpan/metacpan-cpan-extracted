use Test::More;

BEGIN {
    use_ok 'Graphics::Raylib::Color';
}

my $color = Graphics::Raylib::Color::DARKPURPL;
is "$color", '(r: 112, g: 31, b: 126, a: 255)';

done_testing

