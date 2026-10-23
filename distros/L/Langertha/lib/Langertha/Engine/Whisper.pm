package Langertha::Engine::Whisper;
# ABSTRACT: Whisper compatible transcription server
our $VERSION = '0.504';
use Moose;

extends 'Langertha::Engine::TranscriptionBase';


sub default_transcription_model { '' }

sub default_model { '' }

sub api_key_env { undef }

has '+url' => (
  required => 1,
);

sub _build_api_key { 'whisper' }

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Whisper - Whisper compatible transcription server

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    use Langertha::Engine::Whisper;

    my $whisper = Langertha::Engine::Whisper->new(
        url                 => 'http://localhost:8000/v1',
        api_key             => $ENV{WHISPER_API_KEY},   # if the server checks one
        transcription_model => 'Systran/faster-whisper-small',
    );

    print $whisper->simple_transcription('recording.ogg');

=head1 DESCRIPTION

Provides access to a self-hosted Whisper-compatible transcription server.
Extends L<Langertha::Engine::TranscriptionBase> and transcribes through the
server's C</audio/transcriptions> endpoint.

C<url> is required. The API key defaults to C<'whisper'> and is sent as
C<Authorization: Bearer ...>. The transcription model defaults to an empty
string, and then no C<model> field is sent, for servers that pick their own
default.

L<speaches|https://github.com/speaches-ai/speaches> (formerly
faster-whisper-server) is a compatible server. Its answers differ from
OpenAI's in these points (seen on speaches 0.8.3, 2026-10):

=over

=item * C<model> is required: without C<transcription_model> the request
fails with C<422> and C<"loc":["body","model"],"msg":"Field required">. Name a
model the server has installed; C<GET /v1/models> lists them (Hugging Face
IDs such as C<Systran/faster-whisper-small>), an unknown one answers C<404>.

=item * A server started with C<API_KEY> checks the bearer token; a wrong
key answers C<403>, not C<401>.

=item * Errors are FastAPI's C<{"detail": ...}>, not OpenAI's
C<{"error": {...}}>. The croak message carries the body, so the C<detail>
text is in C<$@>.

=item * C<verbose_json> reports C<language> as a code (C<en>), where OpenAI
says C<english> and Groq C<English>. Segment C<id>s start at 1. Each word in
C<words> keeps its leading space (C<" This">), and so does each segment's
C<text>; the top-level C<text> has none.

=item * Fields a request did not ask for are present as JSON C<null>, not
missing: C<words> without word timestamps, C<usage> and C<logprobs>. Read
C<< @{ $result->{words} // [] } >>. A C<null> C<usage> gives a
L<Langertha::CallResult> without C<usage>.

=item * C<srt> and C<text> come as C<text/plain; charset=utf-8>, C<vtt> as
C<text/vtt; charset=utf-8>. L<Langertha::Role::OpenAICompatible/transcription_response>
returns each body as text.

=back

L<Langertha::Engine::OpenAI> exposes a C<whisper> attribute that returns a
L<Langertha::Engine::TranscriptionBase> bound to the OpenAI cloud (sharing
its C<api_key> and C<url>) — use that when you want OpenAI's hosted Whisper
endpoint without re-stating credentials.

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<https://github.com/speaches-ai/speaches> - speaches (formerly faster-whisper-server)

=item * L<Langertha::Engine::TranscriptionBase> - Parent base class

=item * L<Langertha::Engine::OpenAI> - Provides a C<whisper> handle reusing its credentials

=item * L<Langertha::Engine::Groq> - Groq's hosted Whisper transcription

=item * L<Langertha::Role::Transcription> - Transcription role

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
