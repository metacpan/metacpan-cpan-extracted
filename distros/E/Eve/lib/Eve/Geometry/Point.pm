package Eve::Geometry::Point;

use parent qw(Eve::Geometry);

use strict;
use warnings;

=head1 NAME

B<Eve::Geometry::Point> - a point geometry class for map projection purposes.

=head1 SYNOPSIS

    use Eve::Geometry::Point;

    my $geo = Eve::Geometry->new(data => [$lat, $lng]);

=head1 DESCRIPTION

The class is a base for a generic geometry object that is required in
all operations with objects on the map projection.

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my ($data));

    $self->{'latitude'} = $data->[0];
    $self->{'longitude'} = $data->[1];
}

=head2 B<export()>

Returns an array reference with the representation of the geometry object.

=head3 Returns

C<ARRAY>.

=cut

sub export {
    my ($self) = @_;

    return [$self->latitude, $self->longitude];
}

=head2 B<serialize()>

Returns a string representation of the geometry object.

=head3 Returns

C<ARRAY>.

=cut

sub serialize {
    my ($self) = @_;

    return 'POINT(' . join(' ', reverse(@{$self->export()})) . ')';
}

=head1 SEE ALSO

=over 4

=item C<Eve::Class>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHOR

=over 4

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=back

=cut

1;
