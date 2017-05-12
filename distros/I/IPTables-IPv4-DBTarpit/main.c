/* main.c
 *
 * Adapted from ipt_TARPIT.c by Aaron Hopkins <tools@die.net> Copyright (c) 2002 
 * and LaBrea.c by Tom Liston <tliston@premmag.com> Copyright (C) 2001, 2002
 * with additions from the libipq library and other sources.
 *
 * THIS PROGRAM REQUIRES an installed linux kernel SOURCE
 * configured with IPTABLES and NETFILTER
 *
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

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

#include <stdlib.h>
#include <stdio.h>
#include <db.h>

#include "defines.h"
#include "bdbtarpit.h"
#include "util_pid_func.h"

#include "data.c"
#include "godaemon.c"
#include "misc.c"
#include "check.c"

DBTPD dbtp;
short throttlesize = 10;
int star = 0, sflag = 0, currentrand1=0, run = 0;
int logopen = 0, datalog = 0, xflag = 0, Xflag = 0, kflag = 0, aflag = 0, Pflag = 0, Dflag =0;
int currentbandwidth = 0, maxbw = 0, pflag = 0, past[5] = {0,0,0,0,0}, oflag = 0;
int bflag = 0, savedatalog = 0, newthisminute = 0, rflag = 0, testflag = 0;
int Oflag = 0, totalbw = 0, currentrand2 = 0, Lflag = 0;
int dummy_tarpit, trace_tarpit = 0;
char mybuffer[1024], mybuffer2[1024], tnow[100], *rtn;
char default_dbh[] = "/var/run/dbtarpit", default_dbf[] = "tarpit";
char * dbhome = default_dbh;
char  * fifoname = NULL;
int fifofd = 0;


#ifdef DBTARPIT_SUPPORTED_OS_LINUX

ipq_packet_msg_t * m;
void * ipq_h = NULL;

#endif

unsigned long randqueue1[RANDSIZE1], randqueue2[RANDSIZE2];
struct sigaction sa;
pid_t pidrun;

static void __inline Usage(void) {
  extern char helpstring[];
  printf(helpstring);
  CleanExit(0);
}

int realMain(int argc, char **argv) {
  sigset_t set;
  struct stat sbuf;
  int c, dflag = 0, status;
  char * pidpathname;
  struct ipq_handle * h = NULL;
  
  sigemptyset(&set);
  sigprocmask(SIG_SETMASK, &set, NULL);
  set_signals();

  bzero(&dbtp,sizeof(DBTPD));
  dbtp.dbfile[DBtarpit] = default_dbf;
  dbtp.dbfile[DBarchive] = NULL;

  /* parse the command line */
  while((c = getopt(argc, argv, getoptstr)) != EOF) {
    switch(c) {
      case 'u':
	fifoname = optarg;
	oflag = Oflag = 0;
	break;
      case 'r':
      	dbhome = optarg;
	break;
      case 'f':
        dbtp.dbfile[DBtarpit] = optarg;
	break;
      case 's':
        dbtp.dbfile[DBarchive] = optarg;
        break;
      case 'O':
	if (fifoname == NULL)
	  Oflag = oflag = dflag = 1;
        break;
      case 'o':
	if (fifoname == NULL)
	  dflag = oflag = 1;
        break;
      case 'd':
        dflag = 1;
        break;
      case 'T':
        testflag = 1;
        break;
      case 'R':
        rflag = 5;
        break;
      case 'D':
      	Dflag = 1;
      	break;
      case 'x':
        xflag = 1;
        break;
      case 'X':
	Xflag = 1;
	break;
      case 'b':
        bflag = 1;
        break;
      case 'v':
        datalog += 2;
        break;
      case 'k':
        kflag = 1;
        break;
      case 'a':
      	aflag = 1;
	xflag = 1;
      	break;
      case 'l':
        datalog += 1;
        break;
      case 't':
        throttlesize = atoi(optarg);
        break;
      case '?':
      case 'h':
        Usage();
        break;
      case 'P':
        Pflag = 1;
        break;
      case 'p':
        maxbw = atoi(optarg);
        pflag = 1;
        if(maxbw < 1)
          Usage();
        break;
      case 'L':
      	Lflag = 1;
      	break;
      case 'V':
        rtn = version;
        goto ErrorExit;
      default:
        Usage();
        break;
    }
  }

#ifdef DBTARPIT_SUPPORTED_OS_LINUX

  if(throttlesize > BUFSIZE - sizeof(ipq_packet_msg_t)) {
    rtn = err10;
    goto ErrorExit;
  }

#endif

  if(pflag) {
    throttlesize = 3;
    newthisminute = maxbw;
  }
  /* line buffer the output */
  if(oflag)
    setlinebuf(stdout);

  if(Pflag && pflag == 0)
      Pflag = 0;

  if(testflag) {
    printf("dbhome		=> %s\n", dbhome);
    printf("dbprimary	=> %s\n", dbtp.dbfile[DBtarpit]);
    printf("dbsecondary	=> %s\n", dbtp.dbfile[DBarchive]);
    printf("fifo_name	=> %s\n", fifoname);
    printf("lflag		=> %d log enabled > 0\n", datalog);
    printf("vflag		=> %d verbose >= 2\n", datalog);
    printf("oflag		=> %d log to stdout\n", oflag);
    printf("Oflag		=> %d 'o' w/ t = seconds\n", Oflag);
    printf("bflag		=> %d log bandwidth usage\n", bflag);
    printf("dflag		=> %d no daemon\n", dflag);
    printf("aflag		=> %d allow all connections\n", aflag);
    printf("xflag		=> %d disable IP capture\n", xflag);
    printf("Xflag		=> %d enable non-TCP/IP DoS defense\n", Xflag);
    printf("Rflag		=> %d soft restart\n", rflag);
    printf("kflag		=> %d no response SYN/ACK\n", kflag);
    printf("tflag		=> %u throttle size default 10\n", throttlesize);
    printf("Pflag		=> %d persist capture only\n", Pflag);
    printf("pflag		=> %u persist capture, max bw >0 \n", maxbw);
    printf("Lflag		=> %d 127.x.x.x capture enabled\n", Lflag);
    printf("Tflag		=> %d test mode\n", testflag);
    CleanExit(0);
  }

  if(stat(dbhome,&sbuf)) {	/* bail out if dbhome directory does not exist	*/
    rtn = mybuffer;
    strcpy(rtn, dbhome);
    strcat(rtn, ", ");
    strcat(rtn, strerror(errno));
    goto ErrorExit;
  }

  if(!S_ISDIR(sbuf.st_mode)) {	/* bail if exists but not a directory	*/
    rtn = mybuffer;
    strcpy(rtn, dbhome);
    strcat(rtn, " is not a directory");
    goto ErrorExit;
  }

  if((pidpathname = chk4pid(NULL)) == NULL) {	/* bail if another dbtarpit is running	*/
    rtn = mybuffer;
    sprintf(rtn, "%d already running", pidrun);
    goto ErrorExit;
  }

  if(dflag == 0 && testflag == 0) {
    godaemon();
  }

  savpid(pidpathname);
  
  (void)initRandGen(0);
  fillRandGen(randqueue1, RANDSIZE1);
  fillRandGen(randqueue2, RANDSIZE2);

  /* tell 'em we're here... */
  openlog(argv[0],0,LOGFAC);
  LogPrint(diag13);

  /* initialize the database interface	*/
  if ((status = dbtp_init(&dbtp,(unsigned char *)dbhome,-1))) {
    rtn = db_strerror(status);
    goto ErrorExit;
  }

#ifdef DBTARPIT_SUPPORTED_OS_LINUX
#ifndef DBTARPIT_IPQ_CREATE_ARGS
#error no dbtarpit_ipq_create_args defined
#endif
  /* initialize the IPQUEUE interface	*/
  if (run) {
#if DBTARPIT_IPQ_CREATE_ARGS == 1		/* old library		*/
    h = ipq_create_handle(0);
#else						/* the newer library	*/
    h = ipq_create_handle(0,PF_INET);
#endif
  }
  if ((ipq_h = (void *)h) == NULL) {
    rtn = errIPQ1;
    goto ErrorExit;
  }
  status = ipq_set_mode(h, IPQ_COPY_PACKET, BUFSIZE);
  if (status < 0) {
    rtn = ipq_errstr();
    goto ErrorExit;
  }

#endif

  /* fire off an alarm if we're doing persist state capture */
  if(pflag)
    alarm(60);
  /* loop! */
  while (run) {

#ifdef DBTARPIT_SUPPORTED_OS_LINUX

    status = ipq_read(h, buf, BUFSIZE, 0);

#endif

    sigprocmask (SIG_BLOCK, &sa.sa_mask, 0);	/* hold signals */

#ifdef DBTARPIT_SUPPORTED_OS_LINUX

    if (status > 0 && (ipq_message_type(buf) == IPQM_PACKET))
      (void)check_4_tarpit(ipq_get_packet(buf));

#endif

    sigprocmask (SIG_UNBLOCK, &sa.sa_mask, 0);
  }

  rtn = errIPQ3;

ErrorExit:
  fprintf(stderr, err25, rtn);
  CleanExit(0);
  return(0);
}

int main(int argc, char **argv) {
  check_no_support();
  run = 1;
  return(realMain(argc,argv));
}
