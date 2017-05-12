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

package Games::Risk::AI::Dumb;
# ABSTRACT: dumb ai that does nothing
$Games::Risk::AI::Dumb::VERSION = '4.000';
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
# This implementation never attacks anything, it ends its attack turn as soon
# as it begins. Therefore, it always returns ('attack_end', undef, undef).
#
sub attack {
    return ('attack_end', undef, undef);
}


#
# my $difficulty = $ai->difficulty;
#
# Return a difficulty level for the ai.
#
sub difficulty { return T('very easy') }


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
# This implementation will place the armies randomly on the continent owned by
# the AI, maybe restricted by $continent if it is specified.
#
sub place_armies {
    my ($self, $nb, $continent) = @_;

    # get list of countries eligible.
    my $player = $self->player;

    my @countries = defined $continent
        ? grep { $_->continent->id == $continent } $player->countries
        : $player->countries;

    # assign armies randomly.
    my @where = ();
    push @where, [ $countries[ rand @countries ], 1 ] while $nb--;
    return @where;
}


# -- private methods

#
# my $descr = $ai->_description;
#
# Return a brief description of the ai and the way it operates.
#
sub _description {
    return T(q{

        This artificial intelligence does nothing: it just piles up new armies
        randomly, and never ever attacks nor move armies.

    });
}

1;

__END__

=pod

=head1 NAME

Games::Risk::AI::Dumb - dumb ai that does nothing

=head1 VERSION

version 4.000

=head1 SYNOPSIS

    my $ai = Games::Risk::AI::Dumb->new(\%params);

=head1 DESCRIPTION

This module implements a dumb ai for risk, that does nothing. It just piles up
new armies randomly, and never ever attacks nor move armies.

=head1 METHODS

This class implements (or inherits) all of those methods (further described in
C<Games::Risk::AI>):

=over 4

=item * attack()

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
