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
    sub { HTTP::API::Core::Pagination->new(client => $client, path => '/x', mode => 'offset') },
    qr/unsupported pagination mode: offset/,
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
    qr/pagination continuation repeated: url:\/r/,
    'repeated continuation is rejected',
);

done_testing;
