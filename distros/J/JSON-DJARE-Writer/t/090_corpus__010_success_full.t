#!perl

use strict;
use warnings;
use lib 'lib';

use Test::Most;
use JSON qw/decode_json/;
use JSON::DJARE::Writer;

my $expected = decode_json( join '', (<DATA>) );

my $djare = JSON::DJARE::Writer->new(
    djare_version => '0.0.2',
    meta_version  => '0.1.0',
    meta_from     => 'rescue.int/launch/machines#POST',
    meta_schema   => 'https://rescue.int/schemas/launch/machines/response.json',
    auto_timestamp => 1,
);

my $result = $djare->data(
    {
        machines => [
            {
                id     => "thunderbird-1",
                status => "go",
                pilot  => {
                    username => "scott.tracy",
                    comment  => "FAB"
                }
            },
            {
                id     => "thunderbird-4",
                status => "go",
                pilot  => {
                    username => "gordon.tracy",
                    comment  => "FAB"
                }
            }
        ]
    }
);

# meta/trace is discouraged, so we need to manually add to it
$result->{'meta'}->{'trace'} = {
    "_comment"   => "don't stick too much stuff in trace, see the docs",
    "request-id" => "X-deadbeef"
};

# Fudge the auto-timestamp
$expected->{'meta'}->{'timestamp'} = JSON::DJARE::Writer->auto_timestamp;

eq_or_diff( $result, $expected, "matches" );

# Sanity-check that timestamp tho
like(
    $expected->{'meta'}->{'timestamp'},
    qr/20\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d/,
    "timestamp looks reasonably shaped"
);

done_testing();

__DATA__
{
    "meta": {
        "version": "0.1.0",
        "from": "rescue.int/launch/machines#POST",
        "djare": "0.0.2",
        "timestamp": "2020-12-09 16:09:53+00:00",
        "schema": "https://rescue.int/schemas/launch/machines/response.json",
        "trace": {
            "_comment": "don't stick too much stuff in trace, see the docs",
            "request-id": "X-deadbeef"
        }
    },
    "data": {
        "machines": [
            {
                "id": "thunderbird-1",
                "status": "go",
                "pilot": {
                    "username": "scott.tracy",
                    "comment": "FAB"
                }
            },
            {
                "id": "thunderbird-4",
                "status": "go",
                "pilot": {
                    "username": "gordon.tracy",
                    "comment": "FAB"
                }
            }
        ]
    }
}
