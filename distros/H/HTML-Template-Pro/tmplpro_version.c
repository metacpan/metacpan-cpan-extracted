/* -*- c -*- 
 * File: tmplpro_version.c
 * Author: Igor Vlasenko <vlasenko@imath.kiev.ua>
 * Created: Mon Jul 13 21:24:55 2009
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifndef PACKAGE_VERSION
 #ifdef VERSION
#define PACKAGE_VERSION VERSION
 #else
#define PACKAGE_VERSION "0.0(not defined)"
 #endif
#endif

/*************************************************
*          Return version string                 *
*************************************************/

/* These macros are the standard way of turning unquoted text into C strings.
They allow macros like PCRE_MAJOR to be defined without quotes, which is
convenient for user programs that want to test its value. */

#define STRING(a)  # a
#define XSTRING(s) STRING(s)

const char* tmplpro_version(void) {
  //return "" XSTRING(PACKAGE_VERSION) ;
  return "" PACKAGE_VERSION ;
}

/*
 *  Local Variables:
 *  mode: c
 *  End:
 */
