use strict;
use warnings;
use Test::More;
use HTTP::API::Core;

sub dies_like {
    my ($code, $pattern, $name) = @_;
    my $error;
    eval { $code->(); 1 } or $error = $@;
    like($error, $pattern, $name);
}

my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    transport => sub {
        return { status => 200, reason => 'OK', headers => {}, content => '{}' };
    },
);

is_deeply(
    $api->retry,
    {
        attempts   => 3,
        base_delay => 0.25,
        max_delay  => 5,
        jitter     => 1,
        methods    => [qw(GET HEAD PUT DELETE OPTIONS)],
    },
    'default retry policy is stable',
);

my $normalized = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => {
        attempts   => '2',
        base_delay => '0',
        max_delay  => '3.5',
        jitter     => 0,
        methods    => [qw(get post)],
    },
    transport => sub {
        return { status => 200, reason => 'OK', headers => {}, content => '{}' };
    },
);

is_deeply(
    $normalized->retry,
    {
        attempts   => 2,
        base_delay => 0,
        max_delay  => 3.5,
        jitter     => 0,
        methods    => [qw(GET POST)],
    },
    'retry policy is normalized predictably',
);

dies_like(
    sub { HTTP::API::Core->new(base_url => 'https://api.example.test', retry => { attempts => 0 }) },
    qr/retry attempts must be a positive integer/,
    'zero attempts rejected',
);

dies_like(
    sub { HTTP::API::Core->new(base_url => 'https://api.example.test', retry => { base_delay => -1 }) },
    qr/retry base_delay must be a non-negative number/,
    'negative base delay rejected',
);

dies_like(
    sub { HTTP::API::Core->new(base_url => 'https://api.example.test', retry => { max_delay => -1 }) },
    qr/retry max_delay must be a non-negative number/,
    'negative max delay rejected',
);

dies_like(
    sub { HTTP::API::Core->new(base_url => 'https://api.example.test', retry => { methods => 'GET' }) },
    qr/retry methods must be an array reference/,
    'non-array retry methods rejected',
);

dies_like(
    sub { HTTP::API::Core->new(base_url => 'https://api.example.test', retry => { methods => ['GET', ''] }) },
    qr/retry methods must not contain empty values/,
    'empty retry method rejected',
);

dies_like(
    sub { HTTP::API::Core->new(base_url => 'https://api.example.test', retry => { surprise => 1 }) },
    qr/unknown retry option: surprise/,
    'unknown retry option rejected',
);

for my $status (408, 425, 429, 500, 503, 599) {
    my $calls = 0;
    my $client = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 2, base_delay => 0, jitter => 0 },
        transport => sub {
            $calls++;
            return { status => $status, reason => 'retry', headers => {}, content => '' };
        },
    );
    eval { $client->get('/retry'); 1 };
    is($calls, 2, "status $status is retried for safe methods");
}

for my $status (400, 401, 403, 404, 422) {
    my $calls = 0;
    my $client = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 2, base_delay => 0, jitter => 0 },
        transport => sub {
            $calls++;
            return { status => $status, reason => 'no retry', headers => {}, content => '' };
        },
    );
    eval { $client->get('/once'); 1 };
    is($calls, 1, "status $status is not retried without rate-limit exhaustion");
}

{
    my $calls = 0;
    my $client = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 2, base_delay => 0, jitter => 0 },
        transport => sub {
            $calls++;
            return {
                status => 403,
                reason => 'Forbidden',
                headers => { 'X-RateLimit-Remaining' => '0' },
                content => '',
            };
        },
    );
    eval { $client->get('/limited'); 1 };
    is($calls, 2, 'exhausted 403 rate limit is retried');
}

{
    my $calls = 0;
    my $client = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 2, methods => ['post'], base_delay => 0, jitter => 0 },
        transport => sub {
            $calls++;
            return { status => 503, reason => 'Unavailable', headers => {}, content => '' };
        },
    );
    eval { $client->post('/explicit'); 1 };
    is($calls, 2, 'lowercase configured method is normalized and retried');
}

done_testing;
