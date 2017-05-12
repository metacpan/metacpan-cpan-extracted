#
# This file is part of Games-Risk
#
# This software is Copyright (c) 2008 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.010;
use strict;
use warnings;

package Games::Risk::AI;
# ABSTRACT: base class for all ais
$Games::Risk::AI::VERSION = '4.000';
use POE        qw{ Loop::Tk };
use Carp;
use List::Util qw{ shuffle };
use Readonly;

use constant K => $poe_kernel;

use base qw{ Class::Accessor::Fast };
__PACKAGE__->mk_accessors( qw{ game player } );

use Games::Risk::Logger qw{ debug };

#--
# CLASS METHODS

# -- constructor

#
# my $ai = Games::Risk::AI::$AItype->new( \%params );
#
# Note that you should not instantiate a Games::Risk::AI object directly:
# instantiate an AI subclass.
#
# Create a new AI of type $AItype. All subclasses accept the following
# parameters:
#  - player: the Game::Risk::Player associated to the AI. (mandatory)
#
sub new {
    my ($pkg, $args) = @_;

    # create the object
    my $self = bless $args, $pkg;

    # update object attributes
    $self->game( Games::Risk->new );    # get singleton ref

    return $self;
}



#
# my $id = Games::Risk::AI->spawn( $ai )
#
# This method will create a POE session responsible for the artificial
# intelligence $ai. It will return the poe id of the session newly created. The
# session will also react to the ai's player name (poe alias).
#
sub spawn {
    my (undef, $ai) = @_;

    my $session = POE::Session->create(
        heap          => $ai,
        inline_states => {
            # private events - session management
            _start                => \&_onpriv_start,
            _stop                 => sub { debug( "AI shutdown\n" ) },
            # public events
            attack                => \&_onpub_attack,
            attack_move           => \&_onpub_attack_move,
            exchange_cards        => \&_onpub_exchange_cards,
            move_armies           => \&_onpub_move_armies,
            place_armies          => \&_onpub_place_armies,
            place_armies_initial  => \&_onpub_place_armies_initial,
            shutdown              => \&_onpub_shutdown,
        },
    );
    return $session->ID;
}


#--
# METHODS

# -- public methods

#
# my $str = $ai->description;
#
# Format the subclass description.
#
sub description {
    my ($self) = @_;
    my $descr = $self->_description;
    $descr =~ s/[\n\s]+\z//;
    $descr =~ s/\A\n+//;
    return $descr;
}

#
# my @cards = $ai->exchange_cards;
#
# Check if ai can trade some @cards for armies.
#
sub exchange_cards {
    my ($self) = @_;
    my $me = $self->player;

    my @cards = $me->cards->all;
    return if scalar(@cards) < 3;

    # dispatch cards on their type
    my @a =
        sort { ($b->country->owner eq $me) <=> ($a->country->owner eq $me) }
        grep { $_->type eq 'artillery' } @cards;
    my @c =
        sort { ($b->country->owner eq $me) <=> ($a->country->owner eq $me) }
        grep { $_->type eq 'cavalry'   } @cards;
    my @i =
        sort { ($b->country->owner eq $me) <=> ($a->country->owner eq $me) }
        grep { $_->type eq 'infantry'  } @cards;
    my @j = grep { $_->type eq 'joker' } @cards;
    my $nba = scalar @a;
    my $nbc = scalar @c;
    my $nbi = scalar @i;
    my $nbj = scalar @j;

    # trade cards
    return ($a[0],$c[0],$i[0]) if $nba && $nbc && $nbi;
    return ($a[0],$c[0],$j[0]) if $nba && $nbc && $nbj;
    return ($a[0],$i[0],$j[0]) if $nba && $nbi && $nbj;
    return ($c[0],$i[0],$j[0]) if $nbc && $nbi && $nbj;
    return ($a[0],@j[0..1])    if $nba && $nbj >= 2;
    return ($c[0],@j[0..1])    if $nbc && $nbj >= 2;
    return ($i[0],@j[0..1])    if $nbi && $nbj >= 2;
    return (@j[0..2])          if $nbj >= 3;
    return (@a[0..2])          if $nba >= 3;
    return (@a[0..1],$j[0])    if $nba >= 2 && $nbj;
    return (@c[0..2])          if $nbc >= 3;
    return (@c[0..1],$j[0])    if $nbc >= 2 && $nbj;
    return (@i[0..2])          if $nbi >= 3;
    return (@i[0..1],$j[0])    if $nbi >= 2 && $nbj;

    return;
}


#
# my @where = $ai->move_armies;
#
# See pod in Games::Risk::AI for information on the goal of this method.
#
# This implementation will not move any armies at all.
#
sub move_armies {
    my ($self) = @_;
    return;
}



#--
# EVENTS HANDLERS

# -- public events

#
# event: attack();
#
# request the ai to attack a country, or to end its attack turn.
#
sub _onpub_attack {
    my $ai = $_[HEAP];
    my ($action, @params) = $ai->attack;
    K->post('risk', $action, @params);
}


#
# event: attack_move($src, $dst, $min);
#
# request the ai to move some armies from $src to $dst (minimum $min)
# after a succesful attack.
#
sub _onpub_attack_move {
    my ($ai, $src, $dst, $min) = @_[HEAP, ARG0..$#_];
    my $nb = $ai->attack_move($src, $dst, $min);
    K->post('risk', 'attack_move', $src, $dst, $nb);
}


#
# event: exchange_cards();
#
# request the ai to exchange some cards if it wants to.
#
sub _onpub_exchange_cards {
    my $ai = $_[HEAP];

    # try to exchange cards
    my @cards = $ai->exchange_cards;
    K->post('risk', 'cards_exchange', @cards) if @cards;
}


#
# event: move_armies();
#
# request the ai to move armies between adjacent countries, or to end
# its move turn.
#
sub _onpub_move_armies {
    my $ai = $_[HEAP];

    foreach my $move ( $ai->move_armies ) {
        my ($src, $dst, $nb) = @$move;
        K->post('risk', 'move_armies', $src, $dst, $nb);
    }

    K->post('risk', 'armies_moved');
}


#
# event: place_armies($nb, $continent);
#
# request the ai to place $nb armies, possibly within $continent (if defined).
#
sub _onpub_place_armies {
    my ($ai, $nb, $continent) = @_[HEAP, ARG0, ARG1];

    # place armies
    foreach my $where ( $ai->place_armies($nb, $continent) ) {
        my ($country, $nb) = @$where;
        K->post('risk', 'armies_placed', $country, $nb);
    }
}


#
# event: place_armies_initial();
#
# request the ai to place 1 army on a country.
#
sub _onpub_place_armies_initial {
    my $ai = $_[HEAP];

    my ($where) = $ai->place_armies(1);
    my ($country, $nb) = @$where;
    K->post('risk', 'initial_armies_placed', $country, $nb);
}


#
# event: shutdown()
#
# request the ai to terminate itself.
#
sub _onpub_shutdown {
    my $ai = $_[HEAP];
    K->alias_remove( $ai->player->name );
}


# -- private events - session management

#
# event: _start( \%params )
#
# Called when the poe session gets initialized. Receive a reference
# to %params, same as spawn() received.
#
sub _onpriv_start {
    my $ai = $_[HEAP];
    K->alias_set( $ai->player->name );
    K->post('risk', 'player_created', $ai->player);
}


1;

__END__

=pod

=head1 NAME

Games::Risk::AI - base class for all ais

=head1 VERSION

version 4.000

=head1 SYNOPSIS

    [don't use this class directly]

=head1 DESCRIPTION

This module is the base class for all artificial intelligence. It implements
also a POE session representing an AI player. This POE session will retain the
C<Games::Risk::AI::*> object as heap.

=head1 METHODS

=head2 Constructor

=over 4

=item * my $ai = Games::Risk::AI::$AItype->new( \%params )

Create a new AI of type C<$AItype>. Note that you should not instantiate a
C<Games::Risk::AI> object directly: instantiate an AI subclass instead. All
subclasses accept the following parameters:

=over 4

=item * player: the C<Game::Risk::Player> associated to the AI. (mandatory)

=back

Note that the AI will automatically get a name, and update the player object.

=item * my $id = Games::Risk::AI->spawn( $ai )

This method will create a POE session responsible for the artificial
intelligence C<$ai>. It will return the poe id of the session newly created.
The session will also react to the ai's player name (poe alias).

=back

=head2 Object methods

An AI object will typically implements the following methods:

=over 4

=item * my ($action, [$from, $country]) = $ai->attack()

Return the attack plan, which can be either C<attack> or C<attack_end> to stop
this step of the ai's turn. If C<attack> is returned, then it should also
supply C<$from> and C<$country> parameters to know the attack parameters.

=item * my $nb = $ai->attack_move($src, $dst, $min)

Return the number of armies to move from C<$src> to C<$dst> after a
successful attack (minimum C<$nb> to match the number of attack dices).

=item * my $str = $ai->description()

Return a short description of the ai and how it works.

=item * my $str = $ai->difficulty()

Return a difficulty level for the ai.

=item * my @cards = $ai->exchange_cards()

Check if ai can trade some C<@cards> for armies.

=item * my @moves = $ai->move_armies()

Return a list of C<[ $src, $dst, $nb ]> tuples (two
C<Games::Risk::Country> and an integer), each defining a move of
C<$nb> armies from $dst to C<$src>.

=item * my @where = $ai->place_armies($nb, [$continent])

Return a list of C<[ $country, $nb ]> tuples (a C<Games::Risk::Country>
and an integer) defining where to place C<$nb> armies. If C<$continent> (a
C<Games::Risk::Continent>) is defined, all the returned C<$countries>
should be within this continent.

=back

Note that some of those methods may be inherited from the base class, when it
provide sane defaults.

=head1 SEE ALSO

L<Games::Risk>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
