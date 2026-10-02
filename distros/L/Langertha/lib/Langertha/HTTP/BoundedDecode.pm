package Langertha::HTTP::BoundedDecode;
# ABSTRACT: Bounded Content-Encoding inflate shared by the response-body decoders
our $VERSION = '0.503';
use strict;
use warnings;


# The Content-Encodings this decoder can undo, mapped to the inflate kind.
# identity is a no-op; gzip/deflate/bzip2 (plus the x- aliases HTTP::Message
# accepts) inflate; anything else is refused by the caller's
# unbounded_encoding handler, because it cannot be bounded here.
my %INFLATE = (
  identity  => undef,
  gzip      => 'gzip',  'x-gzip'    => 'gzip',
  deflate   => 'zlib',  'x-deflate' => 'zlib',
  bzip2     => 'bzip2', 'x-bzip2'   => 'bzip2',
);

# Undo $content_encoding on $body within $max decoded bytes. $content_encoding
# is the raw Content-Encoding header value (a comma list is applied in order,
# so undone in reverse). $handlers holds the three croak points; each is
# expected to croak (its return value is ignored):
#   too_big            => sub { my ($max) = @_; ... }       # decoded past $max
#   undecodable        => sub { my ($encoding) = @_; ... }  # corrupt / not that encoding
#   unbounded_encoding => sub { my ($encoding) = @_; ... }  # an encoding we cannot bound
sub decode_within {
  my ( $body, $content_encoding, $max, $handlers ) = @_;
  my @encodings = grep { length } map { s/\A\s+|\s+\z//gr }
    split /,/, lc( $content_encoding // '' );
  for my $encoding ( reverse @encodings ) {   # listed in the order applied
    $handlers->{unbounded_encoding}->($encoding) unless exists $INFLATE{$encoding};
    my $kind = $INFLATE{$encoding} or next;
    $body = $kind eq 'bzip2'
      ? _bunzip_capped( $body, $max, $encoding, $handlers )
      : _inflate_capped( $body, $max, $encoding, $kind, $handlers );
  }
  return $body;
}


# zlib inflate in output blocks of at most 64 KiB. deflate is the zlib format,
# with raw deflate as the fallback that HTTP::Message allows too.
sub _inflate_capped {
  my ( $in, $max, $encoding, $kind, $handlers ) = @_;
  require Compress::Raw::Zlib;
  my @bits = $kind eq 'gzip' ? ( Compress::Raw::Zlib::WANT_GZIP() )
    : ( Compress::Raw::Zlib::MAX_WBITS(), -Compress::Raw::Zlib::MAX_WBITS() );
  for my $bits (@bits) {
    my $input = $in;
    my ( $inflater, $status ) = Compress::Raw::Zlib::Inflate->new(
      -WindowBits => $bits, -Bufsize => 65_536, -LimitOutput => 1,
      -ConsumeInput => 1, -AppendOutput => 1 );
    $handlers->{undecodable}->($encoding) unless $status == Compress::Raw::Zlib::Z_OK();
    my $out = '';
    while (1) {
      my @before = ( length $input, length $out );
      $status = $inflater->inflate( $input, $out );
      $handlers->{too_big}->($max) if length $out > $max;
      return $out if $status == Compress::Raw::Zlib::Z_STREAM_END();
      last unless $status == Compress::Raw::Zlib::Z_OK()
        || $status == Compress::Raw::Zlib::Z_BUF_ERROR();
      # No progress: the stream ends before its end marker.
      $handlers->{undecodable}->($encoding)
        if length $input == $before[0] && length $out == $before[1];
    }
    $handlers->{undecodable}->($encoding) unless $status == Compress::Raw::Zlib::Z_DATA_ERROR();
  }
  return $handlers->{undecodable}->($encoding);
}

sub _bunzip_capped {
  my ( $input, $max, $encoding, $handlers ) = @_;
  require Compress::Raw::Bzip2;
  # appendOutput, consumeInput, small, verbosity, limitOutput
  my ( $bunzip, $status ) = Compress::Raw::Bunzip2->new( 1, 1, 0, 0, 1 );
  $handlers->{undecodable}->($encoding) unless $status == Compress::Raw::Bzip2::BZ_OK();
  my $out = '';
  while (1) {
    my @before = ( length $input, length $out );
    $status = $bunzip->bzinflate( $input, $out );
    $handlers->{too_big}->($max) if length $out > $max;
    return $out if $status == Compress::Raw::Bzip2::BZ_STREAM_END();
    $handlers->{undecodable}->($encoding) unless $status == Compress::Raw::Bzip2::BZ_OK();
    $handlers->{undecodable}->($encoding)
      if length $input == $before[0] && length $out == $before[1];
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::HTTP::BoundedDecode - Bounded Content-Encoding inflate shared by the response-body decoders

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::HTTP::BoundedDecode;

    my $bytes = Langertha::HTTP::BoundedDecode::decode_within(
      $response->content,                        # the raw body
      scalar $response->header('Content-Encoding'),
      $max_decoded_bytes,
      {
        too_big            => sub { croak "body exceeds $_[0]" },
        undecodable        => sub { croak "cannot decode '$_[0]'" },
        unbounded_encoding => sub { croak "cannot bound '$_[0]'" },
      },
    );

=head1 DESCRIPTION

The bounded Content-Encoding inflater behind Langertha's response decoders.
L<HTTP::Message/decoded_content> undoes a C<Content-Encoding> (C<gzip>,
C<deflate>, C<bzip2>) with B<no size bound>, so a small compressed body can
inflate to gigabytes in memory — a decompression bomb from a hostile or broken
endpoint. This module inflates in bounded blocks and refuses a body once its
decoded size passes C<$max>, so the memory is capped.

It carries no error text of its own: each caller passes the three croak points,
so L<Langertha::Content::Image> (image fetches, karr k342) and
L<Langertha::Role::HTTP> (provider/metrics response bodies, karr k346) keep
their own messages while sharing one inflate path. It returns the decoded
B<bytes>; charset decoding is the caller's concern.

=head2 decode_within

    my $bytes = Langertha::HTTP::BoundedDecode::decode_within(
      $raw_body, $content_encoding_header, $max, \%handlers );

Undoes the C<Content-Encoding> of C<$raw_body> within C<$max> decoded bytes and
returns the decoded bytes. A comma-listed encoding is undone in reverse of the
order it was applied. Calls C<< $handlers->{too_big}->($max) >> as soon as the
decoded size passes C<$max>, C<< $handlers->{undecodable}->($encoding) >> when a
supported encoding is corrupt, and
C<< $handlers->{unbounded_encoding}->($encoding) >> for an encoding it cannot
bound (anything but C<gzip> / C<deflate> / C<bzip2> and their C<x-> aliases and
C<identity>). Each handler is expected to croak.

=head1 SEE ALSO

=over

=item * L<Langertha::Content::Image> - Bounds inline image fetches (karr k342)

=item * L<Langertha::Role::HTTP> - Bounds provider/metrics response bodies (karr k346)

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
