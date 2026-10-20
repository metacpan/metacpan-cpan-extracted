/*
 * sha_hw.h - SHA-1 and SHA-256 through the CPU's SHA instructions, when the
 * CPU has them. Each returns a function that compresses n whole blocks into
 * the state, or NULL when this CPU or this build cannot.
 */
#ifndef FILE_RAW_HASH_SHA_HW_H
#define FILE_RAW_HASH_SHA_HW_H

#include <stddef.h>
#include <stdint.h>

typedef void (*frh_blocks32_fn)(uint32_t *state, const unsigned char *p, size_t nblocks);

frh_blocks32_fn frh_hw_sha256_blocks(void);
frh_blocks32_fn frh_hw_sha1_blocks(void);

/* The name of the path the functions above return ("armv8"). */
const char *frh_hw_name(void);

#endif
