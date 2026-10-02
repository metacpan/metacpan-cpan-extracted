package Langertha::Engine::OpenRouter;
# ABSTRACT: OpenRouter API
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );
use Scalar::Util qw( looks_like_number );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Tools';


has '+url' => (
  lazy => 1,
  default => sub { 'https://openrouter.ai/api/v1' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_OPENROUTER_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_OPENROUTER_API_KEY or api_key set";
}

sub default_model { croak "".(ref $_[0])." requires model to be set" }

sub _build_supported_operations {[qw(
  createChatCompletion
)]}

# image_input (k266, ADR 0019): a gateway: the model behind it is unknown to
# the client, so no static claim. The catch-all is a layer-3 row, not a
# layer-2 delete, so a fact probed from /models (architecture.input_modalities)
# can answer per model (ADR 0032).
sub model_capability_corrections {
  return ( qr/\A/ => { image_input => 0 } );
}

# usage.cost is what OpenRouter charged, in its credits, and "OpenRouter uses a
# credit system where the base currency is US dollars" (openrouter.ai/docs/faq,
# read 2026-09-30). The wire number names no unit and "cost" is too generic to
# read as USD from every OpenAI-compatible server, so this engine states it:
# the copy of the usage block gets the canonical cost_usd key that
# Langertha::Usage reads (ADR 0018 tier 3, ADR 0031, k363).
# cost_details.upstream_inference_cost (BYOK: what the key's own provider
# charged) is not OpenRouter's bill and is not folded in.
sub _wire_usage {
  my ( $self, $usage ) = @_;
  return $usage unless ref $usage eq 'HASH';
  my $cost = $usage->{cost};
  return $usage unless defined $cost && !ref $cost && looks_like_number($cost);
  return { %$usage, cost_usd => 0 + $cost };
}

sub model_metadata_format { 'openrouter' }
sub model_metadata_url    { $_[0]->url . $_[0]->list_models_path }

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::OpenRouter - OpenRouter API

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::OpenRouter;

    my $router = Langertha::Engine::OpenRouter->new(
        api_key => $ENV{OPENROUTER_API_KEY},
        model   => 'anthropic/claude-sonnet-4-6',
    );

    print $router->simple_chat('Hello from Perl!');

    # Access many providers through one API
    my $deepseek = Langertha::Engine::OpenRouter->new(
        api_key => $ENV{OPENROUTER_API_KEY},
        model   => 'deepseek/deepseek-r1',
    );

=head1 DESCRIPTION

Provides access to OpenRouter, a unified API gateway for 300+ models from
many providers (OpenAI, Anthropic, Google, Meta, Mistral, and more).
Composes L<Langertha::Role::OpenAICompatible> with OpenRouter's endpoint
(C<https://openrouter.ai/api/v1>).

Model names use C<provider/model> format (e.g., C<anthropic/claude-sonnet-4-6>,
C<openai/gpt-4o>, C<google/gemini-2.5-flash>). No default model is set;
C<model> must be specified explicitly.

Supports chat, streaming, and MCP tool calling. Embeddings and transcription
are not supported.

What OpenRouter charged for a request (C<usage.cost>, in its credits, which
are US dollars) is read as L<Langertha::Usage/cost_usd>, on responses and on
the stream's usage frame.

Get your API key at L<https://openrouter.ai/settings/keys> and set
C<LANGERTHA_OPENROUTER_API_KEY> in your environment.

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<https://status.openrouter.ai/> - OpenRouter service status

=item * L<https://openrouter.ai/docs> - OpenRouter documentation

=item * L<https://openrouter.ai/models> - Browse available models

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
