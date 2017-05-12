use strict;
use warnings;
use Test::More;

plan tests => 14 unless  $::NO_PLAN && $::NO_PLAN;

require_ok 'List::Pairwise';
List::Pairwise->import(':all');

# test import
is(\&mapp, \&List::Pairwise::mapp, 'mapp imported');
is(\&map_pairwise, \&List::Pairwise::map_pairwise, 'map_pairwise imported');
is(\&mapp, \&map_pairwise, 'mapp and map_pairwise are alias');

is(\&grepp, \&List::Pairwise::grepp, 'grepp imported');
is(\&grep_pairwise, \&List::Pairwise::grep_pairwise, 'grep_pairwise imported');
is(\&grepp, \&grep_pairwise, 'grepp and grep_pairwise are alias');

is(\&firstp, \&List::Pairwise::firstp, 'firstp imported');
is(\&first_pairwise, \&List::Pairwise::first_pairwise, 'first_pairwise imported');
is(\&firstp, \&first_pairwise, 'firstp and first_pairwise are alias');

is(\&lastp, \&List::Pairwise::lastp, 'lastp imported');
is(\&last_pairwise, \&List::Pairwise::last_pairwise, 'last_pairwise imported');
is(\&lastp, \&last_pairwise, 'lastp and last_pairwise are alias');

is(\&pair, \&List::Pairwise::pair, 'pair imported');