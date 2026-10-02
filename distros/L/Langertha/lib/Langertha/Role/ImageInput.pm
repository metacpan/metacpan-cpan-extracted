package Langertha::Role::ImageInput;
# ABSTRACT: Role for an engine whose wire can carry image input
our $VERSION = '0.503';
use Moose::Role;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::ImageInput - Role for an engine whose wire can carry image input

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Content::Image;

    if ( $engine->supports('image_input') ) {
        my $img = Langertha::Content::Image->from_url('https://example.com/cat.jpg');
        my $r   = $engine->simple_chat({
            role => 'user', content => [ 'What is in this image?', $img ],
        });
    }

=head1 DESCRIPTION

A capability role (ADR 0016): an engine composes it when its wire can carry
L<Langertha::Content::Image> parts, i.e. its
L<Langertha::Role::Chat/content_format> serializes an image into a shape the
endpoint accepts. Composing it contributes the C<image_input> flag to
L<Langertha::Role::Capabilities/engine_capabilities>.

C<image_input> is B<model-scoped> and means B<the model sees the image>, not
merely that the wire accepts the part (ADR 0019, k266 Update). Most providers
serve text-only and vision models side by side, so an engine that composes
this role refines the flag per model:

=over

=item * all-vision families (OpenAI, first-party Anthropic, Gemini, Hetzner)
keep the flag and clear it for the listed text-only models
(C<model_capability_corrections>);

=item * other cloud engines clear it for every model and re-assert it only for
the documented vision models -- including the C</anthropic> shims of MiniMax
and Moonshot, which carry the same rows as their OpenAI faces;

=item * gateways, self-hosted servers, AKIAnthropic and LMStudioAnthropic clear
it for every model: the model behind them is unknown to the client, or its
vision is unverified on that face, so the engine makes no static claim.

=back

The static answer can be replaced by what the provider says about its own
models: L<Langertha::Role::Capabilities/probe_model_capabilities_f> reads the
metadata endpoint of OpenRouter, Mistral, Ollama, OllamaOpenAI, LMStudio,
LMStudioOpenAI, LMStudioAnthropic, LlamaCpp and TSystems and stores C<image_input> per model on the engine
instance (ADR 0032). Nothing probes implicitly.

The flag is advisory. Nothing blocks or strips an image when it is false; an
image sent to an engine without the claim goes out on the wire as usual and the
provider decides.

One reader chooses a representation by it: in the tool loop,
L<Langertha::Role::Tools/format_tool_results> sends an image a I<tool>
returned as an image part on the C<responses>, Gemini 3 and C<anthropic> wires
only when the flag is true, and as a text placeholder otherwise (see
L<Langertha::ToolResult/DESCRIPTION>). A PDF a tool returned follows the same
flag on OpenAI Responses and Gemini 3, which read PDFs through the model's
vision. So a claim for a model that does not
see images is no longer harmless there: the provider may reject the tool-loop
turn, or (as AKI.IO's C</anthropic> shim does) accept it while the model never
sees the image.

This role has no methods or attributes of its own.

=head1 SEE ALSO

=over

=item * L<Langertha::Content::Image> - Provider-agnostic image input

=item * L<Langertha::Role::Capabilities> - The capability registry

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
