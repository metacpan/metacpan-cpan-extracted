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

#ifndef _SHAPEREADER_SHP_POINTM_H
#define _SHAPEREADER_SHP_POINTM_H

/**
 * PointM
 *
 * A location in a two-dimensional coordinate plane with a measure, for
 * example a temperature.
 */
typedef struct shp_pointm_t {
    double x; /**< X coordinate */
    double y; /**< Y coordinate */
    double m; /**< Measure */
} shp_pointm_t;

#endif
