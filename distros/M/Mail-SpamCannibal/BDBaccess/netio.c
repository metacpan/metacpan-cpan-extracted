/* netio.c
 *
 * Copyright 2003, Michael Robinton <michael@bizsystems.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/uio.h>
#include <sys/un.h>
#include <netinet/in_systm.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <errno.h>
#include <string.h>
#include <sys/stat.h>

u_char my_msgbuf[IP_MAXPACKET];

/*	write "n" bytes to file handle
 *	returns number of bytes actually written
 *	or -1 on error
 */
 
int
writen(int fd, u_char * bptr, size_t n)
{
  int nleft, nwritten;
  
  nleft = (int)n;
  alarm(10);
  while (nleft > 0) {
    nwritten = send(fd, bptr, (size_t)nleft, 0);
    if (nwritten <= 0) {	/* do we need MSG_DONTWAIT?	*/
/* printf("error=%d, %s\n",errno,strerror(errno));	*/
      if (errno == EINTR)
	nwritten = 0;		/* is OK, try again	*/
      else {
        alarm(0);
	return(nwritten);		/* ERROR, bail	*/
      }
    }
    nleft -= nwritten;
    bptr += nwritten;
  }
  alarm(0);
  return((int)n);
}

/*	write msglen the msg to handle	*/

int
write_msg(int fd, u_char * bptr, size_t n)
{
  u_short len;
  len =  htons((u_short)n);
  if ((writen(fd,(u_char *)&len,sizeof(len))) < 0)
  	return(-1);
  return(writen(fd,bptr,n));
}

/* read data from socket, return length	*/
int
read_msg(int fd)
{
  extern u_char my_msgbuf[];
  size_t msglen;
  int len;
  
  alarm(10);
  if (recv(fd,my_msgbuf,2,0) != 2) {
 Bail:
    alarm(0);
    return(0);
  }
  if ((msglen = ntohs(*(u_short *)my_msgbuf)) > IP_MAXPACKET)
    goto Bail;
    
  msglen = recv(fd,my_msgbuf,msglen,0);
  alarm(0);

  len = (int)msglen;
  return(len);
}

/* open a socket of type SOCK_STREAM */
int
init_socket()
{
  extern char * dbhome;
  extern char * sockname;
  extern int port;

  struct sockaddr_un u_server;
  struct sockaddr_in n_server;
  struct sockaddr * server;
  int fd;
  mode_t mask = 0;
  size_t s_len;

  if (port) {
    if ((fd = socket(PF_INET,SOCK_STREAM,0)) < 0)
    	return(0);
    s_len = sizeof(n_server);
    bzero(&n_server,s_len);
    n_server.sin_family = PF_INET;
    n_server.sin_port = htons(port);
    server = (struct sockaddr *)&n_server;
  }
  else {
    if ((fd = socket(PF_UNIX,SOCK_STREAM,0)) < 0)
  	return(0);
    s_len = sizeof(u_server);
    bzero(&u_server,s_len);
    u_server.sun_family = PF_UNIX;
    strcpy(u_server.sun_path,dbhome);
    strcat(u_server.sun_path,"/");
    strcat(u_server.sun_path,sockname);
    server = (struct sockaddr *)&u_server;
    
    unlink(u_server.sun_path);
  }
  
  mask = umask(mask);
  if (bind(fd,server,s_len) < 0) {
  Upunt:
	umask(mask);
  Punt:
  	close(fd);
  	return(0);
  }
  if (port == 0) {
    if (fchmod(fd, S_IRUSR | S_IWUSR | S_IXUSR | S_IRGRP | S_IWGRP | S_IXGRP | S_IROTH | S_IWOTH | S_IXOTH))
	goto Upunt;
  }
  
  umask(mask);
  if (listen(fd,SOMAXCONN) < 0)
	goto Punt;

  return(fd);
}

int
accept_client(int fd)
{
  extern int port;
  struct sockaddr_un domain_sock;
  struct sockaddr_in net_sock;
  struct sockaddr * client;
  socklen_t len;
  int newfd;

  if (port ) {
    len = sizeof(net_sock);
    client = (struct sockaddr *)&net_sock;
  }
  else {
    len = sizeof(domain_sock);
    client = (struct sockaddr *)&domain_sock;
  }

  if ((newfd = accept(fd,client,&len)) < 0)
    newfd = 0;
  return(newfd);
}
