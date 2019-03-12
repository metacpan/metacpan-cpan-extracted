package HTTP::AnyUA::Middleware;
# ABSTRACT: A base class for HTTP::AnyUA middleware


use warnings;
use strict;

our $VERSION = '0.903'; # VERSION

sub _croak { require Carp; Carp::croak(@_) }
sub _usage { _croak("Usage: @_\n") }



sub new {
    my $class   = shift;
    my $backend = shift or die 'Backend is required';
    my $self = bless {backend => $backend}, $class;
    $self->init(@_);
    return $self;
}


sub init {}


sub wrap {
    my $self    = shift;
    my $backend = shift or _usage($self . q{->wrap($backend, %args)});

    if (ref $self) {
        $self->{backend} = $backend;
    }
    else {
        $self = $self->new($backend, @_);
    }

    return $self;
}


sub request { shift->backend->request(@_) }


sub backend { shift->{backend} }


sub ua { shift->backend->ua(@_) }


sub response_is_future { shift->backend->response_is_future(@_) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::AnyUA::Middleware - A base class for HTTP::AnyUA middleware

=head1 VERSION

version 0.903

=head1 SYNOPSIS

    package HTTP::AnyUA::Middleware::MyMiddleware;

    use parent 'HTTP::AnyUA::Middleware';

    sub request {
        my ($self, $method, $url, $args) = @_;

        # Maybe do something with the request args here.

        # Let backend handle the response:
        my $response = $self->backend->request($method, $url, $args);

        my $handle_response = sub {
            my $response = shift;

            # Maybe do something with the response here.

            return $response;
        };

        if ($self->response_is_future) {
            $response = $response->transform(
                done => $handle_response,
                fail => $handle_response,
            );
        }
        else {
            $response = $handle_response->($response);
        }

        return $response;
    }

=head1 DESCRIPTION

This module provides an interface for an L<HTTP::AnyUA> "middleware," which is a component that sits
between an L<HTTP::AnyUA> object and the L<backend|HTTP::AnyUA::Backend> (which may in fact be
another middleware).

The easiest way to use middleware is to use L<HTTP::AnyUA/apply_middleware>.

The middleware mechanism can be used to munge or react to requests and responses to and from the
backend user agent. Middlewares are a completely optional part of L<HTTP::AnyUA>. They can be
wrapped around each other to create multiple layers and interesting possibilities. The functionality
provided by middleware may be alternative to features provided by some of the supported user agents,
themselves, but implementing functionality on this layer makes it work for I<all> the user agents.

=head1 ATTRIBUTES

=head2 backend

Get the current backend that is wrapped.

=head2 ua

Get the backend user agent.

=head2 response_is_future

Get whether or not responses are L<Future> objects. Default is whatever the backend returns.

This may be overridden by implementations.

=head1 METHODS

=head2 new

    $middleware = HTTP::AnyUA::Middleware::MyMiddleware->new($backend);
    $middleware = HTTP::AnyUA::Middleware::MyMiddleware->new($backend, %args);

Construct a new middleware.

=head2 init

Called by the default constructor with the middleware arguments.

This may be overridden by implementations instead of the constructor.

=head2 wrap

    $middleware = HTTP::AnyUA::Middleware::MyMiddleware->wrap($backend, %args);
    $middleware->wrap($backend);

Construct a new middleware or, when called on an instance, set a new backend on an existing
middleware.

=head2 request

    $response = $middleware->request($method => $url, \%options);

Make a request, get a response.

This should be overridden by implementations to do whatever they want with or to the request and/or
response.

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
