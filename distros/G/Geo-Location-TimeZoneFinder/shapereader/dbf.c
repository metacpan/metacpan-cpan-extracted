/*
 * Read ESRI shapefiles
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This library is free software; you can redistribute it and/or modify it
 * under either the terms of the ISC License or the same terms as Perl.
 */

/* SPDX-License-Identifier: ISC OR Artistic-1.0-Perl OR GPL-1.0-or-later */

#include "dbf.h"
#include "convert.h"
#include <assert.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

dbf_file_t *
dbf_file(dbf_file_t *fh, FILE *fp, void *user_data)
{
    assert(fh != NULL);
    assert(fp != NULL);

    fh->fp = fp;
    fh->user_data = user_data;
    fh->num_bytes = 0;
    fh->error[0] = '\0';
    fh->_record_size = 0;

    return fh;
}

void
dbf_error(dbf_file_t *fh, const char *format, ...)
{
    va_list ap;

    assert(fh != NULL);
    assert(format != NULL);

    va_start(ap, format);
    vsnprintf(fh->error, sizeof(fh->error), format, ap); /* NOLINT */
    va_end(ap);
}

static size_t
field_size(const dbf_field_t *field)
{
    size_t n;
    if (field->type == DBFT_CHARACTER) {
        n = (field->decimal_places << 8) | field->length;
    }
    else {
        n = field->length;
    }
    return n;
}

static void
get_bytes_readonly(const dbf_record_t *record, const dbf_field_t *field,
                   const char **pbytes, size_t *plen)
{
    *pbytes = record->_bytes + field->_offset;
    *plen = field->_size;
}

static void
get_left_justified_string(const dbf_record_t *record,
                          const dbf_field_t *field, const char **pstr,
                          size_t *plen)
{
    const char *s;
    size_t n;

    get_bytes_readonly(record, field, &s, &n);
    while (n > 0 && s[n - 1] == ' ') {
        --n;
    }
    *pstr = s;
    *plen = n;
}

static void
get_right_justified_string(const dbf_record_t *record,
                           const dbf_field_t *field, const char **pstr,
                           size_t *plen)
{
    const char *s;
    size_t n;

    get_bytes_readonly(record, field, &s, &n);
    while (n > 0 && s[0] == ' ') {
        ++s;
        --n;
    }
    *pstr = s;
    *plen = n;
}

void
dbf_record_bytes(const dbf_record_t *record, const dbf_field_t *field,
                 const char **pbytes, size_t *plen)
{
    assert(record != NULL);
    assert(field != NULL);
    assert(pbytes != NULL);
    assert(plen != NULL);

    get_bytes_readonly(record, field, pbytes, plen);
}

int
dbf_record_date(const dbf_record_t *record, const dbf_field_t *field,
                struct tm *ptm)
{
    const char *s;
    size_t n;

    assert(record != NULL);
    assert(field != NULL);
    assert(ptm != NULL);

    get_bytes_readonly(record, field, &s, &n);
    return shp_yyyymmdd_to_tm(s, n, ptm);
}

int
dbf_record_datetime(const dbf_record_t *record, const dbf_field_t *field,
                    struct tm *ptm)
{
    int ok = 0;
    const char *bytes;
    size_t n;
    int32_t jdn = 0, jt = 0;

    assert(record != NULL);
    assert(field != NULL);
    assert(ptm != NULL);

    get_bytes_readonly(record, field, &bytes, &n);
    if (n == 8) {
        jdn = shp_le32_to_int32(&bytes[0]);
        jt = shp_le32_to_int32(&bytes[4]);
        ok = 1;
    }
    shp_jd_to_tm(jdn, jt, ptm);
    return ok;
}

int
dbf_record_double(const dbf_record_t *record, const dbf_field_t *field,
                  double *pvalue)
{
    int ok = 0;
    const char *bytes;
    size_t n;
    double d = 0.0;

    assert(record != NULL);
    assert(field != NULL);
    assert(pvalue != NULL);

    get_bytes_readonly(record, field, &bytes, &n);
    if (n == 8) {
        d = shp_le64_to_double(bytes);
        ok = 1;
    }
    *pvalue = d;
    return ok;
}

int
dbf_record_int32(const dbf_record_t *record, const dbf_field_t *field,
                 int32_t *pvalue)
{
    int ok = 0;
    const char *bytes;
    size_t n;
    int32_t i = 0;

    assert(record != NULL);
    assert(field != NULL);
    assert(pvalue != NULL);

    get_bytes_readonly(record, field, &bytes, &n);
    if (n == 4) {
        i = shp_le32_to_int32(bytes);
        ok = 1;
    }
    *pvalue = i;
    return ok;
}

int
dbf_record_int64(const dbf_record_t *record, const dbf_field_t *field,
                 int64_t *pvalue)
{
    int ok = 0;
    int64_t i = 0;
    const char *bytes;
    size_t n;

    assert(record != NULL);
    assert(field != NULL);
    assert(pvalue != NULL);

    get_bytes_readonly(record, field, &bytes, &n);
    if (n == 8) {
        i = shp_le64_to_int64(&bytes[0]);
        ok = 1;
    }
    *pvalue = i;
    return ok;
}

int
dbf_record_is_deleted(const dbf_record_t *record)
{
     return (record->_bytes[0] == '*');
}

static int
is_all(const char *s, size_t n, char c)
{
    size_t i;

    for (i = 0; i < n; ++i) {
        if (s[i] != c) {
            return 0;
        }
    }
    return 1;
}

int
dbf_record_is_null(const dbf_record_t *record, const dbf_field_t *field)
{
    int is_null;
    const char *s;
    size_t n;

    assert(record != NULL);
    assert(field != NULL);

    switch (field->type) {
    case DBFT_CHARACTER:
        get_left_justified_string(record, field, &s, &n);
        is_null = (n == 0);
        break;
    case DBFT_DATE:
        get_left_justified_string(record, field, &s, &n);
        is_null = (n == 0 || is_all(s, n, '0'));
        break;
    case DBFT_FLOAT:
    case DBFT_NUMBER:
        get_right_justified_string(record, field, &s, &n);
        is_null = (n == 0 || s[0] == '*');
        break;
    case DBFT_LOGICAL:
        switch (dbf_record_logical(record, field)) {
        case 'F':
        case 'f':
        case 'N':
        case 'n':
        case 'T':
        case 't':
        case 'Y':
        case 'y':
            is_null = 0;
            break;
        default:
            is_null = 1;
            break;
        }
        break;
    default:
        is_null = 0;
        break;
    }

    return is_null;
}

int
dbf_record_logical(const dbf_record_t *record, const dbf_field_t *field)
{
    int c = '\0';
    const char *s;
    size_t n;

    assert(record != NULL);
    assert(field != NULL);

    get_bytes_readonly(record, field, &s, &n);
    if (n == 1) {
        c = s[0];
    }

    return c;
}

int
dbf_record_logical_is_false(const dbf_record_t *record,
                            const dbf_field_t *field)
{
    int no = 0;

    assert(record != NULL);
    assert(field != NULL);

    switch (dbf_record_logical(record, field)) {
    case 'F':
    case 'f':
    case 'N':
    case 'n':
        no = 1;
        break;
    }

    return no;
}

int
dbf_record_logical_is_true(const dbf_record_t *record,
                           const dbf_field_t *field)
{
    int yes = 0;

    assert(record != NULL);
    assert(field != NULL);

    switch (dbf_record_logical(record, field)) {
    case 'T':
    case 't':
    case 'Y':
    case 'y':
        yes = 1;
        break;
    }

    return yes;
}

char *
dbf_record_strdup(const dbf_record_t *record, const dbf_field_t *field)
{
    char *d;
    const char *s;
    size_t n;

    assert(record != NULL);
    assert(field != NULL);

    get_left_justified_string(record, field, &s, &n);
    d = (char *) malloc(n + 1);
    if (d != NULL) {
        memcpy(d, s, n); /* NOLINT */
        d[n] = '\0';
    }

    return d;
}

void
dbf_record_string(const dbf_record_t *record, const dbf_field_t *field,
                  const char **pstr, size_t *plen)
{
    assert(record != NULL);
    assert(field != NULL);
    assert(pstr != NULL);
    assert(plen != NULL);

    get_left_justified_string(record, field, pstr, plen);
}

int
dbf_record_strtod(const dbf_record_t *record, const dbf_field_t *field,
                  double *pvalue)
{
    int ok = 0;
    double d = 0.0;
    const char *s;
    size_t n;
    char buf[256], *end;

    assert(record != NULL);
    assert(field != NULL);
    assert(pvalue != NULL);

    get_right_justified_string(record, field, &s, &n);
    if (n > 0) {
        if (n < sizeof(buf)) {
            memcpy(buf, s, n); /* NOLINT */
            buf[n] = '\0';
            d = strtod(buf, &end);
            ok = (end[0] == '\0');
        }
    }
    *pvalue = d;
    return ok;
}

int
dbf_record_strtol(const dbf_record_t *record, const dbf_field_t *field,
                  int base, long *pvalue)
{
    int ok = 0;
    long l = 0;
    const char *s;
    size_t n;
    char buf[256], *end;

    assert(record != NULL);
    assert(field != NULL);
    assert(pvalue != NULL);

    get_right_justified_string(record, field, &s, &n);
    if (n > 0) {
        if (n < sizeof(buf)) {
            memcpy(buf, s, n); /* NOLINT */
            buf[n] = '\0';
            l = strtol(buf, &end, base);
            ok = (end[0] == '\0');
        }
    }
    *pvalue = l;
    return ok;
}

int
dbf_record_strtold(const dbf_record_t *record, const dbf_field_t *field,
                   long double *pvalue)
{
    int ok = 0;
    long double d = 0.0;
    const char *s;
    size_t n;
    char buf[256], *end;

    assert(record != NULL);
    assert(field != NULL);
    assert(pvalue != NULL);

    get_right_justified_string(record, field, &s, &n);
    if (n > 0) {
        if (n < sizeof(buf)) {
            memcpy(buf, s, n); /* NOLINT */
            buf[n] = '\0';
            d = strtold(buf, &end);
            ok = (end[0] == '\0');
        }
    }
    *pvalue = d;
    return ok;
}

int
dbf_record_strtoll(const dbf_record_t *record, const dbf_field_t *field,
                   int base, long long *pvalue)
{
    int ok = 0;
    long long l = 0;
    const char *s;
    size_t n;
    char buf[256], *end;

    assert(record != NULL);
    assert(field != NULL);
    assert(pvalue != NULL);

    get_right_justified_string(record, field, &s, &n);
    if (n > 0) {
        if (n < sizeof(buf)) {
            memcpy(buf, s, n); /* NOLINT */
            buf[n] = '\0';
            l = strtoll(buf, &end, base);
            ok = (end[0] == '\0');
        }
    }
    *pvalue = l;
    return ok;
}

int
dbf_record_strtoul(const dbf_record_t *record, const dbf_field_t *field,
                   int base, unsigned long *pvalue)
{
    int ok = 0;
    unsigned long l = 0;
    const char *s;
    size_t n;
    char buf[256], *end;

    assert(record != NULL);
    assert(field != NULL);
    assert(pvalue != NULL);

    get_right_justified_string(record, field, &s, &n);
    if (n > 0) {
        if (n < sizeof(buf)) {
            memcpy(buf, s, n); /* NOLINT */
            buf[n] = '\0';
            l = strtoul(buf, &end, base);
            ok = (end[0] == '\0');
        }
    }
    *pvalue = l;
    return ok;
}

int
dbf_record_strtoull(const dbf_record_t *record, const dbf_field_t *field,
                    int base, unsigned long long *pvalue)
{
    int ok = 0;
    unsigned long long l = 0;
    const char *s;
    size_t n;
    char buf[256], *end;

    assert(record != NULL);
    assert(field != NULL);
    assert(pvalue != NULL);

    get_right_justified_string(record, field, &s, &n);
    if (n > 0) {
        if (n < sizeof(buf)) {
            memcpy(buf, s, n); /* NOLINT */
            buf[n] = '\0';
            l = strtoull(buf, &end, base);
            ok = (end[0] == '\0');
        }
    }
    *pvalue = l;
    return ok;
}

static dbf_version_t
database_type(dbf_version_t version)
{
    dbf_version_t type = 0;

    switch (version) {
    case DBFV_DBASE2:
        type = DBFV_DBASE2;
        break;
    case DBFV_DBASE3:
    case DBFV_DBASE3_MEMO:
    case DBFV_DBASE4:
    case DBFV_DBASE4_MEMO:
    case DBFV_DBASE5:
    case DBFV_FOXPRO_MEMO:
    case DBFV_VISUAL_FOXPRO:
    case DBFV_VISUAL_FOXPRO_AUTO:
    case DBFV_VISUAL_FOXPRO_VARIFIELD:
    case DBFV_VISUAL_OBJECTS:
    case DBFV_VISUAL_OBJECTS_MEMO:
        type = DBFV_DBASE3;
        break;
    case DBFV_DBASE7:
        type = DBFV_DBASE7;
        break;
    }
    return type;
}

static void
get_field_dbase2(const char *buf, size_t *poffset, dbf_field_t *field)
{
    int i;

    field->next = NULL;
    memcpy(field->name, buf, 11); /* NOLINT */
    field->name[11] = '\0';
    field->type = (dbf_type_t) buf[11];
    field->length = (unsigned char) buf[12];
    field->decimal_places = (unsigned char) buf[15];
    for (i = 0; i < 14; ++i) {
        field->reserved[i] = 0;
    }

    field->_size = field_size(field);
    field->_offset = *poffset;
    *poffset += field->_size;
}

static void
get_field_dbase3(const char *buf, size_t *poffset, dbf_field_t *field)
{
    int i;

    field->next = NULL;
    memcpy(field->name, buf, 11); /* NOLINT */
    field->name[11] = '\0';
    field->type = (dbf_type_t) buf[11];
    field->length = (unsigned char) buf[16];
    field->decimal_places = (unsigned char) buf[17];
    for (i = 0; i < 14; ++i) {
        field->reserved[i] = (unsigned char) buf[18 + i];
    }

    field->_size = field_size(field);
    field->_offset = *poffset;
    *poffset += field->_size;
}

static int
read_header_dbase2(dbf_file_t *fh, dbf_version_t version,
                   dbf_header_t **pheader)
{
    int rc = -1;
    char buf[521], *descriptors;
    size_t nr;
    size_t header_size, num_records, record_size, offset;
    size_t result_size, n;
    int year, month, day;
    int num_fields, i;
    dbf_field_t *fields, *field, **field_next;
    dbf_header_t *header = NULL;

    header_size = 521;
    nr = fread(&buf[1], 1, header_size - 1, fh->fp);
    fh->num_bytes += nr;
    if (ferror(fh->fp)) {
        dbf_error(fh, "Cannot read file header");
        goto cleanup;
    }
    if (nr != header_size - 1) {
        dbf_error(fh, "Expected file header of %zu bytes, got %zu",
                  header_size, nr + 1);
        errno = EINVAL;
        goto cleanup;
    }

    num_records = shp_le16_to_uint16(&buf[1]);
    month = (unsigned char) buf[3];
    day = (unsigned char) buf[4];
    year = (unsigned char) buf[5];
    record_size = shp_le16_to_uint16(&buf[6]);
    descriptors = &buf[8];

    if (record_size < 1) {
        dbf_error(fh, "Record size %zu is invalid", record_size);
        errno = EINVAL;
        goto cleanup;
    }

    num_fields = 0;
    n = 0;
    while (num_fields < 32 && descriptors[n] != '\r') {
        ++num_fields;
        n += 16;
    }

    result_size = sizeof(*header) + num_fields * sizeof(dbf_field_t);
    header = (dbf_header_t *) calloc(1, result_size);
    if (header == NULL) {
        dbf_error(fh, "Cannot allocate %zu bytes", result_size);
        goto cleanup;
    }

    fields = (dbf_field_t *) (((char *) header) + sizeof(*header));

    header->version = version;
    header->year = year;
    header->month = month;
    header->day = day;
    header->num_records = num_records;
    header->header_size = header_size;
    header->record_size = record_size;
    header->num_fields = num_fields;
    header->fields = NULL;

    field_next = &header->fields;
    offset = 1;
    i = 0;
    n = 0;
    while (i < num_fields) {
        field = &fields[i];
        get_field_dbase2(&descriptors[n], &offset, field);
        *field_next = field;
        field_next = &field->next;
        ++i;
        n += 16;
    }

    if (offset != record_size) {
        dbf_error(fh, "Sum %zu of field lengths differs from record size %zu",
                  offset, record_size);
        free(header);
        header = NULL;
        goto cleanup;
    }

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

static int
read_header_dbase3(dbf_file_t *fh, dbf_version_t version,
                   dbf_header_t **pheader)
{
    int rc = -1;
    char buf[32], *descriptors = NULL;
    size_t nr;
    size_t header_size, num_records, record_size, offset;
    size_t descriptors_size, result_size, n;
    int year, month, day;
    int num_fields, i;
    dbf_field_t *fields, *field, **field_next;
    dbf_header_t *header = NULL;

    nr = fread(&buf[1], 1, 31, fh->fp);
    fh->num_bytes += nr;
    if (ferror(fh->fp)) {
        dbf_error(fh, "Cannot read file header");
        goto cleanup;
    }
    if (nr != 31) {
        dbf_error(fh, "Expected file header of %zu bytes, got %zu",
                  (size_t) 32, nr + 1);
        errno = EINVAL;
        goto cleanup;
    }

    year = (unsigned char) buf[1];
    month = (unsigned char) buf[2];
    day = (unsigned char) buf[3];
    num_records = shp_le32_to_uint32(&buf[4]);
    header_size = shp_le16_to_uint16(&buf[8]);
    record_size = shp_le16_to_uint16(&buf[10]);

    if (header_size < 32) {
        dbf_error(fh, "Header size %zu is invalid", header_size);
        errno = EINVAL;
        goto cleanup;
    }

    if (record_size < 1) {
        dbf_error(fh, "Record size %zu is invalid", record_size);
        errno = EINVAL;
        goto cleanup;
    }

    descriptors_size = header_size - 32;
    if (descriptors_size == 0) {
        dbf_error(fh, "No field descriptors");
        errno = EINVAL;
        goto cleanup;
    }

    descriptors = (char *) malloc(descriptors_size);
    if (descriptors == NULL) {
        dbf_error(fh, "Cannot allocate %zu bytes", descriptors_size);
        goto cleanup;
    }

    nr = fread(descriptors, 1, descriptors_size, fh->fp);
    fh->num_bytes += nr;
    if (ferror(fh->fp)) {
        dbf_error(fh, "Cannot read field descriptors");
        goto cleanup;
    }
    if (nr != descriptors_size) {
        dbf_error(fh, "Expected field descriptors of %zu bytes, got %zu",
                  descriptors_size, nr);
        errno = EINVAL;
        goto cleanup;
    }

    fh->_record_size = record_size;

    num_fields = 0;
    n = 0;
    while (n < descriptors_size && descriptors[n] != '\r') {
        ++num_fields;
        n += 32;
    }

    if (num_fields > 2046) {
        dbf_error(fh, "Expected at most %d fields, got %d", 2046, num_fields);
        errno = EINVAL;
        goto cleanup;
    }

    result_size = sizeof(*header) + num_fields * sizeof(dbf_field_t);
    header = (dbf_header_t *) calloc(1, result_size);
    if (header == NULL) {
        dbf_error(fh, "Cannot allocate %zu bytes", result_size);
        goto cleanup;
    }

    fields = (dbf_field_t *) (((char *) header) + sizeof(*header));

    header->version = version;
    header->year = year;
    header->month = month;
    header->day = day;
    header->num_records = num_records;
    header->header_size = header_size;
    header->record_size = record_size;
    for (i = 0; i < 20; ++i) {
        header->reserved[i] = (unsigned char) buf[12 + i];
    }
    header->num_fields = num_fields;
    header->fields = NULL;

    field_next = &header->fields;
    offset = 1;
    i = 0;
    n = 0;
    while (i < num_fields) {
        field = &fields[i];
        get_field_dbase3(&descriptors[n], &offset, field);
        *field_next = field;
        field_next = &field->next;
        ++i;
        n += 32;
    }

    if (offset != record_size) {
        dbf_error(fh, "Sum %zu of field lengths differs from record size %zu",
                  offset, record_size);
        free(header);
        header = NULL;
        goto cleanup;
    }

    if (feof(fh->fp)) {
        free(header);
        header = NULL;
        rc = 0;
        goto cleanup;
    }

    rc = 1;

cleanup:

    free(descriptors);

    *pheader = header;

    return rc;
}

int
dbf_read_header(dbf_file_t *fh, dbf_header_t **pheader)
{
    int rc = -1;
    unsigned char bytes[1];
    size_t nr;
    dbf_version_t version;

    assert(fh != NULL);
    assert(fh->fp != NULL);
    assert(pheader != NULL);

    nr = fread(bytes, 1, 1, fh->fp);
    fh->num_bytes += nr;
    if (ferror(fh->fp)) {
        dbf_error(fh, "Cannot read file version");
        goto cleanup;
    }
    if (nr != 1) {
        dbf_error(fh, "Expected 1 byte, got %zu", nr);
        errno = EINVAL;
        goto cleanup;
    }

    version = (dbf_version_t) bytes[0];
    switch (database_type(version)) {
    case DBFV_DBASE2:
        rc = read_header_dbase2(fh, version, pheader);
        break;
    case DBFV_DBASE3:
        rc = read_header_dbase3(fh, version, pheader);
        break;
    default:
        dbf_error(fh, "Database version %d is not supported", version);
        errno = EINVAL;
        goto cleanup;
    }

cleanup:

    return rc;
}

int
dbf_read_record(dbf_file_t *fh, dbf_record_t **precord)
{
    int rc = -1;
    dbf_record_t *record;
    char *buf;
    size_t record_size, result_size;
    size_t nr;

    assert(fh != NULL);
    assert(fh->fp != NULL);
    assert(fh->_record_size > 0);
    assert(precord != NULL);

    record_size = fh->_record_size;

    result_size = sizeof(*record) + record_size;
    record = (dbf_record_t *) malloc(result_size);
    if (record == NULL) {
        dbf_error(fh, "Cannot allocate %zu bytes", result_size);
        goto cleanup;
    }

    buf = ((char *) record) + sizeof(*record);
    record->_bytes = buf;
    if ((nr = fread(buf, 1, record_size, fh->fp)) > 0) {
        fh->num_bytes += nr;

        if (buf[0] == '\x1a') {
            /* Reached end-of-file marker. */
            free(record);
            record = NULL;
            rc = 0;
            goto cleanup;
        }

        if (nr != record_size) {
            dbf_error(fh, "Expected record of %zu bytes, got %zu",
                      record_size, nr);
            free(record);
            record = NULL;
            goto cleanup;
        }
    }

    if (ferror(fh->fp)) {
        dbf_error(fh, "Cannot read record");
        free(record);
        record = NULL;
        goto cleanup;
    }

    if (feof(fh->fp)) {
        free(record);
        record = NULL;
        rc = 0;
        goto cleanup;
    }

    rc = 1;

cleanup:

    *precord = record;

    return rc;
}

int
dbf_read(dbf_file_t *fh, dbf_header_callback_t handle_header,
         dbf_record_callback_t handle_record)
{
    int rc = -1, rc2;
    dbf_header_t *header = NULL;
    dbf_record_t *record = NULL;
    char *buf;
    size_t record_size, result_size;
    size_t num_records, record_num;
    size_t file_offset;
    size_t nr;

    assert(fh != NULL);
    assert(fh->fp != NULL);
    assert(handle_header != NULL);
    assert(handle_record != NULL);

    if (dbf_read_header(fh, &header) <= 0) {
        goto cleanup;
    }

    assert(header != NULL);
    assert(header->record_size > 0);

    num_records = header->num_records;
    record_size = header->record_size;

    result_size = sizeof(*record) + record_size;
    record = (dbf_record_t *) malloc(result_size);
    if (record == NULL) {
        dbf_error(fh, "Cannot allocate %zu bytes", result_size);
        goto cleanup;
    }

    rc2 = (*handle_header)(fh, header);
    if (rc2 == 0) {
        /* Stop processing. */
        rc = 0;
    }
    if (rc2 <= 0) {
        goto cleanup;
    }

    record_num = 0;

    buf = ((char *) record) + sizeof(*record);
    record->_bytes = buf;
    while ((nr = fread(buf, 1, record_size, fh->fp)) > 0) {
        file_offset = fh->num_bytes;
        fh->num_bytes += nr;

        if (buf[0] == '\x1a') {
            /* Reached end-of-file marker. */
            rc = 0;
            goto cleanup;
        }

        if (nr != record_size) {
            dbf_error(fh,
                      "Expected record of %zu bytes at index %zu and "
                      "file position %zu, got %zu",
                      record_size, record_num, file_offset, nr);
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

        ++record_num;
    }

    if (ferror(fh->fp)) {
        dbf_error(fh, "Cannot read record");
        goto cleanup;
    }

    if (record_num < num_records) {
        dbf_error(fh, "Expected %zu records, got %zu", num_records,
                  record_num);
        errno = EINVAL;
        goto cleanup;
    }

    if (feof(fh->fp)) {
        rc = 0;
        goto cleanup;
    }

    rc = 1;

cleanup:

    free(record);
    free(header);

    return rc;
}
