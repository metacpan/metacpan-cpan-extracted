use v5.26;
use Object::Pad;

use Getopt::Pad::Config::Format;

class Getopt::Pad::Config::Format::Json :isa(Getopt::Pad::Config::Format) :strict(params) {
	use JSON::PP ();

	our $VERSION = '0.06';

	use constant NAMES => ['json'];

	# An empty file sets nothing. Values arrive as plain scalars, as YAML
	# gives them: booleans as 1 and 0, so a string option set to true reads
	# 1, not an object; numbers as written, so a large integer is not
	# rounded to a float before a bigint option sees it.
	method parse($text) {
		return {} if $text !~ /\S/;
		return $self->plainScalars(JSON::PP->new->allow_bignum->decode($text));
	}

	method plainScalars($data) {
		return [map { $self->plainScalars($_) } $data->@*] if ref $data eq 'ARRAY';
		return { map { $_ => $self->plainScalars($data->{$_}) } keys $data->%* } if ref $data eq 'HASH';
		return $data ? 1 : 0 if JSON::PP::is_bool($data);
		return "$data" if ref $data;
		return $data;
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
errors. C<true> and C<false> become plain 1 and 0, which C<flag> and
C<bool> options accept and other options read as values (a C<string>
option set to C<true> reads 1). C<null> is reported as C<no value given>
(for C<hash> and C<objectlist> options as a value of the wrong shape).
An empty file, or one with only white space, sets nothing. Numbers
reach the options as written, so a large integer is not rounded to a
float first (see L<Getopt::Pad/bigint>).

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
