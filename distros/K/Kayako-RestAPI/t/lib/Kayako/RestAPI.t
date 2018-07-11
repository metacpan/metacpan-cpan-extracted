#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Kayako::RestAPI'); }

my $api_params = {
    "api_url"    => 'http://kayako.example.com/api/index.php?',
    "api_key"    => '123',
    "secret_key" => '456'
};

my $module_params = {
    content_key      => 'text',
    pretty           => 1,
    attribute_prefix => 'attr_'
};

my $kayako_api = Kayako::RestAPI->new( $api_params, $module_params );

my $r = $kayako_api->_prepare_request;

is $r->{'apikey'}, $api_params->{'api_key'}, "Request has api key";
ok $r->{'signature'}, "Request has signature";
ok $r->{'salt'},      "Request has salt";
is length $r->{'salt'}, 10, "Salt length is 10";

my $a = [
    {
        'title' => { text => 'In progress' },
        'id'  => =>     { text => 1 },
        'foo' => { text => 'bar' }
    },
    {
        'title' => { text => 'Closed' },
        'id'    => { text => 3 },
        'foo'   => { text => 'baz' }
    }
];

my $b = [
    {
        'title' => 'In progress',
        'id'    => 1,
    },
    {
        'title' => 'Closed',
        'id'    => 3,
    }
];

is_deeply $kayako_api->filter_fields($a), $b,
  'filter_fields is working as expected';

done_testing;
