#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <sys/ioctl.h>

#ifndef SIOCATMARK
  #include <sys/sockio.h>
#endif

#ifdef PerlIO
typedef PerlIO * InputStream;
#else
#define PERLIO_IS_STDIO 1
typedef FILE * InputStream;
#define PerlIO_fileno(f) fileno(f)
#endif

MODULE = IO::Sockatmark		PACKAGE = IO::Sockatmark

int
sockatmark (sock)
   InputStream sock
   PROTOTYPE: $
   PREINIT:
     int fd,flag,result;
   CODE:
   {
     fd = PerlIO_fileno(sock);
     if (ioctl(fd,SIOCATMARK,&flag) != 0)
       XSRETURN_UNDEF;
     RETVAL = flag;
   }
   OUTPUT:
     RETVAL

          
 
     



