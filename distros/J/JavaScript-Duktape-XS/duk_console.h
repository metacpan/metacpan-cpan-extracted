#if !defined(DUK_CONSOLE_H_INCLUDED)
#define DUK_CONSOLE_H_INCLUDED

#include <stdarg.h>
#include "duktape.h"

#if defined(__cplusplus)
extern "C" {
#endif

/* Use a proxy wrapper to make undefined methods (console.foo()) no-ops. */
#define DUK_CONSOLE_PROXY_WRAPPER  (1 << 0)

/* Flush output after every call. */
#define DUK_CONSOLE_FLUSH          (1 << 1)

/* Send output to stdout. */
#define DUK_CONSOLE_TO_STDOUT      (1 << 2)

/* Send output to stderr. */
#define DUK_CONSOLE_TO_STDERR      (1 << 3)

/* The console handler prototype */
typedef int (ConsoleHandler)(duk_uint_t flags, void* data,
                             const char* fmt, va_list ap);

/* Initialize the console system */
extern void duk_console_init(duk_context *ctx, duk_uint_t flags);

/* Register a console handler */
extern void duk_console_register_handler(ConsoleHandler* handler, void* data);

/* Public function to log messages, callable from C */
extern int duk_console_log(duk_uint_t flags, const char* fmt, ...);

#if defined(__cplusplus)
}
#endif  /* end 'extern "C"' wrapper */

#endif  /* DUK_CONSOLE_H_INCLUDED */
