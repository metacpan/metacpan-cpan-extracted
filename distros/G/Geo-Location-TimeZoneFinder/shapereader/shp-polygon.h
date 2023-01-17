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

#include "shp-box.h"
#include "shp-point.h"
#include <stdint.h>

/**
 * Polygon
 *
 * A polygon consists of one or more rings.  A ring is a connected sequence of
 * four or more points that form a closed, non-self-intersecting loop.  See
 * the "ESRI Shapefile Technical Description" @cite ESRI_shape for more
 * information.
 */
typedef struct shp_polygon_t {
    shp_box_t box;       /**< The polygon's bounding box */
    int32_t num_parts;   /**< Number of parts in the polygon */
    int32_t num_points;  /**< Total number of points in the polygon */
    const char *_parts;  /* Indices to the first points in the parts */
    const char *_points; /* The points for all parts */
} shp_polygon_t;

/**
 * Get the points that form a ring.
 *
 * Gets the indices for the points specified by @p part_num.
 *
 * @memberof shp_polygon_t
 * @param polygon a polygon.
 * @param part_num a zero-based part number.
 * @param[out] pstart the range start.
 * @param[out] pend the range end (exclusive).
 * @return the number of points in the range.
 *
 * @see shp_polygon_point
 */
extern int32_t shp_polygon_points(const shp_polygon_t *polygon,
                                  int32_t part_num, int32_t *pstart,
                                  int32_t *pend);

/**
 * Get a point.
 *
 * Gets a point that belongs to the edges of a polygon.
 *
 * @memberof shp_polygon_t
 * @param polygon a polygon.
 * @param point_num a zero-based point number.
 * @param[out] ppoint the address of a shp_point_t structure.
 *
 * @see shp_polygon_points
 */
extern void shp_polygon_point(const shp_polygon_t *polygon, int32_t point_num,
                              shp_point_t *ppoint);

/**
 * Check whether a point is in a polygon.
 *
 * Determines whether a point is inside or outside a polygon.  Uses the
 * algorithm described in the article "Optimal Reliable Point-in-Polygon Test
 * and Differential Coding Boolean Operations on Polygons" @cite sym10100477.
 *
 * @memberof shp_polygon_t
 * @param polygon a polygon.
 * @param point a point.
 * @retval 1 if the point is in the polygon.
 * @retval 0 if the point is not in the polygon.
 * @retval -1 if the point is on the polygon's edges.
 *
 * @see shp_box_point_in_box
 */
extern int shp_polygon_point_in_polygon(const shp_polygon_t *polygon,
                                        const shp_point_t *point);

#endif
