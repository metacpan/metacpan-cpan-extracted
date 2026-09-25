package Getopt::Pad::Type;

use v5.26;
use strict;
use warnings;
use experimental 'signatures';

use Object::Pad;
use Getopt::Pad::Registry;
use Getopt::Pad::Util qw(specError);

our $VERSION = '0.03';

my @builtins = map { "Getopt::Pad::Type::$_" } qw(Flag Bool Counter String Int Float File Dir Url);
my $registry;

sub registry() {
	return $registry //= Getopt::Pad::Registry->new(kind => 'option type')->register(@builtins);
}

sub registerType($class) {
	return registry()->register($class);
}

# Build the Type an option or arg spec names. Takes the type name (or
# $defaultName when the spec has none) and the keys the Type declares in
# SPEC_KEYS out of %$spec, so the caller can treat whatever is left as
# unknown. The Type checks those keys first; a problem is reported for
# $owner (e.g. "option 'retries'"). Returns the Type and the name it was
# resolved under.
sub takeFromSpec($spec, $defaultName, $owner) {
	my $typeName  = delete $spec->{type} // $defaultName;
	my $typeClass = registry()->resolve($typeName);
	my @typeKeys  = $typeClass->can('SPEC_KEYS') ? $typeClass->SPEC_KEYS->@* : ();
	my %typeArgs  = map { $_ => delete $spec->{$_} } grep { exists $spec->{$_} } @typeKeys;

	my $problem = $typeClass->checkSpecKeys(%typeArgs);
	specError("%s: %s", $owner, $problem) if defined $problem;
	return ($typeClass->new(%typeArgs), $typeName);
}

class Getopt::Pad::Type :abstract {
	method glSuffix;

	# Types with SPEC_KEYS check them here, before construction: return a
	# problem description without the option name, or undef.
	method checkSpecKeys :common (%args) {
		return undef;
	}

	method takesValue() {
		return $self->glSuffix =~ /=/ ? 1 : 0;
	}

	method negatable() {
		return $self->glSuffix eq '!' ? 1 : 0;
	}

	method glSpec($names, %flags) {
		my $suffix = $self->glSuffix;
		$suffix =~ s/^=/:/ if $flags{optionalValue};
		my $glSpec = $names . $suffix;
		$glSpec .= '@' if $flags{multiple};
		$glSpec .= '%' if $flags{hash};
		return $glSpec;
	}

	method coerce($value) {
		return $value;
	}

	method check($value) {
		return undef;
	}

	# Runs once per parse on every scalar of an option's or arg's effective
	# value, after the value pipeline, for types whose values need the
	# world arranged (a path created on demand). Return a problem
	# description without the option name, or undef.
	method prepare($value) {
		return undef;
	}

	method label() {
		return undef;
	}

	method constraintNotes() {
		return ();
	}

	# Which of the shell's own completions a value of this type gets:
	# 'files', 'dirs', or undef for none.
	method completes() {
		return undef;
	}
}

class Getopt::Pad::Type::Flag :isa(Getopt::Pad::Type) :strict(params) {
	use JSON::PP ();

	use constant NAMES => ['flag'];

	method glSuffix() { return '' }

	# Config files give JSON or YAML booleans, 1/0 or ''; an undefined spec
	# default stays undefined.
	method check($value) {
		return undef if !defined $value || JSON::PP::is_bool($value) || $value =~ /\A[01]?\z/;
		return sprintf("'%s' is not a boolean (use true or false)", $value);
	}

	method coerce($value) {
		return $value if !defined $value;
		return $value ? 1 : 0;
	}
}

class Getopt::Pad::Type::Bool :isa(Getopt::Pad::Type::Flag) :strict(params) {
	use constant NAMES => ['!', 'bool', 'boolean'];

	method glSuffix() { return '!' }
}

class Getopt::Pad::Type::Counter :isa(Getopt::Pad::Type) :strict(params) {
	use constant NAMES => ['+', 'counter', 'count'];

	method glSuffix() { return '+' }

	method check($value) {
		return undef if !defined $value || $value =~ /\A[0-9]+\z/;
		return sprintf("'%s' is not a count", $value);
	}

	method coerce($value) {
		return $value if !defined $value;
		return $value + 0;
	}
}

class Getopt::Pad::Type::String :isa(Getopt::Pad::Type) :strict(params) {
	use constant NAMES => ['s', 'string', 'str'];

	method glSuffix() { return '=s' }
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type - option type base class and registry

=head1 DESCRIPTION

Abstract base class for option types and home of the type Registry. Subclass it, provide a NAMES constant and glSuffix, optionally check/coerce/prepare/label/constraintNotes and SPEC_KEYS, then call Getopt::Pad::Type::registerType with your class. Getopt::Pad::Type::takeFromSpec($spec, $defaultName, $owner) is how an option or arg spec gets its type: it resolves the spec's type name (or the default), takes that name and the type's SPEC_KEYS out of the spec hash, lets the type check those keys through the class method checkSpecKeys (a problem is reported as a spec error for $owner, e.g. "option 'retries'"), and returns the constructed type with the name it answered to, so the SPEC_KEYS handshake lives here and nowhere else.

completes names the shell's own completion a value of the type gets when the user presses tab (C<files>, C<dirs> or undef); the path types use it. glSuffix is the Getopt::Long option-spec suffix the type contributes (C<''> plain flag, C<'!'> negatable, C<'+'> counter, C<'=s'> takes a value); value-taking types return C<'=s'> even for numbers and validate in check() so all errors speak with one voice. It is the only place Getopt::Long spelling enters a type: the base class derives takesValue and negatable from it and assembles the full option specification in glSpec (appending C<@> for a C<multiple> option and C<%> for a C<hash> option), so overriding those is rarely useful. The full contract with a worked example is documented under "EXTENDING" in L<Getopt::Pad>.

The small built-in types live in this file: Flag (C<flag>) and its subclass Bool (C<!>) accept only JSON or YAML booleans, 1, 0 and C<''> and store 1 or 0; Counter (C<+>) accepts only non-negative integers; String (C<s>) accepts any single value. The built-ins with more behaviour (Int, Float, File, Dir, Url) have modules of their own.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
