/* Copyright 2009, 2010 Kevin Ryde

   This file is part of Devel-Mallinfo.

   Devel-Mallinfo is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3, or (at your option) any later
   version.

   Devel-Mallinfo is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
   or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
   for more details.

   You should have received a copy of the GNU General Public License along
   with Devel-Mallinfo.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <malloc.h>
#include <unistd.h>


int
main (void)
{
  malloc (123);

  fprintf (stderr, "malloc_stats():\n");
  malloc_stats();

  fprintf (stderr, "\nmalloc_info():\n");
  malloc_info (0, stdout);

  {
    FILE *fp;
    char buf[256];
    struct stat st;
    putenv ("TMPDIR=/tmp/fullfs/tmp/");
    printf ("%s\n", tmpnam(NULL));
    fp = tmpfile();
    printf ("%p\n", fp);
    printf ("%d\n", fstat(fileno(fp), &st));
    printf ("ino %ld dev %ld\n", (long) st.st_ino, (long) st.st_dev);
    printf ("%d\n", fwrite ("hello", 1, 2048, fp));
    printf ("%d\n", fflush (fp));
    rewind (fp);
    printf ("%d\n", fread (buf, 1, 5, fp));
  }

  {
    int fd;
    struct stat st;
    fd = open ("/tmp/fullfs/yes", O_RDONLY);
    printf ("%d\n", fstat(fd, &st));
    printf ("ino %ld dev %ld\n", (long) st.st_ino, (long) st.st_dev);
  }

  return 0;
}
