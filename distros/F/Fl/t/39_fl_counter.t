use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
#
my $input = new_ok 'Fl::Counter' => [100, 200, 340, 180], 'counter w/o label';
my $input2 = new_ok
    'Fl::Counter' => [100, 200, 340, 180, 'title!'],
    'counter w/ label';
#
isa_ok $input, 'Fl::Valuator';
#
can_ok $input, 'lstep';
can_ok $input, 'step';
#
done_testing;
