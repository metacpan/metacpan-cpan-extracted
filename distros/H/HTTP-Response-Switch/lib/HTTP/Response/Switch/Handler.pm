package HTTP::Response::Switch::Handler;
{
  $HTTP::Response::Switch::Handler::VERSION = '1.1.1';
}
# ABSTRACT: handle one specific type of HTTP::Response


use Moose::Role;
use namespace::autoclean;
use HTTP::Response::Switch::HandlerDeclinedResponse ();


requires 'handle';


has 'response' => (
    is          => 'ro',
    isa         => 'HTTP::Response',
    required    => 1,
);


sub decline {
    HTTP::Response::Switch::HandlerDeclinedResponse->throw;
}


1;

__END__

=pod

=for :stopwords Alex Peters analyse

=head1 NAME

HTTP::Response::Switch::Handler - handle one specific type of HTTP::Response

=head1 VERSION

This module is part of distribution HTTP-Response-Switch v1.1.1.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 SYNOPSIS

A handler that handles an "expected" response:

    package MyProject::PageHandler::RawDataPage;
    use Moose;
    with 'HTTP::Response::Switch::Handler';

    sub handle {
        my $self = shift;

        # Each handler should only deal with one concern; let other
        # handlers deal with other things.
        $self->decline
            if $self->response->headers->content_type ne 'text/csv';

        # This response holds something that this handler can handle.
        return STRUCTURED_DATA_FROM( $self->response->content );
    }

A handler that handles an "unexpected" or undesired response:

    package MyProject::PageHandler::RawDataForm;
    use Moose;
    with 'HTTP::Response::Switch::Handler';

    sub handle {
        my $self = shift;
        $self->decline
            if NOT_A_RAW_DATA_FORM( $self->response->content );

        # If the web server is providing a form, there's a problem with
        # user data.  Extract the errors and throw an exception.
        die MyProject::Error::UserDataProblem->new(
            errors => EXTRACT_ERRORS_FROM( $self->response->content ),
        );
    }

=head1 DESCRIPTION

A "handler" class holds the logic to identify one particular type of
L<HTTP::Response> that might be returned by a web application, and
perform an appropriate action like:

=over 4

=item *

parsing the page and returning structured data; or

=item *

throwing a specific exception in the case of specific "unexpected" or
undesired web server responses.

=back

These "handler" classes are called upon by a
L<"dispatcher"|HTTP::Response::Switch> class, which is responsible for
delegating a response to the correct handlers in the correct order.

=head1 METHODS TO DEFINE IN CONSUMING CLASSES

These methods must be defined in order for the consuming class to work.

=head2 handle

    my %structured_data = $instance->handle;
    my @structured_data = $instance->handle;
    my $structured_data = $instance->handle;

Obtain the L</response> object and L</decline> to analyse it if it
doesn't concern this handler.  Otherwise, return some sort of
structured data or throw a specific exception as appropriate.

The specific type of data to return, if any, depends entirely on what
the caller wants.

If this method returns without error (even if it returns nothing), it
is deemed to have successfully handled the response and subsequent
handlers will not be invoked by the
L<dispatcher|HTTP::Response::Switch>.

=head1 METHODS AVAILABLE WITHIN CONSUMING CLASSES

These methods are intended only to be called on a consuming class by
that class itself, and not by code external to the class.

=head2 response

    my $http_response = $self->response;

The L<HTTP::Response> object to analyse.

=head2 decline

    $self->decline if NOT_MY_TYPE( $self->response );

Indicate that this particular handler cannot handle this particular
L</response>.  This is done by throwing an
L<HTTP::Response::Switch::HandlerDeclinedResponse> exception, which
prevents further execution of the handler from occurring.

=head1 SEE ALSO



=over 4

=item *

L<HTTP::Response::Switch>

=item *

L<HTTP::Response::Switch::HandlerDeclinedResponse>

=back

=head1 AUTHOR

Alex Peters <lxp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alex Peters.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
'LICENSE' file included with this distribution.

=cut
