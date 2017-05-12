package Eve::PgSqlType::Array;

use parent qw(Eve::PgSqlType);

use strict;
use warnings;

use DateTime::Format::Pg;
use DBD::Pg ();

=head1 NAME

B<Eve::PgSqlType::Array> - a PostgreSQL array type.

=head1 SYNOPSIS

    my $array = Eve::PgSqlType::Array->new();
    my $text = $array->serialize(value => $some_array);
    my $array_ref = $bigint->deserialize(value => $some_result);

=head1 DESCRIPTION

B<Eve::PgSqlType::Array> is a PostgreSQL array type adapter class.

=head1 METHODS

=head2 B<get_type()>

=head3 Returns

The PG_ANYARRAY type.

=cut

sub get_type {
    return DBD::Pg::PG_ANYARRAY;
}

=head2 B<wrap()>

Wraps an expression with CAST statement.

=head3 Arguments

=over 4

=item C<expression>

=back

=head3 Returns

CAST (C<expression> AS array)

=cut

sub wrap {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $expression);

    return 'CAST ('.$expression.' AS anyarray)';
}

=head2 B<serialize()>

Formats an array object into the appropriate string array
representation.

=head3 Arguments

=over 4

=item C<value>

=back

=head3 Returns

The string like '{all, array, values}'.

=cut

sub serialize {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $value);

    return '{' . join(',', @{$value}) . '}';
}

=head2 B<deserialize()>

Just a passthrough method to return whatever value has been passed to it.

=head3 Arguments

=over 4

=item C<value>

=back

=head3 Returns

The value that is passed to the method.

=cut

sub deserialize {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $value);

    return $value;
}

=head1 SEE ALSO

=over 4

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
