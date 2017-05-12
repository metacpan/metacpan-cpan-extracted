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

package Games::Risk::GUI::Startup;
# ABSTRACT: startup window
$Games::Risk::GUI::Startup::VERSION = '4.000';
use POE             qw{ Loop::Tk };
use List::Util      qw{ shuffle };
use List::MoreUtils qw{ any };
use Readonly;
use Tk;
use Tk::Balloon;
use Tk::BrowseEntry;
use Tk::Font;
use Tk::Sugar;

use Games::Risk;
use Games::Risk::I18n      qw{ T };
use Games::Risk::Logger    qw{ debug };
use Games::Risk::Resources qw{ get_image };
use Games::Risk::Utils     qw{ $SHAREDIR };

use constant K => $poe_kernel;

Readonly my $WAIT_CLEAN_AI    => 1.000;
Readonly my $WAIT_CLEAN_HUMAN => 0.250;

Readonly my @COLORS => (
    '#333333',  # grey20
    '#FF2052',  # awesome
    '#01A368',  # green
    '#0066FF',  # blue
    '#9E5B40',  # sepia
    '#A9B2C3',  # cadet blue
    '#BB3385',  # red violet
    '#FF681F',  # orange
    '#DCB63B',  # ~ dirty yellow
    '#00CCCC',  # robin's egg blue
    #'#1560BD',  # denim
    #'#33CC99',  # shamrock
    #'#FF9966',  # atomic tangerine
    #'#00755E',  # tropical rain forest
    #'#A50B5E',  # jazzberry jam
    #'#A3E3ED',  # blizzard blue
);
Readonly my @NAMES => (
    T('Napoleon Bonaparte'),   # france,   1769  - 1821
    T('Staline'),              # russia,   1878  - 1953
    T('Alexander the Great'),  # greece,   356BC - 323BC
    T('Julius Caesar'),        # rome,     100BC - 44BC
    T('Attila'),               # hun,      406   - 453
    T('Genghis Kahn'),         # mongolia, 1162  - 1227
    T('Charlemagne'),          # france,   747   - 814
    T('Saladin'),              # iraq,     1137  - 1193
    T('Otto von Bismarck'),    # germany,  1815  - 1898
    T('Ramses II'),            # egypt,    1303BC - 1213BC
);



#--
# Constructor

#
# my $id = Games::Risk::GUI->spawn( \%params );
#
# create a new window containing the board used for the game. refer
# to the embedded pod for an explanation of the supported options.
#
sub spawn {
    my (undef, $args) = @_;

    my $session = POE::Session->create(
        args          => [ $args ],
        inline_states => {
            # private events - session
            _start               => \&_onpriv_start,
            _stop                => sub { debug( "gui-startup shutdown\n" ) },
            _check_errors        => \&_onpriv_check_errors,
            _check_nb_players    => \&_onpriv_check_nb_players,
            _load_defaults       => \&_onpriv_load_defaults,
            _new_player          => \&_onpriv_new_player,
            _player_color        => \&_onpriv_player_color,
            # private events - game
            # gui events
            _but_color           => \&_ongui_but_color,
            _but_delete          => \&_ongui_but_delete,
            _but_new_player      => \&_ongui_but_new_player,
            _but_quit            => \&_ongui_but_quit,
            _but_start           => \&_ongui_but_start,
        },
    );
    return $session->ID;
}


#--
# EVENT HANDLERS

# -- private events

#
# event: _check_errors()
#
# check various config errors, such as player without a name, 2 human
# players, etc. disable start game if any error spotted.
#
sub _onpriv_check_errors {
    my ($h, $s) = @_[HEAP, SESSION];

    my $players = $h->{players};
    my @players = grep { defined $_ } @$players;
    my $top = $h->{toplevel};
    my $errstr;

    # remove previous error message
    if ( $h->{error} ) {
        # remove label
        $h->{error}->destroy;
        $h->{error} = undef;

        # allow start to be clicked
        $h->{button}{start}->configure(enabled);
        $top->bind('<Key-Return>', $s->postback('_but_start'));
    }

    # 2 players cannot have the same color
    my %colors;
    @colors{ map { $_->{color} } @players } = (0) x @players;
    $colors{ $_->{color} }++ for @players;
    $errstr = T('Two players cannot have the same color.')
        if any { $colors{$_} > 1 } keys %colors;

    # 2 players cannot have the same name
    my %names;
    @names{ map { $_->{name} } @players } = (0) x @players;
    $names{ $_->{name} }++ for @players;
    $errstr = T('Two players cannot have the same name.')
        if any { $names{$_} > 1 } keys %names;

    # human players
    my $nbhuman = grep { $_->{type} eq T('Human') } @players;
    $errstr = T('Cannot have more than one human player.')            if $nbhuman > 1;
    $errstr = T('Game without any human player not (yet) supported.') if $nbhuman < 1;

    # all players should have a name
    $errstr = T('A player cannot have an empty name.')
        if any { $_->{name} eq '' } @players;

    # there should be at least 2 players
    $errstr = T('Game should have at least 2 players.') if scalar @players < 2;

    # check if there are some errors
    if ( $errstr ) {
        # add warning
        $h->{error} = $h->{frame}{players}->Label(
            -bg => 'red',
            -text => $errstr,
        )->pack(top, fillx);

        # prevent start to be clicked
        $h->{button}{start}->configure(disabled);
        $top->bind('<Key-Return>', undef);
    }
}


#
# event: _check_nb_players
#
# check whether one can add new players.
#
sub _onpriv_check_nb_players {
    my $h = $_[HEAP];

    my $players = $h->{players};
    my @players = grep { defined $_ } @$players;

    # check whether we can add another player
    my @config = ( scalar(@players) >= 10 ) ? (disabled) : (enabled);
    $h->{button}{add_player}->configure(@config);
}


#
# _load_defaults()
#
# load default players, currently hardcoded (FIXME), but later from the
# last choices (saved in a config file somewhere).
#
sub _onpriv_load_defaults {
    # FIXME: hardcoded
    my $user   = $ENV{USER} // $ENV{USERNAME} //$ENV{LOGNAME}; # FIXME: use a module?
    my @names  = ($user, shuffle @NAMES );
    my @types  = (T('Human'), (T('Computer, easy'))x1, (T('Computer, hard'))x2);
    my @colors = @COLORS;
    foreach my $i ( 0..$#types ) {
        K->yield('_new_player', $names[$i], $types[$i], $colors[$i]);
    }
}


#
# event: _new_player([$name], [)
#
# fired when there's a new player created.
#
sub _onpriv_new_player {
    my ($h, $s, @args) = @_[HEAP, SESSION, ARG0..$#_];

    my ($name, $type, $color) = @args;
    my $players = $h->{players};
    my $num = scalar @$players;
    my @choices = ( T('Human'), T('Computer, easy'), T('Computer, hard') );

    # the frame
    $players->[$num]{name}  = $name;
    $players->[$num]{type}  = $type;
    $players->[$num]{color} = $color;
    my $fpl = $h->{frame}{players}->Frame
        ->pack(top, fillx, -before=>$h->{button}{add_player});
    my $f = $fpl->Frame(-bg=>$color)->pack(left, fillx);
    $players->[$num]{line}  = $fpl;
    $players->[$num]{frame} = $f;
    $f->Entry(
        -textvariable => \$players->[$num]{name},
        -validate     => 'all',
        -vcmd         => sub { $s->postback('_check_errors')->(); 1; },
        #-highlightbackground => $color,
    )->pack(left,xfillx);
    my $be = $f->BrowseEntry(
        -variable           => \$players->[$num]{type},
        -background         => $color,
        -listheight         => scalar(@choices)+1,
        -choices            => \@choices,
        -state              => 'readonly',
        -disabledforeground => 'black',
        -browsecmd          => $s->postback('_check_errors'),
    )->pack(left);
    my $bc = $f->Button(
        -bg               => $color,
        -fg               => 'white',
        -activebackground => $color,
        -activeforeground => 'white',
        -image            => get_image('paintbrush'),
        -command          => $s->postback('_but_color', $num),
    )->pack(left);
    my $ld = $fpl->Label(-image=>get_image('fileclose16'))->pack(left);
    $ld->bind('<1>', $s->postback('_but_delete', $num));
    $players->[$num]{be_type}   = $be;
    $players->[$num]{but_color} = $bc;

    # max players reached?
    K->yield('_check_nb_players');
}


#
# event: _player_color( [$num, $color] )
#
# called to change color of player number $num to $color.
#
sub _onpriv_player_color {
    my ($h, $args) = @_[HEAP, ARG0];
    my ($num, $color) = @$args;

    $h->{players}[$num]{color} = $color;
    $h->{players}[$num]{frame}->configure(-bg=>$color);
    $h->{players}[$num]{be_type}->configure(-bg=>$color);
    $h->{players}[$num]{but_color}->configure(
        -background => $color,
        -activebackground => $color);

    K->yield('_check_errors');
}


#
# Event: _start( \%params )
#
# Called when the poe session gets initialized. Receive a reference
# to %params, same as spawn() received.
#
sub _onpriv_start {
    my ($h, $s, $args) = @_[HEAP, SESSION, ARG0];

    K->alias_set('startup');
    my $top = $h->{toplevel} = $poe_main_window->Toplevel;

    # hide window during its creation to avoid flickering
    $top->withdraw;

    $top->title('prisk - ' . T('new game'));
    my $icon = $SHAREDIR->file('icons', '32', 'prisk.png');
    my $mask = $SHAREDIR->file('icons', '32', 'prisk-mask.xbm');
    $top->iconimage( $top->Photo(-file=>$icon) );
    $top->iconmask( '@' . $mask );


    #-- initializations
    $h->{players} = [];

    #-- title
    my $font = $top->Font(-size=>16);
    $top->Label(
        -bg   => 'black',
        -fg   => 'white',
        -font => $font,
        -text => T('New game'),
    )->pack(top,pad20,fillx);

    #-- various resources

    # ballon
    $h->{balloon} = $top->Balloon;

    #-- map selection
    my @choices = map { $_->title } Games::Risk->maps;
    $h->{map} = $choices[0]; # FIXME: config
    my $fmap = $top->Frame->pack(top, xfill2, pad20);
    $fmap->Label(-text=>T('Map'), -anchor=>'w')->pack(top, fillx);
    $fmap->BrowseEntry(
        -variable           => \$h->{map},
        -listheight         => scalar(@choices)+1,
        -choices            => \@choices,
        -state              => 'readonly',
        -disabledforeground => 'black',
    )->pack(top );

    #-- frame for players
    my $fpl = $top->Frame->pack(top, xfill2, pad20);
    $fpl->Label(-text=>T('Players'), -anchor=>'w')->pack(top, fillx);
    $h->{button}{add_player} = $fpl->Button(
        -text    => T('New player...'),
        -command => $s->postback('_but_new_player'),
    )->pack(top,fillx);
    $h->{frame}{players} = $fpl;
    K->yield('_load_defaults');

    #-- bottom frame
    my $fbot = $top->Frame->pack(bottom, fillx, pad20);
    my $b_start = $h->{button}{start} = $fbot->Button(
        -text => T('Start game'),
        -command => $s->postback('_but_start'),
    );
    my $b_quit = $fbot->Button(
        -text => T('Quit'),
        -command => $s->postback('_but_quit'),
    );
    # pack after creation, to have clean focus order
    $b_quit->pack(right,pad1);
    $b_start->pack(right,pad1);

    # window binding
    $top->bind('<Key-Return>', $s->postback('_but_start'));
    $top->bind('<Key-Escape>', $s->postback('_but_quit'));

    $top->update;
    $top->Popup;
    $top->grab;
}


# -- gui events

#
# event: _but_color([$num])
#
# called when button to choose another color for player number $num has
# been clicked.
#
sub _ongui_but_color {
    my ($h, $s, $args) = @_[HEAP, SESSION, ARG0];

    my ($num) = @$args;
    my $top = $h->{toplevel};

    # creating popup window
    my $tc =$top->Menu;
    $tc->overrideredirect(1);  # no window decoration
    foreach my $i ( 0..$#COLORS ) {
        my $color = $COLORS[$i];
        my $row = $i < 5 ? 0 : 1;
        my $col = $i % 5;
        my $l = $tc->Label(
            -bg     => $color,
            -width  => 2,
        )->grid(-row=>$row, -column=>$col);
        $l->bind('<1>', $s->postback('_player_color', $num, $color));
    }

    # poping up
    $tc->Popup(
        -popover => $h->{players}[$num]{but_color},
        -overanchor => 'sw',
        -popanchor  => 'nw',
    );
    $top->bind('<1>', sub { $tc->destroy; $top->bind('<1>',undef); });
    #$tc->bind('<1>', sub { $tc->destroy; $top->bind('<1>',undef); });

    K->yield('_check_errors');
}


#
# event: _but_delete([$num])
#
# called when button to delete player number $num has been clicked.
#
sub _ongui_but_delete {
    my ($h, $args) = @_[HEAP, ARG0];

    # remove player
    my ($num) = @$args;
    $h->{players}[$num]{line}->destroy;
    delete $h->{players}[$num];

    # max players reached?
    K->yield('_check_nb_players');

    # check if we have enough players
    K->yield('_check_errors');
}


#
# event: _but_new_player()
#
# called when button to create a player has been clicked.
#
sub _ongui_but_new_player {
    my $h = $_[HEAP];

    my $players = $h->{players};
    my @players = grep { defined $_ } @$players;

    # pick a name
    my %names;
    @names{ @NAMES } = ();
    delete @names{ map { $_->{name} } @players };
    my $name = ( shuffle keys %names )[0];

    # pick a color
    my %colors;
    @colors{ @COLORS } = ();
    delete @colors{ map { $_->{color} } @players };
    my $color = ( shuffle keys %colors )[0];

    # default type
    my $type = T('Computer, hard');

    # create new player
    K->yield('_new_player', $name, $type, $color);
}


#
# event: _but_quit()
#
# called when button quit is clicked, ie user wants to cancel new game.
#
sub _ongui_but_quit {
    my $h = $_[HEAP];
    K->alias_remove('startup');
    $h->{toplevel}->destroy;
}


#
# event: _but_start()
#
# called when button start is clicked. signal controller to really load
# a game.
#
sub _ongui_but_start {
    my $h = $_[HEAP];

    # remove undef players from list of players. this can happen when
    # deleting some players: it is removed, but the list keeps an undef
    # value.
    my $players = $h->{players};
    my @players = grep { defined $_ } @$players;
    my ($modmap) = grep { $_->title eq $h->{map} } Games::Risk->maps;
    debug( "map to be created: $modmap\n" );

    K->post('risk', 'new_game', { players => \@players, map => $modmap } );
    $h->{toplevel}->destroy;
}



1;

__END__

=pod

=head1 NAME

Games::Risk::GUI::Startup - startup window

=head1 VERSION

version 4.000

=head1 SYNOPSIS

    my $id = Games::Risk::GUI::Startup->spawn(\%params);

=head1 DESCRIPTION

This class implements a poe session responsible for the startup window
of the GUI. It allows to design the new game to be played.

=head1 METHODS

=head2 my $id = Games::Risk::GUI::Startup->spawn( )

=head1 SEE ALSO

L<Games::Risk>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
