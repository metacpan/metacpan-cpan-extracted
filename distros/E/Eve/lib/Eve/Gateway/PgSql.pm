package Eve::Gateway::PgSql;

use parent qw(Eve::Class);

use strict;
use warnings;

=head1 NAME

B<Eve::Gateway::PgSql> - a base class for PostgreSQL data gateways.

=head1 SYNOPSIS

    # Creating a subclass
    package Eve::Gateway::PgSql::Foo;

    use parent qw(Eve::Gateway::PgSql);

    # Adapting a stored function
    sub do_something {
        my $self = shift;

        if (not exists $self->{'_do_something'}) {
            $self->{'_do_something'} = $self->_pgsql->function(
                name => 'do_something',
                output_list => [{'result_code' => $self->_pgsql->smallint()}]);
        }
        my $row = $self->_do_something->execute();

        return $row->{'result_code'};
    }

    1;

=head1 DESCRIPTION

B<Eve::Gateway::PgSql> is a base class for PostgreSQL data
gateways. It houses some generic initialization stuff.

=head3 Constructor arguments

=over 4

=item C<pgsql>

a B<Eve::Registry::PgSql> instance.

=back

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $pgsql);

    $self->{'_pgsql'} = $pgsql;

    return;
}

=head1 SEE ALSO

=over 4

=item L<Eve::Class>

=item L<Eve::Registry::PgSql>

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
