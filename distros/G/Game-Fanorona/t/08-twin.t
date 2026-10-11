use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Fanorona::Engine ':all';
use FnT qw(texts mtexts board);

# THE TWIN'S LISTS. t/steps.txt was written by a second program, in another
# language, from the rules text alone.
{
open my $fh, '<', "$FindBin::Bin/steps.txt" or die "t/steps.txt: $!";
my ($rows, $captures, $stuck, %size, @bad) = (0, 0, 0);
while (my $line = <$fh>) {
    chomp $line;
    next if $line =~ /\A#/ || $line !~ /\S/;
    my ($position, $steps) = split /\t/, $line, -1;
    my $bd = board($position);
    my $got = texts($bd->steps);
    push @bad, "$position\n  twin:   $steps\n  engine: $got" unless $got eq $steps;
    $rows++;
    $captures++ if $steps =~ /x/;
    $stuck++ if $steps eq '';
    $size{ $bd->cols . 'x' . $bd->rows }++;
}
is($rows, 423, 'four hundred and twenty-three rows read');
cmp_ok($captures, '>', 200, "$captures of them have a capture");
cmp_ok($rows - $captures - $stuck, '>', 20, ($rows - $captures - $stuck) . ' have paikas only');
cmp_ok(scalar(keys %size), '>=', 5, 'on ' . join(', ', sort keys %size));
is(scalar(@bad), 0, 'and every list is the twin\'s list')
    or diag join "\n", @bad[0 .. ($#bad < 2 ? $#bad : 2)];
}

# THE SAME FOR WHOLE MOVES. t/moves.txt is the twin's list of every whole move
# of each position: the chain, the stop, the direction rule and the rule
# against standing on a point twice, all in one comparison.
{
open my $fh, '<', "$FindBin::Bin/moves.txt" or die "t/moves.txt: $!";
my ($rows, $moves, $chains, $longest, $stuck, @bad) = (0, 0, 0, 0, 0);
while (my $line = <$fh>) {
    chomp $line;
    next if $line =~ /\A#/ || $line !~ /\S/;
    my ($position, $list) = split /\t/, $line, -1;
    my $bd = board($position);
    my $got = mtexts($bd->moves);
    push @bad, "$position\n  twin:   $list\n  engine: $got" unless $got eq $list;
    $rows++;
    $stuck++ if $list eq '';
    for my $m (split ' ', $list) {
        $moves++;
        my $steps = () = $m =~ /-/g;
        $chains++ if $steps > 1;
        $longest = $steps if $steps > $longest;
    }
}
is($rows, 285, 'two hundred and eighty-five rows of whole moves read');
cmp_ok($moves, '>', 3000, "$moves whole moves in them");
cmp_ok($chains, '>', 2000, "$chains of them chains of two steps or more");
cmp_ok($longest, '>=', 8, "the longest of $longest steps");
cmp_ok($stuck, '>=', 1, "$stuck positions with no move at all");
is(scalar(@bad), 0, 'and every list is the twin\'s list')
    or diag join "\n", @bad[0 .. ($#bad < 1 ? $#bad : 1)];
}

done_testing();
