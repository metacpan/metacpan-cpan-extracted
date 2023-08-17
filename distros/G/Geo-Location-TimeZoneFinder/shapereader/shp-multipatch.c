/*
 * Read ESRI shapefiles
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This library is free software; you can redistribute it and/or modify it
 * under either the terms of the ISC License or the same terms as Perl.
 */

/* SPDX-License-Identifier: ISC OR Artistic-1.0-Perl OR GPL-1.0-or-later */

#include "shp-multipatch.h"
#include "byteorder.h"
#include <assert.h>

size_t
shp_multipatch_points(const shp_multipatch_t *multipatch, size_t part_num,
                      shp_part_type_t *part_type, size_t *start, size_t *end)
{
    size_t num_points, i, j, m, n;
    const char *buf;

    assert(multipatch != NULL);
    assert(part_num < multipatch->num_parts);
    assert(start != NULL);
    assert(end != NULL);

    m = multipatch->num_points;
    n = 4 * part_num;

    buf = multipatch->parts + n;
    i = shp_le32_to_int32(&buf[0]);
    if (part_num + 1 < multipatch->num_parts) {
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

    buf = multipatch->types + n;
    *part_type = (shp_part_type_t) shp_le32_to_int32(&buf[0]);

    return num_points;
}

void
shp_multipatch_pointz(const shp_multipatch_t *multipatch, size_t point_num,
                      shp_pointz_t *pointz)
{
    const char *buf;

    assert(multipatch != NULL);
    assert(point_num < multipatch->num_points);
    assert(pointz != NULL);

    buf = multipatch->points + 16 * point_num;
    pointz->x = shp_le64_to_double(&buf[0]);
    pointz->y = shp_le64_to_double(&buf[8]);

    buf = multipatch->z_array + 8 * point_num;
    pointz->z = shp_le64_to_double(&buf[0]);

    buf = multipatch->m_array + 8 * point_num;
    pointz->m = shp_le64_to_double(&buf[0]);
}
