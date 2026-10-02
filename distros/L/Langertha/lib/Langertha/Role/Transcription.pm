package Langertha::Role::Transcription;
# ABSTRACT: Role for APIs with transcription functionality
our $VERSION = '0.503';
use Moose::Role;
use Future::AsyncAwait;
use Carp qw( croak );
use Scalar::Util qw( openhandle );
use Time::HiRes qw( gettimeofday tv_interval );
use Langertha::CallResult;

# The _f methods send through the engine's async backend (k292): injected
# client > Net::Async::HTTP > the sync LWP shim (ADR 0027).
with 'Langertha::Role::AsyncHTTP';

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


sub transcription_file_part {
  my ( $self, $input, $filename ) = @_;
  croak "".(ref $self).": no audio given for transcription" unless defined $input;
  my $bytes;
  if ( ref $input eq 'SCALAR' ) {
    $bytes = $$input;
  }
  elsif ( openhandle($input) ) {
    binmode $input;
    local $/;
    $bytes = readline $input;
    croak "".(ref $self).": cannot read audio from filehandle: $!" unless defined $bytes;
  }
  elsif ( !ref $input && index( $input, "\0" ) >= 0 ) {
    # No path contains a NUL byte, and nearly every audio container header
    # does (RIFF sizes, ID3, OggS, fLaC) -- so this is content, and it never
    # reaches open() or a file test. -- karr k287
    $bytes = $input;
  }
  else {
    return [ $input, defined $filename ? ( $filename ) : () ];
  }
  croak "".(ref $self).": audio content must be bytes, not a character string"
    if utf8::is_utf8($bytes) && !utf8::downgrade( $bytes, 1 );
  return [ undef, $filename // 'audio',
    'Content-Type' => 'application/octet-stream', Content => $bytes ];
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


async sub simple_transcription_f {
  my ( $self, $file_or_content, %extra ) = @_;
  my $request = $self->transcription($file_or_content, %extra);
  my $response = await $self->_async_do_request_f( request => $request );
  return $request->response_call->($response);
}


sub simple_transcription_result {
  my ( $self, $file_or_content, %extra ) = @_;
  croak "".(ref $self)." has no transcription_result" unless $self->can('transcription_result');
  my $request = $self->transcription($file_or_content, %extra);
  return $self->transcription_result( $self->user_agent->request($request) );
}


async sub simple_transcription_result_f {
  my ( $self, $file_or_content, %extra ) = @_;
  croak "".(ref $self)." has no transcription_result" unless $self->can('transcription_result');
  my $request = $self->transcription($file_or_content, %extra);
  my $response = await $self->_async_do_request_f( request => $request );
  return $self->transcription_result($response);
}


sub simple_transcription_call {
  my ( $self, $file_or_content, %extra ) = @_;
  my $model = exists $extra{model} ? $extra{model} : $self->transcription_model;
  my $request = $self->transcription($file_or_content, %extra);
  my $t0 = [gettimeofday];
  my $response = $self->user_agent->request($request);
  my $elapsed = tv_interval($t0);
  my $value = $request->response_call->($response);
  return Langertha::CallResult->from_http_response( $self, $response,
    value => $value, model => $model, total_seconds => $elapsed );
}


async sub simple_transcription_call_f {
  my ( $self, $file_or_content, %extra ) = @_;
  my $model = exists $extra{model} ? $extra{model} : $self->transcription_model;
  my $request = $self->transcription($file_or_content, %extra);
  my $t0 = [gettimeofday];
  my $response = await $self->_async_do_request_f( request => $request );
  my $elapsed = tv_interval($t0);
  my $value = $request->response_call->($response);
  return Langertha::CallResult->from_http_response( $self, $response,
    value => $value, model => $model, total_seconds => $elapsed );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Transcription - Role for APIs with transcription functionality

=head1 VERSION

version 0.503

=head2 transcription_model

The model name to use for transcription requests. Lazily defaults to
C<default_transcription_model> if the engine provides it, otherwise falls back
to the general C<model> attribute from L<Langertha::Role::Models>.

=head2 transcription_file_part

    my $part = $engine->transcription_file_part($audio, $filename);

Turns the audio argument of L</transcription> into the multipart file part.
C<$audio> is one of:

=over

=item * a path to the audio file (a plain string);

=item * a reference to a scalar holding the audio bytes: C<\$bytes>;

=item * an open filehandle, read to the end in binary mode;

=item * a plain string that contains a NUL byte, taken as the audio bytes
(no path can contain one). Prefer C<\$bytes>: a short content without a NUL
would be taken as a path.

=back

C<$filename> is the name sent with the part; it defaults to the basename of
the path, and to C<audio> for in-memory content. Hosted APIs (OpenAI, Groq)
detect the format from the filename's extension, so pass one such as
C<speech.mp3> with in-memory audio.

=head2 transcription

    my $request = $engine->transcription($audio, %extra);
    my $request = $engine->transcription(\$bytes, filename => 'speech.mp3');

Builds and returns a transcription HTTP request object for the given audio:
a path, C<\$bytes>, or a filehandle (see L</transcription_file_part>).
C<filename> in C<%extra> sets the uploaded filename; the other C<%extra> pairs
are sent as form fields. Use L</simple_transcription> to execute the request
and get the transcript directly.

=head2 simple_transcription

    my $text = $engine->simple_transcription($audio, %extra);
    my $text = $engine->simple_transcription('/path/to/audio.mp3');
    my $text = $engine->simple_transcription(\$audio_bytes,
        filename => 'audio.mp3', language => 'en');

Sends a transcription request for the audio (a path, C<\$bytes> or a
filehandle, see L</transcription_file_part>) and returns the transcript text. Blocks until the request completes. Additional options such as
C<language> can be passed as C<%extra> key/value pairs.
L</simple_transcription_f> is the non-blocking variant.

=head2 simple_transcription_f

    my $text = await $engine->simple_transcription_f('/path/to/audio.mp3');
    my $text = await $engine->simple_transcription_f(\$audio_bytes,
        filename => 'audio.mp3', language => 'en');

Async variant of L</simple_transcription>: same arguments, returns a
L<Future> that resolves to the transcript text and fails with the same error
text. The multipart upload goes through the engine's async backend
(L<Langertha::Role::AsyncHTTP>), so L<Langertha::Role::HTTP/user_agent_timeout>
bounds it on L<Net::Async::HTTP> too; without that module it runs
synchronously over LWP. The audio is read into the request body when the
call is made.

=head2 simple_transcription_result

    my $result = $engine->simple_transcription_result('/path/to/audio.mp3',
        response_format => 'verbose_json',
        'timestamp_granularities[]' => [qw( word segment )],
    );
    say $_->{word}, ' @ ', $_->{start} for @{ $result->{words} };

Like L</simple_transcription>, but returns the whole parsed answer as a
HashRef (see L<Langertha::Role::OpenAICompatible/transcription_result>)
instead of only the text. C<verbose_json> and word timestamps need a model
that offers them (C<whisper-1>, Groq, Whisper servers); OpenAI's default
C<gpt-transcribe> answers C<json> only.

=head2 simple_transcription_result_f

    my $result = await $engine->simple_transcription_result_f($audio,
        response_format => 'verbose_json');

Async variant of L</simple_transcription_result>: returns a L<Future> that
resolves to the parsed answer as a HashRef, like L</simple_transcription_f>
does for the text.

=head2 simple_transcription_call

    my $result = $engine->simple_transcription_call('/path/to/audio.mp3');
    say $result->value;                                   # the transcript text
    say $result->usage->input_tokens if $result->has_usage;
    my $segments = $result->raw->{segments};              # verbose_json

Like L</simple_transcription>, but returns a L<Langertha::CallResult>: the
transcript text as C<value>, plus the provider's token C<usage> (OpenAI's
C<gpt-transcribe>), this response's C<rate_limit>, the model and the measured
C<total_seconds>. A JSON answer is kept whole in C<raw> (C<segments>,
C<words>, C<duration>, a duration-billed C<usage>).

It is not called C<simple_transcription_result> because that name already
returns the parsed answer as a HashRef, and keeps doing so.

=head2 simple_transcription_call_f

    my $result = await $engine->simple_transcription_call_f(\$bytes,
        filename => 'speech.mp3');

Async variant of L</simple_transcription_call>, sent like
L</simple_transcription_f>: resolves to the L<Langertha::CallResult> and fails
with the same error text.

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

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
