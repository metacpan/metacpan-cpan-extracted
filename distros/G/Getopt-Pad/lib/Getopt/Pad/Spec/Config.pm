use v5.26;
use Object::Pad;

use Getopt::Pad::Config;
use Getopt::Pad::Config::Format;

class Getopt::Pad::Spec::Config :strict(params) {
	use Getopt::Pad::Util qw(specError);

	our $VERSION = '0.04';

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

Getopt::Pad::Spec::Config - The checked config block of a spec (internal)

=head1 DESCRIPTION

This module is internal to Getopt::Pad. It is not part of the public
API and can change without notice. Programs use L<Getopt::Pad/GetOptions>;
this page is for people working on Getopt::Pad itself.

Checks the C<config> block of a spec: C<format> is mandatory and must be
a registered format name (the format object is created right away, so a
missing YAML::XS is reported as a spec error here), C<paths> must be an
arrayref, and there must be no unknown keys. C<defaultPath> and
C<autoload> are taken as given.

The config block is pure declaration data. Every config file is read and
written by the L<Getopt::Pad::Config> object it hands out through C<io>.

=head1 METHODS

=over 4

=item io

The L<Getopt::Pad::Config> object for this config block.

=item formatName, defaultPath

As given in the spec. The help texts of the automatic C<--config> option
mention them.

=back

=head1 SEE ALSO

L<Getopt::Pad::Config>, L<Getopt::Pad/CONFIG FILES>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
