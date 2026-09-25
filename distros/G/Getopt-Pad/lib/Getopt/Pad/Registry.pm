use v5.26;
use Object::Pad;

class Getopt::Pad::Registry {
	use Carp qw(croak);
	use Getopt::Pad::Util qw(specError);

	our $VERSION = '0.03';

	# Registration errors are reported at the registerType/registerFormat
	# caller, not inside those one-line forwarders.
	our @CARP_NOT = qw(Getopt::Pad::Type Getopt::Pad::Config::Format);

	field $kind :param;
	field %entries;

	method register(@classes) {
		foreach my $class (@classes) {
			if (!$class->can('NAMES')) {
				(my $file = "$class.pm") =~ s{::}{/}g;
				require $file;
			}
			croak sprintf('Getopt::Pad: %s class %s does not provide a NAMES list', $kind, $class) unless $class->can('NAMES');

			# Registering a class again is harmless; taking a name away from
			# another class is not, so it fails instead of silently winning.
			foreach my $name (map { lc } $class->NAMES->@*) {
				my $owner = $entries{$name};
				croak sprintf("Getopt::Pad: %s name '%s' is already registered by %s", $kind, $name, $owner) if defined $owner && $owner ne $class;
				$entries{$name} = $class;
			}
		}

		return $self;
	}

	method resolve($name) {
		my $class = $entries{lc($name // '')};
		specError("unknown %s '%s' (known: %s)", $kind, $name // '', join(', ', $self->knownNames)) unless defined $class;

		return $class;
	}

	method knownNames() {
		return sort keys %entries;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Registry - name-to-class registry

=head1 DESCRIPTION

Name-to-class lookup table used for option Types and config Formats. Classes register under the names their NAMES constant lists; register loads a class's module file first when the package is not defined yet, so builtin lists are plain class names. A name already registered by a different class is refused (registering the same class again is a no-op), so a third-party type cannot silently replace a built-in. Resolution is case insensitive and fails loudly listing all known names.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
