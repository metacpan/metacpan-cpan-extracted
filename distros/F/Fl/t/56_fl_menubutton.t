use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
#
my $mnubtn = new_ok 'Fl::MenuButton' => [100, 200, 340, 180], 'menu button w/o label';
my $mnubtn2 = new_ok
    'Fl::MenuButton' => [100, 200, 340, 180, 'title!'],
    'menu button w/ label';
#
isa_ok $mnubtn, 'Fl::Menu';
#
Fl::delete_widget($mnubtn2);
is $mnubtn2, undef, '$mnubtn2 is now undef';
undef $mnubtn;
is $mnubtn, undef, '$mnubtn is now undef';
#
done_testing;
