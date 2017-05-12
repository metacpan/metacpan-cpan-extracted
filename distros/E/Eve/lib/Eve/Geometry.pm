package Eve::Geometry;

use parent qw(Eve::Class);

use strict;
use warnings;

use POSIX qw(strtod);

use Eve::Geometry::Point;
use Eve::Geometry::Polygon;

=head1 NAME

B<Eve::Geometry> - an abstract geometry class for map projection purposes.

=head1 SYNOPSIS

    use Eve::Geometry;

    my $geo = Eve::Geometry->from_string(
        string => 'PostGIS textual geometry representation');

=head1 DESCRIPTION

The class is a base for a generic geometry object that is required in
all operations with objects on the map projection.

=head1 METHODS

=head2 B<from_string>

A static method that parses the PostGIS textual representation of a
geometry object and returns a corresponding object.

=head3 B<Arguments>

=over 4

=item C<string>

=back

=head3 B<Returns>

=over 4

=item C<Eve::Geometry>

an object that implements the C<Eve::Geometry> abstract class.

=back

=cut

sub from_string {
    my ($class, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my ($string));

    my $result;
    if ($string =~ m/^POINT/) {

        $string =~ s/^POINT\(//;
        $string =~ s/\)$//g;

        my ($lng, $lat) = split(' ', $string);

        $lat = strtod($lat);
        $lng = strtod($lng);

        $result = Eve::Geometry::Point->new(data => [$lat, $lng]);
    } else {
        $string =~ s/^POLYGON\(\(//;
        $string =~ s/\)\)$//g;

        my $data = [];
        my @pairs = split(',', $string);

        map {
            my ($lng, $lat) = split(' ', $_);
            $lat = strtod($lat);
            $lng = strtod($lng);
            push @{$data}, [$lat, $lng];
        } @pairs;

        $result = Eve::Geometry::Polygon->new(data => $data);
    }
}


=head1 METHODS

=head2 B<clone()>

Clones and returns the object.

=head3 Returns

The object identical to self.

=cut

sub clone {
    my ($self) = @_;

    return $self->new(data => $self->export());
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

    return 'POINT((' . join(' ', @{$self->export()}) . '))';
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
