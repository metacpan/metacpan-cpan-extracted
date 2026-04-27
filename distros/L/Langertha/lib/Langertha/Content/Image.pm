package Langertha::Content::Image;
# ABSTRACT: Canonical image content block with cross-provider conversion (OpenAI / Anthropic / Gemini)
our $VERSION = '0.500';
use Moose;
use Carp qw( croak );
use MIME::Base64 qw( encode_base64 decode_base64 );

with 'Langertha::Content';


has url => (
  is => 'ro',
  isa => 'Maybe[Str]',
  predicate => 'has_url',
);


has base64 => (
  is => 'rw',
  isa => 'Maybe[Str]',
  predicate => 'has_base64',
);


has media_type => (
  is => 'rw',
  isa => 'Maybe[Str]',
  predicate => 'has_media_type',
);


sub BUILD {
  my ($self) = @_;
  croak "Langertha::Content::Image requires url, base64, or data"
    unless $self->has_url || $self->has_base64;
}

# --- Constructors ---

sub from_url {
  my ( $class, $url, %extra ) = @_;
  croak "from_url requires a URL" unless defined $url && length $url;
  my $media_type = $extra{media_type} // _sniff_media_type($url);
  return $class->new(
    url => $url,
    ( defined $media_type ? ( media_type => $media_type ) : () ),
  );
}


sub from_file {
  my ( $class, $path, %extra ) = @_;
  croak "from_file requires a path" unless defined $path && length $path;
  croak "from_file: $path not found" unless -f $path;
  open my $fh, '<:raw', $path or croak "open $path: $!";
  my $bytes = do { local $/; <$fh> };
  close $fh;
  my $media_type = $extra{media_type} // _sniff_media_type($path);
  croak "from_file: cannot determine media_type for $path"
    unless defined $media_type;
  return $class->new(
    base64     => encode_base64($bytes, ''),
    media_type => $media_type,
  );
}


sub from_data {
  my ( $class, $bytes, %extra ) = @_;
  croak "from_data requires bytes" unless defined $bytes;
  croak "from_data requires media_type" unless defined $extra{media_type};
  return $class->new(
    base64     => encode_base64($bytes, ''),
    media_type => $extra{media_type},
  );
}


sub from_base64 {
  my ( $class, $b64, %extra ) = @_;
  croak "from_base64 requires a base64 string" unless defined $b64 && length $b64;
  croak "from_base64 requires media_type" unless defined $extra{media_type};
  return $class->new(
    base64     => $b64,
    media_type => $extra{media_type},
  );
}


# --- Base64 materialization ---

sub ensure_base64 {
  my ($self) = @_;
  return $self->base64 if $self->has_base64;
  croak "ensure_base64: no url to fetch" unless $self->has_url;

  require LWP::UserAgent;
  my $ua = LWP::UserAgent->new(
    agent   => 'Langertha-Content-Image/'.$VERSION,
    timeout => 30,
  );
  my $response = $ua->get($self->url);
  croak "ensure_base64: failed to fetch ".$self->url.": ".$response->status_line
    unless $response->is_success;

  $self->base64(encode_base64($response->decoded_content(charset => 'none'), ''));
  unless ($self->has_media_type) {
    my $ct = $response->header('Content-Type') // '';
    $ct =~ s/;.*$//;
    $ct =~ s/^\s+|\s+$//g;
    $self->media_type($ct) if length $ct;
  }
  return $self->base64;
}


# --- Serializers ---

sub to_openai {
  my ($self) = @_;
  my $url = $self->has_url
    ? $self->url
    : sprintf('data:%s;base64,%s',
        ($self->media_type // 'application/octet-stream'),
        $self->base64,
      );
  return { type => 'image_url', image_url => { url => $url } };
}


sub to_anthropic {
  my ($self) = @_;
  if ($self->has_url) {
    return {
      type   => 'image',
      source => { type => 'url', url => $self->url },
    };
  }
  croak "to_anthropic: base64 image requires media_type"
    unless $self->has_media_type;
  return {
    type   => 'image',
    source => {
      type       => 'base64',
      media_type => $self->media_type,
      data       => $self->base64,
    },
  };
}


sub to_gemini {
  my ($self) = @_;
  $self->ensure_base64;
  croak "to_gemini: image requires media_type"
    unless $self->has_media_type;
  return {
    inline_data => {
      mime_type => $self->media_type,
      data      => $self->base64,
    },
  };
}


# --- Helpers ---

my %EXT_MAP = (
  jpg  => 'image/jpeg',
  jpeg => 'image/jpeg',
  png  => 'image/png',
  gif  => 'image/gif',
  webp => 'image/webp',
  bmp  => 'image/bmp',
  svg  => 'image/svg+xml',
  heic => 'image/heic',
  heif => 'image/heif',
);

sub _sniff_media_type {
  my ($path) = @_;
  return undef unless defined $path;
  ( my $clean = $path ) =~ s/[?#].*$//;
  if ( $clean =~ /\.([a-zA-Z0-9]+)$/ ) {
    return $EXT_MAP{ lc $1 };
  }
  return undef;
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Content::Image - Canonical image content block with cross-provider conversion (OpenAI / Anthropic / Gemini)

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    use Langertha::Content::Image;

    # From a remote URL
    my $img = Langertha::Content::Image->from_url('https://example.com/cat.jpg');

    # From a local file (media_type sniffed from extension)
    my $img = Langertha::Content::Image->from_file('/tmp/cat.png');

    # From raw bytes
    my $img = Langertha::Content::Image->from_data($bytes, media_type => 'image/jpeg');

    # From an existing base64 string
    my $img = Langertha::Content::Image->from_base64($b64, media_type => 'image/png');

    # Embed in a chat message — Langertha::Role::Chat converts per engine
    my $response = $engine->simple_chat_f({
        role    => 'user',
        content => [ 'What is in this image?', $img ],
    });

=head1 DESCRIPTION

Provider-neutral image block. Carries either a remote URL, a base64 payload,
or both, plus an IANA C<media_type>. Serializes to the three dominant
vision-chat wire formats:

=over

=item * OpenAI chat completions — C<{ type => 'image_url', image_url => { url => ... } }>

=item * Anthropic messages — C<{ type => 'image', source => { type => 'url' | 'base64', ... } }>

=item * Google Gemini — C<{ inline_data => { mime_type => ..., data => <base64> } }>

=back

Gemini requires base64, so C<to_gemini> will transparently download a
remote URL on first call (cached on the object).

=head2 url

Remote HTTP(S) URL of the image. May be passed through directly (OpenAI,
Anthropic) or auto-downloaded and base64-encoded (Gemini).

=head2 base64

The base64-encoded image payload (no C<data:> URL prefix). Can be supplied
at construction, or populated lazily when a provider that requires inline
data (Gemini) is targeted.

=head2 media_type

IANA media type (C<image/jpeg>, C<image/png>, C<image/gif>, C<image/webp>).
Required for base64 payloads on Anthropic and Gemini. Sniffed from the file
extension by C<from_file> and from the URL path by C<from_url>.

=head2 from_url

    my $img = Langertha::Content::Image->from_url($url);
    my $img = Langertha::Content::Image->from_url($url, media_type => 'image/jpeg');

Builds an image block referencing a remote URL. Media type is sniffed from
the URL extension when not provided.

=head2 from_file

    my $img = Langertha::Content::Image->from_file('/tmp/cat.png');

Reads a local file, base64-encodes it, and sniffs the media type from the
extension (unless C<media_type> is passed).

=head2 from_data

    my $img = Langertha::Content::Image->from_data($bytes, media_type => 'image/jpeg');

Builds an image block from raw bytes. C<media_type> is required.

=head2 from_base64

    my $img = Langertha::Content::Image->from_base64($b64, media_type => 'image/png');

Builds an image block from an existing base64 string.

=head2 ensure_base64

    my $b64 = $img->ensure_base64;

Returns the base64 payload, fetching the URL over HTTP if necessary.
Populates C<media_type> from the response C<Content-Type> header when the
image was URL-only. Caches the result on the object.

=head2 to_openai

    my $block = $img->to_openai;
    # { type => 'image_url', image_url => { url => ... } }

Serializes to the OpenAI chat-completions image block. Uses the URL when
available, otherwise emits a C<data:> URL from the base64 payload.

=head2 to_anthropic

    my $block = $img->to_anthropic;
    # { type => 'image', source => { type => 'url', url => ... } }
    # or
    # { type => 'image', source => { type => 'base64', media_type => ..., data => ... } }

Serializes to the Anthropic messages image block. Prefers a URL source
when available; otherwise emits an inline base64 source (C<media_type>
required).

=head2 to_gemini

    my $block = $img->to_gemini;
    # { inline_data => { mime_type => ..., data => <base64> } }

Serializes to the Gemini C<inlineData> part. Auto-downloads URL-only
images because Gemini has no URL-fetching equivalent.

=head1 SEE ALSO

=over

=item * L<Langertha::Content> - Base role this class implements

=item * L<Langertha::Role::Chat> - Normalizes content blocks per engine during C<chat_messages>

=item * L<Langertha::ToolChoice> - Sibling value object for tool_choice normalization

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
