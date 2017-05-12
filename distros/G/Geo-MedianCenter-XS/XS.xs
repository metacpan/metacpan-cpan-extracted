#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PI (3.141592653589793)

double
haversine_distance_rad(double lat1, double lon1, double lat2, double lon2) {
  double smlat = sin((lat1 - lat2) / 2.0);
  double smlon = sin((lon1 - lon2) / 2.0);
  double a = smlat * smlat + cos(lat1) * cos(lat2) * smlon * smlon;
  return 6371640 * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double
haversine_distance_dec(double lat1, double lon1, double lat2, double lon2) {
  return haversine_distance_rad(
    lat1 * (PI / 180.0),
    lon1 * (PI / 180.0),
    lat2 * (PI / 180.0),
    lon2 * (PI / 180.0)
  );
}

double*
data_from_av(AV* list) {
  double* data;
  I32 len = av_len(list);
  I32 ix;
  
  Newxz(data, (len + 1)*6, double);
  
  if (data == NULL) {
    return NULL;
  }

  for (ix = 0; ix <= len; ++ix) {
    SV** value = av_fetch(list, ix, 0);
    SV* rv;
    AV* entry;
    I32 entry_len;
    I32 ex;
    I32 dx = ix * 6;

    if (!value || !*value || !SvROK(*value))
      continue;

    rv = SvRV(*value);

    if (!rv || !(SvTYPE(rv) == SVt_PVAV))
      continue;

    entry = (AV*)rv;
    entry_len = av_len(entry);

    /* Must have two or three entries */
    if (entry_len < 1 || entry_len > 2) {
      warn("bad item in points list");
      continue;
    }

    /* default for weight */
    data[ dx + 2 ] = 1.0;

    for (ex = 0; ex <= entry_len && ex < 3; ++ex) {
      SV** item = av_fetch(entry, ex, 0);
      
      if (!item || !*item) {
        continue;
      }

      data[ dx + ex ] = SvNV(*item);
    }

    data[ dx + 0 ] *= (PI / 180.0);                         /* lat in rad */
    data[ dx + 1 ] *= (PI / 180.0);                         /* lon in rad */
                                                            /* weight     */
    data[ dx + 3 ] = cos(data[ dx ]) * cos(data[ dx + 1 ]); /* x          */
    data[ dx + 4 ] = cos(data[ dx ]) * sin(data[ dx + 1 ]); /* y          */
    data[ dx + 5 ] = sin(data[ dx ]);                       /* z          */
  }

  return data;
}

int
median_center(HV* opts, double* plat, double* plon) {

  U32 max_iterations = 4;
  double tolerance = 0.0f;
  SV** value;
  double* data = NULL;
  double clat = 0;
  double clon = 0;
  I32 count = 0;

  if (opts == NULL || !( SvTYPE(opts) == SVt_PVHV )) {
    return -1;
  }

  value = hv_fetch(opts, "points", 6, 0);

  if (value && *value && SvROK(*value)) {
    SV* rv = SvRV(*value);

    count = av_len((AV*)rv);
    if (rv && (SvTYPE(rv) == SVt_PVAV) && count >= 0) {
      data = data_from_av((AV*)rv);
    }
  }

  value = hv_fetch(opts, "tolerance", 9, 0);

  if (value && *value && SvOK(*value)) {
    tolerance = SvNV(*value);
  }

  value = hv_fetch(opts, "max_iterations", 14, 0);

  if (value && *value && SvOK(*value)) {
    max_iterations = SvUV(*value);
  }

  while (data) {

    double sumkx, sumky, sumkz, sumk, avgx, avgy, avgz, nlat, nlon, ndst;
    size_t last = (count + 1) * 6;
    size_t ix;

    sumkx = sumky = sumkz = sumk = 0;

    for (ix = 0; ix < last;) {
      double lat = data[ix++];
      double lon = data[ix++];
      double wgt = data[ix++];
      double dst = haversine_distance_rad(clat, clon, lat, lon);
      double wgd;

      if (dst == 0) {
        dst = DBL_EPSILON;
      }

      wgd = wgt / dst;

      sumkx += wgd * data[ix++];
      sumky += wgd * data[ix++];
      sumkz += wgd * data[ix++];
      sumk  += wgd;
    }
    
    avgx = sumkx / sumk;
    avgy = sumky / sumk;
    avgz = sumkz / sumk;

    /* Should this rather use asin(avgz)? */
    nlat = atan2(avgz, sqrt(avgx * avgx + avgy * avgy));
    nlon = atan2(avgy, avgx);

    ndst = haversine_distance_rad(clat, clon, nlat, nlon);

    if (!(max_iterations-- > 0) || (ndst <= tolerance)) {
      *plat = nlat * (180.0 / PI);
      *plon = nlon * (180.0 / PI);

      Safefree(data);
      
      return 0;
    }

    clat = nlat;
    clon = nlon;
  }

  /* If we get here, there was an error retrieving the points */
  return -1;
}

MODULE = Geo::MedianCenter::XS PACKAGE = Geo::MedianCenter::XS

PROTOTYPES: DISABLE

double
haversine_distance_rad(double lat1, double lon1, double lat2, double lon2)

double
haversine_distance_dec(double lat1, double lon1, double lat2, double lon2)

void
median_center(opts)
  HV* opts;

  PREINIT:
    double lat = 0.0f;
    double lon = 0.0f;

  PPCODE:
    if (median_center(opts, &lat, &lon))
      XSRETURN_EMPTY;
      
    mXPUSHs(newSVnv( lat ));
    mXPUSHs(newSVnv( lon ));

