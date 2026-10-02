package Langertha::Engine::XAI;
# ABSTRACT: xAI Grok API
our $VERSION = '0.503';
use Moose;
use Carp qw( carp croak );

extends 'Langertha::Engine::OpenAIBase';

with map { 'Langertha::Role::'.$_ } qw(
  ImageGeneration
  Tools
);


sub _build_supported_operations {[qw(
  createChatCompletion
  createImage
)]}

has '+url' => (
  lazy => 1,
  default => sub { 'https://api.x.ai/v1' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_XAI_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_XAI_API_KEY or api_key set";
}

sub default_model { 'grok-4.7' }

# image_input (k266, k280, ADR 0019 k266 Update): every grok-4 chat model in
# the docs.x.ai catalogue lists text+image input -- grok-4.3, 4.5, 4.6, 4.7,
# the grok-4.20 family and grok-build-0.1 (aliases grok-code-fast-1 /
# grok-code-fast); retired grok-4-0709 / grok-4-fast-* / grok-4-1-fast-*
# redirect to grok-4.3 (llm-advisor, docs only, read 2026-09-25). Other
# families are unchecked, so the catch-all first row clears the flag.
sub model_capability_corrections {
  return (
    qr/\A/                         => { image_input => 0 },
    qr/\Agrok-4(?:[.-]|\z)/        => { image_input => 1 },
    qr/\Agrok-(?:build-|code-fast)/ => { image_input => 1 },
  );
}

sub default_image_model { 'grok-imagine-image-2.0' }

# xAI's /v1/images/generations takes aspect_ratio and resolution in place of
# OpenAI's size / quality / style and does not accept those; one passed in
# (Langertha::ImageGen forwards size and quality) is dropped with a warning,
# as k308 drops response_format for gpt-image. -- karr k309
around image_request => sub {
  my ( $orig, $self, $prompt, %extra ) = @_;
  if ( my @unsupported = grep { exists $extra{$_} } qw( quality size style ) ) {
    delete @extra{@unsupported};
    carp "".(ref $self)." image_request: xAI does not take "
      . join( ', ', @unsupported ) . " (use aspect_ratio / resolution); dropped";
  }
  return $self->$orig( $prompt, %extra );
};


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::XAI - xAI Grok API

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::XAI;

    my $xai = Langertha::Engine::XAI->new(
        api_key       => $ENV{XAI_API_KEY},
        model         => 'grok-4.7',
        system_prompt => 'You are a helpful assistant',
    );

    print $xai->simple_chat('Say something nice');

    # Streaming
    $xai->simple_chat_stream(sub {
        print shift->content;
    }, 'Write a poem');

    # Tool calling
    my $response = await $xai->chat_with_tools_f('Search for Perl modules');

    # Image generation (Imagine API)
    my $images = $xai->simple_image('A lighthouse at dusk',
        aspect_ratio => '16:9', resolution => '2k');
    print $images->[0]{url}, "\n";
    # async: await $xai->simple_image_f(...)

=head1 DESCRIPTION

Provides access to L<xAI|https://x.ai/>'s Grok models via their
OpenAI-compatible API at C<https://api.x.ai/v1>. Composes
L<Langertha::Role::OpenAICompatible> with xAI's endpoint and API key
handling, plus L<Langertha::Role::Tools> for MCP tool calling.

Grok 4.7 (C<grok-4.7>, the default) is xAI's current flagship general model,
with a 500K-token context window and agentic tool calling. C<model> takes any
id the API serves, such as the previous default C<grok-4.6>; xAI's models page
lists only C<grok-4.7> today, so check L<https://docs.x.ai/docs/models> before
relying on an older id. Grok has no knowledge of current events beyond its
training cut-off unless you enable xAI's server-side Web Search / X Search
tools.

The engine covers chat, streaming, tool calling, structured output, and
image generation with the Imagine API (C</v1/images/generations>, default
model C<grok-imagine-image-2.0>, see L</image_request>). xAI's audio (Voice
API) and video endpoints are not exposed.

C<reasoning_effort> goes out on C<chat/completions> only with a level the
model accepts: C<low>/C<medium>/C<high>/C<xhigh> on C<grok-4.6> and later,
C<low>/C<medium>/C<high> on C<grok-4.5>. Grok always reasons (server default
C<high>), so C<none>, C<minimal> and C<max> are dropped and the default
applies (see L<Langertha::Reasoning::Profile>).

Set C<prompt_cache_key> to a stable per-conversation value to steer xAI's
best-effort prompt-cache routing: it goes out as a C<prompt_cache_key> body
field on C<chat/completions>, which xAI plumbs internally to its
C<x-grok-conv-id> sticky-routing hint. Check
C<< $response->usage->cached_tokens >> to confirm a cache hit actually
happened.

Get your API key at L<https://console.x.ai/> and set
C<LANGERTHA_XAI_API_KEY> in your environment.

B<THIS API IS WORK IN PROGRESS>

=head2 image_request

    my $request = $xai->image_request('A lighthouse at dusk',
        aspect_ratio    => '16:9',
        resolution      => '2k',
        n               => 2,
        response_format => 'b64_json',
    );

Builds the Imagine API request (C<POST /v1/images/generations>) with
C<image_model> (default: C<grok-imagine-image-2.0>). xAI's own options pass
through as given: C<aspect_ratio> (such as C<1:1>, C<16:9>), C<resolution>
(C<1k>, C<1.5k>, C<2k>), C<n> (up to 10 images) and C<response_format>
(C<url>, the default, or C<b64_json>). The OpenAI options C<size>,
C<quality> and C<style> are not accepted by xAI and are dropped with a
warning. L<Langertha::Role::OpenAICompatible/simple_image> and
L<Langertha::Role::ImageGeneration/simple_image_f> return the ArrayRef of
images (C<url> or C<b64_json> each).

=head1 SEE ALSO

=over

=item * L<https://status.x.ai/> - xAI service status

=item * L<https://docs.x.ai/docs/models> - Official xAI models documentation

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role

=item * L<Langertha::Role::Tools> - MCP tool calling interface

=item * L<Langertha::Role::ImageGeneration> - Image generation role (Imagine API)

=item * L<https://docs.x.ai/docs/guides/image-generations> - xAI image generation guide

=item * L<Langertha::Engine::Groq> - Another OpenAI-compatible engine

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
