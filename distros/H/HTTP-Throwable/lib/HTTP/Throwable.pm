package HTTP::Throwable;
our $AUTHORITY = 'cpan:STEVAN';
$HTTP::Throwable::VERSION = '0.026';
use Types::Standard qw(Int Str ArrayRef);

use Moo::Role;

use overload
    '&{}' => 'to_app',
    '""'  => 'as_string',
    fallback => 1;

use Plack::Util ();

with 'Throwable';

has 'status_code' => (
    is       => 'ro',
    isa      => Int,
    builder  => 'default_status_code',
);

has 'reason' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    builder  => 'default_reason',
);

has 'message' => (
    is  => 'ro',
    isa => Str,
    predicate => 'has_message',
);

# TODO: type this attribute more strongly -- rjbs, 2011-02-21
has 'additional_headers' => ( is => 'ro', isa => ArrayRef );

sub build_headers {
    my ($self, $body) = @_;

    my @headers;

    @headers = @{ $self->body_headers($body) };

    if ( my $additional_headers = $self->additional_headers ) {
        push @headers => @$additional_headers;
    }

    return \@headers;
}

sub status_line {
    my $self = shift;
    my $out  = $self->status_code . " " . $self->reason;
    $out .= " " . $self->message if $self->message;

    return $out;
}

requires 'body';
requires 'body_headers';
requires 'as_string';

sub as_psgi {
    my $self    = shift;
    my $body    = $self->body;
    my $headers = $self->build_headers( $body );
    [ $self->status_code, $headers, [ defined $body ? $body : () ] ];
}

sub to_app {
    my $self = shift;
    sub { my $env; $self->as_psgi( $env ) }
}

sub is_redirect {
    my $status = (shift)->status_code;
    return $status >= 300 && $status < 400;
}

sub is_client_error {
    my $status = (shift)->status_code;
    return $status >= 400 && $status < 500;
}

sub is_server_error {
    my $status = (shift)->status_code;
    return $status >= 500 && $status < 600;
}

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable - a set of strongly-typed, PSGI-friendly HTTP 1.1 exception libraries

=head1 VERSION

version 0.026

=head1 SYNOPSIS

B<ACHTUNG>:  The interface for HTTP::Throwable has changed significantly
between 0.005 and 0.010.  Further backward incompatibilities may appear in the
next few weeks, as the interface is refined.  This notice will be removed when
it has stabilized.

I<Actually>, you probably want to use L<HTTP::Throwable::Factory>, so here's a
sample of how that works:

  use HTTP::Throwable::Factory qw(http_throw http_exception);

  # you can just throw a generic exception...
  HTTP::Throwable::Factory->throw({
      status_code => 500,
      reason      => 'Internal Server Error',
      message     => 'Something has gone very wrong!'
  });

  # or with a little sugar...
  http_throw({
      status_code => 500,
      reason      => 'Internal Server Error',
      message     => 'Something has gone very wrong!'
  });


  # ...but it's much more convenient to throw well-defined exceptions, like
  # this:

  http_throw(InternalServerError => {
    message => 'Something has gone very wrong!',
  });

  # or you can use the exception objects as PSGI apps:
  builder {
      mount '/old' => http_exception(MovedPermanently => { location => '/new' }),
      # ...
  };

=head1 DESCRIPTION

HTTP-Throwable provides a set of strongly-typed, PSGI-friendly exception
implementations corresponding to the HTTP error status code (4xx-5xx) as well
as the redirection codes (3xx).

This particular package (HTTP::Throwable) is the shared role for all the
exceptions involved.  It's not intended that you use HTTP::Throwable
directly, although you can, and instructions for using it correctly are
given below.  Instead, you probably want to use
L<HTTP::Throwable::Factory>, which will assemble exception classes from
roles needed to build an exception for your use case.

For example, you can throw a redirect:

  use HTTP::Throwable::Factory qw(http_throw);

  http_throw(MovedPermanently => { location => '/foo-bar' });

...or a generic fully user-specified exception...

  http_throw({
    status_code => 512,
    reason      => 'Server on fire',
    message     => "Please try again after heavy rain",
  });

For a list of pre-defined, known errors, see L</WELL-KNOWN TYPES> below.
These types will have the correct status code and reason, and will
understand extra status-related arguments like redirect location or authentication realms.

For information on using HTTP::Throwable directly, see L</COMPOSING WITH
HTTP::THROWABLE>, below.

=head2 HTTP::Exception

This module is similar to HTTP::Exception with a few, well uhm,
exceptions. First, we are not implementing the 1xx and 2xx status
codes, it is this authors opinion that those not being errors or
an exception control flow (redirection) should not be handled with
exceptions. And secondly, this module is very PSGI friendly in that
it can turn your exception into a PSGI response with just a
method call.

All that said HTTP::Exception is a wonderful module and if that
better suits your needs, then by all means, use it.

=head2 Note about Stack Traces

It should be noted that even though these are all exception objects,
only the 500 Internal Server Error error actually includes the stack
trace (albiet optionally). This is because more often then not you will
not actually care about the stack trace and therefore do not the extra
overhead. If you do find you want a stack trace though, it is as simple
as adding the L<StackTrace::Auto> role to your exceptions.

=head1 ATTRIBUTES

=head2 status_code

This is the status code integer as specified in the HTTP spec.

=head2 reason

This is the reason phrase as specified in the HTTP spec.

=head2 message

This is an additional message string that can be supplied, which I<may>
be used when stringifying or building an HTTP response.

=head2 additional_headers

This is an arrayref of pairs that will be added to the headers of the
exception when converted to a HTTP message.

=head1 METHODS

=head2 status_line

This returns a string that would be used as a status line in a response,
like C<404 Not Found>.

=head2 as_string

This returns a string representation of the exception.  This method
B<must> be implemented by any class consuming this role.

=head2 as_psgi

This returns a representation of the exception object as PSGI
response.

In theory, it accepts a PSGI environment as its only argument, but
currently the environment is ignored.

=head2 to_app

This is the standard Plack convention for L<Plack::Component>s.
It will return a CODE ref which expects the C<$env> parameter
and returns the results of C<as_psgi>.

=head2 &{}

We overload C<&{}> to call C<to_app>, again in keeping with the
L<Plack::Component> convention.

=head1 WELL-KNOWN TYPES

Below is a list of the well-known types recognized by the factory and
shipped with this distribution. The obvious 4xx and 5xx errors are
included but we also include the 3xx redirection status codes. This is
because, while not really an error, the 3xx status codes do represent an
exceptional control flow.

The implementation for each of these is in a role with a name in the
form C<HTTP::Throwable::Role::Status::STATUS-NAME>.  For example, "Gone"
is C<HTTP::Throwable::Role::Status::Gone>.  When throwing the exception
with the factory, just pass "Gone"

=head2 Redirection 3xx

This class of status code indicates that further action needs to
be taken by the user agent in order to fulfill the request. The
action required MAY be carried out by the user agent without
interaction with the user if and only if the method used in the
second request is GET or HEAD.

=over 4

=item 300 L<HTTP::Throwable::Role::Status::MultipleChoices>

=item 301 L<HTTP::Throwable::Role::Status::MovedPermanently>

=item 302 L<HTTP::Throwable::Role::Status::Found>

=item 303 L<HTTP::Throwable::Role::Status::SeeOther>

=item 304 L<HTTP::Throwable::Role::Status::NotModified>

=item 305 L<HTTP::Throwable::Role::Status::UseProxy>

=item 307 L<HTTP::Throwable::Role::Status::TemporaryRedirect>

=back

=head2 Client Error 4xx

The 4xx class of status code is intended for cases in which
the client seems to have erred. Except when responding to a
HEAD request, the server SHOULD include an entity containing an
explanation of the error situation, and whether it is a temporary
or permanent condition. These status codes are applicable to any
request method. User agents SHOULD display any included entity
to the user.

=over 4

=item 400 L<HTTP::Throwable::Role::Status::BadRequest>

=item 401 L<HTTP::Throwable::Role::Status::Unauthorized>

=item 403 L<HTTP::Throwable::Role::Status::Forbidden>

=item 404 L<HTTP::Throwable::Role::Status::NotFound>

=item 405 L<HTTP::Throwable::Role::Status::MethodNotAllowed>

=item 406 L<HTTP::Throwable::Role::Status::NotAcceptable>

=item 407 L<HTTP::Throwable::Role::Status::ProxyAuthenticationRequired>

=item 408 L<HTTP::Throwable::Role::Status::RequestTimeout>

=item 409 L<HTTP::Throwable::Role::Status::Conflict>

=item 410 L<HTTP::Throwable::Role::Status::Gone>

=item 411 L<HTTP::Throwable::Role::Status::LengthRequired>

=item 412 L<HTTP::Throwable::Role::Status::PreconditionFailed>

=item 413 L<HTTP::Throwable::Role::Status::RequestEntityTooLarge>

=item 414 L<HTTP::Throwable::Role::Status::RequestURITooLong>

=item 415 L<HTTP::Throwable::Role::Status::UnsupportedMediaType>

=item 416 L<HTTP::Throwable::Role::Status::RequestedRangeNotSatisfiable>

=item 417 L<HTTP::Throwable::Role::Status::ExpectationFailed>

=back

=head2 Server Error 5xx

Response status codes beginning with the digit "5" indicate
cases in which the server is aware that it has erred or is
incapable of performing the request. Except when responding to
a HEAD request, the server SHOULD include an entity containing
an explanation of the error situation, and whether it is a
temporary or permanent condition. User agents SHOULD display
any included entity to the user. These response codes are applicable
to any request method.

=over 4

=item 500 L<HTTP::Throwable::Role::Status::InternalServerError>

=item 501 L<HTTP::Throwable::Role::Status::NotImplemented>

=item 502 L<HTTP::Throwable::Role::Status::BadGateway>

=item 503 L<HTTP::Throwable::Role::Status::ServiceUnavailable>

=item 504 L<HTTP::Throwable::Role::Status::GatewayTimeout>

=item 505 L<HTTP::Throwable::Role::Status::HTTPVersionNotSupported>

=back

=head1 COMPOSING WITH HTTP::THROWABLE

In general, we expect that you'll use L<HTTP::Throwable::Factory> or a
subclass to throw exceptions.  You can still use HTTP::Throwable
directly, though, if you keep these things in mind:

HTTP::Throwable is mostly concerned about providing basic headers and a
PSGI representation.  It doesn't worry about the body or a
stringification.  You B<must> provide the methods C<body> and
C<body_headers> and C<as_string>.

The C<body> method returns the string (of octets) to be sent as the HTTP
entity.  That body is passed to the C<body_headers> method, which must
return an arrayref of headers to add to the response.  These will
generally include the Content-Type and Content-Length headers.

The C<as_string> method should return a printable string, even if the
body is going to be empty.

For convenience, these three methods are implemented by the roles
L<HTTP::Throwable::Role::TextBody> and L<HTTP::Throwable::Role::NoBody>.

=head1 SEE ALSO

=over 4

=item *

L<http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html>

=item *

L<Plack::Middleware::HTTPExceptions>

=back

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords Brian Cassidy Chris Prather Fitz Elliott Karen Etheridge

=over 4

=item *

Brian Cassidy <bricas@cpan.org>

=item *

Chris Prather <chris@prather.org>

=item *

Fitz Elliott <felliott@fiskur.org>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: a set of strongly-typed, PSGI-friendly HTTP 1.1 exception libraries

#pod =head1 SYNOPSIS
#pod
#pod B<ACHTUNG>:  The interface for HTTP::Throwable has changed significantly
#pod between 0.005 and 0.010.  Further backward incompatibilities may appear in the
#pod next few weeks, as the interface is refined.  This notice will be removed when
#pod it has stabilized.
#pod
#pod I<Actually>, you probably want to use L<HTTP::Throwable::Factory>, so here's a
#pod sample of how that works:
#pod
#pod   use HTTP::Throwable::Factory qw(http_throw http_exception);
#pod
#pod   # you can just throw a generic exception...
#pod   HTTP::Throwable::Factory->throw({
#pod       status_code => 500,
#pod       reason      => 'Internal Server Error',
#pod       message     => 'Something has gone very wrong!'
#pod   });
#pod
#pod   # or with a little sugar...
#pod   http_throw({
#pod       status_code => 500,
#pod       reason      => 'Internal Server Error',
#pod       message     => 'Something has gone very wrong!'
#pod   });
#pod
#pod
#pod   # ...but it's much more convenient to throw well-defined exceptions, like
#pod   # this:
#pod
#pod   http_throw(InternalServerError => {
#pod     message => 'Something has gone very wrong!',
#pod   });
#pod
#pod   # or you can use the exception objects as PSGI apps:
#pod   builder {
#pod       mount '/old' => http_exception(MovedPermanently => { location => '/new' }),
#pod       # ...
#pod   };
#pod
#pod =head1 DESCRIPTION
#pod
#pod HTTP-Throwable provides a set of strongly-typed, PSGI-friendly exception
#pod implementations corresponding to the HTTP error status code (4xx-5xx) as well
#pod as the redirection codes (3xx).
#pod
#pod This particular package (HTTP::Throwable) is the shared role for all the
#pod exceptions involved.  It's not intended that you use HTTP::Throwable
#pod directly, although you can, and instructions for using it correctly are
#pod given below.  Instead, you probably want to use
#pod L<HTTP::Throwable::Factory>, which will assemble exception classes from
#pod roles needed to build an exception for your use case.
#pod
#pod For example, you can throw a redirect:
#pod
#pod   use HTTP::Throwable::Factory qw(http_throw);
#pod
#pod   http_throw(MovedPermanently => { location => '/foo-bar' });
#pod
#pod ...or a generic fully user-specified exception...
#pod
#pod   http_throw({
#pod     status_code => 512,
#pod     reason      => 'Server on fire',
#pod     message     => "Please try again after heavy rain",
#pod   });
#pod
#pod For a list of pre-defined, known errors, see L</WELL-KNOWN TYPES> below.
#pod These types will have the correct status code and reason, and will
#pod understand extra status-related arguments like redirect location or authentication realms.
#pod
#pod For information on using HTTP::Throwable directly, see L</COMPOSING WITH
#pod HTTP::THROWABLE>, below.
#pod
#pod =head2 HTTP::Exception
#pod
#pod This module is similar to HTTP::Exception with a few, well uhm,
#pod exceptions. First, we are not implementing the 1xx and 2xx status
#pod codes, it is this authors opinion that those not being errors or
#pod an exception control flow (redirection) should not be handled with
#pod exceptions. And secondly, this module is very PSGI friendly in that
#pod it can turn your exception into a PSGI response with just a
#pod method call.
#pod
#pod All that said HTTP::Exception is a wonderful module and if that
#pod better suits your needs, then by all means, use it.
#pod
#pod =head2 Note about Stack Traces
#pod
#pod It should be noted that even though these are all exception objects,
#pod only the 500 Internal Server Error error actually includes the stack
#pod trace (albiet optionally). This is because more often then not you will
#pod not actually care about the stack trace and therefore do not the extra
#pod overhead. If you do find you want a stack trace though, it is as simple
#pod as adding the L<StackTrace::Auto> role to your exceptions.
#pod
#pod =attr status_code
#pod
#pod This is the status code integer as specified in the HTTP spec.
#pod
#pod =attr reason
#pod
#pod This is the reason phrase as specified in the HTTP spec.
#pod
#pod =attr message
#pod
#pod This is an additional message string that can be supplied, which I<may>
#pod be used when stringifying or building an HTTP response.
#pod
#pod =attr additional_headers
#pod
#pod This is an arrayref of pairs that will be added to the headers of the
#pod exception when converted to a HTTP message.
#pod
#pod =method status_line
#pod
#pod This returns a string that would be used as a status line in a response,
#pod like C<404 Not Found>.
#pod
#pod =method as_string
#pod
#pod This returns a string representation of the exception.  This method
#pod B<must> be implemented by any class consuming this role.
#pod
#pod =method as_psgi
#pod
#pod This returns a representation of the exception object as PSGI
#pod response.
#pod
#pod In theory, it accepts a PSGI environment as its only argument, but
#pod currently the environment is ignored.
#pod
#pod =method to_app
#pod
#pod This is the standard Plack convention for L<Plack::Component>s.
#pod It will return a CODE ref which expects the C<$env> parameter
#pod and returns the results of C<as_psgi>.
#pod
#pod =method &{}
#pod
#pod We overload C<&{}> to call C<to_app>, again in keeping with the
#pod L<Plack::Component> convention.
#pod
#pod =head1 WELL-KNOWN TYPES
#pod
#pod Below is a list of the well-known types recognized by the factory and
#pod shipped with this distribution. The obvious 4xx and 5xx errors are
#pod included but we also include the 3xx redirection status codes. This is
#pod because, while not really an error, the 3xx status codes do represent an
#pod exceptional control flow.
#pod
#pod The implementation for each of these is in a role with a name in the
#pod form C<HTTP::Throwable::Role::Status::STATUS-NAME>.  For example, "Gone"
#pod is C<HTTP::Throwable::Role::Status::Gone>.  When throwing the exception
#pod with the factory, just pass "Gone"
#pod
#pod =head2 Redirection 3xx
#pod
#pod This class of status code indicates that further action needs to
#pod be taken by the user agent in order to fulfill the request. The
#pod action required MAY be carried out by the user agent without
#pod interaction with the user if and only if the method used in the
#pod second request is GET or HEAD.
#pod
#pod =over 4
#pod
#pod =item 300 L<HTTP::Throwable::Role::Status::MultipleChoices>
#pod
#pod =item 301 L<HTTP::Throwable::Role::Status::MovedPermanently>
#pod
#pod =item 302 L<HTTP::Throwable::Role::Status::Found>
#pod
#pod =item 303 L<HTTP::Throwable::Role::Status::SeeOther>
#pod
#pod =item 304 L<HTTP::Throwable::Role::Status::NotModified>
#pod
#pod =item 305 L<HTTP::Throwable::Role::Status::UseProxy>
#pod
#pod =item 307 L<HTTP::Throwable::Role::Status::TemporaryRedirect>
#pod
#pod =back
#pod
#pod =head2 Client Error 4xx
#pod
#pod The 4xx class of status code is intended for cases in which
#pod the client seems to have erred. Except when responding to a
#pod HEAD request, the server SHOULD include an entity containing an
#pod explanation of the error situation, and whether it is a temporary
#pod or permanent condition. These status codes are applicable to any
#pod request method. User agents SHOULD display any included entity
#pod to the user.
#pod
#pod =over 4
#pod
#pod =item 400 L<HTTP::Throwable::Role::Status::BadRequest>
#pod
#pod =item 401 L<HTTP::Throwable::Role::Status::Unauthorized>
#pod
#pod =item 403 L<HTTP::Throwable::Role::Status::Forbidden>
#pod
#pod =item 404 L<HTTP::Throwable::Role::Status::NotFound>
#pod
#pod =item 405 L<HTTP::Throwable::Role::Status::MethodNotAllowed>
#pod
#pod =item 406 L<HTTP::Throwable::Role::Status::NotAcceptable>
#pod
#pod =item 407 L<HTTP::Throwable::Role::Status::ProxyAuthenticationRequired>
#pod
#pod =item 408 L<HTTP::Throwable::Role::Status::RequestTimeout>
#pod
#pod =item 409 L<HTTP::Throwable::Role::Status::Conflict>
#pod
#pod =item 410 L<HTTP::Throwable::Role::Status::Gone>
#pod
#pod =item 411 L<HTTP::Throwable::Role::Status::LengthRequired>
#pod
#pod =item 412 L<HTTP::Throwable::Role::Status::PreconditionFailed>
#pod
#pod =item 413 L<HTTP::Throwable::Role::Status::RequestEntityTooLarge>
#pod
#pod =item 414 L<HTTP::Throwable::Role::Status::RequestURITooLong>
#pod
#pod =item 415 L<HTTP::Throwable::Role::Status::UnsupportedMediaType>
#pod
#pod =item 416 L<HTTP::Throwable::Role::Status::RequestedRangeNotSatisfiable>
#pod
#pod =item 417 L<HTTP::Throwable::Role::Status::ExpectationFailed>
#pod
#pod =back
#pod
#pod =head2 Server Error 5xx
#pod
#pod Response status codes beginning with the digit "5" indicate
#pod cases in which the server is aware that it has erred or is
#pod incapable of performing the request. Except when responding to
#pod a HEAD request, the server SHOULD include an entity containing
#pod an explanation of the error situation, and whether it is a
#pod temporary or permanent condition. User agents SHOULD display
#pod any included entity to the user. These response codes are applicable
#pod to any request method.
#pod
#pod =over 4
#pod
#pod =item 500 L<HTTP::Throwable::Role::Status::InternalServerError>
#pod
#pod =item 501 L<HTTP::Throwable::Role::Status::NotImplemented>
#pod
#pod =item 502 L<HTTP::Throwable::Role::Status::BadGateway>
#pod
#pod =item 503 L<HTTP::Throwable::Role::Status::ServiceUnavailable>
#pod
#pod =item 504 L<HTTP::Throwable::Role::Status::GatewayTimeout>
#pod
#pod =item 505 L<HTTP::Throwable::Role::Status::HTTPVersionNotSupported>
#pod
#pod =back
#pod
#pod =head1 COMPOSING WITH HTTP::THROWABLE
#pod
#pod In general, we expect that you'll use L<HTTP::Throwable::Factory> or a
#pod subclass to throw exceptions.  You can still use HTTP::Throwable
#pod directly, though, if you keep these things in mind:
#pod
#pod HTTP::Throwable is mostly concerned about providing basic headers and a
#pod PSGI representation.  It doesn't worry about the body or a
#pod stringification.  You B<must> provide the methods C<body> and
#pod C<body_headers> and C<as_string>.
#pod
#pod The C<body> method returns the string (of octets) to be sent as the HTTP
#pod entity.  That body is passed to the C<body_headers> method, which must
#pod return an arrayref of headers to add to the response.  These will
#pod generally include the Content-Type and Content-Length headers.
#pod
#pod The C<as_string> method should return a printable string, even if the
#pod body is going to be empty.
#pod
#pod For convenience, these three methods are implemented by the roles
#pod L<HTTP::Throwable::Role::TextBody> and L<HTTP::Throwable::Role::NoBody>.
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod * L<http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html>
#pod * L<Plack::Middleware::HTTPExceptions>
