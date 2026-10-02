package Langertha::Skeid::Protocol;
our $VERSION = '0.003';
# ABSTRACT: Shared helpers for Skeid wire-format translation
use strict;
use warnings;
use POSIX qw(strftime);
use JSON::MaybeXS qw(encode_json decode_json);
use MIME::Base64 qw(decode_base64);

# Nested JSON (a document carried as a string inside another) must be characters: the body
# around it is byte-encoded once when it is sent (skeid #33, core k252).
my $TEXT_JSON = JSON::MaybeXS->new(utf8 => 0, canonical => 1);


sub iso8601_now {
  return strftime('%Y-%m-%dT%H:%M:%SZ', gmtime());
}


sub encode_json_safe {
  my ($value) = @_;
  return '{}' unless defined $value;
  return eval { encode_json($value) } || '{}';
}


sub encode_json_text_safe {
  my ($value) = @_;
  return '{}' unless defined $value;
  return eval { $TEXT_JSON->encode($value) } || '{}';
}


sub utf8_length {
  my ($text) = @_;
  return 0 unless defined $text;
  utf8::encode(my $octets = $text);
  return length $octets;
}


sub decode_json_safe {
  my ($value) = @_;
  return $value if ref($value);
  return undef unless defined $value && length $value;
  my $decoded = eval { decode_json($value) };
  return $@ ? undef : $decoded;
}


sub image_media_type {
  my ($base64) = @_;
  return 'image/png' unless defined($base64) && !ref($base64);
  (my $head = substr($base64, 0, 64)) =~ s/\s+//g;
  my $bytes = decode_base64(substr($head, 0, 16));
  return 'image/png'  if $bytes =~ /\A\x89PNG\r\n\x1a\n/;
  return 'image/jpeg' if $bytes =~ /\A\xFF\xD8\xFF/;
  return 'image/gif'  if $bytes =~ /\AGIF8[79]a/;
  return 'image/webp' if $bytes =~ /\ARIFF.{4}WEBP/s;
  return 'image/png';
}


sub image_url_part {
  my ($url, $base64, $media_type) = @_;
  unless (defined($url) && length($url)) {
    $base64 //= '';
    $media_type = image_media_type($base64) unless defined($media_type) && length($media_type);
    $url = "data:$media_type;base64,$base64";
  }
  return { type => 'image_url', image_url => { url => "$url" } };
}


sub openai_manifest_endpoint {
  return {
    dialect      => 'openai-chat',
    path         => '/v1',
    capabilities => [qw(
      chat streaming system_prompt
      tools_native tools_hermes
      tool_choice_auto tool_choice_any tool_choice_none tool_choice_named
      parallel_tool_use
      response_format_json_object response_format_json_schema
      reasoning_effort temperature seed response_size prompt_cache_key
      image_input
    )],
  };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::Protocol - Shared helpers for Skeid wire-format translation

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Skeid speaks several client dialects but makes exactly one kind of upstream call: an
OpenAI-shaped C<POST> to the selected node. Every other API format is translated in on the way
up and out on the way back, by a module under this namespace — one per format.

That is the whole rule, and it is load-bearing: a format-specific field name belongs inside its
own translator and nowhere else. Routing, admission, usage accounting and the upstream request
builder never learn that Anthropic calls it C<system> or that Ollama calls it
C<prompt_eval_count>. See F<docs/adr/0001-one-upstream-call-shape-all-client-formats-translated.md>.

This module itself holds only the handful of helpers the translators share. They are plain
functions, called fully qualified (C<Langertha::Skeid::Protocol::utf8_length($text)>) and not
exported; only L</openai_manifest_endpoint> is a class method.

=head2 iso8601_now

  my $now = Langertha::Skeid::Protocol::iso8601_now();   # '2026-09-29T16:54:00Z'

Current UTC time as C<YYYY-MM-DDTHH:MM:SSZ>.

=head2 encode_json_safe

  my $line = Langertha::Skeid::Protocol::encode_json_safe($payload) . "\n";

JSON-encodes a value to UTF-8 B<bytes>, returning C<'{}'> rather than dying on anything
unencodable. For a whole wire unit that goes out as-is -- one SSE event or NDJSON line. Never
for a string nested inside another JSON document: use L</encode_json_text_safe>.

=head2 encode_json_text_safe

  my $arguments = Langertha::Skeid::Protocol::encode_json_text_safe($block->{input});

JSON-encodes a value to a B<character> string, returning C<'{}'> rather than dying. For JSON
nested as a string inside a body that is encoded as a whole later -- C<tool_use.input> becoming
C<function.arguments>, a structured C<tool_result> becoming a tool message's content. Byte
output there would be encoded a second time and every non-ASCII character would reach the
model as mojibake.
Used where a malformed tool argument must not take the whole request down.

=head2 utf8_length

  my $bytes = Langertha::Skeid::Protocol::utf8_length($text);

Length of a character string in UTF-8 B<bytes> -- what a C<content_bytes> count means.
C<length> on decoded text counts characters and undercounts every non-ASCII answer.

=head2 decode_json_safe

  my $data = Langertha::Skeid::Protocol::decode_json_safe($bytes);   # or undef

Decodes a JSON string of UTF-8 B<bytes> (a raw body or SSE payload), returning C<undef> instead
of dying. Not for text that is already characters, such as C<function.arguments> read from a
decoded body. A reference is passed through unchanged, so it is safe to call on a value that
may already be decoded.

=head2 image_media_type

  my $mt = Langertha::Skeid::Protocol::image_media_type($base64);   # 'image/jpeg'

The media type of a base64-encoded image, read from its magic bytes: PNG, JPEG, GIF and WebP
are recognised, anything else is reported as C<image/png>. For a client format that sends
raw base64 without saying what it is (Ollama's C<images>), so the data URL the OpenAI
upstream needs can name a type.

=head2 image_url_part

  my $part = Langertha::Skeid::Protocol::image_url_part($url);
  my $part = Langertha::Skeid::Protocol::image_url_part(undef, $base64, $media_type);

An OpenAI C<image_url> content part: C<< { type => 'image_url', image_url => { url => ... } } >>.
Given a URL, it is used as is. Given base64 data, it becomes a C<data:> URL with
C<$media_type>, or with L</image_media_type> when none is given.

=head2 openai_manifest_endpoint

  my $spec = Langertha::Skeid::Protocol->openai_manifest_endpoint;
  # { dialect => 'openai-chat', path => '/v1', capabilities => [ ... ] }

How the OpenAI face (C</v1/chat/completions>) appears in the provider manifest (skeid #29).
That face is the upstream call shape itself: its body goes to the node untranslated, apart from
the model name, so it carries every OpenAI-chat request field a model entry may claim.
C<capabilities> is the list of those flags; a model is published on this face with the
capabilities declared for it, cut down to this list. The translated faces carry their own
spec (L<Langertha::Skeid::Protocol::Anthropic/manifest_endpoint>,
L<Langertha::Skeid::Protocol::Ollama/manifest_endpoint>).

=head1 SEE ALSO

=over 4

=item * L<Langertha::Skeid::Protocol::Anthropic>, L<Langertha::Skeid::Protocol::Anthropic::Stream>

=item * L<Langertha::Skeid::Protocol::Ollama>, L<Langertha::Skeid::Protocol::Ollama::Stream>

=item * L<Langertha::Skeid::Proxy> -- the routes that use them

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-skeid/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
