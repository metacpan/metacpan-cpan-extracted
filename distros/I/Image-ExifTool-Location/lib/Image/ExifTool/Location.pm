package Image::ExifTool::Location;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv( '0.0.4' );

sub new {
    croak "Call Image::ExifTool->new() instead of " . __PACKAGE__ . "->new()";
}

# Reopen Image::ExifTool

package Image::ExifTool;

use warnings;
use strict;
use Carp;
use Image::ExifTool;

my @LOC_TAGS = qw(
  GPSLatitude     GPSLatitudeRef
  GPSLongitude    GPSLongitudeRef
);

my @ELE_TAGS = qw(
  GPSAltitude     GPSAltitudeRef
);

my @GROUP = ( Group => 'GPS' );

sub _has_all {
    my $self = shift;
    for ( @_ ) {
        return unless defined( $self->GetValue( $_ ) );
    }
    return 1;
}

sub HasLocation {
    my $self = shift;
    return $self->_has_all( @LOC_TAGS );
}

sub HasElevation {
    my $self = shift;
    return $self->_has_all( @ELE_TAGS );
}

sub _set_latlon {
    my $self = shift;
    my ( $name, $latlon, @sign_flags ) = @_;

    $self->SetNewValue( $name, abs( $latlon ), @GROUP, Type => 'ValueConv' );
    $self->SetNewValue(
        $name . 'Ref',
        $sign_flags[ $latlon < 0 ? 1 : 0 ],
        @GROUP, Type => 'ValueConv'
    );
}

sub SetLocation {
    my $self = shift;
    my ( $lat, $lon ) = @_;

    croak "SetLocation must be called with the latitude and longitude"
      unless defined( $lon );

    $self->_set_latlon( 'GPSLatitude',  $lat, qw(N S) );
    $self->_set_latlon( 'GPSLongitude', $lon, qw(E W) );
}

sub SetElevation {
    my $self = shift;
    my ( $ele ) = @_;

    croak "SetElevation must be called with the elevation in metres"
      unless defined( $ele );

    $self->SetNewValue( 'GPSAltitude', abs( $ele ),
        @GROUP, Type => 'ValueConv' );
    $self->SetNewValue( 'GPSAltitudeRef', $ele < 0 ? '1' : '0',
        @GROUP, Type => 'ValueConv' );
}

sub GetLocation {
    my $self = shift;

    wantarray or croak "GetLocation must be called in a list context";
    return
      map { $self->GetValue( $_, 'ValueConv' ) } qw(GPSLatitude GPSLongitude);
}

sub GetElevation {
    my $self = shift;
    my $v    = $self->GetValue( 'GPSAltitude', 'Raw' );
    my $r    = $self->GetValue( 'GPSAltitudeRef', 'Raw' );

    return unless defined( $v ) && defined( $r );
    return $v * ( $r == 0 ? 1 : -1 );
}

1;
__END__

=head1 NAME

Image::ExifTool::Location - Easy setting, getting of an image's location information

=head1 VERSION

This document describes Image::ExifTool::Location version 0.0.4

=head1 SYNOPSIS

    use Image::ExifTool;
    use Image::ExifTool::Location;

    my $exif = Image::ExifTool->new();

    # Extract info from existing image
    $exif->ExtractInfo($src);
    # Set location
    $exif->SetLocation(54.787515, -2.341355);
    # Set elevation
    $exif->SetElevation(515);
    # Write new image
    $exif->WriteInfo($src, $dst);

=head1 DESCRIPTION

C<Image::ExifTool> is a versatile module for reading and writing EXIF
data in a number of image formats. This module extends its interface
adding methods that simplify the reading and writing of GPS location
information.

Without this module the interface for working with GPS location
information is cryptic. To store latitude and longitude a total of four
EXIF values are used - two to store the latitude and longitude in
degrees, minutes and seconds format and two to store the hemisphere
(north / south, east / west).

This module replaces that cryptic interface with simple calls
(C<GetLocation> and C<SetLocation>) that take care of encoding and
decoding the latitude and longitude values correctly.

=head1 INTERFACE 

The methods this module provides are added directly to
C<Image::ExifTool>'s interface. To use them do something
like this:

    use Image::ExifTool;
    use Image::ExifTool::Location;

    my $exif = Image::ExifTool->new();

    $exif->ExtractInfo($src);
    $exif->SetLocation(54.787515, -2.341355);
    $exif->WriteInfo($src, $dst);

All of the methods described below are implemented in terms of
C<Image::ExifTool>'s C<GetValue> and C<SetNewValue> methods. Read the
documentation for C<Image::ExifTool> for more information.

=over

=item C<HasLocation()>

Returns true if the image contains all of these EXIF tags:

    GPSLatitude     GPSLatitudeRef
    GPSLongitude    GPSLongitudeRef

=item C<HasElevation()>

Returns true if the image contains both of these EXIF tags:

    GPSAltitude     
    GPSAltitudeRef

=item C<SetLocation( $lat, $lon )>

Set the image's GPS location to the specified latitude and longitude.

=item C<SetElevation( $ele )>

Set the image's GPS elevation to the specified height in metres. Use negative
values for locations below sea level.

=item C<GetLocation()>

Return the image's GPS location as a two element list:

    my ($lat, $lon) = $exif->GetLocation();

=item C<GetElevation()>

Return the image's GPS elevation:

    my $ele = $exif->GetElevation();

=back

=head1 DIAGNOSTICS

=over

=item C<< Call Image::ExifTool->new() instead of Image::ExifTool::Location->new() >>

This module adds methods directly to Image::ExifTool. After

    use Image::ExifTool::Location;
    
create a new Image::ExifTool object as normal.

=item C<< SetLocation must be called with the latitude and longitude >>

C<SetLocation> requires latitude and longitude values in decimal degrees.

=item C<< SetElevation must be called with the elevation in metres >>

C<SetElevation> requires the elavation in metres as a signed number.

=item C<< GetLocation must be called in a list context >>

C<GetLocation> returns latitude and longitude as a two element list.

=back

=head1 DEPENDENCIES

    Image::ExifTool
    Geo::Coordinates::DecimalDegrees

=head1 CONFIGURATION AND ENVIRONMENT
  
Image::ExifTool::Location requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-image-exiftool-location@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
