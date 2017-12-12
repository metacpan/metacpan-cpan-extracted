use Test::More;

BEGIN {
    use_ok 'Graphics::Raylib::Keyboard';
}

is Graphics::Raylib::Keyboard::KEY_SPACE, ord ' ';

use Graphics::Raylib::Keyboard qw(:all);

is KEY_SPACE, ord ' ';

my $key = Graphics::Raylib::Keyboard->new;
ok $key;
$key->exit(KEY_SPACE);
is $key->exit, KEY_SPACE;

done_testing;
