package Langertha::CallResult;
# ABSTRACT: Result of an embedding, transcription or image call, with usage, rate limit and timing
our $VERSION = '0.503';
use Moose;
use Langertha::Usage;


has value => (
  is       => 'ro',
  required => 1,
);


has usage => (
  is        => 'ro',
  isa       => 'Langertha::Usage',
  predicate => 'has_usage',
);


has rate_limit => (
  is        => 'ro',
  isa       => 'Langertha::RateLimit',
  predicate => 'has_rate_limit',
);


has model => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_model',
);


has total_seconds => (
  is        => 'ro',
  isa       => 'Num',
  predicate => 'has_total_seconds',
);


has raw => (
  is        => 'ro',
  isa       => 'Ref',
  predicate => 'has_raw',
);


sub from_http_response {
  my ( $class, $engine, $http_response, %args ) = @_;
  my $raw;
  my $type = lc( $http_response->content_type // '' );
  if ( $type =~ /json/ || ( $type !~ m{\Atext/} && $http_response->content =~ /\A\s*[\{\[]/ ) ) {
    local $@;
    $raw = eval { $engine->json->decode( $http_response->content ) };
  }
  my $usage;
  if ( ref $raw eq 'HASH' ) {
    my $block = $raw->{usage};
    # A duration-billed transcription has no token counts; zeros would lie.
    $usage = Langertha::Usage->from_raw($raw)
      unless ref $block eq 'HASH' && ( $block->{type} // '' ) eq 'duration';
  }
  my $model = ref $raw eq 'HASH' && defined $raw->{model} && !ref $raw->{model}
    && length $raw->{model} ? $raw->{model} : $args{model};
  my $rate_limit = $engine->can('has_rate_limit') && $engine->has_rate_limit
    ? $engine->rate_limit : undef;
  return $class->new(
    value => $args{value},
    defined $usage                 ? ( usage         => $usage )                 : (),
    defined $rate_limit            ? ( rate_limit    => $rate_limit )            : (),
    defined $model                 ? ( model         => $model )                 : (),
    defined $args{total_seconds}   ? ( total_seconds => $args{total_seconds} )   : (),
    defined $raw                   ? ( raw           => $raw )                   : (),
  );
}


sub with_value {
  my ( $self, $value ) = @_;
  return $self->new(
    value => $value,
    map { my $has = "has_$_"; $self->$has ? ( $_ => $self->$_ ) : () }
      qw( usage rate_limit model total_seconds raw ),
  );
}


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::CallResult - Result of an embedding, transcription or image call, with usage, rate limit and timing

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    my $result = $engine->simple_embedding_result('Hello world');
    my $vector = $result->value;              # what simple_embedding returns
    say $result->usage->input_tokens if $result->has_usage;
    say $result->rate_limit->requests_remaining if $result->has_rate_limit;
    say $result->model, ' in ', $result->total_seconds, 's';

    my $images = ( await $engine->simple_image_result_f('A cat') )->value;
    my $text   = $engine->simple_transcription_call('speech.mp3')->value;

=head1 DESCRIPTION

The answer of one non-chat call (embedding, transcription, image generation)
together with what the HTTP response said about it. L</value> is exactly what
the bare method (C<simple_embedding>, C<simple_transcription>,
C<simple_image>) returns; the other attributes are the provider's usage block,
the rate limit of this response, the model that answered and the measured time.

It is deliberately not a L<Langertha::Response>: that class is chat-shaped (it
stringifies to C<content>, carries C<tool_calls>, C<thinking>,
C<finish_reason>), and a vector or a list of images has none of that. See ADR
0034 in the distribution's C<docs/adr/>.

=head2 value

The call's result, the same value the bare method returns: an embedding vector
(ArrayRef of floats) or an ArrayRef of vectors for a batch, the transcript
text, or the ArrayRef of image objects.

=head2 usage

A L<Langertha::Usage> read from the response body by
L<Langertha::Usage/from_raw>: OpenAI embeddings' C<usage>
(C<prompt_tokens>, C<total_tokens>), a GPT image model's C<usage>, a token-billed
transcription's C<usage>, Ollama's C<prompt_eval_count>. Not set when the body
reports none (Gemini embeddings, Whisper servers), and not set for a
duration-billed transcription (C<< usage => { type => 'duration', seconds => N } >>):
it has no tokens to count, and its seconds stay in L</raw>. Check
L</has_usage> first.

=head2 rate_limit

The L<Langertha::RateLimit> parsed from this response's headers, the same
object L<Langertha::Engine::Remote/rate_limit> returns right after the call.
Not set when the response carried no rate limit headers.

=head2 model

The model that answered: the C<model> field of the response body when the
provider sends one (OpenAI embeddings do), otherwise the model that was
requested. Not set when neither is known (a self-hosted embedding server
called without a model).

=head2 total_seconds

Wall-clock seconds from sending the request to receiving the full response,
measured by the client like L<Langertha::Response/total_seconds>.

=head2 raw

The decoded response body when the provider answered JSON; not set for a
plain-text body (a transcription with C<response_format> C<text>, C<srt> or
C<vtt>). Fields Langertha does not lift (C<segments>, C<duration>,
C<revised_prompt>, ...) stay reachable here.

=head2 from_http_response

    my $result = Langertha::CallResult->from_http_response( $engine, $http_response,
        value => $value, model => $requested_model, total_seconds => $seconds );

Builds the result of a call whose C<$http_response> the engine has already
parsed into C<$value> (so an HTTP error has croaked before this point). Reads
L</raw>, L</usage> and the answering L</model> from the body, and takes
L</rate_limit> from the engine, which recorded it from this response while
parsing. C<model> is the requested model, used when the body names none.

=head2 with_value

    my $replaced = $result->with_value($new_value);

Returns a new C<Langertha::CallResult> with C<$new_value> as L</value> and
every other attribute copied; C<$result> itself is unchanged. Used by
L<Langertha::Embedder> and L<Langertha::ImageGen> when a plugin after-hook
replaces the value.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::Embedding/simple_embedding_result>

=item * L<Langertha::Role::Transcription/simple_transcription_call>

=item * L<Langertha::Role::ImageGeneration/simple_image_result>

=item * L<Langertha::Response> - The chat counterpart

=item * L<Langertha::Usage>, L<Langertha::RateLimit>

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
