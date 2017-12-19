use Test::More;

BEGIN {
    use_ok 'Graphics::Raylib::Key';
}
use Graphics::Raylib::Key ':all';

my $key = Graphics::Raylib::Key->new(map => '<CR>');
is $key->keycode, KEY_ENTER;
ok $key == Graphics::Raylib::Key->new(keycode => KEY_ENTER);
ok $key eq Graphics::Raylib::Key->new(keycode => KEY_ENTER);
ok $key eq '<cr>';
ok $key eq '<ENTER>';
ok $key eq '<Return>';
ok(Graphics::Raylib::Key->new(keycode => KEY_ENTER) eq '<return>');
ok "$key" eq '<cr>' || "$key" eq '<enter>' || "$key" eq '<return>';

$key = Graphics::Raylib::Key->new(map => '<0020>');
is $key->keycode, KEY_SPACE;
ok $key eq '<Space>';

$key = Graphics::Raylib::Key->new(keycode => 0);
ok $key->is_special;
#diag 0+$key;
#ok $key == 0, 'numeric value of keycode => 0 is 0';
ok $key eq '<0000>', 'stringifed value of keycode => 0 is <0000>';
diag sprintf("KEY: %s", $key);
is "$key", '<0000>';

$key = Graphics::Raylib::Key->new(keycode => KEY_LEFT_CONTROL);
ok $key == 0x155; # 341
ok $key eq '<0155>';
ok $key eq '<cleft>';
ok $key eq '<CTRL>';
ok $key eq '<C>';

$key = Graphics::Raylib::Key->new(map => 'a');
ok $key eq 'a';

$key = Graphics::Raylib::Key->new(map => '0');
ok $key eq '0';
is "$key", '0';
isnt "$key", '<30>';

done_testing;
