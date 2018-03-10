#ifndef URI_H_
#define URI_H_

/*
 * Routines to URI encode and decode a string efficiently.
 */

#include "buffer.h"

Buffer* url_decode(Buffer* src, Buffer* tgt);
Buffer* url_encode(Buffer* src, Buffer* tgt);

#endif
