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

done_testing;
