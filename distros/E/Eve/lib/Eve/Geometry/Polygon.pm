package Eve::Geometry::Polygon;

use parent qw(Eve::Geometry);

use strict;
use warnings;

=head1 NAME

B<Eve::Geometry::Polygon> - a polygon geometry class for map
projection purposes.

=head1 SYNOPSIS

    use Eve::Geometry::Polygon;

    my $geo = Eve::Geometry->new(data => [[$lat, $lng], [$lat, $lng], ...]);

=head1 DESCRIPTION

The class is a polygon geometry object.

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my ($data));

    $self->{'length'} = scalar @{$data};
    $self->{'data'} = $data;
}

=head2 B<export()>

Returns an array reference with the representation of the geometry object.

=head3 Returns

C<ARRAY>.

=cut

sub export {
    my ($self) = @_;

    return $self->data;
}

=head2 B<serialize()>

Returns a string representation of the geometry object.

=head3 Returns

C<ARRAY>.

=cut

sub serialize {
    my ($self) = @_;

    return (
        'POLYGON(('
        . join(
            ',',
            map { join(' ', reverse(@{$_})) } @{$self->export()})
        . '))');
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
