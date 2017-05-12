use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
#
my $button = new_ok 'Fl::Button' => [100, 200, 340, 180], 'button w/o label';
my $button2 = new_ok
    'Fl::Button' => [100, 200, 340, 180, 'title!'],
    'button w/ label';
#
isa_ok $button, 'Fl::Widget';
#
can_ok $button, 'clear';
can_ok $button, 'down_box';
can_ok $button, 'set';
can_ok $button, 'shortcut';
can_ok $button, 'value';
#
done_testing;
