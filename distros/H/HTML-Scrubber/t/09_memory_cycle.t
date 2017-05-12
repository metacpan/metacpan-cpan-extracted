
use Test::More tests => 1;
use Test::Memory::Cycle;

use HTML::Scrubber;

my $scrubber = HTML::Scrubber->new();

memory_cycle_ok( $scrubber, "Scrubber has no cycles" );
