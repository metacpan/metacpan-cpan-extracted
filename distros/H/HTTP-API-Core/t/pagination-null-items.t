use strict;
use warnings;
use Test::More;

use HTTP::API::Core::Pagination;

{
    package T::NullablePageResponse;
    sub new { bless { data => $_[1] }, $_[0] }
    sub json { $_[0]->{data} }
}

{
    package T::NullablePageClient;
    sub new { bless { pages => $_[1], calls => [] }, $_[0] }
    sub base_url { 'https://api.example.test' }
    sub get {
        my ($self, $url) = @_;
        push @{ $self->{calls} }, $url;
        die "unexpected page: $url\n" if !exists $self->{pages}{$url};
        return T::NullablePageResponse->new($self->{pages}{$url});
    }
}

# JSON null decodes to undef.  It is still an item, not an end marker.
{
    my $client = T::NullablePageClient->new({
        '/first'  => { items => [undef, 2], next => '/second' },
        '/second' => { items => [3, undef], next => undef },
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/first',
    );
    is_deeply scalar($pager->all), [undef, 2, 3, undef],
        'next_url all preserves leading and trailing JSON nulls across pages';
    is_deeply $client->{calls}, ['/first', '/second'],
        'a null item does not stop continuation to the next page';
}

{
    my $client = T::NullablePageClient->new({
        '/one' => { items => [undef], next => undef },
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/one',
    );
    is_deeply [ $pager->all ], [undef],
        'single null item is retained in list context';
    is_deeply [ $pager->all ], [],
        'all remains exhausted after collecting the final null';
}

{
    my $client = T::NullablePageClient->new({
        '/empty' => { items => [], next => '/one' },
        '/one'   => { items => [undef], next => undef },
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/empty',
    );
    is_deeply scalar($pager->all), [undef],
        'empty intermediary page does not manufacture a null item';
    is_deeply $client->{calls}, ['/empty', '/one'],
        'empty intermediary page still follows its continuation';
}

{
    my $client = T::NullablePageClient->new({
        '/items' => { items => [undef, 7], next => undef },
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/items',
    );
    is $pager->next, undef,
        'next retains its existing ambiguous undef return for a null item';
    is_deeply scalar($pager->all), [7],
        'all drains the remaining buffer after next consumed a null item';
}

{
    my $client = T::NullablePageClient->new({
        '/pages?page=1&per_page=2' => { items => [undef, 1] },
        '/pages?page=2&per_page=2' => { items => [undef] },
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/pages', mode => 'page', page_size => 2,
    );
    is_deeply scalar($pager->all), [undef, 1, undef],
        'page-number mode includes null items and ends on a short page';
    is_deeply $client->{calls},
        ['/pages?page=1&per_page=2', '/pages?page=2&per_page=2'],
        'page-number continuation is unaffected by null values';
}

{
    my $client = T::NullablePageClient->new({
        '/cursor'               => { items => [undef], next_cursor => 'next' },
        '/cursor?cursor=next'    => { items => [8, undef], next_cursor => undef },
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/cursor', mode => 'cursor',
    );
    is_deeply scalar($pager->all), [undef, 8, undef],
        'cursor mode preserves null items across pages';
}

{
    my $client = T::NullablePageClient->new({
        '/offset?offset=0&per_page=2' => { items => [undef, 4], total => 3 },
        '/offset?offset=2&per_page=2' => { items => [undef], total => 3 },
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/offset', mode => 'offset',
        page_size => 2, total => 'total',
    );
    is_deeply scalar($pager->all), [undef, 4, undef],
        'offset mode preserves null items and counts them toward total';
    is_deeply $client->{calls},
        ['/offset?offset=0&per_page=2', '/offset?offset=2&per_page=2'],
        'null entries advance the offset by actual item count';
}

done_testing;
