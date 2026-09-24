use v5.26;
use Object::Pad;

use Getopt::Pad::Type::Path;

class Getopt::Pad::Type::File :isa(Getopt::Pad::Type::Path) :strict(params) {
	use constant NAMES => ['file'];

	our $VERSION = '0.02';

	method label() { return 'File Path' }

	method kind() { return 'file' }

	method completes() { return 'files' }

	method pathExists($value) { return -f $value }
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type::File - file path type

=head1 DESCRIPTION

File path, optionally required to exist via C<mustExist>.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
