#ifndef GEOHEX3_H
#define GEOHEX3_H

#include <math.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>
#include <geohex3/macro.h>

#define GEOHEX3_MAJOR_VERSION 1
#define GEOHEX3_MINOR_VERSION 5
#define GEOHEX3_PATCH_VERSION 0
#define GEOHEX3_VERSION       "1.50"

#define GEOHEX3_MIN_LEVEL           0
#define GEOHEX3_MAX_LEVEL           15
#define GEOHEX3_GLOBAL_CODE_BUFSIZE 4
#define GEOHEX3_DEC9_BUFSIZE        32
#define GEOHEX3_DEC3_BUFSIZE        64

#define GEOHEX3_HASH_BASE 20037508.34L
#define GEOHEX3_PI        3.14159265358979323846L

typedef struct _geohex_location_s {
  long double lat;
  long double lng;
} geohex_location_t;

typedef struct _geohex_coordinate_s {
  int64_t x;
  int64_t y;
} geohex_coordinate_t;

struct _geohex_location_lrpair_s {
  geohex_location_t right;
  geohex_location_t left;
};

typedef struct _geohex_polygon_s {
  struct _geohex_location_lrpair_s top;
  struct _geohex_location_lrpair_s middle;
  struct _geohex_location_lrpair_s bottom;
} geohex_polygon_t;

typedef struct _geohex_s {
  geohex_location_t   location;
  geohex_coordinate_t coordinate;
  char                code[GEOHEX3_MAX_LEVEL + 3];
  size_t              level;
  long double         size;
} geohex_t;

typedef enum _geohex_verify_result_enum {
  GEOHEX3_VERIFY_RESULT_SUCCESS,
  GEOHEX3_VERIFY_RESULT_INVALID_CODE,
  GEOHEX3_VERIFY_RESULT_INVALID_LEVEL
} geohex_verify_result_t;

typedef size_t geohex_level_t;

static inline geohex_coordinate_t geohex_coordinate (const int64_t x, const int64_t y) {
  const geohex_coordinate_t coordinate = { .x = x, .y = y };
  return coordinate;
}

static inline geohex_location_t geohex_location (const double lat, const double lng) {
  const geohex_location_t location = { .lat = lat, .lng = lng };
  return location;
}

static inline geohex_level_t geohex_calc_level_by_code(const char *code) {
  return strlen(code) - 2;
}

static inline long double geohex_hexsize(const geohex_level_t level) {
  if (level > GEOHEX3_MAX_LEVEL) {
    return GEOHEX3_HASH_BASE / (long double)pow(3.0L, level + 3);
  }
  else {
    // for performance :)
    static const long double GEOHEX3_CALCED_HEX_SIZE[] = {
      GEOHEX3_HASH_BASE / GEOHEX3_MACRO_POW(3.0L,  3), //  0
      GEOHEX3_HASH_BASE / GEOHEX3_MACRO_POW(3.0L,  4), //  1
      GEOHEX3_HASH_BASE / GEOHEX3_MACRO_POW(3.0L,  5), //  2
      GEOHEX3_HASH_BASE / GEOHEX3_MACRO_POW(3.0L,  6), //  3
      GEOHEX3_HASH_BASE / GEOHEX3_MACRO_POW(3.0L,  7), //  4
      GEOHEX3_HASH_BASE / GEOHEX3_MACRO_POW(3.0L,  8), //  5
      GEOHEX3_HASH_BASE / GEOHEX3_MACRO_POW(3.0L,  9), //  6
      GEOHEX3_HASH_BASE / GEOHEX3_MACRO_POW(3.0L, 10), //  7
      GEOHEX3_HASH_BASE / GEOHEX3_MACRO_POW(3.0L, 11), //  8
      GEOHEX3_HASH_BASE / GEOHEX3_MACRO_POW(3.0L, 12), //  9
      GEOHEX3_HASH_BASE / GEOHEX3_MACRO_POW(3.0L, 13), // 10
      GEOHEX3_HASH_BASE / GEOHEX3_MACRO_POW(3.0L, 14), // 11
      GEOHEX3_HASH_BASE / GEOHEX3_MACRO_POW(3.0L, 15), // 12
      GEOHEX3_HASH_BASE / GEOHEX3_MACRO_POW(3.0L, 16), // 13
      GEOHEX3_HASH_BASE / GEOHEX3_MACRO_POW(3.0L, 17), // 14
      GEOHEX3_HASH_BASE / GEOHEX3_MACRO_POW(3.0L, 18)  // 15
    };
    return GEOHEX3_CALCED_HEX_SIZE[level];
  }
}

extern geohex_verify_result_t geohex_verify_code(const char *code);
extern geohex_coordinate_t geohex_location2coordinate(const geohex_location_t location);
extern geohex_location_t   geohex_coordinate2location(const geohex_coordinate_t coordinate);
extern geohex_t            geohex_get_zone_by_location(const geohex_location_t location, geohex_level_t level);
extern geohex_t            geohex_get_zone_by_coordinate(const geohex_coordinate_t coordinate, geohex_level_t level);
extern geohex_t            geohex_get_zone_by_code(const char *code);
extern geohex_polygon_t    geohex_get_hex_polygon (const geohex_t *geohex);

// XXX: for test
extern geohex_coordinate_t geohex_get_coordinate_by_location(const geohex_location_t location, geohex_level_t level);

#endif
