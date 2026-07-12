#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';

use lib 't/lib';
use MockUA;
use HTTP::Response;
use Test::More;
use Map::Tube::API;

sub json_response {
    my ($perl_data) = @_;
    my $response = HTTP::Response->new(200, 'OK');
    $response->content(JSON->new->allow_nonref->utf8(1)->encode($perl_data));
    return $response;
}

{
    local $ENV{MAP_BASE_URL} = undef;
    local $ENV{MAP_VERSION}  = undef;

    my $api = Map::Tube::API->new;
    eval { $api->shortest_route({ map => 'london', start => 'A', end => 'B' }) };
    like(
        $@, qr/Missing map base url/,
        'a call dies with a clear error when base_url is neither passed nor set via MAP_BASE_URL'
    );
}

{
    my $api = Map::Tube::API->new(base_url => 'http://example.test');
    is($api->version, 'v1', 'version defaults to v1 when not passed and MAP_VERSION is unset');
}

{
    local $ENV{MAP_VERSION} = 'v2';
    my $api = Map::Tube::API->new(base_url => 'http://example.test');
    is($api->version, 'v2', 'version is picked up from the MAP_VERSION environment variable');
}

{
    local $ENV{MAP_BASE_URL} = 'http://from-env.test';
    my $api = Map::Tube::API->new;
    is($api->base_url, 'http://from-env.test', 'base_url is picked up from the MAP_BASE_URL environment variable');
}

{
    my $api = Map::Tube::API->new(base_url => 'http://example.test');

    eval { $api->shortest_route({ start => 'A', end => 'B' }) };
    like($@, qr/Missing map name/, 'shortest_route() dies when "map" is missing');

    eval { $api->shortest_route({ map => 'london', end => 'B' }) };
    like($@, qr/Missing start station name/, 'shortest_route() dies when "start" is missing');

    eval { $api->shortest_route({ map => 'london', start => 'A' }) };
    like($@, qr/Missing end station name/, 'shortest_route() dies when "end" is missing');

    eval { $api->shortest_route({ map => '', start => 'A', end => 'B' }) };
    like($@, qr/Missing map name/, 'shortest_route() dies when "map" is an empty string');
}

{
    my $expected = { route => [ 'Baker Street', 'Great Portland Street', 'Euston Square' ] };
    my $mock  = MockUA->new(json_response($expected));
    my $api   = Map::Tube::API->new(base_url => 'http://example.test', ua => $mock);

    my $result = $api->shortest_route({
        map => 'london', start => 'Baker Street', end => 'Euston Square',
    });

    is_deeply($result, $expected, 'shortest_route() decodes the JSON response body');
    is(
        $mock->last_request->uri,
        'http://example.test/map-tube/v1/shortest-route/london/Baker%20Street/Euston%20Square',
        'shortest_route() builds the expected URL, including base_url, version, and %-encoded station names'
    );
    is($mock->last_request->method, 'GET', 'shortest_route() issues a GET request');
}

{
    # a custom version should be reflected in the URL
    my $mock = MockUA->new(json_response({}));
    my $api  = Map::Tube::API->new(base_url => 'http://example.test', version => 'v2', ua => $mock);

    $api->shortest_route({ map => 'london', start => 'A', end => 'B' });
    is(
        $mock->last_request->uri,
        'http://example.test/map-tube/v2/shortest-route/london/A/B',
        'a custom version is reflected in the constructed URL'
    );
}

{
    my $api = Map::Tube::API->new(base_url => 'http://example.test');

    eval { $api->line_stations({ line => 'Metropolitan' }) };
    like($@, qr/Missing map name/, 'line_stations() dies when "map" is missing');

    eval { $api->line_stations({ map => 'london' }) };
    like($@, qr/Missing line name/, 'line_stations() dies when "line" is missing');
}

{
    my $expected = { stations => [ 'Baker Street', 'Great Portland Street' ] };
    my $mock  = MockUA->new(json_response($expected));
    my $api   = Map::Tube::API->new(base_url => 'http://example.test', ua => $mock);

    my $result = $api->line_stations({ map => 'london', line => 'Metropolitan' });

    is_deeply($result, $expected, 'line_stations() decodes the JSON response body');
    is(
        $mock->last_request->uri,
        'http://example.test/map-tube/v1/stations/london/Metropolitan',
        'line_stations() builds the expected URL'
    );
}

{
    my $api = Map::Tube::API->new(base_url => 'http://example.test');

    eval { $api->map_stations({}) };
    like($@, qr/Missing map name/, 'map_stations() dies when "map" is missing');
}

{
    my $expected = { stations => [ 'A', 'B', 'C' ] };
    my $mock  = MockUA->new(json_response($expected));
    my $api   = Map::Tube::API->new(base_url => 'http://example.test', ua => $mock);

    my $result = $api->map_stations({ map => 'london' });

    is_deeply($result, $expected, 'map_stations() decodes the JSON response body');
    is(
        $mock->last_request->uri,
        'http://example.test/map-tube/v1/stations/london',
        'map_stations() builds the expected URL'
    );
}

{
    my $expected = { maps => [ 'London', 'Delhi', 'Paris' ] };
    my $mock  = MockUA->new(json_response($expected));
    my $api   = Map::Tube::API->new(base_url => 'http://example.test', ua => $mock);

    my $result = $api->available_maps;

    is_deeply($result, $expected, 'available_maps() decodes the JSON response body');
    is(
        $mock->last_request->uri,
        'http://example.test/map-tube/v1/maps',
        'available_maps() builds the expected URL'
    );
}

{
    my $fail_response = HTTP::Response->new(404, 'Not Found');
    $fail_response->content('map not found');

    my $mock = MockUA->new($fail_response);
    my $api  = Map::Tube::API->new(base_url => 'http://example.test', ua => $mock);

    eval { $api->map_stations({ map => 'nonexistent' }) };
    isa_ok($@, 'Map::Tube::API::Exception', 'a failed HTTP response propagates as an exception');
    is($@->code, 404, 'the exception carries the HTTP status code from the failed request');
}

{
    my $api = Map::Tube::API->new(base_url => 'http://example.test');
    isa_ok($api, 'Map::Tube::API::UserAgent', 'Map::Tube::API extends Map::Tube::API::UserAgent');
    can_ok($api, qw(get post shortest_route line_stations map_stations available_maps));
}

done_testing;
