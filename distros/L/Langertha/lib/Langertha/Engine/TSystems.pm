package Langertha::Engine::TSystems;
# ABSTRACT: T-Systems AI Foundation Services (LLM Hub)
our $VERSION = '0.500';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Embedding', 'Langertha::Role::Tools';


has '+url' => (
  lazy => 1,
  default => sub { 'https://llm-server.llmhub.t-systems.net/v2' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_TSYSTEMS_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_TSYSTEMS_API_KEY or api_key set";
}

sub default_model { 'gpt-oss-120b' }

sub default_embedding_model { 'text-embedding-bge-m3' }

sub _build_supported_operations {[qw(
  createChatCompletion
  createEmbedding
)]}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::TSystems - T-Systems AI Foundation Services (LLM Hub)

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    use Langertha::Engine::TSystems;

    my $tsi = Langertha::Engine::TSystems->new(
        api_key => $ENV{LANGERTHA_TSYSTEMS_API_KEY},
        model   => 'gpt-oss-120b',
    );

    print $tsi->simple_chat('Hello from AIFS!');

    my $vector = $tsi->simple_embedding('embed me');

=head1 DESCRIPTION

Provides access to T-Systems' B<AI Foundation Services> (formerly LLM Hub),
an OpenAI-compatible aggregator hosted in Germany / the EU. Composes
L<Langertha::Role::OpenAICompatible> with the AIFS endpoint
(C<https://llm-server.llmhub.t-systems.net/v2>) and Bearer auth.

T-Systems AIFS exposes 30+ open-source and proprietary models behind a single
OpenAI-compatible API. Models hosted on B<T-Cloud> are processed exclusively
in Germany (Llama 3.3, Qwen 3, Mistral Small, Teuken, BGE-M3, Jina embeddings,
Whisper); hyperscaler models (GPT 5/4.1/4o, Claude 4.5 Sonnet, Gemini 2.5/3)
are processed in the EU. GDPR-compliant.

Get a trial API key at L<https://apikey.llmhub.t-systems.net/> and set
C<LANGERTHA_TSYSTEMS_API_KEY> in your environment.

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<https://docs.llmhub.t-systems.net/> - Official AIFS / LLM Hub documentation

=item * L<https://apikey.llmhub.t-systems.net/> - Trial API key request

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role

=item * L<Langertha::Engine::AKIOpenAI> - Another EU/Germany OpenAI-compatible engine

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
