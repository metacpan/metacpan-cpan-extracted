/*
 *  This file is part of the Kools::Okapi package
 *  a Perl C wrapper for the Thomson Reuters Kondor+ OKAPI api.
 *
 *  Copyright (C) 2009 Gabriel Galibourg
 *
 *  The Kools::Okapi package is free software; you can redistribute it and/or
 *  modify it under the terms of the Artistic License 2.0 as published by
 *  The Perl Foundation; either version 2.0 of the License, or
 *  (at your option) any later version.
 *
 *  The Kools::Okapi package is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  Perl Artistic License for more details.
 *
 *  You should have received a copy of the Artistic License along with
 *  this package.  If not, see <http://www.perlfoundation.org/legal/>.
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "okapi.h"


typedef struct {
    ICC_opaque   iccObj;
    SV*          clientData;

    SV*          data_msg_callback;
    SV*          set_fds_callback;
    SV*          select_timeout_callback;
    SV*          select_signal_callback;
    SV*          select_msg_callback;
    SV*          disconnect_callback;
    SV*          reconnect_callback;
}  perl_iccObj_t;




/* ================================
 *
 * _data_msg_callback
 *
 * Generic callback registered for ICC_DATA_MSG_CALLBACK events.
 */
static ICC_status_t
_data_msg_callback(ICC_opaque cd, char *key, ICC_Data_Msg_Type_t type)
{
    perl_iccObj_t *picc=(perl_iccObj_t*)cd;
    dSP;

    int count;
    int retval;
    
    
    ENTER;SAVETMPS;
    PUSHMARK(SP);
    XPUSHs (sv_2mortal (newSViv ( cd)));
    XPUSHs (sv_2mortal (newSVpv ( key, strlen(key))));
    XPUSHs (sv_2mortal (newSViv ( type  )));
    PUTBACK;

    count = call_sv(picc->data_msg_callback, G_SCALAR);
    SPAGAIN;

    if ( count!= 1 )
        croak ("icc_data_callback() returned more than one argument\n");

    retval = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}


/* ================================
 *
 * _set_fds_callback
 *
 * Generic callback registered for ICC_SET_FDS_CALLBACK events.
 */
static ICC_status_t
_set_fds_callback(ICC_opaque cd, fd_set *r_fds, fd_set *w_fds, fd_set *e_fds)
{
    perl_iccObj_t *picc=(perl_iccObj_t*)cd;
    dSP;

    int count;
    int retval;
    
    ENTER;SAVETMPS;
    PUSHMARK(SP);

    AV *readFD  = (AV*)sv_2mortal((SV*)newAV());
    AV *writeFD = (AV*)sv_2mortal((SV*)newAV());
    AV *errFD   = (AV*)sv_2mortal((SV*)newAV());

    XPUSHs (sv_2mortal (newSViv ( cd)));
    XPUSHs (sv_2mortal (newRV_inc((SV*)readFD)));
    XPUSHs (sv_2mortal (newRV_inc((SV*)writeFD)));
    XPUSHs (sv_2mortal (newRV_inc((SV*)errFD)));
    PUTBACK;

    count = call_sv(picc->set_fds_callback, G_SCALAR);
    SPAGAIN;

    if ( count!= 1 )
        croak ("icc_set_fds_callback() returned more than one argument\n");

    retval = POPi;

    if (retval == ICC_OK) {
        I32 n,numElt;
        // read
        numElt=av_len(readFD);
        for (n=0 ; n<=numElt ; ++n) {
            if (av_fetch(readFD,n,0) != NULL) {
                int val=SvIV(*av_fetch(readFD,n,0));
                FD_SET(val,r_fds);
            }
        }
        // write
        numElt=av_len(writeFD);
        for (n=0 ; n<=numElt ; ++n) {
            if (av_fetch(writeFD,n,0) != NULL) {
                int val=SvIV(*av_fetch(writeFD,n,0));
                FD_SET(val,w_fds);
            }
        }
        // error
        numElt=av_len(errFD);
        for (n=0 ; n<=numElt ; ++n) {
            if (av_fetch(errFD,n,0) != NULL) {
                int val=SvIV(*av_fetch(errFD,n,0));
                FD_SET(val,e_fds);
            }
        }
	}

    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}


/* ================================
 *
 * _select_timeout_callback
 *
 * Generic callback registered for ICC_SELECT_TIMEOUT_CALLBACK events.
 */
static ICC_status_t
_select_timeout_callback(ICC_opaque cd)
{
    perl_iccObj_t *picc=(perl_iccObj_t*)cd;
    dSP;

    int count;
    int retval;
    
    
    ENTER;SAVETMPS;
    PUSHMARK(SP);
    XPUSHs (sv_2mortal (newSViv ( cd)));
    PUTBACK;

    count = call_sv(picc->select_timeout_callback, G_SCALAR);
    SPAGAIN;

    if ( count!= 1 )
        croak ("icc_select_timeout_callback() returned more than one argument\n");

    retval = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}


/* ================================
 *
 * _select_signal_callback
 *
 * Generic callback registered for ICC_SELECT_SIGNAL_CALLBACK events.
 */
static ICC_status_t
_select_signal_callback(ICC_opaque cd)
{
    perl_iccObj_t *picc=(perl_iccObj_t*)cd;
    dSP;

    int count;
    int retval;
    
    
    ENTER;SAVETMPS;
    PUSHMARK(SP);
    XPUSHs (sv_2mortal (newSViv ( cd)));
    PUTBACK;

    count = call_sv(picc->select_signal_callback, G_SCALAR);
    SPAGAIN;

    if ( count!= 1 )
        croak ("icc_select_signal_callback() returned more than one argument\n");

    retval = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}


/* ================================
 *
 * _select_msg_callback
 *
 * Generic callback registered for ICC_SELECT_MSG_CALLBACK events.
 */
static ICC_status_t
_select_msg_callback(ICC_opaque cd, fd_set *r_fds, fd_set *w_fds, fd_set *e_fds)
{
    perl_iccObj_t *picc=(perl_iccObj_t*)cd;
    dSP;

    int count;
    int retval;
    
    
    ENTER;SAVETMPS;
    PUSHMARK(SP);

    AV *readFD  = (AV*)sv_2mortal((SV*)newAV());
    AV *writeFD = (AV*)sv_2mortal((SV*)newAV());
    AV *errFD   = (AV*)sv_2mortal((SV*)newAV());

    int i;
    for (i=0 ; i<FD_SETSIZE ; ++i) {
        if (FD_ISSET(i,r_fds))
            av_push(readFD,newSViv(i));
    }
    for (i=0 ; i<FD_SETSIZE ; ++i) {
        if (FD_ISSET(i,w_fds))
            av_push(writeFD,newSViv(i));
    }
    for (i=0 ; i<FD_SETSIZE ; ++i) {
        if (FD_ISSET(i,e_fds))
            av_push(errFD,newSViv(i));
    }


    XPUSHs (sv_2mortal (newSViv ( cd)));
    XPUSHs (sv_2mortal (newRV_inc((SV*)readFD)));
    XPUSHs (sv_2mortal (newRV_inc((SV*)writeFD)));
    XPUSHs (sv_2mortal (newRV_inc((SV*)errFD)));

    PUTBACK;

    count = call_sv(picc->select_msg_callback, G_SCALAR);
    SPAGAIN;

    if ( count!= 1 )
        croak ("icc_select_msg_callback() returned more than one argument\n");

    retval = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}


/* ================================
 *
 * _disconnect_callback
 *
 * Generic callback registered for ICC_DISCONNECT_CALLBACK events.
 */
static ICC_status_t
_disconnect_callback(ICC_opaque cd)
{
    perl_iccObj_t *picc=(perl_iccObj_t*)cd;
    dSP;

    int count;
    int retval;
    
    
    ENTER;SAVETMPS;
    PUSHMARK(SP);
    XPUSHs (sv_2mortal (newSViv ( cd)));
    PUTBACK;

    count = call_sv(picc->disconnect_callback, G_SCALAR);
    SPAGAIN;

    if ( count!= 1 )
        croak ("icc_disconnect_callback() returned more than one argument\n");

    retval = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}


/* ================================
 *
 * _reconnect_callback
 *
 * Generic callback registered for ICC_RECONNECT_CALLBACK events.
 */
static ICC_status_t
_reconnect_callback(ICC_opaque cd)
{
    perl_iccObj_t *picc=(perl_iccObj_t*)cd;
    dSP;

    int count;
    int retval;
    
    
    ENTER;SAVETMPS;
    PUSHMARK(SP);
    XPUSHs (sv_2mortal (newSViv ( cd)));
    PUTBACK;

    count = call_sv(picc->reconnect_callback, G_SCALAR);
    SPAGAIN;

    if ( count!= 1 )
        croak ("icc_reconnect_callback() returned more than one argument\n");

    retval = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}


/* ================================
 *
 * processCreateAndSetParameters
 *
 * This is a function called by both ICC_set or ICC_create to process their parameters.
 * The function returns the number of parameters to pop of the stack.
 */
static int
processCreateAndSetParameters(perl_iccObj_t *picc, int key, SV* attrib, SV* attrib2, SV* attrib3)
{
    int skipStack=1; // default is just one parameter to take off the stack
    
    //printf("key=%d  attrib=%ld\n",key,attrib);
    switch (key) {
        // these attributes do not take any parameter
        case ICC_DISCONNECT:
            skipStack=0;
            break;

        // these attributes take integer values
        case ICC_TIMEOUT:
        case ICC_RECONNECT:
        case ICC_PING_INTERVAL:
        case ICC_CLIENT_READY:
        case ICC_SELECT_TIMEOUT:
            {
                long val=SvIV(attrib);
                //printf("%d(INT): %d\n",key,val);
                if (ICC_OK != ICC_set(picc->iccObj,key,val,NULL,NULL))
                    croak("ICC_set(%d,%d) failed ...\n",key,val);
            }
            break;

        // these attributes take strings
        case ICC_PORT_NAME:
        case ICC_KIS_HOST_NAMES:
        case ICC_CLIENT_NAME:
        case ICC_CRYPT_PASSWORD:
           {
               STRLEN l;
               char *val=(char*)SvPV(attrib,l);
               //printf("%d(STR): %s\n",key,val);
               if (ICC_OK != ICC_set(picc->iccObj,key,val,NULL,NULL))
                    croak("ICC_set(%d,%s) failed ...\n",key,val);
            }
            break;

        // a long (pointer, etc...)
        case ICC_CLIENT_DATA:
            picc->clientData=newSVsv(attrib);
            break;

        // takes an array of strings
        case ICC_CLIENT_RECEIVE_ARRAY:
            {
                char *fn;
                STRLEN l;
                I32 n, numStr=av_len((AV*)SvRV(attrib));
                char *ar[104];
                for (n=0 ; n<=numStr && n<=99 ; ++n) {
                    fn=SvPV(*av_fetch((AV*)SvRV(attrib),n,0),l);
                    ar[n]=strdup(fn);
                }
                ar[n+0]=NULL;
                ar[n+1]=NULL;
                        
                if (ICC_OK != ICC_set(picc->iccObj,ICC_CLIENT_RECEIVE,
                                      ar[ 0],ar[ 1],ar[ 2],ar[ 3],ar[ 4],ar[ 5],ar[ 6],ar[ 7],ar[ 8],ar[ 9],
                                      ar[10],ar[11],ar[12],ar[13],ar[14],ar[15],ar[16],ar[17],ar[18],ar[19],
                                      ar[20],ar[21],ar[22],ar[23],ar[24],ar[25],ar[26],ar[27],ar[28],ar[29],
                                      ar[30],ar[31],ar[32],ar[33],ar[34],ar[35],ar[36],ar[37],ar[38],ar[39],
                                      ar[40],ar[41],ar[42],ar[43],ar[44],ar[45],ar[46],ar[47],ar[48],ar[49],
                                      ar[50],ar[51],ar[52],ar[53],ar[54],ar[55],ar[56],ar[57],ar[58],ar[59],
                                      ar[60],ar[61],ar[62],ar[63],ar[64],ar[65],ar[66],ar[67],ar[68],ar[69],
                                      ar[70],ar[71],ar[72],ar[73],ar[74],ar[75],ar[76],ar[77],ar[78],ar[79],
                                      ar[80],ar[81],ar[82],ar[83],ar[84],ar[85],ar[86],ar[87],ar[88],ar[89],
                                      ar[90],ar[91],ar[92],ar[93],ar[94],ar[95],ar[96],ar[97],ar[98],ar[99],
                                      NULL,NULL)) {
                    croak("ICC_set(ICC_CLIENT_RECEIVE,....) failed\n");
                }
            }
            break;

        // callbacks
        case ICC_DATA_MSG_CALLBACK:
            if (ICC_OK != ICC_set(picc->iccObj,key,_data_msg_callback,NULL))
                croak("ICC_set(ICC_DATA_MSG_CALLBACK,....) failed\n");
            sv_setsv (picc->data_msg_callback, attrib);
            break;
                     
        case ICC_SET_FDS_CALLBACK:
            if (ICC_OK != ICC_set(picc->iccObj,key,_set_fds_callback,NULL))
                croak("ICC_set(ICC_SET_FDS_CALLBACK,....) failed\n");
            sv_setsv (picc->set_fds_callback, attrib);
            break;

        case ICC_SELECT_TIMEOUT_CALLBACK:
            if (ICC_OK != ICC_set(picc->iccObj,key,_select_timeout_callback,NULL))
                croak("ICC_set(ICC_SELECT_TIMEOUT_CALLBACK,....) failed\n");
            sv_setsv (picc->select_timeout_callback, attrib);
            break;
        
        case ICC_SELECT_SIGNAL_CALLBACK:
            if (ICC_OK != ICC_set(picc->iccObj,key,_select_signal_callback,NULL))
                croak("ICC_set(ICC_SELECT_SIGNAL_CALLBACK,....) failed\n");
            sv_setsv (picc->select_signal_callback, attrib);
            break;

        case ICC_SELECT_MSG_CALLBACK:
            if (ICC_OK != ICC_set(picc->iccObj,key,_select_msg_callback,NULL))
                croak("ICC_set(ICC_SELECT_MSG_CALLBACK,....) failed\n");
            sv_setsv (picc->select_msg_callback, attrib);
            break;

        case ICC_DISCONNECT_CALLBACK:
            if (ICC_OK != ICC_set(picc->iccObj,key,_disconnect_callback,NULL))
                croak("ICC_set(ICC_DISCONNECT_CALLBACK,....) failed\n");
            sv_setsv (picc->disconnect_callback, attrib);
            break;

        case ICC_RECONNECT_CALLBACK:
            if (ICC_OK != ICC_set(picc->iccObj,key,_reconnect_callback,NULL))
                croak("ICC_set(ICC_RECONNECT_CALLBACK,....) failed\n");
            sv_setsv (picc->reconnect_callback, attrib);
            break;

        // send data to server
        case ICC_SEND_DATA:
            {
                STRLEN l;
                char *keyStr=SvPV(attrib,l);
                int type=SvIV(attrib2);
                char *buf=SvPV(attrib3,l);
                if (ICC_OK != ICC_set(picc->iccObj,key,keyStr,type,buf,NULL)) {
                    croak("ICC_set(ICC_SEND_DATA,...) failed\n");
                }
                skipStack=3;
            }
            break;

        // specific errors:
        case ICC_CLIENT_RECEIVE:
            croak("ICC_set: use ICC_CLIENT_RECEIVE_ARRAY instead of ICC_CLIENT_RECEIVE!\n");
            break;

        default:
            croak("ICC_set internal error: %d is unknown!\n",key);
    } // end switch
    
    return skipStack;
}




MODULE = Kools::Okapi        PACKAGE = Kools::Okapi

#
# ============================================== ICC_create
#
perl_iccObj_t *
ICC_create(fArg,...)
    ICC_option_t fArg = NO_INIT
    CODE:
        ICC_opaque iccObj;
        int i=0;
        perl_iccObj_t *picc;

        // perform ICC_create, if it fails bail out.        
        iccObj=ICC_create(0);
        if (0L==iccObj)
            croak("ICC_create(NULL) failed\n");
        
        // now allocate main Perl ICC structure
        picc=calloc(sizeof(perl_iccObj_t),1);
        if (NULL==picc)
            croak("Out of memory in ICC_create()\n");
            
        // fill up picc
        picc->iccObj=iccObj;
        picc->data_msg_callback        = newSVsv (&PL_sv_undef);
        picc->set_fds_callback         = newSVsv (&PL_sv_undef);
        picc->select_timeout_callback  = newSVsv (&PL_sv_undef);
        picc->select_signal_callback   = newSVsv (&PL_sv_undef);
        picc->select_msg_callback      = newSVsv (&PL_sv_undef);
        picc->disconnect_callback      = newSVsv (&PL_sv_undef);
        picc->reconnect_callback       = newSVsv (&PL_sv_undef);


        if (ICC_OK != ICC_set(iccObj,ICC_CLIENT_DATA,picc,NULL))
            croak("ICC_create(internal ICC_CLIENT_DATA) failed\n");
        
        while (i<items) {
            ICC_option_t key=SvIV(ST(i));
            SV* p1 = (i+1<items ? ST(i+1) : NULL);
            SV* p2 = (i+2<items ? ST(i+2) : NULL);
            SV* p3 = (i+3<items ? ST(i+3) : NULL);
            int iSkip=processCreateAndSetParameters(picc, key,p1,p2,p3);
            i += iSkip+1;
        }
        RETVAL = picc;
    OUTPUT:
        RETVAL


#
# ============================================== ICC_set
#
ICC_status_t
ICC_set(picc,fArg,...)
    perl_iccObj_t* picc
    ICC_option_t fArg = NO_INIT
    CODE:
        ICC_status_t status;
        int i=1;

        while (i<items) {
            ICC_option_t key=SvIV(ST(i));
            SV* p1 = (i+1<items ? ST(i+1) : NULL);
            SV* p2 = (i+2<items ? ST(i+2) : NULL);
            SV* p3 = (i+3<items ? ST(i+3) : NULL);
            int iSkip=processCreateAndSetParameters(picc, key,p1,p2,p3);
            i += iSkip+1;
        }
        RETVAL = ICC_OK;
    OUTPUT:
        RETVAL


#
# ============================================== ICC_get
#
SV*
ICC_get(picc,attrib)
    perl_iccObj_t* picc
    ICC_option_t attrib
    CODE:
        RETVAL=newSV(0);
        switch (attrib) {
            // special attributes:
            case ICC_CLIENT_DATA:
                sv_setsv(RETVAL,picc->clientData);
                break;

            // these attributes take strings
            case ICC_PORT_NAME:
            case ICC_KIS_HOST_NAMES:
            case ICC_CLIENT_NAME:
            case ICC_CRYPT_PASSWORD:
            case ICC_GET_SENT_DATA_MSG_FOR_DISPLAY:
                {
                    char *s=(char*)ICC_get(picc->iccObj,attrib);
                    if (s!=NULL)
                        sv_setpv(RETVAL,s);
                }
                break;

            // these attributes take integer values
            case ICC_TIMEOUT:
            case ICC_RECONNECT:
            case ICC_PING_INTERVAL:
            case ICC_CLIENT_READY:
            case ICC_SELECT_TIMEOUT:
            default:
                {
                    long l=(long)ICC_get(picc->iccObj,attrib);
                    sv_setiv(RETVAL,l);
                }
                break;
        }
    OUTPUT:
        RETVAL


#
# ============================================== ICC_main_loop
#
ICC_status_t
ICC_main_loop(picc)
    perl_iccObj_t* picc;
    CODE:
        RETVAL = ICC_main_loop(picc->iccObj);
    OUTPUT:
	    RETVAL


#
# ============================================== ICC_main_init
#
ICC_status_t
ICC_main_init(picc)
    perl_iccObj_t* picc;
    CODE:
        RETVAL = ICC_main_init(picc->iccObj);
    OUTPUT:
	    RETVAL


#
# ============================================== ICC_main_start
#
ICC_status_t
ICC_main_start(picc)
    perl_iccObj_t* picc;
    CODE:
        RETVAL = ICC_main_start(picc->iccObj);
    OUTPUT:
	    RETVAL


#
# ============================================== ICC_main_select
#
int
ICC_main_select(picc)
    perl_iccObj_t* picc;
    CODE:
        RETVAL = ICC_main_select(picc->iccObj);
    OUTPUT:
	    RETVAL


#
# ============================================== ICC_main_timeout
#
ICC_status_t
ICC_main_timeout(picc)
    perl_iccObj_t* picc
    CODE:
        RETVAL = ICC_main_timeout(picc->iccObj);
    OUTPUT:
	    RETVAL


#
# ============================================== ICC_main_signal
#
ICC_status_t
ICC_main_signal(picc)
    perl_iccObj_t* picc
    CODE:
        RETVAL = ICC_main_signal(picc->iccObj);
    OUTPUT:
	    RETVAL


#
# ============================================== ICC_main_message
#
ICC_status_t
ICC_main_message(picc)
    perl_iccObj_t* picc
    CODE:
        RETVAL = ICC_main_message(picc->iccObj);
    OUTPUT:
	    RETVAL


#
# ============================================== ICC_main_disconnect
#
ICC_status_t
ICC_main_disconnect(picc)
    perl_iccObj_t* picc
    CODE:
        RETVAL = ICC_main_disconnect(picc->iccObj);
    OUTPUT:
	    RETVAL


#
# ============================================== ICC_multiple_main_start
#
ICC_status_t
ICC_multiple_main_start(piccArr)
    AV *piccArr
    CODE:
	    {
	        I32 n, numElt;
	        ICC_opaque *ar;
	
	        numElt=av_len(piccArr);
	        ar=calloc(sizeof(ICC_opaque),numElt+1);
	        for (n=0 ; n<=numElt ; ++n) {
	            ar[n]=((perl_iccObj_t*)SvIV(*av_fetch(piccArr,n,0)))->iccObj;
	        }
	        RETVAL = ICC_multiple_main_start(ar, numElt);
	    }
    OUTPUT:
	    RETVAL


#
# ============================================== ICC_multiple_main_message
#
ICC_status_t
ICC_multiple_main_message(piccArr)
    AV *piccArr
    CODE:
	    {
	        I32 n, numElt;
	        ICC_opaque *ar;
	
	        numElt=av_len(piccArr);
	        ar=calloc(sizeof(ICC_opaque),numElt+1);
	        for (n=0 ; n<=numElt ; ++n) {
	            ar[n]=((perl_iccObj_t*)SvIV(*av_fetch(piccArr,n,0)))->iccObj;
	        }
	        RETVAL = ICC_multiple_main_message(ar, numElt);
	    }
    OUTPUT:
	    RETVAL


#
# ============================================== ICC_multi_main_loop
#
ICC_status_t
ICC_multi_main_loop(piccArr)
    AV *piccArr
    CODE:
	    {
	        I32 n, numElt;
	        ICC_opaque ar[6];
	
	        numElt=av_len(piccArr);
	        if (numElt>4)
	            croak("Sorry, but Perl implementation of ICC_multi_main_loop([]) can only take a maximum of 5 ICC objects!");
	        
	        for (n=0 ; n<=numElt ; ++n) {
	            ar[n]=((perl_iccObj_t*)SvIV(*av_fetch(piccArr,n,0)))->iccObj;
	        }
	        ar[n]=0L;
	        RETVAL = ICC_multi_main_loop(ar[0], ar[1], ar[2], ar[3], ar[4], ar[5], ar[6], NULL);
	    }
    OUTPUT:
	    RETVAL


#
# ============================================== ICC_DataMsg_init
#
void
ICC_DataMsg_init(type, msgkey)
    ICC_Data_Msg_Type_t  type
    char *               msgkey


#
# ============================================== ICC_DataMsg_set
#
void
ICC_DataMsg_set(key, value)
    char *  key
    char *  value


#
# ============================================== ICC_DataMsg_String_set
#
void
ICC_DataMsg_String_set(key, value)
    char *  key
    char *  value


#
# ============================================== ICC_DataMsg_Integer_set
#
void
ICC_DataMsg_Integer_set(key, value)
    char *  key
    int     value


#
# ============================================== ICC_DataMsg_Float_set
#
void
ICC_DataMsg_Float_set(key, dec, value)
    char *  key
    int     dec
    double  value


#
# ============================================== ICC_DataMsg_Date_set
#
void
ICC_DataMsg_Date_set(key, value)
    char *  key
    char *  value


#
# ============================================== ICC_DataMsg_Choice_set
#
void
ICC_DataMsg_Choice_set(key, val, value)
    char *  key
    int     val
    char *  value


#
# ============================================== ICC_DataMsg_get
#
char *
ICC_DataMsg_get(key)
    char *  key
    CODE:
        char *buf;
        int bufLen=0;
        long bufLenL=0;
        bufLenL=ICC_DataMsg_Size_find(key,&bufLen);
        if (bufLen>0) {
            char *buf=calloc(sizeof(char),bufLen+1);
            if (NULL==buf)
                croak("ICC_DataMsg_get() - out of memory\n");
            else {
                RETVAL=ICC_DataMsg_get(key,buf);
                free(buf);
            }
        }
        else
            RETVAL=NULL;
    OUTPUT:
        RETVAL


#
# ============================================== ICC_DataMsg_Buffer_set
#
void
ICC_DataMsg_Buffer_set(buffer)
    char * buffer
    

#
# ============================================== ICC_DataMsg_Buffer_get
#
char *
ICC_DataMsg_Buffer_get()
    CODE:
        //RETVAL=newSV(0);
        RETVAL=ICC_DataMsg_Buffer_get();
        //if (buf!=NULL)
        //    sv_setpv(RETVAL,buf);
    OUTPUT:
        RETVAL


#
# ============================================== ICC_DataMsg_send_to_server
#
int
ICC_DataMsg_send_to_server(picc)
    perl_iccObj_t * picc
    CODE:
        RETVAL=ICC_DataMsg_send_to_server(picc->iccObj);
    OUTPUT:
        RETVAL
    
