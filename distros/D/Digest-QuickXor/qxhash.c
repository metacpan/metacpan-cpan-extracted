/*
 * libquickxor - QuickXorHash Library
 *
 * © 2019 by Tekki (Rolf Stöckli)
 *
 * The original C# algorithm was published by Microsoft under the following copyright:
 *
 *   Copyright (c) 2016 Microsoft Corporation
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, andor sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 *
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 *
 */

#include <stdio.h>
#include <string.h>
#include "qxhash.h"
#include "base64.h"

QX* QX_new() {
  QX* pqx = NULL;

  pqx = calloc(1, sizeof(QX));
  if (pqx) {
    pqx->kDataLength   = QX_DATA_LENGTH;
    pqx->kShift        = QX_SHIFT;
    pqx->kWidthInBits  = QX_WIDTH_IN_BITS;
    pqx->kWidthInBytes = QX_WIDTH_IN_BYTES;
  }

  return pqx;
}

void QX_add(QX* pqx, uint8_t* addData, size_t addSize) {
  // the bitvector where we'll start xoring
  size_t vectorArrayIndex = pqx->shiftSoFar / 64;

  // the position within the bit vector at which we begin xoring
  int    vectorOffset = pqx->shiftSoFar % 64;
  size_t iterations   = addSize > pqx->kWidthInBits ? pqx->kWidthInBits : addSize;

  for (size_t i = 0; i < iterations; ++i) {
    size_t nextCell         = vectorArrayIndex + 1;
    int    bitsInVectorCell = 64;
    if (nextCell == pqx->kDataLength) {
      nextCell = 0;
      if (pqx->kWidthInBits % 64 > 0) {
        bitsInVectorCell = pqx->kWidthInBits % 64;
      }
    }

    uint8_t xoredByte = 0x0;
    for (size_t j = i; j < addSize; j += pqx->kWidthInBits) {
      xoredByte ^= addData[j];
    }

    pqx->data[vectorArrayIndex] ^= ((uint64_t)xoredByte) << vectorOffset;

    if (vectorOffset > bitsInVectorCell - 8) {
      pqx->data[nextCell] ^= ((uint64_t)xoredByte) >> (bitsInVectorCell - vectorOffset);
    }

    vectorOffset += pqx->kShift;
    if (vectorOffset >= bitsInVectorCell) {
      vectorArrayIndex = nextCell;
      vectorOffset -= bitsInVectorCell;
    }
  }

  // update the starting position in a circular shift pattern
  pqx->shiftSoFar += pqx->kShift * (addSize % pqx->kWidthInBits);
  pqx->shiftSoFar %= pqx->kWidthInBits;
  pqx->lengthSoFar += addSize;
}

char* QX_b64digest(QX* pqx) {
  uint8_t* digest = NULL;
  size_t   hashSize;
  char*    hash = NULL;

  digest   = QX_digest(pqx);
  hashSize = 2 * pqx->kWidthInBytes;
  hash     = calloc(1, hashSize);

  if (digest && hash) {
    B64_encode(digest, pqx->kWidthInBytes, hash, hashSize);
  }

  free(digest);
  digest = NULL;

  return hash;
}

uint8_t* QX_digest(QX* pqx) {
  uint8_t* digest       = NULL;
  uint8_t* digestLength = NULL;
  size_t   lengthSize   = sizeof(pqx->lengthSoFar);

  // create a byte array big enough to hold all our data
  digest = calloc(1, pqx->kWidthInBytes);

  if (digest) {
    // block copy all our bitvectors to this byte array
    memcpy(digest, pqx->data, pqx->kWidthInBytes);
    digestLength = calloc(1, lengthSize);
    if (digestLength) {
      // xor the file length with the least significant bits
      memcpy(digestLength, &pqx->lengthSoFar, lengthSize);

      for (size_t i = 0; i < lengthSize; ++i) {
        digest[pqx->kWidthInBytes - lengthSize + i] ^= digestLength[i];
      }

      free(digestLength);
      digestLength = NULL;
    }
  }

  return digest;
}

int QX_readFile(QX* pqx, char* filename) {
  int status = 1;
  if (pqx && strlen(filename)) {
    FILE* pFile = NULL;
    pFile       = fopen(filename, "rb");
    if (pFile) {
      uint8_t buf[4096];
      size_t  len;

      QX_reset(pqx);
      while ((len = fread(buf, 1, 4096, pFile)) > 0) {
        QX_add(pqx, buf, len);
      }
      fclose(pFile);

      status = 0;
    }
  }
  return status;
}

void QX_free(QX*pqx) {
  if (pqx) {
    free(pqx);
  }
}

void QX_reset(QX* pqx) {
  if (pqx) {
    memset(pqx->data, 0, QX_DATA_LENGTH * sizeof(uint64_t));
    pqx->lengthSoFar = 0;
    pqx->shiftSoFar  = 0;
  }
}
