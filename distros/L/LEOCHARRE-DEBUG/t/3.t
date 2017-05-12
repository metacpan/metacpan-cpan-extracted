use Test::Simple 'no_plan';
use strict;
use lib './lib';
use LEOCHARRE::DEBUG;
ok( ! DEBUG );

DEBUG 1;

ok(DEBUG);


my $complex_struct = {
   range => 'bullemic',
   numbers => [qw(a b c d e f g)],   
};



sub testing {
   debug($complex_struct);
}


testing();



