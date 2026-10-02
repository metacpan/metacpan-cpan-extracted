package Langertha::Knarr::Image;
# ABSTRACT: Translate a client's image parts into Langertha::Content::Image objects
our $VERSION = '1.102';
use strict;
use warnings;
use Scalar::Util qw( blessed );
use MIME::Base64 qw( decode_base64 );


my @ALL_FORMATS = qw( openai anthropic gemini ollama responses lmstudio );

my $translates;

sub translates {
  return $translates if defined $translates;
  $translates = eval {
    require Langertha::Content::Image;
    my $class = 'Langertha::Content::Image';
    ( $class->can('to_ollama') && $class->can('to_responses') && $class->can('to_lmstudio') ) ? 1 : 0;
  } || 0;
  return $translates;
}


sub content_formats {
  my (@face_formats) = @_;
  return translates() ? [@ALL_FORMATS] : [@face_formats];
}


sub openai_messages    { _map_messages( $_[0], \&_openai_message ) }
sub anthropic_messages { _map_messages( $_[0], \&_anthropic_message ) }
sub ollama_messages    { _map_messages( $_[0], \&_ollama_message ) }


sub _map_messages {
  my ( $messages, $code ) = @_;
  return $messages unless translates() && ref $messages eq 'ARRAY';
  return [ map { ref $_ eq 'HASH' ? $code->($_) : $_ } @$messages ];
}

sub _openai_message {
  my ($msg) = @_;
  return $msg unless ref $msg->{content} eq 'ARRAY';
  my $found = 0;
  my @parts = map {
    my $img = _from_openai_part($_);
    $img ? do { $found = 1; $img } : $_;
  } @{ $msg->{content} };
  return $found ? { %$msg, content => _plain_text(\@parts) } : $msg;
}

sub _from_openai_part {
  my ($part) = @_;
  return undef unless ref $part eq 'HASH' && ( $part->{type} // '' ) eq 'image_url';
  my $url = ref $part->{image_url} eq 'HASH' ? $part->{image_url}{url} : $part->{image_url};
  return undef unless defined $url && !ref $url && length $url;
  if ( $url =~ /\Adata:/ ) {
    my ( $media_type, $b64 ) = _parse_data_url($url) or return undef;
    return Langertha::Content::Image->from_base64( $b64, media_type => $media_type );
  }
  # Not fetched here: core fetches only for engines that need inline data.
  return Langertha::Content::Image->from_url($url);
}

sub _anthropic_message {
  my ($msg) = @_;
  return $msg unless ref $msg->{content} eq 'ARRAY';
  my $found = 0;
  my @parts = map {
    my $img = _from_anthropic_block($_);
    $img ? do { $found = 1; $img } : $_;
  } @{ $msg->{content} };
  return $found ? { %$msg, content => _plain_text(\@parts) } : $msg;
}

sub _from_anthropic_block {
  my ($block) = @_;
  return undef unless ref $block eq 'HASH' && ( $block->{type} // '' ) eq 'image'
    && ref $block->{source} eq 'HASH';
  my $src  = $block->{source};
  my $type = $src->{type} // '';
  if ( $type eq 'base64' && defined $src->{data} && length $src->{data} ) {
    return Langertha::Content::Image->from_base64( $src->{data},
      media_type => $src->{media_type} // _sniff_base64( $src->{data} ) );
  }
  if ( $type eq 'url' && defined $src->{url} && length $src->{url} ) {
    return Langertha::Content::Image->from_url( $src->{url} );
  }
  return undef;
}

sub _ollama_message {
  my ($msg) = @_;
  return $msg unless ref $msg->{images} eq 'ARRAY' && @{ $msg->{images} };
  my @images;
  for my $raw ( @{ $msg->{images} } ) {
    return $msg unless defined $raw && !ref $raw && length $raw;
    my ( $media_type, $b64 ) = $raw =~ /\Adata:/ ? _parse_data_url($raw) : ();
    return $msg if $raw =~ /\Adata:/ && !defined $b64;
    $b64 //= $raw;
    push @images, Langertha::Content::Image->from_base64( $b64,
      media_type => $media_type // _sniff_base64($b64) );
  }
  my $content = $msg->{content};
  my @parts = ref $content eq 'ARRAY'            ? @$content
            : defined $content && length $content ? ($content)
            :                                       ();
  my %out = %$msg;
  delete $out{images};
  return { %out, content => _plain_text( [ @parts, @images ] ) };
}

# A bare { type => 'text', text => ... } part as a plain string: the one
# text form core renders in every content format.
sub _plain_text {
  my ($parts) = @_;
  return [ map {
    ( ref $_ eq 'HASH' && keys %$_ == 2 && ( $_->{type} // '' ) eq 'text'
      && defined $_->{text} && !ref $_->{text} ) ? $_->{text} : $_
  } @$parts ];
}

# data:<media type>[;param...];base64,<payload>
sub _parse_data_url {
  my ($url) = @_;
  return unless $url =~ m{\Adata:([^;,]+)((?:;[^;,]*)*);base64,(.+)\z}s;
  return ( $1, $3 );
}

my @MAGIC = (
  [ qr/\A\x89PNG/,          'image/png' ],
  [ qr/\A\xFF\xD8\xFF/,     'image/jpeg' ],
  [ qr/\AGIF8/,             'image/gif' ],
  [ qr/\ARIFF.{4}WEBP/s,    'image/webp' ],
  [ qr/\ABM/,               'image/bmp' ],
);

# Media type from the payload's magic bytes; Ollama sends none. PNG when
# nothing matches.
sub _sniff_base64 {
  my ($b64) = @_;
  my $head = decode_base64( substr( $b64, 0, 16 ) );
  for my $m (@MAGIC) {
    return $m->[1] if $head =~ $m->[0];
  }
  return 'image/png';
}

sub plain_messages {
  my ($messages) = @_;
  return $messages unless ref $messages eq 'ARRAY'
    && grep { ref $_ eq 'HASH' && ref $_->{content} eq 'ARRAY'
              && grep { blessed $_ } @{ $_->{content} } } @$messages;
  return [ map {
    ( ref $_ eq 'HASH' && ref $_->{content} eq 'ARRAY' )
      ? { %$_, content => [ map { _plain_part($_) } @{ $_->{content} } ] }
      : $_
  } @$messages ];
}


sub _plain_part {
  my ($part) = @_;
  return $part unless blessed $part;
  if ( $part->isa('Langertha::Content::Image') ) {
    my $url = $part->has_base64
      ? sprintf( 'data:%s;base64,%s', $part->media_type // 'application/octet-stream', $part->base64 )
      : $part->url;
    return { type => 'image_url', image_url => { url => $url } };
  }
  return "$part";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Image - Translate a client's image parts into Langertha::Content::Image objects

=head1 VERSION

version 1.102

=head1 SYNOPSIS

    use Langertha::Knarr::Image;

    # In a protocol's parse_chat_request:
    my $messages = Langertha::Knarr::Image::openai_messages( $data->{messages} );

    # Before a messages array is JSON-encoded for a trace or a log:
    my $plain = Langertha::Knarr::Image::plain_messages($messages);

=head1 DESCRIPTION

Each client-facing protocol receives images in its own shape: OpenAI
C<image_url> content parts, Anthropic C<image> blocks, Ollama's per-message
C<images> array of raw base64. The engine behind the route may speak another
shape entirely. This module turns every face's image representation into
L<Langertha::Content::Image> objects inside the message C<content> array;
Langertha core then serializes them in the engine's own C<content_format>
(C<openai>, C<anthropic>, C<gemini>, C<ollama>, C<responses>, C<lmstudio>).

Translation needs a core whose L<Langertha::Content::Image> serializes all of
those formats (C<to_ollama>, C<to_responses>, C<to_lmstudio>). On an older
core (Langertha 0.503) the translators return the messages untouched and
images keep passing through in the client's shape, as before.

Only messages that carry an image change. In such a message a bare
C<< { type => 'text', text => ... } >> part becomes a plain string, which core
turns into the text part of whatever format the engine speaks; a text part
with any other key (C<cache_control>, ...) is kept as sent. The input arrays
are never modified; a changed message is a copy.

An OpenAI C<image_url> part's C<detail> hint has no field on
L<Langertha::Content::Image> and is not carried.

=head2 translates

True when the installed core can serialize an image object into every
engine content format, i.e. when this module translates at all.

=head2 content_formats

    image_content_formats => Langertha::Knarr::Image::content_formats('openai', 'gemini'),

The engine content formats a protocol's images reach: every format when
L</translates>, else the given formats that read the protocol's own shape
untranslated.

=head2 openai_messages

=head2 anthropic_messages

=head2 ollama_messages

    my $messages = Langertha::Knarr::Image::openai_messages( \@messages );

Returns a new ArrayRef of messages with the face's image representation
replaced by L<Langertha::Content::Image> objects, or the given ArrayRef
itself when L</translates> is false.

=head2 plain_messages

    my $plain = Langertha::Knarr::Image::plain_messages($messages);

The messages with every image object replaced by its OpenAI
C<image_url> part (the URL as sent, or a C<data:> URL; nothing is fetched),
so a trace or request log can JSON-encode them. Returns the given ArrayRef
when it holds no object.

=head1 SEE ALSO

=over

=item * L<Langertha::Content::Image> (Langertha core)

=item * L<Langertha::Knarr::Protocol/manifest_endpoint> - C<image_content_formats>

=back

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
