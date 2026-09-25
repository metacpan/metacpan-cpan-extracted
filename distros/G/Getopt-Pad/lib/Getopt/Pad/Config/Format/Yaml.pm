use v5.26;
use Object::Pad;

use Getopt::Pad::Config::Format;

class Getopt::Pad::Config::Format::Yaml :isa(Getopt::Pad::Config::Format) :strict(params) {
	use Encode ();
	use Feature::Compat::Try;
	use Getopt::Pad::Util qw(specError);

	our $VERSION = '0.03';

	use constant NAMES => ['yaml', 'yml'];

	# A missing YAML::XS is an installation problem for the programmer:
	# report it when the spec is built, not when the first file is read.
	ADJUST {
		try { require YAML::XS }
		catch ($error) { specError("config format 'yaml' requires the YAML::XS module") }
	}

	# YAML::XS speaks UTF-8 octets on both sides while the Format seam
	# speaks text, so the translation happens here and nowhere else.
	method parse($text) {
		# A config file is data: a !!perl/... tag never blesses anything,
		# whatever the installed YAML::XS defaults to.
		local $YAML::XS::LoadBlessed = 0;
		return YAML::XS::Load(Encode::encode('UTF-8', $text));
	}

	method dump($data) {
		return Encode::decode('UTF-8', YAML::XS::Dump($data));
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Config::Format::Yaml - YAML config format

=head1 DESCRIPTION

YAML config files via YAML::XS (a recommended, not required, dependency; a spec naming this format fails to build without it). YAML::XS works on UTF-8 octets; this format converts to and from the text Config I/O hands over, so non-ASCII values survive a --create-default-config round trip. Loading never blesses: a C<!!perl/hash:Some::Class> tag yields a plain hash regardless of the YAML::XS version's LoadBlessed default.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
