package Langertha::Engine::LMStudioAnthropic;
# ABSTRACT: LM Studio via Anthropic-compatible API
our $VERSION = '0.503';
use Moose;

extends 'Langertha::Engine::AnthropicBase';


has '+url' => (
  lazy => 1,
  default => sub { 'http://localhost:1234' },
);

sub _build_api_key {
  return $ENV{LANGERTHA_LMSTUDIO_API_KEY} || 'lmstudio';
}


sub default_model { 'default' }

# Shares the LM Studio key with the native engine (derivation would name the
# protocol variant); optional, the local server accepts the 'lmstudio' dummy.
sub api_key_env { 'LANGERTHA_LMSTUDIO_API_KEY' }
sub api_key_required { 0 }

# image_input (k266, ADR 0019): self-hosted: the served model is launch state
# the client cannot see, so no static claim. A layer-3 catch-all rather than a
# layer-2 delete, so a fact probed from the server's native /api/v1/models
# (capabilities.vision) can answer per model (ADR 0032), as on the other two
# LM Studio faces.
sub model_capability_corrections {
  return ( qr/\A/ => { image_input => 0 } );
}

# Source blocks in a tool_result (karr k372, ADR 0001 k372 Update): off,
# conservatively, like MoonshotAnthropic. NOT live-verified (no LM Studio
# server available); the evidence is indirect: the anthropic-compat docs
# (lmstudio.ai/docs/developer/anthropic-compat) only point to Anthropic's own,
# the changelog names only "Images in tool call results" for /v1/messages, and
# lmstudio-bug-tracker#1792 (LM Studio 0.4.11, Apr 2026) reports the API
# rejecting PDFs with a 400 even for vision models and offering no document
# type. A text resource (the common MCP case) goes out as a text block, a PDF
# as the k336 placeholder, a native document / search_result as its text.
# Wire truth, not image_input: a vision model gets the same treatment.
sub _tool_result_source_blocks_on_wire { 0 }

# url is the server root (the envelope appends /v1/messages); the native
# models list sits beside it.
sub model_metadata_format { 'lmstudio' }
sub model_metadata_url {
  return Langertha::ModelProbe->server_root_url( $_[0]->url ) . '/api/v1/models';
}

# LM Studio documents only "Authorization: Bearer" for its native REST API
# (lmstudio.ai/docs/developer/core/authentication); x-api-key is documented for
# /v1/messages. So the probe request also carries the token as Bearer, the chat
# wire is unchanged.
around update_request => sub {
  my ( $orig, $self, $request ) = @_;
  $self->$orig($request);
  $request->header( 'Authorization', 'Bearer ' . $self->api_key )
    if $request->uri->as_string eq $self->model_metadata_url;
  return;
};

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::LMStudioAnthropic - LM Studio via Anthropic-compatible API

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::LMStudioAnthropic;

    my $lm_anthropic = Langertha::Engine::LMStudioAnthropic->new(
        url   => 'http://localhost:1234',
        model => 'qwen2.5-7b-instruct-1m',
    );

    print $lm_anthropic->simple_chat('Hello from Anthropic-compatible endpoint');

=head1 DESCRIPTION

Adapter for LM Studio's Anthropic-compatible local endpoint
(C<POST /v1/messages> on the LM Studio server URL, default
C<http://localhost:1234>).

LM Studio requires a non-empty C<x-api-key> header for this endpoint, but the
value is not validated against Anthropic. This class defaults to C<lmstudio>
when no API key is configured.

A tool result that carries an embedded text resource or PDF goes out as plain
text (the PDF as a placeholder): LM Studio documents no C<document> or
C<search_result> block inside a C<tool_result>, and its bug tracker reports PDFs
rejected with a 400. This is conservative and not live-verified.

B<THIS API IS WORK IN PROGRESS>

=head2 api_key

API key sent as C<x-api-key> to the Anthropic-compatible endpoint.
LM Studio accepts arbitrary non-empty values. Defaults to C<lmstudio> when
no explicit C<api_key> and no C<LANGERTHA_LMSTUDIO_API_KEY> are set.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::LMStudio> - Native LM Studio API (C</api/v1/chat>)

=item * L<Langertha::Engine::AnthropicBase> - Base Anthropic-compatible engine

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
