#!perl

use strict;
use warnings;
use lib 'lib';

use Test::Most;
use JSON qw/decode_json/;
use JSON::DJARE::Writer;

my $expected  = decode_json( join '', (<DATA>) );
my $from      = 'myapi.com/coefficiants';
my $timestamp = sub { '2020-12-09 16:09:53+00:00' };

for my $t (
    {
        name       => 'from in new()',
        new_args   => [ auto_timestamp => $timestamp, meta_from => $from ],
        error_args => []
    },
    {
        name       => 'from in error()',
        new_args   => [ auto_timestamp => $timestamp ],
        error_args => [ from           => $from ]
    }
  )
{

    my $djare = JSON::DJARE::Writer->new(
        djare_version => '0.0.2',
        meta_version  => '0.0.1',
        @{ $t->{'new_args'} }
    );

    my $result = $djare->error(
        'Invalid payload provided',
        id     => '10.10.3.59:453294281',
        code   => 'BADPAYLOAD',
        detail => 'Value at [/error/title]: expected[string] actual[array]',
        trace  => [
            {
                instancePath => "/error/title",
                schemaPath   => "#/definitions/error/properties/title/type",
                keyword      => "type",
                params       => {
                    type => "string"
                },
                message => "must be string"
            }
        ],
        @{ $t->{'error_args'} }
    );

    eq_or_diff( $result, $expected, "matches for case: " . $t->{'name'} );
}

done_testing();

__DATA__
{
  "meta": {
    "version": "0.0.1",
    "from": "myapi.com/coefficiants",
    "djare": "0.0.2",
    "timestamp": "2020-12-09 16:09:53+00:00"
  },
  "error": {
    "title": "Invalid payload provided",
    "code": "BADPAYLOAD",
    "detail": "Value at [/error/title]: expected[string] actual[array]",
    "id": "10.10.3.59:453294281",
    "trace": [
      {
        "instancePath": "/error/title",
        "schemaPath": "#/definitions/error/properties/title/type",
        "keyword": "type",
        "params": {
          "type": "string"
        },
        "message": "must be string"
      }
    ]
  }
}
