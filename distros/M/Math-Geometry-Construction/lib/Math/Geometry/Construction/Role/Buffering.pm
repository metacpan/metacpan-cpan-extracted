package Math::Geometry::Construction::Role::Buffering;
use Moose::Role;

use 5.008008;

use Carp;

=head1 NAME

C<Math::Geometry::Construction::Role::Buffering> - buffer results

=head1 VERSION

Version 0.018

=cut

our $VERSION = '0.018';


###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

requires 'construction';

has 'buffer' => (isa     => 'HashRef[Any]',
		 is      => 'bare',
		 traits  => ['Hash'],
		 default => sub { {} },
		 handles => {delete_buffer => 'delete',
			     is_buffered   => 'exists',
			     clear_buffer  => 'clear',
			     buffer        => 'accessor'});

sub clear_global_buffer {
    my ($self) = @_;

    $self->construction->clear_buffer;
}

1;


__END__

=pod

=head1 DESCRIPTION

This role provides a hash in which results can be stored in order to
prevent expensive recalculating when they are accessed. It is used
by C<DerivedPoint> and C<Derivate> objects to store their positions.

=head1 INTERFACE

=head3 buffer

The C<buffer> attribute implements the following hash traits (see
L<Moose|Moose> if you are not familiar with traits and native
delegation):

=over 4

=item * C<buffer> is the name of the C<accessor> method, which
provides accessor and mutator functionality for a single entry of
the hash

=item * C<delete_buffer> is the name of the C<delete> method, which
deletes a single entry of the hash

=item * C<clear_buffer> is the name of the C<clear> method, which
resets the hash to the empty hash

=back

=head3 clear_global_buffer

Calls L<clear_buffer|Math::Geometry::Construction/clear_buffer> on
the C<Math::Geometry::Construction> object. Mainly used as
C<trigger> for attributes. When the attribute is changed the buffer
is cleared.

=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

