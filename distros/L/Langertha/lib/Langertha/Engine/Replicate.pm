package Langertha::Engine::Replicate;
# ABSTRACT: Replicate API
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Tools';


has '+url' => (
  lazy => 1,
  default => sub { 'https://api.replicate.com/v1' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_REPLICATE_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_REPLICATE_API_KEY or api_key set";
}

sub default_model { croak "".(ref $_[0])." requires model to be set" }

sub _build_supported_operations {[qw(
  createChatCompletion
)]}

# Replicate's OpenAPI (api.replicate.com/openapi.json) has no chat/completions
# path, so nothing documents parallel_tool_calls: clear parallel_tool_use
# (karr k242, docs only; the endpoint question itself is karr k243).
around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  delete $caps->{parallel_tool_use};
  # image_input (k266, ADR 0019): a gateway: the model behind it is unknown to the client, so no claim.
  delete $caps->{image_input};
  return $caps;
};

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Replicate - Replicate API

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::Replicate;

    my $replicate = Langertha::Engine::Replicate->new(
        api_key => $ENV{REPLICATE_API_TOKEN},
        model   => 'meta/llama-4-maverick',
    );

    print $replicate->simple_chat('Hello from Perl!');

    # Streaming
    $replicate->simple_chat_stream(sub {
        print shift->content;
    }, 'Write a Perl haiku');

=head1 DESCRIPTION

Replicate hosts thousands of open-source models with pay-per-use pricing.
This engine speaks the OpenAI C</chat/completions> wire format and, by
default, POSTs to C<https://api.replicate.com/v1/chat/completions>.

B<Unverified against the hosted API.> Replicate's official OpenAPI document
(C<https://api.replicate.com/openapi.json>, checked 2026-09-25) lists no
C</chat/completions> path, only C</predictions>, C</models/{owner}/{name}/predictions>,
C</deployments/...> and similar, and its documentation index
(C<https://replicate.com/docs/llms.txt>) has no OpenAI-compatibility page. The
OpenAI-compatible examples on Replicate model pages are for a Cog container run
locally. The project has no Replicate key, so whether the hosted endpoint
answers has never been tested. To talk to a locally run Cog container or an
OpenAI-compatible proxy in front of Replicate, set C<url> to that server's
base URL (for example C<http://localhost:5000/v1>).

Model names use C<owner/model> format (e.g., C<meta/llama-4-maverick>,
C<meta/llama-4-scout>). No default model is set; C<model> must be specified
explicitly.

Chat, streaming, and MCP tool calling use the OpenAI wire format as above.
Embeddings and transcription are not supported through this interface.

Get your API token at L<https://replicate.com/account/api-tokens> and set
C<LANGERTHA_REPLICATE_API_KEY> in your environment.

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<https://www.replicatestatus.com/> - Replicate service status

=item * L<https://replicate.com/explore> - Browse available models

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
