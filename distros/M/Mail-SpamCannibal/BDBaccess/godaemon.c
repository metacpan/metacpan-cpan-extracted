/* godaemon.c
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

#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>

/* detach this process */
static __inline void godaemon(void) {
  extern char devnull[];
  pid_t pid;
/* suppress annoying compiler warnings	*/
  int discard;
  
  if ((pid = fork()) != 0)
    exit(0);			/* parent exits		*/
  
  setsid();			/* become session leader	*/

/*  signal(SIGHUP,SIG_IGN);	set in signal handler	*/
  
  if ((pid = fork()) != 0)	/* double fork		*/
    exit(0);			/* 1st child exits	*/

  discard = chdir("/");
  /* redirect stdin/stdout/stderr to /dev/null */
  close(0);
  close(1);
  close(2);
  open(devnull, O_RDWR);
  discard = dup(0);
  discard = dup(0);
  return;
}

/* detach child
 * return PID to parent, 0 to child
 */
static __inline int forkchild(void) {
  extern char err26[];
  pid_t pid;

  if((pid = fork()) > 0)
    return(pid);	/* parent	*/

  if(pid < 0) {		/* error, log and fail	*/
    LogPrint(err26);
    CleanExit(0);
  }
  return(0);
}
