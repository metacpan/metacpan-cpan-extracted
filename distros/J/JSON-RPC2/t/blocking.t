use Test::More tests => 17;

use JSON::RPC2::Server;
use JSON::RPC2::Client;


my $server = JSON::RPC2::Server->new();
my $client = JSON::RPC2::Client->new();
ok($server,                         'server object created');
ok($client,                         'client object created');

$server->register('echo', \&echo);
$server->register('fail', \&bang);

sub echo { return "my params is (@_)"   }
sub bang { return (undef, 1, 'failed!') }


my ($request, $response, $failed, $result, $error);

($request, $response) = ();
$request = $client->call('echo', 1, 2, 3);
ok($request,                        'request generated');
$server->execute($request, sub { $response = $_[0] });
ok($response,                       'response generated');
($failed, $result, $error) = $client->response($response);
is($failed, undef,                  'response parsed without errors');
is($result, "my params is (1 2 3)", 'result data correct');
is($error, undef,                   'no error happens');

($request, $response) = ();
$request = $client->call('fail', 1, 2, 3);
ok($request,                        'request generated');
$server->execute($request, sub { $response = $_[0] });
ok($response,                       'response generated');
($failed, $result, $error) = $client->response($response);
is($failed, undef,                  'response parsed without errors');
is($result, undef,                  'no result');
ok($error,                          'error happens');
is($error->{code}, 1,               'error code correct');
is($error->{message}, 'failed!',    'error message correct');

($failed, $result, $error) = $client->response($response);
is($failed, 'unknown {id}',         'failed to parse same response again');
is($result, undef,                  'no result');
is($error, undef,                   'no error');

