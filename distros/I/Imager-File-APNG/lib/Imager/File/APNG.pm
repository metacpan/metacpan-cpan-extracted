package Imager::File::APNG;
use strict;
use warnings;
use Imager;
use Imager::File::PNG;
use vars qw($VERSION);

our $VERSION = "0.002";

my $png_header = "\x89PNG\x0d\x0A\cZ\x0A";

sub _read_png_data {
  my ($data, $frame) = @_;

  my $io = Imager::IO->new_buffer($data)
    or die;
  my $im = Imager->new;
  unless (Imager::File::PNG->read($im, $io)) {
    Imager->_set_error("APNG: " . $im->_error_as_msg . " decoding frame $frame");
    return;
  }
  return $im;
}

# single image APNG is just PNG
sub write_apng {
  my ($im, $io, %hsh) = @_;

  return return Imager::File::PNG->write($im, $io, %hsh);
};

sub _make_actl {
  my ($num_frames, $num_plays) = @_;

  return _make_chunk("acTL", pack("NN", $num_frames, $num_plays));
}

my %dispose_names =
  (
    0 => "none",
    1 => "background",
    2 => "previous",
   );

my %dispose_nums = reverse(%dispose_names);

my %blend_names =
  (
    0 => "source",
    1 => "over",
   );

my %blend_nums = reverse(%blend_names);

sub _make_fctl {
  my ($seq, $im, $frame) = @_;

  my $xoff = $im->tags(name => "apng_xoffset") || 0;
  my $yoff = $im->tags(name => "apng_yoffset") || 0;
  my $delay = $im->tags(name => "apng_delay");
  my $delay_num = $im->tags(name => "apng_delay_num");
  my $delay_den = $im->tags(name => "apng_delay_den");

  if (defined $delay) {
    if ($delay > 65) {
      # some seconds
      $delay_num = int($delay);
      $delay_den = 1;
    }
    elsif ($delay < 0) {
      Imager->_set_error("APNG: apng_delay value $delay page $frame must be non-negative");
      return;
    }
    else {
      # FIXME: try to find a better rational estimate
      $delay_num = int($delay * 1000);
      $delay_den = 1000;
    }
  }
  elsif (defined $delay_den) {
    unless (defined $delay_num) {
      $delay_num = 1;
    }
  }
  else {
    $delay_den = 60;
    unless (defined $delay_num) {
      $delay_num = 1;
    }
  }
  if ($delay_num < 0 || $delay_num > 65535) {
    Imager->_set_error("APNG: apng_delay_num value $delay_num page $frame out of range 0 .. 65535");
    return;
  }
  if ($delay_den < 0 || $delay_den > 65535) {
    Imager->_set_error("APNG: apng_delay_den value $delay_den page $frame out of range 0 .. 65535");
    return;
  }

  my $dispose = $im->tags(name => "apng_dispose") || 0;
  my $blend = $im->tags(name => "apng_blend") || 0;
  if ($dispose =~ /[^0-9.]/) {
    if (exists $dispose_nums{$dispose}) {
      $dispose = $dispose_nums{$dispose};
    }
    else {
      Imager->_set_error("APNG: unknown value '$dispose' page $frame for apng_dispose");
      return
    }
  }
  if ($blend =~ /[^0-9.]/) {
    if (exists $blend_nums{$blend}) {
      $blend   = $blend_nums{$blend};
    }
    else {
      Imager->_set_error("APNG: unknown value '$blend' page $frame for apng_blend");
      return
    }
  }

  return _make_chunk("fcTL", pack("NNNNNnnCC", $seq, $im->getwidth, $im->getheight,
                                  $xoff, $yoff, $delay_num, $delay_den, $dispose, $blend));
}

sub _make_fdat {
  my ($seq, $payload) = @_;

  return _make_chunk("fdAT", pack("N", $seq) . $payload);
}

sub write_multi_apng  {
  my ($class, $io, $opts, @ims) = @_;

  if (@ims == 1) {
    return $ims[0]->write(%$opts, type => "png", io => $io);
  }

  Imager->_set_opts($opts, "apng_", @ims);

  # APNG files contain only a single image type and bit depth, if
  # they're all the same use that, otherwise we need to convert them
  # to the same
  my $type = $ims[0]->type;
  my $bits = $ims[0]->bits;
  my $chans = $ims[0]->colorchannels;
  my $allchans = $ims[0]->getchannels;
  my $palette = $type eq "paletted" && $chans == 3
    ? join "", map { chr } map { ($_->rgba)[0..($allchans-1)] } $ims[0]->getcolors
    : "";
  my $need_alpha = 0;
  for my $im (@ims) {
    if ($type eq 'paletted') {
      if ($im->type eq 'direct' || $im->getchannels() != $allchans) {
        $type = 'direct';
      }
      else {
        # check we have a common palette and channels is 3
        my $npalette = join "", map { chr } map { ($_->rgba)[0..($allchans-1)] } $im->getcolors;
        if ($im->colorchannels != 3 || $palette ne $npalette) {
          $type = 'direct';
        }
      }
    }
    if ($im->bits eq 'double' || ($bits ne 'double' && $im->bits > $bits)) {
      $bits = $im->bits;
    }
    $need_alpha = 1 if $im->alphachannel;
    if ($im->colorchannels > $chans) {
      $chans = $im->colorchannels;
    }
  }

  if ($type eq 'direct') {
    if ($bits eq 'double' || $bits > 8) {
      $bits = 16;
    }
    # chans is fine
  }

  # Which is the first visible frame in the animation? The first image
  # can be hidden from the animation.  The first image still needs to be
  # the same type as the other images, since they share the type fields of the
  # IHDR (and the PLTE, tRNS).
  my $first_frame = 0;
  if ($ims[0]->tags(name => "apng_hidden")) {
    ++$first_frame;
  }
  my $cwidth = $ims[0]->getwidth;
  my $cheight = $ims[0]->getheight;
  for my $frame (0 .. $#ims) {
    my $im = $ims[$frame];
    my $xoff = $im->tags(name => "apng_xoffset") || 0;
    my $yoff = $im->tags(name => "apng_yoffset") || 0;
    if ($xoff < 0) {
      Imager->_set_error("APNG: apng_xoffset must be non-negative for page $frame");
      return;
    }
    if ($yoff < 0) {
      Imager->_set_error("APNG: apng_yoffset must be non-negative for page $frame");
      return;
    }
    my $fwidth = $im->getwidth;
    my $fheight = $im->getheight;
    if ($xoff + $fwidth > $cwidth || $yoff + $fheight > $cheight) {
      Imager->_set_error("APNG: Page $frame (${fwidth}x${fheight}\@${xoff}x$yoff) is outside the canvas defined by page $first_frame (${cwidth}x$cheight)");
      return;
    }
  }

  my @workims;
  my $ihdr;
  my $seq = 0;
  for my $frame (0 .. $#ims) {
    my $im = $ims[$frame];
    my $orig = $im;

    # convert each frame to a common form
    # paletted are already in common form
    unless ($type eq 'paletted') {
      if ($bits > 8 && $im->bits == 8) {
        $im = $im->to_rgb16;
      }
      elsif ($im->type eq "paletted") {
        $im = $im->to_rgb8;
      }
      if ($im->colorchannels != $chans) {
        $im = $im->convert(preset => "rgb");
      }
      if ($need_alpha && !$im->alphachannel) {
        $im = $im->convert(preset => "addalpha");
      }
    }
    my $dio = Imager::IO->new_bufchain;
    Imager::File::PNG->write($im, $dio, %$opts)
      or return;
    my $data = Imager::io_slurp($dio);
    undef $dio;
    my $rio = Imager::IO->new_buffer($data);
    my $dparsed = _parse_apng_parts($rio, 0);
    undef $rio;
    unless ($dparsed) {
      Imager->_set_error("APNG: Failed to parse temp PNG for frame $frame");
      return;
    }
    my $writeme;
    if ($frame == 0) {
      $ihdr = _make_ihdr(%{$dparsed->{ihdr}}, w => $im->getwidth, h => $im->getheight);
      $writeme = join "", $png_header, $ihdr, @{$dparsed->{headers}};
      my $num_plays = $orig->tags(name => "apng_num_plays") || 0;
      $writeme .= _make_actl(scalar(@ims) - $first_frame, $num_plays);
      if ($first_frame == 0) {
        my $fctl = _make_fctl($seq++, $orig, $frame)
          or return;
        $writeme .= $fctl;
      }
      $writeme .= join "", @{$dparsed->{frames}[0]{idat}};
    }
    else {
      # validate that we're making the same type of image
      my $myihdr = _make_ihdr(%{$dparsed->{ihdr}}, w => $ims[0]->getwidth, h => $ims[0]->getheight);
      if ($ihdr ne $myihdr) {
        Imager->_set_error("APNG: Internal error: IHDR mismatch "
                           . unpack("H*", $ihdr) . " vs " . unpack("H*", $myihdr));
        return;
      }
      my $fctl = _make_fctl($seq++, $orig, $frame)
        or return;
      $writeme .= $fctl;
      for my $idat (@{$dparsed->{frames}[0]{idat_payloads}}) {
        $writeme .= _make_fdat($seq++, $idat);
      }
    }
    if ($io->write($writeme) != length $writeme) {
      Imager->_set_error("APNG: Write failed: $!");
      return;
    }
  }
  my $iend = _make_chunk("IEND", "");
  if ($io->write($iend) != length $iend) {
    Imager->_set_error("APNG: Write failed: $!");
    return;
  }
  if ($io->close) {
    Imager->_set_error("APNG: Close failed: $!");
    return;
  }

  return 1;
}

#unsigned long crc_table[256];
my @crc_table;

#/* Flag: has the table been computed? Initially false. */
#   int crc_table_computed = 0;

#   /* Make the table for a fast CRC. */
#   void make_crc_table(void)
#   {
sub _make_crc_table {
#     unsigned long c;
#     int n, k;
#
#     for (n = 0; n < 256; n++) {
  for my $n (0 .. 255) {
#       c = (unsigned long) n;
    my $c = $n;
#       for (k = 0; k < 8; k++) {
    for my $k (0 .. 7) {
#         if (c & 1)
#           c = 0xedb88320L ^ (c >> 1);
#         else
#           c = c >> 1;
      if ($c & 1) {
	$c = 0xedb88320 ^ ($c >> 1);
      }
      else {
	$c = $c >> 1;
      }
#   }
    }
#       crc_table[n] = c;
    $crc_table[$n] = $c;
#     }
  }
#     crc_table_computed = 1;
#   }
}

# /* Update a running CRC with the bytes buf[0..len-1]--the CRC
#    should be initialized to all 1's, and the transmitted value
#    is the 1's complement of the final running CRC (see the
#    crc() routine below). */

# unsigned long update_crc(unsigned long crc, unsigned char *buf,
#                          int len)
#   {
sub _update_crc {
  my ($crc, $data) = @_;
#     unsigned long c = crc;
#     int n;
   
#     for (n = 0; n < len; n++) {
#       c = crc_table[(c ^ buf[n]) & 0xff] ^ (c >> 8);
#     }
  for my $code (unpack("C*", $data)) {
    $crc = $crc_table[($crc ^ $code) & 0xFF] ^ ($crc >> 8);
  }
#     return c;
#   }
  return $crc;
}
   
#   /* Return the CRC of the bytes buf[0..len-1]. */
#   unsigned long crc(unsigned char *buf, int len)
#   {
#     return update_crc(0xffffffffL, buf, len) ^ 0xffffffffL;
#   }

sub _crc {
  my $data = shift;

  return _update_crc(0xFFFFFFFF, $data) ^ 0xFFFFFFFF;
}

sub _read_chunk {
  my ($io) = @_;

  my $rlen;
  unless ($io->read($rlen, 4) == 4) {
    Imager->_set_error("APNG: Cannot read chunk length");
    return;
  }
  my $len = unpack("N", $rlen);
  my $type;
  unless ($io->read($type, 4) == 4){
    Imager->_set_error("APNG: Cannot read chunk type");
    return;
  }
  my $payload = "";
  if ($len) {
    unless ($io->read($payload, $len) == $len) {
      Imager->_set_error("Cannot read payload");
      return;
    }
  }
  my $crc;
  unless ($io->read($crc, 4) == 4) {
    Imager->_set_error("APNG: Cannot read CRC");
    return;
  }

  return ( $len + 12, $rlen . $type . $payload . $crc, $len, $type, $payload, $crc );
}

sub _parse_apng_parts {
  my ($io, $strict) = @_;

  my $head;
  unless($io->read($head, 8) == 8 && $head eq $png_header) {
    Imager->_set_error("Invalid PNG header");
    return;
  }
  my @frames;
  my $ihdr;
  my @headers;
  my $end;
  my $actl;
  my $sequence = -1;
  my $frame = -1;
  while (my ($dlen, $data, $len, $type, $payload, $crc) = _read_chunk($io)) {
    if ($strict) {
      my $ncrc = unpack("N", $crc);
      my $ccrc = _crc($type . $payload);
      if ($ncrc != $ccrc) {
        Imager->_set_error(sprintf("APNG: CRC mismatch for $type chunk %#x vs %#x (strict)",
                                   $ncrc, $ccrc));
        return;
      }
    }
    if ($type eq 'IHDR') {
      my ($w, $h, $d, $ct, $comp, $filter, $inter) =
        unpack("NNCCCCC", $payload);
      $ihdr =
        {
          w => $w,
          h => $h,
          d => $d,
          type => $ct,
          comp => $comp,
          filter => $filter,
          interlace => $inter,
          data => $data,
         };
    }
    # chunks we need to duplicate from image to image
    elsif ($type =~ /\A(PLTE|tRNS|sRGB|cHRM|gAMA|iCCP|sBIT|pHYs|tIME)\z/) {
      push @headers, $data;
    }
    elsif ($type eq 'IEND') {
      $end = $data;
    }
    elsif ($type eq 'acTL') {
      unless ($len == 8) {
        Imager->_set_error("APNG: Invalid aCTL chunk");
        return;
      }
      my ($num_frames, $num_plays) = unpack("NN", $payload);
      $actl = { frames => $num_frames, plays => $num_plays };
    }
    elsif ($type eq 'fcTL') {
      ++$frame;
      my ($seq, $width, $height, $xoff, $yoff, $delay_num, $delay_den, $dispose_op, $blend_op)
        = unpack("NNNNNnnCC", $payload);
      if ($frames[$frame]{fctl}) {
        Imager->_set_error("APNG: Duplicate fcTL chunk for frame $seq");
        return;
      }
      if ($strict && $seq != $sequence) {
        Imager->_set_error("APNG: out of sequence fcTL chunk, got $seq, expected ".
                           ($sequence+1) . " (strict)");
        return;
      }
      $frames[$frame]{fctl} =
        {
          frame => $frame,
          sequence => $seq,
          width => $width,
          height => $height,
          xoff => $xoff,
          yoff => $yoff,
          delay_num => $delay_num,
          delay_den => $delay_den,
          dispose => $dispose_op,
          blend => $blend_op,
        };
      $sequence = $seq;
    }
    elsif ($type eq 'IDAT') {
      $frame = 0;
      push @{$frames[$frame]{idat}}, $data;
      push @{$frames[$frame]{idat_payloads}}, $payload;
    }
    elsif ($type eq 'fdAT') {
      my $seq = unpack("N", $payload);
      if ($strict && $seq != $sequence+1) {
        Imager->_set_error("APNG: invalid fdAT sequence got $seq, expected $sequence (strict)");
        return;
      }
      ++$sequence;
      # we need to rebuild the IDAT from scratch anyway
      push @{$frames[$frame]{fdat}}, substr($payload, 4);
    }
    # what to do about text chunks?

    last if $type eq 'IEND';
  }
  return +{
    ihdr => $ihdr,
    headers => \@headers,
    end => $end,
    actl => $actl,
    frames => \@frames,
  };
}

sub _from_idat {
  my ($parsed) = @_;

  my $data = join "", $png_header,
    $parsed->{ihdr}{data},
    @{$parsed->{headers}},
    @{$parsed->{frames}[0]{idat}},
    $parsed->{end};
  my $im = _read_png_data($data, 0)
    or return;

  return $im;
}

sub _make_chunk {
  my ($type, $payload) = @_;

  my $base = $type . $payload;
  my $sizeb = pack("N", length $payload);
  my $crc = _crc($type . $payload);

  return $sizeb . $type . $payload . pack("N", $crc);
}

sub _make_idat {
  my ($payload) = @_;

  return _make_chunk("IDAT", $payload);
}

sub _make_ihdr {
  my (%args) = @_;

  return _make_chunk("IHDR", pack("NNCCCCC", @args{qw/w h d type comp filter interlace/}));
}

sub _from_fdat {
  my ($parsed, $frame) = @_;

  my $fctl = $parsed->{frames}[$frame]{fctl};
  unless ($parsed->{frames}[$frame]{fdat}) {
    Imager->_set_error("APNG: No fdAT found for frame $frame");
    return;
  }
  my $data = join "", $png_header,
    _make_ihdr(%{$parsed->{ihdr}}, w => $fctl->{width}, h => $fctl->{height}),
    @{$parsed->{headers}},
    ( map { _make_idat($_) } @{$parsed->{frames}[$frame]{fdat}} ),
    $parsed->{end};

  my $im = _read_png_data($data, $frame)
    or return;

  return $im;
}

sub _from_frame {
  my ($parsed, $frame) = @_;

  my $im;
  if ($frame == 0 && $parsed->{frames}[0]{idat}) {
    $im = _from_idat($parsed)
      or return;
  }
  else {
    $im = _from_fdat($parsed, $frame)
      or return;
  }
  my $fctl = $parsed->{frames}[$frame]{fctl};
  if ($fctl) {
    $im->settag(name => "apng_hidden", value => 0);
    $im->settag(name => "apng_xoffset", value => $fctl->{xoff});
    $im->settag(name => "apng_yoffset", value => $fctl->{yoff});
    $im->settag(name => "apng_delay_num", value => $fctl->{delay_num});
    $im->settag(name => "apng_delay_den", value => $fctl->{delay_den});
    $im->settag(name => "apng_delay", value => sprintf("%.4g", $fctl->{delay_num} / ($fctl->{delay_den} || 100)));
    $im->settag(name => "apng_dispose", value => $fctl->{dispose});
    $im->settag(name => "apng_blend", value => $fctl->{blend});
  }
  else {
    $im->settag(name => "apng_hidden", value => 1);
  }
  $im->settag(name => "apng_num_plays", value => $parsed->{actl}{plays});

  return $im;
}

sub read_apng {
  my ($im, $io, %hsh) = @_;

  my $strict = $hsh{apng_strict} || 0;

  my $page = $hsh{page};
  defined $page or $page = 0;

  my $parsed = _parse_apng_parts($io, $strict);
  unless ($parsed) {
    $im->_set_error(Imager->errstr);
    return;
  }

  if ($page < 0 || $page > $#{$parsed->{frames}}) {
    my $im2 = _from_frame($parsed, $page);
    unless ($im2) {
      $im->_set_error(Imager->errstr);
      return;
    }
    $im->{IMG} = $im2->{IMG};
  }
  else {
    $im->_set_error("APNG: page out of range");
    return;
  }

  return $im;
}

sub read_multi_apng {
  my ($io, %hsh) = @_;

  my $strict = $hsh{apng_strict} || 0;

  my $parsed = _parse_apng_parts($io, $strict)
    or return;

  my @imgs;

  for my $frame (0 .. $#{$parsed->{frames}}) {
    my $im = _from_frame($parsed, $frame)
      or return;
    push @imgs, $im;
  }

  return @imgs;
}

_make_crc_table();

Imager->register_reader
  (
   type => 'apng',
   single => \&read_apng,
   multiple => \&read_multi_apng,
  );

# override the PNG reader
Imager->register_reader
  (
   type => 'png',
   single => \&read_apng,
   multiple => \&read_multi_apng,
  );

Imager->register_writer
  (
   type=>'apng',
   single => \&write_apng,
   multiple => \&write_multi_apng,
  );

1;


__END__

=head1 NAME

Imager::File::APNG - read and write APNG image files

=head1 SYNOPSIS

  use Imager;
  use Imager::File::APNG;

  my @frames = Imager->read_multi(file => "foo.png", type => "apng)
    or die Imager->errstr;

  Imager->write_multi({
      file => "foo.png",
      type => "apng"
      apng_delay => 1/60,
    }, @frames)
    or die Imager->errstr;

=head1 DESCRIPTION

Implements APNG support for Imager.

To write an APNG image the type parameter needs to be explicitly supplied.

=head1 LIMITATIONS

=over

=item *

Due to the limitations of C<APNG> all images are written as the same
type, e.g. all RGBA, or all grayscale, or all paletted with the same
palette.  C<Imager::File::APNG> will upgrade all supplied images to
the greatest common layout.  If all images are paletted, but do not
have exactly the same palette the file will use direct color.

=item *

Single images are written without animation chunks.

=back

=head2 Image tags

The C<i_format> tag is deliberately set to C<png> on reading an APNG
image.

Tags common to reading and writing:

=over

=item *

C<apng_hidden> - set on all images when reading, only has an effect on
the first image when writing.  If non-zero for the first image it will
be hidden from the animation.

=item *

C<apng_num_plays> - set on all images when reading, only used from the
first image when writing.  Specifies the number of time to repeat the
animation.  If zero repeat forever.  Default: 0.

=item *

C<apng_xoffset>, C<apng_yoffset> - the position of the frame within
the canvas, which is defined by the first image.  The frame as
positioned by these offsets must be contained within the canvas
dimensions.  Both default to 0.

=item *

C<apng_dispose> - for each animation frame, one of 0, 1, or 2, or
alternatively C<none>, C<background> or C<previous> when writing.
Default: 0.

=item *

C<apng_blend> - for each animation frame, one of 0 or 1, or
alternatively C<source> or C<over> when writing.  Default: 0.

=item *

C<apng_delay> - for each animation frame, the delay in seconds,
including fractional seconds, that the frame is displayed for.  This
overrides C<apng_delay_num> and C<apng_delay_den>.  This is currently
converted to a fraction out of 1000 when written to the file.

=item *

C<apng_delay_num>, C<apng_delay_den> - for each animation frame, the
delay in seconds, including fractional seconds, that the frame is
displayed for, as a rational number C< apng_delay_num / apng_delay_den
>.  Default: 1/60.  Ignored if C<apng_delay> is set.  All three tags
are set on read.

=back

=head1 TODO

Optionally optimize frame generation from the source images, e.g.,
trimming common pixels between the canvas at that point.

Optionally generate a common palette across all the frames.  This
should work with the above.

Provide a tool to convert optimized frames read from a file into full
frames.

=head1 AUTHOR

Tony Cook <tonyc@cpan.org>

=head1 SEE ALSO

L<Imager>, L<Imager::Files>.

=cut
