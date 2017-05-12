use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl qw[:box :label :font];
my $box1 = new_ok
    'Fl::Box' => [20, 40, 300, 100, 'Hello, World!'],
    'box w/ label';
my $box2 = new_ok 'Fl::Box' => [20, 40, 300, 100], 'box2 w/o label';
my $box = new_ok
    'Fl::Box' => [FL_UP_BOX, 20, 40, 300, 100, 'Hello, World!'],
    'box w/ label and box type';
#
isa_ok $box, 'Fl::Widget';
#
undef $box;
is $box, undef, 'box is now undef';
#
done_testing;
