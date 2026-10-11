package Game::Fanorona::Bot;

use 5.014;
use strict;
use warnings;

use Carp ();
use Digest::SHA ();

our $VERSION = '0.01';

our @LADDER = (0, 100, 1_000, 10_000, 30_000);

my $number = sub {
    my (@parts) = @_;
    my $bytes = join '|', map { defined $_ ? $_ : '' } @parts;
    Carp::croak('Game::Fanorona::Bot: a seed is bytes, and that one holds a character above 255')
        unless utf8::downgrade($bytes, 1);
    return unpack 'N', Digest::SHA::sha256($bytes);
};

sub levels { @LADDER }

my $level_of = sub {
    my (%with) = @_;
    my $level = defined $with{level} ? $with{level} : $LADDER[-1];
    Carp::croak('Game::Fanorona::Bot: a level is a whole number of positions to look at, 0 for the player that only counts')
        unless !ref $level && $level =~ /\A[0-9]{1,9}\z/;
    return $level;
};

my $check = sub {
    my ($game) = @_;
    Carp::croak('Game::Fanorona::Bot: this takes a Game::Fanorona')
        unless ref $game && $game->can('search') && $game->can('steps') && $game->can('step');
    return;
};

my $greedy = sub {
    my ($game, $seed) = @_;
    my $copy = Game::Fanorona->new(variant => $game->variant, position => $game->position);
    my (@made, $n);
    if ($game->in_chain) {
        return { move => '', steps => [], level => 0, nodes => '0', depth => 0, score => undef };
    }
    while (1) {
        my @steps = $copy->steps or last;
        my ($most) = sort { $b <=> $a } map { scalar @{ $_->{takes} } } @steps;
        my @best = grep { @{ $_->{takes} } == $most } @steps;
        my $pick = $best[ $number->('greedy', $seed, $game->signature, $game->ply, $n++) % @best ];
        my $turn = $copy->turn;
        $copy->step($pick->{string}) or last;
        push @made, $pick;
        last if $copy->over || !$copy->in_chain || $copy->turn ne $turn;
    }
    my $move = @made ? $made[0]{from} . join('', map { substr($_->{string}, 2) } @made) : '';
    return { move => $move, steps => \@made, level => 0, nodes => '0', depth => 0, score => undef };
};

sub think {
    my ($class, $game, %with) = @_;
    $check->($game);
    return undef if $game->over;
    my $level = $level_of->(%with);
    my $seed  = $with{seed};
    return $greedy->($game, $seed) if $level == 0;
    my $found = $game->search(
        budget => $level,
        seed   => 1 + $number->('search', $seed, $game->signature, $game->ply, $game->in_progress) % 4_294_967_295,
        (defined $with{depth} ? (depth => $with{depth}) : ()),
    ) or return undef;
    $found->{level} = $level;
    return $found;
}

sub choose {
    my ($class, $game, %with) = @_;
    my $thought = $class->think($game, %with) or return undef;
    return $thought->{move};
}

sub play {
    my ($class, $game, %with) = @_;
    my $thought = $class->think($game, %with) or return undef;
    my $turn = $game->turn;
    for my $step (@{ $thought->{steps} }) {
        $game->step($step->{string})
            or Carp::croak('Game::Fanorona::Bot: the game refused ' . $step->{string} . ': ' . $game->error->message);
    }
    $game->stop if !$game->over && $game->in_chain && defined $game->turn && $game->turn eq $turn;
    return $thought;
}

sub hint {
    my ($class, $game, %with) = @_;
    return $class->think($game, %with, level => $LADDER[-1]);
}

sub answer_draw {
    my ($class, $game, %with) = @_;
    $check->($game);
    return undef if $game->over;
    my $offered = $game->draw_offered_by // return undef;
    my $me = $offered eq 'white' ? 'black' : 'white';
    my $mine = $game->evaluate * ($me eq 'white' ? 1 : -1);
    my $stuck = $game->quiet * 2 >= $game->quiet_limit;
    return ($mine < 0 || ($mine == 0 && $stuck)) ? 'accept' : 'decline';
}

1;

__END__

=head1 NAME

Game::Fanorona::Bot - a player for fanorona, at a strength you choose

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Fanorona;
    use Game::Fanorona::Bot;

    my $game = Game::Fanorona->new;
    until ($game->over) {
        Game::Fanorona::Bot->play($game, level => 10_000, seed => 'a seed');
    }
    print $game->result->how, "\n";

=head1 DESCRIPTION

A player. It has no state: every method is a class method that is handed the
game.

=head2 A level is a number of positions

A level is how many positions the player may look at before it moves. It is a
count and not a time, so a level plays the same on a fast machine as on a slow
one, and the same position, level and seed always give the same move.

Level 0 does not look ahead at all. It makes the capture that takes most,
goes on taking while it can, and otherwise moves a stone at random.

C<levels> lists the levels this distribution has measured against each other.
Any other number is a level too.

=head2 What it is and is not good at

It counts stones, likes its stones to have room to move and to stand towards
the middle of the board, and looks ahead. Where there is a capture to be
found within its reach it finds it, and it does not leave stones to be taken.

It has no plan for an ending. With a few stones against fewer, it will often
not find the way to finish, and the game will be drawn when sixty moves have
passed with nothing taken.

=head1 CLASS METHODS

=head2 play

    my $thought = Game::Fanorona::Bot->play($game, level => 10_000, seed => $seed);

Makes the player's move on the game: every step of it, and the stop if one is
needed. From the middle of a move it finishes that move. Returns what
C<think> returns, or C<undef> if the game is over.

=head2 think

    my $thought = Game::Fanorona::Bot->think($game, level => 10_000, seed => $seed);

What the player would do, without doing it:

    {
        move  => 'b2-c2A-c3A',   # '' when the thing to do is stop
        steps => [ ... ],        # the same, a step at a time, as $game->steps gives them
        level => 10000,
        depth => 4,              # whole moves looked ahead
        nodes => '9984',         # positions looked at
        score => 100,            # for the side to move; undef at level 0
    }

C<level> is the strongest of C<levels> unless given. C<seed> may be any
string of bytes; it settles the choice among moves the player thinks equal,
and at level 0 the choice among captures of the same size. A seed holding a
character above 255 croaks. C<depth> limits the
looking ahead to that many whole moves.

=head2 choose

The move as a string, and nothing else.

=head2 hint

C<think> at the strongest level, whatever level is asked for.

=head2 answer_draw

    my $answer = Game::Fanorona::Bot->answer_draw($game);

C<accept> or C<decline>, for the side a standing offer was made to; C<undef>
when there is no offer or the game is over. It accepts when it is behind in
stones, and when it is level and half the quiet limit has already passed with
nothing taken.

=head2 levels

The measured levels, weakest first.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
