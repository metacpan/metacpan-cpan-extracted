use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib", "$Bin/..";
use ForgeOps::Tracker;
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

subtest 'init configures and returns the configuration' => sub {
    ForgeOps::Tracker::_reset_for_testing();
    my $config = ForgeOps::Tracker::init(
        dsn     => 'https://key@tracker.example.com/api/v1/events',
        release => 'abc123',
    );

    is($config->{dsn}, 'https://key@tracker.example.com/api/v1/events');
    is($config->{release}, 'abc123');
};

subtest 'init dies on an unknown configuration property' => sub {
    ForgeOps::Tracker::_reset_for_testing();

    eval { ForgeOps::Tracker::init(not_a_real_setting => 1) };
    like($@, qr/no property/);
};

subtest 'report delivers through the full stack' => sub {
    ForgeOps::Tracker::_reset_for_testing();
    ForgeOps::Tracker::init(
        dsn                  => 'http://key@127.0.0.1:' . $server->{port} . '/api/v1/events',
        enabled_environments => { production => 1 },
        environment          => 'production',
    );

    eval { die "boom\n" };
    ForgeOps::Tracker::report($@);

    ok(wait_until(sub { scalar(@{ $server->requests }) >= 1 }));
    my $requests = $server->requests;
    is($requests->[-1]{headers}{AUTHORIZATION}, 'Bearer key');
};

subtest 'set_user attaches the user to a later report call' => sub {
    ForgeOps::Tracker::_reset_for_testing();
    ForgeOps::Tracker::init(
        dsn                  => 'http://key@127.0.0.1:' . $server->{port} . '/api/v1/events',
        enabled_environments => { production => 1 },
        environment          => 'production',
    );

    # $server (and its requests list) is shared, cumulative across every subtest in this file:
    # wait for the count to grow *past* whatever it already was, not just "at least 1", or this
    # could pass immediately against an earlier subtest's already-delivered request instead of
    # this one's own.
    my $before = scalar(@{ $server->requests });
    ForgeOps::Tracker::set_user(id => 42, email => 'alice@example.com');
    eval { die "boom\n" };
    ForgeOps::Tracker::report($@);

    ok(wait_until(sub { scalar(@{ $server->requests }) > $before }));
    my $requests = $server->requests;
    like($requests->[-1]{body}, qr/alice\@example\.com/);
};

subtest 'an explicit user argument overrides whatever set_user last set' => sub {
    ForgeOps::Tracker::_reset_for_testing();
    ForgeOps::Tracker::init(
        dsn                  => 'http://key@127.0.0.1:' . $server->{port} . '/api/v1/events',
        enabled_environments => { production => 1 },
        environment          => 'production',
    );

    my $before = scalar(@{ $server->requests });
    ForgeOps::Tracker::set_user(id => 42);
    eval { die "boom\n" };
    ForgeOps::Tracker::report($@, {}, { id => 99 });

    ok(wait_until(sub { scalar(@{ $server->requests }) > $before }));
    my $requests = $server->requests;
    like($requests->[-1]{body}, qr/"id":99/);
};

subtest 'set_user with no arguments clears whatever was set' => sub {
    ForgeOps::Tracker::_reset_for_testing();
    ForgeOps::Tracker::set_user(id => 42);

    ForgeOps::Tracker::set_user();

    is($ForgeOps::Tracker::current_user, undef);
};

sub enable_against_server {
    ForgeOps::Tracker::_reset_for_testing();
    ForgeOps::Tracker::init(
        dsn                  => 'http://key@127.0.0.1:' . $server->{port} . '/api/v1/events',
        enabled_environments => { production => 1 },
        environment          => 'production',
        @_,
    );
}

subtest 'add_breadcrumb attaches the trail to a later report call' => sub {
    enable_against_server();
    my $before = scalar(@{ $server->requests });

    ForgeOps::Tracker::add_breadcrumb('charging card', category => 'payment', data => { order_id => 42 });
    eval { die "boom\n" };
    ForgeOps::Tracker::report($@);

    ok(wait_until(sub { scalar(@{ $server->requests }) > $before }));
    my $body = $server->requests->[-1]{body};
    like($body, qr/charging card/);
    like($body, qr/"category":"payment"/);
};

subtest 'add_breadcrumb defaults to the custom category and info level' => sub {
    enable_against_server();

    ForgeOps::Tracker::add_breadcrumb('something happened');

    my ($crumb) = @ForgeOps::Tracker::current_breadcrumbs;
    is($crumb->{category}, 'custom');
    is($crumb->{level}, 'info');
    like($crumb->{timestamp}, qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/);
    is_deeply($crumb->{data}, {});
};

subtest 'add_breadcrumb does nothing when track_breadcrumbs is off' => sub {
    enable_against_server(track_breadcrumbs => 0);

    ForgeOps::Tracker::add_breadcrumb('should not be recorded');

    is(scalar(@ForgeOps::Tracker::current_breadcrumbs), 0);
};

subtest 'add_breadcrumb caps the trail at max_breadcrumbs, dropping the oldest first' => sub {
    enable_against_server(max_breadcrumbs => 2);

    ForgeOps::Tracker::add_breadcrumb($_) for qw(first second third);

    is_deeply([ map { $_->{message} } @ForgeOps::Tracker::current_breadcrumbs ], [qw(second third)]);
};

subtest 'clear_breadcrumbs empties the trail' => sub {
    enable_against_server();
    ForgeOps::Tracker::add_breadcrumb('first');

    ForgeOps::Tracker::clear_breadcrumbs();

    is(scalar(@ForgeOps::Tracker::current_breadcrumbs), 0);
};

subtest 'a report with an empty trail sends no breadcrumbs key at all' => sub {
    enable_against_server();
    my $before = scalar(@{ $server->requests });

    eval { die "boom\n" };
    ForgeOps::Tracker::report($@);

    ok(wait_until(sub { scalar(@{ $server->requests }) > $before }));
    unlike($server->requests->[-1]{body}, qr/breadcrumbs/);
};

subtest '_reset_for_testing clears the trail' => sub {
    enable_against_server();
    ForgeOps::Tracker::add_breadcrumb('leftover');

    ForgeOps::Tracker::_reset_for_testing();

    is(scalar(@ForgeOps::Tracker::current_breadcrumbs), 0);
};

END { $server->stop if $server }

done_testing;
