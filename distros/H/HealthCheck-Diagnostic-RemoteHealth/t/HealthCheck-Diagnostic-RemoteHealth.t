use Test2::V0 -target => 'HealthCheck::Diagnostic::RemoteHealth',
    qw< is mock done_testing >;
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

is $res, {
    status  => 'OK',
    id      => 'remotehealth',
    label   => 'RemoteHealth',
    results => [ { status => 'OK', info => 'Ok!' } ],
}, 'Expected OK HealthCheck from 200 HTTP Response.';

$mock_web = mock_web_request(code => 503);
$res      = $hc->check;

is $res, {
    status  => 'OK',
    id      => 'remotehealth',
    label   => 'RemoteHealth',
    results => [ { status => 'OK', info => 'Ok!' } ],
}, 'Expected OK HealthCheck from 503 HTTP Response.';

$mock_web = mock_web_request(
    response => { status => 'CRITICAL', info => 'Ouch!'}
);
$res      = $hc->check;

is $res, {
    status  => 'CRITICAL',
    id      => 'remotehealth',
    label   => 'RemoteHealth',
    results => [ { status => 'CRITICAL', info => 'Ouch!' } ],
}, 'Expected CRITICAL HealthCheck from JSON object with CRITICAL status.';

$mock_web = mock_web_request(die => 'I have died!');
$res      = $hc->check;

is $res, {
    status  => 'CRITICAL',
    info    => 'User Agent returned: I have died!',
    id      => 'remotehealth',
    label   => 'RemoteHealth',
    results => [ {
        status => 'CRITICAL',
        info   => 'User Agent returned: I have died!',
    } ],
}, 'Expected CRITICAL status from web request that dies.';

$mock_web = mock_web_request(response => 'Not a valid JSON Object.');
$res      = $hc->check;

is $res, {
    id      => 'remotehealth',
    label   => 'RemoteHealth',
    status  => 'CRITICAL',
    info    => 'Could not decode JSON.',
    data    => 'Not a valid JSON Object.',
}, 'Expected CRITICAL status when it cannot decode JSON.';

$mock_web = mock_web_request(code => 400);
$res      = $hc->check;

is $res, {
    id      => 'remotehealth',
    label   => 'RemoteHealth',
    status  => 'CRITICAL',
    info    =>
        'Requested http://foo.test/healthz and got status code 400, expected 200, 503',
    results => [ {
        status => 'CRITICAL',
        info   =>
            'Requested http://foo.test/healthz and got status code 400, expected 200, 503',
    } ],
}, 'Expected CRITICAL status when it gets unwanted status code.';

done_testing;
