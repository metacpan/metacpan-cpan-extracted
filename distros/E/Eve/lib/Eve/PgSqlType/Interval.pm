package Eve::PgSqlType::Interval;

use parent qw(Eve::PgSqlType);

use strict;
use warnings;

use DateTime::Format::Pg;
use DBD::Pg ();

=head1 NAME

B<Eve::PgSqlType::Interval> - a PostgreSQL interval type.

=head1 SYNOPSIS

    my $interval = Eve::PgSqlType::Interval->new();
    $interval->serialize(value => $duration);

=head1 DESCRIPTION

B<Eve::PgSqlType::Interval> is a PostgreSQL interval type adapter
class.

=head1 METHODS

=head2 B<get_type()>

=head3 Returns

The PG_TIMESTAMP type.

=cut

sub get_type {
    return DBD::Pg::PG_INTERVAL;
}

=head2 B<wrap()>

Wraps an expression with CAST statement.

=head3 Arguments

=over 4

=item C<expression>

=back

=head3 Returns

CAST (C<expression> AS interval)

=cut

sub wrap {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $expression);

    return 'CAST ('.$expression.' AS interval)';
}

=head2 B<serialize()>

Formats a B<DateTime::Duration> object into the appropriate string interval
representation with the B<DateTime::Format::Pg> module.

=head3 Arguments

=over 4

=item C<value>

=back

=head3 Returns

The string like '1 day 1 hour 1 minute 1 second'.

=cut

sub serialize {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $value);

    return DateTime::Format::Pg->format_interval($value);
}

=head2 B<deserialize()>

Parses an interval string representation into the appropriate
B<DateTime::Duration> object with the B<DateTime::Format::Pg> module.

=head3 Arguments

=over 4

=item C<value>

=back

=head3 Returns

A B<DateTime::Duration> object.

=cut

sub deserialize {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $value);

    my $result;
    if (defined $value) {
        $result = DateTime::Format::Pg->parse_interval($value);
    }

    return $result;
}

=head1 SEE ALSO

=over 4

=item L<DateTime>

=item L<DateTime::Duration>

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
