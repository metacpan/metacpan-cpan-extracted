use strict;
use warnings;
use threads;
use threads::shared;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib", "$Bin/..";
use JSON::PP;
use ForgeOps::Tracker;
use ForgeOps::Tracker::Configuration;
use ForgeOps::Tracker::MetricBuffer;
use t::lib::EchoServer;

sub new_configuration {
    my $config = ForgeOps::Tracker::Configuration->new;
    $config->{dsn} = 'https://key@tracker.example.com/api/v1/events';
    $config->{enabled_environments} = { production => 1 };
    $config->{environment} = 'production';
    $config->{release} = '1.2.3';
    $config->{server_name} = 'web-1';
    return $config;
}

# A delivery function that records each batch (as a JSON string, so it can cross the thread boundary)
# into a shared array and answers with whatever the shared outcome list says (true once it runs out).
sub recording_buffer {
    my ($delivered, $outcomes) = @_;
    my $buffer = ForgeOps::Tracker::MetricBuffer->new(
        new_configuration(),
        sub {
            my ($entries) = @_;
            lock(@$delivered);
            push @$delivered, JSON::PP::encode_json([ map { $_->{metric_name} } @$entries ]);
            return @$outcomes ? shift(@$outcomes) : 1;
        },
        sub { 3600 },
    );
    return $buffer;
}

subtest 'delivers every entry as one batch, stamped with a seconds-precision UTC recorded_at' => sub {
    my (@delivered, @outcomes) :shared;
    my $seen_stamp :shared;
    my $buffer = ForgeOps::Tracker::MetricBuffer->new(
        new_configuration(),
        sub { my ($entries) = @_; lock(@delivered); push @delivered, scalar(@$entries); $seen_stamp = $entries->[0]{recorded_at}; 1 },
        sub { 3600 },
    );
    ok($buffer->record({ metric_name => 'signup', value => 1 }));
    ok($buffer->record({ metric_name => 'payment', value => 49.5 }));
    $buffer->flush;

    is_deeply([@delivered], [2]);
    like($seen_stamp, qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/);
    $buffer->_clear;
};

subtest 'keeps a negative value, drops NaN, infinite and non-numeric ones' => sub {
    my (@delivered, @outcomes) :shared;
    my $buffer = recording_buffer(\@delivered, \@outcomes);
    ok($buffer->record({ metric_name => 'refund', value => -12 }), 'a refund is a real metric');
    ok(!$buffer->record({ metric_name => 'nan', value => 'NaN' }));
    ok(!$buffer->record({ metric_name => 'inf', value => 'Inf' }));
    ok(!$buffer->record({ metric_name => 'str', value => 'twelve' }));
    ok(!$buffer->record({ metric_name => 'undef', value => undef }));
    ok($buffer->record({ metric_name => 'sci', value => '1.5e3' }));
    is($buffer->count, 2);
    $buffer->_clear;
};

subtest 'a failed delivery keeps every entry for the next flush' => sub {
    my (@delivered, @outcomes) :shared;
    push @outcomes, 0, 1;
    my $buffer = recording_buffer(\@delivered, \@outcomes);
    $buffer->record({ metric_name => 'a', value => 1 });
    $buffer->flush;
    $buffer->record({ metric_name => 'b', value => 2 });
    $buffer->flush;
    $buffer->flush; # nothing left: no third delivery

    is_deeply([@delivered], ['["a"]', '["a","b"]']);
    $buffer->_clear;
};

subtest 'an entry recorded while delivery is in flight is never lost' => sub {
    my (@delivered, @outcomes) :shared;
    my ($in_flight, $release) :shared;
    $in_flight = 0;
    $release = 0;
    my $buffer = ForgeOps::Tracker::MetricBuffer->new(
        new_configuration(),
        sub {
            my ($entries) = @_;
            {
                lock(@delivered);
                push @delivered, JSON::PP::encode_json([ map { $_->{metric_name} } @$entries ]);
            }
            if (@delivered == 1) {
                lock($in_flight);
                $in_flight = 1;
                cond_signal($in_flight);
            }
            if (@delivered == 1) {
                lock($release);
                cond_wait($release) until $release;
            }
            return 1;
        },
        sub { 3600 },
    );

    $buffer->record({ metric_name => 'first', value => 1 });
    my $flushing = threads->create(sub { $buffer->flush });
    { lock($in_flight); cond_wait($in_flight) until $in_flight; }
    $buffer->record({ metric_name => 'during', value => 2 });
    { lock($release); $release = 1; cond_signal($release); }
    $flushing->join;
    $buffer->flush;

    is_deeply([@delivered], ['["first"]', '["during"]']);
    $buffer->_clear;
};

subtest 'is capped and drops further entries until a flush succeeds' => sub {
    my (@delivered, @outcomes) :shared;
    my $buffer = ForgeOps::Tracker::MetricBuffer->new(new_configuration(), sub { 0 }, sub { 3600 });
    my $accepted = 0;
    $accepted += $buffer->record({ metric_name => 'm', value => 1 }) for 1 .. ForgeOps::Tracker::MetricBuffer::MAX_ENTRIES + 50;
    is($accepted, ForgeOps::Tracker::MetricBuffer::MAX_ENTRIES);
    $buffer->_clear;
};

subtest 'the metric uris swap the trailing /events segment' => sub {
    my $config = new_configuration();
    is($config->custom_metrics_uri, 'https://tracker.example.com/api/v1/custom_metrics');
    is($config->infrastructure_metrics_uri, 'https://tracker.example.com/api/v1/infrastructure_metrics');
};

subtest 'capture_metric and capture_infrastructure_metric deliver to their own endpoints end to end' => sub {
    my $server = t::lib::EchoServer->start;
    ForgeOps::Tracker::_reset_for_testing();
    ForgeOps::Tracker::init(
        dsn                  => 'http://key@127.0.0.1:' . $server->{port} . '/api/v1/events',
        environment          => 'production',
        release              => 'a1b2c3d',
        enabled_environments => { production => 1 },
        server_name          => 'web-1',
    );
    ForgeOps::Tracker::capture_metric('signup');
    ForgeOps::Tracker::capture_metric('payment', 49);
    ForgeOps::Tracker::capture_infrastructure_metric('cpu', 0.42, hostname => 'db-1');
    ForgeOps::Tracker::capture_infrastructure_metric('memory', 0.7);
    ForgeOps::Tracker::flush_metrics();

    my %by_path = map { $_->{path} => $_ } @{ $server->requests };
    my $custom = $by_path{'/api/v1/custom_metrics'};
    is($custom->{headers}{AUTHORIZATION}, 'Bearer key');
    my $body = JSON::PP::decode_json($custom->{body});
    is_deeply([ map { $_->{metric_name} } @{ $body->{metrics} } ], ['signup', 'payment']);
    is($body->{metrics}[0]{value}, 1);
    is($body->{metrics}[1]{value}, 49);
    is($body->{metrics}[0]{environment}, 'production');
    is($body->{metrics}[0]{release}, 'a1b2c3d');
    my $infrastructure = JSON::PP::decode_json($by_path{'/api/v1/infrastructure_metrics'}{body})->{metrics};
    is($infrastructure->[0]{hostname}, 'db-1');
    is($infrastructure->[1]{hostname}, 'web-1');
    ForgeOps::Tracker::_reset_for_testing();
    $server->stop;
};

subtest 'is a no-op when the client is not enabled' => sub {
    ForgeOps::Tracker::_reset_for_testing();
    ForgeOps::Tracker::init(dsn => 'https://key@tracker.example.com/api/v1/events', environment => 'development');
    ForgeOps::Tracker::capture_metric('signup');
    ForgeOps::Tracker::capture_infrastructure_metric('cpu', 1);
    ForgeOps::Tracker::flush_metrics();
    pass('nothing was buffered or sent');
    ForgeOps::Tracker::_reset_for_testing();
};

subtest 'a script that captures a reading and just ends still delivers it from its END block' => sub {
    my $server = t::lib::EchoServer->start;
    my $script = qq{
        use lib "$Bin/../lib";
        use ForgeOps::Tracker;
        ForgeOps::Tracker::init(
            dsn => 'http://key\@127.0.0.1:$server->{port}/api/v1/events',
            environment => 'production',
            enabled_environments => { production => 1 },
        );
        ForgeOps::Tracker::capture_infrastructure_metric('cpu', 0.5, hostname => 'cron-1');
    };
    system($^X, '-e', $script) == 0 or diag("child exit: $?");

    my ($request) = grep { $_->{path} eq '/api/v1/infrastructure_metrics' } @{ $server->requests };
    ok($request, 'the reading arrived');
    is(JSON::PP::decode_json($request->{body})->{metrics}[0]{hostname}, 'cron-1');
    $server->stop;
};

done_testing;
