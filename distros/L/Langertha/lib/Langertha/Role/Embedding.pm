package Langertha::Role::Embedding;
# ABSTRACT: Role for APIs with embedding functionality
our $VERSION = '0.503';
use Moose::Role;
use Future::AsyncAwait;
use Carp qw( croak );
use Log::Any qw( $log );
use Time::HiRes qw( gettimeofday tv_interval );
use Langertha::CallResult;

# simple_embedding_f sends through the engine's async backend (k292): injected
# client > Net::Async::HTTP > the sync LWP shim (ADR 0027).
with 'Langertha::Role::AsyncHTTP';

requires qw(
  embedding_request
  embedding_response
);

has embedding_model => (
  is => 'ro',
  isa => 'Maybe[Str]',
  lazy_build => 1,
);
sub _build_embedding_model {
  my ( $self ) = @_;
  croak "".(ref $self)." can't handle models!" unless $self->does('Langertha::Role::Models');
  return $self->model unless $self->can('default_embedding_model');
  my $default = $self->default_embedding_model;
  return $default if defined $default;
  # No fixed embedding model (self-hosted servers, k297): the caller's model,
  # never the engine's own placeholder default_model ('default' 404s on older
  # vLLM); undef leaves the model field out and the server picks.
  my $model = $self->model;
  return undef unless defined $model;
  return undef if $self->can('default_model') && $model eq $self->default_model;
  return $model;
}


has embedding_dimensions => (
  is => 'ro',
  isa => 'Maybe[Int]',
);


sub embedding {
  my ( $self, $text ) = @_;
  return $self->embedding_request($text);
}


sub simple_embedding {
  my ( $self, $text ) = @_;
  $log->debugf("[%s] simple_embedding, model=%s, %s",
    ref $self, $self->embedding_model // 'default',
    ref $text eq 'ARRAY' ? 'inputs='.scalar(@{$text}) : 'input_length='.length($text // ''));
  my $request = $self->embedding($text);
  my $response = $self->user_agent->request($request);
  return $request->response_call->($response);
}


async sub simple_embedding_f {
  my ( $self, $text ) = @_;
  $log->debugf("[%s] simple_embedding_f, model=%s, %s",
    ref $self, $self->embedding_model // 'default',
    ref $text eq 'ARRAY' ? 'inputs='.scalar(@{$text}) : 'input_length='.length($text // ''));
  my $request = $self->embedding($text);
  my $response = await $self->_async_do_request_f( request => $request );
  return $request->response_call->($response);
}


sub simple_embedding_result {
  my ( $self, $text, %extra ) = @_;
  my $model = exists $extra{model} ? $extra{model} : $self->embedding_model;
  my $request = %extra ? $self->embedding_request($text, %extra) : $self->embedding($text);
  my $t0 = [gettimeofday];
  my $response = $self->user_agent->request($request);
  my $elapsed = tv_interval($t0);
  my $value = $request->response_call->($response);
  return Langertha::CallResult->from_http_response( $self, $response,
    value => $value, model => $model, total_seconds => $elapsed );
}


async sub simple_embedding_result_f {
  my ( $self, $text, %extra ) = @_;
  my $model = exists $extra{model} ? $extra{model} : $self->embedding_model;
  my $request = %extra ? $self->embedding_request($text, %extra) : $self->embedding($text);
  my $t0 = [gettimeofday];
  my $response = await $self->_async_do_request_f( request => $request );
  my $elapsed = tv_interval($t0);
  my $value = $request->response_call->($response);
  return Langertha::CallResult->from_http_response( $self, $response,
    value => $value, model => $model, total_seconds => $elapsed );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Embedding - Role for APIs with embedding functionality

=head1 VERSION

version 0.503

=head2 embedding_model

The model name to use for embedding requests. Lazily defaults to
C<default_embedding_model> if the engine provides it, otherwise falls back
to the general C<model> attribute from L<Langertha::Role::Models>.

An engine whose C<default_embedding_model> returns C<undef> (the self-hosted
vLLM, LlamaCpp and LM Studio servers) has no fixed embedding model: it uses
the C<model> you set, and without one sends no C<model> field, so the
server embeds with the model it serves.

=head2 embedding_dimensions

Optional size of the returned vectors, for models that can shorten them
(OpenAI C<text-embedding-3-*>, C<gemini-embedding-001>, Mistral
C<codestral-embed>, matryoshka models on vLLM / SGLang). How it reaches the
wire:

=over 4

=item * C<dimensions> — L<Langertha::Engine::OpenAI>,
L<Langertha::Engine::OllamaOpenAI>, L<Langertha::Engine::vLLM>,
L<Langertha::Engine::VLLMHook>, L<Langertha::Engine::SGLang>, and top-level
on the native C</api/embed> of L<Langertha::Engine::Ollama>.

=item * C<output_dimension> — L<Langertha::Engine::Mistral>, for
C<codestral-embed*> models only.

=item * C<embedContentConfig.outputDimensionality> —
L<Langertha::Engine::Gemini>.

=item * not sent, with one C<carp> per engine instance — Mistral's other
embedding models (C<mistral-embed> included), L<Langertha::Engine::Scaleway>,
L<Langertha::Engine::LlamaCpp>, L<Langertha::Engine::LMStudioOpenAI> and
L<Langertha::Engine::TSystems>; each engine's POD says why.

=back

A matching extra passed to C<embedding_request> wins over it, and an
explicit C<dimensions> extra is always sent untouched. Unset (the default),
nothing is sent and the model answers in its native size.

=head2 embedding

    my $request = $engine->embedding($text);

Builds and returns an embedding HTTP request object for the given C<$text>.
Use L</simple_embedding> to execute the request and get the result directly.

=head2 simple_embedding

    my $vector  = $engine->simple_embedding($text);
    my $vectors = $engine->simple_embedding([ $text_a, $text_b ]);

Sends an embedding request for C<$text> and returns the embedding vector
(an ArrayRef of floats). An ArrayRef of strings is sent as one batch
request and returns an ArrayRef of vectors, one per input and in input
order. Blocks until the request completes. L</simple_embedding_f> is the
non-blocking variant.

=head2 simple_embedding_f

    my $vector  = await $engine->simple_embedding_f($text);
    my $vectors = await $engine->simple_embedding_f([ $text_a, $text_b ]);

Async variant of L</simple_embedding>: returns a L<Future> that resolves to
the same value (a vector, or an ArrayRef of vectors for an ArrayRef input)
and fails with the same error text. The request goes through the engine's
async backend (L<Langertha::Role::AsyncHTTP>), so
L<Langertha::Role::HTTP/user_agent_timeout> bounds it on
L<Net::Async::HTTP> too; without that module it runs synchronously over LWP.

=head2 simple_embedding_result

    my $result = $engine->simple_embedding_result($text);
    my $vector = $result->value;
    say $result->usage->input_tokens if $result->has_usage;

    my $large = $engine->simple_embedding_result($text, model => 'text-embedding-3-large');

Like L</simple_embedding>, but returns a L<Langertha::CallResult>: the same
vector (or ArrayRef of vectors for a batch) as C<value>, plus the provider's
C<usage>, this response's C<rate_limit>, the answering C<model> and the
measured C<total_seconds>. Croaks like L</simple_embedding>. Optional
C<%extra> goes to C<embedding_request> (e.g. a C<model> override, which is
then also the requested model of the result); L<Langertha::Embedder> uses it
for its model override.

=head2 simple_embedding_result_f

    my $result = await $engine->simple_embedding_result_f(\@texts);

Async variant of L</simple_embedding_result>, sent like
L</simple_embedding_f>: resolves to the L<Langertha::CallResult> and fails
with the same error text.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::HTTP> - HTTP transport layer

=item * L<Langertha::Role::Models> - Model selection (provides C<embedding_model>)

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
