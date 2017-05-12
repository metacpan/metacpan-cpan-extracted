#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "math.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846264338327950288
#endif
#ifndef M_PI_2
#define M_PI_2 1.57079632679489661923132169163975144
#endif

const double DEG_RADS = M_PI / 180.;

/* From Geo::Distance */
const double KILOMETER_RHO = 6371.64;

/* WGS 84 Ellipsoid */
const double A = 6378137.;
const double B = 6356752.314245;
const double F = 1. / 298.257223563;

static void
my_croak (char* pat, ...) {
    va_list args;
    SV *error_sv;

    dTHX;
    dSP;

    error_sv = newSV(0);

    va_start(args, pat);
    sv_vsetpvf(error_sv, pat, &args);
    va_end(args);

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(error_sv));
    PUTBACK;
    call_pv("Carp::croak", G_VOID | G_DISCARD);
    FREETMPS;
    LEAVE;
}

double
haversine (double lat1, double lon1, double lat2, double lon2) {
    lat1 *= DEG_RADS; lon1 *= DEG_RADS;
    lat2 *= DEG_RADS; lon2 *= DEG_RADS;
    double a = sin(0.5 * (lat2 - lat1));
    double b = sin(0.5 * (lon2 - lon1));
    double c = a * a + cos(lat1) * cos(lat2) * b * b;
    double d = 2. * atan2(sqrt(c), sqrt(fabs(1. - c)));
    return d;
}

double
cosines (double lat1, double lon1, double lat2, double lon2) {
    lat1 *= DEG_RADS; lon1 *= DEG_RADS;
    lat2 *= DEG_RADS; lon2 *= DEG_RADS;
    double a = sin(lat1) * sin(lat2);
    double b = cos(lat1) * cos(lat2) * cos(lon2 - lon1);
    double d = acos(a + b);
    /* Antipodal coordinates result in NaN */
    if (isnan(d))
        return haversine(lat1, lon1, lat2, lon2);
    return d;
}

double
polar (double lat1, double lon1, double lat2, double lon2) {
    double a = M_PI_2 - lat1 * DEG_RADS;
    double b = M_PI_2 - lat2 * DEG_RADS;
    double dlon = (lon2 - lon1) * DEG_RADS;
    double d = sqrt(a * a + b * b - 2. * a * b * cos(dlon));
    return d;
}

double
great_circle (double lat1, double lon1, double lat2 , double lon2) {
    lat1 *= DEG_RADS; lon1 *= DEG_RADS;
    lat2 *= DEG_RADS; lon2 *= DEG_RADS;
    double a = sin(0.5 * (lat2 - lat1));
    double b = sin(0.5 * (lon2 - lon1));
    double c = a * a + cos(lat1) * cos(lat2) * b * b;
    double d = 2. * asin(sqrt(c));
    return d;
}

double
vincenty (double lat1, double lon1, double lat2 , double lon2) {
    double dlon = (lon2 - lon1) * DEG_RADS;
    double u1 = atan((1. - F) * tan(lat1 * DEG_RADS));
    double u2 = atan((1. - F) * tan(lat2 * DEG_RADS));
    double sin_u1 = sin(u1), cos_u1 = cos(u1);
    double sin_u2 = sin(u2), cos_u2 = cos(u2);

    double lambda = dlon, lambda_p = 2. * M_PI;
    int iter_limit = 100;

    double sin_sigma, cos_sigma;
    double sigma;
    double cos_sq_alpha, cos_sigma_m;
    double u_sq, a, b, delta_sigma, d;

    while (fabs(lambda - lambda_p) > 1e-12 && iter_limit-- > 0) {
        double alpha, c;
        double sin_lambda = sin(lambda);
        double cos_lambda = cos(lambda);
        sin_sigma = sqrt((cos_u2 * sin_lambda) * (cos_u2 * sin_lambda) +
                         (cos_u1 * sin_u2 - sin_u1 * cos_u2 * cos_lambda) *
                         (cos_u1 * sin_u2-sin_u1 * cos_u2 * cos_lambda));
        if (sin_sigma == 0.) {
            return 0.;
        }
        cos_sigma = sin_u1 * sin_u2 + cos_u1 * cos_u2 * cos_lambda;
        sigma = atan2(sin_sigma, cos_sigma);
        alpha = asin(cos_u1 * cos_u2 * sin_lambda / sin_sigma);
        cos_sq_alpha = cos(alpha) * cos(alpha);
        cos_sigma_m = cos_sigma - 2. * sin_u1 * sin_u2 / cos_sq_alpha;
        if (isnan(cos_sigma_m)) {
            cos_sigma_m = 0.;
        }
        c = 0.0625 * F * cos_sq_alpha *
            (4. + F * (4. - 3. * cos_sq_alpha));
        lambda_p = lambda;
        lambda = dlon + (1. - c) * F * sin(alpha) * (sigma + c *
                 sin_sigma * (cos_sigma_m + c * cos_sigma * (-1. + 2. *
                 cos_sigma_m * cos_sigma_m)));
    }
    if (! iter_limit)
        return 0.;

    u_sq = cos_sq_alpha * (A * A / (B * B) - 1.);
    a = 1. + u_sq / 16384. * (4096. + u_sq * (-768. + u_sq *
               (320. - 175. * u_sq)));
    b = u_sq / 1024. * (256. + u_sq * (-128. + u_sq * (74. - 47. * u_sq)));
    delta_sigma = b * sin_sigma * (cos_sigma_m + b / 4. * (cos_sigma *
                  (-1. + 2. * cos_sigma_m * cos_sigma_m) - b / 6. *
                  cos_sigma_m * (- 3. + 4. * sin_sigma * sin_sigma) *
                  (-3. + 4. * cos_sigma_m * cos_sigma_m)));
    d = B * a * (sigma - delta_sigma);
    return d / KILOMETER_RHO * 0.001;
}

double
andoyer_lambert_thomas (double lat1, double lon1, double lat2, double lon2) {
    /* Sphere with equal meridian length */
    const double RM = 6367449.14582342;

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
    if (c2 == 0.) return M_PI * RM / KILOMETER_RHO * 0.001;

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
    return d / KILOMETER_RHO * 0.001;
}

/* TODO: add more guards against unexpected data */
double
_count_units (SV *self, SV *unit) {
    dTHX;

    STRLEN len;
    char *name = SvPV(unit, len);
    HV *hash;

    SV **svp = hv_fetchs((HV *)SvRV(self), "units", 0);
    if (! svp) my_croak("Unknown unit type \"%s\"", name);

    hash = (HV *)SvRV(*svp);
    svp = hv_fetch(hash, name, len, 0);
    if (! svp) my_croak("Unknown unit type \"%s\"", name);

    return SvNV(*svp);
}

MODULE = Geo::Distance::XS    PACKAGE = Geo::Distance::XS

PROTOTYPES: DISABLE

void
distance (self, unit, lon1, lat1, lon2, lat2)
    SV *self
    SV *unit
    NV lon1
    NV lat1
    NV lon2
    NV lat2
PREINIT:
    SV **key;
    int index = 1;
    double (*func)(double, double, double, double);
CODE:
    if (lat2 == lat1 && lon2 == lon1)
        XSRETURN_NV(0.);
    key = hv_fetchs((HV *)SvRV(self), "formula_index", 0);
    if (key) index = SvIV(*key);
    switch (index) {
        case 1: func = &haversine; break;
        case 2: func = &cosines; break;
        case 3: func = &vincenty; break;
        case 4: func = &great_circle; break;
        case 5: func = &polar; break;
        case 6: func = &andoyer_lambert_thomas; break;
    }
    XSRETURN_NV(_count_units(self, unit) * (*func)(lat1, lon1, lat2, lon2));
