use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
my $simcounter1 = new_ok
    'Fl::SimpleCounter' => [20, 40, 300, 100, 'Hello, World!'],
    'simple counter w/ label';
my $simcounter2 = new_ok
    'Fl::SimpleCounter' => [20, 40, 300, 100],
    'simple counter w/o label';
#
isa_ok $simcounter1, 'Fl::Counter';
#
Fl::delete_widget($simcounter2);
is $simcounter2, undef, '$simcounter2 is now undef';
undef $simcounter1;
is $simcounter1, undef, '$simcounter1 is now undef';
#
done_testing;
