#include	<sys/types.h>
#include	<sys/socket.h>		/* struct msghdr */
#include	<sys/uio.h>		/* struct iovec */
#include	<errno.h>
#include	<stddef.h>
#include	<stdio.h>
#include	<fcntl.h>
#include	<string.h>
#include	<stdlib.h>
#include	<unistd.h>
#include	<sys/stat.h>
#include	<sys/un.h>
#include	<time.h>
#include	"common.h"



static struct cmsghdr	*cmptr = NULL;	/* buffer is malloc'ed first time */
#define	CONTROLLEN	(sizeof(struct cmsghdr) + sizeof(int))


/* size of control buffer to send/recv one file descriptor */
/* Pass a file descriptor to another process.
 * If fd<0, then -fd is sent back instead as the error status. */

int
my_send_fd(int clifd, int fd) {
  struct iovec	iov[1];
  struct msghdr	msg;
  char buf[2]; /* send_fd()/recv_fd() 2-byte protocol */

  iov[0].iov_base = buf;
  iov[0].iov_len  = 2;
  msg.msg_iov     = iov;
  msg.msg_iovlen  = 1;
  msg.msg_name    = NULL;
  msg.msg_namelen = 0;
  if (fd<0) {
    msg.msg_control    = NULL;
    msg.msg_controllen = 0;
    buf[1] = -fd;	/* nonzero status means error */
    if (buf[1] == 0) buf[1] = 1;	/* -256, etc. would screw up protocol */
  } else {
    if (cmptr == NULL && (cmptr = malloc(CONTROLLEN)) == NULL) return(-1);
    cmptr->cmsg_level  = SOL_SOCKET;
    cmptr->cmsg_type   = SCM_RIGHTS;
    cmptr->cmsg_len    = CONTROLLEN;
    msg.msg_control    = (caddr_t) cmptr;
    msg.msg_controllen = CONTROLLEN;
    *(int *)CMSG_DATA(cmptr) = fd;	/* the fd to pass */
    buf[1] = 0;		/* zero status means OK */
  }
  buf[0] = 0;			/* null byte flag to recv_fd() */
  
  if (sendmsg(clifd, &msg, 0) != 2) return(-1);
  return(0);
}

int
my_recv_fd(int servfd) {
  int newfd, nread, status;
  char *ptr, buf[MAXLINE];
  struct iovec iov[1];
  struct msghdr msg;
  
  status = -1;
  iov[0].iov_base = buf;
  iov[0].iov_len  = sizeof(buf);
  msg.msg_iov     = iov;
  msg.msg_iovlen  = 1;
  msg.msg_name    = NULL;
  msg.msg_namelen = 0;
  if (cmptr == NULL && (cmptr = malloc(CONTROLLEN)) == NULL) return(-1);
  msg.msg_control    = (caddr_t) cmptr;
  msg.msg_controllen = CONTROLLEN;
    
  if ( (nread = recvmsg(servfd, &msg, 0)) < 0) return(-1);
  else if (nread == 0) {
    fprintf(stderr,"connection closed by server");
    return(-1);
  }  

  /* See if this is the final data with null & status.
     Null must be next to last byte of buffer, status
     byte is last byte.  Zero status means there must
     be a file descriptor to receive. */
    
  for (ptr = buf; ptr < &buf[nread]; ) {
    if (*ptr++ == 0) {
	if (ptr != &buf[nread-1]) { fprintf(stderr,"message format error"); exit(2); }
	status = *ptr & 255;
	if (status == 0) {
	  if (msg.msg_controllen != CONTROLLEN) { fprintf(stderr,"status = 0 but no fd"); exit(2); }
	  newfd = *(int *)CMSG_DATA(cmptr); /* new descriptor */
	} else newfd = -status;
	nread -= 2;
    }
  }
  if (nread > 0) if (write(STDERR_FILENO, buf, nread) != nread) return(-1);
  if (status >= 0) return(newfd);	/* final data has arrived,  descriptor, or -status */
}

int my_getfl(int fd) { return fcntl(fd,F_GETFL); }

/* only used in svr4 */
int my_isastream(int fd) { return 0; } 
int my_serv_accept(int listenfd) { return(0); }
int serv_listen(const char *name) { return(0); }
int cli_conn(const char *name) { return(0); }
int bind_to_fs(int fd,const char *name) { return(0); }



