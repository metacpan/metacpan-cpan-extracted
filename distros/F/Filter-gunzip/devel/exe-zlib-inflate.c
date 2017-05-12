/* Copyright 2014 Kevin Ryde

   This file is part of Filter-gunzip.

   Filter-gunzip is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3, or (at your option) any later
   version.

   Filter-gunzip is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
   or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
   for more details.

   You should have received a copy of the GNU General Public License along
   with Filter-gunzip.  If not, see <http://www.gnu.org/licenses/>.
*/
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <zlib.h>

int
main (void)
{
  int fd = open("/tmp/test2.in.gz", O_RDONLY);
  if (fd < 0) { abort(); }

  char inbuf[4096];
  int inlen = read (fd, inbuf, sizeof(inbuf));
  if (inlen < 0) { abort(); }
  printf ("inlen=%d\n", inlen);

  char outbuf[104096];

  z_stream z;
  z.zalloc = Z_NULL;
  z.zfree = Z_NULL;
  z.opaque = Z_NULL;
  z.next_in = (Bytef *) inbuf;
  z.avail_in = inlen;
  z.next_out = (Bytef *) outbuf;
  z.avail_out = sizeof (outbuf);

  /* ask to accept either gzip or zlib header formats */
  int ret = inflateInit2 (&z, 32 + 15);
  if (ret != Z_OK) {
    abort();
  }

  ret = inflate (&z, Z_NO_FLUSH);
  printf ("ret=%d\n", ret);
  printf ("avail_in=%d\n", z.avail_in);
  printf ("avail_out=%d\n", z.avail_out);

  return 0;
}
