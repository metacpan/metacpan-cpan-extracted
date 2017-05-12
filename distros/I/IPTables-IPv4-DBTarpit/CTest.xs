/* CTest.xs
 *
 * Copyright 2003-9, Michael Robinton <michael@bizsystems.com>
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
#include <stdio.h>

#define DBTP_U32size sizeof(u_int32_t)

/* for supported OS's		*/
#include "supported_os.h"

/* for BerkeleyDB interface - bdb.c	*/
#include "bdbtarpit.h"
#include "defines.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#ifdef DBTARPIT_SUPPORTED_OS_LINUX

/* for check.c			*/
#include "libipq.h"
#include <linux/ip.h>
#include <linux/netfilter.h>

#endif

/* for util_pid.c		*/
#include "util_pid_func.h"

/* for fifo.c			*/
#include <errno.h>

typedef union {
  DBT dbt;
 u_int32_t * naddr;
 u_int32_t * val;
} dbtU;

/* Global Variables from main.c	*/
  extern DBTPD dbtp;
  extern int xflag, oflag, Oflag, logopen, Lflag;
  extern int dummy_tarpit, trace_tarpit;
  extern pid_t pidrun;
  extern int fifofd;
  extern char * fifoname;
  extern char * dbhome;

/* ****************************	*
 *	check.c testing		*
 *	generate net packet	*
 *	with skeleton fill	*
 * ****************************	*

 *	want to fill 		*
 *	m_pkt->timestamp_sec	*
 *	iph->protocol		*
 *	iph->saddr		*
 */

#ifdef DBTARPIT_SUPPORTED_OS_LINUX

  struct ckmsg
  {
	ipq_packet_msg_t mpkt;
	struct iphdr iph;
  };

  struct ckmsg ct_checkmsg;

#endif

/* **************************** *
 *      misc.c random test      *
 * **************************** *
 */

  unsigned long rarry[10];   

/*	declarations		*/

  void fillRandGen(unsigned long * rq, int size);
  int realMain(int argc, char **argv);
  void set_signals (void);
  unsigned long initRandGen(int seed);
  int check_4_tarpit(ipq_packet_msg_t * m_pkt);
  void LogPrint(char * message);


unsigned long *
fillrandom()
{
  int size = sizeof(rarry) / 4;  
  fillRandGen(rarry, size);
  return (rarry);
}

#ifdef DBTARPIT_SUPPORTED_OS_LINUX

ipq_packet_msg_t *
ct_check_pkt(void * ipaddr, u_int32_t timestamp, int xflg, int protocol, int dt)
{
  struct iphdr * iph = (struct iphdr *)ct_checkmsg.mpkt.payload;
  iph->saddr = *(u_int32_t *)ipaddr;
  iph->protocol = (__u8)protocol;
  ct_checkmsg.mpkt.timestamp_sec = timestamp;
  xflag = xflg;
  dummy_tarpit = dt;
  return(&ct_checkmsg.mpkt);
}

#endif

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
mydb_dump(int secondary)
{
  DB * dbp;
  dbtU key, data;
  int status;
  u_int32_t cursor = 1;
  struct in_addr inadr;

  if (secondary) {
    dbp = dbtp.dbaddr[DBarchive];
  }
  else
    dbp = dbtp.dbaddr[DBtarpit];

  memset(&key.dbt, 0, sizeof(key.dbt));
  memset(&data.dbt, 0, sizeof(data.dbt));
  key.dbt.data = &cursor;
  key.dbt.size = sizeof(cursor);
  while((status = dbp->get(dbp, NULL, &key.dbt, &data.dbt, DB_SET_RECNO)) == 0) {
    inadr.s_addr = (in_addr_t)(*key.naddr);
    printf("%16s => %10ld\n", inet_ntoa(inadr), (long int)*data.val);
    key.dbt.data = &cursor;
    key.dbt.size = sizeof(cursor);
    cursor++;
  }
  if (status == DB_NOTFOUND)
  	status = 0;
  return status;
}

void
my_helpinit(DBTPD * dbtp, int ai, char * addr)
{
  dbtp->dbfile[ai] = addr;
}

MODULE = IPTables::IPv4::DBTarpit::CTest	PACKAGE = IPTables::IPv4::DBTarpit::CTest
PROTOTYPES: DISABLE

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
t_main(...)
    PREINIT:
	STRLEN	len;
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
t_setsig()
    CODE:
	logopen = 0;	/* skip branch in Code	*/
	oflag = 1;	/* print to stdout	*/
	set_signals();

void
t_inirand(test)
	int test
    PPCODE:
	XPUSHs(sv_2mortal(newSVnv(sizeof(rarry) / 4)));
	XPUSHs(sv_2mortal(newSVnv(initRandGen(test))));

void
t_fillrand()
    PREINIT:
	unsigned long * rptr;
	int i;
    PPCODE:
	rptr = fillrandom();
	for (i=0; i< sizeof(rarry) / 4;i++)
	{
	    XPUSHs(sv_2mortal(newSVnv(rptr[i])));
	}

int
t_ret_IPPTCP()
    CODE:
	RETVAL = IPPROTO_TCP;
    OUTPUT:
	RETVAL

int
t_chk_trace()
    CODE:
	RETVAL = trace_tarpit;
    OUTPUT:
	RETVAL

void
t_Lflag(ell)
	int ell
    CODE:
	Lflag = ell;


#ifdef DBTARPIT_SUPPORTED_OS_LINUX

int
t_NF_ACCEPT()
    CODE:
	RETVAL = NF_ACCEPT;
    OUTPUT:
	RETVAL

int
t_NF_DROP()
    CODE:
	RETVAL = NF_DROP;
    OUTPUT:
	RETVAL

int
t_check(addr, ts, xf, prot, tarpitresp)
	unsigned char *	addr
	U32		ts
	int		xf
	int		prot
	int		tarpitresp
    PREINIT:
	ipq_packet_msg_t * m = ct_check_pkt((void *)addr, ts, xf, prot, tarpitresp);
    CODE:
	RETVAL = check_4_tarpit(m);
    OUTPUT:
	RETVAL

#endif

int
t_init(home,...)
	unsigned char * home
    PREINIT:
	STRLEN len;
    CODE:
	my_helpinit(&dbtp,DBtarpit,NULL);
	my_helpinit(&dbtp,DBarchive,NULL);
	if (items > 1)
	    my_helpinit(&dbtp,DBtarpit,(char *)(SvPV(ST(1), len)));
	if (items > 2)
	    my_helpinit(&dbtp,DBarchive,(char *)(SvPV(ST(2), len)));

	RETVAL = dbtp_init(&dbtp,home, -1);
    OUTPUT:
	RETVAL

int
t_dump(which)
	int which
    CODE:
	RETVAL = mydb_dump(which);
    OUTPUT:
	RETVAL

void
t_close()
    CODE:
	dbtp_close(&dbtp);

int
t_findaddr(addr,timestamp)
	unsigned char * addr
	U32 timestamp
    CODE:
	RETVAL = dbtp_find_addr(&dbtp,DBtarpit,(void *)addr,timestamp);
    OUTPUT:
	RETVAL

void
t_saveaddr(addr, timestamp)
	unsigned char * addr
	U32 timestamp
    CODE:
	if (dbtp.dbaddr[DBarchive] != NULL)
	    dbtp_put(&dbtp,DBarchive,(void *)addr,sizeof(void *),&timestamp,sizeof(timestamp));

void
t_dberror(err)
	int err
    PPCODE:
	XPUSHs(sv_2mortal(newSVpv(dbtp_strerror(err),0)));
	XSRETURN(1);

int
t_statn(name)
	char * name
    CODE:
	RETVAL = dbtp_statn(&dbtp,name);
    OUTPUT:
	RETVAL

void
t_LogPrint(home, name, message, ofg, Ofg,...)
	char * home
	char * name
	char * message
	int ofg
	int Ofg
    PPCODE:
	if (items >5) {		/* is there a file descriptor	*/
	    fifofd = SvIV(ST(6));
	}
	else
	    fifofd = 0;

	oflag = ofg;
	Oflag = Ofg;
	dbhome = home;
	fifoname = name;
	LogPrint(message);
	XPUSHs(sv_2mortal(newSViv(errno)));
	if (GIMME_V == G_ARRAY) {
	    XPUSHs(sv_2mortal(newSViv(fifofd)));
	    XSRETURN(2);
	}
	XSRETURN(1);

void
t_fifo_close()
    CODE:
	if (fifofd > 0)
	    close(fifofd);
	fifofd = 0;

void
t_errors()
    PPCODE:
	EXTEND(SP,7);
	PUSHs(sv_2mortal(newSViv(EPIPE)));
	PUSHs(sv_2mortal(newSViv(ENOSPC)));
	PUSHs(sv_2mortal(newSViv(EEXIST)));
	PUSHs(sv_2mortal(newSViv(ENOENT)));
	PUSHs(sv_2mortal(newSViv(ENOTDIR)));
	PUSHs(sv_2mortal(newSViv(ENXIO)));
	PUSHs(sv_2mortal(newSViv(ENODEV)));
	XSRETURN(7);

 # if ai < notstring, get U32, else get string

SV *
t_get(ai,addr,notstring)
	int ai
	SV * addr
	int notstring
    PREINIT:
	STRLEN len;
	void * adp;
	int rv;
	SV * val;
    PPCODE:
	adp = (void *)SvPV(addr,len);
/*	rv = dbtp_get(&dbtp,ai,adp,len); */
	rv = dbtp_readOne(&dbtp,0,ai,adp,0);

	if (rv == DB_NOTFOUND)
	    XSRETURN_UNDEF;
	else if (rv)
	    XSRETURN_IV(0);

	if (ai < notstring && dbtp.mgdbt.size == DBTP_U32size) {
	    val = newSViv(*(U32 *)dbtp.mgdbt.data);
	    sv_setuv(val,*(U32 *)dbtp.mgdbt.data);
	    XPUSHs(sv_2mortal(val));
	}
	else
	    XPUSHs(sv_2mortal(newSVpv(dbtp.mgdbt.data,dbtp.mgdbt.size)));
	XSRETURN(1);
 # not reached - silence compiler warning
	RETVAL = val;


 # if ai < notstring, get U32, else get string
void
t_getrecno(ai,cursor,notstring)
	int ai
	U32 cursor
	int notstring
    PREINIT:
	int rv;
	SV * val;
    PPCODE:
 #	rv = dbtp_getrecno(&dbtp,ai,cursor);
	rv = dbtp_readOne(&dbtp,1,ai,&cursor,0);
	if (rv) {
	    if (GIMME == G_ARRAY)
		XSRETURN_EMPTY;
	    else
		XSRETURN_UNDEF;
	}

	XPUSHs(sv_2mortal(newSVpv(dbtp.keydbt.data,dbtp.keydbt.size)));

	if (GIMME == G_ARRAY) {
	    if (ai < notstring && dbtp.mgdbt.size == DBTP_U32size) {
		val = newSViv(*(U32 *)dbtp.mgdbt.data);
		sv_setuv(val,*(U32 *)dbtp.mgdbt.data);
		XPUSHs(sv_2mortal(val));
	    }
	    else
		XPUSHs(sv_2mortal(newSVpv(dbtp.mgdbt.data,dbtp.mgdbt.size)));
	    XSRETURN(2);
	}
	XSRETURN(1);

void
t_libversion(ai)
	int ai
    PREINIT:
	int major, minor, patch;
	int zero[] = {0,0};
	SV * stats;
    PPCODE:
	(void) dbtp_readOne(&dbtp,1,ai,(void *)&zero,0);
	major = (int)*(u_char *)(dbtp.keydbt.data + 1);
	minor = (int)*(u_char *)(dbtp.keydbt.data + 2);
	patch = (int)*(u_char *)(dbtp.keydbt.data + 3);
	stats = newSViv(*(U32 *)dbtp.mgdbt.data);
	sv_setuv(stats,*(U32 *)dbtp.mgdbt.data);
	XPUSHs(sv_2mortal(stats));	
	if (GIMME == G_ARRAY) {
	    XPUSHs(sv_2mortal(newSViv((I32)major)));
	    XPUSHs(sv_2mortal(newSViv((I32)minor)));
	    XPUSHs(sv_2mortal(newSViv((I32)patch)));
	    XSRETURN(4);
	}
	XSRETURN(1);
