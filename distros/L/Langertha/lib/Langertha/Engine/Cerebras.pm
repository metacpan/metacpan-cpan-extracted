package Langertha::Engine::Cerebras;
# ABSTRACT: Cerebras Inference API
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Tools';


has '+url' => (
  lazy => 1,
  default => sub { 'https://api.cerebras.ai/v1' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_CEREBRAS_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_CEREBRAS_API_KEY or api_key set";
}

sub default_model { 'gpt-oss-120b' }

# Image inputs are base64 data URLs only
# (inference-docs.cerebras.ai/capabilities/image-inputs), karr k267.
sub _content_inline_images_only { 1 }

sub _build_supported_operations {[qw(
  createChatCompletion
)]}

# karr #148: the Cerebras API rejects a request that carries both tools and a
# structured-output response_format of EITHER type (json_object or json_schema)
# with an opaque HTTP 400. Its docs make this per-model, but every model this
# engine currently serves (gpt-oss-120b default, zai-glm-4.7) rejects the
# combination, so an all-models matcher (qr//) expresses the platform-wide
# reality on the model-scoped exclusion seam (Langertha::Role::Chat). There is no
# shared gpt-oss base rule (removed k184); this all-models rule is Cerebras's only
# exclusion and refuses both json_object and json_schema alongside tools. Consulted
# by chat_f and chat_stream_realtime_f.
sub model_capability_exclusions {
  return (
    qr// => \&_exclude_tools_with_any_response_format,
  );
}

sub _exclude_tools_with_any_response_format {
  my ( $self, %request ) = @_;
  my $rf   = $request{response_format};
  my $type = ( ref $rf eq 'HASH' ) ? ( $rf->{type} // '' ) : '';
  return unless $request{has_tools}
    && ( $type eq 'json_object' || $type eq 'json_schema' );
  croak "".(ref $self)." cannot combine tools and response_format in one "
    ."request: the Cerebras API rejects this combination with HTTP 400. Send "
    ."tools or response_format, not both (run the tools first, then a second "
    ."structured-output turn).";
}

# image_input (k266, ADR 0019 k266 Update): only the vision models take image
# input (inference-docs.cerebras.ai/capabilities/image-inputs, public preview,
# base64 PNG/JPEG only -- URL images are inlined by _content_inline_images_only;
# llm-advisor, docs only, 2026-09-25). The catch-all first row clears the flag,
# so the default gpt-oss-120b and unknown ids make no claim.
sub model_capability_corrections {
  return (
    qr/\A/                                          => { image_input => 0 },
    qr/\A(?:qwen-3\.8-27b|gemma-4-31b|kimi-k2\.7-code)/ => { image_input => 1 },
  );
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Cerebras - Cerebras Inference API

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::Cerebras;

    my $cerebras = Langertha::Engine::Cerebras->new(
        api_key => $ENV{CEREBRAS_API_KEY},
        model   => 'gpt-oss-120b',
    );

    print $cerebras->simple_chat('Hello from Perl!');

=head1 DESCRIPTION

Provides access to Cerebras Inference, the fastest AI inference platform.
Composes L<Langertha::Role::OpenAICompatible> with Cerebras's endpoint
(C<https://api.cerebras.ai/v1>) and API key handling.

Cerebras uses custom wafer-scale chips to deliver extremely fast inference
speeds. The public endpoint serves C<gpt-oss-120b> (production, the default)
and C<zai-glm-4.7> (preview).

Supports chat, streaming, and MCP tool calling. Embeddings and transcription
are not supported.

Get your API key at L<https://cloud.cerebras.ai/> and set
C<LANGERTHA_CEREBRAS_API_KEY> in your environment.

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<https://status.cerebras.ai/> - Cerebras service status

=item * L<https://inference-docs.cerebras.ai/> - Cerebras Inference documentation

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role

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
