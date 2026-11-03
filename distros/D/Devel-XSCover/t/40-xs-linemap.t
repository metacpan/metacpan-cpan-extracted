use 5.020;
use strict;
use warnings;
use Test::More;
use Devel::XSCover::XS ();

my $xs  = Devel::XSCover::XS->new(dir => 't/fixtures/ex-op');
my $map = $xs->line_map('Op.c');
is_deeply($map->[1], ['Op.c', 1], 'the first generated line is its own');
is_deeply($map->[9], ['Op.c', 9], 'a #line directive maps to the c itself');
is_deeply($map->[10], ['Op.xs', 1], 'the line after #line 1 "Op.xs" is Op.xs:1');
is_deeply($map->[11], ['Op.xs', 2], 'and the next in sequence');
is_deeply($map->[1017], ['Op.c', 1017], 'the directive back to the c');
is_deeply($map->[1018], ['Op.c', 1018], 'maps the line after it to itself');
is_deeply($map->[1178], ['Op.xs', 1015], 'the body of import');
is_deeply($map->[1179], ['Op.xs', 1016], 'and its second line');
is(scalar(@$map) - 1, 1668, 'one entry per generated line');

my $spike = Devel::XSCover::XS->new(dir => 't/fixtures/spike')->line_map('Spike.c');
is_deeply($spike->[366], ['xs/more.xs', 7], 'an INCLUDEd file loses its leading ./');
is_deeply($spike->[192], ['Spike.xs', 26], 'the body of add');

done_testing;
