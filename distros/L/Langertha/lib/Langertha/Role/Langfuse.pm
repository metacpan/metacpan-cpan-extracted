package Langertha::Role::Langfuse;
# ABSTRACT: Langfuse observability integration
our $VERSION = '0.305';
use Moose::Role;
use Time::HiRes qw( gettimeofday tv_interval );
use Carp qw( croak );
use JSON::MaybeXS ();
use MIME::Base64 qw( encode_base64 );


has langfuse_public_key => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_langfuse_public_key',
);


has langfuse_secret_key => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_langfuse_secret_key',
);


has langfuse_url => (
  is => 'ro',
  isa => 'Str',
  lazy => 1,
  default => sub { $ENV{LANGFUSE_URL} || 'https://cloud.langfuse.com' },
);


has langfuse_enabled => (
  is => 'ro',
  isa => 'Bool',
  lazy => 1,
  builder => '_build_langfuse_enabled',
);


sub _build_langfuse_enabled {
  my ( $self ) = @_;
  # Enabled if keys are passed directly or via env vars
  my $pub = $self->has_langfuse_public_key || $ENV{LANGFUSE_PUBLIC_KEY};
  my $sec = $self->has_langfuse_secret_key || $ENV{LANGFUSE_SECRET_KEY};
  return $pub && $sec ? 1 : 0;
}

around BUILDARGS => sub {
  my ( $orig, $class, %args ) = @_;
  # Auto-populate from env vars if not passed
  $args{langfuse_public_key} //= $ENV{LANGFUSE_PUBLIC_KEY}
    if $ENV{LANGFUSE_PUBLIC_KEY};
  $args{langfuse_secret_key} //= $ENV{LANGFUSE_SECRET_KEY}
    if $ENV{LANGFUSE_SECRET_KEY};
  return $class->$orig(%args);
};

has _langfuse_batch => (
  is => 'rw',
  isa => 'ArrayRef',
  default => sub { [] },
);

sub _langfuse_id {
  my ( $self ) = @_;
  # Simple UUID v4 generation without external dependency
  my @hex = map { sprintf("%04x", int(rand(65536))) } 1..8;
  return join('-',
    $hex[0].$hex[1],
    $hex[2],
    '4'.substr($hex[3], 1),  # version 4
    sprintf("%x", 8 + int(rand(4))).substr($hex[4], 1),  # variant
    $hex[5].$hex[6].$hex[7],
  );
}

sub _langfuse_timestamp {
  my ( $self ) = @_;
  my ($s, $us) = gettimeofday;
  my @t = gmtime($s);
  return sprintf("%04d-%02d-%02dT%02d:%02d:%02d.%03dZ",
    $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0], int($us/1000));
}

sub langfuse_trace {
  my ( $self, %opts ) = @_;
  return unless $self->langfuse_enabled;
  my $id = $opts{id} || $self->_langfuse_id;
  push @{$self->_langfuse_batch}, {
    id   => $self->_langfuse_id,
    type => 'trace-create',
    timestamp => $self->_langfuse_timestamp,
    body => {
      id   => $id,
      name => $opts{name} // 'langfuse-trace',
      $opts{input}       ? ( input       => $opts{input} )       : (),
      $opts{output}      ? ( output      => $opts{output} )      : (),
      $opts{metadata}    ? ( metadata    => $opts{metadata} )    : (),
      $opts{tags}        ? ( tags        => $opts{tags} )        : (),
      $opts{user_id}     ? ( userId      => $opts{user_id} )     : (),
      $opts{session_id}  ? ( sessionId   => $opts{session_id} )  : (),
      $opts{release}     ? ( release     => $opts{release} )     : (),
      $opts{version}     ? ( version     => $opts{version} )     : (),
      defined $opts{public}
        ? ( public => $opts{public} ? JSON::MaybeXS->true : JSON::MaybeXS->false ) : (),
      $opts{environment} ? ( environment => $opts{environment} ) : (),
    },
  };
  return $id;
}


sub langfuse_generation {
  my ( $self, %opts ) = @_;
  return unless $self->langfuse_enabled;
  my $id = $opts{id} || $self->_langfuse_id;
  push @{$self->_langfuse_batch}, {
    id   => $self->_langfuse_id,
    type => 'generation-create',
    timestamp => $self->_langfuse_timestamp,
    body => {
      id       => $id,
      traceId  => $opts{trace_id} // croak("langfuse_generation requires trace_id"),
      name     => $opts{name} // 'generation',
      model    => $opts{model},
      $opts{input}          ? ( input          => $opts{input} )          : (),
      $opts{output}         ? ( output         => $opts{output} )         : (),
      $opts{usage}          ? ( usage          => $opts{usage} )          : (),
      $opts{metadata}       ? ( metadata       => $opts{metadata} )       : (),
      $opts{start_time}     ? ( startTime      => $opts{start_time} )     : (),
      $opts{end_time}       ? ( endTime        => $opts{end_time} )       : (),
      defined $opts{completion_start_time}
        ? ( completionStartTime => $opts{completion_start_time} ) : (),
      $opts{parent_observation_id}
        ? ( parentObservationId => $opts{parent_observation_id} ) : (),
      $opts{model_parameters}
        ? ( modelParameters     => $opts{model_parameters} )     : (),
      $opts{level}          ? ( level          => $opts{level} )          : (),
      $opts{status_message} ? ( statusMessage  => $opts{status_message} ) : (),
      $opts{version}        ? ( version        => $opts{version} )        : (),
    },
  };
  return $id;
}


sub langfuse_span {
  my ( $self, %opts ) = @_;
  return unless $self->langfuse_enabled;
  my $id = $opts{id} || $self->_langfuse_id;
  push @{$self->_langfuse_batch}, {
    id   => $self->_langfuse_id,
    type => 'span-create',
    timestamp => $self->_langfuse_timestamp,
    body => {
      id      => $id,
      traceId => $opts{trace_id} // croak("langfuse_span requires trace_id"),
      $opts{name}       ? ( name       => $opts{name} )       : (),
      $opts{input}      ? ( input      => $opts{input} )      : (),
      $opts{output}     ? ( output     => $opts{output} )     : (),
      $opts{metadata}   ? ( metadata   => $opts{metadata} )   : (),
      $opts{start_time} ? ( startTime  => $opts{start_time} ) : (),
      $opts{end_time}   ? ( endTime    => $opts{end_time} )   : (),
      $opts{parent_observation_id}
        ? ( parentObservationId => $opts{parent_observation_id} ) : (),
      $opts{level}          ? ( level         => $opts{level} )          : (),
      $opts{status_message} ? ( statusMessage => $opts{status_message} ) : (),
      $opts{version}        ? ( version       => $opts{version} )        : (),
    },
  };
  return $id;
}


sub langfuse_update_trace {
  my ( $self, %opts ) = @_;
  return unless $self->langfuse_enabled;
  my $id = $opts{id} // croak("langfuse_update_trace requires id");
  push @{$self->_langfuse_batch}, {
    id   => $self->_langfuse_id,
    type => 'trace-create',
    timestamp => $self->_langfuse_timestamp,
    body => {
      id => $id,
      $opts{name}        ? ( name        => $opts{name} )        : (),
      $opts{input}       ? ( input       => $opts{input} )       : (),
      $opts{output}      ? ( output      => $opts{output} )      : (),
      $opts{metadata}    ? ( metadata    => $opts{metadata} )    : (),
      $opts{tags}        ? ( tags        => $opts{tags} )        : (),
      $opts{user_id}     ? ( userId      => $opts{user_id} )     : (),
      $opts{session_id}  ? ( sessionId   => $opts{session_id} )  : (),
      $opts{release}     ? ( release     => $opts{release} )     : (),
      $opts{version}     ? ( version     => $opts{version} )     : (),
      defined $opts{public}
        ? ( public => $opts{public} ? JSON::MaybeXS->true : JSON::MaybeXS->false ) : (),
      $opts{environment} ? ( environment => $opts{environment} ) : (),
    },
  };
  return $id;
}


sub langfuse_update_span {
  my ( $self, %opts ) = @_;
  return unless $self->langfuse_enabled;
  my $id = $opts{id} // croak("langfuse_update_span requires id");
  push @{$self->_langfuse_batch}, {
    id   => $self->_langfuse_id,
    type => 'span-update',
    timestamp => $self->_langfuse_timestamp,
    body => {
      id => $id,
      $opts{trace_id}   ? ( traceId   => $opts{trace_id} )   : (),
      $opts{output}     ? ( output    => $opts{output} )      : (),
      $opts{metadata}   ? ( metadata  => $opts{metadata} )    : (),
      $opts{end_time}   ? ( endTime   => $opts{end_time} )    : (),
      $opts{level}          ? ( level         => $opts{level} )          : (),
      $opts{status_message} ? ( statusMessage => $opts{status_message} ) : (),
    },
  };
  return $id;
}


sub langfuse_update_generation {
  my ( $self, %opts ) = @_;
  return unless $self->langfuse_enabled;
  my $id = $opts{id} // croak("langfuse_update_generation requires id");
  push @{$self->_langfuse_batch}, {
    id   => $self->_langfuse_id,
    type => 'generation-update',
    timestamp => $self->_langfuse_timestamp,
    body => {
      id => $id,
      $opts{trace_id}   ? ( traceId   => $opts{trace_id} )   : (),
      $opts{output}     ? ( output    => $opts{output} )      : (),
      $opts{usage}      ? ( usage     => $opts{usage} )       : (),
      $opts{metadata}   ? ( metadata  => $opts{metadata} )    : (),
      $opts{end_time}   ? ( endTime   => $opts{end_time} )    : (),
      $opts{level}          ? ( level              => $opts{level} )          : (),
      $opts{status_message} ? ( statusMessage      => $opts{status_message} ) : (),
      defined $opts{completion_start_time}
        ? ( completionStartTime => $opts{completion_start_time} ) : (),
    },
  };
  return $id;
}


sub langfuse_flush {
  my ( $self ) = @_;
  return unless $self->langfuse_enabled;
  my $batch = $self->_langfuse_batch;
  return unless @$batch;

  require LWP::UserAgent;
  my $ua = LWP::UserAgent->new(agent => 'Langertha-Langfuse/'.$VERSION);

  my $auth = encode_base64(
    $self->langfuse_public_key . ':' . $self->langfuse_secret_key, ''
  );

  my $body = $self->json->encode({ batch => $batch });

  my $request = HTTP::Request->new(
    POST => $self->langfuse_url . '/api/public/ingestion',
    [
      'Content-Type'  => 'application/json',
      'Authorization' => 'Basic ' . $auth,
    ],
    $body,
  );

  my $response = $ua->request($request);
  $self->_langfuse_batch([]);

  unless ($response->is_success) {
    warn "Langfuse ingestion failed: " . $response->status_line;
  }

  return $response;
}


# Auto-instrumentation: wraps simple_chat to record a trace and generation
# for every call when Langfuse is enabled.

around simple_chat => sub {
  my ( $orig, $self, @messages ) = @_;
  return $self->$orig(@messages) unless $self->langfuse_enabled;

  my $t0 = $self->_langfuse_timestamp;
  my $start = [gettimeofday];

  my $response = $self->$orig(@messages);

  my $t1 = $self->_langfuse_timestamp;

  # Build usage from Response if available
  my $usage;
  if (ref $response && $response->isa('Langertha::Response') && $response->has_usage) {
    $usage = {
      input  => $response->prompt_tokens,
      output => $response->completion_tokens,
      total  => $response->total_tokens,
    };
  }

  my $trace_id = $self->langfuse_trace(
    name   => 'simple_chat',
    input  => \@messages,
    output => "$response",
  );

  $self->langfuse_generation(
    trace_id   => $trace_id,
    name       => 'chat',
    model      => (ref $response && $response->isa('Langertha::Response') && $response->has_model)
                    ? $response->model : $self->chat_model,
    input      => \@messages,
    output     => "$response",
    start_time => $t0,
    end_time   => $t1,
    $usage ? ( usage => $usage ) : (),
  );

  return $response;
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Langfuse - Langfuse observability integration

=head1 VERSION

version 0.305

=head1 SYNOPSIS

Langfuse is built into every Langertha engine. Just set the env vars:

    export LANGFUSE_PUBLIC_KEY=pk-lf-...
    export LANGFUSE_SECRET_KEY=sk-lf-...
    export LANGFUSE_URL=http://localhost:3000   # optional, defaults to cloud

Then use any engine as normal — C<simple_chat> is auto-traced:

    use Langertha::Engine::OpenAI;

    my $engine = Langertha::Engine::OpenAI->new(
        api_key => $ENV{OPENAI_API_KEY},
        model   => 'gpt-4o-mini',
    );

    my $response = $engine->simple_chat('Hello!');
    $engine->langfuse_flush;  # send events to Langfuse

Or pass keys explicitly:

    my $engine = Langertha::Engine::Anthropic->new(
        api_key             => $ENV{ANTHROPIC_API_KEY},
        langfuse_public_key => 'pk-lf-...',
        langfuse_secret_key => 'sk-lf-...',
        langfuse_url        => 'http://localhost:3000',
    );

Manual traces for custom workflows:

    my $trace_id = $engine->langfuse_trace(
        name  => 'my-workflow',
        input => { query => 'custom input' },
    );

    $engine->langfuse_generation(
        trace_id => $trace_id,
        name     => 'step-1',
        model    => 'gpt-4o',
        input    => 'prompt text',
        output   => 'response text',
        usage    => { input => 10, output => 5, total => 15 },
    );

    $engine->langfuse_flush;

=head1 DESCRIPTION

This role integrates Langertha engines with L<Langfuse|https://langfuse.com/>,
an open-source observability platform for LLM applications. It is composed
into L<Langertha::Role::Chat>, so B<every engine has Langfuse support built in>.

B<Features:>

=over 4

=item * Zero-config via environment variables

=item * Auto-instrumentation of C<simple_chat> calls

=item * Manual trace and generation event creation

=item * Batched event ingestion via Langfuse REST API

=item * Basic Auth using public/secret key pair

=item * Disabled by default — only active when both keys are set

=back

B<Langfuse concepts:>

=over 4

=item * B<Trace> — Top-level unit of work (a request, a conversation turn)

=item * B<Span> — A grouping of work within a trace (an iteration, a tool call)

=item * B<Generation> — A single LLM call within a trace (with model, usage, timing)

=back

B<Hierarchy:> Traces contain spans and generations. Spans can nest via
C<parent_observation_id>. All observations can be updated after creation.

=head2 langfuse_public_key

Your Langfuse project public key. Auto-populated from C<LANGFUSE_PUBLIC_KEY>
environment variable if not passed.

=head2 langfuse_secret_key

Your Langfuse project secret key. Auto-populated from C<LANGFUSE_SECRET_KEY>
environment variable if not passed.

=head2 langfuse_url

Langfuse API URL. Defaults to C<LANGFUSE_URL> env var, or
C<https://cloud.langfuse.com> if not set. Set this to your
self-hosted instance URL (e.g. C<http://localhost:3000>).

=head2 langfuse_enabled

Bool indicating whether Langfuse integration is active. Lazy — defaults
to true when both public and secret keys are available (from constructor
or environment variables).

=head2 langfuse_trace

    my $trace_id = $engine->langfuse_trace(
        name        => 'my-trace',
        input       => { ... },
        output      => '...',
        metadata    => { ... },
        tags        => ['tag1', 'tag2'],
        user_id     => 'user-123',
        session_id  => 'session-abc',
        release     => '1.0.0',
        version     => '1',
        public      => 1,
        environment => 'production',
    );

Creates a trace event. Returns the trace ID for linking generations and
spans. Accepts optional C<tags>, C<user_id>, C<session_id>, C<release>,
C<version>, C<public>, and C<environment> fields. Calling with the same
C<id> upserts (updates) the trace.

=head2 langfuse_generation

    $engine->langfuse_generation(
        trace_id              => $trace_id,
        name                  => 'chat',
        model                 => 'gpt-4o',
        input                 => '...',
        output                => '...',
        usage                 => { input => 10, output => 5, total => 15 },
        start_time            => $iso_timestamp,
        end_time              => $iso_timestamp,
        parent_observation_id => $span_id,
        model_parameters      => { temperature => 0.7, max_tokens => 1000 },
        level                 => 'DEFAULT',
        status_message        => 'OK',
        version               => '1',
    );

Creates a generation event linked to a trace. C<trace_id> is required.
Accepts optional C<parent_observation_id> for nesting under a span,
C<model_parameters>, C<level> (DEBUG/DEFAULT/WARNING/ERROR),
C<status_message>, and C<version>.

=head2 langfuse_span

    my $span_id = $engine->langfuse_span(
        trace_id              => $trace_id,
        name                  => 'my-span',
        input                 => { ... },
        output                => '...',
        start_time            => $iso_timestamp,
        end_time              => $iso_timestamp,
        parent_observation_id => $parent_span_id,
        metadata              => { ... },
        level                 => 'DEFAULT',
        status_message        => 'OK',
        version               => '1',
    );

Creates a span event for grouping work within a trace. C<trace_id> is
required. Returns the span ID. Spans can be nested via
C<parent_observation_id>.

=head2 langfuse_update_trace

    $engine->langfuse_update_trace(
        id       => $trace_id,
        output   => 'final result',
        metadata => { ... },
    );

Updates a trace by upserting with the same C<id>. Uses C<trace-create>
event type (Langfuse upserts on matching body ID). C<id> is required.

=head2 langfuse_update_span

    $engine->langfuse_update_span(
        id       => $span_id,
        end_time => $iso_timestamp,
        output   => { ... },
    );

Updates an existing span. C<id> is required. Use this to set C<end_time>
and C<output> after the span's work completes.

=head2 langfuse_update_generation

    $engine->langfuse_update_generation(
        id     => $gen_id,
        output => 'final response text',
        usage  => { input => 100, output => 50, total => 150 },
    );

Updates an existing generation. C<id> is required. Use this to add
C<output>, C<usage>, and C<end_time> after the LLM call completes.

=head2 langfuse_flush

    $engine->langfuse_flush;

Sends all batched events to the Langfuse ingestion API. Clears the batch
after sending. Warns on HTTP errors but does not die.

=head1 ENVIRONMENT VARIABLES

=over 4

=item C<LANGFUSE_PUBLIC_KEY> — Auto-populates C<langfuse_public_key>

=item C<LANGFUSE_SECRET_KEY> — Auto-populates C<langfuse_secret_key>

=item C<LANGFUSE_URL> — Auto-populates C<langfuse_url> (default: C<https://cloud.langfuse.com>)

=back

=head1 SELF-HOSTING LANGFUSE

A ready-to-use Kubernetes manifest is included in the distribution:

    kubectl apply -f ex/langfuse-k8s.yaml
    kubectl -n langfuse port-forward svc/langfuse-web 3000:3000 &

    export LANGFUSE_PUBLIC_KEY=pk-lf-langertha
    export LANGFUSE_SECRET_KEY=sk-lf-langertha
    export LANGFUSE_URL=http://localhost:3000

The manifest pre-creates a project with known API keys so you can send
data immediately without going through the web UI.

Dashboard: C<http://localhost:3000> (login: C<langertha@test.invalid> / C<langertha>)

=head1 GETTING LANGFUSE KEYS

For Langfuse Cloud, sign up at L<https://langfuse.com/> and generate
API keys in your project settings.

=head1 SEE ALSO

=over

=item * L<https://langfuse.com/docs> - Langfuse documentation

=item * L<Langertha::Role::Chat> - Chat role that composes this role

=item * L<Langertha::Raider> - Autonomous agent with Langfuse tracing support

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
