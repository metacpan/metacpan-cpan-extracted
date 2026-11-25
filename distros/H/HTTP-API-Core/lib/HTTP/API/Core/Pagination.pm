package HTTP::API::Core::Pagination;

use strict;
use warnings;

sub new {
    my $class = shift;
    die "pagination options must be key/value pairs\n" if @_ % 2;
    die "pagination option names must be scalars\n"
        if grep { ref($_) ne '' } @_[ grep { $_ % 2 == 0 } 0 .. $#_ ];
    my %args = @_;
    die "client is required\n" if !exists $args{client} || !defined $args{client};
    my $client = delete $args{client};
    my $path   = delete $args{path};
    die "path is required\n" if !defined $path;
    die "path must be a scalar\n" if ref($path) ne '';

    my $mode = delete($args{mode});
    die "mode must be a scalar\n" if ref($mode) ne '';
    $mode = 'next_url' if !defined($mode) || $mode eq '';
    die "unsupported pagination mode: $mode\n"
        if $mode ne 'next_url' && $mode ne 'page'
        && $mode ne 'cursor' && $mode ne 'offset';

    my $items = delete($args{items});
    $items = 'items' if !defined $items;

    my $response_aware_extractors = delete($args{response_aware_extractors});
    die "response_aware_extractors must be a scalar\n"
        if defined($response_aware_extractors) && ref($response_aware_extractors) ne '';
    my $allow_cross_origin = delete($args{allow_cross_origin});
    die "allow_cross_origin must be a scalar\n"
        if defined($allow_cross_origin) && ref($allow_cross_origin) ne '';

    my $self = bless {
        client          => $client,
        path            => $path,
        mode            => $mode,
        items           => $items,
        next            => exists($args{next}) ? delete($args{next}) : ($mode eq 'cursor' ? 'next_cursor' : 'next'),
        has_more        => delete($args{has_more}),
        total           => delete($args{total}),
        response_aware_extractors => $response_aware_extractors ? 1 : 0,
        allow_cross_origin => $allow_cross_origin ? 1 : 0,
        page_param      => exists($args{page_param}) ? delete($args{page_param}) : 'page',
        page_size_param => exists($args{page_size_param}) ? delete($args{page_size_param}) : 'per_page',
        page_size       => delete($args{page_size}),
        max_pages       => delete($args{max_pages}),
        current_page    => exists($args{start_page}) ? delete($args{start_page}) : 1,
        offset_param    => exists($args{offset_param}) ? delete($args{offset_param}) : 'offset',
        current_offset  => exists($args{start_offset}) ? delete($args{start_offset}) : 0,
        cursor_param    => exists($args{cursor_param}) ? delete($args{cursor_param}) : 'cursor',
        cursor          => delete($args{cursor}),
        query           => exists($args{query}) ? delete($args{query}) : {},
        request         => exists($args{request}) ? delete($args{request}) : {},
        buffer          => [],
        finished        => 0,
        started         => 0,
        pages_fetched   => 0,
        seen            => {},
    }, $class;

    for my $name (qw(items next has_more total)) {
        next if !defined $self->{$name};
        die "pagination $name extractor must be a code reference or scalar path\n"
            if ref($self->{$name}) ne '' && ref($self->{$name}) ne 'CODE';
    }
    for my $name (qw(page_param page_size_param cursor_param offset_param)) {
        die "pagination $name must be a non-empty scalar\n"
            if !defined($self->{$name}) || ref($self->{$name}) ne '' || $self->{$name} eq '';
    }

    die "cursor must be a scalar or undef\n"
        if defined($self->{cursor}) && ref($self->{cursor}) ne '';
    die "query must be a hash reference\n" if ref($self->{query}) ne 'HASH';
    die "request must be a hash reference\n" if ref($self->{request}) ne 'HASH';
    die "page_size must be a positive integer\n"
        if defined($self->{page_size}) && (ref($self->{page_size}) ne '' || $self->{page_size} !~ /\A[0-9]+\z/ || $self->{page_size} < 1);
    die "max_pages must be a positive integer\n"
        if defined($self->{max_pages})
        && (ref($self->{max_pages}) ne ''
            || $self->{max_pages} !~ /\A[0-9]+\z/
            || $self->{max_pages} < 1);
    die "start_page must be a positive integer\n"
        if ref($self->{current_page}) ne '' || $self->{current_page} !~ /\A[0-9]+\z/ || $self->{current_page} < 1;
    die "start_offset must be a non-negative integer\n"
        if !defined($self->{current_offset})
        || ref($self->{current_offset}) ne ''
        || $self->{current_offset} !~ /\A[0-9]+\z/;
    die "unknown pagination option: $_\n" for sort keys %args;

    return $self;
}

sub next {
    my ($self) = @_;
    my ($has_item, $item) = $self->_take_item;
    return $item;
}

# Keep item availability separate from item value: a decoded JSON null
# is undef, but it is still a real item in the page.
sub _take_item {
    my ($self) = @_;
    while (!@{ $self->{buffer} }) {
        return (0, undef) if $self->{finished};
        $self->_fetch_page;
    }
    return (1, shift @{ $self->{buffer} });
}

sub all {
    my ($self) = @_;
    my @items;
    while (1) {
        my ($has_item, $item) = $self->_take_item;
        last if !$has_item;
        push @items, $item;
    }
    return wantarray ? @items : \@items;
}

sub _fetch_page {
    my ($self) = @_;
    # A page limit guards against a server that keeps reporting more pages,
    # including empty pages with has_more set. Do not send another request.
    die "pagination maximum page count exceeded\n"
        if defined($self->{max_pages})
        && $self->{pages_fetched} >= $self->{max_pages};
    my $url = $self->_request_url;
    my $first_page = !$self->{started};
    my $response = $self->{client}->get($url, %{ $self->{request} });
    my $data = $response->json;
    my $items = _extract($data, $self->{items}, $response, $self->{response_aware_extractors});

    die "pagination items extractor must return an array reference\n" if ref($items) ne 'ARRAY';

    # Stage iterator updates until the continuation is fully validated.
    # A failed page must not leave items in the buffer or advance the cursor.
    my %update = (
        buffer => [ @$items ],
        started => 1,
        pages_fetched => $self->{pages_fetched} + 1,
    );
    my %seen = %{ $self->{seen} };

    # Continuations must not revisit the initial page or a supplied cursor.
    # These values were previously absent from the seen-continuation set.
    if ($first_page) {
        if ($self->{mode} eq 'next_url') {
            $seen{"url:$url"} = 1;
        }
        elsif ($self->{mode} eq 'cursor'
            && defined($self->{cursor}) && $self->{cursor} ne '') {
            $seen{"cursor:$self->{cursor}"} = 1;
        }
    }

    if ($self->{mode} eq 'next_url') {
        my $next = _extract($data, $self->{next}, $response, $self->{response_aware_extractors});
        die "pagination next URL continuation must be a scalar\n" if defined($next) && ref($next) ne '';
        if (!defined($next) || $next eq '') {
            $update{finished} = 1;
        }
        else {
            $self->_guard_next_url_origin($next);
            $self->_guard_continuation("url:$next", \%seen);
            $update{path} = $next;
        }
    }
    elsif ($self->{mode} eq 'cursor') {
        my $next = _extract($data, $self->{next}, $response, $self->{response_aware_extractors});
        die "pagination cursor continuation must be a scalar\n" if defined($next) && ref($next) ne '';
        if (!defined($next) || $next eq '') {
            $update{finished} = 1;
        }
        else {
            $self->_guard_continuation("cursor:$next", \%seen);
            $update{cursor} = $next;
        }
    }
    elsif ($self->{mode} eq 'offset') {
        # Advance by the actual number of items returned. Services may impose
        # a smaller page size than requested, so an explicit total is the most
        # reliable completion signal for offset-based APIs.
        my $next_offset = $self->{current_offset} + @$items;
        my $finished = !@$items;

        if (defined $self->{total}) {
            my $total = _extract($data, $self->{total}, $response, $self->{response_aware_extractors});
            die "pagination total extractor must return a non-negative integer\n"
                if !defined($total) || ref($total) ne ''
                || $total !~ /\A[0-9]+\z/;
            $finished = 1 if $next_offset >= $total;
        }
        elsif (defined $self->{has_more}) {
            $finished = 1
                if !_extract($data, $self->{has_more}, $response, $self->{response_aware_extractors});
        }
        elsif (defined $self->{page_size}) {
            $finished = 1 if @$items < $self->{page_size};
        }

        if ($finished) {
            $update{finished} = 1;
        }
        else {
            $update{current_offset} = $next_offset;
        }
    }
    else {
        my $has_more;
        if (defined $self->{has_more}) {
            $has_more = _extract($data, $self->{has_more}, $response, $self->{response_aware_extractors}) ? 1 : 0;
        }
        elsif (defined $self->{page_size}) {
            $has_more = @$items >= $self->{page_size} ? 1 : 0;
        }
        else {
            $has_more = @$items ? 1 : 0;
        }

        if ($has_more) {
            $update{current_page} = $self->{current_page} + 1;
        }
        else {
            $update{finished} = 1;
        }
    }

    $update{finished} = 1 if !@$items && $self->{mode} eq 'page' && !defined($self->{has_more});
    $update{seen} = \%seen;
    $self->{$_} = $update{$_} for keys %update;
}

sub _request_url {
    my ($self) = @_;
    return $self->{path} if $self->{mode} eq 'next_url' && $self->{started};

    my %query = %{ $self->{query} };
    if ($self->{mode} eq 'page') {
        $query{ $self->{page_param} } = $self->{current_page};
        $query{ $self->{page_size_param} } = $self->{page_size} if defined $self->{page_size};
    }
    elsif ($self->{mode} eq 'offset') {
        $query{ $self->{offset_param} } = $self->{current_offset};
        $query{ $self->{page_size_param} } = $self->{page_size} if defined $self->{page_size};
    }
    elsif ($self->{mode} eq 'cursor' && defined($self->{cursor}) && $self->{cursor} ne '') {
        $query{ $self->{cursor_param} } = $self->{cursor};
    }

    return _append_query($self->{path}, \%query);
}

sub _guard_next_url_origin {
    my ($self, $next) = @_;
    return if $self->{allow_cross_origin};
    return if $next !~ m{\Ahttps?://}i;

    my $base = $self->{client}->base_url;
    return if !defined($base) || $base !~ m{\A(https?)://([^/?#]+)}i;
    my ($base_scheme, $base_authority) = (lc($1), lc($2));

    die "invalid pagination continuation URL\n"
        if $next !~ m{\A(https?)://([^/?#]+)}i;
    my ($next_scheme, $next_authority) = (lc($1), lc($2));

    # Explicit default ports (including leading zeros) and omitted ports
    # represent the same origin. Keep other authority forms conservative.
    if ($base_scheme eq $next_scheme) {
        my $default_port = $base_scheme eq 'https' ? 443 : 80;
        $base_authority =~ s/:0*$default_port\z//;
        $next_authority =~ s/:0*$default_port\z//;
    }
    # The server-controlled continuation may contain credentials.
    die "cross-origin pagination continuation rejected\n"
        if $base_scheme ne $next_scheme || $base_authority ne $next_authority;
}

sub _guard_continuation {
    my ($self, $key, $seen) = @_;
    $seen = $self->{seen} if !defined $seen;
    if ($seen->{$key}++) {
        # Keep the error useful without echoing a token or URL from an API.
        my ($type) = $key =~ /\A(url|cursor):/;
        $type = 'unknown' if !defined $type;
        die "pagination continuation repeated: $type\n";
    }
}

sub _extract {
    my ($data, $extractor, $response, $response_aware) = @_;
    return $response_aware ? $extractor->($data, $response) : $extractor->($data)
        if ref($extractor) eq 'CODE';
    return $data if !defined($extractor) || $extractor eq '';

    my $value = $data;
    for my $part (split /\./, $extractor) {
        return undef if !defined $value;
        if (ref($value) eq 'HASH') {
            $value = $value->{$part};
        }
        elsif (ref($value) eq 'ARRAY' && $part =~ /\A[0-9]+\z/) {
            $value = $value->[$part];
        }
        else {
            return undef;
        }
    }
    return $value;
}

sub _append_query {
    my ($url, $query) = @_;
    my @pairs;
    for my $key (sort keys %$query) {
        die "query parameter names must be scalars\n" if ref($key) ne '';
        my $value = $query->{$key};
        next if !defined $value;

        my @values;
        if (ref($value) eq 'ARRAY') {
            die "query parameter array values must contain only scalars or undef\n"
                if grep { defined($_) && ref($_) ne '' } @$value;
            @values = grep { defined $_ } @$value;
        }
        elsif (ref($value) ne '') {
            die "query values must be scalars, array references, or undef\n";
        }
        else {
            @values = ($value);
        }

        push @pairs, map { _escape($key) . '=' . _escape($_) } @values;
    }
    return $url if !@pairs;

    my $fragment = '';
    if ($url =~ s/(#.*)\z//) {
        $fragment = $1;
    }

    my $sep = index($url, '?') >= 0 ? '&' : '?';
    return $url . $sep . join('&', @pairs) . $fragment;
}

sub _escape {
    my ($value) = @_;
    $value = '' if !defined $value;
    my $bytes = "$value";
    utf8::encode($bytes) if utf8::is_utf8($bytes);
    $bytes =~ s/([^A-Za-z0-9\-._~])/sprintf('%%%02X', ord($1))/ge;
    return $bytes;
}

1;

__END__

=head1 NAME

HTTP::API::Core::Pagination - Iterate through HTTP API response pages

=head1 SYNOPSIS

    my $pager = $api->paginate(
        '/users',
        mode      => 'page',
        page_size => 100,
        max_pages => 50,
    );

    my $items = $pager->all;

=head1 DESCRIPTION

Provides lazy, synchronous pagination for C<next_url>, C<page>, C<cursor>,
and C<offset> APIs. Requests are issued only when more items are needed.
The default mode is C<next_url>. See L<HTTP::API::Core> for the client
interface.

=head1 METHODS

=head2 new

    my $pager = HTTP::API::Core::Pagination->new(
        client => $api,
        path   => '/users',
        mode   => 'next_url',
        items  => 'data.items',
        next   => 'links.next',
    );

Constructs a paginator without fetching a page. Normally use the client's
C<paginate> method. C<client> and C<path> are required.

C<items>, C<next>, C<has_more>, and C<total> accept dotted paths or code
references. A code reference receives the decoded body; with
C<response_aware_extractors> enabled, it also receives the response object.
The items extractor must return an array reference. An empty items path
selects the whole decoded body.

C<query> and C<request> are hash references. Query options are applied
when constructing page requests; subsequent C<next_url> continuations
are followed as returned. Request options are passed to the client on
every page. Absolute HTTP(S) continuation URLs are restricted to the
client's configured origin by default; C<allow_cross_origin> explicitly
opts out of that check.

C<page_size>, when supplied, must be a positive integer. Page numbering
starts at C<start_page> (default 1); offset numbering starts at
C<start_offset> (default 0) and advances by the actual returned item count.
For offset mode, an explicit C<total> takes precedence over C<has_more>.
C<max_pages> optionally limits the number of successfully validated pages.
The default is unlimited. If another page is needed after that limit,
an exception is raised before another request.

=head2 next

    my $item = $pager->next;

Returns the next item, or C<undef> at exhaustion. A decoded JSON null
item also returns C<undef>, so this interface cannot distinguish null
from exhaustion. Use C<all> if null items must be preserved.

=head2 all

    my $items = $pager->all;
    my @items = $pager->all;

Consumes the remaining items. Returns an array reference in scalar
context or a list in list context. JSON null items are preserved as
C<undef> elements. Items already consumed through C<next> are not returned
again.

=head1 ERRORS

Malformed item or continuation metadata, repeated continuations and
page limit violations raise exceptions. A page is committed only after
its response and continuation have been validated; a failed page does
not advance the iterator or consume its page allowance. A subsequent
call may retry that page. Earlier successful pages remain consumed.

Continuation errors do not include the rejected URL or cursor value,
which could contain sensitive data.

=head1 SEE ALSO

L<HTTP::API::Core>

=cut
