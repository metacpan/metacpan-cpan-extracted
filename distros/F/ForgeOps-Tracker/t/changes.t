use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib", "$Bin/..";
use JSON::PP qw(decode_json encode_json);
use ForgeOps::Tracker;
use ForgeOps::Tracker::Changes;
use ForgeOps::Tracker::Configuration;
use t::lib::EchoServer;

sub wait_until {
    my ($predicate, $timeout) = @_;
    $timeout //= 2;
    my $deadline = time + $timeout;
    while (time < $deadline) {
        return 1 if $predicate->();
        select(undef, undef, undef, 0.02);
    }
    return 0;
}

my $server = t::lib::EchoServer->start;

sub requests_to {
    my ($path) = @_;
    return [ grep { $_->{path} eq $path } @{ $server->requests } ];
}

sub init_enabled {
    my (%overrides) = @_;
    return ForgeOps::Tracker::init(
        dsn                  => 'http://secret-key@127.0.0.1:' . $server->{port} . '/api/v1/events',
        enabled_environments => { production => 1 },
        environment          => 'production',
        %overrides,
    );
}

sub configuration {
    my $config = ForgeOps::Tracker::Configuration->new;
    $config->{environment} = 'production';
    return $config;
}

# record_change

subtest 'record_change posts the full payload to the changes endpoint' => sub {
    ForgeOps::Tracker::_reset_for_testing();
    init_enabled();

    my $queued = ForgeOps::Tracker::record_change(
        kind        => 'feature_flag',
        title       => 'Enabled new_checkout for 10%',
        details     => { flag => 'new_checkout', rollout => 10 },
        service     => 'web',
        actor       => 'luke',
        url         => 'https://flags.example.com/new_checkout',
        id          => 'flag-42',
        occurred_at => 1790337600, # 2026-09-25T12:00:00Z
    );
    is($queued, 1);

    ok(wait_until(sub { @{ requests_to('/api/v1/changes') } >= 1 }));
    my $request = requests_to('/api/v1/changes')->[-1];
    is($request->{headers}{AUTHORIZATION}, 'Bearer secret-key');
    is_deeply(decode_json($request->{body}), {
        kind        => 'feature_flag',
        title       => 'Enabled new_checkout for 10%',
        details     => { flag => 'new_checkout', rollout => 10 },
        environment => 'production',
        service     => 'web',
        actor       => 'luke',
        url         => 'https://flags.example.com/new_checkout',
        id          => 'flag-42',
        occurred_at => '2026-09-25T12:00:00.000Z',
    });
};

subtest 'optional fields are left out and occurred_at defaults to now' => sub {
    my $payload = ForgeOps::Tracker::Changes::build_change(configuration(), kind => 'config', title => 'Raised the timeout');

    is_deeply([ sort keys %$payload ], [qw(details environment kind occurred_at title)]);
    is(encode_json($payload->{details}), '{}');
    like($payload->{occurred_at}, qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z\z/);
    is(ForgeOps::Tracker::Changes::build_change(configuration(), kind => 'config', title => 'x', occurred_at => '2026-09-25T12:00:00Z')->{occurred_at}, '2026-09-25T12:00:00Z');
};

subtest 'an explicit environment overrides the configured one' => sub {
    is(ForgeOps::Tracker::Changes::build_change(configuration(), kind => 'config', title => 'x', environment => 'staging')->{environment}, 'staging');
};

subtest 'every known kind is sent as is, and anything else as other' => sub {
    for my $kind (@ForgeOps::Tracker::Changes::KINDS) {
        is(ForgeOps::Tracker::Changes::build_change(configuration(), kind => $kind, title => 'x')->{kind}, $kind);
    }
    for my $kind ('deploy', '', undef, 'FEATURE_FLAG') {
        is(ForgeOps::Tracker::Changes::build_change(configuration(), kind => $kind, title => 'x')->{kind}, 'other');
    }
};

subtest 'the title is truncated to 200 characters and non-hash details are dropped' => sub {
    my $payload = ForgeOps::Tracker::Changes::build_change(configuration(), kind => 'config', title => 'x' x 300, details => [1, 2]);

    is($payload->{title}, 'x' x 200);
    is_deeply($payload->{details}, {});
};

subtest 'a blank title sends nothing' => sub {
    ForgeOps::Tracker::_reset_for_testing();
    init_enabled();

    is(ForgeOps::Tracker::record_change(kind => 'config', title => '   '), 0);
    is(ForgeOps::Tracker::record_change(kind => 'config'), 0);
};

subtest 'record_change does nothing when the client is not enabled' => sub {
    ForgeOps::Tracker::_reset_for_testing();
    init_enabled(environment => 'development');
    my $before = @{ requests_to('/api/v1/changes') };

    is(ForgeOps::Tracker::record_change(kind => 'config', title => 'Raised the timeout'), 0);
    select(undef, undef, undef, 0.2);
    is(scalar @{ requests_to('/api/v1/changes') }, $before);
};

subtest 'record_change never dies on an error response or an unreachable server' => sub {
    ForgeOps::Tracker::_reset_for_testing();
    ForgeOps::Tracker::init(
        dsn                  => 'http://key@127.0.0.1:1/api/v1/events', # nothing listens on port 1
        enabled_environments => { production => 1 },
        environment          => 'production',
        timeout              => 1,
    );

    my $queued = eval { ForgeOps::Tracker::record_change(kind => 'config', title => 'x') };
    is($@, '');
    is($queued, 1);
    select(undef, undef, undef, 0.2);
};

# Startup snapshot

subtest 'the snapshot has the Perl runtime and no dependencies or env var names by default' => sub {
    my $snapshot = ForgeOps::Tracker::Changes::build_snapshot(configuration());

    is($snapshot->{environment}, 'production');
    is($snapshot->{state}{runtime}, sprintf('perl %vd', $^V));
    ok(!exists $snapshot->{state}{dependencies}, 'no reliable source in Perl, so left out');
    ok(!exists $snapshot->{state}{schema_version});
    ok(!exists $snapshot->{state}{env_var_names});
};

subtest 'env var names, never values, are sent when track_env_var_names is on' => sub {
    my $config = configuration();
    $config->{track_env_var_names} = 1;
    local %ENV = (DATABASE_URL => 'postgres://secret', HOSTNAME => 'web-1', STRIPE_KEY => 'sk_live');

    my $snapshot = ForgeOps::Tracker::Changes::build_snapshot($config);

    is_deeply($snapshot->{state}{env_var_names}, [qw(DATABASE_URL STRIPE_KEY)]);
    unlike(encode_json($snapshot), qr/sk_live|postgres:|web-1/);
};

subtest 'the env var denylist drops host-specific noise and the client\'s own settings' => sub {
    my @names = qw(
        HOSTNAME HOST HOME PATH PWD OLDPWD SHLVL _ TERM USER LOGNAME SHELL LANG LC_ALL LC_CTYPE TMPDIR TZ
        PORT DYNO INVOCATION_ID JOURNAL_STREAM SYSTEMD_EXEC_PID MEMORY_PRESSURE_WATCH KUBERNETES_SERVICE_HOST
        REDIS_SERVICE_HOST REDIS_SERVICE_PORT REDIS_SERVICE_PORT_HTTP REDIS_PORT_6379_TCP REDIS_PORT_6379_TCP_ADDR
        FORGE_OPS_DSN FORGE_OPS_RELEASE SECRET_KEY PLACK_ENV DATABASE_URL
    );

    is_deeply(ForgeOps::Tracker::Changes::env_var_names({ map { $_ => 'value' } @names }), [qw(DATABASE_URL PLACK_ENV SECRET_KEY)]);
};

subtest 'init sends one snapshot to the change_snapshots endpoint, once per process' => sub {
    ForgeOps::Tracker::_reset_for_testing(change_snapshot => 1);
    my $before = @{ requests_to('/api/v1/change_snapshots') };

    init_enabled();
    init_enabled();

    ok(wait_until(sub { @{ requests_to('/api/v1/change_snapshots') } > $before }));
    my $request = requests_to('/api/v1/change_snapshots')->[-1];
    is($request->{headers}{AUTHORIZATION}, 'Bearer secret-key');
    my $body = decode_json($request->{body});
    is($body->{environment}, 'production');
    is($body->{state}{runtime}, sprintf('perl %vd', $^V));

    select(undef, undef, undef, 0.2);
    is(scalar @{ requests_to('/api/v1/change_snapshots') }, $before + 1, 'not once per init()');
};

subtest 'detect_changes => 0 sends no snapshot' => sub {
    ForgeOps::Tracker::_reset_for_testing(change_snapshot => 1);
    my $before = @{ requests_to('/api/v1/change_snapshots') };

    init_enabled(detect_changes => 0);

    select(undef, undef, undef, 0.2);
    is(scalar @{ requests_to('/api/v1/change_snapshots') }, $before);
};

subtest 'no snapshot is sent when the client is not enabled' => sub {
    ForgeOps::Tracker::_reset_for_testing(change_snapshot => 1);
    my $before = @{ requests_to('/api/v1/change_snapshots') };

    init_enabled(environment => 'development');

    select(undef, undef, undef, 0.2);
    is(scalar @{ requests_to('/api/v1/change_snapshots') }, $before);
};

subtest 'a failing snapshot never dies' => sub {
    ForgeOps::Tracker::_reset_for_testing(change_snapshot => 1);

    eval {
        ForgeOps::Tracker::init(
            dsn                  => 'http://key@127.0.0.1:1/api/v1/events',
            enabled_environments => { production => 1 },
            environment          => 'production',
            timeout              => 1,
        );
    };
    is($@, '');
    select(undef, undef, undef, 0.2);
};

ForgeOps::Tracker::_reset_for_testing();
END { $server->stop if $server }
done_testing;
