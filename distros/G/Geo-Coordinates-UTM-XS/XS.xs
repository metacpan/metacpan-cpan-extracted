/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <string.h>

#include "ppport.h"

const double pi = 3.14159265358979;

const double deg2rad = 0.0174532925199433;
const double rad2deg = 57.2957795130823;

const double k0 = 0.9996;
const double inv_k0 = 1.00040016006403;

#define MAX_ELLIPSOIDS 100

struct ellipsoid {
    int defined;
    double radius;
    double inv_radius;
    double eccentricity_2;
    double eccentricity_4;
    double eccentricity_6;
    double eccentricity_prime_2;
};

static struct ellipsoid ellipsoids[MAX_ELLIPSOIDS];

static char latitude_letter[] = "CDEFGHJKLMNPQRSTUVWXX";

static HV *ellipsoid_hv;

int
ellipsoid_index(pTHX_ SV *name) {
    /* Perl_warn(aTHX_ "looking for ellipsoid %_\n", name); */
    if (SvIOK(name)) {
        return SvIV(name);
    }
    {
        HE *he = hv_fetch_ent(ellipsoid_hv, name, FALSE, 0);
        if (he) {
            SV *sv = HeVAL(he);
            if (sv && SvIOK(sv)) {
                /* Perl_warn(aTHX_ "found at %i\n", SvIV(sv)); */
                return SvIV(sv);
            }
        }
    }
    {
        int n, index;
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(name);
        PUTBACK;
        n = call_pv("Geo::Coordinates::UTM::XS::_ellipsoid_index", G_SCALAR);
        SPAGAIN;
        if (n != 1)
            Perl_croak(aTHX_ "internal error: _ellipsoid_index failed");
        index = POPi;
        PUTBACK;
        FREETMPS;
        LEAVE;
        return index;
    }
}

void
_zonesv_to_number_letter(pTHX_ SV *zone, int *zone_number, char *zone_letter) {
    int i;
    STRLEN zone_len;
    char *zone_pv = SvPV(zone, zone_len);
    int zone_ok = 1;

    for (i=0; i<zone_len; i++) {
        if (zone_pv[i] >= '0' && zone_pv[i] <= '9') continue;
        if (i+1 == zone_len) {
            *zone_letter = zone_pv[i];
            if(strchr(latitude_letter, *zone_letter)) continue;
        }
        zone_ok = 0;
        break;
    }
    if (zone_ok) {
        (*zone_number) = atoi(zone_pv);
        if ((*zone_number) < 1 || (*zone_number) > 60)
            zone_ok = 0;
    }
    if(!zone_ok)
        Perl_croak(aTHX_ "UTM zone (%s) invalid.", zone_pv);
}

void
_latlon_to_utm(pTHX_ SV *ename, double latitude_deg, double longitude_deg,
               int *zone, char *zone_letter, double *easting, double *northing) {
    dSP;
    int index;
    double radius;
    double eccentricity_2, eccentricity_4, eccentricity_6, eccentricity_prime_2;
    double longitude_origin_deg, longitude_origin;
    double latitude, delta_longitude, delta_longitude_deg;
    double sin_latitude, cos_latitude, tan_latitude, sin_latitude_2, cos_latitude_2;
    double sin_2_latitude, cos_2_latitude, sin_4_latitude, cos_4_latitude, sin_6_latitude;
    double N, tan_latitude_2, tan_latitude_4, tan_latitude_6, C, A, A_2, A_3, A_4, A_5, A_6, M;
    
    index = ellipsoid_index(aTHX_ ename);
    
    /* Perl_warn(aTHX_ "ename: %_, eindex: %d", ename, index); */
    
    if (index < 1 || index >= MAX_ELLIPSOIDS || !ellipsoids[index].defined) {
        Perl_croak(aTHX_ "invalid ellipsoid index %i", index);
    }
    
    if (longitude_deg < -180.0 || longitude_deg > 180)
        Perl_croak(aTHX_ "Longitude value (%f) invalid.", longitude_deg);
    
    if (longitude_deg == 180)
        longitude_deg = -180;
    
    if (latitude_deg < -80 || latitude_deg > 84.0)
        Perl_croak(aTHX_ "Latitude (%f) out of UTM range", latitude_deg);

    if (!*zone_letter)
        *zone_letter = latitude_letter[(int)(10 + latitude_deg / 8)];
    
    radius = ellipsoids[index].radius;
    eccentricity_2 = ellipsoids[index].eccentricity_2;
    eccentricity_4 = ellipsoids[index].eccentricity_4;
    eccentricity_6 = ellipsoids[index].eccentricity_6;

    eccentricity_prime_2 = ellipsoids[index].eccentricity_prime_2;

    if (!(*zone)) {
        if (latitude_deg >= 56.0 && latitude_deg < 64.0 && longitude_deg >= 3.0 && longitude_deg < 12.0) {
            (*zone) = 32;
        }
        else if (latitude_deg >= 72.0 && latitude_deg < 84.0) {
            if (longitude_deg >= 0.0) {
                if (longitude_deg < 9.0)
                    (*zone) = 31;
                else if (longitude_deg < 21.0)
                    (*zone) = 33;
                else if (longitude_deg < 33.0)
                    (*zone) = 35;
                else if (longitude_deg < 42.0)
                    (*zone) = 37;
                else
                    (*zone) = (longitude_deg + 180)/6 + 1;
            }
            else {
                (*zone) = (longitude_deg + 180)/6 + 1;
            }
        }
        else {
            (*zone) = (longitude_deg + 180)/6 + 1;
        }
    }
    
    latitude = deg2rad * latitude_deg;
    // longitude = deg2rad * longitude_deg;

    longitude_origin_deg = ((*zone) - 1) * 6 - 180 + 3;

    delta_longitude_deg = longitude_deg - longitude_origin_deg;
    if (delta_longitude_deg > 180)
        delta_longitude_deg -= 360;
    if (delta_longitude_deg < -180)
        delta_longitude_deg += 360;
    delta_longitude = deg2rad * delta_longitude_deg;
        
    sin_latitude = sin(latitude);
    cos_latitude = cos(latitude);
    tan_latitude = sin_latitude / cos_latitude;
    
    sin_latitude_2 = sin_latitude * sin_latitude;
    cos_latitude_2 = cos_latitude * cos_latitude;

    sin_2_latitude = 2.0 * sin_latitude * cos_latitude;
    cos_2_latitude = cos_latitude_2 - sin_latitude_2;
    
    sin_4_latitude = 2.0 * sin_2_latitude * cos_2_latitude;
    cos_4_latitude = cos_2_latitude * cos_2_latitude - sin_2_latitude * sin_2_latitude;
    
    sin_6_latitude = sin_2_latitude * cos_4_latitude + sin_4_latitude * cos_2_latitude;
        
    N = radius / sqrt(1 - eccentricity_2 * sin_latitude_2);
    tan_latitude_2 = tan_latitude * tan_latitude;
    C = eccentricity_prime_2 * cos_latitude_2;
    A = cos_latitude * delta_longitude;
    M = radius * ( ( 1 - 0.25 * eccentricity_2 - (3./64.) * eccentricity_4 - (5./256.) * eccentricity_6 ) * latitude
                   - ( (3./8.) * eccentricity_2 + (3./32.) * eccentricity_4 + (45./1024.) * eccentricity_6) * sin_2_latitude
                   + ( ( 15./256.) * eccentricity_4 + (45./1024.) * eccentricity_6) * sin_4_latitude
                   - (35./3072.) * eccentricity_6 * sin_6_latitude);

    A_2 = A * A;
    A_3 = A_2 * A;
    A_4 = A_3 * A;
    A_5 = A_4 * A;
    A_6 = A_5 * A;

    tan_latitude_4 = tan_latitude_2 * tan_latitude_2;
        
    *easting =   500000.0 + k0 * N * (A + (1 - tan_latitude_2 + C) * A_3 * (1./6.) + (5 - 18 * tan_latitude_2 + tan_latitude_4 + 72 * C - 58 * eccentricity_prime_2) * A_5 * (1./120.));

    *northing= k0 * ( M + N * tan_latitude * ( A * A / 2 + (5 - tan_latitude_2 + 9 * C + 4 * C * C) * A_4 * (1./ 24.)
                                             + (61 - 58 * tan_latitude_2 + tan_latitude_4 + 600 * C - 330 * eccentricity_prime_2) * A_6 * (1./720.)));

    if ((*zone_letter) < 'N')
        *northing += 10000000.0;
}
    

MODULE = Geo::Coordinates::UTM::XS		PACKAGE = Geo::Coordinates::UTM::XS		
PROTOTYPES: ENABLE

BOOT:
memset(ellipsoids, 0, sizeof(ellipsoids));
ellipsoid_hv = GvHV(gv_fetchpv("Geo::Coordinates::UTM::XS::_ellipsoid", TRUE, SVt_PVHV));

void
_set_ellipsoid_info(index, radius, eccentricity_2)
    int index
    double radius
    double eccentricity_2
PROTOTYPE: @
CODE:
    {
        if (index < 1 || index >= MAX_ELLIPSOIDS || ellipsoids[index].defined) {
            Perl_croak(aTHX_ "invalid ellipsoid index %i", index);
        }
        ellipsoids[index].radius = radius;
        ellipsoids[index].inv_radius = 1.0/radius;
        ellipsoids[index].eccentricity_2 = eccentricity_2;
        ellipsoids[index].eccentricity_4 = eccentricity_2 * eccentricity_2;
        ellipsoids[index].eccentricity_6 = eccentricity_2 * eccentricity_2 * eccentricity_2;
        ellipsoids[index].eccentricity_prime_2 = eccentricity_2/(1-eccentricity_2);
        ellipsoids[index].defined = 1;
    }

void
_latlon_to_utm(ename, latitude_deg, longitude_deg)
    SV *ename
    double latitude_deg
    double longitude_deg
PROTOTYPE: $$$
PREINIT:
    int zone = 0;
    char zone_letter = 0;
    double easting, northing;
PPCODE:
    _latlon_to_utm(aTHX_ ename, latitude_deg, longitude_deg,
                   &zone, &zone_letter, &easting, &northing);
    XPUSHs(sv_2mortal(newSVpvf("%d%c", zone, zone_letter)));
    XPUSHs(sv_2mortal(newSVnv(easting)));
    XPUSHs(sv_2mortal(newSVnv(northing)));
    XSRETURN(3);

void
_latlon_to_utm_force_zone(ename, zone, latitude_deg, longitude_deg)
    SV *ename
    SV *zone
    double latitude_deg
    double longitude_deg
PROTOTYPE: $$$$
PREINIT:
    int zone_number;
    char zone_letter;
    double easting, northing;
PPCODE:
    zone_letter = 0;
    _zonesv_to_number_letter(aTHX_ zone, &zone_number, &zone_letter);
    if (zone_number < 0 || zone_number > 60)
        Perl_croak(aTHX_ "Zone value (%d) invalid.", zone_number);
    _latlon_to_utm(aTHX_ ename, latitude_deg, longitude_deg,
                   &zone_number, &zone_letter, &easting, &northing);
    XPUSHs(sv_2mortal(newSVpvf("%d%c", zone_number, zone_letter)));
    XPUSHs(sv_2mortal(newSVnv(easting)));
    XPUSHs(sv_2mortal(newSVnv(northing)));
    XSRETURN(3);



void
_utm_to_latlon(ename, zone, easting, northing)
    SV *ename
    SV *zone
    double easting
    double northing
PROTOTYPE: $$$$
PPCODE:
    {
        int index;
        double radius, inv_radius, eccentricity_2, eccentricity_4, eccentricity_6, eccentricity_prime_2;
        double x, y;
        double longitude_origin_deg;
        double M, mu, e1, e1_2, e1_3, e1_4, phi1, N1, N2, N3, tan_phi1_2, C1, C1_2, R1, D, D_2, D_3, D_4, D_5, D_6;
        double sin_phi1, cos_phi1, inv_cos_phi1, tan_phi1, sin_phi1_2, tan_phi1_4;
        double latitude_deg, longitude_deg;
        int zone_number;
        char zone_letter;
        int i, zone_ok;

        index = ellipsoid_index(aTHX_ ename);
        
        if (index < 1 || index >= MAX_ELLIPSOIDS || !ellipsoids[index].defined) {
            Perl_croak(aTHX_ "invalid ellipsoid index %i", index);
        }

        radius = ellipsoids[index].radius;
        inv_radius = ellipsoids[index].inv_radius;

        eccentricity_2 = ellipsoids[index].eccentricity_2;
        eccentricity_4 = ellipsoids[index].eccentricity_4;
        eccentricity_6 = ellipsoids[index].eccentricity_6;
        eccentricity_prime_2 = ellipsoids[index].eccentricity_prime_2;

        zone_letter = 'N';
        _zonesv_to_number_letter(aTHX_ zone, &zone_number, &zone_letter);

        x = easting - 500000.0;
        y = northing;
        if (zone_letter < 'N')
            y -= 10000000.0;
        
        M = inv_k0 * y;
        mu = M / (radius * (1 - eccentricity_2 * (1./4.) - eccentricity_4 * (3./64.) - eccentricity_6 * (5./256.)));
        e1 = -1 + 2 * (1 - sqrt(1 - eccentricity_2)) / eccentricity_2;

        e1_2 = e1 * e1;
        e1_3 = e1_2 * e1;
        e1_4 = e1_3 * e1;
        
        phi1 = mu + (1.5 * e1 - e1_3 * (27./32.)) * sin(2 * mu) + (e1_2 * (21./16.) - e1_4 * (55./32.)) * sin(4 * mu) + (e1_3 * (151./96.)) * sin(6 * mu);

        sin_phi1 = sin(phi1);
        cos_phi1 = cos(phi1);
        inv_cos_phi1 = 1.0 / cos_phi1;
        tan_phi1 = sin_phi1 * inv_cos_phi1;

        sin_phi1_2 = sin_phi1 * sin_phi1;

        N3 = sqrt(1 - eccentricity_2 * sin_phi1_2);
        N2 = 1.0 / N3;
        N1 = radius * N2;
        
        tan_phi1_2 = tan_phi1 * tan_phi1;
        tan_phi1_4 = tan_phi1_2 * tan_phi1_2;
        
        C1 = eccentricity_2 * cos_phi1 * cos_phi1;
        C1_2 = C1 * C1;
        
        R1 = radius * (1-eccentricity_2) * N2 * N2 * N2;
        
        D = inv_k0 * inv_radius * N3 * x;
        D_2 = D * D;
        D_3 = D_2 * D;
        D_4 = D_3 * D;
        D_5 = D_4 * D;
        D_6 = D_5 * D;

        latitude_deg = rad2deg * (phi1 - (N1 * tan_phi1 / R1) * (D_2 / 2 - (5 + 3 * tan_phi1_2 + 10 * C1 - 4 * C1_2 - 9 * eccentricity_prime_2) * D_4 * (1./24.)
                                                                  + (61 + 90 * tan_phi1_2 + 298 * C1 + 45 * tan_phi1_4 - 252 * eccentricity_prime_2 - 3 * C1_2) * D_6 * (1./720)));

        longitude_origin_deg = (zone_number - 1) * 6 - 180 + 3;
        longitude_deg = ((D - (1 + 2 * tan_phi1_2 + C1) * D_3 / 6 + (5 - 2 * C1 + 28 * tan_phi1_2 - 3 * C1_2 + 8 * eccentricity_prime_2 + 24 * tan_phi1_4) * D_5 * (1./120.)) * inv_cos_phi1) * rad2deg + longitude_origin_deg;

        if (longitude_deg < -180) longitude_deg += 360.0;
        if (longitude_deg > 180) longitude_deg -= 360.0;
        
        XPUSHs(sv_2mortal(newSVnv(latitude_deg)));
        XPUSHs(sv_2mortal(newSVnv(longitude_deg)));
    }
    XSRETURN(2);

