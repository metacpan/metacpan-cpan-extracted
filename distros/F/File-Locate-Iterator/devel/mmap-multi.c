/* Copyright 2009, 2010 Kevin Ryde.

   This file is part of File-Locate-Iterator.

   File-Locate-Iterator is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as published
   by the Free Software Foundation; either version 3, or (at your option)
   any later version.

   File-Locate-Iterator is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
   Public License for more details.

   You should have received a copy of the GNU General Public License along
   with File-Locate-Iterator; see the file COPYING.  Failing that, go to
   <http://www.gnu.org/licenses/>.
*/

/* #define _LARGEFILE64_SOURCE  1 */
/* #define _LARGEFILE_SOURCE    1 */
#define _FILE_OFFSET_BITS 64

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <dirent.h>

/* multiple maps give a different address each time */

/* const char filename[] = "/var/cache/locate/locatedb"; */
const char filename[] = "/dev/zero";

#define MAX(x,y) ((x) >= (y) ? (x) : (y))
int
main (void)
{
  {
#ifdef _DIRENT_HAVE_D_TYPE
    printf ("_DIRENT_HAVE_D_TYPE\n");
#endif
#ifdef DT_UNKNOWN
    printf ("DT_UNKNOWN %d\n", DT_UNKNOWN);
#endif
    DIR *dp = opendir ("/tmp");
    printf ("dp %p\n", dp);
    struct dirent *de;

    /* while (de = readdir (dp)) { */
    /*       printf ("de %p\n", de); */
    /*       printf ("name  %s\n", de->d_name); */
    /*       printf ("inode %d\n", de->d_ino); */
    /*       printf ("type  %d\n", de->d_type); */
    /*     } */

    union {
      struct dirent d;
      char b[sizeof(struct dirent)
             + MAX (sizeof(de->d_name), NAME_MAX + 1)
             - sizeof(de->d_name)];
    } du;
    printf ("sizeof d_name %d\n", sizeof(de->d_name));
    printf ("NAME_MAX+1    %d\n", NAME_MAX+1);

    while (readdir_r (dp, &du.d, &de) == 0) {
      printf ("de %p\n", de);
      printf ("name  %s\n", de->d_name);
      printf ("inode %ld\n", (long) de->d_ino);
      printf ("type  %d\n", de->d_type);
    }

    return 0;
  }

  {
    int fd, i;
    void *p;
    size_t len;
    off_t offset;

    fd = open (filename, O_RDONLY);
    if (fd < 0) {
      perror ("open");
      return 1;
    }

    {
      printf ("sizeof(off_t) %d\n", sizeof(off_t));
      len = 1;
      offset = (off_t)1 << 32;
      p = mmap (NULL, len, PROT_READ, MAP_SHARED, fd, offset);
      printf ("%p\n", p);
      return 0;
    }

    {
      len = 4;
      offset = 0;
      for (i = 0; i < 3; i++) {
        p = mmap (NULL, len, PROT_READ, MAP_SHARED, fd, offset);
        printf ("%p\n", p);
      }
      return 0;
    }
  }
}
