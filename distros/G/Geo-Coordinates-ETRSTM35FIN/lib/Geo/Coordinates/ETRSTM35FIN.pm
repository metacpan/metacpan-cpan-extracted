package Geo::Coordinates::ETRSTM35FIN;

use 5.008006;
use strict;
use warnings;
use Carp;
use Math::Trig;

our $VERSION = '0.01';

sub new {
	my $class = shift;
	
	my $self = {};

	bless($self, $class);

	# Constants used in calculations transforming between WGS84 and ETRS-TM35FIN 
	add_constant($self, 'Ca', 6378137.0);
	add_constant($self, 'Cb', 6356752.314245);
	add_constant($self, 'Cf', 1.0 / 298.257223563);
	add_constant($self, 'Ck0', 0.9996);
	add_constant($self, 'Clo0', Math::Trig::deg2rad(27.0));
	add_constant($self, 'CE0', 500000.0);
	add_constant($self, 'Cn', get_c($self, 'Cf') / (2.0 - get_c($self, 'Cf')));
	add_constant($self, 'CA1', get_c($self, 'Ca') / (1.0 + get_c($self, 'Cn')) * (1.0 + (get_c($self, 'Cn') ** 2.0) / 4.0 + (get_c($self, 'Cn') ** 4.0) / 64.0));
	add_constant($self, 'Ce', sqrt(2.0 * get_c($self, 'Cf') - get_c($self, 'Cf') ** 2.0));
	add_constant($self, 'Ch1', 1.0/2.0 * get_c($self, 'Cn') - 2.0/3.0 * (get_c($self, 'Cn') ** 2.0) + 37.0/96.0 * (get_c($self, 'Cn') ** 3.0) - 1.0/360.0 * (get_c($self, 'Cn') ** 4.0));
	add_constant($self, 'Ch2', 1.0/48.0 * (get_c($self, 'Cn') ** 2.0) + 1.0/15.0 * (get_c($self, 'Cn') ** 3.0) - 437.0/1440.0 * (get_c($self, 'Cn') ** 4.0));
	add_constant($self, 'Ch3', 17.0/480.0 * (get_c($self, 'Cn') ** 3.0) - 37.0/840.0 * (get_c($self, 'Cn') ** 4.0));
	add_constant($self, 'Ch4', 4397.0/161280.0 * (get_c($self, 'Cn') ** 4.0));
	add_constant($self, 'Ch1p', 1.0/2.0 * get_c($self, 'Cn') - 2.0/3.0 * (get_c($self, 'Cn') ** 2.0) + 5.0/16.0 * (get_c($self, 'Cn') ** 3.0) + 41.0/180.0 * (get_c($self, 'Cn') ** 4.0));
	add_constant($self, 'Ch2p', 13.0/48.0 * (get_c($self, 'Cn') ** 2.0) - 3.0/5.0 * (get_c($self, 'Cn') ** 3.0) + 557.0/1440.0 * (get_c($self, 'Cn') ** 4.0));
	add_constant($self, 'Ch3p', 61.0/240.0 * (get_c($self, 'Cn') ** 3.0) - 103.0/140.0 * (get_c($self, 'Cn') ** 4.0));
	add_constant($self, 'Ch4p', 49561.0/161280.0 * (get_c($self, 'Cn') ** 4.0));

	# WGS84 bounds (ref. http://spatialreference.org/ref/epsg/3067/)
	add_constant($self, 'WGS84_min_la', "59.3000");
	add_constant($self, 'WGS84_max_la', "70.1300");
	add_constant($self, 'WGS84_min_lo', "19.0900");
	add_constant($self, 'WGS84_max_lo', "31.5900");

	# ETRS-TM35FIN bounds (ref. http://spatialreference.org/ref/epsg/3067/)
	add_constant($self, 'ETRSTM35FIN_min_x', "6582464.0358");
	add_constant($self, 'ETRSTM35FIN_max_x', "7799839.8902");
	add_constant($self, 'ETRSTM35FIN_min_y', "50199.4814");
	add_constant($self, 'ETRSTM35FIN_max_y', "761274.6247");
	
	return $self;
}

sub add_constant {
	my ($class, $constant_name, $constant_value) = @_;
	
	$class->{$constant_name} = $constant_value;
	
	return;
}

sub get_constant {
	my ($class, $constant_name) = @_;
	
	return $class->{$constant_name};
}

# Alias for get_constant

sub get_c {
	my ($class, $constant_name) = @_;
	
	return get_constant($class, $constant_name);
}

sub is_defined_ETRSTM35FINxy {
	my @params = @_;
	my ($class, $etrs_x, $etrs_y) = @params;
	
	if (scalar(@params) != 3) {
		croak 'Geo::Coordinates::ETRSTM35FIN::is_defined_ETRSTM35FINxy needs two arguments';
	}

	if (($etrs_x >= get_c($class, 'ETRSTM35FIN_min_x')) and ($etrs_x <= get_c($class, 'ETRSTM35FIN_max_x')) and
		($etrs_y >= get_c($class, 'ETRSTM35FIN_min_y')) and ($etrs_y <= get_c($class, 'ETRSTM35FIN_max_y'))) {
			# Is in bounds
			return 1;
	}
	
	return;
}

sub is_defined_WGS84lalo {
	my @params = @_;
	my ($class, $wgs_la, $wgs_lo) = @params;
	
	if (scalar(@params) != 3) {
		croak 'Geo::Coordinates::ETRSTM35FIN::is_defined_WGS84lalo needs two arguments';
	}

	if (($wgs_la >= get_c($class, 'WGS84_min_la')) and ($wgs_la <= get_c($class, 'WGS84_max_la')) and
		($wgs_lo >= get_c($class, 'WGS84_min_lo')) and ($wgs_lo <= get_c($class, 'WGS84_max_lo'))) {
			# Is in bounds
			return 1;
	}
	
	return;
}
	
sub ETRSTM35FINxy_to_WGS84lalo {
	my @params = @_;
	my ($class, $etrs_x, $etrs_y) = @params;

	if (scalar(@params) != 3) {
		croak 'Geo::Coordinates::ETRSTM35FIN::ETRSTM35FINxy_to_WGS84lalo needs two arguments'
	}

	if (!is_defined_ETRSTM35FINxy($class,$etrs_x, $etrs_y)) {
		return (undef, undef);
	}
		
	my $E = $etrs_x / (get_c($class,'CA1') * get_c($class,'Ck0'));
	my $nn = ($etrs_y - get_c($class,'CE0')) / (get_c($class,'CA1') * get_c($class,'Ck0'));
  
	my $E1p = get_c($class,'Ch1') * sin(2.0 * $E) * Math::Trig::cosh(2.0 * $nn);
	my $E2p = get_c($class,'Ch2') * sin(4.0 * $E) * Math::Trig::cosh(4.0 * $nn);
	my $E3p = get_c($class,'Ch3') * sin(6.0 * $E) * Math::Trig::cosh(6.0 * $nn);
	my $E4p = get_c($class,'Ch4') * sin(8.0 * $E) * Math::Trig::cosh(8.0 * $nn);
	my $nn1p = get_c($class,'Ch1') * cos(2.0 * $E) * Math::Trig::sinh(2.0 * $nn);
	my $nn2p = get_c($class,'Ch2') * cos(4.0 * $E) * Math::Trig::sinh(4.0 * $nn);
	my $nn3p = get_c($class,'Ch3') * cos(6.0 * $E) * Math::Trig::sinh(6.0 * $nn);
	my $nn4p = get_c($class,'Ch4') * cos(8.0 * $E) * Math::Trig::sinh(8.0 * $nn);
	my $Ep = $E - $E1p - $E2p - $E3p - $E4p;
	my $nnp = $nn - $nn1p - $nn2p - $nn3p - $nn4p;
	my $be = Math::Trig::asin(sin($Ep) / Math::Trig::cosh($nnp));
  
	my $Q = Math::Trig::asinh(Math::Trig::tan($be));
	my $Qp = $Q + get_c($class,'Ce') * Math::Trig::atanh(get_c($class,'Ce') * Math::Trig::tanh($Q));
	$Qp = $Q + get_c($class,'Ce') * Math::Trig::atanh(get_c($class,'Ce') * Math::Trig::tanh($Qp));
	$Qp = $Q + get_c($class,'Ce') * Math::Trig::atanh(get_c($class,'Ce') * Math::Trig::tanh($Qp));
	$Qp = $Q + get_c($class,'Ce') * Math::Trig::atanh(get_c($class,'Ce') * Math::Trig::tanh($Qp));
	
	my $wgs_la = Math::Trig::rad2deg(Math::Trig::atan(Math::Trig::sinh($Qp)));
	my $wgs_lo = Math::Trig::rad2deg(get_c($class,'Clo0') + Math::Trig::asin(Math::Trig::tanh($nnp) / cos($be)));

	return ($wgs_la, $wgs_lo);
}

sub WGS84lalo_to_ETRSTM35FINxy {
	my @params = @_;
	my ($class, $wgs_la, $wgs_lo) = @params;
	
	if (scalar(@params) != 3) {
		croak 'Geo::Coordinates::ETRSTM35FIN::WGS84lalo_to_ETRSTM35FINxy needs two arguments'
	}

	if (!is_defined_WGS84lalo($class, $wgs_la, $wgs_lo)) {
		return (undef, undef);
	}
	
	my $la = Math::Trig::deg2rad($wgs_la);
	my $lo = Math::Trig::deg2rad($wgs_lo);
    
	my $Q = Math::Trig::asinh(Math::Trig::tan($la)) - get_c($class,'Ce') * Math::Trig::atanh(get_c($class,'Ce') * sin($la));
	my $be = Math::Trig::atan(Math::Trig::sinh($Q));
	my $nnp = Math::Trig::atanh(cos($be) * sin($lo - get_c($class,'Clo0')));
	my $Ep = Math::Trig::asin(sin($be) * Math::Trig::cosh($nnp));
	my $E1 = get_c($class,'Ch1p') * sin(2.0 * $Ep) * Math::Trig::cosh(2.0 * $nnp);
	my $E2 = get_c($class,'Ch2p') * sin(4.0 * $Ep) * Math::Trig::cosh(4.0 * $nnp);
	my $E3 = get_c($class,'Ch3p') * sin(6.0 * $Ep) * Math::Trig::cosh(6.0 * $nnp);
	my $E4 = get_c($class,'Ch4p') * sin(8.0 * $Ep) * Math::Trig::cosh(8.0 * $nnp);
	
	my $nn1 = get_c($class,'Ch1p') * cos(2.0 * $Ep) * Math::Trig::sinh(2.0 * $nnp);
	my $nn2 = get_c($class,'Ch2p') * cos(4.0 * $Ep) * Math::Trig::sinh(4.0 * $nnp);
	my $nn3 = get_c($class,'Ch3p') * cos(6.0 * $Ep) * Math::Trig::sinh(6.0 * $nnp);
	my $nn4 = get_c($class,'Ch4p') * cos(8.0 * $Ep) * Math::Trig::sinh(8.0 * $nnp);
	my $E = $Ep + $E1 + $E2 + $E3 + $E4;
	my $nn = $nnp + $nn1 + $nn2 + $nn3 + $nn4;
  
	my $etrs_x = get_c($class,'CA1') * $E * get_c($class,'Ck0');
	my $etrs_y = get_c($class,'CA1') * $nn * get_c($class,'Ck0') + get_c($class,'CE0');

	return ($etrs_x, $etrs_y);
}

1;

__END__

=head1 NAME

Geo::Coordinates::ETRSTM35FIN - converts Finnish ETRS-TM35FIN coordinate system from/to WGS84 coordinate system

=head1 SYNOPSIS

  use Geo::Coordinates::ETRSTM35FIN;

  my $gce = new Geo::Coordinates::ETRSTM35FIN;
  
  # ETRS-TM35FIN coordinates to WGS84 coordinates
  my ( $lat, $lon ) = $gce->ETRSTM35FINxy_to_WGS84lalo('6717563', '2545107');

  # WGS84 coordinates to ETRS-TM35FIN coordinates
  my ( $x, $y ) = $gce->WGS84lalo_to_ETRSTM35FINxy('60.22543759', '24.85437044');
  
  # Is the given location in the defined ETRS-TM35FIN boundaries?
  if ($gce->is_defined_ETRSTM35FINxy($x, $y)) {
     print "You gave valid ETRS-TM35FIN coordinates";
  }

=head1 DESCRIPTION

This module converts WGS84 coordinate system to/from the Finnish ETRS-TM35FIN coordinate system. The coordinate system
covers Finland and surroundings. The coordinate system and the transformation functions are defined in the Finnish
JHS-Public Administration Recommendation number 154.

=head1 METHODS

=over 8

=item ETRSTM35FINxy_to_WGS84lalo(x, y)

    Transforms ETRS-TM35FIN coordinates (x = northing, y = easting) to WGS84
    coordinates.
    
    Returns WGS84 latitude and longitude in a two-value array (latitude,
    longitude). If the given ETRS coordinates are out of defined bounds
    (see is_defined_ETRSTM35FIN) the return values are undefined.

=item WGS84lalo_to_ETRSTM35FINxy(lat, lon)

    Transforms WGS84 coordinates to ETRS-TM35FIN coordinates.
    
    Returns transformed coordinates in a two-value array (x = northing,
    y = easting). If the given WGS84 values are out of the defined bounds
    (see is_defined_WGS84lalo) the return values are undefined.

=item is_defined_ETRSTM35FINxy(x, y)

    Checks whether given ETRS-TM35FIN coordinates (x = northing, y = easting)
    are in the area where the ETRS-TM35FIN coordinate system is defined. The
    boundaries are defined in L<http://spatialreference.org/ref/epsg/3067/>.
    
    Returns true if the coordinates are in the defined area, otherwise false.

=item is_defined_WGS84lalo(lat, lon)

    Checks whether given WGS84 coordinates are in the area where the
    ETRS-TM35FIN coordinate system is defined. The boundaries are defined
    in L<http://spatialreference.org/ref/epsg/3067/>.

    Returns true if the coordinates are in the defined area, otherwise false.

=back

=head1 BUGS

Please report to author.

=head1 SEE ALSO

Official ETRS-TM35FIN definition
L<http://www.jhs-suositukset.fi/web/guest/jhs/projects/jhs154> (in Finnish).
The conversion functions are in appendix 1.

Good explanation about the Finnish coordinate system and its history
L<http://www.kolumbus.fi/eino.uikkanen/geodocsgb/ficoords.htm>.

On-line transformations between different coordinate systems
L<http://kansalaisen.karttapaikka.fi/koordinaatit/koordinaatit.html?lang=en>.

Former Finnish coordinate system conversion routines B<Geo::Coordinates:KKJ>.

=head1 AUTHOR

Perl port and CPAN package Matti Lattu, <matti@lattu.biz>

The conversion formulae have been acquired from a Python module from Olli Lammi
L<http://olammi.iki.fi/sw/fetch_map/>.

=head1 ACKNOWLEDGEMENTS

The Perl realization follows closely Geo::Coordinates::KKJ by Josep Roca.

Thanks for GIS specialist PhD Tuuli Toivonen (University of Helsinki) for her
essential support.

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

Copyright (C) 2010-2011 Olli Lammi and Matti Lattu

=cut
