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
#include "shp.h"
#include <assert.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef SHP_MIN_BUF_SIZE
#define SHP_MIN_BUF_SIZE 26214400
#endif

shp_file_t *
shp_file(shp_file_t *fh, FILE *fp, void *user_data)
{
    assert(fh != NULL);
    assert(fp != NULL);

    fh->fp = fp;
    fh->user_data = user_data;
    fh->num_bytes = 0;
    fh->error[0] = '\0';

    return fh;
}

void
shp_error(shp_file_t *fh, const char *format, ...)
{
    va_list ap;

    assert(fh != NULL);
    assert(format != NULL);

    va_start(ap, format);
    vsnprintf(fh->error, sizeof(fh->error), format, ap); /* NOLINT */
    va_end(ap);
}

int
shp_read_header(shp_file_t *fh, shp_header_t **pheader)
{
    int rc = -1;
    shp_header_t *header = NULL;
    char buf[100];
    int32_t file_code;
    size_t nr;

    assert(fh != NULL);
    assert(fh->fp != NULL);
    assert(pheader != NULL);

    nr = fread(buf, 1, 100, fh->fp);
    fh->num_bytes += nr;
    if (ferror(fh->fp)) {
        shp_error(fh, "Cannot read file header");
        goto cleanup;
    }
    if (nr != 100) {
        shp_error(fh, "Expected file header of %zu bytes, got %zu",
                  (size_t) 100, nr);
        errno = EINVAL;
        goto cleanup;
    }

    file_code = shp_be32_to_int32(&buf[0]);
    if (file_code != 9994) {
        shp_error(fh, "Expected file code 9994, got %ld", (long) file_code);
        errno = EINVAL;
        goto cleanup;
    }

    header = (shp_header_t *) malloc(sizeof(*header));
    if (header == NULL) {
        shp_error(fh, "Cannot allocate %zu bytes", sizeof(*header));
        goto cleanup;
    }

    header->file_code = file_code;
    header->unused[0] = shp_be32_to_int32(&buf[4]);
    header->unused[1] = shp_be32_to_int32(&buf[8]);
    header->unused[2] = shp_be32_to_int32(&buf[12]);
    header->unused[3] = shp_be32_to_int32(&buf[16]);
    header->unused[4] = shp_be32_to_int32(&buf[20]);
    header->file_length = shp_be32_to_int32(&buf[24]);
    header->version = shp_le32_to_int32(&buf[28]);
    header->shape_type = (shp_shpt_t) shp_le32_to_int32(&buf[32]);
    header->x_min = shp_le64_to_double(&buf[36]);
    header->y_min = shp_le64_to_double(&buf[44]);
    header->x_max = shp_le64_to_double(&buf[52]);
    header->y_max = shp_le64_to_double(&buf[60]);
    header->z_min = shp_le64_to_double(&buf[68]);
    header->z_max = shp_le64_to_double(&buf[76]);
    header->m_min = shp_le64_to_double(&buf[84]);
    header->m_max = shp_le64_to_double(&buf[92]);

    if (feof(fh->fp)) {
        free(header);
        header = NULL;
        rc = 0;
        goto cleanup;
    }

    rc = 1;

cleanup:

    *pheader = header;

    return rc;
}

static size_t
get_record_size(const shp_record_t *record)
{
    return 2 * record->content_length;
}

static int
get_point(const char *buf, shp_record_t *record)
{
    int rc = -1;
    shp_point_t *point = &record->shape.point;

    if (get_record_size(record) != 16) {
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
get_polygon(const char *buf, shp_record_t *record)
{
    int rc = -1;
    shp_polygon_t *polygon = &record->shape.polygon;
    size_t record_size, parts_size, points_size;

    record_size = get_record_size(record);
    if (get_record_size(record) < 44) {
        errno = EINVAL;
        goto cleanup;
    }

    polygon->box.x_min = shp_le64_to_double(&buf[4]);
    polygon->box.y_min = shp_le64_to_double(&buf[12]);
    polygon->box.x_max = shp_le64_to_double(&buf[20]);
    polygon->box.y_max = shp_le64_to_double(&buf[28]);
    polygon->num_parts = shp_le32_to_int32(&buf[36]);
    polygon->num_points = shp_le32_to_int32(&buf[40]);

    parts_size = 4 * polygon->num_parts;
    points_size = 16 * polygon->num_points;

    if (record_size != 44 + parts_size + points_size) {
        errno = EINVAL;
        goto cleanup;
    }

    polygon->_parts = &buf[44];
    polygon->_points = &buf[44 + parts_size];

    rc = 1;

cleanup:

    return rc;
}

static int
read_record(shp_file_t *fh, shp_record_t **precord, size_t *psize)
{
    int rc = -1;
    char header_buf[8], *buf;
    int32_t record_number;
    int32_t content_length;
    size_t record_size, buf_size;
    struct shp_record_t *record;
    size_t nr;

    nr = fread(header_buf, 1, 8, fh->fp);
    fh->num_bytes += nr;
    if (ferror(fh->fp)) {
        shp_error(fh, "Cannot read record header");
        goto cleanup;
    }
    if (feof(fh->fp)) {
        /* Reached end of file. */
        rc = 0;
        goto cleanup;
    }
    if (nr != 8) {
        shp_error(fh, "Expected record header of %zu bytes, got %zu",
                  (size_t) 8, nr);
        errno = EINVAL;
        goto cleanup;
    }

    record_number = shp_be32_to_int32(&header_buf[0]);
    content_length = shp_be32_to_int32(&header_buf[4]);
    if (content_length < 2) {
        shp_error(fh, "Content length %ld is invalid", (long) content_length);
        errno = EINVAL;
        goto cleanup;
    }

    record_size = 2 * content_length;

    record = *precord;
    buf_size = sizeof(*record) + record_size;
    if (record == NULL || *psize < buf_size) {
        record = (shp_record_t *) realloc(record, buf_size);
        if (record == NULL) {
            shp_error(fh, "Cannot allocate %zu bytes", buf_size);
            goto cleanup;
        }
        *precord = record;
        *psize = buf_size;
    }

    buf = ((char *) record) + sizeof(*record);

    nr = fread(buf, 1, record_size, fh->fp);
    fh->num_bytes += nr;
    if (ferror(fh->fp)) {
        shp_error(fh, "Cannot read record");
        goto cleanup;
    }
    if (nr != record_size) {
        shp_error(fh, "Expected record of %zu bytes, got %zu", record_size,
                  nr);
        errno = EINVAL;
        goto cleanup;
    }

    record->record_number = record_number;
    record->content_length = content_length;
    record->shape_type = (shp_shpt_t) shp_le32_to_int32(&buf[0]);
    switch (record->shape_type) {
    case SHPT_NULL:
        rc = 1;
        break;
    case SHPT_POINT:
        rc = get_point(buf, record);
        break;
    case SHPT_POLYGON:
        rc = get_polygon(buf, record);
        break;
    default:
        shp_error(fh, "Shape type %d is unknown", (int) record->shape_type);
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
    assert(fh->fp != NULL);
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
shp_read(shp_file_t *fh, shp_header_callback_t handle_header,
         shp_record_callback_t handle_record)
{
    int rc = -1, rc2;
    shp_header_t *header = NULL;
    shp_record_t *record = NULL;
    size_t buf_size;
    size_t file_offset;

    assert(fh != NULL);
    assert(fh->fp != NULL);
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

    assert(header != NULL);

    rc2 = (*handle_header)(fh, header);
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
        shp_error(fh, "Cannot allocate %zu bytes", buf_size);
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

        rc2 = (*handle_record)(fh, header, record, file_offset);
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
    free(header);

    return rc;
}
