package Eve::PgSqlType::Geometry;

use parent qw(Eve::PgSqlType);

use strict;
use warnings;

use DBD::Pg ();
use POSIX qw(strtod);

use Eve::Geometry::Point;
use Eve::Geometry::Polygon;

=head1 NAME

B<Eve::PgSqlType::Geometry> - a generic PostGIS geometry type wrapper.

=head1 SYNOPSIS

    my $bigint = Eve::PgSqlType::Geometry->new();
    $bigint->serialize(value => $geometry);

=head1 DESCRIPTION

B<Eve::PgSqlType::Geometry> is a generic PostGIS type that allows
basic conversion from PostGIS internal format to a simple
B<Eve::Geometry> object.

=head1 METHODS

=head2 B<get_type()>

=head3 Returns

The PG_ANY type.

=cut

sub get_type {
    return DBD::Pg::PG_ANY;
}

=head2 B<wrap()>

Wraps an expression with CAST statement.

=head3 Arguments

=over 4

=item C<expression>

=back

=head3 Returns

CAST (C<expression> AS geometry)

=cut

sub wrap {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $expression);

    return 'CAST ('.$expression.' AS geometry)';
}

=head2 B<serialize()>

Formats a B<Eve::Geometry> object into the appropriate string
representation.

=head3 Arguments

=over 4

=item C<value>

=back

=head3 Returns

The string like 'geomfromtext('POINT(XXX YYY)', 4001)'.

=cut

sub serialize {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $value);

    return
        q{(geomfromtext('} . $value->serialize() . q{', 4001))};
}

=head2 B<deserialize()>

Parses a geometry string representation into the appropriate
B<Eve::Geometry> object.

=head3 Arguments

=over 4

=item C<value>

=back

=head3 Returns

A B<Eve::Geometry> object.

=cut

sub deserialize {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $value);

    my $result;
    if (defined $value) {
         $result = Eve::Geometry->from_string(string => $value);
    }

    return $result;
}

=head1 SEE ALSO

=over 4

=item L<Eve::Geometry>

=item L<DBD::Pg>

=item L<Eve::PgSqlType>

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
