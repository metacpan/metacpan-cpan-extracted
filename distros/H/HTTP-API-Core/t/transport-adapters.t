use strict;
use warnings;
use Test::More;

use lib 'examples';
use HTTP::API::Core;
use HTTP::API::Core::Example::TransportAdapters;

{
    package Local::Tiny;
    sub new { bless { calls => [] }, shift }
    sub request {
        my ($self, @args) = @_;
        push @{ $self->{calls} }, \@args;
        return {
            status => 201,
            reason => 'Created',
            headers => { 'content-type' => 'text/plain' },
            content => 'tiny',
        };
    }
    sub calls { $_[0]->{calls} }
}

{
    my $http = Local::Tiny->new;
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        transport => HTTP::API::Core::Example::TransportAdapters::http_tiny($http),
    );
    my $response = $api->post('/items', content => '');
    is $response->status, 201, 'HTTP::Tiny response is passed through';
    is $response->content, 'tiny', 'HTTP::Tiny content is preserved';
    is $http->calls->[0][0], 'POST', 'HTTP::Tiny receives method';
    ok exists $http->calls->[0][2]{content}, 'HTTP::Tiny adapter preserves explicit empty body';
}

{
    package Local::LWPHeaders;
    sub new { bless {}, shift }
    sub flatten { ('Content-Type' => 'application/json', 'X-Test' => 'yes') }

    package Local::LWPResponse;
    sub new { bless {}, shift }
    sub code { 202 }
    sub message { 'Accepted' }
    sub headers { Local::LWPHeaders->new }
    sub content { '{"adapter":"lwp"}' }

    package Local::LWP;
    sub new { bless { request => undef }, shift }
    sub request {
        my ($self, $request) = @_;
        $self->{request} = $request;
        return Local::LWPResponse->new;
    }
    sub seen { $_[0]->{request} }
}

SKIP: {
    eval { require HTTP::Request; 1 }
        or skip 'HTTP::Request is not installed', 6;

    my $ua = Local::LWP->new;
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        transport => HTTP::API::Core::Example::TransportAdapters::lwp_user_agent($ua),
    );
    my $response = $api->post('/items', headers => { 'X-In' => 'yes' }, content => '');
    is $response->status, 202, 'LWP response status is mapped';
    is $response->reason, 'Accepted', 'LWP response reason is mapped';
    is $response->content, '{"adapter":"lwp"}', 'LWP raw content is mapped';
    is $ua->seen->method, 'POST', 'LWP request receives method';
    is $ua->seen->header('X-In'), 'yes', 'LWP request receives headers';
    is $ua->seen->content, '', 'LWP adapter preserves explicit empty body';
}

done_testing;
