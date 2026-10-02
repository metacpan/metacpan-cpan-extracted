package Langertha::Tool;
# ABSTRACT: Immutable canonical tool definition with cross-provider format conversion
our $VERSION = '0.503';
use Moose;
use Carp qw( croak carp );
use JSON::MaybeXS;
use Scalar::Util qw( blessed );

has name => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has description => (
  is      => 'ro',
  isa     => 'Str',
  default => '',
);

has input_schema => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { { type => 'object', properties => {} } },
);

sub _empty_schema { { type => 'object', properties => {} } }

# --- Constructors from wire-format hashes ---

sub from_openai {
  my ($class, $hash) = @_;
  return undef unless ref($hash) eq 'HASH';
  return undef unless ($hash->{type} // '') eq 'function';
  # Chat Completions nests the function fields under `function`; the
  # Responses API's flat form puts name/description/parameters directly on
  # the tool hash (k217). Normalize both here (ADR 0018 tier 1: the
  # value-object inbound door), so the nested shape still wins whenever it
  # is actually present.
  my $fn = ref( $hash->{function} ) eq 'HASH' ? $hash->{function} : $hash;
  my $name = $fn->{name} // '';
  return undef unless length $name;
  return $class->new(
    name         => $name,
    description  => ( $fn->{description} // '' ),
    input_schema => ( $fn->{parameters} || $class->_empty_schema ),
  );
}

sub from_anthropic {
  my ($class, $hash) = @_;
  return undef unless ref($hash) eq 'HASH';
  my $name = $hash->{name} // '';
  return undef unless length $name;
  return $class->new(
    name         => $name,
    description  => ( $hash->{description} // '' ),
    input_schema => ( $hash->{input_schema} || $hash->{parameters} || $class->_empty_schema ),
  );
}

# MCP server tool definition: name + description + inputSchema (camelCase).
sub from_mcp {
  my ($class, $hash) = @_;
  return undef unless ref($hash) eq 'HASH';
  my $name = $hash->{name} // '';
  return undef unless length $name;
  return $class->new(
    name         => $name,
    description  => ( $hash->{description} // '' ),
    input_schema => ( $hash->{inputSchema} || $hash->{input_schema} || $class->_empty_schema ),
  );
}

# Gemini functionDeclarations: name + description + parameters (flat), or
# the JSON-Schema parametersJsonSchema (both spellings, ADR 0018).
sub from_gemini {
  my ($class, $hash) = @_;
  return undef unless ref($hash) eq 'HASH';
  my $name = $hash->{name} // '';
  return undef unless length $name;
  return $class->new(
    name         => $name,
    description  => ( $hash->{description} // '' ),
    input_schema => ( $hash->{parameters} || $hash->{parametersJsonSchema}
      || $hash->{parameters_json_schema} || $class->_empty_schema ),
  );
}

# Generic: figure out the wire shape and route accordingly. Order matters —
# we test the most specific markers first.
sub from_hash {
  my ($class, $hash) = @_;
  return $hash if ref($hash) && eval { $hash->isa(__PACKAGE__) };
  croak "Langertha::Tool: a Langertha::ServerTool is not a function tool; "
    . "format_list and the engine's tools list take it, Langertha::Tool does not"
    if ref($hash) && eval { $hash->isa('Langertha::ServerTool') };
  return undef unless ref($hash) eq 'HASH';
  $class->_croak_unless_function_tool($hash);
  return $class->from_openai($hash)    if ( $hash->{type} // '' ) eq 'function';
  return $class->from_mcp($hash)       if ref( $hash->{inputSchema} )  eq 'HASH';
  return $class->from_anthropic($hash) if ref( $hash->{input_schema} ) eq 'HASH';
  return $class->from_gemini($hash)
    if grep { ref( $hash->{$_} ) eq 'HASH' } qw( parameters parametersJsonSchema parameters_json_schema );
  # Last resort: name-only / schemaless
  return $class->from_anthropic($hash);
}

# Only function tools pass this door; since k210 (ADR 0001) everything else
# croaks instead of being dropped or turned into a function tool. The decision
# is classify()'s -- the one source of truth, also used by
# Role::ResponsesCompatible and by sibling callers that must not croak.
sub _croak_unless_function_tool {
  my ($class, $hash) = @_;
  my ( $category, $wire, $label ) = $class->classify($hash);
  return if $category eq 'function';
  my $tail = '(refusing to drop it or send it as a function tool)';
  croak "Langertha::Tool: '$label' is a server-side tool ($wire), not a function "
    . "tool $tail; "
    . ( $wire eq 'responses'
      ? "pass it in the tools list of an engine that supports('server_tools'), "
        . "or wrap it in Langertha::ServerTool"
      : "Langertha::ServerTool does not support the $wire wire yet" )
    if $category eq 'server';
  croak "Langertha::Tool: '$label' is a client-executed built-in tool ($wire), "
    . "not a server tool, and Langertha cannot run it $tail"
    if $category eq 'client_builtin';
  croak "Langertha::Tool: unsupported tool type '$label': not a function tool $tail"
    if length( $hash->{type} // '' );
  croak "Langertha::Tool: tool hash has no type and no name (keys: $label): "
    . "not a function tool $tail";
}

# Built-in tools, recognised explicitly per wire (spec k206 section 3.4,
# llm-advisor against the provider references, 2026-09-25). Typed wires match
# on `type` (plus `execution` / `environment` where that decides who runs it);
# Gemini's built-ins are keyed, not typed ({ google_search => {} }), in both
# snake and camel case (ADR 0018). Documentation-derived, not capture-verified.
my %RESPONSES_SERVER_TYPE = map { $_ => 1 } qw(
  web_search file_search code_interpreter image_generation mcp
  x_search collections_search
);
my %RESPONSES_CLIENT_TYPE = map { $_ => 1 } qw(
  local_shell computer computer_use_preview apply_patch
);
my @GEMINI_SERVER_KEY = qw(
  google_search googleSearch google_search_retrieval googleSearchRetrieval
  code_execution codeExecution url_context urlContext google_maps googleMaps
  enterprise_web_search enterpriseWebSearch file_search fileSearch retrieval
);
my @GEMINI_CLIENT_KEY = qw( computer_use computerUse );

# The inbound mirror of %RESPONSES_CLIENT_TYPE: Responses output[] items the
# CLIENT must answer and Langertha does not map into Response.tool_calls
# (llm-advisor must-change 1 on k206, OpenAI create-response reference). A
# known one croaks rather than being skipped -- skipped, a tool loop ends as if
# the model were done and a chat_f caller never learns it is waiting. A
# tool_search_call is client-actionable only with execution => 'client'.
# Unknown item types stay skipped (values open); ADR 0030.
my %RESPONSES_CLIENT_ITEM = (
  custom_tool_call     => 'a custom tool call',
  computer_call        => 'a computer-use action',
  local_shell_call     => 'a local shell command',
  apply_patch_call     => 'a patch to apply',
  mcp_approval_request => "an MCP approval request; send the mcp tool with require_approval => 'never'",
  tool_search_call     => 'a client-side tool search',
);

sub _croak_on_client_item {
  my ( $class, $item ) = @_;
  return unless ref $item eq 'HASH';
  my $type = $item->{type} // '';
  my $what = $RESPONSES_CLIENT_ITEM{$type} or return;
  return if $type eq 'tool_search_call' && ( $item->{execution} // '' ) ne 'client';
  croak "Langertha: the reply contains a '$type' output item ($what) that the "
    . "client must answer, and Langertha cannot; refusing to end the turn as if the "
    . "model were done";
}

# ($category, $wire) for a recognised built-in, else ().
sub _builtin_kind {
  my ($hash) = @_;
  my $type = $hash->{type} // '';
  if ( length $type ) {
    if ( $type eq 'tool_search' ) {
      return ( ( $hash->{execution} // '' ) eq 'client' ? 'client_builtin' : 'server', 'responses' );
    }
    if ( $type eq 'shell' ) {
      # Hosted only in one of the two container environments; a bare, local
      # or unrecognised environment runs on the client (spec k206 3.4, Q3).
      my $env = ref $hash->{environment} eq 'HASH' ? ( $hash->{environment}{type} // '' ) : '';
      return ( ( $env eq 'container_auto' || $env eq 'container_reference' )
        ? 'server' : 'client_builtin', 'responses' );
    }
    return ( server => 'responses' )
      if $RESPONSES_SERVER_TYPE{$type}
      || $type =~ /\Aweb_search_(?:preview|\d{4}_\d{2}_\d{2}\z)/;
    return ( client_builtin => 'responses' ) if $RESPONSES_CLIENT_TYPE{$type};
    return ( server => 'anthropic' )
      if $type eq 'mcp_toolset'
      || $type =~ /\A(?:web_search|web_fetch|code_execution|tool_search_tool_\w+?)_\d{8}\z/;
    return ( client_builtin => 'anthropic' )
      if $type =~ /\A(?:bash|text_editor|computer|memory)_\d{8}\z/;
    return ();
  }
  for my $key (@GEMINI_SERVER_KEY) { return ( server => 'gemini' ) if exists $hash->{$key} }
  for my $key (@GEMINI_CLIENT_KEY) { return ( client_builtin => 'gemini' ) if exists $hash->{$key} }
  return ();
}


my %KNOWN_FMT = map { $_ => 1 } qw( openai anthropic gemini ollama responses mcp hermes );
my %CARPED_FMT;

sub classify {
  my ( $class, $hash, $fmt ) = @_;
  if ( defined $fmt && !$KNOWN_FMT{$fmt} && !$CARPED_FMT{$fmt}++ ) {
    carp "Langertha::Tool->classify: unknown tool_wire_format '$fmt'; "
      . "every built-in counts as foreign for it";
  }
  my @none = ( undef, undef );
  if ( ref($hash) && eval { $hash->isa(__PACKAGE__) } ) {
    return wantarray ? ( 'function', @none ) : 'function';
  }
  unless ( ref($hash) eq 'HASH' ) {
    return wantarray ? ( 'unknown', undef, ref($hash) || 'non-reference' ) : 'unknown';
  }
  my $type = $hash->{type} // '';
  my ( $category, $wire ) = _builtin_kind($hash);
  my $label = length $type ? $type
    : $category ? ( grep { exists $hash->{$_} } @GEMINI_SERVER_KEY, @GEMINI_CLIENT_KEY )[0]
    : undef;
  if ($category) {
    $category = 'foreign' if defined $fmt && $wire ne $fmt;
  }
  elsif ( $type eq 'function'
    || ( $type eq 'custom' && ref( $hash->{input_schema} ) eq 'HASH' )
    || ( $type eq '' && !ref( $hash->{name} ) && length( $hash->{name} // '' ) ) ) {
    $category = 'function';
    $label    = undef;
  }
  else {
    $category = 'unknown';
    $label  //= join( ',', sort keys %$hash ) || '(empty)';
  }
  return wantarray ? ( $category, $wire, $label ) : $category;
}

# Build from a list of any-shape tool definitions. A plain hash that is not a
# function tool croaks in from_hash (k210). Anything that is not a plain HASH
# and not a Langertha::Tool -- a string, an array ref, a blessed non-Tool
# object even if it is hash-based -- is still skipped silently.
sub from_list {
  my ($class, $list) = @_;
  return [] unless ref($list) eq 'ARRAY';
  my @out;
  for my $item (@$list) {
    my $tool = $class->from_hash($item);
    push @out, $tool if $tool;
  }
  return \@out;
}

# --- Serializers to wire-format hashes ---

sub to_openai {
  my ($self) = @_;
  return {
    type     => 'function',
    function => {
      name        => $self->name,
      description => $self->description,
      parameters  => $self->input_schema,
    },
  };
}

sub to_anthropic {
  my ($self) = @_;
  my $schema = $self->input_schema;
  return {
    name         => $self->name,
    description  => $self->description,
    input_schema => $schema,
    # Strict tool use (GA, no beta header): guarantees tool_use.input validates
    # exactly against input_schema. Anthropic requires a closed schema for it —
    # additionalProperties:false plus a non-empty required list — so we only
    # emit strict:true where the schema author opted into that shape, and stay
    # silent (and lenient) otherwise. Emitting strict on an open schema 400s.
    ( _schema_is_strict($schema) ? ( strict => JSON->true ) : () ),
  };
}

# True when input_schema is closed enough for Anthropic strict tool use:
# additionalProperties explicitly false and a non-empty required array.
sub _schema_is_strict {
  my ($schema) = @_;
  return 0 unless ref($schema) eq 'HASH';
  return 0 unless exists $schema->{additionalProperties};
  return 0 if $schema->{additionalProperties};   # true / truthy -> open schema
  return 0 unless ref($schema->{required}) eq 'ARRAY' && @{$schema->{required}};
  return 1;
}

sub to_ollama { $_[0]->to_openai }

# Gemini: the schema goes out as parametersJsonSchema (v1beta), which takes JSON
# Schema as-is -- `parameters` is an OpenAPI-subset proto that 400s on MCP's
# additionalProperties, $ref/$defs, const. The two are mutually exclusive, so
# `parameters` is never sent; no sanitizer. Only a top-level $schema is dropped,
# and a tool without arguments declares no schema at all (karr k330, ADR 0001).
my %NO_ARG_KEY = map { $_ => 1 } qw( type properties required additionalProperties );

sub _gemini_schema {
  my ($self) = @_;
  my $schema = $self->input_schema;
  return undef unless ref $schema eq 'HASH';
  my %schema = %$schema;
  delete $schema{'$schema'};
  my $props = $schema{properties};
  my $no_args = !( ref $props eq 'HASH' && %$props )
    && !grep { !$NO_ARG_KEY{$_} } keys %schema;
  return $no_args ? undef : \%schema;
}

sub to_gemini {
  my ($self) = @_;
  my $schema = $self->_gemini_schema;
  return {
    name        => $self->name,
    description => $self->description,
    ( $schema ? ( parametersJsonSchema => $schema ) : () ),
  };
}

# OpenAI Responses API: flat tool objects, no {type:'function',function:{...}} wrapper
sub to_responses {
  my ($self) = @_;
  return {
    type        => 'function',
    name        => $self->name,
    description => $self->description,
    parameters  => $self->input_schema,
  };
}

sub to_mcp {
  my ($self) = @_;
  return {
    name        => $self->name,
    description => $self->description,
    inputSchema => $self->input_schema,
  };
}

# Shape used inside OpenAI's response_format => { type=>'json_schema',
# json_schema => { ... } } — and the basis of the chat_f forced-tool
# fallback path.
sub to_json_schema {
  my ($self) = @_;
  return {
    name        => $self->name,
    description => $self->description,
    schema      => $self->input_schema,
  };
}

# Canonical hash (matches the legacy Input::Tools->normalize_tools shape).
sub to_hash {
  my ($self) = @_;
  return {
    name         => $self->name,
    description  => $self->description,
    input_schema => $self->input_schema,
  };
}

# Make the object transparent to any JSON encoder configured with
# convert_blessed => 1 (the house default, see Langertha::Plugin::Langfuse).
# to_hash is the complete canonical representation, so this is a plain
# delegator — nothing is dropped.
sub TO_JSON { shift->to_hash }

# --- Tag-driven dispatch ---

# Maps a tool_wire_format tag to the per-tool serializer method.
my %TO_METHOD = (
  openai    => 'to_openai',
  anthropic => 'to_anthropic',
  gemini    => 'to_gemini',
  ollama    => 'to_ollama',
  responses => 'to_responses',
  mcp       => 'to_mcp',
  hermes    => 'to_mcp',     # Hermes injects raw MCP defs into the prompt as JSON
);

# Serialize this single tool to the given wire format.
sub to {
  my ($self, $fmt) = @_;
  my $method = $TO_METHOD{ $fmt // '' }
    or croak "Langertha::Tool: unknown wire format '" . ( $fmt // '' ) . "'";
  return $self->$method;
}

# Class method: turn a list of any-shape (usually MCP) tool hashrefs into the
# full wire `tools` payload for the given format. Handles collection-level
# shaping (Gemini wraps its declarations) that a per-tool serializer cannot.
#
# A server-side tool (a Langertha::ServerTool, or a hash ServerTool->from_hash
# recognises for $fmt) keeps its place in the list and goes out as its native
# hash; ServerTool->to croaks when its wire is not $fmt (k206, ADR 0030).
# Everything else goes through from_list, so a server tool of another wire, a
# client-executed built-in or an unknown type still croaks at the Tool door.
sub format_list {
  my ($class, $fmt, $tools) = @_;
  $fmt //= '';
  require Langertha::ServerTool;
  my @items = map {
    my $st = Langertha::ServerTool->from_hash( $fmt, $_ );
    $st ? $st : @{ $class->from_list([$_]) };
  } ( ref($tools) eq 'ARRAY' ? @$tools : () );
  if ( $fmt eq 'gemini' ) {
    return [ { functionDeclarations => [ map { $_->to('gemini') } @items ] } ];
  }
  return [ map { $_->to($fmt) } @items ];
}

# --- A caller's request tools list (k227, ADR 0001) ---
#
# chat_f and chat_stream_realtime_f take a tools list the caller built by
# hand: Tool objects, ServerTool objects and hashes of any shape, often mixed.
# Unlike format_list (whose callers only ever emit function tools), this keeps
# everything the caller meant and decides per item, in place:
#   - a Tool or ServerTool object goes through its own to($fmt);
#   - a function-tool hash already in $fmt's own shape goes out verbatim, so
#     the extras the value object does not model survive (function.strict,
#     cache_control, Gemini's declaration fields);
#   - a function-tool hash in another shape (MCP inputSchema, canonical
#     input_schema, the other dialect's shape) is converted, carrying over
#     the extras $fmt takes (%CARRY);
#   - anything else -- a built-in, a typed item Langertha does not know, a
#     Gemini { functionDeclarations => [...] } -- goes out verbatim: the
#     provider judges it, as the Responses envelope does for typed items
#     (k210). Nothing is dropped and nothing becomes a function tool.
# Gemini keeps all function declarations in ONE functionDeclarations entry
# (k221 review M4), placed where the first declaration came from; a later
# raw functionDeclarations (or function_declarations) entry gives up its
# declarations to it and keeps its other fields.

# True when a function-tool hash is already in $fmt's own tools-list shape.
sub _is_wire_function {
  my ( $hash, $fmt ) = @_;
  my $type = $hash->{type} // '';
  return $type eq 'function' && ref $hash->{function} eq 'HASH'
    if $fmt eq 'openai' || $fmt eq 'ollama';
  return ( $type eq '' || $type eq 'custom' )
    && ref $hash->{input_schema} eq 'HASH' && !exists $hash->{inputSchema}
    if $fmt eq 'anthropic';
  # A Gemini declaration (name + parameters, and fields such as behavior).
  return $type eq '' && !exists $hash->{inputSchema} && !exists $hash->{input_schema}
    if $fmt eq 'gemini';
  return 0;
}

# The extras a converted hash keeps, per target wire. strict may sit on the
# hash or in OpenAI's nested function; an explicit value beats the schema
# guess of to_anthropic.
sub _carry_extras {
  my ( $hash, $out, $fmt ) = @_;
  my $fn = ref $hash->{function} eq 'HASH' ? $hash->{function} : {};
  my $strict = exists $hash->{strict} ? $hash->{strict} : $fn->{strict};
  if ( $fmt eq 'openai' ) {
    $out->{function}{strict} = $strict if defined $strict;
  }
  elsif ( $fmt eq 'anthropic' ) {
    $out->{strict} = $strict if defined $strict;
    $out->{cache_control} = $hash->{cache_control} if exists $hash->{cache_control};
  }
  return $out;
}

# One item on $fmt; for gemini, a function tool comes back as a declaration.
sub _request_item {
  my ( $class, $item, $fmt ) = @_;
  return $item->to($fmt)
    if blessed($item) && ( $item->isa(__PACKAGE__) || $item->isa('Langertha::ServerTool') );
  return $item unless _is_function_hash($item);
  return $item if _is_wire_function( $item, $fmt );
  return _carry_extras( $item, $class->from_hash($item)->to($fmt), $fmt );
}

sub _is_function_hash {
  my ($item) = @_;
  return ref $item eq 'HASH' && scalar __PACKAGE__->classify($item) eq 'function';
}

# The key a raw Gemini tool entry keeps its declarations under; the REST API
# reads both spellings (ADR 0018), the merged entry is written in camelCase.
sub _declarations_key {
  my ($item) = @_;
  return undef unless ref $item eq 'HASH';
  for my $key (qw( functionDeclarations function_declarations )) {
    return $key if ref $item->{$key} eq 'ARRAY';
  }
  return undef;
}

sub request_list {
  my ( $class, $fmt, $tools ) = @_;
  return $tools unless ref $tools eq 'ARRAY';
  return [ map { $class->_request_item( $_, $fmt ) } @$tools ] unless $fmt eq 'gemini';
  my ( @out, @decls, $group );
  for my $item (@$tools) {
    if ( ( blessed($item) && $item->isa(__PACKAGE__) ) || _is_function_hash($item) ) {
      push @decls, $class->_request_item( $item, $fmt );
      push @out, $group = {} unless $group;
    }
    elsif ( my $key = _declarations_key($item) ) {
      push @decls, @{ $item->{$key} };
      my %rest = %$item;
      delete $rest{$key};
      push @out, \%rest if !$group || %rest;
      $group //= \%rest;
    }
    else {
      push @out, $class->_request_item( $item, $fmt );
    }
  }
  $group->{functionDeclarations} = \@decls if $group;
  return \@out;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Tool - Immutable canonical tool definition with cross-provider format conversion

=head1 VERSION

version 0.503

=head2 classify

  my $category = Langertha::Tool->classify( $tool_hash );
  my $category = Langertha::Tool->classify( $tool_hash, 'responses' );
  my ( $category, $wire, $label ) = Langertha::Tool->classify( $tool_hash );

Says what kind of tool definition C<$tool_hash> is, without croaking. Use it
where a tool list comes from someone else, such as a gateway that must answer
a bad client request with a 400 instead of dying: C<from_hash>,
C<from_list> and C<format_list> croak on every category except
C<function>, and they take that decision from this method.

The category is one of:

=over 4

=item C<function>

A function tool C<from_hash> translates: a C<Langertha::Tool>, a hash
without C<type> that has a C<name> (canonical, MCP, Gemini declaration,
Anthropic client tool), C<< type => 'function' >> (OpenAI, nested or flat),
or C<< type => 'custom' >> with an C<input_schema> (Anthropic's explicit
client tool).

=item C<server>

A known provider built-in that the provider runs, for example
C<web_search> (Responses), C<web_search_20250305> (Anthropic) or
C<< { google_search => {} } >> (Gemini). Server-side tools of the
C<responses> wire are carried by L<Langertha::ServerTool>; those of the
Anthropic and Gemini wires are not supported yet.

=item C<client_builtin>

A known provider built-in that the I<client> has to run and Langertha
cannot, for example C<local_shell>, C<computer_use_preview>, C<apply_patch>,
a C<shell> with a local environment, a C<tool_search> with
C<< execution => 'client' >> (Responses), C<bash_20250124> (Anthropic) or
C<computer_use> (Gemini).

=item C<foreign>

Only with C<$fmt>: a C<server> or C<client_builtin> tool whose own wire is
not C<$fmt> -- that is, for any C<$fmt> other than the built-in's own wire
(C<responses>, C<anthropic> or C<gemini>), including C<openai>, C<ollama> or
C<hermes>, which have no built-ins of their own. A C<$fmt> outside the known
C<tool_wire_format> values carps once per value. C<foreign> hides whether
the tool is server-side or client-executed; to learn that, call
C<classify> again without C<$fmt>.

=item C<unknown>

Anything else: a C<type> Langertha does not recognise (including OpenAI's
C<custom> without C<input_schema> and C<namespace>), a hash with neither
C<type> nor C<name> (such as C<< { functionDeclarations => [...] } >>), or
not a hash at all. A wire that takes native items verbatim (the Responses
envelope) passes a typed C<unknown> through to the provider.

=back

C<$fmt> is a C<tool_wire_format> (C<responses>, C<anthropic>, C<gemini>, ...).
In list context the method also returns the wire the built-in belongs to
(C<undef> for C<function> and C<unknown>) and a label: the C<type>, the
Gemini key, or, for an untyped C<unknown>, its keys. The per-wire lists are
taken from the provider documentation and are not verified against live
responses.

=head2 request_list

    my $wire_tools = Langertha::Tool->request_list( $engine->tool_wire_format, \@tools );

Shapes a caller's C<tools> list for one request on the wire C<$fmt>
(C<openai>, C<anthropic>, C<gemini> or C<ollama>); the Responses envelope
and the C<hermes> wire shape their own. L<Langertha::Role::Chat/chat_f> and
L<Langertha::Role::Chat/chat_stream_realtime_f> call it. Each item is decided
on its own and keeps its place:

=over 4

=item * a C<Langertha::Tool> or L<Langertha::ServerTool> goes through its
C<to($fmt)> (a server tool croaks off its own wire);

=item * a function-tool hash already in the wire's shape goes out verbatim,
extras such as C<function.strict> and C<cache_control> included;

=item * a function-tool hash in another shape (MCP C<inputSchema>, canonical
C<input_schema>, another dialect's shape) is converted through L</from_hash>,
keeping C<strict> (OpenAI and Anthropic) and C<cache_control> (Anthropic);

=item * anything else -- a provider built-in, a typed item Langertha does not
know, a Gemini C<< { functionDeclarations => [...] } >> entry -- goes out
verbatim, for the provider to judge.

=back

On C<gemini> every function declaration ends up in one
C<functionDeclarations> entry, where the first declaration came from; a later
raw C<functionDeclarations> or C<function_declarations> entry is merged into it
and keeps its other fields. The merged entry is spelled C<functionDeclarations>.

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
