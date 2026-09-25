use v5.26;
use Object::Pad;

use Getopt::Pad::Type;

class Getopt::Pad::Type::Path :isa(Getopt::Pad::Type) :abstract {
	use constant SPEC_KEYS => ['mustExist', 'createPathIfMissing'];

	our $VERSION = '0.03';

	field $mustExist           :param :reader = 0;
	field $createPathIfMissing :param :reader = 0;

	method checkSpecKeys :common (%args) {
		return 'mustExist and createPathIfMissing are mutually exclusive' if $args{mustExist} && $args{createPathIfMissing};
		return undef;
	}

	method glSuffix() { return '=s' }

	method kind;
	method pathExists($value);

	# Create the path; return undef, or the reason it could not be created.
	method createPath($value);

	method check($value) {
		return sprintf("%s '%s' does not exist", $self->kind, $value) if $mustExist && !$self->pathExists($value);
		return undef;
	}

	# A path is created when the parse settles on it, not when a default is
	# checked at spec build time.
	method prepare($value) {
		return undef if !defined $value || !$createPathIfMissing || $self->pathExists($value);

		my $reason = $self->createPath($value);
		return defined $reason ? sprintf("cannot create %s '%s': %s", $self->kind, $value, $reason) : undef;
	}

	method constraintNotes() {
		return ('has to exist')        if $mustExist;
		return ('created if missing') if $createPathIfMissing;
		return ();
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type::Path - filesystem path type base class

=head1 DESCRIPTION

Abstract base for filesystem path types: owns the C<mustExist> and C<createPathIfMissing> keys (mutually exclusive), the existence check, the creation on demand through prepare, and the "has to exist" / "created if missing" annotations. Subclasses provide kind (the word used in error messages), pathExists, the filesystem test, and createPath, the creation (see File and Dir).

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
