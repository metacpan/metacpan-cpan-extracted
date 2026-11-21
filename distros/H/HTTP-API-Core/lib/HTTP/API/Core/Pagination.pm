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
    while (!@{ $self->{buffer} }) {
        return undef if $self->{finished};
        $self->_fetch_page;
    }
    return shift @{ $self->{buffer} };
}

sub all {
    my ($self) = @_;
    my @items;
    while (1) {
        my $item = $self->next;
        last if !defined $item;
        push @items, $item;
    }
    return wantarray ? @items : \@items;
}

sub _fetch_page {
    my ($self) = @_;
    my $url = $self->_request_url;
    my $first_page = !$self->{started};
    my $response = $self->{client}->get($url, %{ $self->{request} });
    my $data = $response->json;
    my $items = _extract($data, $self->{items}, $response, $self->{response_aware_extractors});

    die "pagination items extractor must return an array reference\n" if ref($items) ne 'ARRAY';

    # Stage iterator updates until the continuation is fully validated.
    # A failed page must not leave items in the buffer or advance the cursor.
    my %update = (buffer => [ @$items ], started => 1);
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
    return if !defined($base) || $base !~ m{\A(https?)://([^/]+)}i;
    my ($base_scheme, $base_authority) = (lc($1), lc($2));

    $next =~ m{\A(https?)://([^/]+)}i;
    my ($next_scheme, $next_authority) = (lc($1), lc($2));
    die "cross-origin pagination continuation rejected: $next\n"
        if $base_scheme ne $next_scheme || $base_authority ne $next_authority;
}

sub _guard_continuation {
    my ($self, $key, $seen) = @_;
    $seen = $self->{seen} if !defined $seen;
    die "pagination continuation repeated: $key\n" if $seen->{$key}++;
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
