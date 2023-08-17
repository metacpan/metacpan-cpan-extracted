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

#ifndef _SHAPEREADER_SHP_POLYGONM_H
#define _SHAPEREADER_SHP_POLYGONM_H

#include "shp-pointm.h"
#include <stddef.h>

/**
 * PolygonM
 *
 * A PolygonM consists of one or more parts.  A part is a connected sequence
 * of four or more points that form a closed, non-self-intersecting loop. Each
 * point is associated with a measure, for example a temperature.
 */
typedef struct shp_polygonm_t {
    double x_min;        /**< X minimum value */
    double x_max;        /**< X maximum value */
    double y_min;        /**< Y minimum value */
    double y_max;        /**< Y maximum value */
    double m_min;        /**< M minimum value */
    double m_max;        /**< M maximum value */
    size_t num_parts;    /**< Number of parts */
    size_t num_points;   /**< Total number of points */
    const char *parts;   /* Index to first point in part */
    const char *points;  /* X and Y coordinates */
    const char *m_array; /* Measures */
} shp_polygonm_t;

/**
 * Get the points that form a part
 *
 * Gets the indices for the points specified by @p part_num.
 *
 * @memberof shp_polygonm_t
 * @param polygonm a PolygonM.
 * @param part_num a zero-based part number.
 * @param[out] start the range start.
 * @param[out] end the range end (exclusive).
 * @return the number of points in the part.  At least 4 if the part is valid.
 *
 * @see shp_polygonm_pointm
 */
extern size_t shp_polygonm_points(const shp_polygonm_t *polygonm,
                                  size_t part_num, size_t *start,
                                  size_t *end);

/**
 * Get a PointM
 *
 * Gets a PointM that belongs to the edges of a PolygonM.
 *
 * @b Example
 *
 * @code{.c}
 * // Iterate over all parts and points
 * size_t part_num, i, n;
 * shp_pointm_t pointm;
 *
 * for (part_num = 0; part_num < polygonm->num_parts; ++part_num) {
 *   shp_polygonm_points(polygonm, part_num, &i, &n);
 *   while (i < n) {
 *     shp_polygonm_pointm(polygonm, i, &pointm);
 *     ++i;
 *   }
 * }
 * @endcode
 *
 * @memberof shp_polygonm_t
 * @param polygonm a PolygonM.
 * @param point_num a zero-based point number.
 * @param[out] pointm a shp_pointm_t structure.
 *
 * @see shp_polygonm_points
 */
extern void shp_polygonm_pointm(const shp_polygonm_t *polygonm,
                                size_t point_num, shp_pointm_t *pointm);

#endif
