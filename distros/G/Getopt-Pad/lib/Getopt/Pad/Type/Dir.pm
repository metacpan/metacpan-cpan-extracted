use v5.26;
use Object::Pad;

use Getopt::Pad::Type::Path;

class Getopt::Pad::Type::Dir :isa(Getopt::Pad::Type::Path) :strict(params) {
	use constant NAMES => ['dir', 'directory'];
	use File::Path ();

	our $VERSION = '0.03';

	method label() { return 'Path' }

	method kind() { return 'directory' }

	method completes() { return 'dirs' }

	method pathExists($value) { return -d $value }

	method createPath($value) {
		File::Path::make_path($value, { error => \my $errors });
		return undef if !$errors->@*;
		my ($path, $reason) = $errors->[0]->%*;
		return $reason;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type::Dir - directory path type

=head1 DESCRIPTION

Directory path, optionally required to exist via C<mustExist>, or created with its parents on demand via C<createPathIfMissing>.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
