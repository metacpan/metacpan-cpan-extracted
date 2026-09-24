use strict;
use warnings;
use Test::More;
use HTTP::API::Core;
use HTTP::API::Core::Pagination;

{
    package T::Response;
    sub new { bless { data => $_[1] }, $_[0] }
    sub json { $_[0]{data} }
}

{
    package T::Client;
    sub new { bless { calls => [], pages => $_[1] }, $_[0] }
    sub get {
        my ($self, $url, %opts) = @_;
        push @{ $self->{calls} }, $url;
        die "no page for $url\n" if !exists $self->{pages}{$url};
        return T::Response->new($self->{pages}{$url});
    }
}

my $next_client = T::Client->new({
    '/users' => {
        data => { items => [1, 2] },
        links => { next => '/users?p=2' },
    },
    '/users?p=2' => {
        data => { items => [3] },
        links => { next => undef },
    },
});
my $next = HTTP::API::Core::Pagination->new(
    client => $next_client,
    path   => '/users',
    mode   => 'next_url',
    items  => 'data.items',
    next   => 'links.next',
);
is_deeply([$next->all], [1, 2, 3], 'next URL pagination');
is_deeply($next_client->{calls}, ['/users', '/users?p=2'], 'follows next URL');

my $page_client = T::Client->new({
    '/users?page=1&per_page=2' => { items => [qw(a b)] },
    '/users?page=2&per_page=2' => { items => ['c'] },
});
my $page = HTTP::API::Core::Pagination->new(
    client    => $page_client,
    path      => '/users',
    mode      => 'page',
    items     => 'items',
    page_size => 2,
);
is_deeply(scalar($page->all), [qw(a b c)], 'page-number pagination');

my $cursor_client = T::Client->new({
    '/users?limit=2' => { items => [1, 2], next_cursor => 'abc xyz' },
    '/users?cursor=abc%20xyz&limit=2' => { items => [3], next_cursor => undef },
});
my $cursor = HTTP::API::Core::Pagination->new(
    client => $cursor_client,
    path   => '/users',
    mode   => 'cursor',
    items  => 'items',
    next   => 'next_cursor',
    query  => { limit => 2 },
);
is_deeply(scalar($cursor->all), [1, 2, 3], 'cursor pagination');
is_deeply(
    $cursor_client->{calls},
    ['/users?limit=2', '/users?cursor=abc%20xyz&limit=2'],
    'cursor and query parameters encoded',
);

my $fragment_client = T::Client->new({
    '/users?filter=active&page=1&per_page=2#results' => { items => [qw(a b)] },
    '/users?filter=active&page=2&per_page=2#results' => { items => ['c'] },
});
my $fragment_page = HTTP::API::Core::Pagination->new(
    client    => $fragment_client,
    path      => '/users?filter=active#results',
    mode      => 'page',
    items     => 'items',
    page_size => 2,
);
is_deeply(scalar($fragment_page->all), [qw(a b c)], 'page pagination preserves URL fragment');
is_deeply(
    $fragment_client->{calls},
    [
        '/users?filter=active&page=1&per_page=2#results',
        '/users?filter=active&page=2&per_page=2#results',
    ],
    'pagination parameters are inserted before fragment',
);

my $repeat_client = T::Client->new({
    '/x' => { items => [1], next => '/x' },
});
my $repeat = HTTP::API::Core::Pagination->new(
    client => $repeat_client,
    path   => '/x',
);
my $error;
eval { $repeat->all; 1 } or $error = $@;
like($error, qr/pagination continuation repeated/, 'repeated continuation is guarded');

my @urls;
my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    transport => sub {
        my ($method, $url) = @_;
        push @urls, $url;
        return {
            status  => 200,
            reason  => 'OK',
            headers => { 'content-type' => 'application/json' },
            content => $url =~ /(?:[?&])page=2(?:&|$)/
                ? '{"items":[3]}'
                : '{"items":[1,2]}',
        };
    },
);
my $integrated = $api->paginate(
    '/things',
    mode      => 'page',
    page_size => 2,
);
is_deeply(scalar($integrated->all), [1, 2, 3], 'client paginate entry point');
is_deeply(
    \@urls,
    [
        'https://api.example.test/things?page=1&per_page=2',
        'https://api.example.test/things?page=2&per_page=2',
    ],
    'client joins paginated URLs against base URL',
);

my $query_validation_client = T::Client->new({
    '/users?page=1&tag=admin&tag=staff' => { items => [] },
});
my $query_validation = HTTP::API::Core::Pagination->new(
    client => $query_validation_client,
    path   => '/users',
    mode   => 'page',
    items  => 'items',
    query  => { tag => ['admin', undef, 'staff'], skip => undef },
);
is_deeply(scalar($query_validation->all), [], 'pagination omits undefined query values');
is_deeply(
    $query_validation_client->{calls},
    ['/users?page=1&tag=admin&tag=staff'],
    'pagination omits undefined array entries while preserving repeated keys',
);

my $bad_query = HTTP::API::Core::Pagination->new(
    client => T::Client->new({}),
    path   => '/users',
    mode   => 'page',
    query  => { nested => { x => 1 } },
);
my $query_error;
eval { $bad_query->next; 1 } or $query_error = $@;
like $query_error, qr/query values must be scalars/, 'pagination rejects nested query references';

my $bad_array_query = HTTP::API::Core::Pagination->new(
    client => T::Client->new({}),
    path   => '/users',
    mode   => 'page',
    query  => { tag => ['ok', {}] },
);
eval { $bad_array_query->next; 1 } or $query_error = $@;
like $query_error, qr/query parameter array values must contain only scalars or undef/,
    'pagination rejects references inside query arrays';

my $response_aware_client = T::Client->new({
    '/headers' => { items => [1] },
});
{
    package T::HeaderResponse;
    sub new { bless { data => $_[1], headers => $_[2] }, $_[0] }
    sub json { $_[0]{data} }
    sub header { $_[0]{headers}{lc $_[1]} }
}
{
    package T::HeaderClient;
    sub new { bless { calls => [] }, $_[0] }
    sub get {
        my ($self, $url) = @_;
        push @{ $self->{calls} }, $url;
        return T::HeaderResponse->new(
            { items => $url =~ /page=2/ ? [2] : [1] },
            { link => $url =~ /page=2/ ? '' : '</headers?page=2>; rel="next"' },
        );
    }
}
my $header_client = T::HeaderClient->new;
my $header_pager = HTTP::API::Core::Pagination->new(
    client => $header_client,
    path   => '/headers',
    mode   => 'next_url',
    response_aware_extractors => 1,
    items  => 'items',
    next   => sub {
        my ($data, $response) = @_;
        my $link = $response->header('link') || '';
        return $1 if $link =~ /<([^>]+)>;\s*rel="next"/;
        return undef;
    },
);
is_deeply(scalar($header_pager->all), [1, 2],
    'pagination extractor can inspect response headers');

my $fixed_arity_calls = 0;
my $fixed_arity = HTTP::API::Core::Pagination->new(
    client => T::Client->new({ '/fixed' => { items => [] } }),
    path   => '/fixed',
    mode   => 'next_url',
    items  => sub { $fixed_arity_calls++; return $_[0]{items} },
    next   => sub { return undef },
);
is_deeply(scalar($fixed_arity->all), [],
    'existing one-argument-style extractors remain compatible by default');
is $fixed_arity_calls, 1, 'default extractor is invoked once';

done_testing;
