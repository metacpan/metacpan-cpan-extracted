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

#ifndef _SHAPEREADER_SHP_MULTIPATCH_H
#define _SHAPEREADER_SHP_MULTIPATCH_H

#include "shp-pointz.h"
#include <stddef.h>

/**
 * Part types
 */
typedef enum shp_part_type_t {
    /**
     * A linked strip of triangles, where every vertex (after the first two)
     * completes a new triangle.  A new triangle is always formed by
     * connecting the new vertex with its two immediate predecessors.
     */
    SHP_PART_TYPE_TRIANGLE_STRIP = 0,
    /**
     * A linked fan of triangles, where every vertex (after the first two)
     * completes a new triangle.  A new triangle is always formed by
     * connecting the new vertex with its immediate predecessor and the
     * first vertex of the part.
     */
    SHP_PART_TYPE_TRIANGLE_FAN = 1,
    /**
     * The outer ring of a polygon.
     */
    SHP_PART_TYPE_OUTER_RING = 2,
    /**
     * A hole of a polygon.
     */
    SHP_PART_TYPE_INNER_RING = 3,
    /**
     * The first ring of a polygon of an unspecified type.
     */
    SHP_PART_TYPE_FIRST_RING = 4,
    /**
     * A ring of a polygon of an unspecified type.
     */
    SHP_PART_TYPE_RING = 5
} shp_part_type_t;

/**
 * MultiPatch
 *
 * A MultiPatch consists of a number of surface patches.  Each surface patch
 * describes a surface.  The surface patches of a MultiPatch are referred to
 * as its parts, and the type of part controls how the order of vertices of an
 * MultiPatch part is interpreted.  See the "ESRI Shapefile Technical
 * Description" @cite ESRI_shape for more information.
 */
typedef struct shp_multipatch_t {
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
    const char *types;   /* Part types */
    const char *points;  /* X and Y coordinates */
    const char *z_array; /* Z coordinates */
    const char *m_array; /* Measures */
} shp_multipatch_t;

/**
 * Get the points that form a part
 *
 * Gets the indices for the points specified by @p part_num.
 *
 * @memberof shp_multipatch_t
 * @param multipatch a MultiPatch.
 * @param part_num a zero-based part number.
 * @param[out] part_type the part type.
 * @param[out] start the range start.
 * @param[out] end the range end (exclusive).
 * @return the number of points in the part.
 *
 * @see shp_multipatch_pointz
 */
extern size_t shp_multipatch_points(const shp_multipatch_t *multipatch,
                                    size_t part_num,
                                    shp_part_type_t *part_type, size_t *start,
                                    size_t *end);

/**
 * Get a PointZ
 *
 * Gets a PointZ that belongs to the edges of a MultiPatch.
 *
 * @b Example
 *
 * @code{.c}
 * // Iterate over all parts and points
 * size_t part_num, i, n;
 * shp_part_type_t part_type;
 * shp_pointz_t pointz;
 *
 * for (part_num = 0; part_num < multipatch->num_parts; ++part_num) {
 *   shp_multipatch_points(multipatch, part_num, &part_type, &i, &n);
 *   while (i < n) {
 *     shp_multipatch_pointz(multipatch, i, &pointz);
 *     ++i;
 *   }
 * }
 * @endcode
 *
 * @memberof shp_multipatch_t
 * @param multipatch a MultiPatch.
 * @param point_num a zero-based point number.
 * @param[out] pointz a shp_pointz_t structure.
 *
 * @see shp_multipatch_points
 */
extern void shp_multipatch_pointz(const shp_multipatch_t *multipatch,
                                  size_t point_num, shp_pointz_t *pointz);

#endif
