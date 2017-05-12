package Eve::PgSqlType::Boolean;

use parent qw(Eve::PgSqlType::DriverNative);

use strict;
use warnings;

use DBD::Pg ();

=head1 NAME

B<Eve::PgSqlType::Boolean> - a PostgreSQL boolean type.

=head1 SYNOPSIS

    my $bigint = Eve::PgSqlType::Boolean->new();
    $bigint->serialize(value => 1);

=head1 DESCRIPTION

B<Eve::PgSqlType::Boolean> is a PostgreSQL boolean type adapter
class.

=head1 METHODS

=head2 B<get_type()>

=head3 Returns

The PG_BOOL type.

=cut

sub get_type {
    return DBD::Pg::PG_BOOL;
}

=head1 SEE ALSO

=over 4

=item L<DBD::Pg>

=item L<Eve::PgSqlType::DriverNative>

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
