#ifndef COOKIE_H_
#define COOKIE_H_

/*
 * Manage a cookie buffer, where the caller can put different
 * values (strings, dates, integers, booleans) and also
 * parse the string back into its separate values.
 */

#include "buffer.h"

Buffer* cookie_put_string(Buffer* cookie,
                          const char* name, int nlen,
                          const char* value, int vlen,
                          int enc_nam, int enc_val);
Buffer* cookie_put_date(Buffer* cookie,
                        const char* name, int nlen,
                        const char* value, int vlen);
Buffer* cookie_put_integer(Buffer* cookie,
                          const char* name, int nlen,
                          long value);
Buffer* cookie_put_boolean(Buffer* cookie,
                          const char* name, int nlen,
                          int value);

int cookie_get_pair(Buffer* cookie,
                    Buffer* name, Buffer* value);

#endif
