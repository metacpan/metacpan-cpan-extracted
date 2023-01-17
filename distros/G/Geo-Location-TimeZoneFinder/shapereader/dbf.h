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

#include <stdint.h>
#include <stdio.h>
#include <time.h>

/**
 * Versions
 */
typedef enum dbf_version_t {
    DBFV_DBASE2 = 0x02,                  /**< dBase II */
    DBFV_DBASE3 = 0x03,                  /**< dBase III */
    DBFV_DBASE4 = 0x04,                  /**< dBase IV */
    DBFV_DBASE5 = 0x05,                  /**< dBase V */
    DBFV_VISUAL_OBJECTS = 0x07,          /**< Visual Objects */
    DBFV_VISUAL_FOXPRO = 0x30,           /**< Visual FoxPro */
    DBFV_VISUAL_FOXPRO_AUTO = 0x31,      /**< Visual FoxPro with
                                              Autoincrement field */
    DBFV_VISUAL_FOXPRO_VARIFIELD = 0x32, /**< Visual FoxPro with Varchar or
                                              Varbinary field */
    DBFV_DBASE3_MEMO = 0x83,             /**< dBase III with memo file */
    DBFV_VISUAL_OBJECTS_MEMO = 0x87,     /**< Visual Objects with memo file */
    DBFV_DBASE4_MEMO = 0x8b,             /**< dBase IV with memo file */
    DBFV_DBASE7 = 0x8c,                  /**< dBase 7 */
    DBFV_FOXPRO_MEMO = 0xf5,             /**< FoxPro with memo file */
} dbf_version_t;

/**
 * Field types
 */
typedef enum dbf_type_t {
    DBFT_AUTOINCREMENT = '+',    /**< Autoincrement (4 bytes) */
    DBFT_BINARY_OR_DOUBLE = 'B', /**< Binary (integer stored as a string) or
                                      Double (8 bytes) in FoxPro */
    DBFT_BLOB = 'W',             /**< Blob (integer stored as a string) */
    DBFT_CHARACTER = 'C',        /**< String */
    DBFT_CURRENCY = 'Y',         /**< Decimal number (8 bytes) */
    DBFT_DATE = 'D',             /**< Date (stored as "YYYYMMDD") */
    DBFT_DATETIME = 'T',         /**< Date and time (8 bytes) */
    DBFT_DOUBLE = 'O',           /**< Double (8 bytes) */
    DBFT_FLOAT = 'F',            /**< Number (stored as a string) */
    DBFT_GENERAL = 'G',          /**< OLE (integer stored as a string) */
    DBFT_INTEGER = 'I',          /**< Integer (4 bytes) */
    DBFT_LOGICAL = 'L',          /**< Logical (1 byte) */
    DBFT_MEMO = 'M',             /**< Memo (integer stored as a string) */
    DBFT_NULLFLAGS = '0',        /**< _NullFlags (bytes) */
    DBFT_NUMBER = 'N',           /**< Number (stored as a string) */
    DBFT_PICTURE = 'P',          /**< Picture (integer stored as a string) */
    DBFT_TIMESTAMP = '@',        /**< Timestamp (8 bytes) */
    DBFT_VARBINARY = 'Q',        /**< Varbinary */
    DBFT_VARCHAR = 'V',          /**< Varchar */
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
    size_t _size;               /* Size in bytes */
    size_t _offset;             /* Position in the record buffer */
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
    char *_bytes; /* Raw data of length record_size */
} dbf_record_t;

/**
 * Get bytes.
 *
 * Gets the bytes and the number of bytes from a field in a record.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param[out] pbytes a pointer to the bytes.
 * @param[out] plen the number of bytes.
 */
extern void dbf_record_bytes(const dbf_record_t *record,
                             const dbf_field_t *field, const char **pbytes,
                             size_t *plen);

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
 * @param[out] ptm a tm structure.
 * @return true on success, otherwise false.
 */
extern int dbf_record_date(const dbf_record_t *record,
                           const dbf_field_t *field, struct tm *ptm);

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
 * @param[out] ptm a tm structure.
 * @return true on success, otherwise false.
 */
extern int dbf_record_datetime(const dbf_record_t *record,
                               const dbf_field_t *field, struct tm *ptm);

/**
 * Get a double value
 *
 * Gets a floating-point number from a double field.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param[out] pvalue the double value.
 * @return true on success, otherwise false.
 */
extern int dbf_record_double(const dbf_record_t *record,
                             const dbf_field_t *field, double *pvalue);

/**
 * Get a 32-bit integer value
 *
 * Gets an integer from an integer or auto-increment field.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param[out] pvalue the unscaled value.
 * @return true on success, otherwise false.
 */
extern int dbf_record_int32(const dbf_record_t *record,
                            const dbf_field_t *field, int32_t *pvalue);

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
 * @param[out] pvalue the unscaled value.
 * @return true on success, otherwise false.
 */
extern int dbf_record_int64(const dbf_record_t *record,
                            const dbf_field_t *field, int64_t *pvalue);

/**
 * Check if a record is deleted.
 *
 * Returns true if the record is marked as deleted.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @return true if the record is deleted, otherwise false.
 */
extern int dbf_record_is_deleted(const dbf_record_t *record);

/**
 * Check if a field is null.
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
 * Get a logical value.
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
 * Check if a logical value is false.
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
 * Check if a logical value is true.
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
 * Duplicate a string.
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
 * Get a string.
 *
 * Gets a string and its length.  The string is not null-terminated and not
 * decoded to UTF-8.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param[out] pstr a pointer to the string.
 * @param[out] plen the length.
 */
extern void dbf_record_string(const dbf_record_t *record,
                              const dbf_field_t *field, const char **pstr,
                              size_t *plen);

/**
 * Convert a string to double representation.
 *
 * Converts a numeric string to a floating-point number.  Fails if the string
 * does not contain a number.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param[out] pvalue the converted value.
 * @return true on success, otherwise false.
 */
extern int dbf_record_strtod(const dbf_record_t *record,
                             const dbf_field_t *field, double *pvalue);

/**
 * Convert a string to a long integer.
 *
 * Converts a numeric string to a long integer.  Fails if the string does not
 * contain a number with no decimal places.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param base 10 for decimal.  See strtol(3) for details.
 * @param[out] pvalue the converted value.
 * @return true on success, otherwise false.
 */
extern int dbf_record_strtol(const dbf_record_t *record,
                             const dbf_field_t *field, int base,
                             long *pvalue);

/**
 * Convert a string to long double representation.
 *
 * Converts a numeric string field to a floating-point number.  Fails if the
 * string does not contain a number.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param[out] pvalue the converted value.
 * @return true on success, otherwise false.
 */
extern int dbf_record_strtold(const dbf_record_t *record,
                              const dbf_field_t *field, long double *pvalue);

/**
 * Convert a string to a long long integer.
 *
 * Converts a numeric string to a long long integer.  Fails if the string
 * does not contain a number with no decimal places.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param base 10 for decimal.  See strtol(3) for details.
 * @param[out] pvalue the converted value.
 * @return true on success, otherwise false.
 */
extern int dbf_record_strtoll(const dbf_record_t *record,
                              const dbf_field_t *field, int base,
                              long long *pvalue);

/**
 * Convert a string to an unsigned long integer.
 *
 * Converts a numeric string to an unsigned long integer.  Fails if the
 * string does not contain a non-negative number with no decimal places.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param base 10 for decimal.  See strtoul(3) for details.
 * @param[out] pvalue the converted value.
 * @return true on success, otherwise false.
 */
extern int dbf_record_strtoul(const dbf_record_t *record,
                              const dbf_field_t *field, int base,
                              unsigned long *pvalue);

/**
 * Convert a string to an unsigned long long integer.
 *
 * Converts a numeric string to an unsigned long long integer.  Fails if the
 * string does not contain a non-negative number with no decimal places.
 *
 * @memberof dbf_record_t
 * @param record a record.
 * @param field a field in the record.
 * @param base 10 for decimal.  See strtoul(3) for details.
 * @param[out] pvalue the converted value.
 * @return true on success, otherwise false.
 */
extern int dbf_record_strtoull(const dbf_record_t *record,
                               const dbf_field_t *field, int base,
                               unsigned long long *pvalue);

/**
 * File handle
 */
typedef struct dbf_file_t {
    FILE *fp;            /**< File pointer */
    void *user_data;     /**< Callback data */
    size_t num_bytes;    /**< Number of bytes read */
    char error[1024];    /**< Error message */
    size_t _record_size; /* Record size from the file header */
} dbf_file_t;

/**
 * Initialize a file handle
 *
 * Initializes a dbf_file_t structure.
 *
 * @param fh an uninitialized file handle.
 * @param fp a file pointer.
 * @param user_data callback data or NULL.
 * @return the initialized file handle.
 */
extern dbf_file_t *dbf_file(dbf_file_t *fh, FILE *fp, void *user_data);

/**
 * Set an error message.
 *
 * Formats and sets an error message.
 *
 * @param fh a file handle.
 * @param format a printf format string followed by a variable number of
 *               arguments.
 */
extern void dbf_error(dbf_file_t *fh, const char *format, ...);

/**
 * Handle the file header.
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
 * Handle a record.
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
 * Read a data file.
 *
 * Reads files that have the file extension ".dbf" and calls functions for the
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
 * @see the "Xbase File Format Description" @cite Xbase_format for
 *      information on the file format.
 */
extern int dbf_read(dbf_file_t *fh, dbf_header_callback_t handle_header,
                    dbf_record_callback_t handle_record);

/**
 * Read the file header.
 *
 * Reads the header from files that have the file extension ".dbf".
 *
 * @param fh a file handle.
 * @param[out] pheader on sucess, a pointer to a dbf_header_t structure.
 *                     Free the header with @c free() when you are done.
 * @retval 1 on success.
 * @retval 0 on end of file.
 * @retval -1 on error.
 */
extern int dbf_read_header(dbf_file_t *fh, dbf_header_t **pheader);

/**
 * Read a record.
 *
 * Reads a record from files that have the file extension ".dbf".
 *
 * @param fh a file handle.
 * @param[out] precord on sucess, a pointer to a dbf_record_t structure.
 *                     Free the record with @c free() when you are done.
 * @retval 1 on success.
 * @retval 0 on end of file.
 * @retval -1 on error.
 */
extern int dbf_read_record(dbf_file_t *fh, dbf_record_t **precord);

#endif
