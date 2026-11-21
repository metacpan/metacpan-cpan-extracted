use strict;
use warnings;
use utf8;
use Test::More;

use HTTP::API::Core;
use HTTP::API::Core::Pagination;

sub rejects_without_warnings {
    my ($call, $regex, $label) = @_;
    my (@warnings, $error);
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        eval { $call->(); 1 } or $error = $@;
    }
    like $error, $regex, "$label rejected with a clear diagnostic";
    is_deeply \@warnings, [], "$label rejected without numeric warnings";
}

my $base = 'https://api.example.test';

for my $digits (
    [ '٢',  'Arabic-Indic digit' ],
    [ '２', 'fullwidth digit' ],
) {
    my ($digit, $name) = @$digits;

    rejects_without_warnings(
        sub { HTTP::API::Core->new(base_url => $base, timeout => $digit) },
        qr/timeout must be a positive number/,
        "$name timeout",
    );
    rejects_without_warnings(
        sub { HTTP::API::Core->new(base_url => $base, retry => { attempts => $digit }) },
        qr/retry attempts must be a positive integer/,
        "$name retry attempts",
    );
    rejects_without_warnings(
        sub { HTTP::API::Core->new(base_url => $base, retry => { base_delay => $digit }) },
        qr/retry base_delay must be a non-negative number/,
        "$name retry base_delay",
    );
    rejects_without_warnings(
        sub { HTTP::API::Core->new(base_url => $base, retry => { max_delay => $digit }) },
        qr/retry max_delay must be a non-negative number/,
        "$name retry max_delay",
    );
    rejects_without_warnings(
        sub {
            HTTP::API::Core::Pagination->new(
                client => 'offline', path => '/items', mode => 'page', page_size => $digit,
            );
        },
        qr/page_size must be a positive integer/,
        "$name pagination page size",
    );
    rejects_without_warnings(
        sub {
            HTTP::API::Core::Pagination->new(
                client => 'offline', path => '/items', mode => 'page', start_page => $digit,
            );
        },
        qr/start_page must be a positive integer/,
        "$name pagination start page",
    );
}

my $calls = 0;
my $api = HTTP::API::Core->new(
    base_url => $base,
    timeout => '1.5',
    retry => { attempts => '2', base_delay => '0.25', max_delay => '3.5', jitter => 0 },
    transport => sub {
        ++$calls;
        return { status => 200, content => '{}', headers => {} };
    },
);
is $api->timeout, '1.5', 'ASCII decimal timeout still accepted';
is $api->retry->{attempts}, 2, 'ASCII retry count still accepted';
is $api->retry->{base_delay}, 0.25, 'ASCII fractional retry base delay still accepted';
is $api->retry->{max_delay}, 3.5, 'ASCII fractional retry max delay still accepted';

for my $digit ('٢', '２') {
    rejects_without_warnings(
        sub { $api->get('/users', retry => { attempts => $digit }) },
        qr/retry attempts must be a positive integer/,
        'invalid per-request attempt count',
    );
    rejects_without_warnings(
        sub { $api->get('/users', retry => { attempts => 1, base_delay => $digit }) },
        qr/retry base_delay must be a non-negative number/,
        'invalid per-request delay',
    );
    rejects_without_warnings(
        sub { $api->get("https://api.example.test:$digit/users") },
        qr/url must be an absolute HTTP\(S\) URL/,
        'invalid Unicode URL port',
    );
}
is $calls, 0, 'invalid configuration and URLs never reach the transport';
is $api->get('/users')->status, 200, 'valid ASCII configuration still sends requests';
is $calls, 1, 'valid request reaches the transport once';

{
    package T::ASCIIPagerResponse;
    sub new { bless { value => $_[1] }, $_[0] }
    sub json { $_[0]{value} }

    package T::ASCIIPagerClient;
    sub new { bless { calls => 0 }, $_[0] }
    sub get { $_[0]{calls}++; T::ASCIIPagerResponse->new({ rows => [[1], [2]], next => undef }) }
}

my $client = T::ASCIIPagerClient->new;
my $pager = HTTP::API::Core::Pagination->new(
    client => $client, path => '/items',
    items => 'rows.1',
);
is_deeply scalar($pager->all), [2],
    'ASCII numeric dotted-path index still selects the correct array entry';

my $bad_pager = HTTP::API::Core::Pagination->new(
    client => $client, path => '/items',
    items => 'rows.١',
);
rejects_without_warnings(
    sub { $bad_pager->next },
    qr/pagination items extractor must return an array reference/,
    'Unicode dotted-path array index',
);
is $client->{calls}, 2, 'each paginated request is made only once';

done_testing;
