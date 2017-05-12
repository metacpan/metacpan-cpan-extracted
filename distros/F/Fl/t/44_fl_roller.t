use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
my $dial1 = new_ok
    'Fl::Roller' => [20, 40, 300, 100, 'Hello, World!'],
    'roller w/ label';
my $dial2 = new_ok
    'Fl::Roller' => [20, 40, 300, 100],
    'roller w/o label';
#
isa_ok $dial1, 'Fl::Valuator';
#
Fl::delete_widget($dial2);
is $dial2, undef, '$dial2 is now undef';
undef $dial1;
is $dial1, undef, '$dial1 is now undef';
#
done_testing;
