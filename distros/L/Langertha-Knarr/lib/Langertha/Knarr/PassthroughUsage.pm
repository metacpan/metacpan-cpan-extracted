package Langertha::Knarr::PassthroughUsage;
# ABSTRACT: Token usage and model read off a copy of a raw passthrough answer
our $VERSION = '1.102';
use Moose;
use JSON::MaybeXS;


has max_line => ( is => 'ro', isa => 'Int', default => 65536 );

has usage => ( is => 'ro', init_arg => undef, writer => '_set_usage' );

has model => ( is => 'ro', init_arg => undef, writer => '_set_model' );

has _json => ( is => 'ro', lazy => 1, builder => '_build__json' );
sub _build__json { JSON::MaybeXS->new( utf8 => 1 ) }

# The unfinished last line, and whether the line in progress was too long
# and is being skipped up to its end.
has _tail     => ( is => 'rw', init_arg => undef, default => '' );
has _skipping => ( is => 'rw', init_arg => undef, default => 0 );

sub add_chunk {
  my ( $self, $data ) = @_;
  return unless defined $data && length $data;
  my $buf = $self->_tail . $data;
  if ( $self->_skipping ) {
    my $nl = index( $buf, "\n" );
    if ( $nl < 0 ) { $self->_tail(''); return }
    substr( $buf, 0, $nl + 1, '' );
    $self->_skipping(0);
  }
  my $end = rindex( $buf, "\n" );
  if ( $end >= 0 ) {
    $self->_read_line($_) for split /\n/, substr( $buf, 0, $end );
    substr( $buf, 0, $end + 1, '' );
  }
  if ( length $buf > $self->max_line ) {
    $self->_tail('');
    $self->_skipping(1);
    return;
  }
  $self->_tail($buf);
  return;
}


sub read_body {
  my ( $self, $body ) = @_;
  return unless defined $body && length $body;
  if ( $body =~ /\A\s*\{/ ) {
    my $obj = eval { $self->_json->decode($body) };
    return $self->_take($obj) if ref $obj eq 'HASH';
  }
  # A buffered stream (PSGI), or NDJSON.
  $self->add_chunk($body);
  $self->finish;
  return;
}


sub finish {
  my ( $self ) = @_;
  my $tail = $self->_tail;
  $self->_tail('');
  $self->_read_line($tail) if length $tail && !$self->_skipping;
  $self->_skipping(0);
  return;
}


sub trace_args {
  my ( $self ) = @_;
  $self->finish;
  return (
    defined $self->usage ? ( usage => $self->usage ) : (),
    defined $self->model ? ( model => $self->model ) : (),
  );
}


# A line worth decoding carries a usage object or count, or names the
# model while none is known yet (OpenAI repeats it in every chunk, and
# sends "usage":null in every chunk but the last).
sub _read_line {
  my ( $self, $line ) = @_;
  $line =~ s/\r\z//;
  $line =~ s/\Adata:[ \t]*//;
  return unless $line =~ /\A\s*\{/;
  return unless $line =~ /"(?:usage"\s*:\s*\{|prompt_eval_count"|eval_count")/
    || ( !defined $self->model && index( $line, '"model"' ) >= 0 );
  my $obj = eval { $self->_json->decode($line) };
  $self->_take($obj) if ref $obj eq 'HASH';
  return;
}

sub _take {
  my ( $self, $obj ) = @_;
  # Anthropic's message_start carries the message, model and usage inside.
  my $msg = ref $obj->{message} eq 'HASH' ? $obj->{message} : {};
  my $model = $obj->{model} // $msg->{model};
  $self->_set_model($model) if defined $model && !ref $model && length $model;

  my $type = $obj->{type} // '';
  if ( $type eq 'message_delta' && ref $obj->{usage} eq 'HASH' ) {
    my %merged = %{ $self->usage // {} };
    my $delta = $obj->{usage};
    $merged{$_} = $delta->{$_} for grep { defined $delta->{$_} } keys %$delta;
    $self->_set_usage( \%merged );
  }
  elsif ( ref $obj->{usage} eq 'HASH' ) {
    $self->_set_usage( $obj->{usage} );
  }
  elsif ( ref $msg->{usage} eq 'HASH' ) {
    $self->_set_usage( $msg->{usage} );
  }
  elsif ( defined $obj->{prompt_eval_count} || defined $obj->{eval_count} ) {
    $self->_set_usage({ map { defined $obj->{$_} ? ( $_ => $obj->{$_} ) : () }
      qw( prompt_eval_count eval_count ) });
  }
  return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::PassthroughUsage - Token usage and model read off a copy of a raw passthrough answer

=head1 VERSION

version 1.102

=head1 SYNOPSIS

    my $reader = Langertha::Knarr::PassthroughUsage->new;

    # A stream, chunk by chunk, as the bytes go to the client
    $reader->add_chunk($_) for @chunks;

    # or a buffered answer at once
    $reader->read_body($body);

    $tracing->end_trace( $trace, output => '[stream]', $reader->trace_args );

=head1 DESCRIPTION

The raw passthrough (L<Langertha::Knarr/raw_passthrough>) pipes the
upstream's bytes to the client untouched. For its Langfuse trace, this
reader looks at a copy of those bytes and keeps the token usage and the
model the upstream reported -- it never changes, holds back or re-frames
what the client gets.

It reads what the three passthrough upstreams send, by the shape of each
JSON object, buffered or streamed:

=over

=item * OpenAI: C<model> and C<usage> of a completion; in a stream the
chunk carrying C<usage> (sent with C<stream_options.include_usage>).

=item * Anthropic: C<model> and C<usage> of a message; in a stream the
C<usage> of C<message_start>, with the counts of every C<message_delta>
laid over it.

=item * Ollama: C<model>, C<prompt_eval_count> and C<eval_count> of an
answer; in a stream those of the C<done> frame.

=back

The usage is kept in the provider's own keys, which
L<Langertha::Knarr::Tracing/end_trace> maps. A stream is read line by line
(SSE C<data:> lines, NDJSON lines), a line split across chunks included;
only the unfinished last line is held, at most L</max_line> bytes of it,
and only lines that can carry usage or a still unknown model are decoded.
Anything that does not parse is skipped.

=head2 max_line

Bytes of an unfinished line held between chunks. Default C<65536>; a longer
line is dropped whole -- a usage frame is far shorter.

=head2 usage

The provider's usage hash seen last (merged for Anthropic), or C<undef>.

=head2 model

The model the upstream named last, or C<undef>.

=head2 add_chunk

    $reader->add_chunk($bytes);

Reads the next piece of a stream. Returns nothing.

=head2 read_body

    $reader->read_body($bytes);

Reads a whole buffered answer: one JSON object, or a buffered stream.

=head2 finish

    $reader->finish;

Reads a last line the stream did not end with a newline. L</trace_args>
calls it.

=head2 trace_args

    $tracing->end_trace( $trace, output => '[stream]', $reader->trace_args );

C<usage> and C<model> as far as the answer had them, for
L<Langertha::Knarr::Tracing/end_trace>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

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
