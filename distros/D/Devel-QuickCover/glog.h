#ifndef GLOG_H_
#define GLOG_H_

/*
 * A set of macros / functions to log messages.
 *
 * When compiling with GLOG_SHOW defined, the messages are shown; when it is
 * undefined, the messages AND the calls to the macros disappear from the
 * file, thus incurring no runtime cost.
 *
 * When logging, a newline is automatically added to each line.
 *
 * The GLOG macro must be called with double parenthesis.  For example:
 *
 *   GLOG(("My name is [%s]", name));
 */

#include <stdio.h>

#ifndef GLOG_SHOW

#define GLOG(args)

#else

#define GLOG(args) glog args

#endif

void glog(const char* fmt, ...);

#endif
