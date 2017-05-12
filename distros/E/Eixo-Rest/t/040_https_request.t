use t::test_base;

use strict;
use warnings;
use IO::Socket::SSL;
use File::Spec;

my @parts = File::Spec->splitpath(__FILE__);

my $basedir = $parts[1];

my $port = 20000+int(rand(10000));

my $TEST_TEXT = 'Hi, how are you!';

my ($public_cert,$private_cert) = (
    "$basedir/certs/server.pem", 
    "$basedir/certs/server-key.pem"
);

my $ca_file = "$basedir/certs/ca.pem";

&start_server($port, $public_cert, $private_cert, $ca_file);

#
# here starts test definitions, to avoid warnings by the server process
#
plan tests => 3;
use_ok("Eixo::Rest::Client");
use_ok("Eixo::Rest::Api");

my $a =  Eixo::Rest::Client->new(
    "https://localhost:$port",

    ssl_opts => {
        SSL_use_cert => 1,
        verify_hostname => 1,
        SSL_ca_file => $ca_file,
        SSL_cert_file => "$basedir/certs/client.pem",
        SSL_key_file => "$basedir/certs/client-key.pem",
    }
);

ok(
    $a->getSearch(
        PROCESS_DATA => {
            onSuccess => sub {$_[0]}
        },
        __format => 'RAW',
        __implicit_format => 1,
        __callback => sub {$_[0]},

    ) eq $TEST_TEXT,

    "Send a request throught https obtains expected response"

);

done_testing();



sub start_server {
    my ($port, $public_cert, $private_cert, $ca_file) = @_;

    if(my $pid = fork){
        #print "Open socket in 127.0.0.1:$port\n";
        # simple server
        my $srv = IO::Socket::SSL->new(
            LocalAddr => "localhost:$port",
            Listen => 10,
            SSL_server => 1,
            SSL_cert_file => $public_cert,
            SSL_key_file => $private_cert,
            SSL_client_ca_file => $ca_file,
            SSL_ca_file => $ca_file,
        );

        my $con = $srv->accept;

        my $buf = '';

        while(my $lbuf = <$con>){
            $buf .= $lbuf;
            last if $lbuf eq "\r\n";
        }

        my $body = $TEST_TEXT;
        print $con "HTTP/1.1 200 ok\r\nContent-type: text/plain\r\n"
        . "Connection: close\r\n"
        . "Content-length: ".length($body)."\r\n"
        . "\r\n"
        . $body;

        exit(0);
    }
    else{
        sleep(1);
    }

}
