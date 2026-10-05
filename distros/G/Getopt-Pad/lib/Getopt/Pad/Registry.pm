use v5.26;
use Object::Pad;

class Getopt::Pad::Registry {
	use Carp qw(croak);
	use Getopt::Pad::Util qw(specError);

	our $VERSION = '0.05';

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

Getopt::Pad::Registry - Looks up types and formats by name (internal)

=head1 DESCRIPTION

This module is internal to Getopt::Pad. It is not part of the public
API and can change without notice. Programs use L<Getopt::Pad/GetOptions>;
this page is for people working on Getopt::Pad itself.

A registry maps names to classes. There are two: one for option types,
used through L<Getopt::Pad::Type/registerType>, and one for config
formats, used through L<Getopt::Pad::Config::Format/registerFormat>. They
are the only places where a type or format name in a spec is resolved.

=head1 METHODS

=over 4

=item new(kind => $kind)

C<$kind> names the registry in messages, such as C<option type>.

=item register(@classes)

Registers every class under the names its C<NAMES> constant lists, in
lower case. A class without a C<NAMES> method has its module file loaded
first, so the built-in classes can be listed by name. A name already
registered by another class makes C<register> die; registering the same
class again changes nothing. Returns the registry.

=item resolve($name)

The class registered under C<$name>, matched case-insensitively. An
unknown name is a spec error that lists all known names.

=item knownNames

All registered names, sorted.

=back

=head1 SEE ALSO

L<Getopt::Pad::Type>, L<Getopt::Pad::Config::Format>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
