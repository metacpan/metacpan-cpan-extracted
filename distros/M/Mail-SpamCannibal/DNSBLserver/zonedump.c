/* zonedump.c
 *
 * Copyright 2004 - 2009, Michael Robinton <michael@bizsystems.com>
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

#include "config.h"
#include "zonefile.h"

void
zonedump()
{
  extern DBTPD dbtp;
  extern pid_t zonechild;
  extern char mybuffer[], * rtn, * dbhome, * zone_name;
  extern int parent, unlinkOK, zone_request, fdTCPlisten, fdUDP, fdTCP;
  
  FILE * fd;
  int retry = 3, zresult = -8, wbsize = 256 * 1024;
  char zonepath[512], wbuf[wbsize];
  struct stat fs;
  
  rtn = mybuffer;
  if (zonechild) {				/* punt if dump already in progress	*/
    if (kill(zonechild,0) == 0) {
      zone_request = 0;
      sprintf(rtn,"zone dump %d already running", zonechild);
      LogPrint(rtn);
      return;
    }
  }

  if (zone_request) {				/* not testing, fork OK		*/
    if (dbtp.dbenv != NULL)
	dbtp_close(&dbtp);			/* close databases across fork	*/
    if ((zonechild = forkchild()) != 0) {	/* parent			*/
      zone_request = 0;
      return;
    }
    else {
      sprintf(rtn,"zone dump %d initiated", getpid());
      LogPrint(rtn);
      if (fdTCPlisten)
	close(fdTCPlisten);
      if (fdTCP)
	close(fdTCP);
      if (fdUDP)
	close(fdUDP);
      fdTCPlisten = 0;
      fdTCP = 0;
      fdUDP = 0;
      parent = 0;
      savpid(pidpath());
      if (dbtp_init(&dbtp,(u_char *)dbhome,-1))
	goto ZoneExit;
    }
  }

#ifdef HAVE_SETPRIORITY
  setpriority(0,0,20);
#endif

  rtn = zonepath;
  sprintf(rtn,"%s/%s.tmp",dbhome,zone_name);	/* zone path and filename	*/
  umask(0x2);
 Retry:
  if ((fd = fopen(rtn,"w")) == NULL) {
    zresult = -9;
    goto ZoneExit;
  }

  setvbuf(fd,wbuf,_IOFBF,wbsize);
  
  if (zone_request != 0)			/* if not test mode		*/
	zresult = zonefile(fd);			/* fd closed in zonfile.c	*/
  else
	fclose(fd);

  if (zresult < 0) {
    if (retry-- > 0) {
      LogPrint("retry zone dump");
      goto Retry;
    }
    else
	goto ZoneExit;	
  }
  
  rtn = mybuffer;
  sprintf(rtn,"%s/%s.in",dbhome,zone_name);	/* zone path and filename	*/
  rename(zonepath,rtn);

 ZoneExit:
  if (! stat(zonepath,&fs) && ((fs.st_mode & S_IFMT) == S_IFREG))
    unlink(zonepath);				/* remove lingering tmp file	*/
  sprintf(rtn,"zone dump done, status=%d",zresult);
  LogPrint(rtn);
  if (zone_request)				/* if not testing		*/
	CleanExit(0);
  return;
}
