use v5.26;
use Object::Pad;

use Getopt::Pad::Type;

class Getopt::Pad::Type::Url :isa(Getopt::Pad::Type) :strict(params) {
	use constant NAMES => ['url', 'uri'];

	our $VERSION = '0.03';

	method glSuffix() { return '=s' }

	method label() { return 'URL' }

	method check($value) {
		return undef if $value =~ m{\A[a-zA-Z][a-zA-Z0-9.+-]*://\S+\z};    # scheme://...
		return sprintf("'%s' is not a URL", $value);
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Type::Url - URL type

=head1 DESCRIPTION

URL of the form C<scheme://...>.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
