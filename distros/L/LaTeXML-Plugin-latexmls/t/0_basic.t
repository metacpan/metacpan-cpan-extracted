use IO::Socket;
use Test::More;
use File::Which;
use HTTP::Response;
use JSON::XS qw(decode_json);
use IO::Socket::INET;

my $test_address = "localhost";

# pick a random free port for this test, makes parallel testing more robust
my $random_sock = IO::Socket::INET->new(
    Proto     => 'tcp',
    LocalAddr => 'localhost',
);
my $test_port = $random_sock->sockport();
close($random_sock);

# Make sure we have a free socket
my $sock = IO::Socket::INET->new(
  PeerAddr => $test_address,
  PeerPort => $test_port,
  Proto    => 'tcp',
);    #Attempt connecting to a service
ok(!$sock, "latexmls default socket $test_port should be available, but wasn't, failing."); # Should be empty

my $latexmls = "blib/script/latexmls";
# Boot a server
system($latexmls,"--port=$test_port","--address=$test_address",'--expire=2','--timeout=2');
# TODO: Talk to the web service via HTTP
#Setup client and communicate
$sock = IO::Socket::INET->new(
  PeerAddr => $test_address,
  PeerPort => $test_port,
  Proto    => 'tcp',
);    #Attempt connecting to a service

ok($sock, 'latexmls not available after boot'); # socket is up and running

my $test_message = "source=literal:test";
my $test_message_length = length($test_message);
my $test_route = "$test_address:$test_address";
my $payload = <<"PAYLOADEND";
POST $test_route HTTP/1.0
Host: $test_address:$test_address
User-Agent: tester
Content-Type: application/x-www-form-urlencoded
Content-Length: $test_message_length

$test_message
PAYLOADEND
$sock->send($payload);
my $response_string = q{};
{ local $/ = undef;
  $response_string = <$sock>; }
close($sock);

ok($response_string, "did not get a response!");

my $http_response = HTTP::Response->parse($response_string);

ok($http_response->is_success, 'Request did not succeed!');
my $response = decode_json($http_response->content);
ok($response, "JSON payload was malformed.");
($result, $status, $log) = map { $$response{$_} } qw(result status log);

my $expected_xml = <<XML;
<?xml version="1.0" encoding="UTF-8"?>
<?latexml searchpaths=""?>
<?latexml RelaxNGSchema="LaTeXML"?>
<document xmlns="http://dlmf.nist.gov/LaTeXML">
  <resource src="LaTeXML.css" type="text/css"/>
  <para>
    <p>test
</p>
  </para>
</document>
XML

is($expected_xml, $result, 'wrong result');
is("No obvious problems", $status, 'wrong status');
like($log, qr/Status\:conversion\:0/, 'malformed log messages');

done_testing();
