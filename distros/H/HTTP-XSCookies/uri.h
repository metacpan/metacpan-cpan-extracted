#ifndef URI_H_
#define URI_H_

/*
 * Routines to URI encode and decode a string efficiently.
 */

#include "buffer.h"

Buffer* url_decode(Buffer* src, int length,
                   Buffer* tgt);

Buffer* url_encode(Buffer* src, int length,
                   Buffer* tgt);

#endif
