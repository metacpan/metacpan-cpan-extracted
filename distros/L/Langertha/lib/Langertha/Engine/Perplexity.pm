package Langertha::Engine::Perplexity;
# ABSTRACT: Perplexity Sonar API
our $VERSION = '0.308';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';


sub _build_supported_operations {[qw(
  createChatCompletion
)]}

has '+url' => (
  lazy => 1,
  default => sub { 'https://api.perplexity.ai' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_PERPLEXITY_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_PERPLEXITY_API_KEY or api_key set";
}

sub default_model { 'sonar' }

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Perplexity - Perplexity Sonar API

=head1 VERSION

version 0.308

=head1 SYNOPSIS

    use Langertha::Engine::Perplexity;

    my $perplexity = Langertha::Engine::Perplexity->new(
        api_key => $ENV{PERPLEXITY_API_KEY},
        model   => 'sonar-pro',
    );

    print $perplexity->simple_chat('What are the latest Perl releases?');

    # Streaming
    $perplexity->simple_chat_stream(sub {
        print shift->content;
    }, 'Summarize recent Perl news');

    # Async with Future::AsyncAwait
    use Future::AsyncAwait;
    my $response = await $perplexity->simple_chat_f('What is new in Perl?');

=head1 DESCRIPTION

Provides access to Perplexity's Sonar API. Composes
L<Langertha::Role::OpenAICompatible> with Perplexity's endpoint
(C<https://api.perplexity.ai>). Perplexity models are search-augmented
LLMs with real-time web access; responses include citations alongside
generated text.

Available models: C<sonar> (default, fast), C<sonar-pro> (deeper analysis),
C<sonar-reasoning> (chain-of-thought), C<sonar-reasoning-pro> (most capable).

Limitations: tool calling, embeddings, and transcription are not supported.
Only chat and streaming are available.

Get your API key at L<https://www.perplexity.ai/settings/api> and set
C<LANGERTHA_PERPLEXITY_API_KEY>.

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<https://status.perplexity.com/> - Perplexity service status

=item * L<https://docs.perplexity.ai/> - Official Perplexity API documentation

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role

=item * L<Langertha::Engine::DeepSeek> - Another search-augmented engine (web-aware reasoning)

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
