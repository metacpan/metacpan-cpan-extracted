package Eve::Session;

use parent qw(Eve::Class);

use strict;
use warnings;

use CGI::Session;

=head1 NAME

B<Eve::Session> - a persistent session class.

=head1 SYNOPSIS

    # Construct the session object
    my $session = Eve::Session->new(
        id => $md5_id,
        storage_path => '/storage/path',
        expiration_interval => 3600);

    # Get the session identifier
    my $id = $session->get_id();

    # Set ang get the parameter
    $session->set_parameter(name => 'foo', value => 'bar');
    my $foo = $session->get_parameter(name => 'foo');

    # Set the parameter expired after 600 seconds of idling
    $session->set_parameter(
        name => 'foo', value => 'bar', expiration_interval => 600);

    # Clear the parameter
    $session->clear_parameter(name => 'foo');

=head1 DESCRIPTION

B<Eve::Session> is a persistent session class allowing to share an
identified state between application calls. The class adapts the
package B<CGI::Session>.

=head3 Constructor arguments

=over 4

=item C<id>

a session ID string (it can differ from the actual ID, see the
C<get_id()> method documentation)

=item C<storage_path>

a path on the server where session files are stored

=item C<expiration_interval>

an interval of idling from the last access when the session is
considered actual (0 cancels expiration).

=back

=head3 Attributes

=over 4

=item C<expiration_interval>

(read only) an expiration interval in seconds that has been initially
set for the session.

=back

=head3 Throws

=over 4

=item C<Eve::Error::Session>

when the session creation is unsuccessful.

=back

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(
        \%arg_hash,
        my ($id, $storage_path, $expiration_interval));

    $self->{'session'} = CGI::Session->new(
        undef, $id, { Directory => $storage_path });

    if (not defined $self->session) {
        Eve::Error::Session->throw(message => CGI::Session->errstr());
    }

    $self->session->expire($expiration_interval);

    $self->{'expiration_interval'} = $self->session->expire();

    $self->_flush();

    return;
}

=head2 B<get_id()>

=head3 Returns

An md5 string identified the session. The string can be different from
one that is specified in the constructor in case of not existing or
expired session.

=cut

sub get_id {
    my $self = shift;

    return $self->session->id();
}

=head2 B<set_parameter()>

Sets a named parameter in the session.

=head3 Arguments

=over 4

=item C<name>

=item C<value>

=item C<expiration_interval>

an interval of idling from the last access when the parameter is
considered actual (0 cancels expiration).

=back

=head3 Returns

The value passed to the method.

=cut

sub set_parameter {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(
        \%arg_hash, my ($name, $value), my $expiration_interval = \undef);

    my $result = $self->session->param(-name => $name, -value => $value);

    if (defined $expiration_interval) {
        $self->session->expire($name, $expiration_interval);
    }

    $self->_flush();

    return $result;
}

=head2 B<get_parameter()>

=head3 Arguments

=over 4

=item C<name>

=back

=head3 Returns

A parameter value.

=cut

sub get_parameter {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $name);

    return $self->session->param($name);
}

=head2 B<clear_parameter()>

Clears the parameter from the session.

=head3 Arguments

=over 4

=item C<name>

=back

=head3 Returns

An old parameter value.

=cut

sub clear_parameter {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $name);

    my $result = $self->session->param($name);
    $self->session->clear($name);

    $self->_flush();

    return $result;
}

sub _flush {
    my $self = shift;

    if (not $self->session->flush()) {
        Eve::Error::Session->throw(message => CGI::Session->errstr());
    }
}

=head1 SEE ALSO

=over 4

=item L<CGI::Session>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHOR

L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=cut

1;
