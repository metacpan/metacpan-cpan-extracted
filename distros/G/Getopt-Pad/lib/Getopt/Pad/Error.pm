use v5.26;
use Object::Pad;

class Getopt::Pad::Error {
	use overload '""' => sub { $_[0]->message }, fallback => 1;

	our $VERSION = '0.04';

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

Getopt::Pad::Error - The exception for user errors (internal)

=head1 DESCRIPTION

This module is internal to Getopt::Pad. It is not part of the public
API and can change without notice. Programs use L<Getopt::Pad/GetOptions>;
this page is for people working on Getopt::Pad itself.

The exception thrown for every mistake on the command line or in a
config file. C<GetOptions> catches it, prints C<ERROR: MESSAGE> and the
help text of the level it belongs to to STDERR, and exits with status 2.
Spec errors are not Getopt::Pad::Error objects; they are plain C<die>
messages.

=head1 METHODS

=over 4

=item throw($format, @args)

Class method. Throws a new error whose message is
C<sprintf($format, @args)>.

=item message

The message. The object also stringifies to it.

=item level

The spec level the error belongs to, or C<undef>.

=item attachContext($level)

Sets the level if none is set yet, and returns the error. The parser
calls it while the exception passes through; the first level set is
kept.

=back

=head1 SEE ALSO

L<Getopt::Pad/ERRORS AND EXIT STATUS>, L<Getopt::Pad::ExitRequest>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
