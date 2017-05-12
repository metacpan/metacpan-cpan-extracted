use Test::More 'no_plan';

use warnings;
use strict;

use Lorem::Style;

my $style = Lorem::Style->new;
ok( $style, 'created style');