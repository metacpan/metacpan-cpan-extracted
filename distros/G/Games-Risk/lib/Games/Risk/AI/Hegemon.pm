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

package Games::Risk::AI::Hegemon;
# ABSTRACT: ai that tries to conquer the world
$Games::Risk::AI::Hegemon::VERSION = '4.000';
use List::MoreUtils qw{ all };

use Games::Risk::I18n qw{ T };

use base qw{ Games::Risk::AI };

#--
# METHODS

# -- public methods

#
# my ($action, [$from, $country]) = $ai->attack;
#
# See pod in Games::Risk::AI for information on the goal of this method.
#
# This implementation will attack various countries according to various
# heuristics, maximizing the chances of the ai to win.
#
sub attack {
    my ($self) = @_;
    my $me   = $self->player;
    my $game = $self->game;
    my @my_countries = $me->countries;
    my @continents   = $game->map->continents;

    # get all possible attacks
    my @options;
    foreach my $country ( @my_countries ) {
        next if $country->armies == 1;

        # attack ratio of 50% min
        my $max = $country->armies / 2;
        foreach my $neighbour ( $country->neighbours ) {
            next if $neighbour->owner eq $me;
            next if $neighbour->armies >= $max;
            push @options, [ $country, $neighbour ];
        }
    }

    # sort players by threat
    my @players =
        sort { $b->greatness <=> $a->greatness }
        grep { $_ ne $me }
        $game->players_active;

    # 1- attack player most threatening
    my @attack;
    PLAYER:
    foreach my $player ( @players ) {
        foreach my $option ( @options ) {
            my ($src, $dst) = @$option;
            next unless $dst->owner eq $player;
            @attack = ( $src, $dst );
            last PLAYER;
        }
    }

    # 2- try to complete continent
    my $count   = 0;
    my $complex = 0;
    my $from;
    foreach my $continent ( @continents ) {
        next unless $self->_owns_mostly( $continent );
        my @countries = $continent->countries;

        # find biggest attack base
        foreach my $country ( @countries ) {
            next unless $country->owner eq $me;
            next unless $country->armies > $count;
            $count = $country->armies;
            $from  = $country;
        }

        #
        foreach my $country ( @countries ) {
            next if $country->owner eq $me;
            next unless $country->armies + 1 < $count;
            next unless $from->is_neighbour($country);
            @attack  = ( $from, $country );
            $complex = 1;
            last;
        }
    }

    # 3- else attempt to attack continent with the greatest territories
    # owned, that has yet to be conquered.
    if ( not $complex ) {
        my $value = 0; # FIXME: uh, don't understand this
        my $choice;

        foreach my $continent ( @continents ) {
            next if $continent->is_owned($me);
            my @owned =
                grep { $_->owner eq $me }
                $continent->countries;

            $choice = $continent if scalar(@owned) > $value;
        }

        if ( $choice ) {
            my @countries = $choice->countries;
            foreach my $country ( @countries ) {
                next unless $country->owner eq $me;
                next unless $country->armies > $count;
                $count = $country->armies;
                $from  = $country;
            }
            foreach my $country ( @countries ) {
                next if $country->owner eq $me;
                next unless $country->armies + 1 < $count;
                next unless $from->is_neighbour( $country );
                @attack = ( $from, $country );
                last;
            }
        }
    }

    # 4- check continents to break
    my @to_break = $self->_continents_to_break;

    if ( scalar(@to_break) ) {
        RANGE:
        foreach my $range ( 1 .. 4 ) {
            foreach my $continent ( @to_break ) {
                foreach my $country ( @my_countries ) {
                    NEIGHBOUR:
                    foreach my $neighbour ( $country->neighbours ) {
                        # fight to death on the last step of breaking a
                        # continent bonus.
                        next unless $country->armies - 1 > $neighbour->armies
                            || ( $range == 1 && $country->armies > 1 );

                        my $freeable = _short_path_to_continent(
                            $continent, $country, $neighbour, $range);
                        next NEIGHBOUR if not $freeable;
                        # eheh, we found a path!
                        @attack = ( $country, $neighbour );
                        last RANGE;
                    }
                }
            }
        }
    }

    # 5- check to see if we can crush a player
    # find weak players
    my @weaks =
        grep { scalar($_->countries) < 4 }  # less than 4 countries
        grep { $_ ne $me }
        $self->game->players_active;
    foreach my $weak ( @weaks ) {
        foreach my $country ( $weak->countries ) {
            foreach my $neighbour ( $country->neighbours ) {
                next unless $neighbour->owner eq $me;
                next unless $country->armies - 2 < $neighbour->armies;
                next unless $neighbour->armies > 1;

                @attack = ( $neighbour, $country );
                last; # FIXME: last outer foreach?
            }
        }
    }

    return ( 'attack', @attack ) if @attack;

    # hum. we don't have that much choice, do we?
    return ('attack_end', undef, undef);
}


#
# my $nb = $ai->attack_move($src, $dst, $min);
#
# See pod in Games::Risk::AI for information on the goal of this method.
#
# This implementation always move the maximum possible from $src to
# $dst.
#
sub attack_move {
    my ($self, $src) = @_;

    my $nbsrc = $src->armies;
    my $max   = $nbsrc - 1;

    my $continent = $src->continent;
    return $max unless $continent->is_owned($self->player);
    return $max unless $self->_owns_mostly($continent);

    # attempt to safeguard critical areas when moving armies.
    if    ( $nbsrc > 8 )                { return $max-4; }
    elsif ( $nbsrc > 5 && $nbsrc <= 7 ) { return 4; }
    else  { return 3; }
}


#
# my $difficulty = $ai->difficulty;
#
# Return a difficulty level for the ai.
#
sub difficulty { return T('hard') }


#
# my @where = $ai->move_armies;
#
# See pod in Games::Risk::AI for information on the goal of this method.
#
# This implementation reinforces armies from less critical to more
# critical areas.
#
sub move_armies {
    my ($self) = @_;
    #my $me = $self->player;

    my @where;
    # move all armies from countries enclosed within other countries
    # that we own.
    foreach my $country ( $self->player->countries ) {
        next unless $self->_owns_neighbours($country);

        foreach my $neighbour ( $country->neighbours ) {
            next if $self->_owns_neighbours($neighbour);
            push @where, [ $country, $neighbour, $country->armies - 1 ];
            last;
        }
    }

    return @where;
}


#
# my @where = $ai->place_armies($nb, [$continent]);
#
# See pod in Games::Risk::AI for information on the goal of this method.
#
# This implementation will place the armies according to various
# heuristics, maximizing the chances of the ai to win.
#
sub place_armies {
    my ($self, $nb) = @_;

    # FIXME: restrict to continent if strict placing
    #my @countries = defined $continent
    #    ? grep { $_->continent->id == $continent } $player->countries
    #    : $player->countries;

    # 1- find a country that can be used as an attack base.
    my $where = $self->_country_to_attack_from(11);

    # 2- check if we can block another player from gaining a continent.
    # this takes precedence over basic attack as defined in 1-
    my $block = $self->_country_to_block_continent;
    $where    = $block if defined $block;

    # 3- even more urgent: try to remove a continent from the greedy
    # hands of another player. ai will try to free continent as far as 4
    # countries! prefer to free closer continents - if range equals,
    # decision is taken based on continent worth.
    my $free = $self->_country_to_free_continent;
    $where   = $free if defined $free;

    # 4- another good opportunity: completely crushing a weak enemy
    my $weak = $self->_country_to_crush_weak_enemy;
    $where   = $weak if defined $weak;

    # 5- if no base found, default to any suitable attack base.
    $where //= $self->_country_to_attack_from(10_000); # 10_000 armies should never be reached!

    # 6- if still no base found (?), pick first owned country.
    $where //= ($self->countries)[0];


    # assign all of our armies in one country
    return ( [ $where, $nb ] );
}


# -- private methods

#
# my $bool = $ai->_almost_owned( $player, $continent );
#
# Return true if $continent is almost (as in "all countries but 2")
# owned by $player.
#
sub _almost_owned {
    my ($self, $player, $continent) = @_;

    my @countries = $continent->countries;
    my @owned     = grep { $_->owner eq $player } @countries;

    return scalar(@owned) >= scalar(@countries) - 2;
}


#
# my @continents = $ai->_continents_to_break;
#
# Return a list of continents owned by a single player which isn't the
# ai.
#
sub _continents_to_break {
    my ($self) = @_;
    my $me = $self->player;

    # owned continents, sorted by worth value
    my @to_break =
        grep { not $_->is_owned($me) }
        sort { $b->bonus <=> $a->bonus }
        $self->game->map->continents_owned;

    return @to_break;
}


#
# my $country = $self->_country_to_attack_from($nb);
#
# Return a country that can be used to attack neighbours. The country
# should be next to an enemy, and have less than $nb armies.
#
sub _country_to_attack_from {
    my ($self, $nb) = @_;

    foreach my $country ( $self->player->countries ) {
        next if $self->_owns_neighbours($country);
        next if $country->armies > $nb;
        return $country;
    }

    return;
}


#
# my $country = $self->_country_to_block_continent;
#
# Return a country on a continent almost owned by another player. This
# will be used to pile up armies on it, to block continent from falling
# in the hands of the other player.
#
sub _country_to_block_continent {
    my ($self) = @_;
    my $me   = $self->player;
    my $game = $self->game;
    my $map  = $game->map;

    PLAYER:
    foreach my $player ( $game->players_active ) {
        next PLAYER if $player eq $me;

        CONTINENT:
        foreach my $continent ( $map->continents ) {
            next CONTINENT unless $self->_almost_owned($player, $continent);
            next CONTINENT if     $continent->is_owned($player);

            # continent almost owned, let's try to block!
            COUNTRY:
            foreach my $country ( $continent->countries ) {
                next COUNTRY if $country->owner ne $me;
                next COUNTRY if $country->armies > 5;

                # ok, we've found a country to fortify.
                return $country;
            }
        }
    }

    return;
}


#
# my $country = $self->_country_to_crush_weak_enemy;
#
# Return a country that can be used to crush a weak enemy.
#
sub _country_to_crush_weak_enemy {
    my ($self) = @_;

    # find weak players
    my @weaks =
        grep { scalar($_->countries) < 4 }  # less than 4 countries
        grep { $_ ne $self->player }
        $self->game->players_active;
    return unless @weaks;

    # potential targets
    my @targets = map { $_->countries } @weaks;

    COUNTRY:
    foreach my $country ( $self->player->countries ) {
        WEAK:
        foreach my $target ( @targets ) {
            next WEAK unless $country->is_neighbour($target);
            return $country;
        }
    }

    return;
}


#
# my $country = $self->_country_to_free_continent;
#
# Return a country that can be used to attack a continent owned by another player. This
# will prevent the user from getting the bonus.
#
sub _country_to_free_continent {
    my ($self) = @_;

    my @to_break     = $self->_continents_to_break;
    my @my_countries = $self->player->countries;

    RANGE:
    foreach my $range ( 1 .. 4 ) {
        foreach my $continent ( @to_break ) {
            foreach my $country ( @my_countries ) {
                NEIGHBOUR:
                foreach my $neighbour ( $country->neighbours ) {
                    my $freeable = _short_path_to_continent(
                        $continent, $country, $neighbour, $range);
                    next NEIGHBOUR if not $freeable;
                    # eheh, we found a path!
                    return $country;
                }
            }
        }
    }

    return;
}


#
# my $descr = $ai->_description;
#
# Return a brief description of the ai and the way it operates.
#
sub _description {
    return T(q{

        This artificial intelligence is optimized to conquer the world.
        It checks what countries are most valuable for it, optimizes
        attacks and moves for continent bonus and blocking other
        players.

    });
}


#
# my $bool = $ai->_owns_mostly( $continent );
#
# Return true if $ai owns more than half of $continent.
#
sub _owns_mostly {
    my ($self, $continent) = @_;

    my @countries = $continent->countries;
    my @owned     = grep { $_->owner eq $self->player } @countries;
    return scalar(@owned) >= scalar(@countries) / 2;
}


#
# my $bool = $ai->_owns_neighbours($country);
#
# Return true if ai also owns all the neighbours of $country.
#
sub _owns_neighbours {
    my ($self, $country) = @_;

    my $player = $self->player;
    return all { $_->owner eq $player } $country->neighbours;
}


#--
# SUBROUTINES

# -- private subs

#
# my $bool = _short_path_to_continent( $continent,
#                                      $from, $through, $range );
#
# Return true if $continent is within $range (integer) of $from, going
# through country $through.
#
sub _short_path_to_continent {
    my ($continent, $from, $through, $range) = @_;

    # can't attack if both $from and $through are owned by the same
    # player, or if they are not neighbour of each-other.
    return 0 unless $from->is_neighbour($through);
    return 0 if $from->owner eq $through->owner;

    # definitely not within range.
    return 0 if $range <= 0 && $from->continent ne $continent;

    # within range.
    return 1 if $from->continent eq $continent;
    return 1 if $range > 0 && $through->continent eq $continent;

    # not currently within range, let's try one hop further.
    foreach my $country ( $through->neighbours ) {
        return 1 if
            _short_path_to_continent($continent, $through, $country, $range-1);
    }

    # dead-end, abort this path.
    return 0;
}

1;

__END__

=pod

=head1 NAME

Games::Risk::AI::Hegemon - ai that tries to conquer the world

=head1 VERSION

version 4.000

=head1 SYNOPSIS

    my $ai = Games::Risk::AI::Hegemon->new(\%params);

=head1 DESCRIPTION

This artificial intelligence is optimized to conquer the world.  It
checks what countries are most valuable for it, optimizes attacks and
moves for continent bonus and blocking other players.

=head1 METHODS

This class implements (or inherits) all of those methods (further described in
C<Games::Risk::AI>):

=over 4

=item * attack()

=item * attack_move()

=item * description()

=item * difficulty()

=item * move_armies()

=item * place_armies()

=back

=head1 ACKNOWLEDGEMENTS

This AI is freely adapted from jRisk.

=head1 SEE ALSO

L<Games::Risk::AI>, L<Games::Risk>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
