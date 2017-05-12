/*
 * Perl XS for the Digest::Murmur Module
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <string.h>
#include <stdint.h>

U32
murmur_hash(char *data, size_t len) {
  const uint32_t m  =  0x5bd1e995;
  const uint8_t r   =  16;
  uint32_t length   =  len;
  uint32_t h        =  length * m;

  while (length >= 4) {
    h += *(unsigned int *)data;
    h *= m;
    h ^= h >> r;
    data += 4;
    length -= 4;
  }

  switch (length) {
    case 3:
      h += data[2] << 16;
    case 2:
      h += data[1] << 8;
    case 1:
      h += data[0];
      h *= m;
      h ^= h >> r;
  }

  h *= m;
  h ^= h >> 10;
  h *= m;
  h ^= h >> 17;

  return h;
}

MODULE = Digest::MurmurHash	PACKAGE = Digest::MurmurHash		

U32 murmur_hash(char *data, size_t length(data))
