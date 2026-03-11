package Langertha::Knarr::Config;
our $VERSION = '0.007';
# ABSTRACT: YAML configuration loader and validator
use Moo;
use YAML::PP;
use Carp qw( croak );
use Log::Any qw( $log );


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
  my $data = $ypp->load_file($file);
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


# Build config purely from environment variables (zero-config Docker mode)
sub from_env {
  my ($class, %opts) = @_;
  my $found = $class->scan_env(%opts);

  my %default_models = (
    OpenAI     => 'gpt-4o-mini',
    Anthropic  => 'claude-sonnet-4-6',
    Groq       => 'llama-3.3-70b-versatile',
    Mistral    => 'mistral-large-latest',
    DeepSeek   => 'deepseek-chat',
    MiniMax    => 'MiniMax-M2.1',
    Cerebras   => 'llama-3.3-70b',
    OpenRouter => 'openai/gpt-4o-mini',
    Perplexity => 'sonar',
    Gemini     => 'gemini-2.0-flash',
  );

  my %models;
  for my $engine (keys %$found) {
    my $name = lc($engine);
    $models{$name} = {
      engine      => $engine,
      model       => $default_models{$engine},
      api_key_env => $found->{$engine}{api_key_env},
    };
  }

  my %data = (
    models        => \%models,
    auto_discover => 1,
    passthrough   => 1,
  );

  # Set default engine if OpenAI found
  if ($found->{OpenAI}) {
    $data{default} = { engine => 'OpenAI' };
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
  return ref $raw eq 'ARRAY' ? $raw : [$raw];
}

has models => (
  is      => 'lazy',
  builder => '_build_models',
);


sub _build_models {
  my ($self) = @_;
  return $self->data->{models} // {};
}

has default_engine => (
  is      => 'lazy',
  builder => '_build_default_engine',
);


sub _build_default_engine {
  my ($self) = @_;
  return $self->data->{default} // undef;
}

has log_file => (
  is      => 'lazy',
  builder => '_build_log_file',
);


sub _build_log_file {
  my ($self) = @_;
  return $self->data->{logging}{file} // _strip_quotes($ENV{KNARR_LOG_FILE}) // undef;
}

has log_dir => (
  is      => 'lazy',
  builder => '_build_log_dir',
);


sub _build_log_dir {
  my ($self) = @_;
  return $self->data->{logging}{dir} // _strip_quotes($ENV{KNARR_LOG_DIR}) // undef;
}

has langfuse => (
  is      => 'lazy',
  builder => '_build_langfuse',
);


sub _build_langfuse {
  my ($self) = @_;
  return $self->data->{langfuse} // {};
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

  return {} unless ref $raw eq 'HASH';

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

  my $models = $self->models;
  for my $name (keys %$models) {
    my $def = $models->{$name};
    unless ($def->{engine}) {
      push @errors, "Model '$name': missing 'engine' key";
    }
  }

  if (my $default = $self->default_engine) {
    unless ($default->{engine}) {
      push @errors, "Default: missing 'engine' key";
    }
  }

  unless (keys %$models || $self->default_engine) {
    push @errors, "No models configured and no default engine set";
  }

  return @errors;
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

  # Engine definitions with env var names in priority order
  # First match wins per engine: LANGERTHA_ > bare name > TEST_
  my @engine_defs = (
    { engine => 'OpenAI',     vars => [qw( LANGERTHA_OPENAI_API_KEY     OPENAI_API_KEY     TEST_LANGERTHA_OPENAI_API_KEY     )] },
    { engine => 'Anthropic',  vars => [qw( LANGERTHA_ANTHROPIC_API_KEY  ANTHROPIC_API_KEY  TEST_LANGERTHA_ANTHROPIC_API_KEY  )] },
    { engine => 'Groq',       vars => [qw( LANGERTHA_GROQ_API_KEY      GROQ_API_KEY       TEST_LANGERTHA_GROQ_API_KEY       )] },
    { engine => 'Mistral',    vars => [qw( LANGERTHA_MISTRAL_API_KEY   MISTRAL_API_KEY    TEST_LANGERTHA_MISTRAL_API_KEY    )] },
    { engine => 'DeepSeek',   vars => [qw( LANGERTHA_DEEPSEEK_API_KEY  DEEPSEEK_API_KEY   TEST_LANGERTHA_DEEPSEEK_API_KEY   )] },
    { engine => 'MiniMax',    vars => [qw( LANGERTHA_MINIMAX_API_KEY   MINIMAX_API_KEY    TEST_LANGERTHA_MINIMAX_API_KEY    )] },
    { engine => 'Cerebras',   vars => [qw( LANGERTHA_CEREBRAS_API_KEY  CEREBRAS_API_KEY   TEST_LANGERTHA_CEREBRAS_API_KEY   )] },
    { engine => 'OpenRouter', vars => [qw( LANGERTHA_OPENROUTER_API_KEY OPENROUTER_API_KEY TEST_LANGERTHA_OPENROUTER_API_KEY )] },
    { engine => 'Perplexity', vars => [qw( LANGERTHA_PERPLEXITY_API_KEY PERPLEXITY_API_KEY TEST_LANGERTHA_PERPLEXITY_API_KEY )] },
    { engine => 'Replicate',  vars => [qw( LANGERTHA_REPLICATE_API_KEY REPLICATE_API_TOKEN TEST_LANGERTHA_REPLICATE_API_KEY  )] },
    { engine => 'HuggingFace',vars => [qw( LANGERTHA_HUGGINGFACE_API_KEY HUGGINGFACE_API_KEY TEST_LANGERTHA_HUGGINGFACE_API_KEY )] },
    { engine => 'Gemini',     vars => [qw( LANGERTHA_GEMINI_API_KEY    GEMINI_API_KEY     TEST_LANGERTHA_GEMINI_API_KEY     )] },
  );

  my $include_test = $opts{include_test} // 1;

  my %found;
  for my $def (@engine_defs) {
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

  my %default_models = (
    OpenAI     => 'gpt-4o-mini',
    Anthropic  => 'claude-sonnet-4-6',
    Groq       => 'llama-3.3-70b-versatile',
    Mistral    => 'mistral-large-latest',
    DeepSeek   => 'deepseek-chat',
    MiniMax    => 'MiniMax-M2.1',
    Cerebras   => 'llama-3.3-70b',
    OpenRouter => 'openai/gpt-4o-mini',
    Perplexity => 'sonar',
    Gemini     => 'gemini-2.0-flash',
  );

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
    my $model = $default_models{$engine};
    my $name = lc($engine);
    $name .= "-default" if $name eq 'openai' || $name eq 'anthropic';
    push @lines, "  $name:";
    push @lines, "    engine: $engine";
    push @lines, "    model: $model" if $model;
    push @lines, "    api_key_env: $info->{api_key_env}" if $info->{api_key_env};
    push @lines, "";
  }

  unless (keys %$found) {
    push @lines, "  # No API keys found. Add your models here:";
    push @lines, "  # my-model:";
    push @lines, "  #   engine: OpenAI";
    push @lines, "  #   model: gpt-4o-mini";
    push @lines, "";
  }

  push @lines, "# Default engine for models without explicit config (optional)";
  if ($found->{OpenAI}) {
    push @lines, "default:";
    push @lines, "  engine: OpenAI";
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

version 0.007

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

See L<Langertha::Knarr> for the full configuration file format reference.

=head2 file

Path to the YAML configuration file. Optional — when omitted the config
object starts with an empty data hash (useful for testing or for
configs built purely from environment variables via L</from_env>).

=head2 data

The raw configuration hashref, loaded from L</file> and with all
C<${ENV_VAR}> references expanded. Can be supplied directly to bypass
file loading.

=head2 from_env

    my $config = Langertha::Knarr::Config->from_env(%opts);

Class method. Builds a config object purely from environment variables
(zero-config Docker mode). Calls L</scan_env> to detect which API keys are
set, assigns a sensible default model for each detected engine, enables
C<auto_discover> and C<passthrough>, and sets OpenAI as the default engine
when C<OPENAI_API_KEY> is present.

Options are passed through to L</scan_env> (e.g. C<include_test>).

=head2 listen

ArrayRef of C<host:port> strings to listen on. Defaults to
C<['127.0.0.1:8080', '127.0.0.1:11434']>.

=head2 models

HashRef of model name → model definition hashref from the C<models:> config
section. Each definition may include C<engine>, C<model>, C<api_key_env>,
C<api_key>, C<url>, C<system_prompt>, C<temperature>, and C<response_size>.

=head2 default_engine

HashRef from the C<default:> config section, or C<undef> if not set. At
minimum contains C<engine>. Used as the fallback when a model name is not
explicitly configured and no passthrough URL matches.

=head2 log_file

Path to a JSONL log file for request logging. Resolved from
C<logging.file> in config or C<KNARR_LOG_FILE> environment variable.

=head2 log_dir

Path to a directory for per-request JSON log files. Resolved from
C<logging.dir> in config or C<KNARR_LOG_DIR> environment variable.

=head2 langfuse

HashRef from the C<langfuse:> config section. May contain C<url>,
C<public_key>, C<secret_key>, and C<trace_name>. Returns an empty hashref
when the section is absent.

=head2 proxy_api_key

Optional shared secret that clients must present in the C<Authorization: Bearer>
or C<x-api-key> header. Falls back to the C<KNARR_API_KEY> environment variable.
When not set, the proxy is open (no auth required).

=head2 has_proxy_api_key

    if ($config->has_proxy_api_key) { ... }

Returns true when a L</proxy_api_key> is configured.

=head2 auto_discover

Boolean. When true, L<Langertha::Knarr::Router> queries each configured engine
for its model list at startup, making all discovered models available without
explicit config entries. Defaults to C<0>.

=head2 passthrough

HashRef of format name → upstream base URL. C<passthrough: true> in YAML
enables all known formats with their default upstream URLs
(C<https://api.openai.com> and C<https://api.anthropic.com>). Per-format
URLs can be customised or set to C<false> to disable selectively.

=head2 passthrough_url_for

    my $url = $config->passthrough_url_for('openai');

Returns the upstream base URL for the given format name (e.g. C<openai> or
C<anthropic>), or C<undef> if passthrough is not configured for that format.

=head2 validate

    my @errors = $config->validate;

Validates the configuration and returns a list of error strings. Returns an
empty list when the config is valid. Checks that every model entry has an
C<engine> key, that the default engine (if set) has an C<engine> key, and
that at least one model or default engine is configured.

=head2 scan_env

    my $found = Langertha::Knarr::Config->scan_env(
      env_files    => ['.env', '.env.local'],
      include_test => 1,
    );

Class method. Scans C<%ENV> and optional C<.env> files for known API key
environment variables. Returns a HashRef of engine name → C<{engine,
api_key_env}> for every engine whose key was found.

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

=item * L<Langertha::Knarr> — Main documentation and config format reference

=item * L<Langertha::Knarr::Router> — Uses config to resolve models to engines

=item * L<Langertha::Knarr::Tracing> — Uses config for Langfuse credentials

=item * L<Langertha::Knarr::RequestLog> — Uses config for request logging paths

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
