use strict;
use warnings;

use Test::More;
use Test::MockModule;
use HealthCheck::Diagnostic::WebRequest;

# Mock the HTTP response so that we don't actually end up making any
# HTTP requests while running tests.
sub mock_http_response {
    my (%params) = @_;

    my $mock = Test::MockModule->new( 'LWP::Protocol::http' );
    $mock->mock( request => sub {
        my ($self, $request, $proxy, $arg, $size, $timeout) = @_;

        die $params{die} if $params{die};

        # Borrowed and mocked from here: http://metacpan.org/source/OALDERS/libwww-perl-6.39/lib/LWP/Protocol/http.pm#L440
        my $response = HTTP::Response->new(
            $params{code}    // 200,
        );
        $response->{_content} = $params{content} // 'html_content';
        $response->protocol("HTTP/1.1");
        $response->push_header( @{ $params{headers} } );
        $response->request($request);

        return $response;
    });
    return $mock;
}

sub get_info_and_status {
    my ($diagnostic) = @_;

    my $results = $diagnostic->check;
    return { info => $results->{info}, status => $results->{status} };
}

# Default params
my %default_options = (
    agent => LWP::UserAgent->_agent
        . ' HealthCheck-Diagnostic-WebRequest/'
        . ( HealthCheck::Diagnostic::WebRequest->VERSION || 0 ),
    timeout => 7,
);

is_deeply( HealthCheck::Diagnostic::WebRequest->new( url => 'x' )->{options},
    {%default_options}, "Set default LWP::UserAgent options" );
is_deeply(
    HealthCheck::Diagnostic::WebRequest->new(
        url     => 'x',
        options => { foo => 'bar' }
    )->{options},
    { %default_options, foo => 'bar' },
    "Added default LWP::UserAgent options"
);
is_deeply(
    HealthCheck::Diagnostic::WebRequest->new(
        url     => 'x',
        options => { agent => 'custom', foo => 'bar', timeout => 3 }
    )->{options},
    { agent => 'custom', foo => 'bar', timeout => 3 },
    "Added default LWP::UserAgent options"
);

# Check that we get the right code responses.
my $mock = mock_http_response();
my $diagnostic = HealthCheck::Diagnostic::WebRequest->new(
    url => 'http://foo.com',
);
is_deeply( get_info_and_status( $diagnostic ), {
    info   => 'Requested http://foo.com and got expected status code 200',
    status => 'OK',
}, 'Pass diagnostic check on status.' );

$mock = mock_http_response( code => 401 );
is_deeply( get_info_and_status( $diagnostic ), {
    info   => 'Requested http://foo.com and got status code 401, expected 200',
    status => 'CRITICAL',
}, 'Fail diagnostic check on status.' );

# Check that we get the right content responses.
$mock = mock_http_response( content => 'content_doesnt_exist' );
$diagnostic = HealthCheck::Diagnostic::WebRequest->new(
    url => 'http://bar.com',
    content_regex => 'content_exists',
);
is_deeply( get_info_and_status( $diagnostic ), {
    info   => 'Requested http://bar.com and got expected status code 200'
            . '; Response content does not match /content_exists/',
    status => 'CRITICAL',
}, 'Fail diagnostic check on content.' );
$mock = mock_http_response( content => 'content_exists' );
is_deeply( get_info_and_status( $diagnostic ), {
    info   => 'Requested http://bar.com and got expected status code 200'
            . '; Response content matches /content_exists/',
    status => 'OK',
}, 'Pass diagnostic check on content.' );

# Check that we skip the content match on status code failures.
$mock = mock_http_response( code => 300 );
$diagnostic = HealthCheck::Diagnostic::WebRequest->new(
    url => 'http://cyprus.co',
    content_regex => 'match_check_should_not_happen',
);
is_deeply( get_info_and_status( $diagnostic ), {
    info   => 'Requested http://cyprus.co and got status code 300,'
            . ' expected 200',
    status => 'CRITICAL',
}, 'Do not look for content with failed status code check.' );

# Check that the content regex can be  a qr// variable.
$mock = mock_http_response( content => 'This is Disney World\'s site' );
$diagnostic = HealthCheck::Diagnostic::WebRequest->new(
    url => 'http://disney.world',
    content_regex => qr/Disney/,
);
my $results = $diagnostic->check;
is $results->{status}, 'OK',
    'Pass diagnostic with regex content_regex.';
like $results->{info},
    qr/Response content matches .+Disney/,
    'Info message is correct.';

# Check content failure for appropriate message
$mock = mock_http_response( content => 'This is Disney World\'s site' );
$diagnostic = HealthCheck::Diagnostic::WebRequest->new(
    url => 'http://fake.site.us',
    content_regex => qr/fail_on_this/,
);
$results = $diagnostic->check;
is $results->{status}, 'CRITICAL',
    'Fail diagnostic with regex content_regex.';
like $results->{info},
    qr/Response content does not match .+fail_on_this/,
    'Info message is correct.';

# Check timeout failure for appropriate message
$mock = mock_http_response( die => "Can't connect to fake.site.us" );
$diagnostic = HealthCheck::Diagnostic::WebRequest->new(
    url => 'http://fake.site.us',
);
$results = $diagnostic->check;
is $results->{status}, 'CRITICAL', 'Timeout check';
like $results->{info}, qr/Can't connect to/, 'Internal timeout check';

# Check for proxy errors, even on matching status code
$mock = mock_http_response( code => 403,
    headers => ["X-Squid-Error" => "ERR_ACCESS_DENIED 0"]);
$diagnostic = HealthCheck::Diagnostic::WebRequest->new(
    url => 'http://fake.site.us',
    status_code => '<500',
);
$results = $diagnostic->check;
is $results->{status}, 'CRITICAL', 'Proxy status check';
like $results->{info}, qr/got status code 403 from proxy with error/,
    'Proxy info message';

# Check < operator
$mock = mock_http_response( code => 401 );
$diagnostic = HealthCheck::Diagnostic::WebRequest->new(
    url => 'http://fake.site.us',
    status_code => '<500',
);
$results = $diagnostic->check;
is $results->{status}, 'OK', 'Less than status check';
like $results->{info}, qr/and got expected status code 401/,
    'Valid less than message';

# Failed < operator with timeout
$mock = mock_http_response( die => "Can't connect to fake.site.us" );
$diagnostic = HealthCheck::Diagnostic::WebRequest->new(
    url => 'http://fake.site.us',
    status_code => '<500',
);
$results = $diagnostic->check;
is $results->{status}, 'CRITICAL', 'Failed less than status check';
like $results->{info}, qr/User Agent returned: Can't connect to/,
    'Failed less than message with internal response timeout';

# Check valid ! operator
$mock = mock_http_response( code => 401 );
$diagnostic = HealthCheck::Diagnostic::WebRequest->new(
    url => 'http://fake.site.us',
    status_code => '!500'
);

$results = $diagnostic->check;
is $results->{status}, 'OK', 'Less than status check';
like $results->{info}, qr/and got expected status code 401/,
    'Valid not message';

# Check failed ! operator
$mock = mock_http_response( code => 500 );
$diagnostic = HealthCheck::Diagnostic::WebRequest->new(
    url => 'http://fake.site.us',
    status_code => '!500',
);

$results = $diagnostic->check;
is $results->{status}, 'CRITICAL', 'failed NOT status check';
like $results->{info}, qr/got status code 500, expected !500/,
    'failed NOT status message';

# Complex status code string
$diagnostic = HealthCheck::Diagnostic::WebRequest->new(
    url => 'http://fake.site.us',
    status_code => '<400, 405, !202',
);

$mock = mock_http_response( code => 500 );
$results = $diagnostic->check;
is $results->{status}, 'CRITICAL', 'Complex check: 500 is BAD';

$mock = mock_http_response( code => 400 );
$results = $diagnostic->check;
is $results->{status}, 'CRITICAL', 'Complex check: 400 is BAD';

$mock = mock_http_response( code => 202 );
$results = $diagnostic->check;
is $results->{status}, 'CRITICAL', 'Complex check: 202 is BAD';

$mock = mock_http_response( code => 404 );
$results = $diagnostic->check;
is $results->{status}, 'CRITICAL', 'Complex check: 404 is BAD';

$mock = mock_http_response( code => 405 );
$results = $diagnostic->check;
is $results->{status}, 'OK', 'Complex check: 405 is GOOD';

$mock = mock_http_response( code => 200 );
$results = $diagnostic->check;
is $results->{status}, 'OK', 'Complex check: 200 is GOOD';

$mock = mock_http_response( code => 302 );
$results = $diagnostic->check;
is $results->{status}, 'OK', 'Complex check: 302 is GOOD';

# Make sure that we do not call `check` without an instance.
local $@;
eval { HealthCheck::Diagnostic::WebRequest->check };
like $@, qr/check cannot be called as a class method/,
    'Cannot call `check` without an instance.';

done_testing;
