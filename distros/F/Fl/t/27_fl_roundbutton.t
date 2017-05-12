use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
#
my $button = new_ok 'Fl::RoundButton' => [100, 200, 340, 180], 'round button w/o label';
my $button2 = new_ok
    'Fl::RoundButton' => [100, 200, 340, 180, 'title!'],
    'round button w/ label';
#
isa_ok $button, 'Fl::Button';
#
done_testing;
