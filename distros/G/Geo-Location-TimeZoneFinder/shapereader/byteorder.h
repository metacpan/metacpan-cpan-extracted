/*
 * Read ESRI shapefiles
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This library is free software; you can redistribute it and/or modify it
 * under either the terms of the ISC License or the same terms as Perl.
 */

/* SPDX-License-Identifier: ISC OR Artistic-1.0-Perl OR GPL-1.0-or-later */

#ifndef _SHAPEREADER_BYTEORDER_H
#define _SHAPEREADER_BYTEORDER_H

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#ifndef WORDS_BIGENDIAN
#if defined __BYTE_ORDER__
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#define WORDS_BIGENDIAN 1
#elif __BYTE_ORDER__ != __ORDER_LITTLE_ENDIAN__
#error Unknown byte order
#endif
#endif
#endif

/*
 * Remember that some architectures require data to be aligned on 16-, 32- or
 * 64-bit boundaries.
 */

/**
 * Convert bytes in litte-endian order to uint16_t
 *
 * Converts two bytes in litte-endian order to a uint16_t value.
 *
 * @param bytes a buffer with two bytes.
 * @return a uint16_t value.
 */
static inline uint16_t
shp_le16_to_uint16(const char *bytes)
{
    uint16_t n;

#ifdef WORDS_BIGENDIAN
    ((char *) &n)[0] = bytes[1];
    ((char *) &n)[1] = bytes[0];
#else
    memcpy(&n, bytes, sizeof(n)); /* NOLINT */
#endif
    return n;
}

/**
 * Convert bytes in big-endian order to int32_t
 *
 * Converts four bytes in big-endian order to an int32_t value.
 *
 * @param bytes a buffer with four bytes.
 * @return an int32_t value.
 */
static inline int32_t
shp_be32_to_int32(const char *bytes)
{
    int32_t n;

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

/**
 * Convert bytes in little-endian order to int32_t
 *
 * Converts four bytes in little-endian order to an int32_t value.
 *
 * @param bytes a buffer with four bytes.
 * @return an int32_t value.
 */
static inline int32_t
shp_le32_to_int32(const char *bytes)
{
    int32_t n;

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

/**
 * Convert bytes in big-endian order to uint32_t
 *
 * Converts four bytes in big-endian order to a uint32_t value.
 *
 * @param bytes a buffer with four bytes.
 * @return a uint32_t value.
 */
static inline uint32_t
shp_be32_to_uint32(const char *bytes)
{
    uint32_t n;

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

/**
 * Convert bytes in little-endian order to uint32_t
 *
 * Converts four bytes in little-endian order to a uint32_t value.
 *
 * @param bytes a buffer with four bytes.
 * @return a uint32_t value.
 */
static inline uint32_t
shp_le32_to_uint32(const char *bytes)
{
    uint32_t n;

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

/**
 * Convert bytes in little-endian order to int64_t
 *
 * Converts eight bytes in little-endian order to an int64_t value.
 *
 * @param bytes a buffer with eight bytes.
 * @return an int64_t value.
 */
static inline int64_t
shp_le64_to_int64(const char *bytes)
{
    int64_t n;

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

/**
 * Convert bytes in little-endian order to double
 *
 * Converts eight bytes in little-endian order to a double value.
 *
 * @param bytes a buffer with eight bytes.
 * @return a double value.
 */
static inline double
shp_le64_to_double(const char *bytes)
{
    double n;

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

#endif
