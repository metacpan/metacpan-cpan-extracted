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
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <resolv.h>
#include <fcntl.h>
#include <bdbtarpit.h>

#if DBTP_MAJOR == 0
# if DBTP_MINOR == 0
#  if DBTP_PATCH < 1
#   error requires IPTables::IPv4::DBTarpit version 0.21 or higher
#  endif
# endif
#endif

#ifndef INADDR_NONE
#define INADDR_NONE INADDR_BROADCAST 
#endif

#include "defines.h"
#include "data.c"
#include "misc.c"
#include "godaemon.c"
#include "util_pid_func.h"
#include "netio_func.h"
#include "misc_func.h"

#define MY_DBerrorstatus 1

DBTPD dbtp;
char default_dbh[] = "/var/run/dbtarpit";
char * dbhome = default_dbh;
char defsockname[] = "bdbread", * sockname = defsockname;
char mybuffer[1024], * rtn;
int logopen = 0, datalog = 0, savedatalog = 0, inetd = 0;
int run, dflag = 0, oflag = 0, fd = 0, fdlisten = 0, port = 0;
pid_t pidrun, parent = 1;
struct sigaction sa;

int main(int argc, char **argv) {
  run = 1;
  return(realMain(argc,argv));
}

int realMain(int argc, char **argv)
{
  extern u_char my_msgbuf[];
  extern DBTPD dbtp;
      
  char getoptstr[] = "r:f:s:ip:dlVvT?ho";
  char c, * pidpathname, shortbuf[255];
  int testflag = 0, dbnp = 0, i, status, fdlisten = 0, fd = 0;
  sigset_t set;
  size_t msglen;
  struct stat sbuf;
  int32_t notfound[] = {INADDR_NONE,DB_NOTFOUND};
  u_char how;
  u_int32_t recno, atmp;
  
  sigemptyset(&set);
  sigprocmask(SIG_SETMASK, &set, NULL);
  set_signals();

  bzero(&dbtp,sizeof(DBTPD));

  /* parse the command line */
  while((c = getopt(argc, argv, getoptstr)) != EOF) {
    switch(c) {
      case 'r':
      	dbhome = optarg;
	break;
      case 'f':
        dbtp.dbfile[dbnp++] = optarg;
	break;
      case 's':
	if (inetd == 0 && port == 0)
          sockname = optarg;
        break;
      case 'd':
        dflag = 1;
        break;
      case 'i':
        inetd = dflag = 1;
	break;
      case 'p':
        sockname = defsockname;
        port = atoi(optarg);
	break;
      case 'o':
      	dflag = 1;
      	oflag = 1;
      	break;
      case 'l':
      	datalog += 1;
      	break;
      case 'V':
      case 'v':
        rtn = version;
        goto ErrorExit;
      case 'T':
        testflag = 1;
        break;
      case '?':
      case 'h':   
      default:
	printf(helpstring);
	CleanExit(0);
        break;
    }
  }
  if(testflag) {
    printf("dbhome      -r	=> %s\n", dbhome);
    for(i=0; i<dbnp; i++) {
      printf("dbfile      -f	=> %s\n", dbtp.dbfile[i]);
    }
    printf("socket_name -s	=> %s\n", sockname);
    printf("inetd		=> %d use inetd\n", inetd);
    printf("port		=> %d port number\n", port);
    printf("dflag		=> %d no daemon\n", dflag);
    printf("oflag		=> %d log to stdout\n",oflag);
    printf("loglvl		=> %d log enabled > 0\n", datalog);
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

/* verify that db file names have been added	*/
  if(dbnp == 0) {
    rtn = mybuffer;
    sprintf(rtn, "Error: -f, you must specify at least one database name");
    goto ErrorExit;
  }
  
  if(inetd == 0) {

    if((pidpathname = chk4pid(NULL)) == NULL) {	/* bail if another bdbreader is running	*/
      rtn = mybuffer;
      sprintf(rtn, "%d already running", pidrun);
      goto ErrorExit;
    }

    if(port == 0 && (strlen(dbhome) + strlen(sockname) + 2) > 104) {
      rtn = mybuffer;
      sprintf(rtn, "path /dbhome/sockname + null exceeds 104 bytes");
      goto ErrorExit;
    }
  
    if(!dflag && !testflag)
      godaemon();

    savpid(pidpathname);
  
  /* tell 'em we're here... */
    openlog(argv[0],0,LOGFAC);
    LogPrint(diag13);

/*	init domain socket
 *	wait for message
 *	forkchild
 *	    child open db
 *	    child go service then exit
 *
 */

/* init socket	*/
  
    if ((fdlisten = init_socket()) == 0) {
      rtn = err27;
      goto ErrorExit;
    }
    sigprocmask (SIG_UNBLOCK, &sa.sa_mask, 0);

} /* end if inetd == 0	*/


  /* loop! */
  while (run) {
    if (inetd)
    	run = 0;
    else {
      if ((fd = accept_client(fdlisten)) == 0)
        continue;				/* failed to connect	*/
    }
    if(inetd || (parent = forkchild()) == 0) {		/* child		*/
      if(inetd == 0)
        close(fdlisten);			/* close listening socket	*/

      savpid(pidpath());				/* register child PID		*/
      
      if((msglen = read_msg(fd)) > 0) {
	if (datalog) {
	  rtn = mybuffer;
	  strcpy(rtn,(char *)(my_msgbuf +5));
	  strcat(rtn,", ");
	}
	if ((i = dbtp_index(&dbtp,(char *)(my_msgbuf +5))) < 0) {
	  status = DB_NOTFOUND;
      ReturnNotFound:
	  notfound[MY_DBerrorstatus] = (int32_t)status;
	  if (datalog) {
	    strcat(rtn,db_strerror((int)(notfound[MY_DBerrorstatus])));
	    LogPrint(rtn);
	  }
	  notfound[MY_DBerrorstatus] = htonl(notfound[MY_DBerrorstatus]);
	  write_msg(fd,(u_char *)notfound,8);
	  goto CleanUp;
	}
	if ((status = dbtp_init(&dbtp,(u_char *)dbhome,i)))
	  goto ReturnNotFound;

	if((how = *my_msgbuf) < 2) {			/* normal - single item read	*/
	  memcpy((u_char *)&atmp,my_msgbuf +1,4);	/* move address pointer off odd address boundry */
/*	  if (notfound[MY_DBerrorstatus] = (int32_t)dbtp_readOne(&dbtp,how,i,(void *)&atmp,1)) */
	  if ((status = dbtp_readOne(&dbtp,how,i,(void *)&atmp,1)))
		goto ReturnNotFound;
		
	  memcpy(my_msgbuf,dbtp.keydbt.data,dbtp.keydbt.size);
	  msglen = (size_t)dbtp.keydbt.size;
	  memcpy((void *)(my_msgbuf + msglen),dbtp.mgdbt.data,dbtp.mgdbt.size);
	  msglen += dbtp.mgdbt.size;
	  status = write_msg(fd,my_msgbuf,msglen);
	}
	else {					/* multi key read	*/
	  memcpy((u_char *)&atmp,my_msgbuf +1,4);	/* move address pointer off odd address boundry */
	  recno = ntohl(atmp);
	  msglen = 1;				/* size of message now	*/
	  *my_msgbuf = 0;			/* record count		*/
	  while (*my_msgbuf < how) {
  /* note that the 'is_network' parameter is set to zero since 'recno' is converted to host order */
	    if ((status = dbtp_readOne(&dbtp,1,i,(void *)&recno,0)))
	    	break;
	    memcpy((u_char *)(my_msgbuf + msglen),dbtp.keydbt.data,dbtp.keydbt.size);	      
	    msglen += dbtp.keydbt.size;
	    *my_msgbuf += 1;
	    recno++;
	  }
	  status = write_msg(fd,my_msgbuf,msglen);
	}
	if (datalog) {
	  sprintf(shortbuf,"%d bytes sent",msglen);
	  strcat(rtn,shortbuf);
	  LogPrint(rtn);
	}
      }
    CleanUp:
      dbtp_close(&dbtp);
      close(fd);
      unlink(pidpath());
      exit(0);
    }
    else
      close(fd);	/* parent, close connected socket	*/
  }
  rtn = err20;

ErrorExit:
  fprintf(stderr, err25, rtn);
  CleanExit(0);
  return(0);
}
