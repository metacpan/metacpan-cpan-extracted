package Eve::Registry;

use parent qw(Eve::Class);

use strict;
use warnings;

use File::Basename ();

use Eve::Email;
use Eve::EventMap;
use Eve::HttpOutput;
use Eve::HttpRequest::Psgi;
use Eve::HttpDispatcher;
use Eve::HttpResource::Template;
use Eve::HttpResponse::Psgi;
use Eve::Json;
use Eve::PgSql;
use Eve::Session;
use Eve::Template;
use Eve::Uri;

=head1 NAME

B<Eve::Registry> - a service provider class.

=head1 SYNOPSIS

    my $registry = Eve::Registry->new(
        # some literals declarations);

    my $service = $registry->get_service();

=head1 DESCRIPTION

B<Eve::Registry> is the class that provides all services that are
required by the application and manages their dependencies.

=head3 Constructor arguments

=over 4

=item C<working_dir_string>

=item C<base_uri_string>

=item C<alias_base_uri_string_list>

an optional base URI alias string list

=item C<email_from_string>

=item C<pgsql_database>

=item C<pgsql_host>

=item C<pgsql_port>

=item C<pgsql_user>

=item C<pgsql_password>

=item C<pgsql_schema>

=item C<session_expiration_interval>

an interval of idling from the last access when the session is
considered actual (0 cancels expiration), 30 days is set by default,

=item C<template_path>

=item C<template_compile_path>

=item C<template_expiration_interval>

=item C<template_var_hash>

a hash of variables that will be made available for the templates.

=back

the C<pgsql_*> literals except C<pgsql_schema> are C<undef> by default
so an attempt will be made to use standard PostgreSQL environment
variables. For the C<pgsql_schema> the default 'public' value will be
used.

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(
        \%arg_hash,

        my $working_dir_string = File::Spec->catdir(
            File::Basename::dirname(__FILE__), '..', '..'),

        my $base_uri_string,
        my $alias_base_uri_string_list = [],

        my $email_from_string,

        my $pgsql_database = \undef,
        my $pgsql_host = \undef,
        my $pgsql_port = \undef,
        my $pgsql_user = \undef,
        my $pgsql_password = \undef,
        my $pgsql_schema = \undef,

        my $session_storage_path = File::Spec->catdir(
            File::Spec->curdir(), 'tmp', 'session'),
        my $session_expiration_interval = 30 * 24 * 60 * 60,
        my $session_cookie_domain = \undef,

        my $template_path = File::Spec->catdir(
            File::Spec->curdir(), 'template'),
        my $template_compile_path = File::Spec->catdir(
            File::Spec->curdir(), 'tmp', 'template'),
        my $template_expiration_interval = 60,
        my $template_var_hash = {});

    $self->{'working_dir_string'} = $working_dir_string;

    $self->{'base_uri_string'} = $base_uri_string;
    $self->{'alias_base_uri_string_list'} = $alias_base_uri_string_list;

    $self->{'email_from_string'} = $email_from_string;

    $self->{'pgsql_database'} = $pgsql_database;
    $self->{'pgsql_host'} = $pgsql_host;
    $self->{'pgsql_port'} = $pgsql_port;
    $self->{'pgsql_user'} = $pgsql_user;
    $self->{'pgsql_password'} = $pgsql_password;
    $self->{'pgsql_schema'} = $pgsql_schema;

    $self->{'session_storage_path'} = $session_storage_path;
    $self->{'session_expiration_interval'} = $session_expiration_interval;
    $self->{'session_cookie_domain'} = $session_cookie_domain;

    $self->{'template_path'} = $template_path;
    $self->{'template_compile_path'} = $template_compile_path;
    $self->{'template_expiration_interval'} = $template_expiration_interval;
    $self->{'template_var_hash'} = $template_var_hash;

    $self->{'_lazy_hash'} = {};
}

=head1 SERVICES

The registry's purpose is to provide different services, which can be
simple literals as well as lists, hashes and objects. For objects
there are two types of services: B<lazy loader> and B<prototype>:

=head3 Lazy loader

A lazy loader service is a service that creates the object it
provides upon first request. All subsequent requests of this service
will return the same object that was created the first time.

    use Eve::Registry;

    sub first_sub {
        my $registry = Eve::Registry->new();
        my $lazy_service = $registry->get_lazy_service();

        $lazy_service->set_state(true);
    }

    sub second_sub {
        my $registry = Eve::Registry->new();
        my $lazy_service = $registry->get_lazy_service();

        # Returns state set in previous sub
        print $lazy_service->get_state();
    }

=head3 Prototype

A prototype service is a service that creates the provided object
each time it is requested.

    use Eve::Registry;

    sub third_sub {
        my $registry = Eve::Registry->new();
        my $first_service = $registry->get_proto_service();
        my $second_service = $registry->get_proto_service();

        if ($first_service eq $second_service) {
            die("This will never get executed");
        }
    }

=head2 B<lazy_load()>

Creates a service object if it hasn't been created and returns
it. Otherwise returns a stored copy of a previously service object.

=head3 Arguments

=over 4

=item C<name>

A unique name for a service,

=item C<code>

A code reference that must create and return the service object.

=back

=cut

sub lazy_load {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my ($name, $code));

    if (not defined $self->_lazy_hash->{$name}) {
        $self->_lazy_hash->{$name} = $code->();
    }

    return $self->_lazy_hash->{$name};
}

=head2 B<get_uri()>

A URI prototype service.

=head3 Arguments

=over 4

=item C<string>

a URI string that will be used to create a new URI object.

=back

=cut

sub get_uri {
    my $self = shift;

    return Eve::Uri->new(@_);
}

=head2 B<get_base_uri()>

A base URI prototype service.

=cut

sub get_base_uri {
    my $self = shift;

    return $self->get_uri(string => $self->base_uri_string);
}

=head2 B<get_alias_base_uri_list()>

A list of alias base URIs prototype service.

=cut

sub get_alias_base_uri_list {
    my $self = shift;

    return [
        map { $self->get_uri(string => $_) }
        @{$self->alias_base_uri_string_list}];
}

=head2 B<get_http_request()>

An HTTP request lazy loader service.

=cut

sub get_http_request {
    my $self = shift;

    return Eve::HttpRequest::Psgi->new(
        uri_constructor => sub { return $self->get_uri(@_); },
        @_);
}

=head2 B<get_http_response()>

An HTTP response lazy loader service.

=cut

sub get_http_response {
    my $self = shift;

    return Eve::HttpResponse::Psgi->new();
}

=head2 B<get_event_map()>

An event map lazy loader service.

=cut

sub get_event_map {
    my $self = shift;

    return $self->lazy_load(
        name => 'event_map',
        code => sub {
            return Eve::EventMap->new();
        });
}

=head2 B<get_email()>

A mailer lazy loader service.

=cut

sub get_email {
    my $self = shift;

    return $self->lazy_load(
        name => 'email',
        code => sub {
            return Eve::Email->new(from => $self->email_from_string);
        });
}

=head2 B<get_http_dispatcher()>

An HTTP resource dispatcher lazy loader service.

=cut

sub get_http_dispatcher {
    my $self = shift;

    return $self->lazy_load(
        name => 'http_dispatcher',
        code => sub {
            return Eve::HttpDispatcher->new(
                request_constructor => sub {
                    return $self->get_http_request(@_);
                },
                response => $self->get_http_response(),
                event_map => $self->get_event_map(),
                base_uri => $self->get_base_uri(),
                alias_base_uri_list => $self->get_alias_base_uri_list());
        });
}

=head2 B<get_http_output()>

An HTTP output lazy service.

=cut

sub get_http_output {
    my $self = shift;

    return $self->lazy_load(
        name => 'http_output',
        code => sub {
            return Eve::HttpOutput->new(filehandle => *STDOUT);
        });
}

=head2 B<get_template()>

A Template lazy loader service.

=cut

sub get_template {
    my $self = shift;

    return $self->lazy_load(
        name => 'template',
        code => sub {
            return Eve::Template->new(
                path => $self->template_path,
                compile_path => $self->template_compile_path,
                expiration_interval => $self->template_expiration_interval,
                var_hash => $self->get_template_var_hash());
        });
}

=head2 B<get_template_var_hash()>

A lazy template hash getter service.

=cut

sub get_template_var_hash {
    my $self = shift;

    return {%{$self->template_var_hash or {}}, @_};
}

=head2 B<get_session()>

A persistent session prototype service.

=head3 Arguments

=over 4

=item C<id>

a session identifier md5 string

=back

=cut

sub get_session {
    my $self = shift;

    return Eve::Session->new(
        storage_path => $self->session_storage_path,
        expiration_interval => $self->session_expiration_interval,
        @_);
}

=head2 B<get_pgsql()>

A PostgreSQL registry lazy loader service.

=cut

sub get_pgsql {
    my $self = shift;

    return $self->lazy_load(
        name => 'pgsql',
        code => sub {
            return Eve::PgSql->new(
                database => $self->pgsql_database,
                host => $self->pgsql_host,
                port => $self->pgsql_port,
                user => $self->pgsql_user,
                password => $self->pgsql_password,
                schema => $self->pgsql_schema);
        });
}

=head2 B<get_json()>

A JSON converter adapter class lazy loader service.

=cut

sub get_json {
    my $self = shift;

    return $self->lazy_load(
        name => 'json',
        code => sub {
            return Eve::Json->new();
        });
}

=head2 B<add_binding>

A shorthand method for binding resources to specific URI
patterns. Accepts arguments as a simple list, which are resource
binding name, pattern and constructor code reference. The fourth
argument is a hash reference that is added to the C<bind> method call.

=cut

sub add_binding {
    my ($self, $name, $pattern, $resource_constructor) = @_;

    my $http_dispatcher = $self->get_http_dispatcher();

    return $http_dispatcher->bind(
        name => $name,
        pattern => $pattern,
        resource_constructor => $resource_constructor);
}

=head2 B<bind_http_event_handlers()>

Binds HTTP event handlers for standard request/response functionality.

=cut

sub bind_http_event_handlers {
    my $self = shift;

    my $event_map = $self->get_event_map();

    $event_map->bind(
        event_class => 'Eve::Event::PsgiRequestReceived',
        handler => $self->get_http_dispatcher());
}

sub _get_http_resource_parameter_list {
    my $self = shift;

    return {
        'response' => $self->get_http_response(),
        'session_constructor' => sub { return $self->get_session(@_); },
        'dispatcher' => $self->get_http_dispatcher(),
        (defined $self->session_cookie_domain ?
            ('session_cookie_domain' => $self->session_cookie_domain) : ())};
}

sub _get_template_http_resource_parameter_list {
    my $self = shift;

    return {
        %{$self->_get_http_resource_parameter_list()},
        template => $self->get_template(),
        template_var_hash => $self->get_template_var_hash(),
        text_var_hash => $self->template_text_hash};
}

sub _get_graph_http_resource_parameter_list {
    my $self = shift;

    return {
        %{$self->_get_http_resource_parameter_list()},
        'json' => $self->get_json()};
}

=head1 SEE ALSO

=over 4

=item L<Eve::Email>

=item L<Eve::EventHandler::ExternalSignup>

=item L<Eve::EventMap>

=item L<Eve::HttpOutput>

=item L<Eve::HttpRequest>

=item L<Eve::HttpDispatcher>

=item L<Eve::HttpResource>

=item L<Eve::HttpResource::Template>

=item L<Eve::HttpResponse>

=item L<Eve::Json>

=item L<Eve::Model::Authentication>

=item L<Eve::PgSql>

=item L<Eve::Session>

=item L<Eve::Template>

=item L<Eve::Uri>

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
