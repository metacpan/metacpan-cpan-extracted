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

#ifndef _SHAPEREADER_SHX_H
#define _SHAPEREADER_SHX_H

#include "shp.h"
#include <stddef.h>
#include <stdio.h>

/**
 * Header
 */
typedef shp_header_t shx_header_t;

/**
 * Index record
 */
typedef struct shx_record_t {
    size_t file_offset; /**< Offset in the ".shp" file in bytes */
    size_t record_size; /**< Content length in bytes */
} shx_record_t;

/**
 * File handle
 */
typedef shp_file_t shx_file_t;

/**
 * Initialize a file handle
 *
 * Initializes a shx_file_t structure.
 *
 * @param fh an uninitialized file handle.
 * @param fp a file pointer.
 * @param user_data callback data or NULL.
 * @return the initialized file handle.
 */
extern shx_file_t *shx_init_file(shx_file_t *fh, FILE *fp, void *user_data);

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
extern void shx_set_error(shx_file_t *fh, const char *format, ...)
    __attribute__((format(printf, 2, 3)));
#else
extern void shx_set_error(shx_file_t *fh, const char *format, ...);
#endif

/**
 * Handle the file header
 *
 * A callback function that is called for the file header.
 *
 * @param fh a file handle.
 * @param header a pointer to a shx_header_t structure.
 * @retval 1 on sucess.
 * @retval 0 to stop the processing.
 * @retval -1 on error.
 */
typedef int (*shx_header_callback_t)(shx_file_t *fh,
                                     const shx_header_t *header);

/**
 * Handle a record
 *
 * A callback function that is called for each record.
 *
 * @param fh a file handle.
 * @param header a pointer to a shx_header_t structure.
 * @param record a pointer to a shx_record_t structure.
 * @retval 1 on sucess.
 * @retval 0 to stop the processing.
 * @retval -1 on error.
 */
typedef int (*shx_record_callback_t)(shx_file_t *fh,
                                     const shx_header_t *header,
                                     const shx_record_t *record);

/**
 * Read an index file
 *
 * Reads a file that has the file extension ".shx" and calls functions for the
 * file header and each record.
 *
 * The data that is passed to the callback functions is only valid during the
 * function call.  Do not keep pointers to the data.
 *
 * @b Example
 *
 * @code{.c}
 * int handle_header(shx_file_t *fh, const shx_header_t *header) {
 *   mydata_t *mydata = (mydata_t *) fh->user_data;
 *   // Do something
 *   return 1;
 * }
 *
 * int handle_record(shx_file_t *fh, const shx_header_t *header,
 *                   const shx_record_t *record) {
 *   mydata_t *mydata = (mydata_t *) fh->user_data;
 *   // Do something
 *   return 1;
 * }
 *
 * shx_init_file(fh, fp, mydata)
 * rc = shx_read(fh, handle_header, handle_record);
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
extern int shx_read(shx_file_t *fh, shx_header_callback_t handle_header,
                    shx_record_callback_t handle_record);

/**
 * Read the file header
 *
 * Reads the header from a file that has the file extension ".shx".
 *
 * @param fh a file handle.
 * @param[out] header a shx_header_t structure.
 * @retval 1 on success.
 * @retval 0 on end of file.
 * @retval -1 on error.
 *
 * @see shx_read_record
 */
extern int shx_read_header(shx_file_t *fh, shx_header_t *header);

/**
 * Read an index record
 *
 * Reads an index record from a file that has the file extension ".shx".
 *
 * @b Example
 *
 * @code{.c}
 * shx_header_t header;
 * shx_record_t record;
 *
 * if ((rc = shx_read_header(fh, &header)) > 0) {
 *   while ((rc = shx_read_record(fh, &record)) > 0) {
 *     // Do something
 *   }
 * }
 * @endcode
 *
 * @param fh a file handle.
 * @param[out] record a shx_record_t structure.
 * @retval 1 on success.
 * @retval 0 on end of file.
 * @retval -1 on error.
 *
 * @see shx_read_header
 */
extern int shx_read_record(shx_file_t *fh, shx_record_t *record);

/**
 * Read an index record by record number
 *
 * Sets the file position to the specified record number and reads the
 * requested index record.
 *
 * Please note that this function uses zero-based record numbers, whereas the
 * record numbers in shapefiles begin at 1.
 *
 * @param fh a file handle.
 * @param record_number a zero-based record number.
 * @param[out] record a shx_record_t structure.
 * @retval 1 on success.
 * @retval 0 on end of file.
 * @retval -1 on error.
 *
 * @see shp_seek_record
 */
extern int shx_seek_record(shx_file_t *fh, size_t record_number,
                           shx_record_t *record);

#endif
