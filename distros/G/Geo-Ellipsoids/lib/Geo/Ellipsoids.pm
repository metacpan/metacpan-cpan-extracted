package Geo::Ellipsoids;

=head1 NAME

Geo::Ellipsoids - Package for standard Geo:: ellipsoid a, b, f and 1/f values.

=head1 SYNOPSIS

  use Geo::Ellipsoids;
  my $obj = Geo::Ellipsoids->new();
  $obj->set('WGS84'); #default
  print "a=", $obj->a, "\n";
  print "b=", $obj->b, "\n";
  print "f=", $obj->f, "\n";
  print "i=", $obj->i, "\n";
  print "e=", $obj->e, "\n";
  print "n=", $obj->n(45), "\n";

=head1 DESCRIPTION

=cut

use strict;
use vars qw($VERSION);
use constant DEFAULT_ELIPS => 'WGS84';
use Geo::Constants qw{PI};
use Geo::Functions qw{rad_deg};

$VERSION = sprintf("%d.%02d", q{Revision: 0.16} =~ /(\d+)\.(\d+)/);

=head1 CONSTRUCTOR

=head2 new

The new() constructor may be called with any parameter that is appropriate to the set method.

  my $obj = Geo::Ellipsoid->new();

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head1 METHODS

=cut

sub initialize {
  my $self = shift();
  my $param = shift();
  $self->set($param);
}

=head2 set

Method sets the current ellipsoid.  This method is called when the object is constructed (default is WGS84).

  $obj->set(); #default WGS84
  $obj->set('Clarke 1866'); #All built in ellipsoids are stored in meters
  $obj->set({a=>1, b=>1});  #Custom Sphere 1 unit radius

=cut

sub set {
  my $self=shift();
  my $param=shift()||DEFAULT_ELIPS;
  undef($self->{'shortname'});
  undef($self->{'longname'});
  if ("HASH" eq ref($param)) {
    return $self->_setref($param);
  } elsif ('' eq ref($param)) {
    return $self->_setname($param);
  } else {
    die("Error: Parameter must be the name of an ellipsoid or a hash reference");
  } 
}

=head2 list

Method returns a list of known elipsoid names.

  my @list=$obj->list;

  my $list=$obj->list;
  while (@$list) {
    print "$_\n";
  }

=cut 

sub list {
  my $self=shift();
  my $data=$self->data;
  my @keys=keys %$data;
  return wantarray ? @keys : \@keys;
}

=head2 a

Method returns the value of the semi-major axis.

  my $a=$obj->a;

=cut

sub a {
  my $self=shift();
  return $self->{'a'} || die('Error: $self->{"a"} must be defined here');
}

=head2 b

Method returns the value of the semi-minor axis.

  my $b=$obj->b;  #b=a(1-f)

=cut

sub b {
  my $self=shift();
  if (defined $self->{'b'}) {
    return $self->{'b'};
  } elsif (defined $self->{'f'}) {
    return $self->{'a'}*(1-$self->{'f'});
  } elsif (defined $self->{'i'}) {
    return $self->{'a'}*(1-1/$self->{'i'});
  } else {
    return undef();
  }
}

=head2 f

Method returns the value of flatting

  my $f=$obj->f;  #f=(a-b)/a

=cut

sub f {
  my $self=shift();
  if (defined $self->{'f'}) {
    return $self->{'f'};
  } elsif (defined $self->{'b'}) {
    return ($self->{'a'}-$self->{'b'})/$self->{'a'};
  } elsif (defined $self->{'i'}) {
    return 1/$self->{'i'};
  } else {
    return undef();
  }
}

=head2 i

Method returns the value of the inverse flatting

  my $i=$obj->i; #i=1/f=a/(a-b)

=cut

sub i {
  my $self=shift();
  if (defined $self->{'i'}) {
    return $self->{'i'};
  } elsif (defined $self->{'b'}) {
    if ($self->{'a'} == $self->{'b'}) {
      return undef();
    } else {
      return $self->{'a'}/($self->{'a'}-$self->{'b'});
    }
  } elsif (defined $self->{'f'}) {
    return 1/$self->{'f'};
  } else {
    return undef();
  }
}

=head2 invf

Method synonym for the i method

  my $i=$obj->invf; #i=1/f

=cut

sub invf {
  my $self = shift();
  return $self->i(@_);
}

=head2 e

Method returns the value of the first eccentricity, e.  This is the eccentricity of the earth's elliptical cross-section.

  my $e=$obj->e;

=cut

sub e {
  my $self=shift();
  return sqrt($self->e2);
}

=head2 e2

Method returns the value of eccentricity squared (e.g. e^2). This is not the second eccentricity, e' or e-prime see the "ep" method.

  my $e=sqrt($obj->e2); #e^2 = f(2-f) = 2f-f^2 = 1-b^2/a^2

=cut

sub e2 {
  my $self=shift();
  my $f=$self->f();
  return $f*(2 - $f);
}

=head2 ep

Method returns the value of the second eccentricity, e' or e-prime.  The second eccentricity is related to the first eccentricity by the equation: 1=(1-e^2)(1+e'^2).

  my $ep=$obj->ep;

=cut

sub ep {
  my $self=shift();
  return sqrt($self->ep2);
}

=head2 ep2

Method returns the square of value of second eccentricity, e' (e-prime).  This is more useful in almost all equations.

  my $ep=sqrt($obj->ep2);  #ep2=(ea/b)^2=e2/(1-e2)=a^2/b^2-1

=cut

sub ep2 {
  my $self=shift();
  my $a=$self->a();
  my $b=$self->b();
  return $a**2/$b**2 - 1;
}

=head2 n

Method returns the value of n given latitude (degrees).  Typically represented by the Greek letter nu, this is the radius of curvature of the ellipsoid perpendicular to the meridian plane.  It is also the distance from the point in question to the polar axis, measured perpendicular to the ellipsoid's surface.

  my $n=$obj->n($lat);

Note: Some define a variable n as (a-b)/(a+b) this is not that variable.

Note: It appears that n can also be calculated as 

  n=a^2/sqrt(a^2 * cos($lat)^2 + $b^2 * sin($lat)^2);

=cut

sub n {
  my $self=shift();
  my $lat=shift(); #degrees
  die("Error: Latitude (degrees) required.") unless defined $lat;
  return $self->n_rad(rad_deg($lat));
}

=head2 n_rad

Method returns the value of n given latitude (radians).

  my $n=$obj->n_rad($lat);

Reference: John P. Snyder, "Map Projections: A Working Manual", USGS, page 25, equation (4-20) http://pubs.er.usgs.gov/usgspubs/pp/pp1395

=cut

sub n_rad {
  my $self=shift();
  my $lat=shift(); #radians
  die("Error: Latitude (radians) required.") unless defined $lat;
  my $a=$self->a;
  my $e2=$self->e2;
  return $a / sqrt(1 - $e2 * sin($lat)**2);
}

=head2 rho

rho is the radius of curvature of the earth in the meridian plane.

  my $rho=$obj->rho($lat);

=cut

sub rho {
  my $self=shift();
  my $lat=shift(); #degrees
  die("Error: Latitude (degrees) required.") unless defined $lat;
  return $self->rho_rad(rad_deg($lat));
}

=head2 rho_rad

rho is the radius of curvature of the earth in the meridian plane. Sometimes denoted as R'.

  my $rho=$obj->rho_rad($lat);

Reference: John P. Snyder, "Map Projections: A Working Manual", USGS, page 24, equation (4-18) http://pubs.er.usgs.gov/usgspubs/pp/pp1395

=cut

sub rho_rad {
  my $self=shift();
  my $lat=shift(); #radians
  die("Error: Latitude (radians) required.") unless defined $lat;
  my $a=$self->a;
  my $e2=$self->e2;
  return $a * (1-$e2) / ( 1 - $e2 * sin($lat)**2 )**(3/2)
  #return $a * (1-$e2) / sqrt(1 - $e2 * sin($lat)**(3/2)); #Bad formula from somewhere
}

=head2 polar_circumference

Method returns the value of the semi-minor axis times 2*PI.

  my $polar_circumference=$obj->polar_circumference;

=cut

sub polar_circumference {
  my $self=shift();
  return 2 * PI() * $self->b();
}

=head2 equatorial_circumference

Method returns the value of the semi-major axis times 2*PI.

  my $equatorial_circumference=$obj->equatorial_circumference;

=cut

sub equatorial_circumference {
  my $self=shift();
  return 2 * PI() * $self->a();
}

sub _setref {
  my $self=shift();
  my $param=shift();
  if ('HASH' eq ref($param)) {
    if (defined($param->{'a'})) {
      $self->{'a'}=$param->{'a'};
      $self->{'shortname'}='Custom' unless defined($self->shortname);
      if (defined $param->{'i'}) {
        $self->{'i'}=$param->{'i'};
        undef($self->{'b'});
        undef($self->{'f'});
        $self->{'longname'}='Custom Ellipsoid {a=>'.$self->a.',i=>'.$self->i.'}'  unless defined($self->longname);
      } elsif (defined $param->{'b'}){
        $self->{'b'}=$param->{'b'};
        undef($self->{'i'});
        undef($self->{'f'});
        $self->{'longname'}='Custom Ellipsoid {a=>'.$self->a.',b=>'.$self->b.'}'  unless defined($self->longname);
      } elsif (defined $param->{'f'}){
        $self->{'f'}=$param->{'f'};
        undef($self->{'b'});
        undef($self->{'i'});
        $self->{'longname'}='Custom Ellipsoid {a=>'.$self->a.',f=>'.$self->f.'}'  unless defined($self->longname);
      } else {
        $self->{'b'}=$param->{'a'};
        undef($self->{'f'});
        undef($self->{'i'});
        $self->{'longname'}='Custom Sphere {a=>'.$self->a.'}' unless defined($self->longname);
      }
    } else {
      die("Error: a must be defined");
    }
  } else {
    die('Error: a hash reference e.g. {a=>###, i=>###} must be define');
  }
  return 1;
}

sub _setname {
  my $self=shift();
  my $param=shift();
  my $ref=$self->name2ref($param);
  if ("HASH" eq ref($ref)) {
    $self->{'shortname'}=$param;
    my $data=$self->data;
    my %data=map {$_, $data->{$_}->{'name'}} (keys %$data);
    $self->{'longname'} = $data{$param};
    return $self->_setref($ref);
  } else {
    die("Error: Ellipsoid $param was not found");
  }
}

=head2 shortname

Method returns the shortname, which is the hash key, of the current ellipsoid

  my $shortname=$obj->shortname;

=cut

sub shortname {
  my $self = shift();
  return $self->{'shortname'};
}

=head2 longname

Method returns the long name of the current ellipsoid

  my $longname=$obj->longname;

=cut

sub longname {
  my $self = shift();
  return $self->{'longname'};
}

=head2 data

Method returns a hash reference for the ellipsoid definition data structure.

  my $datastructure=$obj->data;

=cut

sub data {
#Information from
#  http://earth-info.nga.mil/GandG/coordsys/datums/datumorigins.html
#  http://www.ngs.noaa.gov/PC_PROD/Inv_Fwd/

  return {

    WGS84=>{name=>'World Geodetic System of 1984',
            data=>{a=>6378137,i=>298.257223563},
            alias=>[qw{WGS-84 NAD83 NAD-83}]},

    GRS80=>{name=>'Geodetic Reference System of 1980',
            data=>{a=>6378137,i=>298.25722210088},
            alias=>['GRS-80','GDA','Geocentric Datum of Australia']},
    
    'Clarke 1866'=>{name=>'Clarke Ellipsoid of 1866',
                    data=>{a=>6378206.4,i=>294.9786982138},
                    alias=>[qw{NAD27 NAD-27}]},
    
    'Airy 1858'=>{name=>'Airy 1858 Ellipsoid',
                  data=>{a=>6377563.396,i=>299.3249646}},


    'Airy Modified'=>{name=>'Modified Airy Spheroid',
                      data=>{a=>6377340.189,b=>6356034.448}},

    'Australian National'=>{name=>'Australian National Spheroid of 1965',
                            data=>{a=>6378160,i=>298.25},
                            alias=>["Australian 1965"]},

    'Bessel 1841'=>{name=>'Bessel 1841 Ellipsoid',
                    data=>{a=>6377397.155,i=>299.1528128}},

    'Clarke 1880'=>{name=>'Clarke Ellipsoid of 1880',
                    data=>{a=>6378249.145,b=>6356514.966}},

    'Clarke 1866'=>{name=>'Clarke Ellipsoid of 1866',
                    data=>{a=>6378206.4,b=>6356583.8}},

    'Danish 1876'=>{name=>'Danish Spheroid of 1876',
                     data=>{a=>3271883.25*1.94903631,i=>300.00}},

    'Everest 1830'=>{name=>'Everest Spheroid of 1830',
                     data=>{a=>6377276.345,i=>300.8017}},

    'Everest Modified'=>{name=>'Modified Everest Spheroid',
                         data=>{a=>6377304.063,i=>300.8017}},

    'Fisher 1960'=>{name=>'Fisher 1960',
                    data=>{a=>6378166,i=>298.3}},

    'Fisher 1968'=>{name=>'Fisher 1968',
                    data=>{a=>6378150,i=>298.3}},

    'Hough 1956'=>{name=>'Hough 1956',
                   data=>{a=>6378270,i=>297}},

    'International (Hayford)'=>{name=>'International - 1924 (Hayford - 1909)',
                                data=>{a=>6378388,i=>297}},

    'Krassovsky 1938'=>{name=>'Krassovsky 1938',
                        data=>{a=>6378245,i=>298.3},
                        alias=>["Krasovsky 1940"]},

    'NWL-9D'=>{name=>'NWL-9D Ellipsoid',
               data=>{a=>6378145,i=>298.25},
               alias=>['WGS-66'=>'World Geodetic System 1966']},

    'SA69'=>{name=>'South American 1969',
             data=>{a=>6378160,i=>298.25},
             alias=>['SA-69']},

    'SGS85'=>{name=>'Soviet Geodetic System 1985',
              data=>{a=>6378136,i=>298.257},
              alias=>['SGS-85']},

    'WGS72'=>{name=>'World Geodetic System 1972',
              data=>{a=>6378135,i=>298.26},
              alias=>['WGS-72']},

    'WOS'=>{name=>'War Office Spheroid',
            data=>{a=>6378300.58,i=>296}},

    'UTM'=>{name=>'Department of the Army Universal Transverse Mercator',
            data=>{a=>6378249.2,b=>6356515.0}},
  };
}

=head2 name2ref

Method returns a hash reference (e.g. {a=>6378137,i=>298.257223563}) when passed a valid ellipsoid name (e.g. 'WGS84').

  my $ref=$obj->name2ref('WGS84')

=cut

sub name2ref {
  my $self=shift();
  my $key=shift();
  my $data=$self->data;
  return $data->{$key}->{'data'};
}

1;

__END__

=head1 TODO

What should we do about bad input?  I tend to die in the module which for most situations is fine.  I guess you could always overload die to handle exceptions for web based solutions and the like.

Support for ellipsoid aliases in the data structure

=head1 BUGS

Please send to the geo-perl email list.

=head1 LIMITS

No guarantees that Perl handles all of the double precision calculations in the same manner as Fortran.

=head1 AUTHOR

Michael R. Davis qw/perl michaelrdavis com/

=head1 LICENSE

Copyright (c) 2006 Michael R. Davis (mrdvt92)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Geo::Forward
Geo::Ellipsoid
Geo::Coordinates::UTM
Geo::GPS::Data::Ellipsoid
GIS::Distance

=cut

__END__
#Information from
#  http://earth-info.nga.mil/GandG/coordsys/datums/datumorigins.html
#  http://www.ngs.noaa.gov/PC_PROD/Inv_Fwd/
#
#  @DATA=([DATA, 0, a, #, i|b|f, #], ...);
#  @NAME=([NAME, 0, short_name, long_name], ...);
#  @ALIAS=([ALIAS, 0, alias, alias, alias,...], ...);

DATA:0:a:6378137:i:298.257223563
NAME:0:WGS84:World Geodetic System of 1984
ALIAS:0:WGS-84:NAD83:NAD-83

DATA:1:a:6378137:i:298.25722210088
NAME:1:GRS80:Geodetic Reference System of 1980
ALIAS:1:GRS-80

DATA:2:a:6378206.4:i:294.9786982138
NAME:2:Clarke 1866:Clarke Ellipsoid - 1866
ALIAS:NAD27:NAD-27

DATA:3:a:6377563.396:i:299.3249646
NAME:3:Airy 1858:Airy 1858

#DATA:4:a:6377340.189:i:299.3249646
DATA:4:a:6377340.189:b:6356034.448
NAME:4:Airy Modified:Modified Airy Spheroid

DATA:5:a:6378160:i:298.25
NAME:5:Australian National:Australian National Spheroid

DATA:6:a:6377397.155:i:299.1528128
NAME:6:Bessel 1841:Bessel 1841

#DATA:7:a:6378249.145:i:293.465
DATA:7:a:6378249.145:b:6356514.966
NAME:7:Clarke 1880:Clarke 1880

DATA:8:a:6377276.345:i:300.8017
NAME:8:Everest 1830:Everest Spheroid 1830

DATA:9:a:6377304.063:i:300.8017
NAME:9:Everest Modified:Modified Everest Spheroid

DATA:10:a:6378166:i:298.3
NAME:10:Fisher 1960:Fisher 1960

DATA:11:a:6378150:i:298.3
NAME:11:Fisher 1968:Fisher 1968

DATA:12:a:6378270:i:297
NAME:12:Hough 1956:Hough 1956

DATA:13:a:6378388:i:297
NAME:13:International (Hayford):International (Hayford)

DATA:14:a:6378245:i:298.3
NAME:14:Krassovsky 1938:Krassovsky 1938

DATA:15:a:6378145:i:298.25
NAME:15:NWL-9D:NWL-9D Ellipsoid
ALIAS:15:WGS-66:World Geodetic System 1966

DATA:16:a:6378160:i:298.25
NAME:16:SA69:South American 1969
ALIAS:16:SA-69

DATA:17:a:6378136:i:298.257
NAME:17:SGS85:Soviet Geodetic System 1985
ALIAS:17:SGS-85

DATA:18:a:6378135:i:298.26
NAME:18:WGS72:World Geodetic System 1972
ALIAS:18:WGS-72

DATA:19:a:6378300.58:i:296
NAME:19:WOS:War Office Spheroid

DATA:20:a:6378249.2:b:6356515.0
NAME:20:UTM:Department of the Army Universal Transverse Mercator
