/*
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#ifndef BAILOUT_H
#define BAILOUT_H

#ifdef __GNUC__
#if __GNUC__ > 2 || (__GNUC__ ==2 && __GNUC_MINOR__ >=5)
#define BAILOUT_NORETURN __attribute__((noreturn))
#endif
#endif
#ifndef BAILOUT_NORETURN
#define BAILOUT_NORETURN
#endif

#include "buffer.h"
extern buffer *bailout_buffer;

extern const char *flag_bailout_log_name;
extern int flag_bailout_log_pid;
extern int flag_bailout_fatal_begin;
extern const char *flag_bailout_fatal_string;

void warning(int erno, const char *s1, const char *s2, const char *s3,
        const char *s4);
void bailout(int erno, const char *s1, const char *s2, const char *s3,
        const char *s4) BAILOUT_NORETURN;
void oom(void) BAILOUT_NORETURN;
#define OOMSTRING2(x) #x
#define OOMSTRING(x) OOMSTRING2(x)
#define oom() \
  do { \
    xbailout(111,0,"out of memory in ",__FILE__," at line ", \
      OOMSTRING(__LINE__)); \
  } while(0)
void bailout_exit(int) BAILOUT_NORETURN;
void xbailout(int ecode, int erno, const char *s1, const char *s2, 
		const char *s3, const char *s4) BAILOUT_NORETURN;
void bailout_progname(const char *keep_this_string_in_place);

#undef BAILOUT_NORETURN
#endif
