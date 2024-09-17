use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Test::Mock::Time;
use HealthCheck::Diagnostic::WebRequest;
use HealthCheck::WebRequests;

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

        sleep $params{sleep} if $params{sleep};

        return $response;
    });
    return $mock;
}

# Check we get expected responses when checks contains both a hashref and a HealthCheck::Diagnostic::WebRequest object
{
    my $mock = mock_http_response();
    my $diagnostic = HealthCheck::WebRequests->new(
        checks => [
            {
                url  => 'http://foo.example',
                tags => ['foo'],
            },
            HealthCheck::Diagnostic::WebRequest->new(url => 'http://bar.example',),
            {
                url  => 'http://baz.example',
            },
        ],
        tags => ['default'],
    );
    my $results = $diagnostic->check;
    is $results->{status}, 'OK',
        'Got expected status for overall healthcheck';
    is $results->{tags}[0], 'default',
        'Got expected tag for overall healthcheck';
    my @expected_urls = ('http://foo.example', 'http://bar.example', 'http://baz.example');
    my @expected_tags = ('foo', undef, 'default');
    for my $result (@{ $results->{results} }) {
        my $url = shift @expected_urls;
        my $tag = shift @expected_tags;
        is $result->{info}, "Requested $url and got expected status code 200; Request took 0 seconds",
            "Got expected info for $url";
        is $result->{status}, 'OK',
            "Got expected status for $url";
        is $result->{tags}[0], $tag,
            "Got expected tag for $url" if $tag;
    }
}

done_testing;
