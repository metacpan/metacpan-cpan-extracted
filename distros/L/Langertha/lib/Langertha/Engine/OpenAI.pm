package Langertha::Engine::OpenAI;
# ABSTRACT: OpenAI API
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );
use Langertha::Engine::TranscriptionBase;
use Langertha::Reasoning::Profile;

extends 'Langertha::Engine::OpenAIBase';

with map { 'Langertha::Role::'.$_ } qw(
  Embedding
  Transcription
  ImageGeneration
  Tools
);


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

sub default_model { 'gpt-5.6-terra' }

# OpenAI removes whisper-1 on 2027-02-26; its successor gpt-transcribe exists
# only on OpenAI, so only this engine (and its whisper handle) defaults to it
# (k308, k313).
sub default_transcription_model { 'gpt-transcribe' }

# image_input (k266, ADR 0019 k266 Update): every modern OpenAI chat model is a
# vision model (llm-advisor, docs only, 2026-09-25), so the family keeps the
# role-derived flag and only the text-only legacy / non-chat ids clear it.
# OpenAIResponses inherits this table.
sub model_capability_corrections {
  return (
    qr/\A(?:gpt-3\.5|o1-mini|o3-mini|text-embedding|whisper|tts-|dall-e|gpt-image|gpt-realtime|gpt-audio)/
                                                     => { image_input => 0 },
    qr/-(?:audio|realtime|transcribe|tts)(?:-|\z)/   => { image_input => 0 },
    'gpt-4'                                          => { image_input => 0 },
    qr/\Agpt-4-0(?:314|613)/                         => { image_input => 0 },
    qr/\Agpt-4-32k/                                  => { image_input => 0 },
    qr/\Agpt-4-(?:\d{4}-preview|turbo-preview)\z/    => { image_input => 0 },
    qr/\Ao1-preview/                                 => { image_input => 0 },
    qr/\Agpt-oss/                                    => { image_input => 0 },
    qr/\A(?:davinci|babbage)/                        => { image_input => 0 },
  );
}

# The completion-length body key diverges by OpenAI model within the shared
# openai wire format: the gpt-5.x and gpt-6 reasoning lines dropped max_tokens
# entirely — gpt-5.x verified live 2026-08-13 (gpt-5.1 / gpt-5.6-terra reject it
# with HTTP 400 "Use 'max_completion_tokens' instead"); gpt-6 confirmed against
# the Chat Completions API reference (max_tokens "is now deprecated in favor of
# max_completion_tokens, and is not compatible with o-series models", extended
# to the gpt-5 / gpt-6 reasoning family — developers.openai.com, 2026-09-14) —
# while gpt-4.x / gpt-4o still accept it. Match the gpt-5 and gpt-6 families by
# anchored prefix, so gpt-5, gpt-5.1, gpt-5.6-*, gpt-6-astra etc. all hit the
# new key; unknown future ids keep the old key (the safe default for every
# other engine in the OpenAI-compatible family).
sub _max_tokens_key {
  my ( $self ) = @_;
  my $model = $self->can('chat_model') ? ( $self->chat_model // '' ) : '';
  return $model =~ /\Agpt-[56]/ ? 'max_completion_tokens' : 'max_tokens';
}

# k155: OpenAI reasoning models 400 on a non-default temperature while reasoning
# is active -- "Unsupported value: 'temperature' does not support 0.7 with this
# model. Only the default (1) value is supported." (live-verified 2026-09-17
# against /v1/chat/completions on gpt-5.6-terra + gpt-5.6). The rejection is
# EFFORT-AWARE, not a flat per-model capability clear: at reasoning_effort=none
# (where the model accepts it) the same call returns 200, so clearing the
# temperature capability wholesale would wrongly drop the valid effort=none path.
# It also fires on the NO-EFFORT path for a model whose server-side default effort
# is a reasoning level -- so this predicate resolves the effort INCLUDING that
# default, via the Profile's default_reasoning_off signal (k185): the
# gpt-5.1/5.2/5.4 line defaults to reasoning-OFF (reasoning_tokens=0 with no
# effort) and keeps a non-default temperature there, while gpt-5.5/5.6, gpt-6, the
# o-series and legacy gpt-5 default to reasoning-ON. It is consumed READ-ONLY by
# the shared _temperature_kwargs gate in Role::OpenAICompatible /
# Role::ResponsesCompatible; OpenAIResponses inherits it and runs on the
# 'responses' wire. Non-reasoning OpenAI models (gpt-4o, gpt-4.1, gpt-5-chat,
# gpt-5.N-chat, any unknown id) are classified by the Profile and keep their
# temperature; every other OpenAI-compatible engine never reaches this predicate
# (they do not define it).
sub _temperature_rejected_by_reasoning {
  my ( $self, $controls ) = @_;
  my $model = $self->can('chat_model') ? ( $self->chat_model // '' ) : '';
  my $profile = Langertha::Reasoning::Profile->for_model($model);
  # Which OpenAI models HAVE reasoning (and thus can reject temperature) is
  # Profile wire-truth (karr k186, ADR 0023): the o-series, gpt-5 / gpt-5.N
  # except every -chat id, and gpt-6. Non-reasoning models and unknown ids are
  # classified non-reasoning there, so their temperature is kept.
  return 0 unless $profile->is_reasoning_model;
  # Resolved reasoning effort: a per-request control (chat_f, karr #46) beats the
  # engine attribute; neither set means the model's server-side default applies.
  my $effort = exists $controls->{reasoning_effort} ? $controls->{reasoning_effort}
             : $self->has_reasoning_effort          ? $self->reasoning_effort
             :                                         undef;
  # No explicit effort: the model's server-side default effort applies. For most
  # reasoning models that default is a reasoning level (temperature rejected), but
  # the gpt-5.1/5.2/5.4 line defaults to reasoning-OFF, so a non-default
  # temperature is honored there. The Profile carries which is which
  # (default_reasoning_off, ADR 0023 wire-truth; live k185 2026-09-19).
  if ( !defined $effort ) {
    return 0 if $profile->default_reasoning_off;
    return 1;
  }
  # Explicit effort=none disables reasoning (temperature accepted) only where the
  # model's wire actually accepts 'none' as the disable value -- a read-only
  # consult of the same Langertha::Reasoning::Profile effort table the serializer
  # uses (ADR 0023). A model that cannot be disabled (gpt-6) drops a 'none' effort
  # server-side and keeps reasoning on, so temperature stays rejected there.
  if ( $effort eq 'none' ) {
    return 0 if $profile->effort_accepted_on( $self->reasoning_wire_format, 'none' );
  }
  return 1;
}

has whisper => (
  is => 'ro',
  isa => 'Langertha::Engine::TranscriptionBase',
  lazy_build => 1,
);

sub _build_whisper {
  my ($self) = @_;
  # Same settings as $self->simple_transcription would use. -- karr k293
  return Langertha::Engine::TranscriptionBase->new(
    api_key             => $self->api_key,
    url                 => $self->url,
    transcription_model => $self->transcription_model,
    user_agent_agent    => $self->user_agent_agent,
    $self->has_user_agent_timeout ? ( user_agent_timeout => $self->user_agent_timeout ) : (),
    defined $self->connect_address ? ( connect_address => $self->connect_address ) : (),
  );
}


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::OpenAI - OpenAI API

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::OpenAI;

    my $openai = Langertha::Engine::OpenAI->new(
        api_key      => $ENV{OPENAI_API_KEY},
        model        => 'gpt-5.6-terra',
        system_prompt => 'You are a helpful assistant',
        temperature  => 0.7,
    );

    my $response = $openai->simple_chat('Say something nice');
    print $response;

    # Embeddings
    my $vector = $openai->simple_embedding('Some text to embed');

    # Transcription (Whisper)
    my $text = $openai->simple_transcription('/path/to/audio.mp3');

    # Async with Future::AsyncAwait
    use Future::AsyncAwait;

    async sub ask_gpt {
        my $response = await $openai->simple_chat_f('What is Perl?');
        say $response;
        my $vector = await $openai->simple_embedding_f('Some text to embed');
    }

=head1 DESCRIPTION

Provides access to OpenAI's APIs, including GPT models, embeddings, and
Whisper transcription. Composes L<Langertha::Role::OpenAICompatible> for the
standard OpenAI API format.

Popular models: C<gpt-6-astra> (GPT-6 flagship — 1.05M-token context, 128K max
output, text+image input, knowledge cutoff 2026-04-30), C<gpt-5.6-terra>
(default, balances intelligence and cost — the GPT-5.6 successor of the former
mini tier), C<gpt-5.6> (Sol, frontier), C<gpt-5.6-luna> (cost-sensitive,
successor of the former nano tier), C<text-embedding-3-large> (embeddings),
C<gpt-transcribe> (transcription, default), C<gpt-image-2> (image generation,
default).

Dynamic model listing is supported via L<Langertha::Role::Models/list_models>.
Results are cached for C<models_cache_ttl> seconds (default: 3600).

Get your API key at L<https://platform.openai.com/> and set
C<LANGERTHA_OPENAI_API_KEY> in your environment.

B<THIS API IS WORK IN PROGRESS>

=head2 compatibility_for_engine

Optional identifier of the engine this instance is acting as a compatibility
shim for. Used internally when one engine is accessed via another's OpenAI
endpoint.

=head2 whisper

Lazy-built L<Langertha::Engine::TranscriptionBase> instance bound to
this engine's C<api_key>, C<url>, C<transcription_model> (C<gpt-transcribe>
unless set), C<user_agent_agent>, C<user_agent_timeout> and
L<Langertha::Role::HTTP/connect_address>, so it
transcribes exactly as C<< $openai->simple_transcription >> does.
Useful when you have an OpenAI engine handy and want a focused
transcription handle without re-stating credentials:

    my $text = $openai->whisper->simple_transcription('/path/audio.mp3');

The transcription engine is fully independent: configure it directly
(C<temperature>, C<language>, etc.) via the returned object, or
construct your own L<Langertha::Engine::TranscriptionBase> if you need
a different model or endpoint.

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
