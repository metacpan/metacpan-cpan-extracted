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

package Games::Pandemic::Card::Special::ResilientPopulation;
{
  $Games::Pandemic::Card::Special::ResilientPopulation::VERSION = '1.120510';
}
# ABSTRACT: resilient population event card for pandemic

use File::Spec::Functions qw{ catfile };
use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::I18n      qw{ T };
use Games::Pandemic::Utils;

extends 'Games::Pandemic::Card::Special';

# -- default builders

sub _build_icon  { catfile($SHAREDIR, 'cards', 'resilient-population-16.png' ) }
sub _build_label { T('Resilient population') }
sub _build_description {
    T( 'This event allows to pick a city from past infections '
     . 'and remove it from the game.' );
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Card::Special::ResilientPopulation - resilient population event card for pandemic

=head1 VERSION

version 1.120510

=head1 DESCRIPTION

This package implements the special event card C<resilient population>.
When played, this event allows to pick a city from past infections and
remove it from the game.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__


