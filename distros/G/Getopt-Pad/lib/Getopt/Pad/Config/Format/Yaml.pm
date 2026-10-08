use v5.26;
use Object::Pad;

use Getopt::Pad::Config::Format;

class Getopt::Pad::Config::Format::Yaml :isa(Getopt::Pad::Config::Format) :strict(params) {
	use Encode ();
	use Feature::Compat::Try;
	use Getopt::Pad::Util qw(specError);

	our $VERSION = '0.06';

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
		my @documents = YAML::XS::Load(Encode::encode('UTF-8', $text));

		# A file without a document, empty or holding only comments, sets
		# nothing. Of several documents the last one counts.
		return @documents ? $documents[-1] : {};
	}

	method dump($data) {
		return Encode::decode('UTF-8', YAML::XS::Dump($data));
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Config::Format::Yaml - The yaml config file format

=head1 SYNOPSIS

=for highlighter language=perl

    config => { format => 'yaml', paths => ['~/.tool.yaml'] },

=for highlighter language=yaml

    Options:
      log-level: debug
      tag:
        - a
        - b
    commands:
      resize:
        Options:
          width: 800

=head1 DESCRIPTION

The config file format C<yaml> (also C<yml>), based on L<YAML::XS>.

YAML::XS is not installed together with Getopt::Pad. A spec whose
C<config> block uses this format makes C<GetOptions> die with the spec
error C<config format 'yaml' requires the YAML::XS module> when YAML::XS is
missing, whether or not a config file exists.

C<true> and C<false> are accepted for C<flag> and C<bool> options; C<yes>,
C<no>, C<on> and C<off> are read as strings and rejected. C<~> and empty
values are reported as C<no value given> (for C<hash> and C<objectlist>
options as a value of the wrong shape). An empty file, or one with only
comments, sets nothing. Of a file with several documents, the last one
is used. Tags
such as C<!!perl/hash:Foo> never create objects: a config file is data.

C<--create-default-config> writes a YAML document that starts with
C<--->.

See L<Getopt::Pad/CONFIG FILES> for the layout of config files.

=head1 SEE ALSO

L<Getopt::Pad::Config::Format>, L<Getopt::Pad::Config::Format::Json>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
