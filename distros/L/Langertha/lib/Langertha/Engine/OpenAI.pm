package Langertha::Engine::OpenAI;
# ABSTRACT: OpenAI API
our $VERSION = '0.305';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::'.$_ for (qw(
  ResponseFormat
  Embedding
  Transcription
  ImageGeneration
  Tools
));


has compatibility_for_engine => (
  is => 'ro',
  predicate => 'has_compatibility_for_engine',
);


has '+url' => (
  lazy => 1,
  default => sub { 'https://api.openai.com/v1' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_OPENAI_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_OPENAI_API_KEY or api_key set";
}

sub default_model { 'gpt-4o-mini' }

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::OpenAI - OpenAI API

=head1 VERSION

version 0.305

=head1 SYNOPSIS

    use Langertha::Engine::OpenAI;

    my $openai = Langertha::Engine::OpenAI->new(
        api_key      => $ENV{OPENAI_API_KEY},
        model        => 'gpt-4o-mini',
        system_prompt => 'You are a helpful assistant',
        temperature  => 0.7,
    );

    my $response = $openai->simple_chat('Say something nice');
    print $response;

    # Embeddings
    my $embedding = $openai->embedding('Some text to embed');

    # Transcription (Whisper)
    my $text = $openai->transcription('/path/to/audio.mp3');

    # Async with Future::AsyncAwait
    use Future::AsyncAwait;

    async sub ask_gpt {
        my $response = await $openai->simple_chat_f('What is Perl?');
        say $response;
    }

=head1 DESCRIPTION

Provides access to OpenAI's APIs, including GPT models, embeddings, and
Whisper transcription. Composes L<Langertha::Role::OpenAICompatible> for the
standard OpenAI API format.

Popular models: C<gpt-4o-mini> (default, fast), C<gpt-4o> (most capable),
C<o1>/C<o3-mini> (reasoning), C<text-embedding-3-large> (embeddings),
C<whisper-1> (transcription).

Dynamic model listing is supported via L<Langertha::Role::Models/list_models>.
Results are cached for C<models_cache_ttl> seconds (default: 3600).

Get your API key at L<https://platform.openai.com/> and set
C<LANGERTHA_OPENAI_API_KEY> in your environment.

B<THIS API IS WORK IN PROGRESS>

=head2 compatibility_for_engine

Optional identifier of the engine this instance is acting as a compatibility
shim for. Used internally when one engine is accessed via another's OpenAI
endpoint.

=head1 SEE ALSO

=over

=item * L<https://status.openai.com/> - OpenAI service status

=item * L<https://platform.openai.com/docs> - Official OpenAI documentation

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role composed by this engine

=item * L<Langertha::Role::Tools> - MCP tool calling interface

=item * L<Langertha::Engine::DeepSeek> - DeepSeek (via OpenAICompatible role)

=item * L<Langertha::Engine::Groq> - Groq (via OpenAICompatible role)

=item * L<Langertha::Engine::Mistral> - Mistral (via OpenAICompatible role)

=item * L<Langertha::Engine::vLLM> - vLLM inference server (via OpenAICompatible role)

=item * L<Langertha::Engine::NousResearch> - Nous Research (via OpenAICompatible role)

=item * L<Langertha::Engine::Perplexity> - Perplexity Sonar (via OpenAICompatible role)

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
