use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
#
my $input = new_ok 'Fl::FloatInput' => [100, 200, 340, 180], 'float input w/o label';
my $input2 = new_ok
    'Fl::FloatInput' => [100, 200, 340, 180, 'title!'],
    'float input w/ label';
#
isa_ok $input, 'Fl::Input';
#
done_testing;
