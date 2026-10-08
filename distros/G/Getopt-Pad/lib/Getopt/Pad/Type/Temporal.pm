use v5.26;
use Object::Pad;

use Getopt::Pad::Type;

class Getopt::Pad::Type::Temporal :isa(Getopt::Pad::Type) :abstract {
	use Feature::Compat::Try;

	our $VERSION = '0.06';

	use constant SPEC_KEYS => ['timezone'];

	field $timezone :param :reader = 'local';
	field $zone :reader;

	# DateTime::Format::Natural is optional: a missing module, like an
	# unknown time zone, is a spec mistake reported when the spec is built.
	method checkSpecKeys :common (%args) {
		return sprintf("type '%s' requires the DateTime::Format::Natural module", $class->NAMES->[0]) if !$class->isNaturalInstalled;

		my $name = $args{timezone} // 'local';
		return 'timezone must be a non-empty string' if ref $name || $name eq '';
		return sprintf("timezone '%s' is not a known time zone", $name) if !defined $class->zoneNamed($name);
		return undef;
	}

	method isNaturalInstalled :common () {
		try {
			require DateTime::Format::Natural;
			require DateTime::TimeZone;
			return 1;
		}
		catch ($error) {
			return 0;
		}
	}

	# The DateTime::TimeZone called $name, or undef for an unknown name. A
	# local zone the system cannot tell is floating rather than an error.
	method zoneNamed :common ($name) {
		try {
			return DateTime::TimeZone->new(name => $name);
		}
		catch ($error) {
			return DateTime::TimeZone->new(name => 'floating') if $name eq 'local';
			return undef;
		}
	}

	# A spec has reported a missing module in checkSpecKeys already; a Type
	# constructed directly fails here instead.
	ADJUST {
		require DateTime::Format::Natural;
		require DateTime::TimeZone;
		$zone = __CLASS__->zoneNamed($timezone);
	}

	method glSuffix() { return '=s' }

	method newParser(%options) {
		return DateTime::Format::Natural->new(time_zone => $zone, %options);
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type::Temporal - Base class of the date and duration option
types

=head1 DESCRIPTION

The common base class of L<Getopt::Pad::Type::Date> and
L<Getopt::Pad::Type::Duration>. It is abstract: specs cannot use it
directly.

Both types parse natural language with L<DateTime::Format::Natural>,
which is not installed together with Getopt::Pad. A spec that uses one of
them without the module fails with the spec error
C<type 'NAME' requires the DateTime::Format::Natural module>.

It provides the spec key C<timezone>: the name of the time zone in which
values are parsed and returned, as L<DateTime::TimeZone> knows it. It
defaults to C<local>, the system's time zone; when the system's time
zone cannot be determined, C<local> falls back to C<floating>. An unknown
name is the spec error C<timezone 'NAME' is not a known time zone>. The
key is described for users in L<Getopt::Pad/Type-specific keys>.

A type constructed directly, outside a spec, loads
DateTime::Format::Natural when it is constructed and dies with Perl's
own message if the module is missing.

Values are coerced to objects. The help output and
C<--create-default-config> show a default as the spec wrote it, as for
every type. Every temporal type takes a value (C<glSuffix> C<'=s'>).

=head1 METHODS

=over 4

=item timezone

The time zone name from the spec.

=item zone

The L<DateTime::TimeZone> it resolved to.

=item newParser(%options)

A new L<DateTime::Format::Natural> parser in C<zone>, with C<%options>
passed on.

=back

=head1 SEE ALSO

L<Getopt::Pad::Type>, L<Getopt::Pad::Type::Date>,
L<Getopt::Pad::Type::Duration>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
