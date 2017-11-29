use warnings;
use strict;
use Test::More tests => 10;

use AnyEvent::HTTPD;
use JSON::RPC2::AnyEvent::Server;
use JSON::RPC2::AnyEvent::Server::Handle; # Add `dispatch_fh' method in JSON::RPC2::AnyEvent::Server
use IO::Socket::INET;
use JSON::XS;

use JSON::RPC2::AnyEvent::Client;

my $HOST = "127.0.0.1";
my $PORT = 5554;

my $sock = IO::Socket::INET->new( LocalAddr => $HOST );
$PORT = $sock->sockport();
undef $sock;

my $cv = AE::cv;

my $httpd = AnyEvent::HTTPD->new( port => $PORT );

my $srv = JSON::RPC2::AnyEvent::Server->new(
    test_fn => sub{
        my ( $cv, $args ) = @_;
        pass( 'remote function call on server' );
        my $one = $args->[0] + 1;
        my $two = $args->[1] - 1;
        cmp_ok( $one, '==', '1', 'check first param on server' );
        cmp_ok( $two, '==', '2', 'check second param on server' );
        $cv->send( { one => $one, two => $two } );
    }
);
isa_ok $srv, 'JSON::RPC2::AnyEvent::Server', 'new object';

$httpd->reg_cb(
   '/' => sub {
      my ( $httpd, $req ) = @_;
      pass( 'incoming accepted' );
      my $cv = $srv->dispatch( decode_json( $req->content ) );
      $cv->cb( sub {
         my ($cv) = @_;
         $req->respond( {
            content => [ 'application/json-rpc', encode_json( $cv->recv ) ]
         } );
      } );
   },
);

my $rpc;

my $tm = AE::timer( 2, 0, sub {
    $rpc = JSON::RPC2::AnyEvent::Client->new(
        url => "http://$HOST:$PORT/",
    );
    pass( 'start rpc call' );
    $rpc->test_fn( 0, 3, sub{
        my ( $fail, $result, $error ) = @_;
        ok( ! $fail && ! $error, 'check result arrival status on client' );
        cmp_ok( $result->{one}, '==', '1', 'check first result element on client' );
        cmp_ok( $result->{two}, '==', '2', 'check second result element on client' );
        $cv->send("OK");
    });
});

my $wd = AE::timer( 5, 0, sub { $cv->send('watch dog timeout') } );

is( $cv->recv, "OK", "successfully complete");

$rpc->destroy;

$cv = AE::cv; $wd = AE::timer( 5, 0, sub { $cv->send('OK') } ); $cv->recv;


done_testing();
