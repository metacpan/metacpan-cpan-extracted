#!/usr/bin/env perl
use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Fugu::TestLog;

use_ok('Fugu::MQTT');

# Test MQTT client creation
{
    my $mqtt = Fugu::MQTT->new(
        host => '192.168.1.100',
        port => 1883,
    );
    
    ok(defined $mqtt, 'MQTT client created');
    isa_ok($mqtt, 'Fugu::MQTT');
    is($mqtt->{host}, '192.168.1.100', 'Host set correctly');
    is($mqtt->{port}, 1883, 'Port set correctly');
}

# Test default values
{
    my $mqtt = Fugu::MQTT->new();
    
    is($mqtt->{host}, '127.0.0.1', 'Default host is localhost');
    is($mqtt->{port}, 1883, 'Default port is 1883');
    ok(!$mqtt->{connected}, 'Not connected by default');
}

# Test with credentials
{
    my $mqtt = Fugu::MQTT->new(
        host => 'broker.example.com',
        port => 8883,
        username => 'testuser',
        password => 'testpass',
    );
    
    is($mqtt->{username}, 'testuser', 'Username stored');
    is($mqtt->{password}, 'testpass', 'Password stored');
}

# Test subscription storage
{
    my $mqtt = Fugu::MQTT->new();
    
    my $callback_called = 0;
    my $callback = sub { $callback_called = 1 };
    
    $mqtt->subscribe('test/topic', $callback);
    
    ok(exists $mqtt->{subscriptions}{'test/topic'}, 'Subscription stored');
    is(ref $mqtt->{subscriptions}{'test/topic'}, 'CODE', 'Callback is code ref');
}

# Test multiple subscriptions
{
    my $mqtt = Fugu::MQTT->new();
    
    $mqtt->subscribe('topic1', sub { });
    $mqtt->subscribe('topic2', sub { });
    $mqtt->subscribe('topic3', sub { });
    
    is(scalar keys %{$mqtt->{subscriptions}}, 3, 'Three subscriptions stored');
}

# Test is_connected
{
    my $mqtt = Fugu::MQTT->new();
    
    ok(!$mqtt->is_connected(), 'Not connected initially');
    
    $mqtt->{connected} = 1;
    ok($mqtt->is_connected(), 'Connected after flag set');
}

# Test disconnect
{
    my $mqtt = Fugu::MQTT->new();
    
    $mqtt->{connected} = 1;
    $mqtt->{client} = 'dummy';
    
    $mqtt->disconnect();
    
    ok(!$mqtt->is_connected(), 'Not connected after disconnect');
    ok(!defined $mqtt->{client}, 'Client cleared');
}

# Test connect without Net::MQTT::Simple
SKIP: {
    skip 'Net::MQTT::Simple may be installed', 1 if eval { require Net::MQTT::Simple; 1 };
    
    my $mqtt = Fugu::MQTT->new();
    my $result = $mqtt->mqtt_connect();
    
    ok(!$result, 'Connect fails without Net::MQTT::Simple');
}

# Test publish when not connected
{
    my $mqtt = Fugu::MQTT->new();
    
    # The publish must not die. It returns early.
    eval {
        $mqtt->publish('test/topic', 'test payload');
    };
    ok(!$@, 'Publish when not connected does not die');
}

# Test topic matching: exact match
{
    my $mqtt = Fugu::MQTT->new();
    
    ok($mqtt->_topic_matches('stat/device/POWER', 'stat/device/POWER'),
        'Exact topic match');
    ok(!$mqtt->_topic_matches('stat/device/POWER', 'stat/device/RESULT'),
        'Different topic no match');
}

# Test topic matching: single level wildcard (+)
{
    my $mqtt = Fugu::MQTT->new();
    
    ok($mqtt->_topic_matches('stat/+/POWER', 'stat/device1/POWER'),
        'Single wildcard matches');
    ok($mqtt->_topic_matches('stat/+/POWER', 'stat/device2/POWER'),
        'Single wildcard matches different device');
    ok(!$mqtt->_topic_matches('stat/+/POWER', 'stat/device1/RESULT'),
        'Single wildcard requires rest to match');
    ok(!$mqtt->_topic_matches('stat/+/POWER', 'stat/a/b/POWER'),
        'Single wildcard only matches one level');
}

# Test topic matching: multi level wildcard (#)
{
    my $mqtt = Fugu::MQTT->new();
    
    ok($mqtt->_topic_matches('tele/#', 'tele/device/SENSOR'),
        'Multi wildcard matches');
    ok($mqtt->_topic_matches('tele/#', 'tele/device/sub/SENSOR'),
        'Multi wildcard matches multiple levels');
    ok($mqtt->_topic_matches('tele/device/#', 'tele/device/SENSOR'),
        'Multi wildcard at end');
    ok(!$mqtt->_topic_matches('stat/#', 'tele/device/SENSOR'),
        'Multi wildcard prefix must match');
}

# Test topic matching: combined wildcards
{
    my $mqtt = Fugu::MQTT->new();
    
    ok($mqtt->_topic_matches('+/+/SENSOR', 'tele/device/SENSOR'),
        'Multiple single wildcards');
    ok($mqtt->_topic_matches('stat/+/#', 'stat/device/POWER'),
        'Single then multi wildcard');
    ok($mqtt->_topic_matches('stat/+/#', 'stat/device/sub/level/POWER'),
        'Single then multi wildcard multiple levels');
}

# Test subscriptions accessor
{
    my $mqtt = Fugu::MQTT->new();
    
    $mqtt->subscribe('topic1', sub { });
    $mqtt->subscribe('topic2', sub { });
    
    my @topics = sort $mqtt->subscriptions();
    is_deeply(\@topics, ['topic1', 'topic2'], 'subscriptions() returns topics');
}

# Test message dispatch
{
    my $mqtt = Fugu::MQTT->new();
    
    my $received_topic;
    my $received_payload;
    $mqtt->subscribe('stat/device/POWER', sub($topic, $payload) {
        $received_topic = $topic;
        $received_payload = $payload;
    });
    
    my $count = $mqtt->_dispatch_message('stat/device/POWER', 'ON');
    
    is($count, 1, 'One callback dispatched');
    is($received_topic, 'stat/device/POWER', 'Topic passed to callback');
    is($received_payload, 'ON', 'Payload passed to callback');
}

# Test message dispatch with wildcard
{
    my $mqtt = Fugu::MQTT->new();
    
    my @received;
    $mqtt->subscribe('stat/+/POWER', sub($topic, $payload) {
        push @received, { topic => $topic, payload => $payload };
    });
    
    $mqtt->_dispatch_message('stat/device1/POWER', 'ON');
    $mqtt->_dispatch_message('stat/device2/POWER', 'OFF');
    
    is(scalar @received, 2, 'Two messages dispatched');
    is($received[0]{topic}, 'stat/device1/POWER', 'First topic correct');
    is($received[0]{payload}, 'ON', 'First payload correct');
    is($received[1]{topic}, 'stat/device2/POWER', 'Second topic correct');
    is($received[1]{payload}, 'OFF', 'Second payload correct');
}

# Test tick when not connected
{
    my $mqtt = Fugu::MQTT->new();

    my $result = $mqtt->tick();
    is($result, 0, 'tick returns 0 when not connected');
}

# The internal buffer callback that the module registers with
# Net::MQTT::Simple must accept extra arguments. Since 1.33 the
# library passes a retain flag as a third argument. A two-argument
# signature dies on every incoming message. The integration suite
# found this regression.
{
    package StubMQTTClient;

    sub new($class) { bless { callbacks => {} }, $class }

    sub subscribe($self, $topic, $callback)
    {
        $self->{callbacks}{$topic} = $callback;
    }

    package main;

    my $mqtt = Fugu::MQTT->new();
    my $stub = StubMQTTClient->new;
    $mqtt->{client}    = $stub;
    $mqtt->{connected} = 1;

    $mqtt->subscribe('stat/device/POWER', sub($topic, $payload) { });
    my $internal = $stub->{callbacks}{'stat/device/POWER'};
    ok(defined $internal, 'internal callback registered with the client');

    my $lived = eval { $internal->('stat/device/POWER', 'ON', 1); 1 };
    ok($lived, 'internal callback accepts a third (retain) argument')
        or diag($@);
    is_deeply($mqtt->{pending_messages},
        [['stat/device/POWER', 'ON']],
        'message buffered without the retain flag');

    # A resubscribe registers the callbacks again. They also accept
    # a third argument.
    $mqtt->{pending_messages} = [];
    $stub->{callbacks}        = {};
    $mqtt->resubscribe();
    $internal = $stub->{callbacks}{'stat/device/POWER'};
    $lived = eval { $internal->('stat/device/POWER', 'OFF', 0); 1 };
    ok($lived, 'resubscribed callback accepts a third argument')
        or diag($@);
}

# Test disconnect clears pending messages
{
    my $mqtt = Fugu::MQTT->new();
    
    push @{$mqtt->{pending_messages}}, ['topic', 'payload'];
    $mqtt->disconnect();
    
    is(scalar @{$mqtt->{pending_messages}}, 0, 'Pending messages cleared on disconnect');
}

# Test warning capture during connection attempts
SKIP: {
    skip 'Net::MQTT::Simple not available', 2 unless eval { require Net::MQTT::Simple; 1 };
    
    my $mqtt = Fugu::MQTT->new(
        host => '192.0.2.1',  # TEST-NET-1, always unreachable
        port => 9999,
    );
    
    # Capture STDERR to make sure that no warnings leak through
    my $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr or die "Cannot redirect STDERR: $!";
        
        # Try to connect with a short timeout. The attempt must
        # fail silently.
        $mqtt->mqtt_connect(1);
    }
    
    # No warnings must leak to STDERR. The module logs them instead.
    ok(!$stderr, 'Connection failures do not print to STDERR')
        or diag("Leaked to STDERR: $stderr");
    
    # Note: the connect can succeed or fail, because 192.0.2.1:9999
    # can be reachable or not. Thus the test only makes sure that
    # the warnings are captured.
    pass('Connection attempt completed');
}

done_testing();
