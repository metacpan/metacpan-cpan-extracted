/*
 * Read ESRI shapefiles
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This library is free software; you can redistribute it and/or modify it
 * under either the terms of the ISC License or the same terms as Perl.
 */

/* SPDX-License-Identifier: ISC OR Artistic-1.0-Perl OR GPL-1.0-or-later */

#include "shx.h"
#include "byteorder.h"
#include <assert.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>

shx_file_t *
shx_init_file(shx_file_t *fh, FILE *stream, void *user_data)
{
    return shp_init_file(fh, stream, user_data);
}

void
shx_set_error(shx_file_t *fh, const char *format, ...)
{
    va_list ap;

    assert(fh != NULL);
    assert(format != NULL);

    va_start(ap, format);
    vsnprintf(fh->error, sizeof(fh->error), format, ap); /* NOLINT */
    va_end(ap);
}

int
shx_read_header(shx_file_t *fh, shx_header_t *header)
{
    return shp_read_header(fh, header);
}

static int
read_record(shx_file_t *fh, shx_record_t *record)
{
    int rc = -1;
    char buf[8];
    size_t nr;
    size_t offset = 0, content_length = 0;

    nr = (*fh->fread)(fh, buf, 8);
    if ((*fh->ferror)(fh)) {
        shx_set_error(fh, "Cannot read index record");
        goto cleanup;
    }
    if ((*fh->feof)(fh)) {
        /* Reached end of file. */
        rc = 0;
        goto cleanup;
    }
    if (nr != 8) {
        shx_set_error(fh, "Expected index record of %zu bytes, got %zu",
                      (size_t) 8, nr);
        errno = EINVAL;
        goto cleanup;
    }

    offset = shp_be32_to_uint32(&buf[0]);
    content_length = shp_be32_to_uint32(&buf[4]);

    if (offset < 50) {
        shx_set_error(fh, "Offset %zu is invalid", offset);
        errno = EINVAL;
        goto cleanup;
    }

    if (content_length < 2) {
        shx_set_error(fh, "Content length %zu is invalid", content_length);
        errno = EINVAL;
        goto cleanup;
    }

    rc = 1;

cleanup:

    record->file_offset = 2 * offset;
    record->record_size = 2 * content_length;

    return rc;
}

int
shx_read_record(shx_file_t *fh, shx_record_t *record)
{
    int rc = -1;

    assert(fh != NULL);
    assert(record != NULL);

    rc = read_record(fh, record);

    return rc;
}

int
shx_seek_record(shx_file_t *fh, size_t record_number, shx_record_t *record)
{
    int rc = -1;
    size_t file_offset;

    assert(fh != NULL);
    assert(record != NULL);

    /* The largest possible record number is (8GB - 100) / 12. */
    if (record_number > 715827874UL) {
        shx_set_error(fh, "Record number %zu is too big\n", record_number);
        errno = EINVAL;
        goto cleanup;
    }

    file_offset = record_number * 8 + 100;
    if ((*fh->fsetpos)(fh, file_offset) != 0) {
        shx_set_error(fh, "Cannot set file position to record number %zu\n",
                      record_number);
        goto cleanup;
    }

    rc = read_record(fh, record);

cleanup:

    return rc;
}

int
shx_read(shx_file_t *fh, shx_header_callback_t handle_header,
         shx_record_callback_t handle_record)
{
    int rc = -1, rc2;
    shx_header_t header;
    shx_record_t record;

    assert(fh != NULL);
    assert(handle_header != NULL);
    assert(handle_record != NULL);

    rc2 = shx_read_header(fh, &header);
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

    for (;;) {
        rc2 = read_record(fh, &record);
        if (rc2 == 0) {
            /* Reached end of file. */
            rc = 0;
        }
        if (rc2 <= 0) {
            goto cleanup;
        }

        rc2 = (*handle_record)(fh, &header, &record);
        if (rc2 == 0) {
            /* Stop processing. */
            rc = 0;
        }
        if (rc2 <= 0) {
            goto cleanup;
        }
    }

cleanup:

    return rc;
}
