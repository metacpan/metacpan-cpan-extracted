#   ------------------------------------------------------------------------------------------------
#
#   file: t/lib/DistZillaPlugin.pm
#
#   This file is part of perl-Dist-Zilla-Tester-DieHard.
#
#   ------------------------------------------------------------------------------------------------

package DistZillaPlugin;

use Moose;
use namespace::autoclean;

with 'Dist::Zilla::Role::Plugin';

sub BUILD {
    my ( $self ) = @_;
    $self->log( 'before die' );
    die;
};

__PACKAGE__->meta->make_immutable;

1;

# end of file #
