/*
 * Read ESRI shapefiles
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This library is free software; you can redistribute it and/or modify it
 * under either the terms of the ISC License or the same terms as Perl.
 */

/* SPDX-License-Identifier: ISC OR Artistic-1.0-Perl OR GPL-1.0-or-later */

#include "convert.h"
#include "shp-polygon.h"
#include <assert.h>
#include <stddef.h>

int32_t
shp_polygon_points(const shp_polygon_t *polygon, int32_t part_num,
                   int32_t *pstart, int32_t *pend)
{
    int32_t num_points = 0;
    int32_t i, j, m;
    const char *buf;

    assert(polygon != NULL);
    assert(part_num >= 0);
    assert(part_num < polygon->num_parts);
    assert(pstart != NULL);
    assert(pend != NULL);

    m = polygon->num_points;

    buf = polygon->_parts + 4 * part_num;
    i = shp_le32_to_int32(&buf[0]);
    if (part_num + 1 < polygon->num_parts) {
        j = shp_le32_to_int32(&buf[4]);
    }
    else {
        j = m;
    }

    *pstart = i;
    *pend = j;

    /* Is the range valid? */
    if (i >= 0 && i < m && j >= 0 && j <= m && i < j) {
        num_points = j - i;
    }

    return num_points;
}

void
shp_polygon_point(const shp_polygon_t *polygon, int32_t point_num,
                  shp_point_t *ppoint)
{
    const char *buf;

    assert(polygon != NULL);
    assert(point_num >= 0);
    assert(point_num < polygon->num_points);
    assert(ppoint != NULL);

    buf = polygon->_points + 16 * point_num;
    ppoint->x = shp_le64_to_double(&buf[0]);
    ppoint->y = shp_le64_to_double(&buf[8]);
}

int
shp_polygon_point_in_polygon(const shp_polygon_t *polygon,
                             const shp_point_t *point)
{
    int32_t k, i, n, parts_count, part_num;
    double x, y, f, u1, v1, u2, v2;
    shp_point_t p;

    assert(polygon != NULL);
    assert(point != NULL);

    if (shp_box_point_in_box(&polygon->box, point) == 0) {
        return 0;
    }

    k = 0;
    x = point->x;
    y = point->y;

    parts_count = polygon->num_parts;
    for (part_num = 0; part_num < parts_count; ++part_num) {
        if (shp_polygon_points(polygon, part_num, &i, &n) < 4) {
            /* The shape file is corrupt. */
            return 0;
        }

        shp_polygon_point(polygon, i, &p);
        u1 = p.x - x;
        v1 = p.y - y;

        while (++i < n) {
            shp_polygon_point(polygon, i, &p);
            u2 = p.x - x;
            v2 = p.y - y;

            if ((v1 < 0.0 && v2 < 0.0) || (v1 > 0.0 && v2 > 0.0)) {
                u1 = u2;
                v1 = v2;
                continue;
            }

            if (v2 > 0.0 && v1 <= 0.0) {
                f = u1 * v2 - u2 * v1;
                if (f > 0.0) {
                    ++k;
                }
                else if (f == 0.0) {
                    return -1;
                }
            }
            else if (v1 > 0.0 && v2 <= 0.0) {
                f = u1 * v2 - u2 * v1;
                if (f < 0.0) {
                    ++k;
                }
                else if (f == 0.0) {
                    return -1;
                }
            }
            else if (v2 == 0.0 && v1 < 0.0) {
                f = u1 * v2 - u2 * v1;
                if (f == 0.0) {
                    return -1;
                }
            }
            else if (v1 == 0.0 && v2 < 0.0) {
                f = u1 * v2 - u2 * v1;
                if (f == 0.0) {
                    return -1;
                }
            }
            else if (v1 == 0.0 && v2 == 0.0) {
                if (u2 <= 0.0 && u1 >= 0.0) {
                    return -1;
                }
                else if (u1 <= 0 && u2 >= 0.0) {
                    return -1;
                }
            }

            u1 = u2;
            v1 = v2;
        }
    }

    return (k % 2 == 0) ? 0 : 1;
}
