#!perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/testmodule.t'

use HTTP::Daemon::SSL;
use HTTP::Status;
eval {require "t/ssl_settings.req";} ||
eval {require "ssl_settings.req";};

$numtests = 9;
$|=1;
$SIG{PIPE}='IGNORE';

foreach ($^O) {
    if (/MacOS/ or /VOS/ or /vmesa/ or /riscos/ or /amigaos/) {
	print "1..0 # Skipped: fork not implemented on this platform\n";
	exit;
    }
}

print "1..$numtests\n";

$test = 0;

unless (fork) {
    sleep 1;

    my $client = new IO::Socket::INET(PeerAddr => $SSL_SERVER_ADDR,
				      PeerPort => $SSL_SERVER_PORT);

    print $client "GET / HTTP/1.0\r\n\r\n";
    (<$client> eq "HTTP/1.1 400 Bad Request\r\n") || print "not ";
    &ok("client bad connection test");
    my @ary = <$client>;
    close $client;

    $client = new IO::Socket::SSL(PeerAddr => $SSL_SERVER_ADDR,
				  PeerPort => $SSL_SERVER_PORT,
				  SSL_verify_mode => 0x01,
				  SSL_ca_file => "certs/test-ca.pem");

    $client || (print("not ok #client failure\n") && exit);
    &ok("client good connection test");

    print $client "GET /foo HTTP/1.0\r\n\r\n";

    (<$client> eq "HTTP/1.1 403 Forbidden\r\n") || print "not ";
    &ok("client permission test");
    @ary = <$client>;

    exit(0);
}


my $server = new HTTP::Daemon::SSL(LocalPort => $SSL_SERVER_PORT,
				   LocalAddr => $SSL_SERVER_ADDR,
				   Listen => 5,
				   Timeout => 30,
				   ReuseAddr => 1,
				   SSL_verify_mode => 0x00,
				   SSL_ca_file => "certs/test-ca.pem",
				   SSL_cert_file => "certs/server-cert.pem");

if (!$server) {
    print "not ok $test\n";
    exit;
}
&ok("server init");

print "not " if (!defined fileno($server));
&ok("server fileno");

print "not " unless ($server->url =~ m!^https:!);
&ok("server url test");

my $conn;
if (!($conn = $server->accept)) {
    # first client request is a bad request
    &ok("bad request handled");
} else {
    print "not ok $test # bad request returned a socket\n";
}

if ($conn = $server->accept) {
    &ok("valid request handled");
} else {
    print "not ok $test # valid request did not return a socket\n";
}

my $r = $conn->get_request();

unless ($r->method eq 'GET' and $r->url->path eq '/foo') {
    print "not ";
}
&ok("server method processing");

$conn->send_error(RC_FORBIDDEN);

close $conn;
wait;

sub ok {
    print "ok #$_[0] ", ++$test, "\n"; 
}
