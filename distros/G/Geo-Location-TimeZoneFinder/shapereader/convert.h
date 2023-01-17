/*
 * Read ESRI shapefiles
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This library is free software; you can redistribute it and/or modify it
 * under either the terms of the ISC License or the same terms as Perl.
 */

/* SPDX-License-Identifier: ISC OR Artistic-1.0-Perl OR GPL-1.0-or-later */

#ifndef _SHAPEREADER_CONVERT_H
#define _SHAPEREADER_CONVERT_H

/**
 * @file
 */

#include <stdint.h>
#include <time.h>

/**
 * Convert bytes in litte-endian order to uint16_t
 *
 * Converts two bytes in litte-endian order to a uint16_t value.
 *
 * @param bytes a buffer with two bytes.
 * @return a uint16_t value.
 */
extern uint16_t shp_le16_to_uint16(const char *bytes);

/**
 * Convert bytes in big-endian order to int32_t
 *
 * Converts four bytes in big-endian order to an int32_t value.
 *
 * @param bytes a buffer with four bytes.
 * @return an int32_t value.
 */
extern int32_t shp_be32_to_int32(const char *bytes);

/**
 * Convert bytes in little-endian order to int32_t
 *
 * Converts four bytes in little-endian order to an int32_t value.
 *
 * @param bytes a buffer with four bytes.
 * @return an int32_t value.
 */
extern int32_t shp_le32_to_int32(const char *bytes);

/**
 * Convert bytes in little-endian order to uint32_t
 *
 * Converts four bytes in little-endian order to a uint32_t value.
 *
 * @param bytes a buffer with four bytes.
 * @return a uint32_t value.
 */
extern uint32_t shp_le32_to_uint32(const char *bytes);

/**
 * Convert bytes in little-endian order to int64_t
 *
 * Converts eight bytes in little-endian order to an int64_t value.
 *
 * @param bytes a buffer with eight bytes.
 * @return an int64_t value.
 */
extern int64_t shp_le64_to_int64(const char *bytes);

/**
 * Convert bytes in little-endian order to double
 *
 * Converts eight bytes in little-endian order to a double value.
 *
 * @param bytes a buffer with eight bytes.
 * @return a double value.
 */
extern double shp_le64_to_double(const char *bytes);

/**
 * Convert a Julian date into a tm structure.
 *
 * Calculates the calendar date from a Julian date and the time since midnight.
 *
 * The tm_isdst member of the tm structure is always set to -1.
 *
 * @param jd days since 1 January -4712.
 * @param jt milliseconds since midnight.
 * @param[out] ptm the converted date.
 * @see "Astronomical Algorithms" @cite Astronomical_Algorithms, p. 63 for a
 *      description of the algorithm.
 */
extern void shp_jd_to_tm(int32_t jd, int32_t jt, struct tm *ptm);

/**
 * Converts a date string in the format "YYYYMMDD" into a tm structure.
 *
 * Fills a tm structure with the day, month and year from a date string.
 *
 * The tm_wday member is only valid after 15 October 1582 in the Gregorian
 * calendar.
 *
 * The tm_isdst member is always set to -1.
 *
 * @param ymd a date string in the format "YYYYMMDD".
 * @param n the string length
 * @param[out] ptm the converted date.
 * @return true on success, otherwise false.
 */
extern int shp_yyyymmdd_to_tm(const char *ymd, size_t n, struct tm *ptm);

#endif
