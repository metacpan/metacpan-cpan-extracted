package Langertha::Knarr::Config;
our $VERSION = '1.102';
# ABSTRACT: YAML configuration loader and validator
use Moo;
use YAML::PP;
use Carp qw( croak );
use Log::Any qw( $log );
use Langertha ();


has file => (
  is        => 'ro',
  predicate => 'has_file',
);


has data => (
  is      => 'lazy',
  builder => '_build_data',
);


sub _build_data {
  my ($self) = @_;
  return {} unless $self->has_file;
  my $file = $self->file;
  croak "Config file not found: $file" unless -f $file;
  my $ypp = YAML::PP->new;
  my $data = eval { $ypp->load_file($file) };
  croak "Config file $file is not valid YAML: ".$self->_error_text($@) if $@;
  croak "Config file $file must be a mapping of key: value pairs"
    unless ref $data eq 'HASH';
  _interpolate_env($data);
  $log->debugf("Loaded config from %s", $file);
  return $data;
}

# Recursively interpolate ${ENV_VAR} in string values
sub _interpolate_env {
  my ($ref) = @_;
  if (ref $ref eq 'HASH') {
    for my $key (keys %$ref) {
      if (ref $ref->{$key}) {
        _interpolate_env($ref->{$key});
      } elsif (defined $ref->{$key}) {
        $ref->{$key} =~ s/\$\{(\w+)\}/$ENV{$1} \/\/ ''/ge;
      }
    }
  } elsif (ref $ref eq 'ARRAY') {
    for my $i (0..$#$ref) {
      if (ref $ref->[$i]) {
        _interpolate_env($ref->[$i]);
      } elsif (defined $ref->[$i]) {
        $ref->[$i] =~ s/\$\{(\w+)\}/$ENV{$1} \/\/ ''/ge;
      }
    }
  }
}

# Engine catalog: which Langertha engines are worth auto-detecting from the
# environment, and under which variable names, in priority order.
# First match wins per engine: LANGERTHA_ > bare vendor name > TEST_.
#
# Only hosted, API-key authenticated engines belong here. Local engines
# (Ollama, LMStudio, vLLM, SGLang, LlamaCpp, Whisper) are reached by URL and
# have no meaningful key to detect, and protocol variants of an engine
# (MiniMaxAnthropic, MoonshotAnthropic, AKIOpenAI, OpenAIResponses) share
# their vendor's key — listing them would emit two model entries per key.
my @ENGINE_DEFS = (
  { engine => 'OpenAI',      vars => [qw( LANGERTHA_OPENAI_API_KEY       OPENAI_API_KEY       TEST_LANGERTHA_OPENAI_API_KEY       )] },
  { engine => 'Anthropic',   vars => [qw( LANGERTHA_ANTHROPIC_API_KEY    ANTHROPIC_API_KEY    TEST_LANGERTHA_ANTHROPIC_API_KEY    )] },
  { engine => 'Groq',        vars => [qw( LANGERTHA_GROQ_API_KEY         GROQ_API_KEY         TEST_LANGERTHA_GROQ_API_KEY         )] },
  { engine => 'Mistral',     vars => [qw( LANGERTHA_MISTRAL_API_KEY      MISTRAL_API_KEY      TEST_LANGERTHA_MISTRAL_API_KEY      )] },
  { engine => 'DeepSeek',    vars => [qw( LANGERTHA_DEEPSEEK_API_KEY     DEEPSEEK_API_KEY     TEST_LANGERTHA_DEEPSEEK_API_KEY     )] },
  { engine => 'MiniMax',     vars => [qw( LANGERTHA_MINIMAX_API_KEY      MINIMAX_API_KEY      TEST_LANGERTHA_MINIMAX_API_KEY      )] },
  { engine => 'Cerebras',    vars => [qw( LANGERTHA_CEREBRAS_API_KEY     CEREBRAS_API_KEY     TEST_LANGERTHA_CEREBRAS_API_KEY     )] },
  { engine => 'OpenRouter',  vars => [qw( LANGERTHA_OPENROUTER_API_KEY   OPENROUTER_API_KEY   TEST_LANGERTHA_OPENROUTER_API_KEY   )] },
  { engine => 'Perplexity',  vars => [qw( LANGERTHA_PERPLEXITY_API_KEY   PERPLEXITY_API_KEY   TEST_LANGERTHA_PERPLEXITY_API_KEY   )] },
  { engine => 'Replicate',   vars => [qw( LANGERTHA_REPLICATE_API_KEY    REPLICATE_API_TOKEN  TEST_LANGERTHA_REPLICATE_API_KEY    )] },
  { engine => 'HuggingFace', vars => [qw( LANGERTHA_HUGGINGFACE_API_KEY  HUGGINGFACE_API_KEY  TEST_LANGERTHA_HUGGINGFACE_API_KEY  )] },
  { engine => 'Gemini',      vars => [qw( LANGERTHA_GEMINI_API_KEY       GEMINI_API_KEY       TEST_LANGERTHA_GEMINI_API_KEY       )] },
  { engine => 'XAI',         vars => [qw( LANGERTHA_XAI_API_KEY          XAI_API_KEY          TEST_LANGERTHA_XAI_API_KEY          )] },
  { engine => 'Moonshot',    vars => [qw( LANGERTHA_MOONSHOT_API_KEY     MOONSHOT_API_KEY     TEST_LANGERTHA_MOONSHOT_API_KEY     )] },
  { engine => 'NousResearch', vars => [qw( LANGERTHA_NOUSRESEARCH_API_KEY NOUSRESEARCH_API_KEY TEST_LANGERTHA_NOUSRESEARCH_API_KEY )] },
  { engine => 'AKI',         vars => [qw( LANGERTHA_AKI_API_KEY          AKI_API_KEY          TEST_LANGERTHA_AKI_API_KEY          )] },
  { engine => 'Scaleway',    vars => [qw( LANGERTHA_SCALEWAY_API_KEY     SCALEWAY_API_KEY     TEST_LANGERTHA_SCALEWAY_API_KEY     )] },
  { engine => 'TSystems',    vars => [qw( LANGERTHA_TSYSTEMS_API_KEY     TSYSTEMS_API_KEY     TEST_LANGERTHA_TSYSTEMS_API_KEY     )] },
  # No bare HETZNER_API_KEY: that name is in wide use for the Hetzner Cloud
  # infrastructure API and would false-positive into an unusable model entry.
  { engine => 'Hetzner',     vars => [qw( LANGERTHA_HETZNER_API_KEY                           TEST_LANGERTHA_HETZNER_API_KEY      )] },
);

# Last resort for engines whose Langertha class deliberately has no usable
# default_model (it croaks, demanding an explicit model). Everything else is
# read off the engine class — see default_model_for. An engine only belongs
# here while its class refuses to name a default; t/10-config.t asserts that.
my %DEFAULT_MODEL_FALLBACK = (
  Groq       => 'llama-3.3-70b-versatile',
  OpenRouter => 'openai/gpt-4o-mini',
);

my %DEFAULT_MODEL_CACHE;


sub engine_catalog {
  return [ map { { engine => $_->{engine}, vars => [@{$_->{vars}}] } } @ENGINE_DEFS ];
}


sub default_model_for {
  my ($class, $engine) = @_;
  return undef unless defined $engine && length $engine;
  return $DEFAULT_MODEL_CACHE{$engine} if exists $DEFAULT_MODEL_CACHE{$engine};

  my $model;
  my $engine_class = eval { Langertha->resolve_engine_class($engine) };
  if (!defined $engine_class) {
    $log->debugf("No Langertha engine class for %s: %s", $engine, $@);
  } elsif ($engine_class->can('default_model')) {
    # Engines without a sensible default croak here instead of returning one.
    $model = eval { $engine_class->default_model };
    $log->debugf("Engine %s names no default model: %s", $engine, $@)
      unless defined $model;
  }

  undef $model unless defined $model && length $model;
  $model = $DEFAULT_MODEL_FALLBACK{$engine} unless defined $model;

  return $DEFAULT_MODEL_CACHE{$engine} = $model;
}


# Build config purely from environment variables (zero-config Docker mode)
sub from_env {
  my ($class, %opts) = @_;
  my $found = $class->scan_env(%opts);

  my %models;
  for my $engine (keys %$found) {
    my $name = lc($engine);
    $models{$name} = {
      engine      => $engine,
      model       => $class->default_model_for($engine),
      api_key_env => $found->{$engine}{api_key_env},
    };
  }

  my %data = (
    models        => \%models,
    auto_discover => 1,
    passthrough   => 1,
  );

  # Set default engine if OpenAI found, reading its key from the variable
  # that was found: the engine by itself reads only LANGERTHA_OPENAI_API_KEY
  # (k45)
  if ($found->{OpenAI}) {
    $data{default} = { engine => 'OpenAI', api_key_env => $found->{OpenAI}{api_key_env} };
  }

  return $class->new(data => \%data);
}

has listen => (
  is      => 'lazy',
  builder => '_build_listen',
);


sub _build_listen {
  my ($self) = @_;
  my $raw = $self->data->{listen};
  return ['127.0.0.1:8080', '127.0.0.1:11434'] unless defined $raw;
  my $list = ref $raw eq 'ARRAY' ? $raw : [$raw];
  # A mapping would be bound as "HASH(0x...)" (k67); validate reports it
  croak "listen must be a host:port string or a list of them"
    if grep { ref } @$list;
  return $list;
}

has models => (
  is      => 'lazy',
  builder => '_build_models',
);


sub _build_models {
  my ($self) = @_;
  my $models = $self->_section('models') // {};
  $self->_warn_unused_context_size( "Model '$_'", $models->{$_} )
    for sort keys %$models;
  return $models;
}

# A context_size only reaches engines that compose Role::ContextSize (k30);
# say so once, at load, instead of dropping the operator's intent silently.
# An engine class that does not load is left for the router to report.
sub _warn_unused_context_size {
  my ($self, $label, $def) = @_;
  return unless ref $def eq 'HASH'
    && defined $def->{context_size} && $def->{engine};
  my $class = eval { Langertha->resolve_engine_class( $def->{engine} ) };
  return if !defined $class || $class->can('context_size');
  $log->warnf( "%s: engine %s does not take context_size, ignoring it",
    $label, $def->{engine} );
}

has default_engine => (
  is      => 'lazy',
  builder => '_build_default_engine',
);


sub _build_default_engine {
  my ($self) = @_;
  my $default = $self->_section('default');
  $self->_warn_unused_context_size( 'Default', $default );
  return $default;
}

has log_file => (
  is      => 'lazy',
  builder => '_build_log_file',
);


sub _build_log_file {
  my ($self) = @_;
  return ( $self->_section('logging') // {} )->{file} // _strip_quotes($ENV{KNARR_LOG_FILE}) // undef;
}

has log_dir => (
  is      => 'lazy',
  builder => '_build_log_dir',
);


sub _build_log_dir {
  my ($self) = @_;
  return ( $self->_section('logging') // {} )->{dir} // _strip_quotes($ENV{KNARR_LOG_DIR}) // undef;
}

has langfuse => (
  is      => 'lazy',
  builder => '_build_langfuse',
);


sub _build_langfuse {
  my ($self) = @_;
  return $self->_section('langfuse') // {};
}

has langfuse_transport => (
  is      => 'lazy',
  builder => '_build_langfuse_transport',
);


sub _build_langfuse_transport {
  my ($self) = @_;
  my $value = $self->langfuse->{transport} // _strip_quotes($ENV{KNARR_LANGFUSE_TRANSPORT});
  return 'ingestion' unless defined $value && length $value;
  croak "langfuse.transport '$value' must be ingestion or otel"
    unless $value =~ /\A(?:ingestion|otel)\z/i;
  return lc $value;
}

has langfuse_timeout => (
  is      => 'lazy',
  builder => '_build_langfuse_timeout',
);


sub _build_langfuse_timeout {
  my ($self) = @_;
  return _seconds( 'langfuse.timeout' =>
    $self->langfuse->{timeout} // _strip_quotes($ENV{KNARR_LANGFUSE_TIMEOUT}), 15 );
}

has proxy_api_key => (
  is      => 'lazy',
  builder => '_build_proxy_api_key',
);


sub _build_proxy_api_key {
  my ($self) = @_;
  return $self->data->{proxy_api_key} // $ENV{KNARR_API_KEY} // undef;
}

sub has_proxy_api_key {
  my ($self) = @_;
  return defined $self->proxy_api_key;
}

has public_url => (
  is      => 'lazy',
  builder => '_build_public_url',
);


sub _build_public_url {
  my ($self) = @_;
  return $self->data->{public_url} // $ENV{KNARR_PUBLIC_URL} // undef;
}


has ollama_compat_version => (
  is      => 'lazy',
  builder => '_build_ollama_compat_version',
);


sub _build_ollama_compat_version {
  my ($self) = @_;
  my $version = $self->data->{ollama_compat_version} // $ENV{KNARR_OLLAMA_COMPAT_VERSION};
  return undef unless defined $version;
  # Open WebUI int()s every dotted part (k28): digits and dots only.
  croak "ollama_compat_version '$version' must be three dot-separated numbers"
    . " like 0.34.4 (Ollama clients parse each part as an integer)"
    unless $version =~ /\A\d+\.\d+\.\d+\z/;
  return $version;
}

has a2a_name => (
  is      => 'lazy',
  builder => '_build_a2a_name',
);


sub _build_a2a_name {
  my ($self) = @_;
  return ( $self->_section('a2a') // {} )->{name} // _strip_quotes($ENV{KNARR_A2A_NAME}) // undef;
}

has a2a_description => (
  is      => 'lazy',
  builder => '_build_a2a_description',
);


sub _build_a2a_description {
  my ($self) = @_;
  return ( $self->_section('a2a') // {} )->{description} // _strip_quotes($ENV{KNARR_A2A_DESCRIPTION}) // undef;
}

sub protocol_args {
  my ($self) = @_;
  return { A2A => {
    ( defined $self->a2a_name ? ( agent_name => $self->a2a_name ) : () ),
    ( defined $self->a2a_description ? ( agent_description => $self->a2a_description ) : () ),
  } };
}


has upstream_timeout => (
  is      => 'lazy',
  builder => '_build_upstream_timeout',
);


sub _build_upstream_timeout {
  my ($self) = @_;
  return _seconds( upstream_timeout =>
    $self->data->{upstream_timeout} // _strip_quotes($ENV{KNARR_UPSTREAM_TIMEOUT}), 300 );
}

has upstream_stall_timeout => (
  is      => 'lazy',
  builder => '_build_upstream_stall_timeout',
);


sub _build_upstream_stall_timeout {
  my ($self) = @_;
  return _seconds( upstream_stall_timeout =>
    $self->data->{upstream_stall_timeout} // _strip_quotes($ENV{KNARR_UPSTREAM_STALL_TIMEOUT}), 120 );
}

has probe_capabilities => (
  is      => 'lazy',
  builder => '_build_probe_capabilities',
);


sub _build_probe_capabilities {
  my ($self) = @_;
  my $value = $self->data->{probe_capabilities};
  unless ( defined $value ) {
    $value = _strip_quotes($ENV{KNARR_PROBE_CAPABILITIES});
    return 1 unless defined $value && length $value;
  }
  return !$value || $value =~ /\A(?:false|no|off)\z/i ? 0 : 1;
}

has probe_timeout => (
  is      => 'lazy',
  builder => '_build_probe_timeout',
);


sub _build_probe_timeout {
  my ($self) = @_;
  return _seconds( probe_timeout =>
    $self->data->{probe_timeout} // _strip_quotes($ENV{KNARR_PROBE_TIMEOUT}), 10 );
}

has workers => (
  is      => 'lazy',
  builder => '_build_workers',
);


sub _build_workers {
  my ($self) = @_;
  my $value = $self->data->{workers} // _strip_quotes($ENV{KNARR_WORKERS});
  return 1 unless defined $value && length $value;
  croak "workers '$value' must be a whole number of 1 or more"
    unless $value =~ /\A[1-9][0-9]*\z/;
  return $value + 0;
}

# A config section (models:, default:, logging:, ...) that is not a mapping
# croaks when read (k67), instead of dying later as a HASH dereference;
# validate reports it.
sub _section {
  my ($self, $key) = @_;
  my $value = $self->data->{$key};
  return $value if !defined $value || ref $value eq 'HASH';
  croak "$key must be a mapping of key: value pairs, not "
    . ( ref $value eq 'ARRAY' ? 'a list' : "'".$value."'" );
}

sub _seconds {
  my ($name, $value, $default) = @_;
  return $default unless defined $value && length $value;
  croak "$name '$value' must be a number of seconds (0 disables it)"
    unless $value =~ /\A(?:\d+(?:\.\d*)?|\.\d+)\z/;
  return $value + 0;
}

has auto_discover => (
  is      => 'lazy',
  builder => '_build_auto_discover',
);


sub _build_auto_discover {
  my ($self) = @_;
  return $self->data->{auto_discover} // 0;
}

my %PASSTHROUGH_DEFAULTS = (
  anthropic => 'https://api.anthropic.com',
  openai    => 'https://api.openai.com',
);

has passthrough => (
  is      => 'lazy',
  builder => '_build_passthrough',
);


sub _build_passthrough {
  my ($self) = @_;
  my $raw = $self->data->{passthrough};
  return {} unless defined $raw;

  # passthrough: true → enable all with default URLs
  if (!ref $raw) {
    return $raw ? { %PASSTHROUGH_DEFAULTS } : {};
  }

  croak "passthrough must be true, false or a mapping of format: URL, not a list"
    unless ref $raw eq 'HASH';

  my %result;
  for my $format (keys %$raw) {
    my $val = $raw->{$format};
    next unless $val;
    if ($val eq '1' || $val eq 'true') {
      $result{$format} = $PASSTHROUGH_DEFAULTS{$format} // next;
    } else {
      # Custom URL
      $result{$format} = $val;
    }
  }
  return \%result;
}

sub passthrough_url_for {
  my ($self, $format) = @_;
  return $self->passthrough->{$format};
}



sub validate {
  my ($self) = @_;
  my @errors;

  # A file that does not load leaves nothing else to check (k67)
  return $self->_error_text($@) unless eval { $self->data; 1 };

  # A section that is not a mapping croaks when read (k67)
  for my $key (qw( models default langfuse logging a2a )) {
    push @errors, $self->_error_text($@) unless eval { $self->_section($key); 1 };
  }
  for my $attr (qw( passthrough listen )) {
    push @errors, $self->_error_text($@) unless eval { $self->$attr; 1 };
  }
  return @errors if @errors;

  my $models = $self->models;
  for my $name (keys %$models) {
    my $def = $models->{$name};
    if ( defined $def && ref $def ne 'HASH' ) {
      push @errors, "Model '$name' must be a mapping of key: value pairs";
      next;
    }
    unless ($def->{engine}) {
      push @errors, "Model '$name': missing 'engine' key";
    }
    if ( defined $def->{context_size} && $def->{context_size} !~ /\A[1-9][0-9]*\z/ ) {
      push @errors, "Model '$name': context_size must be a positive integer";
    }
    unless ( eval { _seconds( user_agent_timeout => $def->{user_agent_timeout}, 0 ); 1 } ) {
      push @errors, "Model '$name': user_agent_timeout must be a number of seconds";
    }
  }

  if (my $default = $self->default_engine) {
    unless ($default->{engine}) {
      push @errors, "Default: missing 'engine' key";
    }
    if ( defined $default->{context_size} && $default->{context_size} !~ /\A[1-9][0-9]*\z/ ) {
      push @errors, "Default: context_size must be a positive integer";
    }
    unless ( eval { _seconds( user_agent_timeout => $default->{user_agent_timeout}, 0 ); 1 } ) {
      push @errors, "Default: user_agent_timeout must be a number of seconds";
    }
  }

  unless (keys %$models || $self->default_engine) {
    push @errors, "No models configured and no default engine set";
  }

  for my $attr (qw( ollama_compat_version upstream_timeout upstream_stall_timeout probe_timeout workers langfuse_transport langfuse_timeout )) {
    next if eval { $self->$attr; 1 };
    push @errors, $self->_error_text($@);
  }

  return @errors;
}

# A croak as a validation error: without the trailing "at FILE line N."
sub _error_text {
  my ($self, $err) = @_;
  $err =~ s/\s+at \S+ line \d+\.?\s*\z//;
  return $err;
}

sub engine_definitions {
  my ($self) = @_;
  my %defs;
  my $models = $self->models;
  for my $name (keys %$models) {
    $defs{$name} = { %{$models->{$name}}, name => $name };
  }
  return \%defs;
}


# Scan environment and .env files for API keys, return model config suggestions
sub scan_env {
  my ($class, %opts) = @_;
  my @env_files = @{$opts{env_files} // []};
  my %env = %ENV;

  # Load .env files
  for my $file (@env_files) {
    next unless -f $file;
    open my $fh, '<', $file or next;
    while (<$fh>) {
      chomp;
      next if /^\s*#/ || /^\s*$/;
      if (/^\s*(?:export\s+)?(\w+)\s*=\s*['"]?(.*?)['"]?\s*$/) {
        $env{$1} = $2;
      }
    }
    close $fh;
  }

  my $include_test = $opts{include_test} // 1;

  my %found;
  for my $def (@ENGINE_DEFS) {
    for my $var (@{$def->{vars}}) {
      next unless $env{$var};
      next if !$include_test && $var =~ /^TEST_/;
      $found{$def->{engine}} = {
        engine      => $def->{engine},
        api_key_env => $var,
      };
      last; # first match wins (priority order)
    }
  }

  return \%found;
}


# Generate a YAML config string from scan results
sub generate_config {
  my ($class, %opts) = @_;
  my $found = $opts{engines} // {};
  my $listen = $opts{listen} // ['127.0.0.1:8080', '127.0.0.1:11434'];
  $listen = [$listen] unless ref $listen eq 'ARRAY';

  my @lines;
  push @lines, "# Knarr configuration - auto-generated";
  push @lines, "listen:";
  for my $addr (@$listen) {
    push @lines, "  - \"$addr\"";
  }
  push @lines, "";
  push @lines, "models:";

  for my $engine (sort keys %$found) {
    my $info = $found->{$engine};
    my $model = $class->default_model_for($engine);
    my $name = lc($engine);
    $name .= "-default" if $name eq 'openai' || $name eq 'anthropic';
    push @lines, "  $name:";
    push @lines, "    engine: $engine";
    push @lines, "    model: $model" if $model;
    push @lines, "    api_key_env: $info->{api_key_env}" if $info->{api_key_env};
    push @lines, "";
  }

  unless (keys %$found) {
    my $example = $class->default_model_for('OpenAI') // 'gpt-4o-mini';
    push @lines, "  # No API keys found. Add your models here:";
    push @lines, "  # my-model:";
    push @lines, "  #   engine: OpenAI";
    push @lines, "  #   model: $example";
    push @lines, "";
  }

  push @lines, "# Default engine for models without explicit config (optional)";
  if ($found->{OpenAI}) {
    push @lines, "default:";
    push @lines, "  engine: OpenAI";
    push @lines, "  api_key_env: $found->{OpenAI}{api_key_env}" if $found->{OpenAI}{api_key_env};
  } else {
    push @lines, "# default:";
    push @lines, "#   engine: OpenAI";
  }
  push @lines, "";

  push @lines, "# Auto-discover models from configured engines";
  push @lines, "auto_discover: true";
  push @lines, "";

  push @lines, "# Optional: proxy authentication";
  push @lines, "# proxy_api_key: your-secret-key";
  push @lines, "";

  push @lines, "# Optional: Langfuse tracing (or set env vars)";
  push @lines, "# langfuse:";
  push @lines, "#   url: http://localhost:3000";
  push @lines, "#   public_key: pk-lf-...";
  push @lines, "#   secret_key: sk-lf-...";
  push @lines, "#   transport: otel   # default ingestion; otel needs Langfuse Cloud or v3.22+";
  push @lines, "#   timeout: 15       # seconds per trace POST, 0 disables";

  return join("\n", @lines) . "\n";
}

# Strip surrounding quotes from env values (Docker --env-file includes them literally)
sub _strip_quotes {
  my $v = shift;
  return $v unless defined $v;
  $v =~ s/^["']|["']$//g;
  return $v;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Config - YAML configuration loader and validator

=head1 VERSION

version 1.102

=head1 SYNOPSIS

    use Langertha::Knarr::Config;

    # Load from file
    my $config = Langertha::Knarr::Config->new(file => 'knarr.yaml');

    # Build from environment (Docker zero-config mode)
    my $config = Langertha::Knarr::Config->from_env;

    # Validate
    my @errors = $config->validate;
    die join("\n", @errors) if @errors;

=head1 DESCRIPTION

Loads and validates Knarr configuration from a YAML file or from environment
variables. All string values in the YAML file support C<${ENV_VAR}>
interpolation.

The attributes below are the configuration file reference: each one
names its YAML key and, where there is one, its environment variable. The
README has an annotated example, and C<share/example-config.yaml> in the
distribution is a commented starting point.

=head2 file

Path to the YAML configuration file. Optional — when omitted the config
object starts with an empty data hash (useful for testing or for
configs built purely from environment variables via L</from_env>).

=head2 data

The raw configuration hashref, loaded from L</file> and with all
C<${ENV_VAR}> references expanded. Can be supplied directly to bypass
file loading.

=head2 engine_catalog

    my $defs = Langertha::Knarr::Config->engine_catalog;
    for my $def (@$defs) { say $def->{engine}, ": @{$def->{vars}}" }

Class method. Returns an ArrayRef of C<{engine, vars}> hashrefs describing
every engine L</scan_env> can auto-detect, with its API key environment
variable names in priority order. The list is a copy — mutating it does not
affect scanning.

=head2 default_model_for

    my $model = Langertha::Knarr::Config->default_model_for('Anthropic');

Class method. Returns the default model name for an engine, read from the
Langertha engine class itself (C<< Langertha::Engine::Anthropic->default_model >>)
so the catalog cannot drift away from the framework. Returns C<undef> when the
engine class is not installed, or when it has no default model and no fallback
is known. The result is cached per engine name.

=head2 from_env

    my $config = Langertha::Knarr::Config->from_env(%opts);

Class method. Builds a config object purely from environment variables
(zero-config Docker mode). Calls L</scan_env> to detect which API keys are
set, assigns each detected engine its L</default_model_for> model, enables
C<auto_discover> and C<passthrough>, and sets OpenAI as the default engine
when an OpenAI key is present. Every generated entry, the default engine
included, names the variable its key was found in as C<api_key_env>, so
C<OPENAI_API_KEY> works as well as C<LANGERTHA_OPENAI_API_KEY>.

Options are passed through to L</scan_env> (e.g. C<include_test>).

=head2 listen

ArrayRef of C<host:port> strings to listen on (C<listen:>, a list or a
single string). Defaults to C<['127.0.0.1:8080', '127.0.0.1:11434']>, so
a config without C<listen:> only answers on loopback. C<knarr start -p>
replaces it with the given ports on C<-H> (default C<0.0.0.0>); the Docker
image starts that way.

=head2 models

HashRef of model name → model definition hashref from the C<models:> config
section. Each definition may include C<engine>, C<model>, C<api_key_env>,
C<api_key>, C<url>, C<system_prompt>, C<temperature>, C<response_size>,
C<context_size>, and C<user_agent_timeout> (seconds the engine waits for
its upstream; defaults to L</upstream_timeout>, C<0> disables it).

C<context_size> is passed to engines that compose
L<Langertha::Role::ContextSize> (Ollama, LMStudio native), which send it on
the wire (Ollama's C<num_ctx>, LM Studio's C<context_length>) and report it
from C</api/show>. For any other engine it is ignored, with one warning
when the models are loaded.

Models found by L</auto_discover> inherit the endpoint-level keys of the
entry they were discovered through, but not the model-specific C<model> and
C<context_size>; see L<Langertha::Knarr::Router/DESCRIPTION> for the split.

=head2 default_engine

HashRef from the C<default:> config section, or C<undef> if not set. At
minimum contains C<engine>. Used as the fallback when a model name is not
explicitly configured and no passthrough URL matches -- that is, no
L</passthrough> upstream exists for the protocol the client speaks (Ollama
without an C<ollama> entry, and A2A, ACP and AG-UI always). Without a
default engine such a request is answered with C<404> in the client
protocol's error shape.

A C<model> in this section is what the default engine uses for a request
that names no model (A2A always, ACP without C<agent_name>); a model the
client names replaces it. The section takes the same keys as a
L</models> entry, C<api_key_env> or C<api_key> included; without either
the engine reads only its own C<LANGERTHA_*_API_KEY> variable.

=head2 log_file

Path to a JSONL log file for request logging. Resolved from
C<logging.file> in config or C<KNARR_LOG_FILE> environment variable.

=head2 log_dir

Path to a directory for per-request JSON log files. Resolved from
C<logging.dir> in config or C<KNARR_LOG_DIR> environment variable.

=head2 langfuse

HashRef from the C<langfuse:> config section. May contain C<url>,
C<public_key>, C<secret_key>, C<trace_name>, C<transport> (see
L</langfuse_transport>) and C<timeout> (see L</langfuse_timeout>). Returns an empty hashref when the section is
absent.

=head2 langfuse_transport

How L<Langertha::Knarr::Tracing> sends traces to Langfuse: C<ingestion>
(the default) posts trace and generation events to Langfuse's
C</api/public/ingestion> API; C<otel> exports them as OpenTelemetry spans
(OTLP/HTTP, JSON encoded) to C</api/public/otel/v1/traces>, the path
Langfuse now recommends (Langfuse Cloud, or self-hosted v3.22 and later;
Langfuse v2 has only the ingestion API). See
L<Langertha::Knarr::Tracing/OpenTelemetry transport>. Read from C<langfuse.transport>, falling back to
the C<KNARR_LANGFUSE_TRANSPORT> environment variable, so it also applies
under C<--from-env>. Case does not matter. Any other value croaks when
read, and L</validate> reports it.

=head2 langfuse_timeout

Seconds a trace POST to Langfuse may take before it is given up and logged
as a C<Langfuse flush error> warning, for either
L</langfuse_transport>. Default C<15>; C<0> disables it. The POST never
holds a request, so this only decides when a slow Langfuse is reported as
failed. Read from C<langfuse.timeout>, falling back to the
C<KNARR_LANGFUSE_TIMEOUT> environment variable. A value that is not a
non-negative number croaks when read, and L</validate> reports it.

=head2 proxy_api_key

Optional shared secret that clients must present in the C<Authorization: Bearer>
or C<x-api-key> header. Falls back to the C<KNARR_API_KEY> environment variable.
When not set, the proxy is open (no auth required). It is never forwarded to a
passthrough upstream; see L<Langertha::Knarr/auth_token>.

=head2 public_url

Optional public base URL of this Knarr (e.g. C<https://knarr.example>),
published in the provider manifest at C</.well-known/langertha.json>. Falls
back to the C<KNARR_PUBLIC_URL> environment variable. When not set, the
manifest takes the base URL from each request.

=head2 has_proxy_api_key

    if ($config->has_proxy_api_key) { ... }

Returns true when a L</proxy_api_key> is configured.

=head2 ollama_compat_version

Optional Ollama version to report at C<GET /api/version> (see
L<Langertha::Knarr/ollama_compat_version>). Falls back to the
C<KNARR_OLLAMA_COMPAT_VERSION> environment variable. When not set, Knarr's
default applies. A value that is not three dot-separated numbers
(C<0.34.4>) croaks when read, and L</validate> reports it: Ollama clients
parse each part as an integer.

=head2 a2a_name

Optional name of the A2A agent card at C</.well-known/agent.json> (see
L<Langertha::Knarr::Protocol::A2A/agent_name>). Resolved from C<a2a.name> in
config or the C<KNARR_A2A_NAME> environment variable. When not set, the
card says C<Langertha Knarr Agent>.

=head2 a2a_description

Optional description of the A2A agent card (see
L<Langertha::Knarr::Protocol::A2A/agent_description>). Resolved from
C<a2a.description> in config or the C<KNARR_A2A_DESCRIPTION> environment
variable. When not set, Knarr's default description applies.

=head2 protocol_args

    my $knarr = Langertha::Knarr->new( ..., protocol_args => $config->protocol_args );

Returns the L<Langertha::Knarr/protocol_args> HashRef for the configured
protocol settings: C<< { A2A => { agent_name => ..., agent_description => ... } } >>,
with only the keys that are set (L</a2a_name>, L</a2a_description>).

=head2 upstream_timeout

Seconds an upstream may take to answer a non-streaming request. Default
C<300>; C<0> disables it. Falls back to the C<KNARR_UPSTREAM_TIMEOUT>
environment variable. It is the total time of a raw passthrough request
(answered with C<504> in the client protocol's error shape when it runs
out), and it becomes the C<user_agent_timeout> of every routed engine
whose model config sets none -- Langertha applies that as the total time
of a plain request and as the time without data of a streaming one. A
value that is not a non-negative number croaks when read, and
L</validate> reports it.

=head2 upstream_stall_timeout

Seconds a streaming raw passthrough request may go without data from the
upstream, the wait for its response headers included. Default C<120>;
C<0> disables it. Falls back to the C<KNARR_UPSTREAM_STALL_TIMEOUT>
environment variable. A stream that stalls before its headers is answered
with C<504>; one that stalls later ends with the protocol's error frame.
Croaks when read and is reported by L</validate> like
L</upstream_timeout>.

=head2 probe_capabilities

Boolean, default C<1>. When true, L<Langertha::Knarr/start> asks every routed
engine that can read its provider's model metadata (OpenRouter, Mistral,
LM Studio, T-Systems, Ollama, llama.cpp; Langertha core's C<probe_model_capabilities_f>)
which capabilities its model has, once at startup, after auto-discovery. What
it learns (today: whether the model sees images) then shows as C<vision> in
C<POST /api/show> and as C<image_input> in the provider manifest. Engines
without such metadata and a Langertha too old to probe (0.503) send nothing.
A failed probe is logged and changes nothing. Set C<0> (or
C<KNARR_PROBE_CAPABILITIES=0>) to never send these requests. See
L<Langertha::Knarr::Router/probe_capabilities_f>.

=head2 probe_timeout

Seconds one capability probe (see L</probe_capabilities>) may take before it
is given up and logged. Default C<10>; C<0> leaves only the engine's own
C<user_agent_timeout>. Falls back to C<KNARR_PROBE_TIMEOUT>. A value that is
not a non-negative number croaks when read, and L</validate> reports it.

=head2 workers

Number of processes C<knarr start> serves from. Default C<1>: one process,
nothing forked. With more, it forks that many workers on the same listen
sockets and supervises them (see L<Langertha::Knarr/workers>). Falls back
to C<KNARR_WORKERS>, so it also applies under C<--from-env>; C<knarr start
-w N> wins over both. A value that is not a whole number of C<1> or more
croaks when read, and L</validate> reports it.

=head2 auto_discover

Boolean. When true, L<Langertha::Knarr::Router> asks each configured
endpoint (engine, URL and API key variable) for its model list the first time
a model is resolved, making all discovered models available without
explicit config entries and listing them (C</v1/models>, C</api/tags>, the
manifest). A discovered model is routed through its engine, except when the
L</passthrough> upstream of the client's protocol is the endpoint that
listed it (same scheme, host, port and path, an engine's trailing C</v1>
aside, so a gateway's C</openai> and C</groq> paths are two upstreams) and
the request carries the client's own provider key (C<Authorization> for
OpenAI, C<x-api-key> or C<Authorization> for Anthropic, not counting the
L</proxy_api_key>; Ollama needs none): then it passes through byte for byte
like an unknown model, with that key. Without one it is routed through its
engine, with the engine's key, and so it is when the upstream refuses that
key with C<401> (see L<Langertha::Knarr/raw_passthrough>). A model under L</models> is always routed.
Defaults to C<0>; L</from_env> and the C<knarr init> output turn it on.

=head2 passthrough

HashRef of format name (C<openai>, C<anthropic>, C<ollama>) → upstream
base URL. Empty, and passthrough off, unless the config has a
C<passthrough:> key; L</from_env> turns it on. C<passthrough: true> in YAML
enables C<openai> and C<anthropic> with their default upstream URLs
(C<https://api.openai.com> and C<https://api.anthropic.com>); C<ollama>
has no default and needs its URL. Per-format URLs can be customised or set
to C<false> to disable selectively.

A request for a model that is neither configured nor auto-discovered (or
auto-discovered from that very upstream, see L</auto_discover>) goes
to the upstream of its protocol byte for byte, with the client's own
headers and key. A protocol without an upstream sends such a request to
the L</default_engine> instead.

=head2 passthrough_url_for

    my $url = $config->passthrough_url_for('openai');

Returns the upstream base URL for the given format name (e.g. C<openai> or
C<anthropic>), or C<undef> if passthrough is not configured for that format.

=head2 validate

    my @errors = $config->validate;

Validates the configuration and returns a list of error strings. Returns an
empty list when the config is valid. A config file that does not load (not
YAML, or not a mapping) is reported alone, and so are the sections
C<models>, C<default>, C<langfuse>, C<logging>, C<a2a> and C<passthrough>
when one is not a mapping (C<passthrough> may also be C<true> or C<false>),
and C<listen> when it is not a string or a list of strings: reading such a
section croaks. Otherwise it checks that every model entry is a
mapping with an
C<engine> key, that the default engine (if set) has an C<engine> key,
that at least one model or default engine is configured, that a model's
C<context_size> (and the default engine's), when set, is a positive integer, and its
C<user_agent_timeout> a non-negative number, and that
L</ollama_compat_version>, when set, is three dot-separated numbers, and that
L</upstream_timeout>, L</upstream_stall_timeout> and L</probe_timeout> are
non-negative numbers, and that L</workers> is a whole number of C<1> or
more.

=head2 scan_env

    my $found = Langertha::Knarr::Config->scan_env(
      env_files    => ['.env', '.env.local'],
      include_test => 1,
    );

Class method. Scans C<%ENV> and optional C<.env> files for known API key
environment variables. Returns a HashRef of engine name → C<{engine,
api_key_env}> for every engine whose key was found. See L</engine_catalog>
for the engines and variable names it knows about.

Priority order per engine: C<LANGERTHA_*_API_KEY> beats the bare vendor key
(e.g. C<OPENAI_API_KEY>), which beats the C<TEST_LANGERTHA_*_API_KEY> variant.

Options:

=over

=item * C<env_files> — ArrayRef of .env file paths to parse (optional)

=item * C<include_test> — Include C<TEST_*> variables (default: C<1>)

=back

=head2 generate_config

    my $yaml = Langertha::Knarr::Config->generate_config(
      engines => $found,       # from scan_env
      listen  => ['127.0.0.1:8080', '127.0.0.1:11434'],
    );

Class method. Generates a YAML configuration string from C<scan_env> results.
The generated YAML includes sensible defaults for each detected engine and
commented-out stanzas for optional features. Used by C<knarr init>.

Returns a string.

=head1 SEE ALSO

=over

=item * L<Langertha::Knarr> — Main documentation

=item * L<Langertha::Knarr::Router> — Uses config to resolve models to engines

=item * L<Langertha::Knarr::Tracing> — Uses config for Langfuse credentials

=item * L<Langertha::Knarr::RequestLog> — Uses config for request logging paths

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

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
