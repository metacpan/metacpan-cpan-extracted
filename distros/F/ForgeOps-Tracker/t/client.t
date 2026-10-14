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

subtest 'last_status tells a rejection from a failure worth retrying' => sub {
    my %expected = (
        202 => 'delivered',
        400 => 'rejected', 401 => 'rejected', 403 => 'rejected', 413 => 'rejected', 422 => 'rejected',
        408 => 'failed', 429 => 'failed', 500 => 'failed', 503 => 'failed',
    );
    for my $code (sort keys %expected) {
        my $config = new_configuration('http://secret-key@127.0.0.1:' . $server->{port} . "/status/$code");
        my $client = ForgeOps::Tracker::Client->new($config);

        is($client->deliver({ exception_class => 'RuntimeError' }), $expected{$code} eq 'delivered' ? 1 : 0, "$code answers as before");
        is($client->last_status, $expected{$code}, "$code is $expected{$code}");
    }
};

subtest 'last_status is failed for now when there is no reachable server or no DSN' => sub {
    my $config = new_configuration('http://secret-key@127.0.0.1:1/api/v1/events');
    $config->{timeout} = 1;
    my $client = ForgeOps::Tracker::Client->new($config);
    $client->deliver_metrics([ { metric_name => 'signup', value => 1 } ]);
    is($client->last_status, 'failed');

    my $unconfigured = ForgeOps::Tracker::Client->new(new_configuration(undef));
    $unconfigured->deliver({ exception_class => 'RuntimeError' });
    is($unconfigured->last_status, 'failed');
};

subtest 'says why a delivery was not accepted' => sub {
    my @logged;
    my $config = new_configuration('http://secret-key@127.0.0.1:' . $server->{port} . '/status/422');
    $config->{logger} = sub { push @logged, $_[0] };

    ForgeOps::Tracker::Client->new($config)->deliver({ exception_class => 'RuntimeError' });

    is(scalar(@logged), 1);
    like($logged[0], qr/\A\[forge-ops-tracker\] delivery rejected: 422 .*the server will not accept a retry\z/);
};

END { $server->stop if $server }

done_testing;
