package Eve::PgSqlType;

use parent qw(Eve::Class);

use strict;
use warnings;

use DBD::Pg ();

=head1 NAME

B<Eve::PgSqlType> - a base class for PostgreSQL types.

=head1 SYNOPSIS

    package Eve::PgSqlType::Bigint;

    use parent qw(Eve::PgSqlType);

    # Some implementation here

    1;

=head1 DESCRIPTION

B<Eve::PgSqlType> is an base class for all PostgreSQL type classes.

=head1 METHODS

=head2 B<get_type()>

It must be overridden.

=head3 Returns

A PostgreSQL data type value. See B<DBD::Pg> for more information.

=cut

sub get_type {
    Eve::Error::NotImplemented->throw();
}

=head2 B<wrap()>

If you need to implement some specific type you might be required to
add implicitly casting statement or do another wrapping operation with
the expression.

It must be overridden.

=head3 Arguments

=over 4

=item C<expression>

a text expression to be wrapper.

=back

=head3 Returns

A wrapped expression text.

=cut

sub wrap {
    #my ($self, %arg_hash) = @_;
    #Eve::Support::arguments(\%arg_hash, my $expression);

    Eve::Error::NotImplemented->throw();
}

=head2 B<serialize()>

Serializes a value into the database representation.

It must be overriden.

=head3 Arguments

=over 4

=item C<value>

a value to serialize.

=back

=head3 Returns

A serizlized value.

=cut

sub serialize {
    #my ($self, %arg_hash) = @_;
    #Eve::Support::arguments(\%arg_hash, my $value);

    Eve::Error::NotImplemented->throw();
}

=head2 B<deserialize()>

Deserializes a value from the database representation.

It must be overriden.

=head3 Arguments

=over 4

=item C<value>

a value to deserialize.

=back

=head3 Returns

A deserizlized value.

=cut

sub deserialize {
    #my ($self, %arg_hash) = @_;
    #Eve::Support::arguments(\%arg_hash, my $value);

    Eve::Error::NotImplemented->throw();
}

=head1 SEE ALSO

=over 4

=item L<DBI>

=item L<DBD::Pg>

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
