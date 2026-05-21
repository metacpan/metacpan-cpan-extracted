package Imager::File::HEIF::Encoder;
use strict;
use warnings;

our $VERSION = 1.000;

sub id {
    $_[0]{id};
}

sub name {
    $_[0]{name};
}

sub compression {
    $_[0]{compression};
}

sub supports_lossy_compression {
    $_[0]{supports_lossy_compression};
}

sub supports_lossless_compression {
    $_[0]{supports_lossless_compression};
}

sub parameters {
    @{$_[0]{parameters}};
}

1;

=head1 NAME

Imager::File::HEIF::Encoder - information about a libheif encoder

=head1 SYNOPSIS

  use Imager::File::HEIF;
  my @encoders = Imager::File::HEIF->encoders;
  for my $encoder (@encoders) {
     print "Id: ", $encoder->id, "\n";
     print "Name: ", $encoder->name, "\n";
     print "Compression: ", $encoder->compression, "\n";
     print "CanLossy: ", $encoder->supports_lossy_compression, "\n";
     print "CanLossless: ", $encoder->supports_lossless_compression, "\n";
     for my $param ($encoder->parameters) {
          # see Imager::File::HEIF::Encoder::Parameter
          ...
     }
  }

=head1 DESCRIPTION

This is the object type that the Imager::File::HEIF encoders method
returns.

=head1 METHODS

=over

=item id

The identifier for this encoder, this can be supplied as
C<heif_encoder> when writing HEIF images.

=item name

A descriptive name for the encoder.  Typically includes the name and
version of the underlying library.

=item compression

The compression supported by this encoder, this will match one of the
names returned by the Imager::File::HEIF compression_names() method.

=item supports_lossy_compression

Returns true if the encoder supports lossy compression.

=item supports_lossless_compression

Returns true if the encoder supports lossless compression.

=item parameters

Returns a list of L<Imager::File::HEIF::Encoder::Parameter> objects
representing the parameters the encoder accepts.

=back

=head1 AUTHOR

Tony Cook <tony@develop-help.com>

=head1 SEE ALSO

L<Imager::File::HEIF>, L<Imager>, L<Imager::Files>.

=cut

