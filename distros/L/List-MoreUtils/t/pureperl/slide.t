#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 1; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use lib ("t/lib");
use List::MoreUtils (":all");


use Test::More;
use Test::LMU;

# use case provided my Michael Schwern
my @ol = (0 .. 3);
is(join(", ", slide { "$a and $b" } @ol), "0 and 1, 1 and 2, 2 and 3", "M. Schwern requested example");

is_dying('slide without sub' => sub { &slide(0 .. 3); });

done_testing;


