#ifndef BUFFER_H_
#define BUFFER_H_

/*
 * An implementation of a byte buffer with the following characteristics:
 *
 * + Can be used to wrap an existing char* and give it the semantics of
 *   a buffer.
 * + Can be used a a newly allocated memory buffer; if the needed size is
 *   small (see below), it will use a stack array and will not allocate
 *   any memory.
 * + Can grow as needed, using realloc (and moving the data from the stack
 *   array if needed).
 */

#include "gmem.h"

/*
 * How big we want our struct to be, total size, in bytes.
 */
#define BUFFER_SIZEOF_DESIRED 64

/*
 * How big we want the buffer to be, at least.
 */
#define BUFFER_SIZE_INIT   64

/*
 * By how much we multiply a size.
 */
#define BUFFER_SIZE_FACTOR 2

/*
 * Definition for a Buffer. Fields are:
 *
 * + rpos: current reading position in buffer
 * + wpos: current writing position in buffer
 * + size: maximum size for buffer
 * + data: pointer to the underlying memory
 * + fixed: array for small buffers, whose size is adjusted so that
 *          it will make the Buffer be BUFFER_SIZEOF_DESIRED bytes.
 */
typedef struct Buffer {
    unsigned int rpos;
    unsigned int wpos;
    unsigned int size;
    unsigned int unused_;  /* padding for allignment */
    char* data;
    char fixed[  BUFFER_SIZEOF_DESIRED
               - 4*sizeof(unsigned int)
               - 1*sizeof(char*) ];
} Buffer;

/*
 * The whole API is implemented as macros, for performance purposes.
 */

/*
 * Initialize / finalize a buffer that could either use the
 * internal stack array or dynamically allocate memory.
 */
#define buffer_init(buffer, length) \
    do { \
        unsigned int target = (length) > 0 ? ((length)+1) : BUFFER_SIZE_INIT; \
        buffer_zero(buffer); \
        if ((length) > sizeof((buffer)->fixed)) { \
            target = BUFFER_SIZE_INIT; \
            while (target < (length)) { \
                target *= BUFFER_SIZE_FACTOR; \
            } \
            (buffer)->size = target; \
            GMEM_NEW((buffer)->data, char, target); \
        } else { \
            (buffer)->size = sizeof((buffer)->fixed); \
            (buffer)->data = (buffer)->fixed; \
        } \
        buffer_reset(buffer); \
    } while (0)

#define buffer_fini(buffer) \
    do { \
        if ((buffer)->data && \
            (buffer)->data != (buffer)->fixed) { \
            GMEM_DEL((buffer)->data, char, (buffer)->size); \
        } \
        buffer_zero(buffer); \
    } while (0)

/*
 * Wrap an existing char* to be used as a buffer.
 * NOTE: a wrapped buffer's size does not include the null terminator.
 */
#define buffer_wrap(buffer, src, length) \
    do { \
        buffer_zero(buffer); \
        (buffer)->size = (buffer)->wpos = (length); \
        (buffer)->data = (char*) src; \
    } while (0)

/*
 * Bytes still to be read.
 */
#define buffer_used(buffer) \
    ( (buffer)->wpos - (buffer)->rpos )

/*
 * Zero out buffer.
 */
#define buffer_zero(buffer) \
    do { \
        (buffer)->size = 0; \
        (buffer)->rpos = 0; \
        (buffer)->wpos = 0; \
        (buffer)->data = 0; \
    } while (0)

/*
 * Set buffer reading position to 0.
 */
#define buffer_rewind(buffer) \
    do { \
        (buffer)->rpos = 0; \
    } while (0)

/*
 * Set buffer writing position to 0.
 */
#define buffer_reset(buffer) \
    do { \
        buffer_rewind(buffer); \
        (buffer)->wpos = 0; \
    } while (0)

/*
 * Append a given char*, with indicated length, to the buffer.
 * If necessary, grow the buffer before appending.
 */
#define buffer_append_str(buffer, src, length) \
    do { \
        unsigned int l = (length); \
        buffer_ensure_unused(buffer, l); \
        memcpy((buffer)->data + (buffer)->wpos, src, l); \
        (buffer)->wpos += l; \
    } while (0)

/*
 * Append a given Buffer to the buffer.
 * If necessary, grow the buffer before appending.
 */
#define buffer_append_buf(buffer, src) \
    do { \
        unsigned int l = (src)->wpos - (src)->rpos; \
        buffer_ensure_unused(buffer, l); \
        memcpy((buffer)->data + (buffer)->wpos, (src)->data + (src)->rpos, l); \
        (buffer)->wpos += l; \
        (src)->rpos += l; \
    } while (0)

/*
 * Make sure the unused space in the buffer is at least size.
 */
#define buffer_ensure_unused(buffer, length) \
    do { \
        unsigned int needed = (length) + 1; \
        unsigned int left = (buffer)->size - (buffer)->wpos; \
        if (left < needed) { \
            buffer_ensure_total((buffer), (buffer)->wpos + (length)); \
        } \
    } while (0)

/*
 * Make sure the total size of the buffer is at least size.
 */
#define buffer_ensure_total(buffer, length) \
    do { \
        unsigned int needed = (length) + 1; \
        if ((buffer)->size < needed) { \
            unsigned int target = BUFFER_SIZE_INIT; \
            while (target < needed) { \
                target *= BUFFER_SIZE_FACTOR; \
            } \
            if ((buffer)->data == (buffer)->fixed) { \
                GMEM_NEW((buffer)->data, char, target); \
                memcpy((buffer)->data, (buffer)->fixed, (buffer)->size); \
            } else { \
                GMEM_REALLOC((buffer)->data, char, (buffer)->size, target); \
            } \
            (buffer)->size = target; \
        } \
    } while (0)

#endif
