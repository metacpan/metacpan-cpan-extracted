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

package Games::Pandemic::Card::Special::GovernmentGrant;
{
  $Games::Pandemic::Card::Special::GovernmentGrant::VERSION = '1.120510';
}
# ABSTRACT: government grant event card for pandemic

use File::Spec::Functions qw{ catfile };
use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::I18n      qw{ T };
use Games::Pandemic::Utils;

extends 'Games::Pandemic::Card::Special';

# -- default builders

sub _build_icon  { catfile($SHAREDIR, 'cards', 'government-grant-16.png' ) }
sub _build_label { T('Government grant') }
sub _build_description {
    T( 'This event allows to add a research station to any city for free.' );
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Card::Special::GovernmentGrant - government grant event card for pandemic

=head1 VERSION

version 1.120510

=head1 DESCRIPTION

This package implements the special event card C<government grant>.
When played, this event allows to add a research station to any
city for free.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__


