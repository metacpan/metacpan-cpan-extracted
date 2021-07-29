use Test::More;
use strict;
use lib 'inc';
use IO::String;
use Data::Dumper;
use LWP::UserAgent;
use LWP::Protocol::PSGI;

BEGIN {
    require 't/test-lib.pm';
}

my $reject = 1;

LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        my $res = $reject
          ? '[{"duration":"1h2m10.462947715s",
  "id":1121,
  "origin":"CAPI",
  "scenario":"crowdsecurity/iptables-scan-multi_ports",
  "scope":"ip",
  "type":"ban",
  "value":"127.0.0.1/32"}]'
          : '';
        return [ 200, [], [$res] ];
    }
);

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => 'error',
            authentication => 'Demo',
            userDB         => 'Same',
            crowdsec       => 1,
            crowdsecAction => 'reject',
        }
    }
);

ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
    ),
    'Auth query'
);
expectReject($res);
count(1);

$reject = 0;
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
    ),
    'Auth query'
);
expectOK($res);
count(1);

clean_sessions();

done_testing( count() );
