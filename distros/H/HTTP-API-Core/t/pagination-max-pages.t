use strict;
use warnings;
use utf8;
use Test::More;

use HTTP::API::Core::Pagination;

{
    package T::BoundedPageResponse;
    sub new { bless { data => $_[1] }, $_[0] }
    sub json { $_[0]->{data} }
}

{
    package T::BoundedPageClient;
    sub new { bless { pages => $_[1], calls => [] }, $_[0] }
    sub base_url { 'https://api.example.test' }
    sub get {
        my ($self, $url) = @_;
        push @{ $self->{calls} }, $url;
        die "unexpected page: $url\n" if !exists $self->{pages}{$url};
        die "no more responses: $url\n" if !@{ $self->{pages}{$url} };
        return T::BoundedPageResponse->new(shift @{ $self->{pages}{$url} });
    }
}

sub caught_error {
    my ($code) = @_;
    my $error;
    eval { $code->(); 1 } or $error = $@;
    return $error;
}

my $noop = T::BoundedPageClient->new({});
for my $case (
    [ 0, 'zero' ],
    [ -1, 'negative' ],
    [ '1.5', 'fractional' ],
    [ '', 'empty' ],
    [ [], 'array reference' ],
    [ {}, 'hash reference' ],
    [ '１２', 'non-ASCII digits' ],
) {
    my ($value, $label) = @$case;
    like caught_error(sub {
        HTTP::API::Core::Pagination->new(
            client => $noop, path => '/items', max_pages => $value,
        );
    }), qr/max_pages must be a positive integer/,
        "$label max_pages rejected";
}

{
    my $client = T::BoundedPageClient->new({
        '/one'   => [ { items => [1], next => '/two' } ],
        '/two'   => [ { items => [2], next => '/three' } ],
        '/three' => [ { items => [3], next => undef } ],
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/one', max_pages => 2,
    );
    is $pager->next, 1, 'bounded iterator yields first page';
    is $pager->next, 2, 'bounded iterator yields second page';
    like caught_error(sub { $pager->next }),
        qr/pagination maximum page count exceeded/,
        'third page rejected at configured limit';
    like caught_error(sub { $pager->next }),
        qr/pagination maximum page count exceeded/,
        'rechecking the limit does not issue a request';
    is_deeply $client->{calls}, ['/one', '/two'],
        'next URL limit prevents any request for the third page';
}

{
    my $client = T::BoundedPageClient->new({
        '/one' => [ { items => [1], next => '/two' } ],
        '/two' => [ { items => [2], next => undef } ],
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/one', max_pages => '0002',
    );
    is_deeply scalar($pager->all), [1, 2],
        'ending on the exact limit succeeds, including leading zero spelling';
    is $pager->next, undef, 'exhausted paginator remains exhausted at limit';
}

# An empty page with has_more=true may legitimately precede more data.
# Preserve that behavior by default, while allowing callers to cap requests.
{
    my $pages = {
        '/p?page=1' => [ { items => [], more => 1 } ],
        '/p?page=2' => [ { items => [], more => 1 } ],
        '/p?page=3' => [ { items => [7], more => 0 } ],
    };
    my $unbounded = T::BoundedPageClient->new({
        map { $_ => [ @{ $pages->{$_} } ] } keys %$pages
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $unbounded, path => '/p',
        mode => 'page', has_more => 'more',
    );
    is_deeply scalar($pager->all), [7],
        'without max_pages, empty pages obey explicit has_more metadata';
    is_deeply $unbounded->{calls},
        ['/p?page=1', '/p?page=2', '/p?page=3'],
        'unlimited page mode reaches non-empty page after empty pages';

    my $limited = T::BoundedPageClient->new({
        map { $_ => [ @{ $pages->{$_} } ] } keys %$pages
    });
    my $bounded = HTTP::API::Core::Pagination->new(
        client => $limited, path => '/p',
        mode => 'page', has_more => 'more', max_pages => 2,
    );
    like caught_error(sub { $bounded->all }),
        qr/pagination maximum page count exceeded/,
        'empty pages with perpetual has_more cannot exceed the cap';
    is_deeply $limited->{calls},
        ['/p?page=1', '/p?page=2'],
        'limit fails before making a third empty-page request';
}

{
    my $client = T::BoundedPageClient->new({
        '/items?offset=0&per_page=2' => [ { items => [1, 2], total => 4 } ],
        '/items?offset=2&per_page=2' => [ { items => [3, 4], total => 4 } ],
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/items', mode => 'offset',
        page_size => 2, total => 'total', max_pages => 1,
    );
    is $pager->next, 1, 'offset first item is available';
    is $pager->next, 2, 'offset second buffered item is available';
    like caught_error(sub { $pager->next }),
        qr/pagination maximum page count exceeded/,
        'offset mode is also subject to the bound';
    is_deeply $client->{calls}, ['/items?offset=0&per_page=2'],
        'offset next page is not fetched after limit';
}

{
    my $client = T::BoundedPageClient->new({
        '/cursor' => [ { items => [1], next_cursor => 'abc' } ],
        '/cursor?cursor=abc' => [ { items => [2], next_cursor => undef } ],
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/cursor',
        mode => 'cursor', max_pages => 1,
    );
    is $pager->next, 1, 'cursor first item is available';
    like caught_error(sub { $pager->next }),
        qr/pagination maximum page count exceeded/,
        'cursor mode is also subject to the bound';
    is_deeply $client->{calls}, ['/cursor'],
        'cursor follow-up is not requested after limit';
}

{
    my $client = T::BoundedPageClient->new({
        '/retry' => [
            { items => [99], next => [] },
            { items => [9], next => undef },
        ],
    });
    my $pager = HTTP::API::Core::Pagination->new(
        client => $client, path => '/retry', max_pages => 1,
    );
    like caught_error(sub { $pager->next }),
        qr/pagination next URL continuation must be a scalar/,
        'malformed page is rejected without committing it';
    is $pager->next, 9,
        'failed page can be refetched without consuming a page slot';
    is $pager->next, undef, 'successful final page completes at the limit';
    is_deeply $client->{calls}, ['/retry', '/retry'],
        'only validated pages count toward max_pages';
}

done_testing;
