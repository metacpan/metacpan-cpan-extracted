package Eve::PgSqlType::Text;

use parent qw(Eve::PgSqlType::DriverNative);

use strict;
use warnings;

use DBD::Pg ();

=head1 NAME

B<Eve::PgSqlType::Text> - a PostgreSQL text type.

=head1 SYNOPSIS

    my $text = Eve::PgSqlType::Text->new();
    $text->serialize(value => 'some text goes here');

=head1 DESCRIPTION

B<Eve::PgSqlType::Text> is a PostgreSQL text type adapter class.

=head1 METHODS

=head2 B<get_type()>

=head3 Returns

The PG_TEXT type.

=cut

sub get_type {
    return DBD::Pg::PG_TEXT;
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

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=back

=cut

1;
