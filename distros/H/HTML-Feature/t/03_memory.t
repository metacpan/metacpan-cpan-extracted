use strict;
use warnings;
use HTML::Feature;
use Test::Memory::Cycle tests => 1;

my $object = HTML::Feature->new;
memory_cycle_ok( $object );
