package Langertha::Engine::Moonshot;
# ABSTRACT: Moonshot AI Kimi API (OpenAI-compatible)
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
  default => sub { 'https://api.moonshot.ai/v1' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_MOONSHOT_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_MOONSHOT_API_KEY or api_key set";
}

sub default_model { 'kimi-k3' }

# Kimi vision takes base64 data URLs (or ms:// file ids), no remote image URLs
# (platform.kimi.ai/docs/guide/use-kimi-vision-model), karr k267.
sub _content_inline_images_only { 1 }

sub default_response_size { 4096 }

# Kimi counts reasoning_content against max_tokens and recommends
# max_tokens >= 16000 while thinking is on (karr k225; platform.kimi.ai, advisor
# 2026-09-25 on k219, docs only). kimi-k3 and kimi-k2.7-code(-highspeed) always
# think, kimi-k2.6 thinks by default, so they default to 16000 instead of 4096.
# Only when no response_size is set; max_tokens is a ceiling, billing follows
# the tokens produced (ADR 0019 k225 Update).
sub model_response_size_defaults {
  return (
    qr/\Akimi-k3(?!\d)/                          => 16000,
    qr/\Akimi-k2\.(?:6|7-code(?:-highspeed)?)\z/ => 16000,
  );
}

sub _build_static_models {[
  { id => 'kimi-k3' },
  { id => 'kimi-k2.7-code' },
  { id => 'kimi-k2.7-code-highspeed' },
  { id => 'kimi-k2.6' },
]}

# Per-model tool_choice reality on Kimi's OpenAI-compatible endpoint
# (ADR 0002 amendment, ADR 0019; platform.kimi.ai/docs/guide/use-tool-choice):
#   * kimi-k3 (the engine default) always thinks, and forcing a *specific*
#     tool is incompatible with thinking -> a named tool_choice returns 400.
#     Clear tool_choice_named there (auto/any/none stay).
#   * The K2.x line does not support `required` and errors if it is passed.
#     Canonical `any` serializes to wire `required` (Langertha::ToolChoice),
#     so clear tool_choice_any there (auto/none/named stay).
#   * Reasoning is per model too (karr k207, platform.kimi.ai models overview,
#     advisor 2026-09-25, docs only): kimi-k3 takes a top-level
#     reasoning_effort (low|high|max, server default max; the accepted set
#     lives in its Reasoning::Profile row), while the K2.x line takes only the
#     Kimi `thinking` object. Clear reasoning_effort there (dotted and
#     dash-form K2 ids alike, e.g. kimi-k2-thinking), and
#     Role::ReasoningEffort then sends no reasoning field (the k204 gate).
#     kimi-k2.6 alone is re-asserted (karr k219, exact id): it takes a
#     top-level thinking {type: enabled|disabled} (KimiK26ChatRequest schema,
#     kimi-k2-6-quickstart; advisor 2026-09-25, docs only, not live), which
#     the opted-in toggle (_reasoning_thinking_toggle below) serializes from
#     reasoning_effort. kimi-k2.7-code(-highspeed) stays cleared: `disabled`
#     is an error there and the guides say not to pass thinking at all, so
#     there is nothing to send.
#   * Temperature is fixed server-side on every current Kimi id (karr k214,
#     platform.kimi.ai models overview, advisor 2026-09-25, docs + third-party
#     400 reports, not live): kimi-k3 and kimi-k2.7-code(-highspeed) take only
#     1.0, kimi-k2.6 1.0 with thinking and only 0.6 without, anything else is a
#     400. Not effort-dependent, and 1 is not safe either (k2.6 non-thinking),
#     so the flag is cleared and the field never goes out (ADR 0025 k214 Update).
#   * image_input (k266, llm-advisor, docs only, 2026-09-25): the vision models
#     kimi-k3, kimi-k2.6 and kimi-k2.7-code take image input (platform.kimi.ai
#     use-kimi-vision-model; base64 only, Role::Chat inlines URL images here,
#     k267); other ids are unchecked, so the catch-all first row clears the flag.
# The rows are deliberately distinct per model — that is the discriminating
# information the flat role-derived row could not carry.
sub model_capability_corrections {
  return (
    qr/\A/          => { image_input => 0 },
    'kimi-k3'       => { tool_choice_named => 0 },
    qr/\Akimi-k3(?!\d)/ => { temperature => 0 },
    qr/\Akimi-k2(?!\d)/ => { tool_choice_any => 0, reasoning_effort => 0, temperature => 0 },
    'kimi-k2.6'     => { reasoning_effort => 1 },
    qr/\Akimi-k(?:3|2\.6|2\.7-code)(?!\d)/ => { image_input => 1 },
  );
}

# Kimi's chat/completions schema (platform.kimi.ai/docs/api/chat) has no
# parallel_tool_calls field; only its separate Responses API lists one. Clear
# parallel_tool_use engine-wide so it is dropped with a carp rather than sent
# unhonored (karr k242, docs only).
around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  delete $caps->{parallel_tool_use};
  return $caps;
};

# Kimi's chat/completions speaks the K2.x `thinking` on/off toggle as a
# top-level object (karr k219; ADR 0023 k209 Update: the toggle is an
# endpoint's opt-in). Only kimi-k2.6 reaches it: its Profile row maps none ->
# {type: disabled}, any other level -> {type: enabled}, and never sends `keep`.
# kimi-k3 has no toggle row and keeps its reasoning_effort (k207).
sub _reasoning_thinking_toggle { 1 }

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Moonshot - Moonshot AI Kimi API (OpenAI-compatible)

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::Moonshot;

    my $moonshot = Langertha::Engine::Moonshot->new(
        api_key => $ENV{MOONSHOT_API_KEY},
        model   => 'kimi-k3',
    );

    print $moonshot->simple_chat('Hello from Perl!');

    # Streaming
    $moonshot->simple_chat_stream(sub {
        print shift->content;
    }, 'Write a poem');

    # Tool calling
    my $response = await $moonshot->chat_with_tools_f('Search for Perl modules');

=head1 DESCRIPTION

Provides access to L<Moonshot AI|https://www.moonshot.ai/>'s Kimi models via
their native OpenAI-compatible endpoint at C<https://api.moonshot.ai/v1>.

Moonshot AI is a Beijing-based AI company; their Kimi models are natively
multimodal (text, image, and video input) with strong coding, reasoning, and
agentic capabilities. C<kimi-k3> offers a 1M-token context window; the K2.x
legacy models below remain at 256K.

B<Why the OpenAI endpoint:> Moonshot also exposes an Anthropic-compatible
C</anthropic> endpoint; if you need the Anthropic wire format, use
L<Langertha::Engine::MoonshotAnthropic>. The native OpenAI-compatible endpoint
is the recommended default.

B<Available models:>

=over 4

=item * C<kimi-k3> — Current flagship (default). Kimi's most capable model:
2.8 trillion parameters, native visual understanding, 1M context, frontier
reasoning and agentic tasks.

=item * C<kimi-k2.7-code> — Dedicated coding model: more reliable
instruction following in long contexts and higher coding task success. 256K
context.

=item * C<kimi-k2.7-code-highspeed> — High-speed variant of C<kimi-k2.7-code>
(~180 tokens/s, up to ~260 tokens/s in short-context scenarios).

=item * C<kimi-k2.6> — Previous multimodal model: thinking and non-thinking
modes, dialogue and Agent tasks. 256K context.

=back

B<Sunset:> C<kimi-k2.5> and the C<moonshot-v1-*> generation series are no
longer available to newly registered users and reach full platform sunset on
2026-08-31; they are deliberately no longer listed here. The older C<kimi-k2>
preview series was discontinued on 2026-05-25.

See L<https://platform.kimi.ai/docs/models> for the full model catalog.

B<Reasoning note:> reasoning control differs per model family on this
endpoint. The K2.x line uses a Kimi-specific top-level C<thinking> object
(C<{ type =E<gt> 'enabled' }> / C<{ type =E<gt> 'disabled' }>), not the
OpenAI-wire C<reasoning_effort> field. On C<kimi-k2.6> this engine serializes
C<reasoning_effort> onto that toggle: C<none> sends
C<< thinking =E<gt> { type =E<gt> 'disabled' } >>, any other level
C<< thinking =E<gt> { type =E<gt> 'enabled' } >> (every level gives the same
depth), and no C<reasoning_effort> field goes out. C<kimi-k2.7-code> and
C<kimi-k2.7-code-highspeed> always think and must not be sent a C<thinking>
field, so the engine does not advertise C<reasoning_effort> there and sends
nothing. This K2.x wire is taken from Moonshot's documentation and is not
verified against the live API. C<kimi-k3> instead accepts a top-level
C<reasoning_effort> of C<low> / C<high> / C<max> and defaults to C<max>
server-side when the field is omitted; it always reasons. On C<kimi-k3> the
engine sends C<reasoning_effort> when it is one of those three values and drops
any other level, so the server default applies.

B<Temperature:> every current Kimi model fixes C<temperature> server-side and
rejects other values, so this engine never sends one; a C<temperature> other
than C<1> is dropped with a warning.

B<Response size:> Kimi counts reasoning toward C<max_tokens> and recommends at
least 16000 while thinking is on, so C<kimi-k3>, C<kimi-k2.7-code>,
C<kimi-k2.7-code-highspeed> and C<kimi-k2.6> default to 16000 (per model, so
C<kimi-k2.6> keeps 16000 even with C<< reasoning_effort => 'none' >>); other ids
keep 4096. An explicit C<response_size> is always sent as given.

Supports chat, streaming, tool calling, and structured output. Embeddings,
transcription, and image generation are not supported via this endpoint.

Get your API key at L<https://platform.kimi.ai/> and set
C<LANGERTHA_MOONSHOT_API_KEY> in your environment.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::MoonshotAnthropic> - Moonshot via Anthropic-compatible endpoint

=item * L<https://platform.kimi.ai/docs/api/overview> - Kimi OpenAI-compatible API docs

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
