/* NATools - Package with parallel corpora tools
 * Copyright (C) 1998-2001  Djoerd Hiemstra
 * Copyright (C) 2002-2012  Alberto Simões
 *
 * This package is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#ifndef __STANDARD_H__
#define __STANDARD_H__

#include <NATools.h>

#include <stdio.h>
#include <sys/time.h>

/**
 * @file
 * @brief Utility functions header file
 */

/**
 * @brief NullWord identifier
 */
#define NULLWORD 1

/**
 * @brief Maximum sentence length (in words)
 */
#define MAXLEN 500

/**
 * @brief Hard delimiter definition
 *
 * @todo Check if this is really useful
 */
#define HARDDELIMITER L'@'

/**
 * @brief Soft delimiter (division of aligned sentences)
 */
#define SOFTDELIMITER L'$'

/**
 * @brief Calculates the maximum between two numbers
 */
#define max(a,b)    (((a) > (b)) ? (a) : (b))

/**
 * @brief Calculates the minimum between two numbers
 */
#define min(a,b)    (((a) < (b)) ? (a) : (b))

/**
 * @brief Time variable to store timer start value;
 */
extern struct timeval TIMER_BEFORE;

/**
 * @brief Time variable to store timer end value;
 */
extern struct timeval TIMER_AFTER;

/**
 * @brief Prints a warning message and starts the timer;
 */
#define START_TIMER   fprintf(stderr, "** TIMER START **\n"); gettimeofday(&TIMER_BEFORE, NULL)

/**
 * @brief Stops the timer and prints a warning message with the number
 * of elapsed seconds
 */
#define STOP_TIMER    gettimeofday(&TIMER_AFTER, NULL); fprintf(stderr,                  \
                                                "** TIMER STOP ** %.8f secs **\n", \
  	                ((double)TIMER_AFTER.tv_sec - (double)BEFORE.tv_sec) +           \
	                ((double)TIMER_AFTER.tv_usec - (double)BEFORE.tv_usec) / 1000000 )


void     report_error(const char *msg, ...);
wchar_t* chomp(wchar_t *str);

wchar_t* uppercase_dup(const wchar_t *str);
wchar_t* capital_dup(const wchar_t *str);

nat_boolean_t isCapital(const wchar_t* str);
nat_boolean_t isUPPERCASE(const wchar_t* str);

/**
 * @mainpage NATools Documentation
 *
 * These pages include documentation for the NATools C modules,
 * gerated automatically using DoxyGen. If you want to use the Perl
 * API you must refer to the Perl documentation files.
 *
 * Note that these pages document not only the modules (.c and .h file
 * pairs) but also main program algorithms. So not all documented
 * functions are usable outside those programs.
 *
 * @section NATools Library
 *
 * The current NATools library (libnatools) includes the following
 * modules:
 *
 * - Words  (see words.c and words.h)
 * - Corpus   (see corpus.c and corpus.h)
 * - Standard   (see standard.c and standard.h)
 * - InvIndex   (see invindex.c and invindex.h)
 * - Bucket   (see bucket.c and bucket.h)
 *
 */

#endif /* __STANDARD_H__ */
