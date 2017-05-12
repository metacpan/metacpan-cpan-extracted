use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
#
isa_ok 'Fl::Valuator', 'Fl::Widget';
#
can_ok 'Fl::Valuator', $_
for qw[bounds clamp maximum minimum precision range round step value];

#
done_testing;
