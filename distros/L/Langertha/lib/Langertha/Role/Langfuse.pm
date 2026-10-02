package Langertha::Role::Langfuse;
# ABSTRACT: Langfuse observability integration
our $VERSION = '0.503';
use Moose::Role;
use Time::HiRes qw( gettimeofday tv_interval );
use Carp qw( croak );
use JSON::MaybeXS qw( JSON );
use MIME::Base64 qw( encode_base64 );
use Scalar::Util qw( blessed );
use Future;
use Future::AsyncAwait;


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

has langfuse_max_batch => (
  is => 'ro',
  isa => 'Int',
  default => 1000,
);


# Every event goes through here so the batch stays bounded (karr k305).
sub _langfuse_push {
  my ( $self, $event ) = @_;
  my $batch = $self->_langfuse_batch;
  push @$batch, $event;
  my $max = $self->langfuse_max_batch;
  if ( $max > 0 && @$batch > $max ) {
    splice @$batch, 0, @$batch - $max;
    unless ( $self->{_langfuse_overflow_warned}++ ) {
      warn ref($self) . ": Langfuse batch reached langfuse_max_batch ($max events) "
         . "without a flush; dropping the oldest events. Call langfuse_flush regularly.\n";
    }
  }
  return;
}

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

sub langfuse_timestamp {
  my ( $self ) = @_;
  my ($s, $us) = gettimeofday;
  my @t = gmtime($s);
  return sprintf("%04d-%02d-%02dT%02d:%02d:%02d.%03dZ",
    $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0], int($us/1000));
}


# Private alias kept for existing callers; the internal call sites use it too.
sub _langfuse_timestamp { $_[0]->langfuse_timestamp }

sub langfuse_trace {
  my ( $self, %opts ) = @_;
  return unless $self->langfuse_enabled;
  my $id = $opts{id} || $self->_langfuse_id;
  $self->_langfuse_push({
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
        ? ( public => $opts{public} ? JSON->true : JSON->false ) : (),
      $opts{environment} ? ( environment => $opts{environment} ) : (),
    },
  });
  return $id;
}


sub langfuse_generation {
  my ( $self, %opts ) = @_;
  return unless $self->langfuse_enabled;
  my $id = $opts{id} || $self->_langfuse_id;
  $self->_langfuse_push({
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
  });
  return $id;
}


sub langfuse_span {
  my ( $self, %opts ) = @_;
  return unless $self->langfuse_enabled;
  my $id = $opts{id} || $self->_langfuse_id;
  $self->_langfuse_push({
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
  });
  return $id;
}


sub langfuse_update_trace {
  my ( $self, %opts ) = @_;
  return unless $self->langfuse_enabled;
  my $id = $opts{id} // croak("langfuse_update_trace requires id");
  $self->_langfuse_push({
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
        ? ( public => $opts{public} ? JSON->true : JSON->false ) : (),
      $opts{environment} ? ( environment => $opts{environment} ) : (),
    },
  });
  return $id;
}


sub langfuse_update_span {
  my ( $self, %opts ) = @_;
  return unless $self->langfuse_enabled;
  my $id = $opts{id} // croak("langfuse_update_span requires id");
  $self->_langfuse_push({
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
  });
  return $id;
}


sub langfuse_update_generation {
  my ( $self, %opts ) = @_;
  return unless $self->langfuse_enabled;
  my $id = $opts{id} // croak("langfuse_update_generation requires id");
  $self->_langfuse_push({
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
  });
  return $id;
}


has langfuse_timeout => (
  is => 'ro',
  isa => 'Num',
  default => 10,
);


has langfuse_flush_batch_size => (
  is => 'ro',
  isa => 'Int',
  default => 100,
);


# --- Ingestion transport (karr k303) -----------------------------------------
# The helpers below use no engine state and are called as class methods, so
# Langertha::Plugin::Langfuse shares them instead of carrying a copy.

sub _langfuse_ingestion_request {
  my ( $class, %args ) = @_;
  require HTTP::Request;
  my $auth = encode_base64( $args{public_key} . ':' . $args{secret_key}, '' );
  return HTTP::Request->new(
    POST => $args{url} . '/api/public/ingestion',
    [
      'Content-Type'  => 'application/json',
      'Authorization' => 'Basic ' . $auth,
    ],
    $args{json}->encode({ batch => $args{events} }),
  );
}

# Sends @{$args{chunks}} one request after another and returns a Future of
# the responses; it never fails. $args{engine} (anything with
# _async_do_request_f) carries the request on its async backend with the
# short timeout; without one, or when that backend is the synchronous LWP
# shim (whose user agent has the provider's timeout), a dedicated LWP agent
# with the short timeout does. A transport failure (timeout, refused) stops
# the flush: the remaining chunks would only wait out the same timeout.
async sub _langfuse_send_chunks_f {
  my ( $class, %args ) = @_;
  my @chunks = @{ $args{chunks} };
  my @responses;
  while ( my $chunk = shift @chunks ) {
    my $request  = $class->_langfuse_ingestion_request( %args, events => $chunk );
    my $response = await $class->_langfuse_send_f( $args{engine}, $request, %args );
    push @responses, $response;
    $class->_langfuse_check_ingestion( $response, scalar @$chunk );
    if ( @chunks && ( $response->header('Client-Warning') // '' ) eq 'Internal response' ) {
      my $dropped = 0;
      $dropped += @$_ for @chunks;
      warn "Langfuse ingestion: endpoint unreachable, dropping $dropped more event(s)\n";
      last;
    }
  }
  return @responses;
}

sub _langfuse_send_f {
  my ( $class, $engine, $request, %args ) = @_;
  my $http = $engine ? $engine->_async_http : undef;
  unless ( blessed($http) && !$http->isa('Langertha::Request::SyncHTTP') ) {
    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new( agent => $args{agent}, timeout => $args{timeout} );
    return Future->done( $ua->request($request) );
  }
  return $engine->_async_do_request_f( request => $request, timeout => $args{timeout} )
    ->else( sub {
      my ( $message ) = @_;
      $message = ( split /\n/, "$message" )[0] // 'request failed';
      # Same shape LWP gives a transport failure, so both paths report alike.
      require HTTP::Response;
      return Future->done( HTTP::Response->new(
        500, $message, [ 'Client-Warning' => 'Internal response' ],
      ) );
    } );
}

# Warns about what did not arrive; never dies. Langfuse answers a batch with
# 207 Multi-Status, listing per-event failures under "errors".
sub _langfuse_check_ingestion {
  my ( $class, $response, $count ) = @_;
  unless ( $response->is_success ) {
    warn "Langfuse ingestion failed: " . $response->status_line . " ($count event(s) lost)\n";
    return;
  }
  return unless $response->code == 207;
  my $data = eval { JSON::MaybeXS->new( utf8 => 1 )->decode( $response->content ) };
  my $errors = ref $data eq 'HASH' && ref $data->{errors} eq 'ARRAY' ? $data->{errors} : [];
  return unless @$errors;
  my $first  = ref $errors->[0] eq 'HASH' ? $errors->[0] : {};
  my $detail = join ' ', grep { defined && !ref && length } @{$first}{qw( status message )};
  warn sprintf "Langfuse ingestion: %d of %d event(s) rejected%s\n",
    scalar @$errors, $count, length $detail ? " (first: $detail)" : '';
  return;
}

sub _langfuse_flush_args {
  my ( $self ) = @_;
  my @events = @{ $self->_langfuse_batch };
  return unless @events;
  $self->_langfuse_batch([]);
  my $size = $self->langfuse_flush_batch_size;
  $size = 1 if $size < 1;
  my @chunks;
  push @chunks, [ splice @events, 0, $size ] while @events;
  return (
    chunks     => \@chunks,
    url        => $self->langfuse_url,
    public_key => $self->langfuse_public_key,
    secret_key => $self->langfuse_secret_key,
    json       => $self->json,
    agent      => 'Langertha-Langfuse/' . $VERSION,
    timeout    => $self->langfuse_timeout,
  );
}

sub langfuse_flush {
  my ( $self ) = @_;
  return unless $self->langfuse_enabled;
  my %args = $self->_langfuse_flush_args or return;
  my @responses = __PACKAGE__->_langfuse_send_chunks_f(%args)->get;
  return $responses[-1];
}


async sub langfuse_flush_f {
  my ( $self ) = @_;
  return unless $self->langfuse_enabled;
  my %args = $self->_langfuse_flush_args or return;
  return await __PACKAGE__->_langfuse_send_chunks_f( %args, engine => $self );
}


# Auto-instrumentation: wraps simple_chat to record a trace and generation
# for every call when Langfuse is enabled.

# Returns an ISO-8601 timestamp (UTC, ms resolution) at
# $start_hires + $delta_seconds. Used to compute endTime /
# completionStartTime from a client-measured total_seconds / ttft_seconds
# carried on a Langertha::Response, anchored to the moment the simple_chat
# wrapper entered — not to wall-clock now, which has already advanced
# past end. Sub-millisecond precision in the underlying hires time is
# rounded to whole milliseconds to match the rest of Langfuse timestamp
# formatting.
sub _langfuse_iso_after {
  my ( $self, $start_hires, $delta_seconds ) = @_;
  # Guard against clock skew / monotonic drift producing a negative delta
  # (Perl's % preserves sign on negatives, which would yield a negative $us
  # and an out-of-range millisecond field below). Clamp to zero — better
  # to report a same-instant end_time than a wall-clock trip into the past.
  $delta_seconds = 0 if $delta_seconds < 0;
  my ($s, $us) = @$start_hires;
  my $delta_us = $delta_seconds * 1_000_000;
  $s += int( ($us + $delta_us) / 1_000_000 );
  $us = int( ($us + $delta_us) % 1_000_000 );
  $us = 0 if $us < 0;
  my @t = gmtime($s);
  return sprintf("%04d-%02d-%02dT%02d:%02d:%02d.%03dZ",
    $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0], int($us/1000));
}

around simple_chat => sub {
  my ( $orig, $self, @messages ) = @_;
  return $self->$orig(@messages) unless $self->langfuse_enabled;

  my $start      = [gettimeofday];
  my $start_time = $self->_langfuse_timestamp;

  my $response = $self->$orig(@messages);

  my $t1        = $self->_langfuse_timestamp;
  my $end_time  = $t1;

  # Build usage from Response if available
  my $usage;
  if (ref $response && $response->isa('Langertha::Response') && $response->has_usage) {
    $usage = {
      input  => $response->prompt_tokens,
      output => $response->completion_tokens,
      total  => $response->total_tokens,
    };
  }

  # Prefer response-side timing (carries total_seconds and optionally
  # ttft_seconds) when available. Both are deltas measured from the
  # same anchor as our wrapper's $start — anchor end / completion_start
  # to that anchor so the generation event spans the real call window
  # rather than drifting into the future.
  my $completion_start_time;
  if (ref $response && $response->isa('Langertha::Response')) {
    if ($response->has_total) {
      $end_time = $self->_langfuse_iso_after($start, $response->total_seconds);
    }
    if ($response->has_ttft) {
      $completion_start_time = $self->_langfuse_iso_after($start, $response->ttft_seconds);
    }
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
    start_time => $start_time,
    end_time   => $end_time,
    defined $completion_start_time ? ( completion_start_time => $completion_start_time ) : (),
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

version 0.503

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

    # inside an event loop, without blocking it:
    await $engine->langfuse_flush_f;

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

=head2 langfuse_max_batch

The most events kept in memory between two L</langfuse_flush> calls. Default
C<1000> (500 traced C<simple_chat> calls, each a trace and a generation). The
events are only sent when someone flushes, and Langfuse turns on by itself as
soon as C<LANGFUSE_PUBLIC_KEY> and C<LANGFUSE_SECRET_KEY> are in the
environment, so a long-running process that never flushes would otherwise
keep every prompt and answer it ever sent. When the batch is full the
B<oldest> event is dropped for each new one, with a single warning per engine
object. C<0> removes the cap.

Nothing is flushed automatically: a flush is an HTTP request, and
C<simple_chat> should not pay for one at an unpredictable moment. Call
L</langfuse_flush> (or L</langfuse_flush_f>) yourself, for example after each
request in a server.

=head2 langfuse_timestamp

    my $t0 = $engine->langfuse_timestamp;   # 2026-09-25T12:34:56.789Z
    ...
    $engine->langfuse_span(
      trace_id   => $trace_id,
      name       => 'tool: search',
      start_time => $t0,
      end_time   => $engine->langfuse_timestamp,
    );

Returns the current time as an ISO-8601 UTC string with millisecond
precision (C<YYYY-MM-DDTHH:MM:SS.mmmZ>) — the format this role stamps on
every Langfuse event. Use it for C<start_time> / C<end_time> when you create
spans or generations yourself. The older private name C<_langfuse_timestamp>
still works and returns the same.

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

=head2 langfuse_timeout

Seconds a flush may wait for Langfuse per request. Default C<10>, deliberately
short: Langfuse is observability, and an ingestion endpoint that accepts the
connection and never answers must not hold up the application (LWP's own
default would be 180 seconds). The engine's
L<Langertha::Role::HTTP/user_agent_timeout> does not apply here; it is meant
for the LLM provider. On the L<Net::Async::HTTP> backend it is the total time
of the request, on the synchronous LWP path the time without activity on the
connection.

=head2 langfuse_flush_batch_size

The most events sent in one ingestion request. Default C<100>. A flush with
more events sends several requests one after another, so a large backlog does
not become one body that Langfuse rejects for its size.

=head2 langfuse_flush

    $engine->langfuse_flush;

Sends all batched events to the Langfuse ingestion API over a dedicated
L<LWP::UserAgent> with L</langfuse_timeout>, and clears the batch. Blocks
until the requests are done, so do not call it from inside an event loop;
use L</langfuse_flush_f> there. More than L</langfuse_flush_batch_size>
events go out as several requests. Returns the L<HTTP::Response> of the last
request, or nothing when there was nothing to send.

It never dies. It warns when a request fails (the events of that request are
lost, and after a timeout or refused connection the rest of the flush is
dropped too, instead of waiting out the timeout once per request), and when
Langfuse accepts the request but rejects single events (C<207 Multi-Status>
with an C<errors> list): the warning gives the number rejected and the first
error.

=head2 langfuse_flush_f

    await $engine->langfuse_flush_f;

Async L</langfuse_flush>: sends the batched events through the engine's own
async backend (L<Langertha::Role::AsyncHTTP>) with L</langfuse_timeout> as
the request's total timeout, so a slow or silent Langfuse never blocks the
event loop. The batch is taken when the call starts; events recorded while
it runs wait for the next flush. The future resolves to the
L<HTTP::Response> of each request and B<never fails>; problems are warned
about as in L</langfuse_flush>. On the synchronous fallback (no
L<Net::Async::HTTP>) it runs like L</langfuse_flush>.

=head1 ENVIRONMENT VARIABLES

=over 4

=item C<LANGFUSE_PUBLIC_KEY> — Auto-populates C<langfuse_public_key>

=item C<LANGFUSE_SECRET_KEY> — Auto-populates C<langfuse_secret_key>

=item C<LANGFUSE_URL> — Auto-populates C<langfuse_url> (default: C<https://cloud.langfuse.com>)

=back

With both keys in the environment every engine records C<simple_chat> calls
without being asked to, but sends nothing until L</langfuse_flush> is called.
Events wait in memory up to L</langfuse_max_batch>; past that the oldest are
dropped with one warning. A process that has the variables set but never
flushes therefore holds a bounded amount of trace data, not every prompt it
ever sent.

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
