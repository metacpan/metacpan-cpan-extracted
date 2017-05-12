[![Build Status](https://travis-ci.org/karupanerura/c-geohex3.svg?branch=master)](https://travis-ci.org/karupanerura/c-geohex3)

# c-geohex3

GeoHex v3 implementation in C99.

VERSION: 1.50

# What is GeoHex?

https://sites.google.com/site/geohexdocs/
http://geohex.net/

# Synopsis

```c
#include <geohex3.h>
#include <stdio.h>
#include <stdint.h>

int main (int argc, char *argv[]) {
  for (int i = 1; i < argc; i++) {
    printf("/********* geohex:%s **********/\n", argv[i]);
    const geohex_verify_result_t result = geohex_verify_code(argv[i]);
    switch (result) {
      case GEOHEX_VERIFY_RESULT_SUCCESS:
        {
          const geohex_t geohex = geohex_get_zone_by_code(argv[i]);
          printf("code  = %s\n", geohex.code);
          printf("level = %zu\n", geohex.level);
          printf("size  = %Lf\n", geohex.size);
          printf("[location]\n");
          printf("lat = %Lf\n", geohex.location.lat);
          printf("lng = %Lf\n", geohex.location.lng);
          printf("[coordinate]\n");
          printf("x = %ld\n", geohex.coordinate.x);
          printf("y = %ld\n", geohex.coordinate.y);
        }
        break;
      case GEOHEX_VERIFY_RESULT_INVALID_CODE:
        printf("code:%s is invalid.\n", argv[i]);
        break;
      case GEOHEX_VERIFY_RESULT_INVALID_LEVEL:
        printf("code:%s is invalid level. MAX_LEVEL:%d\n", argv[i], GEOHEX_MAX_LEVEL);
        break;
    }
  }
}

```


# Dependencies

* picotest
* cmake
* prove

# Cheat Sheet

## SETUP

```bash
git clone https://github.com/karupanerura/c-geohex3.git
cd c-geohex3
git submodule update --init
```

## BUILD

```bash
cmake .
make
```

## TEST

```bash
make test
```

## INSTALL

```bash
sudo -H make install
```

# Types

SEE DETAIL: [geohex3.h](https://github.com/karupanerura/c-geohex3/blob/master/include/geohex3.h)

## Struct

### geohex_location_t

Details of struct:

* lat: `long double` - latitude
* lng: `long double` - longitude

### geohex_coordinate_t

Details of struct:

* x: `int64_t`
* y: `int64_t`

### geohex_polygon_t

Details of struct:

* top:
  * left:  `geohex_location_t`
  * right: `geohex_location_t`
* middle:
  * left:  `geohex_location_t`
  * right: `geohex_location_t`
* bottom:
  * left:  `geohex_location_t`
  * right: `geohex_location_t`

### geohex_t

Details of struct:

* location: `geohex_location_t`
* coordinate: `geohex_coordinate_t`
* code: `char *`
* level: `geohex_level_t`
* size: `long double`

## Enum

### geohex_verify_result_t

Enum value. Result of verifing geohex's code.

* GEOHEX_VERIFY_RESULT_SUCCESS:       Success to verify code.
* GEOHEX_VERIFY_RESULT_INVALID_CODE:  Invalid code format.
* GEOHEX_VERIFY_RESULT_INVALID_LEVEL: Invalid geohex's level. (0-15 is valid.)

## Others

### geohex_level_t

Alias of `size_t`.
Because geohex's level is defined as `strlen(code) - 2`.

# Functions

SEE DETAIL: [geohex3.h](https://github.com/karupanerura/c-geohex3/blob/master/include/geohex3.h)

## Constructor

### static inline geohex_coordinate_t geohex_coordinate(const int64_t x, const int64_t y);

Creates `geohex_coordinate_t`.

```c
geohex_coordinate_t coordinate = geohex_coordinate(123L, 123L);
```

### static inline geohex_location_t geohex_location(const double lat, const double lng);

Creates `geohex_location_t`.

```c
geohex_location_t location = geohex_location(40.5814792855475L, 134.296601127877L);
```

### geohex_t geohex_get_zone_by_location(const geohex_location_t location, geohex_level_t level);

Creates `geohex_t` by location.

```c
geohex_t geohex = geohex_get_zone_by_location(geohex_location(40.5814792855475L, 134.296601127877L), 7);
```

### geohex_t geohex_get_zone_by_coordinate(const geohex_coordinate_t coordinate, geohex_level_t level);

Creates `geohex_t` by coordinate.

```c
geohex_t geohex = geohex_get_zone_by_coordinate(geohex_coordinate(123L, 123L), 7);
```

### geohex_t geohex_get_zone_by_code(const char *code);

Creates `geohex_t` by geohex's code.

```c
geohex_t geohex = geohex_get_zone_by_code("XE1234");
```

## Utility

### static inline long double geohex_hexsize(const geohex_level_t level);

Calculate geohex size.

### static inline geohex_level_t geohex_calc_level_by_code(const char *code);

Calculate geohex level.

```c
geohex_level_t level = geohex_calc_level_by_code("XE2345"); // => 4
```

### geohex_verify_result_t geohex_verify_code(const char *code);

Verify geohex code.

```c
const geohex_verify_result_t result = geohex_verify_code(geohex_code);
switch (result) {
case GEOHEX_VERIFY_RESULT_SUCCESS:
  ...;
  break;
case GEOHEX_VERIFY_RESULT_INVALID_CODE:
  ...;
  break;
case GEOHEX_VERIFY_RESULT_INVALID_LEVEL:
  ...;
  break;
}
```

## Converter

### geohex_coordinate_t geohex_location2coordinate(const geohex_location_t location);

Convert `geohex_location_t` to `geohex_coordinate_t`.

```c
geohex_coordinate_t coordinate = geohex_location2coordinate(geohex_location(40.5814792855475L, 134.296601127877L));
```

### geohex_location_t geohex_coordinate2location(const geohex_coordinate_t coordinate);

Convert `geohex_coordinate_t` to `geohex_location_t`.

```c
geohex_coordinate_t coordinate = geohex_coordinate2location(geohex_coordinate(123L, 123L));
```

### geohex_polygon_t geohex_get_hex_polygon(const geohex_t *geohex);

Convert `geohex_t` to `geohex_polygon_t`.
(calc vertex location of geohex's polygon.)

```c
geohex_t geohex = geohex_get_zone_by_code("XE1234");
geohex_polygon_t polygon = geohex_get_hex_polygon(&geohex);
```

# LICENCE

MIT Licence.
(GeoHex is MIT Licence too.)

# AUTHOR

karupanerura
