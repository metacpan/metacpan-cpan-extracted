use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
#
my $button = new_ok 'Fl::CheckButton' => [100, 200, 340, 180], 'check button w/o label';
my $button2 = new_ok
    'Fl::CheckButton' => [100, 200, 340, 180, 'title!'],
    'check button w/ label';
#
isa_ok $button, 'Fl::LightButton';
#
done_testing;
