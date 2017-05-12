use Test::More tests => 6;
use strict;
use Measure::Everything::Adapter;
use Measure::Everything qw($stats);
use Sys::Hostname;
use IO::Socket::INET;
use IO::Select;

my $time     = time * 1E09;
my $hostname = hostname();

server_ok(
    'single measurement',
    "test.measurement value=1000i $time",
    [ 'test.measurement' => 1000 => {} => $time ]
);

server_ok(
    'tagged measurement',
    "test.measurement,hostname=$hostname value=1000i $time",
    [ 'test.measurement' => 1000 => { hostname => $hostname } => $time ]
);

server_ok(
    'multi-tagged measurement',
    "test.measurement,hostname=$hostname,instance=1 value=1000i $time",
    [ 'test.measurement' => 1000 => { hostname => $hostname, instance => 1 } =>
        $time ]
);

server_ok(
    'multiple measurements',
    "test.measurement a=1000i,b=2000i $time",
    [ 'test.measurement' => { a => 1000, b => 2000 } => $time ]
);

server_ok(
    'multiple measurements, empty tag',
    "test.measurement a=1000i,b=2000i $time",
    [ 'test.measurement' => { a => 1000, b => 2000 } => {} => $time ]
);

server_ok(
    'multiple tagged measurements',
    "test.measurement,hostname=$hostname a=1000i,b=2000i $time",
    [ 'test.measurement' => { a => 1000, b => 2000 } =>
        { hostname => $hostname } => $time ]
);


sub server_ok {
    my ( $name, $expected, $args ) = @_;
    my $pid;
    my $server
        = IO::Socket::INET->new( LocalAddr => '127.0.0.1', Proto => 'udp' );
    my $port = $server->sockport();
    if ( $pid = fork() ) {
        my $buf;
        my $select = IO::Select->new($server);
        my @ready = $select->can_read(5);
        if(scalar(@ready)) {
        $server->recv( $buf, 1024 );
        is( $buf, $expected, $name );
        } else {
            fail("$name: recv timeout");
        }
    }
    elsif ( defined($pid) ) {
        Measure::Everything::Adapter->set(
            'InfluxDB::UDP',
            host => '127.0.0.1',
            port => $port,
        );
        sleep(1);
        $stats->write(@{$args});
        exit;
    }
    else {
        die;
    }
}


done_testing();
