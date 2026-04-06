package Langertha::Stream::Chunk;
# ABSTRACT: Represents a single chunk from a streaming response
our $VERSION = '0.309';
use Moose;


has content => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);


has raw => (
  is => 'ro',
  isa => 'HashRef',
  predicate => 'has_raw',
);


has is_final => (
  is => 'ro',
  isa => 'Bool',
  default => 0,
);


has model => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_model',
);


has finish_reason => (
  is => 'ro',
  isa => 'Maybe[Str]',
  predicate => 'has_finish_reason',
);


has usage => (
  is => 'ro',
  isa => 'Maybe[HashRef]',
  predicate => 'has_usage',
);



__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Stream::Chunk - Represents a single chunk from a streaming response

=head1 VERSION

version 0.309

=head1 SYNOPSIS

    my $stream = $engine->simple_chat_stream_iterator('Tell me a story');

    while (my $chunk = $stream->next) {
        print $chunk->content;

        if ($chunk->is_final) {
            say "\nModel: ", $chunk->model     if $chunk->has_model;
            say "Finish: ", $chunk->finish_reason if $chunk->has_finish_reason;
        }
    }

=head1 DESCRIPTION

A single text chunk delivered during a streaming LLM response. Each chunk
carries incremental content text and optional metadata. Chunks are collected
into a L<Langertha::Stream> iterator by
L<Langertha::Role::Chat/simple_chat_stream_iterator>.

=head2 content

The incremental text content delivered in this chunk. Required. For most
chunks this is a word or partial word; the final chunk may be an empty
string.

=head2 raw

The raw parsed API response data for this chunk as a HashRef. Use
C<has_raw> to check whether it was provided.

=head2 is_final

Boolean flag set to C<1> on the last chunk of a stream. Defaults to C<0>.

=head2 model

The model identifier returned by the provider, if present. Use C<has_model>
to check availability.

=head2 finish_reason

The reason the stream ended: C<stop>, C<length>, C<tool_calls>, etc.
Provider-specific values are preserved as-is. C<undef> on non-final chunks.
Use C<has_finish_reason> to check availability.

=head2 usage

Token usage counts as a HashRef, if provided by the engine on the final
chunk. Keys vary by provider. Use C<has_usage> to check availability.

=head1 SEE ALSO

=over

=item * L<Langertha::Stream> - Iterator that holds chunks

=item * L<Langertha::Response> - Non-streaming response object

=item * L<Langertha::Role::Chat> - Chat role that produces streams

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
