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

package Games::Pandemic::Card::Special::Forecast;
{
  $Games::Pandemic::Card::Special::Forecast::VERSION = '1.120510';
}
# ABSTRACT: "forecast" event card for pandemic

use File::Spec::Functions qw{ catfile };
use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::I18n      qw{ T };
use Games::Pandemic::Utils;

extends 'Games::Pandemic::Card::Special';

# -- default builders

sub _build_icon  { catfile($SHAREDIR, 'cards', 'forecast-16.png' ) }
sub _build_label { T('Forecast') }
sub _build_description {
    T( 'This event allows to examine the top 6 infections to come and '
     . 'rearrange them in the order of your choice.' );
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Card::Special::Forecast - "forecast" event card for pandemic

=head1 VERSION

version 1.120510

=head1 DESCRIPTION

This package implements the special event card C<forecast>. When played,
this event allows to examine the top 6 infections to come and rearrange
them in the order of your choice.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__


