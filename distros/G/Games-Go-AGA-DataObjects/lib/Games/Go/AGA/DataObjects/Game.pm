#===============================================================================
#
#         FILE:  Games::Go::AGA::DataObjects::Game.pm
#
#        USAGE:  use Games::Go::AGA::DataObjects::Game;
#
#      PODNAME:  Games::Go::AGA::DataObjects::Game
#     ABSTRACT:  model an AGA game
#
#       AUTHOR:  Reid Augustin (REID), <reid@hellosix.com>
#      CREATED:  11/19/2010 03:13:05 PM PST
#===============================================================================

use strict;
use warnings;

# the Game class is useful for tournament pairing
package Games::Go::AGA::DataObjects::Game;
use Moo;
use namespace::clean;

use Carp;
use Scalar::Util qw(refaddr weaken);
use Try::Tiny;
use Games::Go::AGA::Parse::Util qw( Rank_to_Rating );
use Games::Go::AGA::DataObjects::Types qw( isa_Int isa_CodeRef isa_Handicap isa_Komi );

our $VERSION = '0.152'; # VERSION

sub isa_Player   { die("$_[0] is not a Games::Go::AGA::DataObjects::Player\n") if (ref $_[0] ne 'Games::Go::AGA::DataObjects::Player') }
has black    => (
    is       => 'rw',
    isa      => \&isa_Player,
    weak_ref => 1, # Players have Games, Games have Players, so weaken
    trigger  => sub
        {
            my $self = shift;
            $self->_set_player('black', @_);
        },
);
has white    => (
    is       => 'rw',
    isa      => \&isa_Player,
    weak_ref => 1,
    trigger  => sub
        {
            my $self = shift;
            $self->_set_player('white', @_);
        },
);
has table_number    => (
    is       => 'rw',
    isa      => \&isa_Int,
    lazy => 1,
    default  => sub { 0 },
    trigger  => sub { shift->changed; },
);
has handi    => (
    is       => 'rw',
    isa      => \&isa_Handicap,
    lazy => 1,
    default  => sub { 0 },
    trigger  => sub { shift->changed; },
#   alias    => 'handicap',
);
has komi     => (
    is       => 'rw',
    isa      => \&isa_Komi,
    lazy => 1,
    default  => sub { 5.5 },
    trigger  => sub { shift->changed; },
);
has result   => (
    is       => 'rw',
    lazy => 1,
    default  => '?',
    trigger  => sub {
        my ($self, $new) = @_;

        if (ref $new) {     # better be a Games::Go::AGA::DataObjects::Player
            my $id = $new->id;
            if ($id eq $self->white->id) { $self->result('w'); return }
            if ($id eq $self->black->id) { $self->result('b'); return }
        }
        $new ||= '?';
        $new = lc $new;
        if ($new ne '?' and $new ne 'w' and $new ne 'b') {
            croak("result must be '?' (or false), 'w', 'b', or one of the players\n");
        }
        $self->{result} = $new;
        $self->changed;
    },
);
has change_callback   => (
    isa => \&isa_CodeRef,
    is => 'rw',
    lazy => 1,
    default => sub { sub { } }
);
has built => (
    is => 'rw',
);

sub BUILD {
    my ($self, $args) = @_;

    if (defined $args and exists $args->{winner}) {
        $self->result(delete $args->{winner});
    }
    $self->built(1);
}

sub changed {
    my ($self) = @_;

    &{$self->change_callback}(@_);
}

sub _set_player {
    my ($self, $color, $new) = @_;

    if (    $self->built            # after object is built,
        and $self->result ne '?') { # can't change players if result is set
        $self->{$color} = $self->{"prev_$color"};   # restore
        croak 'Result already set, cannot change players';
    }
    $self->{"prev_$color"} = $new;
    $self->changed;
}

sub winner {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->result($new);
    }
    return $self->white if ($self->result eq 'w');
    return $self->black if ($self->result eq 'b');
    return; # undef
}

sub loser {
    my ($self, $new) = @_;

    return $self->black if ($self->result eq 'w');
    return $self->white if ($self->result eq 'b');
    return; # undef
}

sub opponent {
    my ($self, $player) = @_;

    my $me = $player->id;
    return $self->white if ($self->black->id eq $me);
    return $self->black if ($self->white->id eq $me);
    croak "ID $me is not in this game";
}

sub swap {
    my ($self) = @_;

    my $white = $self->white;
    $self->{white} = $self->black;
    $self->{black} = $white;
    $self->changed;
}

sub handicap {
    my ($self, $default_komi) = @_;

    if (defined $self->winner) {
        croak 'Winner already set, cannot change players';
    }

    $default_komi = 7.5 if (not defined $default_komi);
    my $white = $self->white;
    my $black = $self->black;
    my $rankDiff = $self->_rank_to_level($white) - $self->_rank_to_level($black);
    if ($rankDiff < 0.5) {
        $self->handi(0);
        $self->komi($default_komi);   # normal komi game
    }
    elsif ($rankDiff < 1.0) {
        $self->handi(0);
        $self->komi(0.5);   # no komi game, white wins ties
    }
    elsif ($rankDiff < 1.5) {
        $self->handi(0);
        $self->komi(-$default_komi);  # reverse komi game
    }
    else {
        $self->handi(int $rankDiff + 0.5);  # handicap game
        $self->komi(0.5);                   # white wins ties
    }
    # TODO handi/komi have different relationship in AGA vs ING rules...
    $self->changed;
}

sub auto_handicap {
    my ($self, $default_komi) = @_;

    if (defined $self->winner) {
        croak 'Winner already set, cannot change players';
    }

    my $white = $self->white;
    my $black = $self->black;
    my $rankDiff = $self->_rank_to_level($white) - $self->_rank_to_level($black);
    if ($rankDiff < 0.1) {  # black is significantly stronger than white - swap
        $self->{white} = $black;
        $self->{black} = $white;
    };
    $self->handicap($default_komi);
}

# AGA ratings have a hole between +1 and -1 which messes up
#   handicap/komi calculations.  Collapse that hole to make a 'level'
sub _rank_to_level {
    my ($self, $player) = @_;

    my $level = $player->adj_rating(-1);
    return $level + (($level > 0) ? -1 : 1);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Go::AGA::DataObjects::Game - model an AGA game

=head1 VERSION

version 0.152

=head1 SYNOPSIS

    use Games::Go::AGA::DataObjects::Game;

    my $game = Games::Go::AGA::DataObjects::Game->new(
        black  => $player,  # Games::Go::AGA::DataObjects::Player
        white  => $another, # this too
        handi  => 0,        # positive integer
        komi   => 5.5,      # number
    );
    $game->winner($player); # set the winner

=head1 DESCRIPTION

Games::Go::AGA::DataObjects::Game models a single game.

=head1 ACCESSORS

Accessor methods are defined for the following attributes:

=over 8

=item black     Games::Go::AGA::DataObjects::Player

=item white     Games::Go::AGA::DataObjects::Player

=item handi     Integer from 0 to 99 (probably should be 9 or less)

=item komi      Number

=item winner    Games::Go::AGA::DataObjects::Player or 'b' or 'w' or undef

=item loser     read only (set automatically when winner is set)

=back

Accessors are used like this to retrieve an attribute:

    my $winner = $game->winner;

and like this to set an attribute:

    $game->winner($player);

All attributes are read/write, and are type-checked on setting.

Attempting to set the B<winner> to a player who is not either the B<black>
or the B<white> player causes an exception to be thrown.

Attempting to set B<black> or B<white> player when a B<winner> is already
set causes an exception to be thrown.

=head1 METHODS

=head2 my $loser = $game->loser;

Simalar to the B<winner> accessor, but read only - returns the player who
is not the B<winner>, or undef if no B<winner> is set.

=head2 $game->handicap( $default_komi );

=head2 $game->auto_handicap( $default_komi );

Sets handicap and komi based on the adjusted ratings of the two players.
B<auto_handicap> swaps white and black players if black's rating is significantly
higher than white's.  C<$default_komi> is the value set for even games or
C<-$default_komi> for reverse komi games.  If C<$default_komi> is undefined, 7.5 is
used.

=head1 SEE ALSO

=over 4

=item Games::Go::AGA

=item Games::Go::AGA::DataObjects

=item Games::Go::AGA::Parse

=item Games::Go::AGA::Gtd

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
