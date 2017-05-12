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

package Games::Pandemic::Tk::Main;
{
  $Games::Pandemic::Tk::Main::VERSION = '1.120510';
}
# ABSTRACT: main pandemic window

use Convert::Color;
use File::Spec::Functions qw{ catfile };
use Image::Size;
use List::Util            qw{ min };
use Math::Gradient        qw{ array_gradient };
use Moose                 0.92;
use MooseX::Has::Sugar;
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;
use Readonly;
use Tk;
use Tk::Action;
use Tk::Balloon;
use Tk::Font;
use Tk::JPEG;
use Tk::Pane;
use Tk::PNG;
use Tk::ToolBar;
use Tk::Sugar;

use Games::Pandemic::Config;
use Games::Pandemic::I18n       qw{ T };
use Games::Pandemic::Tk::Dialog::Action;
use Games::Pandemic::Tk::Dialog::Airlift;
use Games::Pandemic::Tk::Dialog::ChooseDisease;
use Games::Pandemic::Tk::Dialog::DropCards;
use Games::Pandemic::Tk::Dialog::Forecast;
use Games::Pandemic::Tk::Dialog::GiveCard;
use Games::Pandemic::Tk::Dialog::GovernmentGrant;
use Games::Pandemic::Tk::Dialog::ResilientPopulation;
use Games::Pandemic::Tk::Dialog::Simple;
use Games::Pandemic::Tk::Dialog::ViewCards;
use Games::Pandemic::Tk::PlayerCards;
use Games::Pandemic::Tk::Utils  qw{ image pandemic_icon };
use Games::Pandemic::Utils;

Readonly my $K  => $poe_kernel;
Readonly my $mw => $poe_main_window; # already created by poe
Readonly my $RADIUS     => 10;
Readonly my $TIME_BLINK => 0.5;
Readonly my $TIME_DECAY => 0.150;
Readonly my $TIME_GLOW  => 0.150;

# -- attributes

# a hash with all the widgets, for easier reference.
has _widgets => (
    ro,
    traits  => ['Hash'],
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        _set_w => 'set',
        _w     => 'get',
        _del_w => 'delete',
    },
);

# a hash with all the actions.
has _actions => (
    ro,
    traits  => ['Hash'],
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        _set_action => 'set',
        _action     => 'get',
    },
);

# color gradient for outbreak scale
has _outbreak_gradient => (
    ro,
    auto_deref,
    lazy_build,
    traits  => ['Array'],
    isa     => 'ArrayRef[ArrayRef]',
    handles => {
        _outbreak_color           => 'get',   # my $c = $main->_outbreak_color($i);
        _add_to_outbreak_gradient => 'push',  # my $c = $main->_add_to_outbreak_gradient($rgb);
    }
);

# color gradient for infection rate
has _infection_rate_gradient => (
    ro,
    auto_deref,
    lazy_build,
    traits  => ['Array'],
    isa     => 'ArrayRef[Str]',
    handles => {
        _next_infection_rate_color => 'shift',
        _add_infection_rate_color  => 'push',
    }
);


# currently selected player
has _selplayer => ( rw, weak_ref, isa => 'Games::Pandemic::Player' );


# it's not usually a good idea to retain a reference on a poe session,
# since poe is already taking care of the references for us. however, we
# need the session to call ->postback() to set the various gui callbacks
# that will be fired upon gui events.
has _session => ( rw, weak_ref, isa=>'POE::Session' );


# -- initialization

#
# START()
#
# called as poe session initialization.
#
sub START {
    my ($self, $session) = @_[OBJECT, SESSION];
    $K->alias_set('main');
    $self->_set_session($session);
    $self->_build_gui;
}


sub _build__infection_rate_gradient {
    my @gradient =
        map { sprintf "#%02x%02x%02x", @$_ }
        array_gradient([15,71,15], [212,219,16], 50);
    push @gradient, reverse @gradient;
    return \@gradient;
}

sub _build__outbreak_gradient {
    my $self = shift;
    my $scale = $self->_w('outbreaks');

    my $color = substr( ($scale->configure(-troughcolor))[3], 1);
    my $c = Convert::Color->new("rgb8:$color");
    my @gradient = array_gradient([ map {$_*255} $c->rgb ], [255,0,0], 9);
    return \@gradient;
}



# -- public events


event action_done => sub {
    my $self = $_[OBJECT];
    $self->_update_status;
};



event airlift => sub {
    my ($self, $player, $card) = @_[OBJECT, ARG0..$#_];
    Games::Pandemic::Tk::Dialog::Airlift->new(
        parent => $mw,
        player => $player,
        card   => $card,
    );
};



event all_cures_discovered => sub {
    # warn user
    Games::Pandemic::Tk::Dialog::Simple->new(
        parent => $mw,
        title  => T('You won!'),
        header => T('Congratulations'),
        icon   => catfile($SHAREDIR, 'icons', 'success-48.png'),
        text   => T(  "You won: you discovered all the cures."
                    . "\n\n"
                    . "Perhaps is it time to augment difficulty?" ),
    );
};



event build_station => sub {
    my ($self, $city) = @_[OBJECT, ARG0];
    $self->_draw_station($city);
    $self->_update_status;
};



event cure => sub {
    my ($self, $disease) = @_[OBJECT, ARG0];
    $self->_w('tooltip')->attach(
        $self->_w("lab_cure_$disease"),
        -msg=> sprintf( T("cure found\nfor %s"), $disease->name ),
    );
    $self->_update_status;
};



event drop_card => sub {
    my ($self, $player, $card) = @_[OBJECT, ARG0..$#_];
    $K->post( cards => 'drop_card', $player, $card );
    $self->_update_status; # deck count
};



event end_of_actions => sub {
    my $self = $_[OBJECT];
    $self->_update_actions;
};



event end_of_cards => sub {
    my $self = $_[OBJECT];
    $self->_update_actions;
};



event end_of_propagation => sub {
    my $self = $_[OBJECT];
    $self->_update_actions;
};



event epidemic => sub {
    my ($self, $city) = @_[OBJECT, ARG0];

    # warn user
    my $format = T('%s epidemic strikes in %s.');
    Games::Pandemic::Tk::Dialog::Simple->new(
        parent => $mw,
        title  => T('Warning'),
        header => T('New epidemic'),
        icon   => catfile($SHAREDIR, 'icons', 'warning-48.png'),
        text   => sprintf($format, $city->disease->name, $city->name)
    );
};



event eradicate => sub {
    my ($self, $disease) = @_[OBJECT, ARG0];
    my $label = $self->_w("lab_cure_$disease");
    $label->configure(
        -image => image( $disease->image('golden-cure', 32) ) );
    $self->_w('tooltip')->attach(
        $label,
        -msg => sprintf( T("%s:\ndisease eradicated"), $disease->name ),
    );
};



event forecast => sub {
    my ($self, $player, $card) = @_[OBJECT, ARG0..$#_];
    Games::Pandemic::Tk::Dialog::Forecast->new(
        parent => $mw,
        player => $player,
        card   => $card,
    );
};



event gain_card => sub {
    my ($self, $player, $card) = @_[OBJECT, ARG0..$#_];
    $K->post( cards => 'gain_card', $player, $card );
    $self->_update_status; # deck count
};



event game_over => sub {
    my $self = shift;
    $self->_update_status;
    $self->_action($_)->disable for ( "continue",
        map { "action_$_" } qw{ build discover treat share pass drop } );
};



event government_grant => sub {
    my ($self, $player, $card) = @_[OBJECT, ARG0..$#_];
    Games::Pandemic::Tk::Dialog::GovernmentGrant->new(
        parent => $mw,
        player => $player,
        card   => $card,
    );
};



event infection => sub {
    my ($self, $city, $outbreak) = @_[OBJECT, ARG0, ARG1];

    # draw city infections
    $self->_draw_infection($city);

    # update status bar
    $self->_update_status;

    # compute decay colors
    my @from = (0, 255, 0);
    my @to   = (0, 0, 0);
    my $steps = 20;
    my @colors;
    foreach my $i ( 0 .. $steps ) {
        my $r = $from[0] + int( ($to[0] - $from[0]) / $steps * $i );
        my $g = $from[1] + int( ($to[1] - $from[1]) / $steps * $i );
        my $b = $from[2] + int( ($to[2] - $from[2]) / $steps * $i );
        push @colors, sprintf( "#%02x%02x%02x", $r, $g, $b );
    }
    $self->yield( _decay => $city, \@colors );
};



event new_game => sub {
    my $self = shift;
    my $c = $self->_w('canvas');
    my $s = $self->_session;

    # add missing gui elements
    $self->_build_action_bar;
    $self->_build_status_bar;
    Games::Pandemic::Tk::PlayerCards->new( parent=>$mw );

    # remove everything on the canvas
    $c->delete('all');

    # prevent some actions
    $self->_action('new')->disable;
    $self->_action('load')->disable;
    $self->_action('close')->enable;
    $self->_action('show_cards')->enable;

    # the background image
    my $map    = Games::Pandemic->instance->map;
    my $bgpath = $map->background_path;
    my ($xmax, $ymax) = imgsize($bgpath);
    my $bg = image($bgpath);
    $c->createImage(0, 0, -anchor=>'nw', -image=>$bg, -tags=>['background']);
    $c->lower('background', 'all');

    # place the cities on the map
    my @smooth = ( -smooth => 1, -splinesteps => 5 );
    foreach my $city ( $map->all_cities ) {
        $self->_draw_city($city);
        my $x = $city->coordx;
        my $y = $city->coordy;

        # draw connections between cities
        foreach my $n ( $city->neighbours ) {
            my $xn = $n->coordx;
            my $yn = $n->coordy;
            next if $xn < $x; # line already drawn
            if ( ($xn-$x) > $xmax/2 ) {
                $c->createLine( $x, $y, 0, ($y+$yn)/2, -fill => 'red', -tags=>['line'], @smooth );
                $c->createLine( $xn, $yn, $xmax, ($y+$yn)/2, -fill => 'red', -tags=>['line'], @smooth );
            } else {
                $c->createLine( $x, $y, $xn, $yn, -fill => 'red', -tags=>['line'], @smooth );
            }
        }
    }

    $c->raise('city',    'all');
    $c->raise('station', 'all');
    $c->raise('name',    'all');
    $c->bind( 'spot', '<1>', $s->postback('_city_click') );

    # draw the starting station
    my $start = $map->start_city;
    $self->_draw_station($start);
};



event new_player => sub {
    my ($self, $player) = @_[OBJECT, ARG0];

    # adding the player to player cards window
    $K->post( cards => 'new_player', $player );

    # drawing the pawn on the canvas
    my $c = $self->_w('canvas');
    my @placed = $c->find( withtag => 'player' );
    # each player will be located at a given offset of the city center,
    # in order not to overlap each other.
    my @offsets = ( [-8, -10], [8, -10], [  0, -20], [-15, -20], [ 15, -20] );
    my $offsets = $offsets[ scalar(@placed) ];
    my $city = $player->location;
    my $x = $city->coordx + $offsets->[0];
    my $y = $city->coordy + $offsets->[1];
    $c->createImage(
        $x, $y,
        -image  => image( $player->image('pawn',16) ),
        -anchor => 's',
        -tags   => ['player', $player],
    );
};



event next_action => sub {
    my $self = $_[OBJECT];
    $self->_update_status;
    $self->_update_actions;
};



event next_player => sub {
    my ($self, $player) = @_[OBJECT, ARG0];
    my $game = Games::Pandemic->instance;

    # raise back current selected player
    $self->_w('canvas')->raise( $self->_selplayer );
    $self->_set_selplayer( $player );
    $K->delay( _blink_player => $TIME_BLINK, 0 );

    $self->_w('lab_curplayer')->configure(-image=>image($player->image('icon', 32)));
};



event no_more_cards => sub {
    my $self = $_[OBJECT];

    # warn user
    my $header = T('No more cards');
    my $reason = T('there are no more cards to deal.');

    $self->_game_lost($header, $reason);
};



event no_more_cubes => sub {
    my ($self, $disease) = @_[OBJECT, ARG0];

    # warn user
    my $fmt_reason = T( "the %s pandemic is too spread out to be cured." );
    my $header = T('Pandemic out of control');
    my $reason = sprintf $fmt_reason, $disease->name;

    $self->_game_lost($header, $reason);
};



event one_quiet_night => sub {
    my ($self, $player, $card) = @_[OBJECT, ARG0..$#_];

    my $text = $card->description . "\n\n" .
        T('Do you want to play this card?');

    Games::Pandemic::Tk::Dialog::Action->new(
        parent    => $mw,
        title     => T('Special event'),
        header    => $card->label,
        icon      => catfile($SHAREDIR, 'cards', 'one-quiet-night-48.png'),
        text      => $text,
        action    => T('Play'),
        post_args => [ controller=>'one_quiet_night', $player, $card ],
    );
};



event player_move => sub {
    my ($self, $player, $from, $to) = @_[OBJECT, ARG0..$#_];

    # canvas uses delta for move()
    my $dx = $to->coordx - $from->coordx;
    my $dy = $to->coordy - $from->coordy;
    $self->_w('canvas')->move( $player, $dx, $dy );

    # need to update actions if moved with airlift
    $self->_update_actions;
};



event resilient_population => sub {
    my ($self, $player, $card) = @_[OBJECT, ARG0..$#_];
    Games::Pandemic::Tk::Dialog::ResilientPopulation->new(
        parent => $mw,
        player => $player,
        card   => $card,
    );
};



event too_many_cards => sub {
    my ($self, $player) = @_[OBJECT, ARG0];

    # warn user
    my $format = T('Player %s has too many cards. '.
        'Drop some cards (or use some action cards) before continuing.');
    Games::Pandemic::Tk::Dialog::Simple->new(
        parent => $mw,
        title  => T('Warning'),
        header => T('Too many cards'),
        icon   => catfile($SHAREDIR, 'icons', 'warning-48.png'),
        text   => sprintf($format, $player->role)
    );

    # prevent any action but dropping cards
    $self->_action("action_$_")->disable for qw{ build discover treat share pass };
    $self->_action("action_drop")->enable;

    # FIXME: provide a way to drop cards
};


event too_many_outbreaks => sub {
    my $self = shift;

    # warn user
    my $header = T('Too many outbreaks');
    my $reason = T('there were too many outbreaks, pandemics have spread out of control.');

    $self->_game_lost($header, $reason);
};



event treatment => sub {
    my ($self, $city) = @_[OBJECT, ARG0];
    $self->_draw_infection($city);
    $self->_update_status;
};


# -- private events

#
# event: _blink_player( $bool )
#
# make current selected player blink on the map, depending on previous $bool
# visibility satus.  schedule another _blink_player event.
#
event _blink_player => sub {
    my ($self, $lit) = @_[OBJECT, ARG0];
    my $c    = $self->_w('canvas');
    my $curp = $self->_selplayer;
    my $method = $lit ? 'raise' : 'lower';
    $c->$method( $curp );
    $K->delay( _blink_player => $TIME_BLINK, !$lit );
};


#
# event: _decay( $city, \@colors )
#
# change $city outline color to the first element of @colors, and
# schedule another _decay event with the rest of @colors if it's still
# not empty.
#
event _decay => sub {
    my ($self, $city, $colors) = @_[OBJECT, ARG0, ARG1];
    my $c    = $self->_w('canvas');
    my $name = $city->name;
    my $col  = shift @$colors;
    $c->itemconfigure(
        "$name&&spot",
        -outline => $col,
        -width   => min(5, $#$colors+1),
    );
    $K->delay_add( _decay => $TIME_DECAY, $city, $colors ) if $#$colors;
};


event _glow => sub {
    my $self = shift;
    my $game = Games::Pandemic->instance;
    my $color = $self->_next_infection_rate_color;
    $self->_w('lab_infection_rate')->configure(-bg=>$color);
    $K->delay( _glow => $TIME_GLOW / ($game->nb_epidemics+1) );
    $self->_add_infection_rate_color($color);
};

# -- gui events

#
# event: _action_build()
#
# user wishes to build a research station.
#
event _action_build => sub {
    $K->post( controller => 'action', 'build' );
};


#
# event: _action_drop()
#
# user wishes to drop a card, either from current player or if we're in
# a situation of too many cards.
#
event _action_drop => sub {
    my $game = Games::Pandemic->instance;
    my $player = $game->too_many_cards // $game->curplayer; # FIXME://padre
    Games::Pandemic::Tk::Dialog::DropCards->new(
        parent => $mw,
        player => $player,
    );
};


#
# event: _action_discover()
#
# user wishes to discover a cure.
#
event _action_discover => sub {
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;

    my $disease = $curp->is_discover_possible;
    my @cards =
        grep { $_->city->disease eq $disease }
        grep { $_->isa('Games::Pandemic::Card::City') }
        $curp->all_cards;

    # FIXME: choose which cards
    splice @cards, $curp->cards_needed;

    $K->post( controller => 'action', 'discover', $disease, @cards );
};


#
# event: _action_pass()
#
# user wishes to pass.
#
event _action_pass => sub {
    $K->post( controller => 'action', 'pass' );
};


#
# event: _action_share()
#
# user wishes to give a card to another player.
#
event _action_share => sub {
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;
    my $city = $curp->location;

    # get list of players to whom the card can be given
    my @players =
        grep { $_->location eq $city }
        grep { $_ ne $curp }
        $game->all_players;

    # get list of cards to be shared
    my @cards = $curp->can_share_anywhere
        ? grep { $_->isa('Games::Pandemic::Card::City') } $curp->all_cards
        : $curp->owns_city_card($city);

    if ( @players == 1 && @cards == 1 ) {
        $K->post( controller => 'action', 'share', @cards, @players );

    } else {
        Games::Pandemic::Tk::Dialog::GiveCard->new(
            parent  => $mw,
            cards   => \@cards,
            players => \@players,
        );
    }
};


#
# event: _action_treat()
#
# user wishes to treat a disease in her location.
#
event _action_treat => sub {
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;
    my $map  = $game->map;
    my $city = $curp->location;

    # find the city infections
    my @diseases;
    foreach my $disease ( $map->all_diseases ) {
        next if $city->get_infection($disease) == 0;
        push @diseases, $disease;
    }

    # check if city is multi-infected
    if ( scalar @diseases == 1 ) {
        $K->post( controller => 'action', 'treat', $diseases[0] );
    } else {
        Games::Pandemic::Tk::Dialog::ChooseDisease->new(
            parent   => $mw,
            diseases => \@diseases,
        );
    }
};


#
# event: _city_click( undef, [ $canvas ] )
#
# called when used clicked on a city on the canvas.
#
event _city_click => sub {
    my ($self, $args) = @_[OBJECT, ARG1];
    my $game = Games::Pandemic->instance;

    # if we're in a situation of too many cards for a player, user is
    # not allowed to travel
    return $self->yield('too_many_cards', $game->too_many_cards)
        if defined $game->too_many_cards;

    return unless $game->state eq 'actions';

    my ($canvas) = @$args;
    my $map  = $game->map;
    my $player = $game->curplayer; # FIXME: dispatcher

    # find city clicked
    my $item = $canvas->find( withtag => 'current' );
    my ($id) = map { /^c-(.*)/ ? $1 : () } $canvas->gettags($item);
    my $city = $map->city($id);

    if ( $city eq $player->location ) {
        # FIXME: hilight possible travel destinations
    } else {
        return $K->post( controller => 'action', 'move', $player, $city )
            if $player->can_travel_to($city);
        return $K->post( controller => 'action', 'shuttle', $player, $city )
            if $player->can_shuttle_to($city);
        return $K->post( controller => 'action', 'charter', $player, $city )
            if $player->owns_city_card($player->location);
        return $K->post( controller => 'action', 'fly', $player, $city )
            if $player->owns_city_card($city);
    }
};


#
# event: _close()
#
# request to close current game.
#
event _close => sub {
    my $self = shift;
    my $game = Games::Pandemic->instance;

    # remove current timers
    $K->alarm_remove_all;

    # allow some actions
    $self->_action('new')->enable;
    $self->_action('load')->enable;
    $self->_action('close')->disable;
    $self->_action('show_cards')->disable;

    # remove everything from current game
    my $tb = $self->_del_w('tbactions');
    $tb->{CONTAINER}->packForget; # FIXME: breaking encapsulation
    $tb->destroy;
    $self->_del_w('infobar')->destroy;

    my $c = $self->_w('canvas');
    $c->delete('all');

    # destroy player cards window
    $K->post( cards => 'destroy' );

    # redraw initial actions
    $self->_draw_init_screen;

    $K->post( controller => 'close' );
};


#
# event: _continue()
#
# request to move game forward.
#
event _continue => sub {
    my $game = Games::Pandemic->instance;
    $K->post( controller => 'continue' );
};


#
# event: _new()
#
# request a new game to the controller
#
event _new => sub {
    my $game = Games::Pandemic->instance;
    return if $game->is_in_play;
    $K->post( controller => 'new_game' );
};


#
# event: _quit()
#
# user requested to quit the application.
#
event _quit => sub {
    exit; # FIXME: do better than that...
};


#
# event: _show_cards()
#
# user request to toggle player cards visbility
#
event _show_cards => sub {
    $K->post( cards => 'toggle_visibility' );
};


#
# event: _show_past_cards()
#
# user request to see cards already played / dropped.
#
event _show_past_cards => sub {
    my $game = Games::Pandemic->instance;
    my $deck = $game->cards;

    if ( $deck->nbdiscards ) {
        Games::Pandemic::Tk::Dialog::ViewCards->new(
            parent => $mw,
            title  => T('Information'),
            header => T('Discard pile'),
            cards  => [ $deck->past ],
        );
    } else {
        # nothing to show
        Games::Pandemic::Tk::Dialog::Simple->new(
            parent => $mw,
            icon   => catfile($SHAREDIR, 'icons', 'warning-48.png'),
            text   => T('No cards in the discard pile.'),
        );
    }
};


#
# event: _show_past_infections()
#
# user request to see infections already endured.
#
event _show_past_infections => sub {
    my $game = Games::Pandemic->instance;
    my $deck = $game->infection;

    if ( $deck->nbdiscards ) {
        Games::Pandemic::Tk::Dialog::ViewCards->new(
            parent => $mw,
            title  => T('Information'),
            header => T('Past infections'),
            cards  => [ $deck->past ],
        );
    } else {
        # nothing to show
        Games::Pandemic::Tk::Dialog::Simple->new(
            parent => $mw,
            icon   => catfile($SHAREDIR, 'icons', 'warning-48.png'),
            text   => T('No past infections.'),
        );
    }
};


# -- gui creation

#
# $main->_build_action_bar;
#
# create the action bar at the bottom of the window, with the various
# action buttons that a player can press when it's her turn.
#
sub _build_action_bar {
    my $self = shift;
    my $session = $self->_session;

    # create the toolbar
    my $tbmain = $self->_w('toolbar');
    my $tb = $mw->ToolBar(-movable => 0, -in=>$tbmain );
    $self->_set_w('tbactions', $tb);

    # the toolbar widgets
    my @actions = (
        [ 'build',    T('Build a research station')                ],
        [ 'discover', T('Discover a cure')                         ],
        [ 'treat',    T('Treat a disease')                         ],
        [ 'share',    T('Give a card')                             ],
        [ 'pass',     T('Pass your turn')                          ],
        [ 'drop',     T('Drop some cards')                         ],
    );

    # create the widgets
    foreach my $item ( @actions ) {
        my ($action, $tip) = @$item;

        my $image = image( catfile($SHAREDIR, 'actions', "$action.png") );
        my $event = "_action_$action";

        # regular toolbar widgets
        my $widget = $tb->Button(
            -image       => $image,
            -tip         => $tip,
            -command     => $session->postback($event),
        );
        $self->_action("action_$action")->add_widget($widget);
    }

    # player information
    $tb->separator( -movable => 0 );
    my $labcurp = $tb->Label; # for current player image
    $tb->Label( -text => T('actions left: ') );
    my $labturn = $tb->Label;
    $self->_set_w('lab_curplayer', $labcurp);
    $self->_set_w('lab_nbactions', $labturn);

    # continue button
    my $but = $tb->Button(
        -text    => T('Continue'),
        -command => $session->postback('_continue'),
        enabled,
    );
    $self->_action('continue')->add_widget($but);
}


#
# $main->_build_canvas;
#
# create the canvas, where the map will be drawn and the action
# take place.
#
sub _build_canvas {
    my $self = shift;
    my $s = $self->_session;

    my $config = Games::Pandemic::Config->instance;
    my $width  = $config->get( 'canvas_width' );
    my $height = $config->get( 'canvas_height' );

    # creating the canvas
    my $c  = $mw->Canvas(-width=>$width,-height=>$height)->pack(top, xfill2);
    $self->_set_w('canvas', $c);

    # removing class bindings
    foreach my $button ( qw{ 4 5 6 7 } ) {
        $mw->bind('Tk::Canvas', "<Button-$button>",       undef);
        $mw->bind('Tk::Canvas', "<Shift-Button-$button>", undef);
    }
    foreach my $key ( qw{ Down End Home Left Next Prior Right Up } ) {
        $mw->bind('Tk::Canvas', "<Key-$key>", undef);
        $mw->bind('Tk::Canvas', "<Control-Key-$key>", undef);
    }

    # initial actions
    $self->_draw_init_screen;
}


#
# $main->_build_gui;
#
# create the various gui elements.
#
sub _build_gui {
    my $self = shift;
    my $s = $self->_session;

    # hide window during its creation to avoid flickering
    $mw->withdraw;

    # prettyfying tk app.
    # see http://www.perltk.org/index.php?option=com_content&task=view&id=43&Itemid=37
    $mw->optionAdd('*BorderWidth' => 1);

    # set windowtitle
    $mw->title(T('Pandemic'));
    $mw->iconimage( pandemic_icon() );

    # make sure window is big enough
    my $config = Games::Pandemic::Config->instance;
    my $width  = $config->get( 'win_width' );
    my $height = $config->get( 'win_height' );
    $mw->geometry($width . 'x' . $height);

    # create the actions
    my @enabled  = qw{ new load quit };
    my @disabled = (
        qw{ close continue show_cards },
        map { "action_$_" } qw{ build discover drop pass share treat },
    );
    foreach my $what ( @enabled, @disabled ) {
        my $action = Tk::Action->new(
            window   => $mw,
            callback => $s->postback("_$what"),
        );
        $self->_set_action($what, $action);
    }
    # allow some actions
    $self->_action($_)->enable  for @enabled;
    $self->_action($_)->disable for @disabled;

    # the tooltip
    $self->_set_w('tooltip', $mw->Balloon);

    # WARNING: we need to create the toolbar object before anything
    # else. indeed, tk::toolbar loads the embedded icons in classinit,
    # that is when the first object of the class is created - and not
    # during compile time.
    $self->_build_toolbar;
    $self->_build_menubar;
    $self->_build_canvas;

    # center & show the window
    # FIXME: restore last position saved?
    $mw->Popup;
}


#
# $self->_build_menu( $mnuname, $mnulabel, @submenus );
#
# Create the menu $label, with all the @submenus.
# @submenus is a list of [$name, $icon, $accel, $label] items.
# Store the menu items under the name menu_$mnuname_$name.
#
sub _build_menu {
    my ($self, $mnuname, $mnulabel, @submenus) = @_;
    my $menubar = $self->_w('menubar');
    my $s = $self->_session;

    my $menu = $menubar->cascade(-label => $mnulabel);
    foreach my $item ( @submenus ) {
        my ($name, $icon, $accel, $label) = @$item;

        # separators are easier
        if ( $name eq '---' ) {
            $menu->separator;
            next;
        }

        # regular buttons
        my $action = $self->_action($name);
        my $widget = $menu->command(
            -label       => $label,
            -image       => $icon,
            -compound    => 'left',
            -accelerator => $accel,
            -command     => $action->callback,
        );
        $self->_set_w("menu_${mnuname}_${name}", $widget);

        # create the bindings. note: we also need to bind the lowercase
        # letter too!
        $action->add_widget($widget);
        $accel =~ s/Ctrl\+/Control-/;
        $action->add_binding("<$accel>");
        $accel =~ s/Control-(\w)/"Control-" . lc($1)/e;
        $action->add_binding("<$accel>");
    }
}


#
# $main->_build_menubar;
#
# create the window's menu.
#
sub _build_menubar {
    my $self = shift;
    my $s = $self->_session;

    # no tear-off menus
    $mw->optionAdd('*tearOff', 'false');

    #$h->{w}{mnu_run} = $menubar->entrycget(1, '-menu');

    my $menubar = $mw->Menu;
    $mw->configure(-menu => $menubar );
    $self->_set_w('menubar', $menubar);

    # menu game
    my @mnu_game = (
    [ 'new',   'filenew16',   'Ctrl+N', T('~New game')   ],
    [ 'load',  'fileopen16',  'Ctrl+O', T('~Load game')  ],
    [ 'close', 'fileclose16', 'Ctrl+W', T('~Close game') ],
    [ '---'                                              ],
    [ 'quit',  'actexit16',   'Ctrl+Q', T('~Quit')       ],
    );
    $self->_build_menu('game', T('~Game'), @mnu_game);

    # menu view
    my @mnu_view = (
    [ 'show_cards', '', 'F2', T('Player ~cards') ],
    );
    $self->_build_menu('view', T('~View'), @mnu_view);

    # menu actions
    my @mnu_action = (
    [ 'action_build'    , '', 'b', T('~Build a research station') ],
    [ 'action_discover' , '', 'c', T('Discover a ~cure')          ],
    [ 'action_treat'    , '', 't', T('~Treat a disease')          ],
    [ 'action_share'    , '', 's', T('~Give a card')              ],
    [ 'action_pass'     , '', 'p', T('~Pass your turn')           ],
    [ '---'                                                       ],
    [ 'action_drop'     , '', 'd', T('~Drop some cards')          ],
    [ '---'                                                       ],
    [ 'continue'        , '', 'Return', T('Conti~nue')          ],
    );
    $self->_build_menu('action', T('~Action'), @mnu_action);
}


#
# $main->_build_status_bar;
#
# create the status bar at the right of the window.
#
sub _build_status_bar {
    my $self = shift;
    my $game = Games::Pandemic->instance;
    my $map  = $game->map;
    my $s    = $self->_session;
    my $tip  = $self->_w('tooltip');
    my $tipmsg;

    # the status bar itself is a frame
    my $sb = $mw->Frame->pack(right, fillx, -before=>$self->_w('canvas'));
    $self->_set_w( infobar => $sb );

#    # research stations
#    my $fstations = $sb->Frame->pack(top, padx10);
#    my $img_nbstations = $fstations->Label(
#        -image => image( catfile( $SHAREDIR, 'research-station-32.png' ) ),
#    )->pack(@TOP);
#    my $lab_nbstations = $fstations->Label->pack(@TOP);
#    $self->_set_w('lab_nbstations', $lab_nbstations );
#    $tipmsg = T("number of remaining\nresearch stations");
#    $tip->attach($img_nbstations, -msg=>$tipmsg);
#    $tip->attach($lab_nbstations, -msg=>$tipmsg);

    # diseases information
    my $fdiseases = $sb->Frame->pack(top, padx(10));
    my $fcures    = $sb->Frame->pack(top, padx(10));
    foreach my $disease ( $map->all_diseases ) {
        # disease
        my $img_disease = $fdiseases->Label(
            -image => image( $disease->image('cube', 32) ),
        )->pack(top);
        my $lab_disease = $fdiseases->Label->pack(top);
        $self->_set_w("lab_disease_$disease", $lab_disease);
        $tipmsg = sprintf T("number of cubes\nof %s left"), $disease->name;
        $tip->attach($img_disease, -msg=>$tipmsg);
        $tip->attach($lab_disease, -msg=>$tipmsg);

        # cure
        my $lab_cure = $fcures->Label(
            -image => image( $disease->image('cure', 32) ),
        )->pack(top);
        $self->_set_w("lab_cure_$disease", $lab_cure);
        $tipmsg = sprintf T("cure for %s\nnot found"), $disease->name;
        $tip->attach($lab_cure, -msg=>$tipmsg);
    }

    # player cards information
    my $cards  = $game->cards;
    my $fcards = $sb->Frame->pack(top, padx(10));
    my $img_cards = $fcards->Label(
        -image => image( catfile( $SHAREDIR, 'card-player.png' ) ),
    )->pack(top);
    my $lab_cards = $fcards->Label->pack(top);
    $self->_set_w('lab_cards', $lab_cards);
    $img_cards->bind('<Button-1>', $s->postback('_show_past_cards'));
    $lab_cards->bind('<Button-1>', $s->postback('_show_past_cards'));
    $tipmsg = T("number of cards remaining-discarded\nclick to see history");
    $tip->attach($img_cards, -msg=>$tipmsg);
    $tip->attach($lab_cards, -msg=>$tipmsg);

    # infection information
    my $infection = $game->infection;
    my $finfection = $sb->Frame->pack(top, padx(10));
    my $img_infection = $finfection->Label(
        -image => image( catfile( $SHAREDIR, 'card-infection.png' ) ),
    )->pack(top);
    my $lab_infection = $finfection->Label->pack(top);
    $self->_set_w('lab_infection', $lab_infection);
    $img_infection->bind('<Button-1>', $s->postback('_show_past_infections'));
    $lab_infection->bind('<Button-1>', $s->postback('_show_past_infections'));
    $tipmsg = T("number of infections remaining-passed\nclick to see history");
    $tip->attach($img_infection, -msg=>$tipmsg);
    $tip->attach($lab_infection, -msg=>$tipmsg);

    # infection rate
    my $firate = $sb->Frame(-bg=>'black')->pack(top, fillx, padx(10));
    my $lab_irate = $firate->Label->pack(top, xfill2);
    $self->_set_w('lab_infection_rate', $lab_irate);
    $K->delay( _glow => $TIME_GLOW );
    $tipmsg = T("infection rate\n(number of epidemics)");
    $tip->attach($lab_irate, -msg=>$tipmsg);

    # oubreak information
    my $scale = $sb->Scale(
        -orient => 'vertical',
        -sliderlength => 20,
        -from   => 8,
        -to     => 0,
        enabled,
    )->pack(top, padx(10));
    $self->_set_w('outbreaks', $scale);
    $tipmsg = sprintf T("number of outbreaks\n(maximum %s)"), 8; # FIXME: map dependant?
    $tip->attach($scale, -msg=>$tipmsg);
}


#
# $main->_build_toolbar;
#
# create the window toolbar (the one just below the menu).
#
sub _build_toolbar {
    my $self = shift;
    my $session = $self->_session;

    # create the toolbar
    my $tb = $mw->ToolBar( -movable => 0, top );
    $self->_set_w('toolbar', $tb);

    # the toolbar widgets
    my @tb = (
        [ 'Button', 'filenew22',   'new',   T('New game')   ],
        [ 'Button', 'fileopen22',  'load',  T('Load game')  ],
        [ 'Button', 'fileclose22', 'close', T('Close game') ],
        [ 'Button', 'actexit22',   'quit',  T('Quit')       ],
    );

    # create the widgets
    foreach my $item ( @tb ) {
        my ($type, $image, $name, $tip) = @$item;

        # separator is a special case
        $tb->separator( -movable => 0 ), next if $type eq 'separator';
        my $action = $self->_action($name);

        # regular toolbar widgets
        my $widget = $tb->$type(
            -image       => $image,
            -tip         => $tip,
            #-accelerator => $item->[2],
            -command     => $action->callback,
        );
        $self->_set_w( "tbut_$name", $widget );
        $action->add_widget( $widget );
    }
}


# -- private methods

#
# $main->_draw_city($city);
#
# draw $city on the canvas.
# note: this does not draw the diseases, players and research stations.
#
sub _draw_city {
    my ($self, $city) = @_;
    my $c = $self->_w('canvas');

    # fetch city information
    my $id    = $city->id;
    my $name  = $city->name;
    my $color = $city->disease->color(0);
    my $xreal = $city->xreal;
    my $yreal = $city->yreal;
    my $x     = $city->coordx;
    my $y     = $city->coordy;

    # join the 2 circles. this is done first in order to be overwritten
    # by other drawings on the canvas, such as the circles themselves.
    $c->createLine( $xreal, $yreal, $x, $y,
        -width       => 2,
        -fill        => $color,
        -tags        => [ 'city', 'draw', $name ],
        -smooth      => 1,
        -splinesteps => 5,
    );

    # draw the small circle with real position on map
    my $rreal = 2; # 4 pixels diameter
    $c->createOval(
        $xreal-$rreal, $yreal-$rreal, $xreal+$rreal, $yreal+$rreal,
        -fill => $color,
        -tags => ['city', 'draw', $name],
    );

    # draw the big circle that user can click
    $c->createOval(
        $x-$RADIUS, $y-$RADIUS, $x+$RADIUS, $y+$RADIUS,
        -fill => $color,
        -tags => ['city', 'draw', 'spot', $name, "c-$id"],
    );

    # write the city name
    $c->createText(
        $x, $y - $RADIUS * 1.5,
        -text   => $name,
        -fill   => 'black',
        -anchor => 'center',
        -tag    => ['city', $name],
    );
}


#
# $main->_draw_infection($city);
#
# re-draw the infection squares on the canvas for the given $city.
#
sub _draw_infection {
    my ($self, $city) = @_;
    my $game = Games::Pandemic->instance;
    my $map  = $game->map;

    # get number of main infection
    my $maindis = $city->disease;
    my $mainnb  = $city->get_infection( $maindis );
    my $color   = $maindis->color($mainnb);
    my @infections = ( $color ) x $mainnb;

    # update city color
    my $c    = $self->_w('canvas');
    my $name = $city->name;
    $c->itemconfigure( "$name&&draw", -fill => $color );

    # get list of disease items, with their color
    my @diseases =
        sort { $a->id <=> $b->id }
        grep { $_ ne $maindis }
        $map->all_diseases;
    foreach my $disease ( @diseases ) {
        my $nb  = $city->get_infection( $disease );
        my $col = $disease->color($nb);
        push @infections, ( $col ) x $nb;
    }

    # remove all infection items for the city
    $c->delete( "$name&&disease" );

    # draw the infection items
    my $x = $city->coordx;
    my $y = $city->coordy;
    my $tags = [ $name, 'disease' ];

    my $len = 8;
    my $pad = 4;
    foreach my $i ( 0 .. $#infections ) {
        my $xorig = $x + ($#infections/2 -$i) * $len + (($#infections-$i)/2-1) * $pad;
        my $yorig = $y + $RADIUS + $pad;
        $c->createRectangle(
            $xorig, $yorig,
            $xorig+$len, $yorig+$len,
            -fill    => $infections[$i],
            #-outline => undef,
            -tags    => $tags,
        );
    }
}


#
# $main->_draw_init_screen;
#
# draw splash image on canvas + initial actions, to present user with a
# non-empty window by default.
#
sub _draw_init_screen {
    my $self = shift;
    my $c = $self->_w('canvas');
    my $s = $self->_session;

    my $config = Games::Pandemic::Config->instance;
    my $width  = $config->get( 'canvas_width' );
    my $height = $config->get( 'canvas_height' );

    # create the initial welcome screen
    my @tags = ( -tags => ['startup'] );
    # first a background image...
    $c->createImage (
        $width/2, $height/2,
        -anchor => 'center',
        -image  => image( catfile($SHAREDIR, "background.png") ),
        @tags,
    );
    # ... then some basic actions
    my @buttons = (
        [ T('New game') ,  1, '_new'  ],
        [ T('Join game') , 0, '_join' ],
        [ T('Load game') , 0, '_load' ],
    );
    my $pad = 25;
    my $font = $mw->Font(-weight=>'bold');
    foreach my $i ( 0 .. $#buttons ) {
        my ($text, $active, $event) = @{ $buttons[$i] };
        # create the 'button' (really a clickable text)
        my $id = $c->createText(
            $width/2, $height/2 - (@buttons)/2*$pad + $i*$pad,
            $active ? enabled : disabled,
            -text         => $text,
            -fill         => '#dddddd',
            -activefill   => 'white',
            -disabledfill => '#999999',
            -font         => $font,
            @tags,
        );
        # now bind click on this text
        $c->bind( $id, '<1>', $s->postback($event) );
    }
}


#
# $main->_draw_station($city);
#
# draw a research station on the canvas for the given $city.
#
sub _draw_station {
    my ($self, $city) = @_;
    my $c = $self->_w('canvas');

    my $x = $city->coordx;
    my $y = $city->coordy;
    my $name = $city->name;
    my $tags = [ 'station', $name ];
    $c->createImage(
        $x, $y,
        -anchor=>'e',
        -image => image( catfile($SHAREDIR, 'research-station-32.png') ),
        -tags  => $tags,
    );
}


#
# $main->_game_lost( $header, $reason );
#
# show a standard simple dialog announcing end of game for a given $reason.
#
sub _game_lost {
    my ($self, $header, $reason) = @_;
    my $text = T( 'Game is over, you lost: ' )
             . $reason
             . "\n\n"
             . T( 'Try harder next time!' );
    Games::Pandemic::Tk::Dialog::Simple->new(
        parent => $mw,
        title  => T('You lost!'),
        header => $header,
        icon   => catfile($SHAREDIR, 'icons', 'warning-48.png'),
        text   => $text,
    );
};


#
# $main->_update_actions;
#
# update action buttons state depending on player.
#
sub _update_actions {
    my $self = shift;
    my $game = Games::Pandemic->instance;
    my $player = $game->curplayer;

    my @actions = qw{ build discover treat share pass drop };
    given ( $game->state ) {
        when ('actions') {
            foreach my $action ( @actions ) {
                my $check  = "is_${action}_possible";
                my $method = $player->$check ? 'enable' : 'disable';
                $self->_action("action_$action")->$method;
            }
            $self->_action('continue')->disable;
        }
        when ('end_of_actions' || 'end_of_cards') {
            $self->_action("action_$_")->disable for @actions;
            $self->_action('continue')->enable;
        }
    }
}


#
# $main->_update_status;
#
# update the status bar with relevant information.
#
sub _update_status {
    my $self = shift;
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;
    my $map  = $game->map;

#    # research stations
#    $self->_w('lab_nbstations')->configure(-text => $game->stations);

    # diseases information
    foreach my $disease ( $map->all_diseases ) {
        $self->_w("lab_disease_$disease")->configure(-text => $disease->nbleft);
        $self->_w("lab_cure_$disease")->configure(
            $disease->has_cure ? (enabled) : (disabled) );
    }

    # cards information
    my $deck1 = $game->cards;
    my $deck2 = $game->infection;
    my $text1 = $deck1->nbcards . '-' . $deck1->nbdiscards;
    my $text2 = $deck2->nbcards . '-' . $deck2->nbdiscards;
    $self->_w('lab_cards')->configure( -text => $text1 );
    $self->_w('lab_infection')->configure(-text => $text2 );

    # infection rate
    my $lab_irate = $self->_w('lab_infection_rate');
    my $text = sprintf "%d (%d)", $game->infection_rate, $game->nb_epidemics;
    $lab_irate->configure(-text =>$text);

    # number of outbreaks
    my $outbreaks = $game->nb_outbreaks;
    my $scale = $self->_w('outbreaks');
    $scale->configure(enabled); # ->set() doesn't work if disabled
    $scale->set( $outbreaks );
    my $color = Convert::Color::RGB8->new( @{ $self->_outbreak_color($outbreaks) } );
    $scale->configure(
        -troughcolor => '#' . $color->hex,
        enabled,
    );

    # actions left
    $self->_w('lab_nbactions')->configure(-text=>$curp->actions_left);
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Tk::Main - main pandemic window

=head1 VERSION

version 1.120510

=head1 METHODS

=head2 event: action_done()

Received when current player has finished an action.

=head2 event: airlift( $player, $card )

Received when C<$player> wants to play special C<$card>
L<Games::Pandemic::Card::Special::Airlift>. Does not require an action.

=head2 event: all_cures_discovered()

Received when game is won due to all cures being discovered

=head2 event: build_station($city)

Received when C<$city> gained a research station.

=head2 event: cure($disease)

Received when a cure has been found for C<$disease>.

=head2 event: drop_card($player, $card)

Received when C<$player> drops a C<$card>.

=head2 event: end_of_actions()

Received when current player has finished her actions.

=head2 event: end_of_cards()

Received when current player has received her cards for this turn.

=head2 event: end_of_propagation()

Received when propagation is done

=head2 event: epidemic($city)

Received when a new epidemic strikes C<$city>.

=head2 event: eradicate($disease)

Received when $disease has been eradicated.

=head2 event: forecast( $player, $card )

Received when C<$player> wants to play special C<$card>
L<Games::Pandemic::Card::Special::Forecast>. Does not require an action.

=head2 event: gain_card($player, $card)

Received when C<$player> got a new C<$card>.

=head2 event: game_over()

Received when game is over: user cannot advance the game any more.

=head2 event: government_grant( $player, $card )

Received when C<$player> wants to play special C<$card>
L<Games::Pandemic::Card::Special::GovernmentGrant>. Does not require
an action.

=head2 event: infection($city, $outbreak)

Received when C<$city> gets infected. C<$outbreak> is true if this
infection lead to a disease outbreak.

=head2 event: new_game()

Received when the controller started a new game. Display the new map
(incl. cities), action & statusbar.

=head2 event: new_player( $player )

Received when the controller has just created a new player.

=head2 event: next_action

Received when player needs to do its next action.

=head2 event: next_player( $player )

Received when C<$player> starts its turn.

=head2 event: no_more_cards()

Received when game is over due to a lack of cards to deal.

=head2 event: no_more_cubes( $disease )

Received when game is over due to a lack of cards to deal.

=head2 event: one_quiet_night( $player, $card )

Received when C<$player> wants to play special C<$card>
L<Games::Pandemic::Card::Special::OneQuietNight>. Does not require
an action.

=head2 event: player_move( $player, $from ,$to )

Received when C<$player> has moved between C<$from> and C<$to> cities.

=head2 event: resilient_population( $player, $card )

Received when C<$player> wants to play special C<$card>
L<Games::Pandemic::Card::Special::ResilientPopulation>. Does not require
an action.

=head2 event: too_many_cards( $player )

Received when C<$player> has too many cards: she must drop some before
the game can continue.

=head2 event: too_many_outbreaks()

Received when there are too many outbreaks, and game is over.

=head2 event: treatment( $city )

Received when C<$city> has been treated.

=for Pod::Coverage START

=head1 ACKNOWLEDGEMENT

Thanks to the various artists that provide their work for free, we need
them just as much we need coders.

I used the following icons:

=over 4

=item * research station symbol by Klukeart (Miriam Moshinsky), under a
free license for non-commercial use

=item * research station icon by IconsLand, under a free license for non-
commercial use

=item * discover icon by Klukeart (Miriam Moshinsky), under a free
license for non commercial use

=item * syringue icon by Everaldo Coelho, under an lgpl license

=item * share icon by Everaldo Coelho , under a gpl license

=item * pass icon by Zeus Box Studio, under a cc-by license

=item * trash icon by Jojo Mendoza, under a cc-nd-nc license

=item * warning icon by Gnome artists, under a gpl license

=item * success icon by Gnome artists, under a gpl license

=item * quiet night icon by David Vignoni, under a lgpl license

=item * government grant icon by Webdesigner Depot, under a free
license for commercial use

=item * resilient population icon by Gnome Project, under a GPL license

=item * airlift icon by IconsLand, under a free license for non-
commercial use

=item * airlift icon by David Vignoni, under a LGPL license

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__

