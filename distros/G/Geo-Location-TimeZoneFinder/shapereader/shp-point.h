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
    double x; /**< The horizontal position */
    double y; /**< The vertical position */
} shp_point_t;

#endif
