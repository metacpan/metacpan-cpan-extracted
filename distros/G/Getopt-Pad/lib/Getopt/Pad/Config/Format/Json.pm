use v5.26;
use Object::Pad;

use Getopt::Pad::Config::Format;

class Getopt::Pad::Config::Format::Json :isa(Getopt::Pad::Config::Format) :strict(params) {
	use JSON::PP ();

	our $VERSION = '0.02';

	use constant NAMES => ['json'];

	method parse($text) {
		return JSON::PP->new->decode($text);
	}

	method dump($data) {
		return JSON::PP->new->pretty->canonical->encode($data);
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Config::Format::Json - JSON config format

=head1 DESCRIPTION

JSON config files via the core JSON::PP module, translating between the text Config I/O hands over and the config data.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
