/*
 * sys/cygwin.h:37:extern int cygwin_conv_to_win32_path (const char *, char *);
 * sys/cygwin.h:38:extern int cygwin_conv_to_full_win32_path (const char *, char *);
 * sys/cygwin.h:39:extern int cygwin_conv_to_posix_path (const char *, char *);
 * sys/cygwin.h:40:extern int cygwin_conv_to_full_posix_path (const char *, char *);
 */

#include <sys/cygwin.h>
#ifndef MAX_PATH
#include <sys/param.h>
#   define MAX_PATH MAXPATHLEN
#endif


