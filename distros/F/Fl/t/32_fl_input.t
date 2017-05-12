use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
#
my $input = new_ok 'Fl::Input' => [100, 200, 340, 180], 'input w/o label';
my $input2 = new_ok
    'Fl::Input' => [100, 200, 340, 180, 'title!'],
    'input w/ label';
#
isa_ok $input, 'Fl::Widget';
#
can_ok $input, 'copy';
can_ok $input, 'copy_cuts';
can_ok $input, 'cursor_color';
can_ok $input, 'cut';
can_ok $input, 'index';
can_ok $input, 'input_type';
can_ok $input, 'insert';
can_ok $input, 'mark';
can_ok $input, 'maximum_size';
can_ok $input, 'position';
can_ok $input, 'readonly';
can_ok $input, 'replace';
can_ok $input, 'shortcut';
can_ok $input, 'size';
can_ok $input, 'tab_nav';
can_ok $input, 'textcolor';
can_ok $input, 'textfont';
can_ok $input, 'textsize';
can_ok $input, 'undo';
can_ok $input, 'value';
can_ok $input, 'wrap';
#
done_testing;
