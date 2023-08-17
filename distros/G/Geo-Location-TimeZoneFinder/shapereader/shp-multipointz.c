/*
 * Read ESRI shapefiles
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This library is free software; you can redistribute it and/or modify it
 * under either the terms of the ISC License or the same terms as Perl.
 */

/* SPDX-License-Identifier: ISC OR Artistic-1.0-Perl OR GPL-1.0-or-later */

#include "shp-multipointz.h"
#include "byteorder.h"
#include <assert.h>

void
shp_multipointz_pointz(const shp_multipointz_t *multipointz, size_t point_num,
                       shp_pointz_t *pointz)
{
    const char *buf;

    assert(multipointz != NULL);
    assert(point_num < multipointz->num_points);
    assert(pointz != NULL);

    buf = multipointz->points + 16 * point_num;
    pointz->x = shp_le64_to_double(&buf[0]);
    pointz->y = shp_le64_to_double(&buf[8]);

    buf = multipointz->z_array + 8 * point_num;
    pointz->z = shp_le64_to_double(&buf[0]);

    buf = multipointz->m_array + 8 * point_num;
    pointz->m = shp_le64_to_double(&buf[0]);
}
