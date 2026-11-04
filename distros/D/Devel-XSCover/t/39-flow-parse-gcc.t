use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use Devel::XSCover::Flow ();

sub slurp {
    my $f = File::Spec->catfile(@_);
    open my $fh, '<', $f or die "$f: $!";
    local $/;
    return <$fh>;
}

my $flow = Devel::XSCover::Flow->new(dir => 't/fixtures/spike');
my $g    = $flow->parse_gcc(slurp(qw(t fixtures flow gcc Spike.flow.json)));
is($g->{complete}, 0, 'the json has the conditional arcs only');
is_deeply([ sort grep { !m{^/} } keys %{ $g->{files} } ], ['Spike.c', 'Spike.xs', 'include/spike.h', 'xs/more.xs'], 'the files of the dist');
my $if = $g->{files}{'Spike.xs'}{36};
is_deeply([ sort { $a <=> $b } keys %{ $if->{blocks} } ], [10, 11], 'the blocks on the if line');
is_deeply([ sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @{ $if->{arcs} } ],
    [ [10, 11, 2], [10, 13, 1], [11, 12, 1], [11, 13, 1] ], 'their arcs');
is($if->{count}, 3, 'the line count');
is($g->{files}{'xs/more.xs'}{23}{count}, 0, 'the _exit child line never ran');
is_deeply([ map { $_->[2] } sort { $a->[1] <=> $b->[1] } @{ $g->{files}{'Spike.xs'}{47}{arcs} } ], [1, 1, 0, 1, 1], 'the switch arcs in destination order');

my $h = $flow->parse_gcc(slurp(qw(t fixtures flow gcc helper.flow.json)));
is_deeply([ sort keys %{ $h->{files} } ], ['include/spike.h', 'src/helper.c'], 'the helper object');

my $d = $flow->decisions($g);
is_deeply($d->{'Spike.xs'}, [
    { line => 10, arms => [1, 1] },
    { line => 36, arms => [1, 2] },
    { line => 47, arms => [1, 1, 0, 1, 1] },
    { line => 95, arms => [0, 1] },
], 'the same decisions as from the llvm dump');
is_deeply($d->{'include/spike.h'}, [ { line => 6, arms => [1, 0] } ], 'the header inline');
is_deeply($flow->decisions($h)->{'src/helper.c'}, [ { line => 5, arms => [1, 1, 0, 1] } ], 'the helper switch');

done_testing;
