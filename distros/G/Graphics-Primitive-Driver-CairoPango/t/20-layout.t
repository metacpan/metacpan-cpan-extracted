use strict;
use lib qw(t t/lib);

use Test::More tests => 9;

use Graphics::Color::RGB;
use Graphics::Primitive::Font;
use Graphics::Primitive::TextBox;
use Graphics::Primitive::Driver::CairoPango;

my $driver = Graphics::Primitive::Driver::CairoPango->new(
    width => 80,
    height => 500,
    format => 'PNG'
);

my $text = "Lorem ipsum dolor sit amet,\nconsectetur adipisicing elit,\nsed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\nUt enim ad minim veniam,\nquis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\nDuis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.\nExcepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";

# my $tl = Document::Writer::TextLayout->new(
#     default_color => Graphics::Color::RGB->new(
#         red => 0, green => 0, blue => 0, alpha => 1
#     ),
#     font => Graphics::Primitive::Font->new(
#         size => 12
#     ),
#     text => $text,
#     width => 80
# );

my $tb = Graphics::Primitive::TextBox->new(
    color => Graphics::Color::RGB->new,
    width => 80,
    height => 500,
    font => Graphics::Primitive::Font->new(size => 12),
    text => $text
);

my $tl = $driver->get_textbox_layout($tb);

my $ret = $tl->slice(0, 20);
isa_ok($ret, 'Graphics::Primitive::TextBox');
cmp_ok($ret->minimum_width, '>', 0, '0 offset, 20 size, width > 0');
cmp_ok($ret->minimum_height, '>', 0, '0 offset, 20 size, > 0');
cmp_ok($ret->minimum_height, '<=', 20, '0 offset, 20 size, <= 20');

my $ret2 = $tl->slice($ret->height, 2);
ok(!defined($ret2), 'previous offset, 2 size');
my $ret3 = $tl->slice($ret->height, 20);
cmp_ok($ret3->minimum_height, '>', 0, 'previous offset, 20 size, > 0');
cmp_ok($ret3->minimum_height, '<=', 20, 'previous offset, 20 size, <= 20');

my $ret4 = $tl->slice($ret->height + $ret3->height, 20);
cmp_ok($ret4->minimum_height, '<=', 20, 'last 2 offset, 20 size, <= 20');

my $ret5 = $tl->slice(300, 100);
cmp_ok($ret5->minimum_height, '<=', 100, 'big offset slice, <= 300');