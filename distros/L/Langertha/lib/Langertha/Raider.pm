package Langertha::Raider;
# ABSTRACT: Autonomous agent with conversation history and MCP tools
our $VERSION = '0.309';
use Moose;
use Future::AsyncAwait;
use Time::HiRes qw( gettimeofday tv_interval );
use Carp qw( croak );
use Module::Runtime qw( use_module );
use Scalar::Util qw( blessed );
use Langertha::Raider::Result;
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


sub add_history {
  my ( $self, $role, $content ) = @_;
  push @{$self->history}, { role => $role, content => $content };
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


sub _extract_prompt_tokens {
  my ( $self, $data ) = @_;
  # OpenAI-compatible (OpenAI, Groq, Mistral, DeepSeek, MiniMax, vLLM, Ollama, AKI)
  if (my $u = $data->{usage}) {
    return $u->{prompt_tokens} // $u->{input_tokens};
  }
  # Gemini
  if (my $m = $data->{usageMetadata}) {
    return $m->{promptTokenCount};
  }
  return undef;
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
  my $response = await $engine->_async_http->do_request(request => $request);
  my $data = $engine->parse_response($response);
  my $summary = $engine->response_text_content($data);

  # Replace working history with summary
  $self->history([
    { role => 'assistant', content => $summary },
  ]);

  # Mark compression event in session_history
  push @{$self->session_history}, {
    role => 'system',
    content => '[Context compressed — history summarized]',
  };

  return $summary;
}


sub compress_history {
  my ( $self ) = @_;
  return $self->compress_history_f->get;
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
        @hist = grep { ($_->{content} // '') =~ /\Q$q/i } @hist;
      }
      if (my $n = $args->{last_n}) {
        @hist = @hist[-$n..-1] if @hist > $n;
      }
      my $text = join("\n\n", map {
        "[$_->{role}] $_->{content}"
      } @hist);
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

sub _langfuse_usage {
  my ( $self, $data ) = @_;
  # OpenAI-compatible + Anthropic (both use $data->{usage})
  if (my $u = $data->{usage}) {
    my $input  = $u->{prompt_tokens} // $u->{input_tokens};
    my $output = $u->{completion_tokens} // $u->{output_tokens};
    return {
      input  => $input,
      output => $output,
      total  => $u->{total_tokens} // (($input // 0) + ($output // 0)),
    };
  }
  # Gemini
  if (my $m = $data->{usageMetadata}) {
    return {
      input  => $m->{promptTokenCount},
      output => $m->{candidatesTokenCount},
      total  => $m->{totalTokenCount},
    };
  }
  return undef;
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

sub _execute_self_tool {
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
    return { type => 'result', content => [{ type => 'text', text => $self->_query_session_history($input) }] };
  }

  if ($short eq 'manage_mcps') {
    return { type => 'result', content => [{ type => 'text', text => $self->_manage_mcps($input) }] };
  }

  if ($short eq 'switch_engine') {
    return { type => 'result', content => [{ type => 'text', text => $self->_switch_engine_tool($input) }] };
  }

  die "Unknown self-tool: $name";
}

sub _query_session_history {
  my ( $self, $args ) = @_;
  my @hist = @{$self->session_history};

  # Semantic search via embeddings
  if (my $search = $args->{search}) {
    my $engine = $self->_get_embedding_engine;
    if ($engine) {
      my $query_vec = $engine->simple_embedding($search);
      my @scored;
      for my $i (0..$#hist) {
        my $emb = $self->_session_embeddings->[$i];
        next unless $emb;
        my $sim = _cosine_similarity($query_vec, $emb);
        push @scored, { idx => $i, score => $sim };
      }
      @scored = sort { $b->{score} <=> $a->{score} } @scored;
      @scored = @scored[0..9] if @scored > 10;
      @hist = map { $hist[$_->{idx}] } @scored;
    } else {
      # Fallback to text grep
      @hist = grep { ($_->{content} // '') =~ /\Q$search/i } @hist;
    }
  }

  if (my $q = $args->{query}) {
    @hist = grep { ($_->{content} // '') =~ /\Q$q/i } @hist;
  }
  if (my $n = $args->{last_n}) {
    @hist = @hist[-$n..-1] if @hist > $n;
  }

  my $text = join("\n\n", map {
    "[$_->{role}] $_->{content}"
  } @hist);
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
  # Fire-and-forget embedding computation
  my $engine = $self->_get_embedding_engine;
  if ($engine) {
    for my $msg (@msgs) {
      my $text = $msg->{content};
      next unless defined $text && length $text;
      eval {
        my $vec = $engine->simple_embedding($text);
        push @{$self->_session_embeddings}, $vec;
      };
      if ($@) {
        push @{$self->_session_embeddings}, undef;
      }
    }
  } else {
    push @{$self->_session_embeddings}, (undef) x scalar @msgs;
  }
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
  my ( @all_tools, %tool_server_map );

  # Engine MCP servers
  if ($engine->can('mcp_servers')) {
    for my $mcp (@{$engine->mcp_servers}) {
      my $tools = await $mcp->list_tools;
      for my $tool (@$tools) {
        $tool_server_map{$tool->{name}} = $mcp;
        push @all_tools, $tool;
      }
    }
  }

  # Inline MCP
  if ($self->has_inline_mcp) {
    my $tools = await $self->_inline_mcp->list_tools;
    for my $tool (@$tools) {
      $tool_server_map{$tool->{name}} = $self->_inline_mcp;
      push @all_tools, $tool;
    }
  }

  # Active catalog MCPs
  for my $name (sort keys %{$self->_active_catalog_mcps}) {
    my $mcp = $self->_active_catalog_mcps->{$name};
    my $tools = await $mcp->list_tools;
    for my $tool (@$tools) {
      $tool_server_map{$tool->{name}} = $mcp;
      push @all_tools, $tool;
    }
  }

  # Self-tools (virtual — no MCP server mapping needed)
  if ($self->has_raider_mcp) {
    push @all_tools, @{$self->_self_tool_definitions};
  }

  # Plugin self-tools
  for my $plugin (@{$self->_plugin_instances}) {
    my $tools = $plugin->self_tools;
    push @all_tools, @$tools if $tools && @$tools;
  }

  return ( \@all_tools, \%tool_server_map );
}

async sub _initialize_inline_mcp_f {
  my ( $self ) = @_;
  return if $self->has_inline_mcp;

  # Collect inline tools + plugin tools
  my @all_inline;
  push @all_inline, @{$self->tools};
  for my $plugin (@{$self->_plugin_instances}) {
    my $tools = $plugin->self_tools;
    push @all_inline, @$tools if $tools && @$tools;
  }
  return unless @all_inline;

  require MCP::Server;
  require Net::Async::MCP;

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
  $self->engine->_async_http->loop->add($mcp);
  await $mcp->initialize;
  $self->_inline_mcp($mcp);
}

async sub raid_f {
  my ( $self, @messages ) = @_;
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
  for my $plugin (@{$self->_plugin_instances}) {
    @messages = @{await $plugin->plugin_before_raid(\@messages)};
  }

  # Initialize inline MCP if tools defined
  await $self->_initialize_inline_mcp_f;

  # Gather tools from all sources
  my ( $all_tools, $tool_server_map ) = await $self->_gather_tools_f;

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
  for my $plugin (@{$self->_plugin_instances}) {
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
    formatted_tools  => $formatted_tools,
    model_params     => $model_params,
    user_msgs        => \@user_msgs,
    conversation     => \@conversation,
    raid_iterations  => \$raid_iterations,
    raid_tool_calls  => \$raid_tool_calls,
    injected_history => \@injected_history,
  };

  return await $self->_run_raid_loop($state, 1);
}

async sub _run_raid_loop {
  my ( $self, $state, $start_iteration ) = @_;
  my $engine           = $state->{engine};
  my $langfuse         = $state->{langfuse};
  my $trace_id         = $state->{trace_id};
  my $tool_server_map  = $state->{tool_server_map};
  my $formatted_tools  = $state->{formatted_tools};
  my $model_params     = $state->{model_params};
  my $user_msgs        = $state->{user_msgs};
  my $conversation     = $state->{conversation};
  my $raid_iterations  = $state->{raid_iterations};
  my $raid_tool_calls  = $state->{raid_tool_calls};
  my $injected_history = $state->{injected_history};
  my $t0               = $state->{t0};

  for my $iteration ($start_iteration..$self->max_iterations) {
    $$raid_iterations++;

    # Re-gather tools if catalog/engine changed
    if ($self->_tools_dirty) {
      $engine = $self->active_engine;
      $state->{engine} = $engine;
      my ( $all_tools, $new_map ) = await $self->_gather_tools_f;
      $formatted_tools = $engine->format_tools($all_tools);
      $tool_server_map = $new_map;
      $state->{formatted_tools} = $formatted_tools;
      $state->{tool_server_map} = $tool_server_map;
      if ($langfuse) {
        $model_params = $self->_langfuse_model_parameters($engine);
        $state->{model_params} = $model_params;
      }

      $self->_tools_dirty(0);
    }

    # Drain injections for iterations 2+
    if ($iteration > $start_iteration || $start_iteration > 1) {
      my @injected;
      if (@{$self->_injections}) {
        push @injected, splice @{$self->_injections};
      }
      if ($self->has_on_iteration) {
        my $cb_msgs = $self->on_iteration->($self, $iteration);
        push @injected, @$cb_msgs if $cb_msgs && @$cb_msgs;
      }
      if (@injected) {
        my @msgs = map {
          ref $_ ? $_ : { role => 'user', content => $_ }
        } @injected;
        push @$conversation, @msgs;
        push @$injected_history, @msgs;
        $self->_push_session_history(@msgs);
      }
    }

    # Plugin hook: transform conversation before each LLM call
    for my $plugin (@{$self->_plugin_instances}) {
      $conversation = await $plugin->plugin_before_llm_call($conversation, $iteration);
    }

    my $iter_t0 = $langfuse ? $engine->_langfuse_timestamp : undef;

    # Langfuse: create iteration span
    my $iter_span_id;
    if ($langfuse) {
      $iter_span_id = $engine->langfuse_span(
        trace_id   => $trace_id,
        name       => "iteration-$iteration",
        start_time => $iter_t0,
      );
    }

    # Build and send the request
    my $request = $engine->build_tool_chat_request($conversation, $formatted_tools);

    my $response = await $engine->_async_http->do_request(request => $request);

    unless ($response->is_success) {
      die "".(ref $engine)." raid request failed: ".$response->status_line."\n".$response->content;
    }

    my $data = $engine->parse_response($response);

    # Plugin hook: inspect/transform LLM response
    for my $plugin (@{$self->_plugin_instances}) {
      $data = await $plugin->plugin_after_llm_response($data, $iteration);
    }

    # Track prompt tokens for auto-compression
    my $pt = $self->_extract_prompt_tokens($data);
    $self->_last_prompt_tokens($pt) if defined $pt;

    # Extract usage for Langfuse
    my $langfuse_usage = $langfuse ? $self->_langfuse_usage($data) : undef;

    # Extract tool calls
    my $tool_calls = $engine->response_tool_calls($data);

    # No tool calls means done — extract final text
    unless (@$tool_calls) {
      my $text = $engine->response_text_content($data);
      if ($engine->think_tag_filter) {
        ($text) = $engine->filter_think_content($text);
      }

      my $iter_t1 = $langfuse ? $engine->_langfuse_timestamp : undef;

      # Langfuse: generation nested under iteration span
      if ($langfuse) {
        $engine->langfuse_generation(
          trace_id              => $trace_id,
          parent_observation_id => $iter_span_id,
          name                  => 'llm-call',
          model                 => $engine->chat_model,
          input                 => $conversation,
          output                => $text,
          start_time            => $iter_t0,
          end_time              => $iter_t1,
          $langfuse_usage  ? ( usage            => $langfuse_usage )  : (),
          $model_params    ? ( model_parameters => $model_params )    : (),
        );

        # Close iteration span
        $engine->langfuse_update_span(
          id       => $iter_span_id,
          end_time => $iter_t1,
          output   => $text,
        );

        # Update trace with final output
        $engine->langfuse_update_trace(
          id     => $trace_id,
          output => $text,
        );
      }

      # Persist user messages, injections, and final assistant response in history
      push @{$self->history}, @$user_msgs;
      push @{$self->history}, @$injected_history if @$injected_history;
      push @{$self->history}, { role => 'assistant', content => $text };

      # Push final assistant response to session_history
      $self->_push_session_history({ role => 'assistant', content => $text });

      # Update metrics
      my $elapsed = tv_interval($t0) * 1000;
      my $m = $self->metrics;
      $m->{raids}++;
      $m->{iterations}  += $$raid_iterations;
      $m->{tool_calls}  += $$raid_tool_calls;
      $m->{time_ms}     += $elapsed;

      my $result = Langertha::Raider::Result->new(type => 'final', text => $text);

      # Plugin hook: transform final result before return
      for my $plugin (@{$self->_plugin_instances}) {
        $result = await $plugin->plugin_after_raid($result);
      }

      return $result;
    }

    # Langfuse: generation for the LLM call that produced tool calls
    my $post_llm_t = $langfuse ? $engine->_langfuse_timestamp : undef;
    if ($langfuse) {
      $engine->langfuse_generation(
        trace_id              => $trace_id,
        parent_observation_id => $iter_span_id,
        name                  => 'llm-call',
        model                 => $engine->chat_model,
        input                 => $conversation,
        output                => $engine->json->encode([map {
          ($engine->extract_tool_call($_))[0]
        } @$tool_calls]),
        start_time            => $iter_t0,
        end_time              => $post_llm_t,
        $langfuse_usage  ? ( usage            => $langfuse_usage )  : (),
        $model_params    ? ( model_parameters => $model_params )    : (),
      );
    }

    # Execute each tool call
    my @results;
    for my $tc (@$tool_calls) {
      my ( $name, $input ) = $engine->extract_tool_call($tc);

      # Plugin hook: inspect/transform before tool execution
      my @plugin_tc = await $self->_plugin_pipeline_tool_call($name, $input);
      unless (@plugin_tc) {
        # Plugin returned empty list — skip this tool call
        my $skip_result = {
          content => [{ type => 'text', text => "Tool call '$name' was skipped by plugin." }],
        };
        push @results, { tool_call => $tc, result => $skip_result };
        $$raid_tool_calls++;
        next;
      }
      ( $name, $input ) = @plugin_tc;

      my $tool_t0 = $langfuse ? $engine->_langfuse_timestamp : undef;

      # Check for virtual self-tools
      if ($name =~ /^raider_/ && $self->has_raider_mcp) {
        my $self_result = $self->_execute_self_tool($name, $input);

        # Handle interactive self-tool results
        if ($self_result->{type} eq 'question' || $self_result->{type} eq 'pause') {
          # Save continuation state for respond_f
          $self->_continuation({
            state          => $state,
            iteration      => $iteration,
            data           => $data,
            pending_tc     => $tc,
            remaining_tcs  => [grep { $_ != $tc } @$tool_calls],
            results_so_far => \@results,
            iter_span_id   => $iter_span_id,
          });

          if ($self_result->{type} eq 'question') {
            return Langertha::Raider::Result->new(
              type    => 'question',
              content => $self_result->{question},
              $self_result->{options} ? (options => $self_result->{options}) : (),
            );
          } else {
            return Langertha::Raider::Result->new(
              type    => 'pause',
              content => $self_result->{reason},
            );
          }
        }

        if ($self_result->{type} eq 'abort') {
          # Finalize metrics before aborting
          my $elapsed = tv_interval($t0) * 1000;
          my $m = $self->metrics;
          $m->{iterations}  += $$raid_iterations;
          $m->{tool_calls}  += $$raid_tool_calls;
          $m->{time_ms}     += $elapsed;

          return Langertha::Raider::Result->new(
            type    => 'abort',
            content => $self_result->{reason},
          );
        }

        if ($self_result->{type} eq 'wait') {
          my $loop = $engine->_async_http->loop;
          await $loop->delay_future(after => $self_result->{seconds});
          my $result = {
            content => [{ type => 'text', text => "Waited $self_result->{seconds} seconds." }],
          };

          if ($langfuse) {
            $engine->langfuse_span(
              trace_id              => $trace_id,
              parent_observation_id => $iter_span_id,
              name                  => "tool: $name",
              input                 => $input,
              output                => "Waited $self_result->{seconds} seconds.",
              start_time            => $tool_t0,
              end_time              => $engine->_langfuse_timestamp,
            );
          }

          push @results, { tool_call => $tc, result => $result };
          $$raid_tool_calls++;
          next;
        }

        # type eq 'result' — normal self-tool result
        my $result = $self_result;

        # Plugin hook: transform tool result
        for my $plugin (@{$self->_plugin_instances}) {
          $result = await $plugin->plugin_after_tool_call($name, $input, $result);
        }

        if ($langfuse) {
          my $tool_output = join('', map { $_->{text} // '' } @{$result->{content} // []});
          $engine->langfuse_span(
            trace_id              => $trace_id,
            parent_observation_id => $iter_span_id,
            name                  => "tool: $name",
            input                 => $input,
            output                => $tool_output,
            start_time            => $tool_t0,
            end_time              => $engine->_langfuse_timestamp,
          );
        }

        push @results, { tool_call => $tc, result => $result };
        $$raid_tool_calls++;
        next;
      }

      # Normal MCP tool call
      my $mcp = $tool_server_map->{$name}
        or die "Tool '$name' not found on any MCP server";

      my $result = await $mcp->call_tool($name, $input)->else(sub {
        my ( $error ) = @_;
        Future->done({
          content => [{ type => 'text', text => "Error calling tool '$name': $error" }],
          isError => JSON::MaybeXS->true,
        });
      });

      # Plugin hook: transform tool result
      for my $plugin (@{$self->_plugin_instances}) {
        $result = await $plugin->plugin_after_tool_call($name, $input, $result);
      }

      # Langfuse: span for each tool call, nested under iteration span
      if ($langfuse) {
        my $tool_output = join('', map { $_->{text} // '' } @{$result->{content} // []});
        $engine->langfuse_span(
          trace_id              => $trace_id,
          parent_observation_id => $iter_span_id,
          name                  => "tool: $name",
          input                 => $input,
          output                => $tool_output,
          start_time            => $tool_t0,
          end_time              => $engine->_langfuse_timestamp,
          $result->{isError} ? ( level => 'ERROR' ) : (),
        );
      }

      push @results, { tool_call => $tc, result => $result };
      $$raid_tool_calls++;
    }

    # Langfuse: close iteration span after tools complete
    if ($langfuse) {
      $engine->langfuse_update_span(
        id       => $iter_span_id,
        end_time => $engine->_langfuse_timestamp,
        metadata => {
          tool_calls => scalar @$tool_calls,
          tools_used => [map {
            ($engine->extract_tool_call($_->{tool_call}))[0]
          } @results],
        },
      );
    }

    # Append assistant + tool results to conversation and session_history
    my @tool_msgs = $engine->format_tool_results($data, \@results);
    push @$conversation, @tool_msgs;
    $self->_push_session_history(@tool_msgs);
  }

  die "Raider tool loop exceeded ".$self->max_iterations." iterations";
}

async sub respond_f {
  my ( $self, $answer ) = @_;
  croak "No pending interaction — call raid_f first"
    unless $self->has_continuation;

  my $cont = $self->_continuation;
  $self->clear_continuation;

  my $state      = $cont->{state};
  my $data       = $cont->{data};
  my $pending_tc = $cont->{pending_tc};
  my @results    = @{$cont->{results_so_far}};
  my $engine     = $state->{engine};

  # Add the answer as the tool result for the pending self-tool call
  my $answer_result = {
    content => [{ type => 'text', text => "$answer" }],
  };
  push @results, { tool_call => $pending_tc, result => $answer_result };
  ${$state->{raid_tool_calls}}++;

  # Execute remaining tool calls from the same batch
  for my $tc (@{$cont->{remaining_tcs}}) {
    my ( $name, $input ) = $engine->extract_tool_call($tc);

    if ($name =~ /^raider_/ && $self->has_raider_mcp) {
      my $self_result = $self->_execute_self_tool($name, $input);
      if ($self_result->{type} eq 'result') {
        for my $plugin (@{$self->_plugin_instances}) {
          $self_result = await $plugin->plugin_after_tool_call($name, $input, $self_result);
        }
        push @results, { tool_call => $tc, result => $self_result };
        ${$state->{raid_tool_calls}}++;
      }
      # For simplicity, skip interactive self-tools in remaining batch
      next;
    }

    my $mcp = $state->{tool_server_map}{$name}
      or die "Tool '$name' not found on any MCP server";

    my $result = await $mcp->call_tool($name, $input)->else(sub {
      my ( $error ) = @_;
      Future->done({
        content => [{ type => 'text', text => "Error calling tool '$name': $error" }],
        isError => JSON::MaybeXS->true,
      });
    });

    for my $plugin (@{$self->_plugin_instances}) {
      $result = await $plugin->plugin_after_tool_call($name, $input, $result);
    }

    push @results, { tool_call => $tc, result => $result };
    ${$state->{raid_tool_calls}}++;
  }

  # Close iteration span if Langfuse
  if ($state->{langfuse} && $cont->{iter_span_id}) {
    $engine->langfuse_update_span(
      id       => $cont->{iter_span_id},
      end_time => $engine->_langfuse_timestamp,
      metadata => { tool_calls => scalar @results },
    );
  }

  # Format tool results and append to conversation
  my @tool_msgs = $engine->format_tool_results($data, \@results);
  push @{$state->{conversation}}, @tool_msgs;
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

version 0.309

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

=item * Cumulative metrics tracking

=item * Hermes tool calling support (inherited from engine)

=item * Mid-raid context injection via C<inject()> and C<on_iteration>

=back

B<History management:> Only user messages and final assistant text
responses are persisted in history. Intermediate tool-call messages
(assistant tool requests and tool results) are NOT persisted, preventing
token bloat across long conversations.

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
history is summarized via LLM before the next raid.

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
C<reset>. Only cleared manually via C<< $raider->session_history([]) >>.

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

=head2 no_session_embeddings

When true, disables automatic embedding computation for session history
entries. Useful when the engine supports embeddings but calling it would
cause issues (e.g. self-referencing proxy deadlock).

=head2 clear_history

    $raider->clear_history;

Clears conversation history and pending injections while preserving metrics.

=head2 add_history

    $raider->add_history('user', 'Hello');
    $raider->add_history('assistant', 'Hi there!');

Appends a message to the conversation history. Useful for replaying
persisted messages into a fresh Raider instance.

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
automatically resets to the default engine.

=head2 compress_history_f

    my $summary = await $raider->compress_history_f;

Async. Summarizes the current working history via LLM and replaces it
with the summary. Uses C<compression_engine> if set, otherwise falls
back to C<engine>. A marker is added to C<session_history>.

=head2 compress_history

    my $summary = $raider->compress_history;

Synchronous wrapper around C<compress_history_f>.

=head2 register_session_history_tool

    $raider->register_session_history_tool($mcp_server);

Registers a C<session_history> MCP tool on the given server, allowing
the LLM to query its own full session history. Supports C<query>
(text filter) and C<last_n> (return last N messages) parameters.

=head2 raid

    my $response = $raider->raid(@messages);

Synchronous wrapper around C<raid_f>. Sends messages, runs the tool
loop, and returns the final text response. Updates history and metrics.

=head2 raid_f

    my $result = await $raider->raid_f(@messages);

Async tool-calling conversation. Accepts the same message arguments as
C<simple_chat> (strings become user messages, hashrefs pass through).
Returns a L<Future> resolving to a L<Langertha::Raider::Result>.

The result stringifies to the final text (backward compatible), but also
provides C<type>, C<is_final>, C<is_question>, C<is_pause>, C<is_abort>
for programmatic handling of interactive self-tools.

=head2 respond_f

    my $result = await $raider->respond_f($answer);

Continue a paused raid after a C<question> or C<pause> result. The answer
is used as the tool result and the raid loop resumes. Returns the next
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

Plugin instances are created automatically with C<< raider => $self >>.
Extra constructor arguments can be passed via C<_plugin_args>.

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
L<https://github.com/Getty/langertha/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
