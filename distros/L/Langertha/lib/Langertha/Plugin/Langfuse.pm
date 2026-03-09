package Langertha::Plugin::Langfuse;
# ABSTRACT: Langfuse observability plugin for any PluginHost
our $VERSION = '0.305';
use Moose;
use Future::AsyncAwait;
use Time::HiRes qw( gettimeofday );
use Carp qw( croak );
use JSON::MaybeXS ();
use MIME::Base64 qw( encode_base64 );

extends 'Langertha::Plugin';


has public_key => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $ENV{LANGFUSE_PUBLIC_KEY} // '' },
);


has secret_key => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $ENV{LANGFUSE_SECRET_KEY} // '' },
);


has url => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $ENV{LANGFUSE_URL} // 'https://cloud.langfuse.com' },
);


has enabled => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  builder => '_build_enabled',
);


sub _build_enabled {
  my ( $self ) = @_;
  return length($self->public_key) && length($self->secret_key) ? 1 : 0;
}

has trace_name => (
  is      => 'ro',
  isa     => 'Str',
  default => 'llm-call',
);


has user_id => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_user_id',
);


has session_id => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_session_id',
);


has tags => (
  is        => 'ro',
  isa       => 'ArrayRef[Str]',
  predicate => 'has_tags',
);


has metadata => (
  is        => 'ro',
  isa       => 'HashRef',
  predicate => 'has_metadata',
);


has auto_flush => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


# --- Internal state ---

has _batch => (
  is      => 'rw',
  isa     => 'ArrayRef',
  default => sub { [] },
);

has _trace_id => (
  is  => 'rw',
  isa => 'Maybe[Str]',
);

has _iter_start => (
  is  => 'rw',
  isa => 'Maybe[Str]',
);

has _json => (
  is      => 'ro',
  lazy    => 1,
  default => sub { JSON::MaybeXS->new(utf8 => 1, canonical => 1, convert_blessed => 1) },
);

# --- Langfuse utility methods ---

sub _id {
  my @hex = map { sprintf("%04x", int(rand(65536))) } 1..8;
  return join('-',
    $hex[0].$hex[1],
    $hex[2],
    '4'.substr($hex[3], 1),
    sprintf("%x", 8 + int(rand(4))).substr($hex[4], 1),
    $hex[5].$hex[6].$hex[7],
  );
}

sub _timestamp {
  my ($s, $us) = gettimeofday;
  my @t = gmtime($s);
  return sprintf("%04d-%02d-%02dT%02d:%02d:%02d.%03dZ",
    $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0], int($us/1000));
}

# --- Langfuse event creation ---

sub create_trace {
  my ( $self, %opts ) = @_;
  return unless $self->enabled;
  my $id = $opts{id} || _id();
  push @{$self->_batch}, {
    id        => _id(),
    type      => 'trace-create',
    timestamp => _timestamp(),
    body      => {
      id   => $id,
      name => $opts{name} // 'langfuse-trace',
      $opts{input}       ? ( input       => $opts{input} )       : (),
      $opts{output}      ? ( output      => $opts{output} )      : (),
      $opts{metadata}    ? ( metadata    => $opts{metadata} )    : (),
      $opts{tags}        ? ( tags        => $opts{tags} )        : (),
      $opts{user_id}     ? ( userId      => $opts{user_id} )     : (),
      $opts{session_id}  ? ( sessionId   => $opts{session_id} )  : (),
    },
  };
  return $id;
}


sub create_generation {
  my ( $self, %opts ) = @_;
  return unless $self->enabled;
  my $id = $opts{id} || _id();
  push @{$self->_batch}, {
    id        => _id(),
    type      => 'generation-create',
    timestamp => _timestamp(),
    body      => {
      id       => $id,
      traceId  => $opts{trace_id} // croak("create_generation requires trace_id"),
      name     => $opts{name} // 'generation',
      $opts{model}                ? ( model              => $opts{model} )              : (),
      $opts{input}                ? ( input              => $opts{input} )              : (),
      $opts{output}               ? ( output             => $opts{output} )             : (),
      $opts{usage}                ? ( usage              => $opts{usage} )              : (),
      $opts{start_time}           ? ( startTime          => $opts{start_time} )         : (),
      $opts{end_time}             ? ( endTime            => $opts{end_time} )           : (),
      $opts{parent_observation_id}? ( parentObservationId => $opts{parent_observation_id} ) : (),
      $opts{model_parameters}     ? ( modelParameters    => $opts{model_parameters} )   : (),
    },
  };
  return $id;
}


sub create_span {
  my ( $self, %opts ) = @_;
  return unless $self->enabled;
  my $id = $opts{id} || _id();
  push @{$self->_batch}, {
    id        => _id(),
    type      => 'span-create',
    timestamp => _timestamp(),
    body      => {
      id      => $id,
      traceId => $opts{trace_id} // croak("create_span requires trace_id"),
      $opts{name}                 ? ( name               => $opts{name} )               : (),
      $opts{input}                ? ( input              => $opts{input} )              : (),
      $opts{output}               ? ( output             => $opts{output} )             : (),
      $opts{start_time}           ? ( startTime          => $opts{start_time} )         : (),
      $opts{end_time}             ? ( endTime            => $opts{end_time} )           : (),
      $opts{parent_observation_id}? ( parentObservationId => $opts{parent_observation_id} ) : (),
      $opts{metadata}             ? ( metadata           => $opts{metadata} )           : (),
    },
  };
  return $id;
}


sub update_trace {
  my ( $self, %opts ) = @_;
  return unless $self->enabled;
  my $id = $opts{id} // croak("update_trace requires id");
  push @{$self->_batch}, {
    id        => _id(),
    type      => 'trace-create',
    timestamp => _timestamp(),
    body      => {
      id => $id,
      $opts{output}   ? ( output   => $opts{output} )   : (),
      $opts{metadata} ? ( metadata => $opts{metadata} )  : (),
    },
  };
  return $id;
}


sub flush {
  my ( $self ) = @_;
  return unless $self->enabled;
  my $batch = $self->_batch;
  return unless @$batch;

  require LWP::UserAgent;
  my $ua = LWP::UserAgent->new(agent => 'Langertha-Plugin-Langfuse/'.$VERSION);

  my $auth = encode_base64(
    $self->public_key . ':' . $self->secret_key, ''
  );

  my $body = $self->_json->encode({ batch => $batch });

  my $request = HTTP::Request->new(
    POST => $self->url . '/api/public/ingestion',
    [
      'Content-Type'  => 'application/json',
      'Authorization' => 'Basic ' . $auth,
    ],
    $body,
  );

  my $response = $ua->request($request);
  $self->_batch([]);

  unless ($response->is_success) {
    warn "Langfuse ingestion failed: " . $response->status_line;
  }

  return $response;
}


sub reset_trace {
  my ( $self ) = @_;
  $self->_trace_id(undef);
  $self->_iter_start(undef);
}



# --- Plugin hooks ---

async sub plugin_before_llm_call {
  my ( $self, $conversation, $iteration ) = @_;
  return $conversation unless $self->enabled;

  # Create trace on first iteration (or if no trace exists)
  if (!$self->_trace_id) {
    $self->_trace_id($self->create_trace(
      name => $self->trace_name,
      input => $conversation,
      $self->has_user_id    ? ( user_id    => $self->user_id )    : (),
      $self->has_session_id ? ( session_id => $self->session_id ) : (),
      $self->has_tags       ? ( tags       => $self->tags )       : (),
      $self->has_metadata   ? ( metadata   => $self->metadata )   : (),
    ));
  }

  $self->_iter_start(_timestamp());
  return $conversation;
}

async sub plugin_after_llm_response {
  my ( $self, $data, $iteration ) = @_;
  return $data unless $self->enabled;

  # Create generation event
  my $end_time = _timestamp();
  $self->create_generation(
    trace_id   => $self->_trace_id,
    name       => "generation-$iteration",
    start_time => $self->_iter_start,
    end_time   => $end_time,
  );

  # Update trace output (last update wins via upsert)
  $self->update_trace(
    id     => $self->_trace_id,
    output => $data,
  );

  if ($self->auto_flush) {
    $self->flush;
  }

  return $data;
}

async sub plugin_after_tool_call {
  my ( $self, $name, $input, $result ) = @_;
  return $result unless $self->enabled;

  my $t = _timestamp();
  $self->create_span(
    trace_id   => $self->_trace_id,
    name       => "tool:$name",
    input      => $input,
    output     => $result,
    start_time => $t,
    end_time   => $t,
  );

  return $result;
}

async sub plugin_before_image_gen {
  my ( $self, $prompt ) = @_;
  return $prompt unless $self->enabled;

  if (!$self->_trace_id) {
    $self->_trace_id($self->create_trace(
      name  => $self->trace_name,
      input => $prompt,
      $self->has_user_id    ? ( user_id    => $self->user_id )    : (),
      $self->has_session_id ? ( session_id => $self->session_id ) : (),
      $self->has_tags       ? ( tags       => $self->tags )       : (),
      $self->has_metadata   ? ( metadata   => $self->metadata )   : (),
    ));
  }

  $self->_iter_start(_timestamp());
  return $prompt;
}

async sub plugin_after_image_gen {
  my ( $self, $prompt, $result ) = @_;
  return $result unless $self->enabled;

  my $end_time = _timestamp();
  $self->create_generation(
    trace_id   => $self->_trace_id,
    name       => 'image-generation',
    start_time => $self->_iter_start,
    end_time   => $end_time,
    input      => $prompt,
  );

  $self->update_trace(
    id     => $self->_trace_id,
    output => $result,
  );

  if ($self->auto_flush) {
    $self->flush;
  }

  return $result;
}

async sub plugin_before_embedding {
  my ( $self, $text ) = @_;
  return $text unless $self->enabled;

  if (!$self->_trace_id) {
    $self->_trace_id($self->create_trace(
      name  => $self->trace_name,
      input => $text,
      $self->has_user_id    ? ( user_id    => $self->user_id )    : (),
      $self->has_session_id ? ( session_id => $self->session_id ) : (),
      $self->has_tags       ? ( tags       => $self->tags )       : (),
      $self->has_metadata   ? ( metadata   => $self->metadata )   : (),
    ));
  }

  $self->_iter_start(_timestamp());
  return $text;
}

async sub plugin_after_embedding {
  my ( $self, $text, $vector ) = @_;
  return $vector unless $self->enabled;

  my $end_time = _timestamp();
  $self->create_generation(
    trace_id   => $self->_trace_id,
    name       => 'embedding',
    start_time => $self->_iter_start,
    end_time   => $end_time,
    input      => $text,
  );

  $self->update_trace(
    id     => $self->_trace_id,
    output => { dimensions => ref $vector eq 'ARRAY' ? scalar @$vector : undef },
  );

  if ($self->auto_flush) {
    $self->flush;
  }

  return $vector;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Plugin::Langfuse - Langfuse observability plugin for any PluginHost

=head1 VERSION

version 0.305

=head1 SYNOPSIS

    use Langertha::Chat;
    use Langertha::Plugin::Langfuse;

    my $langfuse = Langertha::Plugin::Langfuse->new(
        public_key => 'pk-lf-...',
        secret_key => 'sk-lf-...',
    );

    my $chat = Langertha::Chat->new(
        engine  => $engine,
        plugins => [$langfuse],
    );

    $chat->simple_chat('Hello!');
    $langfuse->flush;

Or with sugar:

    my $chat = Langertha::Chat->new(
        engine  => $engine,
        plugins => [Langfuse => {
            trace_name => 'my-chat',
            auto_flush => 1,
        }],
    );

Environment variables C<LANGFUSE_PUBLIC_KEY>, C<LANGFUSE_SECRET_KEY>, and
C<LANGFUSE_URL> are auto-populated when not explicitly set.

=head1 DESCRIPTION

This plugin integrates any L<Langertha::Role::PluginHost> (L<Langertha::Chat>,
L<Langertha::Embedder>, L<Langertha::Raider>) with
L<Langfuse|https://langfuse.com/> observability. It hooks into the standard
plugin events to automatically create traces, generations, and spans.

Unlike L<Langertha::Role::Langfuse> (which lives on the engine), this plugin
works on any PluginHost and does not require engine-level configuration.

=head2 public_key

Langfuse project public key. Defaults to C<LANGFUSE_PUBLIC_KEY> env var.

=head2 secret_key

Langfuse project secret key. Defaults to C<LANGFUSE_SECRET_KEY> env var.

=head2 url

Langfuse API URL. Defaults to C<LANGFUSE_URL> env var or
C<https://cloud.langfuse.com>.

=head2 enabled

Whether Langfuse integration is active. Defaults to true when both
C<public_key> and C<secret_key> are non-empty.

=head2 trace_name

Name for the Langfuse trace created per chat session. Defaults to
C<'llm-call'>.

=head2 user_id

Optional user ID passed to the Langfuse trace.

=head2 session_id

Optional session ID passed to the Langfuse trace.

=head2 tags

Optional tags passed to the Langfuse trace.

=head2 metadata

Optional metadata HashRef merged into the Langfuse trace.

=head2 auto_flush

When true, automatically flushes events after each C<plugin_after_llm_response>.
Defaults to false.

=head2 create_trace

    my $trace_id = $plugin->create_trace(name => 'my-trace', input => {...});

Creates a trace event. Returns the trace ID. Called automatically by
the plugin hooks, but can also be used manually.

=head2 create_generation

    $plugin->create_generation(trace_id => $id, model => 'gpt-4o', ...);

Creates a generation event linked to a trace.

=head2 create_span

    $plugin->create_span(trace_id => $id, name => 'tool-call', ...);

Creates a span event within a trace.

=head2 update_trace

    $plugin->update_trace(id => $trace_id, output => 'result');

Updates a trace by upserting with the same ID.

=head2 flush

    $plugin->flush;

Sends all batched events to the Langfuse ingestion API. Clears the
batch after sending.

=head2 reset_trace

    $plugin->reset_trace;

Resets the current trace state. Call this between independent chat
sessions to start a new trace.

=head1 SEE ALSO

=over

=item * L<Langertha::Plugin> - Base class with all hook method signatures

=item * L<Langertha::Role::PluginHost> - Plugin system consumed by hosts

=item * L<Langertha::Chat> - Chat host this plugin attaches to

=item * L<Langertha::Embedder> - Embedder host this plugin attaches to

=item * L<Langertha::ImageGen> - Image generation host this plugin attaches to

=item * L<Langertha::Raider> - Autonomous agent host this plugin attaches to

=item * L<https://langfuse.com/> - Langfuse observability platform

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
