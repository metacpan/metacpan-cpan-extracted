package Langertha::ToolCall;
# ABSTRACT: Immutable canonical tool invocation emitted by an LLM
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );
use Encode qw( encode_utf8 );
use JSON::MaybeXS qw( decode_json );

# Character-string codec for JSON nested inside a JSON body or model text
# (function.arguments, the hermes <tool_call> payload). The transport encodes
# the whole body to UTF-8 once; a byte string here would be encoded twice
# ("Köln" -> "KÃ¶ln"). -- karr k252, ADR 0010
my $TEXT_JSON = JSON::MaybeXS->new( utf8 => 0, canonical => 1 );

has name => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has arguments => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

# Provider-specific call id (may be empty if the upstream didn't supply one).
has id => (
  is      => 'ro',
  isa     => 'Str',
  default => '',
);

# True when this call was synthesized by Langertha (e.g. forced-tool
# rewrite via response_format on engines without native named-tool
# forcing) rather than emitted directly by the model. Useful for
# callers that want to distinguish "the model decided to call this"
# from "we asked it to and parsed the result back into a tool_call".
has synthetic => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


# True when the wire sent arguments (a string or a non-object) that do not
# decode to an object -- a JSON string cut off by max_tokens, for one. The
# arguments are {} then, and the tool loops must not run the call on them
# (karr k324).
has arguments_undecodable => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


# Why the arguments did not decode: the JSON parser's message, or "not a JSON
# object". Set exactly when arguments_undecodable is (karr k345).
has arguments_error => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_arguments_error',
);


# The constructor arguments for one raw arguments value: the decoded object
# ({} when there is none) plus arguments_undecodable when the value does not
# decode to an object. Argument strings reach us as Perl-Unicode (pulled out of
# an already-decoded response tree), so UTF-8-encode before the utf8 JSON
# decoder — same convention as Role::JSON's decode_json_text.
sub _args_kwargs {
  my ($args) = @_;
  return ( arguments => {} ) unless defined $args;
  return ( arguments => $args ) if ref($args) eq 'HASH';
  return _undecodable('not a JSON object') if ref $args;
  return ( arguments => {} ) unless length $args;
  my $decoded = eval { decode_json( encode_utf8($args) ) };
  return ( arguments => $decoded ) if ref($decoded) eq 'HASH';
  my $error = $@;
  return _undecodable('not a JSON object') unless $error;
  $error =~ s/ at \S+ line \d+\.?\n?\z//;
  return _undecodable($error);
}

sub _undecodable {
  my ($error) = @_;
  return ( arguments => {}, arguments_undecodable => 1, arguments_error => $error );
}

# --- Constructors from wire-format hashes ---

sub from_openai {
  my ($class, $hash) = @_;
  return undef unless ref($hash) eq 'HASH';
  my $fn = $hash->{function} || {};
  return undef unless ref($fn) eq 'HASH';
  my $name = $fn->{name} // '';
  return undef unless length $name;
  return $class->new(
    name      => $name,
    _args_kwargs( $fn->{arguments} ),
    id        => ( $hash->{id} // '' ),
  );
}

sub from_anthropic {
  my ($class, $block) = @_;
  return undef unless ref($block) eq 'HASH';
  return undef unless ( $block->{type} // '' ) eq 'tool_use';
  my $name = $block->{name} // '';
  return undef unless length $name;
  # Real Anthropic ships input as an object, but the AKI.IO /anthropic shim
  # ships it as a JSON string (like the OpenAI wire). Route input through the
  # same decoder from_openai uses so a stringified object is decoded rather
  # than silently dropped to {}. -- karr k124
  return $class->new(
    name      => $name,
    _args_kwargs( $block->{input} ),
    id        => ( $block->{id} // '' ),
  );
}

sub from_ollama {
  my ($class, $hash) = @_;
  return undef unless ref($hash) eq 'HASH';
  my $fn = $hash->{function} || {};
  return undef unless ref($fn) eq 'HASH';
  my $name = $fn->{name} // '';
  return undef unless length $name;
  return $class->new(
    name      => $name,
    _args_kwargs( $fn->{arguments} ),
    id        => ( $hash->{id} // '' ),
  );
}

# Gemini: a single functionCall part inside candidates[0].content.parts[]:
#   { "functionCall": { "name": "x", "args": { ... } } }
sub from_gemini {
  my ($class, $part) = @_;
  return undef unless ref($part) eq 'HASH';
  my $fc = $part->{functionCall};
  return undef unless ref($fc) eq 'HASH';
  my $name = $fc->{name} // '';
  return undef unless length $name;
  # Google-native ships args as an object, but Vertex-style proxies / OpenRouter
  # / LM Studio can ship it as a JSON string. Route args through the same decoder
  # the other constructors use so a stringified object is decoded rather than
  # silently dropped to {}. -- karr k131 (symmetric to k124's from_anthropic fix)
  return $class->new(
    name      => $name,
    _args_kwargs( $fc->{args} ),
    id        => ( $fc->{id} // '' ),
  );
}

# OpenAI Responses API: function_call appears either as a top-level output[]
# item or nested inside output[type=message].content[]. Both shapes look like:
#   { "type": "function_call", "call_id": "call_abc", "name": "foo", "arguments": "{...}" }
sub from_responses {
  my ($class, $block) = @_;
  return undef unless ref($block) eq 'HASH';
  # locate('responses') pre-filters output[] items to function_call, and a
  # located call passed to from_fmt may carry no type at all — only reject a
  # block whose type is present AND wrong.
  my $type = $block->{type};
  return undef if defined $type && $type ne 'function_call';
  my $name = $block->{name} // '';
  return undef unless length $name;
  return $class->new(
    name      => $name,
    _args_kwargs( $block->{arguments} ),
    id        => ( $block->{call_id} // '' ),
  );
}

# Maps a tool_wire_format tag to the per-call constructor.
my %FROM_METHOD = (
  openai    => 'from_openai',
  anthropic => 'from_anthropic',
  gemini    => 'from_gemini',
  ollama    => 'from_ollama',
  responses => 'from_responses',
);

# Construct a single ToolCall from one raw wire-format call hash, pinned to a
# format (no shape sniffing). Returns undef if the hash doesn't parse.
sub from_fmt {
  my ($class, $fmt, $hash) = @_;
  my $method = $FROM_METHOD{ $fmt // '' }
    or croak "Langertha::ToolCall: unknown wire format '" . ( $fmt // '' ) . "'";
  return $class->$method($hash);
}

# Locate the raw tool-call structures inside an upstream response for a given
# format, WITHOUT parsing them into objects. Returns an arrayref of raw hashes
# (possibly empty). This is the per-format locator that engines used to carry
# as response_tool_calls.
sub locate {
  my ($class, $fmt, $data) = @_;
  $fmt //= '';
  return [] unless ref($data) eq 'HASH';

  if ( $fmt eq 'openai' ) {
    my $msg = $data->{choices}[0]{message} or return [];
    return $msg->{tool_calls} // [];
  }
  if ( $fmt eq 'ollama' ) {
    my $msg = $data->{message} or return [];
    return $msg->{tool_calls} // [];
  }
  if ( $fmt eq 'anthropic' ) {
    return [ grep { ( $_->{type} // '' ) eq 'tool_use' } @{ $data->{content} // [] } ];
  }
  if ( $fmt eq 'gemini' ) {
    my $candidates = $data->{candidates} || [];
    return [] unless @$candidates;
    my $parts = $candidates->[0]{content}{parts} || [];
    return [ grep { exists $_->{functionCall} } @$parts ];
  }
  if ( $fmt eq 'responses' ) {
    # Server-side call items (web_search_call, mcp_call, ...) are never located:
    # the provider already ran them (ADR 0003 Update k206). A client-actionable
    # item Langertha cannot map croaks instead of being skipped (ADR 0030).
    require Langertha::Tool;
    my @calls;
    for my $item ( @{ $data->{output} // [] } ) {
      next unless ref($item) eq 'HASH';
      Langertha::Tool->_croak_on_client_item($item);
      my $type = $item->{type} // '';
      if ( $type eq 'function_call' ) {
        push @calls, $item;
      }
      elsif ( $type eq 'message' ) {
        push @calls,
          grep { ( $_->{type} // '' ) eq 'function_call' } @{ $item->{content} // [] };
      }
    }
    return \@calls;
  }
  croak "Langertha::ToolCall: unknown wire format '$fmt'";
}


# THE canonical inbound entry point: pull every tool call out of an upstream
# response for a given wire format (locate + from_fmt). Engines pass their
# tool_wire_format. Returns a list of ToolCall objects (possibly empty). The
# per-format response-walking lives only in locate(). Callers with no format
# in scope use extract_sniff() instead.
sub extract {
  my ( $class, $fmt, $data ) = @_;
  croak "Langertha::ToolCall->extract requires (\$fmt, \$data)" if ref $fmt;
  return grep { defined }
    map { $class->from_fmt( $fmt, $_ ) } @{ $class->locate( $fmt, $data ) };
}


# Detect the wire format from the top-level shape of a raw response, WITHOUT
# walking the per-format tool structures (that walking lives only in locate).
# Probe order matches the legacy self-sniffing extract. Returns a
# tool_wire_format tag, or undef if the shape matches nothing known.
my @SNIFF_PROBES = (
  [ openai    => sub { ref( $_[0]->{choices} )    eq 'ARRAY' } ],
  [ ollama    => sub { ref( $_[0]->{message} )    eq 'HASH'  } ],
  [ anthropic => sub { ref( $_[0]->{content} )    eq 'ARRAY' } ],
  [ gemini    => sub { ref( $_[0]->{candidates} ) eq 'ARRAY' } ],
  [ responses => sub { ref( $_[0]->{output} )     eq 'ARRAY' } ],
);

sub sniff_format {
  my ( $class, $data ) = @_;
  return undef unless ref($data) eq 'HASH';
  for my $probe (@SNIFF_PROBES) {
    return $probe->[0] if $probe->[1]->($data);
  }
  return undef;
}

# Format-agnostic inbound for callers that genuinely have no wire format in
# scope (the Langertha::Output::Tools back-compat facade): sniff the shape,
# then delegate to extract. Deliberately NOT named extract() so there is
# exactly one canonical inbound entry point — the format-pinned extract above.
sub extract_sniff {
  my ( $class, $data ) = @_;
  my $fmt = $class->sniff_format($data) or return ();
  return $class->extract( $fmt, $data );
}


# Hermes-style XML embedded in plain text. Returns ($cleaned_text, \@calls).
# The one hermes text lift: Role::Tools delegates here with the engine's
# hermes_call_tag (karr k255). Only a well-formed call (a JSON object with a
# non-empty name) becomes a ToolCall and leaves the text (k163); a block that
# carries no call stays in the text where it was -- what the model wrote is
# not dropped (k253).
sub extract_hermes_from_text {
  my ( $class, $text, %opts ) = @_;
  my $tag = defined $opts{tag} && length $opts{tag} ? $opts{tag} : 'tool_call';
  my $clean = defined($text) ? $text : '';
  my @calls;
  $clean =~ s{(<\Q$tag\E>\s*(.*?)\s*</\Q$tag\E>)}{
    my ( $block, $json ) = ( $1, $2 );
    my $obj = eval { $TEXT_JSON->decode($json) };
    ( ref($obj) eq 'HASH' && defined $obj->{name} && length $obj->{name} )
      ? do {
          # Route arguments through the same decoder the wire constructors use
          # (from_openai & co.): a non-object or a value that does not decode to
          # an object becomes {} with arguments_undecodable / arguments_error
          # set, so the tool loop answers the model an error result it can retry
          # rather than running the tool on {} -- karr k350 (the k345 mechanism).
          push @calls, $class->new(
            name => $obj->{name},
            _args_kwargs( $obj->{arguments} ),
          );
          '';
        }
      : $block;
  }seg;
  $clean =~ s/^\s+|\s+$//g;
  return ( $clean, \@calls );
}


# --- Serializers to wire-format hashes ---

sub to_openai {
  my ($self, %opts) = @_;
  my $id = length( $self->id ) ? $self->id : ( $opts{fallback_id} // 'call_langertha' );
  return {
    id       => $id,
    type     => 'function',
    function => {
      name      => $self->name,
      arguments => $TEXT_JSON->encode( $self->arguments ),
    },
  };
}

sub to_anthropic_block {
  my ($self, %opts) = @_;
  my $id = length( $self->id ) ? $self->id : ( $opts{fallback_id} // 'toolu_langertha' );
  return {
    type  => 'tool_use',
    id    => $id,
    name  => $self->name,
    input => $self->arguments,
  };
}

sub to_ollama {
  my ($self) = @_;
  return {
    function => {
      name      => $self->name,
      arguments => $self->arguments,
    },
    ( length( $self->id ) ? ( id => $self->id ) : () ),
  };
}

sub to_hash {
  my ($self) = @_;
  return {
    id        => $self->id,
    name      => $self->name,
    arguments => $self->arguments,
    synthetic => $self->synthetic ? 1 : 0,
  };
}

# Make the object transparent to any JSON encoder configured with
# convert_blessed => 1 (the house default, see Langertha::Plugin::Langfuse).
# Response.tool_calls is an ArrayRef of these, so consumers hit them without
# ever asking for a ToolCall by name. Plain delegator to to_hash: TO_JSON must
# not become a second, divergent shape.
sub TO_JSON { shift->to_hash }

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::ToolCall - Immutable canonical tool invocation emitted by an LLM

=head1 VERSION

version 0.503

=head2 synthetic

Boolean. True when the tool call was synthesized by Langertha — for
example when L<Langertha::Role::Chat/chat_f> rewrote a forced named
tool into a C<response_format> JSON Schema request and parsed the
output back into a C<ToolCall>. False (the default) for native model
output.

C<to_hash> (and therefore C<TO_JSON>) always carries this flag, so a
serialized trace can tell a synthesized call apart from a native one —
without it a forced-tool fallback would look exactly like a call the
model decided to make.

=head2 arguments_undecodable

Boolean. True when the provider sent arguments that do not decode to a JSON
object (typically a JSON string cut off when the reply hit its token limit);
L</arguments> is then C<{}>. The MCP tool loops do not run such a call: when
the reply ended on its token limit they drop it, otherwise they answer it with
an error result naming L</arguments_error>. Missing or empty arguments are not
undecodable.

=head2 arguments_error

The reason the arguments did not decode, set whenever
L</arguments_undecodable> is true: the JSON parser's message (without its
source location) or C<not a JSON object>.

=head2 locate

    my $raw_calls = Langertha::ToolCall->locate( $fmt, $data );

Returns an ArrayRef of the raw tool-call structures in a decoded response for
the wire C<$fmt>, without parsing them. Only calls the client must execute are
located; a server-side call item (C<web_search_call>, C<mcp_call>, ...) never
is (see L<Langertha::ServerToolCall>). On C<responses> it croaks on an output
item the client must answer that Langertha does not map --
C<custom_tool_call>, C<computer_call>, C<local_shell_call>,
C<apply_patch_call>, C<mcp_approval_request>, a C<tool_search_call> with
C<< execution => 'client' >> -- rather than report no calls. Croaks on an
unknown C<$fmt>.

=head2 extract

    my @calls = Langertha::ToolCall->extract( $fmt, $data );

The canonical inbound door: every tool call the client must execute in a
decoded response, as C<Langertha::ToolCall> objects (possibly none). Built on
L</locate>, so on the C<responses> wire it B<croaks> on a client-actionable
output item Langertha cannot map (C<mcp_approval_request>, C<computer_call>,
C<custom_tool_call>, C<local_shell_call>, C<apply_patch_call>, a client
C<tool_search_call>) instead of returning an empty list that looks like "the
model is done". Croaks when C<$fmt> is a reference.

=head2 extract_sniff

    my @calls = Langertha::ToolCall->extract_sniff( $data );

L</extract> for a caller with no wire format in scope: sniffs the format from
the top-level shape, then extracts. Returns an empty list for an unknown shape.
Croaks like L</extract>, including on a client-actionable C<responses> item.

=head2 extract_hermes_from_text

    my ( $clean, $calls ) = Langertha::ToolCall->extract_hermes_from_text($text);
    my ( $clean, $calls ) = Langertha::ToolCall->extract_hermes_from_text(
        $text, tag => 'function_call' );

Lifts Hermes-style C<< <tool_call>{"name":...,"arguments":{...}}</tool_call> >>
blocks out of model text. Returns the trimmed text without the lifted blocks
and an ArrayRef of C<Langertha::ToolCall>. C<tag> names the call tag (default
C<tool_call>); engines pass their C<hermes_call_tag>. A block that carries no
call (invalid JSON, a non-object, an object without a C<name>) stays in the
text where it was. C<arguments> that are not a JSON object (or a string that
does not decode to one) become C<{}> with L</arguments_undecodable> and
L</arguments_error> set, exactly as the wire constructors flag them.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
