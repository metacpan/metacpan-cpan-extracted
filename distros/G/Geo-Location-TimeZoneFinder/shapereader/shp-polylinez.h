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

#ifndef _SHAPEREADER_SHP_POLYLINEZ_H
#define _SHAPEREADER_SHP_POLYLINEZ_H

#include "shp-pointz.h"
#include <stddef.h>

/**
 * PolyLineZ
 *
 * A PolyLineZ consists of one or more parts.  A part is a connected sequence
 * of of two or more points.  Each point is associated with a measure, for
 * example a temperature.
 */
typedef struct shp_polylinez_t {
    double x_min;        /**< X minimum value */
    double x_max;        /**< X maximum value */
    double y_min;        /**< Y minimum value */
    double y_max;        /**< Y maximum value */
    double z_min;        /**< Z minimum value */
    double z_max;        /**< Z maximum value */
    double m_min;        /**< M minimum value */
    double m_max;        /**< M maximum value */
    size_t num_parts;    /**< Number of parts */
    size_t num_points;   /**< Total number of points */
    const char *parts;   /* Index to first point in part */
    const char *points;  /* X and Y coordinates */
    const char *z_array; /* Z coordinates */
    const char *m_array; /* Measures */
} shp_polylinez_t;

/**
 * Get the points that form a part
 *
 * Gets the indices for the points specified by @p part_num.
 *
 * @memberof shp_polylinez_t
 * @param polylinez a PolyLineZ.
 * @param part_num a zero-based part number.
 * @param[out] start the range start.
 * @param[out] end the range end (exclusive).
 * @return the number of points in the part.  At least 2 if the part is valid.
 *
 * @see shp_polylinez_pointz
 */
extern size_t shp_polylinez_points(const shp_polylinez_t *polylinez,
                                   size_t part_num, size_t *start,
                                   size_t *end);

/**
 * Get a PointZ
 *
 * Gets a PointZ that belongs to a PolyLineZ.
 *
 * @b Example
 *
 * @code{.c}
 * // Iterate over all parts and points
 * size_t part_num, i, n;
 * shp_pointz_t pointz;
 *
 * for (part_num = 0; part_num < polylinez->num_parts; ++part_num) {
 *   shp_polylinez_points(polylinez, part_num, &i, &n);
 *   while (i < n) {
 *     shp_polylinez_pointz(polylinez, i, &pointz);
 *     ++i;
 *   }
 * }
 * @endcode
 *
 * @memberof shp_polylinez_t
 * @param polylinez a PolyLineZ.
 * @param point_num a zero-based point number.
 * @param[out] pointz a shp_pointz_t structure.
 *
 * @see shp_polylinez_points
 */
extern void shp_polylinez_pointz(const shp_polylinez_t *polylinez,
                                 size_t point_num, shp_pointz_t *pointz);

#endif
