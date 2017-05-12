package Eve::HttpResource;

use parent qw(Eve::Class);

use strict;
use warnings;

use Eve::Exception;

=head1 NAME

B<Eve::HttpResource> - a base class for HTTP resource controllers.

=head1 SYNOPSIS

    package Eve::HttpResource::SomeResource;

    use parent qw(Eve::HttpResource);

    sub _get {
        # some implementation here
    }

=head1 DESCRIPTION

B<Eve::HttpResource> is a class encapsulating all the actual
processing of an HTTP request. C<_get()>, C<_post()> and C<_delete()>
methods can be overriden by the class derivatives. If not overriden
this methods throw C<Eve::Exception::Http::405MethodNotAllowed>.

Inside the described above methods class attributes C<_request>,
C<_response>, C<_session_constructor> and C<_dispatcher> can be found.

=head3 Constructor arguments

=over 4

=item C<response>

an HTTP response object

=item C<session_constructor>

a reference to a subroutine accepting the session C<id> argument and
returning a session object

=item C<dispatcher>

an HTTP dispatcher object.

=back

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(
        \%arg_hash,
        my ($response, $session_constructor, $dispatcher),
        my $session_cookie_domain = \undef);

    $self->{'_response'} = $response;
    $self->{'_session_constructor'} = $session_constructor;
    $self->{'_dispatcher'} = $dispatcher;
    $self->{'_session_cookie_domain'} = $session_cookie_domain;

    $self->{'_method_map'} = {
        'GET' => sub { return $self->_get(@_); },
        'POST' => sub { return $self->_post(@_); },
        'DELETE' => sub { return $self->_delete(@_); },
        'PUT' => sub { return $self->_post(@_); }};

    return;
}

=head2 B<process()>

Processes an HTTP request delegating control to the appropriate HTTP method
implementation.

=head3 Arguments

=over 4

=item C<matches_hash>

a hash containing pattern matches from the URL.

=item C<request>

an HTTP request object.

=back

=head3 Throws

=over 4

=item C<Eve::Exception::Http::405MethodNotAllowed>

when a not allowed HTTP method specified.

=back

=head3 Returns

a ready HTTP response object.

=cut

sub process {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my ($matches_hash, $request));

    $self->{'_request'} = $request;

    $self->{'_response'} = $self->{'_response'}->new();

    $self->{'_session'} = $self->_session_constructor->(
        id => $self->_request->get_cookie(name => 'session_id'));

    if (!($self->_session->get_id() ~~
          $self->_request->get_cookie(name => 'session_id'))) {
        $self->_response->set_cookie(
            name => 'session_id',
            value => $self->_session->get_id(),
            expires => time + $self->_session->expiration_interval,
            (defined $self->_session_cookie_domain ?
                ('domain' => $self->_session_cookie_domain) : ()));
    }

    eval {
        $self->{'_method_map'}->{$self->_request->get_method()}->(%{
            $matches_hash});
    };

    my $e;
    if ($e = Eve::Exception::Privilege->caught()) {
        #print STDERR "HttpResource::process: caught privilege exception!\n";
        Eve::Exception::Http::403Forbidden->throw(message => $e->message);
    } elsif ($e = Exception::Class->caught()) {
        ref $e ? $e->rethrow() : die $e;
    }

    return $self->{'_response'};
}

=head2 B<get_method_list()>

Returns a list of supported HTTP methods.

=head3 Returns

A list reference.

=cut

sub get_method_list {
    my $self = shift;

    return [keys %{$self->{'_method_map'}}];
}

sub _get {
    Eve::Exception::Http::405MethodNotAllowed->throw();
}

sub _post {
    Eve::Exception::Http::405MethodNotAllowed->throw();
}

sub _delete {
    Eve::Exception::Http::405MethodNotAllowed->throw();
}

=head1 SEE ALSO

=over 4

=item L<Eve::Class>

=item L<Eve::Exception>

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

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=back

=cut

1;
