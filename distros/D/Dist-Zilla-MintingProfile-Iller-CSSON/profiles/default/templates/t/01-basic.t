use strict;
use warnings;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use {{ my $dist = $dist->name; $dist =~ s{-}{::}g; $dist }};
ok 1, 'Loaded';

done_testing;
