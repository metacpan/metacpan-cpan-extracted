#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

static char rcsid[] = "$Id: DeadLetter.xs,v 33.4 2012/09/26 16:10:10 jettisu Exp $";

/*
  (c) 1999-2012 Morgan Stanley & Co. Incorporated
  See ..../src/LICENSE for terms of distribution.
 */

/*
  Copied from DevelPPPort-1.0003/ppport.h
 */
#ifndef PERL_PATCHLEVEL
#       ifndef __PATCHLEVEL_H_INCLUDED__
#               include "patchlevel.h"
#       endif
#endif
#ifndef PATCHLEVEL
#   define PATCHLEVEL PERL_VERSION
#endif
#ifndef PERL_PATCHLEVEL
#       define PERL_PATCHLEVEL PATCHLEVEL
#endif
#ifndef PERL_SUBVERSION
#       define PERL_SUBVERSION SUBVERSION
#endif
 
#ifndef ERRSV
#       define ERRSV perl_get_sv("@",FALSE)
#endif
 
#if (PERL_PATCHLEVEL < 4) || ((PERL_PATCHLEVEL == 4) && (PERL_SUBVERSION <= 4))
#       define PL_sv_undef      sv_undef
#       define PL_sv_yes        sv_yes
#       define PL_sv_no         sv_no
#       define PL_na            na
#       define PL_stdingv       stdingv
#       define PL_hints         hints
#       define PL_curcop        curcop
#       define PL_curstash      curstash
#       define PL_copline       copline
#endif
 
#if (PERL_PATCHLEVEL < 5)
#  ifdef WIN32
#       define dTHR extern int Perl___notused
#  else
#       define dTHR extern int errno
#  endif
#endif
 
#ifndef boolSV
#       define boolSV(b) ((b) ? &PL_sv_yes : &PL_sv_no)
#endif

#include "cmqc.h"

MODULE = MQSeries::Message::DeadLetter		PACKAGE = MQSeries::Message::DeadLetter



void
MQDecodeDeadLetter(pBuffer,BufferLength)
	PMQCHAR pBuffer;
	MQLONG  BufferLength;

    PREINIT:
        PMQCHAR  pTemp;
        HV      *HeaderHV;
	SV      *DataSV;
	MQDLH    Header;
    PPCODE:
        pTemp = pBuffer;
        if ( BufferLength < sizeof(MQDLH) ) {
	    warn("MQDecodeDeadLetter: BufferLength is smaller than the MQDLH.\n");
	    XSRETURN_EMPTY;
	}
        
        Header = *(MQDLH *)pTemp;
        pTemp += sizeof(MQDLH);
	  
	HeaderHV = newHV();
	  
	hv_store(HeaderHV,"StrucId",7,(newSVpv(Header.StrucId,4)),0);
	hv_store(HeaderHV,"Version",7,(newSViv(Header.Version)),0);
	hv_store(HeaderHV,"Reason",6,(newSViv(Header.Reason)),0);
	hv_store(HeaderHV,"DestQName",9,(newSVpv(Header.DestQName,MQ_Q_NAME_LENGTH)),0);
	hv_store(HeaderHV,"DestQMgrName",12,(newSVpv(Header.DestQMgrName,MQ_Q_MGR_NAME_LENGTH)),0);
	hv_store(HeaderHV,"Encoding",8,(newSViv(Header.Encoding)),0);
	hv_store(HeaderHV,"CodedCharSetId",14,(newSViv(Header.CodedCharSetId)),0);
	hv_store(HeaderHV,"Format",6,(newSVpv(Header.Format,8)),0);
	hv_store(HeaderHV,"PutApplType",11,(newSViv(Header.PutApplType)),0);
	hv_store(HeaderHV,"PutApplName",11,(newSVpv(Header.PutApplName,MQ_PUT_APPL_NAME_LENGTH)),0);
	hv_store(HeaderHV,"PutDate",7,(newSVpv(Header.PutDate,MQ_PUT_DATE_LENGTH)),0);
	hv_store(HeaderHV,"PutTime",7,(newSVpv(Header.PutTime,MQ_PUT_TIME_LENGTH)),0);

	XPUSHs(sv_2mortal(newRV_noinc((SV*)HeaderHV)));

	if ( BufferLength == sizeof(MQDLH) )
	    DataSV = newSVpv("",0);
	else 
	    DataSV = newSVpvn(pTemp,BufferLength - sizeof(MQDLH));
	  
	XPUSHs(sv_2mortal(DataSV));


void
MQEncodeDeadLetter(Header,pData,DataLength)
     	MQDLH   Header;
	PMQCHAR pData;
	MQLONG	DataLength;

    PREINIT:	
	SV *Result;
    PPCODE:
	Result = newSVpv((char *)&Header,sizeof(MQDLH));
	sv_catpvn(Result,(char *)pData,DataLength);
	XPUSHs(sv_2mortal(Result));
