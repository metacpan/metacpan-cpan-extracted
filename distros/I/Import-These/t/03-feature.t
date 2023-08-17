use strict;
use warnings;

use Test::More;

no warnings "experimental";
use Import::These feature=>[< refaliasing>];

my $res=eval { \my @a=[10]; 1};

ok !$@,  "feature import";

done_testing;
