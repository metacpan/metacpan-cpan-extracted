#include "glog.h"

#ifndef GLOG_SHOW

void glog(const char* fmt, ...)
{
}

#else

#include <stdarg.h>
#include <stdio.h>
#include <unistd.h>

void glog(const char* fmt, ...)
{
  va_list args;
  va_start(args, fmt);
  fprintf(stderr, "{%lu} ", (unsigned long) getpid());
  vfprintf(stderr, fmt, args);
  fputc('\n', stderr);
  fflush(stderr);
  va_end(args);
}

#endif
