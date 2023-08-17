/*
 * Read ESRI shapefiles
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This library is free software; you can redistribute it and/or modify it
 * under either the terms of the ISC License or the same terms as Perl.
 */

/* SPDX-License-Identifier: ISC OR Artistic-1.0-Perl OR GPL-1.0-or-later */

#include "shp.h"
#include "byteorder.h"
#include <assert.h>
#include <errno.h>
#include <limits.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef SHP_MIN_BUF_SIZE
#define SHP_MIN_BUF_SIZE 26214400
#endif

static size_t
file_fread(shp_file_t *fh, void *buf, size_t count)
{
    size_t nr = fread(buf, 1, count, (FILE *) fh->stream);
    fh->num_bytes += nr;
    return nr;
}

static int
file_feof(shp_file_t *fh)
{
    return feof((FILE *) fh->stream);
}

static int
file_ferror(shp_file_t *fh)
{
    return ferror((FILE *) fh->stream);
}

static int
file_fsetpos(shp_file_t *fh, size_t offset)
{
    if (offset > LONG_MAX) {
        errno = EINVAL;
        return -1;
    }
    return fseek((FILE *) fh->stream, (long) offset, SEEK_SET);
}

shp_file_t *
shp_init_file(shp_file_t *fh, FILE *stream, void *user_data)
{
    assert(fh != NULL);
    assert(stream != NULL);

    fh->stream = stream;
    fh->fread = file_fread;
    fh->feof = file_feof;
    fh->ferror = file_ferror;
    fh->fsetpos = file_fsetpos;
    fh->user_data = user_data;
    fh->num_bytes = 0;
    fh->error[0] = '\0';

    return fh;
}

void
shp_set_error(shp_file_t *fh, const char *format, ...)
{
    va_list ap;

    assert(fh != NULL);
    assert(format != NULL);

    va_start(ap, format);
    vsnprintf(fh->error, sizeof(fh->error), format, ap); /* NOLINT */
    va_end(ap);
}

int
shp_read_header(shp_file_t *fh, shp_header_t *header)
{
    int rc = -1;
    char buf[100];
    long file_code;
    size_t nr;

    assert(fh != NULL);
    assert(header != NULL);

    nr = (*fh->fread)(fh, buf, 100);
    if ((*fh->ferror)(fh)) {
        shp_set_error(fh, "Cannot read file header");
        goto cleanup;
    }
    if (nr != 100) {
        shp_set_error(fh, "Expected file header of %zu bytes, got %zu",
                      (size_t) 100, nr);
        errno = EINVAL;
        goto cleanup;
    }

    file_code = shp_be32_to_int32(&buf[0]);
    if (file_code != 9994) {
        shp_set_error(fh, "Expected file code 9994, got %ld", file_code);
        errno = EINVAL;
        goto cleanup;
    }

    header->file_code = file_code;
    header->unused[0] = shp_be32_to_int32(&buf[4]);
    header->unused[1] = shp_be32_to_int32(&buf[8]);
    header->unused[2] = shp_be32_to_int32(&buf[12]);
    header->unused[3] = shp_be32_to_int32(&buf[16]);
    header->unused[4] = shp_be32_to_int32(&buf[20]);
    header->file_size = 2 * (size_t) shp_be32_to_uint32(&buf[24]);
    header->version = shp_le32_to_int32(&buf[28]);
    header->type = (shp_type_t) shp_le32_to_int32(&buf[32]);
    header->x_min = shp_le64_to_double(&buf[36]);
    header->y_min = shp_le64_to_double(&buf[44]);
    header->x_max = shp_le64_to_double(&buf[52]);
    header->y_max = shp_le64_to_double(&buf[60]);
    header->z_min = shp_le64_to_double(&buf[68]);
    header->z_max = shp_le64_to_double(&buf[76]);
    header->m_min = shp_le64_to_double(&buf[84]);
    header->m_max = shp_le64_to_double(&buf[92]);

    rc = 1;

cleanup:

    return rc;
}

static int
get_point(shp_file_t *fh, const char *buf, shp_record_t *record)
{
    int rc = -1;
    shp_point_t *point = &record->shape.point;
    size_t record_size, expected_size = 20;

    record_size = record->record_size;
    if (record_size != expected_size) {
        shp_set_error(fh,
                      "Expected record of %zu bytes, got %zu in record %zu",
                      expected_size, record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    point->x = shp_le64_to_double(&buf[4]);
    point->y = shp_le64_to_double(&buf[12]);

    rc = 1;

cleanup:

    return rc;
}

static int
get_pointm(shp_file_t *fh, const char *buf, shp_record_t *record)
{
    int rc = -1;
    shp_pointm_t *point = &record->shape.pointm;
    size_t record_size, expected_size = 28;

    record_size = record->record_size;
    if (record_size != expected_size) {
        shp_set_error(fh,
                      "Expected record of %zu bytes, got %zu in record %zu",
                      expected_size, record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    point->x = shp_le64_to_double(&buf[4]);
    point->y = shp_le64_to_double(&buf[12]);
    point->m = shp_le64_to_double(&buf[20]);

    rc = 1;

cleanup:

    return rc;
}

static int
get_pointz(shp_file_t *fh, const char *buf, shp_record_t *record)
{
    int rc = -1;
    shp_pointz_t *point = &record->shape.pointz;
    size_t record_size, expected_size = 36;

    record_size = record->record_size;
    if (record_size != expected_size) {
        shp_set_error(fh,
                      "Expected record of %zu bytes, got %zu in record %zu",
                      expected_size, record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    point->x = shp_le64_to_double(&buf[4]);
    point->y = shp_le64_to_double(&buf[12]);
    point->z = shp_le64_to_double(&buf[20]);
    point->m = shp_le64_to_double(&buf[28]);

    rc = 1;

cleanup:

    return rc;
}

static int
get_multipoint(shp_file_t *fh, const char *buf, shp_record_t *record)
{
    int rc = -1;
    shp_multipoint_t *multipoint = &record->shape.multipoint;
    size_t record_size, points_size, expected_size;

    record_size = record->record_size;
    if (record_size < 40) {
        shp_set_error(fh, "Record size %zu is too small in record %zu",
                      record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    multipoint->x_min = shp_le64_to_double(&buf[4]);
    multipoint->y_min = shp_le64_to_double(&buf[12]);
    multipoint->x_max = shp_le64_to_double(&buf[20]);
    multipoint->y_max = shp_le64_to_double(&buf[28]);
    multipoint->num_points = shp_le32_to_uint32(&buf[36]);

    points_size = 16 * multipoint->num_points;

    expected_size = 40 + points_size;
    if (record_size != expected_size) {
        shp_set_error(fh,
                      "Expected record of %zu bytes, got %zu in record %zu",
                      expected_size, record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    multipoint->points = &buf[40];

    rc = 1;

cleanup:

    return rc;
}

static int
get_multipointm(shp_file_t *fh, const char *buf, shp_record_t *record)
{
    int rc = -1;
    shp_multipointm_t *multipointm = &record->shape.multipointm;
    size_t record_size, points_size, m_size, expected_size;

    record_size = record->record_size;
    if (record_size < 56) {
        shp_set_error(fh, "Record size %zu is too small in record %zu",
                      record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    multipointm->x_min = shp_le64_to_double(&buf[4]);
    multipointm->y_min = shp_le64_to_double(&buf[12]);
    multipointm->x_max = shp_le64_to_double(&buf[20]);
    multipointm->y_max = shp_le64_to_double(&buf[28]);
    multipointm->num_points = shp_le32_to_uint32(&buf[36]);

    points_size = 16 * multipointm->num_points;
    m_size = 8 * multipointm->num_points;

    expected_size = 56 + points_size + m_size;
    if (record_size != expected_size) {
        shp_set_error(fh,
                      "Expected record of %zu bytes, got %zu in record %zu",
                      expected_size, record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    multipointm->points = &buf[40];

    buf = multipointm->points + points_size;
    multipointm->m_min = shp_le64_to_double(&buf[0]);
    multipointm->m_max = shp_le64_to_double(&buf[8]);
    multipointm->m_array = &buf[16];

    rc = 1;

cleanup:

    return rc;
}

static int
get_multipointz(shp_file_t *fh, const char *buf, shp_record_t *record)
{
    int rc = -1;
    shp_multipointz_t *multipointz = &record->shape.multipointz;
    size_t record_size, points_size, z_size, m_size, expected_size;

    record_size = record->record_size;
    if (record_size < 72) {
        shp_set_error(fh, "Record size %zu is too small in record %zu",
                      record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    multipointz->x_min = shp_le64_to_double(&buf[4]);
    multipointz->y_min = shp_le64_to_double(&buf[12]);
    multipointz->x_max = shp_le64_to_double(&buf[20]);
    multipointz->y_max = shp_le64_to_double(&buf[28]);
    multipointz->num_points = shp_le32_to_uint32(&buf[36]);

    points_size = 16 * multipointz->num_points;
    z_size = 8 * multipointz->num_points;
    m_size = z_size;

    expected_size = 72 + points_size + z_size + m_size;
    if (record_size != expected_size) {
        shp_set_error(fh,
                      "Expected record of %zu bytes, got %zu in record %zu",
                      expected_size, record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    multipointz->points = &buf[40];

    buf = multipointz->points + points_size;
    multipointz->z_min = shp_le64_to_double(&buf[0]);
    multipointz->z_max = shp_le64_to_double(&buf[8]);
    multipointz->z_array = &buf[16];

    buf = multipointz->z_array + z_size;
    multipointz->m_min = shp_le64_to_double(&buf[0]);
    multipointz->m_max = shp_le64_to_double(&buf[8]);
    multipointz->m_array = &buf[16];

    rc = 1;

cleanup:

    return rc;
}

static int
get_polyline(shp_file_t *fh, const char *buf, shp_record_t *record)
{
    int rc = -1;
    shp_polyline_t *polyline = &record->shape.polyline;
    size_t record_size, parts_size, points_size, expected_size;

    record_size = record->record_size;
    if (record_size < 44) {
        shp_set_error(fh, "Record size %zu is too small in record %zu",
                      record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    polyline->x_min = shp_le64_to_double(&buf[4]);
    polyline->y_min = shp_le64_to_double(&buf[12]);
    polyline->x_max = shp_le64_to_double(&buf[20]);
    polyline->y_max = shp_le64_to_double(&buf[28]);
    polyline->num_parts = shp_le32_to_uint32(&buf[36]);
    polyline->num_points = shp_le32_to_uint32(&buf[40]);

    parts_size = 4 * polyline->num_parts;
    points_size = 16 * polyline->num_points;

    expected_size = 44 + parts_size + points_size;
    if (record_size != expected_size) {
        shp_set_error(fh,
                      "Expected record of %zu bytes, got %zu in record %zu",
                      expected_size, record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    polyline->parts = &buf[44];
    polyline->points = &buf[44 + parts_size];

    rc = 1;

cleanup:

    return rc;
}

static int
get_polylinem(shp_file_t *fh, const char *buf, shp_record_t *record)
{
    int rc = -1;
    shp_polylinem_t *polylinem = &record->shape.polylinem;
    size_t record_size, parts_size, points_size, m_size, expected_size;

    record_size = record->record_size;
    if (record_size < 60) {
        shp_set_error(fh, "Record size %zu is too small in record %zu",
                      record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    polylinem->x_min = shp_le64_to_double(&buf[4]);
    polylinem->y_min = shp_le64_to_double(&buf[12]);
    polylinem->x_max = shp_le64_to_double(&buf[20]);
    polylinem->y_max = shp_le64_to_double(&buf[28]);
    polylinem->num_parts = shp_le32_to_uint32(&buf[36]);
    polylinem->num_points = shp_le32_to_uint32(&buf[40]);

    parts_size = 4 * polylinem->num_parts;
    points_size = 16 * polylinem->num_points;
    m_size = 8 * polylinem->num_points;

    expected_size = 60 + parts_size + points_size + m_size;
    if (record_size != expected_size) {
        shp_set_error(fh,
                      "Expected record of %zu bytes, got %zu in record %zu",
                      expected_size, record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    polylinem->parts = &buf[44];
    polylinem->points = polylinem->parts + parts_size;

    buf = polylinem->points + points_size;
    polylinem->m_min = shp_le64_to_double(&buf[0]);
    polylinem->m_max = shp_le64_to_double(&buf[8]);
    polylinem->m_array = &buf[16];

    rc = 1;

cleanup:

    return rc;
}

static int
get_polylinez(shp_file_t *fh, const char *buf, shp_record_t *record)
{
    int rc = -1;
    shp_polylinez_t *polylinez = &record->shape.polylinez;
    size_t record_size, parts_size, points_size, z_size, m_size,
        expected_size;

    record_size = record->record_size;
    if (record_size < 76) {
        shp_set_error(fh, "Record size %zu is too small in record %zu",
                      record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    polylinez->x_min = shp_le64_to_double(&buf[4]);
    polylinez->y_min = shp_le64_to_double(&buf[12]);
    polylinez->x_max = shp_le64_to_double(&buf[20]);
    polylinez->y_max = shp_le64_to_double(&buf[28]);
    polylinez->num_parts = shp_le32_to_uint32(&buf[36]);
    polylinez->num_points = shp_le32_to_uint32(&buf[40]);

    parts_size = 4 * polylinez->num_parts;
    points_size = 16 * polylinez->num_points;
    z_size = 8 * polylinez->num_points;
    m_size = z_size;

    expected_size = 76 + parts_size + points_size + z_size + m_size;
    if (record_size != expected_size) {
        shp_set_error(fh,
                      "Expected record of %zu bytes, got %zu in record %zu",
                      expected_size, record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    polylinez->parts = &buf[44];
    polylinez->points = polylinez->parts + parts_size;

    buf = polylinez->points + points_size;
    polylinez->z_min = shp_le64_to_double(&buf[0]);
    polylinez->z_max = shp_le64_to_double(&buf[8]);
    polylinez->z_array = &buf[16];

    buf = polylinez->z_array + z_size;
    polylinez->m_min = shp_le64_to_double(&buf[0]);
    polylinez->m_max = shp_le64_to_double(&buf[8]);
    polylinez->m_array = &buf[16];

    rc = 1;

cleanup:

    return rc;
}

static int
get_polygon(shp_file_t *fh, const char *buf, shp_record_t *record)
{
    int rc = -1;
    shp_polygon_t *polygon = &record->shape.polygon;
    size_t record_size, parts_size, points_size, expected_size;

    record_size = record->record_size;
    if (record_size < 44) {
        shp_set_error(fh, "Record size %zu is too small in record %zu",
                      record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    polygon->x_min = shp_le64_to_double(&buf[4]);
    polygon->y_min = shp_le64_to_double(&buf[12]);
    polygon->x_max = shp_le64_to_double(&buf[20]);
    polygon->y_max = shp_le64_to_double(&buf[28]);
    polygon->num_parts = shp_le32_to_uint32(&buf[36]);
    polygon->num_points = shp_le32_to_uint32(&buf[40]);

    parts_size = 4 * polygon->num_parts;
    points_size = 16 * polygon->num_points;

    expected_size = 44 + parts_size + points_size;
    if (record_size != expected_size) {
        shp_set_error(fh,
                      "Expected record of %zu bytes, got %zu in record %zu",
                      expected_size, record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    polygon->parts = &buf[44];
    polygon->points = &buf[44 + parts_size];

    rc = 1;

cleanup:

    return rc;
}

static int
get_polygonm(shp_file_t *fh, const char *buf, shp_record_t *record)
{
    int rc = -1;
    shp_polygonm_t *polygonm = &record->shape.polygonm;
    size_t record_size, parts_size, points_size, m_size, expected_size;

    record_size = record->record_size;
    if (record_size < 60) {
        shp_set_error(fh, "Record size %zu is too small in record %zu",
                      record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    polygonm->x_min = shp_le64_to_double(&buf[4]);
    polygonm->y_min = shp_le64_to_double(&buf[12]);
    polygonm->x_max = shp_le64_to_double(&buf[20]);
    polygonm->y_max = shp_le64_to_double(&buf[28]);
    polygonm->num_parts = shp_le32_to_uint32(&buf[36]);
    polygonm->num_points = shp_le32_to_uint32(&buf[40]);

    parts_size = 4 * polygonm->num_parts;
    points_size = 16 * polygonm->num_points;
    m_size = 8 * polygonm->num_points;

    expected_size = 60 + parts_size + points_size + m_size;
    if (record_size != expected_size) {
        shp_set_error(fh,
                      "Expected record of %zu bytes, got %zu in record %zu",
                      expected_size, record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    polygonm->parts = &buf[44];
    polygonm->points = polygonm->parts + parts_size;

    buf = polygonm->points + points_size;
    polygonm->m_min = shp_le64_to_double(&buf[0]);
    polygonm->m_max = shp_le64_to_double(&buf[8]);
    polygonm->m_array = &buf[16];

    rc = 1;

cleanup:

    return rc;
}

static int
get_polygonz(shp_file_t *fh, const char *buf, shp_record_t *record)
{
    int rc = -1;
    shp_polygonz_t *polygonz = &record->shape.polygonz;
    size_t record_size, parts_size, points_size, z_size, m_size,
        expected_size;

    record_size = record->record_size;
    if (record_size < 76) {
        shp_set_error(fh, "Record size %zu is too small in record %zu",
                      record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    polygonz->x_min = shp_le64_to_double(&buf[4]);
    polygonz->y_min = shp_le64_to_double(&buf[12]);
    polygonz->x_max = shp_le64_to_double(&buf[20]);
    polygonz->y_max = shp_le64_to_double(&buf[28]);
    polygonz->num_parts = shp_le32_to_uint32(&buf[36]);
    polygonz->num_points = shp_le32_to_uint32(&buf[40]);

    parts_size = 4 * polygonz->num_parts;
    points_size = 16 * polygonz->num_points;
    z_size = 8 * polygonz->num_points;
    m_size = z_size;

    expected_size = 76 + parts_size + points_size + z_size + m_size;
    if (record_size != expected_size) {
        shp_set_error(fh,
                      "Expected record of %zu bytes, got %zu in record %zu",
                      expected_size, record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    polygonz->parts = &buf[44];
    polygonz->points = polygonz->parts + parts_size;

    buf = polygonz->points + points_size;
    polygonz->z_min = shp_le64_to_double(&buf[0]);
    polygonz->z_max = shp_le64_to_double(&buf[8]);
    polygonz->z_array = &buf[16];

    buf = polygonz->z_array + z_size;
    polygonz->m_min = shp_le64_to_double(&buf[0]);
    polygonz->m_max = shp_le64_to_double(&buf[8]);
    polygonz->m_array = &buf[16];

    rc = 1;

cleanup:

    return rc;
}

static int
get_multipatch(shp_file_t *fh, const char *buf, shp_record_t *record)
{
    int rc = -1;
    shp_multipatch_t *multipatch = &record->shape.multipatch;
    size_t record_size, parts_size, points_size, z_size, m_size,
        expected_size;

    record_size = record->record_size;
    if (record_size < 76) {
        shp_set_error(fh, "Record size %zu is too small in record %zu",
                      record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    multipatch->x_min = shp_le64_to_double(&buf[4]);
    multipatch->y_min = shp_le64_to_double(&buf[12]);
    multipatch->x_max = shp_le64_to_double(&buf[20]);
    multipatch->y_max = shp_le64_to_double(&buf[28]);
    multipatch->num_parts = shp_le32_to_uint32(&buf[36]);
    multipatch->num_points = shp_le32_to_uint32(&buf[40]);

    parts_size = 4 * multipatch->num_parts;
    points_size = 16 * multipatch->num_points;
    z_size = 8 * multipatch->num_points;
    m_size = z_size;

    expected_size = 76 + 2 * parts_size + points_size + z_size + m_size;
    if (record_size != expected_size) {
        shp_set_error(fh,
                      "Expected record of %zu bytes, got %zu in record %zu",
                      expected_size, record_size, record->record_number);
        errno = EINVAL;
        goto cleanup;
    }

    multipatch->parts = &buf[44];
    multipatch->types = multipatch->parts + parts_size;
    multipatch->points = multipatch->types + parts_size;

    buf = multipatch->points + points_size;
    multipatch->z_min = shp_le64_to_double(&buf[0]);
    multipatch->z_max = shp_le64_to_double(&buf[8]);
    multipatch->z_array = &buf[16];

    buf = multipatch->z_array + z_size;
    multipatch->m_min = shp_le64_to_double(&buf[0]);
    multipatch->m_max = shp_le64_to_double(&buf[8]);
    multipatch->m_array = &buf[16];

    rc = 1;

cleanup:

    return rc;
}

static int
read_record(shp_file_t *fh, shp_record_t **precord, size_t *size)
{
    int rc = -1;
    char header_buf[8], *buf;
    size_t record_number, content_length;
    size_t record_size, buf_size;
    struct shp_record_t *record;
    size_t nr;

    nr = (*fh->fread)(fh, header_buf, 8);
    if ((*fh->ferror)(fh)) {
        shp_set_error(fh, "Cannot read record header");
        goto cleanup;
    }
    if ((*fh->feof)(fh)) {
        /* Reached end of file. */
        rc = 0;
        goto cleanup;
    }
    if (nr != 8) {
        shp_set_error(fh, "Expected record header of %zu bytes, got %zu",
                      (size_t) 8, nr);
        errno = EINVAL;
        goto cleanup;
    }

    record_number = shp_be32_to_uint32(&header_buf[0]);

    content_length = shp_be32_to_uint32(&header_buf[4]);
    if (content_length < 2) {
        shp_set_error(fh, "Content length %zu is invalid in record %zu",
                      content_length, record_number);
        errno = EINVAL;
        goto cleanup;
    }

    record_size = 2 * content_length;

    record = *precord;
    buf_size = sizeof(*record) + record_size;
    if (record == NULL || *size < buf_size) {
        record = (shp_record_t *) realloc(record, buf_size);
        if (record == NULL) {
            shp_set_error(fh, "Cannot allocate %zu bytes for record %zu",
                          buf_size, record_number);
            goto cleanup;
        }
        *precord = record;
        *size = buf_size;
    }

    buf = ((char *) record) + sizeof(*record);

    nr = (*fh->fread)(fh, buf, record_size);
    if ((*fh->ferror)(fh)) {
        shp_set_error(fh, "Cannot read record %zu", record_number);
        goto cleanup;
    }
    if (nr != record_size) {
        shp_set_error(fh,
                      "Expected record of %zu bytes, got %zu in record %zu",
                      record_size, nr, record_number);
        errno = EINVAL;
        goto cleanup;
    }

    record->record_number = record_number;
    record->record_size = record_size;
    record->type = (shp_type_t) shp_le32_to_int32(&buf[0]);
    switch (record->type) {
    case SHP_TYPE_NULL:
        rc = 1;
        break;
    case SHP_TYPE_POINT:
        rc = get_point(fh, buf, record);
        break;
    case SHP_TYPE_POINTM:
        rc = get_pointm(fh, buf, record);
        break;
    case SHP_TYPE_POINTZ:
        rc = get_pointz(fh, buf, record);
        break;
    case SHP_TYPE_MULTIPOINT:
        rc = get_multipoint(fh, buf, record);
        break;
    case SHP_TYPE_MULTIPOINTM:
        rc = get_multipointm(fh, buf, record);
        break;
    case SHP_TYPE_MULTIPOINTZ:
        rc = get_multipointz(fh, buf, record);
        break;
    case SHP_TYPE_POLYLINE:
        rc = get_polyline(fh, buf, record);
        break;
    case SHP_TYPE_POLYLINEM:
        rc = get_polylinem(fh, buf, record);
        break;
    case SHP_TYPE_POLYLINEZ:
        rc = get_polylinez(fh, buf, record);
        break;
    case SHP_TYPE_POLYGON:
        rc = get_polygon(fh, buf, record);
        break;
    case SHP_TYPE_POLYGONM:
        rc = get_polygonm(fh, buf, record);
        break;
    case SHP_TYPE_POLYGONZ:
        rc = get_polygonz(fh, buf, record);
        break;
    case SHP_TYPE_MULTIPATCH:
        rc = get_multipatch(fh, buf, record);
        break;
    default:
        shp_set_error(fh, "Shape type %d is unknown in record %zu",
                      (int) record->type, record_number);
        errno = EINVAL;
        break;
    }

cleanup:

    return rc;
}

int
shp_read_record(shp_file_t *fh, shp_record_t **precord)
{
    int rc;
    shp_record_t *record = NULL;
    size_t buf_size = 0;

    assert(fh != NULL);
    assert(precord != NULL);

    rc = read_record(fh, &record, &buf_size);
    if (rc <= 0) {
        free(record);
        record = NULL;
    }

    *precord = record;

    return rc;
}

int
shp_seek_record(shp_file_t *fh, size_t file_offset, shp_record_t **precord)
{
    int rc = -1;
    shp_record_t *record = NULL;
    size_t buf_size = 0;

    assert(fh != NULL);
    assert(precord != NULL);

    /* The largest possible file offset is 8GB minus 12 bytes for a null
     * shape.  The offset may be further limited by LONG_MAX on 32-bit
     * systems. */
    if ((*fh->fsetpos)(fh, file_offset) != 0) {
        shp_set_error(fh, "Cannot set file position to %zu\n", file_offset);
        goto cleanup;
    }

    rc = read_record(fh, &record, &buf_size);
    if (rc <= 0) {
        free(record);
        record = NULL;
    }

cleanup:

    *precord = record;

    return rc;
}

int
shp_read(shp_file_t *fh, shp_header_callback_t handle_header,
         shp_record_callback_t handle_record)
{
    int rc = -1, rc2;
    shp_header_t header;
    shp_record_t *record = NULL;
    size_t buf_size;
    size_t file_offset;

    assert(fh != NULL);
    assert(handle_header != NULL);
    assert(handle_record != NULL);

    rc2 = shp_read_header(fh, &header);
    if (rc2 == 0) {
        /* Reached end of file. */
        rc = 0;
    }
    if (rc2 <= 0) {
        goto cleanup;
    }

    rc2 = (*handle_header)(fh, &header);
    if (rc2 == 0) {
        /* Stop processing. */
        rc = 0;
    }
    if (rc2 <= 0) {
        goto cleanup;
    }

    /* Preallocate a big record. */
    buf_size = SHP_MIN_BUF_SIZE;
    record = (shp_record_t *) malloc(buf_size);
    if (record == NULL) {
        shp_set_error(fh, "Cannot allocate %zu bytes", buf_size);
        goto cleanup;
    }

    for (;;) {
        file_offset = fh->num_bytes;

        rc2 = read_record(fh, &record, &buf_size);
        if (rc2 == 0) {
            /* Reached end of file. */
            rc = 0;
        }
        if (rc2 <= 0) {
            goto cleanup;
        }

        rc2 = (*handle_record)(fh, &header, record, file_offset);
        if (rc2 == 0) {
            /* Stop processing. */
            rc = 0;
        }
        if (rc2 <= 0) {
            goto cleanup;
        }
    }

cleanup:

    free(record);

    return rc;
}
