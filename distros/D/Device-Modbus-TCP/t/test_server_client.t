#! /usr/bin/perl

use lib 't/lib';
use Test::More tests => 17;
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus::TCP::Client';
    use_ok 'Device::Modbus::TCP::Server';
    use_ok 'Test::Unit';
}

# Fork. Child builds a server who dies after a couple of seconds
$|++;
my $pid = fork;
unless (defined $pid && $pid) {
    # We are the child. Start a server.
    # Send an alarm signal in two seconds.
    # Then, send a SIGINT to stop the server.
    $SIG{ALRM} = sub { kill 2, $$ };
    alarm(2);

    my $unit   = Test::Unit->new( id => 3 );
    my $server = Device::Modbus::TCP::Server->new(
        port              => 6545,
        log_level         => 4,
        log_file          => "/tmp/log$$",
        server_type       => ['PreFork'],
        min_servers       => 5,
        max_servers       => 10,
        min_spare_servers => 1,
        max_spare_servers => 5,
        max_requests      => 1000,
    );
    $server->add_server_unit($unit);
    $server->start;
}

# The parent is the client. Send requests and evaluate responses.
ok $pid, "Test forked, and server started on PID $pid";

my $client = Device::Modbus::TCP::Client->new( port => 6545 );
isa_ok $client, 'Device::Modbus::Client';

my $req = $client->read_holding_registers(
    unit     => 3,
    address  => 2,
    quantity => 1
);
isa_ok $req, 'Device::Modbus::Request';

sleep 1;

eval {
    $client->send_request($req);
};
ok !$@, 'Survived sending request to forked server';

SKIP : {
    skip "Client just died($@)", 2, if $@;
    
    my $adu = $client->receive_response;
    isa_ok $adu, 'Device::Modbus::TCP::ADU';

    is_deeply $adu->values, [6], 'Value returned from server is correct';

    $client->disconnect;
}

is wait(), $pid, "Waited for child whose pid was $pid" ;

# Now check the log of the server. Pull everything into a variable
my $log;
{
    local $/ = undef;
    open my $server_log, '<', "/tmp/log$pid"
        or die "Unable to open log file: $!";
    $log = <$server_log>;
    close $server_log;
}

like $log, qr/Device::Modbus::TCP::Server .*? starting!/,
    'Server logged its starting line';
like $log, qr/^Binding to TCP port 6545/m,
    'Logged port binding step';
like $log, qr/^Starting "5" children/m,
    'Logged the default number of preforked children';
like $log, qr/^Received message from 127.0.0.1/m,
    'Logged the reception of our message';
like $log, qr/<holding_registers> address: <2> quantity: <1>/,
    'Message interpreted correctly';
like $log, qr/^Match was successful/m,
    'Match succeeded';
like $log, qr/Server closing!$/m,
    'Server closed';


done_testing();
