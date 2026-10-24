package Langertha::Skeid::Protocol::RawBody;
our $VERSION = '0.004';
# ABSTRACT: The client's JSON body as it was sent, with one top-level value replaced
use strict;
use warnings;
use JSON::MaybeXS ();


my $STRING = JSON::MaybeXS->new(utf8 => 1, allow_nonref => 1);


sub with_top_level {
  my ($body, $key, $value) = @_;
  return undef unless defined($body) && defined($key) && defined($value);
  my $spans = _top_level_spans($body) or return undef;
  my @hits = grep { $_->{key} eq $key } @$spans;
  return undef unless @hits;
  my $replacement = $STRING->encode("$value");
  # Back to front, so the offsets of the earlier spans stay valid.
  for my $hit (sort { $b->{start} <=> $a->{start} } @hits) {
    substr($body, $hit->{start}, $hit->{length}, $replacement);
  }
  return $body;
}

# The members of a JSON object: [{ key, start, length }], key decoded, start/length the byte span
# of the value. undef when the text is not one well-formed-enough object. This follows structure
# only -- strings, nesting, separators -- and leaves validating values to the decoder that
# already accepted the body.
sub _top_level_spans {
  my ($json) = @_;
  my @spans;
  pos($json) = 0;
  $json =~ /\G\s*\{/gc or return undef;
  $json =~ /\G\s*/gc;
  unless ($json =~ /\G\}/gc) {
    while (1) {
      $json =~ /\G\s*("(?:[^"\\]|\\.)*")\s*:\s*/gcs or return undef;
      my $key = eval { $STRING->decode($1) };
      return undef unless defined $key;
      my $start = pos($json);
      _skip_value(\$json) or return undef;
      push @spans, { key => $key, start => $start, length => pos($json) - $start };
      $json =~ /\G\s*/gc;
      next if $json =~ /\G,/gc;
      last if $json =~ /\G\}/gc;
      return undef;
    }
  }
  $json =~ /\G\s*\z/gc or return undef;
  return \@spans;
}

# The elements of a JSON array, as their texts. undef when the text is not one array.
sub _elements {
  my ($json) = @_;
  my @elements;
  pos($json) = 0;
  $json =~ /\G\s*\[/gc or return undef;
  $json =~ /\G\s*/gc;
  unless ($json =~ /\G\]/gc) {
    while (1) {
      $json =~ /\G\s*/gc;
      my $start = pos($json);
      _skip_value(\$json) or return undef;
      push @elements, substr($json, $start, pos($json) - $start);
      $json =~ /\G\s*/gc;
      next if $json =~ /\G,/gc;
      last if $json =~ /\G\]/gc;
      return undef;
    }
  }
  $json =~ /\G\s*\z/gc or return undef;
  return \@elements;
}

# The text of one member of an object text -- the last one of that name, as decoders read it.
sub _member {
  my ($json, $key) = @_;
  my $spans = _top_level_spans($json) or return undef;
  my ($hit) = reverse grep { $_->{key} eq $key } @$spans;
  return $hit ? substr($json, $hit->{start}, $hit->{length}) : undef;
}

# Moves pos() of the referenced string past one JSON value.
sub _skip_value {
  my ($ref) = @_;
  return 1 if $$ref =~ /\G"(?:[^"\\]|\\.)*"/gcs;
  if ($$ref =~ /\G[\[\{]/gc) {
    my $depth = 1;
    while ($depth) {
      if    ($$ref =~ /\G[^"\[\]\{\}]+/gc)       { }
      elsif ($$ref =~ /\G"(?:[^"\\]|\\.)*"/gcs)   { }
      elsif ($$ref =~ /\G[\[\{]/gc)              { $depth++ }
      elsif ($$ref =~ /\G[\]\}]/gc)              { $depth-- }
      else                                       { return 0 }
    }
    return 1;
  }
  return $$ref =~ /\G[^\s,\]\}"\[\{]+/gc ? 1 : 0;
}


sub tool_schemas {
  my ($body, @path) = @_;
  return undef unless defined $body;
  my $tools = _member($body, 'tools');
  my $elements = defined($tools) ? _elements($tools) : undef;
  return undef unless $elements;
  my @schemas;
  for my $text (@$elements) {
    for my $key (@path) {
      $text = defined($text) ? _member($text, $key) : undef;
    }
    push @schemas, $text;
  }
  return \@schemas;
}


my $CANONICAL = JSON::MaybeXS->new(utf8 => 1, allow_nonref => 1, canonical => 1);

sub encode_with_schemas {
  my ($body, $texts) = @_;
  return undef unless ref($body) eq 'HASH' && ref($texts) eq 'ARRAY';
  my $tools = $body->{tools};
  return undef unless ref($tools) eq 'ARRAY' && @$tools && @$tools == @$texts;

  my @spelled;
  for my $i (0 .. $#$tools) {
    my $tool = $tools->[$i];
    return undef unless ref($tool) eq 'HASH' && ref($tool->{function}) eq 'HASH';
    my %function = %{ $tool->{function} };
    my @members;
    for my $key (qw(name description)) {
      next unless exists $function{$key};
      push @members, qq("$key":) . $CANONICAL->encode(delete $function{$key});
    }
    if (exists $function{parameters}) {
      my $parameters = delete $function{parameters};
      my $text = $texts->[$i];
      my $same = defined($text) && eval {
        $CANONICAL->encode($CANONICAL->decode($text)) eq $CANONICAL->encode($parameters);
      };
      push @members, '"parameters":' . ($same ? $text : $CANONICAL->encode($parameters));
    }
    push @members, $STRING->encode($_) . ':' . $CANONICAL->encode($function{$_}) for sort keys %function;

    my %rest = %$tool;
    delete $rest{function};
    my $type = delete $rest{type};
    push @spelled, join(',',
      '{"type":' . $CANONICAL->encode($type // 'function'),
      '"function":{' . join(',', @members) . '}',
      map { $STRING->encode($_) . ':' . $CANONICAL->encode($rest{$_}) } sort keys %rest,
    ) . '}';
  }

  my %rest = %$body;
  delete $rest{tools};
  my $encoded = $CANONICAL->encode(\%rest);
  my $tools_member = '"tools":[' . join(',', @spelled) . ']';
  substr($encoded, -1, 1, (%rest ? ',' : '') . $tools_member . '}');
  return $encoded;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::Protocol::RawBody - The client's JSON body as it was sent, with one top-level value replaced

=head1 VERSION

version 0.004

=head1 DESCRIPTION

A request on the OpenAI face goes to a node that speaks the same wire, and the only thing Skeid
has to change in it is C<model> (ADR 0008: the node is asked for the served model). Decoding
the body and encoding it again changes more than that: a Perl hash has no key order, so every
object comes out with its keys sorted.

That is not cosmetic. A chat template renders the tool definitions into the prompt in the order
they arrive, so a re-encoded request is a different prompt -- a different prefix for the node's
prompt cache, and a JSON schema spelled C<properties, required, type> where the client wrote and
the model was trained on C<type, properties, required>. One node answered exactly such a prompt
with gibberish that the client's own bytes did not produce.

So the body is not rebuilt. It goes upstream as the bytes the client sent, and this module
replaces the value of one top-level key in them, touching nothing else: not the order, not the
whitespace, not the escapes.

The Anthropic and Ollama faces cannot do that -- their bodies are translated, so the upstream
body is new. What reaches the prompt verbatim there is still the tool definitions, and those
are carried over: L</tool_schemas> takes each tool's JSON schema out of the client's bytes, and
L</encode_with_schemas> writes it into the translated body as it was, inside a tool definition
spelled in the order the function-calling wire spells it.

=head2 with_top_level

  my $bytes = Langertha::Skeid::Protocol::RawBody::with_top_level($body, model => $served);

Returns C<$body>, a JSON object as bytes, with the value of every top-level C<model> replaced
by the JSON string for C<$served>, or C<undef> when the bytes are not a JSON object this scanner
can follow or carry no such key. The caller then falls back to encoding the decoded body.

B<Every> occurrence is replaced. A body may spell a key twice; parsers disagree on which one
counts, and a node that read the other one would be asked for a model the request was never
routed or authorized for.

=head2 tool_schemas

  my $texts = Langertha::Skeid::Protocol::RawBody::tool_schemas($body, 'input_schema');
  my $texts = Langertha::Skeid::Protocol::RawBody::tool_schemas($body, 'function', 'parameters');

The JSON schema of every entry of the body's top-level C<tools>, as the client spelled it: an
array of texts, one per tool, C<undef> for a tool without one. The path names the member inside
a tool -- C<input_schema> on the Anthropic wire, C<function.parameters> on Ollama's. Returns
C<undef> when the body has no C<tools> array.

=head2 encode_with_schemas

  my $bytes = Langertha::Skeid::Protocol::RawBody::encode_with_schemas($openai_body, $texts);

Encodes a translated chat-completions body with its tool definitions spelled the way the
function-calling wire spells them and models have seen them -- C<type> before C<function>,
C<name> before C<description> before C<parameters> -- and each schema as the text from
L</tool_schemas>, B<if> that text still says what the translated tool carries. A schema the
translation changed, or a tool without a text, is encoded from the data instead.

Returns C<undef> when the body has no tools to spell, or their number does not match the
texts: the caller then sends the body encoded as before.

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
