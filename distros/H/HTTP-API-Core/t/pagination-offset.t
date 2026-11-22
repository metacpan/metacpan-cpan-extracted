use strict;
use warnings;
use Test::More;

use HTTP::API::Core::Pagination;

{
    package T::OffsetResponse;
    sub new { bless { data => $_[1] }, $_[0] }
    sub json { $_[0]{data} }
}

{
    package T::OffsetClient;
    sub new { bless { calls => [], pages => $_[1] || {} }, $_[0] }
    sub base_url { 'https://api.example.test' }
    sub get {
        my ($self, $url, %opts) = @_;
        push @{ $self->{calls} }, [$url, { %opts }];
        die "unexpected page: $url\n" if !exists $self->{pages}{$url};
        my $data = $self->{pages}{$url};
        $data = $data->() if ref($data) eq 'CODE';
        return T::OffsetResponse->new($data);
    }
}

sub fails_like {
    my ($code, $pattern, $description) = @_;
    my $error;
    eval { $code->(); 1 } or $error = $@;
    like $error, $pattern, $description;
}

my $prefix = '/jira/rest/api/2/search?fields=summary%2Cdescription%2Ccomponents&jql=filter%3D12345&maxResults=1000&startAt=';
my $client = T::OffsetClient->new({
    $prefix . '0' => { issues => [ { key => 'A' }, { key => 'B' } ], total => 5 },
    $prefix . '2' => { issues => [ { key => 'C' }, { key => 'D' } ], total => 5 },
    $prefix . '4' => { issues => [ { key => 'E' } ], total => 5 },
});
my $pager = HTTP::API::Core::Pagination->new(
    client          => $client,
    path            => '/jira/rest/api/2/search',
    mode            => 'offset',
    items           => 'issues',
    total           => 'total',
    offset_param    => 'startAt',
    page_size_param => 'maxResults',
    page_size       => 1000,
    query           => {
        jql => 'filter=12345',
        fields => 'summary,description,components',
    },
);
is scalar @{ $client->{calls} }, 0, 'offset pagination is lazy';
is_deeply [ map { $_->{key} } $pager->all ], [qw(A B C D E)],
    'total-based pagination continues across server-capped short pages';
is_deeply [map { $_->[0] } @{ $client->{calls} }],
    [map { $prefix . $_ } (0, 2, 4)],
    'offset advances by actual response count, with no extra fetch at total';

my $starting_client = T::OffsetClient->new({
    '/items?limit=2&offset=10' => { items => [10, 11] },
    '/items?limit=2&offset=12' => { items => [12] },
});
my $starting = HTTP::API::Core::Pagination->new(
    client => $starting_client,
    path => '/items',
    mode => 'offset',
    page_size_param => 'limit',
    page_size => 2,
    start_offset => 10,
);
is_deeply scalar($starting->all), [10, 11, 12],
    'offset mode supports non-zero start and short-page fallback';
is scalar @{ $starting_client->{calls} }, 2, 'short page ends without total';

my $more_client = T::OffsetClient->new({
    '/items?offset=0' => { items => [1], more => 1 },
    '/items?offset=1' => { items => [2], more => 0 },
});
my $more = HTTP::API::Core::Pagination->new(
    client => $more_client, path => '/items', mode => 'offset',
    has_more => 'more',
);
is_deeply scalar($more->all), [1, 2],
    'has_more can control offset completion when total is absent';

my $empty_client = T::OffsetClient->new({
    '/items?offset=0' => { items => [], total => 100 },
});
my $empty = HTTP::API::Core::Pagination->new(
    client => $empty_client, path => '/items',
    mode => 'offset', total => 'total',
);
is_deeply scalar($empty->all), [], 'empty page ends even if total indicates more';
is scalar @{ $empty_client->{calls} }, 1, 'empty page never loops indefinitely';

my $attempts = 0;
my $retry_client = T::OffsetClient->new({
    '/items?offset=0' => sub {
        return { items => [1], total => ++$attempts == 1 ? {} : 2 };
    },
    '/items?offset=1' => { items => [2], total => 2 },
});
my $retry = HTTP::API::Core::Pagination->new(
    client => $retry_client, path => '/items',
    mode => 'offset', total => 'total',
);
fails_like(sub { $retry->next },
    qr/pagination total extractor must return a non-negative integer/,
    'invalid total causes an error before exposing page items');
is $retry->next, 1, 'after a malformed total, retry refetches the same page';
is_deeply scalar($retry->all), [2], 'remaining item is returned once';
is_deeply [map { $_->[0] } @{ $retry_client->{calls} }],
    ['/items?offset=0', '/items?offset=0', '/items?offset=1'],
    'invalid total does not advance the offset';

my $noop = T::OffsetClient->new;
for my $case (
    [{ start_offset => -1 }, qr/start_offset must be a non-negative integer/],
    [{ start_offset => [] }, qr/start_offset must be a non-negative integer/],
    [{ offset_param => '' }, qr/pagination offset_param must be a non-empty scalar/],
    [{ total => [] }, qr/pagination total extractor must be a code reference or scalar path/],
) {
    my ($opts, $pattern) = @$case;
    fails_like(
        sub { HTTP::API::Core::Pagination->new(
            client => $noop, path => '/items', mode => 'offset', %$opts,
        ) },
        $pattern,
        'invalid offset parameter is rejected',
    );
}

done_testing;
