package Langertha::Engine::Scaleway;
# ABSTRACT: Scaleway Generative APIs
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Embedding', 'Langertha::Role::Tools';


has '+url' => (
  lazy => 1,
  default => sub { 'https://api.scaleway.ai/v1' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_SCALEWAY_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_SCALEWAY_API_KEY or api_key set";
}

# llama-3.1-8b-instruct went EOL on Scaleway's serverless tier (supported-models
# page, 2026-09-25); llama-3.3-70b-instruct is still served (k307).
sub default_model { 'llama-3.3-70b-instruct' }

# Scaleway's embedding model (supported-models list, llm-advisor 2026-09-25;
# bge-multilingual-gemma2 is also served). The OpenAI role's
# text-embedding-3-large is not (k291).
sub default_embedding_model { 'qwen3-embedding-8b' }

# Undocumented: the embeddings API docs list dimensions as unsupported (k319).
sub _embedding_dimensions_field { undef }

# Scaleway's Generative APIs narrow two flags the OpenAI role inventory grants
# (scaleway.com/en/docs/generative-apis, verified 2026-09-01):
#   * parallel_tool_calls is accepted but INERT — "even if set false this
#     parameter will be ignored and act as if set to true". A silently-ignored
#     control is worse than a rejected one, so clear parallel_tool_use.
#   * response_format json_object is deprecated ("should not be used anymore");
#     json_schema is the supported structured-output path, so clear json_object
#     and keep json_schema.
# NOT cleared: tool_choice_any. Scaleway's tool_choice enum is
# none|auto|required, and Langertha's canonical `any` serializes to the wire
# `required` (Langertha::ToolChoice::to_openai), which Scaleway accepts. (The
# k138 matrix flagged tool_choice_any here by reading OpenAI's non-existent
# literal "any"; the canonical mapping makes the flag correct as-is.)
around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  delete @{$caps}{ qw( parallel_tool_use response_format_json_object ) };
  return $caps;
};

# image_input (k266, ADR 0019 k266 Update): Scaleway serves text-only and
# vision models side by side (llm-advisor, docs only, 2026-09-25). The
# catch-all first row clears the flag (the text-only default
# llama-3.3-70b-instruct makes no claim); the vision families re-assert it.
sub model_capability_corrections {
  return (
    qr/\A/ => { image_input => 0 },
    qr/\A(?:pixtral-|mistral-small-3\.[12]|mistral-large-3|gemma-3-27b|gemma-4|qwen3\.[56]-|holo2|molmo)/
      => { image_input => 1 },
  );
}

sub _build_supported_operations {[qw(
  createChatCompletion
  createEmbedding
)]}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Scaleway - Scaleway Generative APIs

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::Scaleway;

    my $scw = Langertha::Engine::Scaleway->new(
        api_key => $ENV{LANGERTHA_SCALEWAY_API_KEY},
        model   => 'llama-3.3-70b-instruct',
    );

    print $scw->simple_chat('Hello from Scaleway!');

=head1 DESCRIPTION

Provides access to B<Scaleway Generative APIs>, a serverless inference service
hosted in European data centers. Composes L<Langertha::Role::OpenAICompatible>
with Scaleway's endpoint (C<https://api.scaleway.ai/v1>) and Bearer auth.

Scaleway is designed as a drop-in replacement for the OpenAI API and is
EU-act compliant. Available chat models include C<llama-3.3-70b-instruct>
(default), C<mistral-small-3.2-24b-instruct-2506>, C<gemma-3-27b-it> and
others; see Scaleway's supported-models page for which are still served. Function calling, structured output and
embeddings are supported; the default embedding model is
C<qwen3-embedding-8b> (C<bge-multilingual-gemma2> is also served, set it
with C<embedding_model>).

L<Langertha::Role::Embedding/embedding_dimensions> is not sent (it carps
once): Scaleway's embeddings API documentation lists C<dimensions> under its
unsupported parameters. Pass a C<dimensions> extra to C<embedding_request> to
send it anyway.

If you want to scope requests to a specific Scaleway project, override C<url>
with C<https://api.scaleway.ai/E<lt>PROJECT_IDE<gt>/v1>.

Generate an API secret key in the Scaleway console
(L<https://console.scaleway.com/>) and set C<LANGERTHA_SCALEWAY_API_KEY>.

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<https://www.scaleway.com/en/docs/generative-apis/> - Scaleway Generative APIs documentation

=item * L<https://www.scaleway.com/en/generative-apis/> - Scaleway Generative APIs product page

=item * L<https://www.scaleway.com/en/docs/generative-apis/reference-content/supported-models/> - Supported chat and embedding models

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role

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
