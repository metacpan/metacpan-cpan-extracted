#ifndef DATE_H_
#define DATE_H_

/*
 * Given a date specification for a cookie expiration date,
 * compute the correct time_t.  Examples of date specs are:
 *
 *   "now"
 *   a number => epoch
 *   a string with "sign" "number" "type"
 *     sign can be + or -
 *     number is an offset
 *     type is y, M, d, h, m, s
 *     this will be added / subtracted to the current time
 */

#include "buffer.h"

double date_compute(const char *date, int len);

Buffer* date_format(double date, Buffer* format);

#endif
