/*
 * Read ESRI shapefiles
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This library is free software; you can redistribute it and/or modify it
 * under either the terms of the ISC License or the same terms as Perl.
 */

/* SPDX-License-Identifier: ISC OR Artistic-1.0-Perl OR GPL-1.0-or-later */

#include "shp-polygonz.h"
#include "byteorder.h"
#include <assert.h>

size_t
shp_polygonz_points(const shp_polygonz_t *polygonz, size_t part_num,
                    size_t *start, size_t *end)
{
    size_t num_points, i, j, m;
    const char *buf;

    assert(polygonz != NULL);
    assert(part_num < polygonz->num_parts);
    assert(start != NULL);
    assert(end != NULL);

    m = polygonz->num_points;

    buf = polygonz->parts + 4 * part_num;
    i = shp_le32_to_int32(&buf[0]);
    if (part_num + 1 < polygonz->num_parts) {
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
shp_polygonz_pointz(const shp_polygonz_t *polygonz, size_t point_num,
                    shp_pointz_t *pointz)
{
    const char *buf;

    assert(polygonz != NULL);
    assert(point_num < polygonz->num_points);
    assert(pointz != NULL);

    buf = polygonz->points + 16 * point_num;
    pointz->x = shp_le64_to_double(&buf[0]);
    pointz->y = shp_le64_to_double(&buf[8]);

    buf = polygonz->z_array + 8 * point_num;
    pointz->z = shp_le64_to_double(&buf[0]);

    buf = polygonz->m_array + 8 * point_num;
    pointz->m = shp_le64_to_double(&buf[0]);
}
