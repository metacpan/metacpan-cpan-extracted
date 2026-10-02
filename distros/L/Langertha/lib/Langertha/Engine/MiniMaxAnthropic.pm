package Langertha::Engine::MiniMaxAnthropic;
# ABSTRACT: MiniMax API via Anthropic-compatible endpoint (legacy)
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::AnthropicBase';

with 'Langertha::Role::StaticModels';


# AnthropicBase->chat_request appends '/v1/messages' to url; the default must
# therefore stop at '/anthropic' so the composed endpoint is a single
# '/anthropic/v1/messages' (a '/anthropic/v1' default double-stacks to
# '/anthropic/v1/v1/messages' -> HTTP 404 on every model).
has '+url' => (
  lazy => 1,
  default => sub { 'https://api.minimax.io/anthropic' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_MINIMAX_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_MINIMAX_API_KEY or api_key set";
}

sub default_model { 'MiniMax-M3' }

sub api_key_env { 'LANGERTHA_MINIMAX_API_KEY' }

sub default_response_size { 4096 }

sub _build_static_models {[
  { id => 'MiniMax-M3' },
  { id => 'MiniMax-M2.7' },
  { id => 'MiniMax-M2.5' },
  { id => 'MiniMax-M2.5-highspeed' },
  { id => 'MiniMax-M2.1' },
  { id => 'MiniMax-M2.1-highspeed' },
  { id => 'MiniMax-M2' },
]}

# MiniMax's /anthropic CreateMessageReq has a `thinking` object (default
# disabled on M3) but no `output_config` (openapi-chat-anthropic.json, advisor
# 2026-09-25, docs only; karr k209). That holds for every model on this
# endpoint, so the effort is stripped here rather than in a per-model
# Reasoning::Profile row; thinking:{type:adaptive} stays, since it is how an
# effort turns thinking on (ADR 0009 k209 update).
around reasoning_kwargs_for => sub {
  my ( $orig, $self, @args ) = @_;
  my %kwargs = $self->$orig(@args);
  if ( ref $kwargs{output_config} eq 'HASH' ) {
    my %output_config = %{ $kwargs{output_config} };
    delete $output_config{effort};
    if (%output_config) { $kwargs{output_config} = \%output_config }
    else                { delete $kwargs{output_config} }
  }
  return %kwargs;
};

# This endpoint speaks the `thinking` on/off toggle (ADR 0023 k209 Update): the
# thinking-toggle Reasoning::Profile rows serialize as the toggle only on an
# engine that opts in here; the same model id elsewhere keeps its effort wire.
sub _reasoning_thinking_toggle { 1 }

# image_input (k266, ADR 0019 k266 Update): MiniMax-M3 takes image input, the
# M2.x line is text-only (llm-advisor, docs only, 2026-09-25) -- the same rows
# as Engine::MiniMax, the OpenAI face of the same service.
sub model_capability_corrections {
  return (
    qr/\A/                 => { image_input => 0 },
    qr/\AMiniMax-M3(?!\d)/ => { image_input => 1 },
  );
}

# Source blocks in a tool_result (karr k364, k371): deliberately 1, the
# Role::Tools default, stated here so nobody flips it to 0 as "undocumented".
# MiniMax's docs do not know `document` (RequestContentBlock.type enum is
# text | image | video | tool_use | tool_result | thinking | mid_conv_system;
# tool_result.content is "string or array of text/image", docs only), but a
# live probe 2026-09-30 (tool_use -> tool_result[text, document{base64
# application/pdf}], 1-page PDF reading a codeword) got HTTP 200 and the
# correct codeword from both MiniMax-M2.7 (text-only, 244 input tokens: text
# extracted without vision) and MiniMax-M3 (3159 input tokens: page seen as
# well). Gating on image_input would turn working PDF reading on M2.x into the
# placeholder. Only a PDF/base64 document was probed; a text-source document
# and search_result were NOT.
sub _tool_result_source_blocks_on_wire { 1 }

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::MiniMaxAnthropic - MiniMax API via Anthropic-compatible endpoint (legacy)

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::MiniMaxAnthropic;

    my $minimax = Langertha::Engine::MiniMaxAnthropic->new(
        api_key => $ENV{MINIMAX_API_KEY},
        model   => 'MiniMax-M3',
    );

    print $minimax->simple_chat('Hello from Perl!');

=head1 DESCRIPTION

Provides access to L<MiniMax|https://www.minimax.io/> models via their
Anthropic-compatible endpoint at C<https://api.minimax.io/anthropic> (the
shared L<Langertha::Engine::AnthropicBase> appends the C</v1/messages> path).

B<Historical note:> Until version 0.402 this was the default behavior of
L<Langertha::Engine::MiniMax>. MiniMax's C</anthropic> endpoint is a shim
over their native OpenAI-compatible API — it does not always re-parse
stringified tool-call arguments, which causes intermittent tool-calling
failures where the Anthropic SDK sees a wrapper object whose key rotates
between C<result>, C<arguments>, and the tool name. For new code prefer
L<Langertha::Engine::MiniMax>, which talks to MiniMax's native OpenAI
endpoint and avoids the shim. This class is retained for anyone who needs
the Anthropic wire format specifically.

See L<Langertha::Engine::MiniMax> for the available models list.

MiniMax's Anthropic-compatible request schema has no C<output_config>, so a
C<reasoning_effort> is not sent as C<output_config.effort>. It goes out as the
C<thinking> toggle instead: any level sends C<< { type =E<gt> 'adaptive' } >>,
which turns thinking on (the endpoint's default for C<MiniMax-M3> is thinking
off), and C<none> sends C<< { type =E<gt> 'disabled' } >> on C<MiniMax-M3>. The
M2.x models cannot turn thinking off, so C<none> sends nothing there.

Get your API key at L<https://platform.minimax.io/> and set
C<LANGERTHA_MINIMAX_API_KEY> in your environment.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::MiniMax> - Recommended MiniMax engine (OpenAI-compatible endpoint)

=item * L<https://platform.minimax.io/docs/api-reference/text-anthropic-api> - MiniMax Anthropic API docs

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
