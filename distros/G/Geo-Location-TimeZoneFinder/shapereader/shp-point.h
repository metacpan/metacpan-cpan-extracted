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

#ifndef _SHAPEREADER_SHP_POINT_H
#define _SHAPEREADER_SHP_POINT_H

/**
 * Point
 *
 * A location in a two-dimensional coordinate plane.
 */
typedef struct shp_point_t {
    double x; /**< X coordinate */
    double y; /**< Y coordinate */
} shp_point_t;

/**
 * Check whether a point is in a bounding box
 *
 * Determines whether a point is inside or outside a bounding box.
 *
 * @memberof shp_point_t
 * @param point a point.
 * @param x_min X coordinate of the bottom left corner.
 * @param y_min Y coordinate of the bottom left corner.
 * @param x_max X coordinate of the top right corner.
 * @param y_max Y coordinate of the top right corner.
 * @retval 1 if the point is in the box.
 * @retval 0 if the point is not in the box.
 * @retval -1 if the point is on the boundary.
 *
 * @see shp_point_in_polygon
 */
extern int shp_point_in_bounding_box(const shp_point_t *point, double x_min,
                                     double y_min, double x_max,
                                     double y_max);

#endif
