#!perl -Tw

use warnings;
use strict;

use Test::More tests => 2;

use List::Cycle;

my $cycle = List::Cycle->new( {vals=> [2112, 5150, 90125]} );
isa_ok( $cycle, 'List::Cycle' );

my $expected = <<'END_DUMP';
pointer => 0
values => 2112,5150,90125
END_DUMP

my @actual = sort split /\n/, $cycle->dump;

# Now that we're sure $actual[1] contains 'values => ...',
# we can sort the values themselves.

my @field  = split(/\s*=>\s*/, $actual[1]);
$actual[1] = "$field[0] => " . join(',', sort split(/\s*,\s*/, $field[1]) );
my $actual = join("\n", @actual) . "\n";

is($expected, $actual, 'dumped properly');

done_testing();
