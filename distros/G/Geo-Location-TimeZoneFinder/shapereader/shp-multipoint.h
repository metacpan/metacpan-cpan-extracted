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

#ifndef _SHAPEREADER_SHP_MULTIPOINT_H
#define _SHAPEREADER_SHP_MULTIPOINT_H

#include "shp-point.h"
#include <stddef.h>

/**
 * MultiPoint
 *
 * A MultiPoint is a set of points.
 */
typedef struct shp_multipoint_t {
    double x_min;       /**< X minimum value */
    double x_max;       /**< X maximum value */
    double y_min;       /**< Y minimum value */
    double y_max;       /**< Y maximum value */
    size_t num_points;  /**< Number of points */
    const char *points; /* X and Y coordinates */
} shp_multipoint_t;

/**
 * Get a Point
 *
 * Gets a Point from a MultiPoint.
 *
 * @b Example
 *
 * @code{.c}
 * // Iterate over all points
 * size_t i;
 * shp_point_t point;
 *
 * for (i = 0; i < multipoint->num_points; ++i) {
 *   shp_multipoint_point(multipoint, i, &point);
 * }
 * @endcode
 *
 * @memberof shp_multipoint_t
 * @param multipoint a shp_multipoint_t structure.
 * @param point_num a zero-based point number.
 * @param[out] point a shp_point_t structure.
 */
extern void shp_multipoint_point(const shp_multipoint_t *multipoint,
                                 size_t point_num, shp_point_t *point);

#endif
