use v5.26;
use Object::Pad;

use Getopt::Pad::Type::Path;

class Getopt::Pad::Type::File :isa(Getopt::Pad::Type::Path) :strict(params) {
	use constant NAMES => ['file'];
	use File::Basename ();
	use File::Path     ();

	our $VERSION = '0.03';

	method label() { return 'File Path' }

	method kind() { return 'file' }

	method completes() { return 'files' }

	method pathExists($value) { return -f $value }

	# The parent directories are created along with the empty file.
	method createPath($value) {
		File::Path::make_path(File::Basename::dirname($value), { error => \my $errors });
		if ($errors->@*) {
			my ($path, $reason) = $errors->[0]->%*;
			return $reason;
		}
		open my $handle, '>>', $value or return "$!";
		close $handle;
		return undef;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type::File - file path type

=head1 DESCRIPTION

File path, optionally required to exist via C<mustExist>, or created empty with its parent directories on demand via C<createPathIfMissing>.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
