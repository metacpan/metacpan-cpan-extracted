#
# This file is part of Games-Pandemic
#
# This software is Copyright (c) 2009 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 2, June 1991
#
use 5.010;
use strict;
use warnings;

package Games::Pandemic::Controller;
{
  $Games::Pandemic::Controller::VERSION = '1.120510';
}
# ABSTRACT: controller for a pandemic game

use List::Util      qw{ shuffle };
use List::MoreUtils qw{ all };
use MooseX::Singleton;  # should come before any other moose
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;
use Readonly;

use Games::Pandemic::Card::Epidemic;
use Games::Pandemic::Deck;
use Games::Pandemic::Map::Pandemic;
use Games::Pandemic::Player;

Readonly my $K  => $poe_kernel;

# -- accessors

# -- initialization

#
# START()
#
# called as poe session initialization.
#
sub START {
    $K->alias_set('controller');
}

# -- public events

event action => sub {
    my ($action, @params) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $player = $game->curplayer;

    # FIXME: check src vs current player

    $K->yield("_action_$action", @params);
};



event airlift => sub {
    my ($player, $card, $selplayer, $city) = @_[ARG0..$#_];

    # basic checks
    return unless $player->owns_card($card);
    my $from = $selplayer->location;
    return if $from eq $city;

    # play special card: move player
    $selplayer->set_location($city);
    _check_auto_clean_on_cure();
    $K->post( main => 'player_move', $selplayer, $from, $city );

    # drop the card
    my $game = Games::Pandemic->instance;
    $player->drop_card( $card );
    $game->cards->discard( $card );
    $K->post( main => 'drop_card', $player, $card );

    # check that there are not too many cards
    foreach my $player ( $game->all_players ) {
        next if $player->nb_cards <= $player->max_cards;
        $game->set_too_many_cards($player);
        $K->post( main => 'too_many_cards', $player );
        return;
    }
    $K->yield( $game->next_step ) if $game->too_many_cards;
    $game->clear_too_many_cards;
};



event close => sub {
    my $game = Games::Pandemic->instance;
    $game->clear_map;
    $game->clear_cards_deck;
    $game->clear_infection_deck;
    $game->clear_players;
    $game->clear_players_in_turn;
    $game->clear_curplayer;
    $game->clear_too_many_cards;
    $game->has_ended;
};



event continue => sub {
    my $game = Games::Pandemic->instance;
    # FIXME: check src vs current player
    given ( $game->state ) {
        when ('end_of_actions')     { $K->yield('_draw_cards' ); }
        when ('end_of_cards')       { $K->yield('_propagate'  ); }
        when ('end_of_propagation') { $K->yield('_next_player'); }
    }
};



event drop_cards => sub {
    my ($player, @cards) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $deck = $game->cards;

    # FIXME: check src vs $player

    # remove cards from player hands
    foreach my $card ( @cards ) {
        $player->drop_card( $card );
        $deck->discard( $card );
        $K->post( main => 'drop_card', $player, $card );
    }

    # check again that there are not too many cards
    foreach my $player ( $game->all_players ) {
        next if $player->nb_cards <= $player->max_cards;
        $game->set_too_many_cards($player);
        $K->post( main => 'too_many_cards', $player );
        return;
    }

    $K->yield( $game->next_step ) if $game->too_many_cards;
    $game->clear_too_many_cards;
};



event forecast => sub {
    my ($player, $card, @cards) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $deck = $game->infection;

    # basic checks
    return unless $player->owns_card($card);

    # check if cards are the correct ones
    my @curr = $deck->future;
    splice @curr, 0, @curr-6;
    return if join('+', sort @cards) ne join('+', sort @curr);

    # rearrange the cards
    $deck->next for 1..6;
    $deck->refill( reverse @cards );

    # drop the card
    $player->drop_card( $card );
    $game->cards->discard( $card );
    $K->post( main => 'drop_card', $player, $card );

    # check that there are not too many cards
    foreach my $player ( $game->all_players ) {
        next if $player->nb_cards <= $player->max_cards;
        $game->set_too_many_cards($player);
        $K->post( main => 'too_many_cards', $player );
        return;
    }
    $K->yield( $game->next_step ) if $game->too_many_cards;
    $game->clear_too_many_cards;
};



event government_grant => sub {
    my ($player, $card, $city) = @_[ARG0..$#_];

    # basic checks
    return unless $player->owns_card($card);
    return if $city->has_station;

    # play special card: build station
    my $game = Games::Pandemic->instance;
    $city->build_station;
    $game->dec_stations;
    $K->post( main => 'build_station', $city );

    # drop the card
    $player->drop_card( $card );
    $game->cards->discard( $card );
    $K->post( main => 'drop_card', $player, $card );

    # check that there are not too many cards
    foreach my $player ( $game->all_players ) {
        next if $player->nb_cards <= $player->max_cards;
        $game->set_too_many_cards($player);
        $K->post( main => 'too_many_cards', $player );
        return;
    }
    $K->yield( $game->next_step ) if $game->too_many_cards;
    $game->clear_too_many_cards;
};




event new_game => sub {
    my $game = Games::Pandemic->instance;
    $game->has_started;

    # create the map
    my $map = Games::Pandemic::Map::Pandemic->new;
    $game->set_map( $map );

    # 5 research stations available. FIXME: should it be part of the map?
    $game->set_stations( 5 );

    # no epidemics and no outbreaks yet
    $game->set_epidemics( 0 );
    $game->set_outbreaks( 0 );

    # create the player cards deck
    my @pcards = shuffle $map->cards;
    {
        # insert epidemic cards
        my $nbinit    = 8; # FIXME: 2 players * 4 cards, should not be fixed
        my $epidemics = 4; # FIXME: depends on game difficulty
        my $nbleft  = scalar(@pcards) - $nbinit;
        my $perheap = $nbleft / $epidemics;
        foreach my $i ( reverse 0 .. $epidemics-1 ) {
            my $offset = int( $i * $perheap + rand($perheap) );
            splice @pcards, $offset, 0, Games::Pandemic::Card::Epidemic->new;
        }
    }
    my $pcards = Games::Pandemic::Deck->new( cards => \@pcards );
    $game->set_cards( $pcards );

    # create the infection deck
    my @icards = shuffle $map->disease_cards;
    my $icards = Games::Pandemic::Deck->new( cards => \@icards );
    $game->set_infection( $icards );

    # do the initial infections
    foreach my $nb ( $map->start_diseases ) {
        my $card = $icards->next;
        $K->yield( _infect => $card->city, $nb );
        $icards->discard( $card );
    }

    # signal main window that we have started a new game
    $K->post( main => 'new_game' );

    # create the players
    # FIXME: by now we're creating a fixed set of players, should be
    # configurable
    # FIXME: initial number of card depends of map / number of players
    my @roles = shuffle qw{ Researcher Scientist OperationsExpert Medic };
    $K->yield( _new_player => $_, 4 ) for @roles[0..1];
    #$K->yield( _new_player => 'Researcher', 4 );
    #$K->yield( _new_player => 'Scientist', 4 );
    #$K->yield( _new_player => 'Medic', 4 );
    #$K->yield( _new_player => 'Dispatcher', 4 );
    #$K->yield( _new_player => 'OperationsExpert', 4 );

    # start the game
    $K->yield( '_next_player' );
};



event one_quiet_night => sub {
    my ($player, $card) = @_[ARG0..$#_];

    # basic check
    return unless $player->owns_card($card);

    # play special card
    my $game = Games::Pandemic->instance;
    $game->disable_propagation;
    # FIXME: update gui?

    # drop the card
    $player->drop_card( $card );
    $game->cards->discard( $card );
    $K->post( main => 'drop_card', $player, $card );

    # check that there are not too many cards
    foreach my $player ( $game->all_players ) {
        next if $player->nb_cards <= $player->max_cards;
        $game->set_too_many_cards($player);
        $K->post( main => 'too_many_cards', $player );
        return;
    }
    $K->yield( $game->next_step ) if $game->too_many_cards;
    $game->clear_too_many_cards;
};



event resilient_population => sub {
    my ($player, $card, $city) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $deck = $game->infection;

    my $after_epidemic = ($deck->nbdiscards == 0);
    my @past = $after_epidemic
        ? ( reverse $deck->future )[ 0 .. $deck->previous_nbdiscards-1 ]
        : $deck->past;

    # basic checks
    return unless $player->owns_card($card);
    return unless grep { $_->city eq $city } @past;

    # play special card: make population resilient
    if ( $after_epidemic ) {
        my @future = $deck->future;
        $deck->clear_cards;
        $deck->refill( grep { $_->city ne $city } @future );
    } else {
        $deck->clear_pile;
        $deck->discard( grep { $_->city ne $city } @past );
    }

    # drop the card
    $player->drop_card( $card );
    $game->cards->discard( $card );
    $K->post( main => 'drop_card', $player, $card );

    # check that there are not too many cards
    foreach my $player ( $game->all_players ) {
        next if $player->nb_cards <= $player->max_cards;
        $game->set_too_many_cards($player);
        $K->post( main => 'too_many_cards', $player );
        return;
    }
    $K->yield( $game->next_step ) if $game->too_many_cards;
    $game->clear_too_many_cards;
};

# -- private event

#
# event: _action_build()
#
# request to build a research station.
#
event _action_build => sub {
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;

    # invalid request
    return $K->yield('_next_action')
        unless $curp->is_build_possible;
    # FIXME: check research station count

    # build station
    my $city = $curp->location;
    $city->build_station;
    $game->dec_stations;
    $K->post( main => 'build_station', $city );

    # player loose a card
    if ( not $curp->can_build_anywhere ) {
        my $card = $curp->owns_city_card($city);
        $curp->drop_card( $card );
        $game->cards->discard( $card );
        $K->post( main => 'drop_card', $curp, $card );
    }

    $K->yield('_action_done');
};


#
# event: _action_charter($player, $city)
#
# request to charter $player to $city.
#
event _action_charter => sub {
    my ($player, $city) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;

    return $K->yield('_next_action')
        if $player ne $curp; # FIXME: dispatcher

    # get the card
    my $card = $curp->owns_city_card($player->location);
    return $K->yield('_next_action') unless defined $card;

    # move the player
    my $from = $player->location;
    $player->set_location($city);
    $K->post( main => 'player_move', $player, $from, $city );
    _check_auto_clean_on_cure();
    $K->yield('_action_done');

    # drop the card
    $curp->drop_card( $card );
    $game->cards->discard( $card );
    $K->post( main => 'drop_card', $curp, $card );
};


#
# event: _action_treat($disease)
#
# request to treat $disease from current player location.
#
event _action_treat => sub {
    my $disease = $_[ARG0];
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;
    my $city = $curp->location;

    my $nb = $city->get_infection($disease);
    return $K->yield('_next_action') if $nb == 0;

    my $nbtreat = ( $curp->treat_all || $disease->has_cure )
        ? $nb
        : 1;

    $city->treat($disease, $nbtreat);
    $disease->return($nbtreat);
    $K->post( main => 'treatment', $city );

    # check if disease is eradicated
    $K->yield( '_eradicate', $disease )
        if $disease->has_cure && $disease->nbleft == $disease->nbmax;

    $K->yield('_action_done');
};


#
# event: _action_discover($disease, @cards)
#
# request to discover a cure.
#
event _action_discover => sub {
    my ($disease, @cards) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;
    my $deck = $game->cards;

    # various checks
    return $K->yield('_next_action')
        if $disease->has_cure                                # nothing to do
        || !$curp->location->has_station                     # no research station
        || scalar(@cards) != $curp->cards_needed             # not enough cards
        || not(all { $_->isa('Games::Pandemic::Card::City') } @cards) # not the right cards
        || not(all { $curp->owns_card($_) } @cards)          # not the right player
        || not(all { $_->city->disease eq $disease } @cards) # wrong cards
        ;

    # yup, we can exchange cards for a cure
    foreach my $card ( @cards ) {
        $curp->drop_card($card);
        $deck->discard($card);
        $K->post( main => 'drop_card', $curp, $card );
    }
    $disease->find_cure;
    $K->post( main => 'cure', $disease );

    _check_auto_clean_on_cure();

    # check if disease is eradicated
    $K->yield( '_eradicate', $disease )
        if $disease->has_cure && $disease->nbleft == $disease->nbmax;

    # check if game is won
    return $K->yield('_all_cures_discovered')
        if all { $_->has_cure } $game->map->all_diseases;

    $K->yield('_action_done');
};


#
# event: _action_done()
#
# action is finished.
#
event _action_done => sub {
    my $game = Games::Pandemic->instance;

    # turn is done
    my $curp = $game->curplayer;
    $curp->action_done;
    $K->post( main => 'action_done' );

    # next step would be...
    my $event = $curp->actions_left == 0 ? '_end_of_actions' : '_next_action';

    # ... unless a player has too many cards
    foreach my $player ( $game->all_players ) {
        next if $player->nb_cards <= $player->max_cards;
        $game->set_too_many_cards($player);
        $game->set_next_step($event);
        $K->post( main => 'too_many_cards', $player );
        return;
    }

    # everything's fine, we can continue
    $K->yield( $event );
};


#
# event: _action_fly($player, $city)
#
# request to fly $player to $city.
#
event _action_fly => sub {
    my ($player, $city) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;

    return $K->yield('_next_action')
        if $player ne $curp; # FIXME: dispatcher

    # get the card
    my $card = $curp->owns_city_card($city);
    return $K->yield('_next_action') unless defined $card;

    # move the player
    my $from = $player->location;
    $player->set_location($city);
    $K->post( main => 'player_move', $player, $from, $city );
    _check_auto_clean_on_cure();
    $K->yield('_action_done');

    # drop the card
    $curp->drop_card( $card );
    $game->cards->discard( $card );
    $K->post( main => 'drop_card', $curp, $card );
};


#
# event: _action_move($player, $city)
#
# request to move $player to $city by proximity.
#
event _action_move => sub {
    my ($player, $city) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;

    return $K->yield('_next_action')
        if $player ne $curp; # FIXME: dispatcher

    if ( $player->can_travel_to($city) ) {
        my $from = $player->location;
        $player->set_location($city);
        $K->post( main => 'player_move', $player, $from, $city );
        _check_auto_clean_on_cure();
        $K->yield('_action_done');
    } else {
        # invalid move
        $K->yield('_next_action');
    }
};


#
# event: _action_pass()
#
# user wishes to pass.
# 
event _action_pass => sub {
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;

    # nothing to do - user is just passing
    $curp->set_actions_left(0);
    $K->post( main => 'action_done' );
    $K->yield( '_end_of_actions' );
};


#
# event: _action_share($card, $player)
#
# request to give $card to $player.
#
event _action_share => sub {
    my ($card, $player) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;
    my $city = $curp->location;

    return $K->yield('_next_action') if $player eq $curp;
    return $K->yield('_next_action') if $player->location ne $city;
    return $K->yield('_next_action') unless $curp->owns_card($card);
    return $K->yield('_next_action') unless $card->isa('Games::Pandemic::Card::City');
    return $K->yield('_next_action') unless $card->city eq $city || $curp->can_share_anywhere;

    # give the card
    $curp->drop_card( $card );
    $player->gain_card( $card );
    $K->post( main => 'drop_card', $curp, $card );
    $K->post( main => 'gain_card', $player, $card );

    $K->yield('_action_done');
};


#
# event: _action_shuttle($player, $city)
#
# request to move $player to $city by research station shuttle.
#
event _action_shuttle => sub {
    my ($player, $city) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;

    return $K->yield('_next_action')
        if $player ne $curp; # FIXME: dispatcher

    # get the card
    return $K->yield('_next_action') unless $player->can_shuttle_to($city);

    # move the player
    my $from = $player->location;
    $player->set_location($city);
    $K->post( main => 'player_move', $player, $from, $city );
    _check_auto_clean_on_cure();
    $K->yield('_action_done');
};


#
# event: _all_cures_discovered()
#
# sent when game has been won.
#
event _all_cures_discovered => sub {
    $K->post( main => 'all_cures_discovered' );
    $K->yield( '_game_over' );
};


#
# _deal_card( $player, $nb );
#
# deal $nb cards to $player. check whether player has too much cards in
# her hands, and also for game over condition.
#
event _deal_card => sub {
    my ($player, $nb) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $deck = $game->cards;

    # deal some cards to the players
    foreach my $i ( 1 .. $nb ) {
        my $card = $deck->next;

        if ( not defined $card ) {
            # no more cards - game is over
            $K->yield('_no_more_cards');
            return;
        }

        # check if we hit a new epidemic
        if ( $card->isa('Games::Pandemic::Card::Epidemic') ) {
            $K->yield( '_epidemic', $card );
            next;
        }

        # regular card, dealing it to player
        $player->gain_card($card);
        $K->post(main=>'gain_card', $player, $card);
    }

    # check if player has too much cards
    if ( $player->nb_cards > $player->max_cards ) {
        $game->set_too_many_cards($player);
        $K->post( main => 'too_many_cards', $player );
    }
};


#
# event: _draw_cards()
#
# sent when player needs to draw her cards.
#
event _draw_cards => sub {
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;
    # FIXME: is 2 cards fixed or map-dependant?
    $K->yield( '_deal_card', $curp, 2 );
    $game->clear_next_step;

    $game->set_state('end_of_cards');
    $K->post( main => 'end_of_cards' );
};


#
# event: _game_over()
#
# sent when game is over (either win or loose), user cannot do anything
# but close the game.
#
event _game_over => sub {
    my $game = Games::Pandemic->instance;
    $game->has_ended;
    $K->post( main => 'game_over' );
};


#
# event: _end_of_actions()
#
# sent when player finished her actions
#
event _end_of_actions => sub {
    my $game = Games::Pandemic->instance;
    $game->set_state('end_of_actions');
    $K->post( main => 'end_of_actions' );
};


#
# event: _epidemic( $card )
#
# an epidemic $card has been drawn.
#
event _epidemic => sub {
    my $game = Games::Pandemic->instance;
    my $deck = $game->infection;

    # epidemic first strikes hard a new city...
    my $card = $deck->last;
    my $city = $card->city;
    $K->yield( '_infect', $city, 3 );
    $K->post( main => 'epidemic', $city );

    # then already hit cities ready for a new turn...
    $deck->discard( $card );
    my @cards = $deck->past;
    $deck->clear_pile;
    $deck->refill( shuffle @cards );

    # update infection rate
    $game->inc_epidemics;

    # discard the epidemic card
    $game->cards->discard( $_[ARG0] );
};


#
# event: _eradicate($disease)
#
# $disease has been eradicated.
#
event _eradicate => sub {
    my $disease = $_[ARG0];
    $disease->eradicate;
    $K->post( main => 'eradicate', $disease );
};


#
# _infect( $city [, $nb [, $disease [, $seen ] ] ] );
#
# infect $city with $nb items of $disease. perform an outbreak on
# neighbour cities if needed. $nb defaults to 1, $disease defaults to
# the city default disease. if there's an outbreak, keep a list of
# cities already C<$seen> (a hash reference).
#
event _infect => sub {
    my ($city, $nb, $disease, $seen) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    $nb      //= 1;
    $disease //= $city->disease;
    $seen    //= {}; # FIXME: padre//

    # disease eradicated: no infection! \o/
    return if $disease->is_eradicated;
    return if $disease->has_cure &&
        grep { $_->location eq $city  }
        grep { $_->auto_clean_on_cure }
        $game->all_players;

    # perform the infection & update the gui
    my ($outbreak, $nbreal) = $city->infect($nb, $disease);

    # update the disease
    $disease->take($nbreal);
    if ( $disease->nbleft <= 0 ) {
        $K->yield('_no_more_cubes', $disease);
        return;
    }

    $K->post( main => 'infection', $city, $outbreak );
    return unless $outbreak && !$seen->{$city};

    # update number of outbreaks
    $game->inc_outbreaks;
    if ( $game->nb_outbreaks == 8 ) { # FIXME: map dependant?
        $K->yield('_too_many_outbreaks');
        return;
    }

    # chaining infections
    $seen->{$city}++;
    $K->yield( '_infect', $_, 1, $disease, $seen ) for $city->neighbours;
};


#
# event: _new_player( $role, $nb )
#
# request to create & store a new player, having $role and starting with
# $nb cards.
#
event _new_player => sub {
    my ($role, $nbcards) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;

    $role = "Games::Pandemic::Role::$role";
    my $player = Games::Pandemic::Player->new_with_traits(traits=>[$role]);
    $game->add_player($player);
    $K->post( main => 'new_player', $player );
    $K->yield( '_deal_card', $player, $nbcards );
};


#
# event: _next_action()
#
# sent for player to continue its turn
#
event _next_action => sub {
    $K->post( main => 'next_action' );
};


#
# event: _next_player( $player )
#
# sent when $player should start to play its turn.
#
event _next_player => sub {
    my $game = Games::Pandemic->instance;

    my $player = $game->next_player;
    if ( not defined $player ) {
        $game->reinit_players( $game->all_players );
        $player = $game->next_player;
    }
    $game->set_curplayer( $player );
    $game->set_state('actions');

    $player->set_actions_left(4);
    $K->post( main => 'next_player', $player );
    $K->yield( '_next_action' );
};


#
# event: _no_more_cards()
#
# sent when controller cannot deal any more cards, and game is over.
#
event _no_more_cards => sub {
    $K->post( main => 'no_more_cards' );
    $K->yield('_game_over');
};


#
# event: _no_more_cubes($disease)
#
# sent when a $disease has spread over any control, and game is over.
#
event _no_more_cubes => sub {
    my $disease = $_[ARG0];
    $K->post( main => 'no_more_cubes', $disease );
    $K->yield('_game_over');
};


#
# event: _propagate()
#
# sent to do the regular disease propagation.
#
event _propagate => sub {
    my $game   = Games::Pandemic->instance;

    if ( $game->propagation ) {
        my $icards = $game->infection;

        # propagate diseases
        do {
            my $card = $icards->next;
            $K->yield( _infect => $card->city, 1 );
            $icards->discard( $card );
        } for 1 .. $game->infection_rate;
    } else {
        $game->enable_propagation;
    }

    # update game state
    $game->set_state('end_of_propagation');
    $K->post( main => 'end_of_propagation' );
};


#
# event: _too_many_outbreaks()
#
# sent when there are too many outbreaks, and game is over.
#
event _too_many_outbreaks => sub {
    $K->post( main => 'too_many_outbreaks' );
    $K->yield('_game_over');
};


# -- private subs

sub _check_auto_clean_on_cure {
    my $game = Games::Pandemic->instance;

    # only diseases with a cure are eligible
    my @diseases =
        grep { $_->has_cure }
        $game->map->all_diseases ;

    foreach my $player ( $game->all_players ) {
        # only works for player with auto_clean_on_cure property
        next unless $player->auto_clean_on_cure;

        # check all diseases
        my $city = $player->location;
        foreach my $disease ( @diseases ) {
            my $nb = $city->get_infection( $disease );
            next unless $nb; # no infection, move on

            # yup, let's treat automatically
            # FIXME - should be in a sub?
            $city->treat($disease, $nb);
            $disease->return($nb);
            $K->post( main => 'treatment', $city );

            # check if disease is eradicated
            $K->yield( '_eradicate', $disease )
                if $disease->has_cure && $disease->nbleft == $disease->nbmax;
        }
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Controller - controller for a pandemic game

=head1 VERSION

version 1.120510

=head1 METHODS

=head2 event: airlift($player, $card, $selplayer, $city)

Special event card: move a player in any city.

=head2 event: close()

Player has closed current game.

=head2 event: continue()

Player wishes to move game forward.

=head2 event: drop_cards( $player, @cards )

Request from C<$player> to remove some C<@cards> from her hands.

=head2 event: forecast($player, $card, @cards)

Special event card: rearrange infections to come.

=head2 event: government_grant($player, $card, $city)

Special event card: add a new research station.

=head2 event: new_game()

Create a new game: (re-)initialize the map, and various internal states.

=head2 event: one_quiet_night($player, $card)

Special event card: prevent disease propagation during this turn.

=head2 event: resilient_population($player, $card, $city)

Special event card: remove a city from the game.

=for Pod::Coverage START

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__

