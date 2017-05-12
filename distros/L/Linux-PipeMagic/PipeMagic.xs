#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <fcntl.h>

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
    RETVAL = tee(fd_in, fd_out, len, flags);
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
    RETVAL = splice(fd_in, NULL, fd_out, NULL, len, flags);
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
    RETVAL = sendfile(fd_out, fd_in, NULL, len);
OUTPUT:
    RETVAL

