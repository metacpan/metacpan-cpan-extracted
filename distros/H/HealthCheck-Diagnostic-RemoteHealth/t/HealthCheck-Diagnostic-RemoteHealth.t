use Test2::V0 -target => 'HealthCheck::Diagnostic::RemoteHealth',
    qw< field hash is match mock done_testing >;
use JSON;
use LWP::Protocol::http;

sub mock_web_request {
    my ( %params ) = @_;
    my $res           = $params{response} || { status => 'OK', info => 'Ok!' };
    my $json_response = ref($res) eq 'HASH' ? encode_json($res) : $res;
    my $mock = mock 'LWP::Protocol::http' => (
        override => [
            request => sub {
                die $params{die} if $params{die};
                # Borrowed and mocked from here:
                # http://metacpan.org/source/OALDERS/libwww-perl-6.39/lib/LWP/Protocol/http.pm#L440
                my $response = HTTP::Response->new($params{code} || 200);
                $response->{_content} = $json_response;
                return $response;
            }
        ]
    );
    return $mock;
}

my $hc = HealthCheck::Diagnostic::RemoteHealth->new(
    url => 'http://foo.test/healthz'
);

my $mock_web = mock_web_request();
my $res      = $hc->check;

is $res, hash {
    field status  => 'OK';
    field id      => 'remotehealth'; 
    field label   => 'RemoteHealth';
    field results => [
        { status => 'OK', info => match(qr/^Request took [\d.e\-]+ seconds?/) },
        { status => 'OK', info => 'Ok!' },
    ];
}, 'Expected OK HealthCheck from 200 HTTP Response.';

$mock_web = mock_web_request(code => 503);
$res      = $hc->check;

is $res, hash {
    field status  => 'OK';
    field id      => 'remotehealth'; 
    field label   => 'RemoteHealth';
    field results => [
        { status => 'OK', info => match(qr/^Request took [\d.e\-]+ seconds?/) },
        { status => 'OK', info => 'Ok!' },
    ];
}, 'Expected OK HealthCheck from 503 HTTP Response.';

$mock_web = mock_web_request(
    response => { status => 'CRITICAL', info => 'Ouch!'}
);
$res      = $hc->check;

is $res, hash {
    field status  => 'CRITICAL';
    field id      => 'remotehealth'; 
    field label   => 'RemoteHealth';
    field results => [
        { status => 'OK', info => match(qr/^Request took [\d.e\-]+ seconds?/) },
        { status => 'CRITICAL', info => 'Ouch!' },
    ];
}, 'Expected CRITICAL HealthCheck from JSON object with CRITICAL status.';

$mock_web = mock_web_request(die => 'I have died!');
$res      = $hc->check;

is $res, hash {
    field status  => 'CRITICAL';
    field info    => match(qr/^User Agent returned: I have died!; Request took [\d.e\-]+ seconds?/);
    field id      => 'remotehealth'; 
    field label   => 'RemoteHealth';
    field results => [
        { status => 'CRITICAL', info => 'User Agent returned: I have died!' },
        { status => 'OK', info => match(qr/^Request took [\d.e\-]+ seconds?/) },
    ];
}, 'Expected CRITICAL status from web request that dies.';

$mock_web = mock_web_request(response => 'Not a valid JSON Object.');
$res      = $hc->check;

is $res, hash {
    field status  => 'CRITICAL';
    field id      => 'remotehealth'; 
    field label   => 'RemoteHealth';
    field results => [
        { status => 'OK', info => match(qr/^Request took [\d.e\-]+ seconds?/) },
        { status => 'CRITICAL', info => 'Could not decode JSON.', data => 'Not a valid JSON Object.' },
    ];
}, 'Expected CRITICAL status when it cannot decode JSON.';

$mock_web = mock_web_request(code => 400);
$res      = $hc->check;

is $res, hash {
    field status  => 'CRITICAL';
    field info    => match(qr{^\QRequested http://foo.test/healthz and got status code 400, expected 200, 503;\E Request took [\d.e\-]+ seconds?});
    field id      => 'remotehealth'; 
    field label   => 'RemoteHealth';
    field results => [
        { status => 'CRITICAL', info => 'Requested http://foo.test/healthz and got status code 400, expected 200, 503' },
        { status => 'OK', info => match(qr/^Request took [\d.e\-]+ seconds?/) },
    ];
}, 'Expected CRITICAL status when it gets unwanted status code.';

done_testing;
