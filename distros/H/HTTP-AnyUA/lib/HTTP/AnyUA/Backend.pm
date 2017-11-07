package HTTP::AnyUA::Backend;
# ABSTRACT: A base class for HTTP::AnyUA backends


use warnings;
use strict;

our $VERSION = '0.901'; # VERSION



sub new {
    my $class   = shift;
    my $ua      = shift or die 'User agent is required';
    bless {ua => $ua}, $class;
}


sub request {
    die 'Not yet implemented';
}


sub ua { shift->{ua} }


sub response_is_future { 0 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::AnyUA::Backend - A base class for HTTP::AnyUA backends

=head1 VERSION

version 0.901

=head1 SYNOPSIS

    package HTTP::AnyUA::Backend::MyUserAgent;

    use parent 'HTTP::AnyUA::Backend';

    sub response_is_future { 0 }

    sub request {
        my ($self, $method, $url, $args) = @_;

        my $ua = $self->ua;

        # Here is where you transform the arguments into a request that $ua
        # understands, make the request against $ua and get a response, and
        # transform the response to the expected hashref form.

        my $resp = $ua->make_request();

        return $resp;
    }

    ### Non-blocking user agents are expected to return Future objects:

    use Future;

    sub response_is_future { 1 }

    sub request {
        my ($self, $method, $url, $args) = @_;

        my $ua = $self->ua;

        my $future = Future->new;

        # Again, this example glosses over transforming the request and response
        # to and from the actual user agent, but such details are the whole
        # point of a backend.

        $ua->nonblocking_callback(sub {
            my $resp = shift;

            if ($resp->{success}) {
                $future->done($resp);
            }
            else {
                $future->fail($resp);
            }
        });

        return $future;
    }

=head1 DESCRIPTION

This module provides an interface for an L<HTTP::AnyUA> "backend," which is an adapter that adds
support for using a type of user agent with L<HTTP::AnyUA>.

This class should not be instantiated directly, but it may be convenient for backend implementations
to subclass it.

At its core, a backend simply takes a set of standard arguments that represent an HTTP request,
transforms that request into a form understood by an underlying user agent, calls upon the user
agent to make the request and get a response, and then transforms that response into a standard
form. The standard forms for the request and response are based on L<HTTP::Tiny>'s arguments and
return value to and from its L<request|HTTP::Tiny/request> method.

=head1 ATTRIBUTES

=head2 ua

Get the user agent that was passed to L</new>.

=head2 response_is_future

Get whether or not responses are L<Future> objects. Default is false.

This may be overridden by implementations.

=head1 METHODS

=head2 new

    $backend = HTTP::AnyUA::Backend::MyUserAgent->new($my_user_agent);

Construct a new backend.

=head2 request

    $response = $backend->request($method => $url, \%options);

Make a request, get a response.

This must be overridden by implementations.

=head1 SEE ALSO

=over 4

=item *

L<HTTP::AnyUA/The Request>  - Explanation of the request arguments

=item *

L<HTTP::AnyUA/The Response> - Explanation of the response

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
