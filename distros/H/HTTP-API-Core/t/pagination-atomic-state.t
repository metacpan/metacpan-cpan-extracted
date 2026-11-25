use strict;
use warnings;
use Test::More;
use HTTP::API::Core::Pagination;

{
    package T::AtomicPageResponse;
    sub new { bless { data => $_[1] }, $_[0] }
    sub json { $_[0]->{data} }
}

{
    package T::AtomicPageClient;
    sub new { bless { pages => $_[1], calls => [] }, $_[0] }
    sub base_url { 'https://api.example.test' }
    sub get {
        my ($self, $url) = @_;
        push @{ $self->{calls} }, $url;
        die "unexpected page: $url\n" if !exists $self->{pages}{$url};
        die "no more responses for $url\n" if !@{ $self->{pages}{$url} };
        return T::AtomicPageResponse->new(shift @{ $self->{pages}{$url} });
    }
}

sub error_from {
    my ($code) = @_;
    my $error;
    eval { $code->(); 1 } or $error = $@;
    return $error;
}

# Bad next metadata must not make the first page's items visible.
{
    my $client = T::AtomicPageClient->new({
        '/items' => [
            { items => [10], next => [] },
            { items => [20], next => undef },
        ],
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/items',
    );
    like error_from(sub { $pager->next }),
        qr/pagination next URL continuation must be a scalar/,
        'malformed initial next URL is rejected';
    is $pager->next, 20, 'retry fetches the corrected page, not stale item 10';
    is $pager->next, undef, 'corrected final page is exhausted';
    is_deeply $client->{calls}, ['/items', '/items'],
        'initial page is refetched after metadata failure';
}

# Previously committed pages must survive a failure on a later page.
{
    my $client = T::AtomicPageClient->new({
        '/a' => [ { items => [1], next => '/b' } ],
        '/b' => [
            { items => [99], next => {} },
            { items => [2], next => undef },
        ],
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/a',
    );
    is $pager->next, 1, 'first page is committed normally';
    like error_from(sub { $pager->next }),
        qr/pagination next URL continuation must be a scalar/,
        'invalid second-page continuation is rejected';
    is $pager->next, 2, 'retry of second page does not leak stale item 99';
    is $pager->next, undef, 'corrected second page finishes pagination';
    is_deeply $client->{calls}, ['/a', '/b', '/b'],
        'retry refetches the failed page instead of the initial page';
}

# Cursor continuation metadata must be validated before committing items.
{
    my $client = T::AtomicPageClient->new({
        '/cursor?cursor=seed' => [
            { items => [99], next_cursor => [] },
            { items => [2], next_cursor => 'next' },
        ],
        '/cursor?cursor=next' => [
            { items => [3], next_cursor => undef },
        ],
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/cursor',
        mode => 'cursor', cursor => 'seed',
    );
    like error_from(sub { $pager->next }),
        qr/pagination cursor continuation must be a scalar/,
        'invalid cursor continuation is rejected';
    is_deeply scalar($pager->all), [2, 3],
        'retry resumes from initial cursor without stale items';
    is_deeply $client->{calls},
        ['/cursor?cursor=seed', '/cursor?cursor=seed', '/cursor?cursor=next'],
        'cursor is not advanced until the page is valid';
}

# has_more extractors can die; page-number state must remain unchanged.
{
    my $client = T::AtomicPageClient->new({
        '/page?page=1' => [
            { items => [99], more => 'bad' },
            { items => [2], more => 1 },
        ],
        '/page?page=2' => [
            { items => [3], more => 0 },
        ],
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/page', mode => 'page',
        has_more => sub {
            my ($data) = @_;
            die "invalid more flag\n" if $data->{more} eq 'bad';
            return $data->{more};
        },
    );
    like error_from(sub { $pager->next }),
        qr/invalid more flag/,
        'failing has_more extractor propagates its error';
    is_deeply scalar($pager->all), [2, 3],
        'failed has_more metadata does not leak or skip page items';
    is_deeply $client->{calls},
        ['/page?page=1', '/page?page=1', '/page?page=2'],
        'failed page is refetched at the same page number';
}

# Rejected loops must not corrupt the guard for a later valid response.
{
    my $client = T::AtomicPageClient->new({
        '/loop' => [
            { items => [99], next => '/loop' },
            { items => [1], next => '/ok' },
        ],
        '/ok' => [ { items => [2], next => undef } ],
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/loop',
    );
    like error_from(sub { $pager->next }),
        qr/pagination continuation repeated: url/,
        'initial self-loop is rejected';
    is_deeply scalar($pager->all), [1, 2],
        'corrected loop metadata may be retried without stale page data';
    is_deeply $client->{calls}, ['/loop', '/loop', '/ok'],
        'retry preserves normal loop guard and fetch sequence';
}

# Cross-origin continuation errors also leave the failed page uncommitted.
{
    my $client = T::AtomicPageClient->new({
        '/origin' => [
            { items => [99], next => 'https://evil.example/items' },
            { items => [1], next => '/safe' },
        ],
        '/safe' => [ { items => [2], next => undef } ],
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/origin',
    );
    like error_from(sub { $pager->next }),
        qr/cross-origin pagination continuation rejected/,
        'cross-origin continuation is rejected';
    is_deeply scalar($pager->all), [1, 2],
        'corrected same-origin continuation can be fetched';
    is_deeply $client->{calls}, ['/origin', '/origin', '/safe'],
        'cross-origin target is never requested and invalid items stay hidden';
}


# Empty continuation strings are terminal, not a new request or a loop.
for my $mode (qw(next_url cursor)) {
    my $field = $mode eq 'cursor' ? 'next_cursor' : 'next';
    my $client = T::AtomicPageClient->new({
        '/empty' => [ { items => [1], $field => '' } ],
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/empty', mode => $mode,
    );
    is_deeply scalar($pager->all), [1], "$mode retains final items with empty continuation";
    is_deeply $client->{calls}, ['/empty'], "$mode does not request an empty continuation";
}

# An absolute continuation without an authority is invalid; failure must
# leave the iterator at the same page and must not expose unaccepted items.
{
    my $client = T::AtomicPageClient->new({
        '/malformed' => [
            { items => [99], next => 'https:///private' },
            { items => [1], next => '' },
        ],
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/malformed', max_pages => 1,
    );
    like error_from(sub { $pager->next }), qr/invalid pagination continuation URL/,
        'absolute URL without authority is rejected';
    is_deeply scalar($pager->all), [1], 'corrected page fits the original page allowance';
    is_deeply $client->{calls}, ['/malformed', '/malformed'],
        'malformed continuation is never fetched';
}

# Total is required to be a defined non-negative integer when configured.
# Both missing and non-numeric totals must leave offset and allowance intact.
for my $case ([undef, 'missing'], ['1.5', 'fractional'], [-1, 'negative']) {
    my ($total, $label) = @$case;
    my $client = T::AtomicPageClient->new({
        '/offset?offset=0' => [
            { items => [99], total => $total },
            { items => [1], total => 1 },
        ],
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/offset', mode => 'offset',
        total => 'total', max_pages => 1,
    );
    like error_from(sub { $pager->next }),
        qr/pagination total extractor must return a non-negative integer/,
        "$label total is rejected";
    is_deeply scalar($pager->all), [1], "$label total leaves items and allowance uncommitted";
    is_deeply $client->{calls}, ['/offset?offset=0', '/offset?offset=0'],
        "$label total leaves offset unchanged";
}

# Page-number fallback without a size or has_more stops at the first empty
# page, including when the items extractor selects the entire JSON body.
{
    my $client = T::AtomicPageClient->new({
        '/root?page=1' => [ [1, 2] ],
        '/root?page=2' => [ [] ],
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/root', mode => 'page', items => '',
    );
    is_deeply scalar($pager->all), [1, 2], 'root array and implicit page completion work';
    is_deeply $client->{calls}, ['/root?page=1', '/root?page=2'],
        'empty page ends iteration without another request';
}

# A missing intermediate member of a dotted continuation path is a normal
# absent continuation, not an exception or a request to a bogus URL.
{
    my $client = T::AtomicPageClient->new({
        '/missing' => [ { items => [1], links => undef } ],
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/missing', next => 'links.next',
    );
    is_deeply scalar($pager->all), [1], 'missing intermediate continuation ends pagination';
    is_deeply $client->{calls}, ['/missing'], 'no request for a missing continuation';
}

done_testing;
