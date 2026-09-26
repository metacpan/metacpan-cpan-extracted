package DurakFixture;

use strict;
use warnings;

use Exporter 'import';

use Game::Durak;
use Game::Durak::Bout ();
use Game::Durak::Card qw(id_of name_of six_of);
use Game::Durak::Rules qw(cap_for);

our @EXPORT_OK = qw(seed32 game_with cards names kinds end_of refill_of);

# A position written by hand, so that a test says what it is testing instead
# of hunting for a seed that happens to produce it. The trump is 'ro' on the
# game, so the fixture searches seeds for the trump it wants and then replaces
# the hands, the talon and the bout.

sub seed32 { return sprintf '%-32.32s', $_[0] }

sub cards { return [ map { id_of($_) } @_ ] }

sub names { return join ' ', map { name_of($_) } @{ $_[0] } }

# An error is rendered rather than dereferenced: apply returns either events
# or one error, and a test that asked for events and got a refusal should say
# which refusal instead of dying on a blessed object that is not a hash.
sub kinds {
    return join ' ', map {
          ref $_ eq 'HASH'                    ? $_->{kind}
        : eval { $_->isa('Game::Durak::Error') } ? 'error:' . $_->code
        :                                       'not an event'
    } @_;
}

# An empty hashref rather than undef, so that a missing event fails the
# assertion that wanted it instead of dying and taking every later block of
# the file with it.
sub end_of {
    my ($end) = grep { ref $_ eq 'HASH' && $_->{kind} eq 'bout_end' } @_;
    return $end || {};
}

sub refill_of {
    my ($refill) = grep { ref $_ eq 'HASH' && $_->{kind} eq 'refill' } @_;
    return $refill || {};
}

sub game_with {
    my (%o) = @_;

    my $trump = defined $o{trump} ? $o{trump} : 'H';
    my $game;
    for my $i (1 .. 500) {
        my $g = Game::Durak->build(seed => seed32("fixture-$trump-$i"));
        next unless $g->trump eq $trump;
        $game = $g;
        last;
    }
    die "no seed in five hundred turned up a $trump trump\n" unless $game;

    my $attacker = defined $o{attacker} ? $o{attacker} : 1;
    my $defender = 3 - $attacker;

    $game->hands({
        1 => [ sort { $a <=> $b } @{ cards(@{ $o{hand1} }) } ],
        2 => [ sort { $a <=> $b } @{ cards(@{ $o{hand2} }) } ],
    });
    my $talon = cards(@{ $o{talon} || [] });
    $game->talon($talon);

    # The turn-up is the last card of the talon unless a test names one, which
    # is how a position with the turn-up already drawn is written.
    $game->trump_card(
          $o{trump_card} ? id_of($o{trump_card})
        : @$talon        ? $talon->[-1]
        :                  $game->trump_card
    );

    my $six = six_of($trump);
    my ($owner) = grep {
        scalar grep { $_ == $six } @{ $game->hands->{$_} }
    } 1, 2;
    $game->six_owner(exists $o{six_owner} ? $o{six_owner} : $owner);

    $game->discard(defined $o{discard} ? $o{discard} : 0);
    $game->history([]);
    $game->over(0);

    $game->bout(Game::Durak::Bout->build(
        attacker => $attacker,
        defender => $defender,
        cap      => defined $o{cap}
                    ? $o{cap}
                    : cap_for(scalar @{ $game->hands->{$defender} }),
    ));

    return $game;
}

1;
