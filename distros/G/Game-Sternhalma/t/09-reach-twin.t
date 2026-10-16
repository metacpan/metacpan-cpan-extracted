use strict;
use warnings;
use Test::More;
use FindBin;

use Game::Sternhalma::Engine ':all';
my $E = 'Game::Sternhalma::Engine';

# THE TWIN'S REACH AND PATHS. t/reach.txt was written by
# plan_game_sternhalma/twin/sternhalma.py, a second generator in Python from
# the rules text alone. The paths agree because both follow the documented
# convention (a step if a step gets there, else breadth first, first in first
# out, directions in order, first parent kept), not because they share code.

open my $fh, '<', "$FindBin::Bin/reach.txt" or die "t/reach.txt: $!";
my ($rows, $pieces, $stops, $chains, $longest, %seats, @bad) = (0, 0, 0, 0, 0);
while (my $line = <$fh>) {
    chomp $line;
    next if $line =~ /\A#/ || $line !~ /\S/;
    my (undef, $position, $cells) = split /\t/, $line, -1;
    my ($bd) = $E->from_string($position) or do { push @bad, "unread: $position"; next };
    $rows++;
    $seats{ $bd->seats . 'x' . $bd->pieces }++;
    my @mine = grep { defined $bd->at($_) && $bd->at($_) == $bd->to_move } 0 .. HOLES - 1;
    my @cells = split ' ', $cells;
    push @bad, "$position: the twin has " . scalar(@cells) . " pieces to move, the engine " . scalar(@mine)
        unless @cells == @mine;
    my $legal = 0;
    for my $cell (@cells) {
        my ($from, $list) = $cell =~ /\A(\d+):(.*)\z/;
        my @paths = map { [ split /\./ ] } grep { length } split /,/, $list;
        my $want = join ',', map { $_->[-1] } @paths;
        my $got  = join ',', $bd->reach($from);
        push @bad, "$position from $from\n  twin:   $want\n  engine: $got" unless $got eq $want;
        for my $p (@paths) {
            my $w = join '.', $from, @$p;
            my $g = join '.', $bd->path($from, $p->[-1]);
            push @bad, "$position path $from to $p->[-1]\n  twin:   $w\n  engine: $g" unless $g eq $w;
            $stops++;
            $chains++ if @$p > 1;
            $longest = @$p if @$p > $longest;
        }
        $legal += @paths;
        $pieces++;
    }
    my $n = () = $bd->legal;
    push @bad, "$position: legal has $n pairs, the twin's reaches $legal" unless $n == $legal;
}

is($rows, 374, '374 positions read');
is_deeply([ sort keys %seats ], [ qw(2x10 2x15 3x10 3x15 4x10 6x10) ], 'on every seat count and both piece counts');
cmp_ok($stops, '>', 10_000, "$stops stops of $pieces pieces compared, reach and path");
cmp_ok($chains, '>', 1_000, "$chains of them chains of two hops or more");
cmp_ok($longest, '>=', 8, "the longest of $longest hops");
is(scalar(@bad), 0, 'and every reach, every path and every legal count is the twin\'s')
    or diag join "\n", @bad[0 .. ($#bad < 4 ? $#bad : 4)];

done_testing();
