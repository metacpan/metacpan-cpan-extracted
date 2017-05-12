package FeyX::Active::SQL;
use Moose::Role;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

has 'dbh' => (
    is        => 'ro',
    isa       => 'DBI::db',
    required  => 1,
);

has 'execute_rv' => (is => 'rw', isa => 'Any');

sub prepare_sql { (shift)->sql }

sub prepare {
    my $self = shift;
    $self->dbh->prepare( $self->prepare_sql );
}

sub execute {
    my $self = shift;
    my $sth  = $self->prepare;
    # NOTE:
    # this is because of some silly Moose bug
    # and the fact that dave uses those silly
    # semiaffordance accessors.
    # * sigh *
    # - SL
    if ($self->can('set_execute_rv')) {
        $self->set_execute_rv( $sth->execute( $self->bind_params ) );
    }
    else {
        $self->execute_rv( $sth->execute( $self->bind_params ) );
    }
    $sth;
}

around sql => sub {
    my $next = shift;
    my $self = shift;
    $self->$next( $self->dbh );
};

no Moose::Role; 1;

__END__

=pod

=head1 NAME

FeyX::Active::SQL - A role to represent an active SQL statement

=head1 DESCRIPTION

This is a role that all the FeyX::Active::SQL::* objects consume,
it contains all the basic logic to manage and execute the SQL
commands.

=head1 ATTRIBUTES

=over 4

=item B<dbh>

This is a L<DBI> database handle.

=item B<execute_rv>

This is the return value of C<execute> on
the given L<DBI> statement handle in our
C<execute> method.

=back

=head1 METHODS

=over 4

=item B<prepare_sql>

This simply calls C<sql> to get the SQL code that L<Fey::SQL>
will generate for us.

=item B<prepare>

This calls C<prepare_sql> and passes that SQL to the C<prepare>
method of our C<dbh>. It will return a L<DBI> statement handle.

=item B<execute>

This will call C<prepare> to get the L<DBI> statement handle,
then it will call C<execute> on the statement handle and pass in
the bind params that L<Fey::SQL> will generate for us.

This will save any return value of C<execute> in the C<execute_rv>
attribute and then return the L<DBI> statement handle.

=item B<sql>

This just wraps the L<Fey::SQL> C<sql> method to make sure that
we are passing in our C<dbh>.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
