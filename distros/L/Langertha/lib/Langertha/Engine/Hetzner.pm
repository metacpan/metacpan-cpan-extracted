package Langertha::Engine::Hetzner;
# ABSTRACT: Hetzner Inference API (OpenAI-compatible)
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with map { 'Langertha::Role::'.$_ } qw(
  StaticModels
  Tools
);



sub _build_supported_operations {[qw(
  createChatCompletion
)]}

has '+url' => (
  lazy => 1,
  default => sub { 'https://inference.hetzner.com/api/v1' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_HETZNER_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_HETZNER_API_KEY or api_key set";
}

sub default_model { 'Qwen/Qwen3.6-35B-A3B-FP8' }

# image_input (k266, ADR 0019 k266 Update): both catalog models take image input
# (see MODELS), so the engine keeps the flag Role::ImageInput (via OpenAIBase)
# brings and needs no model rows. A text-only catalog addition gets a layer-3
# clear row here.

sub default_response_size { 4096 }

# DOC-SOURCED, NOT LIVE-CONFIRMED (Hetzner blog "inference-experiment", reduced
# scope, 2026-08-17 + docs catalog, checked 2026-09-17): the Inference
# experiment was narrowed to the small Qwen models — DeepSeek-V4-Flash-0731,
# GLM-5.2-NVFP4 and Kimi-K2.7-Code were retired. This list reflects the
# published docs, not a live /v1/models read. The drift check in
# t/88_live_hetzner.t (karr k40) should confirm against the live endpoint
# before this catalog is considered frozen.
sub _build_static_models {[
  { id => 'Qwen/Qwen3.6-35B-A3B-FP8' },
  { id => 'Qwen3.8-27B' },
]}

# Hetzner Inference documents neither tool calling nor structured output on its
# OpenAI-compatible endpoint, and the platform is explicitly experimental —
# "you should not use the platform for production environments"
# (docs.hetzner.com/general/company-and-policy/experiments/inference/, verified
# 2026-09-01). Only /v1/models, /v1/completions and /v1/chat/completions exist.
# The wire shape is OpenAI-compatible, so the role inventory grants the tool and
# response_format flags — but nothing confirms the gateway honors them, so clear
# them rather than advertise capabilities that may silently no-op. Re-add via
# this around once a live test confirms them.
around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  delete @{$caps}{ qw(
    tools_native
    tool_choice_auto tool_choice_any tool_choice_none tool_choice_named
    response_format_json_object response_format_json_schema
    parallel_tool_use
  ) };
  return $caps;
};

__PACKAGE__->meta->make_immutable;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Hetzner - Hetzner Inference API (OpenAI-compatible)

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::Hetzner;

    my $hetzner = Langertha::Engine::Hetzner->new(
        api_key => $ENV{LANGERTHA_HETZNER_API_KEY},
    );

    print $hetzner->simple_chat('Hello from Perl!');

    # Streaming
    $hetzner->simple_chat_stream(sub {
        print shift->content;
    }, 'Write a poem');

    # Vision (Qwen/Qwen3.6-35B-A3B-FP8 accepts image_url content parts)
    use Langertha::Content::Image;
    my $img = Langertha::Content::Image->from_url('https://example.com/cat.jpg');
    my $resp = await $hetzner->simple_chat_f({
        role    => 'user',
        content => [ 'What is in this image?', $img ],
    });

    # Tool calling
    my $response = await $hetzner->chat_with_tools_f('Search for Perl modules');

=head1 DESCRIPTION

Provides access to L<Hetzner Cloud|https://www.hetzner.com/>'s
L<Inference API|https://inference.hetzner.com/api/v1> via their
OpenAI-compatible endpoint at C<https://inference.hetzner.com/api/v1>.

Hetzner's Inference API is currently experimental and free of charge; rate
limits are 10M input / 200K output tokens per 60 seconds per API key (HTTP 429
when exceeded). Bearer-token authentication via
C<LANGERTHA_HETZNER_API_KEY>.

Supports chat, streaming, tool calling, structured output (OpenAI-compatible
C<response_format>), and image inputs (C<image_url> content parts) on the
vision-capable models. Embeddings and transcription are not available on this
endpoint.

=head1 DEFAULT MODEL

C<Qwen/Qwen3.6-35B-A3B-FP8> — one of the two currently-listed Hetzner models,
an MoE (35B total / 3B activated), Apache 2.0, text + image input, 262K context
window. Picked because it is distinct from the existing
L<Langertha::Engine::Moonshot> default (Kimi K3); the catalog's only other entry
(C<Qwen3.8-27B>, a dense 27B model) is likewise text + image, so the choice is a
capacity/architecture preference rather than a modality one.

=head1 MODELS

The two models currently listed at C</api/v1/models> (Hetzner narrowed the
Inference experiment to the small Qwen models in Aug 2026, retiring the earlier
DeepSeek/GLM/Kimi checkpoints):

=over 4

=item * C<Qwen/Qwen3.6-35B-A3B-FP8> — C<default>. Apache 2.0. MoE 35B/3B.
262K context. Text + image input.

=item * C<Qwen3.8-27B> — dense 27B. 262K context. Text + image input.

=back

B<Tool support caveat:> the Hetzner Inference docs do not confirm server-side
tool calling or structured output on the OpenAI-compatible endpoint, and the
platform is explicitly experimental. The engine composes L<Langertha::Role::Tools>
(so C<chat_with_tools_f> exists) and L<Langertha::Role::ResponseFormat>, but
C<engine_capabilities> B<clears> C<tools_native>, every C<tool_choice_*>,
C<parallel_tool_use> and both C<response_format_*> flags rather than advertise
capabilities that may silently no-op. Tools you pass still go out in the
C<tools> array, but C<tool_choice> and C<parallel_tool_calls> are no longer
sent: C<auto> is dropped silently, a forced choice with a warning, and
C<none> leaves the tools out instead (see L<Langertha::Role::Chat/chat_f>).
If a live test confirms the gateway honors them for the model you use,
re-add them in the engine's C<around engine_capabilities>.

B<No embeddings or transcription:> the Hetzner Inference endpoint exposes chat
completions + image processing only. L</embedding> and L</transcription> are
not composed on this engine.

Get your API key at L<https://inference.hetzner.com/> and set
C<LANGERTHA_HETZNER_API_KEY> in your environment.

=head1 REFRESHING THE MODEL CATALOG

To add or remove a model: edit C<_build_static_models> below, update the
L</MODELS> POD block to match, add a Changes entry, and run the offline
tests (C<t/48_hetzner.t>, C<t/00_load.t>). The live drift check in
C<t/88_live_hetzner.t> (karr #40) compares the hardcoded catalog against
L<https://inference.hetzner.com/api/v1/models> and warns on missing models.

=head1 CAPABILITIES

Advertised flags (derived from composed roles via L<Langertha::Role::Capabilities>):

=over 4

=item * C<chat> — L<Langertha::Role::Chat>

=item * C<streaming> — L<Langertha::Role::Streaming>

=item * C<temperature> — L<Langertha::Role::Temperature>

=item * C<response_size>, C<system_prompt>, C<context_size>, C<seed>
— generation-parameter knobs the engine will honour

=back

C<tools_native>, C<tool_choice_*>, C<parallel_tool_use> and
C<response_format_*> are B<not> advertised even though L<Langertha::Role::Tools>
and L<Langertha::Role::ResponseFormat> are composed — the engine clears them in
its C<around engine_capabilities> (see the tool-support caveat above). Tools
are still sent; C<tool_choice> and C<parallel_tool_calls> are not. If a live
test confirms them, re-add them there.

Vision input is supported on both currently-listed models
(Qwen/Qwen3.6-35B-A3B-FP8 and Qwen3.8-27B) via C<image_url> content parts; this
is handled by L<Langertha::Content::Image> and L<Langertha::Role::Chat>'s
normalization — there is no engine-level C<vision> flag.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::Moonshot> - Another OpenAI-compatible cloud engine with multimodal support

=item * L<Langertha::Engine::XAI> - Another OpenAI-compatible cloud engine with vision + tool calling

=item * L<https://inference.hetzner.com/> - Hetzner Inference API

=item * L<Langertha::Engine::OpenAIBase> - Base class for OpenAI-compatible engines

=item * L<Langertha::Role::Tools> - MCP tool calling interface

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
