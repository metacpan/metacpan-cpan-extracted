/*
 * Read ESRI shapefiles
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This library is free software; you can redistribute it and/or modify it
 * under either the terms of the ISC License or the same terms as Perl.
 */

/* SPDX-License-Identifier: ISC OR Artistic-1.0-Perl OR GPL-1.0-or-later */

#include "shp-polylinem.h"
#include "byteorder.h"
#include <assert.h>

size_t
shp_polylinem_points(const shp_polylinem_t *polylinem, size_t part_num,
                     size_t *start, size_t *end)
{
    size_t num_points, i, j, m;
    const char *buf;

    assert(polylinem != NULL);
    assert(part_num < polylinem->num_parts);
    assert(start != NULL);
    assert(end != NULL);

    m = polylinem->num_points;

    buf = polylinem->parts + 4 * part_num;
    i = shp_le32_to_int32(&buf[0]);
    if (part_num + 1 < polylinem->num_parts) {
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
shp_polylinem_pointm(const shp_polylinem_t *polylinem, size_t point_num,
                     shp_pointm_t *pointm)
{
    const char *buf;

    assert(polylinem != NULL);
    assert(point_num < polylinem->num_points);
    assert(pointm != NULL);

    buf = polylinem->points + 16 * point_num;
    pointm->x = shp_le64_to_double(&buf[0]);
    pointm->y = shp_le64_to_double(&buf[8]);

    buf = polylinem->m_array + 8 * point_num;
    pointm->m = shp_le64_to_double(&buf[0]);
}
