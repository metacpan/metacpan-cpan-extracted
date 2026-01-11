#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use JSON::RPC::Simple::Lite;

################################################################################
# It's really hard to test functionality of module that requires network access.
#
# The best we can do is simulate some calls using create_request() and make sure
# the resulting output is what we expect.
################################################################################

my $api_url = "https://www.perturb.org/api/json-rpc/";
my $opts    = { debug => 0 };
my $json    = JSON::RPC::Simple::Lite->new($api_url, $opts);

is($json->create_request("foo"             , (1,2,3))   , '{"id":1,"method":"foo","params":[1,2,3],"version":1.1}');
is($json->create_request("bar"             ,())         , '{"id":1,"method":"bar","params":[],"version":1.1}');
is($json->create_request("baz"             ,(undef))    , '{"id":1,"method":"baz","params":[null],"version":1.1}');
is($json->create_request("user.email.login", ("doolis")), '{"id":1,"method":"user.email.login","params":["doolis"],"version":1.1}');

done_testing();
