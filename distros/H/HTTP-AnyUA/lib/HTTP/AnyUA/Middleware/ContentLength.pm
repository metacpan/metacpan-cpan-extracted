package HTTP::AnyUA::Middleware::ContentLength;
# ABSTRACT: Middleware to add Content-Length header automatically


use warnings;
use strict;

our $VERSION = '0.904'; # VERSION

use parent 'HTTP::AnyUA::Middleware';

use HTTP::AnyUA::Util;


sub request {
    my $self = shift;
    my ($method, $url, $args) = @_;

    $args->{headers} = HTTP::AnyUA::Util::normalize_headers($args->{headers});

    if (!defined $args->{headers}{'content-length'} && $args->{content} && !ref $args->{content}) {
        $args->{headers}{'content-length'} = length $args->{content};
    }

    return $self->backend->request($method, $url, $args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::AnyUA::Middleware::ContentLength - Middleware to add Content-Length header automatically

=head1 VERSION

version 0.904

=head1 SYNOPSIS

    $any_ua->apply_middleware('ContentLength');

=head1 DESCRIPTION

This middleware adds a Content-Length header to the request if the content is known (i.e. the
"content" field of the request options is a string instead of a coderef) and if the header is not
already set.

=head1 SEE ALSO

=over 4

=item *

L<HTTP::AnyUA::Middleware>

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
