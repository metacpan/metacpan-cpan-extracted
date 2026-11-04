use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use Devel::XSCover::Gcov ();

sub slurp { my $f = File::Spec->catfile(@_); open my $fh, '<', $f or die "$f: $!"; local $/; <$fh> }

my $reader = Devel::XSCover::Gcov->new(dir => 't/fixtures/spike', silent => 1, flow => 'llvm');
my $parsed = $reader->parse(slurp(qw(t fixtures gcov llvm helper.gcov.txt)));
is($reader->attach_decisions($parsed, ''), 0, 'no graph, nothing attached');
is($reader->attach_decisions($parsed, undef), 0, 'nor for no text at all');
ok(!exists $parsed->{'src/helper.c'}{decisions}, 'and the file has no decisions key, so its branches come from the blocks');

is($reader->attach_decisions($parsed, slurp(qw(t fixtures flow llvm helper.flow.txt))), 2, 'the llvm dump of the helper object reaches both of its files');
is_deeply($parsed->{'src/helper.c'}{decisions}, [ { line => 5, arms => [1, 1, 0, 1] } ], 'the switch of the helper, with its never taken arm');
is_deeply($parsed->{'include/spike.h'}{decisions}, [ { line => 6, arms => [0, 1] } ], 'the inline if, from this object only ever false');
is_deeply([ sort keys %{ $parsed->{'src/helper.c'} } ], [qw(blocks conditions decisions functions lines)], 'the rest of the parse untouched');

my $part = $reader->parse(slurp(qw(t fixtures gcov llvm helper.gcov.txt)));
delete $part->{'include/spike.h'};
is($reader->attach_decisions($part, slurp(qw(t fixtures flow llvm helper.flow.txt))), 1, 'a file the gcov text did not name is left out of the count');
ok(!exists $part->{'include/spike.h'}, 'and is not invented from the graph');

my $gcc = Devel::XSCover::Gcov->new(dir => 't/fixtures/spike', silent => 1, flow => 'gcc');
my $g   = $gcc->parse(slurp(qw(t fixtures gcov gcc helper.gcov.txt)));
is($gcc->attach_decisions($g, slurp(qw(t fixtures flow gcc helper.flow.json))), 2, 'the gcc json reaches both files too');
is_deeply($g->{'src/helper.c'}{decisions}, [ { line => 5, arms => [1, 1, 0, 1] } ], 'the same switch read from the json');
is_deeply($g->{'include/spike.h'}{decisions}, [ { line => 6, arms => [0, 1] } ], 'and the same inline if');

done_testing;
