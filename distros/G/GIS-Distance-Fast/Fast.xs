#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <math.h>

double _deg2rad(double deg) {
    return ( deg * ( M_PI / 180.0 ) );
}

double cosine_distance(double lat1, double lon1, double lat2, double lon2) {
    lon1 = _deg2rad( lon1 );
    lat1 = _deg2rad( lat1 );
    lon2 = _deg2rad( lon2 );
    lat2 = _deg2rad( lat2 );

    double a = sin( lat1 ) * sin( lat2 );
    double b = cos( lat1 ) * cos( lat2 ) * cos( lon2 - lon1 );
    double c = acos( a + b );

    return c;
}

double haversine_distance(double lat1, double lon1, double lat2, double lon2) {
    lon1 = _deg2rad( lon1 );
    lat1 = _deg2rad( lat1 );
    lon2 = _deg2rad( lon2 );
    lat2 = _deg2rad( lat2 );

    double dlon = lon2 - lon1;
    double dlat = lat2 - lat1;
    double a = pow( sin(dlat/2.0), 2.0 ) + cos(lat1) * cos(lat2) * pow( sin(dlon/2.0), 2.0 );
    double c = 2.0 * atan2( sqrt(a), sqrt(1.0-a) );

    return c;
}

double vincenty_distance(double lat1, double lon1, double lat2, double lon2) {
    if ( (lon1==lon2) && (lat1==lat2) ) {
        return 0;
    }
    lon1 = _deg2rad( lon1 );
    lat1 = _deg2rad( lat1 );
    lon2 = _deg2rad( lon2 );
    lat2 = _deg2rad( lat2 );

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

    return c;
}

MODULE = GIS::Distance::Fast     PACKAGE = GIS::Distance::Fast

PROTOTYPES: DISABLE

double
cosine_distance (lat1, lon1, lat2, lon2)
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
vincenty_distance (lat1, lon1, lat2, lon2)
    double lat1
    double lon1
    double lat2
    double lon2

