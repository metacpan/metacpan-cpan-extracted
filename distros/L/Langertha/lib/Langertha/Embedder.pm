package Langertha::Embedder;
# ABSTRACT: Embedding abstraction wrapping an engine with optional model override
our $VERSION = '0.404';
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


async sub _run_plugin_before_embedding {
  my ( $self, $text ) = @_;
  for my $plugin (@{$self->_plugin_instances}) {
    if ($plugin->can('plugin_before_embedding')) {
      $text = await $plugin->plugin_before_embedding($text);
    }
  }
  return $text;
}

async sub _run_plugin_after_embedding {
  my ( $self, $text, $vector ) = @_;
  for my $plugin (@{$self->_plugin_instances}) {
    if ($plugin->can('plugin_after_embedding')) {
      $vector = await $plugin->plugin_after_embedding($text, $vector);
    }
  }
  return $vector;
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



__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Embedder - Embedding abstraction wrapping an engine with optional model override

=head1 VERSION

version 0.404

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

Returns the embedding vector for C<$text>. If C<model> is set, uses it
as an override; otherwise delegates directly to the engine's
C<simple_embedding>. Plugin hooks C<plugin_before_embedding> and
C<plugin_after_embedding> are fired around the request.

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
