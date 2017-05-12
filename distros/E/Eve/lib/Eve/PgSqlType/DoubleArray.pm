package Eve::PgSqlType::DoubleArray;

use parent qw(Eve::PgSqlType::Array);

use strict;
use warnings;

use DBD::Pg ();

=head1 NAME

B<Eve::PgSqlType::DoubleArray> - a PostgreSQL double precision array type.

=head1 SYNOPSIS

    my $array = Eve::PgSqlType::DoubleArray->new();
    my $text = $array->serialize(value => $some_array);
    my $array_ref = $bigint->deserialize(value => $some_result);

=head1 DESCRIPTION

B<Eve::PgSqlType::DoubleArray> is a PostgreSQL double precision
number array type adapter class.

=head1 METHODS

=head2 B<get_type()>

=head3 Returns

The PG_FLOAT8ARRAY type.

=cut

sub get_type {
    return DBD::Pg::PG_FLOAT8ARRAY;
}

=head2 B<wrap()>

Wraps an expression with CAST statement.

=head3 Arguments

=over 4

=item C<expression>

=back

=head3 Returns

CAST (C<expression> AS double precision[])

=cut

sub wrap {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $expression);

    return 'CAST ('.$expression.' AS double precision[])';
}

=head1 SEE ALSO

=over 4

=item L<DBD::Pg>

=item L<Eve::PgSqlType::Array>

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
