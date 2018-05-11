package HTTP::Tiny::UNIX;

use 5.010001;
use strict;
use warnings;

our $DATE = '2018-05-08'; # DATE
our $VERSION = '0.051'; # VERSION

# issue: port must be numeric to avoid warning
# put everything in path_query

use parent qw(HTTP::Tiny);

use IO::Socket::UNIX;

sub _split_url {
    my ($self, $url) = @_;

    if ($url =~ m<\A[^:/?#]+://>) {
        $self->{_unix} = 0;
        return $self->SUPER::_split_url($url);
    }

    my ($scheme, $sock_path, $path_query) =
        $url =~ m<\A(\w+):(.+?)/(/[^#]*)>
            or die "Cannot parse HTTP-over-Unix URL: '$url'\n";

    # a hack
    $self->{_unix} = 1;
    $self->{_path_query} = $path_query;

    $scheme = lc $scheme;
    die "Only http scheme is supported\n" unless $scheme eq 'http';

    #return ($scheme, $host,      $port, $path_query, $auth);
    return  ($scheme, $sock_path, -1,    $path_query, '');
}

sub _open_handle {
    my ($self, $request, $scheme, $host, $port) = @_;

    return $self->SUPER::_open_handle($request, $scheme, $host, $port)
        unless $self->{_unix};

    my $handle = HTTP::Tiny::Handle::UNIX->new(
        timeout => $self->{timeout},
    );

    $handle->connect($scheme, $host, $port, $self);
}

package
    HTTP::Tiny::Handle::UNIX;

use parent -norequire, 'HTTP::Tiny::Handle';

use IO::Socket;

sub connect {
    my ($self, $scheme, $host, $port, $tiny) = @_;

    # on Unix, we use $host for path and leave port at -1 (unused)
    my $path = $host;

    local($^W) = 0;
    my $sock = IO::Socket::UNIX->new(
        Peer    => $path,
        Type    => SOCK_STREAM,
        Timeout => $self->{timeout},
        Host    => 'localhost',
    );

    unless ($sock) {
        $@ =~ s/^.*?: //;
        die "Can't open Unix socket $path\: $@";
    }

    eval { $sock->blocking(0); };

    $self->{fh} = $sock;

    $self->{scheme} = $scheme;
    $self->{host} = $host;
    $self->{port} = $port;
    $self->{_unix} = 1;
    # this is a hack, we inject this so we can get HTTP::Tiny::UNIX object from
    # HTTP::Tiny::Handle::UNIX, to get path
    $self->{_tiny} = $tiny;
    $self;
}

sub write_request_header {
    my ($self, $method, $request_uri, $headers, $header_case) = @_;

    return $self->SUPER::write_request_header(@_)
        unless $self->{_unix};

    return $self->write_header_lines($headers, $header_case, "$method $self->{_tiny}{_path_query} HTTP/1.1\x0D\x0A");
}

1;
# ABSTRACT: A subclass of HTTP::Tiny to connect to HTTP server over Unix socket

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::UNIX - A subclass of HTTP::Tiny to connect to HTTP server over Unix socket

=head1 VERSION

This document describes version 0.051 of HTTP::Tiny::UNIX (from Perl distribution HTTP-Tiny-UNIX), released on 2018-05-08.

=head1 SYNOPSIS

 use HTTP::Tiny::UNIX;

 my $response = HTTP::Tiny::UNIX->new->get('http:/path/to/unix.sock//uri/path');

 die "Failed!\n" unless $response->{success};
 print "$response->{status} $response->{reason}\n";

 while (my ($k, $v) = each %{$response->{headers}}) {
     for (ref $v eq 'ARRAY' ? @$v : $v) {
         print "$k: $_\n";
     }
 }

 print $response->{content} if length $response->{content};

=head1 DESCRIPTION

This is a subclass of L<HTTP::Tiny> to connect to HTTP server over Unix socket.
URL syntax is C<"http:"> + I<path to unix socket> + C<"/"> + I<uri path>. For
example: C<http:/var/run/apid.sock//api/v1/matches>. URL not matching this
pattern will be passed to HTTP::Tiny.

Proxy is currently not supported.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Tiny-UNIX>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Tiny-UNIX>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Tiny-UNIX>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HTTP::Tiny>

To use L<LWP> to connect over Unix sockets, see
L<LWP::Protocol::http::SocketUnixAlt>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
