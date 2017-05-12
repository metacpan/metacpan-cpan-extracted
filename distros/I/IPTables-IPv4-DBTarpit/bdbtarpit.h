/*	bdbtarpit.h	*/

/* ****************************************************************************	*
 *										*
 *   Portions of this program were adapted from BerkeleyDB-0.20			*
 *   and BerkeleyDB-0.31 by Paul Marquess, Copyright (c) 1997-2004.		*
 *										*
 *     All rights reserved. This program is free software; you can 		*
 *     redistribute it and/or modify it under the same terms as Perl		*
 *     itself.									*
 *										*
 *   Copyright 2003 - 2007, Michael Robinton <michael@bizsystems.com>		*
 *										*
 *   This program is free software; you can redistribute it and/or modify       *
 *   it under the same terms as Perl itself.					*
 *										*
 * **************************************************************************** *
 */

#define DBTP_MAJOR      0
#define DBTP_MINOR      3
#define DBTP_PATCH      0
#define DBTP_DATE       "2-6-07"

/*
  So, libtool library versions are described by three integers:

  current
    The most recent interface number that this library implements.
  revision
    The implementation number of the current interface.
  age
    The difference between the newest and oldest interfaces that this
  library implements. In other words, the library implements all the
  interface numbers in the range from number current - age to current.

  If two libraries have identical current and age numbers, then the
  dynamic linker chooses the library with the greater revision number.

  Here are a set of rules to help you update your library version
  information:

  1.  Start with version information of 0:0' for each libtool library.
  
  2.  Update the version information only immediately before a public
      release of your software. More frequent updates are unnecessary, and 
      only guarantee that the current interface number gets larger faster.
  
  3.  If the library source code has changed at all since the last
      update, then increment revision (c:r:a becomes c:r+1:a').
  
  4.  If any interfaces have been added, removed, or changed since the
      last update, increment current, and set revision to 0.

  5.  If any interfaces have been added since the last public release,
      then increment age.

  6.  If any interfaces have been removed since the last public release,
      then set age to 0.
 */

#include <db.h>

#define DBTP_MAXdbf 10
typedef struct {
  int	  dberr;
  DB_ENV  * dbenv; 
  DBT     mgdbt;
  DBT     keydbt;
  DB      * dbaddr[DBTP_MAXdbf];
  char    * dbfile[DBTP_MAXdbf];
} DBTPD;

void dbtp_env_close(DBTPD * dbtp);
void dbtp_close(DBTPD * dbtp);
int dbtp_init(DBTPD * dbtp, unsigned char * home, int index);
int dbtp_get(DBTPD * dbtp, int ai, void * addr, size_t size);
int dbtp_getrecno(DBTPD * dbtp, int ai, u_int32_t cursor);
u_int32_t dbtp_stati(DBTPD * dbtp, int ai);
u_int32_t dbtp_statn(DBTPD * dbtp, char * name);
int dbtp_index(DBTPD * dbtp, char * name);
int dbtp_readOne(DBTPD * dbtp, u_char how, int ai, void * ptr, int is_network);
int dbtp_readDB(DBTPD * dbtp, u_char how, char * name, void * ptr, int is_network);
int dbtp_put(DBTPD * dbtp, int ai, void * addr, size_t asize, void * data, size_t dsize);
int dbtp_sync(DBTPD * dbtp, int ai);
int dbtp_find_addr(DBTPD * dbtp, int ai, void * addr, u_int32_t timestamp);
int dbtp_del(DBTPD * dbtp, int ai, void * addr, size_t size);
int dbtp_notfound();
char * dbtp_libversion(int * major, int * minor, int * patch);
char * dbtp_bdbversion(int * major, int * minor, int * patch);
char * dbtp_strerror(int err);

/* *******	Berkeley DB stuff			*******
 * *******	Check the version of Berkeley DB	*******
 * *******	adapted from BerkeleyDB-0.20		*******
 */

#ifndef DB_VERSION_MAJOR
#ifdef HASHMAGIC
#error db.h is from Berkeley DB 1.x - need at least Berkeley DB 2.6.4
#else
#error db.h is not for Berkeley DB at all.
#endif
#endif

#if (DB_VERSION_MAJOR == 2 && DB_VERSION_MINOR < 6) ||\
    (DB_VERSION_MAJOR == 2 && DB_VERSION_MINOR == 6 && DB_VERSION_PATCH < 4)
#  error db.h is from Berkeley DB 2.0-2.5 - need at least Berkeley DB 2.6.4 
#endif


#if (DB_VERSION_MAJOR == 3 && DB_VERSION_MINOR == 0)
#  define IS_DB_3_0_x
#endif

#if DB_VERSION_MAJOR >= 3
#  define AT_LEAST_DB_3  
#endif

#if DB_VERSION_MAJOR > 3 || (DB_VERSION_MAJOR == 3 && DB_VERSION_MINOR >= 1)
#  define AT_LEAST_DB_3_1
#endif

#if DB_VERSION_MAJOR > 3 || (DB_VERSION_MAJOR == 3 && DB_VERSION_MINOR >= 2)
#  define AT_LEAST_DB_3_2
#endif

#if DB_VERSION_MAJOR > 3 || \
    (DB_VERSION_MAJOR == 3 && DB_VERSION_MINOR > 2) ||\
    (DB_VERSION_MAJOR == 3 && DB_VERSION_MINOR == 2 && DB_VERSION_PATCH >= 6)
#  define AT_LEAST_DB_3_2_6
#endif

#if DB_VERSION_MAJOR > 3 || (DB_VERSION_MAJOR == 3 && DB_VERSION_MINOR >= 3)
#  define AT_LEAST_DB_3_3
#endif

#if DB_VERSION_MAJOR >= 4
#  define AT_LEAST_DB_4  
#endif

#if DB_VERSION_MAJOR > 4 || (DB_VERSION_MAJOR == 4 && DB_VERSION_MINOR >= 1)
#  define AT_LEAST_DB_4_1
#endif

#if DB_VERSION_MAJOR > 4 || (DB_VERSION_MAJOR == 4 && DB_VERSION_MINOR >= 2)
#  define AT_LEAST_DB_4_2
#endif

#if DB_VERSION_MAJOR > 4 || (DB_VERSION_MAJOR == 4 && DB_VERSION_MINOR >= 3)
#  define AT_LEAST_DB_4_3
#endif

#if DB_VERSION_MAJOR > 4 || (DB_VERSION_MAJOR == 4 && DB_VERSION_MINOR >= 4)
#  define AT_LEAST_DB_4_4
#endif

#if DB_VERSION_MAJOR > 4 || (DB_VERSION_MAJOR == 4 && DB_VERSION_MINOR >= 5)
#  define AT_LEAST_DB_4_5
#endif

/* END BerkeleyDB version	*/

