#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

unsigned char paethPredictor(unsigned char a, unsigned char b, unsigned char c) {
  unsigned int p = a + b - c;
  unsigned int pa = abs((int)(p - a));
  unsigned int pb = abs((int)(p - b));
  unsigned int pc = abs((int)(p - c));

  if (pa <= pb && pa <= pc)
    return a;

  if (pb <= pc)
    return b;

  return c;
}

void filterRowNone(unsigned char* src, unsigned char* dst, size_t row, size_t bytes) {
  return;
}

void filterRowSub(unsigned char* src, unsigned char* dst, size_t row, size_t pwidth, size_t bytes) {
  size_t xix = row * bytes + 1;
  size_t aix = xix;
  xix += pwidth;
  while (xix < (row+1)*bytes)
    dst[xix++] -= src[aix++];
}

void filterRowUp(unsigned char* src, unsigned char* dst, size_t row, size_t pwidth, size_t bytes) {
  size_t xix = row * bytes + 1;
  size_t bix = xix - bytes;
  if (row == 0)
    return;
  while (xix < (row+1)*bytes)
    dst[xix++] -= src[bix++];
}

void filterRowAvg(unsigned char* src, unsigned char* dst, size_t row, size_t pwidth, size_t bytes) {
  size_t xix = row * bytes + 1;
  size_t bix = xix - bytes;
  size_t aix;

  if (row == 0) {
    size_t aix = xix;
    xix += pwidth;
    while (xix < (row+1)*bytes)
      dst[xix++] -= src[aix++] >> 1;
    return;
  }

  aix = xix;
  for (; pwidth > 0; --pwidth)
    dst[xix++] -= src[bix++] >> 1;
  
  while (xix < (row+1)*bytes)
    dst[xix++] -= (src[aix++] + src[bix++]) >> 1;
}

void filterRowPaeth(unsigned char* src, unsigned char* dst, size_t row, size_t pwidth, size_t bytes) {
  size_t xix = row * bytes + 1;
  size_t bix = xix - bytes;
  size_t aix, cix;

  if (row == 0) {
    size_t aix = xix;
    xix += pwidth;
    while (xix < (row+1)*bytes)
      dst[xix++] -= paethPredictor(src[aix++], 0 , 0);
    return;
  }

  aix = xix;
  cix = aix - bytes;

  for (; pwidth > 0; --pwidth)
    dst[xix++] -= paethPredictor(0, src[bix++] , 0);
  
  while (xix < (row+1)*bytes)
    dst[xix++] -= paethPredictor(src[aix++], src[bix++], src[cix++]);
}

void unFilterRowNone(unsigned char* idat, size_t row, size_t bytes) {
  return;
}

void unFilterRowSub(unsigned char* idat, size_t row, size_t pwidth, size_t bytes) {
  size_t xix = row * bytes + 1;
  size_t aix = xix;
  xix += pwidth;
  while (xix < (row+1)*bytes)
    idat[xix++] += idat[aix++];
}

void unFilterRowUp(unsigned char* idat, size_t row, size_t pwidth, size_t bytes) {
  size_t xix = row * bytes + 1;
  size_t bix = xix - bytes;
  if (row == 0)
    return;
  while (xix < (row+1)*bytes)
    idat[xix++] += idat[bix++];
}

void unFilterRowAvg(unsigned char* idat, size_t row, size_t pwidth, size_t bytes) {
  size_t xix = row * bytes + 1;
  size_t bix = xix - bytes;
  size_t aix;

  if (row == 0) {
    size_t aix = xix;
    xix += pwidth;
    while (xix < (row+1)*bytes)
      idat[xix++] += idat[aix++] >> 1;
    return;
  }

  aix = xix;
  for (; pwidth > 0; --pwidth)
    idat[xix++] += idat[bix++] >> 1;
  
  while (xix < (row+1)*bytes)
    idat[xix++] += (idat[aix++] + idat[bix++]) >> 1;
}

void unFilterRowPaeth(unsigned char* idat, size_t row, size_t pwidth, size_t bytes) {
  size_t xix = row * bytes + 1;
  size_t bix = xix - bytes;
  size_t aix, cix;

  if (row == 0) {
    size_t aix = xix;
    xix += pwidth;
    while (xix < (row+1)*bytes)
      idat[xix++] += paethPredictor(idat[aix++], 0 , 0);
    return;
  }

  aix = xix;
  cix = aix - bytes;

  for (; pwidth > 0; --pwidth)
    idat[xix++] += paethPredictor(0, idat[bix++] , 0);
  
  while (xix < (row+1)*bytes)
    idat[xix++] += paethPredictor(idat[aix++], idat[bix++] , idat[cix++]);
}

void unFilterIdat(unsigned char* idat, size_t rows, size_t pwidth, size_t bytes) {
  size_t row;
  for (row = 0; row < rows; ++row) {
    switch(idat[row*bytes]) {
    case 0:
      break;
    case 1:
      unFilterRowSub(idat, row, pwidth, bytes);
      break;
    case 2:
      unFilterRowUp(idat, row, pwidth, bytes);
      break;
    case 3:
      unFilterRowAvg(idat, row, pwidth, bytes);
      break;
    case 4:
      unFilterRowPaeth(idat, row, pwidth, bytes);
      break;
    default:
      croak("bad filter type");
    }
    idat[row*bytes] = 0;
  }
}

void filterIdat(unsigned char* src, unsigned char* dst, unsigned char* filter, size_t rows, size_t pwidth, size_t bytes) {
  size_t row;
  for (row = 0; row < rows; ++row) {
    switch(filter[row]) {
    case 0:
      break;
    case 1:
      filterRowSub(src, dst, row, pwidth, bytes);
      break;
    case 2:
      filterRowUp(src, dst, row, pwidth, bytes);
      break;
    case 3:
      filterRowAvg(src, dst, row, pwidth, bytes);
      break;
    case 4:
      filterRowPaeth(src, dst, row, pwidth, bytes);
      break;
    default:
      croak("bad filter type");
    }
    dst[row*bytes] = filter[row];
  }
}


MODULE = Image::PNG::Rewriter PACKAGE = Image::PNG::Rewriter

void
_unfilter(idat, rows, pwidth, bytes)
    unsigned char* idat
    size_t rows
    size_t pwidth
    size_t bytes
  CODE:
    unFilterIdat(idat, rows, pwidth, bytes);

void
_filter(src, dst, filters, rows, pwidth, bytes)
    unsigned char* src
    unsigned char* dst
    unsigned char* filters
    size_t rows
    size_t pwidth
    size_t bytes
  CODE:
    filterIdat(src, dst, filters, rows, pwidth, bytes);
