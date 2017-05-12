use strict;
use lib qw(t t/lib);

use Test::More tests => 7;

use Graphics::Primitive::Font;

use Graphics::Color::RGB;

use Document::Writer::TextArea;

use MockDriver;

my $text = "Lorem ipsum dolor sit amet,\nconsectetur adipisicing elit,\nsed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\nUt enim ad minim veniam,\nquis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\nDuis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.\nExcepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";

my $tb = Document::Writer::TextArea->new(
    width => 80,
    text => $text
);

my $driver = MockDriver->new;
my $tl = $driver->get_textbox_layout($tb);
$tl->layout($driver);

cmp_ok($tl->height, '==', 7, '7 height');

my $ret = $tl->slice(0, 5);
cmp_ok($ret->minimum_height, '<=', 5, '0 offset, 5 size');
my $ret2 = $tl->slice(3, 2);
cmp_ok($ret2->minimum_height, '==', 2, '3 offset, 2 size');
my $ret3 = $tl->slice(4, 1);
cmp_ok($ret3->minimum_height, '==', 1, '4 offset, 1 size');

# 
my $lines3 = $tl->slice(4);
# use Data::Dumper;
# print Dumper($lines3);
cmp_ok($lines3->minimum_height, '==', 3, '4 offset slice');

my $lines4 = $tl->slice(0, 24);
cmp_ok($lines4->minimum_height, '==', 7, '0 offset, 24 size slice');

my $tb2 = Document::Writer::TextArea->new(
    width => 80,
    text => "One\nTwo\n\nThree"
);
my $tl2 = $driver->get_textbox_layout($tb2);

$tl2->layout($driver);
cmp_ok($tl2->height, '==', 4, 'layout');


