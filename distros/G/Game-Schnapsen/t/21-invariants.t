#!perl
use 5.010; use strict; use warnings;
use Test::More;
use Digest::SHA ();

use Game::Schnapsen ();
use Game::Schnapsen::Bot ();
use Game::Schnapsen::Card qw(points_of);
use Game::Schnapsen::Deck qw(pack_for);
use Game::Schnapsen::Variant qw(variants hand_size);

# THERE IS NO PERFT FOR THIS FAMILY, so this file is what stands in for one:
# five properties asserted after EVERY move of a large bot-versus-bot sweep,
# rather than on positions chosen because somebody thought of them.
#
# It is the cheapest file in the distribution and it is the one that would catch
# a draw taken from the wrong end, a card removed from a hand twice, a trick
# counted to both seats, and a close that quietly loses the talon.

sub seed { return Digest::SHA::sha256($_[0]) }
my @VARIANTS = variants();
use constant MAX_MOVES => 4000;

sub every_card {
    my ($d) = @_;
    return (@{ $d->hand_of('p1')->cards }, @{ $d->hand_of('p2')->cards },
            @{ $d->talon },
            (defined $d->turn_up ? ($d->turn_up) : ()),
            (defined $d->lead ? ($d->lead) : ()),
            map { ($_->{lead}, $_->{follow}) } @{ $d->tricks });
}

subtest 'five invariants, after every move of every match' => sub {
    plan tests => 6 * @VARIANTS;
    for my $v (@VARIANTS) {
        my $pack = join ',', @{ pack_for($v) };
        my $size = hand_size($v);
        my (@lost, @points, @talon, @hands, @gp, $checks, $matches);
        $checks = 0;

        for my $n (1 .. 20) {
            my $s = seed("inv $v $n");
            my $g = Game::Schnapsen->build(variant => $v, seed => $s, dealer => 'p1');
            my %bot = (p1 => Game::Schnapsen::Bot->new(level => 2, seed => $s . 'p1'),
                       p2 => Game::Schnapsen::Bot->new(level => 1, seed => $s . 'p2'));

            my $look = sub {
                my ($where) = @_;
                my $d = $g->deal;
                $checks++;

                # 1. every card is in exactly one place
                my @all = every_card($d);
                push @lost, "$n $where: " . scalar(@all)
                    unless join(',', sort { $a <=> $b } @all) eq $pack;

                # 2. the card points in play plus the card points taken is 120
                my $live = 0;
                $live += points_of($_)
                    for (@{ $d->hand_of('p1')->cards }, @{ $d->hand_of('p2')->cards },
                         @{ $d->talon },
                         (defined $d->turn_up ? ($d->turn_up) : ()),
                         (defined $d->lead ? ($d->lead) : ()));
                my $melded = 0;
                $melded += $_->{value} for grep { $_->{counted} } @{ $d->melds };
                push @points, "$n $where: " . ($live + $d->points_of('p1')
                                               + $d->points_of('p2') - $melded)
                    unless $live + $d->points_of('p1') + $d->points_of('p2') - $melded == 120;

                # 3. talon_left counts what is there; draw_left counts what may be
                #    drawn. They agree EXCEPT after a close, where the cards remain
                #    and nothing more may be taken. That is the one place the two
                #    numbers legitimately differ, so it is asserted as a difference
                #    rather than allowed by a loose comparison.
                if ($d->closed) {
                    push @talon, "$n $where: closed but draw_left is " . $d->draw_left
                        unless $d->draw_left == 0;
                }
                else {
                    push @talon, "$n $where: " . $d->talon_left . ' vs ' . $d->draw_left
                        unless $d->talon_left == $d->draw_left;
                }

                # 4. hands are the variant's size, or one short mid-trick, and the
                #    two are never more than one card apart
                my ($a, $b) = map { $d->hand_of($_)->count } qw(p1 p2);
                push @hands, "$n $where: $a and $b" if abs($a - $b) > 1;
                push @hands, "$n $where: $a > $size" if $a > $size || $b > $size;
            };

            $look->('start');
            my $i = 0;
            while (!$g->over && $i++ < MAX_MOVES) {
                my $seat = $g->turn or last;
                my $move = $bot{$seat}->choose($g, $seat) or last;
                $g->apply($seat, $move);
                $look->('move ' . $i);
            }
            $matches++;

            # 5. game points awarded across a match equal game points moved
            my $moved = 0;
            $moved += $_->{game_points} for grep { $_->{winner} } @{ $g->deals };
            my $dir = Game::Schnapsen::Variant::match_direction($v);
            my $start = Game::Schnapsen::Variant::match_start($v);
            my $drift = abs($g->scores->{p1} - $start) + abs($g->scores->{p2} - $start);
            push @gp, "$n: $moved awarded, $drift moved" unless $moved == $drift;
        }

        is(scalar @lost, 0, "$v: every card is in exactly one place, always")
            or diag(join ', ', @lost[0 .. 2]);
        is(scalar @points, 0, "$v: and the 120 card points are all accounted for")
            or diag(join ', ', @points[0 .. 2]);
        is(scalar @talon, 0, "$v: talon_left and draw_left agree except across a close")
            or diag(join ', ', @talon[0 .. 2]);
        is(scalar @hands, 0, "$v: and the hands stay the right size")
            or diag(join ', ', @hands[0 .. 2]);
        is(scalar @gp, 0, "$v: game points awarded equal game points moved")
            or diag(join ', ', @gp[0 .. 2]);
        cmp_ok($checks, '>', 1000,
               "$v: $checks positions inspected across $matches matches");
    }
};

subtest 'the sweep really does reach the interesting states' => sub {
    # A sweep that never closed a talon, never declared a marriage and never
    # claimed would pass everything above while inspecting only the dull half of
    # the game. So the states the invariants exist to guard are counted.
    plan tests => 4 * @VARIANTS;
    for my $v (@VARIANTS) {
        my %saw;
        for my $n (1 .. 20) {
            my $s = seed("inv $v $n");
            my $g = Game::Schnapsen->build(variant => $v, seed => $s, dealer => 'p1');
            my %bot = (p1 => Game::Schnapsen::Bot->new(level => 2, seed => $s . 'p1'),
                       p2 => Game::Schnapsen::Bot->new(level => 1, seed => $s . 'p2'));
            my $i = 0;
            while (!$g->over && $i++ < MAX_MOVES) {
                my $seat = $g->turn or last;
                my $move = $bot{$seat}->choose($g, $seat) or last;
                $saw{ $move->{kind} }++;
                $saw{closed_state}++ if $g->deal->closed;
                $g->apply($seat, $move);
            }
            $saw{ $_->{how} }++ for @{ $g->deals };
        }
        cmp_ok($saw{close} // 0, '>', 0, "$v: a talon was closed");
        cmp_ok($saw{closed_state} // 0, '>', 0, "$v: and play continued while it was");
        cmp_ok($saw{marriage} // 0, '>', 0, "$v: a marriage was declared");
        cmp_ok($saw{claim} // 0, '>', 0, "$v: and a deal was claimed");
    }
};

done_testing();
