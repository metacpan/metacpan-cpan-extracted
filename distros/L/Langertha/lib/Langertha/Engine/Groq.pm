package Langertha::Engine::Groq;
# ABSTRACT: GroqCloud API
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with map { 'Langertha::Role::'.$_ } qw(
  Transcription
  Tools
);


sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_GROQ_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_GROQ_API_KEY or api_key set";
}

has '+url' => (
  lazy => 1,
  default => sub { 'https://api.groq.com/openai/v1' },
);

sub default_model { croak "".(ref $_[0])." requires a default_model" }

sub default_transcription_model { 'whisper-large-v3' }

sub _build_supported_operations {[qw(
  createChatCompletion
  createTranscription
)]}

# karr #148 / #184: Groq rejects a JSON response_format combined with tool use --
# BOTH json_object and json_schema 400 alongside tools, with the same "json mode
# cannot be combined with tool/function calling" message (live-verified
# 2026-09-19). Its Structured Outputs (json_schema) additionally reject streaming;
# json_object + streaming is not disproven and is left through. This is a
# Groq-platform property that holds across the models it serves, so an all-models
# matcher (qr//) expresses it on the model-scoped exclusion seam
# (Langertha::Role::Chat). There is no shared gpt-oss base rule (removed k184),
# so this all-models rule is the only exclusion on Groq's own gpt-oss route.
# Consulted by chat_f (streaming => 0) and chat_stream_realtime_f (streaming => 1).
sub model_capability_exclusions {
  return (
    qr// => \&_exclude_json_schema_with_tools_or_streaming,
  );
}

sub _exclude_json_schema_with_tools_or_streaming {
  my ( $self, %request ) = @_;
  my $rf   = $request{response_format};
  my $type = ( ref $rf eq 'HASH' ) ? ( $rf->{type} // '' ) : '';
  # Streaming: only json_schema is live-confirmed to 400 (json_object + streaming
  # is not disproven, so it is left through).
  if ( $request{streaming} && $type eq 'json_schema' ) {
    croak "".(ref $self)." cannot combine response_format json_schema with "
      ."streaming: Groq Structured Outputs do not support streaming and the "
      ."API rejects this with HTTP 400. Use the non-streaming chat_f for "
      ."json_schema output.";
  }
  # Tools: BOTH json_object and json_schema 400 alongside tools.
  if ( $request{has_tools} && ( $type eq 'json_schema' || $type eq 'json_object' ) ) {
    croak "".(ref $self)." cannot combine tools with a JSON response_format "
      ."(json_object or json_schema) in one request: Groq rejects json mode "
      ."combined with tool/function calling with HTTP 400. Send tools or a JSON "
      ."response_format, not both.";
  }
  return;
}

# image_input (k266, ADR 0019 k266 Update): the only Groq vision model is
# qwen/qwen3.8-27b (console.groq.com/docs/vision, llm-advisor, docs only,
# 2026-09-25); the catch-all first row clears the flag for every other id.
#
# Groq has no default model: building chat_model croaks, and the layer-3 walk
# reads chat_model. With no model configured the table is therefore empty (so
# supports() keeps answering instead of croaking, as it did before k266) and
# the around below makes no image_input claim in its place.
sub _has_configured_model {
  my ( $self ) = @_;
  return $self->has_chat_model || $self->has_model;
}

sub model_capability_corrections {
  my ( $self ) = @_;
  return () unless $self->_has_configured_model;
  return (
    qr/\A/             => { image_input => 0 },
    'qwen/qwen3.8-27b' => { image_input => 1 },
  );
}

around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  delete $caps->{image_input} unless $self->_has_configured_model;
  return $caps;
};

# Groq reports a stream's usage under x_groq.usage on its last chunk instead
# of a top-level usage (Groq API reference / SDK chunk type; not live-verified).
# One provider's spelling, so it is read here (ADR 0018 tier 3), guarded by the
# canonical predicate: a top-level usage, when Groq sends one, wins. -- k298
around parse_stream_chunk => sub {
  my ( $orig, $self, $data, @rest ) = @_;
  my $chunk = $self->$orig( $data, @rest );
  return $chunk if $chunk && $chunk->has_usage;
  my $x_groq = ref $data eq 'HASH' ? $data->{x_groq} : undef;
  my %usage  = $self->_openai_stream_usage_kwargs( ref $x_groq eq 'HASH' ? $x_groq->{usage} : undef );
  return $chunk unless %usage;
  return $chunk->meta->clone_object( $chunk, %usage ) if $chunk;
  require Langertha::Stream::Chunk;
  return Langertha::Stream::Chunk->new( content => '', raw => $data, is_final => 0, %usage );
};

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Groq - GroqCloud API

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::Groq;

    my $groq = Langertha::Engine::Groq->new(
        api_key      => $ENV{GROQ_API_KEY},
        model        => 'llama-3.3-70b-versatile',
        system_prompt => 'You are a helpful assistant',
    );

    print $groq->simple_chat('Say something nice');

    # Audio transcription
    my $text = $groq->simple_transcription('/path/to/audio.mp3');
    # async: await $groq->simple_transcription_f(...)

=head1 DESCRIPTION

Provides access to Groq's ultra-fast LLM inference via their GroqCloud API.
Composes L<Langertha::Role::OpenAICompatible> with Groq's endpoint
(C<https://api.groq.com/openai/v1>) and API key handling.

Popular models: C<llama-3.3-70b-versatile>, C<llama-3-groq-70b-tool-use>,
C<deepseek-r1-distill-llama-70b>, C<qwen-2.5-coder-32b>. Audio transcription
uses C<whisper-large-v3> by default. No default chat model is set; C<model>
must be specified explicitly.

Dynamic model listing via C<list_models()>. Get your API key at
L<https://console.groq.com/keys> and set C<LANGERTHA_GROQ_API_KEY>.

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<https://groqstatus.com/> - Groq service status

=item * L<https://console.groq.com/docs/models> - Official Groq models documentation

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role

=item * L<Langertha::Role::Transcription> - Transcription role (Groq hosts Whisper)

=item * L<Langertha::Engine::DeepSeek> - Another OpenAI-compatible engine

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
