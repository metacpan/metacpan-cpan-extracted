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

my $dropped = Devel::XSCover::XS->new(dir => "t/fixtures/dropped")->line_map("Dropped.c");
is_deeply($dropped->[179], ["Dropped.xs", 12], "a preprocessor line in a body is kept and counted");
is_deeply($dropped->[180], ["Dropped.xs", 13], "and the statement after it");
is_deeply($dropped->[181], ["Dropped.xs", 15], "the statement after a comment xsubpp dropped is where it was written, not one short");
my $inverse = Devel::XSCover::XS->new(dir => "t/fixtures/dropped")->map("Dropped.c")->{inverse};
is_deeply($inverse, { "Dropped.xs" => { 14 => 15 } }, "and the map says which line gcov will report it on instead");

my $below = Devel::XSCover::XS->new(dir => 't');
is($below->resolve('fixtures/dropped/Dropped.c', 'Dropped.xs'), 'fixtures/dropped/Dropped.xs', 'a #line name is taken beside the c when the top has no such file');
is($below->resolve('fixtures/dropped/Dropped.c', 'fixtures/dropped/Dropped.xs'), 'fixtures/dropped/Dropped.xs', 'a name under the top is itself');
is($below->resolve('fixtures/dropped/Dropped.c', 'nowhere.xs'), 'nowhere.xs', 'a name found nowhere is left as written');
is($below->resolve('fixtures/dropped/Dropped.c', '/abs/Dropped.xs'), '/abs/Dropped.xs', 'an absolute one too');
my $sub = $below->line_map('fixtures/dropped/Dropped.c');
is_deeply($sub->[179], ['fixtures/dropped/Dropped.xs', 12], 'a c generated inside a subdirectory maps to the xs beside it');
my $submap = $below->map('fixtures/dropped/Dropped.c');
is_deeply($submap->{files}, ['fixtures/dropped/Dropped.xs'], 'and the map lists that xs');
is_deeply($submap->{inverse}, { 'fixtures/dropped/Dropped.xs' => { 14 => 15 } }, 'with the dropped lines counted from it');
is($_->{file}, 'fixtures/dropped/Dropped.xs', "xsub $_->{c_name} is declared in it") for $below->subroutines($submap);

done_testing;
