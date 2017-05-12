package Image::PNG::Rewriter;

use 5.010000;
use strict;
use warnings;
use Compress::Zlib qw();
use Carp;
use POSIX qw/ceil/;

our $VERSION = '0.9';
our $PNG_MAGIC = "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A";

require XSLoader;
XSLoader::load('Image::PNG::Rewriter', $VERSION);

use constant CHANNELS => {
  0 => 1,
  2 => 3,
  3 => 1,
  4 => 2,
  6 => 4,
};

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  my %o = @_;
  my $h = $o{handle};

  die "No 'handle' specified" unless $h;

  $o{zlib} //= sub {
    my $data = shift;
    my ($d, $status0) = Compress::Zlib::deflateInit();
    die unless $status0 == Compress::Zlib::Z_OK;
    my ($out1, $status1) = $d->deflate($data);
    die unless $status1 == Compress::Zlib::Z_OK;
    my ($out2, $status2) = $d->flush();
    die unless $status2 == Compress::Zlib::Z_OK;
    return $out1 . $out2;
  };

  $self->{_zlib} = $o{zlib};

  read($h, my $magic, 8) == 8 or die;

  die "Not a PNG image" unless $magic eq $PNG_MAGIC;

  $self->{_chunks} = [];

  while (!eof($h)) {
    # [size] [type] [data] [checksum]
    read($h, my $raw, 8) == 8 or die;
    my ($length, $type) = unpack 'Na4', $raw;
    read($h, my $data, $length) == $length or die;
    read($h, my $crc_raw, 4) == 4 or die;
    my $crc = unpack 'N', $crc_raw;
    push @{ $self->{_chunks} }, {
      type => $type,
      size => $length,
      data => $data,
      crc32 => $crc,
    };
  }

  # get the first IHDR chunk; only one is allowed
  my ($ihdr) = grep { $_->{type} eq 'IHDR' } @{ $self->{_chunks} };
  die unless $ihdr;

  my @ihdr_values = unpack 'NNccccc', $ihdr->{data};
  die unless @ihdr_values == 7;

  ($self->{_width},
   $self->{_height},
   $self->{_depth},
   $self->{_color},
   $self->{_comp},
   $self->{_filter},
   $self->{_interlace}) = @ihdr_values;

  die unless $self->{_width};
  die unless $self->{_height};

  # TODO: validate depth/type restrictions?

  die unless $self->{_comp} == 0;
  die unless $self->{_filter} == 0;

  confess "Interlaced images are not supported"
    if $self->{_interlace};

  $self->{_channels} = (CHANNELS)->{ $self->{_color} };

  die unless defined $self->{_channels};

  # PNGs can have many IDAT chunks
  my $coalesced = join '', map { $_->{data} }
    grep { $_->{type} eq 'IDAT' } @{ $self->{_chunks} };

  # One IEND chunk is required
  die unless 1 == grep { $_->{type} eq 'IEND' }
    @{ $self->{_chunks} };

  my ($i, $status0) = Compress::Zlib::inflateInit;
  die unless $status0 == Compress::Zlib::Z_OK;
  my ($inflated, $status1) = $i->inflate("$coalesced");
  die $status1 unless $status1 == Compress::Zlib::Z_STREAM_END;

  $self->{_inflated} = $inflated;
  $self->{_deflated} = $coalesced;

  $self->{_new_deflated} = "$coalesced";
  $self->{_new_inflated} = "$inflated";

  my $expected_bytes = $self->{_height} *
    ceil(($self->{_width} * $self->{_channels} * $self->{_depth} + 8) / 8);

  my $actual_bytes = length $self->{_inflated};
  die unless $expected_bytes == $actual_bytes;

  $self->{_scanline_width} = $expected_bytes / $self->{_height};
  $self->{_scanline_delta} = $self->{_channels} * ceil($self->{_depth} / 8);

  # Destructive operation needs a copy
  $self->{_unfiltered} = "$inflated";
  _unfilter($self->{_unfiltered}, $self->{_height}, $self->{_scanline_delta}, $self->{_scanline_width});

  $self;
}

sub refilter {
  my $self = shift;
  my @filters = @_;
  die unless @filters == $self->height;

  $self->{_new_inflated} = $self->{_unfiltered} . "";
  my $filter = join '', map chr, @filters;

  _filter($self->{_unfiltered}, $self->{_new_inflated},
    $filter, $self->{_height}, $self->{_scanline_delta},
    $self->{_scanline_width});

  $self->{_new_filters} = \@filters;
  $self->{_new_deflated} = $self->{_zlib}->($self->{_new_inflated});
  return $self->{_new_deflated}, $self->{_new_inflated};
}

sub as_png {
  my $self = shift;
  my @other_chunks =
    grep { $_->{type} ne 'IDAT' } $self->original_chunks;
  my $data = $self->{_new_deflated};

  my $idat = { type => 'IDAT', data => $data,
    crc32 => Compress::Zlib::crc32("IDAT$data") };

  my @chunks = map {
    pack('Na4', length $_->{data}, $_->{type})
      . $_->{data} . pack('N', $_->{crc32})
  } map {
    $_->{type} eq 'IEND' ? ($idat, $_) : $_
  } @other_chunks;

  return $PNG_MAGIC . join '', @chunks;
}

sub original_filters {
  my $self = shift;
  map { ord(substr $self->{_inflated},
    $_ * $self->{_scanline_width}, 1) }
    0 .. $self->{_height} - 1;
}

sub original_chunks { @{ $_[0]->{_chunks} } }
sub original_inflated { $_[0]->{_inflated} }
sub original_deflated { $_[0]->{_deflated} }
sub width { $_[0]->{_width} }
sub height { $_[0]->{_height} }
sub color_mode { $_[0]->{_color} }
sub depth { $_[0]->{_depth} }

sub scanline_width { $_[0]->{_scanline_width} }
sub scanline_delta { $_[0]->{_scanline_delta} }

1;

__END__

=head1 NAME

Image::PNG::Rewriter - Rewrite and Refilter PNG images

=head1 SYNOPSIS

  use Image::PNG::Rewriter;

  open my $h, '<', '...';
  binmode $h;
  my $re = Image::PNG::Rewriter->new(handle => $h, zlib => \&zlib);

  my $width = $re->width;
  my $height = $re->height;
  my $mode = $re->color_mode;
  my $depth = $re->depth;
  my @chunks = $re->original_chunks;
  my $orig_deflated = $re->original_deflated;
  my $orig_inflated = $re->original_inflated;
  my @filters = $re->original_filters;
  my $new_deflated = $re->refilter(@filters);
  my $new_png = $re->as_png;

=head1 DESCRIPTION

This module offers low-level access to PNG image data. The primary
purpose is to support rewriting IDAT chunks which hold the main
image data. IDAT chunks can be coalesced, re-compressed, and the
filters applied to each scanline in the image to support compression
can be retrieved and changed. Modified data can be serialized to a
new PNG image, leaving unmodified data intact.

=head1 METHODS

=over 2

=item my $rw = Image::PNG::Rewriter->new(%options)

Constructs a new Image::PNG::Rewriter object. The possible options
are a required C<handle> parameter which must be an opened handle
that can be C<read> from; it is expected that the handle is in binary
mode. Note that C<open> supports turning strings into a handle.

The other parameter is C<zlib> which must be a reference to a
subroutine that takes some byte string and returns a deflated
representation of it that follows the RFC 1950 "zlib" format
(neither a raw RFC 1951 stream nor a RFC 1952 "gzip" stream are
allowed). The default value uses L<Compress::Zlib> with default
settings. The routine must not modify its input.

=item $rw->width

Returns the width specified in the IHDR chunk.

=item $rw->height

Returns the height specified in the IHDR chunk.

=item $rw->depth

Returns the depth specified in the IHDR chunk.

=item $rw->color_mode

Returns the color mode specified in the IHDR chunk.

=item $re->original_chunks

Returns a list of hash references containing the keys C<type>,
C<size>, C<data>, and C<crc32>, containing, respectively, the
type of the chunk, the size of the data in the chunk in bytes,
the raw data contained in the chunk, and the CRC32 checksum in
the original chunk.

=item $re->original_deflated

The raw RFC 1950-encoded coalesced data of all IDAT chunks in
the image.

=item $re->original_inflated

As $re->original_deflated but inflated.

=item $re->original_filters

A list containing the filters applied to the scanlines in the
image. The length is equivalent to the height of the image.

=item $re->as_png

Returns a byte string representing the original image except
that all original IDAT chunks are replaced by a single IDAT
chunk with any changes that may have been applied to the data.

=item my ($deflated, $inflated) = $re->refilter(1,2,3,...)

Re-encodes the image data by removing the filter that had been
applied to the input and applies the new filters. The number of
filters must be equal to the number of scanlines in the image
(the image's height). Only supports filters 0 through 4. Returns
a list containing the deflated and inflated date after applying
the new filters. The values should not be modified.

=item $re->scanline_width

Returns the number of bytes contained within each scanline. The
size of the raw image data is this value times the image's height.
Note that each scanline starts with a byte that identifies the
filter that has been applied to it.

=item $re->scanline_delta

Returns the number of bytes between two "corresponding" values on
a scanline. The number of bytes per pixel or 1 if pixels occupy
less space than a byte.

=back

=head1 SEE ALSO

=over 2

=item L<http://www.w3.org/TR/PNG/>

=item L<Compress::Deflate7>

=item L<Compress::Zlib>

=back

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2011 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
