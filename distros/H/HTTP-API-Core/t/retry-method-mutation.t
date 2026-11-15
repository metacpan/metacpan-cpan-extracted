use strict;
use warnings;
use Test::More;
use HTTP::API::Core;

sub unavailable {
    return { status => 503, reason => 'Unavailable', headers => {}, content => '' };
}

sub success {
    return { status => 200, reason => 'OK', headers => {}, content => '{}' };
}

sub policy {
    my (%overrides) = @_;
    return {
        attempts   => 3,
        base_delay => 0,
        max_delay  => 0,
        jitter     => 0,
        %overrides,
    };
}

# Retry limits must reflect the method *actually sent* by the transport.
# An on_error hook cannot retroactively make an unsafe request eligible.
for my $unsafe (qw(POST PATCH)) {
    my @sent;
    my @error_attempts;
    my $client = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => policy(),
        hooks => {
            before_request => sub { $_[0]{method} = $unsafe },
            on_error => sub {
                my ($error, $context) = @_;
                push @error_attempts, $context->{attempt};
                $context->{method} = 'GET'; # Does not change the sent method.
            },
        },
        transport => sub {
            my ($method) = @_;
            push @sent, $method;
            return unavailable();
        },
    );

    my $caught;
    eval { $client->get('/unsafe'); 1 } or $caught = $@;
    isa_ok $caught, 'HTTP::API::Core::Error';
    is $caught->status, 503, "$unsafe failure is preserved";
    is_deeply \@sent, [$unsafe],
        "hook-mutated $unsafe is not retried by default";
    is_deeply \@error_attempts, [1],
        "on_error is called once for hook-mutated $unsafe";
}

# The same rule must cover retryable transport exceptions.
{
    my @sent;
    my $client = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => policy(),
        hooks => { before_request => sub { $_[0]{method} = 'POST' } },
        transport => sub {
            push @sent, $_[0];
            die "temporary transport failure\n";
        },
    );
    my $caught;
    eval { $client->get('/transport-failure'); 1 } or $caught = $@;
    isa_ok $caught, 'HTTP::API::Core::Error';
    is $caught->category, 'transport', 'transport error keeps its category';
    is_deeply \@sent, ['POST'], 'retryable transport exception does not resend POST';
}

# Normal retries for safe dispatched methods still work.
for my $safe (qw(GET PUT)) {
    my @sent;
    my $client = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => policy(),
        hooks => { before_request => sub { $_[0]{method} = $safe } },
        transport => sub {
            push @sent, $_[0];
            return @sent == 1 ? unavailable() : success();
        },
    );
    is $client->get('/safe')->status, 200,
        "hook-mutated $safe may retry successfully";
    is_deeply \@sent, [$safe, $safe],
        "hook-mutated $safe is retried under the default policy";
}

# The caller can deliberately opt unsafe methods into the retry policy.
{
    my @sent;
    my $client = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => policy(methods => [qw(GET POST)]),
        hooks => { before_request => sub { $_[0]{method} = 'POST' } },
        transport => sub {
            push @sent, $_[0];
            return @sent == 1 ? unavailable() : success();
        },
    );
    is $client->get('/opted-in')->status, 200,
        'explicitly permitted hook-mutated POST can retry';
    is_deeply \@sent, [qw(POST POST)],
        'explicit POST retry opt-in keeps its existing behavior';
}

# Original unsafe calls remain limited to one attempt even if a hook
# subsequently changes the method to a safe one.
{
    my @sent;
    my $client = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => policy(),
        hooks => { before_request => sub { $_[0]{method} = 'GET' } },
        transport => sub {
            push @sent, $_[0];
            return unavailable();
        },
    );
    my $caught;
    eval { $client->post('/originally-unsafe'); 1 } or $caught = $@;
    isa_ok $caught, 'HTTP::API::Core::Error';
    is_deeply \@sent, ['GET'],
        'original POST retry limit remains conservative after GET mutation';
}

done_testing;
