package Langertha::Knarr::Handler::Engine;
# ABSTRACT: Knarr handler that proxies directly to a Langertha engine
our $VERSION = '1.100';
use Moose;
use Future;
use Future::AsyncAwait;
use Langertha::Knarr::Stream;
use Langertha::Knarr::Response;

with 'Langertha::Knarr::Handler';


has engine => (
  is => 'ro',
  required => 1,
);

has model_id => (
  is => 'ro',
  isa => 'Maybe[Str]',
  default => sub { undef },
);

sub _model_id {
  my ($self) = @_;
  return $self->model_id if $self->model_id;
  my $e = $self->engine;
  return $e->chat_model if $e->can('chat_model') && $e->chat_model;
  return ( ref($e) =~ /::([^:]+)$/ ) ? lc($1) : 'engine';
}

async sub handle_chat_f {
  my ($self, $session, $request) = @_;
  my $response = await $self->engine->chat_f( $request->chat_f_args($self->engine) );
  my $r = Langertha::Knarr::Response->coerce($response);
  return $r->clone_with( model => $r->model // $self->_model_id );
}

async sub handle_stream_f {
  my ($self, $session, $request) = @_;
  my $engine = $self->engine;
  unless ( _supports_streaming($engine) ) {
    # Engine doesn't support native streaming — fall back to single-chunk.
    my $r = await $self->handle_chat_f($session, $request);
    return Langertha::Knarr::Stream->from_list( $r->content );
  }

  return Langertha::Knarr::Stream->from_callback( sub {
    my ($emit, $done, $fail) = @_;
    my $cb = sub {
      my ($chunk) = @_;
      my $text = ref $chunk && $chunk->can('content') ? $chunk->content : "$chunk";
      $emit->($text);
    };
    my $f = $engine->simple_chat_stream_realtime_f( $cb, @{ $request->messages } );
    $f->on_done( $done );
    $f->on_fail( $fail );
    $f->retain;
  });
}

sub _supports_streaming {
  my ($engine) = @_;
  return $engine->supports('streaming') if $engine->can('supports');
  return $engine->can('simple_chat_stream_realtime_f') && $engine->can('chat_stream_request');
}

sub list_models {
  my ($self) = @_;
  return [ { id => $self->_model_id, object => 'model' } ];
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Handler::Engine - Knarr handler that proxies directly to a Langertha engine

=head1 VERSION

version 1.100

=head1 SYNOPSIS

    use Langertha::Engine::Groq;
    use Langertha::Knarr::Handler::Engine;

    my $engine = Langertha::Engine::Groq->new(
        api_key    => $ENV{GROQ_API_KEY},
        chat_model => 'llama-3.3-70b-versatile',
    );

    my $handler = Langertha::Knarr::Handler::Engine->new(
        engine   => $engine,
        model_id => 'groq-llama-3.3-70b',
    );

=head1 DESCRIPTION

Wraps a single L<Langertha::Engine::*> instance and exposes it as a
Knarr handler. Non-streaming requests are dispatched via
C<< $engine->chat_f >> with the full set of generation parameters
(C<tools>, C<tool_choice>, C<response_format>, C<temperature>,
C<max_tokens>) forwarded from the client request — subject to the
engine's reported capabilities. Streaming requests use
C<simple_chat_stream_realtime_f> for native token-by-token delivery;
engines that don't support streaming fall back to a single-chunk
emission.

For routing across multiple engines based on model name, use
L<Langertha::Knarr::Handler::Router> with a L<Langertha::Knarr::Router>
config instead.

=head2 engine

Required. Any object consuming L<Langertha::Role::Chat>. Streaming
support is detected via C<< $engine->supports('streaming') >> (Langertha
0.500+) or the presence of C<simple_chat_stream_realtime_f>.

=head2 model_id

Optional. The id reported by L</list_models> and surfaced in responses.
Defaults to the engine's C<chat_model>, falling back to a derived name
from the engine class.

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
