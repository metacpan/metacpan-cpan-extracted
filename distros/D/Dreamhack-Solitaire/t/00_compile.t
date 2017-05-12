use strict;
use Test::More 0.98 tests => 7;

use_ok $_ for qw(
    Dreamhack::Solitaire
);

can_ok('Dreamhack::Solitaire', 'new');
can_ok('Dreamhack::Solitaire', 'init_layout');
can_ok('Dreamhack::Solitaire', 'parse_init_string');
can_ok('Dreamhack::Solitaire', 'add_rnd_layout');
can_ok('Dreamhack::Solitaire', 'extract');
can_ok('Dreamhack::Solitaire', 'format');

done_testing;

