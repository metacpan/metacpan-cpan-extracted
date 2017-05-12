#! /usr/bin/perl

use lib 't/lib';
use Time::HiRes qw(usleep);
use Test::More tests => 10;
use strict;
use warnings;

# This test verifies the solution to a bug reported by Carlos Mendioroz.
# Messages received in different packets broke the module.
# Re-wrote the read_port routine in Device::Modbus::TCP to fix it.

BEGIN {
    use_ok 'Device::Modbus::TCP::Client';
    use_ok 'Device::Modbus::TCP::Server';
    use_ok 'Test::Unit';
}

# Fork. Child builds a server who dies after a couple of seconds
$|++;
my $pid = fork;
die "Could not fork: $!" unless defined $pid;
unless ($pid) {
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

# Get the actual binary string to send to the server
my $adu   = $client->new_adu($req);
my $bin   = $adu->binary_message;
my $len   = length $bin;
my $part1 = substr $bin, 0, $len-2;
my $part2 = substr $bin, -2;

sleep 1;

eval {
    # Send request in two parts
    $client->socket->send($part1);
    usleep(1000); # Wait 0.1 seconds
    $client->socket->send($part2);
};
ok !$@, 'Survived sending broken request to forked server';

SKIP : {
    skip "Client just died($@)", 2, if $@;
    
    my $adu = $client->receive_response;
    isa_ok $adu, 'Device::Modbus::TCP::ADU';

    is_deeply $adu->values, [6], 'Value returned from server is correct';

    $client->disconnect;
}

is wait(), $pid, "Waited for child whose pid was $pid" ;

done_testing();
