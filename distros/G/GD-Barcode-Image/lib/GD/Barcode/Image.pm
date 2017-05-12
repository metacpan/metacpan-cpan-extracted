package GD::Barcode::Image;
use strict;
use Image::Magick;
use GD::Barcode;
require Exporter;
use vars qw($VERSION @ISA $AUTOLOAD);
@ISA     = qw(Exporter);    # HAS-A GD::Barcode:<Symbology>, no IS-A
$VERSION = 1.03;

#------------------------------------------------------------------------------
# GD::Barcode::Image  extends GD::Barcode functionality.
# GD/Barcode.pm is a package with a single factory-like method named new()
# new() itself creates objects of a specific Symbology - Barcode Type,
# which are derived classes from GD::Barcode
# There are other functions in GD/Barcode.pm such as dumpCode, and even
# plot(), but these are not object methods, and since there is never any
# object created of class GD::Barcode, all are private functions.
#
# GD::Barcode::Image follows the implementation of GD::Barcode - which is
# easiest done by using a member object of GD::Barcode::<Symbology> type,
# and implementing plot_imagick and plot_gd functions.
# It would be possible to use AUTOLOAD and proxy all other methods of
# GD::Barcode::<Symbology> classes, but unless someone points out the need for
# that, leaving it out for now (see example after END in this file)
# And if absolutey needed: callers can look at the GD::Barcode::<Symbology>
# object in this object hash: $oThis->{gd_barcode}
#------------------------------------------------------------------------------
# If these functions need to be merged into GD::Barcode, all that is to
# needed from this file are the two functions: plot_imagick and plot_gd -
# they will work with very minor modifications. The command-line script
# barcodegen should also be carried into GD::Barcode, if this module
# becomes obsolete.
#------------------------------------------------------------------------------
# new() - create an object of this class
# [not a factory method - unlike GD::Barcode]
#------------------------------------------------------------------------------
sub new($$$;$) {
    my $sClass = shift;
    my ($sType) = @_;

    # special check: since Image.pm resides in GD/Barcode, there is
    # the danger that the GD::Barcode->new() function will load/init
    # this module as a Barcode Symbology. To prevent this, check for type.
    if ( grep( /^$sType$/i, 'Image' ) ) {
        $GD::Barcode::errStr = 'Error in new() - Invalid Barcode Type: "Image"';
        return undef;
    }

    my $oThis = {};
    bless $oThis, $sClass;
    my $gdbc = GD::Barcode->new(@_);
    $oThis->{gd_barcode} = $gdbc;
    return $gdbc ? $oThis : undef;
}

#------------------------------------------------------------------------------
# init (for GD::Barcode::Image)
# special check: since Image.pm resides in GD/Barcode, there is
# the danger that the GD::Barcode->new() function will load/init this
# module as a Barcode Symbology, so check for type
#------------------------------------------------------------------------------
sub init() {
    return 'Error in init() - Invalid Barcode Type: "Image"';
}

#------------------------------------------------------------------------------
# plot_imagick: Convert to Image::Magick Object (for GD::Barcode)
# Requires both the GD and Image::Magick modules.
# signature is similar to GD::Barcode::QRcode->plot()
#------------------------------------------------------------------------------
sub plot_imagick($%) {
    my ( $oThis, %hParam ) = @_;

    #Create Image
    my $imNew = undef;
    eval {
        require Image::Magick;

        my ( $gdNew, $png ) = ( undef, undef );

        $gdNew = $oThis->{gd_barcode}->plot(%hParam);
        if ($gdNew) {
            $png   = $gdNew->png();
            $imNew = Image::Magick->new();

            $GD::Barcode::errStr = $imNew->BlobToImage($png);
            $imNew               = undef
              if ($GD::Barcode::errStr);    # on error, free imagick object
        }
    };
    return $imNew;
}

#------------------------------------------------------------------------------
# plot_gd: Convert to GD::Image Object (for GD::Barcode)
# plot_gd created to follow name pattern of "plot_imagick" - plot_<what>
# Requires the GD module.
#------------------------------------------------------------------------------
sub plot_gd($%) {
    my ( $oThis, %hParam ) = @_;
    return $oThis->{gd_barcode}->plot(%hParam);
}

#------------------------------------------------------------------------------

1;

__END__

#------------------------------------------------------------------------------
# proxy methods to the GD::Barcode::<Symbology> object
# functions like barcode(), Text() proxied
sub AUTOLOAD() {
    my $oThis = shift;
    my $gdbc = $oThis->{gd_barcode};
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    $method = $gdbc->can($method);
    return $method ? $gdbc->$method(@_) : undef;
}
#------------------------------------------------------------------------------

=head1 NAME

GD::Barcode::Image - Create Image::Magick object for a barcode

=head1 SYNOPSIS

  use GD::Barcode::Image;

  my $oGdBarIm = GD::Barcode::Image->new( $type, $text, \%rhPrm );
  die "** Error: Barcode $type failed for $text: ${GD::Barcode::errStr}," 
    unless ($oGdBarIm);

  my $oGdIm = $oGdBarIm->plot_imagick( Height => I<pixels>, NoText => I<0 | 1>] );
  die "** Error: Image Conversion Failed: ${GD::Barcode::errStr}," 
    unless ($oGdBarIm);

=head1 DESCRIPTION

This module adds minor extensions in functionality to the
B<GD::Barcode> module.  See the documentation for GD::Barcode and all its
barcode symbology types for additional information on the use of this
module.


=over 4

=item new()

I<$oGdBarIm> = GD::Barcode::Image->new(I<$sType>, I<$sTxt>, I<\%rhPrm>);

Constructor. 
Creates a GD::Barcode::Image object for text I<$sTxt>, for barcode
symbology type I<$sType>. 
Additional parameters can be provided for QRcode type - see
GD::Barcode::QRcode module in the GD::Barcode package.

=item plot_imagick()

I<$oGdIm> = $oGdBarIm->plot_imagick([Height => I<$iHeight>, NoText => I<0 | 1>]);

creates Image::Magick object for the barcode object.
I<$iHeight> is height of the image. If I<NoText> is 1, the image has no text image of I<$sTxt>.
Height and NoText parameters will not apply to the QRcode barcode type.

=item plot_gd()

I<$oGd> = $oGdBarIm->plot_gd([Height => I<$iHeight>, NoText => I<0 | 1>]);

Same as plot_imagick() except that a GD image object is returned.

=item $GD::Barcode::errStr

has error message. This is same error mechanism as in the GD::Barcode
module.

=item barcodegen

This module also includes the command-line script B<barcodegen> that can
be used to create barcode images in various formats: GIF, JPEG, PNG, EPS,
PDF.

=back

=head1 AUTHOR

Avinash Chopde <avinash@aczoom.com> http://www.aczoom.com/

=head1 COPYRIGHT

Copyright (C) 2007 Avinash Chopde <avinash@aczoom.com>  www.aczoom.com

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

C<barcodegen>

C<GD::Barcode>

=cut
