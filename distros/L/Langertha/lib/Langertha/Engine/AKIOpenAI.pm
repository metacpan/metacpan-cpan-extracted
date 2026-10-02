package Langertha::Engine::AKIOpenAI;
# ABSTRACT: AKI.IO via OpenAI-compatible API
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

# Native OpenAI tool calling, live-verified 2026-09-01 against
# /openai/v1/chat/completions: a native `tools` array is accepted and answered
# with a native `tool_calls` block, arguments intact — verified on
# llama3-chat-8b, one model AKI's own table rates only "Basic Support".
# So no Role::HermesTools and no tool_wire_format override: the `openai` default
# of Langertha::Role::Tools is the wire reality. -- karr k102
with 'Langertha::Role::Tools';

# AKI.IO ships the model's chain-of-thought under the bare `reasoning` key on
# the OpenAI-compatible message. That spelling is now read by the shared
# Role::OpenAICompatible::chat_response (reasoning_content, else bare
# `reasoning`), so no AKI-scoped lift is needed here. -- karr k127, k129


# AKI.IO's OpenAI-compatibility docs are internally inconsistent about the base
# path: prose mentions /v1, but every working example (curl, Python SDK,
# machine-readable config, /models discovery) uses /openai/v1. We follow the
# working examples. See https://aki.io/docs/compatibility/openai-api-compatibility/
has '+url' => (
  lazy => 1,
  default => sub { 'https://aki.io/openai/v1' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_AKI_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_AKI_API_KEY or api_key set";
}


# gpt-oss-120b replaces the EOL llama3-chat-8b (AKI.IO end-of-life 2026-09-30)
# as the default. AKI.IO exposes MiniMax M3 only on its native endpoint, so a
# current non-MiniMax model AKI's own table rates "Supported" is the shim
# default. Verified live 2026-09-10: the /openai/v1 shim answers gpt-oss-120b
# and echoes it back as $response->model (unknown ids are rejected loudly here,
# not silently substituted). -- karr k132
sub default_model { 'gpt-oss-120b' }


sub api_key_env { 'LANGERTHA_AKI_API_KEY' }

sub _build_supported_operations {[qw( createChatCompletion )]}

# AKI.IO's OpenAI-compatibility page documents no parallel_tool_calls (nor
# tools). One live probe (2026-09-25, gpt-oss-120b, two independent tools,
# parallel_tool_calls=false) answered 200 with one tool call: the field is
# accepted, but one call cannot show it is honored. Clear parallel_tool_use
# until the docs or more evidence say otherwise (karr k242).
around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  delete $caps->{parallel_tool_use};
  return $caps;
};

# image_input (k266/k271, ADR 0019 k266 Update): AKI.IO documents no image
# input on this face and /models carries no modality field, so the catch-all
# row clears the flag (the default gpt-oss-120b makes no claim). Live probe
# 2026-09-25 (k271): an 8x8 solid-red base64 PNG sent as an image_url part to
# qwen3.6-chat-35b answered "Red", its reasoning describing "a solid, uniform
# block of color" (t/data/akiopenai_qwen36_image_response.json). Follow-up
# probe 2026-09-25 (k272), same image and prompt, max_tokens 2048:
# gemma4-chat-26b and qwen3.8-27b both answered "Red", each reasoning about a
# uniform red field (t/data/akiopenai_{gemma4,qwen38}_image_response.json).
# Each row claims the probed model's family, as k271 did for qwen3.6-35b:
# gemma4-26b is claimed with gemma4-chat-26b but was not called itself.
# Every other id (gpt-oss, llama3, apertus, mistral4, deepseek, glm) stays
# unclaimed: not probed as of 2026-09-25.
sub model_capability_corrections {
  return (
    qr/\A/               => { image_input => 0 },
    qr/\Aqwen3\.6(?!\d)/ => { image_input => 1 },
    qr/\Aqwen3\.8(?!\d)/ => { image_input => 1 },
    qr/\Agemma4(?!\d)/   => { image_input => 1 },
  );
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::AKIOpenAI - AKI.IO via OpenAI-compatible API

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::AKIOpenAI;

    # Direct construction (use /v1 model names, NOT native AKI names)
    my $aki = Langertha::Engine::AKIOpenAI->new(
        api_key => $ENV{AKI_API_KEY},
        model   => 'gpt-oss-120b',
    );

    print $aki->simple_chat('Hello!');

    # Streaming
    $aki->simple_chat_stream(sub {
        print shift->content;
    }, 'Tell me about Perl');

    # Via AKI's openai() method (uses default model)
    use Langertha::Engine::AKI;

    my $aki_native = Langertha::Engine::AKI->new(
        api_key => $ENV{AKI_API_KEY},
        model   => 'llama3_8b_chat',
    );
    my $oai = $aki_native->openai;  # warns: model not mapped, uses default
    print $oai->simple_chat('Hello via OpenAI format!');

=head1 DESCRIPTION

Provides access to AKI.IO's OpenAI-compatible API at C<https://aki.io/openai/v1>.
Composes L<Langertha::Role::OpenAICompatible> for the standard OpenAI format.

AKI.IO is a European AI model hub (Germany) — fully GDPR-compliant with all
inference on EU infrastructure. Supports chat completions (with SSE streaming),
dynamic model listing, and native OpenAI-standard tool calling: tools go out as
the C<tools> array and come back as a C<tool_calls> block, the shared default of
L<Langertha::Role::Tools>. Verified live against C<llama3-chat-8b>, one model
AKI's own support table rates only "Basic Support", so the weakest documented
case works — earlier releases routed this engine through
L<Langertha::Role::HermesTools> instead, which is no longer necessary.

Embeddings and transcription are not supported. For native AKI.IO API features
(C<top_k>, C<top_p>, C<max_gen_tokens>), use L<Langertha::Engine::AKI>.

B<Chain-of-thought:> AKI.IO returns the model's reasoning under the bare
C<reasoning> key on the message. The shared OpenAI-compatible path reads that
spelling (canonical C<reasoning_content> first, then bare C<reasoning>) onto
L<Langertha::Response/thinking>, so C<< $response->thinking >> is populated.

B<Vision:> images in C<content> go out as C<image_url> parts.
C<< supports('image_input') >> is true only for the C<qwen3.6-*>,
C<qwen3.8-*> and C<gemma4-*> models, the families verified to see an image on
this endpoint; other models make no claim, which never stops an image from
being sent.

B<Client errors arrive as HTTP 529:> AKI.IO returns some B<caller-side> errors
as C<529> C<overloaded_error> — notably a token budget too small to finish a
tool call (C<"Response finished before tool_call was completed! Try to raise
max_gen_tokens">). That condition is deterministic and fixed by raising
C<response_size> / C<max_tokens>, B<not> transient server overload: do not treat
an AKI C<529> as a wait-and-retry signal, and read
C<< $error->{error}{message} >> for the real diagnostic.

Get your API key at L<https://aki.io/> and set C<LANGERTHA_AKI_API_KEY>.

B<THIS API IS WORK IN PROGRESS>

=head2 api_key

The AKI.IO API key. If not provided, reads from C<LANGERTHA_AKI_API_KEY>
environment variable. Sent as a Bearer token in the C<Authorization> HTTP
header. Required.

=head2 default_model

Returns C<gpt-oss-120b>, a current-generation non-MiniMax model AKI.IO rates
"Supported", replacing C<llama3-chat-8b>, which AKI.IO marks end-of-life
2026-09-30. AKI.IO exposes MiniMax M3 only on its native endpoint, not this
shim; the shim's only MiniMax id (C<minimax-m2.5-230b>) is the older
generation.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::AKI> - Native AKI.IO API (with top_k, top_p, max_gen_tokens)

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role composed by this engine

=item * L<https://aki.io/docs> - AKI.IO API documentation

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
