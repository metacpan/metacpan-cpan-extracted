use warnings;
use strict;
use lib 't';
use share;

my $client = JSON::RPC2::Client->new();

is $client->lax_response_version, 0;

my ($failed, $result, $error, $call) = $client->response('{}');
is $failed, 'expect {jsonrpc}="2.0"';

is $client->lax_response_version(1), 1;
is $client->lax_response_version, 1;

($failed, $result, $error, $call) = $client->response('{}');
isnt $failed, 'expect {jsonrpc}="2.0"';

done_testing();
