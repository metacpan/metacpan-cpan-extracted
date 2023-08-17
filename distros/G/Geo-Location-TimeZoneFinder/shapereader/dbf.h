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

#ifndef _SHAPEREADER_DBF_H
#define _SHAPEREADER_DBF_H

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>

/**
 * Versions
 */
typedef enum dbf_version_t {
    /** Unknown */
    DBF_VERSION_UNKNOWN = 0x00,
    /** dBase II */
    DBF_VERSION_DBASE2 = 0x02,
    /** dBase III */
    DBF_VERSION_DBASE3 = 0x03,
    /** dBase IV */
    DBF_VERSION_DBASE4 = 0x04,
    /** dBase V */
    DBF_VERSION_DBASE5 = 0x05,
    /** Visual Objects */
    DBF_VERSION_VISUAL_OBJECTS = 0x07,
    /** Visual FoxPro */
    DBF_VERSION_VISUAL_FOXPRO = 0x30,
    /** Visual FoxPro with Autoincrement field */
    DBF_VERSION_VISUAL_FOXPRO_AUTO = 0x31,
    /**< Visual FoxPro with Varchar or Varbinary field */
    DBF_VERSION_VISUAL_FOXPRO_VARIFIELD = 0x32,
    /** dBase III with memo file */
    DBF_VERSION_DBASE3_MEMO = 0x83,
    /** Visual Objects with memo file */
    DBF_VERSION_VISUAL_OBJECTS_MEMO = 0x87,
    /** dBase IV with memo file */
    DBF_VERSION_DBASE4_MEMO = 0x8b,
    /** dBase 7 */
    DBF_VERSION_DBASE7 = 0x8c,
    /** FoxPro with memo file */
    DBF_VERSION_FOXPRO_MEMO = 0xf5
} dbf_version_t;

/**
 * Field types
 */
typedef enum dbf_type_t {
    /** Autoincrement (4 bytes) */
    DBF_TYPE_AUTOINCREMENT = '+',
    /** Binary (integer stored as a string). Double (8 bytes) in FoxPro */
    DBF_TYPE_BINARY_OR_DOUBLE = 'B',
    /** Blob (integer stored as a string) */
    DBF_TYPE_BLOB = 'W',
    /** String */
    DBF_TYPE_CHARACTER = 'C',
    /** Decimal number (8 bytes) */
    DBF_TYPE_CURRENCY = 'Y',
    /** Date (stored as "YYYYMMDD") */
    DBF_TYPE_DATE = 'D',
    /** Date and time (8 bytes) */
    DBF_TYPE_DATETIME = 'T',
    /** Double (8 bytes) */
    DBF_TYPE_DOUBLE = 'O',
    /** Number (stored as a string) */
    DBF_TYPE_FLOAT = 'F',
    /** OLE (integer stored as a string) */
    DBF_TYPE_GENERAL = 'G',
    /** Integer (4 bytes) */
    DBF_TYPE_INTEGER = 'I',
    /** Logical (1 byte) */
    DBF_TYPE_LOGICAL = 'L',
    /** Memo (integer stored as a string) */
    DBF_TYPE_MEMO = 'M',
    /** _NullFlags (bytes) */
    DBF_TYPE_NULLFLAGS = '0',
    /** Number (stored as a string) */
    DBF_TYPE_NUMBER = 'N',
    /** Picture (integer stored as a string) */
    DBF_TYPE_PICTURE = 'P',
    /** Timestamp (8 bytes) */
    DBF_TYPE_TIMESTAMP = '@',
    /** Varbinary */
    DBF_TYPE_VARBINARY = 'Q',
    /** Varchar */
    DBF_TYPE_VARCHAR = 'V'
} dbf_type_t;

/**
 * Field
 */
typedef struct dbf_field_t {
    struct dbf_field_t *next;   /**< Next field or NULL */
    char name[32];              /**< Name */
    dbf_type_t type;            /**< Type */
    size_t length;              /**< Number of bytes */
    size_t decimal_places;      /**< Number of decimal places in a number */
    unsigned char reserved[14]; /**< Reserved bytes */
    size_t size;                /* Size in bytes */
    size_t offset;              /* Position in the record buffer */
} dbf_field_t;

/**
 * File header
 */
typedef struct dbf_header_t {
    dbf_version_t version;      /**< Table version */
    int year;                   /**< Year since 1900 */
    int month;                  /**< Month */
    int day;                    /**< Day */
    size_t num_records;         /**< Number of records */
    size_t header_size;         /**< Number of bytes in the header */
    size_t record_size;         /**< Number of bytes in a record */
    unsigned char reserved[20]; /**< Reserved bytes */
    int num_fields;             /**< Number of fields in each record */
    dbf_field_t *fields;        /**< The fields in each record */
} dbf_header_t;

/**
 * Record
 */
typedef struct dbf_record_t {
    char *bytes; /* Raw data of length record_size */
} dbf_record_t;

/**
 * Convert a Julian date into a tm structure
 *
 * Calculates the calendar date from a Julian date and the time since
 * midnight.
 *
 * The tm_isdst member of the tm structure is always set to -1.
 *
 * @param jd days since 1 January -4712.
 * @param jt milliseconds since midnight.
 * @param[out] tm the converted date.
 *
 * @see "Astronomical Algorithms" @cite Astronomical_Algorithms, p. 63 for a
 *      description of the algorithm.
 */
extern void dbf_jd_to_tm(int32_t jd, int32_t jt, struct tm *tm);

/**
 * Converts a date string in the format "YYYYMMDD" into a tm structure
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
 * @param[out] tm the converted date.
 * @return true on success, otherwise false.
 */
extern int dbf_yyyymmdd_to_tm(const char *ymd, size_t n, struct tm *tm);

/**
 * Get bytes
 *
 * Gets the bytes and the number of bytes from a field in a record.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param[out] pbytes a pointer to the bytes.
 * @param[out] len the number of bytes.
 */
extern void dbf_record_bytes(const dbf_record_t *record,
                             const dbf_field_t *field, const char **pbytes,
                             size_t *len);

/**
 * Get a date
 *
 * Fills a tm structure with the day, month and year from a date in the
 * format "YYYYMMDD".
 *
 * The tm_wday member is only valid after 15 October 1582 in the Gregorian
 * calendar.
 *
 * The tm_isdst member is always set to -1.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param[out] tm a tm structure.
 * @return true on success, otherwise false.
 */
extern int dbf_record_date(const dbf_record_t *record,
                           const dbf_field_t *field, struct tm *tm);

/**
 * Get a date and a time
 *
 * Fills a tm structure with a date and time from a date and time field.
 *
 * The tm_isdst member is always set to -1.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param[out] tm a tm structure.
 * @return true on success, otherwise false.
 */
extern int dbf_record_datetime(const dbf_record_t *record,
                               const dbf_field_t *field, struct tm *tm);

/**
 * Get a double value
 *
 * Gets a floating-point number from a double field.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param[out] value the double value.
 * @return true on success, otherwise false.
 */
extern int dbf_record_double(const dbf_record_t *record,
                             const dbf_field_t *field, double *value);

/**
 * Get a 32-bit integer value
 *
 * Gets an integer from an auto-increment or integer field.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param[out] value the unscaled value.
 * @return true on success, otherwise false.
 */
extern int dbf_record_int32(const dbf_record_t *record,
                            const dbf_field_t *field, int32_t *value);

/**
 * Get a 64-bit integer value
 *
 * Gets an unscaled integer from a currency field.  The scale is stored in
 * field->decimal_places.
 *
 * For example, the decimal fraction 3.45 has the unscaled value 345 and the
 * scale 2.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param[out] value the unscaled value.
 * @return true on success, otherwise false.
 */
extern int dbf_record_int64(const dbf_record_t *record,
                            const dbf_field_t *field, int64_t *value);

/**
 * Check if a record is deleted
 *
 * Returns true if the record is marked as deleted.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @return true if the record is deleted, otherwise false.
 */
extern int dbf_record_is_deleted(const dbf_record_t *record);

/**
 * Check if a field is null
 *
 * Returns true if the field contains an empty string, if a number field
 * contains asterisks, if a date field is "00000000" or if a logical field is
 * neither true nor false.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @return true if the field is defined, otherwise false.
 */
extern int dbf_record_is_null(const dbf_record_t *record,
                              const dbf_field_t *field);

/**
 * Get a logical value
 *
 * Returns the value of a logical field.
 *
 * Possible values are:
 *
 * @li @b True: 'T', 't', 'Y' or 'y'
 * @li @b False: 'F', 'f', 'N' or 'n'
 * @li @b Undefined: '?' or a space character
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @return a logical value or zero if the field is not a logical field.
 */
extern int dbf_record_logical(const dbf_record_t *record,
                              const dbf_field_t *field);

/**
 * Check if a logical value is false
 *
 * Returns true if a field's value is 'F', 'f', 'N' or 'n'.
 *
 * A logical value can be true, false or undefined.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @return true if the logical value is false, otherwise false.
 */
extern int dbf_record_logical_is_false(const dbf_record_t *record,
                                       const dbf_field_t *field);

/**
 * Check if a logical value is true
 *
 * Returns true if a field's value is 'T', 't', 'Y' or 'y'.
 *
 * A logical value can be true, false or undefined.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @return true if the logical value is true, otherwise false.
 */
extern int dbf_record_logical_is_true(const dbf_record_t *record,
                                      const dbf_field_t *field);

/**
 * Duplicate a string
 *
 * Duplicates a string.  The string is not decoded to UTF-8.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @return a string that needs to be freed with @c free().  The function
 *         returns NULL if the required memory could not be allocated.
 */
extern char *dbf_record_strdup(const dbf_record_t *record,
                               const dbf_field_t *field);

/**
 * Get a string
 *
 * Gets a string and its length.  The string is not null-terminated and not
 * decoded to UTF-8.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param[out] pstr a pointer to the string.
 * @param[out] len the length.
 */
extern void dbf_record_string(const dbf_record_t *record,
                              const dbf_field_t *field, const char **pstr,
                              size_t *len);

/**
 * Convert a string to double representation
 *
 * Converts a numeric string to a floating-point number.  Fails if the string
 * does not contain a number.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param[out] value the converted value.
 * @return true on success, otherwise false.
 */
extern int dbf_record_strtod(const dbf_record_t *record,
                             const dbf_field_t *field, double *value);

/**
 * Convert a string to a long integer
 *
 * Converts a numeric string to a long integer.  Fails if the string does not
 * contain a number with no decimal places.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param base 10 for decimal.  See strtol(3) for details.
 * @param[out] value the converted value.
 * @return true on success, otherwise false.
 */
extern int dbf_record_strtol(const dbf_record_t *record,
                             const dbf_field_t *field, int base, long *value);

/**
 * Convert a string to long double representation
 *
 * Converts a numeric string field to a floating-point number.  Fails if the
 * string does not contain a number.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param[out] value the converted value.
 * @return true on success, otherwise false.
 */
extern int dbf_record_strtold(const dbf_record_t *record,
                              const dbf_field_t *field, long double *value);

/**
 * Convert a string to a long long integer
 *
 * Converts a numeric string to a long long integer.  Fails if the string
 * does not contain a number with no decimal places.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param base 10 for decimal.  See strtol(3) for details.
 * @param[out] value the converted value.
 * @return true on success, otherwise false.
 */
extern int dbf_record_strtoll(const dbf_record_t *record,
                              const dbf_field_t *field, int base,
                              long long *value);

/**
 * Convert a string to an unsigned long integer
 *
 * Converts a numeric string to an unsigned long integer.  Fails if the
 * string does not contain a non-negative number with no decimal places.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param base 10 for decimal.  See strtoul(3) for details.
 * @param[out] value the converted value.
 * @return true on success, otherwise false.
 */
extern int dbf_record_strtoul(const dbf_record_t *record,
                              const dbf_field_t *field, int base,
                              unsigned long *value);

/**
 * Convert a string to an unsigned long long integer
 *
 * Converts a numeric string to an unsigned long long integer.  Fails if the
 * string does not contain a non-negative number with no decimal places.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param base 10 for decimal.  See strtoull(3) for details.
 * @param[out] value the converted value.
 * @return true on success, otherwise false.
 */
extern int dbf_record_strtoull(const dbf_record_t *record,
                               const dbf_field_t *field, int base,
                               unsigned long long *value);

/**
 * File handle
 */
typedef struct dbf_file_t {
    /* File pointer */
    void *stream;
    /* Read bytes from the stream */
    size_t (*fread)(struct dbf_file_t *fh, void *buf, size_t count);
    /* Test the stream's end-of-file indicator */
    int (*feof)(struct dbf_file_t *fh);
    /* Test the stream's error indicator */
    int (*ferror)(struct dbf_file_t *fh);
    /* Set the stream's file position */
    int (*fsetpos)(struct dbf_file_t *fh, size_t offset);
    /** Callback data */
    void *user_data;
    /** Number of bytes read */
    size_t num_bytes;
    /** Error message */
    char error[128];
    /* Header size */
    size_t header_size;
    /* Record size */
    size_t record_size;
} dbf_file_t;

/**
 * Initialize a file handle
 *
 * Initializes a dbf_file_t structure.
 *
 * @param fh an uninitialized file handle.
 * @param stream a FILE pointer.
 * @param user_data callback data or NULL.
 * @return the initialized file handle.
 */
extern dbf_file_t *dbf_init_file(dbf_file_t *fh, FILE *stream,
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
extern void dbf_set_error(dbf_file_t *fh, const char *format, ...)
    __attribute__((format(printf, 2, 3)));
#else
extern void dbf_set_error(dbf_file_t *fh, const char *format, ...);
#endif

/**
 * Handle the file header
 *
 * A callback function that is called for the file header.
 *
 * @param fh a file handle.
 * @param header a pointer to a dbf_header_t structure.
 * @retval 1 on sucess.
 * @retval 0 to stop the processing.
 * @retval -1 on error.
 */
typedef int (*dbf_header_callback_t)(dbf_file_t *fh,
                                     const dbf_header_t *header);

/**
 * Handle a record
 *
 * A callback function that is called for each record.
 *
 * @param fh a file handle.
 * @param header a pointer to a dbf_header_t structure.
 * @param record a pointer to a dbf_record_t structure.
 * @param file_offset the record's position in the file.
 * @retval 1 on sucess.
 * @retval 0 to stop the processing.
 * @retval -1 on error.
 */
typedef int (*dbf_record_callback_t)(dbf_file_t *fh,
                                     const dbf_header_t *header,
                                     const dbf_record_t *record,
                                     size_t file_offset);

/**
 * Read a data file
 *
 * Reads a file that has the file extension ".dbf" and calls functions for the
 * file header and each record.
 *
 * The data that is passed to the callback functions is only valid during the
 * function call.  Do not keep pointers to the data.
 *
 * @b Example
 *
 * @code{.c}
 * int handle_header(dbf_file_t *fh, const dbf_header_t *header) {
 *   mydata_t *mydata = (mydata_t *) fh->user_data;
 *   // Do something
 *   return 1;
 * }
 *
 * int handle_record(dbf_file_t *fh, const dbf_header_t *header,
 *                   const dbf_record_t *record, size_t file_offset) {
 *   mydata_t *mydata = (mydata_t *) fh->user_data;
 *   // Do something
 *   return 1;
 * }
 *
 * dbf_init_file(fh, stream, mydata)
 * rc = dbf_read(fh, handle_header, handle_record);
 * @endcode
 *
 * @param fh a file handle.
 * @param handle_header a function that is called for the file header.
 * @param handle_record a function that is called for each record.
 * @retval 1 on success.
 * @retval 0 on end of file.
 * @retval -1 on error.
 *
 * @see the "Xbase File Format Description" @cite Xbase_format for
 *      information on the file format.
 */
extern int dbf_read(dbf_file_t *fh, dbf_header_callback_t handle_header,
                    dbf_record_callback_t handle_record);

/**
 * Read the file header
 *
 * Reads the header from a file that has the file extension ".dbf".
 *
 * @param fh a file handle.
 * @param[out] pheader on sucess, a pointer to a dbf_header_t structure.
 *                     Free the header with @c free() when you are done.
 * @retval 1 on success.
 * @retval 0 on end of file.
 * @retval -1 on error.
 *
 * @see dbf_read_record
 */
extern int dbf_read_header(dbf_file_t *fh, dbf_header_t **pheader);

/**
 * Read a record
 *
 * Reads a record from a file that has the file extension ".dbf".
 *
 * @b Example
 *
 * @code{.c}
 * dbf_header_t *header;
 * dbf_record_t *record;
 *
 * if ((rc = dbf_read_header(fh, &header)) > 0) {
 *   while ((rc = dbf_read_record(fh, &record)) > 0) {
 *     // Do something
 *     free(record);
 *   }
 *   free(header);
 * }
 * @endcode
 *
 * @param fh a file handle.
 * @param[out] precord on sucess, a pointer to a dbf_record_t structure.
 *                     Free the record with @c free() when you are done.
 * @retval 1 on success.
 * @retval 0 on end of file.
 * @retval -1 on error.
 *
 * @see dbf_read_header
 */
extern int dbf_read_record(dbf_file_t *fh, dbf_record_t **precord);

/**
 * Read a record by record number
 *
 * Sets the file position to the specified record number and reads the
 * requested record.
 *
 * @b Example
 *
 * @code{.c}
 * size_t i;
 * dbf_header_t *header;
 * dbf_record_t *record;
 *
 * if ((rc = dbf_read_header(fh, &header)) > 0) {
 *   i = header->num_records;
 *   while (i-- > 0) {
 *     if ((rc = dbf_seek_record(fh, i, &record)) > 0) {
 *       // Do something
 *       free(record);
 *     }
 *   }
 *   free(header);
 * }
 * @endcode
 *
 * @param fh a file handle.
 * @param record_number a zero-based record number.
 * @param[out] precord on success, a pointer to a dbf_record_t structure.
 *                     Free the record with @c free() when you are done.
 * @retval 1 on success.
 * @retval 0 on end of file.
 * @retval -1 on error.
 */
extern int dbf_seek_record(dbf_file_t *fh, size_t file_offset,
                           dbf_record_t **precord);

#endif
