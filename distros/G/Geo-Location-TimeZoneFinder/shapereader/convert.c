/*
 * Read ESRI shapefiles
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This library is free software; you can redistribute it and/or modify it
 * under either the terms of the ISC License or the same terms as Perl.
 */

/* SPDX-License-Identifier: ISC OR Artistic-1.0-Perl OR GPL-1.0-or-later */

#ifdef HAVE_CONFIG_H
#include "config.h"
#else
#if defined __BYTE_ORDER__
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#define WORDS_BIGENDIAN 1
#elif __BYTE_ORDER__ != __ORDER_LITTLE_ENDIAN__
#error Unknown byte order
#endif
#endif
#endif

#include "convert.h"
#include <assert.h>
#include <string.h>

/*
 * Some architectures require data to be aligned on 16-, 32- or 64-bit
 * boundaries.
 */

uint16_t
shp_le16_to_uint16(const char *bytes)
{
    uint16_t n;

    assert(bytes != NULL);

#ifdef WORDS_BIGENDIAN
    ((char *) &n)[0] = bytes[1];
    ((char *) &n)[1] = bytes[0];
#else
    memcpy(&n, bytes, sizeof(n)); /* NOLINT */
#endif
    return n;
}

int32_t
shp_be32_to_int32(const char *bytes)
{
    int32_t n;

    assert(bytes != NULL);

#ifdef WORDS_BIGENDIAN
    memcpy(&n, bytes, sizeof(n)); /* NOLINT */
#else
    ((char *) &n)[0] = bytes[3];
    ((char *) &n)[1] = bytes[2];
    ((char *) &n)[2] = bytes[1];
    ((char *) &n)[3] = bytes[0];
#endif
    return n;
}

int32_t
shp_le32_to_int32(const char *bytes)
{
    int32_t n;

    assert(bytes != NULL);

#ifdef WORDS_BIGENDIAN
    ((char *) &n)[0] = bytes[3];
    ((char *) &n)[1] = bytes[2];
    ((char *) &n)[2] = bytes[1];
    ((char *) &n)[3] = bytes[0];
#else
    memcpy(&n, bytes, sizeof(n)); /* NOLINT */
#endif
    return n;
}

uint32_t
shp_le32_to_uint32(const char *bytes)
{
    uint32_t n;

    assert(bytes != NULL);

#ifdef WORDS_BIGENDIAN
    ((char *) &n)[0] = bytes[3];
    ((char *) &n)[1] = bytes[2];
    ((char *) &n)[2] = bytes[1];
    ((char *) &n)[3] = bytes[0];
#else
    memcpy(&n, bytes, sizeof(n)); /* NOLINT */
#endif
    return n;
}

int64_t
shp_le64_to_int64(const char *bytes)
{
    int64_t n;

    assert(bytes != NULL);

#ifdef WORDS_BIGENDIAN
    ((char *) &n)[0] = bytes[7];
    ((char *) &n)[1] = bytes[6];
    ((char *) &n)[2] = bytes[5];
    ((char *) &n)[3] = bytes[4];
    ((char *) &n)[4] = bytes[3];
    ((char *) &n)[5] = bytes[2];
    ((char *) &n)[6] = bytes[1];
    ((char *) &n)[7] = bytes[0];
#else
    memcpy(&n, bytes, sizeof(n)); /* NOLINT */
#endif
    return n;
}

double
shp_le64_to_double(const char *bytes)
{
    double n;

    assert(bytes != NULL);

#ifdef WORDS_BIGENDIAN
    ((char *) &n)[0] = bytes[7];
    ((char *) &n)[1] = bytes[6];
    ((char *) &n)[2] = bytes[5];
    ((char *) &n)[3] = bytes[4];
    ((char *) &n)[4] = bytes[3];
    ((char *) &n)[5] = bytes[2];
    ((char *) &n)[6] = bytes[1];
    ((char *) &n)[7] = bytes[0];
#else
    memcpy(&n, bytes, sizeof(n)); /* NOLINT */
#endif
    return *((double *) &n);
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
shp_jd_to_tm(int32_t jd, int32_t jt, struct tm *ptm)
{
    int sec, min, hour, day, month, year;
    int64_t a, b, c, d, e, alpha;
    double s, m, h;
    const double month_days_without_jan_feb = (365 - 31 - 28) / 10.0;

    assert(ptm != NULL);

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

    memset(ptm, 0, sizeof(*ptm)); /* NOLINT */
    ptm->tm_sec = sec;
    ptm->tm_min = min;
    ptm->tm_hour = hour;
    ptm->tm_mday = day;
    ptm->tm_mon = month - 1;
    ptm->tm_year = year - 1900;
    ptm->tm_wday = (int) ((jd + 1) % 7);
    ptm->tm_yday = day_of_year(day, month, year) - 1;
    ptm->tm_isdst = -1;
}

int
shp_yyyymmdd_to_tm(const char *ymd, size_t n, struct tm *ptm)
{
    int ok = 0;
    int day = 0, month = 0, year = 0, wday = 0, yday = 0;
    size_t a, i, k, z;
    int c;

    assert(ymd != NULL);
    assert(ptm != NULL);

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

    memset(ptm, 0, sizeof(*ptm)); /* NOLINT */
    if (ok) {
        ptm->tm_mday = day;
        ptm->tm_mon = month - 1;
        ptm->tm_year = year - 1900;
        ptm->tm_wday = wday;
        ptm->tm_yday = yday - 1;
    }
    ptm->tm_isdst = -1;

    return ok;
}
