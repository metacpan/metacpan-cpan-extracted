use v5.26;
use Object::Pad;

use Getopt::Pad::Type;
use Getopt::Pad::Result;

class Getopt::Pad::Spec::Arg :strict(params) {
	use Getopt::Pad::Util qw(camelize specError isValidName);

	our $VERSION = '0.03';

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

Getopt::Pad::Spec::Arg - one positional arg spec

=head1 DESCRIPTION

A single validated positional arg spec: short name, type instance, reader name, required/multiple/help/typehint settings. typeLabel is the tag the help output shows for the arg: the typehint, or the type's own label.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
