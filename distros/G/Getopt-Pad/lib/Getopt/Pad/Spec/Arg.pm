use v5.26;
use Object::Pad;

use Getopt::Pad::Type;
use Getopt::Pad::Result;

class Getopt::Pad::Spec::Arg :strict(params) {
	use Getopt::Pad::Util qw(camelize specError isValidName);

	our $VERSION = '0.05';

	field $raw :param;

	field $short    :reader;
	field $reader   :reader;
	field $type     :reader;
	field $typeName :reader;
	field $required :reader = 0;
	field $multiple :reader = 0;
	field $help     :reader = '';
	field $typehint :reader;

	ADJUST {
		specError("arg: spec must be a hash reference") if ref $raw ne 'HASH';

		my %spec = $raw->%*;
		$short   = delete $spec{short};
		specError("arg: missing or invalid 'short' name") if !isValidName($short);
		$reader = camelize($short);
		specError("arg '%s': reader '%s' collides with a built-in result method", $short, $reader) if Getopt::Pad::Result->reservesReader($reader);

		($type, $typeName) = Getopt::Pad::Type::takeFromSpec(\%spec, 'string', sprintf("arg '%s'", $short));
		specError("arg '%s': type '%s' cannot be used for a positional arg", $short, $typeName) if !$type->takesValue;

		$required = delete $spec{required} ? 1 : 0;
		$multiple = delete $spec{multiple} ? 1 : 0;
		$help     = delete $spec{help} // '';
		$typehint = delete $spec{typehint};

		specError("arg '%s': unknown key(s): %s", $short, join(', ', sort keys %spec)) if %spec;
		specError("arg '%s': typehint must be a non-empty string", $short) if defined $typehint && (ref $typehint || $typehint eq '');
	}

	# The tag the help output renders after the help text: the spec's
	# typehint, or what the type calls itself.
	method typeLabel() {
		return $typehint // $type->label;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Spec::Arg - One positional arg of a spec (internal)

=head1 DESCRIPTION

This module is internal to Getopt::Pad. It is not part of the public
API and can change without notice. Programs use L<Getopt::Pad/GetOptions>;
this page is for people working on Getopt::Pad itself.

An arg spec holds the checked settings of one positional arg: its
C<short> name, the reader name derived from it, the type (a
L<Getopt::Pad::Type> instance that must take a value) and the keys
C<required>, C<multiple>, C<help> and C<typehint>. The meaning of each key
is documented in L<Getopt::Pad/ARG SPECS>. Unknown keys are a spec error.

The order rules between args (a required arg after an optional one, and
C<multiple> on the last arg only) are checked by
L<Getopt::Pad::Spec::Level>; the values are checked by
L<Getopt::Pad::Parser> when it consumes the positional words.

=head1 METHODS

The readers C<short>, C<reader>, C<type>, C<typeName>, C<required>,
C<multiple>, C<help> and C<typehint>, and:

=over 4

=item typeLabel

The tag the help output shows: C<typehint>, or the type's C<label>.

=back

=head1 SEE ALSO

L<Getopt::Pad::Spec::Level>, L<Getopt::Pad::Parser>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
