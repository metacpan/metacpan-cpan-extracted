#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <math.h>

#define PI      3.1415926535897932384626433832795

/*
 * Polynomial constants
 */
#define K1   .99435487
#define K2   .00336523
#define K3  -.00065596
#define K4   .00005606
#define K5  -.00000188

/*
 * spherical coordinates of eastern reference point
 * EX^2 + EY^2 + EZ^2 = 1
 */
#define EX   .40426992
#define EY   .68210848
#define EZ   .60933887

/* spherical coordinates of western reference point
 * WX^2 + WY^2 + WZ^2 = 1
 */
#define WX   .65517646
#define WY   .37733790
#define WZ   .65449210

/*
 * spherical coordinates of V-H coordinate system
 * PX^2 + PY^2 + PZ^2 = 1
 */
#define PX  -0.555977821730048699
#define PY  -0.345728488161089920
#define PZ   0.755883902605524030

/*
 * Rotation by 76.597497064 degrees
 * We use the cosine ROTC and sin ROTS values
 */
#define ROTC  0.2317903984757393
#define ROTS  0.9727657534959061

/*
 * orthogonal translation values
 */
#define TRANSV  6363.235
#define TRANSH  2250.700

/*
 * radius of earth in sqrt(0.1)-mile units, minus 0.3 percent
 */
#define RADIUS  12481.103


double radians (double degrees) {
    return degrees*PI/180.0;
}

double degrees (double radians) {
    return radians*180.0/PI;
}

/*
 * Return the distance in miles between 2 VH pairs.
 */
double distance(double v1, double h1, double v2, double h2) {
    double dv = v2 - v1;
    double dh = h2 - h1;
    return sqrt((dv*dv + dh*dh)/10.0);
}

/**
 * Computes Bellcore/AT&T V & H (vertical and horizontal)
 * coordinates from latitude and longitude.  Used primarily by
 * local exchange carriers (LEC's) to compute the V & H coordinates
 * for wire centers.
 *
 * This is an implementation of the Donald Elliptical Projection,
 * a Two-Point Equidistant projection developed by Jay K. Donald
 * of AT&T in 1956 to establish long-distance telephone rates.
 * (ref: "V-H Coordinate Rediscovered", Eric K. Grimmelmann, Bell
 * Labs Tech. Memo, 9/80.  (References Jay Donald notes of Jan 17, 1957.))
 * Ashok Ingle of Bellcore also wrote an internal memo on the subject.
 *
 * The projection is specially modified for the ellipsoid and
 * is confined to the United States and southern Canada.
 *
 * Derived from a program obtained from an anonymous author
 * within Bellcore by way of the National Exchange Carrier
 * Association.  Cleaned up and improved a bit by
 * Tom Libert (tom@comsol.com, libert@citi.umich.edu).
 */


/** lat and lon are in degrees, positive north and east. */
void toVH(double lat, double lon) {

    double lon1,latsq,lat1,cos_lat1,x,y,z,e,w,ht,vt,v,h;
    dXSARGS;
    sp = mark;

    lat = radians(lat);
    lon = radians(lon);

    /* Translate east by 52 degrees */
    lon1 = lon + radians(52.0);

    /* Convert latitude to geocentric latitude using Horner's rule */
    latsq = lat*lat;
    lat1 = lat*(K1 + (K2 + (K3 + (K4 + K5*latsq)*latsq)*latsq)*latsq);

    /* x, y, and z are the spherical coordinates corresponding to lat, lon. */
    cos_lat1 = cos(lat1);
    x = cos_lat1*sin(-lon1);
    y = cos_lat1*cos(-lon1);
    z = sin(lat1);

    /* e and w are the cosine of the angular distance (radians) between
     * our point and the east and west centers.
     */
    e = EX*x + EY*y + EZ*z;
    w = WX*x + WY*y + WZ*z;
    e = e > 1.0 ? 1.0 : e;
    w = w > 1.0 ? 1.0 : w;
    e = (PI/2.0) - atan(e/sqrt(1 - e*e));
    w = (PI/2.0) - atan(w/sqrt(1 - w*w));

    /* e and w are now in radians. */
    ht = (e*e - w*w + .16)/.8;
    vt = sqrt(fabs(e*e - ht*ht));
    vt = (PX*x + PY*y + PZ*z) < 0 ? -vt : vt;

    /* rotate and translate to get final v and h. */
    v = TRANSV +  RADIUS*ROTC*ht - RADIUS*ROTS*vt;
    h = TRANSH + RADIUS*ROTS*ht +  RADIUS*ROTC*vt;

    XPUSHs(sv_2mortal(newSVnv(v)));
    XPUSHs(sv_2mortal(newSVnv(h)));
    PUTBACK;

}

/**
 *      V&H is a system of coordinates (V and H) for describing
 *      locations of rate centers in the United States.  The
 *      projection, devised by J. K. Donald, is an "elliptical,"
 *      or "doubly equidistant" projection, scaled down by a factor
 *      of 0.003 to balance errors.
 *
 *      The foci of the projection, from which distances are
 *      measured accurately (except for the scale correction),
 *      are at 37d 42m 14.69s N, 82d 39m 15.27s W (in Floyd Co.,
 *      Ky.) and 41d 02m 55.53s N, 112d 03m 39.35 W (in Webster
 *      Co., Utah).  They are just 0.4 radians apart.
 *
 *      Here is the transformation from latitude and longitude to V&H:
 *      First project the earth from its ellipsoidal surface
 *      to a sphere.  This alters the latitude; the coefficients
 *      bi in the program are the coefficients of the polynomial
 *      approximation for the inverse transformation.  (The
 *      function is odd, so the coefficients are for the linear
 *      term, the cubic term, and so on.)  Also subtract 52 degrees
 *      from the longitude.
 *
 *      For the rest, compute the arc distances of the given point
 *      to the reference points, and transform them to the coordinate
 *      system in which the line through the reference points is the
 *      X-axis and the origin is the eastern reference point.
 *      The solution is
 *              h = (square of distance to E - square of distance to W
 *                      + square of distance between E and W) /
 *                      twice distance between E and W;
 *              v = square root of absolute value of (square of
 *                      distance to E - square of h).
 *      Reduce by three-tenths of a percent, rotate by 76.597497
 *      degrees, and add 6363.235 to V and 2250.7 to H.
 *
 *      To go the other way, as this program does, undo the final translation,
 *      rotation, and scaling.  The z-value Pz of the point on the x-y-z sphere
 *      satisfies the quadratic Azz+Bz+c=0, where
 *              A = (ExWz-EzWx)^2 + (EyWzx-EzWy)^2 + (ExWy-EyWx)^2;
 *              B = -2[(Ex cos(arc to W) - Wx cos(arc to E))(ExWz-EzWx) -
 *                      (Ey cos(arc to W) -Wy cos(arc to E))(EyWz-EzWy)];
 *              C = (Ex cos(arc to W) - Wx cos(arc to E))^2 +
 *                      (Ey cos(arc to W) - Wy cos(arc to E))^2 -
 *                      (ExWy - EyWx)^2.
 *      Solve with the quadratic formula.  The latitude is simply the
 *      arc sine of Pz.  Px and Py satisfy
 *              ExPx + EyPy + EzPz = cos(arc to E);
 *              WxPx + WyPy + WzPz = cos(arc to W).
 *      Substitute Pz's value, and solve linearly to get Px and Py.
 *      The longitude is the arc tangent of Px/Py.
 *      Finally, this latitude and longitude are spherical; use the
 *      inverse polynomial approximation on the latitude to get the
 *      ellipsoidal earth latitude, and add 52 degrees to the longitude.
 */

void toLatLon (double v, double h) {

    double GX,GY,A,Q,Q2,EPSILON,t1,t2,vhat,hhat,e,w,fx,fy,b,c,disc,x,y,z;
    double delta,lat,lat2,earthlat,lon,earthlon;
    /*
     *  Use polynomial approximation for inverse mapping (sphere to spheroid)
     */
    double bi[] = {
        1.00567724920722457,
        -0.00344230425560210245,
        0.000713971534527667990,
        -0.0000777240053499279217,
        0.00000673180367053244284,
        -0.000000742595338885741395,
        0.0000000905058919926194134
    };
    dXSARGS;
    sp = mark;

    /* GX = ExWz - EzWx; GY = EyWz - EzWy */
    GX =  0.216507961908834992;
    GY = -0.134633014879368199;
    /* A = (ExWz-EzWx)^2 + (EyWz-EzWy)^2 + (ExWy-EyWx)^2 */
    A =   0.151646645621077297;
    /* Q = ExWy-EyWx; Q2 = Q*Q */
    Q =  -0.294355056616412800;
    Q2=   0.0866448993556515751;
    EPSILON = .0000001;

    t1 = (v - TRANSV) / RADIUS;
    t2 = (h - TRANSH) / RADIUS;
    vhat = ROTC*t2 - ROTS*t1;
    hhat = ROTS*t2 + ROTC*t1;
    e = cos(sqrt(vhat*vhat + hhat*hhat));
    w = cos(sqrt(vhat*vhat + (hhat-0.4)*(hhat-0.4)));
    fx = EY*w - WY*e;
    fy = EX*w - WX*e;
    b = fx*GX + fy*GY;
    c = fx*fx + fy*fy - Q2;
    disc = b*b - A*c;               /* discriminant */
    x, y, z, delta;
    if (fabs(disc) < EPSILON) {
        z = b/A;
        x = (GX*z - fx)/Q;
        y = (fy - GY*z)/Q;
    } else {
        delta = sqrt(disc);
        z = (b + delta)/A;
        x = (GX*z - fx)/Q;
        y = (fy - GY*z)/Q;
        if (vhat * (PX*x + PY*y + PZ*z) < 0) {  /* wrong direction */
            z = (b - delta)/A;
            x = (GX*z - fx)/Q;
        y = (fy - GY*z)/Q;
        }
    }
    lat = asin(z);
    lat2 = lat*lat;
    earthlat = lat*(bi[0] + lat2*(bi[1] + lat2*(bi[2] + lat2*(bi[3] + \
               lat2*(bi[4] + lat2*(bi[5] + lat2*(bi[6])))))));
    earthlat = degrees(earthlat);

    /* Adjust longitude by 52 degrees */
    lon = degrees(atan2(x, y));
    earthlon = lon + 52.0;

    XPUSHs(sv_2mortal(newSVnv(earthlat)));
    XPUSHs(sv_2mortal(newSVnv(earthlon)));
    PUTBACK;
}


MODULE = Geo::Coordinates::VandH::XS    PACKAGE = Geo::Coordinates::VandH::XS

PROTOTYPES: DISABLE

double
radians (degrees)
    double    degrees

double
degrees (radians)
    double    radians

double
distance (v1, h1, v2, h2)
    double    v1
    double    h1
    double    v2
    double    h2

void
toVH (lat, lon)
    double    lat
    double    lon
    PREINIT:
    I32* temp;
    PPCODE:
    temp = PL_markstack_ptr++;
    toVH(lat, lon);
    if (PL_markstack_ptr != temp) {
      /* truly void, because dXSARGS not invoked */
      PL_markstack_ptr = temp;
      XSRETURN_EMPTY; /* return empty stack */
    }
    /* must have used dXSARGS; list context implied */
    return; /* assume stack size is correct */

void
toLatLon (v, h)
    double    v
    double    h
    PREINIT:
    I32* temp;
    PPCODE:
    temp = PL_markstack_ptr++;
    toLatLon(v, h);
    if (PL_markstack_ptr != temp) {
      /* truly void, because dXSARGS not invoked */
      PL_markstack_ptr = temp;
      XSRETURN_EMPTY; /* return empty stack */
    }
    /* must have used dXSARGS; list context implied */
    return; /* assume stack size is correct */



