/* netio.c
 *
 * Copyright 2003 - 2009, Michael Robinton <michael@bizsystems.com>
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
#include <fcntl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/file.h>
#include <netinet/in_systm.h>
#include <netinet/in.h>
#include <errno.h>
#include <string.h>
#include <arpa/nameser.h>

#include "ns.h"		/* includes netinet/ip.h	*/
#include "defines.h"

/*	write "n" bytes to file handle
 *	returns number of bytes actually written
 *	or -1 on error
 */
 
struct sockaddr_in client;
struct sockaddr * cin_ptr = NULL;

int
writen(int fd, u_char * bptr, size_t n, int is_tcp)
{
  extern struct sockaddr_in client;
  extern struct sockaddr * cin_ptr;
  socklen_t s_len = sizeof(client);
  int nleft, nwritten;

  nleft = (int)n;
  while (nleft > 0) {
    if (is_tcp) {
      alarm(DNSBLchildlife);	/* inactivity timer	*/
      nwritten = send(fd, bptr, (size_t)nleft, 0);
    }
    else
      nwritten = sendto(fd,bptr,(size_t)nleft,0,cin_ptr,s_len);

    
    if (nwritten <= 0) {	/* do we need MSG_DONTWAIT?	*/
/* printf("error=%d, %s\n",errno,strerror(errno)); */
      if (errno == EINTR || errno == EWOULDBLOCK)
	nwritten = 0;		/* is OK, try again	*/
      else
	return(nwritten);		/* ERROR, bail	*/
    }
    nleft -= nwritten;
    bptr += nwritten;
  }
  return((int)n);
}

/* read data from socket, return length
 * returns 0 or a positive integer	
 */

int
read_msg(int fd, int is_tcp)
{
  extern struct sockaddr * cin_ptr;
  extern struct sockaddr_in client;
  extern u_char ns_msgbuf[];
  socklen_t s_len = sizeof(struct sockaddr_in);
  size_t msglen;
  u_char * bp;
  int n, i;
  
  cin_ptr = (struct sockaddr *)&client;

  if(is_tcp) {
    msglen = sizeof(u_short);

    alarm(DNSBLchildlife);		/* inactivity timer		*/

    for(i=2;i>0;i--) {
      bp = ns_msgbuf;
      while (msglen > 0) {		/* get the message length	*/
        n = read(fd, bp, msglen);
        if (n > 0) {
          bp += n;
          msglen -= n;
        }
        if (n == -1 && (errno == EINTR || errno == EWOULDBLOCK))
          continue;

        if (n < 0)
          return(0);

        if (n == 0)
          break;
      }
      msglen = (size_t)ntohs(*(u_short *)ns_msgbuf);
      alarm(15);
    }
    alarm(DNSBLchildlife);		/* inactivity timer	*/
    msglen = bp - ns_msgbuf;
  }
  else {
    msglen = PACKETSZ;
    msglen = recvfrom(fd,ns_msgbuf,msglen,0,cin_ptr,&s_len);
  }
  return((int)msglen);
}

/* open a socket where type is one of SOCK_STREAM or SOCK_DGRAM	*/
int
init_socket(int type)
{
  extern int port;
  struct sockaddr_in server;
  int fd;
  const int on = 1;
  
  if ((fd = socket(PF_INET,type,0)) < 0)
  	return(0);
  bzero(&server, sizeof(server));
  server.sin_family = PF_INET;
  server.sin_addr.s_addr = htonl(INADDR_ANY);
  server.sin_port = htons(port);
  if (type == SOCK_STREAM) {
    (void) fcntl(fd, F_SETFL, FNDELAY);		/* set non-blocking	*/
    if (setsockopt(fd,SOL_SOCKET,SO_REUSEADDR,&on,sizeof(on)) < 0)
	goto Punt;
  }
  if (bind(fd,(struct sockaddr *)&server,sizeof(server)) < 0) {
  Punt:
  	close(fd);
  	return(0);
  }
  if (type == SOCK_STREAM) {
    if (listen(fd,SOMAXCONN) < 0)
	goto Punt;
  }
  return(fd);
}

int
accept_tcp(int fd)
{
  extern struct sockaddr_in client;
  socklen_t len;
  int newfd;

  len = sizeof(client);
  if ((newfd = accept(fd,(struct sockaddr *)(&client),&len)) < 0)
    newfd = 0;
  return(newfd);
}
