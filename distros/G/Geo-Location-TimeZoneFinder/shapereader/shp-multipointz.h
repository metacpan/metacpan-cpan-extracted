/*
 * Read ESRI shapefiles
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This library is free software; you can redistribute it and/or modify it
 * under either the terms of the ISC License or the same terms as Perl.
 */

/* SPDX-License-Identifier: ISC OR Artistic-1.0-Perl OR GPL-1.0-or-later */

/**
 * @file
 */

#ifndef _SHAPEREADER_SHP_MULTIPOINTZ_H
#define _SHAPEREADER_SHP_MULTIPOINTZ_H

#include "shp-pointz.h"
#include <stddef.h>

/**
 * MultiPointZ
 *
 * A MultiPointZ is a set of points with one measure per point, for example
 * a temperature.
 */
typedef struct shp_multipointz_t {
    double x_min;        /**< X minimum value */
    double x_max;        /**< X maximum value */
    double y_min;        /**< Y minimum value */
    double y_max;        /**< Y maximum value */
    double z_min;        /**< Z minimum value */
    double z_max;        /**< Z maximum value */
    double m_min;        /**< M minimum value */
    double m_max;        /**< M maximum value */
    size_t num_points;   /**< Number of points */
    const char *points;  /* X and Y coordinates */
    const char *z_array; /* Z coordinates */
    const char *m_array; /* Measures */
} shp_multipointz_t;

/**
 * Get a PointZ
 *
 * Gets a PointZ and a measure from a MultiPointZ.
 *
 * @b Example
 *
 * @code{.c}
 * // Iterate over all points
 * size_t i;
 * shp_pointz_t pointz;
 *
 * for (i = 0; i < multipointz->num_points; ++i) {
 *   shp_multipointz_pointz(multipoint, i, &pointz);
 * }
 * @endcode
 *
 * @memberof shp_multipointz_t
 * @param multipointz a shp_multipointz_t structure.
 * @param point_num a zero-based point number.
 * @param[out] pointz a shp_pointz_t structure.
 */
extern void shp_multipointz_pointz(const shp_multipointz_t *multipointz,
                                   size_t point_num, shp_pointz_t *pointz);

#endif
