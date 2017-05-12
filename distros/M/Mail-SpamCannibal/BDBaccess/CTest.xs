/* CText.xs
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

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
/* #include <sys/vfs.h>
*/
#include <stdio.h>

/* for local subs	*/
#include "misc_func.h"

/* for BerkeleyDB interface - bdbtarpit.c	*/
#include <bdbtarpit.h>
#include "defines.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

/* for util_pid.c		*/
#include "util_pid_func.h"

/* Global Variables from main.c */
  extern DBTPD	dbtp;
  extern int oflag, logopen, bflag, port;
  extern pid_t pidrun, parent;
  extern char * zone_name, local_name[], * contact, * errormsg;
  extern int zone_name_len, zoneEQlocal;
  extern int h_name_ctr;        /* name service buffer ring pointer     */
  extern u_int32_t * Astart, * Aptr, localip[];
  extern int mxmark[];
  extern struct in_addr stdResp, serial_rec;

/* Global Variables from ns.c	*/
  extern unsigned char ns_msgbuf[];

/* Globals used within CTest	*/

typedef union {
  DBT dbt;
 u_int32_t * naddr;
 u_int32_t * val;
} dbtU;

#define MAXname 512

char strbuf[MAXname];
char c, * nsname = NULL;

/* ****************************	*
 * 	dump database		*
 * 	used only for test	*
 * ****************************	*

Dumps database contents as ascii strings of the form
	  key	=> data (time secs)
	1.2.3.4	=> 1234567890

Returns:	0 on success, else error code
 */

int
mydb_dump(int secondary,char * filename)
{
  extern DBTPD dbtp;

  int status;
  u_int32_t cursor = 1, netcursor;
  struct in_addr inadr;
  char dumpbuf[1000];		/* arbitrary buffer */

  netcursor = htonl(cursor);
  while ((status = dbtp_readDB(&dbtp,1,filename,&netcursor,1)) == 0) {
    inadr.s_addr = *(in_addr_t *)(dbtp.keydbt.data);
    if (secondary) {
      strncpy(dumpbuf,(char *)dbtp.mgdbt.data,dbtp.mgdbt.size);
      dumpbuf[dbtp.mgdbt.size] = 0;
      printf("%16s => %s\n", inet_ntoa(inadr),dumpbuf);
    }
    else
      printf("%16s => %10ld\n", inet_ntoa(inadr),(long int)htonl(*(u_int32_t *)(dbtp.mgdbt.data)));
    dbtp.keydbt.data = &cursor;
    dbtp.keydbt.size = sizeof(cursor);
    cursor++;
    netcursor = htonl(cursor);
  }
  if (status == DB_NOTFOUND)
	status = 0;
  return status;   
}

void *
myct_getsec()
{
  extern DBTPD dbtp;
  extern char strbuf[];

  u_int32_t i;
  i = (u_int32_t)(dbtp.mgdbt.size);
  if (i > MAXname -1)
	i = MAXname -1;
  memcpy(strbuf,(char *)(dbtp.mgdbt.data),i);
  *((char *)(strbuf + i)) = '\0';
  return((void *)strbuf);
}

void *
myct_getpri()
{
  extern DBTPD dbtp;

  *(u_int32_t *)dbtp.mgdbt.data = htonl(*(u_int32_t *)dbtp.mgdbt.data);
  return(dbtp.mgdbt.data);
}

u_int32_t
my_u32(void * data)
{
  return(*(u_int32_t *)data);
}


MODULE = Mail::SpamCannibal::BDBaccess::CTest	PACKAGE = Mail::SpamCannibal::BDBaccess::CTest

PROTOTYPES: DISABLE

 # first item in list is the program name

int
t_main(...)
    PREINIT:
	STRLEN  len;
	unsigned char * ptr[20];
	int i;
	extern int opterr;
    CODE:
	if (items > 20) {
	    i = 0;  
	} else {
	    for (i=0; i < items; i++)
	    {
		ptr[i] = (unsigned char *)(SvPV(ST(i), len));
	    }
	opterr = 0;
	realMain(items, (char **)ptr);
	}
	RETVAL = i;
    OUTPUT:
	RETVAL

void
t_setport(pnum)
	int pnum
    CODE:
	port = pnum;

void
t_setsig()
    CODE:
	logopen = 0;	/* skip branch in Code	*/
	oflag = 1;	/* print to stdout	*/
	set_signals();

int
t_pidrun()
    CODE:
	RETVAL = (int)pidrun;
    OUTPUT:
	RETVAL

void
t_savpid(path)
	char * path
    CODE:
	savpid(path);

void
t_chk4pid(path)
	char * path
    PREINIT:
	SV * out;
    PPCODE:
	path = chk4pid(path);
	if (path == NULL) {
	  ST(0) = &PL_sv_undef;
	}
	else {
	  out = sv_newmortal();
	  out = newSVpv(path,0);
	  ST(0) = out;
	  XSRETURN(1);
	}

void
t_pidpath()
    PREINIT:
	SV * out;
    PPCODE:
	out = sv_newmortal();
	out = newSVpv(pidpath(),0);
	ST(0) = out;
	XSRETURN(1);

int
t_init(home,...)
	unsigned char * home
    PREINIT:
	STRLEN len;
	int i;
    CODE:
	for(i=1; i<items; i++) {
	  dbtp.dbfile[i-1] = SvPV(ST(i),len);
	}
	RETVAL = dbtp_init(&dbtp,home, -1);
    OUTPUT:
	RETVAL

int
t_dump(which,name)
	int which
	char * name
    CODE:
	RETVAL = mydb_dump(which,name);
    OUTPUT:
	RETVAL

void
t_close()
    CODE:
	dbtp_close(&dbtp);

void
t_get(which, name, addr);
	int which;
	char * name
	unsigned char * addr
    PREINIT:
	SV * out;
	void * data;
    PPCODE:
	if (dbtp_readDB(&dbtp,0, name, addr, 1))
	  XSRETURN_UNDEF;

	if (which)
	  data = myct_getsec();
	else
	  data = myct_getpri();

	if (data == NULL) {
	  ST(0) = &PL_sv_undef;
	}
	else {
	  out = sv_newmortal();
	  if(which) {
	    out = newSVpv((char *)data,0);
	  } 
	  else {
	    out = newSViv(*(I32 *)data);
	  }
	  ST(0) = out;
	}
	XSRETURN(1);

void
t_getrecno(which, name, cursor)
	int which
	char * name
	U32 cursor
    PREINIT:
	SV * netaddr, * tmp;		/* older perl does not know about newSVuv */
    PPCODE:
	cursor = htonl(cursor);
	if (dbtp_readDB(&dbtp,1,name,&cursor,1)) {
	    if(GIMME == G_ARRAY)
		XSRETURN_EMPTY;
	    else
		XSRETURN_UNDEF;
	}
	netaddr = sv_newmortal();
	sv_setpvn(netaddr, (char *)dbtp.keydbt.data, (size_t)dbtp.keydbt.size);
	XPUSHs(netaddr);
	if(GIMME == G_ARRAY) {
	    if (which)
		XPUSHs(sv_2mortal(newSVpv((char *)dbtp.mgdbt.data,(size_t)dbtp.mgdbt.size)));
	    else {
		cursor = ntohl(my_u32(dbtp.mgdbt.data));	/* temp variable	*/
		tmp = newSViv(cursor);
		sv_setuv(tmp,cursor);
		XPUSHs(sv_2mortal(tmp));
	    }
	    XSRETURN(2);
	}
	XSRETURN(1);

void
t_bdberror(status)
	int status
    PPCODE:
	XPUSHs(sv_2mortal(newSVpv(db_strerror(status),0)));
	XSRETURN(1);

void
t_bdbversion()
    PREINIT:
	char version[256];
	int major, minor, patch;
    PPCODE:
	(void)db_version(&major,&minor,&patch);
	(void)sprintf(version,"%d.%d.%d",major,minor,patch);
	XPUSHs(sv_2mortal(newSVpv(version,0)));
	XSRETURN(1);

U32
t_bdbcount(name)
	char * name
    CODE:
	RETVAL = dbtp_statn(&dbtp,name);
    OUTPUT:
	RETVAL

int
t_set_parent(val)
	int val
    CODE:
	RETVAL = parent;
	parent = val;
    OUTPUT:
	RETVAL
