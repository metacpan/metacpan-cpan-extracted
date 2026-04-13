package Langertha::Role::Transcription;
# ABSTRACT: Role for APIs with transcription functionality
our $VERSION = '0.401';
use Moose::Role;
use Carp qw( croak );

requires qw(
  transcription_request
  transcription_response
);

has transcription_model => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);
sub _build_transcription_model {
  my ( $self ) = @_;
  croak "".(ref $self)." can't handle models!" unless $self->does('Langertha::Role::Models');
  return $self->default_transcription_model if $self->can('default_transcription_model');
  return $self->model;
}


sub transcription {
  my ( $self, $file_or_content, %extra ) = @_;
  return $self->transcription_request($file_or_content, %extra);
}


sub simple_transcription {
  my ( $self, $file_or_content, %extra ) = @_;
  my $request = $self->transcription($file_or_content, %extra);
  my $response = $self->user_agent->request($request);
  return $request->response_call->($response);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Transcription - Role for APIs with transcription functionality

=head1 VERSION

version 0.401

=head2 transcription_model

The model name to use for transcription requests. Lazily defaults to
C<default_transcription_model> if the engine provides it, otherwise falls back
to the general C<model> attribute from L<Langertha::Role::Models>.

=head2 transcription

    my $request = $engine->transcription($file_or_content, %extra);

Builds and returns a transcription HTTP request object for the given audio
file path or content. Use L</simple_transcription> to execute the request
and get the transcript directly.

=head2 simple_transcription

    my $text = $engine->simple_transcription($file_or_content, %extra);
    my $text = $engine->simple_transcription('/path/to/audio.mp3');
    my $text = $engine->simple_transcription($audio_bytes, language => 'en');

Sends a transcription request for the audio file or content and returns the
transcript text. Blocks until the request completes. Additional options such as
C<language> can be passed as C<%extra> key/value pairs.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::HTTP> - HTTP transport layer

=item * L<Langertha::Role::Models> - Model selection (provides C<transcription_model>)

=item * L<Langertha::Engine::Whisper> - Whisper-compatible transcription server

=item * L<Langertha::Engine::Groq> - Groq's hosted Whisper transcription

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

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
