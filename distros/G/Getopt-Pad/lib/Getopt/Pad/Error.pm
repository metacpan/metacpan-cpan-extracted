use v5.26;
use Object::Pad;

class Getopt::Pad::Error {
	use overload '""' => sub { $_[0]->message }, fallback => 1;

	our $VERSION = '0.03';

	field $message :param :reader;
	field $level   :param :reader = undef;

	method throw :common ($format, @args) {
		die $class->new(message => sprintf($format, @args));
	}

	method attachContext($contextLevel) {
		$level //= $contextLevel;
		return $self;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Error - user-facing error exception

=head1 DESCRIPTION

Exception class for user-facing parse and validation errors; GetOptions turns it into STDERR output and exit status 2. Stringifies to its message; throw builds the message sprintf-style from a format and its arguments.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
