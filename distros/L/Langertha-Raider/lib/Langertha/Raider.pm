package Langertha::Raider;
# ABSTRACT: Autonomous agent with conversation history and MCP tools
our $VERSION = '0.503';
use Moose;
use Future;
use Future::AsyncAwait;
use Time::HiRes qw( gettimeofday tv_interval );
use Carp qw( croak carp );
use Module::Runtime qw( use_module );
use Scalar::Util qw( blessed refaddr weaken );
use JSON::MaybeXS qw( JSON );
use Log::Any qw( $log );
use MCP::Server;
use Net::Async::MCP;
use IO::Async::Handle;
use IO::Async::Loop;
use IO::Async::OS;
use Langertha::Usage;
use Langertha::Raider::ConnectCheck qw( connect_error );
use Langertha::Raider::Result;
use Langertha::Raider::ToolArgs qw( tool_args_problems );
use Langertha::RunContext;

with 'Langertha::Role::PluginHost', 'Langertha::Role::Runnable';


has engine => (
  is => 'ro',
  required => 1,
);


has mission => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_mission',
  writer => '_set_mission',
);


has history => (
  is => 'rw',
  isa => 'ArrayRef',
  default => sub { [] },
);


has max_iterations => (
  is => 'ro',
  isa => 'Int',
  default => 10,
);


has max_context_tokens => (
  is => 'ro',
  isa => 'Int',
  predicate => 'has_max_context_tokens',
);


has context_compress_threshold => (
  is => 'ro',
  isa => 'Num',
  default => 0.75,
);


has compression_prompt => (
  is => 'ro',
  isa => 'Str',
  lazy => 1,
  default => sub {
    'You are a conversation summarizer. Summarize the following conversation '
    . 'between a user and an AI assistant. Preserve all key facts, decisions, '
    . 'action items, file names, code references, and important context. '
    . 'Be concise but complete. The summary will replace the conversation '
    . 'history, so the assistant must be able to continue naturally.'
  },
);


has compression_engine => (
  is => 'ro',
  predicate => 'has_compression_engine',
);


has session_history => (
  is => 'ro',
  isa => 'ArrayRef',
  default => sub { [] },
);


has _last_prompt_tokens => (
  is => 'rw',
  isa => 'Int',
  predicate => 'has_last_prompt_tokens',
);

has _injections => (
  is => 'ro',
  isa => 'ArrayRef',
  default => sub { [] },
);

has on_iteration => (
  is => 'rw',
  isa => 'CodeRef',
  predicate => 'has_on_iteration',
);


has metrics => (
  is => 'rw',
  isa => 'HashRef',
  default => sub { {
    raids => 0, iterations => 0, tool_calls => 0, time_ms => 0,
  } },
);


has langfuse_trace_name => (
  is => 'ro',
  isa => 'Str',
  default => 'raid',
);


has langfuse_user_id => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_langfuse_user_id',
);


has langfuse_session_id => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_langfuse_session_id',
);


has langfuse_tags => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  predicate => 'has_langfuse_tags',
);


has langfuse_release => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_langfuse_release',
);


has langfuse_version => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_langfuse_version',
);


has langfuse_metadata => (
  is => 'ro',
  isa => 'HashRef',
  predicate => 'has_langfuse_metadata',
);


has raider_mcp => (
  is => 'ro',
  predicate => 'has_raider_mcp',
);


has on_ask_user => (
  is => 'rw',
  isa => 'CodeRef',
  predicate => 'has_on_ask_user',
);


has on_pause => (
  is => 'rw',
  isa => 'CodeRef',
  predicate => 'has_on_pause',
);


has on_wait_for => (
  is => 'rw',
  isa => 'CodeRef',
  predicate => 'has_on_wait_for',
);


has _continuation => (
  is => 'rw',
  predicate => 'has_continuation',
  clearer => 'clear_continuation',
);

# A requested cancel (ADR 0009): the flag, and a future completed on the
# loop that the waits of a raid race against.
has cancel_requested => (
  is       => 'ro',
  isa      => 'Bool',
  init_arg => undef,
  default  => 0,
  writer   => '_set_cancel_requested',
);

has _cancel_f => (
  is       => 'rw',
  init_arg => undef,
  lazy     => 1,
  default  => sub { Future->new },
  clearer  => '_clear_cancel_f',
);


sub cancel {
  my ( $self ) = @_;
  return if $self->cancel_requested;
  $self->_set_cancel_requested(1);
  # Only once a raid has waited on the loop is there a wait to wake up.
  syswrite $self->_cancel_wake->{write}, 'c' if $self->_has_cancel_wake;
  return;
}

# A pipe on the raid's loop (ADR 0016: one loop): cancel writes to it, and
# the loop completes the cancel future. A signal alone does not wake the
# loop: IO::Async::Loop::Poll polls again after EINTR, with the same timeout.
has _cancel_wake => (
  is        => 'ro',
  init_arg  => undef,
  lazy      => 1,
  builder   => '_build_cancel_wake',
  predicate => '_has_cancel_wake',
);

sub _build_cancel_wake {
  my ( $self ) = @_;
  my ( $read, $write ) = IO::Async::OS->pipepair or croak "Raider cancel pipe: $!";
  $write->blocking(0);
  weaken(my $weak = $self);
  my $handle = IO::Async::Handle->new(
    read_handle   => $read,
    on_read_ready => sub {
      sysread $read, my $buffer, 512;
      my $raider = $weak or return;
      my $f = $raider->_cancel_f;
      $f->done if $raider->cancel_requested && !$f->is_ready;
    },
  );
  my $engine = $self->engine;
  ( ( $engine->can('async_loop') && $engine->async_loop ) || IO::Async::Loop->new )->add($handle);
  return { write => $write, handle => $handle };
}

# The cancel pipe leaves the loop with the raider; at global destruction
# the process ends anyway.
sub DEMOLISH {
  my ( $self, $in_global_destruction ) = @_;
  return if $in_global_destruction || !$self->_has_cancel_wake;
  my $wake = $self->_cancel_wake;
  my $handle = $wake->{handle} or return;
  $handle->loop->remove($handle) if $handle->loop;
  $handle->close;
  close $wake->{write} if $wake->{write};
  return;
}

# The future $f, or nothing as soon as a cancel is requested: then $f is
# cancelled.
sub _until_cancelled {
  my ( $self, $f ) = @_;
  $self->_cancel_wake;   # on the loop before the raid waits
  my $cancel_f = $self->_cancel_f;
  $cancel_f->done if $self->cancel_requested && !$cancel_f->is_ready;
  return Future->wait_any($f, $cancel_f->without_cancel);
}


sub clear_cancel {
  my ( $self ) = @_;
  $self->_set_cancel_requested(0);
  $self->_clear_cancel_f;
  return;
}

# Ends the cancel request when a raid (or respond) has ended.
sub _end_raid {
  my ( $self, $f ) = @_;
  return $f->on_ready(sub { $self->clear_cancel });
}

# The result of a raid stopped by a cancel, metrics finalized as for abort.
sub _cancelled_result {
  my ( $self, $state ) = @_;
  my $m = $self->metrics;
  $m->{iterations} += ${ $state->{raid_iterations} };
  $m->{tool_calls} += ${ $state->{raid_tool_calls} };
  $m->{time_ms}    += tv_interval($state->{t0}) * 1000;
  return Langertha::Raider::Result->cancelled('Cancelled');
}

# Whether a cancel cut off the tool call $call_f: it was abandoned, or it
# ended with an error after the cancel was requested -- ended by the
# canceller, as a tool subprocess the CLI terminates. A call that succeeds
# keeps its result.
sub _cut_off {
  my ( $self, $call_f, $result ) = @_;
  return 1 unless $call_f->is_done;
  return $self->cancel_requested && ref $result eq 'HASH' && $result->{isError} ? 1 : 0;
}

# The result of a tool call cut off by a cancel.
sub _cancelled_tool_result {
  my ( $self, $name ) = @_;
  return {
    content   => [{ type => 'text', text => "Tool call '$name' was cancelled." }],
    isError   => JSON->true,
    cancelled => 1,
  };
}

has tools => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  default => sub { [] },
);


has mcp_catalog => (
  is => 'ro',
  isa => 'HashRef',
  default => sub { {} },
);


has engine_catalog => (
  is => 'ro',
  isa => 'HashRef',
  default => sub { {} },
);


has _active_engine => (
  is => 'rw',
  predicate => '_has_active_engine',
  clearer => '_clear_active_engine',
);

has _active_engine_name => (
  is => 'rw',
  isa => 'Maybe[Str]',
  default => undef,
);

has _active_catalog_mcps => (
  is => 'ro',
  isa => 'HashRef',
  default => sub { {} },
);

has _tools_dirty => (
  is => 'rw',
  isa => 'Bool',
  default => 0,
);

# The gate step of ADR 0005's one execution path ("check policy", k121): a
# CodeRef the code that builds the raider hands in. Every tool call about to
# run -- after plugin_before_tool_call and the inputSchema check -- is put to it
# as its canonical call:
#   $gate->( $raider, { name => ..., source => ..., arguments => ... } )
# source is where the call runs: 'raider' (self-tools), 'inline', 'engine:N'
# (the engine's Nth MCP server), 'catalog:NAME'; undef for a tool no source
# offers. It answers { verdict => 'allow' }, { verdict => 'deny', reason => ... }
# or { verdict => 'ask', reason => ... }. Without a gate every call runs.
# Read-only and constructor-only on purpose: nothing a raid carries -- model
# output, a plugin, a manifest -- sets or changes it (ADR 0005: permissions
# never come from prompts). Internal (ADR 0017); no policy format yet.
has _tool_gate => (
  is => 'ro',
  isa => 'CodeRef',
  predicate => '_has_tool_gate',
);

has _inline_mcp => (
  is => 'rw',
  predicate => 'has_inline_mcp',
);

has embedding_engine => (
  is => 'ro',
  predicate => 'has_embedding_engine',
);


has no_session_embeddings => (
  is => 'ro',
  default => sub { 0 },
);


has _session_embeddings => (
  is => 'ro',
  isa => 'ArrayRef',
  default => sub { [] },
);

# The in-flight simple_embedding_f futures of _embed_session_slot, keyed by
# refaddr. Held here so none is lost to GC mid-request; each removes itself
# when ready, clear_session_history cancels the rest.
has _pending_embeddings => (
  is => 'ro',
  isa => 'HashRef',
  default => sub { {} },
);

sub BUILD {
  my ( $self ) = @_;

  # Auto-activate catalog MCPs with auto => 1
  for my $name (keys %{$self->mcp_catalog}) {
    my $entry = $self->mcp_catalog->{$name};
    if ($entry->{auto}) {
      $self->_active_catalog_mcps->{$name} = $entry->{server};
    }
  }
}

sub clear_history {
  my ( $self ) = @_;
  $self->history([]);
  splice @{$self->_injections};
  return $self;
}


sub clear_session_history {
  my ( $self ) = @_;
  splice @{$self->session_history};
  splice @{$self->_session_embeddings};
  # Their vectors would belong to entries that are gone: stop the requests.
  my $pending = $self->_pending_embeddings;
  my @inflight = values %$pending;
  %$pending = ();
  $_->cancel for grep { !$_->is_ready } @inflight;
  return $self;
}


sub add_history {
  my ( $self, $role, $content ) = @_;
  push @{$self->history}, { role => $role, content => $content };
  return $self;
}


sub add_session_history {
  my ( $self, @entries ) = @_;
  $self->_push_session_history(@entries);
  return $self;
}


sub inject {
  my ( $self, @messages ) = @_;
  push @{$self->_injections}, @messages;
  return $self;
}


sub reset {
  my ( $self ) = @_;
  $self->clear_history;
  $self->_clear_active_engine;
  $self->_active_engine_name(undef);
  $self->metrics({
    raids => 0, iterations => 0, tool_calls => 0, time_ms => 0,
  });
  return $self;
}


sub active_engine {
  my ($self) = @_;
  return $self->_has_active_engine ? $self->_active_engine : $self->engine;
}


sub active_engine_name {
  my ($self) = @_;
  return $self->_active_engine_name;
}


sub switch_engine {
  my ($self, $name) = @_;
  croak "Engine '$name' not found in engine_catalog"
    unless exists $self->engine_catalog->{$name};
  my $entry = $self->engine_catalog->{$name};
  my $engine = $entry->{engine} // $self->engine;
  $self->_active_engine($engine);
  $self->_active_engine_name($name);
  $self->_tools_dirty(1);
  return $engine;
}


sub reset_engine {
  my ($self) = @_;
  $self->_clear_active_engine;
  $self->_active_engine_name(undef);
  $self->_tools_dirty(1);
  return $self->engine;
}


sub engine_info {
  my ($self) = @_;
  my $engine = $self->active_engine;
  return {
    name  => $self->_active_engine_name // 'default',
    class => ref $engine,
    model => $engine->can('chat_model') ? $engine->chat_model : undef,
  };
}


sub list_engines {
  my ($self) = @_;
  my %list;
  $list{default} = {
    engine => $self->engine,
    active => !$self->_has_active_engine,
  };
  for my $name (keys %{$self->engine_catalog}) {
    my $entry = $self->engine_catalog->{$name};
    $list{$name} = {
      engine      => $entry->{engine} // $self->engine,
      description => $entry->{description},
      active      => (defined $self->_active_engine_name && $self->_active_engine_name eq $name),
    };
  }
  return \%list;
}


sub add_engine {
  my ( $self, $name, %opts ) = @_;
  $self->engine_catalog->{$name} = \%opts;
  $self->_tools_dirty(1);
  return;
}


sub remove_engine {
  my ( $self, $name ) = @_;
  croak "Engine '$name' not found in engine_catalog"
    unless exists $self->engine_catalog->{$name};
  if (defined $self->_active_engine_name && $self->_active_engine_name eq $name) {
    $self->reset_engine;
  }
  delete $self->engine_catalog->{$name};
  $self->_tools_dirty(1);
  return;
}


async sub compress_history_f {
  my ( $self ) = @_;
  my @history = @{$self->history};
  return unless @history;

  my $engine = $self->has_compression_engine
    ? $self->compression_engine : $self->engine;

  my @messages = (
    { role => 'system', content => $self->compression_prompt },
    @history,
    { role => 'user', content => 'Provide a concise summary.' },
  );

  my $request = $engine->chat_request(\@messages);
  my $response = await $engine->async_request_f($request);

  # Read the summary through the engine's public chat_response (core ADR 0028),
  # the parser chat_f uses: an error carried in a 200 body croaks instead of
  # yielding '' silently, and Gemini thought parts / <think> tags stay out of the
  # text -- the same reasons the tool loop reads its replies via
  # tool_loop_response (karr k85). This is a plain (non-tool) chat, so
  # chat_response is the right hook, not tool_loop_response. A duck-typed engine
  # that lacks chat_response (the in-process test fixtures) falls back to the
  # legacy response_text_content, which never croaks.
  my $summary;
  if ( $engine->can('chat_response') ) {
    $summary = $engine->chat_response($response)->content // '';
  } else {
    my $data = $engine->parse_response($response);
    $summary = $engine->response_text_content($data);
  }

  # Replace working history with summary
  $self->history([
    { role => 'assistant', content => $summary },
  ]);

  # Mark compression event in session_history — through the pusher, so the
  # marker gets its embedding slot like every other message.
  $self->_push_session_history({
    role => 'system',
    content => '[Context compressed — history summarized]',
  });

  return $summary;
}


sub compress_history {
  my ( $self ) = @_;
  return $self->compress_history_f->get;
}


# --- Session history rendering (karr #96) ---
#
# session_history holds whatever the engine's format_tool_results() put on the
# wire, so an element's shape follows the engine's tool_wire_format: only the
# openai / ollama / hermes dialects give every element a {role} plus a
# plain-string {content}. Anthropic content is an ArrayRef of blocks, Gemini
# keeps its blocks under {parts}, and OpenAI Responses items have no {role} at
# all — they are discriminated by {type} (function_call, function_call_output,
# reasoning). Both readers of the history (the MCP tool registered by
# register_session_history_tool and the raider_session_history self-tool)
# render through the helpers below, so they cannot drift apart again.

my $history_json = JSON->new->canonical(1)->allow_nonref(1);

# Compact a tool-call argument payload for display: an already-serialized
# argument string (OpenAI, Responses) passes through, a structure (Anthropic
# input, Gemini args) gets canonical JSON.
sub _render_history_args {
  my ( $args ) = @_;
  return '' unless defined $args;
  return $args unless ref $args;
  my $encoded = eval { $history_json->encode($args) };
  return defined $encoded ? $encoded : "$args";
}

sub _render_history_tool_call {
  my ( $name, $args ) = @_;
  return sprintf 'tool_call %s(%s)',
    ( defined $name && length $name ? $name : '?' ),
    _render_history_args($args);
}

# Flatten one wire block to text. The text rule is the one
# Langertha::ToolResult applies for the plain-text formats (to_gemini /
# to_hermes): a text part carries its text under ->{text}. Unlike a wire
# serializer this renderer must not swallow the non-text blocks — a tool call
# is named, never dropped, so an element that is only a tool call still shows
# up as something readable.
sub _render_history_block {
  my ( $block ) = @_;
  return '' unless defined $block;
  return "$block" unless ref $block eq 'HASH';

  return $block->{text}     if defined $block->{text}     && !ref $block->{text};
  return $block->{thinking} if defined $block->{thinking} && !ref $block->{thinking};

  # Gemini parts key their call/response by name instead of carrying a {type}.
  if ( ref $block->{functionCall} eq 'HASH' ) {
    return _render_history_tool_call(
      $block->{functionCall}{name}, $block->{functionCall}{args} );
  }
  if ( ref $block->{functionResponse} eq 'HASH' ) {
    my $response = $block->{functionResponse}{response};
    # A bare {result} is Langertha's string form; any other hash is the tool's
    # MCP structuredContent (langertha k336) and renders whole, as JSON.
    my $result = ref $response eq 'HASH'
      && keys %$response == 1 && exists $response->{result}
      ? $response->{result} : $response;
    # Gemini 3 carries a tool-result image beside the result string in
    # functionResponse.parts[].inlineData (langertha k344).
    return 'tool_result: ' . join "\n", grep { length }
      ( defined $result && !ref $result ? $result : _render_history_args($result) ),
      _render_history_payload_value( $block->{functionResponse}{parts} );
  }
  # An image is named, never dumped as base64.
  return '[image]'
    if ref $block->{inlineData} eq 'HASH'
    && ( $block->{inlineData}{mimeType} // '' ) =~ m{^image/};
  # Any other inlineData (a tool-result PDF, langertha k361) is named by its
  # MIME type, never dumped.
  return '[document] ' . $block->{inlineData}{mimeType}
    if ref $block->{inlineData} eq 'HASH'
    && defined $block->{inlineData}{mimeType} && length $block->{inlineData}{mimeType};

  my $type = $block->{type} // '';

  # Tool invocations: Anthropic tool_use, Responses function_call, and the
  # OpenAI/Ollama {function=>{...}} entry from an assistant echo.
  return _render_history_tool_call( $block->{name}, $block->{input} )
    if $type eq 'tool_use';
  return _render_history_tool_call( $block->{name}, $block->{arguments} )
    if $type eq 'function_call';
  return _render_history_tool_call(
    $block->{function}{name}, $block->{function}{arguments} )
    if ref $block->{function} eq 'HASH';

  # Tool results: Anthropic nests the MCP content array, the Responses item
  # carries the same payload JSON-encoded in {output} -- or, with an image,
  # as an input_text / input_image part array (langertha k344).
  if ( $type eq 'tool_result' || $type eq 'function_call_output' ) {
    return 'tool_result: '
      . _render_history_payload_value(
          defined $block->{output} ? $block->{output} : $block->{content} );
  }
  # Responses input_image, Anthropic image (langertha k326).
  return '[image]' if $type eq 'input_image' || $type eq 'image';
  # Responses input_file (a tool-result PDF, langertha k361): named by its
  # filename, never the file_data / data: URL.
  return defined $block->{filename} && !ref $block->{filename} && length $block->{filename}
    ? '[document] ' . $block->{filename} : '[document]'
    if $type eq 'input_file';

  # Anthropic document (langertha k326): a text source gives its text, a
  # content source (Citations custom content) its chunks, any other source
  # (base64 PDF, url, file) is named, never dumped. The optional context the
  # model reads beside it gets a line of its own.
  if ( $type eq 'document' ) {
    my $source = ref $block->{source} eq 'HASH' ? $block->{source} : {};
    my $source_type = $source->{type} // '';
    my $has_title = defined $block->{title} && length $block->{title};
    my $marker    = $has_title ? '[document] ' . $block->{title} : '[document]';
    my $text = $source_type eq 'text'    ? $source->{data} // ''
      : $source_type eq 'content' ? _render_history_payload_value( $source->{content} )
      : '';
    my $context = defined $block->{context} && !ref $block->{context}
      && length $block->{context} ? '[context] ' . $block->{context} : '';
    return join "\n", grep { length }
      ( $has_title || !length $text ? $marker : () ), $context, $text;
  }
  # Anthropic search_result: title and source URL, then its text blocks.
  if ( $type eq 'search_result' ) {
    return join "\n", grep { length }
      join( ' ', grep { defined && length } '[search_result]', $block->{title},
        ( defined $block->{source} && !ref $block->{source}
          ? '<' . $block->{source} . '>' : () ) ),
      _render_history_payload_value( $block->{content} );
  }

  # Unknown block: name it by its discriminator rather than dropping it.
  my $rest = _render_history_payload_value( $block->{content} );
  return length $rest
    ? ( length $type ? "<$type> $rest" : $rest )
    : ( length $type ? "<$type>" : '<block>' );
}

# Render a {content} / {parts} / {summary} / {tool_calls} payload: a plain
# string as-is, an ArrayRef of blocks flattened block by block.
sub _render_history_payload_value {
  my ( $value ) = @_;
  return '' unless defined $value;
  return "$value" unless ref $value;
  return join( "\n", grep { length } map { _render_history_block($_) } @$value )
    if ref $value eq 'ARRAY';
  return _render_history_block($value) if ref $value eq 'HASH';
  return "$value";
}

# The readable body of one history element, without its role/type label. Also
# what the query/search filters match against, so a filter reaches the text of
# an Anthropic block or a Responses item too.
sub _render_history_payload {
  my ( $entry ) = @_;
  return '' unless defined $entry;
  return "$entry" unless ref $entry eq 'HASH';

  my @body;
  for my $key (qw( content parts summary tool_calls )) {
    push @body, _render_history_payload_value( $entry->{$key} )
      if defined $entry->{$key};
  }
  # Items that are a block in their own right (Responses function_call /
  # function_call_output) carry no content payload at all.
  unless (@body) {
    my $block = _render_history_block($entry);
    # A bare "<type>" marker would only repeat the label the caller prints.
    push @body, $block unless $block eq '<' . ( $entry->{type} // '' ) . '>';
  }

  return join "\n", grep { length } @body;
}

sub _render_history_entry {
  my ( $entry ) = @_;
  return '' unless defined $entry;
  return "$entry" unless ref $entry eq 'HASH';

  my $label = $entry->{role} // $entry->{type} // 'message';
  my $body  = _render_history_payload($entry);
  return length $body ? "[$label] $body" : "[$label]";
}

sub _render_session_history {
  my ( @hist ) = @_;
  return join "\n\n", map { _render_history_entry($_) } @hist;
}

sub register_session_history_tool {
  my ( $self, $server ) = @_;
  $server->tool(
    name => 'session_history',
    description => 'Retrieve the full session history including tool calls.',
    input_schema => {
      type => 'object',
      properties => {
        query   => { type => 'string', description => 'Filter messages containing this text' },
        last_n  => { type => 'integer', description => 'Return only the last N messages' },
      },
    },
    code => sub {
      my ( $tool, $args ) = @_;
      my @hist = @{$self->session_history};
      if (my $q = $args->{query}) {
        @hist = grep { _render_history_payload($_) =~ /\Q$q/i } @hist;
      }
      if (my $n = $args->{last_n}) {
        @hist = @hist[-$n..-1] if @hist > $n;
      }
      my $text = _render_session_history(@hist);
      $tool->text_result($text || 'No messages in session history.');
    },
  );
}


sub _langfuse_model_parameters {
  my ( $self, $engine ) = @_;
  my $e = $engine // $self->active_engine;
  my %p;
  $p{temperature} = $e->temperature if $e->can('has_temperature') && $e->has_temperature;
  $p{max_tokens} = $e->get_response_size if $e->can('get_response_size') && $e->get_response_size;
  return keys %p ? \%p : undef;
}

sub _self_tool_enabled {
  my ( $self, $tool_name ) = @_;
  return 0 unless $self->has_raider_mcp;
  my $cfg = $self->raider_mcp;
  return 1 if !ref $cfg; # truthy scalar = all tools
  return $cfg->{$tool_name} ? 1 : 0 if ref $cfg eq 'HASH';
  return 0;
}

sub _self_tool_definitions {
  my ( $self ) = @_;
  my @tools;

  if ($self->_self_tool_enabled('ask_user')) {
    push @tools, {
      name => 'raider_ask_user',
      description => 'Ask the user a question and wait for their answer. Use this when you need clarification or a decision from the user.',
      inputSchema => {
        type => 'object',
        properties => {
          question => { type => 'string', description => 'The question to ask the user' },
          options  => { type => 'array', items => { type => 'string' }, description => 'Optional list of choices for the user' },
        },
        required => ['question'],
      },
    };
  }

  if ($self->_self_tool_enabled('wait')) {
    push @tools, {
      name => 'raider_wait',
      description => 'Wait for a specified number of seconds before continuing.',
      inputSchema => {
        type => 'object',
        properties => {
          seconds => { type => 'number', description => 'Number of seconds to wait' },
          reason  => { type => 'string', description => 'Why you are waiting' },
        },
        required => ['seconds'],
      },
    };
  }

  if ($self->_self_tool_enabled('wait_for')) {
    push @tools, {
      name => 'raider_wait_for',
      description => 'Wait for an external condition to be met. The condition is evaluated by the host application.',
      inputSchema => {
        type => 'object',
        properties => {
          condition => { type => 'string', description => 'Description of the condition to wait for' },
          args      => { type => 'object', description => 'Additional arguments for the condition check' },
          timeout   => { type => 'number', description => 'Timeout in seconds' },
        },
        required => ['condition'],
      },
    };
  }

  if ($self->_self_tool_enabled('pause')) {
    push @tools, {
      name => 'raider_pause',
      description => 'Pause execution and return control to the user. The user can resume later with respond_f.',
      inputSchema => {
        type => 'object',
        properties => {
          reason => { type => 'string', description => 'Why you are pausing' },
        },
      },
    };
  }

  if ($self->_self_tool_enabled('abort')) {
    push @tools, {
      name => 'raider_abort',
      description => 'Abort the current raid. Use only when the task cannot be completed.',
      inputSchema => {
        type => 'object',
        properties => {
          reason => { type => 'string', description => 'Why you are aborting' },
        },
      },
    };
  }

  if ($self->_self_tool_enabled('session_history')) {
    push @tools, {
      name => 'raider_session_history',
      description => 'Search or retrieve the full session history including tool calls and results.',
      inputSchema => {
        type => 'object',
        properties => {
          query   => { type => 'string', description => 'Filter messages containing this text' },
          last_n  => { type => 'integer', description => 'Return only the last N messages' },
          search  => { type => 'string', description => 'Semantic search query (requires embedding engine)' },
        },
      },
    };
  }

  if ($self->_self_tool_enabled('manage_mcps')) {
    push @tools, {
      name => 'raider_manage_mcps',
      description => 'List, activate, or deactivate MCP tool servers from the catalog.',
      inputSchema => {
        type => 'object',
        properties => {
          action => { type => 'string', enum => ['list', 'activate', 'deactivate'], description => 'Action to perform' },
          name   => { type => 'string', description => 'Name of the MCP server (for activate/deactivate)' },
        },
        required => ['action'],
      },
    };
  }

  if ($self->_self_tool_enabled('switch_engine') && keys %{$self->engine_catalog}) {
    my @names = ('default', sort keys %{$self->engine_catalog});
    push @tools, {
      name => 'raider_switch_engine',
      description => 'Switch to a different AI engine from the catalog. Use "default" to reset to the original engine.',
      inputSchema => {
        type => 'object',
        properties => {
          name => {
            type => 'string',
            enum => \@names,
            description => 'Name of the engine to switch to',
          },
        },
        required => ['name'],
      },
    };
  }

  return \@tools;
}

async sub _execute_self_tool_f {
  my ( $self, $name, $input ) = @_;
  my $short = $name;
  $short =~ s/^raider_//;

  if ($short eq 'ask_user') {
    my $question = $input->{question};
    my $options  = $input->{options};
    if ($self->has_on_ask_user) {
      my $answer = $self->on_ask_user->($question, $options);
      return { type => 'result', content => [{ type => 'text', text => "$answer" }] };
    }
    return { type => 'question', question => $question, options => $options };
  }

  if ($short eq 'wait') {
    my $seconds = $input->{seconds} // 1;
    return { type => 'wait', seconds => $seconds, reason => $input->{reason} };
  }

  if ($short eq 'wait_for') {
    croak "No on_wait_for callback configured" unless $self->has_on_wait_for;
    my $result = $self->on_wait_for->($input->{condition}, $input->{args});
    return { type => 'result', content => [{ type => 'text', text => "$result" }] };
  }

  if ($short eq 'pause') {
    my $reason = $input->{reason} // '';
    if ($self->has_on_pause) {
      $self->on_pause->($reason);
      return { type => 'result', content => [{ type => 'text', text => "Resumed after pause." }] };
    }
    return { type => 'pause', reason => $reason };
  }

  if ($short eq 'abort') {
    return { type => 'abort', reason => $input->{reason} // 'Agent aborted' };
  }

  if ($short eq 'session_history') {
    return { type => 'result', content => [{ type => 'text', text => await $self->_query_session_history_f($input) }] };
  }

  if ($short eq 'manage_mcps') {
    return { type => 'result', content => [{ type => 'text', text => $self->_manage_mcps($input) }] };
  }

  if ($short eq 'switch_engine') {
    return { type => 'result', content => [{ type => 'text', text => $self->_switch_engine_tool($input) }] };
  }

  die "Unknown self-tool: $name";
}

async sub _query_session_history_f {
  my ( $self, $args ) = @_;
  my $search = $args->{search};

  # Semantic search via embeddings. The vector of history element $i is
  # _session_embeddings->[$i], so a length mismatch means the two arrays drifted
  # apart (session_history is a public ArrayRef, code outside _push_session_history
  # can splice it) — searching a drifted index would answer with the wrong
  # message, so degrade to the text search instead of lying. A failed query
  # embedding degrades the same way.
  my $query_vec;
  my $engine = $search ? $self->_get_embedding_engine : undef;
  if ($engine && @{$self->_session_embeddings} == @{$self->session_history}) {
    ( $query_vec ) = await Future->call(sub { $engine->simple_embedding_f($search) })
      ->else(sub {
        $log->warnf('[%s] session history search embedding failed, using text match: %s',
          __PACKAGE__, $_[0]);
        return Future->done;
      });
  }

  # Read after the await: the history may have changed meanwhile, and more
  # background embeddings may have landed.
  my @hist  = @{$self->session_history};
  my $slots = $self->_session_embeddings;

  if ($search) {
    # A slot whose embedding is still in flight (or failed) is undef and simply
    # not scored: the search ranks what is embedded now and never waits.
    if ($query_vec && @$slots == @hist) {
      my @scored;
      for my $i (0..$#hist) {
        my $emb = $slots->[$i];
        next unless $emb;
        my $sim = _cosine_similarity($query_vec, $emb);
        push @scored, { idx => $i, score => $sim };
      }
      @scored = sort { $b->{score} <=> $a->{score} } @scored;
      @scored = @scored[0..9] if @scored > 10;
      @hist = map { $hist[$_->{idx}] } @scored;
    } else {
      # Fallback to text grep
      @hist = grep { _render_history_payload($_) =~ /\Q$search/i } @hist;
    }
  }

  if (my $q = $args->{query}) {
    @hist = grep { _render_history_payload($_) =~ /\Q$q/i } @hist;
  }
  if (my $n = $args->{last_n}) {
    @hist = @hist[-$n..-1] if @hist > $n;
  }

  my $text = _render_session_history(@hist);
  return $text || 'No messages in session history.';
}

sub _manage_mcps {
  my ( $self, $args ) = @_;
  my $action = $args->{action};

  if ($action eq 'list') {
    my @lines;
    for my $name (sort keys %{$self->mcp_catalog}) {
      my $entry = $self->mcp_catalog->{$name};
      my $active = exists $self->_active_catalog_mcps->{$name} ? 'ACTIVE' : 'inactive';
      my $desc = $entry->{description} // '';
      push @lines, "- $name [$active] $desc";
    }
    return join("\n", @lines) || 'No MCP servers in catalog.';
  }

  if ($action eq 'activate') {
    my $name = $args->{name} or return "Error: name required for activate";
    my $entry = $self->mcp_catalog->{$name}
      or return "Error: '$name' not found in catalog";
    $self->_active_catalog_mcps->{$name} = $entry->{server};
    $self->_tools_dirty(1);
    return "Activated MCP server '$name'.";
  }

  if ($action eq 'deactivate') {
    my $name = $args->{name} or return "Error: name required for deactivate";
    delete $self->_active_catalog_mcps->{$name};
    $self->_tools_dirty(1);
    return "Deactivated MCP server '$name'.";
  }

  return "Error: unknown action '$action'";
}

sub _switch_engine_tool {
  my ( $self, $args ) = @_;
  my $name = $args->{name} or return "Error: name required";

  if ($name eq 'default') {
    $self->reset_engine;
    my $info = $self->engine_info;
    return "Switched to default engine ($info->{class}, model: $info->{model}).";
  }

  my $entry = $self->engine_catalog->{$name}
    or return "Error: '$name' not found in engine catalog";
  $self->switch_engine($name);
  my $info = $self->engine_info;
  return "Switched to engine '$name' ($info->{class}, model: $info->{model}).";
}

sub _get_embedding_engine {
  my ( $self ) = @_;
  return undef if $self->no_session_embeddings;
  return $self->embedding_engine if $self->has_embedding_engine;
  my $engine = $self->engine;
  return $engine if $engine->does('Langertha::Role::Embedding');
  return undef;
}

sub _cosine_similarity {
  my ( $a, $b ) = @_;
  my $dot = 0;
  my $na  = 0;
  my $nb  = 0;
  my $len = @$a < @$b ? @$a : @$b;
  for my $i (0..$len-1) {
    $dot += $a->[$i] * $b->[$i];
    $na  += $a->[$i] * $a->[$i];
    $nb  += $b->[$i] * $b->[$i];
  }
  my $denom = sqrt($na) * sqrt($nb);
  return $denom > 0 ? $dot / $denom : 0;
}

sub _push_session_history {
  my ( $self, @msgs ) = @_;
  push @{$self->session_history}, @msgs;

  # The embeddings are computed in the background (simple_embedding_f on the
  # raid's loop, k24): the raid never waits for them, so a slow embedding
  # endpoint, or one served by this same reactor, cannot stall it.
  #
  # _query_session_history_f looks the vector of history element $i up as
  # _session_embeddings->[$i], so this reserves EXACTLY one slot per message,
  # right now and synchronously — undef until its embedding lands, and for good
  # when a message has no embeddable text or its embedding fails. Skipping a
  # slot shifts every later vector onto the wrong message and the similarity
  # search silently answers with that one.
  my $slots = $self->_session_embeddings;
  my $first = @$slots;
  push @$slots, (undef) x scalar @msgs;

  my $engine = $self->_get_embedding_engine or return;
  for my $n (0..$#msgs) {
    # The rendered payload, not the raw {content}: an element's shape follows
    # the engine's tool_wire_format, so {content} is an ArrayRef of blocks on
    # anthropic and absent entirely on gemini ({parts}) and on responses
    # envelope items. It is also the text the grep fallback in
    # _query_session_history_f matches, so both search modes see one history
    # element the same way.
    my $text = _render_history_payload($msgs[$n]);
    $self->_embed_session_slot($engine, $first + $n, $msgs[$n], $text) if length $text;
  }

  return;
}

# Fires the embedding of one history entry and fills slot $i when it lands.
# By then the history may have been cleared, spliced or refilled, so the vector
# is stored only while slot $i still belongs to the very same entry ($msg is
# held by this closure, so its address cannot be reused meanwhile). A failure
# is logged and leaves the slot undef; it never reaches the raid.
sub _embed_session_slot {
  my ( $self, $engine, $i, $msg, $text ) = @_;
  weaken( my $weak = $self );
  my $f = Future->call(sub { $engine->simple_embedding_f($text) });
  $f->on_done(sub {
    my ( $vec ) = @_;
    my $raider = $weak or return;
    return unless $i < @{$raider->_session_embeddings};
    my $entry = $raider->session_history->[$i];
    my $same = ref $msg
      ? ref $entry && refaddr($entry) == refaddr($msg)
      : defined $entry && !ref $entry && $entry eq $msg;
    $raider->_session_embeddings->[$i] = $vec if $same;
  });
  $f->on_fail(sub {
    $log->warnf('[%s] session history embedding failed: %s', __PACKAGE__, $_[0]);
  });
  return if $f->is_ready;

  my $key = refaddr $f;
  $self->_pending_embeddings->{$key} = $f;
  $f->on_ready(sub {
    my $raider = $weak or return;
    delete $raider->_pending_embeddings->{$key};
  });
  return;
}

sub raid {
  my ( $self, @messages ) = @_;
  return $self->raid_f(@messages)->get;
}

async sub run_f {
  my ( $self, $ctx ) = @_;
  $ctx = Langertha::RunContext->new(input => $ctx)
    unless blessed($ctx) && $ctx->isa('Langertha::RunContext');

  my $input = $ctx->input;
  my @messages = ref($input) eq 'ARRAY' ? @{$input} : ($input);
  @messages = grep { defined } @messages;

  my $result = await $self->raid_f(@messages);

  if ($result->is_final && $result->has_text) {
    $ctx->input($result->text);
    $ctx->state->{last_output} = $result->text;
  }
  $ctx->state->{last_result_type} = $result->type;
  $ctx->state->{last_result} = $result->as_hash if $result->can('as_hash');
  $ctx->history($self->history) if $ctx->can('history');

  return $result->with_context($ctx);
}



async sub _gather_tools_f {
  my ( $self ) = @_;
  my $engine = $self->active_engine;
  my ( @all_tools, %tool_server_map, %tool_source, %seen );

  # A name offered by more than one source is sent to the provider once --
  # providers reject a request that declares one function twice -- and the
  # first source (in gather order) wins, as core's
  # Langertha::Role::Tools->_tool_loop_tools does across mcp_servers (karr k332).
  # Raider assembles its own tool set from four kinds of source, so it needs its
  # own dedup. Returns true when the tool was accepted, false when it was a
  # duplicate of an earlier source and dropped with a carp. $source is the
  # short name of the source the tool gate sees (k121).
  my $accept = sub {
    my ( $tool, $label, $source ) = @_;
    my $name = $tool->{name};
    if ( my $first = $seen{$name} ) {
      carp "" . ( ref $self ) . ": tool '$name' is offered by $first and $label; using the first";
      return 0;
    }
    $seen{$name} = $label;
    $tool_source{$name} = $source;
    push @all_tools, $tool;
    return 1;
  };

  # Engine MCP servers
  if ($engine->can('mcp_servers')) {
    my $no = 0;
    for my $mcp (@{$engine->mcp_servers}) {
      my $label = 'engine MCP server ' . ( ++$no ) . ' (' . ref($mcp) . ')';
      my $tools = await $mcp->list_tools;
      for my $tool (@$tools) {
        $tool_server_map{$tool->{name}} = $mcp if $accept->($tool, $label, 'engine:'.$no);
      }
    }
  }

  # Inline MCP
  if ($self->has_inline_mcp) {
    my $tools = await $self->_inline_mcp->list_tools;
    for my $tool (@$tools) {
      $tool_server_map{$tool->{name}} = $self->_inline_mcp
        if $accept->($tool, 'inline MCP', 'inline');
    }
  }

  # Active catalog MCPs
  for my $name (sort keys %{$self->_active_catalog_mcps}) {
    my $mcp = $self->_active_catalog_mcps->{$name};
    my $tools = await $mcp->list_tools;
    for my $tool (@$tools) {
      $tool_server_map{$tool->{name}} = $mcp
        if $accept->($tool, "catalog MCP '$name'", 'catalog:'.$name);
    }
  }

  # Self-tools (virtual — no MCP server mapping needed)
  if ($self->has_raider_mcp) {
    $accept->($_, 'raider self-tools', 'raider') for @{$self->_self_tool_definitions};
  }

  return ( \@all_tools, \%tool_server_map, \%tool_source );
}

async sub _initialize_inline_mcp_f {
  my ( $self ) = @_;
  return if $self->has_inline_mcp;

  # Collect inline tools + plugin tools
  my @all_inline;
  push @all_inline, @{$self->tools};
  for my $plugin (@{$self->plugin_instances}) {
    my $tools = $plugin->self_tools;
    push @all_inline, @$tools if $tools && @$tools;
  }
  return unless @all_inline;

  my $server = MCP::Server->new(name => 'raider-inline', version => '1.0');
  for my $tdef (@all_inline) {
    $server->tool(
      name         => $tdef->{name},
      description  => $tdef->{description},
      input_schema => $tdef->{input_schema} // $tdef->{inputSchema},
      code         => $tdef->{code},
    );
  }

  my $mcp = Net::Async::MCP->new(server => $server);
  ($self->engine->async_loop // IO::Async::Loop->new)->add($mcp);
  await $mcp->initialize;
  $self->_inline_mcp($mcp);
}

# One raid awaits the futures of every engine it may use, and one ->get drives
# exactly one IO::Async loop: engines on two loops hang the raid (core karr
# k228). An engine without a loop (sync fallback) counts as the process-wide
# IO::Async::Loop->new, like everywhere else in raider.
# Tradeoff: async_loop builds each engine's HTTP client now, so a sync-fallback warning may show at raid start.
sub _check_engine_loops {
  my ( $self ) = @_;
  my @engines = $self->_raid_engines;
  my $loop_of = sub {
    my ( $engine ) = @_;
    return ( $engine->can('async_loop') && $engine->async_loop ) || IO::Async::Loop->new;
  };
  my $loop = $loop_of->($engines[0][1]);
  for my $entry (@engines[1..$#engines]) {
    next if refaddr($loop_of->($entry->[1])) == refaddr($loop);
    croak "Raider $entry->[0] runs on a different event loop than engine; "
        . "a raid drives only one loop, so every engine of a raider must share it "
        . "(put their HTTP clients on the same IO::Async::Loop)";
  }
  return $loop;
}

# Every engine a raid may use, as [ name => engine ] pairs, engine first.
sub _raid_engines {
  my ( $self ) = @_;
  my @engines = ( [ engine => $self->engine ] );
  push @engines, [ compression_engine => $self->compression_engine ]
    if $self->has_compression_engine;
  # Its futures complete only while the raid's loop runs.
  push @engines, [ embedding_engine => $self->embedding_engine ]
    if $self->has_embedding_engine && !$self->no_session_embeddings;
  for my $name (sort keys %{$self->engine_catalog}) {
    my $engine = $self->engine_catalog->{$name}{engine} // next;
    push @engines, [ "engine_catalog '$name'" => $engine ];
  }
  return @engines;
}

# Net::Async::HTTP loads what a connection needs only when it opens one, and
# a load that dies there keeps the host's connection slot taken: every later
# request to the host -- the chat request after the session-history
# embedding -- waits forever (karr k107). Checked before the raid sends, a
# missing module is an error that names it. Only engines with an event loop
# and a url: the synchronous fallback connects through LWP.
sub _check_engine_connect {
  my ( $self ) = @_;
  for my $entry ($self->_raid_engines) {
    my ( $name, $engine ) = @$entry;
    next unless $engine->can('async_loop') && $engine->async_loop
      && $engine->can('url') && defined $engine->url;
    my $error = connect_error($engine->url) // next;
    croak "Raider $name: $error";
  }
  return;
}

sub raid_f {
  my ( $self, @messages ) = @_;
  return $self->_end_raid($self->_raid_f(@messages));
}

async sub _raid_f {
  my ( $self, @messages ) = @_;
  $self->_check_engine_loops;
  $self->_check_engine_connect;
  my $engine = $self->active_engine;
  my $t0 = [gettimeofday];
  my $langfuse = $engine->can('langfuse_enabled') && $engine->langfuse_enabled;
  my $trace_id;

  if ($langfuse) {
    my %trace_meta = (
      mission        => $self->has_mission ? $self->mission : undef,
      history_length => scalar @{$self->history},
    );
    if ($self->has_langfuse_metadata) {
      %trace_meta = (%trace_meta, %{$self->langfuse_metadata});
    }
    $trace_id = $engine->langfuse_trace(
      name     => $self->langfuse_trace_name,
      input    => \@messages,
      metadata => \%trace_meta,
      $self->has_langfuse_user_id    ? ( user_id    => $self->langfuse_user_id )    : (),
      $self->has_langfuse_session_id ? ( session_id => $self->langfuse_session_id ) : (),
      $self->has_langfuse_tags       ? ( tags       => $self->langfuse_tags )       : (),
      $self->has_langfuse_release    ? ( release    => $self->langfuse_release )    : (),
      $self->has_langfuse_version    ? ( version    => $self->langfuse_version )    : (),
    );
  }

  # Auto-compress if threshold exceeded
  if ($self->has_max_context_tokens && $self->has_last_prompt_tokens
      && $self->_last_prompt_tokens > $self->max_context_tokens * $self->context_compress_threshold) {
    await $self->compress_history_f();
  }

  # Plugin hook: transform input messages before raid
  for my $plugin (@{$self->plugin_instances}) {
    @messages = @{await $plugin->plugin_before_raid(\@messages)};
  }

  # Initialize inline MCP if tools defined
  await $self->_initialize_inline_mcp_f;

  # Gather tools from all sources
  my ( $all_tools, $tool_server_map, $tool_sources ) = await $self->_gather_tools_f;

  croak "No tools available (configure MCP servers, inline tools, or raider_mcp)"
    unless @$all_tools;

  my $formatted_tools = $engine->format_tools($all_tools);
  my $model_params = $langfuse ? $self->_langfuse_model_parameters($engine) : undef;

  # Build new user messages
  my @user_msgs = map {
    ref $_ ? $_ : { role => 'user', content => $_ }
  } @messages;

  # Push user messages to session_history
  $self->_push_session_history(@user_msgs);

  # Build full conversation: mission + history + new messages
  my @conversation;
  push @conversation, { role => 'system', content => $self->mission }
    if $self->has_mission;
  push @conversation, @{$self->history};
  push @conversation, @user_msgs;

  # Plugin hook: transform assembled conversation
  for my $plugin (@{$self->plugin_instances}) {
    @conversation = @{await $plugin->plugin_build_conversation(\@conversation)};
  }

  my $raid_iterations = 0;
  my $raid_tool_calls = 0;
  my @injected_history;

  # Package loop state for potential continuation
  my $state = {
    engine           => $engine,
    t0               => $t0,
    langfuse         => $langfuse,
    trace_id         => $trace_id,
    tool_server_map  => $tool_server_map,
    tool_sources     => $tool_sources,
    tool_schemas     => $self->_tool_schemas($all_tools),
    formatted_tools  => $formatted_tools,
    model_params     => $model_params,
    user_msgs        => \@user_msgs,
    conversation     => \@conversation,
    raid_iterations  => \$raid_iterations,
    raid_tool_calls  => \$raid_tool_calls,
    injected_history => \@injected_history,
    # The tool exchanges appended each iteration, tracked so in-loop compaction
    # can drop the oldest ones as whole units (karr k89).
    tool_segments    => [],
  };

  return await $self->_run_raid_loop($state, 1);
}

# Reads one tool-loop turn's reply. An engine that carries the public
# Langertha::Role::Tools->tool_loop_response hook (Langertha core from the
# release that added it) together with a real chat_response reads the reply the
# way core's own tool loops do: an error carried in a 200 body croaks instead of
# ending the raid silently with '', Gemini thought parts and <think> tags stay
# out of the final text, and a tool call whose arguments were cut off by the
# token limit is dropped from the run and from the assistant echo (core
# k321/k323/k324). A duck-typed engine that lacks either (the in-process test
# fixtures, or any backend on a core older than the hook) falls back to the
# legacy response_tool_calls / response_text_content readers, which never croak.
# Returns ( \@tool_calls, $final_text, $echo_data ): the calls are
# Langertha::ToolCall objects on the hook path and raw wire structures on the
# fallback (both understood by _tool_call_name_input and by format_tool_results),
# and $echo_data is the wire body to build the assistant echo from.
sub _read_tool_loop_reply {
  my ( $self, $engine, $data ) = @_;
  if ( $engine->can('tool_loop_response') && $engine->can('chat_response') ) {
    my $reply = $engine->tool_loop_response($data);
    my ( $calls, $echo_data ) = $engine->tool_loop_calls( $reply, $data );
    return ( $calls, $reply->content, $echo_data );
  }
  my $tool_calls = $engine->response_tool_calls($data);
  my $text       = $engine->response_text_content($data);
  ( $text ) = $engine->filter_think_content($text) if $engine->think_tag_filter;
  return ( $tool_calls, $text, $data );
}

# The tool name and decoded arguments of one call, whether it is the
# Langertha::ToolCall the tool_loop_response hook yields or the raw wire
# structure an engine's response_tool_calls located (the fallback path).
sub _tool_call_name_input {
  my ( $self, $engine, $tc ) = @_;
  return ( $tc->name, $tc->arguments ) if blessed $tc;
  return $engine->extract_tool_call($tc);
}

# The error result a call whose arguments the model did not send as valid JSON
# is answered with -- running the tool on the {} such a call decodes to is wrong
# (karr k345). undef for a call whose arguments decoded, and for a raw wire
# structure (the fallback path, where arguments_undecodable is not tracked). The
# text matches core's Langertha::Role::Tools->_undecodable_arguments_result, so
# the model sees the same error whichever loop ran it. A call whose arguments
# were cut off by the token limit was already dropped upstream by
# _read_tool_loop_reply (tool_loop_calls); this is the OTHER case -- a reply that
# did not hit its token limit but still sent arguments that do not decode.
sub _undecodable_tool_result {
  my ( $self, $tc ) = @_;
  return undef unless blessed $tc && $tc->arguments_undecodable;
  return {
    content => [{ type => 'text',
      text => "arguments are not valid JSON: " . ( $tc->arguments_error // 'not a JSON object' ) }],
    isError => JSON->true,
  };
}

# The inputSchema of every tool the raid offers, by name, from the tool set
# _gather_tools_f assembled -- so for a name several sources offer, the schema
# of the source that won and was shown to the model. MCP lists and the
# self-tools carry inputSchema; input_schema is taken too.
sub _tool_schemas {
  my ( $self, $all_tools ) = @_;
  return { map {
    ( $_->{name} => $_->{inputSchema} // $_->{input_schema} )
  } grep { ref $_ eq 'HASH' && defined $_->{name} } @$all_tools };
}

# The error result a call whose arguments clearly break its tool's inputSchema
# is answered with (a required key missing, a top-level property of the wrong
# type; Langertha::Raider::ToolArgs says what counts). undef when they pass,
# and for a tool without a known schema. Same shape as the bad-JSON result.
sub _invalid_args_tool_result {
  my ( $self, $state, $name, $input ) = @_;
  my $schema = $state->{tool_schemas}{$name // ''} or return undef;
  my @problems = tool_args_problems($schema, $input) or return undef;
  return {
    content => [{ type => 'text',
      text => "arguments do not match the input schema of tool '".$name."': ".join('; ', @problems) }],
    isError => JSON->true,
  };
}

# The tool gate's verdict on the canonical call $call (see _tool_gate):
# { verdict => 'allow' } when no gate is set. A gate that answers anything
# but allow, deny or ask croaks -- a broken gate must neither let the call
# through nor have its intent guessed.
sub _gate_tool_call {
  my ( $self, $call ) = @_;
  return { verdict => 'allow' } unless $self->_has_tool_gate;
  my $verdict = $self->_tool_gate->($self, $call);
  croak __PACKAGE__."->_tool_gate gave no valid verdict for tool '".( $call->{name} // '' )."'"
    unless ref $verdict eq 'HASH' && defined $verdict->{verdict}
      && $verdict->{verdict} =~ /\A(?:allow|deny|ask)\z/;
  return $verdict;
}

# The error result for a call the gate did not allow. ask is refused like
# deny for now: no surface can ask for an approval yet (k121, provisional
# until the approval step lands).
sub _gate_refused_tool_result {
  my ( $self, $name, $verdict ) = @_;
  my $reason = $verdict->{reason};
  my $has_reason = defined $reason && length $reason;
  my $text = $verdict->{verdict} eq 'ask'
    ? "Tool call '".$name."' was not run: it needs approval"
      .( $has_reason ? ' ('.$reason.')' : '' ).', and this raid has no way to ask for it.'
    : $has_reason
      ? "Tool call '".$name."' was denied: ".$reason
      : "Tool call '".$name."' was denied by policy.";
  return {
    content => [{ type => 'text', text => $text }],
    isError => JSON->true,
  };
}

# Rough token estimate for one tracked tool exchange (a list of wire messages):
# the JSON-encoded byte length over four, the usual ~4-chars-per-token rule. It
# only has to rank exchanges by size and say roughly how much dropping one sheds,
# never to be exact — the provider's real usage count drives the threshold, this
# only decides how many of the oldest exchanges to drop to get back under it.
sub _estimate_message_tokens {
  my ( $self, $segment ) = @_;
  my $chars = 0;
  for my $msg (@$segment) {
    my $encoded = eval { $history_json->encode($msg) };
    $chars += defined $encoded ? length $encoded : length "$msg";
  }
  return int( $chars / 4 ) || 1;
}

# In-loop context compaction (karr k89). Between raids _raid_f compresses the
# working history via compress_history_f, but within one long raid the growth is
# the assistant tool-call echoes and tool results appended to $conversation on
# every iteration — messages _raid_f never sees and history never keeps. Left
# alone a single mission with many tool calls blows past max_context_tokens on
# smaller models. So when the last real prompt-token count (the provider's usage,
# tracked in _last_prompt_tokens) has crossed the threshold, drop the OLDEST tool
# exchanges from the in-flight conversation, oldest first, until the estimate is
# back under the threshold — always keeping the most recent exchange, whose
# results the model still has to act on. Each exchange is dropped as a whole unit
# (the assistant echo carrying the tool_calls together with its tool results), so
# no tool_use is ever left without its tool_result (a 400 on strict providers).
# The header — mission/system prompt with its skill instructions, the pre-raid
# history and the user turn — is never a tracked exchange, so activated skill
# content always survives.
sub _compact_conversation {
  my ( $self, $state ) = @_;
  return unless $self->has_max_context_tokens && $self->has_last_prompt_tokens;
  my $target = $self->max_context_tokens * $self->context_compress_threshold;
  return unless $self->_last_prompt_tokens > $target;
  my $segments = $state->{tool_segments};
  return unless $segments && @$segments > 1;   # always keep the most recent exchange

  # Only exchanges still present in the live conversation may be dropped: a
  # plugin_before_llm_call hook may return a freshly built conversation arrayref
  # (see the write-back below), detaching the tracked messages — then there is
  # nothing safe to drop and compaction is a no-op.
  my %live = map { refaddr($_) => 1 } @{$state->{conversation}};

  my $over = $self->_last_prompt_tokens - $target;
  my $shed = 0;
  my @drop;
  while ( @$segments > 1 && $shed < $over ) {
    last unless grep { $live{ refaddr($_) } } @{ $segments->[0] };
    my $seg = shift @$segments;
    $shed += $self->_estimate_message_tokens($seg);
    push @drop, @$seg;
  }
  return unless @drop;

  my %drop = map { refaddr($_) => 1 } @drop;
  @{$state->{conversation}} = grep { !$drop{ refaddr($_) } } @{$state->{conversation}};
  $log->debugf(
    'Raider in-loop compaction: dropped %d older tool message(s), ~%d est. tokens (%d over threshold %d)',
    scalar @drop, $shed, $self->_last_prompt_tokens, $target );
  return $shed;
}

# The raid loop: one iteration per model turn. Each prepares the conversation
# (_prepare_iteration_f), sends it (_send_turn_f) and reads the reply
# (_read_turn_f); a reply without tool calls ends the raid (_finish_raid_f),
# otherwise the batch of tool calls runs (_execute_tool_calls_f) and the tool
# exchange is appended for the next turn (_append_tool_turn). The cancel safe
# points before each model call and each tool call sit here and in the batch
# (ADR 0009). $state is the continuation respond_f resumes from; $iter is one
# iteration's bookkeeping (number, Langfuse span and usage).
async sub _run_raid_loop {
  my ( $self, $state, $start_iteration ) = @_;

  for my $iteration ($start_iteration..$self->max_iterations) {
    # Safe point: no model call once a cancel is requested.
    return $self->_cancelled_result($state) if $self->cancel_requested;
    ${$state->{raid_iterations}}++;

    await $self->_prepare_iteration_f($state, $iteration, $start_iteration);
    my $iter = $self->_start_iteration_trace($state, $iteration);

    my $response = await $self->_send_turn_f($state);
    return $self->_cancelled_result($state) if $self->cancel_requested;
    my $data = await $self->_read_turn_f($state, $iter, $response);

    # Read this turn's reply (see _read_tool_loop_reply): a 200 body that is an
    # error croaks instead of silently ending the raid with '', Gemini thought
    # parts stay out of the final text, and truncated calls are dropped.
    my ( $tool_calls, $final_text, $echo_data ) = $self->_read_tool_loop_reply($state->{engine}, $data);

    # No tool calls means done — use the reply's final text
    unless (@$tool_calls) {
      return await $self->_finish_raid_f($state, $iter, $final_text);
    }

    $self->_trace_tool_turn($state, $iter, $tool_calls);
    my @results;
    my $stop = await $self->_execute_tool_calls_f($state, $iter, $tool_calls, $echo_data, \@results);
    return $stop if defined $stop;
    $self->_close_iteration_trace($state, $iter, $tool_calls, \@results);
    $self->_append_tool_turn($state, $echo_data, \@results);
  }

  die "Raider tool loop exceeded ".$self->max_iterations." iterations";
}

# Brings the conversation up to date before an iteration's request: in-loop
# compaction, the tool set rebuilt if it changed, injections (from the second
# iteration of the raid on), then the plugin_before_llm_call hook.
async sub _prepare_iteration_f {
  my ( $self, $state, $iteration, $start_iteration ) = @_;

  # Keep one long raid inside the context window: before building the next
  # request, drop the oldest tool exchanges if the last prompt crossed the
  # threshold (karr k89). Runs before injections and the plugin hook so both
  # see the compacted conversation.
  $self->_compact_conversation($state);

  await $self->_refresh_tools_f($state);

  # Drain injections for iterations 2+
  $self->_drain_injections($state, $iteration)
    if $iteration > $start_iteration || $start_iteration > 1;

  # Plugin hook: transform conversation before each LLM call
  my $conversation = $state->{conversation};
  for my $plugin (@{$self->plugin_instances}) {
    $conversation = await $plugin->plugin_before_llm_call($conversation, $iteration);
  }
  # A plugin may return a fresh arrayref. Keep the continuation state pointing
  # at whatever the loop now works with, because respond_f resumes from
  # $state->{conversation}: without this write-back a paused raid reverts to
  # the pre-plugin array and drops every message accumulated after divergence.
  $state->{conversation} = $conversation;
  return;
}

# Re-gathers the tool set for the active engine when the catalog or the engine
# changed (_tools_dirty).
async sub _refresh_tools_f {
  my ( $self, $state ) = @_;
  return unless $self->_tools_dirty;
  my $engine = $self->active_engine;
  $state->{engine} = $engine;
  my ( $all_tools, $new_map, $new_sources ) = await $self->_gather_tools_f;
  $state->{formatted_tools} = $engine->format_tools($all_tools);
  $state->{tool_server_map} = $new_map;
  $state->{tool_sources} = $new_sources;
  $state->{tool_schemas} = $self->_tool_schemas($all_tools);
  $state->{model_params} = $self->_langfuse_model_parameters($engine)
    if $state->{langfuse};
  $self->_tools_dirty(0);
  return;
}

# Moves the queued inject() messages and those the on_iteration callback
# returns into the conversation, the raid's injected history and
# session_history.
sub _drain_injections {
  my ( $self, $state, $iteration ) = @_;
  my @injected;
  if (@{$self->_injections}) {
    push @injected, splice @{$self->_injections};
  }
  if ($self->has_on_iteration) {
    my $cb_msgs = $self->on_iteration->($self, $iteration);
    push @injected, @$cb_msgs if $cb_msgs && @$cb_msgs;
  }
  return unless @injected;
  my @msgs = map {
    ref $_ ? $_ : { role => 'user', content => $_ }
  } @injected;
  push @{$state->{conversation}}, @msgs;
  push @{$state->{injected_history}}, @msgs;
  $self->_push_session_history(@msgs);
  return;
}

# Opens the iteration's Langfuse span. Returns the iteration's bookkeeping:
# its number, and with Langfuse its start time and span id.
sub _start_iteration_trace {
  my ( $self, $state, $iteration ) = @_;
  my $iter = { iteration => $iteration };
  return $iter unless $state->{langfuse};
  my $engine = $state->{engine};
  $iter->{t0} = $engine->langfuse_timestamp;
  $iter->{span_id} = $engine->langfuse_span(
    trace_id   => $state->{trace_id},
    name       => "iteration-$iteration",
    start_time => $iter->{t0},
  );
  return $iter;
}

# Sends the iteration's request. The future gives the HTTP response, or
# nothing once a cancel abandons the request.
sub _send_turn_f {
  my ( $self, $state ) = @_;
  my $engine = $state->{engine};
  my $request = $engine->build_tool_chat_request($state->{conversation}, $state->{formatted_tools});
  return $self->_until_cancelled($engine->async_request_f($request));
}

# Parses the reply to the iteration's request (dying on a failed request),
# runs the plugin_after_llm_response hook and records the prompt tokens for
# auto-compression and, with Langfuse, the usage on $iter. Returns the body.
async sub _read_turn_f {
  my ( $self, $state, $iter, $response ) = @_;
  my $engine = $state->{engine};

  unless ($response->is_success) {
    die "".(ref $engine)." raid request failed: ".$response->status_line."\n".$response->content;
  }

  my $data = $engine->parse_response($response);

  # Plugin hook: inspect/transform LLM response
  for my $plugin (@{$self->plugin_instances}) {
    $data = await $plugin->plugin_after_llm_response($data, $iter->{iteration});
  }

  # Track prompt tokens for auto-compression. from_raw is undef when the
  # body reports no usage, but a Usage without a prompt count still has
  # input_tokens 0: treat 0 as not reported, so it never resets the count.
  my $usage = Langertha::Usage->from_raw($data);
  $self->_last_prompt_tokens($usage->input_tokens)
    if $usage && $usage->input_tokens > 0;

  # Extract usage for Langfuse
  $iter->{usage} = $state->{langfuse} && $usage ? {
    input  => $usage->input_tokens,
    output => $usage->output_tokens,
    total  => $usage->total_tokens,
  } : undef;

  return $data;
}

# The Langfuse generation for the iteration's model call, nested under the
# iteration span.
sub _trace_llm_call {
  my ( $self, $state, $iter, $output, $end_time ) = @_;
  my $engine       = $state->{engine};
  my $model_params = $state->{model_params};
  $engine->langfuse_generation(
    trace_id              => $state->{trace_id},
    parent_observation_id => $iter->{span_id},
    name                  => 'llm-call',
    model                 => $engine->chat_model,
    input                 => $state->{conversation},
    output                => $output,
    start_time            => $iter->{t0},
    end_time              => $end_time,
    $iter->{usage} ? ( usage            => $iter->{usage} ) : (),
    $model_params  ? ( model_parameters => $model_params )  : (),
  );
  return;
}

# Ends the raid on a reply without tool calls: closes the Langfuse span and
# trace, persists the user messages, injections and answer in history,
# updates the metrics and returns the final Result through the
# plugin_after_raid hook.
async sub _finish_raid_f {
  my ( $self, $state, $iter, $text ) = @_;

  if ($state->{langfuse}) {
    my $engine  = $state->{engine};
    my $iter_t1 = $engine->langfuse_timestamp;

    # Langfuse: generation nested under iteration span
    $self->_trace_llm_call($state, $iter, $text, $iter_t1);

    # Close iteration span
    $engine->langfuse_update_span(
      id       => $iter->{span_id},
      end_time => $iter_t1,
      output   => $text,
    );

    # Update trace with final output
    $engine->langfuse_update_trace(
      id     => $state->{trace_id},
      output => $text,
    );
  }

  # Persist user messages, injections, and final assistant response in history
  my $injected_history = $state->{injected_history};
  push @{$self->history}, @{$state->{user_msgs}};
  push @{$self->history}, @$injected_history if @$injected_history;
  push @{$self->history}, { role => 'assistant', content => $text };

  # Push final assistant response to session_history
  $self->_push_session_history({ role => 'assistant', content => $text });

  $self->metrics->{raids}++;
  $self->_record_raid_metrics($state);

  my $result = Langertha::Raider::Result->new(type => 'final', text => $text);

  # Plugin hook: transform final result before return
  for my $plugin (@{$self->plugin_instances}) {
    $result = await $plugin->plugin_after_raid($result);
  }

  return $result;
}

# Adds the raid's iterations, tool calls and elapsed time to the metrics.
sub _record_raid_metrics {
  my ( $self, $state ) = @_;
  my $elapsed = tv_interval($state->{t0}) * 1000;
  my $m = $self->metrics;
  $m->{iterations}  += ${$state->{raid_iterations}};
  $m->{tool_calls}  += ${$state->{raid_tool_calls}};
  $m->{time_ms}     += $elapsed;
  return;
}

# Langfuse: generation for the model call that produced tool calls, its
# output the called tool names.
sub _trace_tool_turn {
  my ( $self, $state, $iter, $tool_calls ) = @_;
  return unless $state->{langfuse};
  my $engine     = $state->{engine};
  my $post_llm_t = $engine->langfuse_timestamp;
  $self->_trace_llm_call($state, $iter, $engine->json->encode([map {
    ($self->_tool_call_name_input($engine, $_))[0]
  } @$tool_calls]), $post_llm_t);
  return;
}

# Runs a batch of tool calls in order and pushes one
# { tool_call => ..., result => ... } per call onto $results. Returns the
# Result that ends the raid when a cancel, an interactive self-tool or an
# abort stops the batch; nothing when the whole batch ran. The iteration's
# batch runs here, and so does the rest of a batch respond_f resumes (k120).
async sub _execute_tool_calls_f {
  my ( $self, $state, $iter, $tool_calls, $echo_data, $results ) = @_;

  for my $tc_idx (0 .. $#$tool_calls) {
    # Safe point: no further tool call once a cancel is requested.
    return $self->_cancelled_result($state) if $self->cancel_requested;
    # Only the calls AFTER a pausing self-tool are still pending. The ones
    # before it already ran and sit in $results; carrying them too (as a plain
    # "everything but $tc" filter did) re-runs their side effects and emits a
    # second tool_result for the same tool_use id on resume — a 400 on strict
    # providers like Anthropic.
    my $stop = await $self->_dispatch_tool_call_f($state, $iter, $echo_data,
      $tool_calls->[$tc_idx], [ @$tool_calls[$tc_idx+1 .. $#$tool_calls] ], $results);
    return $stop if defined $stop;
  }

  return;
}

# Dispatches one tool call: the single path every call of a raid takes, in
# the first run of a batch and on resume alike (k120). Pushes its
# { tool_call => ..., result => ... } onto $results, or returns the Result
# that ends the raid (an interactive self-tool, which saves $remaining_tcs --
# the calls queued after $tc -- for respond_f; an abort). Every call that
# passed plugin_before_tool_call gets its result through
# plugin_after_tool_call exactly once; a pausing self-tool gets it on
# respond_f (k134).
async sub _dispatch_tool_call_f {
  my ( $self, $state, $iter, $echo_data, $tc, $remaining_tcs, $results ) = @_;
  my $engine = $state->{engine};
  my ( $name, $input ) = $self->_tool_call_name_input($engine, $tc);

  # A call whose arguments the model did not send as valid JSON must not run
  # the tool on {} -- answer it with an error result the model can retry, as
  # core does (karr k345). Truncated calls were dropped upstream already.
  if ( my $bad = $self->_undecodable_tool_result($tc) ) {
    push @$results, { tool_call => $tc, result => $bad };
    ${$state->{raid_tool_calls}}++;
    return;
  }

  # Plugin hook: inspect/transform before tool execution
  my @plugin_tc = await $self->plugin_pipeline_tool_call_f($name, $input);
  unless (@plugin_tc) {
    # Plugin returned empty list — skip this tool call
    my $skip_result = {
      content => [{ type => 'text', text => "Tool call '$name' was skipped by plugin." }],
    };
    push @$results, { tool_call => $tc, result => $skip_result };
    ${$state->{raid_tool_calls}}++;
    return;
  }
  ( $name, $input ) = @plugin_tc;

  my $tool_t0 = $state->{langfuse} ? $engine->langfuse_timestamp : undef;

  # Arguments that clearly break the tool's inputSchema do not run the tool:
  # the model gets an error result it can correct (ADR 0005 "validate", k122).
  # Checked after plugin_before_tool_call, so it is the call that would run --
  # and the one the Events plugin recorded as tool.call -- that is held
  # against the schema, and the error result takes the same
  # plugin_after_tool_call path as any other result: one tool.result.
  if ( my $invalid = $self->_invalid_args_tool_result($state, $name, $input) ) {
    my $result = await $self->_after_tool_call_f($state, $iter, $name, $input, $tool_t0, $invalid, 1);
    push @$results, { tool_call => $tc, result => $result };
    ${$state->{raid_tool_calls}}++;
    return;
  }

  # Virtual self-tools. A raider_-prefixed name routes here only when no tool
  # source announced it: an MCP source may offer a raider_-prefixed name and
  # win the first-wins dedup (karr k90), in which case it sits in
  # tool_server_map and was sent to the model as that MCP tool. Dispatch has
  # to follow the actual registration, not the prefix, or such a call dies as
  # "Unknown self-tool" instead of reaching its MCP source (karr k93).
  my $self_tool = $name =~ /^raider_/ && $self->has_raider_mcp
    && !$state->{tool_server_map}{$name};

  # The gate (ADR 0005 "check policy", k121): after the inputSchema check, on
  # the call exactly as it would run. A call it does not allow does not run;
  # its error result takes the plugin_after_tool_call path like any other, so
  # the call keeps one tool.call and one tool.result.
  my $verdict = $self->_gate_tool_call({
    name      => $name,
    source    => $self_tool ? 'raider' : $state->{tool_sources}{$name},
    arguments => $input,
  });
  unless ( $verdict->{verdict} eq 'allow' ) {
    my $result = await $self->_after_tool_call_f($state, $iter, $name, $input, $tool_t0,
      $self->_gate_refused_tool_result($name, $verdict), 1);
    push @$results, { tool_call => $tc, result => $result };
    ${$state->{raid_tool_calls}}++;
    return;
  }

  my $result;

  if ($self_tool) {
    my $self_result = await $self->_execute_self_tool_f($name, $input);

    # Handle interactive self-tool results
    return $self->_pause_raid($state, $iter, $echo_data, $tc, $name, $input,
      $tool_t0, $remaining_tcs, $results, $self_result)
      if $self_result->{type} eq 'question' || $self_result->{type} eq 'pause';

    return $self->_abort_raid($state, $self_result)
      if $self_result->{type} eq 'abort';

    if ($self_result->{type} eq 'wait') {
      $result = await $self->_wait_self_tool_f(
        $state, $iter, $name, $input, $tool_t0, $self_result->{seconds});
    }
    else {
      # type eq 'result' — normal self-tool result
      $result = await $self->_after_tool_call_f($state, $iter, $name, $input, $tool_t0, $self_result);
    }
  }
  else {
    $result = await $self->_call_mcp_tool_f($state, $iter, $name, $input, $tool_t0);
  }

  push @$results, { tool_call => $tc, result => $result };
  ${$state->{raid_tool_calls}}++;
  return;
}

# Saves the continuation respond_f resumes from when an interactive self-tool
# stops the batch, and returns its question or pause Result. $name and $input
# are the call as plugin_before_tool_call handed it on, for the
# plugin_after_tool_call the answer runs through. $remaining_tcs are the
# calls of the batch after $tc, $results those that already ran.
sub _pause_raid {
  my ( $self, $state, $iter, $echo_data, $tc, $name, $input, $tool_t0,
    $remaining_tcs, $results, $self_result ) = @_;
  $self->_continuation({
    state          => $state,
    iteration      => $iter->{iteration},
    data           => $echo_data,
    pending_tc     => $tc,
    pending_name   => $name,
    pending_input  => $input,
    pending_t0     => $tool_t0,
    remaining_tcs  => $remaining_tcs,
    results_so_far => $results,
    iter_span_id   => $iter->{span_id},
  });

  if ($self_result->{type} eq 'question') {
    return Langertha::Raider::Result->new(
      type    => 'question',
      content => $self_result->{question},
      $self_result->{options} ? (options => $self_result->{options}) : (),
    );
  }
  return Langertha::Raider::Result->new(
    type    => 'pause',
    content => $self_result->{reason},
  );
}

# Ends the raid on raider_abort, metrics finalized first.
sub _abort_raid {
  my ( $self, $state, $self_result ) = @_;
  $self->_record_raid_metrics($state);
  return Langertha::Raider::Result->new(
    type    => 'abort',
    content => $self_result->{reason},
  );
}

# Runs raider_wait: waits $seconds on the raid's loop unless a cancel cuts
# the wait short. Returns the tool result -- a cancelled one after a cancel,
# as for a cut-off MCP call -- through plugin_after_tool_call (k134).
async sub _wait_self_tool_f {
  my ( $self, $state, $iter, $name, $input, $tool_t0, $seconds ) = @_;
  my $engine = $state->{engine};
  my $loop = $engine->async_loop // IO::Async::Loop->new;
  await $self->_until_cancelled($loop->delay_future(after => $seconds));
  my $result = $self->cancel_requested
    ? $self->_cancelled_tool_result($name)
    : { content => [{ type => 'text', text => "Waited $seconds seconds." }] };
  return await $self->_after_tool_call_f($state, $iter, $name, $input, $tool_t0, $result);
}

# Calls the tool $name on the MCP source that registered it. A name no server
# offers is answered with an error result so the batch runs to the end and the
# model can correct itself, instead of dying and losing the whole raid (core
# k332). A failed call, or one a cancel cut off, is an error result too.
async sub _call_mcp_tool_f {
  my ( $self, $state, $iter, $name, $input, $tool_t0 ) = @_;
  my $mcp = $state->{tool_server_map}{$name};
  unless ($mcp) {
    return {
      content => [{ type => 'text', text => "unknown tool ".($name // '') }],
      isError => JSON->true,
    };
  }

  my $call_f = $mcp->call_tool($name, $input)->else(sub {
    my ( $error ) = @_;
    Future->done({
      content => [{ type => 'text', text => "Error calling tool '$name': $error" }],
      isError => JSON->true,
    });
  });
  my $result = await $self->_until_cancelled($call_f);
  $result = $self->_cancelled_tool_result($name) if $self->_cut_off($call_f, $result);

  return await $self->_after_tool_call_f($state, $iter, $name, $input, $tool_t0, $result, 1);
}

# Runs the plugin_after_tool_call hook on a tool's result and traces the call
# as a Langfuse span under the iteration span. With $flag_errors an error
# result gets level ERROR (MCP calls; self-tool results carry no level).
async sub _after_tool_call_f {
  my ( $self, $state, $iter, $name, $input, $tool_t0, $result, $flag_errors ) = @_;

  # Plugin hook: transform tool result
  for my $plugin (@{$self->plugin_instances}) {
    $result = await $plugin->plugin_after_tool_call($name, $input, $result);
  }

  if ($state->{langfuse}) {
    my $tool_output = join('', map { $_->{text} // '' } @{$result->{content} // []});
    $self->_trace_tool_call($state, $iter, $name, $input, $tool_t0, $tool_output,
      $flag_errors && $result->{isError} ? ( level => 'ERROR' ) : ());
  }

  return $result;
}

# Langfuse: span for one tool call, nested under the iteration span.
sub _trace_tool_call {
  my ( $self, $state, $iter, $name, $input, $tool_t0, $output, @extra ) = @_;
  my $engine = $state->{engine};
  $engine->langfuse_span(
    trace_id              => $state->{trace_id},
    parent_observation_id => $iter->{span_id},
    name                  => "tool: $name",
    input                 => $input,
    output                => $output,
    start_time            => $tool_t0,
    end_time              => $engine->langfuse_timestamp,
    @extra,
  );
  return;
}

# Langfuse: closes the iteration span once the batch of tool calls ran.
sub _close_iteration_trace {
  my ( $self, $state, $iter, $tool_calls, $results ) = @_;
  return unless $state->{langfuse};
  my $engine = $state->{engine};
  $engine->langfuse_update_span(
    id       => $iter->{span_id},
    end_time => $engine->langfuse_timestamp,
    metadata => {
      tool_calls => scalar @$tool_calls,
      tools_used => [map {
        ($self->_tool_call_name_input($engine, $_->{tool_call}))[0]
      } @$results],
    },
  );
  return;
}

# Appends the assistant echo and the tool results to the conversation and
# session_history, and tracks them as one exchange for in-loop compaction
# (k89). $echo_data is the wire body without any tool call whose arguments
# were truncated, so the next turn never carries a call without a result.
sub _append_tool_turn {
  my ( $self, $state, $echo_data, $results ) = @_;
  my @tool_msgs = $state->{engine}->format_tool_results($echo_data, $results);
  push @{$state->{conversation}}, @tool_msgs;
  push @{$state->{tool_segments}}, [ @tool_msgs ];
  $self->_push_session_history(@tool_msgs);
  return;
}

sub respond_f {
  my ( $self, $answer ) = @_;
  return $self->_end_raid($self->_respond_f($answer));
}

async sub _respond_f {
  my ( $self, $answer ) = @_;
  croak "No pending interaction — call raid_f first"
    unless $self->has_continuation;
  $self->_check_engine_loops;
  $self->_check_engine_connect;

  my $cont = $self->_continuation;
  $self->clear_continuation;

  my $state      = $cont->{state};
  my $data       = $cont->{data};
  my $pending_tc = $cont->{pending_tc};
  my @results    = @{$cont->{results_so_far}};
  my $engine     = $state->{engine};

  my $iter = { iteration => $cont->{iteration}, span_id => $cont->{iter_span_id} };

  # The answer is the tool result of the pending self-tool call. It runs
  # through plugin_after_tool_call like every other result, so the call's
  # tool.call event gets its tool.result (k134).
  my $answer_result = await $self->_after_tool_call_f($state, $iter,
    $cont->{pending_name}, $cont->{pending_input}, $cont->{pending_t0},
    { content => [{ type => 'text', text => "$answer" }] });
  push @results, { tool_call => $pending_tc, result => $answer_result };
  ${$state->{raid_tool_calls}}++;

  # Execute remaining tool calls from the same batch, through the same
  # per-call dispatch as the first run of the batch (k120): the
  # plugin_before_tool_call hook runs for each of them, and a second
  # interactive self-tool re-pauses carrying the calls still queued after it.
  # Every call handled here MUST leave a tool_result behind (or end the raid):
  # a trailing tool_use with no matching tool_result is a 400 on strict
  # providers.
  my $stop = await $self->_execute_tool_calls_f($state, $iter, $cont->{remaining_tcs}, $data, \@results);
  return $stop if defined $stop;

  # Close iteration span if Langfuse
  if ($state->{langfuse} && $cont->{iter_span_id}) {
    $engine->langfuse_update_span(
      id       => $cont->{iter_span_id},
      end_time => $engine->langfuse_timestamp,
      metadata => { tool_calls => scalar @results },
    );
  }

  # Format tool results and append to conversation
  my @tool_msgs = $engine->format_tool_results($data, \@results);
  push @{$state->{conversation}}, @tool_msgs;
  push @{$state->{tool_segments} //= []}, [ @tool_msgs ];   # track for in-loop compaction (k89)
  $self->_push_session_history(@tool_msgs);

  # Continue the raid loop from the next iteration
  return await $self->_run_raid_loop($state, $cont->{iteration} + 1);
}

sub respond {
  my ( $self, $answer ) = @_;
  return $self->respond_f($answer)->get;
}



__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider - Autonomous agent with conversation history and MCP tools

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use IO::Async::Loop;
    use Future::AsyncAwait;
    use Net::Async::MCP;
    use MCP::Server;
    use Langertha::Engine::Anthropic;
    use Langertha::Raider;

    # Set up MCP server with tools
    my $server = MCP::Server->new(name => 'demo', version => '1.0');
    $server->tool(
        name => 'list_files',
        description => 'List files in a directory',
        input_schema => {
            type => 'object',
            properties => { path => { type => 'string' } },
            required => ['path'],
        },
        code => sub { $_[0]->text_result(join("\n", glob("$_[1]->{path}/*"))) },
    );

    my $loop = IO::Async::Loop->new;
    my $mcp = Net::Async::MCP->new(server => $server);
    $loop->add($mcp);

    async sub main {
        await $mcp->initialize;

        my $engine = Langertha::Engine::Anthropic->new(
            api_key     => $ENV{ANTHROPIC_API_KEY},
            mcp_servers => [$mcp],
        );

        my $raider = Langertha::Raider->new(
            engine  => $engine,
            mission => 'You are a code explorer. Investigate files thoroughly.',
        );

        # First raid — uses tools, builds history
        my $r1 = await $raider->raid_f('What files are in the current directory?');
        say $r1;

        # Second raid — has context from first conversation
        my $r2 = await $raider->raid_f('Tell me more about the first file you found.');
        say $r2;

        # Check metrics
        my $m = $raider->metrics;
        say "Raids: $m->{raids}, Tool calls: $m->{tool_calls}, Time: $m->{time_ms}ms";

        # Reset for a fresh conversation
        $raider->clear_history;
    }

    main()->get;

=head1 DESCRIPTION

Langertha::Raider is an autonomous agent that wraps a Langertha engine
with MCP tools. It maintains conversation history across multiple
interactions (raids), enabling multi-turn conversations where the LLM
can reference prior context.

B<Key features:>

=over 4

=item * Conversation history persisted across raids

=item * Mission (system prompt) separate from engine's system_prompt

=item * Automatic MCP tool calling loop

=item * Tool arguments checked against the tool's C<inputSchema> before it
runs: a missing C<required> key or a top-level property of the wrong type
answers the call with an error result the model can correct, and the tool
does not run

=item * Cumulative metrics tracking

=item * Hermes tool calling support (inherited from engine)

=item * Mid-raid context injection via C<inject()> and C<on_iteration>

=item * Automatic context management — between-raid LLM history summary plus in-raid mechanical compaction, mission and skills preserved

=back

B<History management:> Only user messages and final assistant text
responses are persisted in history. Intermediate tool-call messages
(assistant tool requests and tool results) are NOT persisted, preventing
token bloat across long conversations. The full turn-by-turn record, tool
calls and results included, is kept separately in L</session_history>.

=head2 engine

Required. A Langertha engine instance with MCP servers configured.
The engine must compose L<Langertha::Role::Tools>.

=head2 mission

Optional system prompt for the Raider. This is separate from the
engine's own C<system_prompt> — the Raider's mission takes precedence
and is prepended to every conversation.

=head2 history

ArrayRef of message hashes representing the conversation history.
Automatically managed by C<raid>/C<raid_f>. Can be inspected or
manually set.

=head2 max_iterations

Maximum number of tool-calling round trips per raid. Defaults to C<10>.

=head2 max_context_tokens

Optional. Enables auto-compression when set. When prompt token usage
exceeds C<context_compress_threshold * max_context_tokens>, the working
history is summarized via LLM before the next raid, and B<within> a single
long raid the oldest tool-call exchanges are dropped from the in-flight
conversation as the tool loop runs, oldest first, so one long-running
mission cannot outgrow the context window. The mission (system prompt,
including any activated skill instructions) is never compacted — an agent
must not lose its instructions mid-raid.

=head2 context_compress_threshold

Fraction of C<max_context_tokens> that triggers compression. Defaults
to C<0.75> (75%).

=head2 compression_prompt

System prompt used for history summarization. Customizable. The default
instructs the LLM to preserve key facts, decisions, and context.

=head2 compression_engine

Optional separate engine for compression (e.g. a cheaper model).
Falls back to C<engine> when not set.

=head2 session_history

Full chronological archive of ALL messages including tool calls and
results. Never auto-compressed. Persists across C<clear_history> and
C<reset>. Cleared via C<clear_session_history>, which also empties the
internal C<_session_embeddings> array to preserve their 1:1 invariant.

=head2 on_iteration

Optional CodeRef called before each LLM call (iterations 2+). Receives
C<($raider, $iteration)> and returns an arrayref of messages to inject,
or undef/empty to skip.

    my $raider = Langertha::Raider->new(
        engine => $engine,
        on_iteration => sub {
            my ($raider, $iteration) = @_;
            return ['Check the error log'] if $iteration == 3;
            return;
        },
    );

=head2 metrics

HashRef of cumulative metrics across all raids:

    {
        raids      => 3,       # Number of completed raids
        iterations => 7,       # Total LLM round trips
        tool_calls => 12,      # Total tool invocations
        time_ms    => 4500.2,  # Total wall-clock time in milliseconds
    }

=head2 langfuse_trace_name

Name for the Langfuse trace created per raid. Defaults to C<'raid'>.

=head2 langfuse_user_id

Optional user ID passed to the Langfuse trace.

=head2 langfuse_session_id

Optional session ID passed to the Langfuse trace. Use this to group
multiple raids into a single Langfuse session.

=head2 langfuse_tags

Optional tags (ArrayRef[Str]) passed to the Langfuse trace.

=head2 langfuse_release

Optional release identifier passed to the Langfuse trace.

=head2 langfuse_version

Optional version string passed to the Langfuse trace.

=head2 langfuse_metadata

Optional metadata HashRef merged into the Langfuse trace metadata
(alongside auto-generated fields like mission and history_length).

=head2 raider_mcp

Enables virtual self-tools that the LLM can call to interact with the
Raider itself. Set to C<1> to enable all self-tools, or pass a HashRef
to enable selectively:

    raider_mcp => 1                               # all self-tools
    raider_mcp => { ask_user => 1, pause => 1 }   # only these

Available self-tools: C<ask_user>, C<wait>, C<wait_for>, C<pause>,
C<abort>, C<session_history>, C<manage_mcps>, C<switch_engine>.

=head2 on_ask_user

Optional callback for the C<raider_ask_user> self-tool. Receives
C<($question, $options)> and must return an answer string. When not set,
the raid pauses and returns a C<question> Result that can be continued
with L</respond_f>.

=head2 on_pause

Optional callback for the C<raider_pause> self-tool. Receives C<($reason)>.
When not set, the raid pauses and returns a C<pause> Result.

=head2 on_wait_for

Callback for the C<raider_wait_for> self-tool. Receives
C<($condition, $args)> and must return a result string. Required when the
LLM uses C<raider_wait_for> — will die if not set.

=head2 cancel

    $raider->cancel;

Asks the raid in progress to stop (ADR 0009). It stops at its next safe
point -- before the next model call, before the next tool call -- and a
model response, tool call or C<raider_wait> it waits for right then is
abandoned: that future is cancelled, which aborts an HTTP request in
flight on L<Net::Async::HTTP>. A tool call cut off this way still gets its
result, marked C<cancelled> (text C<Tool call 'NAME' was cancelled.>,
C<isError>, C<< cancelled => 1 >>), through C<plugin_after_tool_call>.
Tool subprocesses are not signalled; that is the caller's to do. A tool call
that ends with an error once the cancel is requested -- its subprocess
ended by the caller -- counts as cut off too; one that succeeds keeps its
result.

The raid then resolves with a C<cancelled> L<Langertha::Raider::Result>.
Like a failed raid it adds nothing to L</history>; the tool calls made so
far stay in L</session_history>.

It only sets a flag and writes a byte to a pipe the event loop watches,
so it is safe to call from a signal handler: the rest happens on the loop.
A request made while no raid runs applies to the next one
(L</clear_cancel> drops it); each raid ends with no request pending
(L</cancel_requested>).

=head2 cancel_requested

True from L</cancel> until the raid it applies to has ended.

=head2 clear_cancel

    $raider->clear_cancel;

Drops a cancel request that no raid has used yet (L</cancel>). Every raid
does this when it ends.

=head2 tools

Optional ArrayRef of inline tool definitions. Each entry is a HashRef with
C<name>, C<description>, C<input_schema>, and C<code> keys — the same
format as L<MCP::Server/tool>. An internal MCP server is created
automatically.

    my $raider = Langertha::Raider->new(
        engine => $engine,
        tools  => [{
            name         => 'greet',
            description  => 'Say hello',
            input_schema => { type => 'object', properties => { name => { type => 'string' } } },
            code         => sub { $_[0]->text_result("Hello $_[1]->{name}!") },
        }],
    );

=head2 mcp_catalog

HashRef of named MCP servers available for dynamic activation. The LLM can
use C<raider_manage_mcps> to list, activate, and deactivate catalog entries.

    mcp_catalog => {
        database => { server => $db_mcp, description => 'Database tools', auto => 1 },
        email    => { server => $email_mcp, description => 'Email tools' },
    }

Entries with C<< auto => 1 >> are activated at construction time.

=head2 engine_catalog

HashRef of named engines available for runtime switching via C<switch_engine>.

    engine_catalog => {
        fast  => { engine => $groq,      description => 'Fast inference' },
        smart => { engine => $anthropic,  description => 'Complex reasoning' },
        code  => { engine => $deepseek,   description => 'Code generation' },
    }

Entries without an C<engine> key refer to the default engine (the one passed
as C<engine> at construction). This lets you give the default engine a named
catalog entry with a description:

    engine_catalog => {
        sonnet => { description => 'Balanced model for everyday tasks' },
        fast   => { engine => $groq,  description => 'Fast inference' },
        smart  => { engine => $opus,  description => 'Complex reasoning' },
    }

The LLM always sees a C<default> entry (reset to original) plus all catalog
keys in the C<raider_switch_engine> tool enum.

Use C<switch_engine>, C<reset_engine>, C<active_engine>, and C<engine_info>
to control which engine is used during raids.

=head2 embedding_engine

Optional engine with L<Langertha::Role::Embedding> for semantic history search.
When not set, auto-detects if the main C<engine> supports embeddings.
Set L</no_session_embeddings> to disable auto-detection.

Each C<session_history> entry is embedded in the background through
C<simple_embedding_f>, so the raid never waits for it. Like every engine of
the raider, the embedding engine must run on the same event loop as
C<engine> (see L</raid_f>).

=head2 no_session_embeddings

When true, no session history entry is embedded, and the C<search> of
C<raider_session_history> falls back to a plain text match. Use it when the
engine supports embeddings but they are not wanted, e.g. to save the extra
request per message. With it set, C<embedding_engine> is also left out of
the event-loop check of L</raid_f>.

=head2 clear_history

    $raider->clear_history;

Clears conversation history and pending injections while preserving metrics.

=head2 clear_session_history

    $raider->clear_session_history;

Empties C<session_history> and the matching C<_session_embeddings> array
in lock-step, so the 1:1 invariant both readers of C<session_history> rely
on is preserved. Use this instead of splicing C<session_history> directly,
which leaves C<_session_embeddings> stale. Embedding requests still in
flight for the cleared entries are cancelled.

=head2 add_history

    $raider->add_history('user', 'Hello');
    $raider->add_history('assistant', 'Hi there!');

Appends a message to the conversation history. Useful for replaying
persisted messages into a fresh Raider instance.

=head2 add_session_history

    $raider->add_session_history(
      { role => 'user', content => 'Hello' },
      { role => 'tool', name => 'bash', content => 'README.md' },
    );

Appends entries to C<session_history>, keeping the session embeddings in
step. Useful for replaying a persisted session into a fresh Raider
instance; C<history> is replayed separately with C<add_history>.

=head2 inject

    $raider->inject('Also check the test files');
    $raider->inject({ role => 'user', content => 'Focus on .pm files' });

Queues messages to be injected into the conversation at the next iteration.
Strings are automatically wrapped as user messages. The Raider drains the
queue before each LLM call (iterations 2+).

=head2 reset

    $raider->reset;

Clears conversation history, metrics, and resets to the default engine.

=head2 active_engine

    my $engine = $raider->active_engine;

Returns the currently active engine. If C<switch_engine> was called, returns
the catalog engine; otherwise returns the default C<engine>.

=head2 active_engine_name

    my $name = $raider->active_engine_name;  # 'smart' or undef

Returns the name of the currently active catalog engine, or C<undef> if using
the default engine.

=head2 switch_engine

    $raider->switch_engine('smart');

Switches to a named engine from the C<engine_catalog>. Sets C<_tools_dirty>
so the raid loop re-gathers and re-formats tools for the new engine.
Croaks if the name is not in the catalog.

=head2 reset_engine

    $raider->reset_engine;

Switches back to the default engine (the one passed at construction).

=head2 engine_info

    my $info = $raider->engine_info;
    # { name => 'smart', class => 'Langertha::Engine::Anthropic', model => 'claude-sonnet-4-6' }

Returns a hashref with the active engine's name, class, and model.

=head2 list_engines

    my $engines = $raider->list_engines;

Returns a hashref of all available engines (default + catalog entries),
each with C<engine>, C<description> (if from catalog), and C<active> flag.

=head2 add_engine

    $raider->add_engine('vision', engine => $vision_engine, description => 'Vision model');
    $raider->add_engine('main', description => 'Default model for general tasks');

Adds a new engine to the catalog at runtime. If C<engine> is omitted, the
entry refers to the default engine. The LLM will see it in the
C<raider_switch_engine> tool after the next tool re-gather.

=head2 remove_engine

    $raider->remove_engine('vision');

Removes an engine from the catalog. If the removed engine is currently active,
automatically resets to the default engine. Croaks when the name is not in
the catalog.

=head2 compress_history_f

    my $summary = await $raider->compress_history_f;

Async. Summarizes the current working history via LLM and replaces it
with the summary. Uses C<compression_engine> if set, otherwise falls
back to C<engine>. A marker is added to C<session_history>.

The summary is read through the engine's public C<chat_response> (the parser
L<Langertha::Role::Chat/chat_f> uses), so an error carried in a 200 body croaks
instead of silently producing an empty summary, and Gemini thought parts stay
out of the text. An engine that lacks C<chat_response> falls back to
C<response_text_content>.

=head2 compress_history

    my $summary = $raider->compress_history;

Synchronous wrapper around C<compress_history_f>.

=head2 register_session_history_tool

    $raider->register_session_history_tool($mcp_server);

Registers a C<session_history> MCP tool on the given server, allowing
the LLM to query its own full session history. Supports C<query>
(text filter) and C<last_n> (return last N messages) parameters.

=head2 run_f

    my $result = await $raider->run_f($ctx);   # a Langertha::RunContext, or plain input

The L<Langertha::Role::Runnable> entry point that lets a raider be a step
of a L<Langertha::Raid>. Runs L</raid_f> on the context's C<input> (a
string, or an ArrayRef of messages; plain input is wrapped in a new
L<Langertha::RunContext>). A final answer becomes the context's C<input>
and C<< state->{last_output} >> for the next step; C<last_result_type>,
C<last_result> and C<history> are updated too. Returns the
L<Langertha::Raider::Result> with the context attached.

=head2 raid

    my $response = $raider->raid(@messages);

Synchronous wrapper around C<raid_f>. Sends messages, runs the tool
loop, and returns the L<Langertha::Raider::Result>, which stringifies to
the final text. Updates history and metrics.

=head2 raid_f

    my $result = await $raider->raid_f(@messages);

Async tool-calling conversation. Accepts the same message arguments as
C<simple_chat> (strings become user messages, hashrefs pass through).
Returns a L<Future> resolving to a L<Langertha::Raider::Result>.

The result stringifies to the final text (backward compatible), but also
provides C<type>, C<is_final>, C<is_question>, C<is_pause>, C<is_abort>
for programmatic handling of interactive self-tools, and C<is_cancelled>
for a raid stopped by L</cancel>.

All engines of a raider (C<engine>, C<compression_engine>, every
C<engine_catalog> engine, and C<embedding_engine> unless
C<no_session_embeddings> is set) must run on the same event loop, since one raid
is driven by one loop. An engine without a loop (the synchronous fallback)
counts as the process-wide C<< IO::Async::Loop->new >>. C<raid_f> and
C<respond_f> fail right away, naming the engine, when one runs on another loop.

They also fail right away, naming the engine and the module, when a module
L<Net::Async::HTTP> needs to connect to an engine's C<url> does not load:
L<IO::Async::Internals::Connector>, and for https L<IO::Async::SSL> (which
needs L<IO::Socket::SSL>, L<Net::SSLeay> and the system libssl). Sent
anyway, the first request would fail and every later one to that host would
wait forever.

=head2 respond_f

    my $result = await $raider->respond_f($answer);

Continue a paused raid after a C<question> or C<pause> result. The answer
is used as the tool result of the pausing self-tool call -- handed through
C<plugin_after_tool_call> like any tool result -- and the raid loop resumes.
Returns the next
L<Langertha::Raider::Result>.

=head2 respond

    my $result = $raider->respond($answer);

Synchronous wrapper around C<respond_f>.

=head2 plugins

    my $raider = Langertha::Raider->new(
        plugins => ['Langfuse', 'MyApp::CustomPlugin'],
        engine  => $engine,
    );

Arrayref of plugin names or L<Langertha::Plugin> instances. Short names
are resolved first to C<Langertha::Plugin::$name>, then to
C<LangerthaX::Plugin::$name>. Fully qualified names (with C<::>) are
used as-is.

A leading C<+> (C<+My::Plugin>) loads the class as named, without the
prefix search, and a name may be followed by a HashRef of constructor
arguments for that plugin.

Plugin instances are created automatically with C<< host => $self >>.
Extra constructor arguments can be passed via C<plugin_args>.

Besides the tool-calling hooks every L<Langertha::Plugin> has, a raider
calls C<plugin_before_raid> (the raid's messages), C<plugin_build_conversation>
(the conversation sent to the model) and C<plugin_after_raid> (the final
L<Langertha::Raider::Result>); the contract is in L<Langertha::Plugin>.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::Tools> - Lower-level single-turn tool calling

=item * L<Langertha::Role::Langfuse> - Observability integration (used by Raider)

=item * L<Langertha::Role::SystemPrompt> - Engine-level system prompt (Raider uses C<mission> instead)

=item * L<Langertha::Plugin> - Base role and documentation for Raider plugins

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

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
