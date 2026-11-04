use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use Devel::XSCover::Gcov ();
use Devel::XSCover::Flow ();

sub slurp {
    my $f = File::Spec->catfile(@_);
    open my $fh, '<', $f or die "$f: $!";
    local $/;
    return <$fh>;
}

sub sorted {
    my ($g) = @_;
    my %files;
    for my $file (keys %{ $g->{files} }) {
        for my $n (keys %{ $g->{files}{$file} }) {
            my $l = $g->{files}{$file}{$n};
            $files{$file}{$n} = { %$l, arcs => [ sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } @{ $l->{arcs} } ] };
        }
    }
    return { %$g, files => \%files };
}

my $files = Devel::XSCover::Gcov->new(silent => 1)->parse(slurp(qw(t fixtures gcov llvm Spike.gcov.txt)));
my $flow  = Devel::XSCover::Flow->new(dir => 't/fixtures/spike');
my $g     = $flow->parse_llvm(slurp(qw(t fixtures flow llvm Spike.flow.txt)), $files);
is($g->{complete}, 1, 'the dump has every arc');
is_deeply([ sort grep { !m{^/} } keys %{ $g->{files} } ], ['Spike.c', 'Spike.xs', 'include/spike.h', 'xs/more.xs'],
    'the files of the dist, each file index named by a function of its own or by its lines');
is(scalar(grep { m{/CORE/} } keys %{ $g->{files} }), 2, 'and the two perl headers');
my $if = $g->{files}{'Spike.xs'}{36};
is_deeply([ sort keys %{ $if->{blocks} } ], ['2:7', '2:8'], 'the blocks on the if line, keyed by function and block');
is_deeply([ sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } @{ $if->{arcs} } ],
    [ ['2:7', '2:10', 1], ['2:7', '2:8', 2], ['2:8', '2:10', 1], ['2:8', '2:9', 1] ], 'their arcs with destinations and counts');
ok(!defined $if->{count}, 'no line count in the dump');
is_deeply([ sort { $a <=> $b } keys %{ $g->{files}{'xs/more.xs'} } ], [7, 15, 23, 31], 'more.xs, which no function starts in, matched by its lines');
is_deeply([ sort { $a <=> $b } keys %{ $g->{files}{'include/spike.h'} } ], [4, 6, 7, 8], 'the header seen from this object');
is(scalar keys %{ $g->{files}{'Spike.xs'}{47}{blocks} }, 1, 'one block on the switch line');
is(scalar @{ $g->{files}{'Spike.xs'}{47}{arcs} }, 5, 'with five arcs');

my $noisy = "warning: Spike.gcda: stale profile\n" . slurp(qw(t fixtures flow llvm Spike.flow.txt));
$noisy =~ s/^(===== boot_Spike .*\n)/${1}warning: a line between the header and its blocks\n/m;
is_deeply(sorted($flow->parse_llvm($noisy, $files)), sorted($g), 'warnings llvm-cov prints on stderr before and among the dump are passed over');

my $h = $flow->parse_llvm(slurp(qw(t fixtures flow llvm helper.flow.txt)), {});
is_deeply([ sort keys %{ $h->{files} } ], ['include/spike.h', 'src/helper.c'], 'the helper object, both files named by their functions');
is_deeply([ sort { $a->[1] cmp $b->[1] } @{ $h->{files}{'src/helper.c'}{5}{arcs} } ],
    [ ['0:2', '0:3', 1], ['0:2', '0:4', 1], ['0:2', '0:5', 0], ['0:2', '0:6', 1] ], 'the switch arcs of the helper');

my $d = $flow->decisions($g);
is_deeply($d->{'Spike.xs'}, [
    { line => 10, arms => [1, 1] },
    { line => 36, arms => [1, 2] },
    { line => 47, arms => [1, 1, 0, 1, 1] },
    { line => 95, arms => [0, 1] },
], 'the decisions of Spike.xs: the static if, the && if, the switch and the guard');
is_deeply($d->{'include/spike.h'}, [ { line => 6, arms => [1, 0] } ], 'the header inline from this object');
is_deeply($d->{'xs/more.xs'}, [], 'more.xs has none, and says so');
is_deeply($flow->decisions($h)->{'src/helper.c'}, [ { line => 5, arms => [1, 1, 0, 1] } ], 'the helper switch');

done_testing;
