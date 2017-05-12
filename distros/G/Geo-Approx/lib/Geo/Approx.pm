package Geo::Approx;
use strict;
use Carp;
use Math::Trig;
use vars qw ( $VERSION );
$^W = 1;

$VERSION = 0.8;

my %mask;
BEGIN
{
    for(my $i=0;$i<=32;$i++){
	$mask{$i} = pack("B32",('0'x(32-$i) . '1'x$i));
    }
}

sub new
{
    my ($caller,$precision) = @_;
    my $class = ref($caller) || $caller;
    if(defined $precision){
	unless(($precision =~ /^(\d+)$/)&&($1>=0)&&($1<=32))
	{
	    croak("optional argument to Geo::Aprox constructor must be a precision between zero and 32");
	}
    } else {
	$precision = 32;
    }
    bless \$precision,$class;
}

sub latlon2int
{
    my $prec = ${$_[0]};
    my $result = _intint2int(_lat2int($_[1]),_lon2int($_[2]));
    $result = _setPrecision($prec,$result);
    return $result;
}

sub int2latlon
{
    my $mask = \$_[0];
    my ($lat_int,$lon_int) = _int2intint($_[1]);
    my $lat = _int2lat($lat_int);
    my $lon = _int2lon($lon_int);
    return ($lat,$lon);
}

sub _setPrecision
{
    my ($prec,$num) = @_;
    return unpack("N",pack("N",$num)&$mask{$prec});
}

sub _int2lat # 0 to 65535
{
    return rad2deg(asin(($_[0]+0.5)/32768-1.0));
}

sub _lat2int # -90 to 90 inclusive
{
    my $result = int((sin(deg2rad($_[0]))+1.0)*32768);
    $result = 65535 if ($result==65536); # special case for lat==90.000
    return int($result);
} # 0 to 65535

sub _lon2int # -180 to 180 inclusive
{
    my $result = int(($_[0]/360 + 0.5)*65536);
    $result %= 65536; # wrap-around
    return $result;
} # 0 to 65535 inclusive

sub _int2lon # 0 to 65535 inclusive
{
    return ($_[0]/65536 - 0.5)*360;
} # -180 to <180

sub _intint2int # two 16-bit numbers
{
    my $bina = substr(unpack("B32",pack("N",$_[0])),-16);
    my $binb = substr(unpack("B32",pack("N",$_[1])),-16);
    my $bbiinnab;
    for(my $i=0;$i<16;$i++){
	$bbiinnab .= substr($bina,$i,1);
	$bbiinnab .= substr($binb,$i,1);
    }
    my $dec = unpack("V",pack("B32",$bbiinnab));
    return $dec;
} # one 32-bit number

sub _int2intint # one 32-bit number
{
    my $bbiinnab = substr(unpack("B32",pack("V",$_[0])),-32);
    my ($bina,$binb) = ('0000000000000000','0000000000000000');
    for(my $i=0;$i<32;$i+=2){
	$bina .= substr($bbiinnab,$i,1);
	$binb .= substr($bbiinnab,$i+1,1);
    }
    my $deca = unpack("N",pack("B32",$bina));
    my $decb = unpack("N",pack("B32",$binb));
    return ($deca,$decb);
} # two 16-bit numbers

1;

__END__

=head1 NAME

Geo::Approx - represents an approximate global position by a single number

=head1 SYNOPSIS

  use Geo::Approx;
  my $ga = Geo::Approx($precision);
  my $pos = $ga->latlon2int($lat,$lon);
  my ($approx_lat,$approx_lon) = $ga->int2latlon($pos);

=head1 DESCRIPTION

It is sometimes useful to condense the information present in a 
latitude and longitude into a single number (for example, when storing
the position within a database). This module provides methods for
this conversion. By default, the precision of the position is set
at 32 bits (roughly 

Assuming the surface area of the earth is 5.1 x 10^8 sq km, the area
represented by the single number at each precision is as follows:

  0.12 sq km at 32 bits
  0.24 sq km at 31 bits
  0.47 sq km at 30 bits
  0.95 sq km at 29 bits
  and so on (5.1E8 / 2^precision)

These areas are constant across all latitudes and longitudes.

Thus, if you want to be fairly precise about positions, you can store
fairly large numbers, whereas if you want to be fairly imprecise, 
you can use small numbers.

=head1 CONSTRUCTOR

The constructor takes one optional argument - a number between zero
and 32 indicating precision.

  my $ga = Geo::Aprox->new(24);

By default, the precision is 32 bits.

=head1 OBJECT METHODS

=over 4

=item $pos = $ga-E<gt>latlon2int($lat,$lon);

Converts a latitude and longitude to an integer integer representing that
position. Latitude must be between -90 and 90. Longitude must be 
between -180 and 180.

=item ($lat,$lon) = $ga-E<gt>int2latlon($pos);

Converts a position represented by an integer into a latitude and longitude.

=back

=head1 SEE ALSO

L<http://lists.burri.to/pipermail/geowanking/2003-August/000301.html> - the post that raised my interest.

=head1 COPYRIGHT

Copyright (C) 2002,2003 Nigel Wetters. All Rights Reserved.

NO WARRANTY. This module is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.

=cut
