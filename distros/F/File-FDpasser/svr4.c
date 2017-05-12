#include	<stdio.h>
#include	<sys/types.h>
#include	<stropts.h>
#include	<sys/stat.h>
#include	<fcntl.h>
#include	<unistd.h>
#include	"common.h"



#define FIFO_MODE  (S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP|S_IROTH|S_IWOTH)


/* Receive a file descriptor from another process (a server).
 * In addition, any data received from the server is passed
 * to (*userfunc)(STDERR_FILENO, buf, nbytes).  We have a
 * 2-byte protocol for receiving the fd from send_fd(). */

int
my_recv_fd(int servfd) {
  int newfd, nread, flag, status;
  char *ptr, buf[MAXLINE];
  struct strbuf dat;
  struct strrecvfd recvfd;

  status = -1;

  dat.buf = buf;
  dat.maxlen = MAXLINE;
  flag = 0;
  if (getmsg(servfd, NULL, &dat, &flag) < 0) { fprintf(stderr,"getmsg error\n"); return(-1); }
  nread = dat.len;
  if (nread == 0) {
    fprintf(stderr,"connection closed by server");
    return(-1);
  }
  /* See if this is the final data with null & status.
     Null must be next to last byte of buffer, status
     byte is last byte.  Zero status means there must
     be a file descriptor to receive. */
  
  for (ptr = buf; ptr < &buf[nread]; ) {
    if (*ptr++ == 0) {
      if (ptr != &buf[nread-1]) { fprintf(stderr,"message format error"); return(-1); }
      status = *ptr & 255;
      if (status == 0) {
	if (ioctl(servfd, I_RECVFD, &recvfd) < 0) return(-1);
	newfd = recvfd.fd;	/* new descriptor */
      } else newfd = -status;
      nread -= 2;
    }
  }
  if (nread > 0) if (write(STDERR_FILENO, buf, nread) != nread) return(-1);
  if (status >= 0) return(newfd);	/* final data has arrived - descriptor, or -status */
}


/* Pass a file descriptor to another process.
 * If fd<0, then -fd is sent back instead as the error status. */

int
my_send_fd(int clifd, int fd) {
  char buf[2];				/* send_fd()/recv_fd() 2-byte protocol */
  buf[0] = 0;				/* null byte flag to recv_fd() */
  if (fd < 0) {
    buf[1] = -fd;			/* nonzero status means error */
    if (buf[1] == 0) buf[1] = 1;	/* -256, etc. would screw up protocol */
  } else {
    buf[1] = 0;				/* zero status means OK */
  }
  
  if (write(clifd, buf, 2) != 2) return(-1);
  
  if (fd >= 0) if (ioctl(clifd, I_SENDFD, fd) < 0) return(-1);
  return(0);
}



/* Create a client endpoint and connect to a server.
 * returns fd if all OK, <0 on error */

int
cli_conn(const char *name) {
  int fd;
  if ( (fd = open(name, O_RDWR)) < 0) return(-1);	/* open the mounted stream */ 
  if (isastream(fd) == 0) return(-2);
  return(fd);
}


/* Wait for a client connection to arrive, and accept it.
 * We also obtain the client's user ID.
 * returns new fd if all OK, -1 on error */

int
my_serv_accept(int listenfd) {
  struct strrecvfd recvfd;
  if (ioctl(listenfd, I_RECVFD, &recvfd) < 0) return(-1); /* could be EINTR if signal caught */
  return(recvfd.fd);	/* return the new descriptor */
}


int
bind_to_fs(int fd,const char *name) {
  int tempfd;
  if ( (tempfd = creat(name, FIFO_MODE)) < 0) return 0;
  if (close(tempfd) < 0) return 0;
  if (ioctl(fd, I_PUSH, "connld") < 0) return 0;
  if (fattach(fd, name) < 0) return 0;
  return 1;
}

int my_isastream(int fd) { return isastream(fd); }
int my_getfl(int fd) { return fcntl(fd,F_GETFL); }

