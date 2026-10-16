use strict;
use warnings;
use Test::More;
use FindBin;

use Game::Sternhalma::Engine ':all';
my $E = 'Game::Sternhalma::Engine';

# THE TWIN'S LISTS. t/steps.txt was written by a second program, in another
# language, from the rules text alone: plan_game_sternhalma/twin/sternhalma.py.
# It shares no table with the engine, not even the hole numbering, which it
# derives from the star itself. Read, never run: a smoker does not need python.

open my $fh, '<', "$FindBin::Bin/steps.txt" or die "t/steps.txt: $!";
my (%rows, %seats, @bad, $positions_bad, $hops, $steps, $f_landings, $lands_on_start);
($hops, $steps, $f_landings, $lands_on_start, $positions_bad) = (0) x 5;
my %pos_seen;

while (my $line = <$fh>) {
    chomp $line;
    next if $line =~ /\A#/ || $line !~ /\S/;
    my ($kind, $position, @rest) = split /\t/, $line, -1;
    $rows{$kind}++;
    my ($bd, $code) = $E->from_string($position);
    unless ($bd) { $positions_bad++; next }
    $pos_seen{$position}++;
    if ($kind eq 'S') {
        $seats{ $bd->seats . 'x' . $bd->pieces }++;
        my @cells = split ' ', $rest[0];
        my @mine = grep { defined $bd->at($_) } 0 .. HOLES - 1;
        push @bad, "$position: the twin lists " . scalar(@cells) . " pieces, the engine has " . scalar(@mine)
            unless @cells == @mine;
        for my $cell (@cells) {
            my ($h, $s, $p) = $cell =~ /\A(\d+):([\d,]*)\/([\d,]*)\z/ or do { push @bad, "bad cell $cell"; next };
            my $got_s = join ',', sort { $a <=> $b } $bd->steps($h);
            my $got_p = join ',', sort { $a <=> $b } $bd->hops($h);
            push @bad, "$position hole $h\n  twin:   $s/$p\n  engine: $got_s/$got_p"
                unless $got_s eq $s && $got_p eq $p;
            $steps += () = $s =~ /\d+/g;
            $hops += () = $p =~ /\d+/g;
        }
    }
    elsif ($kind eq 'F') {
        my ($at, $from, $want) = @rest;
        my $got = join ',', sort { $a <=> $b } $bd->hops($at, $from);
        push @bad, "$position at $at from $from\n  twin:   $want\n  engine: $got" unless $got eq $want;
        my @w = $want =~ /\d+/g;
        $f_landings += @w;
        $lands_on_start++ if grep { $_ == $from } @w;
    }
    else {
        push @bad, "a row of kind '$kind'";
    }
}

is($rows{S}, 354, '354 positions with every piece\'s steps and hops');
is($rows{F}, 319, '319 positions with a piece part way through a chain, one to three hops in');
is($positions_bad, 0, 'every position string the twin wrote is one the engine reads');
is_deeply([ sort keys %seats ], [ qw(2x10 2x15 3x10 3x15 4x10 6x10) ], 'on every seat count and both piece counts');
cmp_ok($steps, '>', 20_000, "$steps steps compared");
cmp_ok($hops, '>', 5_000, "$hops hops compared");
cmp_ok($f_landings, '>', 300, "$f_landings landings part way through a chain");
cmp_ok($lands_on_start, '>', 50, "$lands_on_start of those chains can land on the start they left");
cmp_ok($lands_on_start, '<', $rows{F}, '  and the rest cannot, so the start is not simply always a landing');
is(scalar(@bad), 0, 'and every list is the twin\'s list')
    or diag join "\n", @bad[0 .. ($#bad < 4 ? $#bad : 4)];

done_testing();
