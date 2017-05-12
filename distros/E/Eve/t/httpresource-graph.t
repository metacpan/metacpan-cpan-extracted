# -*- mode: Perl; -*-
package HttpResourceGraphTest;

use parent qw(Eve::HttpResourceGraphTestBase);

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Eve::PsgiStub;
use Eve::RegistryStub;

use Eve::Support;
use Eve::Event::PsgiRequestReceived;
use Eve::Registry;

sub setup : Test(setup) {
    my $self = shift;

    $self->SUPER::setup();

    $self->{'registry'}->set_always('base_uri_string', 'http://domain.com');

    $self->{'session_constructor'} = sub {
        return $self->{'session'};
    };

    $self->{'resource_constructor'} = sub{
        Eve::HttpResourceGraphTest::Dummy->new(
            response => $self->{'registry'}->get_http_response(),
            session_constructor => $self->{'session_constructor'},
            json => $self->{'registry'}->get_json(),
            @_);
    };
}

sub set_dispatcher {
    my ($self, $request) = @_;

    $self->{'dispatcher'} = Eve::HttpDispatcher->new(
        request_constructor => sub {
            return $request;
        },
        response => $self->{'registry'}->get_http_response(),
        event_map => $self->{'registry'}->get_event_map(),
        base_uri => $self->{'registry'}->get_base_uri());

    $self->{'resource'} = $self->{'resource_constructor'}->(
        dispatcher => $self->{'dispatcher'});

    $self->{'dispatcher'}->bind(
        name => 'dummy',
        pattern => '/:id',
        resource_constructor => sub { return $self->{'resource'}; });

    return;
}

sub test_read_publish_remove : Test(9) {
    my $self = shift;

    my $data_hash_list = [
        {'uri_string' => 'http://domain.com/12345',
         'body' => {'id' => '12345'}},
        {'uri_string' => 'http://domain.com/me',
         'body' => {'id' => '12345'}},
        {'uri_string' => 'http://domain.com/67890?metadata=1',
         'body' => Eve::Support::indexed_hash(
             'id' => '67890',
             'metadata' => Eve::Support::indexed_hash(
                 'connections' => {
                     'dummy' => 'http://domain.com/67890'}))}];

    for my $method ('GET', 'POST', 'DELETE') {
        for my $data_hash (@{$data_hash_list}) {
            my $uri = Eve::Uri->new(
                    string => $data_hash->{'uri_string'});

            $self->set_dispatcher(
                Eve::PsgiStub->get_request(
                    'method' => $method,
                    'uri' => $uri->path,
                    'host' => 'domain.com',
                    'query' => $uri->query,
                    'cookie' => 'session_id=' . $self->{'session'}->get_id()));

            my $event = Eve::Event::PsgiRequestReceived->new(
                event_map => $self->{'registry'}->get_event_map(),
                env_hash => {});

            $self->{'dispatcher'}->handle(event => $event);

            $self->assert_response(
                $event->response,
                200,
                Eve::Support::indexed_hash(
                    'method' => $method, %{$data_hash->{'body'}}));
        }
    }
}

sub test_delete_via_post : Test(2) {
    my $self = shift;

    $self->set_dispatcher(
        Eve::PsgiStub->get_request(
            'method' => 'POST',
            'uri' => '/12345',
            'host' => 'domain.com',
            'query' => 'method=delete',
            'cookie' => 'session_id=' . $self->{'session'}->get_id()));

    my $event = Eve::Event::PsgiRequestReceived->new(
        event_map => $self->{'registry'}->get_event_map(),
        env_hash => {});

    $self->{'dispatcher'}->handle(event => $event);

    $self->assert_response(
        $event->response,
        200,
        Eve::Support::indexed_hash('method' => 'DELETE', 'id' => '12345'));

    $self->set_dispatcher(
        Eve::PsgiStub->get_request(
            'method' => 'POST',
            'uri' => '/12345',
            'host' => 'domain.com',
            'query' => 'method=something',
            'cookie' => 'session_id=' . $self->{'session'}->get_id()));

    $self->{'dispatcher'}->handle(event => $event);

    $self->assert_response(
        $event->response,
        400,
        {
            'error' => Eve::Support::indexed_hash(
                'type' => 'Request',
                'message' => 'Unsupported pseudo method "something"'
                           . ' for POST.')});
}

sub test_403_on_privilege_exception : Test(3) {
    my $self = shift;

    for my $method ('GET', 'POST', 'DELETE') {
        $self->set_dispatcher(
            Eve::PsgiStub->get_request(
                'method' => $method,
                'uri' => '/40301',
                'host' => 'domain.com',
                'cookie' => 'session_id=' . $self->{'session'}->get_id()));

        my $event = Eve::Event::PsgiRequestReceived->new(
            event_map => $self->{'registry'}->get_event_map(),
            env_hash => {});

        $self->{'dispatcher'}->handle(event => $event);

        $self->assert_response(
            $event->response,
            403,
            {
                'error' => Eve::Support::indexed_hash(
                    'type' => 'Privilege',
                    'message' => 'Some privilege message.')});
    }
}

sub test_no_id_matched : Test {
    my $self = shift;

    $self->set_dispatcher(
        Eve::PsgiStub->get_request(
            'host' => 'domain.com',
            'cookie' => 'session_id=' . $self->{'session'}->get_id()));

    my $event = Eve::Event::PsgiRequestReceived->new(
        event_map => $self->{'registry'}->get_event_map(),
        env_hash => {});

    $self->{'dispatcher'}->bind(
        name => 'no_id_dummy',
        pattern => '/',
        resource_constructor => sub { return $self->{'resource'}; });

    throws_ok(
        sub {
            $self->{'dispatcher'}->handle(event => $event);
        },
        'Eve::Error::Value');
}

sub test_nan_id : Test {
    my $self = shift;

    $self->set_dispatcher(
        Eve::PsgiStub->get_request(
            'uri' => '/id-nan',
            'host' => 'domain.com',
            'cookie' => 'session_id=' . $self->{'session'}->get_id()));

    my $event = Eve::Event::PsgiRequestReceived->new(
        event_map => $self->{'registry'}->get_event_map(),
        env_hash => {});

    $self->{'dispatcher'}->bind(
        name => 'not_a_number_id_dummy',
        pattern => 'http://domain.com/id-:id',
        resource_constructor => sub { return $self->{'resource'}; });

    $self->{'dispatcher'}->handle(event => $event);

    $self->assert_response(
        $event->response,
        400,
        {
            'error' => Eve::Support::indexed_hash(
                'type' => 'Request',
                'message' => 'The identifier must be a number or an '
                           . 'allowed alias, got "nan".')});
}

sub test_400_on_data_exception : Test(3) {
    my $self = shift;

    for my $method ('GET', 'POST', 'DELETE') {
        $self->set_dispatcher(
            Eve::PsgiStub->get_request(
                'method' => $method,
                'uri' => '/40001',
                'host' => 'domain.com',
                'cookie' => 'session_id=' . $self->{'session'}->get_id()));

        my $event = Eve::Event::PsgiRequestReceived->new(
            event_map => $self->{'registry'}->get_event_map(),
            env_hash => {});

        $self->{'dispatcher'}->handle(event => $event);

        $self->assert_response(
            $event->response,
            400,
            {
                'error' => Eve::Support::indexed_hash(
                    'type' => 'Data',
                    'message' => 'Some data message.')});
    }
}

1;

package Eve::HttpResourceGraphTest::Dummy;

use parent qw(Eve::HttpResource::Graph);

sub _read {
    my $self = shift;

    $self->_throw();

    return Eve::Support::indexed_hash(
        'method' => 'GET', 'id' => $self->_id);
}

sub _publish {
    my $self = shift;

    $self->_throw();

    return Eve::Support::indexed_hash(
        'method' => 'POST', 'id' => $self->_id);
}

sub _remove {
    my $self = shift;

    $self->_throw();

    return Eve::Support::indexed_hash(
        'method' => 'DELETE', 'id' => $self->_id);
}

sub _get_connections {
    my $self = shift;

    return {
        'dummy' =>
            $self->_dispatcher->get_uri(name => 'dummy')
            ->substitute(hash => {'id' => $self->_id})
            ->string};
}

sub _get_id_alias_hash {
    return {'me' => '12345'};
}

sub _throw {
    my $self = shift;

    if ($self->_id == 40301) {
        Eve::Exception::Privilege->throw(
            message => 'Some privilege message.');
    } elsif ($self->_id == 40001) {
        Eve::Exception::Data->throw(
            message => 'Some data message.');
    }
}

1;
