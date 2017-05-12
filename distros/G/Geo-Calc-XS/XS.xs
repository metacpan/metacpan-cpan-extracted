#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <float.h>
#include <math.h>

#if __GNUC__ >= 3
# define expect(expr,value)         __builtin_expect ((expr), (value))
# define INLINE                     static inline
#else
# define expect(expr,value)         (expr)
# define INLINE                     static
#endif

#define PI 3.14159265358979323846
#define DEG2RAD(DEG) ((DEG)*((PI)/(180.0)))
#define RAD2DEG(DEG) ((DEG)*(180.0/PI))

#define INT_NOT_R int

enum DISTANCE_UNIT_ENUM {
    UNIT_METERS,
    UNIT_KM,
    UNIT_YARDS,
    UNIT_FEET,
    UNIT_MILES
};

typedef struct {
  /* Coords */
  long double latitude;
  long double longitude;

  /* Distance Units */
  enum DISTANCE_UNIT_ENUM unit_conv;

  /* Earth Radius */
  long double radius;
} GCX;

typedef struct {
    long double lat;
    long double lon;
    long double final_bearing;
} DESTINATION;

typedef struct {
    long double lat;
    long double lon;
} POINT;

INLINE void
geocalc_init( GCX *gcx, HV * options )
{
  Zero( gcx, 1, GCX );
  SV** sv_lat = hv_fetch(options, "lat", strlen("lat"), 0);
  if (! sv_lat) {
    croak("lat must be specified");
  }
  SV** sv_lon = hv_fetch(options, "lon", strlen("lon"), 0);
  if (! sv_lon) {
    croak("lon must be specified");
  }
  gcx->latitude  = (long double) SvNV( *sv_lat );
  gcx->longitude = (long double) SvNV( *sv_lon );

  SV ** sv = hv_fetch(options, "units", 5, 0);
  if( sv == (SV**)NULL ) {
    gcx->unit_conv = UNIT_METERS;    // Default to m
  } else {
    if( strEQ( SvPV_nolen( *sv ), "m" ) ) {
      gcx->unit_conv = UNIT_METERS;
    } else if( strEQ( SvPV_nolen( *sv ), "k-m" ) ) {
      gcx->unit_conv = UNIT_KM;
    } else if( strEQ( SvPV_nolen( *sv ), "yd" ) ) {
      gcx->unit_conv = UNIT_YARDS;
    } else if( strEQ( SvPV_nolen( *sv ), "ft" ) ) {
      gcx->unit_conv = UNIT_FEET;
    } else if( strEQ( SvPV_nolen( *sv ), "mi" ) ) {
      gcx->unit_conv = UNIT_MILES;
    } else if( strEQ( SvPV_nolen( *sv ), "" ) ) {
      gcx->unit_conv = UNIT_METERS;
    } else {
      warn("Unrecognised unit (defaulting to m)");
      gcx->unit_conv = UNIT_METERS;
    }
  }
  /*
  sv = hv_fetch(options, "radius", 6, 0);
  if( sv == (SV**)NULL ) {
    gcx->radius = 6371;    // Default to KM
  } else {
    gcx->radius = 6371;    // Default to KM
  }
  */
  gcx->radius    = 6371; // Earth Radius
}

INLINE long double
convert_km( long double input, enum DISTANCE_UNIT_ENUM to_unit )
{
  double output = 0;

  switch( to_unit )
  {
    case UNIT_METERS : output = input * 1000;        break;
    case UNIT_KM     : output = input;               break;
    case UNIT_YARDS  : output = input * 1093.6133;   break;
    case UNIT_FEET   : output = input * 3280.8399;   break;
    case UNIT_MILES  : output = input * 0.621371192; break;
    default          : output = input;               break; // kilometers
  }

  return output;
}

INLINE long double
convert_to_m( long double input, enum DISTANCE_UNIT_ENUM from_unit )
{
  double output = 0;

  switch( from_unit )
  {
    case UNIT_METERS : output = input;            break;
    case UNIT_KM     : output = input * 1000;     break;
    case UNIT_YARDS  : output = input * 0.9144;   break;
    case UNIT_FEET   : output = input * 0.3048;   break;
    case UNIT_MILES  : output = input * 1609.344; break;
    default          : output = input * 1000;     break; // killometers
  }

  return output;
}

INLINE long double
cint( double x ) {
    double f;
    if ( modf( x, &f ) >= 0.5 )
        return ( x >= 0 ) ? ceil( x ) : floor( x );
    else
        return ( x < 0 ) ? ceil( x ) : floor( x );
}

INLINE long double
_precision_ld( long double r, int places ) {
    long double off = pow( 10, -places );
    return cint( r * off ) / off;
}

INLINE long double
_ib_precision( long double brng, int precision, int mul ) {
    return _precision_ld( (long double)fmod( mul * ( RAD2DEG( brng ) ) + 360, 360 ), precision );
}

INLINE long double
_fb_precision( long double brng, int precision ) {
    return _precision_ld( (long double)fmod( ( RAD2DEG( brng ) ) + 180, 360 ), precision );
}


INLINE void
_destination_point( GCX *self, double bearing, double s, int precision, DESTINATION *dest )
{
    s = convert_to_m( s, self->unit_conv );

    long double r_major    = 6378137;           // Equatorial Radius, WGS84
    long double r_minor    = 6356752.314245179; // defined as constant
    long double f          = 1/298.257223563;   // 1/f = ( $r_major - $r_minor ) / $r_major

    long double alpha1     = DEG2RAD( bearing );
    long double sinAlpha1  = sin( alpha1 );
    long double cosAlpha1  = cos( alpha1 );

    long double tanU1      = ( 1 - f ) * tan( DEG2RAD( self->latitude ) );
    long double cosU1      = 1 / sqrt( ( 1 + ( tanU1 * tanU1 ) ) );
    long double sinU1      = tanU1 * cosU1;
    long double sigma1     = atan2( tanU1, cosAlpha1 );
    long double sinAlpha   = cosU1 * sinAlpha1;
    long double cosSqAlpha = 1 - ( sinAlpha * sinAlpha );

    long double uSq        = cosSqAlpha * ( ( r_major * r_major ) - ( r_minor * r_minor ) ) / ( r_minor * r_minor );
    long double A          = 1 + uSq/16384*(4096+uSq*(-768+uSq*(320-175*uSq)));
    long double B          = uSq/1024 * (256+uSq*(-128+uSq*(74-47*uSq)));

    long double sigma      = s / ( r_minor * A );
    long double sigmaP     = PI * 2;

    long double cos2SigmaM = cos(2*sigma1 + sigma);
    long double sinSigma   = sin(sigma);
    long double cosSigma   = cos(sigma);

    while ( abs(sigma - sigmaP) > 1 * pow( 10, -12 ) ) {
        cos2SigmaM = cos(2*sigma1 + sigma);
        sinSigma   = sin(sigma);
        cosSigma   = cos(sigma);

        long double deltaSigma = B*sinSigma*(cos2SigmaM+B/4*(cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)-
                  B/6*cos2SigmaM*(-3+4*sinSigma*sinSigma)*(-3+4*cos2SigmaM*cos2SigmaM)));
        sigmaP                 = sigma;
        sigma                  = s / (r_minor*A) + deltaSigma;
    }

    long double tmp    = sinU1*sinSigma - cosU1*cosSigma*cosAlpha1;
    long double lat2   = atan2( sinU1*cosSigma + cosU1*sinSigma*cosAlpha1, (1-f)*sqrt(sinAlpha*sinAlpha + tmp*tmp) );

    long double lambda = atan2(sinSigma*sinAlpha1, cosU1*cosSigma - sinU1*sinSigma*cosAlpha1);
    long double C      = f/16*cosSqAlpha*(4+f*(4-3*cosSqAlpha));
    long double L      = lambda - (1-C) * f * sinAlpha * (sigma + C*sinSigma*(cos2SigmaM+C*cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)));

    long double lon2   = fmod( DEG2RAD( self->longitude ) + L + ( PI * 3 ), PI * 2 ) - PI;
    long double revAz  = atan2( sinAlpha, -tmp ); // final bearing, if required

    dest->lat = _precision_ld( RAD2DEG( lat2 ), precision );
    dest->lon = _precision_ld( RAD2DEG( lon2 ), precision );
    dest->final_bearing = _precision_ld( RAD2DEG( revAz ), precision );
}


MODULE = Geo::Calc::XS         PACKAGE = Geo::Calc::XS

PROTOTYPES: DISABLE

void new ( char *klass, ... )
    PREINIT:
        int add_count = items - 1;
    PPCODE:
    {
        SV *pv = NEWSV ( 0, sizeof( GCX ) );
        HV *options = newHV();
        int i = 0;
        SvPOK_only( pv );
        if( add_count % 2 != 0 )
            croak( "Please check your parameters while initiating the module\n" );

        for( i = 0; i < add_count; i = i + 2 ) {
            char *key = SvPV_nolen(ST(i + 1));
            if (! (0 == strcmp(key, "lat") || 0 == strcmp(key, "lon") || 0 == strcmp(key, "units")
                || 0 == strcmp(key, "radius"))) {
                croak("Unexpected key '%s'", key);
            }
            hv_store_ent( options, ST( i + 1 ), newSVsv(ST( i + 2)), 0);
        }

        geocalc_init( (GCX *)SvPVX( pv ), options );

        SvREFCNT_dec((SV *) options);

        XPUSHs( sv_2mortal( sv_bless( newRV_noinc( pv ), gv_stashpv( klass, 1 )) ) );
    }

long double
get_lat ( GCX *self )
    CODE:
        RETVAL = self->latitude;
    OUTPUT:
        RETVAL

long double
get_lon ( GCX *self )
    CODE:
        RETVAL = self->longitude;
    OUTPUT:
        RETVAL

char *
get_units ( GCX *self )
    CODE:
        switch ( self->unit_conv)
        {
            case UNIT_METERS:
                RETVAL = "m";
                break;
            case UNIT_KM:
                RETVAL = "k-m";
                break;
            case UNIT_YARDS:
                RETVAL = "yd";
                break;
            case UNIT_FEET:
                RETVAL = "ft";
                break;
            default:
                RETVAL = "mi";
        }
    OUTPUT:
        RETVAL

long double
get_radius ( GCX *self )
    CODE:
        RETVAL = self->radius;
    OUTPUT:
        RETVAL

long double
distance_to( GCX *self, POINT *to_latlon, INT_NOT_R precision = -6 )
    CODE:
    {
        long double lat1 = DEG2RAD( self->latitude );
        long double lon1 = DEG2RAD( self->longitude );
        long double lat2 = DEG2RAD( to_latlon->lat );
        long double lon2 = DEG2RAD( to_latlon->lon );

        long double t = pow( sin( ( lat2 - lat1 ) / 2 ), 2 ) + ( pow( cos( lat1 ), 2 ) * pow( sin( ( lon2 - lon1 )/2 ), 2 ) );
        long double d = convert_km( self->radius * ( 2 * atan2( sqrt(t), sqrt(1-t) ) ), self->unit_conv );

        RETVAL = _precision_ld( d, precision );
    }
    OUTPUT:
        RETVAL

HV *
destination_point( GCX *self, double bearing, double s, INT_NOT_R precision = -6 )
    CODE:
    {
        DESTINATION dest;
        _destination_point( self, bearing, s, precision, &dest );

        HV *retval = newHV();
        hv_store( retval, "lat", 3, newSVnv( dest.lat ), 0 );
        hv_store( retval, "lon", 3, newSVnv( dest.lon ), 0 );
        hv_store( retval, "final_bearing", 13, newSVnv( dest.final_bearing ), 0 );
        RETVAL = retval;
        sv_2mortal((SV *) RETVAL);
    }
    OUTPUT:
        RETVAL

HV *
boundry_box( GCX *self, ... )
    CODE:
    {
        /* Signature is:
         *    $self, $width, $height, $precision
         * The latter three arguments are optional
         */
        double width, height;
        int precision;
        DESTINATION dest;

        if (items < 2 || items > 4) {
            croak("Unexpected number of parameters");
        } else if (! ST(1) || ! SvOK(ST(1)) || SvROK(ST(1))) {
            croak("width is invalid");
        }
        width = SvNV(ST(1));

        if (items >= 3 && ST(2) && SvOK(ST(2)) && SvROK(ST(2))) {
            croak("height is not expected to be a reference");
        } else if (items >= 3 && ST(2) && SvOK(ST(2))) {
            height = SvNV(ST(2));
        } else {
            width = width * 2;
            height = width;
        }

        if (items >= 4 && ST(3) && SvOK(ST(3)) && SvROK(ST(3))) {
            croak("precision is not expected to be a reference");
        } else if (items >= 4 && ST(3) && SvOK(ST(3))) {
            precision = SvNV(ST(3));
        } else {
            precision = -6;
        }

        HV *retval = newHV();

        _destination_point( self, 180, height / 2, precision, &dest );
        hv_store( retval, "lat_min", 7, newSVnv( dest.lat ), 0 );

        _destination_point( self, 270, width  / 2, precision, &dest );
        hv_store( retval, "lon_min", 7, newSVnv( dest.lon ), 0 );

        _destination_point( self,   0, height / 2, precision, &dest );
        hv_store( retval, "lat_max", 7, newSVnv( dest.lat ), 0 );

        _destination_point( self,  90, width  / 2, precision, &dest );
        hv_store( retval, "lon_max", 7, newSVnv( dest.lon ), 0 );

        RETVAL = retval;
        sv_2mortal((SV *) RETVAL);
    }
    OUTPUT:
        RETVAL

HV *
midpoint_to( GCX *self, POINT *to_latlon, INT_NOT_R precision = -6 )
    CODE:
    {
        long double lat1 = DEG2RAD( self->latitude );
        long double lon1 = DEG2RAD( self->longitude );

        long double lat2 = DEG2RAD( to_latlon->lat );
        long double dlon = DEG2RAD( to_latlon->lon - self->longitude );

        long double bx = cos( lat2 ) * cos( dlon );
        long double by = cos( lat2 ) * sin( dlon );

        long double lat3 = atan2( sin( lat1 ) + sin ( lat2 ), sqrt( ( pow( ( cos( lat1 ) + bx ), 2 ) ) + pow( by, 2 ) ) );
        long double lon3 = fmod( lon1 + atan2( by, cos( lat1 ) + bx ) + ( PI * 3 ), PI * 2 ) - PI;

        HV *retval = newHV();
        hv_store( retval, "lat", 3, newSVnv( _precision_ld( RAD2DEG( lat3 ), precision ) ), 0 );
        hv_store( retval, "lon", 3, newSVnv( _precision_ld( RAD2DEG( lon3 ), precision ) ), 0 );

        RETVAL = retval;
        sv_2mortal((SV *) RETVAL);
    }
    OUTPUT:
        RETVAL

HV *
intersection( GCX *self, double brng1, POINT *to_latlon, double brng2, INT_NOT_R precision = -6 )
    CODE:
    {
        long double lat1   = DEG2RAD( self->latitude );
        long double lon1   = DEG2RAD( self->longitude );
        long double lat2   = DEG2RAD( to_latlon->lat );
        long double lon2   = DEG2RAD( to_latlon->lon );
        long double brng13 = DEG2RAD( brng1 );
        long double brng23 = DEG2RAD( brng2 );

        long double dlat   = lat2 - lat1;
        long double dlon   = lon2 - lon1;

        long double dist12 = 2 * asin( sqrt( pow( sin( dlat/2 ), 2 ) + cos( lat1 ) * cos( lat2 ) * pow( sin( dlon/2 ), 2 ) ) );
        if( dist12 == 0 ) {
            XSRETURN_UNDEF;
        }

        // initial/final bearings between points
        long double brnga, brngb;
        if( sin( dist12 ) * cos( lat1 ) > 0 ) {
            brnga = acos( ( sin( lat2 ) - sin( lat1 ) * cos( dist12 ) ) / ( sin( dist12 ) * cos( lat1 ) ) );
        } else {
            brnga = 0;
        }

        if( sin( dist12 ) * cos( lat2 ) > 0 ) {
            brngb = acos( ( sin( lat1 ) - sin( lat2 ) * cos( dist12 ) ) / ( sin( dist12 ) * cos( lat2 ) ) );
        } else {
            brngb = 0;
        }

        long double brng12, brng21;
        if( sin( dlon ) > 0 ) {
            brng12 = brnga;
            brng21 = PI*2 - brngb;
        } else {
            brng12 = PI*2 - brnga;
            brng21 = brngb;
        }

        long double alpha1 = fmod( brng13 - brng12 + ( PI * 3 ), PI * 2 ) - PI;
        long double alpha2 = fmod( brng21 - brng23 + ( PI * 3 ), PI * 2 ) - PI;

        if( ( sin( alpha1 ) == 0 ) && ( sin( alpha2 ) == 0 ) ) { // infinite intersections
            XSRETURN_UNDEF;
        }

        if( sin( alpha1 ) * sin( alpha2 ) < 0 ) { // ambiguous intersection
            XSRETURN_UNDEF;
        }

        long double alpha3 = acos( -cos( alpha1 ) * cos( alpha2 ) + sin( alpha1 ) * sin( alpha2 ) * cos( dist12 ) );
        long double dist13 = atan2( sin( dist12 ) * sin( alpha1 ) * sin( alpha2 ), cos( alpha2 ) + cos( alpha1 ) * cos( alpha3 ) );
        long double lat3 = asin( sin( lat1 ) * cos( dist13 ) + cos( lat1 ) * sin( dist13 ) * cos( brng13 ) );
        long double dlon13 = atan2( sin( brng13 ) * sin( dist13 ) * cos( lat1 ), cos( dist13 ) - sin( lat1 ) * sin( lat3 ) );
        long double lon3 = fmod( lon1 + dlon13 + ( PI * 3 ), PI * 2 ) - PI;

        HV *retval = newHV();
        hv_store( retval, "lat", 3, newSVnv( _precision_ld( RAD2DEG( lat3 ), precision ) ), 0 );
        hv_store( retval, "lon", 3, newSVnv( _precision_ld( RAD2DEG( lon3 ), precision ) ), 0 );

        RETVAL = retval;
        sv_2mortal((SV *) RETVAL);
    }
    OUTPUT:
        RETVAL

HV *
distance_at( GCX *self, INT_NOT_R precision = -6 )
    CODE:
    {
        long double lat = DEG2RAD( self->latitude );

        // Set up "Constants"
        double m1 = 111132.92; // latitude calculation term 1
        double m2 = -559.82;   // latitude calculation term 2
        double m3 = 1.175;     // latitude calculation term 3
        double m4 = -0.0023;   // latitude calculation term 4
        double p1 = 111412.84; // longitude calculation term 1
        double p2 = -93.5;     // longitude calculation term 2
        double p3 = 0.118;     // longitude calculation term 3.

        HV *retval = newHV();
        hv_store( retval, "m_lat", 5, newSVnv( _precision_ld( m1 + (m2 * cos(2 * lat)) + (m3 * cos(4 * lat)) + ( m4 * cos(6 * lat) ), precision ) ), 0 );
        hv_store( retval, "m_lon", 5, newSVnv( _precision_ld( ( p1 * cos(lat)) + (p2 * cos(3 * lat)) + (p3 * cos(5 * lat) ), precision ) ), 0 );

        RETVAL = retval;
        sv_2mortal((SV *) RETVAL);
    }
    OUTPUT:
        RETVAL

long double
bearing_to( GCX *self, POINT *to_latlon, INT_NOT_R precision = -6 )
    CODE:
    {
        long double lat1 = DEG2RAD( self->latitude );
        long double lat2 = DEG2RAD( to_latlon->lat );
        long double dlon = DEG2RAD( self->longitude - to_latlon->lon );

        long double brng = atan2( sin( dlon ) * cos( lat2 ), ( cos( lat1 ) * sin( lat2 ) ) - ( sin( lat1 ) * cos( lat2 ) * cos( dlon ) ) );

        RETVAL = _ib_precision( brng, precision, -1 );
    }
    OUTPUT:
        RETVAL

long double
final_bearing_to( GCX *self, POINT *to_latlon, INT_NOT_R precision = -6 )
    CODE:
    {
        long double lat1 = DEG2RAD( to_latlon->lat );
        long double lat2 = DEG2RAD( self->latitude );
        long double dlon = -DEG2RAD( to_latlon->lon - self->longitude );

        long double brng = atan2( sin( dlon ) * cos( lat2 ), ( cos( lat1 ) * sin( lat2 ) ) - ( sin( lat1 ) * cos( lat2 ) * cos( dlon ) ) );

        RETVAL = _fb_precision( brng, precision );
    }
    OUTPUT:
        RETVAL

long double
rhumb_distance_to( GCX *self, POINT *to_latlon, INT_NOT_R precision = -6 )
    CODE:
    {
        long double lat1 = DEG2RAD( self->latitude );
        long double lat2 = DEG2RAD( to_latlon->lat );
        long double dlat = DEG2RAD( to_latlon->lat - self->latitude );
        long double dlon = DEG2RAD( to_latlon->lon - self->longitude );
        if( dlon < 0 )
            dlon = -dlon;

        long double dphi = log( tan( lat2/2 + PI/4 ) / tan( lat1/2 + PI/4 ) );

        long double q;

        if ( dphi != 0 ) {
            q = dlat/dphi;
        } else {
            q = cos(lat1); // E-W line gives dPhi=0
        }

        if( dlon > PI )
            dlon = PI*2 - dlon;

        long double dist = sqrt( pow( dlat, 2 ) + pow( q, 2 ) * pow( dlon, 2 ) ) * self->radius;

        RETVAL = _precision_ld( convert_km( dist, self->unit_conv ), precision );
    }
    OUTPUT:
        RETVAL

long double
rhumb_bearing_to( GCX *self, POINT *to_latlon, INT_NOT_R precision = -6 )
    CODE:
    {
        long double lat1 = DEG2RAD( self->latitude );
        long double lat2 = DEG2RAD( to_latlon->lat );
        long double dlon = DEG2RAD( to_latlon->lon - self->longitude );

        long double dphi = log( tan( lat2/2 + PI/4 ) / tan( lat1/2 + PI/4 ) );
        long double abs_dphi = dphi;
        if( abs_dphi < 0 ) {
            abs_dphi = -abs_dphi;
        }

        if( abs_dphi > PI ) {
            dlon = ( dlon > 0 ) ? -( PI*2 - dlon ) : ( PI*2 + dlon );
        }

        RETVAL = _ib_precision( atan2( dlon, dphi ), precision, 1 );
    }
    OUTPUT:
        RETVAL

HV *
rhumb_destination_point( GCX *self, double brng, double s, INT_NOT_R precision = -6 )
    CODE:
    {
        long double d    = ( convert_to_m( s, self->unit_conv ) / 1000 ) / self->radius;

        long double lat1 = DEG2RAD( self->latitude );
        long double lon1 = DEG2RAD( self->longitude );
        brng             = DEG2RAD( brng );

        long double lat2 = lat1 + ( d * cos( brng ) );
        long double dlat = lat2 - lat1;
        long double dphi = log( tan( lat2/2 + PI/4 ) / tan( lat1/2 + PI/4 ) );
        long double q    = ( dphi != 0 ) ? dlat/dphi : cos(lat1); //# E-W line gives dPhi=0
        long double dlon = d * sin( brng ) / q;
        // check for some daft bugger going past the pole
        long double lat2_abs = lat2;
        if( lat2_abs < 0 )
            lat2_abs = -lat2_abs;

        if( lat2_abs > PI/2 )
            lat2 = ( lat2 ) > 0 ? PI-lat2 : -(PI-lat2);

        long double lon2 = fmod( lon1 + dlon + ( PI * 3 ), PI * 2 ) - PI;

        HV *retval = newHV();
        hv_store( retval, "lat", 3, newSVnv( _precision_ld( RAD2DEG( lat2 ), precision ) ), 0 );
        hv_store( retval, "lon", 3, newSVnv( _precision_ld( RAD2DEG( lon2 ), precision ) ), 0 );

        RETVAL = retval;
        sv_2mortal((SV *) RETVAL);
    }
    OUTPUT:
        RETVAL
