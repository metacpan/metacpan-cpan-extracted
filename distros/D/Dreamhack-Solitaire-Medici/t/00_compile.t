use strict;
use Test::More 0.98 tests => 2;

use_ok $_ for qw(
    Dreamhack::Solitaire::Medici
);

can_ok('Dreamhack::Solitaire::Medici', 'process');
done_testing;

