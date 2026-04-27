package Langertha::Knarr::Handler::Router;
# ABSTRACT: Knarr handler that resolves model names via Langertha::Knarr::Router and dispatches to engines
our $VERSION = '1.100';
use Moose;
use Future;
use Future::AsyncAwait;
use Langertha::Knarr::Stream;
use Langertha::Knarr::Response;

with 'Langertha::Knarr::Handler';


# Wraps a Langertha::Knarr::Router (which is Moo) and uses it to resolve
# incoming model names to Langertha engine instances. Also keeps the
# upstream Knarr::Config visible for the rest of the request lifecycle.

has router => ( is => 'ro', required => 1 );

# Optional Passthrough handler used as fallback when the router can't
# resolve a model. Allows mixed mode: configured models go via Langertha
# engines (with tracing/middleware support), unknown models tunnel straight
# to the upstream API the client thinks they're talking to.
has passthrough => (
  is => 'ro',
  isa => 'Maybe[Object]',
  default => sub { undef },
);

sub _resolve {
  my ($self, $model) = @_;
  $model //= 'default';
  if ($self->passthrough) {
    # With passthrough: try without default engine first so unknown models
    # go to passthrough instead of being routed to the default engine.
    my @r = eval { $self->router->resolve($model, skip_default => 1) };
    return @r if @r;
    return ();  # not found or error → passthrough
  }
  my @r = eval { $self->router->resolve($model) };
  return @r unless $@;
  die $@;
}

async sub handle_chat_f {
  my ($self, $session, $request) = @_;
  my ($engine, $canonical_model) = $self->_resolve( $request->model );
  unless ( $engine ) {
    return Langertha::Knarr::Response->coerce(
      await $self->passthrough->handle_chat_f( $session, $request )
    );
  }
  my $response = await $engine->chat_f( $request->chat_f_args($engine) );
  my $r = Langertha::Knarr::Response->coerce($response);
  return $r->clone_with( model => $canonical_model );
}

async sub handle_stream_f {
  my ($self, $session, $request) = @_;
  my ($engine) = $self->_resolve( $request->model );

  unless ( $engine ) {
    return await $self->passthrough->handle_stream_f( $session, $request );
  }

  unless ( _supports_streaming($engine) ) {
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
  my $models = $self->router->list_models;
  return [ map { ref $_ eq 'HASH' ? $_ : { id => "$_", object => 'model' } } @{ $models || [] } ];
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Handler::Router - Knarr handler that resolves model names via Langertha::Knarr::Router and dispatches to engines

=head1 VERSION

version 1.100

=head1 SYNOPSIS

    use Langertha::Knarr::Config;
    use Langertha::Knarr::Router;
    use Langertha::Knarr::Handler::Router;
    use Langertha::Knarr::Handler::Passthrough;

    my $config = Langertha::Knarr::Config->new(file => 'knarr.yaml');
    my $router = Langertha::Knarr::Router->new(config => $config);

    my $handler = Langertha::Knarr::Handler::Router->new(
        router      => $router,
        passthrough => Langertha::Knarr::Handler::Passthrough->new(
            upstreams => $config->passthrough,
        ),
    );

=head1 DESCRIPTION

Resolves incoming model names against a L<Langertha::Knarr::Router>
(which knows your C<knarr.yaml>) and dispatches to the matched
L<Langertha::Engine>. When a passthrough fallback handler is supplied,
unknown model names tunnel through to it instead of failing — this
preserves the classic Knarr behaviour where configured models go via
Langertha and everything else passes straight to the upstream API.

Streaming responses are pumped via the engine's
C<simple_chat_stream_realtime_f> for native token-by-token delivery.

=head2 router

Required. A L<Langertha::Knarr::Router> instance.

=head2 passthrough

Optional. Any L<Langertha::Knarr::Handler> consumer used as a fallback
when the router can't resolve a model.

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
