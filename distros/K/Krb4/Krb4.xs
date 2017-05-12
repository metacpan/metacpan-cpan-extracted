/*
 * Kerberos 4 extensions for Perl 5
 * Author: Jeff Horwitz <jeff@smashing.org>
 *
 * Copyright (c) 1999 Jeff Horwitz (jeff@smashing.org).  All rights reserved.
 * This module is free software; you can redistribute it and/or modify it
 * under the same terms as Perl itself.
 *
 */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <netdb.h>
#include <netinet/in.h>
#include <krb.h>
#include <des.h>
#ifdef __cplusplus
}
#endif

#define ENC_HEADER_SZ 32

typedef KTEXT Authen__Krb4__Ticket;
typedef CREDENTIALS * Authen__Krb4__Creds;
typedef AUTH_DAT * Authen__Krb4__AuthDat;
typedef des_key_schedule * Authen__Krb4__KeySchedule;
typedef des_cblock * Authen__Krb4__EncryptionKey;

void seterror(int error)
{
	SV * errorsv;
	errorsv=perl_get_sv("Authen::Krb4::error",TRUE|0x04);
	sv_setiv(errorsv,error);
}

MODULE = Authen::Krb4		PACKAGE = Authen::Krb4	PREFIX = krb4_

void
krb4_get_phost(alias)
	char *	alias

	PREINIT:
	char host[MAXHOSTNAMELEN];
	char *phost;

	PPCODE:
	phost=(char *)krb_get_phost(alias);
	strncpy(host,phost,MAXHOSTNAMELEN);
	if (host) {
		XPUSHs(sv_2mortal(newSVpv(host,strlen(host))));
	}
	else {
		XPUSHs(sv_2mortal(newSVsv(&PL_sv_undef)));
	}

void
krb4_get_lrealm(n=0)
	int 	n

	PREINIT:
	char realm[REALM_SZ];
	int error;

	PPCODE:
	error=krb_get_lrealm(realm,n);
	seterror(error);
	XPUSHs(sv_2mortal(newSVpv(realm,strlen(realm))));

void
krb4_realmofhost(host)
	char *	host

	PREINIT:
	char *realm;

	PPCODE:
	realm=(char *)krb_realmofhost(host);
	seterror(0);
	XPUSHs(sv_2mortal(newSVpv(realm,strlen(realm))));

int
krb4_get_pw_in_tkt(user,inst,realm,service,srealm,lifetime,password)
	char *	user
	char *	inst
	char *	realm
	char *	service
	char *	srealm
	long	lifetime
	char *	password

	PREINIT:
	int error=0;

	CODE:
	error=krb_get_pw_in_tkt(user,inst,realm,service,srealm,lifetime,
		password[0] ? password : (char *)0);
	seterror(error);
	RETVAL=error;

	OUTPUT:
	RETVAL

int
krb4_get_svc_in_tkt(user,inst,realm,service,srealm,lifetime,srvtab)
	char *	user
	char *	inst
	char *	realm
	char *	service
	char *	srealm
	long	lifetime
	char *	srvtab

	PREINIT:
	int error=0;

	CODE:
	error=krb_get_svc_in_tkt(user,inst,realm,service,srealm,lifetime,
		srvtab[0] ? srvtab : (char *)0);
	seterror(error);
	RETVAL=error;

	OUTPUT:
	RETVAL

void
krb4_read_service_key(user,inst,realm,kvno,srvtab)
	char *	user
	char *	inst
	char *	realm
	int	kvno
	char *	srvtab

	PREINIT:
	des_cblock *k;
	int error=0;

	PPCODE:
	if (!New(0,k,1,des_cblock)) XSRETURN_UNDEF;
	error=read_service_key(user,inst,realm,kvno,srvtab[0] ? srvtab : (char *)0,(char *)k);
	seterror(error);
	if (error) XSRETURN_UNDEF;
	XPUSHs(sv_2mortal(newSVpv((char *)k,sizeof(des_cblock))));

int
krb4_dest_tkt()
	CODE:
	RETVAL=dest_tkt();
	seterror(RETVAL);

	OUTPUT:
	RETVAL

void
krb4_get_err_txt(n)
	int	n

	PPCODE:
	if (n < 0 || n > 255) {
		XPUSHs(newSVsv(&PL_sv_undef));
	}
	else {
		XPUSHs(newSVpv(krb_err_txt[n],strlen(krb_err_txt[n])));
	}	

Authen::Krb4::Ticket
krb4_mk_req(service,instance,realm,checksum)
	char *	service
	char *	instance
	char *	realm
	unsigned long	checksum

	PREINIT:
	KTEXT authent;
	int error;

	PPCODE:
	if (!New(0,authent,1,KTEXT_ST)) XSRETURN_UNDEF;
	error=krb_mk_req(authent,service,instance,realm,checksum);	
	seterror(error);
	if (error == KSUCCESS) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Authen::Krb4::Ticket", (void*)authent);
		XSRETURN(1);
	}
	else {
		Safefree(authent);
		XSRETURN_UNDEF;
	}

Authen::Krb4::AuthDat
krb4_rd_req(t,service,instance,fn)
	Authen::Krb4::Ticket	t
	char *	service
	char *	instance
	char *	fn

	PREINIT:
	AUTH_DAT *ad;
	int error;

	PPCODE:
	if (!New(0,ad,1,AUTH_DAT)) XSRETURN_UNDEF;
	error=krb_rd_req(t,service,instance,(u_long)0,ad,fn);
	seterror(error);
	if (error == RD_AP_OK) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Authen::Krb4::AuthDat", (void*)ad);
		XSRETURN(1);
	}
	else {
		Safefree(ad);
		XSRETURN_UNDEF;
	}

Authen::Krb4::Creds
krb4_get_cred(service,instance,realm)
	char *	service
	char *	instance
	char *	realm

	PREINIT:
	CREDENTIALS *c;
	int error;

	PPCODE:
	if (!New(0,c,1,CREDENTIALS)) XSRETURN_UNDEF;
	error=krb_get_cred(service,instance,realm,c);
	seterror(error);
	if (error == GC_OK) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Authen::Krb4::Creds", (void*)c);
		XSRETURN(1);
	}
	else {
		Safefree(c);
		XSRETURN_UNDEF;
	}

Authen::Krb4::KeySchedule
krb4_get_key_sched(sv_session)
	SV *	sv_session

	PREINIT:
	C_Block session;
	des_key_schedule *sched;
	int error;

	PPCODE:
	if (!New(0,sched,1,des_key_schedule)) XSRETURN_UNDEF;
	Copy(SvPV(sv_session,PL_na),&session,1,C_Block);
	error=des_key_sched(session,sched);
	seterror(error);
	if (error == KSUCCESS) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Authen::Krb4::KeySchedule", (void*)sched);
		XSRETURN(1);
	}
	else {
		Safefree(sched);
	}

void
krb4_mk_priv(s_in,schedule,key,sender,receiver)
	SV *				s_in
	Authen::Krb4::KeySchedule	schedule
	SV *				key
	struct sockaddr_in *		sender
	struct sockaddr_in *		receiver

	PREINIT:
	u_char *in;
	u_char *out;
	des_cblock k;
	long in_length;
	long out_length;

	PPCODE:
	in_length=SvCUR(s_in);
	if (in_length == 0) {
		seterror(-1);
		return;
	}
	if (!New(0,in,in_length,u_char)) {
		seterror(-1);
		return;
	}
	if (!New(0,out,in_length+ENC_HEADER_SZ,u_char)) {
		Safefree(in);
		seterror(-1);
		return;
	}
	Zero(in,in_length,u_char);
	Zero(out,in_length+ENC_HEADER_SZ,u_char);
	Copy(SvPV(s_in,PL_na),in,in_length,u_char);
	Copy(SvPV(key,PL_na),&k,SvCUR(key),u_char);
	out_length=krb_mk_priv(in,out,in_length,schedule,k,sender,receiver);
	Safefree(in);
	XPUSHs(sv_2mortal(newSVpv(out,out_length)));

void
krb4_rd_priv(s_in,schedule,key,sender,receiver)
	SV *				s_in
	Authen::Krb4::KeySchedule	schedule
	SV *				key
	struct sockaddr_in *		sender
	struct sockaddr_in *		receiver

	PREINIT:
	u_char *in;
	des_cblock k;
	int error;
	long in_length;
	MSG_DAT msg_data;

	PPCODE:
	in_length=SvCUR(s_in);
	if (in_length == 0) {
		seterror(-1);
		return;
	}
	if (!New(0,in,in_length,u_char)) {
		seterror(-1);
		return;
	}
	Zero(in,in_length,u_char);
	Zero(&msg_data,1,MSG_DAT);
	Copy(SvPV(s_in,PL_na),in,in_length,u_char);
	Copy(SvPV(key,PL_na),&k,SvCUR(key),u_char);
	error=krb_rd_priv(in,in_length,schedule,k,sender,receiver,&msg_data);
	seterror(error);
	Safefree(in);
	if (error == 0) {
		XPUSHs(sv_2mortal(newSVpv(msg_data.app_data,msg_data.app_length)));
	}

void
krb4_sendauth(options,fh,service,inst,realm,checksum,laddr,faddr,version)
	long 			options
	FILE *			fh
	char *			service
	char * 			inst
	char *			realm
	long			checksum
	struct sockaddr_in *	laddr
	struct sockaddr_in *	faddr
	char *			version

	PREINIT:
	KTEXT ktext;
	MSG_DAT msg_data;
	CREDENTIALS *cred;
	des_key_schedule *schedule;
	int error,fd;

	PPCODE:
	if (!New(0,ktext,1,KTEXT_ST)) XSRETURN_UNDEF;
	if (!New(0,cred,1,CREDENTIALS)) XSRETURN_UNDEF;
	if (!New(0,schedule,1,des_key_schedule)) XSRETURN_UNDEF;
	fd=fileno(fh);
	error=krb_sendauth(options,fd,ktext,service,inst,realm,checksum,
		&msg_data,cred,schedule,laddr,faddr,version);
	seterror(error);
	if (error == KSUCCESS) {
		ST(0) = sv_newmortal();
		ST(1) = sv_newmortal();
		ST(2) = sv_newmortal();
		sv_setref_pv(ST(0), "Authen::Krb4::Ticket", (void*)ktext);
		sv_setref_pv(ST(1), "Authen::Krb4::Creds", (void*)cred);
		sv_setref_pv(ST(2), "Authen::Krb4::KeySchedule", (void*)schedule);
		XSRETURN(3);
	}
	else {
		Safefree(ktext);
		Safefree(cred);
		Safefree(schedule);
	}

void
krb4_recvauth(options,fh,service,inst,faddr,laddr,fn)
	long 			options
	FILE *			fh
	char *			service
	char * 			inst
	struct sockaddr_in *	faddr
	struct sockaddr_in *	laddr
	char *			fn

	PREINIT:
	KTEXT ktext;
	AUTH_DAT *ad;
	des_key_schedule *schedule;
	char version[KRB_SENDAUTH_VLEN];
	int error,fd;

	PPCODE:
	ktext=(KTEXT)safemalloc(sizeof(KTEXT_ST));
	if (!ktext) XSRETURN_UNDEF;
	ad=(AUTH_DAT *)safemalloc(sizeof(AUTH_DAT));
	if (!ad) XSRETURN_UNDEF;
	schedule=(des_key_schedule *)safemalloc(sizeof(des_key_schedule));
	if (!schedule) XSRETURN_UNDEF;
	fd=fileno(fh);
	error=krb_recvauth(options,fd,ktext,service,inst,faddr,laddr,
		ad,fn,schedule,version);
	seterror(error);
	if (error == KSUCCESS) {
		ST(0) = sv_newmortal();
		ST(1) = sv_newmortal();
		ST(2) = sv_newmortal();
		sv_setref_pv(ST(0), "Authen::Krb4::Ticket", (void*)ktext);
		sv_setref_pv(ST(1), "Authen::Krb4::AuthDat", (void*)ad);
		sv_setref_pv(ST(2), "Authen::Krb4::KeySchedule", (void*)schedule);
		ST(3) = sv_2mortal(newSVpv(version,strlen(version)));
		XSRETURN(4);
	}
	else {
		Safefree(ktext);
		Safefree(ad);
		Safefree(schedule);
	}


MODULE = Authen::Krb4		PACKAGE = Authen::Krb4::Ticket

Authen::Krb4::Ticket
new(class,dat)
	char *	class
	SV *	dat

	PREINIT:
	KTEXT authent;
	int error;

	PPCODE:
	if (!SvOK(dat)) XSRETURN_UNDEF;
	authent=(KTEXT)safemalloc(sizeof(KTEXT_ST));
	if (!authent) XSRETURN_UNDEF;
	authent->length=SvCUR(dat);
	Copy(SvPV(dat,PL_na),&authent->dat,authent->length,u_char);
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Authen::Krb4::Ticket", (void*)authent);
	XSRETURN(1);

int
DESTROY(t)
	Authen::Krb4::Ticket	t

	CODE:
	Safefree(t);
	RETVAL=1;

	OUTPUT:
	RETVAL

int
length(t)
	Authen::Krb4::Ticket	t

	CODE:
	RETVAL=t->length;

	OUTPUT:
	RETVAL

void
dat(t)
	Authen::Krb4::Ticket	t

	PPCODE:
	XPUSHs(sv_2mortal(newSVpv((char *)&(t->dat),t->length)));

MODULE = Authen::Krb4		PACKAGE = Authen::Krb4::AuthDat

int
DESTROY(ad)
	Authen::Krb4::AuthDat	ad

	CODE:
	Safefree(ad);
	RETVAL=1;

	OUTPUT:
	RETVAL

void
pname(ad)
	Authen::Krb4::AuthDat	ad

	PPCODE:
	XPUSHs(sv_2mortal(newSVpv(ad->pname,strlen(ad->pname))));

void
pinst(ad)
	Authen::Krb4::AuthDat	ad

	PPCODE:
	XPUSHs(sv_2mortal(newSVpv(ad->pinst,strlen(ad->pinst))));

void
prealm(ad)
	Authen::Krb4::AuthDat	ad

	PPCODE:
	XPUSHs(sv_2mortal(newSVpv(ad->prealm,strlen(ad->prealm))));

void
session(ad)
	Authen::Krb4::AuthDat	ad

	PPCODE:
	XPUSHs(sv_2mortal(newSVpv((char *)&(ad->session),sizeof(ad->session))));

void
k_flags(ad)
	Authen::Krb4::AuthDat	ad

	PPCODE:
	XPUSHs(sv_2mortal(newSVpv((char *)&(ad->k_flags),sizeof(ad->k_flags))));

void
checksum(ad)
	Authen::Krb4::AuthDat	ad

	PPCODE:
	XPUSHs(sv_2mortal(newSVnv(ad->checksum)));

void
life(ad)
	Authen::Krb4::AuthDat	ad

	PPCODE:
	XPUSHs(sv_2mortal(newSViv(ad->life)));

void
time_sec(ad)
	Authen::Krb4::AuthDat	ad

	PPCODE:
	XPUSHs(sv_2mortal(newSVnv(ad->time_sec)));

void
address(ad)
	Authen::Krb4::AuthDat	ad

	PPCODE:
	XPUSHs(sv_2mortal(newSVnv(ad->address)));

Authen::Krb4::Ticket
reply(ad)
	Authen::Krb4::AuthDat	ad

	PPCODE:
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Authen::Krb4::Ticket", (void*)&ad->reply);
	XSRETURN(1);

MODULE = Authen::Krb4		PACKAGE = Authen::Krb4::Creds

int
DESTROY(c)
	Authen::Krb4::Creds	c

	CODE:
	Safefree(c);
	RETVAL=1;

	OUTPUT:
	RETVAL

void
service(c)
	Authen::Krb4::Creds	c

	PPCODE:
	XPUSHs(sv_2mortal(newSVpv(c->service,strlen(c->service))));

void
instance(c)
	Authen::Krb4::Creds	c

	PPCODE:
	XPUSHs(sv_2mortal(newSVpv(c->instance,strlen(c->instance))));

void
realm(c)
	Authen::Krb4::Creds	c

	PPCODE:
	XPUSHs(sv_2mortal(newSVpv(c->realm,strlen(c->realm))));

void
lifetime(c)
	Authen::Krb4::Creds	c

	PPCODE:
	XPUSHs(sv_2mortal(newSViv(c->lifetime)));

void
kvno(c)
	Authen::Krb4::Creds	c

	PPCODE:
	XPUSHs(sv_2mortal(newSViv(c->kvno)));

void
issue_date(c)
	Authen::Krb4::Creds	c

	PPCODE:
	XPUSHs(sv_2mortal(newSVnv(c->issue_date)));

void
session(c)
	Authen::Krb4::Creds	c

	PPCODE:
	XPUSHs(sv_2mortal(newSVpv((char *)&(c->session),sizeof(c->session))));

Authen::Krb4::Ticket
ticket(c)
	Authen::Krb4::Creds	c

	PPCODE:
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Authen::Krb4::Ticket", (void*)&c->ticket_st);
	XSRETURN(1);

void
pname(c)
	Authen::Krb4::Creds	c

	PPCODE:
	XPUSHs(sv_2mortal(newSVpv(c->pname,strlen(c->pname))));

void
pinst(c)
	Authen::Krb4::Creds	c

	PPCODE:
	XPUSHs(sv_2mortal(newSVpv(c->pinst,strlen(c->pinst))));


MODULE = Authen::Krb4		PACKAGE = Authen::Krb4::KeySchedule

int
DESTROY(sched)
	Authen::Krb4::KeySchedule	sched

	CODE:
	Safefree(sched);
	RETVAL=1;

	OUTPUT:
	RETVAL
