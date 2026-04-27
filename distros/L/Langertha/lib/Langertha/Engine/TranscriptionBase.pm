package Langertha::Engine::TranscriptionBase;
# ABSTRACT: Base class for OpenAI-compatible transcription-only engines
our $VERSION = '0.500';
use Moose;
use Carp qw( croak );
use Module::Runtime qw( use_module );

extends 'Langertha::Engine::Remote';

with map { 'Langertha::Role::'.$_ } qw(
  OpenAICompatible
  OpenAPI
  Models
  Transcription
  Capabilities
);

sub _build_openapi_operations {
  return use_module('Langertha::Spec::OpenAI')->data;
}

sub _build_supported_operations {[qw(
  createTranscription
  createTranslation
)]}


sub default_model { croak "".(ref $_[0])." requires transcription_model to be set" }

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::TranscriptionBase - Base class for OpenAI-compatible transcription-only engines

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    package My::TranscriptionEngine;
    use Moose;
    extends 'Langertha::Engine::TranscriptionBase';

    has '+url' => ( default => 'https://api.example.com/v1' );

    sub _build_api_key { $ENV{MY_API_KEY} || die "MY_API_KEY required" }
    sub default_model { 'whisper-1' }

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

Slim base class for engines that only do audio transcription via the
OpenAI-shape C</audio/transcriptions> + C</audio/translations>
endpoints. Unlike L<Langertha::Engine::OpenAIBase>, this does not
compose L<Langertha::Role::Chat> / L<Langertha::Role::Tools> /
L<Langertha::Role::Embedding> / L<Langertha::Role::ImageGeneration>
— callers get a focused object with C<simple_transcription> and
nothing else.

L<Langertha::Engine::Whisper> is the canonical concrete subclass for
self-hosted Whisper servers; L<Langertha::Engine::OpenAI> exposes a
C<whisper> attribute that returns a TranscriptionBase configured for
the OpenAI cloud (sharing the parent's C<api_key> and C<url>) so
chat-side code can grab a transcription handle without re-stating the
credentials.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::Whisper> - Self-hosted Whisper-compatible server

=item * L<Langertha::Engine::OpenAI> - Provides a C<whisper> handle reusing its credentials

=item * L<Langertha::Role::Transcription> - The role this base composes

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
