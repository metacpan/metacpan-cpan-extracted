use strict;
use warnings;
use Test::More;
use HTTP::API::Core;

my $calls = 0;
my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 3, base_delay => 0, jitter => 0 },
    transport => sub {
        $calls++;
        return { status => 503, reason => 'Unavailable', headers => {}, content => '' }
            if $calls < 3;
        return { status => 200, reason => 'OK', headers => {}, content => '{"ok":true}' };
    },
);

my $res = $api->get('/eventually');
is $res->status, 200, 'eventual success returned';
is $calls, 3, 'GET retried until success';

$calls = 0;
my $post_api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 3, base_delay => 0, jitter => 0 },
    transport => sub {
        $calls++;
        return { status => 503, reason => 'Unavailable', headers => {}, content => '' };
    },
);
my $post_error;
eval { $post_api->post('/orders', json => { sku => 'x' }); 1 } or $post_error = $@;
isa_ok $post_error, 'HTTP::API::Core::Error';
is $calls, 1, 'POST is not retried by default';

$calls = 0;
my $transport_api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 2, base_delay => 0, jitter => 0 },
    transport => sub {
        $calls++;
        die "temporary socket failure\n" if $calls == 1;
        return { status => 200, reason => 'OK', headers => {}, content => '{}' };
    },
);
is $transport_api->get('/transport')->status, 200, 'transport failure retried';
is $calls, 2, 'transport called twice';

$calls = 0;
my $disabled_api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 3, base_delay => 0, jitter => 0 },
    transport => sub {
        $calls++;
        return { status => 503, reason => 'Unavailable', headers => {}, content => '' };
    },
);
my $disabled_error;
eval { $disabled_api->get('/once', retry => 0); 1 } or $disabled_error = $@;
isa_ok $disabled_error, 'HTTP::API::Core::Error';
is $calls, 1, 'per-request retry can be disabled';

$calls = 0;
my $override_api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 1 },
    transport => sub {
        $calls++;
        return { status => 503, reason => 'Unavailable', headers => {}, content => '' };
    },
);
my $override_error;
eval {
    $override_api->post('/safe-to-repeat', retry => {
        attempts => 2,
        methods => ['POST'],
        base_delay => 0,
        jitter => 0,
    });
    1;
} or $override_error = $@;
isa_ok $override_error, 'HTTP::API::Core::Error';
is $calls, 2, 'per-request policy can opt POST into retry';

my $retry = $api->retry;
is $retry->{attempts}, 3, 'retry accessor exposes attempts';
is_deeply $retry->{methods}, [qw(GET HEAD PUT DELETE OPTIONS)], 'safe methods default';


# Observe the actual delay requested by the retry loop without sleeping.
# A deterministic fake transport makes each delay and attempt count observable.
for my $case (
    [ 'Retry-After overrides reset and backoff',
      { 'Retry-After' => '4', 'RateLimit-Remaining' => '0', 'RateLimit-Reset' => '2' },
      { base_delay => 1, max_delay => 3, jitter => 0 }, [4, 4] ],
    [ 'exhausted quota reset overrides backoff',
      { 'RateLimit-Remaining' => '0', 'RateLimit-Reset' => '2' },
      { base_delay => 1, max_delay => 3, jitter => 0 }, [2, 2] ],
    [ 'backoff is capped',
      {}, { base_delay => 2, max_delay => 3, jitter => 0 }, [2, 3] ],
    [ 'zero Retry-After suppresses sleep',
      { 'Retry-After' => '0' },
      { base_delay => 1, max_delay => 3, jitter => 0 }, [] ],
) {
    my ($label, $headers, $policy, $expected) = @$case;
    my ($calls, @delays) = (0);
    my $client = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 3, %$policy },
        transport => sub {
            return { status => 200 } if ++$calls == 3;
            return { status => 429, headers => $headers };
        },
    );
    {
        no warnings 'redefine';
        local *HTTP::API::Core::sleep = sub { push @delays, $_[0]; return 0 };
        is $client->get('/delay')->status, 200, "$label: eventual success";
    }
    is $calls, 3, "$label: exactly three attempts";
    is_deeply \@delays, $expected, "$label: requested sleep intervals";
}

# Jitter is bounded by the capped exponential delay. Do not assert a
# particular random sequence, which differs across Perl releases.
{
    my ($calls, @delays) = (0);
    my $client = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 3, base_delay => 2, max_delay => 3, jitter => 1 },
        transport => sub {
            return { status => 200 } if ++$calls == 3;
            return { status => 503 };
        },
    );
    {
        no warnings 'redefine';
        local *HTTP::API::Core::sleep = sub { push @delays, $_[0]; return 0 };
        is $client->get('/jitter')->status, 200, 'jittered retries succeed';
    }
    is $calls, 3, 'jitter does not change attempt limit';
    ok !grep({ $_ <= 0 || $_ > 3 } @delays), 'all requested jitter sleeps stay within the cap';
    ok @delays <= 2, 'no more sleeps than retry opportunities';
}

done_testing;
