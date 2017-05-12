/* Creation date: 2008-12-03T12:59:26Z
 * Authors: Don
 */

#ifndef _JSONEVT_PRINT_H_INCLUDED
#define _JSONEVT_PRINT_H_INCLUDED

#include <stdarg.h>

int js_vasprintf(char **ret, const char *fmt, va_list *ap_ptr);
int js_asprintf(char ** ret, const char * fmt, ...);

#endif
