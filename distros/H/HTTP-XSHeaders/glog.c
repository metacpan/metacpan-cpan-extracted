#include <stdarg.h>
#include <stdio.h>
#include "glog.h"

#ifndef GLOG_SHOW

void glog(const char* fmt, ...) {
}

#else

void glog(const char* fmt, ...) {
  va_list args;
  va_start(args, fmt);
  vfprintf(stderr, fmt, args);
  fputc('\n', stderr);
  va_end(args);
}

#endif
