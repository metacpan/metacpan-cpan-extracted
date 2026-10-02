package Langertha::Engine::MoonshotAnthropic;
# ABSTRACT: Moonshot AI Kimi API via Anthropic-compatible endpoint
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::AnthropicBase';

with 'Langertha::Role::StaticModels';


# AnthropicBase->chat_request appends '/v1/messages' to url; the default must
# therefore stop at '/anthropic' so the composed endpoint is a single
# '/anthropic/v1/messages' (a '/anthropic/v1' default would double-stack to
# '/anthropic/v1/v1/messages' -> HTTP 404).
has '+url' => (
  lazy => 1,
  default => sub { 'https://api.moonshot.ai/anthropic' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_MOONSHOT_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_MOONSHOT_API_KEY or api_key set";
}

sub default_model { 'kimi-k3' }

sub api_key_env { 'LANGERTHA_MOONSHOT_API_KEY' }

sub default_response_size { 4096 }

# Kimi counts reasoning_content against max_tokens and recommends
# max_tokens >= 16000 while thinking is on (karr k225; platform.kimi.ai, advisor
# 2026-09-25 on k219, docs only). kimi-k3 and kimi-k2.7-code(-highspeed) always
# think, kimi-k2.6 thinks by default, so they default to 16000 instead of 4096.
# Only when no response_size is set; max_tokens is a ceiling, billing follows
# the tokens produced (ADR 0019 k225 Update). Same rows as
# Engine::Moonshot: the same models think on this face (k215).
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

# Temperature is fixed server-side on every current Kimi id (karr k214; see
# Engine::Moonshot for the sources). Kimi's Messages-API schema has no
# temperature property at all, and whether /anthropic 400s on one or ignores it
# is undocumented; the value is fixed either way, so omitting it is always safe
# (ADR 0025 k214 Update). Same rows as the OpenAI face.
#
# Reasoning on K2.x (karr k215, docs/api/messages.md + the Claude Code guide,
# advisor 2026-09-25, docs only): output_config.effort is K3-only, so the K2
# line takes no effort -- the flag is cleared for every K2 id. The two
# documented ids opt back in, because this face parses a thinking toggle for
# them (kimi-k2.6 enabled|disabled, kimi-k2.7-code enabled only); their
# Reasoning::Profile rows send it instead of an effort (ADR 0023 k215 Update).
#
# image_input (k266, k359, ADR 0019): the same rows as Engine::Moonshot -- this
# face serves the same Kimi models, and its Messages schema carries image
# blocks (docs/api/messages.md: tool_result content is "a string or an array
# of text / image blocks"; llm-advisor 2026-09-30, docs only). The catch-all
# first row clears the flag for unchecked ids. Until k359 the flag was deleted
# engine-wide here; it now also picks the tool-result image form, and an
# engine-wide no-claim would have kept kimi-k3 from seeing a tool's image.
sub model_capability_corrections {
  return (
    qr/\A/              => { image_input => 0 },
    qr/\Akimi-k3(?!\d)/ => { temperature => 0 },
    qr/\Akimi-k2(?!\d)/ => { temperature => 0, reasoning_effort => 0 },
    qr/\Akimi-k2\.(?:6|7-code(?:-highspeed)?)\z/ => { reasoning_effort => 1 },
    qr/\Akimi-k(?:3|2\.6|2\.7-code)(?!\d)/ => { image_input => 1 },
  );
}

# Source blocks in a tool_result (karr k364, k366): Kimi's Messages OpenAPI
# schema (platform.kimi.ai/docs/api/messages.md, llm-advisor 2026-09-30, docs
# only, not live) lists tool_result content as string | [text | image] -- no
# document, no search_result -- and Kimi checks block types strictly (a 400
# "Input tag 'document' found using 'type' does not match any of the expected
# tags" is reported in github.com/MoonshotAI/Kimi-K2.5/issues/27). A text
# resource goes out as a text block, a PDF as the placeholder, a native
# document or search_result as its text, rather than a rejected tool-loop turn.
sub _tool_result_source_blocks_on_wire { 0 }

# Kimi's Messages API documents native output_config.format {type: json_schema,
# schema} for kimi-k3 (docs/api/messages.md, advisor 2026-09-25, docs only;
# karr k218), so K3 takes the first-party native path (ADR 0005 k218 Update)
# instead of the shim's synthetic tool + forced named tool_choice. K2.x is
# undocumented on this face and keeps the synthetic tool. Per model, so the
# endpoint predicate _native_structured_output stays 0: this is still a shim,
# and its manifest dialect stays anthropic-compat.
sub _native_structured_output_for_model {
  my ( $self ) = @_;
  return ( $self->chat_model // '' ) =~ /\Akimi-k3(?!\d)/ ? 1 : 0;
}

# This endpoint speaks the `thinking` on/off toggle (ADR 0023 k209 Update): the
# thinking-toggle Reasoning::Profile rows serialize as the toggle only on an
# engine that opts in here; the same model id elsewhere keeps its effort wire.
sub _reasoning_thinking_toggle { 1 }

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::MoonshotAnthropic - Moonshot AI Kimi API via Anthropic-compatible endpoint

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::MoonshotAnthropic;

    my $moonshot = Langertha::Engine::MoonshotAnthropic->new(
        api_key => $ENV{MOONSHOT_API_KEY},
        model   => 'kimi-k3',
    );

    print $moonshot->simple_chat('Hello from Perl!');

=head1 DESCRIPTION

Provides access to L<Moonshot AI|https://www.moonshot.ai/>'s Kimi models via
their Anthropic-compatible endpoint at C<https://api.moonshot.ai/anthropic>
(the shared L<Langertha::Engine::AnthropicBase> appends the C</v1/messages>
path). This is the endpoint Moonshot documents for Claude Code / Anthropic-SDK
clients.

For new code prefer L<Langertha::Engine::Moonshot>, which talks to Moonshot's
native OpenAI-compatible endpoint. This class is retained for callers that need
the Anthropic wire format specifically.

See L<Langertha::Engine::Moonshot> for the available models list.

On C<kimi-k3>, C<reasoning_effort> goes out as C<output_config.effort> when it
is C<low>, C<high> or C<max>; any other level is dropped and the server default
(C<max>) applies. K3 always reasons and Kimi's Messages API has no C<thinking>
request field for it, so none is sent (C<thinking_display> has no effect on
K3).

On the K2.x line Kimi takes no effort here, only a C<thinking> toggle, so
C<reasoning_effort> becomes C<< thinking =E<gt> { type =E<gt> 'enabled' } >>
for any level; C<none> sends C<< { type =E<gt> 'disabled' } >> on
C<kimi-k2.6> and nothing on C<kimi-k2.7-code>, which cannot turn thinking off.
Every level gives the same depth. A C<thinking_display> adds C<display> to an
on toggle. Not verified against the live API: whether Kimi requires
C<budget_tokens> with C<enabled> (none is sent), whether it accepts
C<display> there, and whether C<kimi-k2.7-code> accepts a request with no
C<thinking> field. Other K2 ids take no reasoning control on this endpoint.

On C<kimi-k3> a C<json_schema> C<response_format> goes out natively as
C<output_config.format> (with the schema closed, as on first-party Anthropic),
so it also streams; a C<json_object>, and every C<response_format> on the K2.x
models, still use the synthesized-tool rewrite of the C</anthropic> shims.

C<max_tokens> defaults to 16000 on the thinking Kimi models, as on
L<Langertha::Engine::Moonshot>; an explicit C<response_size> is sent as given.

Kimi fixes C<temperature> server-side on every current model, so none is sent;
a C<temperature> other than C<1> is dropped with a warning.

C<image_input> is claimed for the same vision models as on
L<Langertha::Engine::Moonshot> (C<kimi-k3>, C<kimi-k2.6>, C<kimi-k2.7-code>),
so an image a tool returns reaches them as an C<image> block in the
C<tool_result>. Kimi's schema takes no C<document> or C<search_result> there,
so an embedded text resource goes out as a C<text> block, a PDF as a text
placeholder, and a native C<document> / C<search_result> block as its text
(with a warning).

Get your API key at L<https://platform.kimi.ai/> and set
C<LANGERTHA_MOONSHOT_API_KEY> in your environment.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::Moonshot> - Recommended Moonshot engine (OpenAI-compatible endpoint)

=item * L<https://platform.kimi.ai/docs/api/overview> - Kimi API docs

=item * L<Langertha::Engine::AnthropicBase> - Anthropic-compatible base class

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
