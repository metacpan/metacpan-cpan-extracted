package HTTP::Exception;
$HTTP::Exception::VERSION = '0.04006';
use strict;
use HTTP::Status;
use Scalar::Util qw(blessed);

################################################################################
sub import {
    my ($class) = shift;
    require HTTP::Exception::Loader;
    HTTP::Exception::Loader->import(@_);
}

# act as a kind of factory here
sub new  {
    my $class       = shift;
    my $error_code  = shift;

    die ('HTTP::Exception->throw needs a HTTP-Statuscode to throw')  unless ($error_code);
    die ("Unknown HTTP-Statuscode: $error_code") unless (HTTP::Status::status_message ($error_code));

    "HTTP::Exception::$error_code"->new(@_);
}

# makes HTTP::Exception->caught possible instead of HTTP::Exception::Base->caught
sub caught {
    my $self = shift;
    my $e = $@;
    return $e if (blessed $e && $e->isa('HTTP::Exception::Base'));
    $self->SUPER::caught(@_);
}

1;


=head1 NAME

HTTP::Exception - throw HTTP-Errors as (Exception::Class-) Exceptions

=head1 VERSION

version 0.04006

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

=end readme

=head1 SYNOPSIS

HTTP::Exception lets you throw HTTP-Errors as Exceptions.

    use HTTP::Exception;

    # throw a 404 Exception
    HTTP::Exception->throw(404);

    # later in your framework
    eval { ... };
    if (my $e = HTTP::Exception->caught) {
        # do some errorhandling stuff
        print $e->code;             # 404
        print $e->status_message;   # Not Found
    }

You can also throw HTTP::Exception-subclasses like this.

    # same 404 Exception
    eval { HTTP::Exception::404->throw(); };
    eval { HTTP::Exception::NOT_FOUND->throw(); };

And catch them accordingly.

    # same 404 Exception
    eval { HTTP::Exception::404->throw(); };

    if (my $e = HTTP::Exception::405->caught)       { do stuff } # won't catch
    if (my $e = HTTP::Exception::404->caught)       { do stuff } # will catch
    if (my $e = HTTP::Exception::NOT_FOUND->caught) { do stuff } # will catch
    if (my $e = HTTP::Exception::4XX->caught)       { do stuff } # will catch all 4XX Exceptions
    if (my $e = HTTP::Exception->caught)            { do stuff } # will catch every HTTP::Exception
    if (my $e = Exception::Class->caught)           { do stuff } # catch'em all

You can create Exceptions and not throw them, because maybe you want to set some
fields manually. See L<HTTP::Exception/"FIELDS"> and
L<HTTP::Exception/"ACCESSORS"> for more info.

    # is not thrown, ie doesn't die, only created
    my $e = HTTP::Exception->new(404);

    # usual stuff works
    $e->code;               # 404
    $e->status_message      # Not Found

    # set status_message to something else
    $e->status_message('Nothing Here')

    # fails, because code is only an accessor, see section ACCESSORS below
    # $e->code(403);

    # and finally throw our prepared exception
    $e->throw;

=head1 DESCRIPTION

Every HTTP::Exception is a L<Exception::Class> - Class. So the same mechanisms
apply as with L<Exception::Class>-classes. In fact have a look at
L<Exception::Class>' docs for more general information on exceptions and
L<Exception::Class::Base> for information on what methods a caught exception
also has.

HTTP::Exception is only a factory for HTTP::Exception::XXX (where X is a number)
subclasses. That means that HTTP::Exception->new(404) returns a
HTTP::Exception::404 object, which in turn is a HTTP::Exception::Base - Object.

Don't bother checking a caught HTTP::Exception::...-class with "isa" as it might
not contain what you would expect. Use the code- or status_message-attributes
and the is_ -methods instead.

The subclasses are created at compile-time, ie the first time you make
"use HTTP::Exception". See paragraph below for the naming scheme of those
subclasses.

Subclassing the subclasses works as expected.

=head1 NAMING SCHEME

=head2 HTTP::Exception::XXX

X is a Number and XXX is a valid HTTP-Statuscode. All HTTP-Statuscodes are
supported. See chapter L<HTTP::Exception/"COMPLETENESS">

=head2 HTTP::Exception::STATUS_MESSAGE

STATUS_MESSAGE is the same name as a L<HTTP::Status> Constant B<WITHOUT>
the HTTP_ at the beginning. So see L<HTTP::Status/"CONSTANTS"> for more details.

=head1 IMPORTING SPECIFIC ERROR RANGES

It is possible to load only specific ranges of errors. For example

    use HTTP::Exception qw(5XX);

    HTTP::Exception::500->throw; # works
    HTTP::Exception::400->throw; # won't work anymore

will only create HTTP::Exception::500 till HTTP::Exception::510. In theory this
should save some memory, but I don't have any numbers, that back up this claim.

You can load multiple ranges

    use HTTP::Exception qw(3XX 4XX 5XX);

And there are aliases for ranges

    use HTTP::Exception qw(CLIENT_ERROR)

The following aliases exist and load the specified ranges:

    REDIRECTION   => 3XX
    CLIENT_ERROR  => 4XX
    SERVER_ERROR  => 5XX
    ERROR         => 4XX 5XX
    ALL           => 1XX 2XX 3XX 4XX 5XX

And of course, you can load multiple aliased ranges

    use HTTP::Exception qw(REDIRECTION ERROR)

ALL is the same as not specifying any specific range.

    # the same
    use HTTP::Exception qw(ALL);
    use HTTP::Exception;

=head1 ACCESSORS (READONLY)

=head2 code

A valid HTTP-Statuscode. See L<HTTP::Status> for information on what codes exist.

=head2 is_info

Return TRUE if C<$self->code> is an I<Informational> status code (1xx).  This
class of status code indicates a provisional response which can't have
any content.

=head2 is_success

Return TRUE if C<$self->code> is a I<Successful> status code (2xx).

=head2 is_redirect

Return TRUE if C<$self->code> is a I<Redirection> status code (3xx). This class
if status code indicates that further action needs to be taken by the
user agent in order to fulfill the request.

=head2 is_error

Return TRUE if C<$self->code> is an I<Error> status code (4xx or 5xx).  The
function return TRUE for both client error or a server error status codes.

=head2 is_client_error

Return TRUE if C<$self->code> is an I<Client Error> status code (4xx). This
class of status code is intended for cases in which the client seems to
have erred.

=head2 is_server_error

Return TRUE if C<$self->code> is an I<Server Error> status code (5xx). This
class of status codes is intended for cases in which the server is aware
that it has erred or is incapable of performing the request.

I<POD for is_ methods is Copy/Pasted from L<HTTP::Status>, so check back there and
alert me of changes.>

=head1 FIELDS

Fields are the same as ACCESSORS except they can be set. Either you set them
during Exception creation (->new) or Exception throwing (->throw).

    HTTP::Exception->new(200, status_message => "Everything's fine");
    HTTP::Exception::200->new(status_message => "Everything's fine");
    HTTP::Exception::OK->new(status_message => "Everything's fine");

    HTTP::Exception->throw(200, status_message => "Everything's fine");
    HTTP::Exception::200->throw(status_message => "Everything's fine");
    HTTP::Exception::OK->throw(status_message => "Everything's fine");

Catch them in your Webframework like this

    eval { ... }
    if (my $e = HTTP::Exception->caught) {
        print $e->code;          # 200
        print $e->status_message # "Everything's fine" instead of the usual ok
    }

=head2 status_message

B<DEFAULT> The HTTP-Statusmessage as provided by L<HTTP::Status>

A Message, that represents the Execptions' Status for Humans.

=head1 PLACK

HTTP::Exception can be used with L<Plack::Middleware::HTTPExceptions>. But
HTTP::Exception does not depend on L<Plack>, you can use it anywhere else. It
just plays nicely with L<Plack>.

=head1 COMPLETENESS

For the sake of completeness, HTTP::Exception provides exceptions for
non-error-http-statuscodes. This means you can do

    HTTP::Exception->throw(200);

which throws an Exception of type OK. Maybe useless, but complete.
A more realworld-example would be a redirection

    # all are exactly the same
    HTTP::Exception->throw(301, location => 'google.com');
    HTTP::Exception::301->throw(location => 'google.com');
    HTTP::Exception::MOVED_PERMANENTLY->throw(location => 'google.com');

=head1 CAVEATS

The HTTP::Exception-Subclass-Creation relies on L<HTTP::Status>.
It's possible that the Subclasses change, when HTTP::Status'
constants are changed.

New Subclasses are created automatically, when constants are added to
HTTP::Status. That means in turn, that Subclasses disappear, when constants
are removed from L<HTTP::Status>.

Some constants were added to L<HTTP::Status>' in February 2012. As a result
HTTP::Exception broke. But that was the result of uncareful coding on my side.
I think, that breaking changes are now quite unlikely.

=head1 AUTHOR

Thomas Mueller, C<< <tmueller at cpan.org> >>

=head1 SEE ALSO

=head2 L<Exception::Class>, L<Exception::Class::Base>

Consult Exception::Class' documentation for the Exception-Mechanism and
Exception::Class::Base' docs for a list of methods our caught Exception is also
capable of.

=head2 L<HTTP::Status>

Constants, Statuscodes and Statusmessages

=head2 L<Plack>, especially L<Plack::Middleware::HTTPExceptions>

Have a look at Plack, because it rules in general. In the first place, this
Module was written as the companion for L<Plack::Middleware::HTTPExceptions>,
but since it doesn't depend on Plack, you can use it anywhere else, too.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-http-exception at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-Exception>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTTP::Exception

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-Exception>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTTP-Exception>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTTP-Exception>

=item * Search CPAN

L<https://metacpan.org/release/HTTP-Exception>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Thomas Mueller.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
