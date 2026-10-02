package Langertha::Knarr::Router;
our $VERSION = '1.102';
# ABSTRACT: Model name to Langertha engine routing with caching
use Moo;
use Carp qw( croak );
use Log::Any qw( $log );
use Scalar::Util qw( blessed refaddr );
use Future;
use Future::Utils qw( fmap_void );
use Langertha ();
use Langertha::Knarr::Handler::Passthrough;


# Keys of a model config that describe that one model and therefore never
# pass to the models discovered through it (k31). Everything else is
# endpoint-level and inherited; see the POD above.
my @MODEL_SPECIFIC_KEYS = qw( model context_size );

has config => (
  is       => 'ro',
  required => 1,
);


has _engine_cache => (
  is      => 'ro',
  default => sub { {} },
);

has _discovered_models => (
  is      => 'rw',
  default => sub { {} },
);

has _discovery_done => (
  is      => 'rw',
  default => 0,
);

# Engine instances a capability probe was started on (k37), by refaddr: each
# cached instance is probed once, whether the probe succeeded or not.
has _probed => (
  is      => 'ro',
  default => sub { {} },
);

# What a whole-catalogue probe learned, by endpoint key (k38): an instance
# that turns up on that endpoint later imports it instead of asking again.
has _catalogue_learned => (
  is      => 'ro',
  default => sub { {} },
);

has capabilities_generation => (
  is      => 'rw',
  default => 0,
);



sub resolve {
  my ($self, $model_name, %opts) = @_;
  my $named = defined $model_name && length $model_name ? 1 : 0;
  my $def;

  if ($named) {
    # Check explicit config first
    $def = $self->config->models->{$model_name};

    # Check discovered models
    unless ($def) {
      $self->_discover_models unless $self->_discovery_done;
      $def = $self->_discovered_models->{$model_name};
    }
  }

  # Fall back to default engine (skip_default allows caller to try passthrough first)
  unless ($def) {
    return () if $opts{skip_default};
    $def = $self->config->default_engine;
    croak "No model specified" unless $named || $def;
    # A named model replaces the default engine's model:; a request without
    # one (A2A, ...) gets the default engine as configured (k42).
    $def = { %$def, model => $model_name } if $def && $named;
  }

  croak "Model '$model_name' not configured and no default engine" unless $def;

  my $engine = $self->_get_engine($def, $model_name);
  my $resolved_model = $def->{model} // $model_name;
  # No model: key means the engine was built without a model and the
  # provider default answers; $resolved_model is only the alias then (k22).
  my $alias_only = defined $def->{model} ? 0 : 1;

  return ($engine, $resolved_model, $alias_only);
}

sub _get_engine {
  my ($self, $def, $model_name) = @_;

  my $engine_class = $def->{engine};
  my $cache_key = $self->_engine_cache_key($def);

  if (my $cached = $self->_engine_cache->{$cache_key}) {
    return $cached;
  }

  my $full_class = Langertha->resolve_engine_class($engine_class);

  my %args;

  # API key from env var if specified
  if ($def->{api_key_env}) {
    $args{api_key} = $ENV{$def->{api_key_env}}
      // croak "Environment variable $def->{api_key_env} not set for engine $engine_class";
  } elsif ($def->{api_key}) {
    $args{api_key} = $def->{api_key};
  }

  $args{url} = $def->{url} if $def->{url};
  $args{model} = $def->{model} if $def->{model};
  $args{system_prompt} = $def->{system_prompt} if $def->{system_prompt};
  $args{temperature} = $def->{temperature} if defined $def->{temperature};
  $args{response_size} = $def->{response_size} if defined $def->{response_size};
  # context_size is operator intent: engines composing core's
  # Role::ContextSize take it (and put it on their wire, e.g. Ollama's
  # num_ctx); Config warned once at load about engines that cannot (k30).
  $args{context_size} = $def->{context_size}
    if defined $def->{context_size} && $full_class->can('context_size');

  # A hanging upstream must not hold the client's request open forever
  # (k35): the model config's own user_agent_timeout, else the global
  # upstream_timeout. 0 leaves the engine without one.
  my $timeout = $def->{user_agent_timeout} // $self->config->upstream_timeout;
  $args{user_agent_timeout} = $timeout
    if $timeout && $timeout > 0 && $full_class->can('user_agent_timeout');

  # Langfuse config from global config
  my $langfuse = $self->config->langfuse;
  if ($langfuse && %$langfuse) {
    $args{langfuse_public_key} = $langfuse->{public_key} if $langfuse->{public_key};
    $args{langfuse_secret_key} = $langfuse->{secret_key} if $langfuse->{secret_key};
    $args{langfuse_url}        = $langfuse->{url}        if $langfuse->{url};
  }

  $log->debugf("Creating engine %s for model %s", $full_class, $model_name);
  my $engine = $full_class->new(%args);

  $self->_engine_cache->{$cache_key} = $engine;
  return $engine;
}

sub _engine_cache_key {
  my ($self, $def) = @_;
  # The model is part of the key: chat_model is read-only on an engine, and
  # core evaluates model-scoped capabilities against it, so each model needs
  # its own instance (k20). context_size is read-only on the engine too, so
  # two aliases of one model with different windows need two instances (k30);
  # so is user_agent_timeout (k35).
  return join('|', $self->_endpoint_key($def),
    map { $def->{$_} // '' } qw( model context_size user_agent_timeout ));
}

# One upstream endpoint: engine, url and API key variable. Discovery runs
# once per endpoint (k23).
sub _endpoint_key {
  my ($self, $def) = @_;
  return join('|', map { $def->{$_} // '' } qw( engine url api_key_env ));
}

sub _discover_models {
  my ($self) = @_;
  return if $self->_discovery_done;
  $self->_discovery_done(1);

  return unless $self->config->auto_discover;

  my $models = $self->config->models;
  my %seen_endpoints;

  # One model config per endpoint, in a fixed order: an id several endpoints
  # list belongs to the first (k55). Endpoints that are a passthrough
  # upstream come first -- their models may pass through as the client sent
  # them -- then the others, each group by model config name.
  my ( @upstream, @other );
  for my $name (sort keys %$models) {
    my $def = $models->{$name};
    next if $seen_endpoints{ $self->_endpoint_key($def) }++;
    my $engine = eval { $self->_get_engine($def, $name) };
    unless ($engine) {
      $log->debugf("Model discovery skipped for %s: %s", $def->{engine}, $@);
      next;
    }
    push @{ $self->_is_passthrough_upstream($engine) ? \@upstream : \@other },
      [ $name, $def, $engine ];
  }

  my %owner;
  for my $endpoint (@upstream, @other) {
    my ($name, $def, $engine) = @$endpoint;
    my $engine_class = $def->{engine};
    eval {
      if ($engine->can('list_models')) {
        $log->debugf("Discovering models from %s", $engine_class);
        my $model_ids = $engine->list_models;
        for my $id (@$model_ids) {
          next if $models->{$id};
          if ( my $first = $owner{$id} ) {
            $log->debugf("Discovered model %s also listed by %s, stays with %s",
              $id, $name, $first) if $first ne $name;
            next;
          }
          next if $self->_discovered_models->{$id};
          $owner{$id} = $name;
          my %inherited = %$def;
          delete @inherited{@MODEL_SPECIFIC_KEYS};
          $self->_discovered_models->{$id} = {
            %inherited,
            model      => $id,
            discovered => 1,
            # Where the model was listed: its passthrough upstream may
            # serve it as is (k47).
            ( $engine->can('url') && defined $engine->url
              ? ( discovered_url => $engine->url ) : () ),
          };
          $log->debugf("Discovered model: %s (via %s)", $id, $engine_class);
        }
      }
    };
    if ($@) {
      $log->debugf("Model discovery skipped for %s: %s", $engine_class, $@);
    }
  }
}

# The class that knows when two URLs are the same upstream (k54).
sub _passthrough_class { 'Langertha::Knarr::Handler::Passthrough' }

# True when the engine's URL is the passthrough upstream of some protocol.
sub _is_passthrough_upstream {
  my ($self, $engine) = @_;
  my $url = $engine->can('url') ? $engine->url : undef;
  return 0 unless defined $url;
  my $upstreams = $self->config->can('passthrough') ? $self->config->passthrough : undef;
  return 0 unless ref $upstreams eq 'HASH';
  for my $base ( values %$upstreams ) {
    return 1 if $self->_passthrough_class->same_upstream( $base, $url );
  }
  return 0;
}


sub list_models {
  my ($self) = @_;

  $self->_discover_models unless $self->_discovery_done;

  my $configured = $self->config->models;
  my $discovered = $self->_discovered_models;
  my @models;

  for my $name (sort keys %$configured) {
    push @models, {
      id       => $name,
      engine   => $configured->{$name}{engine},
      model    => $configured->{$name}{model} // $name,
      source   => 'configured',
    };
  }

  for my $name (sort keys %$discovered) {
    next if $configured->{$name};
    push @models, {
      id       => $name,
      engine   => $discovered->{$name}{engine},
      model    => $discovered->{$name}{model} // $name,
      source   => 'discovered',
    };
  }

  return \@models;
}


sub probe_capabilities_f {
  my ($self, %args) = @_;
  my $config = $self->config;
  return Future->done(0)
    unless !$config->can('probe_capabilities') || $config->probe_capabilities;
  my $loop    = $args{loop};
  my $timeout = $args{timeout}
    // ( $config->can('probe_timeout') ? $config->probe_timeout : 0 );

  my ( @targets, %endpoint, @endpoint_order );
  my $imported = 0;
  for my $row (@{ $self->list_models }) {
    my ($engine, $model, $alias_only) = eval { $self->resolve( $row->{id}, skip_default => 1 ) };
    next unless blessed $engine && $engine->can('probe_model_capabilities_f')
      && $engine->can('model_metadata_format')
      && defined eval { $engine->model_metadata_format };
    next if $self->_probed->{ refaddr $engine };
    # An alias without model: key asks about the engine's own default (k22).
    my $upstream = $alias_only ? eval { $engine->chat_model } : $model;
    next unless defined $upstream && !ref $upstream && length $upstream;
    $self->_probed->{ refaddr $engine } = 1;

    # A catalogue answers for every model of its endpoint: one request per
    # endpoint, imported into the endpoint's other instances (k38).
    my $def = $config->models->{ $row->{id} } // $self->_discovered_models->{ $row->{id} };
    if ( $def && $self->_shares_catalogue($engine) ) {
      my $key = $self->_endpoint_key($def);
      if ( my $learned = $self->_catalogue_learned->{$key} ) {
        $engine->import_learned_capabilities($learned);
        $imported++;
        next;
      }
      push @endpoint_order, $key unless $endpoint{$key};
      push @{ $endpoint{$key} }, [ $engine, $upstream, $row->{id} ];
      next;
    }
    push @targets, [ $engine, $upstream, $row->{id} ];
  }
  $self->capabilities_generation( $self->capabilities_generation + 1 ) if $imported;
  my $covered = $imported + @targets;
  $covered += @{ $endpoint{$_} } for @endpoint_order;
  push @targets, map { [ $endpoint{$_}, undef, $_ ] } @endpoint_order;
  return Future->done($covered) unless @targets;

  return ( fmap_void {
    # Per model: [ $engine, $upstream, $id ]; per endpoint: [ \@members, undef, $key ].
    my ($target, $upstream, $id) = @{ $_[0] };
    my $shared = ref $target eq 'ARRAY';
    my ($engine, @rest) = $shared ? map { $_->[0] } @$target : ( $target );
    my $what = $shared ? "the catalogue behind $target->[0][2]" : "$id ($upstream)";
    my $probe = eval { $engine->probe_model_capabilities_f(
        models => ( $shared ? 'all' : [ $upstream ] ) ) }
      // Future->fail( $@ || 'probe did not start' );
    $probe = Future->wait_any( $probe,
      $loop->delay_future( after => $timeout )
        ->then_fail("capability probe timed out after ${timeout}s") )
      if $loop && $timeout && $timeout > 0;
    $probe->then(sub {
      my ($learned) = @_;
      if ($shared) {
        $self->_catalogue_learned->{$id} = $learned;
        $_->import_learned_capabilities($learned) for @rest;
        $log->debugf( "Capability probe for %s: %d models learned, %d instances taught",
          $what, scalar keys %{ $learned || {} }, 1 + @rest );
        return Future->done;
      }
      $log->debugf( "Capability probe for %s: %s", $what,
        join( ', ', map { my $m = $_; map { "$m $_=$learned->{$m}{$_}" } sort keys %{ $learned->{$m} } }
          sort keys %{ $learned || {} } ) || 'nothing learned' );
      Future->done;
    })->else(sub {
      my ($err) = @_;
      ( my $text = "$err" ) =~ s/\s+\z//;
      $log->warnf( "Capability probe for %s failed: %s", $what, $text );
      Future->done;
    })->on_ready(sub {
      $self->capabilities_generation( $self->capabilities_generation + 1 );
    });
  } foreach => [ @targets ], concurrent => 4 )   # fmap consumes the array it is given
    ->then(sub { Future->done($covered) });
}

# True when the engine's metadata document is a catalogue AND the core can
# hand learned facts to another instance (k38). Either missing: per-instance
# probing as before (k37).
sub _shares_catalogue {
  my ($self, $engine) = @_;
  return 0 unless $engine->can('import_learned_capabilities');
  return 0 unless eval { require Langertha::ModelProbe; Langertha::ModelProbe->can('is_catalogue') };
  return eval { Langertha::ModelProbe->is_catalogue( $engine->model_metadata_format ) } ? 1 : 0;
}

sub is_passthrough_model {
  my ($self, $model) = @_;
  return 0 unless defined $model && length $model;
  my @r = eval { $self->resolve($model, skip_default => 1) };
  return @r ? 0 : 1;
}


sub discovered_url {
  my ($self, $model) = @_;
  return unless defined $model && length $model;
  return if $self->config->models->{$model};
  $self->_discover_models unless $self->_discovery_done;
  my $def = $self->_discovered_models->{$model} or return;
  return $def->{discovered_url};
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Router - Model name to Langertha engine routing with caching

=head1 VERSION

version 1.102

=head1 SYNOPSIS

    use Langertha::Knarr::Router;

    my $router = Langertha::Knarr::Router->new(config => $config);

    my ($engine, $model) = $router->resolve('gpt-5.6-terra');
    my $result = $engine->simple_chat(@messages);

    my $models = $router->list_models;

=head1 DESCRIPTION

Resolves a model name to a Langertha engine instance and canonical model
identifier. Engine instances are cached per engine, URL, API key variable,
model and C<context_size>, and reused across requests to avoid repeated construction overhead. Two
models on the same endpoint get two instances, each carrying its own model.

Engine classes are resolved from both C<Langertha::Engine::*> and
C<LangerthaX::Engine::*>.

When C<auto_discover> is enabled in the config, the router queries each
configured endpoint (engine, URL and API key variable) for its full model list on first use, making all discovered
models available as routing targets.

A model id several endpoints list belongs to one of them, the same one on
every run: an endpoint that is the passthrough upstream of some protocol
(L<Langertha::Knarr::Config/passthrough>, compared with
L<Langertha::Knarr::Handler::Passthrough/same_upstream>) before any other,
then by model config name. The other endpoints listing it are logged at
debug level.

A discovered model is routed with the config of the model entry it was
discovered through, minus the keys that describe that one model. The keys
split into two groups:

=over

=item * Endpoint-level, inherited: C<engine>, C<url>, C<api_key_env>,
C<api_key> (where and how to reach the upstream), and C<system_prompt>,
C<temperature>, C<response_size> (the operator's request policy for that
endpoint; a C<response_size> is a cap on the answer, not a property of the
model).

=item * Model-specific, not inherited: C<model> (replaced by the discovered
id) and C<context_size> (a context window belongs to one model; another
model on the same endpoint may hold less, and on Ollama it sizes the
loaded model through C<num_ctx>). A discovered model gets no
C<context_size>, so the engine and upstream defaults apply.

=back

C<user_agent_timeout> is endpoint-level too: the seconds Langertha waits
for that upstream. A model config without one gets
L<Langertha::Knarr::Config/upstream_timeout> (default C<300>); C<0> in
either leaves the engine without a timeout.

Any other key is inherited. A new per-model key belongs in the
model-specific group.

=head2 config

The L<Langertha::Knarr::Config> object. Required.

=head2 capabilities_generation

A counter that grows every time L</probe_capabilities_f> finishes probing an
engine instance. What an engine reports through C<supports()> may have
changed then, so anything that caches capabilities (the manifest) keys on it.

=head2 resolve

    my ($engine, $model) = $router->resolve($model_name, %opts);
    my ($engine, $model) = $router->resolve($model_name, skip_default => 1);

Resolves C<$model_name> to a Langertha engine instance and the canonical model
string to use with that engine. The resolution order is:

=over

=item 1. Explicit model config in L<Langertha::Knarr::Config/models>

=item 2. Auto-discovered models (if C<auto_discover> is enabled)

=item 3. The default engine from L<Langertha::Knarr::Config/default_engine>
(skipped when C<skip_default =E<gt> 1> is passed)

=back

On the default engine a named model replaces the C<model> of the
C<default:> section, so the client's model reaches the provider as asked.
Without a model name (C<undef> or empty -- an A2A request never names one)
only the default engine can answer, and it answers as configured: with its
own C<model>, or with the provider's default when C<default:> names none
(the third return value is then true and the returned model C<undef>).

The third return value is true when the matched model config has no
C<model> key: the engine is then built without a model, the provider's
default answers, and the returned model string is just the requested alias.
L<Langertha::Knarr::Handler::Router> uses it to report the model that
answered instead of the alias.

    my ($engine, $model, $alias_only) = $router->resolve($model_name);

Croaks if the model cannot be resolved, and croaks C<No model specified>
when no model is named and there is no default engine. Pass
C<skip_default =E<gt> 1> to allow the caller to try passthrough before
falling back to the default engine; with it, an unresolved or missing model
name returns an empty list.

=head2 list_models

    my $models = $router->list_models;

Returns an ArrayRef of model hashrefs, each with keys C<id>, C<engine>,
C<model>, and C<source> (either C<configured> or C<discovered>). Triggers
auto-discovery if not already done. Used to build the model list responses
for C<GET /v1/models> and C<GET /api/tags>.

=head2 probe_capabilities_f

    $router->probe_capabilities_f( loop => $loop )->get;

Asks each routed engine instance once which capabilities its model has, from
the provider's own model metadata (Langertha core's
C<probe_model_capabilities_f>, ADR 0032; today that is C<image_input>). The
facts are stored on the very instance L</resolve> hands out, so
C<POST /api/show> (C<vision>) and the provider manifest (C<image_input>) pick
them up without further work.

Every model L</list_models> shows is resolved (running auto-discovery first
when it is enabled and has not run yet), and every distinct engine instance
behind them is covered. An instance is skipped when the installed core has no
probe (Langertha 0.503), when its engine implements none
(C<model_metadata_format> is undefined: only OpenRouter, Mistral, LM Studio,
T-Systems, Ollama and llama.cpp read model metadata; the others would answer
C<{}> without a request anyway), when it has no model to ask about, or when
it was covered before. Calling the method again therefore covers only engine
instances that are new since the last call, such as the ones a later
discovery added.

How an instance is covered depends on its metadata document:

=over

=item * A catalogue (OpenRouter, Mistral, LM Studio, T-Systems: one document
names every model; C<< Langertha::ModelProbe->is_catalogue >>) is fetched
once per endpoint (engine, URL and API key variable, the same key discovery
uses) with C<< models => 'all' >>, and what it taught is imported into every
other instance of that endpoint with C<import_learned_capabilities>, without
a request. A gateway with hundreds of discovered models costs one request.
Facts never cross endpoints: two OpenRouter entries with different URLs are
two catalogues. An instance that appears on an endpoint whose catalogue was
already learned imports it; after a failed catalogue probe the next call
asks again for the new instances only. A core without
C<import_learned_capabilities> probes every instance on its own, as below.

=item * A per-model document (Ollama C</api/show>, llama.cpp) is asked once
per instance, for that instance's upstream model.

=back

The probes run concurrently, at most four at a time. A probe that fails or
takes longer than L<Langertha::Knarr::Config/probe_timeout> seconds (only
when C<loop> is given) is logged as a warning and not retried; the engines
it would have taught keep the capabilities they had. The returned Future
never fails and resolves to the number of engine instances covered (probed
or imported into). With L<Langertha::Knarr::Config/probe_capabilities> off
it resolves to C<0> at once.

L<Langertha::Knarr/start> calls this once the server listens.

=head2 is_passthrough_model

    next if $router->is_passthrough_model($model);

True when the router cannot resolve C<$model> without the default engine:
neither configured nor auto-discovered.

=head2 discovered_url

    my $url = $router->discovered_url($model);

For a model known only through auto-discovery (not in
L<Langertha::Knarr::Config/models>), the base URL of the engine that listed
it; C<undef> for a configured or unknown model, or when the engine has no
C<url>. L<Langertha::Knarr> sends such a model to the raw passthrough when
it was listed by the passthrough upstream of the client's protocol and the
client sends its own provider key.

=head1 SEE ALSO

=over

=item * L<Langertha::Knarr> — Main documentation; the routing order is described under L</resolve> above

=item * L<Langertha::Knarr::Config> — Provides model and engine configuration

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
