/*
 * Read ESRI shapefiles
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This library is free software; you can redistribute it and/or modify it
 * under either the terms of the ISC License or the same terms as Perl.
 */

/* SPDX-License-Identifier: ISC OR Artistic-1.0-Perl OR GPL-1.0-or-later */

#include "shp-polygon.h"
#include "byteorder.h"
#include <assert.h>

size_t
shp_polygon_points(const shp_polygon_t *polygon, size_t part_num,
                   size_t *start, size_t *end)
{
    size_t num_points, i, j, m;
    const char *buf;

    assert(polygon != NULL);
    assert(part_num < polygon->num_parts);
    assert(start != NULL);
    assert(end != NULL);

    m = polygon->num_points;

    buf = polygon->parts + 4 * part_num;
    i = shp_le32_to_int32(&buf[0]);
    if (part_num + 1 < polygon->num_parts) {
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
shp_polygon_point(const shp_polygon_t *polygon, size_t point_num,
                  shp_point_t *point)
{
    const char *buf;

    assert(polygon != NULL);
    assert(point_num < polygon->num_points);
    assert(point != NULL);

    buf = polygon->points + 16 * point_num;
    point->x = shp_le64_to_double(&buf[0]);
    point->y = shp_le64_to_double(&buf[8]);
}

int
shp_point_in_polygon(const shp_point_t *point, const shp_polygon_t *polygon)
{
    size_t parts_count, part_num, i, n;
    shp_point_t p;
    size_t k;
    double x, y, f, u1, v1, u2, v2;

    assert(polygon != NULL);
    assert(point != NULL);

    if (shp_point_in_bounding_box(point, polygon->x_min, polygon->y_min,
                                  polygon->x_max, polygon->y_max) == 0) {
        return 0;
    }

    k = 0;
    x = point->x;
    y = point->y;

    parts_count = polygon->num_parts;
    for (part_num = 0; part_num < parts_count; ++part_num) {
        if (shp_polygon_points(polygon, part_num, &i, &n) >= 4) {
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
                    else if (u1 <= 0.0 && u2 >= 0.0) {
                        return -1;
                    }
                }

                u1 = u2;
                v1 = v2;
            }
        }
    }

    return (k % 2 == 0) ? 0 : 1;
}
