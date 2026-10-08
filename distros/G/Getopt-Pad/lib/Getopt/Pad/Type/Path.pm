use v5.26;
use Object::Pad;

use Getopt::Pad::Type;

class Getopt::Pad::Type::Path :isa(Getopt::Pad::Type) :abstract {
	use constant SPEC_KEYS => ['mustExist', 'createPathIfMissing'];

	our $VERSION = '0.06';

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

	# Whether a path exists depends on the machine, so it is asked of the
	# value a parse settles on, never of a default when the spec is built.
	# A path of the wrong kind can neither be used nor created.
	method verify($value) {
		return undef if !defined $value || (!$mustExist && !$createPathIfMissing);
		return undef if $self->pathExists($value);
		return sprintf("'%s' is not a %s", $value, $self->kind) if -e $value;
		return sprintf("%s '%s' does not exist", $self->kind, $value) if $mustExist;
		return undef;
	}

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

Getopt::Pad::Type::Path - Base class of the file and dir option types

=head1 DESCRIPTION

The common base class of L<Getopt::Pad::Type::File> and
L<Getopt::Pad::Type::Dir>. It is abstract: specs cannot use it directly.

It provides the spec keys C<mustExist> and C<createPathIfMissing>, which
exclude each other (C<mustExist and createPathIfMissing are mutually
exclusive>):

=over 4

=item mustExist

The value that is finally used must be an existing path of the
subclass's kind, checked in C<verify> (see L<Getopt::Pad::Type/verify>),
never when the spec is built. A missing path is rejected with
C<KIND 'PATH' does not exist>, where KIND is C<file> or C<directory>,
and a path of the other kind with C<'PATH' is not a KIND>. The help
output shows C<[has to exist]>.

=item createPathIfMissing

A missing path is created for the value that is finally used (in
C<prepare>, see L<Getopt::Pad::Type/prepare>). A path of the other kind
is rejected in C<verify> with C<'PATH' is not a KIND>, a failure to
create it with C<cannot create KIND 'PATH': REASON>. The help output
shows C<[created if missing]>.

=back

Both are described for users in L<Getopt::Pad/Type-specific keys>. Every
path type takes a value (C<glSuffix> C<'=s'>).

A subclass provides C<NAMES> and these methods:

=over 4

=item kind

The word used for the path in messages: C<file> or C<directory>.

=item pathExists($path)

Whether C<$path> exists and is of the right kind.

=item createPath($path)

Creates C<$path>. Returns C<undef> on success, otherwise the reason it
failed.

=back

=head1 SEE ALSO

L<Getopt::Pad::Type>, L<Getopt::Pad::Type::File>, L<Getopt::Pad::Type::Dir>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
