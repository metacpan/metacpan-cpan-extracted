#ifdef __sun
  #define _XOPEN_SOURCE 1
  #define _XOPEN_SOURCE_EXTENDED 1
  #define __EXTENSIONS__ 1
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stddef.h> // needed by broken bsds for NULL used in sys/uio.h
#include <stdlib.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <sys/socket.h>

#ifndef CMSG_SPACE
# define CMSG_SPACE(len) (sizeof (struct cmsghdr) + len)
#endif

#ifndef CMSG_LEN
# define CMSG_LEN(len) (sizeof (struct cmsghdr) + len)
#endif

int
_fd_sendata (int socket, void * buf, int len, int fd)
{

  int size;
  struct msghdr msg;
  struct iovec iov;
  struct cmsghdr *cmsg;
  union {
	struct cmsghdr	cmsghdr;
	char		control[CMSG_SPACE(sizeof (int))];
  } cmsgu;

  iov.iov_base         = buf;
  iov.iov_len          = len;

  msg.msg_name         = NULL;
  msg.msg_namelen      = 0;
  msg.msg_iov          = &iov;
  msg.msg_iovlen       = 1;

  if (fd >= 0) {
    msg.msg_control    = cmsgu.control;
    msg.msg_controllen = sizeof(cmsgu.control);

    cmsg               = CMSG_FIRSTHDR(&msg);
    cmsg->cmsg_len     = CMSG_LEN(sizeof (int));
    cmsg->cmsg_level   = SOL_SOCKET;
    cmsg->cmsg_type    = SCM_RIGHTS;

 //printf ("passing fd %d\n", fd);
    *((int *) CMSG_DATA(cmsg)) = fd;
  } else {
    msg.msg_control    = NULL;
    msg.msg_controllen = 0;
 //printf ("not passing fd\n");
  }

  size = sendmsg(socket, &msg, 0);

  return size;
}

int
_fd_recvdata (int socket, void * buf, int len, int * fd)
{

  int size;

  if (fd) {
    struct msghdr msg;
    struct iovec iov;
    struct cmsghdr *cmsg;

    union {
	struct cmsghdr	cmsghdr;
	char		control[CMSG_SPACE(sizeof (int))];
    } cmsgu;

    iov.iov_base       = buf;
    iov.iov_len        = len;

    msg.msg_name       = NULL;
    msg.msg_namelen    = 0;
    msg.msg_iov        = &iov;
    msg.msg_iovlen     = 1;
    msg.msg_control    = cmsgu.control;
    msg.msg_controllen = sizeof(cmsgu.control);

    size               = recvmsg (socket, &msg, 0);

    if (size < 0) {
 //fprintf(stderr, "sock %d , size to small\n",socket);
 //perror(strerror(errno));
      return -1;
    }

    cmsg = CMSG_FIRSTHDR(&msg);
    if (cmsg && cmsg->cmsg_len == CMSG_LEN(sizeof(int))) {
      if (cmsg->cmsg_level != SOL_SOCKET) {
  //fprintf (stderr, "invalid cmsg_level %d\n", cmsg->cmsg_level);
	return -1;
      }
      else if (cmsg->cmsg_type != SCM_RIGHTS) {
 //fprintf (stderr, "invalid cmsg_type %d\n", cmsg->cmsg_type);
	return -1;
      }
      *fd = *((int *) CMSG_DATA(cmsg));
 //printf ("received fd %d\n", *fd);
    } else {
      *fd = -1;
    }
  } else {
    size = read (socket, buf, len);
    *fd = -1;
  }
  return size;
}

MODULE = IO::FDpassData		PACKAGE = IO::FDpassData

PROTOTYPES: ENABLED

int
fd_sendata (socket, b, ...)
	int socket
	SV * b
INIT:
	STRLEN len = 1;
	unsigned char * buf = "\0";	// preset to empty string if message buffer is 'undef'
	int fd;
CODE:
	if (SvOK(b) && SvPOK(b)) {
	  buf = (unsigned char *) SvPV(b,len);
	  if (len == 0)		// zero length string "\0"
	    len = 1;
	}
	if (items == 3 && SvOK(ST(2)) && SvIOK(ST(2))) {
	  fd = (int)SvIV(ST(2));
	} else {
	  fd = -1;
	}
	RETVAL = _fd_sendata(socket, buf, len, fd);
OUTPUT:
	RETVAL


void
fd_recvdata (sock, len)
	int sock
	int len
PREINIT:
	int fd, size;
	unsigned char * buf = malloc(len);
PPCODE:
	size = _fd_recvdata(sock, buf, len, &fd);
	if (size < 0) {			// ERROR
	  free(buf);
	  XSRETURN_EMPTY;
	}
	if (size == 1 && buf[0] == 0x0) {
	  size = 0;
	}
	XPUSHs(sv_2mortal(newSViv(size)));
	if (size == 0) {
	  XPUSHs(sv_2mortal(newSVpvn(buf,0)));
	} else {
	  XPUSHs(sv_2mortal(newSVpvn(buf,size)));
	}
	free(buf);
	if (fd < 0) {
	  XSRETURN(2);
	}
	XPUSHs(sv_2mortal(newSViv(fd)));
	XSRETURN(3);
