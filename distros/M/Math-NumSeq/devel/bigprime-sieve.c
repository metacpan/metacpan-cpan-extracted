/* Copyright 2021 Kevin Ryde

   This file is part of Math-NumSeq.

   Math-NumSeq is free software; you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3, or (at your option) any later
   version.

   Math-NumSeq is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
   more details.

   You should have received a copy of the GNU General Public License along
   with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.  */

#define WANT_ASSERT 1
#define WANT_DEBUG 0

#if ! WANT_ASSERT
#define NDEBUG
#endif

#define _FILE_OFFSET_BITS 64
#include <assert.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>

#if WANT_DEBUG
#define DEBUG(expr) do { expr; } while(0)
#else
#define DEBUG(expr)
#endif

const uint64_t limit = (uint64_t) 1 << 32;

#define BLOCKSIZE_BITS  28
#define BLOCKSIZE  (1<<BLOCKSIZE_BITS)
#define BLOCK_WORDLEN  (1 << (BLOCKSIZE_BITS - WORD_LOG))

const char filename[] = "/tmp/bigprime-sieve.data";

typedef unsigned WORD;
#define WORDSIZE  4 /*bytes */
#define WORDBITS  (8*WORDSIZE)
#define WORD_LOG  6
#define WORD_MASK  ((1<<WORD_LOG) - 1)

#define W_AND_BIT_ADD(w,bit, w2,bit2)   \
  do {                                  \
    (bit) += (bit2);                    \
    (w) += (w2) + ((bit) >> WORD_LOG);  \
    (bit) &= WORD_MASK;                 \
  } while (0)

#define W_AND_BIT_OF_N(w,bit, p)                \
  do {                                          \
    assert((p)&1);                              \
    uint64_t _W_AND_BIT_OF_PRIME__p = (p) >> 1; \
    (w)   = _W_AND_BIT_OF_PRIME__p >> WORD_LOG; \
    (bit) = _W_AND_BIT_OF_PRIME__p & WORD_MASK; \
  } while (0)


#define N_TO_BYTE_AND_BIT(n,byte,bit) \
  do {                                \
    (byte) = (n)>>4;                  \
    (bit) = ((n)>>1) & 7;             \
  } while (0)

int fd;
WORD *block = NULL;
off_t block_pos;
uint64_t block_w;

static void
ensure_block_w(off_t w)
{
  off_t want_byte = w << 2;
  off_t want_block_pos = want_byte & ((off_t) ~0 << BLOCKSIZE_BITS);
  /* DEBUG(printf("ensure byte %Lu want_block_pos %Lu vs block_pos %Lu\n", */
  /*              byte, want_block_pos, block_pos)); */
  if (block) {
    if (want_block_pos == block_pos) return;
    DEBUG(printf("unmap from %p\n", block));
    if (munmap(block, BLOCKSIZE) != 0) abort();
  }
  block_pos = want_block_pos;
  block = mmap(NULL, BLOCKSIZE, PROT_READ|PROT_WRITE, MAP_SHARED,
               fd, block_pos);
  DEBUG(printf("map at %p pos %Lu for byte %Ld\n", block, block_pos, byte));
  if (block == NULL) abort();
}
static void
set_bit(uint64_t n)
{
  off_t w;
  int bit;
  /* printf("set_bit %Lu\n", n); */
  assert (n&1);
W_AND_BIT_OF_N(w,bit, n);
  ensure_block_w (w);
  uint64_t offset = w - block_w;
  /* DEBUG(printf("  byte %Lu offset %Lu past pos %Lu\n", */
  /*              byte, offset, block_pos)); */
  assert (offset >=0);
  assert (offset < BLOCK_WORDLEN);
  block[offset] |= 1<<bit;
}
static int
get_bit(uint64_t n)
{
  off_t byte, offset;
  int bit;
  assert (n&1);
  N_TO_BYTE_AND_BIT(n, byte,bit);
  ensure_block_w(byte>>2);
  offset = byte - block_pos;
  assert (offset >=0);
  assert (offset < BLOCKSIZE);
  return (block[offset] & (1<<bit));
}

void
sieve_block (void)
{
  uint64_t p, w, step_w;
  int bit, step_bit;
  for (p = 3; ; p+=2) {
    uint64_t t = 3*p - block_w;
    W_AND_BIT_OF_N (step_w,step_bit, p);
    W_AND_BIT_OF_N (w,bit, t);
  }
}

/*
  forstep(n=1,1024,2, print1(!isprime(n),","); if(n%70==69,print()));
 */
const char want[] = {
  1,0,0,0,1,0,0,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,0,1,1,0,1,1,0,0,1,1,0,1,
  0,0,1,1,0,1,0,1,1,0,1,1,1,0,1,0,0,1,0,0,1,0,1,1,1,1,1,1,0,1,0,1,1,0,0,
  1,1,1,1,0,0,1,1,0,1,1,0,1,0,1,1,0,1,1,0,0,1,1,1,1,0,0,1,0,0,1,1,1,1,1,
  0,1,1,1,1,1,0,1,0,0,1,0,1,1,0,0,1,1,1,1,0,1,1,0,1,1,0,1,1,0,0,1,1,0,1,
  0,0,1,1,1,1,0,1,1,1,1,1,1,0,1,0,0,1,0,1,1,1,1,1,1,0,1,1,0,1,1,1,1,0,0,
  1,0,1,1,0,1,1,1,0,1,1,0,1,1,0,1,0,1,1,0,1,1,1,0,1,0,1,1,1,0,1,1,1,1,0,
  0,1,1,1,1,0,0,1,1,0,1,0,1,1,0,1,1,1,0,1,0,0,1,0,1,1,1,1,1,0,1,1,1,0,1,
  0,1,1,1,0,1,0,1,1,0,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,0,1,1,0,1,1,1,1,0,1,
  1,0,1,1,0,0,1,1,0,1,1,1,1,0,1,1,0,1,1,0,0,1,1,0,1,1,0,1,0,0,1,1,1,1,1,
  0,1,1,1,1,0,0,1,0,1,1,0,1,1,0,0,1,1,1,1,1,0,1,0,1,1,0,1,1,1,0,1,1,1,1,
  0,1,1,1,0,1,1,1,1,0,1,1,1,0,1,1,0,1,1,0,1,0,1,1,1,0,1,1,0,1,0,1,1,1,0,
  1,0,1,1,1,1,1,1,0,1,1,1,1,0,1,1,1,1,1,0,0,1,1,1,1,0,0,1,0,0,1,1,1,1,0,
  1,1,1,1,1,1,0,1,0,0,1,0,1,1,1,1,1,1,0,1,0,0,1,0,1,1,1,1,1,1,1,1,1,0,1,
  0,1,1,1,0,1,1,1,1,0,1,1,1,0,1,0,1,1,0,1,1,0,1,1,1,1,1,1,0,1,0,1,1,0,1,
  1,0,1,1,1,0,1,1,0,1,1,1,1,1,0,1,0,1,1,0,0,1,

};

int
main (void)
{
  off_t filesize;
  setbuf(stdout,NULL);
  printf("limit %Lu = %Ld megs = %Ld G\n",
         limit,
         limit / (1000ULL * 1000ULL),
         limit / (1000ULL * 1000ULL * 1000ULL));
  printf("BLOCKSIZE %u = %u megs\n", BLOCKSIZE, BLOCKSIZE / (1000 * 1000));
  printf("sizeof off_t = %u\n", sizeof(off_t));
  {
    uint64_t n = limit - !(limit&1);
    int bit;
    N_TO_BYTE_AND_BIT(n, filesize,bit);
    if (bit) filesize++;
  }
  printf("filesize %Ld bytes  %Ld megs\n",
         filesize, filesize >> 20);

  unlink(filename);
  fd = open(filename, O_CREAT|O_RDWR|O_TRUNC, 0666);
  if (posix_fadvise(fd,0,0, POSIX_FADV_SEQUENTIAL) != 0)
    abort();

  if (ftruncate(fd, filesize) != 0) abort();
  system("ls -l /tmp/bigprime-sieve.data");

  if (fd<0) abort();
  set_bit(1);
  {
    uint64_t p,step,t;
    for (p=3; p<limit; p+=2) {
#if WANT_ASSERT
      if (p < 2*sizeof(want)) {
        /* printf("p=%Ld get_bit %d want %d (idx %Ld)\n", */
        /*        p, get_bit(p), want[p>>1], p>>1); */
        assert((get_bit(p)!=0) == want[p>>1]);
      }
#endif
      if (get_bit(p)) continue;
      if ((p & 0xFFF) == 5)
        printf("prime %Lu\r", p);
      step = p<<1;
      t = p + step;
      if (t >= limit) break;
      for ( ; t < limit; t+=step)
        set_bit(t);
    }
    printf("end at prime %Lu\n", p);
  }

  {
    uint64_t num_primes = 1;     /* including 2 */
    uint64_t i;
    for (i=3; i<limit; i+=2)
      if (! get_bit(i))
        num_primes++;
    printf("num_primes %Lu\n", num_primes);
  }
  return 0;
}

