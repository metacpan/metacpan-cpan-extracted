use strict;
use warnings;
use Test::More;

use HTTP::API::Core::Response;
use HTTP::API::Core::RateLimit;

sub rejects_without_warnings {
    my ($call, $diagnostic, $label) = @_;
    my @warnings;
    my $error;

    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        eval { $call->(); 1 } or $error = $@;
    }

    like $error, $diagnostic, "$label rejects malformed options";
    is_deeply \@warnings, [], "$label does not warn during hash coercion";
}

rejects_without_warnings(
    sub {
        HTTP::API::Core::Response->new(
            status => 200,
            'dangling',
        );
    },
    qr/response constructor options must be key\/value pairs/,
    'Response constructor',
);

rejects_without_warnings(
    sub {
        HTTP::API::Core::RateLimit->new(
            remaining => 1,
            'dangling',
        );
    },
    qr/rate-limit constructor options must be key\/value pairs/,
    'RateLimit constructor',
);

my $rate = HTTP::API::Core::RateLimit->new(
    remaining   => 0,
    retry_after => 0,
);

rejects_without_warnings(
    sub { $rate->wait_seconds(now => 100, 'dangling') },
    qr/rate-limit wait_seconds options must be key\/value pairs/,
    'RateLimit wait_seconds',
);

# Valid calls and existing raw option-name validation must remain unchanged.
my $response = HTTP::API::Core::Response->new(
    status  => 200,
    headers => { 'Content-Type' => 'application/json' },
    content => '{}',
);
is $response->status, 200, 'valid Response constructor still works';
is $response->content_type, 'application/json',
    'Response header behavior is unaffected';

is $rate->remaining, 0, 'valid RateLimit constructor still works';
is $rate->wait_seconds(now => 100), 0,
    'valid wait_seconds option list preserves zero delay';

rejects_without_warnings(
    sub { HTTP::API::Core::Response->new([], 'value') },
    qr/constructor option names must be scalars/,
    'Response raw option-name validation',
);

rejects_without_warnings(
    sub { HTTP::API::Core::RateLimit->new([], 'value') },
    qr/constructor option names must be scalars/,
    'RateLimit raw option-name validation',
);

rejects_without_warnings(
    sub { $rate->wait_seconds([], 'value') },
    qr/rate-limit wait_seconds option names must be scalars/,
    'wait_seconds raw option-name validation',
);

done_testing;
