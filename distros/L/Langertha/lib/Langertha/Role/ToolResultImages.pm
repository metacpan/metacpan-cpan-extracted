package Langertha::Role::ToolResultImages;
# ABSTRACT: Role for an engine whose tool results carry images the model sees
our $VERSION = '0.504';
use Moose::Role;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::ToolResultImages - Role for an engine whose tool results carry images the model sees

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Which representation a tool's image gets in the tool loop:
    if ( $engine->supports('tool_result_images') ) {
        # the image reaches the model as an image part
    }
    else {
        # it becomes a text placeholder: "[image] image/png (12345 bytes)"
    }

    # Composed by an engine whose tool-result wire form takes an image:
    package My::Engine;
    use Moose;
    extends 'Langertha::Engine::AnthropicBase';
    with 'Langertha::Role::ToolResultImages';

=head1 DESCRIPTION

Composing this role gives the engine the C<tool_result_images> capability: an
image a tool returns (an MCP C<image> block, or an embedded resource whose
blob is an image) reaches the selected model as an image it sees, in the
tool-result form of this engine's C<tool_wire_format>
(L<Langertha::ToolResult>'s C<image_input> option). Without the flag the image
goes out as the text placeholder that names its type, MIME type and size.
L<Langertha::Role::Tools/format_tool_results> reads the flag and nothing else.

Like C<image_input>, the flag is B<model-scoped>. The composed role says the
engine's endpoint documents an image inside a tool result;
L<Langertha::Role::Capabilities/engine_capabilities> then keeps the flag only
while

=over

=item * the selected model claims C<image_input> -- a probed or imported
C<image_input> fact (ADR 0032) counts, and

=item * the engine's current C<tool_wire_format> has a native tool-result image
form at all (L<Langertha::ToolResult/carries_native>: C<anthropic>,
C<responses>, C<gemini>), so an engine forced onto another wire loses it.

=back

Engines refine it per model or per endpoint like any other flag (Gemini grants
it to Gemini 3 and later only; AKI.IO's C</anthropic> shim clears it, because
its models do not see an image inside a C<tool_result>).

The tool loop sends what an MCP server returned, not what the caller chose, so
a false claim is not harmless: the provider may reject the turn, or accept it
while the model never sees the image. Engines claim it only where the
provider's documentation (or a live probe) shows the form works (ADR 0039).

The role has no attributes or methods.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::Capabilities> - The C<tool_result_images> flag

=item * L<Langertha::Role::ToolResultPDF> - The same for a PDF

=item * L<Langertha::Role::ImageInput> - The C<image_input> flag it depends on

=item * L<Langertha::ToolResult> - The per-wire tool-result forms

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
