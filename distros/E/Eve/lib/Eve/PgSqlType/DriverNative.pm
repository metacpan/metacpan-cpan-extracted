package Eve::PgSqlType::DriverNative;

use parent qw(Eve::PgSqlType);

use strict;
use warnings;

=head1 NAME

B<Eve::PgSqlType::DriverNative> - a PostgreSQL type native for
B<DBD::Pg> B<DBI> driver.

=head1 SYNOPSIS

    package Eve::PgSqlType::Bigint;

    use parent qw(Eve::PgSqlType::DriverNative);

    sub get_type {
        return DBD::Pg::PG_INT8;
    }

    1;

=head1 DESCRIPTION

B<Eve::PgSqlType::DriverNative> is a base class for PostgreSQL
types natively supported by B<DBD::Pg> B<DBI> driver.

=head1 METHODS

=head2 B<wrap()>

Leaves all the processing issues to the driver returning the
expression as is.

=head3 Arguments

=over 4

=item C<expression>

=back

=head3 Returns

The same expression.

=cut

sub wrap {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $expression);

    return $expression;
}

=head2 B<serialize()>

Leaves all the serialization issues to the driver returning the value
as is.

=head3 Arguments

=over 4

=item C<value>

=back

=head3 Returns

The same value.

=cut

sub serialize {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $value);

    return $value;
}

=head2 B<deserialize()>

Leaves all the deserialization issues to the driver returning the
value as is.

=head3 Arguments

=over 4

=item C<value>

=back

=head3 Returns

The same value.

=cut

sub deserialize {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $value);

    return $value;
}

=head1 SEE ALSO

=over 4

=item L<DBI>

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

=back

=cut

1;
