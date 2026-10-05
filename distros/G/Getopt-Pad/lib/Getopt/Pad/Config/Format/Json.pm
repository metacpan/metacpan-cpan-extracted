use v5.26;
use Object::Pad;

use Getopt::Pad::Config::Format;

class Getopt::Pad::Config::Format::Json :isa(Getopt::Pad::Config::Format) :strict(params) {
	use JSON::PP ();

	our $VERSION = '0.05';

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

Getopt::Pad::Config::Format::Json - The json config file format

=head1 SYNOPSIS

=for highlighter language=perl

    config => { format => 'json', paths => ['~/.tool.json'] },

=for highlighter language=javascript

    {
      "Options": { "log-level": "debug", "tag": ["a", "b"] },
      "commands": { "resize": { "Options": { "width": 800 } } }
    }

=head1 DESCRIPTION

The config file format C<json>, based on L<JSON::PP>, which comes with
Perl. Files are parsed as strict JSON: comments and trailing commas are
errors. C<true> and C<false> are accepted for C<flag> and C<bool>
options. C<null> is reported as C<no value given> (for C<hash> and
C<objectlist> options as a value of the wrong shape). An empty file is a
parse error; a file that sets nothing contains C<{}>.

C<--create-default-config> writes indented JSON with the keys sorted.

See L<Getopt::Pad/CONFIG FILES> for the layout of config files.

=head1 SEE ALSO

L<Getopt::Pad::Config::Format>, L<Getopt::Pad::Config::Format::Yaml>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
