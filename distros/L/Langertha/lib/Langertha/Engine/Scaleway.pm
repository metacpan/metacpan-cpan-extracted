package Langertha::Engine::Scaleway;
# ABSTRACT: Scaleway Generative APIs
our $VERSION = '0.500';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Embedding', 'Langertha::Role::Tools';


has '+url' => (
  lazy => 1,
  default => sub { 'https://api.scaleway.ai/v1' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_SCALEWAY_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_SCALEWAY_API_KEY or api_key set";
}

sub default_model { 'llama-3.1-8b-instruct' }

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

Langertha::Engine::Scaleway - Scaleway Generative APIs

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    use Langertha::Engine::Scaleway;

    my $scw = Langertha::Engine::Scaleway->new(
        api_key => $ENV{LANGERTHA_SCALEWAY_API_KEY},
        model   => 'llama-3.1-8b-instruct',
    );

    print $scw->simple_chat('Hello from Scaleway!');

=head1 DESCRIPTION

Provides access to B<Scaleway Generative APIs>, a serverless inference service
hosted in European data centers. Composes L<Langertha::Role::OpenAICompatible>
with Scaleway's endpoint (C<https://api.scaleway.ai/v1>) and Bearer auth.

Scaleway is designed as a drop-in replacement for the OpenAI API and is
EU-act compliant. Available chat models include C<llama-3.1-8b-instruct>
(default), C<llama-3.3-70b-instruct>, C<mistral-small-3.1-24b-instruct-2503>,
C<gemma-3-27b-it> and others. Function calling, structured output and
embeddings are supported.

If you want to scope requests to a specific Scaleway project, override C<url>
with C<https://api.scaleway.ai/E<lt>PROJECT_IDE<gt>/v1>.

Generate an API secret key in the Scaleway console
(L<https://console.scaleway.com/>) and set C<LANGERTHA_SCALEWAY_API_KEY>.

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<https://www.scaleway.com/en/docs/generative-apis/> - Scaleway Generative APIs documentation

=item * L<https://www.scaleway.com/en/generative-apis/> - Scaleway Generative APIs product page

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
