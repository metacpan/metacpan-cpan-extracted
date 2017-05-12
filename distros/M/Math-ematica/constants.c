/*                               -*- Mode: C -*- 
 * $Basename: constants.c $
 * $Revision: 1.3 $
 * Author          : Ulrich Pfeifer
 * Created On      : Sat Dec 20 16:21:27 1997
 * Last Modified By: Ulrich Pfeifer
 * Last Modified On: Sun Dec 21 12:02:28 1997
 * Language        : C
 * Update Count    : 5
 * Status          : Unknown, Use with caution!
 * 
 * (C) Copyright 1997, Ulrich Pfeifer, all rights reserved.
 * 
 */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <mathlink.h>

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

double
MLconstant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'A':
	if (strEQ(name, "ADSP_CCBREFNUM"))
#ifdef ADSP_CCBREFNUM
	    return ADSP_CCBREFNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ADSP_IOCREFNUM"))
#ifdef ADSP_IOCREFNUM
	    return ADSP_IOCREFNUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ADSP_TYPE"))
#ifdef ADSP_TYPE
	    return ADSP_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ANYMODE"))
#ifdef ANYMODE
	    return ANYMODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "APIENTRY"))
#ifdef APIENTRY
	    return APIENTRY;
#else
	    goto not_there;
#endif
	break;
    case 'B':
	if (strEQ(name, "BEGINDLGPKT"))
#ifdef BEGINDLGPKT
	    return BEGINDLGPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BINARYBIT"))
#ifdef BINARYBIT
	    return BINARYBIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BINARY_MASK"))
#ifdef BINARY_MASK
	    return BINARY_MASK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BN"))
#ifdef BN
	    return BN;
#else
	    goto not_there;
#endif
	break;
    case 'C':
	if (strEQ(name, "CALLPKT"))
#ifdef CALLPKT
	    return CALLPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CFM68K_MACINTOSH_MATHLINK"))
#ifdef CFM68K_MACINTOSH_MATHLINK
	    return CFM68K_MACINTOSH_MATHLINK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLASSIC68K_MACINTOSH_MATHLINK"))
#ifdef CLASSIC68K_MACINTOSH_MATHLINK
	    return CLASSIC68K_MACINTOSH_MATHLINK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "COMMTB_CONNHANDLE"))
#ifdef COMMTB_CONNHANDLE
	    return COMMTB_CONNHANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "COMMTB_TYPE"))
#ifdef COMMTB_TYPE
	    return COMMTB_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CONNECTBIT"))
#ifdef CONNECTBIT
	    return CONNECTBIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CONNECT_YIELDING"))
#ifdef CONNECT_YIELDING
	    return CONNECT_YIELDING;
#else
	    goto not_there;
#endif
	break;
    case 'D':
	if (strEQ(name, "DESTROY_YIELDING"))
#ifdef DESTROY_YIELDING
	    return DESTROY_YIELDING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DEVICE_NAME"))
#ifdef DEVICE_NAME
	    return DEVICE_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DEVICE_TYPE"))
#ifdef DEVICE_TYPE
	    return DEVICE_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISPLAYENDPKT"))
#ifdef DISPLAYENDPKT
	    return DISPLAYENDPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISPLAYPKT"))
#ifdef DISPLAYPKT
	    return DISPLAYPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DLG_LINKNAME"))
#ifdef DLG_LINKNAME
	    return DLG_LINKNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DLG_TEXT"))
#ifdef DLG_TEXT
	    return DLG_TEXT;
#else
	    goto not_there;
#endif
	break;
    case 'E':
	if (strEQ(name, "ENDDLGPKT"))
#ifdef ENDDLGPKT
	    return ENDDLGPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ENTEREXPRPKT"))
#ifdef ENTEREXPRPKT
	    return ENTEREXPRPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ENTERTEXTPKT"))
#ifdef ENTERTEXTPKT
	    return ENTERTEXTPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EVALUATEPKT"))
#ifdef EVALUATEPKT
	    return EVALUATEPKT;
#else
	    goto not_there;
#endif
	break;
    case 'F':
	if (strEQ(name, "FAR"))
#ifdef FAR
	    return FAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FIRSTUSERPKT"))
#ifdef FIRSTUSERPKT
	    return FIRSTUSERPKT;
#else
	    goto not_there;
#endif
	break;
    case 'G':
	if (strEQ(name, "GENERATINGCFM"))
#ifdef GENERATINGCFM
	    return GENERATINGCFM;
#else
	    goto not_there;
#endif
	break;
    case 'H':
	break;
    case 'I':
	if (strEQ(name, "ILLEGALPKT"))
#ifdef ILLEGALPKT
	    return ILLEGALPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INPUTNAMEPKT"))
#ifdef INPUTNAMEPKT
	    return INPUTNAMEPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INPUTPKT"))
#ifdef INPUTPKT
	    return INPUTPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INPUTSTRPKT"))
#ifdef INPUTSTRPKT
	    return INPUTSTRPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INTERNAL_YIELDING"))
#ifdef INTERNAL_YIELDING
	    return INTERNAL_YIELDING;
#else
	    goto not_there;
#endif
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	if (strEQ(name, "LASTUSERPKT"))
#ifdef LASTUSERPKT
	    return LASTUSERPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "LAUNCHBIT"))
#ifdef LAUNCHBIT
	    return LAUNCHBIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "LISTENBIT"))
#ifdef LISTENBIT
	    return LISTENBIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "LOCAL_TYPE"))
#ifdef LOCAL_TYPE
	    return LOCAL_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "LOOPBACKBIT"))
#ifdef LOOPBACKBIT
	    return LOOPBACKBIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "LOOPBACK_TYPE"))
#ifdef LOOPBACK_TYPE
	    return LOOPBACK_TYPE;
#else
	    goto not_there;
#endif
	break;
    case 'M':
	if (strEQ(name, "M68KMACINTOSH_MATHLINK"))
#ifdef M68KMACINTOSH_MATHLINK
	    return M68KMACINTOSH_MATHLINK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MACTCP_IPDRIVER"))
#ifdef MACTCP_IPDRIVER
	    return MACTCP_IPDRIVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MACTCP_PARTNER_ADDR"))
#ifdef MACTCP_PARTNER_ADDR
	    return MACTCP_PARTNER_ADDR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MACTCP_PARTNER_PORT"))
#ifdef MACTCP_PARTNER_PORT
	    return MACTCP_PARTNER_PORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MACTCP_SETSIMPLESOCKET"))
#ifdef MACTCP_SETSIMPLESOCKET
	    return MACTCP_SETSIMPLESOCKET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MACTCP_STREAM"))
#ifdef MACTCP_STREAM
	    return MACTCP_STREAM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MACTCP_TYPE"))
#ifdef MACTCP_TYPE
	    return MACTCP_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAKE_YIELDING"))
#ifdef MAKE_YIELDING
	    return MAKE_YIELDING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAX_BYTES_PER_NEW_CHARACTER"))
#ifdef MAX_BYTES_PER_NEW_CHARACTER
	    return MAX_BYTES_PER_NEW_CHARACTER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAX_BYTES_PER_OLD_CHARACTER"))
#ifdef MAX_BYTES_PER_OLD_CHARACTER
	    return MAX_BYTES_PER_OLD_CHARACTER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAX_SLEEP"))
#ifdef MAX_SLEEP
	    return MAX_SLEEP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MENUPKT"))
#ifdef MENUPKT
	    return MENUPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MESSAGEPKT"))
#ifdef MESSAGEPKT
	    return MESSAGEPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLAPI"))
#ifdef MLAPI
	    return MLAPI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLAPIREVISION"))
#ifdef MLAPIREVISION
	    return MLAPIREVISION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLAPI_"))
#ifdef MLAPI_
	    return MLAPI_;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLBN"))
#ifdef MLBN
	    return MLBN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLBlocking"))
#ifdef MLBlocking
	    return MLBlocking;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLBrowse"))
#ifdef MLBrowse
	    return MLBrowse;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLBrowseMask"))
#ifdef MLBrowseMask
	    return MLBrowseMask;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLCB"))
#ifdef MLCB
	    return MLCB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLDEV_ACKNOWLEDGE"))
#ifdef MLDEV_ACKNOWLEDGE
	    return MLDEV_ACKNOWLEDGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLDEV_HAS_DATA"))
#ifdef MLDEV_HAS_DATA
	    return MLDEV_HAS_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLDEV_READ"))
#ifdef MLDEV_READ
	    return MLDEV_READ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLDEV_READ_COMPLETE"))
#ifdef MLDEV_READ_COMPLETE
	    return MLDEV_READ_COMPLETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLDEV_WRITE"))
#ifdef MLDEV_WRITE
	    return MLDEV_WRITE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLDEV_WRITE_WINDOW"))
#ifdef MLDEV_WRITE_WINDOW
	    return MLDEV_WRITE_WINDOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLDefaultOptions"))
#ifdef MLDefaultOptions
	    return MLDefaultOptions;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLDontBrowse"))
#ifdef MLDontBrowse
	    return MLDontBrowse;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLDontInteract"))
#ifdef MLDontInteract
	    return MLDontInteract;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEABORT"))
#ifdef MLEABORT
	    return MLEABORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEACCEPT"))
#ifdef MLEACCEPT
	    return MLEACCEPT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEARGV"))
#ifdef MLEARGV
	    return MLEARGV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEASSERT"))
#ifdef MLEASSERT
	    return MLEASSERT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEBADHOST"))
#ifdef MLEBADHOST
	    return MLEBADHOST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEBADNAME"))
#ifdef MLEBADNAME
	    return MLEBADNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEBADPARAM"))
#ifdef MLEBADPARAM
	    return MLEBADPARAM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLECLOSED"))
#ifdef MLECLOSED
	    return MLECLOSED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLECONNECT"))
#ifdef MLECONNECT
	    return MLECONNECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEDEAD"))
#ifdef MLEDEAD
	    return MLEDEAD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEDEBUG"))
#ifdef MLEDEBUG
	    return MLEDEBUG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEDEPTH"))
#ifdef MLEDEPTH
	    return MLEDEPTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEFAILED"))
#ifdef MLEFAILED
	    return MLEFAILED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEGBAD"))
#ifdef MLEGBAD
	    return MLEGBAD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEGETENDPACKET"))
#ifdef MLEGETENDPACKET
	    return MLEGETENDPACKET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEGSEQ"))
#ifdef MLEGSEQ
	    return MLEGSEQ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEINIT"))
#ifdef MLEINIT
	    return MLEINIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLELAST"))
#ifdef MLELAST
	    return MLELAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLELAUNCH"))
#ifdef MLELAUNCH
	    return MLELAUNCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLELAUNCHAGAIN"))
#ifdef MLELAUNCHAGAIN
	    return MLELAUNCHAGAIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLELAUNCHSPACE"))
#ifdef MLELAUNCHSPACE
	    return MLELAUNCHSPACE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEMEM"))
#ifdef MLEMEM
	    return MLEMEM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEMODE"))
#ifdef MLEMODE
	    return MLEMODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEMORE"))
#ifdef MLEMORE
	    return MLEMORE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLENAMETAKEN"))
#ifdef MLENAMETAKEN
	    return MLENAMETAKEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLENEWLIB"))
#ifdef MLENEWLIB
	    return MLENEWLIB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLENEXTPACKET"))
#ifdef MLENEXTPACKET
	    return MLENEXTPACKET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLENOACK"))
#ifdef MLENOACK
	    return MLENOACK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLENODATA"))
#ifdef MLENODATA
	    return MLENODATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLENODUPFCN"))
#ifdef MLENODUPFCN
	    return MLENODUPFCN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLENOLISTEN"))
#ifdef MLENOLISTEN
	    return MLENOLISTEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLENOMSG"))
#ifdef MLENOMSG
	    return MLENOMSG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLENOPARENT"))
#ifdef MLENOPARENT
	    return MLENOPARENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLENOTDELIVERED"))
#ifdef MLENOTDELIVERED
	    return MLENOTDELIVERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEOK"))
#ifdef MLEOK
	    return MLEOK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEOLDLIB"))
#ifdef MLEOLDLIB
	    return MLEOLDLIB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEOVFL"))
#ifdef MLEOVFL
	    return MLEOVFL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEPBIG"))
#ifdef MLEPBIG
	    return MLEPBIG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEPBTK"))
#ifdef MLEPBTK
	    return MLEPBTK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEPROTOCOL"))
#ifdef MLEPROTOCOL
	    return MLEPROTOCOL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEPSEQ"))
#ifdef MLEPSEQ
	    return MLEPSEQ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEPUTENDPACKET"))
#ifdef MLEPUTENDPACKET
	    return MLEPUTENDPACKET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLERESOURCE"))
#ifdef MLERESOURCE
	    return MLERESOURCE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLETRACEOFF"))
#ifdef MLETRACEOFF
	    return MLETRACEOFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLETRACEON"))
#ifdef MLETRACEON
	    return MLETRACEON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEUNKNOWN"))
#ifdef MLEUNKNOWN
	    return MLEUNKNOWN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEUNKNOWNPACKET"))
#ifdef MLEUNKNOWNPACKET
	    return MLEUNKNOWNPACKET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEUSER"))
#ifdef MLEUSER
	    return MLEUSER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLEXPORT"))
#ifdef MLEXPORT
	    return MLEXPORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLFAILURE"))
#ifdef MLFAILURE
	    return MLFAILURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLHUGE"))
#ifdef MLHUGE
	    return MLHUGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLInteract"))
#ifdef MLInteract
	    return MLInteract;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLInteractMask"))
#ifdef MLInteractMask
	    return MLInteractMask;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLInternetVisible"))
#ifdef MLInternetVisible
	    return MLInternetVisible;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLLENGTH_DECODER"))
#ifdef MLLENGTH_DECODER
	    return MLLENGTH_DECODER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLLocallyVisible"))
#ifdef MLLocallyVisible
	    return MLLocallyVisible;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLNE__INITSELECTOR"))
#ifdef MLNE__INITSELECTOR
	    return MLNE__INITSELECTOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLNetworkVisible"))
#ifdef MLNetworkVisible
	    return MLNetworkVisible;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLNetworkVisibleMask"))
#ifdef MLNetworkVisibleMask
	    return MLNetworkVisibleMask;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLNonBlocking"))
#ifdef MLNonBlocking
	    return MLNonBlocking;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLNonBlockingMask"))
#ifdef MLNonBlockingMask
	    return MLNonBlockingMask;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLOLDDEFINITION"))
#ifdef MLOLDDEFINITION
	    return MLOLDDEFINITION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLOLDREVISION"))
#ifdef MLOLDREVISION
	    return MLOLDREVISION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLPARAMETERSIZE"))
#ifdef MLPARAMETERSIZE
	    return MLPARAMETERSIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLPARAMETERSIZE_R1"))
#ifdef MLPARAMETERSIZE_R1
	    return MLPARAMETERSIZE_R1;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLPROTOTYPES"))
#ifdef MLPROTOTYPES
	    return MLPROTOTYPES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLREVISION"))
#ifdef MLREVISION
	    return MLREVISION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLSTDDEV_CONNECT"))
#ifdef MLSTDDEV_CONNECT
	    return MLSTDDEV_CONNECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLSTDDEV_CONNECT_READY"))
#ifdef MLSTDDEV_CONNECT_READY
	    return MLSTDDEV_CONNECT_READY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLSTDDEV_DESTROY"))
#ifdef MLSTDDEV_DESTROY
	    return MLSTDDEV_DESTROY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLSTDDEV_GET_HANDLER"))
#ifdef MLSTDDEV_GET_HANDLER
	    return MLSTDDEV_GET_HANDLER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLSTDDEV_GET_YIELDER"))
#ifdef MLSTDDEV_GET_YIELDER
	    return MLSTDDEV_GET_YIELDER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLSTDDEV_HAS_MSG"))
#ifdef MLSTDDEV_HAS_MSG
	    return MLSTDDEV_HAS_MSG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLSTDDEV_READ_MSG"))
#ifdef MLSTDDEV_READ_MSG
	    return MLSTDDEV_READ_MSG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLSTDDEV_SET_HANDLER"))
#ifdef MLSTDDEV_SET_HANDLER
	    return MLSTDDEV_SET_HANDLER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLSTDDEV_SET_YIELDER"))
#ifdef MLSTDDEV_SET_YIELDER
	    return MLSTDDEV_SET_YIELDER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLSTDDEV_WRITE_MSG"))
#ifdef MLSTDDEV_WRITE_MSG
	    return MLSTDDEV_WRITE_MSG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLSTDWORLD_DEINIT"))
#ifdef MLSTDWORLD_DEINIT
	    return MLSTDWORLD_DEINIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLSTDWORLD_INIT"))
#ifdef MLSTDWORLD_INIT
	    return MLSTDWORLD_INIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLSTDWORLD_MAKE"))
#ifdef MLSTDWORLD_MAKE
	    return MLSTDWORLD_MAKE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLSUCCESS"))
#ifdef MLSUCCESS
	    return MLSUCCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKAEND"))
#ifdef MLTKAEND
	    return MLTKAEND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKALL_DECODERS"))
#ifdef MLTKALL_DECODERS
	    return MLTKALL_DECODERS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKAPCTEND"))
#ifdef MLTKAPCTEND
	    return MLTKAPCTEND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKARRAY"))
#ifdef MLTKARRAY
	    return MLTKARRAY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKARRAY_DECODER"))
#ifdef MLTKARRAY_DECODER
	    return MLTKARRAY_DECODER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKCONT"))
#ifdef MLTKCONT
	    return MLTKCONT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKDIM"))
#ifdef MLTKDIM
	    return MLTKDIM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKELEN"))
#ifdef MLTKELEN
	    return MLTKELEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKEND"))
#ifdef MLTKEND
	    return MLTKEND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKERR"))
#ifdef MLTKERR
	    return MLTKERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKERROR"))
#ifdef MLTKERROR
	    return MLTKERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKFUNC"))
#ifdef MLTKFUNC
	    return MLTKFUNC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKINT"))
#ifdef MLTKINT
	    return MLTKINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKMODERNCHARS_DECODER"))
#ifdef MLTKMODERNCHARS_DECODER
	    return MLTKMODERNCHARS_DECODER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKNULL"))
#ifdef MLTKNULL
	    return MLTKNULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKOLDINT"))
#ifdef MLTKOLDINT
	    return MLTKOLDINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKOLDREAL"))
#ifdef MLTKOLDREAL
	    return MLTKOLDREAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKOLDSTR"))
#ifdef MLTKOLDSTR
	    return MLTKOLDSTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKOLDSYM"))
#ifdef MLTKOLDSYM
	    return MLTKOLDSYM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKPACKED"))
#ifdef MLTKPACKED
	    return MLTKPACKED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKPACKED_DECODER"))
#ifdef MLTKPACKED_DECODER
	    return MLTKPACKED_DECODER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKPCTEND"))
#ifdef MLTKPCTEND
	    return MLTKPCTEND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKREAL"))
#ifdef MLTKREAL
	    return MLTKREAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKSEND"))
#ifdef MLTKSEND
	    return MLTKSEND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKSTR"))
#ifdef MLTKSTR
	    return MLTKSTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTKSYM"))
#ifdef MLTKSYM
	    return MLTKSYM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_128BIT_LONGDOUBLE"))
#ifdef MLTK_128BIT_LONGDOUBLE
	    return MLTK_128BIT_LONGDOUBLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_16BIT_SIGNED_2sCOMPLEMENT_BIGENDIAN_INTEGER"))
#ifdef MLTK_16BIT_SIGNED_2sCOMPLEMENT_BIGENDIAN_INTEGER
	    return MLTK_16BIT_SIGNED_2sCOMPLEMENT_BIGENDIAN_INTEGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_16BIT_SIGNED_2sCOMPLEMENT_LITTLEENDIAN_INTEGER"))
#ifdef MLTK_16BIT_SIGNED_2sCOMPLEMENT_LITTLEENDIAN_INTEGER
	    return MLTK_16BIT_SIGNED_2sCOMPLEMENT_LITTLEENDIAN_INTEGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_16BIT_UNSIGNED_2sCOMPLEMENT_BIGENDIAN_INTEGER"))
#ifdef MLTK_16BIT_UNSIGNED_2sCOMPLEMENT_BIGENDIAN_INTEGER
	    return MLTK_16BIT_UNSIGNED_2sCOMPLEMENT_BIGENDIAN_INTEGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_16BIT_UNSIGNED_2sCOMPLEMENT_LITTLEENDIAN_INTEGER"))
#ifdef MLTK_16BIT_UNSIGNED_2sCOMPLEMENT_LITTLEENDIAN_INTEGER
	    return MLTK_16BIT_UNSIGNED_2sCOMPLEMENT_LITTLEENDIAN_INTEGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_32BIT_SIGNED_2sCOMPLEMENT_BIGENDIAN_INTEGER"))
#ifdef MLTK_32BIT_SIGNED_2sCOMPLEMENT_BIGENDIAN_INTEGER
	    return MLTK_32BIT_SIGNED_2sCOMPLEMENT_BIGENDIAN_INTEGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_32BIT_SIGNED_2sCOMPLEMENT_LITTLEENDIAN_INTEGER"))
#ifdef MLTK_32BIT_SIGNED_2sCOMPLEMENT_LITTLEENDIAN_INTEGER
	    return MLTK_32BIT_SIGNED_2sCOMPLEMENT_LITTLEENDIAN_INTEGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_32BIT_UNSIGNED_2sCOMPLEMENT_BIGENDIAN_INTEGER"))
#ifdef MLTK_32BIT_UNSIGNED_2sCOMPLEMENT_BIGENDIAN_INTEGER
	    return MLTK_32BIT_UNSIGNED_2sCOMPLEMENT_BIGENDIAN_INTEGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_32BIT_UNSIGNED_2sCOMPLEMENT_LITTLEENDIAN_INTEGER"))
#ifdef MLTK_32BIT_UNSIGNED_2sCOMPLEMENT_LITTLEENDIAN_INTEGER
	    return MLTK_32BIT_UNSIGNED_2sCOMPLEMENT_LITTLEENDIAN_INTEGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_80BIT_SANE_EXTENDED"))
#ifdef MLTK_80BIT_SANE_EXTENDED
	    return MLTK_80BIT_SANE_EXTENDED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_8BIT_SIGNED_2sCOMPLEMENT_INTEGER"))
#ifdef MLTK_8BIT_SIGNED_2sCOMPLEMENT_INTEGER
	    return MLTK_8BIT_SIGNED_2sCOMPLEMENT_INTEGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_8BIT_UNSIGNED_2sCOMPLEMENT_INTEGER"))
#ifdef MLTK_8BIT_UNSIGNED_2sCOMPLEMENT_INTEGER
	    return MLTK_8BIT_UNSIGNED_2sCOMPLEMENT_INTEGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_96BIT_68881_EXTENDED"))
#ifdef MLTK_96BIT_68881_EXTENDED
	    return MLTK_96BIT_68881_EXTENDED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_96BIT_HIGHPADDED_INTEL_80BIT_EXTENDED"))
#ifdef MLTK_96BIT_HIGHPADDED_INTEL_80BIT_EXTENDED
	    return MLTK_96BIT_HIGHPADDED_INTEL_80BIT_EXTENDED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_BIGENDIAN_IEEE754_DOUBLE"))
#ifdef MLTK_BIGENDIAN_IEEE754_DOUBLE
	    return MLTK_BIGENDIAN_IEEE754_DOUBLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_BIGENDIAN_IEEE754_SINGLE"))
#ifdef MLTK_BIGENDIAN_IEEE754_SINGLE
	    return MLTK_BIGENDIAN_IEEE754_SINGLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_CDOUBLE"))
#ifdef MLTK_CDOUBLE
	    return MLTK_CDOUBLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_CFLOAT"))
#ifdef MLTK_CFLOAT
	    return MLTK_CFLOAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_CINT"))
#ifdef MLTK_CINT
	    return MLTK_CINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_CLONG"))
#ifdef MLTK_CLONG
	    return MLTK_CLONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_CLONGDOUBLE"))
#ifdef MLTK_CLONGDOUBLE
	    return MLTK_CLONGDOUBLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_CSHORT"))
#ifdef MLTK_CSHORT
	    return MLTK_CSHORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_CUCHAR"))
#ifdef MLTK_CUCHAR
	    return MLTK_CUCHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_FIRSTUSER"))
#ifdef MLTK_FIRSTUSER
	    return MLTK_FIRSTUSER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_LASTUSER"))
#ifdef MLTK_LASTUSER
	    return MLTK_LASTUSER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_LITTLEENDIAN_IEEE754_DOUBLE"))
#ifdef MLTK_LITTLEENDIAN_IEEE754_DOUBLE
	    return MLTK_LITTLEENDIAN_IEEE754_DOUBLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLTK_LITTLEENDIAN_IEEE754_SINGLE"))
#ifdef MLTK_LITTLEENDIAN_IEEE754_SINGLE
	    return MLTK_LITTLEENDIAN_IEEE754_SINGLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLVERSION"))
#ifdef MLVERSION
	    return MLVERSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLVersionMask"))
#ifdef MLVersionMask
	    return MLVersionMask;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ML_END_EXTERN_C"))
#ifdef ML_END_EXTERN_C
	    return ML_END_EXTERN_C;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ML_EXTENDED_IS_DOUBLE"))
#ifdef ML_EXTENDED_IS_DOUBLE
	    return ML_EXTENDED_IS_DOUBLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ML_EXTERN_C"))
#ifdef ML_EXTERN_C
	    return ML_EXTERN_C;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ML_MAX_BYTES_PER_CHARACTER"))
#ifdef ML_MAX_BYTES_PER_CHARACTER
	    return ML_MAX_BYTES_PER_CHARACTER;
#else
	    goto not_there;
#endif
    case 'N':
	if (strEQ(name, "NOMODE"))
#ifdef NOMODE
	    return NOMODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NOT_SCATTERED"))
#ifdef NOT_SCATTERED
	    return NOT_SCATTERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_GLOBAL_DATA"))
#ifdef NO_GLOBAL_DATA
	    return NO_GLOBAL_DATA;
#else
	    goto not_there;
#endif
	break;
    case 'O':
	if (strEQ(name, "OUTPUTNAMEPKT"))
#ifdef OUTPUTNAMEPKT
	    return OUTPUTNAMEPKT;
#else
	    goto not_there;
#endif
	break;
    case 'P':
	if (strEQ(name, "PARENTCONNECTBIT"))
#ifdef PARENTCONNECTBIT
	    return PARENTCONNECTBIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PIPE_CHILD_PID"))
#ifdef PIPE_CHILD_PID
	    return PIPE_CHILD_PID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PIPE_FD"))
#ifdef PIPE_FD
	    return PIPE_FD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "POWERMACINTOSH_MATHLINK"))
#ifdef POWERMACINTOSH_MATHLINK
	    return POWERMACINTOSH_MATHLINK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PPC_PARTNER_LOCATION"))
#ifdef PPC_PARTNER_LOCATION
	    return PPC_PARTNER_LOCATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PPC_PARTNER_PORT"))
#ifdef PPC_PARTNER_PORT
	    return PPC_PARTNER_PORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PPC_PARTNER_PSN"))
#ifdef PPC_PARTNER_PSN
	    return PPC_PARTNER_PSN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PPC_SESS_REF_NUM"))
#ifdef PPC_SESS_REF_NUM
	    return PPC_SESS_REF_NUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PPC_TYPE"))
#ifdef PPC_TYPE
	    return PPC_TYPE;
#else
	    goto not_there;
#endif
	break;
    case 'Q':
	break;
    case 'R':
	if (strEQ(name, "READY_YIELDING"))
#ifdef READY_YIELDING
	    return READY_YIELDING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "READ_YIELDING"))
#ifdef READ_YIELDING
	    return READ_YIELDING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "REALBIT"))
#ifdef REALBIT
	    return REALBIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "REAL_MASK"))
#ifdef REAL_MASK
	    return REAL_MASK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RESUMEPKT"))
#ifdef RESUMEPKT
	    return RESUMEPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RETURNEXPRPKT"))
#ifdef RETURNEXPRPKT
	    return RETURNEXPRPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RETURNPKT"))
#ifdef RETURNPKT
	    return RETURNPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RETURNTEXTPKT"))
#ifdef RETURNTEXTPKT
	    return RETURNTEXTPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RIDCANCEL"))
#ifdef RIDCANCEL
	    return RIDCANCEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RIDOK"))
#ifdef RIDOK
	    return RIDOK;
#else
	    goto not_there;
#endif
	break;
    case 'S':
	if (strEQ(name, "SCATTERED"))
#ifdef SCATTERED
	    return SCATTERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SIZEVARIANTBIT"))
#ifdef SIZEVARIANTBIT
	    return SIZEVARIANTBIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SIZEVARIANT_MASK"))
#ifdef SIZEVARIANT_MASK
	    return SIZEVARIANT_MASK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SOCKET_FD"))
#ifdef SOCKET_FD
	    return SOCKET_FD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SOCKET_PARTNER_ADDR"))
#ifdef SOCKET_PARTNER_ADDR
	    return SOCKET_PARTNER_ADDR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SOCKET_PARTNER_PORT"))
#ifdef SOCKET_PARTNER_PORT
	    return SOCKET_PARTNER_PORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SUN_MATHLINK"))
#ifdef SUN_MATHLINK
	    return SUN_MATHLINK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SUSPENDPKT"))
#ifdef SUSPENDPKT
	    return SUSPENDPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYNTAXPKT"))
#ifdef SYNTAXPKT
	    return SYNTAXPKT;
#else
	    goto not_there;
#endif
	break;
    case 'T':
	if (strEQ(name, "TEXTPKT"))
#ifdef TEXTPKT
	    return TEXTPKT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_DEV_CONNECT"))
#ifdef T_DEV_CONNECT
	    return T_DEV_CONNECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_DEV_CONNECT_READY"))
#ifdef T_DEV_CONNECT_READY
	    return T_DEV_CONNECT_READY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_DEV_DESTROY"))
#ifdef T_DEV_DESTROY
	    return T_DEV_DESTROY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_DEV_GET_HANDLER"))
#ifdef T_DEV_GET_HANDLER
	    return T_DEV_GET_HANDLER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_DEV_GET_YIELDER"))
#ifdef T_DEV_GET_YIELDER
	    return T_DEV_GET_YIELDER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_DEV_HAS_DATA"))
#ifdef T_DEV_HAS_DATA
	    return T_DEV_HAS_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_DEV_HAS_MSG"))
#ifdef T_DEV_HAS_MSG
	    return T_DEV_HAS_MSG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_DEV_READ"))
#ifdef T_DEV_READ
	    return T_DEV_READ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_DEV_READ_COMPLETE"))
#ifdef T_DEV_READ_COMPLETE
	    return T_DEV_READ_COMPLETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_DEV_READ_MSG"))
#ifdef T_DEV_READ_MSG
	    return T_DEV_READ_MSG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_DEV_SET_HANDLER"))
#ifdef T_DEV_SET_HANDLER
	    return T_DEV_SET_HANDLER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_DEV_SET_YIELDER"))
#ifdef T_DEV_SET_YIELDER
	    return T_DEV_SET_YIELDER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_DEV_WRITE"))
#ifdef T_DEV_WRITE
	    return T_DEV_WRITE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_DEV_WRITE_MSG"))
#ifdef T_DEV_WRITE_MSG
	    return T_DEV_WRITE_MSG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_DEV_WRITE_WINDOW"))
#ifdef T_DEV_WRITE_WINDOW
	    return T_DEV_WRITE_WINDOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_WORLD_DEINIT"))
#ifdef T_WORLD_DEINIT
	    return T_WORLD_DEINIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_WORLD_INIT"))
#ifdef T_WORLD_INIT
	    return T_WORLD_INIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "T_WORLD_MAKE"))
#ifdef T_WORLD_MAKE
	    return T_WORLD_MAKE;
#else
	    goto not_there;
#endif
	break;
    case 'U':
	if (strEQ(name, "UNIXPIPE_TYPE"))
#ifdef UNIXPIPE_TYPE
	    return UNIXPIPE_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UNIXSOCKET_TYPE"))
#ifdef UNIXSOCKET_TYPE
	    return UNIXSOCKET_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UNIX_MATHLINK"))
#ifdef UNIX_MATHLINK
	    return UNIX_MATHLINK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "UNREGISTERED_TYPE"))
#ifdef UNREGISTERED_TYPE
	    return UNREGISTERED_TYPE;
#else
	    goto not_there;
#endif
	break;
    case 'V':
	break;
    case 'W':
	if (strEQ(name, "WIN16_MATHLINK"))
#ifdef WIN16_MATHLINK
	    return WIN16_MATHLINK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WIN32_EXTRA_LEAN"))
#ifdef WIN32_EXTRA_LEAN
	    return WIN32_EXTRA_LEAN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WIN32_LEAN_AND_MEAN"))
#ifdef WIN32_LEAN_AND_MEAN
	    return WIN32_LEAN_AND_MEAN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WIN32_MATHLINK"))
#ifdef WIN32_MATHLINK
	    return WIN32_MATHLINK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WINLOCAL_TYPE"))
#ifdef WINLOCAL_TYPE
	    return WINLOCAL_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WORLD_MODES"))
#ifdef WORLD_MODES
	    return WORLD_MODES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WORLD_PROTONAME"))
#ifdef WORLD_PROTONAME
	    return WORLD_PROTONAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WORLD_STREAMCAPACITY"))
#ifdef WORLD_STREAMCAPACITY
	    return WORLD_STREAMCAPACITY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WORLD_THISLOCATION"))
#ifdef WORLD_THISLOCATION
	    return WORLD_THISLOCATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WRITE_YIELDING"))
#ifdef WRITE_YIELDING
	    return WRITE_YIELDING;
#else
	    goto not_there;
#endif
	break;
    case 'X':
	if (strEQ(name, "XDRBIT"))
#ifdef XDRBIT
	    return XDRBIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "XDR_MASK"))
#ifdef XDR_MASK
	    return XDR_MASK;
#else
	    goto not_there;
#endif
	break;
    case 'Y':
	if (strEQ(name, "YIELDVERSION"))
#ifdef YIELDVERSION
	    return YIELDVERSION;
#else
	    goto not_there;
#endif
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}
