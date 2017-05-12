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

package Games::Risk::AI::Blitzkrieg;
# ABSTRACT: easy ai that does blitzkrieg attacks
$Games::Risk::AI::Blitzkrieg::VERSION = '4.000';
use List::Util qw{ shuffle };

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
# This implementation attacks starting from its attack base (where it
# has piled new armies). It tries not to suicide itself by always
# requiring 4 armies at least in the attacking country.
#
sub attack {
    my ($self) = @_;
    my $player = $self->player;

    # find first possible attack
    #my ($src, $dst);
    COUNTRY:
    foreach my $country ( shuffle $player->countries )  {
        # don't attack unless there's somehow a chance to win
        next COUNTRY if $country->armies < 4;

        NEIGHBOUR:
        foreach my $neighbour ( shuffle $country->neighbours ) {
            # don't attack ourself
            next NEIGHBOUR if $neighbour->owner eq $player;
            return ('attack', $country, $neighbour);
        }
    }

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
    return $src->armies - 1;
}


#
# my $difficulty = $ai->difficulty;
#
# Return a difficulty level for the ai.
#
sub difficulty { return T('easy') }


#
# my @where = $ai->move_armies;
#
# See pod in Games::Risk::AI for information on the goal of this method.
#
# This implementation will not move any armies at all, and thus inherits
# this method from Games::Risk::AI.
#


#
# my @where = $ai->place_armies($nb, [$continent]);
#
# See pod in Games::Risk::AI for information on the goal of this method.
#
# This implementation will place all the armies on the same country,
# which will be its attack base during attack phase.
#
sub place_armies {
    my ($self, $nb) = @_;
    my $player = $self->player;

    # FIXME: restrict to continent if strict placing
    #my @countries = defined $continent
    #    ? grep { $_->continent->id == $continent } $player->countries
    #    : $player->countries;

    # find a country that can be used as an attack base.
    my $where;
    COUNTRY:
    foreach my $country ( shuffle $player->countries )  {
        NEIGHBOUR:
        foreach my $neighbour ( shuffle $country->neighbours ) {
            # don't attack ourself
            next NEIGHBOUR if $neighbour->owner eq $player;
            $where = $country;
            last COUNTRY;
        }
    }

    # hmm, we could not find a suitable base for our next attack. 
    # FIXME: this is only true if playing with capitals, and the only
    # base suitable is our capital.
    #$where //= 

    # assign all of our armies in one country
    return ( [ $where, $nb ] );
}


# -- private methods

#
# my $descr = $ai->_description;
#
# Return a brief description of the ai and the way it operates.
#
sub _description {
    return T(q{

        This artificial intelligence follows a blitzkrieg strategy. It
        will piles up new armies in one country, and then follow a
        random path from this attack base.

    });
}


1;

__END__

=pod

=head1 NAME

Games::Risk::AI::Blitzkrieg - easy ai that does blitzkrieg attacks

=head1 VERSION

version 4.000

=head1 SYNOPSIS

    my $ai = Games::Risk::AI::Blitzkrieg->new(\%params);

=head1 DESCRIPTION

This module implements a quite easy ai for risk, that plays according to
a blitzkrieg strategy. It will piles up new armies in one country, and
then follow a random path from this attack base.

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

=head1 SEE ALSO

L<Games::Risk::AI>, L<Games::Risk>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
