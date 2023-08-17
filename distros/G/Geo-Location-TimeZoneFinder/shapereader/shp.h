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

#include "shp-multipatch.h"
#include "shp-multipoint.h"
#include "shp-multipointm.h"
#include "shp-multipointz.h"
#include "shp-point.h"
#include "shp-pointm.h"
#include "shp-pointz.h"
#include "shp-polygon.h"
#include "shp-polygonm.h"
#include "shp-polygonz.h"
#include "shp-polyline.h"
#include "shp-polylinem.h"
#include "shp-polylinez.h"
#include <stddef.h>
#include <stdio.h>

/**
 * Shape types
 */
typedef enum shp_type_t {
    SHP_TYPE_NULL = 0,         /**< Null shape without geometric data */
    SHP_TYPE_POINT = 1,        /**< Point with X, Y coordinates */
    SHP_TYPE_POLYLINE = 3,     /**< PolyLine with X, Y coordinates */
    SHP_TYPE_POLYGON = 5,      /**< Polygon with X, Y coordinates */
    SHP_TYPE_MULTIPOINT = 8,   /**< Set of Points */
    SHP_TYPE_POINTZ = 11,      /**< PointZ with X, Y, Z, M coordinates */
    SHP_TYPE_POLYLINEZ = 13,   /**< PolyLineZ with X, Y, Z, M coordinates */
    SHP_TYPE_POLYGONZ = 15,    /**< PolygonZ with X, Y, Z, M coordinates */
    SHP_TYPE_MULTIPOINTZ = 18, /**< Set of PointZs */
    SHP_TYPE_POINTM = 21,      /**< PointM with X, Y, M coordinates */
    SHP_TYPE_POLYLINEM = 23,   /**< PolyLineM with X, Y, M coordinates */
    SHP_TYPE_POLYGONM = 25,    /**< PolygonM with X, Y, M coordinates */
    SHP_TYPE_MULTIPOINTM = 28, /**< Set of PointMs */
    SHP_TYPE_MULTIPATCH = 31   /**< Complex surfaces */
} shp_type_t;

/**
 * File header
 */
typedef struct shp_header_t {
    long file_code;   /**< Always 9994 */
    long unused[5];   /**< Unused fields */
    size_t file_size; /**< Total file length in bytes */
    long version;     /**< Always 1000 */
    shp_type_t type;  /**< Shape type */
    double x_min;     /**< Minimum X */
    double y_min;     /**< Minimum Y */
    double x_max;     /**< Maximum X */
    double y_max;     /**< Maximum Y */
    double z_min;     /**< Minimum Z */
    double z_max;     /**< Maximum Z */
    double m_min;     /**< Minimum M */
    double m_max;     /**< Maximum M */
} shp_header_t;

/**
 * Record
 */
typedef struct shp_record_t {
    size_t record_number; /**< Record number (beginning at 1) */
    size_t record_size;   /**< Content length in bytes */
    shp_type_t type;      /**< Shape type */
    union {
        /** Point if @a type is @c SHP_TYPE_POINT */
        shp_point_t point;
        /** PointM if @a type is @c SHP_TYPE_POINTM */
        shp_pointm_t pointm;
        /** PointZ if @a type is @c SHP_TYPE_POINTZ */
        shp_pointz_t pointz;
        /** Set of Points if @a type is @c SHP_TYPE_MULTIPOINT */
        shp_multipoint_t multipoint;
        /** Set of PointMs if @a type is @c SHP_TYPE_MULTIPOINTM */
        shp_multipointm_t multipointm;
        /** Set of PointZs if @a type is @c SHP_TYPE_MULTIPOINTZ */
        shp_multipointz_t multipointz;
        /** PolyLine if @a type is @c SHP_TYPE_POLYLINE */
        shp_polyline_t polyline;
        /** PolyLineM if @a type is @c SHP_TYPE_POLYLINEM */
        shp_polylinem_t polylinem;
        /** PolyLineZ if @a type is @c SHP_TYPE_POLYLINEZ */
        shp_polylinez_t polylinez;
        /** Polygon if @a type is @c SHP_TYPE_POLYGON */
        shp_polygon_t polygon;
        /** PolygonM if @a type is @c SHP_TYPE_POLYGONM */
        shp_polygonm_t polygonm;
        /** PolygonZ if @a type is @c SHP_TYPE_POLYGONZ */
        shp_polygonz_t polygonz;
        /** MultiPatch if @a type is @c SHP_TYPE_MULTIPATCH */
        shp_multipatch_t multipatch;
    } shape;
} shp_record_t;

/**
 * File handle
 */
typedef struct shp_file_t {
    /* File pointer */
    void *stream;
    /* Read bytes from the stream */
    size_t (*fread)(struct shp_file_t *fh, void *buf, size_t count);
    /* Test the stream's end-of-file indicator */
    int (*feof)(struct shp_file_t *fh);
    /* Test the stream's error indicator */
    int (*ferror)(struct shp_file_t *fh);
    /* Set the stream's file position */
    int (*fsetpos)(struct shp_file_t *fh, size_t offset);
    /** Callback data */
    void *user_data;
    /** Number of bytes read */
    size_t num_bytes;
    /** Error message */
    char error[128];
} shp_file_t;

/**
 * Initialize a file handle
 *
 * Initializes a shp_file_t structure.
 *
 * @param fh an uninitialized file handle.
 * @param stream a FILE pointer.
 * @param user_data callback data or NULL.
 * @return the initialized file handle.
 */
extern shp_file_t *shp_init_file(shp_file_t *fh, FILE *stream,
                                 void *user_data);

/**
 * Set an error message
 *
 * Formats and sets an error message.
 *
 * @param fh a file handle.
 * @param format a printf format string followed by a variable number of
 *               arguments.
 */
#ifdef __GNUC__
extern void shp_set_error(shp_file_t *fh, const char *format, ...)
    __attribute__((format(printf, 2, 3)));
#else
extern void shp_set_error(shp_file_t *fh, const char *format, ...);
#endif

/**
 * Handle the file header
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
 * Handle a record
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
 * Read a shape file
 *
 * Reads a file that has the file extension ".shp" and calls functions for the
 * file header and each record.
 *
 * The data that is passed to the callback functions is only valid during the
 * function call.  Do not keep pointers to the data.
 *
 * @b Example
 *
 * @code{.c}
 * int handle_header(shp_file_t *fh, const shp_header_t *header) {
 *   mydata_t *mydata = (mydata_t *) fh->user_data;
 *   // Do something
 *   return 1;
 * }
 *
 * int handle_record(shp_file_t *fh, const shp_header_t *header,
 *                   const shp_record_t *record, size_t file_offset) {
 *   mydata_t *mydata = (mydata_t *) fh->user_data;
 *   // Do something
 *   return 1;
 * }
 *
 * shp_init_file(fh, stream, mydata)
 * rc = shp_read(fh, handle_header, handle_record);
 * @endcode
 *
 * @param fh a file handle.
 * @param handle_header a function that is called for the file header.
 * @param handle_record a function that is called for each record.
 * @retval 1 on success.
 * @retval 0 on end of file.
 * @retval -1 on error.
 *
 * @see the "ESRI Shapefile Technical Description" @cite ESRI_shape for
 *      information on the file format.
 */
extern int shp_read(shp_file_t *fh, shp_header_callback_t handle_header,
                    shp_record_callback_t handle_record);

/**
 * Read the file header
 *
 * Reads the header from a file that has the file extension ".shp".
 *
 * @param fh a file handle.
 * @param[out] header a shp_header_t structure.
 * @retval 1 on success.
 * @retval 0 on end of file.
 * @retval -1 on error.
 *
 * @see shp_read_record
 */
extern int shp_read_header(shp_file_t *fh, shp_header_t *header);

/**
 * Read a record
 *
 * Reads a record from a file that has the file extension ".shp".
 *
 * @b Example
 *
 * @code{.c}
 * shp_header_t header;
 * shp_record_t *record;
 *
 * if ((rc = shp_read_header(fh, &header)) > 0) {
 *   while ((rc = shp_read_record(fh, &record)) > 0) {
 *     // Do something
 *     free(record);
 *   }
 * }
 * @endcode
 *
 * @param fh a file handle.
 * @param[out] precord on success, a pointer to a shp_record_t structure.
 *                     Free the record with @c free() when you are done.
 * @retval 1 on success.
 * @retval 0 on end of file.
 * @retval -1 on error.
 *
 * @see shp_read_header
 */
extern int shp_read_record(shp_file_t *fh, shp_record_t **precord);

/**
 * Read a record at a particular file position
 *
 * Sets the file position to an offset from a ".shx" file and reads the
 * requested record.
 *
 * @b Example
 *
 * @code{.c}
 * shx_record_t index;
 * shp_record_t *record = NULL;
 *
 * if (shx_seek_record(shx_fh, record_number, &index) > 0) {
 *   if (shp_seek_record(shp_fh, index.file_offset, &record) > 0) {
 *     // Do something
 *     free(record);
 *   }
 * }
 * @endcode
 *
 * @param fh a file handle.
 * @param file_offset an offset from a ".shx" file.
 * @param[out] precord on success, a pointer to a shp_record_t structure.
 *                     Free the record with @c free() when you are done.
 * @retval 1 on success.
 * @retval 0 on end of file.
 * @retval -1 on error.
 *
 * @see shx_seek_record
 */
extern int shp_seek_record(shp_file_t *fh, size_t file_offset,
                           shp_record_t **precord);

#endif
