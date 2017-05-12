/* misc.c
 *
 * Portions of this file are adapted from LaBrea by Tom Liston <tliston@premmag.com>, Copyright (C) 2001, 2002
 #
 * Portions copyright 2003 - 2009, Michael Robinton <michael@bizsystems.com>
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
#include <unistd.h>
#include <sys/time.h>
#include <signal.h>
#include <syslog.h>
#include <signal.h>
#ifdef DBTARPIT_SUPPORTED_OS_LINUX
 #include <libipq.h>
#endif
#include "defines.h"
#include "fifo_func.h"
#include "util_pid_func.h"

unsigned long
initRandGen(int seed)
{
  struct timeval tseed;
if (seed) {
  tseed.tv_sec = seed;
  tseed.tv_usec = 0;
}
  else
    gettimeofday(&tseed, NULL);
  seed = (unsigned)(tseed.tv_sec ^ tseed.tv_usec);
  srandom(seed);
  return(seed);
}

void
fillRandGen(unsigned long * rq, int size)
{
  int c;
  for(c = 0; c < size; c++)
    *(rq + c) = random() % 0xffffffff;
}

/* return true if fifo is up	*/
int
FifoUp()
{
  extern int fifofd;
  extern char * fifoname, * dbhome;
  char fifo_path[255];
  
  if (fifofd <= 0) {
    strcpy(fifo_path,dbhome);
    strcat(fifo_path,"/");
    strcat(fifo_path,fifoname);
    if (make_fifo(fifo_path))
	return(0);
    if (open_fifo(&fifofd,fifo_path))
    	return(0);
  }
  return(1);
}
    
void
LogPrint(char * message)
{
  extern char * fifoname;
  extern int oflag;
  extern int fifofd;

  if (fifoname != NULL) {
    if(FifoUp())
	(void)write_fifo(fifofd,message);
  }
  else {
    if(oflag)
      printf("%s\n",message);
    else
      syslog(INFOTYPE, message);
  }
}

void
CleanExit(int sig)
{
  extern DBTPD dbtp;
  extern int logopen, unlinkOK;
  /* close the database and environment	*/
  dbtp_close(&dbtp);

  if(unlinkOK)
	unlink(pidpath());	/* zap pid file	*/

#ifdef DBTARPIT_SUPPORTED_OS_LINUX

  if (h) {
    ipq_destroy_handle((ipq_handle *)h);
    h = NULL;
  }

#endif

  /* shut down syslog connection */
  LogPrint(str3);
  if(logopen)
    closelog();
  /* error exit if not SIGTERM 	*/
  if (sig != SIGTERM)
    exit(1);
  exit(0);
}

void
ToggleLogging(int sig) {
  extern char * fifoname;
  extern int datalog, savedatalog, oflag;
  extern char str19[], str20[], str21[];
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
  if(fifoname != NULL) {
    strcat(logbuffer,"\n");
    LogPrint(logbuffer);
  }
  else if(oflag) {
    strcat(logbuffer,"\n");
    LogPrint(logbuffer);
  }
  else
    syslog(INFOTYPE, logbuffer);
}

void
ServiceTimer(int sig) {
  extern int totalbw, maxbw, bflag, oflag, rflag;
  extern int currentbandwidth, past[], newthisminute;
  extern char mybuffer[], bwstr[], format5[];
  extern int fifofd;
  extern char * fifoname;    
  int avgbw, i;
  totalbw -= past[4];
  for(i = 4; i; i--)
    past[i] = past[i - 1];   
  past[0] = currentbandwidth;
  totalbw += past[0];  
  currentbandwidth = 0; 
  avgbw = totalbw / 300;

  if(bflag) {
    sprintf(mybuffer, bwstr, avgbw);
    if (fifoname != NULL) {
      if(FifoUp())
	strcat(mybuffer,"\n");
	(void)write_fifo(fifofd,mybuffer);
    } 
    else {
      if(oflag)
        printf(format5, mybuffer);
      else
        syslog(LOGTYPE, mybuffer);
    }
  }
      /* this allows for a "soft" restart by       */
  /* letting 5 minutes go by before allowing   */
  /* any new connections are captured.         */
  /* if you restart with this enabled, then    */
  /* it should "recapture" the old stuff, and  */
  /* base the bw calc on that before grabbing  */
  /* anything new...                           */
  /* I got bit by this... that's why I thought */
  /* to do it...                               */
  if(rflag) 
    rflag--;
  else
    /* an attempt to keep bw in line when you're  */
    /* getting hammered.  limit new connections   */
    /* that we'll allow to be captured per minute */
    newthisminute = maxbw - avgbw;
  if(newthisminute < 0)
    newthisminute = 0;
  alarm(60);
}

void
SigHup(int sig)
{
  return;	/* ignore */
}

void
q_handler (int sig)
{
  switch (sig) {
	case SIGALRM	: ServiceTimer(sig);
			  break;
	case SIGUSR1	: ToggleLogging(sig);
			  break;
	case SIGHUP	: SigHup(sig);
			  break;
	case SIGINT	:
	case SIGQUIT	:
	case SIGTERM	: CleanExit(sig);
			  break;
/*	case SIGPIPE	: SIG_IGN;
			  break;	this is a no-op	*/
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
  sigaddset (&sa.sa_mask, SIGQUIT);
  sigaddset (&sa.sa_mask, SIGINT);
  sigaddset (&sa.sa_mask, SIGALRM);
  sigaddset (&sa.sa_mask, SIGPIPE);
  
  sa.sa_flags = 0;
  sigaction (SIGALRM, &sa, NULL);
  sigaction (SIGINT, &sa, NULL);
  sigaction (SIGQUIT, &sa, NULL);
  sigaction (SIGUSR1, &sa, NULL);
  sigaction (SIGTERM, &sa, NULL);
  sigaction (SIGHUP, &sa, NULL);
  sigaction (SIGPIPE, &sa, NULL);
}

