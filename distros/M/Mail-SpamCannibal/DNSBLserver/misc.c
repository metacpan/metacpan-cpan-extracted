/* misc.c
 *
 * Portions of this file are adapted from LaBrea by Tom Liston <tliston@premmag.com>, Copyright (C) 2001, 2002
 #
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
#include <time.h>
#include <stdio.h>
#include <signal.h>
#include <syslog.h>
#include <signal.h>
#include <sys/wait.h>
#include "defines.h"
#include "util_pid_func.h"

pid_t zonechild = 0;

void
LogPrint(char *output) {
  extern int oflag;
  time_t current;
  char tbuf[17];

  if(oflag) {
    current = time(NULL);
    strncpy(tbuf,ctime(&current)+4,16);
    strcpy(tbuf+16,"\0");
    printf("%s%s\n",tbuf,output);
  }
  else
    syslog(INFOTYPE, output);
}

void
CleanExit(int sig) {
  extern DBTPD dbtp;
  extern int logopen, fdUDP, fdTCPlisten, fdTCP, parent, unlinkOK;
  extern char str2[], str3[];
  
  if(sig == SIGHUP) {
    LogPrint(str2);
    return;
  }

  /* close the database and environment	*/
  dbtp_close(&dbtp);

  /* close open sockets	*/
  if (fdUDP)
    close(fdUDP);
  if (fdTCPlisten)
    close(fdTCPlisten);
  if (fdTCP)
    close(fdTCP);

  if (unlinkOK)
	unlink(pidpath());	/* remove pid file	*/

  /* shut down syslog connection */
  if(parent)
    LogPrint(str3);
  if(logopen)
    closelog();
  /* error exit if not SIGTERM  */
  if (sig != SIGTERM)
    exit(1);
  exit(0);
}

void
ToggleLogging(int sig) {
  extern int datalog, savedatalog, oflag;
  extern char format5[], str19[], str20[], str21[];
  char logbuffer[255];
  if((datalog == 0) && (savedatalog == 0)) {
    datalog = 1;
    sprintf(logbuffer, str19, sig);
    goto logit;
  } else {
    if(savedatalog != 0) {
      datalog = savedatalog;
      savedatalog = 0;
      sprintf(logbuffer, str20, sig, datalog);
      goto logit;
    } else {
      savedatalog = datalog;
      datalog = 0;
      sprintf(logbuffer, str21, sig, datalog);
      goto logit;
    }
  }
  return;
  logit:
  if(oflag)
    printf(format5, logbuffer);
  else
    syslog(INFOTYPE, logbuffer);
}

void
ZoneDump(int sig)
{
  extern int zone_request;

  zone_request = 1;
  LogPrint(str1); 
}

void
SigHup(int sig)
{
  extern int datalog;
  if (datalog > 1)
    LogPrint(str4);
  return;	/* ignore */
}

void
SigChild(int sig)
{
  extern pid_t zonechild;

  pid_t rv;
  if (sig == SIGCHLD) {
    do {
      rv = waitpid(-1, NULL, WNOHANG);
      if (zonechild && zonechild == rv)
      	zonechild = 0;
    } while (rv > 0);
  }
  return;
}

void
q_handler (int sig)
{
  switch (sig) {
	case SIGALRM	: CleanExit(sig);
			  break;
	case SIGUSR1	: ToggleLogging(sig);
			  break;
	case SIGUSR2	: ZoneDump(sig);
			  break;
	case SIGCHLD	: SigChild(sig);
			  break;
	case SIGHUP	: SigHup(sig);
			  break;
	case SIGINT	:
	case SIGQUIT	:
	case SIGTERM	: CleanExit(sig);
			  break;
  }
}

void
set_signals (void)
{
  extern struct sigaction sa;

  sa.sa_handler = q_handler;
  sigemptyset (&sa.sa_mask);
  sigaddset (&sa.sa_mask, SIGTERM);
  sigaddset (&sa.sa_mask, SIGHUP);
  sigaddset (&sa.sa_mask, SIGUSR1);
  sigaddset (&sa.sa_mask, SIGUSR2);
  sigaddset (&sa.sa_mask, SIGQUIT);
  sigaddset (&sa.sa_mask, SIGINT);
  sigaddset (&sa.sa_mask, SIGALRM);
  sigaddset (&sa.sa_mask, SIGCHLD);
  sa.sa_flags = 0;
  sigaction (SIGCHLD, &sa, NULL);
  sigaction (SIGALRM, &sa, NULL);
  sigaction (SIGINT, &sa, NULL);
  sigaction (SIGQUIT, &sa, NULL);
  sigaction (SIGUSR1, &sa, NULL);
  sigaction (SIGUSR2, &sa, NULL);
  sigaction (SIGTERM, &sa, NULL);
  sigaction (SIGHUP, &sa, NULL);
}

