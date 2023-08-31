package Imager::zxing;
use strict;
use warnings;
use Imager;

our $VERSION;
BEGIN {
  $VERSION = "1.000";
  use XSLoader;
  XSLoader::load("Imager::zxing" => $VERSION);
}

1;

=head1 NAME

Imager::zxing - decode barcodes from Imager images using libzxing

=head1 SYNOPSIS

  use Imager::zxing;
  my $decoder = Imager::zxing::Decoder->new;
  # list accepted formats separated by '|'
  print $decoder->formats;
  # list available formats
  print $decoder->avail_formats
  # set the accepted formats
  $decoder->set_formats("DataMatrix|QRCode")
    or die $decoder->error;

  # decode any barcodes
  my $im = Imager->new(file => "somefile.png");
  my @results = $decoder->decoder($im);

  for my $result (@results) {
    print $result->text, "\n";
  }

=head1 DESCRIPTION

A primitive wrapper around zxing-cpp

Currently only supports decoding and doesn't expose much of the
interface.

To use this:

=over

=item 1.

Create a decoder object:

  use Imager::zxing;
  my $decoder = Imager::zxing::Decoder->new;

=item 2.

Configure it if needed, most likely by setting the accepted barcode
encodings:

  $decoder->set_formats("DataMatrix|QRCode");

=item 3.

Load an image using Imager:

  my $img = Imager->new(file => "somename.png")
    or die "Cannot load image ", Imager->errstr;

The available file formats depends on the libraries Imager was built
with.

=item 4.

Decode the barcode:

  my @results = $decoder->decode($img)
    or die "No barcodes found";

=item 5.

Process the results:

  for my $r (@results) {
    print $r->format, ": ", $r->text, "\n";
  }

=back

=head1 Imager::zxing::Decoder class methods

=over

=item * new

  my $decoder = Imager::zxing::Decoder->new;

Create a new decoder object, does not accept any parameters.

Default is to process all available barcode formats.

=item * avail_formats

  my @formats = Imager::zxing::Decoder->avail_formats

Returns a list of the barcode formats that are decodable.

=back

=head1 Decoder object methods

Create a decoder with:

  my $decoder = Imager::zxing::Decoder->new;

=head2 Decoding

=over

=item * decode(image)

Attempts to decode barcodes from the supplied Imager image object.

Returns a list of result objects, or an empty list if none are found.

  my $img = Imager->new(file => "somefile.png") or die Imager->errstr;
  my @results = $decoder->decode($img);

=back

=head2 Settings

=over

=item * formats()

Returns the formats the decoder accepts as a C<|> separated string.

  print $decoder->formats
  # default output:
  # Aztec|Codabar|Code39|Code93|Code128|DataBar|DataBarExpanded|DataMatrix|EAN-8|EAN-13|ITF|MaxiCode|PDF417|QRCode|UPC-A|UPC-E|MicroQRCode

=item * set_formats(formats)

Sets the barcode formats that the decoder will decode, as a space,
C<|> or comma separated string.

  $decoder->set_formats("DataMatrix|QRCode");

=item * set_return_errors($bool)

Set to non-zero to include results with soft errors such as checksum
errors.

  $decoder->set_return_errors(1);

=item * set_pure($bool)

Set to non-zero to only accept results where the image is an aligned
image where the image is only the barcode.

Note: this appears to be non-functional in my testing, this accepted a
rotated image.

  $decoder->set_pure(1);

=back

=head1 Result object methods

Result objects are returned by the decoder decode() method:

  my @results = $decoder->decode($image);

=over

=item * text()

Returns the decoded text.

  my $text = $result->text;

=item * is_valid()

True if the result represents a valid decoded barcode.

=item * is_mirrored()

True if the result is from a mirrored barcode.

=item * is_inverted()

True if the barcode image has inverted dark/light.  Requires zxing
2.0.0 to be valid.

=item * format()

The format of the decoded barcode.

=item * position()

The co-ordinates of the top left, top right, bottom left and bottom
right points of the decoded barcode in the supplied image, as a list.

=item * orientation()

The rotation of the barcode image in degrees.

=back

=head1 LICENSE

Imager::zxing is licensed under the same terms as perl itself.

=cut
