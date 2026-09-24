use v5.26;
use Object::Pad;

use Getopt::Pad::Config;
use Getopt::Pad::Config::Format;

class Getopt::Pad::Spec::Config :strict(params) {
	use Getopt::Pad::Util qw(specError);

	our $VERSION = '0.02';

	field $raw :param;

	field $format;
	field $formatName  :reader;
	field $paths;
	field $defaultPath :reader;
	field $autoload = 1;
	field $io          :reader;

	ADJUST {
		specError("config: expects a hash reference") if ref $raw ne 'HASH';
		my %spec = $raw->%*;

		$formatName = delete $spec{format};
		specError("config: missing 'format'") if !defined $formatName;
		$format = Getopt::Pad::Config::Format::registry()->resolve($formatName)->new;

		$paths = delete $spec{paths} // [];
		specError("config: 'paths' must be an array reference") if ref $paths ne 'ARRAY';

		$defaultPath = delete $spec{defaultPath};
		$autoload    = (delete $spec{autoload} ? 1 : 0) if exists $spec{autoload};

		specError("config: unknown key(s): %s", join(', ', sort keys %spec)) if %spec;

		$io = Getopt::Pad::Config->new(
			format      => $format,
			formatName  => $formatName,
			paths       => $paths,
			defaultPath => $defaultPath,
			autoload    => $autoload,
		);
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Spec::Config - validated config block

=head1 DESCRIPTION

The validated config block: resolved Format instance, paths, defaultPath and autoload. Pure declaration data - all config file reading and writing lives in the L<Getopt::Pad::Config> worker it hands out via its io reader; only formatName and defaultPath are exposed on top, for the auto option help texts.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
