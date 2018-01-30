#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "mgrs.h"

MODULE = Geo::Coordinates::MGRS::XS		PACKAGE = Geo::Coordinates::MGRS::XS		

void mgrs_to_utm(mgrs)
  char *mgrs;
  PPCODE:
  long zone;
  char hemisphere;
  double easting;
  double northing;

  long err = Convert_MGRS_To_UTM(mgrs, &zone, &hemisphere, &easting, &northing);
  if(!err || err == 1024) {
    XPUSHs(sv_2mortal(newSVnv(zone)));
    XPUSHs(sv_2mortal(newSVpv(&hemisphere, 1)));
    XPUSHs(sv_2mortal(newSVnv(easting)));
    XPUSHs(sv_2mortal(newSVnv(northing)));
  } else {
    croak("Unable to convert MGRS coordinates %ld (%s)", err, mgrs);
  }

void mgrs_to_latlon(mgrs)
  char *mgrs;
  PPCODE:
  double latitude;
  double longitude;

  long err = Convert_MGRS_To_Geodetic(mgrs, &latitude, &longitude);
  if(!err) {
    latitude = latitude * (180 / M_PI);
    longitude = longitude * (180 / M_PI);
    XPUSHs(sv_2mortal(newSVnv(latitude)));
    XPUSHs(sv_2mortal(newSVnv(longitude)));
  } else {
    croak("Unable to convert MGRS coordinates %ld", err);
  }

char *latlon_to_mgrs(latitude, longitude, precision)
  double latitude;
  double longitude;
  long precision;
  CODE:
  char mgrs[128] = { 0 };
  latitude = latitude * (M_PI / 180);
  longitude = longitude * (M_PI / 180);
  long err = Convert_Geodetic_To_MGRS(latitude, longitude, precision, mgrs);
  if(err || !*mgrs) croak("Unable to convert lat/lon to MGRS (%ld)", err);
  RETVAL = mgrs;
  OUTPUT:
  RETVAL

