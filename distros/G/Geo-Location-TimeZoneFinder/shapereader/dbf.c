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
#include "byteorder.h"
#include <assert.h>
#include <errno.h>
#include <limits.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SIZEOF16(x) (((sizeof(x) + 15) >> 4) << 4)

static size_t
file_fread(dbf_file_t *fh, void *buf, size_t count)
{
    size_t nr = fread(buf, 1, count, (FILE *) fh->stream);
    fh->num_bytes += nr;
    return nr;
}

static int
file_feof(dbf_file_t *fh)
{
    return feof((FILE *) fh->stream);
}

static int
file_ferror(dbf_file_t *fh)
{
    return ferror((FILE *) fh->stream);
}

static int
file_fsetpos(dbf_file_t *fh, size_t offset)
{
    if (offset > LONG_MAX) {
        errno = EINVAL;
        return -1;
    }
    return fseek((FILE *) fh->stream, (long) offset, SEEK_SET);
}

dbf_file_t *
dbf_init_file(dbf_file_t *fh, FILE *stream, void *user_data)
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
    fh->header_size = 0;
    fh->record_size = 0;

    return fh;
}

void
dbf_set_error(dbf_file_t *fh, const char *format, ...)
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
    if (field->type == DBF_TYPE_CHARACTER) {
        n = (field->decimal_places << 8) | field->length;
    }
    else {
        n = field->length;
    }
    return n;
}

static void
get_bytes_readonly(const dbf_record_t *record, const dbf_field_t *field,
                   const char **pbytes, size_t *len)
{
    *pbytes = record->bytes + field->offset;
    *len = field->size;
}

static void
get_left_justified_string(const dbf_record_t *record,
                          const dbf_field_t *field, const char **pstr,
                          size_t *len)
{
    const char *s;
    size_t n;

    get_bytes_readonly(record, field, &s, &n);
    while (n > 0 && s[n - 1] == ' ') {
        --n;
    }
    *pstr = s;
    *len = n;
}

static void
get_right_justified_string(const dbf_record_t *record,
                           const dbf_field_t *field, const char **pstr,
                           size_t *len)
{
    const char *s;
    size_t n;

    get_bytes_readonly(record, field, &s, &n);
    while (n > 0 && s[0] == ' ') {
        ++s;
        --n;
    }
    *pstr = s;
    *len = n;
}

static int
is_leap_year(int year)
{
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
}

static int
days_in_month(int month, int year)
{
    int i;
    const int days_in_month[2][12] = {
        {31, 28, 31, 30, 31, 30, 30, 31, 30, 31, 30, 31},
        {31, 29, 31, 30, 31, 30, 30, 31, 30, 31, 30, 31},
    };

    assert(month >= 1);
    assert(month <= 12);

    i = is_leap_year(year) ? 1 : 0;
    return days_in_month[i][month - 1];
}

static int
day_of_week(int day, int month, int year)
{
    static const int t[12] = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4};

    assert(month >= 1);
    assert(month <= 12);

    if (month < 3) {
        year -= 1;
    }
    return (year + year / 4 - year / 100 + year / 400 + t[month - 1] + day) %
           7;
}

static int
day_of_year(int day, int month, int year)
{
    int i;
    const int days_for_month[2][12] = {
        {0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334},
        {0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335},
    };

    assert(month >= 1);
    assert(month <= 12);

    i = is_leap_year(year) ? 1 : 0;
    return days_for_month[i][month - 1] + day;
}

void
dbf_jd_to_tm(int32_t jd, int32_t jt, struct tm *tm)
{
    int sec, min, hour, day, month, year;
    int64_t a, b, c, d, e, alpha;
    double s, m, h;
    const double month_days_without_jan_feb = (365 - 31 - 28) / 10.0;

    assert(tm != NULL);

    a = jd;
    if (jd >= 2299161) {
        alpha = (int64_t) ((jd - 1867216.25) / 36524.25);
        a = a + 1 + alpha - (alpha >> 2);
    }
    b = a + 1524;
    c = (int64_t) ((b - 122.1) / 365.25);
    d = (int64_t) (c * 365.25);
    e = (int64_t) ((b - d) / month_days_without_jan_feb);
    day = (int) (b - d - (int64_t) (e * month_days_without_jan_feb));
    if (e > 13) {
        month = (int) (e - 13);
    }
    else {
        month = (int) (e - 1);
    }
    if (month == 2 && day > 28) {
        day = 29;
    }
    if (month == 2 && day == 29 && e == 3) {
        year = (int) (c - 4716);
    }
    else if (month > 2) {
        year = (int) (c - 4716);
    }
    else {
        year = (int) (c - 4715);
    }

    s = jt / 1000.0;
    m = s / 60.0;
    h = m / 60.0;
    hour = (int) h;
    min = (int) ((h - hour) * 60.0);
    sec = (int) ((m - min) * 60.0 - hour * 3600.0);

    memset(tm, 0, sizeof(*tm)); /* NOLINT */
    tm->tm_sec = sec;
    tm->tm_min = min;
    tm->tm_hour = hour;
    tm->tm_mday = day;
    tm->tm_mon = month - 1;
    tm->tm_year = year - 1900;
    tm->tm_wday = (int) ((jd + 1) % 7);
    tm->tm_yday = day_of_year(day, month, year) - 1;
    tm->tm_isdst = -1;
}

int
dbf_yyyymmdd_to_tm(const char *ymd, size_t n, struct tm *tm)
{
    int ok = 0;
    int day = 0, month = 0, year = 0, wday = 0, yday = 0;
    size_t a, i, k, z;
    int c;

    assert(ymd != NULL);
    assert(tm != NULL);

    k = 0;
    z = 1;
    i = n;
    while (i > 0 && (c = ymd[i - 1]) >= '0' && c <= '9') {
        a = c - '0';
        switch (k) {
        case 0:
            day = a;
            break;
        case 1:
            day += 10 * a;
            break;
        case 2:
            month = a;
            break;
        case 3:
            month += 10 * a;
            break;
        default:
            year += z * a;
            z *= 10;
            break;
        }
        ++k;
        --i;
    }

    if (i == 0 && k >= 8) {
        if (month >= 1 && month <= 12) {
            if (day >= 1 && day <= days_in_month(month, year)) {
                wday = day_of_week(day, month, year);
                yday = day_of_year(day, month, year);
                ok = 1;
            }
        }
    }

    memset(tm, 0, sizeof(*tm)); /* NOLINT */
    if (ok) {
        tm->tm_mday = day;
        tm->tm_mon = month - 1;
        tm->tm_year = year - 1900;
        tm->tm_wday = wday;
        tm->tm_yday = yday - 1;
    }
    tm->tm_isdst = -1;

    return ok;
}

void
dbf_record_bytes(const dbf_record_t *record, const dbf_field_t *field,
                 const char **pbytes, size_t *len)
{
    assert(record != NULL);
    assert(field != NULL);
    assert(pbytes != NULL);
    assert(len != NULL);

    get_bytes_readonly(record, field, pbytes, len);
}

int
dbf_record_date(const dbf_record_t *record, const dbf_field_t *field,
                struct tm *tm)
{
    const char *s;
    size_t n;

    assert(record != NULL);
    assert(field != NULL);
    assert(tm != NULL);

    get_bytes_readonly(record, field, &s, &n);
    return dbf_yyyymmdd_to_tm(s, n, tm);
}

int
dbf_record_datetime(const dbf_record_t *record, const dbf_field_t *field,
                    struct tm *tm)
{
    int ok = 0;
    const char *bytes;
    size_t n;
    int32_t jdn = 0, jt = 0;

    assert(record != NULL);
    assert(field != NULL);
    assert(tm != NULL);

    get_bytes_readonly(record, field, &bytes, &n);
    if (n == 8) {
        jdn = shp_le32_to_int32(&bytes[0]);
        jt = shp_le32_to_int32(&bytes[4]);
        ok = 1;
    }
    dbf_jd_to_tm(jdn, jt, tm);
    return ok;
}

int
dbf_record_double(const dbf_record_t *record, const dbf_field_t *field,
                  double *value)
{
    int ok = 0;
    const char *bytes;
    size_t n;
    double d = 0.0;

    assert(record != NULL);
    assert(field != NULL);
    assert(value != NULL);

    get_bytes_readonly(record, field, &bytes, &n);
    if (n == 8) {
        d = shp_le64_to_double(bytes);
        ok = 1;
    }
    *value = d;
    return ok;
}

int
dbf_record_int32(const dbf_record_t *record, const dbf_field_t *field,
                 int32_t *value)
{
    int ok = 0;
    const char *bytes;
    size_t n;
    int32_t i = 0;

    assert(record != NULL);
    assert(field != NULL);
    assert(value != NULL);

    get_bytes_readonly(record, field, &bytes, &n);
    if (n == 4) {
        i = shp_le32_to_int32(bytes);
        ok = 1;
    }
    *value = i;
    return ok;
}

int
dbf_record_int64(const dbf_record_t *record, const dbf_field_t *field,
                 int64_t *value)
{
    int ok = 0;
    int64_t i = 0;
    const char *bytes;
    size_t n;

    assert(record != NULL);
    assert(field != NULL);
    assert(value != NULL);

    get_bytes_readonly(record, field, &bytes, &n);
    if (n == 8) {
        i = shp_le64_to_int64(&bytes[0]);
        ok = 1;
    }
    *value = i;
    return ok;
}

int
dbf_record_is_deleted(const dbf_record_t *record)
{
    return (record->bytes[0] == '*');
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
    case DBF_TYPE_CHARACTER:
        get_left_justified_string(record, field, &s, &n);
        is_null = (n == 0);
        break;
    case DBF_TYPE_DATE:
        get_left_justified_string(record, field, &s, &n);
        is_null = (n == 0 || is_all(s, n, '0'));
        break;
    case DBF_TYPE_FLOAT:
    case DBF_TYPE_NUMBER:
        get_right_justified_string(record, field, &s, &n);
        is_null = (n == 0 || s[0] == '*');
        break;
    case DBF_TYPE_LOGICAL:
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
                  const char **pstr, size_t *len)
{
    assert(record != NULL);
    assert(field != NULL);
    assert(pstr != NULL);
    assert(len != NULL);

    get_left_justified_string(record, field, pstr, len);
}

int
dbf_record_strtod(const dbf_record_t *record, const dbf_field_t *field,
                  double *value)
{
    int ok = 0;
    double d = 0.0;
    const char *s;
    size_t n;
    char buf[256], *end;

    assert(record != NULL);
    assert(field != NULL);
    assert(value != NULL);

    get_right_justified_string(record, field, &s, &n);
    if (n > 0) {
        if (n < sizeof(buf)) {
            memcpy(buf, s, n); /* NOLINT */
            buf[n] = '\0';
            d = strtod(buf, &end);
            ok = (end[0] == '\0');
        }
    }
    *value = d;
    return ok;
}

int
dbf_record_strtol(const dbf_record_t *record, const dbf_field_t *field,
                  int base, long *value)
{
    int ok = 0;
    long l = 0;
    const char *s;
    size_t n;
    char buf[256], *end;

    assert(record != NULL);
    assert(field != NULL);
    assert(value != NULL);

    get_right_justified_string(record, field, &s, &n);
    if (n > 0) {
        if (n < sizeof(buf)) {
            memcpy(buf, s, n); /* NOLINT */
            buf[n] = '\0';
            l = strtol(buf, &end, base);
            ok = (end[0] == '\0');
        }
    }
    *value = l;
    return ok;
}

int
dbf_record_strtold(const dbf_record_t *record, const dbf_field_t *field,
                   long double *value)
{
    int ok = 0;
    long double d = 0.0;
    const char *s;
    size_t n;
    char buf[256], *end;

    assert(record != NULL);
    assert(field != NULL);
    assert(value != NULL);

    get_right_justified_string(record, field, &s, &n);
    if (n > 0) {
        if (n < sizeof(buf)) {
            memcpy(buf, s, n); /* NOLINT */
            buf[n] = '\0';
            d = strtold(buf, &end);
            ok = (end[0] == '\0');
        }
    }
    *value = d;
    return ok;
}

int
dbf_record_strtoll(const dbf_record_t *record, const dbf_field_t *field,
                   int base, long long *value)
{
    int ok = 0;
    long long l = 0;
    const char *s;
    size_t n;
    char buf[256], *end;

    assert(record != NULL);
    assert(field != NULL);
    assert(value != NULL);

    get_right_justified_string(record, field, &s, &n);
    if (n > 0) {
        if (n < sizeof(buf)) {
            memcpy(buf, s, n); /* NOLINT */
            buf[n] = '\0';
            l = strtoll(buf, &end, base);
            ok = (end[0] == '\0');
        }
    }
    *value = l;
    return ok;
}

int
dbf_record_strtoul(const dbf_record_t *record, const dbf_field_t *field,
                   int base, unsigned long *value)
{
    int ok = 0;
    unsigned long l = 0;
    const char *s;
    size_t n;
    char buf[256], *end;

    assert(record != NULL);
    assert(field != NULL);
    assert(value != NULL);

    get_right_justified_string(record, field, &s, &n);
    if (n > 0) {
        if (n < sizeof(buf)) {
            memcpy(buf, s, n); /* NOLINT */
            buf[n] = '\0';
            l = strtoul(buf, &end, base);
            ok = (end[0] == '\0');
        }
    }
    *value = l;
    return ok;
}

int
dbf_record_strtoull(const dbf_record_t *record, const dbf_field_t *field,
                    int base, unsigned long long *value)
{
    int ok = 0;
    unsigned long long l = 0;
    const char *s;
    size_t n;
    char buf[256], *end;

    assert(record != NULL);
    assert(field != NULL);
    assert(value != NULL);

    get_right_justified_string(record, field, &s, &n);
    if (n > 0) {
        if (n < sizeof(buf)) {
            memcpy(buf, s, n); /* NOLINT */
            buf[n] = '\0';
            l = strtoull(buf, &end, base);
            ok = (end[0] == '\0');
        }
    }
    *value = l;
    return ok;
}

static dbf_version_t
database_type(dbf_version_t version)
{
    dbf_version_t type;

    switch (version) {
    case DBF_VERSION_DBASE2:
        type = DBF_VERSION_DBASE2;
        break;
    case DBF_VERSION_DBASE3:
    case DBF_VERSION_DBASE3_MEMO:
    case DBF_VERSION_DBASE4:
    case DBF_VERSION_DBASE4_MEMO:
    case DBF_VERSION_DBASE5:
    case DBF_VERSION_FOXPRO_MEMO:
    case DBF_VERSION_VISUAL_FOXPRO:
    case DBF_VERSION_VISUAL_FOXPRO_AUTO:
    case DBF_VERSION_VISUAL_FOXPRO_VARIFIELD:
    case DBF_VERSION_VISUAL_OBJECTS:
    case DBF_VERSION_VISUAL_OBJECTS_MEMO:
        type = DBF_VERSION_DBASE3;
        break;
    case DBF_VERSION_DBASE7:
        type = DBF_VERSION_DBASE7;
        break;
    default:
        type = DBF_VERSION_UNKNOWN;
        break;
    }
    return type;
}

static void
get_field_dbase2(const char *buf, size_t *offset, dbf_field_t *field)
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

    field->size = field_size(field);
    field->offset = *offset;
    *offset += field->size;
}

static void
get_field_dbase3(const char *buf, size_t *offset, dbf_field_t *field)
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

    field->size = field_size(field);
    field->offset = *offset;
    *offset += field->size;
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
    nr = (*fh->fread)(fh, &buf[1], header_size - 1);
    if ((*fh->ferror)(fh)) {
        dbf_set_error(fh, "Cannot read file header");
        goto cleanup;
    }
    if (nr != header_size - 1) {
        dbf_set_error(fh, "Expected file header of %zu bytes, got %zu",
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
        dbf_set_error(fh, "Record size %zu is invalid", record_size);
        errno = EINVAL;
        goto cleanup;
    }

    num_fields = 0;
    n = 0;
    while (num_fields < 32 && descriptors[n] != '\r') {
        ++num_fields;
        n += 16;
    }

    result_size = SIZEOF16(*header) + num_fields * sizeof(dbf_field_t);
    header = (dbf_header_t *) calloc(1, result_size);
    if (header == NULL) {
        dbf_set_error(fh, "Cannot allocate %zu bytes", result_size);
        goto cleanup;
    }

    fields = (dbf_field_t *) (void *) (((char *) header) + SIZEOF16(*header));

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
        dbf_set_error(fh,
                      "Sum %zu of field lengths differs from record size %zu",
                      offset, record_size);
        free(header);
        header = NULL;
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

    nr = (*fh->fread)(fh, &buf[1], 31);
    if ((*fh->ferror)(fh)) {
        dbf_set_error(fh, "Cannot read file header");
        goto cleanup;
    }
    if (nr != 31) {
        dbf_set_error(fh, "Expected file header of %zu bytes, got %zu",
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
        dbf_set_error(fh, "Header size %zu is invalid", header_size);
        errno = EINVAL;
        goto cleanup;
    }

    if (record_size < 1) {
        dbf_set_error(fh, "Record size %zu is invalid", record_size);
        errno = EINVAL;
        goto cleanup;
    }

    descriptors_size = header_size - 32;
    if (descriptors_size == 0) {
        dbf_set_error(fh, "No field descriptors");
        errno = EINVAL;
        goto cleanup;
    }

    descriptors = (char *) malloc(descriptors_size);
    if (descriptors == NULL) {
        dbf_set_error(fh, "Cannot allocate %zu bytes", descriptors_size);
        goto cleanup;
    }

    nr = (*fh->fread)(fh, descriptors, descriptors_size);
    if ((*fh->ferror)(fh)) {
        dbf_set_error(fh, "Cannot read field descriptors");
        goto cleanup;
    }
    if (nr != descriptors_size) {
        dbf_set_error(fh, "Expected field descriptors of %zu bytes, got %zu",
                      descriptors_size, nr);
        errno = EINVAL;
        goto cleanup;
    }

    num_fields = 0;
    n = 0;
    while (n < descriptors_size && descriptors[n] != '\r') {
        ++num_fields;
        n += 32;
    }

    if (num_fields > 2046) {
        dbf_set_error(fh, "Expected at most %d fields, got %d", 2046,
                      num_fields);
        errno = EINVAL;
        goto cleanup;
    }

    result_size = SIZEOF16(*header) + num_fields * sizeof(dbf_field_t);
    header = (dbf_header_t *) calloc(1, result_size);
    if (header == NULL) {
        dbf_set_error(fh, "Cannot allocate %zu bytes", result_size);
        goto cleanup;
    }

    fields = (dbf_field_t *) (void *) (((char *) header) + SIZEOF16(*header));

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
        dbf_set_error(fh,
                      "Sum %zu of field lengths differs from record size %zu",
                      offset, record_size);
        free(header);
        header = NULL;
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
    assert(pheader != NULL);

    nr = (*fh->fread)(fh, bytes, 1);
    if ((*fh->ferror)(fh)) {
        dbf_set_error(fh, "Cannot read file version");
        goto cleanup;
    }
    if (nr != 1) {
        dbf_set_error(fh, "Expected 1 byte, got %zu", nr);
        errno = EINVAL;
        goto cleanup;
    }

    version = (dbf_version_t) bytes[0];
    switch (database_type(version)) {
    case DBF_VERSION_DBASE2:
        rc = read_header_dbase2(fh, version, pheader);
        break;
    case DBF_VERSION_DBASE3:
        rc = read_header_dbase3(fh, version, pheader);
        break;
    default:
        dbf_set_error(fh, "Database version %d is not supported", version);
        errno = EINVAL;
        *pheader = NULL;
        goto cleanup;
    }

    if (*pheader != NULL) {
        fh->header_size = (*pheader)->header_size;
        fh->record_size = (*pheader)->record_size;
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
    assert(fh->record_size > 0);
    assert(precord != NULL);

    record_size = fh->record_size;

    result_size = sizeof(*record) + record_size;
    record = (dbf_record_t *) malloc(result_size);
    if (record == NULL) {
        dbf_set_error(fh, "Cannot allocate %zu bytes", result_size);
        goto cleanup;
    }

    buf = ((char *) record) + sizeof(*record);
    record->bytes = buf;
    if ((nr = (*fh->fread)(fh, buf, record_size)) > 0) {
        if (buf[0] == '\x1a') {
            /* Reached end-of-file marker. */
            free(record);
            record = NULL;
            rc = 0;
            goto cleanup;
        }

        if (nr != record_size) {
            dbf_set_error(fh, "Expected record of %zu bytes, got %zu",
                          record_size, nr);
            free(record);
            record = NULL;
            goto cleanup;
        }
    }

    if ((*fh->ferror)(fh)) {
        dbf_set_error(fh, "Cannot read record");
        free(record);
        record = NULL;
        goto cleanup;
    }

    if ((*fh->feof)(fh)) {
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
dbf_seek_record(dbf_file_t *fh, size_t record_number, dbf_record_t **precord)
{
    int rc = -1;
    size_t file_offset;
    dbf_record_t *record = NULL;

    assert(fh != NULL);
    assert(fh->header_size > 0);
    assert(fh->record_size > 0);
    assert(precord != NULL);

    file_offset = record_number * fh->record_size + fh->header_size;
    if ((*fh->fsetpos)(fh, file_offset) != 0) {
        dbf_set_error(fh, "Cannot set file position to record number %zu\n",
                      record_number);
        goto cleanup;
    }

    rc = dbf_read_record(fh, &record);

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
        dbf_set_error(fh, "Cannot allocate %zu bytes", result_size);
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

    buf = ((char *) record) + sizeof(*record);
    record->bytes = buf;

    record_num = 0;
    file_offset = fh->num_bytes;
    while ((nr = (*fh->fread)(fh, buf, record_size)) > 0) {
        if (buf[0] == '\x1a') {
            /* Reached end-of-file marker. */
            rc = 0;
            goto cleanup;
        }

        if (nr != record_size) {
            dbf_set_error(fh,
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

        file_offset = fh->num_bytes;
        ++record_num;
    }

    if ((*fh->ferror)(fh)) {
        dbf_set_error(fh, "Cannot read record");
        goto cleanup;
    }

    if (record_num < num_records) {
        dbf_set_error(fh, "Expected %zu records, got %zu", num_records,
                      record_num);
        errno = EINVAL;
        goto cleanup;
    }

    if ((*fh->feof)(fh)) {
        rc = 0;
        goto cleanup;
    }

    rc = 1;

cleanup:

    free(record);
    free(header);

    return rc;
}
