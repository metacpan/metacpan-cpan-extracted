#!perl

use strict;
use warnings;

use Marketplace::Ebay;
use File::Spec;
use Test::More;
use Data::Dumper;
use YAML qw/LoadFile/;

my $config = File::Spec->catfile(qw/t ebay.yml/);

if (-f $config) {
    plan tests => 20;
}
else {
    plan skip_all => "Missing $config file, cannot do a request";
}

my $conf = LoadFile($config);

ok($conf, "Configuration loaded");

my $ebay = Marketplace::Ebay->new(
                                  production => 0,
                                  site_id => 77,
                                  compatibily_level => 901,
                                  xsd_file => File::Spec->catfile(qw/t ebay.xsd/),
                                  # the config can override
                                  %$conf,
                                 );

ok($ebay, "Object created");

is ($ebay->endpoint, 'https://api.sandbox.ebay.com/ws/api.dll')
  or die "Wrong endpoint!";

for my $options ({}, { no_validate => 1 }) {
    my $res = $ebay->api_call('GeteBayOfficialTime', {});
    ok($res);
    is $res->struct->{Ack}, "Success", "Call is ok";
    ok $res->is_success;
    ok !$res->is_warning;
}
my $struct = $ebay->api_call('GeteBayOfficialTime', {}, { requires_struct => 1 });
is $struct->{Ack}, "Success";

ok ($ebay->last_response);
like $ebay->last_response->status_line, qr/200 OK/;

ok ($ebay->last_parsed_response->is_success, "api call ack ok")
  or diag Dumper($ebay->last_parsed_response);

ok ($ebay->last_parsed_response->version, "Got version");

is $ebay->ebay_sites_name_to_id->{UK}, 3;
is $ebay->ebay_sites_name_to_id->{Germany}, 77;
is $ebay->ebay_sites_id_to_name->{77}, 'Germany';
is $ebay->ebay_sites_id_to_name->{3}, 'UK';
