# -*- mode: Perl; -*-
package HttpRequestPsgiTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use FileHandle;

use Test::MockObject;
use Test::More;

use Eve::PsgiStub;
use Eve::RegistryStub;

use Eve::HttpRequest::Psgi;
use Eve::Registry;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'registry'} = Eve::Registry->new();
}

sub test_parent: Test {
    my $self = shift;

    my $request = Eve::PsgiStub->get_request();

    isa_ok($request, 'Eve::HttpRequest');
}

sub test_uri : Test(4) {
    my $self = shift;

    my $uri_string_hash = {
        'domain.com' => '/path',
        'anotherdomain.com' => '/and/path'};

    for my $domain (keys %{$uri_string_hash}) {

        my $request = Eve::PsgiStub->get_request(
            uri => $uri_string_hash->{$domain},
            host => $domain);

        my $uri = $request->get_uri();

        isa_ok($uri, 'Eve::Uri');
        is($uri->string, 'http://' . $domain . $uri_string_hash->{$domain});
    }
}

sub test_uri_post : Test(2) {
    my $self = shift;

    my $uri_string_hash = {
        'http://domain.com/path?some=query_string' => {
            'path' => '/path',
            'host' => 'domain.com',
            'query' => 'some=query_string'},
        'http://anotherdomain.com/and/path?another=value' => {
            'path' => '/and/path',
            'host' => 'anotherdomain.com',
            'query' => 'another=value'}};

    for my $uri_string (keys %{$uri_string_hash}) {

        my $request = Eve::PsgiStub->get_request(
            method => 'POST',
            host => $uri_string_hash->{$uri_string}->{'host'},
            uri => $uri_string_hash->{$uri_string}->{'path'},
            query => $uri_string_hash->{$uri_string}->{'query'});

        my $uri = $request->get_uri();

        is($uri->string, $uri_string);
    }
}

sub test_uri_constructor : Test {
    my $self = shift;

    my $uri_mock = Test::MockObject->new();
    $uri_mock->set_true('set_query_hash');

    my $request = Eve::HttpRequest::Psgi->new(
        uri_constructor => sub { return $uri_mock; },
        env_hash => {});

    is($request->get_uri(), $uri_mock);
}

sub test_method : Test(2) {
    my $self = shift;

    for my $method ('GET', 'POST') {
        my $request = Eve::PsgiStub->get_request(method => $method);

        is($request->get_method(), $method);
    }
}

sub test_parameter : Test(4) {
    my $self = shift;

    my $data = 'first=foo&second=bar';

    my $request = Eve::PsgiStub->get_request(
        method => 'POST', body => $data);

    my $data_hash = {
        'first' => 'foo',
        'second' => 'bar',
        'third' => undef};

    for my $parameter_name (keys %{$data_hash}) {
        is(
            $request->get_parameter(name => $parameter_name),
            $data_hash->{$parameter_name});
    }

    my @parameter_list = map {
        $request->get_parameter(name => $_)
    } keys %{$data_hash};

    is(scalar @parameter_list, (scalar keys %{$data_hash}));
}

sub test_multivalue_parameter : Test(2) {
    my $self = shift;

    my $request = Eve::PsgiStub->get_request(
        method => 'POST', body => 'first=foo&first=bar&second=baz&second=foo');

    my $data_hash = {'first' => ['foo', 'bar'], 'second' => ['baz', 'foo']};

    for my $parameter_name (keys %{$data_hash}) {
        is_deeply(
            [$request->get_parameter(name => $parameter_name)],
            $data_hash->{$parameter_name});
    }
}

sub test_parameter_hash : Test {
    my $self = shift;

    my $data_hash = {
        'first' => 'bar',
        'second' => 'bar'};

    my $request = Eve::PsgiStub->get_request(
        method => 'POST', body => 'first=foo&first=bar&second=bar');

    is_deeply($request->get_parameter_hash(), $data_hash);
}

sub test_get_cookie : Test(2) {
    my $self = shift;

    my $request = Eve::PsgiStub->get_request(
        cookie => 'some_cookie=bleh;another_cookie=another;');

    my $data_hash = {
        'some_cookie' => 'bleh',
        'another_cookie' => 'another'};

    for my $cookie_name (keys %{$data_hash}) {
        is_deeply($request->get_cookie(name => $cookie_name),
                  $data_hash->{$cookie_name});
    }
}

sub test_upload : Test(2) {
    my $request = Eve::PsgiStub->get_request(
        method => 'POST',
        uri => '/graph/object-12345',
        host => 'example.com',
        body => 'title=title&description=desc');

    my $upload_hash = {
        'tempname' => 'some_name.jpg',
        'size' => 123,
        'filename' => 'logo-small.jpg',
        'content_type' => 'image/jpeg'};

    $request->cgi->{'env'}->{'plack.request.upload'} = Hash::MultiValue->new(
        'avatar' => Plack::Request::Upload->new(
            headers =>
                HTTP::Headers->new(
                    "Content-Disposition" =>
                        'form-data; name "avatar"; filename="logo-small.jpg',
                    "Content-Type" => $upload_hash->{'content_type'}),
            %{$upload_hash}));

    is_deeply($request->get_upload(name => 'avatar'), $upload_hash);

    $request->cgi->{'env'}->{'plack.request.upload'} = Hash::MultiValue->new();

    ok(not defined $request->get_upload(name => 'any'));
}

sub test_json_parameters : Test(4) {
    my $self = shift;

    my $data_hash = {'first' => 'bar', 'second' => 'foo', 'last' => 'baz'};

    my $request = Eve::PsgiStub->get_request(
        method => 'POST',
        body => '{"first":"bar","second":"foo","last":"baz"}',
        content_type => 'application/json');

    is_deeply($request->get_parameter_hash(), $data_hash);

    for my $key (keys %{$data_hash}) {
        is($request->get_parameter(name => $key), $data_hash->{$key});
    }
}

1;
