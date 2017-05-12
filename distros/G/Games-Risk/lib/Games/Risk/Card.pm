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

package Games::Risk::Card;
# ABSTRACT: map card
$Games::Risk::Card::VERSION = '4.000';
use Moose;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

use Games::Risk::Logger qw{ debug };
use Games::Risk::Types;


# -- attributes


has type    => ( ro, isa=>'CardType', required );
has country => ( rw, isa=>'Games::Risk::Country', weak_ref );


# -- builders / finishers

sub DEMOLISH {
    my $self = shift;
    my $type = $self->type;
    my $country = $self->country;
    my $name = $country ? $country->name : '';
    debug( "~card: $type ($name)\n" );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Games::Risk::Card - map card

=head1 VERSION

version 4.000

=head1 DESCRIPTION

This module implements a map card, with all its characteristics.

=head1 ATTRIBUTES

=head2 country

Country corresponding to the card (L<Map::Games::Risk::Country> object).

=head2 type

Type of the card: C<artillery>, C<cavalry>, C<infantery> or C<joker>.

=for Pod::Coverage DEMOLISH

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
