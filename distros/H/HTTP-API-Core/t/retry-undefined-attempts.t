use strict;
use warnings;
use Test::More;
use HTTP::API::Core;

sub failed_without_warnings {
    my ($code, $expected, $label) = @_;
    my @warnings;
    my $error;
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        eval { $code->(); 1 } or $error = $@;
    }
    like $error, $expected, "$label reports the expected error";
    is_deeply \@warnings, [], "$label emits no Perl warnings";
}

sub unavailable {
    return { status => 503, reason => 'Unavailable', headers => {}, content => '' };
}

for my $bad (
    [ undef, 'undefined attempts' ],
    [ '',    'empty attempts' ],
    [ '0',   'zero attempts' ],
    [ '-1',  'negative attempts' ],
    [ '1.5', 'fractional attempts' ],
    [ [],    'reference-valued attempts' ],
) {
    my ($attempts, $name) = @$bad;
    failed_without_warnings(
        sub {
            HTTP::API::Core->new(
                base_url => 'https://api.example.test',
                retry => { attempts => $attempts },
                transport => sub { unavailable() },
            );
        },
        qr/retry attempts must be a positive integer/,
        "constructor with $name",
    );
}

{
    my $calls = 0;
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 3, base_delay => 0, jitter => 0 },
        transport => sub { $calls++; return unavailable() },
    );
    failed_without_warnings(
        sub {
            $api->get('/bad', retry => { attempts => undef });
        },
        qr/retry attempts must be a positive integer/,
        'per-request undefined attempts',
    );
    is $calls, 0, 'invalid per-request retry count is rejected before transport';

    failed_without_warnings(
        sub {
            $api->get('/bad-zero', retry => { attempts => 0 });
        },
        qr/retry attempts must be a positive integer/,
        'per-request zero attempts',
    );
    is $calls, 0, 'other invalid per-request count also avoids transport';

    my $error;
    eval {
        $api->get('/two', retry => {
            attempts => '2', base_delay => 0, jitter => 0,
        });
        1;
    } or $error = $@;
    isa_ok $error, 'HTTP::API::Core::Error';
    is $calls, 2, 'valid per-request attempt count still limits dispatches';

    eval { $api->get('/default'); 1 };
    is $calls, 5, 'constructor retry count still applies on later requests';

    eval {
        $api->get('/once', retry => {
            attempts => 1, base_delay => 0, jitter => 0,
        });
        1;
    };
    is $calls, 6, 'a single allowed attempt still means no retries';
}

{
    my $calls = 0;
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 2, base_delay => 0, jitter => 0 },
        transport => sub { $calls++; return unavailable() },
    );
    eval { $api->get('/constructor-two'); 1 };
    is $calls, 2, 'valid constructor retry limit retains normal behavior';
}

done_testing;
