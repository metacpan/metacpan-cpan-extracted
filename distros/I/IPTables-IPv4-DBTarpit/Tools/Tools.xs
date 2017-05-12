/* ToolKit.xs
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
#include <stdio.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "bdbtarpit.h"

#define DBTP_U32size sizeof(u_int32_t)


DBTPD dbtp, xempty;
unsigned char yempty[sizeof(DBTPD)];

#define GET_DBTP(r,mptr) \
	if (! SvROK(r) || !SvREADONLY(SvRV(r))) \
	    XSRETURN_UNDEF; \
	mptr = (DBTPD *) SvPVX(SvRV(r))

#define _t_seterr(dbtp,erp,err) \
	(erp) = get_sv("IPTables::IPv4::DBTarpit::Tools::DBTP_ERROR", FALSE); \
	if ((erp) != NULL) { \
	    (err) = (dbtp)->dberr; \
	    sv_setiv((erp),(err)); \
	}

int run_recovery = 0;

#include "c_includes/alt_inet_aton.c"

MODULE = IPTables::IPv4::DBTarpit::Tools	PACKAGE = IPTables::IPv4::DBTarpit::Tools

PROTOTYPES: DISABLE

 # include functions for inet_aton, inet_ntoa

INCLUDE: xs_include/miniSocket.inc

int
t_set_recovery(val)
	int val
    CODE:
	RETVAL = run_recovery;
	run_recovery = val;
    OUTPUT:
	RETVAL

int
t_new_r(p,home,...)
	SV * p
	char * home
    PREINIT:
	DBTPD * rdbtp;
	STRLEN len;
	int i, index;
	SV * erp;
	IV err;
    CODE:
	GET_DBTP(p,rdbtp);
	if (items < 3) {
	    rdbtp->dberr = DB_NOTFOUND;
	    _t_seterr(rdbtp,erp,err);
	    XSRETURN_UNDEF;
	}
	for(i=2;i<items;i++) {
	    rdbtp->dbfile[i-2] = (char *)SvPV(ST(i),len);
	}
	if (run_recovery)
	    index = DB_RUNRECOVERY;
	else
	    index = -1;
	RETVAL = dbtp_init(rdbtp,(unsigned char *)home,index);
	_t_seterr(rdbtp,erp,err);
    OUTPUT:
	RETVAL

void
t_closedb_r(p)
	SV * p
    PREINIT:
	DBTPD * rdbtp;
	SV * erp;
	IV err;
    CODE:
	GET_DBTP(p,rdbtp);
	dbtp_close(rdbtp);
	_t_seterr(rdbtp,erp,err);

 # if ai < notstring, get U32, else get string

SV *
t_get_r(p,ai,addr,notstring)
	SV * p
	int ai
	SV * addr
	int notstring
    PREINIT:
	DBTPD * rdbtp;
	STRLEN len;
	void * adp;
	int rv;
	SV * val, * erp;
	IV err;
    PPCODE:
	GET_DBTP(p,rdbtp);
	adp = (void *)SvPV(addr,len);
	rv = dbtp_get(rdbtp,ai,adp,len);
	_t_seterr(rdbtp,erp,err);

	if (rv == DB_NOTFOUND)
	    XSRETURN_UNDEF;
	else if (rv)
	    XSRETURN_IV(0);

	if (ai < notstring && rdbtp->mgdbt.size == DBTP_U32size) {
	    val = newSViv(*(U32 *)rdbtp->mgdbt.data);
	    sv_setuv(val,*(U32 *)rdbtp->mgdbt.data);
	    XPUSHs(sv_2mortal(val));
	}
	else
	    XPUSHs(sv_2mortal(newSVpv(rdbtp->mgdbt.data,rdbtp->mgdbt.size)));
	XSRETURN(1);

 # not reached - quiet compiler
	RETVAL = val;


 # if ai < notstring, get U32, else get string
void
t_getrecno_r(p,ai,cursor,notstring)
	SV * p
	int ai
	U32 cursor
	int notstring
    PREINIT:
	DBTPD * rdbtp;
	int rv;
	SV * val, * erp;
	IV err;
    PPCODE:
	GET_DBTP(p,rdbtp);
	rv = dbtp_getrecno(rdbtp,ai,cursor);
	_t_seterr(rdbtp,erp,err);
	if (rv) {
	    if (GIMME == G_ARRAY)
		XSRETURN_EMPTY;
	    else
		XSRETURN_UNDEF;
	}

	XPUSHs(sv_2mortal(newSVpv(rdbtp->keydbt.data,rdbtp->keydbt.size)));

	if (GIMME == G_ARRAY) {
	    if (ai < notstring && rdbtp->mgdbt.size == DBTP_U32size) {
		val = newSViv(*(U32 *)rdbtp->mgdbt.data);
		sv_setuv(val,*(U32 *)rdbtp->mgdbt.data);
		XPUSHs(sv_2mortal(val));
	    }
	    else
		XPUSHs(sv_2mortal(newSVpv(rdbtp->mgdbt.data,rdbtp->mgdbt.size)));
	    XSRETURN(2);
	}
	XSRETURN(1);

int
t_del_r(p,ai,addr)
	SV * p
	int ai
	SV * addr
    PREINIT:
	DBTPD * rdbtp;
	STRLEN len;
	void * adp;
	int rv;
	SV * erp;
	IV err;
    CODE:
	GET_DBTP(p,rdbtp);
	adp = (void *)SvPV(addr,len);
	rv = dbtp_del(rdbtp,ai,adp,len);
	_t_seterr(rdbtp,erp,err);

	if (rv == DB_NOTFOUND)
	    XSRETURN_UNDEF;

	RETVAL = rv;
    OUTPUT:
	RETVAL

 # if ai < notstring, put U32, else put string

int
t_put_r(p,ai,addr,val,notstring)
	SV * p
	int ai
	SV * addr
	SV * val
	int notstring
    PREINIT:
	DBTPD * rdbtp;
	STRLEN alen, vlen;
	void * adp, * vlp;
	SV * erp;
	IV err;
	U32 ival;
    CODE:
	GET_DBTP(p,rdbtp);
	adp = (void *)SvPV(addr,alen);

 # check for IV == number
	if (ai < notstring && SvNIOK(val)) {
	    ival = SvUV(val);
	    vlp = (void *)&ival;
	    vlen = DBTP_U32size;
	}
	else
	    vlp = (void *)SvPV(val,vlen);

	RETVAL = dbtp_put(rdbtp,ai,adp,alen,vlp,vlen);
	_t_seterr(rdbtp,erp,err);
    OUTPUT:
	RETVAL

int
t_sync_r(p,ai)
	SV * p
	int ai;
    PREINIT:
	DBTPD * rdbtp;
	SV * erp;
	IV err;
    CODE:
	GET_DBTP(p,rdbtp);
	RETVAL = dbtp_sync(rdbtp,ai);
	_t_seterr(rdbtp,erp,err);
    OUTPUT:
	RETVAL

char *
t_db_strerror(err)
	int err
    CODE:
	RETVAL = dbtp_strerror(err);
    OUTPUT:
	RETVAL

 # if ai < notstring, put U32, else put string
int
t_dump_r(p,ai,hp,notstring)
	SV * p
	int ai
	SV * hp
	int notstring
    PREINIT:
	DBTPD * rdbtp;
	U32 cursor;
	HV * hash;
	int rv;
	SV * val, * erp;
	IV err;
    CODE:
	GET_DBTP(p,rdbtp);
	if (!SvROK(hp)) {
	    rv = rdbtp->dberr = DB_NOTFOUND;
	    _t_seterr(rdbtp,erp,err);
	    cursor = 0;
	}
	else {
	    cursor = 1;
	    hash = (HV *)SvRV(hp);
	    hv_clear(hash);
	    rv = 0;
	}
	while(cursor) {
	    rv = dbtp_getrecno(rdbtp,ai,cursor++);
	    if (rv) {
		if(rv == DB_NOTFOUND && cursor != 1)
		    rv = rdbtp->dberr = 0;
		_t_seterr(rdbtp,erp,err);
		break;
	    }
	    if (ai < notstring  && rdbtp->mgdbt.size == DBTP_U32size) {
		val = newSViv(*(U32 *)rdbtp->mgdbt.data);
		sv_setuv(val,*(U32 *)rdbtp->mgdbt.data);
	    }
	    else
		val = newSVpv(rdbtp->mgdbt.data,rdbtp->mgdbt.size);

	    (void)hv_store(hash,(char *)rdbtp->keydbt.data,rdbtp->keydbt.size,val,0);
 #	    SvREFCNT_dec(val);
	}

	RETVAL = rv;
    OUTPUT:
	RETVAL

int
t_notfound()
    CODE:
	RETVAL = DB_NOTFOUND;
    OUTPUT:
	RETVAL

int
t_runrecovery()
    CODE:
	RETVAL = DB_RUNRECOVERY;
    OUTPUT:
	RETVAL

void
t_bdbversion()
    PREINIT:
	int major, minor, patch;
    PPCODE:
	XPUSHs(sv_2mortal(newSVpv(dbtp_bdbversion(&major,&minor,&patch),0)));
	if (GIMME == G_ARRAY) {
	    XPUSHs(sv_2mortal(newSViv((I32)major)));
	    XPUSHs(sv_2mortal(newSViv((I32)minor)));
	    XPUSHs(sv_2mortal(newSViv((I32)patch)));
	    XSRETURN(4);
	}
	XSRETURN(1);

void
t_libversion()
    PREINIT:
	int major, minor, patch;
    PPCODE:
	XPUSHs(sv_2mortal(newSVpv(dbtp_libversion(&major,&minor,&patch),0)));
	if (GIMME == G_ARRAY) {
	    XPUSHs(sv_2mortal(newSViv((I32)major)));
	    XPUSHs(sv_2mortal(newSViv((I32)minor)));
	    XPUSHs(sv_2mortal(newSViv((I32)patch)));
	    XSRETURN(4);
	}
	XSRETURN(1);

U32
t_nkeys_r(p,ai)
	SV * p
	int ai
    PREINIT:
	DBTPD * rdbtp;
	SV * erp;
	IV err;
    CODE:
	GET_DBTP(p,rdbtp);
	RETVAL = dbtp_stati(rdbtp,ai);
	_t_seterr(rdbtp,erp,err);
	if (rdbtp->dberr)
	    XSRETURN_UNDEF;
    OUTPUT:
	RETVAL



 #        NI_NEW_IFREQ_REF(rv,sv,stash,ifr) \
 #       sv = newSV (0); \
 #       rv = sv_2mortal (newRV_noinc (sv)); \
 #       sv_bless (rv, stash); \
 #       SvGROW (sv, _SIZEOF_ADDR_IFREQ(*ifr)); \
 #       SvREADONLY_on (sv); \
 #       XPUSHs (rv);


void
t_nmem()
    PREINIT:
	SV * rv, * sv;
    PPCODE:
 # make an empty DBTPD
	sv = newSV(sizeof(DBTPD));
	rv = sv_2mortal(newRV_noinc(sv));
	SvREADONLY_on(sv);
	Zero(SvPVX(sv), 1, DBTPD);
	XPUSHs(rv);
	XSRETURN(1);

 # Save the next two routines in case we decide to switch to using malloc and free
 # void
 # t_rmem(p)
 #	SV * p
 #   PREINIT:
 #	DBTPD * mptr;
 #	AV * msav;
 #	I32 idx, end;
 #	unsigned char * mp;
 #	SV ** pp;
 #   CODE:
 #	GET_DBTP(p,mptr);
 #	Safefree(mptr);
 #	msav = get_av("_IPTDBTTools_memcache",0);
 #	if ((msav != NULL) && ((end = av_len(msav)) >= 0)) {
 #	    for (idx = 0; idx <= end; idx++) {
 #		pp = av_fetch(msav,idx,0);
 #		if ((pp != NULL) && (SvIOK(*pp)) && (mptr == (DBTPD * )SvIV(*pp))) {
 #		    av_delete(msav,idx,0);
 #		    break;
 #		}
 #	    }
 #	}
 #
 #void
 # DESTROY(...)
 #   PREINIT:
 #	DBTPD * mptr;
 #	AV * msav;
 #	I32 idx = 0, end;
 #	SV ** pp;
 #   CODE:
 #	msav = get_av("_IPTDBTTools_memcache",0);
 #	if ((msav != NULL) && ((end = av_len(msav)) >= 0)) {
 #	    while (idx <= end) {
 #		pp = av_fetch(msav,idx,0);
 #		if ((pp != NULL) && (SvIOK(*pp))) {
 #		    mptr = (DBTPD * )SvIV(*pp);
 #		    Safefree(mptr);
 #		}
 #		idx += 1;
 #	    }
 #	    av_undef(msav);
 #	}
 #
