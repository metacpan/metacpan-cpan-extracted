package HTTP::AnyUA::Middleware::RequestHeaders;
# ABSTRACT: Middleware to add custom request headers


use warnings;
use strict;

our $VERSION = '0.902'; # VERSION

use parent 'HTTP::AnyUA::Middleware';

use HTTP::AnyUA::Util;


sub init {
    my $self = shift;
    my %args = @_;
    $self->{override} = !!$args{override};
    $self->{headers}  = HTTP::AnyUA::Util::normalize_headers($args{headers});
}

sub request {
    my $self = shift;
    my ($method, $url, $args) = @_;

    if ($self->override) {
        $args->{headers} = {
            %{HTTP::AnyUA::Util::normalize_headers($args->{headers})},
            %{$self->headers},
        };
    }
    else {
        $args->{headers} = {
            %{$self->headers},
            %{HTTP::AnyUA::Util::normalize_headers($args->{headers})},
        };
    }

    return $self->backend->request($method, $url, $args);
}


sub headers { shift->{headers} }


sub override { shift->{override} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::AnyUA::Middleware::RequestHeaders - Middleware to add custom request headers

=head1 VERSION

version 0.902

=head1 SYNOPSIS

    $any_ua->apply_middleware('RequestHeaders',
        headers  => {connection => 'close'},
        override => 0,
    );

=head1 DESCRIPTION

This middleware adds custom headers to each request.

=head1 ATTRIBUTES

=head2 headers

Get the custom headers.

=head2 override

When true, custom headers overwrite headers in the request. The default is false (the request
headers take precedence when defined).

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

This software is copyright (c) 2017 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
