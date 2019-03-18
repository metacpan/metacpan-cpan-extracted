package HTTP::AnyUA::Util;
# ABSTRACT: Utility subroutines for HTTP::AnyUA backends and middleware

use warnings;
use strict;

our $VERSION = '0.904'; # VERSION

use Exporter qw(import);


our @EXPORT_OK = qw(
    http_headers_to_native
    native_to_http_request
    coderef_content_to_string
    normalize_headers
    internal_exception
    http_date
    parse_http_date
    uri_escape
    www_form_urlencode
);


sub _croak { require Carp; Carp::croak(@_) }
sub _usage { _croak("Usage: @_\n") }


sub coderef_content_to_string {
    my $content = shift;

    return $content if !$content;

    if (ref($content) eq 'CODE') {
        # drain the request body
        my $body = '';
        while (my $chunk = $content->()) {
            $body .= $chunk;
        }
        $content = $body;
    }

    return $content;
}


sub native_to_http_request {
    my $method  = shift;
    my $url     = shift;
    my $args    = shift || {};

    my $headers = [];
    my $content = $args->{content};     # works as either scalar or coderef

    # flatten headers
    for my $header (keys %{$args->{headers} || {}}) {
        my $value  = $args->{headers}{$header};
        my @values = ref($value) eq 'ARRAY' ? @$value : ($value);
        for my $v (@values) {
            push @$headers, ($header => $v);
        }
    }

    require HTTP::Request;
    return HTTP::Request->new($method, $url, $headers, $content);
}


sub http_headers_to_native {
    my $http_headers = shift;

    my $native;

    for my $header ($http_headers->header_field_names) {
        my @values = $http_headers->header($header);
        $native->{lc($header)} = @values == 1 ? $values[0] : [@values];
    }

    return $native;
}


sub normalize_headers {
    my $headers_in = shift;

    my $headers = {};

    if (defined $headers_in) {
        while (my ($key, $value) = each %{$headers_in || {}}) {
            $headers->{lc($key)} = $value;
        }
    }

    return $headers;
}


sub internal_exception {
    my $e       = shift or _usage(q{internal_exception($exception)});
    my $resp    = shift || {};

    $e = "$e";

    $resp->{headers}{'client-original-status'} = $resp->{status} if $resp->{status};
    $resp->{headers}{'client-original-reason'} = $resp->{reason} if $resp->{reason};

    $resp->{success}    = '';
    $resp->{status}     = 599;
    $resp->{reason}     = 'Internal Exception';
    $resp->{content}    = $e;
    $resp->{headers}{'content-type'}    = 'text/plain';
    $resp->{headers}{'content-length'}  = length $e;

    return $resp;
}


# adapted from HTTP/Tiny.pm
sub split_url {
    my $url = shift or _usage(q{split_url($url)});

    # URI regex adapted from the URI module
    my ($scheme, $host, $path_query) = $url =~ m<\A([^:/?#]+)://([^/?#]*)([^#]*)>
        or die(qq/Cannot parse URL: '$url'\n/);

    $scheme     = lc $scheme;
    $path_query = "/$path_query" unless $path_query =~ m<\A/>;

    my $auth = '';
    if ( (my $i = index $host, '@') != -1 ) {
        # user:pass@host
        $auth = substr $host, 0, $i, ''; # take up to the @ for auth
        substr $host, 0, 1, '';          # knock the @ off the host

        # userinfo might be percent escaped, so recover real auth info
        $auth =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    }
    my $port = $host =~ s/:(\d*)\z// && length $1 ? $1
             : $scheme eq 'http'                  ? 80
             : $scheme eq 'https'                 ? 443
             : undef;

    return ($scheme, (length $host ? lc $host : "localhost") , $port, $path_query, $auth);
}


# Date conversions adapted from HTTP::Date
# adapted from HTTP/Tiny.pm
my $DoW = 'Sun|Mon|Tue|Wed|Thu|Fri|Sat';
my $MoY = 'Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec';
sub http_date {
    my $time = shift or _usage(q{http_date($time)});
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($time);
    return sprintf('%s, %02d %s %04d %02d:%02d:%02d GMT',
        substr($DoW,$wday*4,3),
        $mday, substr($MoY,$mon*4,3), $year+1900,
        $hour, $min, $sec
    );
}


# adapted from HTTP/Tiny.pm
sub parse_http_date {
    my $str = shift or _usage(q{parse_http_date($str)});
    my @tl_parts;
    if ($str =~ /^[SMTWF][a-z]+, +(\d{1,2}) ($MoY) +(\d\d\d\d) +(\d\d):(\d\d):(\d\d) +GMT$/) {
        @tl_parts = ($6, $5, $4, $1, (index($MoY,$2)/4), $3);
    }
    elsif ($str =~ /^[SMTWF][a-z]+, +(\d\d)-($MoY)-(\d{2,4}) +(\d\d):(\d\d):(\d\d) +GMT$/ ) {
        @tl_parts = ($6, $5, $4, $1, (index($MoY,$2)/4), $3);
    }
    elsif ($str =~ /^[SMTWF][a-z]+ +($MoY) +(\d{1,2}) +(\d\d):(\d\d):(\d\d) +(?:[^0-9]+ +)?(\d\d\d\d)$/ ) {
        @tl_parts = ($5, $4, $3, $2, (index($MoY,$1)/4), $6);
    }
    require Time::Local;
    return eval {
        my $t = @tl_parts ? Time::Local::timegm(@tl_parts) : -1;
        $t < 0 ? undef : $t;
    };
}


# URI escaping adapted from URI::Escape
# c.f. http://www.w3.org/TR/html4/interact/forms.html#h-17.13.4.1
# perl 5.6 ready UTF-8 encoding adapted from JSON::PP
# adapted from HTTP/Tiny.pm
my %escapes = map { chr($_) => sprintf('%%%02X', $_) } 0..255;
$escapes{' '} = '+';
my $unsafe_char = qr/[^A-Za-z0-9\-\._~]/;

sub uri_escape {
    my $str = shift or _usage(q{uri_escape($str)});
    if ($] ge '5.008') {
        utf8::encode($str);
    }
    else {
        $str = pack('U*', unpack('C*', $str))   # UTF-8 encode a byte string
            if (length $str == do { use bytes; length $str });
        $str = pack('C*', unpack('C*', $str));  # clear UTF-8 flag
    }
    $str =~ s/($unsafe_char)/$escapes{$1}/ge;
    return $str;
}


# adapted from HTTP/Tiny.pm
sub www_form_urlencode {
    my $data = shift;
    ($data && ref $data)
        or _usage(q{www_form_urlencode($dataref)});
    (ref $data eq 'HASH' || ref $data eq 'ARRAY')
        or _croak("form data must be a hash or array reference\n");

    my @params = ref $data eq 'HASH' ? %$data : @$data;
    @params % 2 == 0
        or _croak("form data reference must have an even number of terms\n");

    my @terms;
    while (@params) {
        my ($key, $value) = splice(@params, 0, 2);
        if (ref $value eq 'ARRAY') {
            unshift @params, map { $key => $_ } @$value;
        }
        else {
            push @terms, join('=', map { uri_escape($_) } $key, $value);
        }
    }

    return join('&', ref($data) eq 'ARRAY' ? @terms : sort @terms);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::AnyUA::Util - Utility subroutines for HTTP::AnyUA backends and middleware

=head1 VERSION

version 0.904

=head1 FUNCTIONS

=head2 coderef_content_to_string

    $content = coderef_content_to_string(\&code);
    $content = coderef_content_to_string($content);     # noop

Convert a coderef into a string of content by iteratively calling the coderef and concatenating the
chunks it provides until the coderef returns undef or an empty string.

=head2 native_to_http_request

    $http_request = native_to_http_request($method, $url);
    $http_request = native_to_http_request($method, $url, \%options);

Convert a "native" request tuple to an L<HTTP::Request> object.

=head2 http_headers_to_native

    $headers = http_headers_to_native($http_headers);

Convert an L<HTTP::Headers> object to a "native" hashref.

=head2 normalize_headers

    $normalized_headers = normalize_headers(\%headers);

Normalize headers. Currently lowercases header keys.

=head2 internal_exception

    $response = internal_exception($content);
    $response = internal_exception($content, $response);

Create an internal exception response. If an existing response is passed, that response will have
its fields modified to become an internal exception.

=head2 split_url

    ($scheme, $host, $port, $path_query, $auth) = split_url($url);

Split a URL into its components.

=head2 http_date

    $http_date = http_date($epoch_time);

Convert an epoch time into a date format suitable for HTTP.

=head2 parse_http_date

    $epoch_time = parse_http_date($http_date);

Convert an HTTP date into an epoch time. Returns undef if the date cannot be parsed.

=head2 uri_escape

    $escaped = uri_escape($unescaped);

Escape a string for use in a URL query param or as C<application/x-www-form-urlencoded> data.

=head2 www_form_urlencode

    $bytes = www_form_urlencode(\%form_data);
    $bytes = www_form_urlencode(\@form_data);

Encode a hashref or arrayref as C<application/x-www-form-urlencoded> data.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/HTTP-AnyUA/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
