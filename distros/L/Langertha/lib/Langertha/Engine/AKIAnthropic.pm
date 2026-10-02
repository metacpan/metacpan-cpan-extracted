package Langertha::Engine::AKIAnthropic;
# ABSTRACT: AKI.IO via Anthropic-compatible API
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::AnthropicBase';

with 'Langertha::Role::StaticModels';


# AnthropicBase->chat_request appends '/v1/messages' to url; the default must
# therefore stop at '/anthropic' so the composed endpoint is a single
# '/anthropic/v1/messages' (a '/anthropic/v1' default double-stacks to
# '/anthropic/v1/v1/messages' -> HTTP 404). AKI.IO documents the same rule for
# the Anthropic Python SDK: "AKI.IO API internally appends /v1/messages, so we
# recommend using https://aki.io/anthropic for the base_url instead."
has '+url' => (
  lazy => 1,
  default => sub { 'https://aki.io/anthropic' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_AKI_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_AKI_API_KEY or api_key set";
}


# gpt-oss-120b replaces the EOL llama3-chat-8b (AKI.IO end-of-life 2026-09-30)
# as the default. AKI.IO exposes MiniMax M3 only on its native endpoint, so a
# current non-MiniMax model AKI's own table rates "Supported" is the shim
# default. Verified live 2026-09-10: the /anthropic shim answers gpt-oss-120b
# and echoes it back as $response->model. -- karr k132
sub default_model { 'gpt-oss-120b' }


sub api_key_env { 'LANGERTHA_AKI_API_KEY' }

# AKI.IO's /anthropic shim spells the cache read the Anthropic way but counts it
# inside input_tokens: the captures t/data/akianthropic_chat_response.json and
# akiopenai_chat_response.json answer the same request with input_tokens 65 +
# cache_read_input_tokens 64 here and prompt_tokens 65 / cached_tokens 64 on the
# OpenAI face. Without this, Pricing with a cache rate bills the 64 reads twice.
# -- ADR 0031, k265
sub _usage_input_includes_cache { 1 }

# AKI.IO's machine-readable agent config states "default_max_output_tokens":
# 8192, which is below the documented output limit of every listed model. The
# Anthropic dialect requires max_tokens on every request, so this overrides the
# conservative 1024 of Langertha::Role::AnthropicCompatible.
sub default_response_size { 8192 }

# Static list from the model table on
# https://aki.io/docs/compatibility/anthropic-api-compatibility/ — AKI.IO's own
# docs disagree about model discovery (the Anthropic page points at
# /anthropic/v1/models, the agent integration guide says discovery runs through
# the OpenAI-compatible /openai/v1/models), so this engine does not depend on
# either endpoint. Use Langertha::Engine::AKIOpenAI->list_models for a live list.
sub _build_static_models {[
  { id => 'apertus-chat-70b' },
  { id => 'gpt-oss-120b' },
  { id => 'gemma4-26b' },
  { id => 'kimi-k2.7-code-1100b' },
  { id => 'llama3-chat-8b' },
  { id => 'llama3-chat-70b' },
  { id => 'minimax-m2.5-230b' },
  { id => 'mistral4-119b' },
  { id => 'qwen3.6-35b' },
]}

around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  # image_input (k266, ADR 0019): vision is undocumented / unverified on this face, so no claim.
  delete $caps->{image_input};
  return $caps;
};

# Tool-result images (karr k359): the shim takes an image inside a tool_result
# without error but the model does not see it. Live probe 2026-09-30
# (llm-advisor, aki.io/anthropic/v1/messages): qwen3.6-35b read a plain
# user-message image correctly (16x16 red -> 'Red'), but the same kind of image
# inside a tool_result came back as 'White' (16x16 red) and 'Black' (64x64
# green), with ~340 input tokens whatever the image size; gpt-oss-120b answered
# 200 and saw only the text. The k336 placeholder at least says an image was
# there, so it stays even if an image_input row is added for this face later.
sub _tool_result_images_on_wire { 0 }

# Source blocks in a tool_result (karr k364, k366): live probes 2026-09-30
# (llm-advisor, aki.io/anthropic/v1/messages) -- a text document answered
# HTTP 529 {"type":"overloaded_error","message":"Unsupported content type:
# document"} (qwen3.6-35b), and a search_result block {source, title,
# content:[text]} answered 529 "Unsupported content type: search_result"
# (qwen3.6-35b twice, gpt-oss-120b once). Deterministic on AKI, not a retry
# signal: either breaks the tool-loop turn. An MCP text resource therefore goes
# out as a text block, a PDF as the placeholder, a native document or
# search_result as its text. (is_error: true in the same probes was accepted
# and silently ignored -- 200, same answer and input tokens as without it --
# so it is still sent, like on every other shim; k366.)
sub _tool_result_source_blocks_on_wire { 0 }

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::AKIAnthropic - AKI.IO via Anthropic-compatible API

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::AKIAnthropic;

    my $aki = Langertha::Engine::AKIAnthropic->new(
        api_key => $ENV{LANGERTHA_AKI_API_KEY},
        model   => 'gemma4-26b',
    );

    print $aki->simple_chat('Hello from Perl!');

=head1 DESCRIPTION

Provides access to L<AKI.IO|https://aki.io/> via its Anthropic-compatible
endpoint at C<https://aki.io/anthropic> (the shared
L<Langertha::Engine::AnthropicBase> appends the C</v1/messages> path). AKI.IO
is a European AI model hub based in Germany — all inference runs on EU
infrastructure, fully GDPR-compliant.

This is the third face of the same provider: L<Langertha::Engine::AKI> speaks
the native API, L<Langertha::Engine::AKIOpenAI> the OpenAI-compatible one, and
this class the Anthropic Messages dialect. All three authenticate with the same
AKI.IO key (C<LANGERTHA_AKI_API_KEY>); pick whichever wire format your code
already speaks.

The key is sent as a raw C<x-api-key> header (B<no> C<Bearer> prefix). The
C<anthropic-version> header is accepted but not required by AKI.IO; the base
class sends it anyway.

B<Model fallback for unknown IDs (substitute unconfirmed):> AKI.IO's own
documentation states it does B<not> error on unknown model IDs — "Requests to
unknown model names will fall back onto the Minimax M2.5 model." The exact
substitute is version-dependent and Langertha could not re-confirm it live
(2026-09-14 the C</anthropic> shim answered every request, documented models
included, with HTTP 529), so treat the specific fallback model as
B<unconfirmed>. Either way, Claude model names and HuggingFace repository IDs
are B<not> a usable shortcut — an unknown ID is not the model you asked for.
Always pass an exact AKI.IO model ID (C<list_models> returns the documented
set), and check C<< $response->model >> (and watch for errors) if it matters
which model replied.

Models documented for this endpoint: C<apertus-chat-70b>, C<gpt-oss-120b>,
C<gemma4-26b>, C<kimi-k2.7-code-1100b>, C<llama3-chat-8b>, C<llama3-chat-70b>,
C<minimax-m2.5-230b>, C<mistral4-119b>, C<qwen3.6-35b>.

B<Tool calling works but is undocumented on this endpoint.> AKI.IO's Anthropic
compatibility page lists only C<model>, C<messages>, C<max_tokens>,
C<temperature>, C<top_p>, C<top_k>, C<stop_sequences>, C<stream> and C<system>
as request parameters — no C<tools>. It nevertheless accepts the native
Anthropic C<tools> array this class inherits from
L<Langertha::Engine::AnthropicBase> and answers with a C<tool_use> block,
verified live against C<llama3-chat-8b> (2026-08-24, re-verified 2026-09-01;
fixture C<t/data/akianthropic_tool_call_response.json>). One deviation from
real Anthropic: the C<input> of that block arrives as a B<JSON string>, not an
object — L<Langertha::ToolCall> decodes it, so C<< $tc->arguments >> is a
HashRef either way. Since the parameter is undocumented, AKI.IO owes it no
stability; check C<< $response->has_tool_calls >> rather than assuming.

B<Client errors arrive as HTTP 529:> AKI.IO returns some B<caller-side> errors
as C<529> C<overloaded_error> — notably a token budget too small to finish a
tool call (C<"Response finished before tool_call was completed! Try to raise
max_gen_tokens">). That condition is deterministic and fixed by raising
C<response_size> / C<max_tokens>, B<not> transient server overload: do not treat
an AKI C<529> as a wait-and-retry signal, and read
C<< $error->{error}{message} >> for the real diagnostic.

B<Tool results carry text only.> In the tool loop, an image a tool returns
goes out as a text placeholder (C<[image] image/png (N bytes)>) for every
model: the shim accepts an image inside a C<tool_result> but the model does not
see it (live probe 2026-09-30). An embedded text resource goes out as a
C<text> block and a PDF as a placeholder, because the shim answers a
C<document> block there with C<529> C<"Unsupported content type: document">;
a native C<search_result> block (also a C<529>) or C<document> block becomes a
C<text> block with its text, with a warning.

Get your API key at L<https://aki.io/> and set C<LANGERTHA_AKI_API_KEY>.

B<THIS API IS WORK IN PROGRESS>

=head2 api_key

The AKI.IO API key — the same key the native and OpenAI-compatible AKI.IO
engines use. If not provided, reads from the C<LANGERTHA_AKI_API_KEY>
environment variable. Sent as a raw C<x-api-key> HTTP header (no C<Bearer>
prefix). Required.

=head2 default_model

Returns C<gpt-oss-120b>, a current-generation non-MiniMax model AKI.IO rates
"Supported", matching the default of the sibling
L<Langertha::Engine::AKIOpenAI> and replacing C<llama3-chat-8b>, which AKI.IO
marks end-of-life 2026-09-30. AKI.IO exposes MiniMax M3 only on its native
endpoint, not this shim. AKI.IO documents no default of its own for this
endpoint — an unset or unknown model resolves to a fallback AKI does not
guarantee (its docs name Minimax M2.5; the live substitute is unconfirmed —
see L</DESCRIPTION>), so this class always sends an explicit model.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::AKI> - Native AKI.IO API (with top_k, top_p, max_gen_tokens)

=item * L<Langertha::Engine::AKIOpenAI> - AKI.IO via the OpenAI-compatible endpoint

=item * L<Langertha::Engine::AnthropicBase> - Anthropic-compatible base class

=item * L<https://aki.io/docs/compatibility/anthropic-api-compatibility/> - AKI.IO Anthropic API compatibility docs

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
