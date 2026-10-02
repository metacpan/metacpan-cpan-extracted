package Langertha::Engine::Mistral;
# ABSTRACT: Mistral API
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );
use File::ShareDir::ProjectDistDir qw( :all );
use Module::Runtime qw( use_module );

extends 'Langertha::Engine::OpenAIBase';

with map { 'Langertha::Role::'.$_ } qw(
  Embedding
  Transcription
  Tools
);


has '+url' => (
  lazy => 1,
  default => sub { 'https://api.mistral.ai' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_MISTRAL_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_MISTRAL_API_KEY or api_key set";
}

sub openapi_file { yaml => dist_file('Langertha','mistral.yaml') };

sub _build_openapi_operations {
  return use_module('Langertha::Spec::Mistral')->data;
}

sub default_model { 'mistral-small-latest' }

# image_input (k266, ADR 0019 k266 Update): Mistral serves text-only and vision
# models side by side (llm-advisor, docs only, 2026-09-25), so the catch-all
# first row clears the flag and the vision models re-assert it: the
# small/medium/large -latest aliases, Pixtral, Small >= 3.1 (2503 on, Small 4 =
# 2603), Medium 3.x (2505 on), Large 3 (2512 on) and Ministral 3 (2512 on).
# Codestral, Nemo, Large 2407/2411, Ministral 2410 and Small 2409/2501 are
# text-only and fall to the catch-all. Confirmed against the model cards
# (llm-advisor, docs only, read 2026-09-25; the vision guide itself is stale):
# mistral-small-latest -> mistral-small-2603 (Small 4, text+image); Medium 3.5
# = mistral-medium-3-5 / mistral-medium-3 / mistral-medium-latest (no dated
# id on the card); Large 3 = mistral-large-2512 / mistral-large-latest;
# Ministral 3 = ministral-{3,8,14}b-2512 / ministral-{3,8,14}b-latest. The
# retired Pixtral, Small 2503/2506 and Medium 2505/2508 rows stay (harmless).
sub model_capability_corrections {
  return (
    qr/\A/                                              => { image_input => 0 },
    qr/\Amistral-(?:small|medium|large)-latest\z/       => { image_input => 1 },
    qr/\Apixtral-/                                      => { image_input => 1 },
    qr/\Amistral-small-(?:250[3-9]|251\d|2[6-9]\d\d)/   => { image_input => 1 },
    qr/\Amistral-medium-(?:250[5-9]|251\d|2[6-9]\d\d)/  => { image_input => 1 },
    qr/\Amistral-large-(?:251[2-9]|2[6-9]\d\d)/         => { image_input => 1 },
    qr/\Aministral-\d+b-(?:251[2-9]|2[6-9]\d\d)/        => { image_input => 1 },
    qr/\Amistral-medium-3(?:-5)?\z/                     => { image_input => 1 },
    qr/\Aministral-\d+b-latest\z/                       => { image_input => 1 },
  );
}

sub chat_operation_id { 'chat_completion_v1_chat_completions_post' }

sub list_models_path { '/v1/models' }

# The static table above is the answer until the caller probes: /v1/models
# states capabilities.vision per model and alias, and a probed fact wins over
# the table for the models it describes (ADR 0032).
sub model_metadata_format { 'mistral' }
sub model_metadata_url    { $_[0]->url . $_[0]->list_models_path }

sub embedding_operation_id { 'embeddings_v1_embeddings_post' }

# Mistral's embedding model; the OpenAI role's text-embedding-3-large is not
# served here (k291).
sub default_embedding_model { 'mistral-embed' }

# Mistral spells it output_dimension (EmbeddingRequest is
# additionalProperties:false) and documents it for codestral-embed only (k319).
sub _embedding_dimensions_field {
  my ( $self ) = @_;
  return ( $self->embedding_model // '' ) =~ /\Acodestral-embed/ ? 'output_dimension' : undef;
}

sub transcription_operation_id { 'audio_api_v1_transcriptions_post' }

sub default_transcription_model { 'voxtral-mini-latest' }

# Mistral reads its list-valued form fields as repeated parts under the plain
# name, no [] (its SDKs' Speakeasy "standard" multipart format and its curl
# docs); OpenAI's name[] key (k286) risks a silent no-op there. The [] spelling
# is accepted and normalized too. -- karr k309, k315
around transcription_request => sub {
  my ( $orig, $self, $file, %extra ) = @_;
  for my $field (qw( timestamp_granularities context_bias )) {
    my $value = exists $extra{"${field}[]"} ? delete $extra{"${field}[]"} : $extra{$field};
    next unless ref $value eq 'ARRAY';
    $extra{$field} = { repeated => $value };
  }
  return $self->$orig( $file, %extra );
};


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Mistral - Mistral API

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::Mistral;

    my $mistral = Langertha::Engine::Mistral->new(
        api_key      => $ENV{MISTRAL_API_KEY},
        model        => 'mistral-large-latest',
        system_prompt => 'You are a helpful assistant',
        temperature  => 0.5,
    );

    print $mistral->simple_chat('Say something nice');

    my $vector = $mistral->simple_embedding($content);
    # async: await $mistral->simple_embedding_f($content)

    # Voxtral transcription
    my $text = $mistral->simple_transcription('/path/to/audio.mp3');
    my $result = $mistral->simple_transcription_result('/path/to/audio.mp3',
        timestamp_granularities => ['segment'],
        diarize                 => 'true',
        context_bias            => [qw( Langertha Voxtral )],
    );
    print "$_->{speaker_id}: $_->{text}\n" for @{ $result->{segments} };
    # async: await $mistral->simple_transcription_f(...)

=head1 DESCRIPTION

Provides access to Mistral AI's models via their API. Composes
L<Langertha::Role::OpenAICompatible> with Mistral's endpoint
(C<https://api.mistral.ai>) and its OpenAPI spec.

Popular models: C<mistral-small-latest> (default, fast), C<mistral-large-latest>
(most capable, 675B parameters), C<codestral-latest> (code generation),
C<devstral-latest> (development workflows), C<pixtral-large-latest> (vision).
Supports chat, embeddings (default embedding model C<mistral-embed>), tool
calling, and audio transcription with Voxtral: C</v1/audio/transcriptions>,
default model C<voxtral-mini-latest>, see L</transcription_request>. The audio
is given as for every engine: a path, C<\$bytes> or a filehandle (see
L<Langertha::Role::Transcription/transcription_file_part>).

L<Langertha::Role::Embedding/embedding_dimensions> is sent as Mistral's
C<output_dimension> (not C<dimensions>, which the embeddings endpoint
rejects) for C<codestral-embed*> models, the only ones Mistral documents it
for. With any other embedding model, C<mistral-embed> (fixed 1024) included,
it is not sent and carps once.

Dynamic model listing via C<list_models()>. Get your API key at
L<https://docs.mistral.ai/getting-started/quickstart/> and set
C<LANGERTHA_MISTRAL_API_KEY>.

B<THIS API IS WORK IN PROGRESS>

=head2 transcription_request

    my $request = $mistral->transcription_request($audio,
        timestamp_granularities => ['segment'],
        diarize                 => 'true',
        context_bias            => [qw( Langertha Voxtral )],
    );

Builds the Voxtral transcription request: C<POST /v1/audio/transcriptions> as
C<multipart/form-data>, with C<transcription_model> (default:
C<voxtral-mini-latest>). C<filename> in C<%extra> names the upload; the other
pairs are sent as form fields:

=over

=item * C<timestamp_granularities> - C<segment> and/or C<word>; the
C<segments> of the answer then carry C<start> and C<end>. Mistral does not
accept it together with C<language>.

=item * C<diarize> - C<'true'> labels each segment with a C<speaker_id>. Form
fields are text, so pass the string rather than a JSON boolean object.

=item * C<context_bias> - words or names the model should favour, each
without commas or whitespace.

=item * C<language>, C<temperature>.

=back

C<timestamp_granularities> and C<context_bias> take an ArrayRef and send one
part per element under the plain name, without C<[]>, which is how Mistral
reads a list field (see the C<repeated> marker of
L<Langertha::Role::HTTP/generate_multipart_body>); the C<[]> spelling
(C<timestamp_granularities[]>) is accepted and sent the same way. Get the
whole answer (C<text>, C<language>, C<segments>, C<usage>) with
L<Langertha::Role::Transcription/simple_transcription_result>, or the text
alone with L<Langertha::Role::Transcription/simple_transcription>; both have
C<_f> variants.

=head1 SEE ALSO

=over

=item * L<https://status.mistral.ai/> - Mistral service status

=item * L<https://mistral.ai/models> - Official Mistral models documentation

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role

=item * L<Langertha::Role::Transcription> - Transcription role (Voxtral)

=item * L<https://docs.mistral.ai/api/endpoint/audio/transcriptions> - Mistral transcription API

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
