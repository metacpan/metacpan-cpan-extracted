package Geo::Distance;
{
  $Geo::Distance::VERSION = '0.20';
}
use strict;
use warnings;

=head1 NAME

Geo::Distance - Calculate Distances and Closest Locations

=head1 SYNOPSIS

  use Geo::Distance;
  my $geo = new Geo::Distance;
  $geo->formula('hsin');
  $geo->reg_unit( 'toad_hop', 200120 );
  $geo->reg_unit( 'frog_hop' => 6 => 'toad_hop' );
  my $distance = $geo->distance( 'unit_type', $lon1,$lat1 => $lon2,$lat2 );
  my $locations = $geo->closest(
    dbh => $dbh,
    table => $table,
    lon => $lon,
    lat => $lat,
    unit => $unit_type,
    distance => $dist_in_unit
  );

=head1 DESCRIPTION

This perl library aims to provide as many tools to make it as simple as possible to calculate 
distances between geographic points, and anything that can be derived from that.  Currently 
there is support for finding the closest locations within a specified distance, to find the 
closest number of points to a specified point, and to do basic point-to-point distance 
calculations.

=head1 DECOMMISSIONED

The L<GIS::Distance> module is being worked on as a replacement for this module.  In the
near future Geo::Distance will become a lightweight wrapper around GIS::Distance so that
legacy code benefits from fixes to GIS::Distance through the old Geo::Distance API.  For
any new developement I suggest that you look in to GIS::Distance.

=head1 STABILITY

The interface to Geo::Distance is fairly stable nowadays.  If this changes it 
will be noted here.

0.10 - The closest() method has a changed argument syntax and no longer supports array searches.
0.09 - Changed the behavior of the reg_unit function.
0.07 - OO only, and other changes all over.

=cut

use Carp;
use Math::Trig qw( great_circle_distance deg2rad rad2deg acos pi asin tan atan );
use constant KILOMETER_RHO => 6371.64;

=head1 PROPERTIES

=head2 UNITS

All functions accept a unit type to do the computations of distance with.  By default no units 
are defined in a Geo::Distance object.  You can add units with reg_unit() or create some default 
units with default_units().

=head2 LATITUDE AND LONGITUDE

When a function needs a longitude and latitude, they must always be in decimal degree format.
Here is some sample code for converting from other formats to decimal:

  # DMS to Decimal
  my $decimal = $degrees + ($minutes/60) + ($seconds/3600);
  
  # Precision Six Integer to Decimal
  my $decimal = $integer * .000001;

If you want to convert from decimal radians to degrees you can use Math::Trig's rad2deg function.

=head1 METHODS

=head2 new

  my $geo = new Geo::Distance;
  my $geo = new Geo::Distance( no_units=>1 );

Returns a blessed Geo::Distance object.  The new constructor accepts one optional 
argument.

  no_units - Whether or not to load the default units. Defaults to 0 (false).
             kilometer, kilometre, meter, metre, centimeter, centimetre, millimeter, 
             millimetre, yard, foot, inch, light second, mile, nautical mile, 
             poppy seed, barleycorn, rod, pole, perch, chain, furlong, league, 
             fathom

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my %args = @_;
    
    $self->{formula} = 'hsin';
    $self->{units} = {};
    if(!$args{no_units}){
        $self->reg_unit( KILOMETER_RHO, 'kilometer' );
        $self->reg_unit( 1000, 'meter', => 'kilometer' );
        $self->reg_unit( 100, 'centimeter' => 'meter' );
        $self->reg_unit( 10, 'millimeter' => 'centimeter' );
        
        $self->reg_unit( 'kilometre' => 'kilometer' );
        $self->reg_unit( 'metre' => 'meter' );
        $self->reg_unit( 'centimetre' => 'centimeter' );
        $self->reg_unit( 'millimetre' => 'millimeter' );
        
        $self->reg_unit( 'mile' => 1609.344, 'meter' );
        $self->reg_unit( 'nautical mile' => 1852, 'meter' );
        $self->reg_unit( 'yard' => 0.9144, 'meter' );
        $self->reg_unit( 3, 'foot' => 'yard' );
        $self->reg_unit( 12, 'inch' => 'foot' );
        $self->reg_unit( 'light second' => 299792458, 'meter' );
        
        $self->reg_unit( 'poppy seed' => 2.11, 'millimeter' );
        $self->reg_unit( 'barleycorn' => 8.467, 'millimeter' );
        $self->reg_unit( 'rod' => 5.0292, 'meter' );
        $self->reg_unit( 'pole' => 'rod' );
        $self->reg_unit( 'perch' => 'rod' );
        $self->reg_unit( 'chain' => 20.1168, 'meter' );
        $self->reg_unit( 'furlong' => 201.168, 'meter' );
        $self->reg_unit( 'league' => 4.828032, 'kilometer' );
        $self->reg_unit( 1.8288, 'fathom' => 'meter' );
    }
    
    # Number of units in a single degree (lat or lon) at the equator.
    # Derived from: $geo->distance( 'kilometer', 10,0, 11,0 ) / $geo->{units}->{kilometer}
    $self->{deg_ratio} = 0.0174532925199433;

    return $self;
}

=head2 formula

  if($geo->formula eq 'hsin'){ ... }
  $geo->formula('cos');

Allows you to retrieve and set the formula that is currently being used to
calculate distances.  The available formulas are hsin, polar, cos and mt. hsin
is the default and mt/cos are deprecated in favor of hsin. Polar should be used
when calculating coordinates near the poles.

=cut

sub formula {
    my $self = shift;
    my $formula = shift;
    if( $formula !~ /^(mt|cos|hsin|polar|gcd|tv)$/s ){
        croak('Invalid formula (only mt, cos, hsin, polar, gcd and tv are supported)');
    }else{
        $self->{formula} = $formula;
    }
    return $formula;
}

=head2 reg_unit

  $geo->reg_unit( $radius, $key );
  $geo->reg_unit( $key1 => $key2 );
  $geo->reg_unit( $count1, $key1 => $key2 );
  $geo->reg_unit( $key1 => $count2, $key2 );
  $geo->reg_unit( $count1, $key1 => $count2, $key2 );

This method is used to create custom unit types.  There are several ways of calling it, 
depending on if you are defining the unit from scratch, or if you are basing it off 
of an existing unit (such as saying 12 inches = 1 foot ).  When defining a unit from 
scratch you pass the name and rho (radius of the earth in that unit) value.

So, if you wanted to do your calculations in human adult steps you would have to have an 
average human adult walk from the crust of the earth to the core (ignore the fact that 
this is impossible).  So, assuming we did this and we came up with 43,200 steps, you'd 
do something like the following.

  # Define adult step unit.
  $geo->reg_unit( 43200, 'adult step' );
  # This can be read as "It takes 43,200 adult_steps to walk the radius of the earth".

Now, if you also wanted to do distances in baby steps you might think "well, now I 
gotta get a baby to walk to the center of the earth".  But, you don't have to!  If you do some 
research you'll find (no research was actually conducted) that there are, on average, 
4.7 baby steps in each adult step.

  # Define baby step unit.
  $geo->reg_unit( 4.7, 'baby step' => 'adult step' );
  # This can be read as "4.7 baby steps is the same as one adult step".

And if we were doing this in reverse and already had the baby step unit but not 
the adult step, you would still use the exact same syntax as above.

=cut

sub reg_unit {
    my $self = shift;
    my $units = $self->{units};
    my($count1,$key1,$count2,$key2);
    $count1 = shift;
    if($count1=~/[^\.0-9]/ or !@_){ $key1=$count1; $count1=1; }
    else{ $key1 = shift; }
    if(!@_){
        $units->{$key1} = $count1;
    }else{
        $count2 = shift;
        if($count2=~/[^\.0-9]/ or !@_){ $key2=$count2; $count2=1; }
        else{ $key2 = shift; }
        ($key1,$key2) = ($key2,$key1) if( defined $units->{$key1} );
        $units->{$key1} = ($units->{$key2}*$count1) / $count2;
    }
}

=head2 distance

  my $distance = $geo->distance( 'unit_type', $lon1,$lat1 => $lon2,$lat2 );

Calculates the distance between two lon/lat points.

=cut

sub distance {
    my($self,$unit,$lon1,$lat1,$lon2,$lat2) = @_;
    croak('Unkown unit type "'.$unit.'"') unless($unit = $self->{units}->{$unit});
    if($self->{formula} eq 'mt'){
        return great_circle_distance(
            deg2rad($lon1), 
            deg2rad(90 - $lat1), 
            deg2rad($lon2), 
            deg2rad(90 - $lat2), 
            $unit
        );
    }else{
        $lon1 = deg2rad($lon1); $lat1 = deg2rad($lat1);
        $lon2 = deg2rad($lon2); $lat2 = deg2rad($lat2);
        my $c;
        if($self->{formula} eq 'cos'){
            my $a = sin($lat1) * sin($lat2);
            my $b = cos($lat1) * cos($lat2) * cos($lon2 - $lon1);
            $c = acos($a + $b);
        }
        elsif($self->{formula} eq 'hsin'){
            my $dlon = $lon2 - $lon1;
            my $dlat = $lat2 - $lat1;
            my $a = (sin($dlat/2)) ** 2 + cos($lat1) * cos($lat2) * (sin($dlon/2)) ** 2;
            $c = 2 * atan2(sqrt($a), sqrt(abs(1-$a)));
        }
        elsif($self->{formula} eq 'polar'){
            my $a = pi/2 - $lat1;
            my $b = pi/2 - $lat2;
            $c = sqrt( $a ** 2 + $b ** 2 - 2 * $a * $b * cos($lon2 - $lon1) );
        }
        elsif($self->{formula} eq 'gcd'){
            $c = 2*asin( sqrt(
                ( sin(($lat1-$lat2)/2) )**2 + 
                cos($lat1) * cos($lat2) * 
                ( sin(($lon1-$lon2)/2) )**2
            ) );

            # Eric Samuelson recommended this formula.
            # http://forums.devshed.com/t54655/sc3d021a264676b9b440ea7cbe1f775a1.html
            # http://williams.best.vwh.net/avform.htm
            # It seems to produce the same results at the hsin formula, so...
            
            #my $dlon = $lon2 - $lon1;
            #my $dlat = $lat2 - $lat1;
            #my $a = (sin($dlat / 2)) ** 2
            #    + cos($lat1) * cos($lat2) * (sin($dlon / 2)) ** 2;
            #$c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        }
        elsif($self->{formula} eq 'tv'){
            my($a,$b,$f) = (6378137,6356752.3142,1/298.257223563);
            my $l = $lon2 - $lon1;
            my $u1 = atan((1-$f) * tan($lat1));
            my $u2 = atan((1-$f) * tan($lat2));
            my $sin_u1 = sin($u1); my $cos_u1 = cos($u1);
            my $sin_u2 = sin($u2); my $cos_u2 = cos($u2);
            my $lambda = $l;
            my $lambda_pi = 2 * pi;
            my $iter_limit = 20;
            my($cos_sq_alpha,$sin_sigma,$cos2sigma_m,$cos_sigma,$sigma);
            while( abs($lambda-$lambda_pi) > 1e-12 && --$iter_limit>0 ){
                my $sin_lambda = sin($lambda); my $cos_lambda = cos($lambda);
                $sin_sigma = sqrt(($cos_u2*$sin_lambda) * ($cos_u2*$sin_lambda) + 
                    ($cos_u1*$sin_u2-$sin_u1*$cos_u2*$cos_lambda) * ($cos_u1*$sin_u2-$sin_u1*$cos_u2*$cos_lambda));
                $cos_sigma = $sin_u1*$sin_u2 + $cos_u1*$cos_u2*$cos_lambda;
                $sigma = atan2($sin_sigma, $cos_sigma);
                my $alpha = asin($cos_u1 * $cos_u2 * $sin_lambda / $sin_sigma);
                $cos_sq_alpha = cos($alpha) * cos($alpha);
                $cos2sigma_m = $cos_sigma - 2*$sin_u1*$sin_u2/$cos_sq_alpha;
                my $cc = $f/16*$cos_sq_alpha*(4+$f*(4-3*$cos_sq_alpha));
                $lambda_pi = $lambda;
                $lambda = $l + (1-$cc) * $f * sin($alpha) *
                    ($sigma + $cc*$sin_sigma*($cos2sigma_m+$cc*$cos_sigma*(-1+2*$cos2sigma_m*$cos2sigma_m)));
            }
            undef if( $iter_limit==0 );
            my $usq = $cos_sq_alpha*($a*$a-$b*$b)/($b*$b);
            my $aa = 1 + $usq/16384*(4096+$usq*(-768+$usq*(320-175*$usq)));
            my $bb = $usq/1024 * (256+$usq*(-128+$usq*(74-47*$usq)));
            my $delta_sigma = $bb*$sin_sigma*($cos2sigma_m+$bb/4*($cos_sigma*(-1+2*$cos2sigma_m*$cos2sigma_m)-
                $bb/6*$cos2sigma_m*(-3+4*$sin_sigma*$sin_sigma)*(-3+4*$cos2sigma_m*$cos2sigma_m)));
            $c = ( $b*$aa*($sigma-$delta_sigma) ) / $self->{units}->{meter};
        }
        else{
            croak('Unkown distance formula "'.$self->{formula}.'"');
        }
        return $unit * $c;
    }
}

=head2 closest

  my $locations = $geo->closest(
    dbh => $dbh,
    table => $table,
    lon => $lon,
    lat => $lat,
    unit => $unit_type,
    distance => $dist_in_unit
  );

This method finds the closest locations within a certain distance and returns an 
array reference with a hash for each location matched.

The closest method requires the following arguments:

  dbh - a DBI database handle
  table - a table within dbh that contains the locations to search
  lon - the longitude of the center point
  lat - the latitude of the center point
  unit - the unit of measurement to use, such as "meter"
  distance - the distance, in units, from the center point to find locations

The following arguments are optional:

  lon_field - the name of the field in the table that contains the longitude, defaults to "lon"
  lat_field - the name of the field in the table that contains the latitude, defaults to "lat"
  fields - an array reference of extra field names that you would like returned with each location
  where - additional rules for the where clause of the sql
  bind - an array reference of bind variables to go with the placeholders in where
  sort - whether to sort the locations by their distance, making the closest location the first returned
  count - return at most these number of locations (implies sort => 1)

This method uses some very simplistic calculations to SQL select out of the dbh.  This 
means that the SQL should work fine on almost any database (only tested on MySQL and SQLite so far) and 
this also means that it is fast.  Once this sub set of locations has been retrieved 
then more precise calculations are made to narrow down the result set.  Remember, though, that 
the farther out your distance is, and the more locations in the table, the slower your searches will be.

=cut

sub closest {
    my $self  = shift;
    my %args = @_;

    # Set defaults and prepare.
    my $dbh = $args{dbh} || croak('You must supply a database handle');
    $dbh->isa('DBI::db') || croak('The dbh must be a DBI database handle');
    my $table = $args{table} || croak('You must supply a table name');
    my $lon = $args{lon} || croak('You must supply a longitude');
    my $lat = $args{lat} || croak('You must supply a latitude');
    my $distance = $args{distance} || croak('You must supply a distance');
    my $unit = $args{unit} || croak('You must specify a unit type');
    my $unit_size = $self->{units}->{$unit} || croak('This unit type is not known');
    my $degrees = $distance / ( $self->{deg_ratio} * $unit_size );
    my $lon_field = $args{lon_field} || 'lon';
    my $lat_field = $args{lat_field} || 'lat';
    my $fields = $args{fields} || [];
    
    unshift @$fields, $lon_field, $lat_field;
    $fields = join( ',', @$fields );
    my $count = $args{count} || 0;
    my $sort = $args{sort} || ( $count ? 1 : 0 );
    my $where = qq{$lon_field >= ? AND $lat_field >= ? AND $lon_field <= ? AND $lat_field <= ?};
    $where .= ( $args{where} ? " AND ($args{where})" : '' );
    
    my @bind = (
        $lon-$degrees, $lat-$degrees,
        $lon+$degrees, $lat+$degrees,
        ( $args{bind} ? @{$args{bind}} : () )
    );
    
    # Retrieve locations.
    my $sth = $dbh->prepare(qq{
        SELECT $fields 
        FROM $table
        WHERE $where
    });
    $sth->execute( @bind );
    my $locations = [];
    while(my $location = $sth->fetchrow_hashref){
        push @$locations, $location;
    }

    # Calculate distances.
    my $closest = [];
    foreach my $location (@$locations){
        $location->{distance} = $self->distance(
            $unit, $lon, $lat, 
            $location->{$lon_field}, 
            $location->{$lat_field}
        );
        if( $location->{distance} <= $distance ){
            push @$closest, $location;
        }
    }
    $locations = $closest;

    # Sort.
    if( $sort ){
        my $location;
        for(my $i=@$locations-1; $i>=0; $i--){
            for(my $j=$i-1; $j>=0; $j--){
                if($locations->[$i]->{distance} < $locations->[$j]->{distance}){
                    $location = $locations->[$i];
                    $locations->[$i] = $locations->[$j];
                    $locations->[$j] = $location;
                }
            }
        }
    }

    # Split for count.
    if( $count and $count < @$locations ){
        splice @$locations, $count;
    }
    
    return $locations;
}

unless( $ENV{GEO_DISTANCE_PP} ) {
    eval "use Geo::Distance::XS";
}

1;
__END__

=head1 FORMULAS

Currently Geo::Distance only has spherical and flat type formulas.  
If you have any information concerning ellipsoid and geoid formulas, 
the author would much appreciate some links to this information.

=head2 tv: Thaddeus Vincenty Formula

This is a highly accurate ellipsoid formula.  For most applications 
hsin will be faster and accurate enough.  I've read that this formula can 
be accurate to within a few millimeters.

This formula is still considered alpha quality.  It has not been tested 
enough to be used in production.

=head2 hsin: Haversine Formula

  dlon = lon2 - lon1
  dlat = lat2 - lat1
  a = (sin(dlat/2))^2 + cos(lat1) * cos(lat2) * (sin(dlon/2))^2
  c = 2 * atan2( sqrt(a), sqrt(1-a) )
  d = R * c 

The hsin formula is the new standard formula for Geo::Distance because 
of it's improved accuracy over the cos formula.

=head2 polar: Polar Coordinate Flat-Earth Formula

  a = pi/2 - lat1
  b = pi/2 - lat2
  c = sqrt( a^2 + b^2 - 2 * a * b * cos(lon2 - lon1) )
  d = R * c 

While implimented, this formula has not been tested much.  If you use it 
PLEASE share your results with the author!

=head2 cos: Law of Cosines for Spherical Trigonometry

  a = sin(lat1) * sin(lat2)
  b = cos(lat1) * cos(lat2) * cos(lon2 - lon1)
  c = arccos(a + b)
  d = R * c

Although this formula is mathematically exact, it is unreliable for 
small distances because the inverse cosine is ill-conditioned.

=head2 gcd: Great Circle Distance.

  c = 2 * asin( sqrt(
    ( sin(( lat1 - lat2 )/2) )^2 + 
    cos( lat1 ) * cos( lat2 ) * 
    ( sin(( lon1 - lon2 )/2) )^2
  ) )

Similar notes to the mt and cos formula, not too terribly accurate.

=head2 mt: Math::Trig great_circle_distance

This formula uses Meth::Trig's great_circle_distance function which at this time uses math almost 
exactly the same as the cos formula.  If you want to use the cos formula you may find 
that mt will calculate faster (untested assumption).  For some reason mt and cos return 
slight differences at very close distances. The mt formula has the same drawbacks as the cos formula.

This is the same formula that was previously the only one used by 
Geo::Distance (ending at version 0.06) and was wrongly called the "gcd" formula.

Math::Trig states that the formula that it uses is:

  lat0 = 90 degrees - phi0
  lat1 = 90 degrees - phi1
  d = R * arccos(cos(lat0) * cos(lat1) * cos(lon1 - lon01) + sin(lat0) * sin(lat1))

=head1 NOTES

If L<Geo::Distance::XS> is installed, this module will use it. You can
stick with the pure Perl version by setting the GEO_DISTANCE_PP environment
variable before using this module.

=head1 TODO

=over 4

=item *

A second pass should be done in closest before distance calculations are made that does an inner 
radius simplistic calculation to find the locations that are obviously within the distance needed.

=item *

Tests!  We need more tests!

=item *

For NASA-quality accuracy a geoid forumula.

=item *

The closest() method needs to be more flexible and (among other things) allow table joins.

=back

=head1 SEE ALSO

L<Math::Trig> - Inverse and hyperbolic trigonemetric Functions.

L<http://www.census.gov/cgi-bin/geo/gisfaq?Q5.1> - A overview of calculating distances.

L<http://williams.best.vwh.net/avform.htm> - Aviation Formulary.

=head1 AUTHOR

Aran Clary Deltac <bluefeet@cpan.org>

=head1 CONTRIBUTORS

gray, <gray at cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

