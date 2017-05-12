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

package Games::Pandemic::Card::Special::OneQuietNight;
{
  $Games::Pandemic::Card::Special::OneQuietNight::VERSION = '1.120510';
}
# ABSTRACT: quiet night event card for pandemic

use File::Spec::Functions qw{ catfile };
use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::I18n      qw{ T };
use Games::Pandemic::Utils;

extends 'Games::Pandemic::Card::Special';

# -- default builders

sub _build_icon  { catfile($SHAREDIR, 'cards', 'one-quiet-night-16.png' ) }
sub _build_label { T('One quiet night') }
sub _build_description {
    T( 'This event prevents the next infection phase to be '
    . 'played: it will be skipped.' );
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Card::Special::OneQuietNight - quiet night event card for pandemic

=head1 VERSION

version 1.120510

=head1 DESCRIPTION

This package implements the special event card C<one quiet night>. When
played, this event prevents the next infection phase to be played: it
will be skipped.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__


