package Langertha::Role::Chat;
# ABSTRACT: Role for APIs with normal chat functionality
our $VERSION = '0.304';
use Moose::Role;
use Future::AsyncAwait;
use Carp qw( croak );
use Log::Any qw( $log );

requires qw(
  chat_request
  chat_response
);


has chat_model => (
  is => 'ro',
  isa => 'Maybe[Str]',
  lazy_build => 1,
);
sub _build_chat_model {
  my ( $self ) = @_;
  croak "".(ref $self)." can't handle models!" unless $self->does('Langertha::Role::Models');
  return $self->default_chat_model if $self->can('default_chat_model');
  return $self->model;
}


sub chat {
  my ( $self, @messages ) = @_;
  return $self->chat_request($self->chat_messages(@messages));
}


sub chat_messages {
  my ( $self, @messages ) = @_;
  return [$self->has_system_prompt
    ? ({
      role => 'system', content => $self->system_prompt,
    }) : (),
    map {
      ref $_ ? $_ : {
        role => 'user', content => $_,
      }
    } @messages];
}


sub simple_chat {
  my ( $self, @messages ) = @_;
  $log->debugf("[%s] simple_chat with %d message(s), model=%s",
    ref $self, scalar @messages, $self->chat_model // 'default');
  my $request = $self->chat(@messages);
  my $response = $self->user_agent->request($request);
  my $result = $request->response_call->($response);
  if ($self->can('has_rate_limit') && $self->has_rate_limit && ref $result && $result->isa('Langertha::Response')) {
    $result = $result->clone_with(rate_limit => $self->rate_limit);
  }
  return $result;
}


sub chat_stream {
  my ( $self, @messages ) = @_;
  croak "".(ref $self)." does not support streaming"
    unless $self->can('chat_stream_request');
  return $self->chat_stream_request($self->chat_messages(@messages));
}


sub simple_chat_stream {
  my ( $self, $callback, @messages ) = @_;
  croak "simple_chat_stream requires a callback as first argument"
    unless ref $callback eq 'CODE';
  $log->debugf("[%s] simple_chat_stream (%s format)", ref $self, $self->stream_format);
  my $request = $self->chat_stream(@messages);
  my $chunks = $self->execute_streaming_request($request, $callback);
  $log->debugf("[%s] Stream completed: %d chunks", ref $self, scalar @$chunks);
  return join('', map { $_->content } @$chunks);
}


sub simple_chat_stream_iterator {
  my ( $self, @messages ) = @_;
  require Langertha::Stream;
  my $request = $self->chat_stream(@messages);
  my $chunks = $self->execute_streaming_request($request);
  return Langertha::Stream->new(chunks => $chunks);
}


# Future-based async methods

has _async_loop => (
  is => 'ro',
  lazy_build => 1,
);

sub _build__async_loop {
  require IO::Async::Loop;
  return IO::Async::Loop->new;
}

has _async_http => (
  is => 'ro',
  lazy_build => 1,
);

sub _build__async_http {
  my ($self) = @_;
  require Net::Async::HTTP;
  my $http = Net::Async::HTTP->new;
  $self->_async_loop->add($http);
  return $http;
}

async sub simple_chat_f {
  my ( $self, @messages ) = @_;
  $log->debugf("[%s] simple_chat_f with %d message(s)", ref $self, scalar @messages);
  my $request = $self->chat(@messages);

  my $response = await $self->_async_http->do_request(
    request => $request,
  );

  unless ($response->is_success) {
    die "".(ref $self)." request failed: ".$response->status_line;
  }

  my $result = $request->response_call->($response);
  if ($self->can('has_rate_limit') && $self->has_rate_limit && ref $result && $result->isa('Langertha::Response')) {
    $result = $result->clone_with(rate_limit => $self->rate_limit);
  }
  return $result;
}


sub simple_chat_stream_f {
  my ($self, @messages) = @_;
  return $self->simple_chat_stream_realtime_f(undef, @messages);
}


async sub simple_chat_stream_realtime_f {
  my ($self, $chunk_callback, @messages) = @_;

  croak "".(ref $self)." does not support streaming"
    unless $self->can('chat_stream_request');

  my $request = $self->chat_stream_request($self->chat_messages(@messages));
  my @all_chunks;
  my $buffer = '';
  my $format = $self->stream_format;
  my $response_status;

  await $self->_async_http->do_request(
    request => $request,
    on_header => sub {
      my ($response) = @_;
      $response_status = $response;

      # Return a callback that handles each body chunk
      return sub {
        my ($data) = @_;
        return unless defined $data;  # undef signals end of body

        $buffer .= $data;
        my $chunks = $self->_process_stream_buffer(\$buffer, $format);
        for my $chunk (@$chunks) {
          push @all_chunks, $chunk;
          $chunk_callback->($chunk) if $chunk_callback;
        }
      };
    },
  );

  unless ($response_status->is_success) {
    die "".(ref $self)." streaming request failed: ".$response_status->status_line;
  }

  # Process remaining buffer
  if ($buffer ne '') {
    my $chunks = $self->_process_stream_buffer(\$buffer, $format, 1);
    for my $chunk (@$chunks) {
      push @all_chunks, $chunk;
      $chunk_callback->($chunk) if $chunk_callback;
    }
  }

  my $content = join('', map { $_->content } @all_chunks);
  return ($content, \@all_chunks);
}


sub _process_stream_buffer {
  my ($self, $buffer_ref, $format, $final) = @_;

  my @chunks;

  if ($format eq 'sse') {
    while ($$buffer_ref =~ s/^(.*?)\n\n//s) {
      my $block = $1;
      for my $line (split /\n/, $block) {
        next if $line eq '' || $line =~ /^:/;
        if ($line =~ /^data:\s*(.*)$/) {
          my $json_data = $1;
          next if $json_data eq '[DONE]' || $json_data eq '';
          my $parsed = $self->json->decode($json_data);
          my $chunk = $self->parse_stream_chunk($parsed);
          push @chunks, $chunk if $chunk;
        }
      }
    }
  } elsif ($format eq 'ndjson') {
    while ($$buffer_ref =~ s/^(.*?)\n//s) {
      my $line = $1;
      next if $line eq '';
      my $parsed = $self->json->decode($line);
      my $chunk = $self->parse_stream_chunk($parsed);
      push @chunks, $chunk if $chunk;
    }
  }

  return \@chunks;
}

with 'Langertha::Role::ThinkTag';
with 'Langertha::Role::Langfuse';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Chat - Role for APIs with normal chat functionality

=head1 VERSION

version 0.304

=head1 SYNOPSIS

    # Synchronous chat
    my $response = $engine->simple_chat('Hello, how are you?');

    # Streaming with callback
    $engine->simple_chat_stream(sub {
        my ($chunk) = @_;
        print $chunk->content;
    }, 'Tell me a story');

    # Streaming with iterator
    my $stream = $engine->simple_chat_stream_iterator('Tell me a story');
    while (my $chunk = $stream->next) {
        print $chunk->content;
    }

    # Async with Future (traditional style)
    my $future = $engine->simple_chat_f('Hello');
    my $response = $future->get;

    # Async with Future::AsyncAwait (recommended)
    use Future::AsyncAwait;

    async sub chat_example {
        my ($engine) = @_;
        my $response = await $engine->simple_chat_f('Hello');
        say $response;
    }

    # Async streaming with real-time callback
    async sub stream_example {
        my ($engine) = @_;
        my ($content, $chunks) = await $engine->simple_chat_stream_realtime_f(
            sub { print shift->content },
            'Tell me a story'
        );
        say "\nTotal chunks: ", scalar @$chunks;
    }

=head1 DESCRIPTION

This role provides chat functionality for LLM engines. It includes both
synchronous and asynchronous (L<Future>-based) methods for chat and streaming.

The Future-based C<_f> methods are implemented using L<Future::AsyncAwait> and
L<Net::Async::HTTP>. These modules are loaded lazily only when you call a C<_f>
method, so synchronous-only usage does not require them.

=head2 chat_model

The model name used for chat requests. Lazily defaults to C<default_chat_model>
if the engine provides it, otherwise falls back to the general C<model>
attribute from L<Langertha::Role::Models>.

=head2 chat

    my $request = $engine->chat(@messages);

Builds and returns a chat HTTP request object. Messages may be plain strings
(treated as C<user> role) or HashRefs with C<role> and C<content> keys. A
system prompt from L<Langertha::Role::SystemPrompt> is prepended automatically.

=head2 chat_messages

    my $messages = $engine->chat_messages(@messages);

Normalises C<@messages> into the canonical ArrayRef-of-HashRef format expected
by C<chat_request>. Plain strings become C<{ role =E<gt> 'user', content =E<gt>
$string }>. If the engine has a C<system_prompt> set it is prepended as a
C<system> message.

=head2 simple_chat

    my $response = $engine->simple_chat(@messages);
    my $response = $engine->simple_chat('Hello, how are you?');

Sends a synchronous chat request and returns the response text. Blocks until
the request completes.

=head2 chat_stream

    my $request = $engine->chat_stream(@messages);

Builds and returns a streaming chat HTTP request object. Croaks if the engine
does not implement C<chat_stream_request>. Use L</simple_chat_stream> or
L</simple_chat_stream_iterator> to execute the request.

=head2 simple_chat_stream

    my $content = $engine->simple_chat_stream($callback, @messages);

    $engine->simple_chat_stream(sub {
        my ($chunk) = @_;
        print $chunk->content;
    }, 'Tell me a story');

Sends a synchronous streaming chat request. Calls C<$callback> with each
L<Langertha::Stream::Chunk> as it arrives. Returns the complete concatenated
content string when done. Blocks until the stream completes.

=head2 simple_chat_stream_iterator

    my $stream = $engine->simple_chat_stream_iterator(@messages);
    while (my $chunk = $stream->next) {
        print $chunk->content;
    }

Returns a L<Langertha::Stream> iterator. The full response is fetched
synchronously and buffered; iteration yields each L<Langertha::Stream::Chunk>
in order.

=head2 simple_chat_f

    # Traditional Future style
    my $response = $engine->simple_chat_f(@messages)->get;

    # With async/await (recommended)
    use Future::AsyncAwait;
    async sub my_chat {
        my $response = await $engine->simple_chat_f(@messages);
        return $response;
    }

Async version of L</simple_chat>. Returns a L<Future> that resolves to the
response text. Uses L<Net::Async::HTTP> internally; loaded lazily on first call.

=head2 simple_chat_stream_f

    my ($content, $chunks) = $engine->simple_chat_stream_f(@messages)->get;

Async streaming without a real-time callback. Convenience wrapper around
L</simple_chat_stream_realtime_f> with C<undef> as the callback. Returns a
L<Future> that resolves to C<($content, \@chunks)>.

=head2 simple_chat_stream_realtime_f

    # With async/await (recommended)
    use Future::AsyncAwait;
    async sub my_stream {
        my ($content, $chunks) = await $engine->simple_chat_stream_realtime_f(
            sub { print shift->content },
            @messages
        );
        return $content;
    }

    # Traditional Future style
    my $future = $engine->simple_chat_stream_realtime_f($callback, @messages);
    my ($content, $chunks) = $future->get;

Async streaming with real-time callback. C<$callback> is called with each
L<Langertha::Stream::Chunk> as it arrives from the server. Returns a L<Future>
that resolves to C<($content, \@chunks)> where C<$content> is the full
concatenated text.

This is the recommended method for real-time streaming in async applications.
Pass C<undef> as the callback (or use L</simple_chat_stream_f>) if you only
need the final result.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::Langfuse> - Observability integration (composed by this role)

=item * L<Langertha::Role::SystemPrompt> - System prompt injection

=item * L<Langertha::Role::Streaming> - Stream parsing (SSE / NDJSON)

=item * L<Langertha::Role::Tools> - Tool calling on top of chat

=item * L<Langertha::Role::Models> - Model selection

=item * L<Langertha::Stream> - Stream iterator

=item * L<Langertha::Stream::Chunk> - Individual stream chunk

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
