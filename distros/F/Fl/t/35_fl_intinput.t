use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
#
my $input = new_ok 'Fl::IntInput' => [100, 200, 340, 180], 'int input w/o label';
my $input2 = new_ok
    'Fl::IntInput' => [100, 200, 340, 180, 'title!'],
    'int input w/ label';
#
isa_ok $input, 'Fl::Input';
#
done_testing;
