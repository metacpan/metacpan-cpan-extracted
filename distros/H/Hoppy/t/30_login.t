use strict;
use warnings;
use Test::More tests => 2;
use Hoppy;
use Hoppy::Formatter::JSON;
use IO::Socket;

if ( my $pid = fork ) {
    sleep 1;
    my $socket = IO::Socket::INET->new(
        PeerAddr => 'localhost',
        PeerPort => '10000',
        Proto    => 'tcp',
    );
    my $data      = { method => "login", params => { user_id => "miki" }, id => int rand(100) };
    my $formatter = Hoppy::Formatter::JSON->new;
    my $json      = $formatter->serialize($data);
    $socket->send( $json . "\n" );
    $socket->flush();
    my $buf    = <$socket>;
    my $result = $formatter->deserialize($buf);
    is( ref $result->{result},         'HASH', "login ok" );
    is( $result->{result}->{login_id}, 'miki', "login_id ok" );
    $socket->close;
    wait;
}
elsif ( defined $pid ) {
    my $server = Hoppy->new( config => { alias => "server", test => 2 } );
    POE::Session->create(
        inline_states => {
            _start => sub {
                POE::Kernel->delay_add( "done", 2 );
            },
            done => sub {
                $server->stop;
            },
        },
    );
    $server->start;
}
else {
}