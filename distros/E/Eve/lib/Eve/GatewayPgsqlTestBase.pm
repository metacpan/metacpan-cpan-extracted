# -*- mode: Perl; -*-
package Eve::GatewayPgSqlTestBase;

use parent qw(Eve::Test);

use strict;
use warnings;

use Eve::RegistryStub;

use Eve::Registry;

Eve::GatewayPgSqlTestBase->SKIP_CLASS(1);

=head1 NAME

B<Eve::GatewayPgSqlTestBase> - a postgres gateway test base class.

=head1 SYNOPSIS

    package SomeGatewayTest;

    use parent qw(Eve::GatewayPgSqlTestBase);

    # put your gateway tests here

=head1 DESCRIPTION

B<Eve::GatewayPgSqlTestBasey> is the class that provides setup for all
postgres gateway classes test cases.

=cut

sub setup {
    my $self = shift;

    my $registry = Eve::Registry->new();
    $self->{'pgsql'} = $registry->get_pgsql();
    $self->{'dbh'} = $self->{'pgsql'}->get_connection()->dbh;
}

=head1 SEE ALSO

=over 4

=item L<Eve::Test>

=item L<Test::Class>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Sergey Konoplev, Igor Zinovyev.

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
