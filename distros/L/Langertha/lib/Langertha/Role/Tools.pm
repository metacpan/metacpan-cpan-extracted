package Langertha::Role::Tools;
# ABSTRACT: Role for MCP tool calling support
our $VERSION = '0.503';
use Moose::Role;
use Future::AsyncAwait;
use Carp qw( croak );
use JSON::MaybeXS;
use Scalar::Util qw( blessed refaddr );
use Log::Any qw( $log );
use Langertha::Tool;
use Langertha::ToolCall;
use Langertha::ToolResult;

with 'Langertha::Role::ParallelToolUse';


has mcp_servers => (
  is => 'ro',
  isa => 'ArrayRef',
  default => sub { [] },
);


has tool_max_iterations => (
  is => 'ro',
  isa => 'Int',
  default => 10,
);


has tool_wire_format => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_tool_wire_format',
  clearer => '_clear_tool_wire_format',
  trigger => sub { $_[0]->_set_tool_wire_format_given(1) },
);

# A lazy slot looks the same whether the constructor filled it or the builder
# did, but only the builder's value may be dropped when a clone_object copy
# changes chat_model (Manifest::Builder's per-model probe, karr k251). The
# trigger fires for a constructor value and never for the builder, so this
# flag tells the two apart; clone_object copies it along with the tag.
has _tool_wire_format_given => (
  is       => 'ro',
  isa      => 'Bool',
  init_arg => undef,
  default  => 0,
  writer   => '_set_tool_wire_format_given',
);

# Drops a builder-made tag so the next read resolves it again (for the
# clone's chat_model); a constructor tag stays.
sub _reset_derived_tool_wire_format {
  my ($self) = @_;
  $self->_clear_tool_wire_format unless $self->_tool_wire_format_given;
  return $self;
}

# Defaults to the OpenAI dialect; AnthropicCompatible, HermesTools, and
# OpenAIResponses override the builder via -excludes, while Engines (Ollama,
# Gemini, AKI, NousResearch) ship their own override. See
# Langertha::Engine::AnthropicBase:9-23 for the canonical -excludes exemplar.
sub _build_tool_wire_format { 'openai' }


# The five tool-format methods below are tag-driven defaults: they delegate to
# the Langertha::Tool / ToolCall / ToolResult value objects keyed by
# L</tool_wire_format>. Engines no longer carry per-format copies.

sub build_tool_chat_request {
  my ( $self, $conversation, $formatted_tools, %extra ) = @_;
  if ( $self->tool_wire_format eq 'hermes' ) {
    return $self->chat_request( $self->_hermes_tool_messages( $conversation, $formatted_tools ), %extra );
  }
  return $self->chat_request( $conversation, tools => $formatted_tools, %extra );
}

# The hermes wire has no tools body key: the tools ride a leading system
# message built from hermes_tool_prompt. Shared by the tool loop and by a
# single chat_f / chat_stream_realtime_f turn (karr k231).
sub _hermes_tool_messages {
  my ( $self, $conversation, $formatted_tools ) = @_;
  my $tool_prompt = sprintf( $self->hermes_tool_prompt, $self->encode_json_text($formatted_tools) );
  return [ { role => 'system', content => $tool_prompt }, @$conversation ];
}

# Splits hermes model text into the text without the call tags and the
# well-formed calls ({name, arguments} HASHes) the tags carried, honoring
# hermes_call_tag. Shared by response_tool_calls, response_text_content,
# chat_f's reply lift (karr k231) and the streamed lift (k253). Delegates to
# Langertha::ToolCall->extract_hermes_from_text, the one hermes lift (k255):
# only a well-formed call reaches the tool loop (k163), a block that carries
# no call stays in the text where it was (k253 review).
sub _hermes_split_text {
  my ( $self, $text ) = @_;
  my ( $content, $calls ) = Langertha::ToolCall->extract_hermes_from_text(
    $text, tag => $self->hermes_call_tag );
  # Carry the k345 undecodable flag through the reduced hash so it survives the
  # Response tool_calls upgrade and the tool loop answers a bad hermes call an
  # error result rather than running the tool on {} -- karr k350.
  return ( $content, [ map {
    { name => $_->name, arguments => $_->arguments,
      ( $_->arguments_undecodable
        ? ( arguments_undecodable => 1,
            ( $_->has_arguments_error ? ( arguments_error => $_->arguments_error ) : () ) )
        : () ) }
  } @$calls ] );
}

# The streamed counterpart of chat_f's reply lift (karr k253, ADR 0001): text
# inside <tool_call>...</tool_call> (hermes_call_tag) is not emitted, and the
# calls land on the final chunk. Called by chat_stream_realtime_f for each
# chunk of a turn whose tools went into the prompt; returns the chunk to
# deliver, or undef for a chunk that carried only call markup. Each closed
# block goes through _hermes_split_text, so the stream finds the calls chat_f
# finds and streams a block that is no call as text, where chat_f keeps it.
# $flush (the stream ended without a final chunk) returns the chunk for
# whatever is still held, or undef when nothing is. finish_reason becomes
# tool_calls only over stop or none, as chat_f's lift (k253 review).
sub _hermes_stream_chunk {
  my ( $self, $state, $chunk, $flush ) = @_;
  if ($flush) {
    return if $state->{done};
    my $text  = $self->_hermes_stream_split( $state, '', 1 );
    my $calls = $self->_hermes_stream_calls($state);
    return unless length $text || @$calls;
    require Langertha::Stream::Chunk;
    return Langertha::Stream::Chunk->new( content => $text, is_final => 1,
      @$calls ? ( tool_calls => $calls, finish_reason => 'tool_calls' ) : () );
  }
  return $chunk if $state->{done};
  my $final = $chunk->is_final || length( $chunk->finish_reason // '' );
  my $text  = $self->_hermes_stream_split( $state, $chunk->content, $final );
  my %set;
  $set{content} = $text if $text ne $chunk->content;
  if ($final) {
    $state->{done} = 1;
    my $calls = $self->_hermes_stream_calls($state);
    if (@$calls) {
      $set{tool_calls} = [ @{ $chunk->tool_calls // [] }, @$calls ];
      my $reason = $chunk->finish_reason;
      $set{finish_reason} = 'tool_calls' if !length( $reason // '' ) || $reason eq 'stop';
    }
  }
  return $chunk unless %set;
  return if !$final && $text eq ''
    && !grep { my $has = "has_$_"; $chunk->$has } qw( thinking tool_calls usage cached_tokens citations );
  return $chunk->meta->clone_object( $chunk, %set );
}

# The calls of the closed blocks the stream withheld, as the Response
# BUILDARGS upgrade makes them of chat_f's.
sub _hermes_stream_calls {
  my ( $self, $state ) = @_;
  return [ map {
    Langertha::ToolCall->new(
      name      => $_->{name},
      arguments => ( ref $_->{arguments} eq 'HASH' ? $_->{arguments} : {} ),
      # Carry the k345 undecodable flag through the streamed lift the same way
      # the Response BUILDARGS upgrade does (k350): a closed block whose
      # arguments are no object is a call with arguments {} and the flag, so the
      # streamed tool_calls match the non-streaming reply's -- karr k351.
      ( $_->{arguments_undecodable}
        ? ( arguments_undecodable => 1,
            ( defined $_->{arguments_error} ? ( arguments_error => $_->{arguments_error} ) : () ) )
        : () ),
    )
  } @{ $state->{calls} // [] } ];
}

# Tag-aware incremental splitter behind _hermes_stream_chunk. Appends $text to
# the held text and returns what may be emitted now: text outside a call block
# streams, a closed <tool_call>...</tool_call> is decided when it closes (its
# call goes to $state->{calls}; a block that is no call is emitted in place as
# text), and a tail that may still turn into a tag is held until the next chunk. With the
# think tag filter on (Role::ThinkTag), a <think> block passes through as text
# and a call tag inside it is no call, as chat_f strips thinking before its
# lift. Until a think tag is seen, a closing one is an orphan (the chat
# template opened the thought in the prompt): the text before it is thinking,
# so the calls closed before it are handed back as text, as chat_f finds none
# in thinking (k302). $flush releases everything held, an unclosed call block
# as text.
sub _hermes_stream_split {
  my ( $self, $state, $text, $flush ) = @_;
  my $buf = \$state->{pending};
  $$buf //= '';
  $$buf .= $text // '';
  my $tag   = $self->hermes_call_tag;
  my $think = $self->can('think_tag_filter') && $self->think_tag_filter ? $self->think_tag : undef;
  my $out = '';
  while (1) {
    my $mode = $state->{mode} // 'text';
    if ( $mode eq 'call' ) {
      my $close = "</$tag>";
      my $at = index( $$buf, $close );
      last if $at < 0;
      my $block = substr( $$buf, 0, $at + length $close, '' );
      my ( undef, $calls ) = $self->_hermes_split_text($block);
      if (@$calls) {
        push @{ $state->{calls} }, @$calls;
        push @{ $state->{tentative} }, [ $block, scalar @$calls ]
          if defined $think && !$state->{think_seen};
      }
      else { $out .= $block }
      $state->{mode} = 'text';
      next;
    }
    my @marks = $mode eq 'think' ? ( [ "</$think>", 'text' ] )
      : ( [ "<$tag>", 'call' ], defined $think ? [ "<$think>", 'think' ] : (),
          defined $think && !$state->{think_seen} ? [ "</$think>", 'orphan' ] : () );
    my ( $at, $hit );
    for my $mark (@marks) {
      my $pos = index( $$buf, $mark->[0] );
      ( $at, $hit ) = ( $pos, $mark ) if $pos >= 0 && ( !defined $at || $pos < $at );
    }
    if ( $hit && $hit->[1] eq 'orphan' ) {
      # Everything up to here was thinking, so its calls were none.
      my @blocks = @{ delete $state->{tentative} // [] };
      my $count  = 0;
      $count += $_->[1] for @blocks;
      splice @{ $state->{calls} }, 0, $count;
      $out .= substr( $$buf, 0, $at, '' ) . join( '', map { $_->[0] } @blocks )
        . substr( $$buf, 0, length $hit->[0], '' );
      $state->{think_seen} = 1;
      next;
    }
    if ($hit) {
      $state->{think_seen} = 1 if $hit->[1] eq 'think';
      # A call block stays held from its opening tag on; think tags stream.
      $out .= substr( $$buf, 0, $hit->[1] eq 'call' ? $at : $at + length $hit->[0], '' );
      $state->{mode} = $hit->[1];
      next;
    }
    my $keep = 0;
    for my $mark ( map { $_->[0] } @marks ) {
      for my $len ( reverse 1 .. length($mark) - 1 ) {
        next if $len > length $$buf;
        next unless substr( $$buf, -$len ) eq substr( $mark, 0, $len );
        $keep = $len if $len > $keep;
        last;
      }
    }
    $out .= substr( $$buf, 0, length($$buf) - $keep, '' );
    last;
  }
  if ($flush) {
    $out .= $$buf;
    $$buf = '';
    $state->{mode} = 'text';
  }
  return $out;
}


sub format_tools {
  my ( $self, $mcp_tools ) = @_;
  return Langertha::Tool->format_list( $self->tool_wire_format, $mcp_tools );
}


sub response_tool_calls {
  my ( $self, $data ) = @_;
  my $fmt = $self->tool_wire_format;
  # The calls tool_loop_response would run, as raw structures -- karr k341.
  # Hermes: the calls of chat_response's reply (native ones, else the lift),
  # as { name, arguments }; a body it rejects falls back to the text split.
  if ( $fmt eq 'hermes' ) {
    my $reply = $self->_reply_from_data($data) or return $self->_raw_tool_calls($data);
    $reply = $self->_hermes_lift($reply);
    return [ map { { name => $_->name, arguments => $_->arguments } }
      @{ $reply->has_tool_calls ? $reply->tool_calls : [] } ];
  }
  # Others: a located structure that parses to no ToolCall is no call.
  return [ grep { defined Langertha::ToolCall->from_fmt( $fmt, $_ ) }
    @{ Langertha::ToolCall->locate( $fmt, $data ) } ];
}

# The raw calls read straight off a decoded body, without chat_response:
# response_tool_calls' hermes fallback, and what an engine's own
# chat_response uses (AKI native), which must not recurse into it.
sub _raw_tool_calls {
  my ( $self, $data ) = @_;
  my $fmt = $self->tool_wire_format;
  if ( $fmt eq 'hermes' ) {
    my $content = $self->hermes_extract_content($data);
    # A call inside the thinking is not a call: split the think-filtered text,
    # as chat_f and the stream lift do (k302) -- karr k323.
    ($content) = $self->filter_think_content($content)
      if $self->can('filter_think_content');
    return [] unless $content;
    return ( $self->_hermes_split_text($content) )[1];
  }
  return Langertha::ToolCall->locate( $fmt, $data );
}


sub extract_tool_call {
  my ( $self, $tc ) = @_;
  my $fmt = $self->tool_wire_format;
  return ( $tc->{name}, $tc->{arguments} ) if $fmt eq 'hermes';
  my $call = Langertha::ToolCall->from_fmt( $fmt, $tc );
  return $call ? ( $call->name, $call->arguments ) : ( undef, undef );
}


sub response_text_content {
  my ( $self, $data ) = @_;
  # The text chat_f and the tool loops answer (Gemini thought parts out,
  # content-chunk lists joined, think tags filtered), read by the engine's
  # chat_response. A body chat_response rejects falls back to the plain
  # per-format read below: plugins call this reader, it never croaks -- karr k338.
  if ( my $reply = $self->_reply_from_data($data) ) {
    my $text = $reply->content // '';
    $text = ( $self->_hermes_split_text($text) )[0]
      if $self->tool_wire_format eq 'hermes';
    return $text;
  }
  return $self->_raw_text_content($data);
}

# The per-format text read straight off a decoded body, without
# chat_response: response_text_content's fallback, and what an engine's own
# chat_response uses (AKI native), which must not recurse into it.
sub _raw_text_content {
  my ( $self, $data ) = @_;
  return '' unless ref $data eq 'HASH';
  my $fmt = $self->tool_wire_format;
  if ( $fmt eq 'openai' ) {
    my $choice = $data->{choices}[0] or return '';
    return $choice->{message}{content} // '';
  }
  if ( $fmt eq 'ollama' ) {
    my $msg = $data->{message} or return '';
    return $msg->{content} // '';
  }
  if ( $fmt eq 'anthropic' ) {
    return join( '',
      map { $_->{text} } grep { $_->{type} eq 'text' } @{ $data->{content} // [] } );
  }
  if ( $fmt eq 'gemini' ) {
    my $candidates = $data->{candidates} || [];
    return '' unless @$candidates;
    my $parts = $candidates->[0]{content}{parts} || [];
    return join( '', map { $_->{text} } grep { exists $_->{text} } @$parts );
  }
  if ( $fmt eq 'responses' ) {
    my $text = '';
    for my $item ( @{ $data->{output} // [] } ) {
      next unless ref($item) eq 'HASH';
      next unless ( $item->{type} // '' ) eq 'message';
      for my $block ( @{ $item->{content} // [] } ) {
        $text .= ( $block->{text} // '' ) if ( $block->{type} // '' ) eq 'output_text';
      }
    }
    return $text;
  }
  if ( $fmt eq 'hermes' ) {
    return ( $self->_hermes_split_text( $self->hermes_extract_content($data) ) )[0];
  }
  return '';
}


# The Response the engine's chat_response builds from a decoded body, as if
# the body had arrived in a 200. The engine's rate limit describes the last
# real response, so it is kept as it was -- karr k338.
sub _chat_response_from_data {
  my ( $self, $data ) = @_;
  require HTTP::Response;
  my $http = HTTP::Response->new( 200, 'OK',
    [ 'Content-Type' => 'application/json' ], $self->json->encode($data) );
  return $self->chat_response($http) unless $self->can('_last_rate_limit');
  my ( $had, $rate_limit ) = ( $self->_has_last_rate_limit, $self->_last_rate_limit );
  my $reply;
  my $ok  = eval { $reply = $self->chat_response($http); 1 };
  my $err = $@;
  if ($had) { $self->_last_rate_limit($rate_limit) } else { $self->_clear_last_rate_limit }
  die $err unless $ok;
  return $reply;
}

# _chat_response_from_data for the readers: undef instead of a croak, when
# the body is no HASH or the engine cannot parse it.
sub _reply_from_data {
  my ( $self, $data ) = @_;
  return undef unless ref $data eq 'HASH' && $self->can('chat_response');
  local $@;
  my $reply = eval { $self->_chat_response_from_data($data) };
  return blessed $reply ? $reply : undef;
}

# A result's tool_call is a Langertha::ToolCall (the tool loops read
# Response.tool_calls, ADR 0003) or the raw wire structure response_tool_calls
# locates (langertha-raider). The id / name the result block pairs with, from
# either -- karr k321.
sub _result_call_id {
  my ( $tc ) = @_;
  return $tc->id if blessed $tc;
  return $tc->{functionCall}{id} // '' if ref $tc->{functionCall} eq 'HASH';
  return $tc->{call_id} // $tc->{id} // '';
}

sub _result_call_name {
  my ( $tc ) = @_;
  return $tc->name if blessed $tc;
  return $tc->{functionCall}{name} // '' if ref $tc->{functionCall} eq 'HASH';
  return $tc->{function}{name} // '' if ref $tc->{function} eq 'HASH';
  return $tc->{name} // '';
}

# The MCP call_tool result's payload as ToolResult constructor args: content
# plus structuredContent, which every format falls back to when content is
# empty (karr k326, k336).
sub _result_payload {
  my ( $result ) = @_;
  return (
    content => ( $result->{content} // [] ),
    ( defined $result->{structuredContent}
      ? ( structured_content => $result->{structuredContent} ) : () ),
  );
}

# Tool-result images ride natively (ToolResult's image_input option; the
# responses, gemini and anthropic wires have a form for it, karr k344, k359)
# only when the selected model sees images (image_input, ADR 0019) and the
# wire takes them for that model (_tool_result_images_on_wire). The tool loop
# sends what an MCP server returned, not what the caller chose, so a model that
# makes no claim keeps the k336 placeholder.
sub _tool_result_images_on_wire { 1 }

sub _tool_result_image_opts {
  my ( $self ) = @_;
  return () unless $self->_tool_result_images_on_wire
    && $self->can('supports') && $self->supports('image_input');
  return ( image_input => 1 );
}

# Tool-result PDFs ride natively (ToolResult's native_pdf option, karr k361)
# only where the wire documents a PDF inside a tool result for the selected
# model (_tool_result_pdf_on_wire: OpenAIResponses' input_file, Gemini 3's
# functionResponse.parts) and the model claims image_input: both providers
# document PDF understanding as a vision feature (OpenAI parses page text and
# page images and names vision models; Gemini reads documents through its
# vision), so a text-only model keeps the k336 placeholder rather than risk a
# 400 mid-loop. Off by default: every other wire (openai, ollama, hermes,
# Perplexity's Agent API, older Gemini) has no documented form. The anthropic
# wire's PDF document block is decided by _tool_result_source_blocks_on_wire
# (k326, k364) and does not read this, nor image_input (k371): the Anthropic
# dialect extracts PDF text without vision (MiniMax-M2.7, text-only, read one
# live 2026-09-30), so the block is a wire fact, not a model question.
sub _tool_result_pdf_on_wire { 0 }

sub _tool_result_pdf_opts {
  my ( $self ) = @_;
  return () unless $self->_tool_result_pdf_on_wire
    && $self->can('supports') && $self->supports('image_input');
  return ( native_pdf => 1 );
}

# Whether the anthropic wire takes Anthropic's source blocks (document,
# search_result) inside a tool_result (karr k364, k366). First-party Anthropic
# documents them; a /anthropic shim that rejects them sets this to 0, and
# ToolResult then sends a text document as a text block, a PDF as the k336
# placeholder and a native document / search_result as its text. Wire truth,
# not a model question, so it is a private predicate and not a capability flag.
sub _tool_result_source_blocks_on_wire { 1 }

# A native document / search_result is the caller's choice for the Anthropic
# wire, so turning it into text is worth one warning per engine instance (the
# ADR 0035 once-key pattern). An MCP resource becoming text is the normal path
# on these shims and stays quiet.
sub _carp_degraded_source_blocks {
  my ( $self, $result ) = @_;
  my @types = $result->_native_source_block_types or return;
  return unless $self->can('_langertha_carp');
  $self->_langertha_carp( "".( ref $self ).": sending " . join( ' / ', @types )
    . " blocks in a tool result as text -- this endpoint takes no document or"
    . " search_result block inside a tool_result", 'tool_result_source_blocks' );
  return;
}

sub format_tool_results {
  my ( $self, $data, $results ) = @_;
  my $fmt = $self->tool_wire_format;

  if ( $fmt eq 'anthropic' ) {
    my $source_blocks = $self->_tool_result_source_blocks_on_wire;
    my @opts = ( $self->_tool_result_image_opts,
      ( $source_blocks ? () : ( source_blocks => 0 ) ) );
    my @blocks = map {
      my $result = Langertha::ToolResult->new(
        id       => _result_call_id( $_->{tool_call} ),
        _result_payload( $_->{result} ),
        is_error => ( $_->{result}{isError} ? 1 : 0 ),
      );
      $self->_carp_degraded_source_blocks($result) unless $source_blocks;
      $result->to( 'anthropic', @opts );
    } @$results;
    return (
      { role => 'assistant', content => $data->{content} },
      { role => 'user',      content => \@blocks },
    );
  }

  if ( $fmt eq 'gemini' ) {
    my @opts  = ( $self->_tool_result_image_opts, $self->_tool_result_pdf_opts );
    my @parts = map {
      Langertha::ToolResult->new(
        name    => _result_call_name( $_->{tool_call} ),
        id      => _result_call_id( $_->{tool_call} ),
        _result_payload( $_->{result} ),
      )->to( 'gemini', @opts )
    } @$results;
    my $candidate = $data->{candidates}[0];
    return (
      { role => 'model', parts => $candidate->{content}{parts} },
      { role => 'user',  parts => \@parts },
    );
  }

  if ( $fmt eq 'ollama' ) {
    my $msg  = $data->{message};
    my %echo = (
      role       => 'assistant',
      content    => $msg->{content},
      tool_calls => $msg->{tool_calls},
    );
    # Ollama returns the chain-of-thought in message.thinking; echo it back for
    # the same reason the openai branch below echoes reasoning_content
    # (karr k136).
    $echo{thinking} = $msg->{thinking} if defined $msg->{thinking};
    return (
      \%echo,
      map {
        Langertha::ToolResult->new(
          name    => _result_call_name( $_->{tool_call} ),
          id      => _result_call_id( $_->{tool_call} ),
          _result_payload( $_->{result} ),
        )->to('ollama')
      } @$results,
    );
  }

  if ( $fmt eq 'responses' ) {
    # The Responses API takes one flat item list: the model's own output items
    # echoed back, then one function_call_output per result. It only accepts a
    # function_call_output whose call_id was announced by a *top-level*
    # function_call item, so hoist any call out of the legacy
    # nested-inside-a-message shape that ToolCall->locate('responses') also
    # walks. Returns a LIST like every other branch — every caller does
    # `push @$conversation, $engine->format_tool_results(...)` (karr #85).
    my @echo;
    for my $item ( @{ $data->{output} // [] } ) {
      next unless ref($item) eq 'HASH';
      if ( ( $item->{type} // '' ) eq 'message' ) {
        my @content = grep { ref($_) eq 'HASH' } @{ $item->{content} // [] };
        my @calls   = grep { ( $_->{type} // '' ) eq 'function_call' } @content;
        my @rest    = grep { ( $_->{type} // '' ) ne 'function_call' } @content;
        push @echo, { %$item, content => \@rest } if @rest;
        push @echo, @calls;
        next;
      }
      push @echo, $item;
    }
    # Which echoed items the wire takes back as input is the envelope's call:
    # the ResponsesCompatible hook passes all through on OpenAI and filters to
    # the Agent input schema on Perplexity (karr k213, ADR 0020).
    @echo = map { $self->_responses_echo_item($_) } @echo
      if $self->can('_responses_echo_item');
    my @opts = ( $self->_tool_result_image_opts, $self->_tool_result_pdf_opts );
    return (
      @echo,
      map {
        Langertha::ToolResult->new(
          id      => _result_call_id( $_->{tool_call} ),
          _result_payload( $_->{result} ),
        )->to( 'responses', @opts )
      } @$results,
    );
  }

  if ( $fmt eq 'hermes' ) {
    my $content = $self->hermes_extract_content($data);
    my $res_tag = $self->hermes_response_tag;
    return (
      { role => 'assistant', content => $content },
      map {
        { role    => 'tool',
          content => Langertha::ToolResult->new(
            name    => _result_call_name( $_->{tool_call} ),
            _result_payload( $_->{result} ),
          )->to( 'hermes', response_tag => $res_tag ) }
      } @$results,
    );
  }

  # openai (default)
  my $msg  = $data->{choices}[0]{message};
  my %echo = (
    role       => 'assistant',
    content    => $msg->{content},
    tool_calls => $msg->{tool_calls},
  );
  # Carry the provider's reasoning fields back into the assistant echo.
  # DeepSeek returns HTTP 400 on the next iteration of a tool loop when
  # reasoning_content is not sent back while tools are present; Moonshot
  # (kimi) requires the same within one tool-call loop, OpenRouter requires
  # reasoning_details to round-trip unmodified, Mistral loses output quality
  # and xAI misses the prompt cache without it. Deliberately an allowlist and
  # not the whole message: some OpenAI-compatible servers reject unknown keys
  # on an inbound assistant message (karr k136).
  for my $key (qw( reasoning_content reasoning reasoning_details )) {
    $echo{$key} = $msg->{$key} if defined $msg->{$key};
  }
  return (
    \%echo,
    map {
      Langertha::ToolResult->new(
        id      => _result_call_id( $_->{tool_call} ),
        _result_payload( $_->{result} ),
      )->to('openai')
    } @$results,
  );
}


# One tool-loop turn's reply, read by the parser chat_f uses: chat_response
# croaks on an error-in-body 200 exactly as chat_f does (k301/k311/k317) and
# yields the same final text (Gemini thought parts out, content-chunk arrays
# joined, think tags filtered) -- karr k321, k322. The calls to run are
# Response.tool_calls (ADR 0003); hermes calls ride in the text and are lifted
# as chat_f lifts them, unless the engine's chat_response already did (AKI
# native). ->raw stays the wire body the assistant echo is built from.
# Shared by chat_with_tools_f and both Langertha::Chat tool loops.
# Public since k341 (ADR 0028): langertha-raider's loop reads its replies here
# instead of the raw body. Takes the HTTP::Response or the decoded body.
sub tool_loop_response {
  my ( $self, $reply ) = @_;
  my $response = blessed $reply && $reply->isa('HTTP::Response')
    ? $self->chat_response($reply)
    : $self->_chat_response_from_data($reply);
  # A blocked prompt is an answer to chat_f (k301) but ends a tool loop, whose
  # result is only text: '' would hide why -- karr k339.
  my $blocked = $self->_tool_loop_block_reason($response);
  croak "" . ( ref $self ) . " prompt blocked: $blocked" if defined $blocked;
  return $self->_hermes_lift($response);
}

sub _tool_loop_response { shift->tool_loop_response(@_) }


# The hermes calls ride in the text: lifted as chat_f lifts them, unless the
# engine's chat_response already did (AKI native).
sub _hermes_lift {
  my ( $self, $response ) = @_;
  return $response unless $self->tool_wire_format eq 'hermes'
    && !( $response->has_tool_calls && @{ $response->tool_calls } );
  my ( $clean, $calls ) = $self->_hermes_split_text( $response->content );
  return @$calls ? $response->clone_with( content => $clean, tool_calls => $calls ) : $response;
}

# Why the provider refused the prompt itself, when a reply says so (Gemini's
# promptFeedback.blockReason); undef otherwise. Engines whose wire reports a
# blocked prompt override it -- karr k339.
sub _tool_loop_block_reason { return }

# The finish reasons that mean "the reply hit its token limit", as each wire
# spells it: OpenAI-compatible and Ollama 'length', Anthropic 'max_tokens',
# Gemini 'MAX_TOKENS', an incomplete Responses message 'incomplete'.
my %TOKEN_LIMIT_FINISH = map { $_ => 1 } qw( length max_tokens MAX_TOKENS incomplete );

# The calls one tool-loop turn runs, and the wire body its assistant echo is
# built from. A reply cut off by its token limit can carry a call whose
# arguments string was cut too; it decodes to nothing, and running the tool on
# {} is wrong, so that call is dropped, as the stream parser drops an
# unfinished call. With no call left the loop croaks; otherwise the complete
# calls run, a carp names the dropped ones, and the echo leaves them out, so
# the next turn has no call without a result -- karr k324.
sub tool_loop_calls {
  my ( $self, $reply, $data ) = @_;
  $data //= $reply->raw;
  my @calls  = $reply->has_tool_calls ? @{ $reply->tool_calls } : ();
  my $reason = $reply->finish_reason;
  return ( \@calls, $data )
    unless @calls && defined $reason && $TOKEN_LIMIT_FINISH{$reason};
  my @dropped = grep { $_->arguments_undecodable } @calls;
  return ( \@calls, $data ) unless @dropped;
  my $class = ref $self;
  croak "$class tool call arguments truncated (finish_reason $reason); raise response_size"
    if @dropped == @calls;
  $self->_langertha_carp( "$class: dropped " . scalar(@dropped)
    . " tool call(s) with truncated arguments (finish_reason $reason): "
    . join( ', ', map { $_->name } @dropped ) . "; raise response_size" );
  return ( [ grep { !$_->arguments_undecodable } @calls ],
    $self->_echo_without_undecodable_calls($data) );
}

sub _tool_loop_calls { shift->tool_loop_calls(@_) }


# A copy of the wire body without the raw calls whose arguments do not
# decode; everything else is shared. Hermes calls ride in the text, and an
# unfinished <tool_call> block never became a call.
sub _echo_without_undecodable_calls {
  my ( $self, $data ) = @_;
  my $fmt = $self->tool_wire_format;
  return $data if $fmt eq 'hermes';
  my %drop;
  for my $raw ( @{ Langertha::ToolCall->locate( $fmt, $data ) } ) {
    my $call = Langertha::ToolCall->from_fmt( $fmt, $raw );
    $drop{ refaddr $raw } = 1 if $call && $call->arguments_undecodable;
  }
  return _without_refs( $data, \%drop );
}

sub _without_refs {
  my ( $node, $drop ) = @_;
  return { map { $_ => _without_refs( $node->{$_}, $drop ) } keys %$node }
    if ref $node eq 'HASH';
  return [ map { _without_refs( $_, $drop ) }
    grep { !( ref $_ && $drop->{ refaddr $_ } ) } @$node ]
    if ref $node eq 'ARRAY';
  return $node;
}

# The tool list a tool loop sends and the server each name runs on, from
# ( [ $mcp, \@tools ], ... ) in mcp_servers order. A name two servers offer is
# sent once -- providers reject a request that declares one function twice --
# and runs on the first server; a carp names both -- karr k332.
sub _tool_loop_tools {
  my ( $self, @server_tools ) = @_;
  my ( @all_tools, %tool_server_map, %server_no );
  my $label = sub { "MCP server $server_no{ refaddr $_[0] } (" . ref( $_[0] ) . ")" };
  my $no = 0;
  for my $pair (@server_tools) {
    my ( $mcp, $tools ) = @$pair;
    $server_no{ refaddr $mcp } //= ++$no;
    for my $tool (@$tools) {
      my $name = $tool->{name};
      if ( my $first = $tool_server_map{$name} ) {
        $self->_langertha_carp( "" . ( ref $self ) . ": tool '$name' is offered by "
          . $label->($first) . " and " . $label->($mcp) . "; using the first" );
        next;
      }
      $tool_server_map{$name} = $mcp;
      push @all_tools, $tool;
    }
  }
  return ( \@all_tools, \%tool_server_map );
}

# The result a tool loop answers a call to a tool no server offers: an error
# the model can recover from, not a die that loses the batch -- karr k332.
sub _unknown_tool_result {
  my ( $name ) = @_;
  return {
    content => [ { type => 'text', text => "unknown tool " . ( $name // '' ) } ],
    isError => JSON->true,
  };
}

# The result a tool loop answers a call whose arguments do not decode, or
# undef for a call whose arguments did. A call cut off by the token limit was
# already dropped by _tool_loop_calls; any other one would run the tool on {},
# so the model gets an error it can retry instead -- karr k345.
sub _undecodable_arguments_result {
  my ( $tc ) = @_;
  return undef unless $tc->arguments_undecodable;
  return {
    content => [ { type => 'text',
      text => "arguments are not valid JSON: " . ( $tc->arguments_error // 'not a JSON object' ) } ],
    isError => JSON->true,
  };
}

async sub chat_with_tools_f {
  my ( $self, @messages ) = @_;

  croak "No MCP servers configured" unless @{$self->mcp_servers};

  # Gather tools from all MCP servers
  my @server_tools;
  for my $mcp (@{$self->mcp_servers}) {
    push @server_tools, [ $mcp, await $mcp->list_tools ];
  }
  my ( $all_tools, $tool_server_map ) = $self->_tool_loop_tools(@server_tools);
  my @all_tools = @$all_tools;

  my $formatted_tools = $self->format_tools(\@all_tools);
  # URL images this engine inlines: fetched async, not by LWP in the loop (k274).
  @messages = await $self->_prefetch_inline_images_f(@messages);
  my $conversation = $self->chat_messages(@messages);

  $log->debugf("[%s] chat_with_tools_f: %d tools from %d MCP servers, max_iterations=%d",
    ref $self, scalar @all_tools, scalar @{$self->mcp_servers}, $self->tool_max_iterations);

  for my $iteration (1..$self->tool_max_iterations) {
    $log->debugf("[%s] Tool loop iteration %d/%d",
      ref $self, $iteration, $self->tool_max_iterations);

    my $request = $self->build_tool_chat_request($conversation, $formatted_tools);
    my $response = await $self->_async_do_request_f(request => $request);

    # A failed response records its rate limit before the die, as in chat_f
    # (karr k300); a success does it in parse_response.
    unless ($response->is_success) {
      $self->_update_rate_limit($response) if $self->can('_update_rate_limit');
      die $self->_request_failed_message( $response, 'tool chat request' );
    }

    my $reply = $self->_tool_loop_response($response);
    my ( $calls, $data ) = $self->_tool_loop_calls( $reply, $reply->raw );
    my @tool_calls = @$calls;

    # No tool calls means the LLM is done — return final text
    return $reply->content unless @tool_calls;

    # Execute each tool call via the appropriate MCP server
    my @results;
    for my $tc (@tool_calls) {
      my ( $name, $input ) = ( $tc->name, $tc->arguments );

      # A name no server offers is answered with an error result, so the
      # batch runs to the end and the model can correct itself (k332).
      my $mcp = $tool_server_map->{$name};
      unless ($mcp) {
        push @results, { tool_call => $tc, result => _unknown_tool_result($name) };
        next;
      }
      if ( my $bad = _undecodable_arguments_result($tc) ) {
        push @results, { tool_call => $tc, result => $bad };
        next;
      }

      $log->debugf("[%s] Calling tool: %s", ref $self, $name);

      my $result = await $mcp->call_tool($name, $input)->else(sub {
        my ( $error ) = @_;
        Future->done({
          content => [{ type => 'text', text => "Error calling tool '$name': $error" }],
          isError => JSON->true,
        });
      });

      push @results, { tool_call => $tc, result => $result };
    }

    # Append assistant message and tool results to conversation
    push @$conversation, $self->format_tool_results($data, \@results);
  }

  die "Tool calling loop exceeded ".$self->tool_max_iterations." iterations";
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Tools - Role for MCP tool calling support

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use IO::Async::Loop;
    use Future::AsyncAwait;

    my $loop = IO::Async::Loop->new;

    # Set up any Net::Async::MCP-compatible client (langertha-raider uses
    # Net::Async::MCP directly)
    my $mcp = SomeMCPClient->new(server => $my_mcp_server);
    $loop->add($mcp);
    await $mcp->initialize;

    # Create engine with MCP servers (native tool calling)
    my $engine = Langertha::Engine::Anthropic->new(
        api_key     => $ENV{ANTHROPIC_API_KEY},
        model       => 'claude-sonnet-4-6',
        mcp_servers => [$mcp],
    );

    my $response = await $engine->chat_with_tools_f(
        'Use the available tools to answer my question'
    );

    # Hermes tool calling (for APIs without native tool support)
    my $engine = Langertha::Engine::AKI->new(
        api_key     => $ENV{AKI_API_KEY},
        mcp_servers => [$mcp],
    );

=head1 DESCRIPTION

This role adds MCP (Model Context Protocol) tool calling support to Langertha
engines. It provides the L</chat_with_tools_f> method which implements the full
async tool-calling loop:

=over 4

=item 1. Gather available tools from all configured MCP servers

=item 2. Send a chat request with tool definitions to the LLM

=item 3. If the LLM returns tool calls, execute them via MCP

=item 4. Feed tool results back to the LLM and repeat

=item 5. When the LLM returns final text, return it

=back

All tool wire-translation is tag-driven: an engine declares its dialect via
L</tool_wire_format> (C<openai> | C<anthropic> | C<gemini> | C<ollama> |
C<responses> | C<hermes>) and the default implementations of C<format_tools>,
C<response_tool_calls>, C<extract_tool_call>, C<format_tool_results>, and
C<response_text_content> delegate to the L<Langertha::Tool>,
L<Langertha::ToolCall>, and L<Langertha::ToolResult> value objects keyed by that
tag. Engines carry no per-format tool code. The C<hermes> dialect injects tools
into the system prompt and parses C<E<lt>tool_callE<gt>> XML; its tag names and
prompt template come from L<Langertha::Role::HermesTools>.

=head2 mcp_servers

    mcp_servers => [$mcp1, $mcp2]

ArrayRef of MCP client objects to use as tool providers — any
L<Net::Async::MCP>-compatible client (for example a L<Net::Async::MCP> client
as used by the langertha-raider distribution). Each entry must respond to
C<list_tools> and C<call_tool>. Defaults to an empty ArrayRef. At least one
server must be configured before calling L</chat_with_tools_f>.

=head2 tool_max_iterations

    tool_max_iterations => 20

Maximum number of tool-calling round trips before aborting with an error.
Defaults to C<10>. Increase for complex multi-step tool workflows.

=head2 tool_wire_format

    tool_wire_format => 'anthropic'

The single per-engine enum naming which tool dialect this engine speaks —
C<openai> | C<anthropic> | C<gemini> | C<ollama> | C<responses> | C<hermes>.
This one tag drives all tool wire-translation: the outbound tool definitions
(L<Langertha::Tool>), the inbound tool calls (L<Langertha::ToolCall>), the
result blocks (L<Langertha::ToolResult>), the final-text extraction, and the
outbound transport (native API parameter vs. Hermes prompt injection).

The default follows the engine base-class hierarchy: C<OpenAIBase> leaves it at
C<openai>, C<AnthropicBase> overrides to C<anthropic>, and so on — so the ~25
concrete engines inherit it and carry no tool-format code of their own. Override
C<_build_tool_wire_format> to change it.

=head2 build_tool_chat_request

    my $request = $self->build_tool_chat_request($conversation, $formatted_tools);

Builds an HTTP request for a tool-calling chat turn. For native wire formats the
tools are passed as an API parameter via C<chat_request>; for the C<hermes>
format they are injected into the system prompt as XML.

=head2 format_tools

    my $tools = $engine->format_tools($mcp_tools);

Converts an ArrayRef of MCP tool definitions to the wire C<tools> payload for
this engine's L</tool_wire_format> via L<Langertha::Tool/format_list>.

=head2 response_tool_calls

    my $tool_calls = $engine->response_tool_calls($raw_data);

Returns the ArrayRef of raw tool-call structures in C<$raw_data>: the calls
L</tool_loop_response> puts on L<Langertha::Response/tool_calls> for the same
body, in the same order, as this engine's format spells them. Located via
L<Langertha::ToolCall/locate>; a structure that parses to no call (no name) is
left out. For C<hermes>, each call is C<< { name, arguments } >>: the
C<E<lt>tool_callE<gt>> XML tags parsed out of the model's text (with
C<think_tag_filter> on, a call inside the thinking is not returned), or the
native calls the engine's parser found. May be empty. Calls cut off by the
token limit are still returned; L</tool_loop_calls> drops them.

=head2 extract_tool_call

    my ($name, $args) = $engine->extract_tool_call($tool_call);

Extracts the tool name and decoded argument HashRef from a single raw tool-call
structure, via L<Langertha::ToolCall/from_fmt>.

=head2 response_text_content

    my $text = $engine->response_text_content($raw_data);

Returns the assistant's final text from a decoded response body (what
C<parse_response> returns): the C<content> of the L<Langertha::Response> the
engine's C<chat_response> builds from it, the text L<Langertha::Role::Chat/chat_f>
and the tool loops answer. Gemini thought parts and Anthropic thinking blocks
stay out, a content-chunk list (Mistral) becomes its text, C<E<lt>thinkE<gt>>
tags are filtered when C<think_tag_filter> is on, and for C<hermes> the
C<E<lt>tool_callE<gt>> tags are stripped.

A body C<chat_response> rejects (an error in the body, a shape it cannot read)
does not croak here: the text is read per L</tool_wire_format> straight off the
body, or C<''>. The engine's L<Langertha::Engine::Remote/rate_limit> is left
as it was.

=head2 format_tool_results

    my @messages = $engine->format_tool_results($raw_data, $results);

Assembles tool execution results into the provider-shaped message envelope for
the next turn: the assistant echo of the prior turn plus one
L<Langertha::ToolResult> block per result (arity varies by format).

For the C<openai> and C<ollama> dialects the echo also carries the provider's
reasoning back when the turn had it — C<reasoning_content>, C<reasoning>,
C<reasoning_details> and C<thinking> respectively — because DeepSeek rejects a
tool loop whose earlier assistant turn lost it.

Always returns a LIST, for every C<tool_wire_format> — the callers append it
straight onto the conversation with
C<< push @$conversation, $engine->format_tool_results(...) >>, so a single
arrayref would land as one bogus conversation element.

Each result's C<tool_call> may be a L<Langertha::ToolCall> (what the tool
loops pass) or the raw structure L</response_tool_calls> located.

An image in a tool's output reaches the model as an image, not as a text
placeholder, on the C<responses> wire (C<input_image> parts in
C<function_call_output.output>), on Gemini 3 (C<functionResponse.parts>) and on
the C<anthropic> wire (an C<image> block in the C<tool_result>), when
C<< supports('image_input') >> is true for the configured model; see
L<Langertha::ToolResult/DESCRIPTION>. The C<responses> and Gemini forms are
documentation-derived, not live-verified, and so is the C<anthropic> form on
the C</anthropic> shims (Kimi documents it, MiniMax does not say).
L<Langertha::Engine::AKIAnthropic> keeps the placeholder for every model: its
shim answers a C<tool_result> image without error, but the model does not see
it.

A PDF in a tool's output (an embedded resource blob, C<application/pdf>)
reaches the model as a file, not as a text placeholder, on
L<Langertha::Engine::OpenAIResponses> (an C<input_file> part in
C<function_call_output.output>) and on Gemini 3 (C<functionResponse.parts>),
when C<< supports('image_input') >> is true for the configured model: both
providers document PDF understanding as a vision feature. Both forms are
documentation-derived, not live-verified. L<Langertha::Engine::Perplexity>
keeps the placeholder (its Agent API documents only text and image parts
there), as do the OpenAI chat, Ollama and Hermes wires and Gemini before 3.

On the C<anthropic> wire an embedded text resource or PDF goes out as a
C<document> block, except on L<Langertha::Engine::AKIAnthropic>,
L<Langertha::Engine::MoonshotAnthropic> and (conservatively, not live-verified)
L<Langertha::Engine::LMStudioAnthropic>, whose C</anthropic> endpoints take no
C<document> or C<search_result> in a C<tool_result>: there the text goes out as
a C<text> block and a PDF as a placeholder. The PDF C<document> block elsewhere
does not depend on C<image_input> (k371). An Anthropic-native C<document> or
C<search_result> block in a tool's output becomes a C<text> block with its text
there too, and the engine warns once.

=head2 tool_loop_response

    my $reply = $engine->tool_loop_response($http_response);
    my $reply = $engine->tool_loop_response($data);   # decoded body

Reads one tool-loop turn's reply the way L</chat_with_tools_f> and the
L<Langertha::Chat> tool loops do, and returns the L<Langertha::Response>. Takes
the L<HTTP::Response> of the turn or the body C<parse_response> decoded from
it (the engine's L<Langertha::Engine::Remote/rate_limit> is only updated from
an C<HTTP::Response>). Meant for sibling distributions that run their own tool
loop, such as langertha-raider, so they read replies as core does.

The reply is parsed by the engine's C<chat_response>, the parser
L<Langertha::Role::Chat/chat_f> uses: an error in a 200 body croaks with
C<chat_f>'s text, and the C<content> is C<chat_f>'s final text. The calls to
run are L<Langertha::Response/tool_calls>; on C<hermes> engines the
C<E<lt>tool_callE<gt>> blocks of the text are lifted there and stripped from
C<content>, unless the engine's parser already did. A prompt the provider
refused outright (Gemini's C<promptFeedback.blockReason>) croaks with
C<< <engine class> prompt blocked: REASON >>. C<raw> is the wire body the
assistant echo (L</format_tool_results>) is built from. To leave out calls cut
off by the token limit, pass the reply to L</tool_loop_calls>.

=head2 tool_loop_calls

    my ( $calls, $data ) = $engine->tool_loop_calls( $reply, $data );

The calls one tool-loop turn runs, and the wire body to build its assistant
echo (L</format_tool_results>) from, for a C<$reply> from
L</tool_loop_response>. C<$data> defaults to C<< $reply->raw >>. Public since
k341 for sibling distributions that run their own tool loop, such as
langertha-raider.

C<$calls> is an ArrayRef of L<Langertha::ToolCall>. When the reply hit its
token limit (C<finish_reason> C<length>, C<max_tokens>, C<MAX_TOKENS> or
C<incomplete>), a call whose arguments do not decode
(L<Langertha::ToolCall/arguments_undecodable>) is dropped: with no call left
this croaks C<tool call arguments truncated (finish_reason REASON); raise
response_size>, otherwise one warning names the dropped calls and the returned
C<$data> is a copy without them, so the next turn has no call without a
result. Otherwise the reply's calls and C<$data> come back unchanged.

=head2 chat_with_tools_f

    my $response = await $engine->chat_with_tools_f(@messages);

Async tool-calling chat loop. Accepts the same message arguments as
L<Langertha::Role::Chat/simple_chat>. Gathers tools from all L</mcp_servers>,
sends the request, executes any tool calls returned by the LLM, and repeats
until the LLM returns a final text response or L</tool_max_iterations> is
exceeded. Returns a L<Future> that resolves to the final text response.

Each reply is read by the engine's C<chat_response>, the parser
L<Langertha::Role::Chat/chat_f> uses: a response whose body reports an error
fails with the text C<chat_f> croaks, the calls run are the reply's
L<Langertha::Response/tool_calls>, and the final text is its C<content>. A
prompt the provider refuses outright (Gemini's C<promptFeedback.blockReason>)
dies with C<prompt blocked: REASON>, where C<chat_f> returns the Response.

A reply that hit its token limit (C<finish_reason> C<length>, C<max_tokens>,
C<MAX_TOKENS> or C<incomplete>) never runs a call whose arguments do not
decode (L<Langertha::ToolCall/arguments_undecodable>): if no other call is
left the loop dies with C<tool call arguments truncated>, otherwise the
complete calls run, one warning names the dropped ones, and the dropped calls
are left out of the conversation.

A call to a tool no server offers does not stop the loop: it is answered with
an error result C<unknown tool NAME>, and the other calls of the turn still
run. A tool name offered by two servers is sent once and runs on the first
server in L</mcp_servers>, with a warning naming both.

A call whose arguments do not decode on a reply that did not hit its token
limit is not run either: it is answered with an error result C<arguments are
not valid JSON: REASON> (L<Langertha::ToolCall/arguments_error>), and the
loop continues so the model can retry.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::HermesTools> - Hermes-style tool calling via XML tags

=item * L<Langertha::Role::Chat> - Chat role this is built on top of

=item * L<Langertha::Raider> - Autonomous agent with persistent history using
tools (in the langertha-raider distribution)

=item * L<Net::Async::MCP> - Base for the MCP clients used as tool providers

=item * L<Langertha::Engine::Anthropic> - Engine with native tool support

=back

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
