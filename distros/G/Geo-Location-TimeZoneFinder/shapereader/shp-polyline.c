/*
 * Read ESRI shapefiles
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This library is free software; you can redistribute it and/or modify it
 * under either the terms of the ISC License or the same terms as Perl.
 */

/* SPDX-License-Identifier: ISC OR Artistic-1.0-Perl OR GPL-1.0-or-later */

#include "shp-polyline.h"
#include "byteorder.h"
#include <assert.h>

size_t
shp_polyline_points(const shp_polyline_t *polyline, size_t part_num,
                    size_t *start, size_t *end)
{
    size_t num_points, i, j, m;
    const char *buf;

    assert(polyline != NULL);
    assert(part_num < polyline->num_parts);
    assert(start != NULL);
    assert(end != NULL);

    m = polyline->num_points;

    buf = polyline->parts + 4 * part_num;
    i = shp_le32_to_int32(&buf[0]);
    if (part_num + 1 < polyline->num_parts) {
        j = shp_le32_to_int32(&buf[4]);
    }
    else {
        j = m;
    }

    *start = i;
    *end = j;

    /* Is the range valid? */
    num_points = 0;
    if (i < m && j <= m && i < j) {
        num_points = j - i;
    }

    return num_points;
}

void
shp_polyline_point(const shp_polyline_t *polyline, size_t point_num,
                   shp_point_t *point)
{
    const char *buf;

    assert(polyline != NULL);
    assert(point_num < polyline->num_points);
    assert(point != NULL);

    buf = polyline->points + 16 * point_num;
    point->x = shp_le64_to_double(&buf[0]);
    point->y = shp_le64_to_double(&buf[8]);
}
