package Leyland::Exception;

# ABSTRACT: Throwable class for Leyland application exceptions

use Moo;
use namespace::clean;

=head1 NAME

Leyland::Exception - Throwable class for Leyland application exceptions

=head1 SYNOPSIS

	# in your controllers:

	# throw a simple exception
	$c->exception({ code => 400, error => "You need to give me your name" })
		unless $c->params->{name};

	# you can even render the error according to the requested media type
	create_something()
		|| $c->exception({
			code => 500,
			error => "Man, I have no idea what went wrong",
			mimes => {
				'text/html' => 'error.html',
				'application/json' => 'error.json',
			},
		});

	# or you can create an error that redirects (don't do this unless
	# you have a good reason to, you'd most likely want to use
	# $c->res->redirect to redirect requests). The only place where
	# this should be acceptable is inside controller methods such
	# as auto() and pre_route(), where redirecting responses is not
	# yet possible.
	$c->exception({
		code => 303,
		error => "The resource you're requesting is available at a different location",
		location => $c->uri_for('/some_other_place'),
	});

=head1 DESCRIPTION

This module provides L<Leyland> applications the ability to throw HTTP exceptions
in a consistent and standard way. Leyland applications are meant to throw
standard HTTP errors, like "404 Not Found", "400 Bad Request", "500 Internal
Server Error", etc. Check out L<List of HTTP status codes at Wikipedia|https://secure.wikimedia.org/wikipedia/en/w/index.php?title=List_of_HTTP_status_codes&oldid=424349307>
for a list of HTTP status codes and their descriptions/use cases (the
4xx and 5xx family of status codes are most relevant).

When your application throws a Leyland::Exception, it is caught and automatically
serialized to a format the request accepts (or text if the client doesn't
accept anything we support). You can, however, render the errors into
views with your application's view class (like L<Leyland::View::Tenjin>),
mostly useful for rendering HTML representations of errors inside your
application's layout, thus preserving the design of your application even
when throwing errors.

While you can use this class to throw errors with any HTTP status code,
you really only should do this with the 4xx and 5xx family of status codes.
You can, however, throw errors with a 3xx status code, in which case you
are also expected to provide a URI to redirect to. You should only use this
if you have a good reason to, as it is much more proper to redirect using
C<< $c->res->redirect >> (see L<Leyland::Manual::Controller/"ROUTES">) for more information.

Note that you don't use this class directly. Instead, to throw exceptions,
use C<exception()> in L<Leyland::Context>.

If your application throws an error without calling the C<exception()>
method just mentioned, it will still be caught and automatically turned
into a 500 Internal Server Error. This makes the most sense, as such errors
are most likely to be runtime errors thrown by modules your application
uses.

=head1 CONSUMES

L<Throwable>

=head1 ATTRIBUTES

=head2 code

The HTTP status code of the error. Required.

=head2 error

An error message describing the error that occured. Optional.

=head2 location

A URI to redirect to if this is a redirecting exception.

=head2 mimes

A hash-ref of media types and template names to use for rendering the
error.

=head2 use_layout

A boolean value indicating whether to render the errors inside a layout
view (if exception has the "mimes" attribute). Defaults to true.

=head2 previous_exception

Consumed from L<Throwable>.

=cut

with 'Throwable';

has 'code' => (
	is => 'ro',
	isa => sub { die "code must be an integer" unless $_[0] =~ m/^\d+$/ },
	required => 1
);

has 'error' => (
	is => 'ro',
	isa => sub { die "error must be a scalar" if ref $_[0] },
	predicate => 'has_error',
	writer => '_set_error'
);

has 'location' => (
	is => 'ro',
	isa => sub { die "location must be a scalar" if ref $_[0] },
	predicate => 'has_location'
);

has 'mimes' => (
	is => 'ro',
	isa => sub { die "mimes must be a hash-ref" unless ref $_[0] && ref $_[0] eq 'HASH' },
	predicate => 'has_mimes'
);

has 'use_layout' => (
	is => 'ro',
	default => sub { 1 }
);

=head1 OBJECT METHODS

=head2 has_error()

Returns a true value if the "error" attribute has a value.

=head2 has_location()

Returns a true value if the "location" attribute has a value.

=head2 has_mimes()

Returns a true value if the "mimes" attribute has a value.

=head2 has_mime( $mime )

Returns a true value if the "mimes" attribute has a value for the provided
mime type.

=cut

sub has_mime {
	my ($self, $mime) = @_;

	return unless $self->has_mimes;

	return exists $self->mimes->{$mime};
}

=head2 mime( $mime )

Returns the value of provided mime type from the "mimes" attribute, or
C<undef> if it doesn't exist.

=cut

sub mime {
	my ($self, $mime) = @_;

	return unless $self->has_mime($mime);

	return $self->mimes->{$mime};
}

=head2 name()

Returns the name of the exception. For example, if the error status code
is 404, the name will be "Not Found".

=cut

sub name {
	$Leyland::CODES->{$_[0]->code} || 'Internal Server Error';
}

=head2 hash()

Returns a hash-ref representation of the error. This hash-ref will have
the keys C<error> (which will hold the exception code and the exception
name, separated by a space, e.g. C<404 Not Found>), and C<message>, which
will hold the error message.

=cut

sub hash {
	my $self = shift;

	return {
		error => $self->code.' '.$self->name,
		message => $self->error
	};
}

=head1 INTERNAL METHODS

The following methods are only to be used internally.

=head2 BUILD()

=cut

sub BUILD {
	my $self = shift;

	$self->_set_error($self->code.' '.$self->name)
		unless $self->has_error;
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Leyland at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Leyland>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Leyland::Exception

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Leyland>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Leyland>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Leyland>

=item * Search CPAN

L<http://search.cpan.org/dist/Leyland/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
