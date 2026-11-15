use strict;
use warnings;
use Test::More;
use HTTP::API::Core::Pagination;

{
    package T::InitialLoopResponse;
    sub new { bless { data => $_[1] }, $_[0] }
    sub json { $_[0]->{data} }
}

{
    package T::InitialLoopClient;
    sub new { bless { pages => $_[1], calls => [] }, $_[0] }
    sub get {
        my ($self, $url) = @_;
        push @{ $self->{calls} }, $url;
        die "unexpected page request: $url\n"
            if !exists $self->{pages}{$url};
        return T::InitialLoopResponse->new($self->{pages}{$url});
    }
}

sub caught_error {
    my ($pager) = @_;
    my $error;
    eval { $pager->all; 1 } or $error = $@;
    return $error;
}

{
    my $client = T::InitialLoopClient->new({
        '/items' => { items => [1], next => '/items' },
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/items',
    );
    like caught_error($pager), qr/pagination continuation repeated: url:\/items/,
        'self-loop to initial URL is rejected';
    is_deeply $client->{calls}, ['/items'],
        'self-loop does not fetch the initial URL twice';
}

{
    my $client = T::InitialLoopClient->new({
        '/a' => { items => [1], next => '/b' },
        '/b' => { items => [2], next => '/a' },
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/a',
    );
    like caught_error($pager), qr/pagination continuation repeated: url:\/a/,
        'two-page cycle back to initial URL is rejected';
    is_deeply $client->{calls}, ['/a', '/b'],
        'two-page cycle is stopped before a third request';
}

{
    my $client = T::InitialLoopClient->new({
        '/items?limit=2' => {
            items => [1], next => '/items?limit=2',
        },
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/items', query => { limit => 2 },
    );
    like caught_error($pager),
        qr/pagination continuation repeated: url:\/items\?limit=2/,
        'initial URL including pagination query is protected';
    is_deeply $client->{calls}, ['/items?limit=2'],
        'initial query URL is fetched only once';
}

for my $seed ('seed', '0') {
    my $url = "/cursor?cursor=$seed";
    my $client = T::InitialLoopClient->new({
        $url => { items => [1], next_cursor => $seed },
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client,
        path => '/cursor',
        mode => 'cursor',
        cursor => $seed,
    );
    like caught_error($pager),
        qr/pagination continuation repeated: cursor:\Q$seed\E/,
        "returned initial cursor $seed is rejected";
    is_deeply $client->{calls}, [$url],
        "initial cursor $seed is not fetched twice";
}

{
    my $client = T::InitialLoopClient->new({
        '/cursor?cursor=seed' => { items => [1], next_cursor => 'next' },
        '/cursor?cursor=next' => { items => [2], next_cursor => undef },
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client,
        path => '/cursor',
        mode => 'cursor',
        cursor => 'seed',
    );
    is_deeply scalar($pager->all), [1, 2],
        'valid progression from an initial cursor remains supported';
    is_deeply $client->{calls},
        ['/cursor?cursor=seed', '/cursor?cursor=next'],
        'advancing cursors are requested once each';
}

{
    my $client = T::InitialLoopClient->new({
        '/a' => { items => [1], next => '/b' },
        '/b' => { items => [2], next => '/c' },
        '/c' => { items => [3], next => undef },
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/a',
    );
    is_deeply scalar($pager->all), [1, 2, 3],
        'normal next-URL pagination remains supported';
    is_deeply $client->{calls}, ['/a', '/b', '/c'],
        'valid next URLs are requested once each';
}

done_testing;
