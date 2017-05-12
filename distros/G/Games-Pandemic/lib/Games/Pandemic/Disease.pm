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

package Games::Pandemic::Disease;
{
  $Games::Pandemic::Disease::VERSION = '1.120510';
}
# ABSTRACT: pandemic disease object

use File::Spec::Functions qw{ catfile };
use Moose                 0.92;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;


# -- attributes

has colors => (
    ro, required,
    traits   => ['Array'],
    isa      => 'ArrayRef[Str]',
    handles  => { color => 'get' },
);
has id    => ( ro, required, isa => 'Int' );
has name  => ( ro, required, isa => 'Str' );
has nbleft => (
    ro, lazy,
    traits  => ['Number'],
    isa     => 'Int',
    builder => '_build_nb',
    handles => {
        return => 'add',
        take   => 'sub',
    },
);
has nbmax => ( ro, required, isa => 'Int' );
has _map  => ( ro, required, weak_ref, isa => 'Games::Pandemic::Map' );

has has_cure => (
    ro,
    traits  => ['Bool'],
    isa     => 'Bool',
    default => 0,
    handles => { find_cure => 'set' },
);

has is_eradicated => (
    ro,
    traits  => ['Bool'],
    isa     => 'Bool',
    default => 0,
    handles => { eradicate => 'set' },
);

# -- default builders / finishers

sub DEMOLISH {
    my $self = shift;
    debug( "~disease: " . $self->name . "\n" );
}

sub _build_nb { $_[0]->nbmax }


# -- public methods


sub image {
    my ($self, $what, $size) = @_;
    return catfile( $self->_map->sharedir, $what . '-' . $self->id . "-$size.png" );
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Disease - pandemic disease object

=head1 VERSION

version 1.120510

=head1 METHODS

=head2 my $path = $disease->image($what);

Return the C<$path> to an image for the disease. C<$what> can be either
C<cube> or C<cure>.

=for Pod::Coverage DEMOLISH

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__

