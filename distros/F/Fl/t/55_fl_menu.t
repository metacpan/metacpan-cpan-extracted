use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
# Virtual class so no new(...)
#
isa_ok 'Fl::Menu', 'Fl::Widget';
#
can_ok 'Fl::Menu', $_ for qw[add clear clear_submenu copy down_box
    find_index find_item global insert item_pathname menu mode mvalue picked
    remove replace shortcut size test_shortcut text textcolor textfont
    textsize value];
#
done_testing;
