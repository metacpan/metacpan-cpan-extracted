use strict;
use warnings;
use Test::More;
use lib '../lib';
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use IO::Handle;

use LightTCP::SSLclient qw(EREQUEST ERESPONSE);

subtest 'response with no connection' => sub {
    my $client = LightTCP::SSLclient->new();

    my ($code, $state, $headers, $body, $errors, $debug, $error_code) = $client->response();
    is($code, undef, 'code is undef');
    is($state, undef, 'state is undef');
    is($headers, undef, 'headers is undef');
    is($body, undef, 'body is undef');
    ok(@$errors > 0, 'error message returned');
    ok(@$debug >= 0, 'debug messages present');
    is($error_code, ERESPONSE, 'error code is ERESPONSE');
};

subtest 'request with no connection' => sub {
    my $client = LightTCP::SSLclient->new();

    my ($ok, $errors, $debug, $error_code) = $client->request('GET', '/');
    is($ok, 0, 'returns 0');
    ok(@$errors > 0, 'error message returned');
    ok(@$debug >= 0, 'debug messages present');
    is($error_code, EREQUEST, 'error code is EREQUEST');
};

subtest 'verbose mode returns debug messages' => sub {
    my $client = LightTCP::SSLclient->new(verbose => 1);

    my ($ok, $errors, $debug, $error_code) = $client->request('GET', '/');
    is($ok, 0, 'returns 0');
    ok(@$errors > 0, 'error messages returned');
    ok(@$debug > 0, 'debug messages present when verbose is true');

    my ($code, $state, $headers, $body, $resp_errors, $resp_debug, $resp_code) = $client->response();
    ok(@$resp_errors > 0, 'response errors returned');
    ok(@$resp_debug > 0, 'response debug messages present when verbose is true');
};

subtest 'verbose mode disabled returns empty debug' => sub {
    my $client = LightTCP::SSLclient->new(verbose => 0);

    my ($ok, $errors, $debug, $error_code) = $client->request('GET', '/');
    is($ok, 0, 'returns 0');
    is(@$debug, 0, 'no debug messages when verbose is false');

    my ($code, $state, $headers, $body, $resp_errors, $resp_debug, $resp_code) = $client->response();
    is(@$resp_debug, 0, 'no response debug messages when verbose is false');
};

subtest 'connect with invalid proxy returns 4 values' => sub {
    my $client = LightTCP::SSLclient->new();

    my ($ok, $errors, $debug, $error_code) = $client->connect('example.com', 443, 'invalid:proxy:format', undef);
    is($ok, 0, 'returns 0 on invalid proxy');
    ok(@$errors > 0, 'error messages returned');
    ok(@$debug >= 0, 'debug messages present');
};

subtest 'connect with verbose mode' => sub {
    my $client = LightTCP::SSLclient->new(verbose => 1);

    my ($ok, $errors, $debug, $error_code) = $client->connect('example.com', 443, 'invalid:proxy:format', undef);
    is($ok, 0, 'returns 0 on invalid proxy');
    ok(@$debug > 0, 'debug messages present when verbose is true');
};

done_testing();
