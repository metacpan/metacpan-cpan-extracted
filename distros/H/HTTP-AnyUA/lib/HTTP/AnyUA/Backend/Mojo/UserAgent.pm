package HTTP::AnyUA::Backend::Mojo::UserAgent;
# ABSTRACT: A unified programming interface for Mojo::UserAgent


use warnings;
use strict;

our $VERSION = '0.904'; # VERSION

use parent 'HTTP::AnyUA::Backend';

use Future;
use Scalar::Util;


my $future_class;
BEGIN {
    $future_class = 'Future';
    eval 'use Future::Mojo';    ## no critic
    $future_class = 'Future::Mojo' if !$@;
}


sub response_is_future { 1 }

sub request {
    my $self = shift;
    my ($method, $url, $args) = @_;

    my $future = $future_class->new;

    my $tx = $self->_munge_request(@_);

    $self->ua->start($tx => sub {
        my $ua = shift;
        my $tx = shift;

        my $resp = $self->_munge_response($tx, $args->{data_callback});

        if ($resp->{success}) {
            $future->done($resp);
        }
        else {
            $future->fail($resp);
        }
    });

    return $future;
}


sub _munge_request {
    my $self    = shift;
    my $method  = shift;
    my $url     = shift;
    my $args    = shift;

    my $headers = $args->{headers} || {};
    my $content = $args->{content};

    my @content;

    my $content_length;
    if ($content) {
        for my $header (keys %$headers) {
            if (lc($header) eq 'content-length') {
                $content_length = $headers->{$header};
                last;
            }
        }

        # if we don't know the length we have to just read it all in
        $content = HTTP::AnyUA::Util::coderef_content_to_string($content) if !$content_length;

        push @content, $content if ref($content) ne 'CODE';
    }

    my $tx = $self->ua->build_tx($method => $url => $headers => @content);

    if (ref($content) eq 'CODE') {
        $tx->req->headers->content_length($content_length);
        # stream the request
        my $drain;
        $drain = sub {
            my $body    = shift;
            my $chunk   = $content->() || '';
            undef $drain if !$chunk;
            $body->write($chunk, $drain);
        };
        $tx->req->content->$drain;
    }

    if (my $data_cb = $args->{data_callback}) {
        # stream the response
        my $tx_copy = $tx;
        Scalar::Util::weaken($tx_copy);
        $tx->res->content->unsubscribe('read')->on(read => sub {
            my ($content, $bytes) = @_;
            my $resp = $self->_munge_response($tx_copy, undef);
            $data_cb->($bytes, $resp);
        });
    }

    return $tx;
}

sub _munge_response {
    my $self    = shift;
    my $tx      = shift;
    my $data_cb = shift;
    my $recurse = shift;

    my $resp = {
        success => !!$tx->res->is_success,
        url     => $tx->req->url->to_string,
        status  => $tx->res->code,
        reason  => $tx->res->message,
        headers => {},
    };

    # lowercase header keys
    my $headers = $tx->res->headers->to_hash;
    for my $header (keys %$headers) {
        $resp->{headers}{lc($header)} = delete $headers->{$header};
    }

    my $version = $tx->res->version;
    $resp->{protocol} = "HTTP/$version" if $version;

    if (!$recurse) {
        for my $redirect (@{$tx->redirects}) {
            push @{$resp->{redirects} ||= []}, $self->_munge_response($redirect, undef, 1);
        }
    }

    my $err = $tx->error;
    if ($err && !$err->{code}) {
        return HTTP::AnyUA::Util::internal_exception($err->{message}, $resp);
    }

    my $body = $tx->res->body;
    $resp->{content} = $body if $body && !$data_cb;

    return $resp;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::AnyUA::Backend::Mojo::UserAgent - A unified programming interface for Mojo::UserAgent

=head1 VERSION

version 0.904

=head1 DESCRIPTION

This module adds support for the HTTP client L<Mojo::UserAgent> to be used with the unified
programming interface provided by L<HTTP::AnyUA>.

If installed, requests will return L<Future::Mojo> rather than L<Future>. This allows the use of the
C<< ->get >> method to await a result.

=head1 CAVEATS

=over 4

=item *

The C<url> field in the response has the auth portion (if any) removed from the URL.

=back

=head1 SEE ALSO

=over 4

=item *

L<HTTP::AnyUA::Backend>

=back

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
