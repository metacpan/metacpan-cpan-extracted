use v5.26;
use Object::Pad;

use Getopt::Pad::Type;
use Getopt::Pad::Result;

class Getopt::Pad::Spec::Arg :strict(params) {
	use Getopt::Pad::Util qw(camelize specError isValidName processedWith);

	our $VERSION = '0.06';

	field $raw   :param;
	# Where the arg sits in the spec, as the start of a spec error, e.g.
	# "command 'image resize': ".
	field $where :param = '';

	field $short    :reader;
	field $reader   :reader;
	field $type     :reader;
	field $typeName :reader;
	field $required :reader = 0;
	field $multiple :reader = 0;
	field $help     :reader = '';
	field $typehint :reader;
	field $processValue :reader;

	ADJUST {
		specError("%sarg: spec must be a hash reference", $where) if ref $raw ne 'HASH';

		my %spec = $raw->%*;
		$short   = delete $spec{short};
		specError("%sarg: missing or invalid 'short' name", $where) if !isValidName($short);
		$reader = camelize($short);
		specError("%sarg '%s': reader '%s' collides with a built-in result method", $where, $short, $reader) if Getopt::Pad::Result->reservesReader($reader);

		($type, $typeName) = Getopt::Pad::Type::takeFromSpec(\%spec, 'string', sprintf("%sarg '%s'", $where, $short));
		specError("%sarg '%s': type '%s' cannot be used for a positional arg", $where, $short, $typeName) if !$type->takesValue;

		$required = delete $spec{required} ? 1 : 0;
		$multiple = delete $spec{multiple} ? 1 : 0;
		$help     = delete $spec{help} // '';
		$typehint = delete $spec{typehint};
		$processValue = delete $spec{processValue};

		specError("%sarg '%s': unknown key(s): %s", $where, $short, join(', ', sort keys %spec)) if %spec;
		specError("%sarg '%s': typehint must be a non-empty string", $where, $short) if defined $typehint && (ref $typehint || $typehint eq '');
		specError("%sarg '%s': processValue must be a code reference", $where, $short) if defined $processValue && ref $processValue ne 'CODE';
	}

	# The tag the help output renders after the help text: the spec's
	# typehint, or what the type calls itself.
	method typeLabel() {
		return $typehint // $type->label;
	}

	method processedValue($result, $value) {
		return processedWith($processValue, $result, $value);
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
C<required>, C<multiple>, C<help>, C<typehint> and C<processValue>. The
meaning of each key is documented in L<Getopt::Pad/ARG SPECS>. Unknown
keys are a spec error. Spec errors start with the optional C<where>
constructor param, which the declaring L<Getopt::Pad::Spec::Level> sets
to its command path (C<command 'image resize': >).

The order rules between args (a required arg after an optional one, and
C<multiple> on the last arg only) are checked by
L<Getopt::Pad::Spec::Level>; the values are checked by
L<Getopt::Pad::Parser> when it consumes the positional words.

=head1 METHODS

The readers C<short>, C<reader>, C<type>, C<typeName>, C<required>,
C<multiple>, C<help>, C<typehint> and C<processValue>, and:

=over 4

=item processedValue($result, $value)

The reader value with every single value in it replaced by what the
C<processValue> coderef returns when called with C<$result> and the
value. An arg that was not given (C<undef>) is left alone. Without
C<processValue> the value is returned as it is.

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
