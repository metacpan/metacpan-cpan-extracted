package Langertha::Embedder;
# ABSTRACT: Embedding abstraction wrapping an engine with optional model override
our $VERSION = '0.503';
use Moose;
use Future::AsyncAwait;
use Carp qw( croak );
use Log::Any qw( $log );
use Scalar::Util qw( refaddr );

with 'Langertha::Role::PluginHost';


has engine => (
  is       => 'ro',
  required => 1,
);

has model => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_model',
);


async sub _run_plugin_before_embedding {
  my ( $self, $text ) = @_;
  for my $plugin (@{$self->_plugin_instances}) {
    if ($plugin->can('plugin_before_embedding')) {
      $text = await $plugin->plugin_before_embedding($text);
    }
  }
  return $text;
}

# $call_result (optional) is the Langertha::CallResult of the *_result path;
# every hook gets the same one, while the vector is piped hook to hook.
async sub _run_plugin_after_embedding {
  my ( $self, $text, $vector, $call_result ) = @_;
  for my $plugin (@{$self->_plugin_instances}) {
    if ($plugin->can('plugin_after_embedding')) {
      $vector = await $plugin->plugin_after_embedding($text, $vector,
        defined $call_result ? ($call_result) : ());
    }
  }
  return $vector;
}

sub _assert_embedding_engine {
  my ( $self ) = @_;
  my $engine = $self->engine;
  croak ref($engine) . " does not support embeddings"
    unless $engine->does('Langertha::Role::Embedding');
  return $engine;
}

# The engine's CallResult when the hooks returned its own vector, else a new
# one carrying the hooks' vector (CallResult is immutable).
sub _with_hooked_value {
  my ( $call_result, $value ) = @_;
  my $old = $call_result->value;
  return $call_result if ref $value && ref $old && refaddr($value) == refaddr($old);
  return $call_result->with_value($value);
}

sub simple_embedding {
  my ( $self, $text ) = @_;
  $log->debugf("[Embedder] simple_embedding via %s, model=%s",
    ref $self->engine, $self->has_model ? $self->model : 'default');
  my $engine = $self->engine;
  croak ref($engine) . " does not support embeddings"
    unless $engine->does('Langertha::Role::Embedding');

  $text = $self->_run_plugin_before_embedding($text)->get;

  my $vector;
  if ($self->has_model) {
    my $request = $engine->embedding_request($text, model => $self->model);
    my $response = $engine->user_agent->request($request);
    $vector = $request->response_call->($response);
  } else {
    $vector = $engine->simple_embedding($text);
  }

  $vector = $self->_run_plugin_after_embedding($text, $vector)->get;

  return $vector;
}


async sub simple_embedding_f {
  my ( $self, $text ) = @_;
  $log->debugf("[Embedder] simple_embedding_f via %s, model=%s",
    ref $self->engine, $self->has_model ? $self->model : 'default');
  my $engine = $self->engine;
  croak ref($engine) . " does not support embeddings"
    unless $engine->does('Langertha::Role::Embedding');
  $text = await $self->_run_plugin_before_embedding($text);
  my $vector;
  if ($self->has_model) {
    my $request = $engine->embedding_request($text, model => $self->model);
    my $response = await $engine->_async_do_request_f( request => $request );
    $vector = $request->response_call->($response);
  } else {
    $vector = await $engine->simple_embedding_f($text);
  }
  return await $self->_run_plugin_after_embedding($text, $vector);
}


sub simple_embedding_result {
  my ( $self, $text ) = @_;
  $log->debugf("[Embedder] simple_embedding_result via %s, model=%s",
    ref $self->engine, $self->has_model ? $self->model : 'default');
  my $engine = $self->_assert_embedding_engine;
  $text = $self->_run_plugin_before_embedding($text)->get;
  my $result = $engine->simple_embedding_result($text,
    $self->has_model ? ( model => $self->model ) : ());
  my $vector = $self->_run_plugin_after_embedding($text, $result->value, $result)->get;
  return _with_hooked_value($result, $vector);
}


async sub simple_embedding_result_f {
  my ( $self, $text ) = @_;
  $log->debugf("[Embedder] simple_embedding_result_f via %s, model=%s",
    ref $self->engine, $self->has_model ? $self->model : 'default');
  my $engine = $self->_assert_embedding_engine;
  $text = await $self->_run_plugin_before_embedding($text);
  my $result = await $engine->simple_embedding_result_f($text,
    $self->has_model ? ( model => $self->model ) : ());
  my $vector = await $self->_run_plugin_after_embedding($text, $result->value, $result);
  return _with_hooked_value($result, $vector);
}



__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Embedder - Embedding abstraction wrapping an engine with optional model override

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::OpenAI;
    use Langertha::Embedder;

    my $engine = Langertha::Engine::OpenAI->new(
        api_key => $ENV{OPENAI_API_KEY},
        model   => 'text-embedding-3-small',
    );

    my $embedder = Langertha::Embedder->new(
        engine  => $engine,
        plugins => ['Langfuse'],
    );

    my $vector = $embedder->simple_embedding('Hello world');

    # Override model per-embedder
    my $large = Langertha::Embedder->new(
        engine => $engine,
        model  => 'text-embedding-3-large',
    );

=head1 DESCRIPTION

C<Langertha::Embedder> wraps any engine that consumes
L<Langertha::Role::Embedding> and adds an optional model override plus
plugin lifecycle hooks via L<Langertha::Role::PluginHost>.

Use this class when you need multiple embedding configurations from the
same engine instance, or when you want plugin observability (e.g.
L<Langertha::Plugin::Langfuse>) without modifying the engine.

=head2 engine

The LLM engine to delegate embedding requests to. Must consume
L<Langertha::Role::Embedding>.

=head2 model

Optional model name override. When set, overrides the engine's
C<embedding_model> for requests made through this Embedder.

=head2 simple_embedding

    my $vector = $embedder->simple_embedding($text);

Returns the embedding vector for C<$text>; an ArrayRef of strings is one
batch request and returns an ArrayRef of vectors in input order (the
plugin hooks see the whole batch). If C<model> is set, uses it
as an override; otherwise delegates directly to the engine's
C<simple_embedding>. Plugin hooks C<plugin_before_embedding> and
C<plugin_after_embedding> are fired around the request.

=head2 simple_embedding_f

    my $vector = await $embedder->simple_embedding_f($text);

Async variant of L</simple_embedding>: the same result and plugin hooks, with
the hooks awaited and the request sent through the engine's async backend
(see L<Langertha::Role::Embedding/simple_embedding_f>).

=head2 simple_embedding_result

    my $result = $embedder->simple_embedding_result($text);
    my $vector = $result->value;
    say $result->usage->input_tokens if $result->has_usage;

Like L</simple_embedding>, with the same model override and plugin hooks,
but returns the L<Langertha::CallResult> of
L<Langertha::Role::Embedding/simple_embedding_result>: C<value> is the vector
after the after-hooks, and C<usage>, C<rate_limit>, C<model> and
C<total_seconds> are the call's. C<plugin_after_embedding> gets that
C<CallResult> as an extra third argument (see L<Langertha::Plugin>). When a
hook returns a different vector, the result is a new C<CallResult> with that
value and the other attributes copied.

=head2 simple_embedding_result_f

    my $result = await $embedder->simple_embedding_result_f($text);

Async variant of L</simple_embedding_result>: the same result and hooks, sent
through the engine's async backend like L</simple_embedding_f>.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::PluginHost> - Plugin system consumed by this class

=item * L<Langertha::Role::Embedding> - Embedding role required by the engine

=item * L<Langertha::Plugin::Langfuse> - Observability plugin for embedding calls

=item * L<Langertha::Chat> - Chat counterpart to this class

=item * L<Langertha::ImageGen> - Image generation counterpart to this class

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
