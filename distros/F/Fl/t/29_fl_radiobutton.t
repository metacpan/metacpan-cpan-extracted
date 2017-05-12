use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
#
my $button = new_ok 'Fl::RadioRoundButton' => [100, 200, 340, 180], 'radio round button w/o label';
my $button2 = new_ok
    'Fl::RadioRoundButton' => [100, 200, 340, 180, 'title!'],
    'radio round button w/ label';
#
isa_ok $button, 'Fl::RoundButton';
#
done_testing;
