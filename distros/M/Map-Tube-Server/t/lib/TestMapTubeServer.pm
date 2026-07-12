package TestMapTubeServer;

# Helper utilities for unit-testing the Map::Tube::Server routes.
#
# The route handlers call the Dancer2::Plugin::Map::Tube `api` keyword, which
# in turn talks to a memcached server.  We don't want to require a running
# memcached for `make test`, so this helper installs a mock `api` keyword in
# the Map::Tube::Server package namespace and provides a fake API object
# whose methods return caller-controlled responses.
#
# Usage from a test:
#
#     use lib 't/lib';
#     use TestMapTubeServer;
#     TestMapTubeServer::install_mock_api( response => { content => '[]' } );
#     TestMapTubeServer::set_api_response( { content => '["London"]' } );
#     my $call = TestMapTubeServer::last_received_call();

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
    install_mock_api
    set_api_response
    last_received_call
);

# Map::Tube::Server must already be loaded by the consuming test (so that
# its routes have been declared) before install_mock_api is called.
require Map::Tube::Server;

{
    package TestMapTubeServer::MockAPI;
    no warnings 'redefine';

    sub new {
        my ($class, $map_name) = @_;
        bless {
            map_name      => $map_name,
            last_method   => undef,
            last_arguments => [],
        }, $class;
    }
}

# Shared mutable state for the mock.
our $RESPONSE;
our $CALL_LOG = [];

# Per-method sub that records the call and returns the canned response.
sub _make_handler {
    my $method = shift;

    no warnings 'redefine';
    no strict 'refs';

    return sub {
        my $self = shift;
        $self->{last_method}    = $method;
        $self->{last_arguments} = [@_];
        push @$CALL_LOG, { method => $method, args => [@_] };
        return $RESPONSE;
    };
}

sub install_mock_api {
    my %opts = @_;

    no warnings 'redefine';
    no strict 'refs';

    # Default the response to a benign empty list.
    $RESPONSE = $opts{response} || { content => '[]' };
    $CALL_LOG = [];

    # Install call-recording handlers for every API method used by the
    # route handlers in Map::Tube::Server.
    *TestMapTubeServer::MockAPI::map_stations   = _make_handler('map_stations');
    *TestMapTubeServer::MockAPI::line_stations  = _make_handler('line_stations');
    *TestMapTubeServer::MockAPI::shortest_route = _make_handler('shortest_route');
    *TestMapTubeServer::MockAPI::available_maps = _make_handler('available_maps');

    # Replace the `api` keyword in the Map::Tube::Server package so that the
    # route handlers pick up our mock.  The original is a wrapper around the
    # DSL keyword with prototype `@`; the new one returns a fresh MockAPI
    # each call, matching the real signature.
    *Map::Tube::Server::api = sub (@) {
        my ($map_name) = @_;
        return TestMapTubeServer::MockAPI->new($map_name);
    };

    return;
}

sub set_api_response {
    $RESPONSE = shift;
    return;
}

sub last_received_call {
    return $CALL_LOG && @$CALL_LOG ? $CALL_LOG->[-1] : undef;
}

1;
__END__

=head1 NAME

TestMapTubeServer - test helper for the Map::Tube::Server route handlers

=head1 SYNOPSIS

    use lib 't/lib';
    use TestMapTubeServer;

    TestMapTubeServer::install_mock_api( response => { content => '[]' } );

    # ... drive the app with Plack::Test ...

    TestMapTubeServer::set_api_response(
        { error_code => 400, error_message => 'oops' }
    );

    my $call = TestMapTubeServer::last_received_call();
    is( $call->{method}, 'shortest_route', 'right method was called' );

=head1 DESCRIPTION

Map::Tube::Server's route handlers depend on the C<api> keyword exported by
L<Dancer2::Plugin::Map::Tube>, which in turn depends on a running memcached.
This helper monkey-patches the C<api> function in the Map::Tube::Server
package so the route handlers receive a stub object whose methods return
whatever the test wants.

The stub records every call so tests can assert which method was invoked
and with which arguments.

=cut
