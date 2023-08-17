/*
 * Read ESRI shapefiles
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This library is free software; you can redistribute it and/or modify it
 * under either the terms of the ISC License or the same terms as Perl.
 */

/* SPDX-License-Identifier: ISC OR Artistic-1.0-Perl OR GPL-1.0-or-later */

#include "shp-multipointm.h"
#include "byteorder.h"
#include <assert.h>

void
shp_multipointm_pointm(const shp_multipointm_t *multipointm, size_t point_num,
                       shp_pointm_t *pointm)
{
    const char *buf;

    assert(multipointm != NULL);
    assert(point_num < multipointm->num_points);
    assert(pointm != NULL);

    buf = multipointm->points + 16 * point_num;
    pointm->x = shp_le64_to_double(&buf[0]);
    pointm->y = shp_le64_to_double(&buf[8]);

    buf = multipointm->m_array + 8 * point_num;
    pointm->m = shp_le64_to_double(&buf[0]);
}
