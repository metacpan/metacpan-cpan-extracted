use strict;
use warnings;
use Test::More;
use HTTP::API::Core;

sub retry_policy {
    my (%overrides) = @_;
    return {
        attempts   => 3,
        base_delay => 0,
        max_delay  => 0,
        jitter     => 0,
        %overrides,
    };
}

sub unavailable {
    return { status => 503, reason => 'Unavailable', headers => {}, content => '' };
}

sub success {
    return { status => 200, reason => 'OK', headers => {}, content => '{}' };
}

# Per-attempt hooks can change URL/credentials, but each retry must start
# from the original caller request, and the actual method must be uppercase.
{
    my (@before, @sent, @on_error, @after);
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        headers => { Authorization => 'Bearer default' },
        retry => retry_policy(),
        hooks => {
            before_request => sub {
                my ($ctx) = @_;
                push @before, [
                    $ctx->{attempt}, $ctx->{method},
                    $ctx->{url}, $ctx->{headers}{Authorization},
                ];
                $ctx->{method} = 'get';
                $ctx->{url} = 'https://api.example.test/attempt-' . $ctx->{attempt};
                $ctx->{headers}{Authorization} = 'Bearer attempt-' . $ctx->{attempt};
                $ctx->{headers}{'X-Attempt'} = $ctx->{attempt};
            },
            on_error => sub {
                my ($error, $ctx) = @_;
                push @on_error, [
                    $error->method, $ctx->{method},
                    $ctx->{url}, $ctx->{headers}{Authorization},
                ];
                # These post-dispatch mutations must not leak into retry 2
                # or retroactively affect the sent method's retry eligibility.
                $ctx->{method} = 'post';
                $ctx->{url} = 'https://other.example.test/leaked';
                $ctx->{headers}{Authorization} = 'Bearer leaked';
            },
            after_response => sub {
                my ($response, $ctx) = @_;
                push @after, [
                    $response->method, $ctx->{method},
                    $ctx->{url}, $ctx->{headers}{Authorization},
                ];
            },
        },
        transport => sub {
            my ($method, $url, $opts) = @_;
            push @sent, [
                $method, $url, $opts->{headers}{Authorization},
                $opts->{headers}{'X-Attempt'},
            ];
            return @sent == 1 ? unavailable() : success();
        },
    );
    my $response = $api->get('/initial');
    is $response->status, 200, 'safe lowercase hook method retries successfully';
    is $response->method, 'GET', 'successful response metadata reports uppercase dispatched method';
    is_deeply \@before, [
        [1, 'GET', 'https://api.example.test/initial', 'Bearer default'],
        [2, 'GET', 'https://api.example.test/initial', 'Bearer default'],
    ], 'each attempt starts with original method, URL, and credentials';
    is_deeply \@sent, [
        ['GET', 'https://api.example.test/attempt-1', 'Bearer attempt-1', 1],
        ['GET', 'https://api.example.test/attempt-2', 'Bearer attempt-2', 2],
    ], 'transport uses uppercase method and fresh per-attempt URL/auth headers';
    is_deeply \@on_error, [
        ['GET', 'GET', 'https://api.example.test/attempt-1', 'Bearer attempt-1'],
    ], 'failed request and error context report normalized actual method';
    is_deeply \@after, [
        ['GET', 'GET', 'https://api.example.test/attempt-2', 'Bearer attempt-2'],
    ], 'success hook receives normalized method and retry-specific request context';
}

# Lowercase unsafe hook methods must still not be retried by default.
for my $unsafe (qw(post patch)) {
    my @sent;
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => retry_policy(),
        hooks => {
            before_request => sub { $_[0]{method} = $unsafe },
            on_error => sub { $_[1]{method} = 'GET' },
        },
        transport => sub {
            push @sent, $_[0];
            return unavailable();
        },
    );
    my $caught;
    eval { $api->get('/unsafe'); 1 } or $caught = $@;
    isa_ok $caught, 'HTTP::API::Core::Error';
    is $caught->method, uc($unsafe), 'error metadata uses uppercase unsafe method';
    is_deeply \@sent, [uc($unsafe)],
        'lowercase unsafe method is dispatched once without default retry';
}

# Explicitly permitted lowercase POST follows the same retry method policy.
{
    my (@sent, @errors);
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => retry_policy(methods => [qw(GET POST)]),
        hooks => {
            before_request => sub { $_[0]{method} = 'post' },
            on_error => sub {
                push @errors, $_[0]->method;
            },
        },
        transport => sub {
            push @sent, $_[0];
            return @sent == 1 ? unavailable() : success();
        },
    );
    my $response = $api->get('/explicit');
    is $response->status, 200, 'opted-in lowercase POST retries successfully';
    is $response->method, 'POST', 'successful opted-in response uses uppercase method';
    is_deeply \@sent, [qw(POST POST)],
        'transport and retry checks agree on allowed uppercase POST';
    is_deeply \@errors, ['POST'],
        'error metadata for opted-in POST also uses normalized method';
}

done_testing;
