package Gears::X::HTTP;
$Gears::X::HTTP::VERSION = '0.100';
use v5.40;
use Mooish::Base -standard;

extends 'Gears::X';

has param 'code' => (
	isa => IntRange [400, 500],
);

sub _raise_exception ($self, $code, $message)
{
	$self->new(code => $code, message => $message)->raise;
}

sub raise ($self, @args)
{
	$self->_raise_exception(@args)
		if @args != 0;

	die $self;
}

sub _build_message ($self)
{
	return $self->code . ' - ' . $self->message;
}

__END__

=head1 NAME

Gears::X::HTTP - HTTP exception class

=head1 SYNOPSIS

	use Gears::X::HTTP;

	# Raise an HTTP error
	Gears::X::HTTP->raise(404, "Page not found");
	Gears::X::HTTP->raise(500, "Internal error");

	# Create and raise later
	my $error = Gears::X::HTTP->new(
		code => 403,
		message => "Access denied",
	);
	$error->raise;

	# Catch and inspect
	try {
		Gears::X::HTTP->raise(400, "Bad request");
	}
	catch ($e) {
		say $e->code;     # 400
		say $e->message;  # Bad request
		say $e;           # An error occured: [HTTP] 400 - Bad request (raised at ...)
	}

=head1 DESCRIPTION

Gears::X::HTTP is an exception class for HTTP-related errors. It extends
L<Gears::X> with an HTTP status code attribute and provides a convenient
interface for raising HTTP errors with appropriate codes.

The exception enforces that the status code is in the valid HTTP error range
(400-500). The message is automatically formatted to include the status code.

=head1 INTERFACE

=head2 Attributes

=head3 code

The HTTP status code. Must be in the range 400-500 (inclusive). This covers
client errors (4xx) and server errors (5xx).

I<Required in constructor>

=head2 Methods

=head3 new

	$object = $class->new(%args)

A standard Mooish constructor. Consult L</Attributes> section to learn what
keys can key passed in C<%args>.

=head3 raise

	$exception->raise()
	$class->raise($code, $message)

Raises an HTTP exception. Same as L<Gears::X/raise>, but adds an additional
argument C<$code> (for L</code>).

=head1 SEE ALSO

L<Gears::X> - Base exception class

