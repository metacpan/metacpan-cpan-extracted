use strict;
use warnings;

use Test::More;


my $out = qx{$^X bin/metacpan_by_author.pl SZABGAB};
isnt $out, '';

done_testing;


