use v5.26;
use Object::Pad;

use Getopt::Pad::Type;
use Getopt::Pad::Result;

class Getopt::Pad::Spec::Arg :strict(params) {
	use Getopt::Pad::Util qw(camelize specError isValidName);

	our $VERSION = '0.02';

	field $raw :param;

	field $short    :reader;
	field $reader   :reader;
	field $type     :reader;
	field $typeName :reader;
	field $required :reader = 0;
	field $multiple :reader = 0;
	field $help     :reader = '';

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

		specError("arg '%s': unknown key(s): %s", $short, join(', ', sort keys %spec)) if %spec;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Spec::Arg - one positional arg spec

=head1 DESCRIPTION

A single validated positional arg spec: short name, type instance, reader name, required/multiple/help settings.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
