use v5.26;
use Object::Pad;

use Getopt::Pad::Type;

class Getopt::Pad::Type::Path :isa(Getopt::Pad::Type) :abstract {
	use constant SPEC_KEYS => ['mustExist'];

	our $VERSION = '0.02';

	field $mustExist :param :reader = 0;

	method glSuffix() { return '=s' }

	method kind;
	method pathExists($value);

	method check($value) {
		return sprintf("%s '%s' does not exist", $self->kind, $value) if $mustExist && !$self->pathExists($value);
		return undef;
	}

	method constraintNotes() {
		return $mustExist ? ('has to exist') : ();
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type::Path - filesystem path type base class

=head1 DESCRIPTION

Abstract base for filesystem path types: owns the C<mustExist> key, its existence check and the "has to exist" annotation. Subclasses provide kind (the word used in error messages) and pathExists, the filesystem test (see File and Dir).

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
