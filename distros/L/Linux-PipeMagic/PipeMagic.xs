#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <fcntl.h>
#include <errno.h>

#ifdef __linux__
#include <sys/sendfile.h>
#endif

#include "const-c.inc"

typedef PerlIO *        OutputStream;
typedef PerlIO *        InputStream;


MODULE = Linux::PipeMagic		PACKAGE = Linux::PipeMagic		
PROTOTYPES: ENABLE

INCLUDE: const-xs.inc

ssize_t
systee(io_in, io_out, len, flags)
    InputStream io_in
    OutputStream io_out
    ssize_t len
    int flags
PREINIT:
    int fd_in = PerlIO_fileno(io_in);
    int fd_out = PerlIO_fileno(io_out);
CODE:
#ifdef __linux__
    RETVAL = tee(fd_in, fd_out, len, flags);
#else
    errno  = ENOSYS;
    RETVAL = -1;
#endif
OUTPUT:
    RETVAL

ssize_t
syssplice(io_in, io_out, len, flags)
    InputStream io_in
    OutputStream io_out
    ssize_t len
    int flags
PREINIT:
    int fd_in = PerlIO_fileno(io_in);
    int fd_out = PerlIO_fileno(io_out);
CODE:
#ifdef __linux__
    RETVAL = splice(fd_in, NULL, fd_out, NULL, len, flags);
#else
    errno  = ENOSYS;
    RETVAL = -1;
#endif
OUTPUT:
    RETVAL

ssize_t
syssendfile(io_out, io_in, len)
    InputStream io_in
    OutputStream io_out
    ssize_t len
PREINIT:
    int fd_in = PerlIO_fileno(io_in);
    int fd_out = PerlIO_fileno(io_out);
CODE:
#ifdef __linux__
    RETVAL = sendfile(fd_out, fd_in, NULL, len);
#else
    errno  = ENOSYS;
    RETVAL = -1;
#endif
OUTPUT:
    RETVAL

