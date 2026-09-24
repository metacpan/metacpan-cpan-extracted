package HTTP::API::Core::Example::TransportAdapters;

use strict;
use warnings;

sub http_tiny {
    my ($http) = @_;
    die "HTTP::Tiny-compatible object is required\n"
        if !$http || !$http->can('request');

    return sub {
        my ($method, $url, $opts) = @_;
        return $http->request($method, $url, {
            headers => $opts->{headers} || {},
            (exists($opts->{content}) ? (content => $opts->{content}) : ()),
        });
    };
}

sub lwp_user_agent {
    my ($ua) = @_;
    die "LWP::UserAgent-compatible object is required\n"
        if !$ua || !$ua->can('request');

    return sub {
        my ($method, $url, $opts) = @_;

        require HTTP::Request;
        my $request = HTTP::Request->new($method => $url);
        my $headers = $opts->{headers} || {};
        $request->header($_ => $headers->{$_}) for keys %$headers;
        $request->content($opts->{content}) if exists $opts->{content};

        my $response = $ua->request($request);
        my %headers = $response->headers->flatten;

        return {
            status  => $response->code,
            reason  => $response->message,
            headers => \%headers,
            content => $response->content,
        };
    };
}

sub mojo_user_agent {
    my ($ua) = @_;
    die "Mojo::UserAgent-compatible object is required\n"
        if !$ua || !$ua->can('build_tx') || !$ua->can('start');

    return sub {
        my ($method, $url, $opts) = @_;
        my $headers = $opts->{headers} || {};

        my $tx = $ua->build_tx($method => $url => $headers);
        $tx->req->body($opts->{content}) if exists $opts->{content};
        my $result = $ua->start($tx)->result;

        my %response_headers;
        for my $name (@{ $result->headers->names }) {
            $response_headers{$name} = $result->headers->header($name);
        }

        return {
            status  => $result->code,
            reason  => $result->message,
            headers => \%response_headers,
            content => $result->body,
        };
    };
}

sub furl {
    my ($furl) = @_;
    die "Furl-compatible object is required\n"
        if !$furl || !$furl->can('request');

    return sub {
        my ($method, $url, $opts) = @_;
        my $headers = $opts->{headers} || {};
        my @headers;
        push @headers, $_ => $headers->{$_} for keys %$headers;

        my $response = $furl->request(
            method  => $method,
            url     => $url,
            headers => \@headers,
            (exists($opts->{content}) ? (content => $opts->{content}) : ()),
        );

        my %response_headers;
        my $response_header = $response->headers;
        for my $name ($response_header->header_field_names) {
            $response_headers{$name} = $response_header->header($name);
        }

        return {
            status  => $response->code,
            reason  => $response->message,
            headers => \%response_headers,
            content => $response->content,
        };
    };
}

1;

__END__

=head1 NAME

HTTP::API::Core::Example::TransportAdapters - reference transport adapters

=head1 DESCRIPTION

Small reference adapters for common Perl HTTP clients. These helpers are
examples rather than public core API: copy or adapt the mapping into your own
client or transport distribution.

=head1 FUNCTIONS

=head2 http_tiny($http)

Returns a transport coderef for an HTTP::Tiny-compatible object. HTTP::Tiny
already uses the same response hash shape as HTTP::API::Core.

=head2 lwp_user_agent($ua)

Returns a transport coderef for an LWP::UserAgent-compatible object.

=head2 mojo_user_agent($ua)

Returns a transport coderef for a Mojo::UserAgent-compatible object.

=head2 furl($furl)

Returns a transport coderef for a Furl-compatible object.

=cut
