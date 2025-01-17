#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>           
#include <sys/stat.h>

static double t2d (const struct timespec * ts)
{
  double d = (double)ts->tv_sec + ((double)ts->tv_nsec) / 1000000000;
  return d;
}

MODULE = File::stat2		PACKAGE = File::stat2		

void
_stat2 (path)
      const char * path
    INIT:
      struct stat st;
      char ino[128];
    PPCODE:
      if (stat (path, &st) == 0)
        {
          sprintf (ino, "%llu", (unsigned long long)st.st_ino);
          XPUSHs (sv_2mortal (newSViv (st.st_dev    )));
          XPUSHs (sv_2mortal (newSVpv (ino       , 0)));
          XPUSHs (sv_2mortal (newSViv (st.st_mode   )));
          XPUSHs (sv_2mortal (newSViv (st.st_nlink  )));
          XPUSHs (sv_2mortal (newSViv (st.st_uid    )));
          XPUSHs (sv_2mortal (newSViv (st.st_gid    )));
          XPUSHs (sv_2mortal (newSViv (st.st_rdev   )));
          XPUSHs (sv_2mortal (newSViv (st.st_size   )));
          XPUSHs (sv_2mortal (newSVnv (t2d (&st.st_atim))));
          XPUSHs (sv_2mortal (newSVnv (t2d (&st.st_mtim))));
          XPUSHs (sv_2mortal (newSVnv (t2d (&st.st_ctim))));
          XPUSHs (sv_2mortal (newSViv (st.st_blksize)));
          XPUSHs (sv_2mortal (newSViv (st.st_blocks )));
        }

    


