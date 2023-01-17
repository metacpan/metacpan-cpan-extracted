/*
 * Read ESRI shapefiles
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This library is free software; you can redistribute it and/or modify it
 * under either the terms of the ISC License or the same terms as Perl.
 */

/* SPDX-License-Identifier: ISC OR Artistic-1.0-Perl OR GPL-1.0-or-later */

/**
 * @file
 */

#ifndef _SHAPEREADER_SHP_H
#define _SHAPEREADER_SHP_H

#include "shp-point.h"
#include "shp-polygon.h"
#include <stdint.h>
#include <stdio.h>

/**
 * Shape types
 */
typedef enum shp_shpt_t {
    SHPT_NULL = 0,         /**< Null shape without geometric data */
    SHPT_POINT = 1,        /**< Point with X, Y coordinates */
    SHPT_POLYLINE = 3,     /**< PolyLine with X, Y coordinates */
    SHPT_POLYGON = 5,      /**< Polygon with X, Y coordinates */
    SHPT_MULTIPOINT = 8,   /**< Set of Points */
    SHPT_POINTZ = 11,      /**< PointZ with X, Y, Z, M coordinates */
    SHPT_POLYLINEZ = 13,   /**< PolyLineZ with X, Y, Z, M coordinates */
    SHPT_POLYGONZ = 15,    /**< PolygonZ with X, Y, Z, M coordinates */
    SHPT_MULTIPOINTZ = 18, /**< Set of PointZs */
    SHPT_POINTM = 21,      /**< PointM with X, Y, M coordinates */
    SHPT_POLYLINEM = 23,   /**< PolyLineM with X, Y, M coordinates */
    SHPT_POLYGONM = 25,    /**< PolygonM with X, Y, M coordinates */
    SHPT_MULTIPOINTM = 28, /**< Set of PointMs */
    SHPT_MULTIPATCH = 31   /**< Complex surfaces */
} shp_shpt_t;

/**
 * File header
 */
typedef struct shp_header_t {
    int32_t file_code;     /**< Always 9994 */
    int32_t unused[5];     /**< Unused fields */
    int32_t file_length;   /**< Total file length in 16-bit words */
    int32_t version;       /**< Always 1000 */
    shp_shpt_t shape_type; /**< Shape type */
    double x_min;          /**< Minimum X */
    double y_min;          /**< Minimum Y */
    double x_max;          /**< Maximum X */
    double y_max;          /**< Maximum Y */
    double z_min;          /**< Minimum Z */
    double z_max;          /**< Maximum Z */
    double m_min;          /**< Minimum M */
    double m_max;          /**< Maximum M */
} shp_header_t;

/**
 * Record
 */
typedef struct shp_record_t {
    int32_t record_number;  /**< Record number */
    int32_t content_length; /**< Record content length in 16-bit words */
    shp_shpt_t shape_type;  /**< Shape type */
    union {
        shp_point_t point;     /**< Point if @a shape_type is
                                    @c SHPT_POINT */
        shp_polygon_t polygon; /**< Polygon if @a shape_type is
                                    @c SHPT_POLYGON */
    } shape;
} shp_record_t;

/**
 * File handle
 */
typedef struct shp_file_t {
    FILE *fp;           /**< File pointer */
    void *user_data;    /**< Callback data */
    size_t num_bytes;   /**< Number of bytes read */
    char error[1024];   /**< Error message */
} shp_file_t;

/**
 * Initialize a file handle
 *
 * Initializes a shp_file_t structure.
 *
 * @param fh an uninitialized file handle.
 * @param fp a file pointer.
 * @param user_data callback data or NULL.
 * @return the initialized file handle.
 */
extern shp_file_t *shp_file(shp_file_t *fh, FILE *fp, void *user_data);

/**
 * Set an error message.
 *
 * Formats and sets an error message.
 *
 * @param fh a file handle.
 * @param format a printf format string followed by a variable number of
 *               arguments.
 */
extern void shp_error(shp_file_t *fh, const char *format, ...);

/**
 * Handle the file header.
 *
 * A callback function that is called for the file header.
 *
 * @param fh a file handle.
 * @param header a pointer to a shp_header_t structure.
 * @retval 1 on sucess.
 * @retval 0 to stop the processing.
 * @retval -1 on error.
 */
typedef int (*shp_header_callback_t)(shp_file_t *fh,
                                     const shp_header_t *header);

/**
 * Handle a record.
 *
 * A callback function that is called for each record.
 *
 * @param fh a file handle.
 * @param header a pointer to a shp_header_t structure.
 * @param record a pointer to a shp_record_t structure.
 * @param file_offset the record's position in the file.
 * @retval 1 on sucess.
 * @retval 0 to stop the processing.
 * @retval -1 on error.
 */
typedef int (*shp_record_callback_t)(shp_file_t *fh,
                                     const shp_header_t *header,
                                     const shp_record_t *record,
                                     size_t file_offset);

/**
 * Read a shape file.
 *
 * Reads files that have the file extension ".shp" and calls functions for the
 * file header and each record.
 *
 * The data that is passed to the callback functions is only valid during the
 * function call.  Do not keep pointers to the data.
 *
 * @param fh a file handle.
 * @param handle_header a function that is called for the file header.
 * @param handle_record a function that is called for each record.
 * @retval 1 on success.
 * @retval 0 on end of file.
 * @retval -1 on error.
 * @see the "ESRI Shapefile Technical Description" @cite ESRI_shape for
 *      information on the file format.
 */
extern int shp_read(shp_file_t *fh, shp_header_callback_t handle_header,
                    shp_record_callback_t handle_record);

/**
 * Read the file header.
 *
 * Reads the header from files that have the file extension ".shp".
 *
 * @param fh a file handle.
 * @param[out] pheader on sucess, a pointer to a shp_header_t structure.
 *                     Free the header with @c free() when you are done.
 * @retval 1 on success.
 * @retval 0 on end of file.
 * @retval -1 on error.
 */
extern int shp_read_header(shp_file_t *fh, shp_header_t **pheader);

/**
 * Read a record.
 *
 * Reads a record from files that have the file extension ".shp".
 *
 * @param fh a file handle.
 * @param[out] precord on success, a pointer to a shp_record_t structure.
 *                     Free the record with @c free() when you are done.
 * @retval 1 on success.
 * @retval 0 on end of file.
 * @retval -1 on error.
 */
extern int shp_read_record(shp_file_t *fh, shp_record_t **precord);

#endif
