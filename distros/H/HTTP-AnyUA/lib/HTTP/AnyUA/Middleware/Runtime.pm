package HTTP::AnyUA::Middleware::Runtime;
# ABSTRACT: Middleware to determine response time


use warnings;
use strict;

our $VERSION = '0.901'; # VERSION

use parent 'HTTP::AnyUA::Middleware';

use Time::HiRes;


sub request {
    my $self = shift;
    my ($method, $url, $args) = @_;

    my $start = [Time::HiRes::gettimeofday];

    my $resp = $self->backend->request($method, $url, $args);

    my $handle_response = sub {
        my $resp = shift;

        $resp->{runtime} = sprintf('%.6f', Time::HiRes::tv_interval($start));

        return $resp;
    };

    if ($self->response_is_future) {
        $resp->transform(
            done => $handle_response,
            fail => $handle_response,
        );
    }
    else {
        $resp = $handle_response->($resp);
    }

    return $resp;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::AnyUA::Middleware::Runtime - Middleware to determine response time

=head1 VERSION

version 0.901

=head1 SYNOPSIS

    $any_ua->apply_middleware('Runtime');

=head1 DESCRIPTION

This middleware adds a "runtime" field to the response, the value of which is the number of seconds
it took to make the request and finish the response.

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
