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

package Games::Risk::Controller;
# ABSTRACT: controller poe session for risk
$Games::Risk::Controller::VERSION = '4.000';
use POE             qw{ Loop::Tk };
use List::Util      qw{ min shuffle };
use Readonly;

use Games::Risk::I18n      qw{ T };
use Games::Risk::Logger    qw{ debug };

use constant K => $poe_kernel;


Readonly my $ATTACK_WAIT_AI    => 1.250; # FIXME: hardcoded
Readonly my $ATTACK_WAIT_HUMAN => 0.300; # FIXME: hardcoded
Readonly my $TURN_WAIT         => 1.800; # FIXME: hardcoded
Readonly my $WAIT              => 0.100; # FIXME: hardcoded
Readonly my $START_ARMIES      => 5;



#--
# CLASS METHODS

# -- public methods

#
# my $id = Games::Risk::Controller->spawn( \%params )
#
# This method will create a POE session responsible for a classical risk
# game. It will return the poe id of the session newly created.
#
# You can tune the session by passing some arguments as a hash reference.
# Currently, no params can be tuned.
#
sub spawn {
    my (undef, $game) = @_;

    my $session = POE::Session->create(
        heap          => $game,
        inline_states => {
            # private events - session management
            _start                  => \&_onpriv_start,
            _stop                   => sub { debug( "GR shutdown\n" ) },
            # private events - game states
            _gui_ready              => \&_onpriv_create_players,
            _players_created        => \&_onpriv_assign_countries,
            _countries_assigned     => \&_onpriv_place_armies_initial_count,
            _place_armies_initial   => \&_onpriv_place_armies_initial,
            _initial_armies_placed  => \&_onpriv_turn_begin,
            _begin_turn             => \&_onpriv_turn_begin,
            _turn_begun             => \&_onpriv_player_next,
            _player_begun           => \&_onpriv_cards_exchange,
            _cards_exchanged        => \&_onpriv_place_armies,
            _armies_placed          => \&_onpriv_attack,
            _attack_done            => \&_onpriv_attack_done,
            _attack_end             => \&_onpriv_move_armies,
            _armies_moved           => \&_onpriv_player_next,
            # public events
            map_loaded              => \&_onpub_map_loaded,
            player_created          => \&_onpub_player_created,
            initial_armies_placed   => \&_onpub_initial_armies_placed,
            armies_moved            => \&_onpub_armies_moved,
            cards_exchange          => \&_onpub_cards_exchange,
            armies_placed           => \&_onpub_armies_placed,
            attack                  => \&_onpub_attack,
            attack_move             => \&_onpub_attack_move,
            attack_end              => \&_onpub_attack_end,
            move_armies             => \&_onpub_move_armies,
            new_game                => \&_onpub_new_game,
            quit                    => \&_onpub_quit,
            shutdown                => \&_onpub_shutdown,
        },
    );
    return $session->ID;
}


#--
# EVENTS HANDLERS

# -- public events

#
# event: armies_moved();
#
# fired when player has finished moved armies at the end of the turn.
#
sub _onpub_armies_moved {
    #my $h = $_[HEAP];

    # FIXME: check player is curplayer
    K->delay_set( '_armies_moved' => $WAIT );
}


#
# event: armies_placed($country, $nb);
#
# fired to place $nb additional armies on $country.
#
sub _onpub_armies_placed {
    my ($h, $country, $nb) = @_[HEAP,ARG0, ARG1];

    # FIXME: check player is curplayer
    # FIXME: check country belongs to curplayer
    # FIXME: check validity regarding total number
    # FIXME: check validity regarding continent
    # FIXME: check negative values
    my $left = $h->armies - $nb;
    $h->armies($left);

    $country->set_armies( $country->armies + $nb );
    $h->send_to_all('chnum', $country);

    if ( $left == 0 ) {
        K->delay_set( '_armies_placed' => $WAIT );
    }
}


#
# event: attack( $src, $dst );
#
# fired when a player wants to attack country $dst from $src.
#
sub _onpub_attack {
    my ($h, $src, $dst) = @_[HEAP, ARG0, ARG1];

    my $player = $h->curplayer;

    # FIXME: check player is curplayer
    # FIXME: check src belongs to curplayer
    # FIXME: check dst doesn't belong to curplayer
    # FIXME: check countries src & dst are neighbours
    # FIXME: check src has at least 1 army

    my $armies_src = $src->armies - 1; # 1 army to hold $src
    my $armies_dst = $dst->armies;
    $h->src($src);
    $h->dst($dst);


    # roll the dices for the attacker
    my $nbdice_src = min $armies_src, 3; # don't attack with more than 3 armies
    my @attack;
    push( @attack, int(rand(6)+1) ) for 1 .. $nbdice_src;
    @attack = reverse sort @attack;
    $h->nbdice($nbdice_src); # store number of attack dice, needed for invading

    # roll the dices for the defender. don't defend with 2nd dice if we
    # don't have at least 50% luck to win with it. FIXME: customizable?
    my $nbdice_dst = $nbdice_src > 1
        ? $attack[1] > 4 ? 1 : 2
        : 2; # defend with 2 dices if attacker has only one
    $nbdice_dst = min $armies_dst, $nbdice_dst;
    my @defence;
    push( @defence, int(rand(6)+1) ) for 1 .. $nbdice_dst;
    @defence = reverse sort @defence;

    # compute losses
    my @losses  = (0, 0);
    $losses[ $attack[0] <= $defence[0] ? 0 : 1 ]++;
    $losses[ $attack[1] <= $defence[1] ? 0 : 1 ]++
        if $nbdice_src >= 2 && $nbdice_dst == 2;

    # update countries
    $src->set_armies( $src->armies - $losses[0] );
    $dst->set_armies( $dst->armies - $losses[1] );

    # post damages
    # FIXME: only for human player?
    $h->send_to_all('attack_info', $src, $dst, \@attack, \@defence);

    my $wait = $player->type eq 'ai' ? $ATTACK_WAIT_AI : $ATTACK_WAIT_HUMAN;
    K->delay_set( '_attack_done' => $wait, $src, $dst );
}


#
# event: attack_end();
#
# fired when a player does not want to attack anymore during her turn.
#
sub _onpub_attack_end {
    K->delay_set( '_attack_end' => $WAIT );
}


#
# event: attack_move($src, $dst, $nb)
#
# request to invade $dst from $src with $nb armies.
#
sub _onpub_attack_move {
    my ($h, $src, $dst, $nb) = @_[HEAP, ARG0..$#_];

    # FIXME: check player is curplayer
    # FIXME: check $src & $dst
    # FIXME: check $nb is more than min
    # FIXME: check $nb is less than max - 1

    my $looser = $dst->owner;

    # update the countries
    $src->set_armies( $src->armies - $nb );
    $dst->set_armies( $nb );
    $dst->set_owner( $src->owner );

    # update the gui
    $h->send_to_all('chnum', $src);
    $h->send_to_all('chown', $dst, $looser);

    # check if previous $dst owner has lost.
    if ( scalar($looser->countries) == 0 ) {
        # omg! one player left
        $h->player_lost($looser);
        $h->send_to_all('player_lost', $looser);

        # distribute cards from lost player to the one who crushed her
        my @cards = $looser->cards->all;
        my $player = $h->curplayer;
        foreach my $card ( @cards ) {
            $looser->cards->del($card);
            $player->cards->add($card);
            $h->send_to_one($player, 'card_add', $card);
            $h->send_to_one($looser, 'card_del', $card);
        }

        # check if game is over
        my @active = $h->players_active;
        if ( scalar @active == 1 ) {
            $h->send_to_all('game_over', $player);
            return;
        }
    }

    # continue attack
    $h->send_to_one($h->curplayer, 'attack');
}


#
# event: cards_exchange($card, $card, $card)
#
# exchange the cards against some armies.
#
sub _onpub_cards_exchange {
    my ($h, @cards) = @_[HEAP, ARG0..$#_];
    my $player = $h->curplayer;

    # FIXME: check player is curplayer
    # FIXME: check cards belong to player
    # FIXME: check we're in place_armies phase

    # compute player's bonus
    my $combo = join '', sort map { substr $_->type, 0, 1 } @cards;
    my %bonus;
    $bonus{$_} = 10 for qw{ aci acj aij cij ajj cjj ijj Jérôme Quelin };
    $bonus{$_} = 8  for qw{ aaa aaj };
    $bonus{$_} = 6  for qw{ ccc ccj };
    $bonus{$_} = 4  for qw{ iii iij };
    my $bonus = $bonus{ $combo } // 0;

    # wrong combo
    return if $bonus == 0;

    # trade the armies
    my $armies = $h->armies + $bonus;
    $h->armies($armies);

    # signal that player has some more armies...
    $h->send_to_one($player, 'place_armies', $bonus);

    # ... and maybe some country bonus...
    foreach my $card ( @cards ) {
        next if $card->type eq 'joker'; # joker do not bear a country
        my $country = $card->country;
        next unless $country->owner eq $player;
        $country->set_armies($country->armies + 2);
        $h->send_to_all('chnum', $country);
    }

    # ... but some cards less.
    $player->cards->del($_) foreach @cards;
    $h->send_to_one($player, 'card_del', @cards);

    # finally, put back the cards on the deck
    $h->map->cards->return($_) foreach @cards;
}


#
# event: initial_armies_placed($country, $nb);
#
# fired to place $nb additional armies on $country.
#
sub _onpub_initial_armies_placed {
    my ($h, $country, $nb) = @_[HEAP,ARG0, ARG1];

    # FIXME: check player is curplayer
    # FIXME: check country belongs to curplayer
    # FIXME: check validity regarding total number
    # FIXME: check validity regarding continent

    $country->set_armies( $country->armies + $nb );
    $h->send_to_all('chnum', $country);
    K->delay_set( '_place_armies_initial' => $WAIT );
}


#
# event: map_loaded();
#
# fired when board has finished loading map.
#
sub _onpub_map_loaded {
    # FIXME: sync & wait when more than one window
    K->yield('_gui_ready');
}


#
# event: new_game
#
# fired when user wants to start a new game.
#
sub _onpub_new_game {
    my ($h, $args) = @_[HEAP, ARG0];

    # load map
    my $modmap = delete $args->{map};
    my $map = $modmap->new;
    $h->map($map);

    K->post('gui', 'new_game', { map => $map });
    $h->startup_info($args);
}


#
# event: move_armies( $src, $dst, $nb )
#
# fired when player wants to move $nb armies from $src to $dst.
#
sub _onpub_move_armies {
    my ($h, $src, $dst, $nb) = @_[HEAP, ARG0..$#_];

    # FIXME: check player is curplayer
    # FIXME: check $src & $dst belong to curplayer
    # FIXME: check $src & $dst are adjacent
    # FIXME: check $src keeps one army
    # FIXME: check if army has not yet moved
    # FIXME: check negative values
    # FIXME: check max values

    $h->move_out->{ $src->id } += $nb;
    $h->move_in->{  $dst->id } += $nb;

    $src->set_armies( $src->armies - $nb );
    $dst->set_armies( $dst->armies + $nb );

    $h->send_to_all('chnum', $src);
    $h->send_to_all('chnum', $dst);
}


#
# event: player_created($player);
#
# fired when a player is ready. used as a checkpoint to be sure everyone
# is ready before moving on to next phase (assign countries).
#
sub _onpub_player_created {
    my ($h, $player) = @_[HEAP, ARG0];
    delete $h->wait_for->{ $player->name };

    # go on to the next phase
    K->yield( '_players_created' ) if scalar keys %{ $h->wait_for } == 0;
}


#
# event: quit()
#
# fired by startup window to quit the game.
#
sub _onpub_quit {
    K->alias_remove('risk');
}

#
# event: shutdown()
#
# fired when board window has been closed, requesting all ais and
# remaining windows to shutdown too.
#
sub _onpub_shutdown {
    my $h = $_[HEAP];

    # remove all possible pending events.
    K->alarm_remove_all;

    # close all ais & windows
    $h->send_to_all('shutdown');
    $h->destroy;
}


# -- private events - game states

#
# distribute randomly countries to players.
# FIXME: what in the case of a loaded game?
# FIXME: this can be configured so that players pick the countries
# of their choice, turn by turn
#
sub _onpriv_assign_countries {
    my $h = $_[HEAP];

    # initial random assignment of countries
    my @players   = $h->players;
    my @countries = shuffle $h->map->countries;
    while ( my $country = shift @countries ) {
        # rotate players
        my $player = shift @players;
        push @players, $player;

        # store new owner & place one army to start with
        $country->set_owner($player);
        $country->set_armies(1);
        $h->send_to_all('chown', $country);
    }

    # go on to the next phase
    K->yield( '_countries_assigned' );
}


#
# start the attack phase for curplayer
#
sub _onpriv_attack {
    my $h = $_[HEAP];
    $h->send_to_one($h->curplayer, 'attack');
}


#
# event: _attack_done($src, $dst)
#
# check the outcome of attack of $dst from $src. only used as a
# temporization, so this handler will always serve the same event.
#
sub _onpriv_attack_done {
    my ($h, $src, $dst) = @_[HEAP, ARG0..$#_];

    my $player = $h->curplayer;

    # update gui
    $h->send_to_all('chnum', $src);
    $h->send_to_all('chnum', $dst);

    # check outcome
    if ( $dst->armies <= 0 ) {
        # all your base are belong to us! :-)

        # distribute a card if that's the first successful attack in the
        # player's turn.
        if ( not $h->got_card ) {
            $h->got_card(1);
            my $card = $h->map->cards->get;
            $player->cards->add($card);
            $h->send_to_one($player, 'card_add', $card);
        }

        # move armies to invade country
        if ( $src->armies - 1 == $h->nbdice ) {
            # erm, no choice but move all remaining armies
            K->yield( 'attack_move', $src, $dst, $h->nbdice );

        } else {
            # ask how many armies to move
            $h->send_to_one($player, 'attack_move', $src, $dst, $h->nbdice);
        }

    } else {
        $h->send_to_one($player, 'attack');
    }
}


#
# ask player to exchange cards if they want
#
sub _onpriv_cards_exchange {
    my $h = $_[HEAP];

    $h->send_to_one($h->curplayer, 'exchange_cards');
    K->yield('_cards_exchanged');
}


#
# create the GR::Players that will fight.
#
sub _onpriv_create_players {
    my $h = $_[HEAP];
    require Games::Risk::Player;

    # create players according to startup information.
    my $players = delete $h->startup_info->{players};
    my @players;
    foreach my $p ( shuffle @$players ) {
        my $name  = $p->{name};
        my $type  = $p->{type};
        my $color = $p->{color};
        die "player cannot have an empty name" unless $name;

        my $player;
        if ( $type eq T('Human') ) {         # FIXME 20100517 JQ: mix string & code
            # human player
            $player = Games::Risk::Player->new({
                name  => $name,
                color => $color,
                type  => 'human',
            });
        }
        elsif ( $type eq T('Computer, easy') ) { # FIXME 20100517 JQ: mix string & code
            # artificial intelligence
            $player = Games::Risk::Player->new({
                name     => $name,
                color    => $color,
                type     => 'ai',
                ai_class => 'Games::Risk::AI::Blitzkrieg',
            });
        }
        elsif ( $type eq T('Computer, hard') ) { # FIXME 20100517 JQ: mix string & code
            # artificial intelligence
            $player = Games::Risk::Player->new({
                name     => $name,
                color    => $color,
                type     => 'ai',
                ai_class => 'Games::Risk::AI::Hegemon',
            });
        }
        else {
            # error
            die "unknown player type: $type";
        }

        # store new player
        push @players, $player;
    }

    # store new set of players
    $h->players_reset(@players);

    # broadcast info
    $h->wait_for( {} );
    foreach my $player ( @players ) {
        $h->wait_for->{ $player->name } = 1;
        $h->send_to_all('player_add', $player);
    }
}


#
# request current player to move armies
#
sub _onpriv_move_armies {
    my $h = $_[HEAP];

    # reset counters
    $h->move_in( {} );
    $h->move_out( {} );

    # add current player to move
    $h->send_to_one($h->curplayer, 'move_armies');
}


#
# require curplayer to place its reinforcements.
#
sub _onpriv_place_armies {
    my $h = $_[HEAP];
    my $player = $h->curplayer;

    # compute number of armies to be placed.
    my @countries = $player->countries;
    my $nb = int( scalar(@countries) / 3 );
    $nb = 3 if $nb < 3;

    # signal player
    $h->send_to_one($player, 'place_armies', $nb);

    # continent bonus
    #my $bonus = 0;
    foreach my $c( $h->map->continents ) {
        next unless $c->is_owned($player);

        my $bonus = $c->bonus;
        $nb += $bonus;
        $h->send_to_one($player, 'place_armies', $bonus, $c);
    }

    $h->armies($nb);
}


#
# require players to place initials armies.
#
sub _onpriv_place_armies_initial {
    my $h = $_[HEAP];

    # FIXME: possibility to place armies randomly by server
    # FIXME: possibility to place armies according to map scenario

    # get number of armies to place left
    my $left = $h->armies;

    # get next player that should place an army
    my $player = $h->player_next;

    if ( not defined $player ) {
        # all players have placed an army once. so let's just decrease
        # count of armies to be placed, and start again.

        $player = $h->player_next;
        $left--;
        $h->armies( $left );

        if ( $left == 0 ) {
            # hey, we've finished! move on to the next phase.
            K->yield( '_initial_armies_placed' );
            return;
        }
    }

    # update various guis with current player
    $h->curplayer( $player );
    $h->send_to_all('player_active', $player);

    # request army to be placed.
    $h->send_to_one($player, 'place_armies_initial');
}


#
# tell players how many initial armies they have.
#
sub _onpriv_place_armies_initial_count {
    my $h = $_[HEAP];

    # initialize number of initial armies, and tell players about it.
    $h->armies($START_ARMIES); # FIXME: hardcoded
    $h->send_to_all('place_armies_initial_count', $h->armies);

    # let's initialize list of players.
    $h->players_reset_turn;
    K->yield('_place_armies_initial');
}



#
# get next player & update people.
#
sub _onpriv_player_next {
    my $h = $_[HEAP];

    # get next player
    my $player = $h->player_next;
    $h->curplayer( $player );
    if ( not defined $player ) {
        K->yield('_begin_turn');
        return;
    }

    # reset card status
    $h->got_card(0);

    # update various guis with current player
    $h->send_to_all('player_active', $player);

    K->delay_set('_player_begun'=>$TURN_WAIT);
}


#
# initialize list of players for next turn.
#
sub _onpriv_turn_begin {
    my $h = $_[HEAP];

    # get next player
    $h->players_reset_turn;

    # placing armies
    K->yield('_turn_begun');
}


# -- private events - session management

#
# event: _start( \%params )
#
# Called when the poe session gets initialized. Receive a reference
# to %params, same as spawn() received.
#
sub _onpriv_start {
    K->alias_set('risk');
}



1;

__END__

=pod

=head1 NAME

Games::Risk::Controller - controller poe session for risk

=head1 VERSION

version 4.000

=head1 DESCRIPTION

This module implements a poe session, responsible for the state tracking
as well as rule enforcement of the game.

=head1 PUBLIC METHODS

=head2 my $id = Games::Risk::Controller->spawn( \%params )

This method will create a POE session responsible for a classical risk
game. It will return the poe id of the session newly created.

You can tune the session by passing some arguments as a hash reference.
Currently, no params can be tuned.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
