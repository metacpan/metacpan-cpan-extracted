/*
 * Read ESRI shapefiles
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This library is free software; you can redistribute it and/or modify it
 * under either the terms of the ISC License or the same terms as Perl.
 */

/* SPDX-License-Identifier: ISC OR Artistic-1.0-Perl OR GPL-1.0-or-later */

#include "shp-polylinez.h"
#include "byteorder.h"
#include <assert.h>

size_t
shp_polylinez_points(const shp_polylinez_t *polylinez, size_t part_num,
                     size_t *start, size_t *end)
{
    size_t num_points, i, j, m;
    const char *buf;

    assert(polylinez != NULL);
    assert(part_num < polylinez->num_parts);
    assert(start != NULL);
    assert(end != NULL);

    m = polylinez->num_points;

    buf = polylinez->parts + 4 * part_num;
    i = shp_le32_to_int32(&buf[0]);
    if (part_num + 1 < polylinez->num_parts) {
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
shp_polylinez_pointz(const shp_polylinez_t *polylinez, size_t point_num,
                     shp_pointz_t *pointz)
{
    const char *buf;

    assert(polylinez != NULL);
    assert(point_num < polylinez->num_points);
    assert(pointz != NULL);

    buf = polylinez->points + 16 * point_num;
    pointz->x = shp_le64_to_double(&buf[0]);
    pointz->y = shp_le64_to_double(&buf[8]);

    buf = polylinez->z_array + 8 * point_num;
    pointz->z = shp_le64_to_double(&buf[0]);

    buf = polylinez->m_array + 8 * point_num;
    pointz->m = shp_le64_to_double(&buf[0]);
}
