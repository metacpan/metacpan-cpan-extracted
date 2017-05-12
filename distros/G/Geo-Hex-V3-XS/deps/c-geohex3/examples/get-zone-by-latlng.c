#include "geohex3.h"
#include <stdio.h>
#include <stdlib.h>

int main (int argc, char *argv[]) {
  if (argc != 4) {
    fputs("Usage: examples-get-zone-by-latlng $lat $lng $level\n", stderr);
    return -1;
  }

  const long double    lat   = strtold(argv[1], NULL);
  const long double    lng   = strtold(argv[2], NULL);
  const geohex_level_t level = (geohex_level_t)atoi(argv[3]);

  printf("/********* lat:%Lf, lng:%Lf, level:%zu **********/\n", lat, lng, level);
  const geohex_t geohex = geohex_get_zone_by_location(geohex_location(lat, lng), level);
  printf("code  = %s\n", geohex.code);
  printf("level = %zu\n", geohex.level);
  printf("size  = %Lf\n", geohex.size);
  printf("[location]\n");
  printf("lat = %Lf\n", geohex.location.lat);
  printf("lng = %Lf\n", geohex.location.lng);
  printf("[coordinate]\n");
  printf("x = %ld\n", geohex.coordinate.x);
  printf("y = %ld\n", geohex.coordinate.y);

  return 0;
}
