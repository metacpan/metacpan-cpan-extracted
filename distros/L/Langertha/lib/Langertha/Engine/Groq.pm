package Langertha::Engine::Groq;
# ABSTRACT: GroqCloud API
our $VERSION = '0.500';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with map { 'Langertha::Role::'.$_ } qw(
  Transcription
  Tools
);


sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_GROQ_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_GROQ_API_KEY or api_key set";
}

has '+url' => (
  lazy => 1,
  default => sub { 'https://api.groq.com/openai/v1' },
);

sub default_model { croak "".(ref $_[0])." requires a default_model" }

sub default_transcription_model { 'whisper-large-v3' }

sub _build_supported_operations {[qw(
  createChatCompletion
  createTranscription
)]}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Groq - GroqCloud API

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    use Langertha::Engine::Groq;

    my $groq = Langertha::Engine::Groq->new(
        api_key      => $ENV{GROQ_API_KEY},
        model        => 'llama-3.3-70b-versatile',
        system_prompt => 'You are a helpful assistant',
    );

    print $groq->simple_chat('Say something nice');

    # Audio transcription
    my $text = $groq->transcription('/path/to/audio.mp3');

=head1 DESCRIPTION

Provides access to Groq's ultra-fast LLM inference via their GroqCloud API.
Composes L<Langertha::Role::OpenAICompatible> with Groq's endpoint
(C<https://api.groq.com/openai/v1>) and API key handling.

Popular models: C<llama-3.3-70b-versatile>, C<llama-3-groq-70b-tool-use>,
C<deepseek-r1-distill-llama-70b>, C<qwen-2.5-coder-32b>. Audio transcription
uses C<whisper-large-v3> by default. No default chat model is set; C<model>
must be specified explicitly.

Dynamic model listing via C<list_models()>. Get your API key at
L<https://console.groq.com/keys> and set C<LANGERTHA_GROQ_API_KEY>.

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<https://groqstatus.com/> - Groq service status

=item * L<https://console.groq.com/docs/models> - Official Groq models documentation

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role

=item * L<Langertha::Role::Transcription> - Transcription role (Groq hosts Whisper)

=item * L<Langertha::Engine::DeepSeek> - Another OpenAI-compatible engine

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
