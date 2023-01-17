/*
 * Read ESRI shapefiles
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This library is free software; you can redistribute it and/or modify it
 * under either the terms of the ISC License or the same terms as Perl.
 */

/* SPDX-License-Identifier: ISC OR Artistic-1.0-Perl OR GPL-1.0-or-later */

#include "shp-box.h"
#include "shp-point.h"
#include <assert.h>
#include <stddef.h>

int
shp_box_point_in_box(const shp_box_t *box, const shp_point_t *point)
{
    double x, y, x_min, y_min, x_max, y_max;

    assert(box != NULL);
    assert(point != NULL);

    x = point->x;
    y = point->y;
    x_min = box->x_min;
    y_min = box->y_min;
    x_max = box->x_max;
    y_max = box->y_max;

    if (x >= x_min && x <= x_max && y >= y_min && y <= y_max) {
        if (x == x_min || x == x_max || y == y_min || y == y_max) {
            return -1;
        }
        return 1;
    }
    return 0;
}
