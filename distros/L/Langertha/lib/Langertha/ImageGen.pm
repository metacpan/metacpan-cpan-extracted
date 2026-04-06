package Langertha::ImageGen;
# ABSTRACT: Image generation abstraction wrapping an engine with optional overrides
our $VERSION = '0.309';
use Moose;
use Future::AsyncAwait;
use Carp qw( croak );
use Log::Any qw( $log );

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

has size => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_size',
);

has quality => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_quality',
);


sub _extra {
  my ( $self ) = @_;
  return (
    ($self->has_model   ? (model   => $self->model)   : ()),
    ($self->has_size    ? (size    => $self->size)     : ()),
    ($self->has_quality ? (quality => $self->quality)  : ()),
  );
}

sub _assert_image_engine {
  my ( $self ) = @_;
  my $engine = $self->engine;
  croak ref($engine) . " does not support image generation"
    unless $engine->does('Langertha::Role::ImageGeneration');
  return $engine;
}

# --- Plugin hook runners (async) ---

async sub _run_plugin_before_image_gen {
  my ( $self, $prompt ) = @_;
  for my $plugin (@{$self->_plugin_instances}) {
    if ($plugin->can('plugin_before_image_gen')) {
      $prompt = await $plugin->plugin_before_image_gen($prompt);
    }
  }
  return $prompt;
}

async sub _run_plugin_after_image_gen {
  my ( $self, $prompt, $result ) = @_;
  for my $plugin (@{$self->_plugin_instances}) {
    if ($plugin->can('plugin_after_image_gen')) {
      $result = await $plugin->plugin_after_image_gen($prompt, $result);
    }
  }
  return $result;
}

sub simple_image {
  my ( $self, $prompt ) = @_;
  $log->debugf("[ImageGen] simple_image via %s, model=%s",
    ref $self->engine, $self->has_model ? $self->model : 'default');
  my $engine = $self->_assert_image_engine;

  $prompt = $self->_run_plugin_before_image_gen($prompt)->get;

  my $result;
  if ($self->has_model || $self->has_size || $self->has_quality) {
    my $request = $engine->image_request($prompt, $self->_extra);
    my $response = $engine->user_agent->request($request);
    $result = $request->response_call->($response);
  } else {
    $result = $engine->simple_image($prompt);
  }

  $result = $self->_run_plugin_after_image_gen($prompt, $result)->get;

  return $result;
}



__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::ImageGen - Image generation abstraction wrapping an engine with optional overrides

=head1 VERSION

version 0.309

=head1 SYNOPSIS

    use Langertha::Engine::OpenAI;
    use Langertha::ImageGen;

    my $engine = Langertha::Engine::OpenAI->new(
        api_key => $ENV{OPENAI_API_KEY},
    );

    my $image_gen = Langertha::ImageGen->new(
        engine  => $engine,
        model   => 'dall-e-3',
        size    => '1024x1024',
        quality => 'hd',
        plugins => ['Langfuse'],
    );

    my $result = $image_gen->simple_image('A cat riding a bicycle through Paris');

=head1 DESCRIPTION

C<Langertha::ImageGen> wraps any engine that consumes
L<Langertha::Role::ImageGeneration> and adds optional overrides for
model, size, and quality, plus plugin lifecycle hooks via
L<Langertha::Role::PluginHost>.

Use this class when you need multiple image generation configurations
from the same engine instance, or when you want plugin observability
(e.g. L<Langertha::Plugin::Langfuse>) without modifying the engine.

=head2 engine

The LLM engine to delegate image generation requests to. Must consume
L<Langertha::Role::ImageGeneration>.

=head2 model

Optional model name override. When set, overrides the engine's
C<image_model> via C<%extra> pass-through.

=head2 size

Optional image size (e.g. C<'1024x1024'>, C<'1792x1024'>).

=head2 quality

Optional quality setting (e.g. C<'standard'>, C<'hd'>).

=head2 simple_image

    my $result = $image_gen->simple_image('A cat in space');

Returns the image generation result for C<$prompt>. If C<model>,
C<size>, or C<quality> overrides are set, uses them via C<%extra>;
otherwise delegates to the engine's C<simple_image>. Plugin hooks
C<plugin_before_image_gen> and C<plugin_after_image_gen> are fired.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::PluginHost> - Plugin system consumed by this class

=item * L<Langertha::Role::ImageGeneration> - Image generation role required by the engine

=item * L<Langertha::Plugin::Langfuse> - Observability plugin for image generation calls

=item * L<Langertha::Chat> - Chat counterpart to this class

=item * L<Langertha::Embedder> - Embedding counterpart to this class

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
