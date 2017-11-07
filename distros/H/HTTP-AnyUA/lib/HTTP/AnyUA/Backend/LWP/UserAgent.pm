package HTTP::AnyUA::Backend::LWP::UserAgent;
# ABSTRACT: A unified programming interface for LWP::UserAgent


use warnings;
use strict;

our $VERSION = '0.901'; # VERSION

use parent 'HTTP::AnyUA::Backend';

use HTTP::AnyUA::Util;


sub request {
    my $self = shift;
    my ($method, $url, $args) = @_;

    my $r = HTTP::AnyUA::Util::native_to_http_request(@_);

    my $ua_resp = $self->ua->request($r);

    return $self->_munge_response($ua_resp, $args->{data_callback});
}


sub _munge_response {
    my $self    = shift;
    my $ua_resp = shift;
    my $data_cb = shift;
    my $recurse = shift;

    my $resp = {
        success => !!$ua_resp->is_success,
        url     => $ua_resp->request->uri->as_string,
        status  => $ua_resp->code,
        reason  => $ua_resp->message,
        headers => HTTP::AnyUA::Util::http_headers_to_native($ua_resp->headers),
    };

    $resp->{protocol} = $ua_resp->protocol if $ua_resp->protocol;

    if (!$recurse) {
        for my $redirect ($ua_resp->redirects) {
            push @{$resp->{redirects} ||= []}, $self->_munge_response($redirect, undef, 1);
        }
    }

    my $content_ref = $ua_resp->content_ref;

    if (($resp->{headers}{'client-warning'} || '') eq 'Internal response') {
        HTTP::AnyUA::Util::internal_exception($$content_ref, $resp);
    }
    elsif ($data_cb) {
        $data_cb->($$content_ref, $resp);
    }
    else {
        $resp->{content} = $$content_ref;
    }

    return $resp;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::AnyUA::Backend::LWP::UserAgent - A unified programming interface for LWP::UserAgent

=head1 VERSION

version 0.901

=head1 DESCRIPTION

This module adds support for the HTTP client L<LWP::UserAgent> to be used with the unified
programming interface provided by L<HTTP::AnyUA>.

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

This software is copyright (c) 2017 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
