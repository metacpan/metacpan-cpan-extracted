use strict;
use warnings;
use Test::More;
use HTTP::API::Core::Pagination;

{
    package T::PagerResponse;
    sub new { bless { data => $_[1] }, $_[0] }
    sub json { $_[0]{data} }
}

{
    package T::PagerClient;
    sub new { bless { calls => [], pages => $_[1] || {} }, $_[0] }
    sub base_url { defined($_[0]->{base_url}) ? $_[0]->{base_url} : 'https://api.example.com' }
    sub get {
        my ($self, $url, %opts) = @_;
        push @{ $self->{calls} }, [$url, { %opts }];
        die "no page for $url\n" if !exists $self->{pages}{$url};
        return T::PagerResponse->new($self->{pages}{$url});
    }
}

sub dies_like {
    my ($code, $pattern, $name) = @_;
    my $error;
    eval { $code->(); 1 } or $error = $@;
    like $error, $pattern, $name;
}

my $client = T::PagerClient->new({ '/x' => { items => [] } });

dies_like(
    sub { HTTP::API::Core::Pagination->new(path => '/x') },
    qr/client is required/,
    'client is required',
);

dies_like(
    sub { HTTP::API::Core::Pagination->new(client => $client) },
    qr/path is required/,
    'path is required',
);

dies_like(
    sub { HTTP::API::Core::Pagination->new(client => $client, path => '/x', mode => 'unknown') },
    qr/unsupported pagination mode: unknown/,
    'unsupported mode rejected',
);

dies_like(
    sub { HTTP::API::Core::Pagination->new(client => $client, path => '/x', query => []) },
    qr/query must be a hash reference/,
    'query must be a hash reference',
);

dies_like(
    sub { HTTP::API::Core::Pagination->new(client => $client, path => '/x', request => []) },
    qr/request must be a hash reference/,
    'request must be a hash reference',
);

dies_like(
    sub { HTTP::API::Core::Pagination->new(client => $client, path => '/x', page_size => 0) },
    qr/page_size must be a positive integer/,
    'page size must be positive',
);

dies_like(
    sub { HTTP::API::Core::Pagination->new(client => $client, path => '/x', start_page => 0) },
    qr/start_page must be a positive integer/,
    'start page must be positive',
);

dies_like(
    sub { HTTP::API::Core::Pagination->new(client => $client, path => '/x', mystery => 1) },
    qr/unknown pagination option: mystery/,
    'unknown options rejected',
);

my $list_client = T::PagerClient->new({
    '/items' => { items => [1, 2], next => undef },
});
my $list_pager = HTTP::API::Core::Pagination->new(
    client => $list_client,
    path   => '/items',
);
is_deeply([$list_pager->all], [1, 2], 'all returns a list in list context');

my $scalar_client = T::PagerClient->new({
    '/items' => { items => [1, 2], next => undef },
});
my $scalar_pager = HTTP::API::Core::Pagination->new(
    client => $scalar_client,
    path   => '/items',
);
is_deeply(scalar($scalar_pager->all), [1, 2], 'all returns an array reference in scalar context');

my $extract_client = T::PagerClient->new({
    '/items' => { payload => { records => [qw(a b)] }, continuation => undef },
});
my $extract_pager = HTTP::API::Core::Pagination->new(
    client => $extract_client,
    path   => '/items',
    items  => sub { $_[0]{payload}{records} },
    next   => sub { $_[0]{continuation} },
);
is_deeply(scalar($extract_pager->all), [qw(a b)], 'code-reference extractors are supported');

my $bad_items_client = T::PagerClient->new({
    '/bad' => { items => 'not-an-array', next => undef },
});
my $bad_items = HTTP::API::Core::Pagination->new(
    client => $bad_items_client,
    path   => '/bad',
);
dies_like(
    sub { $bad_items->all },
    qr/items extractor must return an array reference/,
    'items extractor must return an array reference',
);

my $page_client = T::PagerClient->new({
    '/p?p=3&size=2' => { items => [1, 2] },
    '/p?p=4&size=2' => { items => [3] },
});
my $page_pager = HTTP::API::Core::Pagination->new(
    client          => $page_client,
    path            => '/p',
    mode            => 'page',
    start_page      => 3,
    page_param      => 'p',
    page_size_param => 'size',
    page_size       => 2,
);
is_deeply(scalar($page_pager->all), [1, 2, 3], 'custom page parameters are honored');
is_deeply(
    [ map { $_->[0] } @{ $page_client->{calls} } ],
    ['/p?p=3&size=2', '/p?p=4&size=2'],
    'custom start page and parameter names form the request URLs',
);

my $has_more_client = T::PagerClient->new({
    '/h?page=1' => { items => [1], more => 1 },
    '/h?page=2' => { items => [2], more => 0 },
});
my $has_more_pager = HTTP::API::Core::Pagination->new(
    client   => $has_more_client,
    path     => '/h',
    mode     => 'page',
    has_more => 'more',
);
is_deeply(scalar($has_more_pager->all), [1, 2], 'has_more extractor controls page continuation');

my $request_client = T::PagerClient->new({
    '/c?cursor=seed&limit=2' => { items => [1], next_cursor => undef },
});
my $request_pager = HTTP::API::Core::Pagination->new(
    client  => $request_client,
    path    => '/c',
    mode    => 'cursor',
    cursor  => 'seed',
    query   => { limit => 2 },
    request => { retry => 0, headers => { 'X-Test' => 'yes' } },
);
is_deeply(scalar($request_pager->all), [1], 'initial cursor and query are honored');
is $request_client->{calls}[0][1]{retry}, 0, 'request options are passed to client get';
is $request_client->{calls}[0][1]{headers}{'X-Test'}, 'yes', 'nested request headers are passed through';

my $repeat_client = T::PagerClient->new({
    '/r' => { items => [1], next => '/r' },
});
my $repeat = HTTP::API::Core::Pagination->new(
    client => $repeat_client,
    path   => '/r',
);
dies_like(
    sub { $repeat->all },
    qr/pagination continuation repeated: url/,
    'repeated continuation is rejected',
);

my $cross_origin_client = T::PagerClient->new({
    '/origin' => { items => [1], next => 'https://evil.example/items?page=2' },
});
my $cross_origin = HTTP::API::Core::Pagination->new(
    client => $cross_origin_client,
    path   => '/origin',
);
dies_like(
    sub { $cross_origin->all },
    qr/cross-origin pagination continuation rejected/,
    'cross-origin absolute continuation is rejected by default',
);
is scalar(@{ $cross_origin_client->{calls} }), 1,
    'cross-origin continuation is rejected before a second request';

my $same_origin_client = T::PagerClient->new({
    '/same' => { items => [1], next => 'https://api.example.com/items?page=2' },
    'https://api.example.com/items?page=2' => { items => [2], next => undef },
});
my $same_origin = HTTP::API::Core::Pagination->new(
    client => $same_origin_client,
    path   => '/same',
);
is_deeply(scalar($same_origin->all), [1, 2],
    'same-origin absolute continuation is allowed');

# Query-only and fragment-only absolute URLs still have the same host.
# Explicit default ports are equivalent to omitted ports in either direction.
for my $case (
    [ 'https://api.example.com', 'https://api.example.com?page=2',
      'query-only absolute continuation remains same-origin' ],
    [ 'https://api.example.com', 'https://api.example.com#next',
      'fragment-only absolute continuation remains same-origin' ],
    [ 'https://api.example.com', 'https://api.example.com:443/items?page=2',
      'explicit HTTPS default port is same-origin' ],
    [ 'https://api.example.com:443', 'https://api.example.com/items?page=2',
      'omitted HTTPS default port is same-origin' ],
    [ 'http://api.example.com', 'http://api.example.com:80/items?page=2',
      'explicit HTTP default port is same-origin' ],
    [ 'http://api.example.com:80', 'http://api.example.com/items?page=2',
      'omitted HTTP default port is same-origin' ],
    [ 'https://api.example.com', 'https://api.example.com:0443/items?page=2',
      'zero-padded HTTPS default port is same-origin' ],
    [ 'https://api.example.com:000443', 'https://api.example.com/items?page=2',
      'zero-padded HTTPS port on base is same-origin' ],
    [ 'https://api.example.com:0443', 'https://api.example.com:000443/items?page=2',
      'equivalent padded HTTPS default ports are same-origin' ],
    [ 'http://api.example.com', 'http://api.example.com:080/items?page=2',
      'zero-padded HTTP default port is same-origin' ],
    [ 'http://api.example.com:00080', 'http://api.example.com/items?page=2',
      'zero-padded HTTP port on base is same-origin' ],
) {
    my ($base, $next, $label) = @$case;
    my $origin_client = T::PagerClient->new({
        '/start' => { items => [1], next => $next },
        $next => { items => [2], next => undef },
    });
    $origin_client->{base_url} = $base;
    my $pager = HTTP::API::Core::Pagination->new(
        client => $origin_client, path => '/start',
    );
    is_deeply(scalar($pager->all), [1, 2], $label);
}

# A default-port match must not permit a different host, non-default
# port, or scheme to receive the client's authenticated requests.
for my $case (
    [ 'https://api.example.com', 'https://api.example.com:444/items',
      'non-default port remains cross-origin' ],
    [ 'https://api.example.com', 'https://api.example.com:0444/items',
      'zero-padded non-default HTTPS port remains cross-origin' ],
    [ 'http://api.example.com', 'http://api.example.com:0800/items',
      'zero-padded non-default HTTP port remains cross-origin' ],
    [ 'https://api.example.com', 'https://evil.example:0443/items',
      'zero-padded default port does not allow a different host' ],
    [ 'https://api.example.com', 'http://api.example.com:80/items',
      'scheme change remains cross-origin' ],
    [ 'https://api.example.com', 'https://api.example.com:443@evil.example/items',
      'userinfo does not disguise a different host' ],
) {
    my ($base, $next, $label) = @$case;
    my $origin_client = T::PagerClient->new({
        '/start' => { items => [1], next => $next },
    });
    $origin_client->{base_url} = $base;
    my $pager = HTTP::API::Core::Pagination->new(
        client => $origin_client, path => '/start',
    );
    dies_like(
        sub { $pager->all },
        qr/cross-origin pagination continuation rejected/,
        $label,
    );
    is scalar(@{ $origin_client->{calls} }), 1,
        "$label: no request to rejected continuation";
}

my $allowed_cross_origin_client = T::PagerClient->new({
    '/allowed' => { items => [1], next => 'https://cdn.example/items?page=2' },
    'https://cdn.example/items?page=2' => { items => [2], next => undef },
});
my $allowed_cross_origin = HTTP::API::Core::Pagination->new(
    client             => $allowed_cross_origin_client,
    path               => '/allowed',
    allow_cross_origin => 1,
);
is_deeply(scalar($allowed_cross_origin->all), [1, 2],
    'cross-origin continuation can be explicitly enabled');


dies_like(
    sub { HTTP::API::Core::Pagination->new(client => $client, path => '/x', page_size => {}) },
    qr/page_size must be a positive integer/,
    'reference-valued page size rejected',
);

dies_like(
    sub { HTTP::API::Core::Pagination->new(client => $client, path => '/x', start_page => []) },
    qr/start_page must be a positive integer/,
    'reference-valued start page rejected',
);

dies_like(
    sub { HTTP::API::Core::Pagination->new(client => $client, path => []) },
    qr/path must be a scalar/,
    'reference-valued path rejected',
);

dies_like(
    sub { HTTP::API::Core::Pagination->new(client => $client, path => '/x', mode => {}) },
    qr/mode must be a scalar/,
    'reference-valued mode rejected',
);

my $false_mode = bless {}, 'T::FalsePaginationMode';
{
    package T::FalsePaginationMode;
    use overload bool => sub { 0 }, fallback => 1;
}

dies_like(
    sub { HTTP::API::Core::Pagination->new(client => $client, path => '/x', mode => $false_mode) },
    qr/mode must be a scalar/,
    'false-overloaded reference-valued mode rejected before defaulting',
);

my $bad_next_client = T::PagerClient->new({
    '/bad-next' => { items => [1], next => {} },
});
my $bad_next = HTTP::API::Core::Pagination->new(
    client => $bad_next_client,
    path   => '/bad-next',
);
dies_like(
    sub { $bad_next->all },
    qr/pagination next URL continuation must be a scalar/,
    'reference-valued next URL continuation rejected',
);

my $bad_cursor_client = T::PagerClient->new({
    '/bad-cursor' => { items => [1], next_cursor => [] },
});
my $bad_cursor = HTTP::API::Core::Pagination->new(
    client => $bad_cursor_client,
    path   => '/bad-cursor',
    mode   => 'cursor',
);
dies_like(
    sub { $bad_cursor->all },
    qr/pagination cursor continuation must be a scalar/,
    'reference-valued cursor continuation rejected',
);


# Continuation values are server-controlled. Tokens must not be echoed in
# ordinary exception messages when a loop or cross-origin URL is rejected.
my $secret_continuation = 'opaque-secret-123abc';

{
    my $url = "/private?token=$secret_continuation";
    my $secret_client = T::PagerClient->new({
        $url => { items => [1], next => $url },
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $secret_client, path => $url,
    );
    my $error;
    eval { $pager->next; 1 } or $error = $@;
    like $error, qr/pagination continuation repeated: url/,
        'URL loop identifies the repeated continuation type';
    unlike $error, qr/\Q$secret_continuation\E/,
        'URL loop error does not include the query token';
    is scalar(@{ $secret_client->{calls} }), 1,
        'repeated sensitive URL is never fetched a second time';
}

{
    my $url = "/cursor?cursor=$secret_continuation";
    my $secret_client = T::PagerClient->new({
        $url => { items => [1], next_cursor => $secret_continuation },
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $secret_client, path => '/cursor',
        mode => 'cursor', cursor => $secret_continuation,
    );
    my $error;
    eval { $pager->next; 1 } or $error = $@;
    like $error, qr/pagination continuation repeated: cursor/,
        'cursor loop identifies the repeated continuation type';
    unlike $error, qr/\Q$secret_continuation\E/,
        'cursor loop error does not include the opaque cursor';
    is scalar(@{ $secret_client->{calls} }), 1,
        'repeated sensitive cursor is never fetched a second time';
}

{
    my $next = "https://evil.example/items?token=$secret_continuation";
    my $secret_client = T::PagerClient->new({
        '/origin' => { items => [1], next => $next },
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $secret_client, path => '/origin',
    );
    my $error;
    eval { $pager->next; 1 } or $error = $@;
    like $error, qr/cross-origin pagination continuation rejected/,
        'cross-origin rejection remains explicit';
    unlike $error, qr/\Q$secret_continuation\E/,
        'cross-origin error does not include the rejected URL token';
    is scalar(@{ $secret_client->{calls} }), 1,
        'rejected sensitive URL is never requested';
}


# Constructor rejection must happen before contacting the client and without
# warnings from coercing malformed option lists or reference-valued options.
my $validation_client = T::PagerClient->new({
    '/validation' => { items => [1], next => undef },
});
for my $case (
    [ [client => $validation_client, path => '/validation', 'dangling'],
      qr/pagination options must be key\/value pairs/, 'odd option list' ],
    [ [client => $validation_client, path => '/validation', [] => 1],
      qr/pagination option names must be scalars/, 'reference option name' ],
    [ [client => undef, path => '/validation'],
      qr/client is required/, 'explicit undefined client' ],
    [ [client => $validation_client, path => '/validation', response_aware_extractors => []],
      qr/response_aware_extractors must be a scalar/, 'reference response-aware flag' ],
    [ [client => $validation_client, path => '/validation', allow_cross_origin => {}],
      qr/allow_cross_origin must be a scalar/, 'reference cross-origin flag' ],
    [ [client => $validation_client, path => '/validation', cursor => []],
      qr/cursor must be a scalar or undef/, 'reference cursor' ],
    [ [client => $validation_client, path => '/validation', start_offset => undef],
      qr/start_offset must be a non-negative integer/, 'undefined start offset' ],
) {
    my ($args, $pattern, $label) = @$case;
    my @warnings;
    my $error;
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        eval { HTTP::API::Core::Pagination->new(@$args); 1 } or $error = $@;
    }
    like $error, $pattern, "$label is rejected";
    is_deeply \@warnings, [], "$label does not cause coercion warnings";
}

for my $name (qw(page_param page_size_param cursor_param offset_param)) {
    for my $case ([undef, 'undefined'], ['', 'empty'], [[], 'reference-valued']) {
        my ($value, $label) = @$case;
        dies_like(
            sub {
                HTTP::API::Core::Pagination->new(
                    client => $validation_client, path => '/validation', $name => $value,
                );
            },
            qr/pagination \Q$name\E must be a non-empty scalar/,
            "$label $name is rejected",
        );
    }
}

is_deeply $validation_client->{calls}, [], 'invalid constructor options never fetch a page';

my $default_mode = HTTP::API::Core::Pagination->new(
    client => $validation_client, path => '/validation', mode => '',
);
is_deeply scalar($default_mode->all), [1], 'empty mode retains next_url default';
is_deeply [map { $_->[0] } @{ $validation_client->{calls} }],
    ['/validation'], 'default mode uses the original URL';

done_testing;
