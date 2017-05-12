package Eve::PgSqlType::Timestamp;

use parent qw(Eve::PgSqlType);

use strict;
use warnings;

use DateTime::Format::Pg;
use DBD::Pg ();

=head1 NAME

B<Eve::PgSqlType::Timestamp> - a PostgreSQL timestamp without timezone type.

=head1 SYNOPSIS

    my $bigint = Eve::PgSqlType::Timestamp->new();
    $bigint->serialize(value => $datetime);

=head1 DESCRIPTION

B<Eve::PgSqlType::Timestamp> is a PostgreSQL timestamp
without time zone type adapter class.

=head1 METHODS

=head2 B<get_type()>

=head3 Returns

The PG_TIMESTAMP type.

=cut

sub get_type {
    return DBD::Pg::PG_TIMESTAMP;
}

=head2 B<wrap()>

Wraps an expression with CAST statement.

=head3 Arguments

=over 4

=item C<expression>

=back

=head3 Returns

CAST (C<expression> AS timestamp without time zone)

=cut

sub wrap {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $expression);

    return 'CAST ('.$expression.' AS timestamp without time zone)';
}

=head2 B<serialize()>

Formats a B<DateTime> object into the appropriate string timestamp
without timezone representation with the B<DateTime::Format::Pg> module.

=head3 Arguments

=over 4

=item C<value>

=back

=head3 Returns

The string like '2011-03-21 20:41:34.123456'.

=cut

sub serialize {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $value);

    return DateTime::Format::Pg->format_timestamp_without_time_zone($value);
}

=head2 B<deserialize()>

Parses a timestamp without time zone string representation into the
appropriate B<DateTime> object with the B<DateTime::Format::Pg>
module.

=head3 Arguments

=over 4

=item C<value>

=back

=head3 Returns

A B<DateTime> object.

=cut

sub deserialize {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $value);

    my $result;
    if (defined $value) {
        $result = DateTime::Format::Pg->parse_timestamp_without_time_zone(
            $value);
    }

    return $result;
}

=head1 SEE ALSO

=over 4

=item L<DateTime>

=item L<DateTime::Format::Pg>

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

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=back

=cut

1;
