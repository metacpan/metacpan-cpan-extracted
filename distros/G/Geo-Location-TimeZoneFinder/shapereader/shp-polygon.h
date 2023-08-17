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

#ifndef _SHAPEREADER_SHP_POLYGON_H
#define _SHAPEREADER_SHP_POLYGON_H

#include "shp-point.h"
#include <stddef.h>

/**
 * Polygon
 *
 * A polygon consists of one or more parts.  A part is a connected sequence of
 * four or more points that form a closed, non-self-intersecting loop.  See
 * the "ESRI Shapefile Technical Description" @cite ESRI_shape for more
 * information.
 */
typedef struct shp_polygon_t {
    double x_min;       /**< X minimum value */
    double x_max;       /**< X maximum value */
    double y_min;       /**< Y minimum value */
    double y_max;       /**< Y maximum value */
    size_t num_parts;   /**< Number of parts */
    size_t num_points;  /**< Total number of points */
    const char *parts;  /* Index to first point in part */
    const char *points; /* X and Y coordinates */
} shp_polygon_t;

/**
 * Get the points that form a part
 *
 * Gets the indices for the points specified by @p part_num.
 *
 * @memberof shp_polygon_t
 * @param polygon a polygon.
 * @param part_num a zero-based part number.
 * @param[out] start the range start.
 * @param[out] end the range end (exclusive).
 * @return the number of points in the part.  At least 4 if the part is valid.
 *
 * @see shp_polygon_point
 */
extern size_t shp_polygon_points(const shp_polygon_t *polygon,
                                 size_t part_num, size_t *start, size_t *end);

/**
 * Get a Point
 *
 * Gets a Point that belongs to the edges of a Polygon.
 *
 * @b Example
 *
 * @code{.c}
 * // Iterate over all parts and points
 * size_t part_num, i, n;
 * shp_point_t point;
 *
 * for (part_num = 0; part_num < polygon->num_parts; ++part_num) {
 *   shp_polygon_points(polygon, part_num, &i, &n);
 *   while (i < n) {
 *     shp_polygon_point(polygon, i, &point);
 *     ++i;
 *   }
 * }
 * @endcode
 *
 * @memberof shp_polygon_t
 * @param polygon a polygon.
 * @param point_num a zero-based point number.
 * @param[out] point a shp_point_t structure.
 *
 * @see shp_polygon_points
 */
extern void shp_polygon_point(const shp_polygon_t *polygon, size_t point_num,
                              shp_point_t *point);

/**
 * Check whether a point is in a polygon
 *
 * Determines whether a point is inside or outside a polygon.
 *
 * @memberof shp_point_t
 * @param point a point.
 * @param polygon a polygon.
 * @retval 1 if the point is in the polygon.
 * @retval 0 if the point is not in the polygon.
 * @retval -1 if the point is on the polygon's edges.
 *
 * @see shp_point_in_bounding_box
 * @see "Optimal Reliable Point-in-Polygon Test and Differential Coding
 *      Boolean Operations on Polygons" @cite sym10100477 for a description
 *      of the point-in-polygon algorithm.
 */
extern int shp_point_in_polygon(const shp_point_t *point,
                                const shp_polygon_t *polygon);

#endif
