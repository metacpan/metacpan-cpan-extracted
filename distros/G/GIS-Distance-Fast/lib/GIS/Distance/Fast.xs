#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <math.h>

const double DEG_RADS = M_PI / 180.;
const double KILOMETER_RHO = 6371.64;

/* Sphere with equal meridian length */
const double RM = 6367449.14582342;

/* WGS 84 Ellipsoid */
const double A = 6378137.;
const double B = 6356752.314245;
const double F = 1. / 298.257223563;

double alt_distance(double lat1, double lon1, double lat2, double lon2) {
    double f = 0.5 * (lat2 + lat1) * DEG_RADS;
    double g = 0.5 * (lat2 - lat1) * DEG_RADS;
    double l = 0.5 * (lon2 - lon1) * DEG_RADS;

    double sf = sin(f), sg = sin(g), sl = sin(l);
    double s2f = sf * sf, s2g = sg * sg, s2l = sl * sl;
    double c2f = 1. - s2f, c2g = 1. - s2g, c2l = 1. - s2l;

    double s2 = s2g * c2l + c2f * s2l;
    double c2 = c2g * c2l + s2f * s2l;

    double s, c, omega, rr, aa, bb, pp, qq, d2, qp, eps1, eps2;

    if (s2 == 0.) return 0.;
    if (c2 == 0.) return M_PI * RM / 0.001;

    s = sqrt(s2), c = sqrt(c2);
    omega = atan2(s, c);
    rr = s * c;
    aa = s2g * c2f / s2 + s2f * c2g / c2;
    bb = s2g * c2f / s2 - s2f * c2g / c2;
    pp = rr / omega;
    qq = omega / rr;
    d2 = s2 - c2;
    qp = qq + 6. * pp;
    eps1 = 0.5 * F * (-aa - 3. * bb * pp);
    eps2 = 0.25 * F * F * ((-qp * bb + (-3.75 + d2 * (qq + 3.75 * pp)) *
            aa + 4. - d2 * qq) * aa - (7.5 * d2 * bb * pp - qp) * bb);

    double d = 2. * omega * A * (1. + eps1 + eps2);
    return d * 0.001;
}

double cosine_distance(double lat1, double lon1, double lat2, double lon2) {
    lon1 *= DEG_RADS;
    lat1 *= DEG_RADS;
    lon2 *= DEG_RADS;
    lat2 *= DEG_RADS;

    double a = sin( lat1 ) * sin( lat2 );
    double b = cos( lat1 ) * cos( lat2 ) * cos( lon2 - lon1 );
    double c = acos( a + b );

    return KILOMETER_RHO * c;
}

double great_circle_distance(double lat1, double lon1, double lat2, double lon2) {
    lon1 *= DEG_RADS;
    lat1 *= DEG_RADS;
    lon2 *= DEG_RADS;
    lat2 *= DEG_RADS;

    double c = 2 * asin( sqrt(
        pow( sin((lat1-lat2)/2), 2.0 ) +
        cos(lat1) * cos(lat2) *
        pow( sin((lon1-lon2)/2), 2.0 )
    ) );

    return KILOMETER_RHO * c;
}

double haversine_distance(double lat1, double lon1, double lat2, double lon2) {
    lon1 *= DEG_RADS;
    lat1 *= DEG_RADS;
    lon2 *= DEG_RADS;
    lat2 *= DEG_RADS;

    double dlon = lon2 - lon1;
    double dlat = lat2 - lat1;
    double a = pow( sin(dlat/2.0), 2.0 ) + cos(lat1) * cos(lat2) * pow( sin(dlon/2.0), 2.0 );
    double c = 2.0 * atan2( sqrt(a), sqrt(fabs(1.0-a)) );

    return KILOMETER_RHO * c;
}

double null_distance(double lat1, double lon1, double lat2, double lon2) {
    return 0;
}

double polar_distance(double lat1, double lon1, double lat2, double lon2) {
    lon1 *= DEG_RADS;
    lat1 *= DEG_RADS;
    lon2 *= DEG_RADS;
    lat2 *= DEG_RADS;

    double a = M_PI / 2 - lat1;
    double b = M_PI / 2 - lat2;
    double c = sqrt( pow(a, 2.0) + pow(b, 2.0) - 2 * a * b * cos(lon2 - lon1) );

    return KILOMETER_RHO * c;
}

double vincenty_distance(double lat1, double lon1, double lat2, double lon2) {
    if ( (lon1==lon2) && (lat1==lat2) ) {
        return 0;
    }

    lon1 *= DEG_RADS;
    lat1 *= DEG_RADS;
    lon2 *= DEG_RADS;
    lat2 *= DEG_RADS;

    double a = 6378137.0;
    double b = 6356752.3142;
    double f = 1/298.257223563;

    double l = lon2 - lon1;

    double u1 = atan( (1-f) * tan(lat1) );
    double u2 = atan( (1-f) * tan(lat2) );

    double sin_u1 = sin(u1);
    double cos_u1 = cos(u1);
    double sin_u2 = sin(u2);
    double cos_u2 = cos(u2);

    double lambda     = l;
    double lambda_pi  = 2 * M_PI;
    int iter_limit = 20;

    double cos_sq_alpha = 0.0;
    double sin_sigma    = 0.0;
    double cos2sigma_m  = 0.0;
    double cos_sigma    = 0.0;
    double sigma        = 0.0;

    while( fabs(lambda-lambda_pi) > 1e-12 && --iter_limit>0 ){
        double sin_lambda = sin(lambda);
        double cos_lambda = cos(lambda);

        sin_sigma = sqrt((cos_u2*sin_lambda) * (cos_u2*sin_lambda) +
            (cos_u1*sin_u2-sin_u1*cos_u2*cos_lambda) * (cos_u1*sin_u2-sin_u1*cos_u2*cos_lambda));

        cos_sigma = sin_u1*sin_u2 + cos_u1*cos_u2*cos_lambda;
        sigma = atan2(sin_sigma, cos_sigma);

        double alpha = asin(cos_u1 * cos_u2 * sin_lambda / sin_sigma);
        cos_sq_alpha = cos(alpha) * cos(alpha);
        cos2sigma_m = cos_sigma - 2.0*sin_u1*sin_u2/cos_sq_alpha;

        double cc = f/16.0*cos_sq_alpha*(4.0+f*(4.0-3.0*cos_sq_alpha));
        lambda_pi = lambda;
        lambda = l + (1.0-cc) * f * sin(alpha) *
            (sigma + cc*sin_sigma*(cos2sigma_m+cc*cos_sigma*(-1.0+2.0*cos2sigma_m*cos2sigma_m)));
    }

    double usq = cos_sq_alpha*(a*a-b*b)/(b*b);
    double aa = 1.0 + usq/16384.0*(4096.0+usq*(-768.0+usq*(320.0-175.0*usq)));
    double bb = usq/1024.0 * (256.0+usq*(-128.0+usq*(74.0-47.0*usq)));
    double delta_sigma = bb*sin_sigma*(cos2sigma_m+bb/4.0*(cos_sigma*(-1.0+2.0*cos2sigma_m*cos2sigma_m)-
        bb/6.0*cos2sigma_m*(-3.0+4.0*sin_sigma*sin_sigma)*(-3.0+4.0*cos2sigma_m*cos2sigma_m)));
    double c = b*aa*(sigma-delta_sigma);

    return c / 1000;
}

MODULE = GIS::Distance::Fast     PACKAGE = GIS::Distance::Fast

PROTOTYPES: DISABLE

double
alt_distance (lat1, lon1, lat2, lon2)
    double lat1
    double lon1
    double lat2
    double lon2

double
cosine_distance (lat1, lon1, lat2, lon2)
    double lat1
    double lon1
    double lat2
    double lon2

double
great_circle_distance (lat1, lon1, lat2, lon2)
    double lat1
    double lon1
    double lat2
    double lon2

double
haversine_distance (lat1, lon1, lat2, lon2)
    double lat1
    double lon1
    double lat2
    double lon2

double
null_distance (lat1, lon1, lat2, lon2)
    double lat1
    double lon1
    double lat2
    double lon2

double
polar_distance (lat1, lon1, lat2, lon2)
    double lat1
    double lon1
    double lat2
    double lon2

double
vincenty_distance (lat1, lon1, lat2, lon2)
    double lat1
    double lon1
    double lat2
    double lon2

