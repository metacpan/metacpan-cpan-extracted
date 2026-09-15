use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib", "$Bin/..";
use JSON::PP;
use ForgeOps::Tracker::Client;
use ForgeOps::Tracker::Configuration;
use t::lib::EchoServer;

my $server = t::lib::EchoServer->start;

sub new_configuration {
    my ($dsn) = @_;
    my $config = ForgeOps::Tracker::Configuration->new;
    $config->{dsn} = $dsn;
    return $config;
}

subtest 'returns true and sends the api key as a bearer token, payload as JSON' => sub {
    my $config = new_configuration('http://secret-key@127.0.0.1:' . $server->{port} . '/api/v1/events');
    my $client = ForgeOps::Tracker::Client->new($config);

    my $ok = $client->deliver({ exception_class => 'RuntimeError', message => 'boom' });

    is($ok, 1);
    my $requests = $server->requests;
    is(scalar(@$requests), 1);
    is($requests->[0]{headers}{AUTHORIZATION}, 'Bearer secret-key');
    is($requests->[0]{path}, '/api/v1/events');
    my $body = JSON::PP::decode_json($requests->[0]{body});
    is($body->{exception_class}, 'RuntimeError');
    is($body->{message}, 'boom');
};

subtest 'returns false on a non-2xx response' => sub {
    my $config = new_configuration('http://secret-key@127.0.0.1:' . $server->{port} . '/unauthorized');
    my $client = ForgeOps::Tracker::Client->new($config);

    is($client->deliver({ exception_class => 'RuntimeError' }), 0);
};

subtest 'returns false without dying when there is no reachable server' => sub {
    my $config = new_configuration('http://secret-key@127.0.0.1:1/api/v1/events');
    $config->{timeout} = 1;
    my $client = ForgeOps::Tracker::Client->new($config);

    my $result = eval { $client->deliver({ exception_class => 'RuntimeError' }) };
    ok(!$@, 'deliver must not die') or diag $@;
    is($result, 0);
};

subtest 'returns false when there is no DSN configured' => sub {
    my $config = new_configuration(undef);
    my $client = ForgeOps::Tracker::Client->new($config);

    is($client->deliver({ exception_class => 'RuntimeError' }), 0);
};

subtest 'delivers performance samples as a batch to the performance_samples URI' => sub {
    my $config = new_configuration('http://secret-key@127.0.0.1:' . $server->{port} . '/api/v1/events');
    my $client = ForgeOps::Tracker::Client->new($config);

    my $ok = $client->deliver_performance_samples([
        { transaction_name => 'GET /posts/:id', request_count => 2 },
    ]);

    is($ok, 1);
    my $requests = $server->requests;
    is($requests->[-1]{path}, '/api/v1/performance_samples');
    my $body = JSON::PP::decode_json($requests->[-1]{body});
    is(ref($body->{samples}), 'ARRAY');
    is($body->{samples}[0]{transaction_name}, 'GET /posts/:id');
};

subtest 'deliver_performance_samples returns false when there is no DSN configured' => sub {
    my $config = new_configuration(undef);
    my $client = ForgeOps::Tracker::Client->new($config);

    is($client->deliver_performance_samples([]), 0);
};

END { $server->stop if $server }

done_testing;
