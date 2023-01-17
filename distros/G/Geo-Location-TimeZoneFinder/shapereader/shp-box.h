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

#ifndef _SHAPEREADER_SHP_BOX_H
#define _SHAPEREADER_SHP_BOX_H

#include "shp-point.h"

/**
 * Bounding box
 *
 * A bounding box is a rectangle that surrounds a shape.
 */
typedef struct shp_box_t {
    double x_min; /**< X coordinate of the bottom left corner */
    double y_min; /**< Y coordinate of the bottom left corner */
    double x_max; /**< X coordinate of the top right corner */
    double y_max; /**< Y coordinate of the top right corner */
} shp_box_t;

/**
 * Check whether a point is in a bounding box.
 *
 * Determines whether a point is inside or outside a bounding box.
 *
 * @memberof shp_box_t
 * @param box a bounding box.
 * @param point a point.
 * @retval 1 if the point is in the box.
 * @retval 0 if the point is not in the box.
 * @retval -1 if the point is on the boundary.
 */
extern int shp_box_point_in_box(const shp_box_t *box,
                                const shp_point_t *point);

#endif
