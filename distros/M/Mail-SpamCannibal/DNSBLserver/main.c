/* main.c
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

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <time.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <resolv.h>
#include <fcntl.h>
#include <sys/file.h>
#include <bdbtarpit.h>

#if DBTP_MAJOR == 0
# if DBTP_MINOR == 0
#  if DBTP_PATCH < 1
#   error requires IPTables::IPv4::DBTarpit version 0.21 or higher
#  endif
# endif
#endif

#include "defines.h"
#include "data.c"
#include "misc.c"
#include "godaemon.c"
#include "host_info_func.h"
#include "util_pid_func.h"
#include "zonedump.c"
#include "ns_func.h"
#include "misc_func.h"
#include "netio_func.h"

/*
  -z   : Zone Name: bl.domain.com      [default: this hostname]
  -n   : Name Servers: abc.domain.com (Note 1)
  -N   : same as -n, but sets host name (Note 1)
  -a   : NS Address xxx.xxx.xxx.xxx    [default: lookup via DNS]
 ...there can be more than one set of entrys
  -n   : Another NS dul.domain.com (up to 15)
  -a   : eth0 NS Address yyy.yyy.yyy.yyy
  -a   : eth1 another NS Address (up to 10)
  -m   : 10 mark preference for MX entry (Note 2)

  -s   : 60 : SOA negative caching interval
  -u   : 43200 : SOA update/refresh interval
  -y   : 3600  : SOA retry interval
  -x   : 86400 : SOA expire
  -t   : 10800 : SOA ttl/minimum

  -c   : SOA zone contact: contact@somewhere.com

  -e   : ERROR: this RBL's error message  "http://....."
  -b   : Block AXFR transfers
  -L   : Limit zonefile build transfer rate (default 200,000 cps)
  -C   : Continuity (default allow zonefile discontinuity)

  -r   : Alternate DB root directory   [default: /var/run/dbtarpit]
  -i   : Alternate tarpit DB file      [default: tarpit]
  -j   : Alternate contrib DB file     [default: blcontrib]
  -k   : Alternate evidence DB file    [default: evidence]

  -p   : Port number [default: 53]
  -d   : Do NOT detach process.
  -l   : Log activity to syslog (Note 3)
  -v   : Verbose logging to syslog
  -o   : Output to stdout instead of syslog (Note 4)
  -V   : Print version information and exit
  -T   : Test mode - Print out debug info and exit
  -P   : Enable promiscious reporting of contributed entries (Note 5)
  -Z   : Zap TXT records in zonefile dump, A records ONLY
  -g   : Internal test flag - tcpmode, see ns.c, t/ns.t, CTest.pm::t_mode
  -h   : Print this help information
  -?   : Print this help information
 */

DBTPD dbtp;
char default_dbh[] = "/var/run/dbtarpit", * dbhome = default_dbh;
char default_dbi[] = "tarpit", default_dbj[] = "blcontrib", default_dbk[] = "evidence";
char * zone_name = NULL, * contact = NULL, rname[MAXDNAME], undef_err[] = "undefined", * errormsg = undef_err; 
u_int32_t * Astart, * Aptr;
char mybuffer[1024], * rtn;
int logopen = 0, datalog = 0, savedatalog = 0;
int run, zone_name_len, zoneEQlocal, port = 53, zone_request = 0;
int dflag = 0, oflag = 0, bflag = 0, zflag = 0, qflag = 0, Zflag = 0, stop = 0, continuity = 0;
int fdUDP = 0, fdTCPlisten = 0, fdTCP = 0;
u_int32_t refresh = 43200, retry = 3600, expire = 86400, minimum = 10800, soa_ttl = 0;
u_int32_t diskmax = 200000;
pid_t pidrun, parent = 1;
struct sigaction sa;
struct in_addr stdResp, stdRespBeg, stdRespEnd, serial_rec;

int main(int argc, char **argv) {
  run = 1;
  return(realMain(argc,argv));
}

int realMain(int argc, char **argv)
{
  extern int h_name_ctr;	/* name service buffer ring pointer	*/
  extern char * local_name;
  extern int mxmark[];
  extern int bflag, zone_request;
  extern struct in_addr stdResp, stdRespBeg, stdRespEnd, serial_rec;
  
  char getoptstr[] = "L:z:a:n:N:s:u:y:x:m:t:c:e:g:br:i:j:k:p:dlvPVTZ?ho";
  char c, * nsname = NULL, * pidpathname;
  int nstore = 0, Mptr = 0, mxsave = 0, aflag = 0, status = 0, testflag = 0, gflag = 1;
  int flags, maxfd, ready;
  struct stat sbuf;
  struct in_addr in;
  sigset_t set;
  fd_set rset;
  size_t msglen;
  struct timeval tloop;

  sigemptyset(&set);
  sigprocmask(SIG_SETMASK, &set, NULL);
  set_signals();

  bzero(&dbtp, sizeof(DBTPD));
  dbtp.dbfile[DBtarpit] = default_dbi;
  dbtp.dbfile[DBcontrib] = default_dbj;
  dbtp.dbfile[DBevidence] = default_dbk;

  bflag = 0;
/* here's the way zone and name server additions work.
 * if at the end of options, there is no zone name,
 * zone name = long local host name
 *
 * if at the end of options "for a particular name server"
 * if there are no "A" records
 * A = lookup using resolver
 * 
 * When a nameserver is specified, all A records following are
 * appended to it's description until a new nameserver is specified
 */

  /* parse the command line */
  while((c = getopt(argc, argv, getoptstr)) != EOF) {
    switch(c) {
      case 'z':
	zone_name = optarg;
	break;

      case 'N':
      	local_name = optarg;
      case 'n':
	if (nsname != NULL && aflag == 0) {
	  if((status = add_ns_info(nsname,aflag)))
		goto Error_nsname;
	}
	mxmark[Mptr] = mxsave;	/* stash any mx mark	*/

/*	must retrieve Aptrs for next entry before h_name_ctr is incremented	*/
	Aptr = Astart = current_Astart(h_name_ctr);
	Mptr = h_name_ctr;
	nsname = optarg;
	aflag = 0;
	mxsave = 0;
	nstore = 0;
	break;

      case 'a':
        if (nsname == NULL) {
	  status = 0;		/* duh...	*/
	  goto Error_nsname;
	}
	aflag = 1;
	if (nstore == 0) {
	  if ((status = add_ns_info(nsname,aflag)))
		goto Error_nsname;
	  mxmark[Mptr] = mxsave;
	  nstore = 1;
	}
	if ((inet_aton(optarg, &in)) == 0) {
	  status = 0;		/* double duh...	*/
	  rtn = mybuffer;
	  sprintf(rtn, "Error: -n, illegal characters or leading 0's in dotquad address");
	  goto ErrorExit;
	}
	Aptr = insert_A_record(Astart, Aptr, (u_int32_t)in.s_addr);
	break;

      case 'm':
      	if (nsname == NULL) {
	  rtn = mybuffer;
	  strcat(rtn, "Error: -n, name must preceed -m MX marker");
	  goto ErrorExit;   
	}
	mxmark[Mptr] = mxsave = atoi(optarg);
	break;

      case 'u':
      	refresh = strtoul(optarg,NULL,0);
      	break;
      case 'y':
      	retry = strtoul(optarg,NULL,0);
	break;
      case 'x':
	expire = strtoul(optarg,NULL,0);
	break;
      case 't':
      	minimum = strtoul(optarg,NULL,0);
	break;
      case 's':
      	soa_ttl = strtoul(optarg,NULL,0);
      	break;
      case 'c':
      	contact = optarg;
      	break;
      case 'e':
      	errormsg = optarg;
      	break;
      case 'b':
      	bflag = 1;
      	break;
      case 'L':
        diskmax = strtoul(optarg,NULL,0);
      case 'C':
        continuity = 1;
      case 'g':
      	gflag = atoi(optarg);
      	break;
      case 'r':
      	dbhome = optarg;
	break;
      case 'i':
        dbtp.dbfile[DBtarpit] = optarg;
	break;
      case 'j':
        dbtp.dbfile[DBcontrib] = optarg;
        break;
      case 'k':
        dbtp.dbfile[DBevidence] = optarg;
        break;
      case 'p':
        port = atoi(optarg);
	break;
      case 'd':
        dflag = 1;
        break;
      case 'o':
      	dflag = 1;
      	oflag = 1;
      	break;
      case 'l':
      	datalog += 1;
      	break;
      case 'v':
      	datalog += 2;
      	break;
      case 'V':
        rtn = version;
        goto ErrorExit;
      case 'T':
        testflag = 1;
        break;
      case 'P':
	zflag = 1;
	break;
      case 'Z':
	Zflag = 1;
	break;
      case '?':
      case 'h':   
      default:
	printf(helpstring);
	CleanExit(0);
        break;
    }
  }
/*	add any dangling name service entries	*/
  if (nsname != NULL && aflag == 0) {
    if ((status = add_ns_info(nsname,aflag))) {
Error_nsname:
      rtn = mybuffer;
      sprintf(rtn, "Error: %d, could not add host info to cache",status);
      goto ErrorExit;
    }
    mxmark[Mptr] = mxsave;
  }

/*	get the local host name			*/
  if (set_local_name()) {
    rtn = mybuffer;
    sprintf(rtn, "Error: %d, could not get local host name",status);
    goto ErrorExit;
  }

/*	make sure there is a zone name		*/
  if (zone_name == NULL)
	zone_name = local_name;

  zone_name_len = strlen(zone_name);
/* 	set standard response for our tarpit	*/
  inet_aton("127.0.0.2",&stdResp);
  inet_aton("127.0.0.3",&stdRespBeg);		/* beginning allowed response code */
  inet_aton("127.255.255.255",&stdRespEnd);	/* ending allowed response code	*/
/*	set pointer for SOA serial number	*/
  inet_aton("127.0.0.0",&serial_rec);

  if (strcasecmp(zone_name, local_name) == 0) {
  	zoneEQlocal = 1;
  } else
  	zoneEQlocal = 0;
  
  if (contact == NULL) {
    sprintf(rname, "root.%s", zone_name);
  } else {
    strncpy(rname, contact, MAXDNAME);
    if ((contact = strchr(rname,(int)('@'))) != NULL)
    	*contact = '.';				/* substitute a '.' for '@' in the email address	*/
  }
  contact = rname;
  
  if (errormsg != undef_err && strchr(errormsg,'?') != NULL)
  	qflag = 1;				/* error message contains question mark, append address */
  
  if(testflag) {
    if (stop)			/* if testing and no STDOUT is wanted	*/
	return(0);
    printf("dbhome      -r	=> %s\n", dbhome);
    printf("tarpit      -i	=> %s\n", dbtp.dbfile[DBtarpit]);
    printf("contrib     -j	=> %s\n", dbtp.dbfile[DBcontrib]);
    printf("evidence    -k	=> %s\n", dbtp.dbfile[DBevidence]);
    printf("block		=> %d AXFR transfers blocked\n", bflag);
    printf("Limit       -L	=> %dcps, maximum zonefile build rate\n", diskmax);
    printf("Continuity  -C	=> %d continuity\n", continuity);
    printf("eflag		=> %s\n",errormsg);
    printf("qflag		=> %d append IP address\n", qflag);
    printf("dflag		=> %d no daemon\n", dflag);
    printf("oflag		=> %d log to stdout\n", oflag);
    printf("loglvl		=> %d log enabled > 0\n", datalog);
    printf("port		=> %d port number\n", port);
    printf("Tflag		=> %d test mode\n", testflag);
    printf("promiscuous	=> %d reporting enabled\n", zflag);
    printf("zone		=> %s\n", zone_name);
    printf("Zflag		=> %d Zap zone file TXT records\n", Zflag);
    printf("contact		=> %s\n", contact);
    printf("sflag		=>	%d	SOA ttl/negative caching\n", soa_ttl);
    printf("uflag		=>	%d	SOA update/refresh\n", refresh);
    printf("yflag		=>	%d	SOA retry\n", retry);
    printf("xflag		=>	%d	SOA expires\n", expire);
    printf("tflag		=>	%d	SOA ttl/minimum\n", minimum);
    printf("local records:\n");
    report_ns();
/*    CleanExit(0);	this is not needed	*/
    return(0);
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

/*	verify that Name Server records have been added	*/
  if(nsname == NULL) {
    rtn = mybuffer;
    sprintf(rtn, "Error: -n, you must specify at least one name server");
    goto ErrorExit;
  }
  
/*	verify that an error message has been entered	*/
  if (errormsg == undef_err) {
    rtn = mybuffer;
    sprintf(rtn, "Error: -e, you must specify a default error message");
    goto ErrorExit;
  }
  
  if((pidpathname = chk4pid(NULL)) == NULL) {	/* bail if another dnsbls is running	*/
    rtn = mybuffer;
    sprintf(rtn, "%d already running", pidrun);
    goto ErrorExit;
  }

  if(dflag == 0 && testflag == 0)
    godaemon();

  savpid(pidpathname);
  
  /* tell 'em we're here... */
  openlog(argv[0],0,LOGFAC);
  LogPrint(diag13);

/*	init sockets for tcp, udp
 * loop1
 *	init db
 * loop2
 *	wait for message
 *	if udp
 *	    go service
 *	    goto loop2
 *	if tcp
 *	    close db
 *	    forkchild
 *		parent goto loop1
 *		child open db
 *		child go service then exit
 *
 */

/* init sockets	*/
  if((fdUDP = init_socket(SOCK_DGRAM)) == 0) {
    rtn = err27;
    goto ErrorExit;
  }
  if((fdTCPlisten = init_socket(SOCK_STREAM)) == 0) {
    rtn = err28;
    goto ErrorExit;
  }
  if ((flags = fcntl(fdTCPlisten,F_GETFL,0)) == -1) {
    rtn = err29;
    goto ErrorExit;
  }
  if (fcntl(fdTCPlisten,F_SETFL,flags | O_NONBLOCK) < 0) {
    rtn = err30;
    goto ErrorExit;
  }

  FD_ZERO(&rset);
  if (fdUDP > fdTCPlisten)
    maxfd = fdUDP +1;
  else
    maxfd = fdTCPlisten +1;
   
  sigprocmask (SIG_UNBLOCK, &sa.sa_mask, 0);

  /* loop! */
  while (run) {

    FD_SET(fdUDP, &rset);
    FD_SET(fdTCPlisten, &rset);

    tloop.tv_sec = 1;		/* wake up every second		*/
    tloop.tv_usec = 0;
    if ((ready = select(maxfd,&rset,NULL,NULL,&tloop)) < 0) {
      if (errno == EINTR)
            continue;		/* child probably exited	*/
      else if (errno == EWOULDBLOCK)
            continue;		/* tcp not ready		*/
      else if (errno == ECONNABORTED)
            continue;		/* tcp aborted			*/
	
    } else if (zone_request) {
    
	zonedump();

    } else if (ready > 0) {

      if (FD_ISSET(fdUDP, &rset)) {	/* UDP first while db is open	*/
        if (dbtp.dbenv == NULL) {	/* initialize the database interface	*/
          if ((status = dbtp_init(&dbtp,(u_char *)dbhome,-1))) {
    BDBerror:
            rtn = mybuffer;
            sprintf(rtn,str30,status,db_strerror(status));
            goto ErrorExit;
          }
        }
	if((msglen = read_msg(fdUDP,0)) > 0)
	    munge_msg(fdUDP,msglen,0);
      }
      if (FD_ISSET(fdTCPlisten, &rset)) {
	if((fdTCP = accept_tcp(fdTCPlisten)) == 0)
	    continue;		/* sigh.... failed to connect	*/
	if (dbtp.dbenv != NULL)
	    dbtp_close(&dbtp);	/* close databases across fork	*/

	if((parent = forkchild()) == 0) {	/* child	*/
	  close(fdTCPlisten);
	  close(fdUDP);
	  fdTCPlisten = 0;
	  fdUDP = 0;

	/* set block socket access	*/
	  status = fcntl(fdTCP, F_GETFL, 0);
	  if (status != -1)
	  	(void) fcntl(fdTCP, F_SETFL, status & ~FNDELAY);
	  
	  savpid(pidpath());	/* register child pid file	*/

      CHILD_lingers:
	  if((msglen = read_msg(fdTCP,gflag)) <= 0) {
	    if (datalog > 1) {
	      LogPrint("child exit");
	    }
	    goto ErrorExit;
	  }
	  
	/* re-open database connection, if closed	*/
	  if (dbtp.dbenv == NULL) {
	    if ((status = dbtp_init(&dbtp,(u_char *)dbhome,-1)))
	  	goto BDBerror;
	  }
	  	  
	  munge_msg(fdTCP,msglen,gflag);

	/* wait for client network termination or next action	*/
	  goto CHILD_lingers;
	}
	/* else this is the parent	*/
	close(fdTCP);
	fdTCP = 0;
      }
    }
  }
  rtn = err20;

ErrorExit:
  if (parent)
    fprintf(stderr, err25, rtn);
  CleanExit(0);
  return(0);
}

