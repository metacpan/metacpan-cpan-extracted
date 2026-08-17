package HTTP::API::Core::Pagination;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $client = delete $args{client} or die "client is required\n";
    my $path   = delete $args{path};
    die "path is required\n" if !defined $path;

    my $mode = delete($args{mode}) || 'next_url';
    die "unsupported pagination mode: $mode\n"
        if $mode ne 'next_url' && $mode ne 'page' && $mode ne 'cursor';

    my $items = delete($args{items});
    $items = 'items' if !defined $items;

    my $self = bless {
        client          => $client,
        path            => $path,
        mode            => $mode,
        items           => $items,
        next            => exists($args{next}) ? delete($args{next}) : ($mode eq 'cursor' ? 'next_cursor' : 'next'),
        has_more        => delete($args{has_more}),
        page_param      => delete($args{page_param}) || 'page',
        page_size_param => delete($args{page_size_param}) || 'per_page',
        page_size       => delete($args{page_size}),
        current_page    => exists($args{start_page}) ? delete($args{start_page}) : 1,
        cursor_param    => delete($args{cursor_param}) || 'cursor',
        cursor          => delete($args{cursor}),
        query           => delete($args{query}) || {},
        request         => delete($args{request}) || {},
        buffer          => [],
        finished        => 0,
        started         => 0,
        seen            => {},
    }, $class;

    die "query must be a hash reference\n" if ref($self->{query}) ne 'HASH';
    die "request must be a hash reference\n" if ref($self->{request}) ne 'HASH';
    die "page_size must be a positive integer\n"
        if defined($self->{page_size}) && ($self->{page_size} !~ /\A\d+\z/ || $self->{page_size} < 1);
    die "start_page must be a positive integer\n"
        if $self->{current_page} !~ /\A\d+\z/ || $self->{current_page} < 1;
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
    my $response = $self->{client}->get($url, %{ $self->{request} });
    my $data = $response->json;
    my $items = _extract($data, $self->{items});

    die "pagination items extractor must return an array reference\n" if ref($items) ne 'ARRAY';
    $self->{buffer} = [ @$items ];
    $self->{started} = 1;

    if ($self->{mode} eq 'next_url') {
        my $next = _extract($data, $self->{next});
        if (!defined($next) || $next eq '') {
            $self->{finished} = 1;
        }
        else {
            $self->_guard_continuation("url:$next");
            $self->{path} = $next;
        }
    }
    elsif ($self->{mode} eq 'cursor') {
        my $next = _extract($data, $self->{next});
        if (!defined($next) || $next eq '') {
            $self->{finished} = 1;
        }
        else {
            $self->_guard_continuation("cursor:$next");
            $self->{cursor} = $next;
        }
    }
    else {
        my $has_more;
        if (defined $self->{has_more}) {
            $has_more = _extract($data, $self->{has_more}) ? 1 : 0;
        }
        elsif (defined $self->{page_size}) {
            $has_more = @$items >= $self->{page_size} ? 1 : 0;
        }
        else {
            $has_more = @$items ? 1 : 0;
        }

        if ($has_more) {
            $self->{current_page}++;
        }
        else {
            $self->{finished} = 1;
        }
    }

    $self->{finished} = 1 if !@$items && $self->{mode} eq 'page' && !defined($self->{has_more});
}

sub _request_url {
    my ($self) = @_;
    return $self->{path} if $self->{mode} eq 'next_url' && $self->{started};

    my %query = %{ $self->{query} };
    if ($self->{mode} eq 'page') {
        $query{ $self->{page_param} } = $self->{current_page};
        $query{ $self->{page_size_param} } = $self->{page_size} if defined $self->{page_size};
    }
    elsif ($self->{mode} eq 'cursor' && defined($self->{cursor}) && $self->{cursor} ne '') {
        $query{ $self->{cursor_param} } = $self->{cursor};
    }

    return _append_query($self->{path}, \%query);
}

sub _guard_continuation {
    my ($self, $key) = @_;
    die "pagination continuation repeated: $key\n" if $self->{seen}{$key}++;
}

sub _extract {
    my ($data, $extractor) = @_;
    return $extractor->($data) if ref($extractor) eq 'CODE';
    return $data if !defined($extractor) || $extractor eq '';

    my $value = $data;
    for my $part (split /\./, $extractor) {
        return undef if !defined $value;
        if (ref($value) eq 'HASH') {
            $value = $value->{$part};
        }
        elsif (ref($value) eq 'ARRAY' && $part =~ /\A\d+\z/) {
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
        next if !defined $query->{$key};
        my @values = ref($query->{$key}) eq 'ARRAY' ? @{ $query->{$key} } : ($query->{$key});
        push @pairs, map { _escape($key) . '=' . _escape($_) } @values;
    }
    return $url if !@pairs;
    my $sep = index($url, '?') >= 0 ? '&' : '?';
    return $url . $sep . join('&', @pairs);
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
