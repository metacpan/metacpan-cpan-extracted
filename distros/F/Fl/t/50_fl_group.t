use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
#
my $group = new_ok 'Fl::Group' => [100, 200, 340, 180], 'group w/o title';
my $group2 = new_ok
    'Fl::Group' => [100, 200, 340, 180, 'title!'],
    'group w/ title';
#
isa_ok $group, 'Fl::Widget';
#
can_ok $group, 'add';
can_ok $group, 'add_resizable';
can_ok $group, 'begin';
can_ok $group, 'children';
can_ok $group, 'child';
can_ok $group, 'clear';
can_ok $group, 'end';
can_ok $group, 'resizable';
#
done_testing;
