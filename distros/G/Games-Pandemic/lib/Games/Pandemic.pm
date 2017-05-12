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

package Games::Pandemic;
{
  $Games::Pandemic::VERSION = '1.120510';
}
# ABSTRACT: cooperative pandemic board game

# although it's not strictly needed to load POE::Kernel manually (since
# MooseX::POE will load it anyway), we're doing it here to make sure poe
# will use tk event loop. this can also be done by loading module tk
# before poe, for example if we load games::pandemic::tk::main before
# moosex::poe... but better be safe than sorry, and doing things
# explicitly is always better.
use POE::Kernel { loop => 'Tk' };

use MooseX::Singleton;  # should come before any other moose
use MooseX::Has::Sugar;
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Config;
use Games::Pandemic::Controller;
use Games::Pandemic::Tk::Main;


# -- accessors

has config => (
    ro,
    writer   => '_set_config',
    default  => sub { Games::Pandemic::Config->new },
    isa      => 'Games::Pandemic::Config'
);

has map => (
    rw,
    isa     => 'Games::Pandemic::Map',
    clearer => 'clear_map',
);

# player cards deck
has cards => (
    rw,
    isa     => 'Games::Pandemic::Deck',
    clearer => 'clear_cards_deck',
);

# infection cards deck
has infection => (
    rw,
    isa     => 'Games::Pandemic::Deck',
    clearer => 'clear_infection_deck',
);

# current players
has _players => (
    ro, auto_deref,
    traits  => ['Array'],
    isa     => 'ArrayRef[Games::Pandemic::Player]',
    default => sub { [] },
    handles => {
        all_players   => 'elements',       # my @p = $game->all_players;
        add_player    => 'push',           # $game->add_player( $player );
        clear_players => 'clear',
    }
);
# list of players waiting for their turn
has _players_in_turn => (
    ro, auto_deref,
    traits  => ['Array'],
    isa     => 'ArrayRef[Games::Pandemic::Player]',
    default => sub { [] },
    handles => {
        reinit_players        => 'push',  # $game->reinit_players( $player );
        next_player           => 'shift', # my $p = $game->next_player;
        clear_players_in_turn => 'clear',
    }
);
has curplayer => (
    rw, weak_ref,
    isa     => 'Games::Pandemic::Player',
    clearer => 'clear_curplayer',
);

# game state
has state => ( rw, isa=>'Str' );
has is_in_play => (
    ro,
    traits  => ['Bool'],
    isa     => 'Bool',
    default => 0,
    handles => {
        has_started => 'set',
        has_ended   => 'unset',
    }
);


# number of research stations remaining to be build
has stations => (
    rw,
    traits  => ['Counter'],
    default => 0, # just to clear moose warning
    isa     => 'Int',
    handles => { dec_stations => 'dec' },
);

has nb_outbreaks => (
    ro,
    traits  => ['Counter'],
    default => 0, # just to clear moose warning
    isa     => 'Int',
    handles => {
        _inc_outbreaks => 'inc',
        set_outbreaks  => 'set',
    },
);




sub inc_outbreaks {
    my $self = shift;
    return if $self->nb_outbreaks == 8; # FIXME: game dependant?
    $self->_inc_outbreaks;
}


# holds the player having too many cards - if any
has too_many_cards => (
    rw, weak_ref,
    isa      => 'Maybe[Games::Pandemic::Player]',
    default  => undef,
    clearer  => 'clear_too_many_cards',
);


# whether there will be a propagation in this turn
has propagation => (
    ro,
    traits  => ['Bool'],
    isa     => 'Bool',
    default => 1,
    handles => {
        enable_propagation  => 'set',
        disable_propagation => 'unset',
    }
);

has nb_epidemics => (
    ro,
    traits  => ['Counter'],
    default => 0, # just to clear moose warning
    isa     => 'Int',
    handles => {
        inc_epidemics => 'inc',
        set_epidemics => 'set',
    },
);


sub infection_rate {
    my $self = shift;
    my $map  = $self->map;
    my $nbepidemics = $self->nb_epidemics;
    my @rates = $map->infection_rates;
    return $nbepidemics >= scalar(@rates)
        ? $rates[-1] : $rates[$nbepidemics];
}

has next_step => ( is=>'rw', isa=>'Str', clearer=>'clear_next_step' );


# -- public methods


sub run {
    # create the poe sessions
    Games::Pandemic::Controller->new;
    Games::Pandemic::Tk::Main->new;

    # and let's start the fun!
    POE::Kernel->run;
}

no Moose;
#__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic - cooperative pandemic board game

=head1 VERSION

version 1.120510

=head1 SYNOPSIS

    use Games::Pandemic;
    Games::Pandemic->new;
    Games::Pandemic->run;

=head1 DESCRIPTION

Pandemic is a cooperative game where the players are united to beat the
game. The goal is to find the cures for various diseases striking
cities, before they propagate too much.

This distribution implements a graphical interface for this game. I
definitely recommend you to buy a C<pandemic> board game and play with
friends, you'll have an exciting time - much more than with this poor
electronic copy.

=head1 METHODS

=head2 $game->inc_outbreaks;

Increment number of outbreaks, up to a maximum of 8.

=head2 my $nb = $game->infection_rate;

Return the infection rate, that is, the number of cities infected per
turn. This rate is growing with number of epidemics, according to the
table given by the map's C<infection_rates()> method.

=head2 Games::Pandemic->run;

Create the various POE sessions, and start the POE kernel.

=head1 SEE ALSO

You can look for information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Pandemic>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Pandemic>

=item * Git repository

L<http://github.com/jquelin/games-pandemic>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Pandemic>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Pandemic>

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__

