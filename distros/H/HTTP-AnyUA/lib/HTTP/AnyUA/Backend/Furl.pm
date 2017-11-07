package HTTP::AnyUA::Backend::Furl;
# ABSTRACT: A unified programming interface for Furl


use warnings;
use strict;

our $VERSION = '0.901'; # VERSION

use parent 'HTTP::AnyUA::Backend';

use HTTP::AnyUA::Util;


sub request {
    my $self = shift;
    my ($method, $url, $args) = @_;

    local $args->{content} = HTTP::AnyUA::Util::coderef_content_to_string($args->{content});

    my $request = HTTP::AnyUA::Util::native_to_http_request(@_);
    my $ua_resp = $self->ua->request($request);

    return $self->_munge_response($ua_resp, $args->{data_callback});
}

sub _munge_response {
    my $self    = shift;
    my $ua_resp = shift;
    my $data_cb = shift;

    my $resp = {
        success => !!$ua_resp->is_success,
        url     => $ua_resp->request->uri->as_string,
        status  => $ua_resp->code,
        reason  => $ua_resp->message,
        headers => HTTP::AnyUA::Util::http_headers_to_native($ua_resp->headers),
    };

    $resp->{protocol} = $ua_resp->protocol if $ua_resp->protocol;

    if ($resp->{headers}{'x-internal-response'}) {
        HTTP::AnyUA::Util::internal_exception($ua_resp->content, $resp);
    }
    elsif ($data_cb) {
        $data_cb->($ua_resp->content, $resp);
    }
    else {
        $resp->{content} = $ua_resp->content;
    }

    return $resp;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::AnyUA::Backend::Furl - A unified programming interface for Furl

=head1 VERSION

version 0.901

=head1 DESCRIPTION

This module adds support for the HTTP client L<Furl> to be used with the unified programming
interface provided by L<HTTP::AnyUA>.

=head1 CAVEATS

=over 4

=item *

L<Furl> doesn't keep a list of requests and responses along a redirect chain. As such, the C<url> field in the response is always the same as the URL of the original request, and the C<redirects> field is never used.

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

This software is copyright (c) 2017 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
