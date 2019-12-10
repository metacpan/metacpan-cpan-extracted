#ifndef QXHASH_H
#define QXHASH_H

#include <stdint.h>
#include <stdlib.h>

#define QX_SHIFT 11
#define QX_WIDTH_IN_BITS 160
#define QX_WIDTH_IN_BYTES 20
#define QX_DATA_LENGTH 3

typedef struct {
  size_t   kDataLength;
  size_t   kShift;
  size_t   kWidthInBits;
  size_t   kWidthInBytes;
  size_t   lengthSoFar;
  size_t   shiftSoFar;
  uint64_t data[QX_DATA_LENGTH];
} QX;

typedef QX Digest__QuickXor__Hash;

QX* QX_new();

void QX_add(QX* pqx, uint8_t* addData, size_t addSize);

char* QX_b64digest(QX* pqx);

uint8_t* QX_digest(QX* pqx);

void QX_free(QX* pqx);

void QX_reset(QX* pqx);

#endif /* QXHASH_H */
