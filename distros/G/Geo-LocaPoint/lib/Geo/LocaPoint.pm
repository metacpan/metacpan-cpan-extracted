package Geo::LocaPoint;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.4');
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT      = qw(latlng2locapoint locapoint2latlng);
@EXPORT_OK   = qw(latlng2locaporterbase locaporterbase2latlng);

use Math::Round qw(nhimult);

my @devider = (1757600,67600,6760,260,10,1);

# Internal methods

sub int2code {
    my ($value,$count,$precision,$islocapo) = @_;
    my $this = int($value / $devider[$count]);
    my $low = $value % $devider[$count];
    $this = pack "C", 65 + $this if (!$islocapo || ($count % 3 != 2)); 
    if ($count < $precision - 1) {
        $this .= int2code($low,$count+1,$precision,$islocapo);
    }
    return $this;
}

sub code2int {
    my ($value,$count) = @_;
    my $this = substr($value,0,1);
    my $low = substr($value,1);
    $this = unpack("C",$this) - 65 if ($this =~ /^[A-Z]$/);
    $this *= $devider[$count];
    if ($low ne '') {
        $this += code2int($low,$count+1);
    }
    return $this;
}

sub latlng2code {
    my ($lat,$lng,$precision,$islocapo) = @_;

    $lat = int(($lat + 90) * 2284880 / 9);
    $lng = int(($lng + 180) *1142440 / 9);

    foreach ($lat,$lng) {
        while (($_ < 0) || ($_ > 45697599)) {
            $_ = $_ < 0 ? $_ + 45697600 : $_ - 45697600;
        }    
        $_ = int2code($_,0,$precision,$islocapo);
    }
    
    return ($lat,$lng);
}

sub code2latlng {
    my ($lat,$lng) = @_;

    foreach ($lat,$lng) {    
        $_ = code2int($_,0);
    }

    $lat = nhimult(.000001,$lat * 9 / 2284880 - 90);
    $lng = nhimult(.000001,$lng * 9 / 1142440 - 180);

    return ($lat,$lng);
}

# Export methods

sub latlng2locapoint {
    my ($lat,$lng) = @_;

    ($lat,$lng) = latlng2code($lat,$lng,6,1);
  
    my $locapo = sprintf("%s.%s.%s.%s",substr($lat,0,3),substr($lng,0,3),substr($lat,3,3),substr($lng,3,3));
    return $locapo;
}

sub locapoint2latlng {
    my $locapo = shift;
  
    $locapo =~ /^([A-Z][A-Z][0-9])\.([A-Z][A-Z][0-9])\.([A-Z][A-Z][0-9])\.([A-Z][A-Z][0-9])$/ or croak "Argument $locapo is not locapoint!!";
    my $lat = $1.$3;
    my $lng = $2.$4;

    return code2latlng($lat,$lng);
}

sub latlng2locaporterbase {
    my ($lat,$lng,$precision) = @_;

    ($lat,$lng) = latlng2code($lat,$lng,$precision);
    $lng        = lc($lng);

    return wantarray ? ($lat, $lng) : $lat.$lng;
}

sub locaporterbase2latlng {
    my ($lat,$lng) = @_;

    unless (defined($lng)) {
        ($lat,$lng) = $lat =~ /^([A-Z]+)([a-z]+)$/;
    }

    $lng = uc($lng);

    return code2latlng($lat,$lng);
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Geo::LocaPoint - Simple encoder/decoder of LocaPoint


=head1 VERSION

This document describes Geo::LocaPoint version 0.0.1


=head1 SYNOPSIS

  use Geo::LocaPoint;
  
  # Latitude/longitude (WGS84/degree, plus as E and N, minus as W and S)
  my ($lat,$lng) = (35.000,135.000);
  
  # Encode latitude/longitude to LocaPoint
  my $locapo = latlng2locapoint($lat,$lng);
  
  # Decode LocaPoint to latitude/longitude
  ($lat,$lng) = locapoint2latlng($locapo);


=head1 EXPORT METHODS

=over

=item * latlng2locapoint

=item * locapoint2latlng

=back


=head1 INTERNAL METHODS

=over

=item * code2int

=item * code2latlng

=item * int2code

=item * latlng2code

=item * latlng2locapoint

=item * latlng2locaporterbase

=item * locapoint2latlng

=item * locaporterbase2latlng
 
=back


=head1 DEPENDENCIES

Math::Round


=head1 SEE ALSO

Locapoint official site: http://www.locapoint.com/

Specification of Locapoint: http://www.locapoint.com/en/spec.htm


=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>. All rights reserved.

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
