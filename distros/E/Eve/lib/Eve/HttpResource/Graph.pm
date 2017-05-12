package Eve::HttpResource::Graph;

use parent qw(Eve::HttpResource);

use strict;
use warnings;

use Eve::Exception;

=head1 NAME

B<Eve::HttpResource::Graph> - a base class for the Graph API
node HTTP resources.

=head1 SYNOPSIS

    package Eve::HttpResource::SomeGraphResource;

    use parent qw(Eve::HttpResource::Graph);

    sub _read {
        # some object's hash is returned here
    }

    sub _get_connections {
        # some connections hash is returned here
    }

    sub _get_fields {
        # some object fields hash is returned here
    }

    sub _get_type {
        # a required type string is returned here
    }

    1;

=head1 DESCRIPTION

B<Eve::HttpResource::Graph> is an HTTP resource based class
providing an automation of the Facebook like Graph API node/connection
functionality.

Methods C<_read()>, C<_publish()>, C<_remove()>,
C<_get_connections()>, C<_get_fields()>, C<_get_type()>,
C<_get_actions()> and C<_get_id_alias_hash()> could be overriden by
the class derivatives. When not overriden these methods except
C<_get_connections()> and C<_get_fields> throw the exception
C<Eve::Exception::Http::405MethodNotAllowed>. C<_get_type> throws a
C<Eve::Error::NotImplemented> exception which means it must be
overridden to be used. Inside the described above methods class
attributes C<_request>, C<_response>, C<_session>, C<_event_map> and
C<_dispatcher> can be found.

All methods are passed the list of named matched URI parameters as
arguments. The following example illustrates the usage of named
arguments in a resource that is bound to the
C<http://example.com/:named/:another> pattern URI:

    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my ($named, $another));

If the C<metadata> query string parameter is specified then the
C<metadata> section is added to the result. This section always
contains the object's type returned by the C<_get_type> method, and if
present, the object's connections returned by the
C<_get_connections()> method, the object's fields returned by the
C<_get_fields> method and the object's actions returned by the
C<_get_actions()> method.

If the request method is C<POST> and the query string is supplied with
C<method=delete> then it behaves just like the C<DELETE> method is
requested. If other value is passed to the C<method> then the
exception C<Eve::Exception::Http::400BadRequest> is thrown.

If C<Eve::Exception::Privilege> is thrown in the user code the
exception C<Eve::Exception::Http::403Forbidden> is rethrown.

Note that the resource must be bound with the C<id> placeholder. The
C<_id> attribute is representing it. If C<_get_id_alias_hash()> is
redefined you can use ID aliases in URI according to the hash keys.

Object deletion requests must use the deleted object's node URI.  In
case a connection with no public ID is deleted, the request must use
the respective object connection URI.

=head3 Constructor arguments

=over 4

=item C<request>

an HTTP request object

=item C<response>

an HTTP response object

=item C<session_constructor>

a reference to a subroutine accepting the session C<id> argument and
returning a session object

=item C<dispatcher>

an HTTP dispatcher object

=item C<json>

a JSON encoder object.

=back

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    my $arg_hash = Eve::Support::arguments(\%arg_hash, my $json);

    $self->{'_json'} = $json;

    $self->{'_id'} = undef;

    $self->SUPER::init(%{$arg_hash});

    return;
}

=head2 B<_read()>

This method is called when the graph node or connection is requested
with the GET method.

=head3 Returns

It is expected to return a data hash reference
that will be automatically converted to a required textual
representation and returned to the client

=head3 Throws

=over 4

=item C<Eve::Exception::Http::405MethodNotAllowed>

When a method is used without being overridden in a descendant class.

=back

=cut

sub _read {
    Eve::Exception::Http::405MethodNotAllowed->throw(
        message => 'Method is not implemented.');

    return;
}

=head2 B<_publish()>

This method is called when the graph node or connection is requested
with the POST method.

=head3 Returns

It is expected to return a data hash reference
that will be automatically converted to a required textual
representation and returned to the client

=head3 Throws

=over 4

=item C<Eve::Exception::Http::405MethodNotAllowed>

When a method is used without being overridden in a descendant class.

=back

=cut

sub _publish {
    Eve::Exception::Http::405MethodNotAllowed->throw(
        message => 'Method is not implemented.');

    return;
}

=head2 B<_remove()>

This method is called when the graph node or connection is requested
with the DELETE method or when the POST method is used in conjunction
with a C<method=delete> query string parameter..

=head3 Returns

It is expected to return a data hash reference
that will be automatically converted to a required textual
representation and returned to the client

=head3 Throws

=over 4

=item C<Eve::Exception::Http::405MethodNotAllowed>

When a method is used without being overridden in a descendant class.

=back

=cut

sub _remove {
    Eve::Exception::Http::405MethodNotAllowed->throw(
        message => 'Method is not implemented.');

    return;
}

=head2 B<_get_connections()>

This method is called when the C<metadata> parameter is recieved in
the request. Overriding this method is optional.

=head3 Returns

It is expected to return a connection hash reference
that will be automatically converted to a required textual
representation and returned to the client.

=cut

sub _get_connections {
    return (undef);
}

=head2 B<_get_fields()>

This method is called when the C<metadata> parameter is recieved in
the request. Overriding this method is optional.

=head3 Returns

It is expected to return a fields hash reference that will be
automatically converted to a required textual representation and
returned to the client.

=cut

sub _get_fields {
    return (undef);
}

=head2 B<_get_actions()>

This method is called when the C<metadata> parameter is recieved in
the request. Overriding this method is optional.

=head3 Returns

It is expected to return an actions hash reference with action keys as
keys and action names as values that will be automatically converted
to a required textual representation and returned to the client.

=cut

sub _get_actions {
    return (undef);
}

=head2 B<_get_type()>

This method is called when the C<metadata> parameter is recieved in
the request.

=head3 Returns

It is expected to return a type string that will be automatically
converted to a required textual representation and returned to the
client.

=head3 Throws

=over 4

=item C<Eve::Error::NotImplemented>

When a method is used without being overridden in a descendant class.

=back

=cut

sub _get_type {
    Eve::Error::NotImplemented->throw(
        message => 'The _get_type method must be implemented.');

    return;
}

=head2 B<_get_alias_hash()>

This method is called when the graph HTTP resource processes the
pattern placeholder matches from a request URI. A hash of aliases for
an id can be specified in this method. For example, if an id in the
URI is specified as an C<alias> keyword, it can be replaced with a
real identifier by returning this hash reference:

    return {'alias' => $some_service->get_parameter(name => 'id')};

=head3 Returns

It is expected to return a reference to a hash of aliases for an
identifier.

=head3 Throws

=over 4

=item C<Eve::Error::NotImplemented>

When a method is used without being overridden in a descendant class.

=back

=cut

sub _get_id_alias_hash {
    return {};
}

sub _get {
    my ($self, %matches_hash) = @_;

    eval {
        $self->_build_response(
            result_callback => sub { $self->_read(%matches_hash); },
            matches_hash => \%matches_hash);
    };
    $self->_process_exceptions();

    return;
}

sub _post {
    my ($self, %matches_hash) = @_;

    my $method = $self->_request->get_uri()->
        get_query_parameter(name => 'method');

    eval {
        if (defined $method) {
            if ($method eq 'delete') {
                $self->_delete(%matches_hash);
            } else {
                Eve::Exception::Http::400BadRequest->throw(
                    message => 'Unsupported pseudo method "'.$method.
                               '" for POST.');
            }
        } else {
            $self->_build_response(
                result_callback => sub { $self->_publish(%matches_hash); },
                matches_hash => \%matches_hash);
        }
    };

    $self->_process_exceptions();

    return;
}

sub _delete {
    my ($self, %matches_hash) = @_;

    eval {
        $self->_build_response(
            result_callback => sub { $self->_remove(%matches_hash); },
            matches_hash => \%matches_hash);
    };

    $self->_process_exceptions();

    return;
}

sub _get_metadata {
    my ($self, %matches_hash) = @_;

    my $connections = $self->_get_connections(%matches_hash);

    my $metadata = {
        defined $connections ? ('connections' => $connections) : ()};

    return $metadata;
}

sub _build_response {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(
        \%arg_hash, my ($result_callback, $matches_hash));

    if (not exists $matches_hash->{'id'}) {
        Eve::Error::Value->throw(
            message => 'No identifier has been matched in the URI.');
    } else {
        if (exists $self->_get_id_alias_hash()->{$matches_hash->{'id'}}) {
            $self->_id = $self->_get_id_alias_hash()->{$matches_hash->{'id'}};
        } else {
            $self->_id = $matches_hash->{'id'};

            if ($self->_id =~ /\D/) {
                Eve::Exception::Http::400BadRequest->throw(
                    message => 'The identifier must be a number or an allowed '.
                               'alias, got "'.$self->_id.'".');
            }
        }
    };
    my $result = $result_callback->();

    my $metadata;
    if ($self->_request->get_uri()->get_query_parameter(name => 'metadata')) {
        $metadata = $self->_get_metadata(%{$matches_hash});
    }

    $self->_set_response(
        code => 200,
        reference => Eve::Support::indexed_hash(
            %{$result},
            defined $metadata ? ('metadata' => $metadata) : ()));

    return;
}

sub _process_exceptions {
    my $self = shift;

    my ($e, $code, $type);
    if ($e = Eve::Exception::Http::400BadRequest->caught()) {
        ($code, $type) = (400, 'Request');
    } elsif ($e = Eve::Exception::Http::401Unauthorized->caught()) {
        ($code, $type) = (401, 'Authorization');
    } elsif ($e = Eve::Exception::Http::405MethodNotAllowed->caught()) {
        ($code, $type) = (405, 'Request');
    } elsif ($e = Eve::Exception::Data->caught()) {
        ($code, $type) = (400, 'Data');
    } elsif ($e = Eve::Exception::Privilege->caught()) {
        #print STDERR "HttpResource::Graph::process_exceptions: caught privilege exception!\n";
        ($code, $type) = (403, 'Privilege');
    } elsif ($e = Exception::Class::Base->caught()) {
        $e->rethrow();
    }

    if (defined $e) {
        $self->_set_response(
            code => $code,
            reference => {
                'error' => Eve::Support::indexed_hash(
                    'type' => $type,
                    'message' => $e->message)});
    }

    return;
}

sub _set_response {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my ($code, $reference));

    $self->_response->set_status(code => $code);
    $self->_response->set_header(
        name => 'Content-Type', value => 'text/javascript');
    $self->_response->set_body(
        text => $self->_json->encode(reference => $reference));

    return;
}

=head1 SEE ALSO

=over 4

=item L<Eve::HttpResource>

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

=back

=cut

1;
