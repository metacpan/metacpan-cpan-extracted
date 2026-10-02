package Langertha::ImageGen;
# ABSTRACT: Image generation abstraction wrapping an engine with optional overrides
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

# $call_result (optional) is the Langertha::CallResult of the *_result path;
# every hook gets the same one, while the images are piped hook to hook.
async sub _run_plugin_after_image_gen {
  my ( $self, $prompt, $result, $call_result ) = @_;
  for my $plugin (@{$self->_plugin_instances}) {
    if ($plugin->can('plugin_after_image_gen')) {
      $result = await $plugin->plugin_after_image_gen($prompt, $result,
        defined $call_result ? ($call_result) : ());
    }
  }
  return $result;
}

# The engine's CallResult when the hooks returned its own images, else a new
# one carrying the hooks' value (CallResult is immutable).
sub _with_hooked_value {
  my ( $call_result, $value ) = @_;
  my $old = $call_result->value;
  return $call_result if ref $value && ref $old && refaddr($value) == refaddr($old);
  return $call_result->with_value($value);
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


async sub simple_image_f {
  my ( $self, $prompt ) = @_;
  $log->debugf("[ImageGen] simple_image_f via %s, model=%s",
    ref $self->engine, $self->has_model ? $self->model : 'default');
  my $engine = $self->_assert_image_engine;
  $prompt = await $self->_run_plugin_before_image_gen($prompt);
  my $result = await $engine->simple_image_f($prompt, $self->_extra);
  return await $self->_run_plugin_after_image_gen($prompt, $result);
}


sub simple_image_result {
  my ( $self, $prompt ) = @_;
  $log->debugf("[ImageGen] simple_image_result via %s, model=%s",
    ref $self->engine, $self->has_model ? $self->model : 'default');
  my $engine = $self->_assert_image_engine;
  $prompt = $self->_run_plugin_before_image_gen($prompt)->get;
  my $call_result = $engine->simple_image_result($prompt, $self->_extra);
  my $images = $self->_run_plugin_after_image_gen($prompt, $call_result->value, $call_result)->get;
  return _with_hooked_value($call_result, $images);
}


async sub simple_image_result_f {
  my ( $self, $prompt ) = @_;
  $log->debugf("[ImageGen] simple_image_result_f via %s, model=%s",
    ref $self->engine, $self->has_model ? $self->model : 'default');
  my $engine = $self->_assert_image_engine;
  $prompt = await $self->_run_plugin_before_image_gen($prompt);
  my $call_result = await $engine->simple_image_result_f($prompt, $self->_extra);
  my $images = await $self->_run_plugin_after_image_gen($prompt, $call_result->value, $call_result);
  return _with_hooked_value($call_result, $images);
}



__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::ImageGen - Image generation abstraction wrapping an engine with optional overrides

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::OpenAI;
    use Langertha::ImageGen;

    my $engine = Langertha::Engine::OpenAI->new(
        api_key => $ENV{OPENAI_API_KEY},
    );

    my $image_gen = Langertha::ImageGen->new(
        engine  => $engine,
        model   => 'gpt-image-2',
        size    => '1024x1024',
        quality => 'high',
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

Optional image size (e.g. C<'1024x1024'>, C<'1536x1024'>).

=head2 quality

Optional quality setting (e.g. C<'low'>, C<'medium'>, C<'high'> for GPT image models).

=head2 simple_image

    my $result = $image_gen->simple_image('A cat in space');

Returns the image generation result for C<$prompt>. If C<model>,
C<size>, or C<quality> overrides are set, uses them via C<%extra>;
otherwise delegates to the engine's C<simple_image>. Plugin hooks
C<plugin_before_image_gen> and C<plugin_after_image_gen> are fired.

=head2 simple_image_f

    my $result = await $image_gen->simple_image_f('A cat in space');

Async variant of L</simple_image>: the same result, overrides and plugin
hooks, with the hooks awaited and the request sent through the engine's
async backend (see L<Langertha::Role::ImageGeneration/simple_image_f>).

=head2 simple_image_result

    my $result = $image_gen->simple_image_result('A cat in space');
    my $images = $result->value;
    say $result->usage->output_tokens if $result->has_usage;

Like L</simple_image>, with the same overrides and plugin hooks, but returns
the L<Langertha::CallResult> of
L<Langertha::Role::ImageGeneration/simple_image_result>: C<value> is the
image result after the after-hooks, and C<usage>, C<rate_limit>, C<model>
and C<total_seconds> are the call's. C<plugin_after_image_gen> gets that
C<CallResult> as an extra third argument (see L<Langertha::Plugin>). When a
hook returns a different value, the result is a new C<CallResult> with that
value and the other attributes copied.

=head2 simple_image_result_f

    my $result = await $image_gen->simple_image_result_f('A cat in space');

Async variant of L</simple_image_result>: the same result, overrides and
hooks, sent through the engine's async backend like L</simple_image_f>.

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
