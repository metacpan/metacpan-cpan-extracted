package Langertha::Engine::TSystems;
# ABSTRACT: T-Systems AI Foundation Services (LLM Hub)
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Embedding', 'Langertha::Role::Tools';

# NOTE (karr #184 / ADR 0024): the project has no available developer key for AIFS (the
# LANGERTHA_TSYSTEMS_API_KEY / test key is empty and none is obtainable), so this engine's wire
# behavior -- notably whether gpt-oss-120b rejects tools + a structured-output response_format -- is
# documentation-derived, NOT live-verified. Verify changes against docs.llmhub.t-systems.net.


has '+url' => (
  lazy => 1,
  default => sub { 'https://llm-server.llmhub.t-systems.net/v2' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_TSYSTEMS_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_TSYSTEMS_API_KEY or api_key set";
}

sub default_model { 'gpt-oss-120b' }

sub default_embedding_model { 'text-embedding-bge-m3' }

# Docs-only engine, a dimensions field is not documented or verifiable (k319).
sub _embedding_dimensions_field { undef }

sub _build_supported_operations {[qw(
  createChatCompletion
  createEmbedding
)]}

# image_input (k266, ADR 0019 k266 Update): DOCS ONLY, no key exists
# (docs.llmhub.t-systems.net/models/vision/, llm-advisor 2026-09-25). The
# catch-all first row clears the flag (the default gpt-oss-120b makes no
# claim); the listed vision models re-assert it. The docs spell ids
# inconsistently (qwen-3.6-35b-fp8 vs Qwen3.6-35B-A3B-FP8), so every row is
# case-insensitive and tolerates a missing dash before the version. The hub
# documents gpt-5.4+/5.5/5.6-*, gemini-3.1-pro(-long-context), gemini-3.5-flash,
# claude-opus-4.8 / claude-*-5 and GLM-5.2 as TEXT-ONLY, so the gpt-5 and
# gemini-3 rows are pinned to the listed vision ids (gpt-5, gpt-5-mini,
# gpt-5-codex; gemini-3-flash, gemini-3-pro[-long-context|-image]) (k280,
# llm-advisor re-read 2026-09-25).
sub model_capability_corrections {
  return (
    qr/\A/                                   => { image_input => 0 },
    qr/\Agemma-?4(?!\d)/i                    => { image_input => 1 },
    qr/\Aglm-?5\.3-flash/i                   => { image_input => 1 },
    qr/\Amistral-small-?4(?!\d)/i            => { image_input => 1 },
    qr/\Amistral-medium-?3(?!\d)/i           => { image_input => 1 },
    qr/\Aqwen-?3\.[68](?!\d)/i               => { image_input => 1 },
    qr/\Agpt-5(?:-mini|-codex)?\z/i          => { image_input => 1 },
    qr/\Aclaude-(?:[a-z]+-)?4[.-][56](?!\d)/i => { image_input => 1 },
    qr/\Agemini-3-(?:flash|pro)\b/i          => { image_input => 1 },
  );
}

# Model metadata probe (k281, ADR 0032): GET {url}/models (the /v2 base) lists
# data[].meta_data.input_modalities. DOCS ONLY: the shape is from the public
# OpenAPI document (llm-server.llmhub.t-systems.net/openapi.json); no key
# exists to see a real answer.
sub model_metadata_format { 'tsystems' }
sub model_metadata_url    { $_[0]->url . $_[0]->list_models_path }

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::TSystems - T-Systems AI Foundation Services (LLM Hub)

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::TSystems;

    my $tsi = Langertha::Engine::TSystems->new(
        api_key => $ENV{LANGERTHA_TSYSTEMS_API_KEY},
        model   => 'gpt-oss-120b',
    );

    print $tsi->simple_chat('Hello from AIFS!');

    my $vector = $tsi->simple_embedding('embed me');

=head1 DESCRIPTION

Provides access to T-Systems' B<AI Foundation Services> (formerly LLM Hub),
an OpenAI-compatible aggregator hosted in Germany / the EU. Composes
L<Langertha::Role::OpenAICompatible> with the AIFS endpoint
(C<https://llm-server.llmhub.t-systems.net/v2>) and Bearer auth.

T-Systems AIFS exposes 30+ open-source and proprietary models behind a single
OpenAI-compatible API. Models hosted on B<T-Cloud> are processed exclusively
in Germany (Llama 3.3, Qwen3-Next 80B, Mistral Small 4, C<gpt-oss-120b>,
Gemma 4, plus the C<BGE-M3> / C<text-embedding-bge-m3> and Jina embeddings);
EU-hosted hyperscaler models are processed within the EU and now include
current frontier models — GPT-5.2 / GPT-5, Claude Sonnet 4.6 / Haiku 4.5, and
Gemini 3 Pro / Flash. This makes AIFS a sovereign-EU route to otherwise non-EU
frontier models. GDPR-compliant.

Get a trial API key at L<https://apikey.llmhub.t-systems.net/> and set
C<LANGERTHA_TSYSTEMS_API_KEY> in your environment.

L<Langertha::Role::Embedding/embedding_dimensions> is not sent (it carps
once): AIFS does not document a C<dimensions> field for its embedding models,
and Langertha cannot verify it without a key.

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<https://docs.llmhub.t-systems.net/> - Official AIFS / LLM Hub documentation

=item * L<https://apikey.llmhub.t-systems.net/> - Trial API key request

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role

=item * L<Langertha::Engine::AKIOpenAI> - Another EU/Germany OpenAI-compatible engine

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
