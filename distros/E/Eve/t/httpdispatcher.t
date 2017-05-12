# -*- mode: Perl; -*-
package HttpDispatcherTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::Exception;

use Test::MockObject;
use Test::More;

use Eve::PsgiStub;
use Eve::RegistryStub;

use Eve::Event::PsgiRequestReceived;
use Eve::Exception;
use Eve::HttpDispatcher;
use Eve::Registry;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'host'} = 'www.domain.com';
    $self->{'path'} = '/path';
    $self->{'registry'} = Eve::Registry->new();
    $self->{'registry'}->{'base_uri_string'} =
        'http://' . $self->{'host'} . $self->{'path'};

    $self->{'session'} = $self->{'registry'}->get_session(
        id => undef,
        storage_path => File::Spec->catdir(
            File::Spec->tmpdir(), 'test_session_storage'),
        expiration_interval => 3600);

    $self->{'event'} = Eve::Event::PsgiRequestReceived->new(
        event_map => $self->{'registry'}->get_event_map(),
        env_hash => {});
}

sub set_dispatcher {
    my ($self, $request, $alias_uri_list) = @_;

    $self->{'data_list'} = [
        { name => 'root', pattern => '/' },
        { name => 'another', pattern => '/another' },
        { name => 'place', pattern => '/:place' },
        { name => 'placeholder', pattern => '/:place/:holder' }];

    $self->{'dispatcher'} = Eve::HttpDispatcher->new(
        request_constructor => sub {
            return $request;
        },
        response => $self->{'registry'}->get_http_response(),
        event_map => $self->{'registry'}->get_event_map(),
        base_uri => $self->{'registry'}->get_base_uri(),
        alias_base_uri_list => ($alias_uri_list or []));

    $self->{'http_resource'} = Eve::HttpDispatcherTest::DummyResource->new(
        response => $self->{'registry'}->get_http_response(),
        session_constructor => sub {
            return $self->{'session'};
        },
        dispatcher => $self->{'dispatcher'});

    for my $data (@{$self->{'data_list'}}) {
        $self->{'dispatcher'}->bind(
            name => $data->{'name'},
            pattern => $data->{'pattern'},
            resource_constructor => sub {
                return $self->{'http_resource'};
            });
    }

    return;
}

sub test_handle_exception_data : Test(2) {
    my $self = shift;

    $self->set_dispatcher(
        Eve::PsgiStub->get_request(
            host => $self->{'host'}, uri => '/path/thrower'));

    $self->{'dispatcher'}->bind(
        name => 'thrower',
        pattern => '/thrower',
        resource_constructor => sub {
            return Eve::HttpDispatcherTest::ThrowerResource->new(
                response => $self->{'registry'}->get_http_response(),
                session_constructor => sub {
                    return $self->{'session'}
                },
                dispatcher => $self->{'dispatcher'});
        });

    $self->{'dispatcher'}->bind(
        name => '400',
        pattern => '/400',
        exception => 'Eve::Exception::Http::400BadRequest',
        resource_constructor => sub {
            return $self->{'http_resource'};
        });

    $self->{'dispatcher'}->handle(event => $self->{'event'});

    is(
        $self->{'http_resource'}->process_count,
        1,
        'The process method should be called only once');

    isa_ok(
        $self->{'http_resource'}->call_args->{'exception'},
        'Eve::Exception::Http::400BadRequest');
}

sub test_handle_matched : Test(10) {
    my $self = shift;

    $self->set_dispatcher(Eve::PsgiStub->get_request());

    my $uri_string_hash = {
        '/path' => {},
        '/path?with=query&string=1' => {},
        '/path/another' => {
            'place' => 'another'},
        '/path/some/thing' =>
            {'place' => 'some', 'holder' => 'thing'},
        '/path/another/stuff' =>
            {'place' => 'another', 'holder' => 'stuff'}
    };

    for my $uri_string (keys %{$uri_string_hash}) {
        my ($path, $query) = split('\?', $uri_string);
        $self->set_dispatcher(
            Eve::PsgiStub->get_request(
                host => $self->{'host'},
                uri => $path,
                query => $query));

        $self->{'dispatcher'}->handle(event => $self->{'event'});

        is($self->{'http_resource'}->process_count, 1, $uri_string);
        is_deeply(
            $self->{'http_resource'}->call_args,
            $uri_string_hash->{$uri_string},
            $uri_string);

        $self->{'http_resource'}->clear();
    }
}

sub test_handle_not_matched : Test(4) {
    my $self = shift;

    my $uri_string_list = [
        'http://www.domain.com/another/path',
        'http://www.domain.com/another'];

    for my $uri_string (@{$uri_string_list}) {
        $self->set_dispatcher(
            Eve::PsgiStub->get_request(
                host => $self->{'host'},
                uri => $uri_string));

        throws_ok(
            sub {
                $self->{'dispatcher'}->handle(event => $self->{'event'});
            },
            'Eve::Exception::Http::404NotFound',
            $uri_string);
        is($self->{'http_resource'}->process_count, 0, $uri_string);

        $self->{'http_resource'}->clear();
    }
}

sub test_resource_exception : Test(2) {
    my $self = shift;

    $self->set_dispatcher(
        Eve::PsgiStub->get_request(
            host => $self->{'host'},
            uri => '/this/should/never/match'));

    $self->{'dispatcher'}->bind(
        name => '404',
        pattern => '/404',
        exception => 'Eve::Exception::Http::404NotFound',
        resource_constructor => sub {
            return $self->{'http_resource'};
        });

    $self->{'dispatcher'}->handle(event => $self->{'event'});

    is($self->{'http_resource'}->process_count, 1);

    isa_ok(
        $self->{'http_resource'}->call_args->{'exception'},
        'Eve::Exception::Base');
}

sub test_resource_exception_uniqueness : Test {
    my $self = shift;

    $self->set_dispatcher(Eve::PsgiStub->get_request());

    my $resources = [
        {
            'name' => '404',
            'pattern' => '/404',
            'exception' => 'Eve::Exception::Http::404NotFound'},
        {
            'name' => '405',
            'pattern' => '/405',
            'exception' => 'Eve::Exception::Http::404NotFound' }
    ];

    throws_ok( sub {
        for my $data (@{$resources}){
            $self->{'dispatcher'}->bind(
                name => $data->{'name'},
                pattern => $data->{'pattern'},
                resource_constructor => sub {
                    return $self->{'http_resource'};
                },
                exception => $data->{'exception'}
            );
        }
    }, 'Eve::Error::HttpDispatcher');
}

sub test_resource_uri_uniqueness : Test(2) {
    my $self = shift;

    $self->set_dispatcher(Eve::PsgiStub->get_request());

    throws_ok(
        sub {
            $self->{'dispatcher'}->bind(
                name => 'not_unique_uri',
                pattern => '/:place/:holder',
                resource_constructor => sub {
                    return $self->{'http_resource'};
                });
        },
        'Eve::Error::HttpDispatcher');
    ok(Eve::Error::HttpDispatcher->caught()->message =~
       qr/Binding URI must be unique: /.
       'http://www.domain.com/path/:place/:holder');
}

sub test_resource_name_uniqueness : Test(2) {
    my $self = shift;

    $self->set_dispatcher(Eve::PsgiStub->get_request());

    throws_ok(
        sub {
            $self->{'dispatcher'}->bind(
                name => 'root',
                pattern => '/not/unique/name',
                resource_constructor => sub {
                    return $self->{'http_resource'};
                });
        },
        'Eve::Error::HttpDispatcher');
    ok(Eve::Error::HttpDispatcher->caught()->message =~
       qr/Binding name must be unique: root/);
}

sub test_build_uri : Test(4) {
    my $self = shift;

    $self->set_dispatcher(Eve::PsgiStub->get_request());

    is(
        $self->{'dispatcher'}->get_uri(name => 'root')->string,
        'http://www.domain.com/path');
    is(
        $self->{'dispatcher'}->get_uri(name => 'another')->string,
        'http://www.domain.com/path/another');
    throws_ok(
        sub { $self->{'dispatcher'}->get_uri(name => 'oops'); },
        'Eve::Error::HttpDispatcher');
    ok(Eve::Error::HttpDispatcher->caught()->message =~
       qr/There is no resource with such name: oops/);
}

sub test_response_event_parameter : Test {
    my $self = shift;

    my $request = Eve::PsgiStub->get_request(
        uri => '/path', host => 'www.domain.com');
    $self->set_dispatcher($request);

    my $event;
    my $handler_mock = Test::MockObject->new();
    $handler_mock->mock('handle', sub { (undef, undef, $event) = @_; });

    $self->{'registry'}->get_event_map()->bind(
        event_class => 'Eve::Event::HttpResponseReady',
        handler => $handler_mock);

    $self->{'dispatcher'}->handle(event => $self->{'event'});

    isa_ok($self->{'event'}->response, 'Eve::HttpResponse');
}

sub test_alias_base_uri : Test(6) {
    my $self = shift;

    my $uri_string_hash = {
        '/path' => {
            'host' => 'sub.domain.com',
            'query' => '?with=query&string=1',
            'matches' => {}},
        '/path/another' => {
            'host' => 'another.domain.com',
            'matches' => {'place' => 'another'}},
        '/path/some/thing' => {
            'host' => 'whoops.com',
            'matches' => {'place' => 'some', 'holder' => 'thing'}}};

    for my $uri_string (keys %{$uri_string_hash}) {
        my $request = Eve::PsgiStub->get_request(
            uri => $uri_string,
            host => $uri_string_hash->{$uri_string}->{'host'},
            query =>
            $uri_string_hash->{$uri_string}->{'query_string'});

        $self->set_dispatcher(
            $request,
            [Eve::Uri->new(string => 'http://sub.domain.com/path'),
             Eve::Uri->new(string => 'http://another.domain.com/path'),
             Eve::Uri->new(string => 'http://whoops.com/path')]);

        $self->{'dispatcher'}->handle(event => $self->{'event'});

        is($self->{'http_resource'}->process_count, 1, $uri_string);
        is_deeply(
            $self->{'http_resource'}->call_args,
            $uri_string_hash->{$uri_string}->{'matches'},
            $uri_string);

        $self->{'http_resource'}->clear();
    }
}

package Eve::HttpDispatcherTest::DummyResource;

use parent qw(Eve::HttpResource);

sub init {
    my $self = shift;

    $self->SUPER::init(@_);
    $self->clear();
}

sub _get {
    my ($self, %arg_hash) = @_;

    $self->call_args = \%arg_hash;
    $self->process_count++;
}

sub clear {
    my $self = shift;

    $self->{'call_args'} = undef;
    $self->{'process_count'} = 0;
}

1;

package Eve::HttpDispatcherTest::ThrowerResource;

use parent qw(Eve::HttpResource);

sub init {
    my $self = shift;

    $self->SUPER::init(@_);
}

sub _get {
    my ($self, %arg_hash) = @_;

    Eve::Exception::Http::400BadRequest->throw(message => $arg_hash{'message'});
}

1;

1;
