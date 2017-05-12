/*###################################################################################
#
#   Embperl - Copyright (c) 1997-2001 Gerald Richter / ECOS
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#   For use with Apache httpd and mod_perl, see also Apache copyright.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: epio.c,v 1.23.2.1 2003/01/22 08:23:35 richter Exp $
#
###################################################################################*/


#include "ep.h"
#include "epmacro.h"
#include "crypto/epcrypto.h"


static char sLogFilename [512] = "" ;

#ifndef PerlIO


#define FILEIOTYPE "StdIO"
/* define same helper macros to let it run with plain perl 5.003 */
/* where no PerlIO is present */

#define PerlIO_stdinF stdin
#define PerlIO_stdoutF stdout
#define PerlIO_stderrF stderr
#define PerlIO_close fclose
#define PerlIO_open fopen
#define PerlIO_flush fflush
#define PerlIO_vprintf vfprintf
#define PerlIO_fileno fileno
#define PerlIO_tell ftell
#define PerlIO_seek fseek

#define PerlIO_read(f,buf,cnt) fread(buf,1,cnt,f)
#define PerlIO_write(f,buf,cnt) fwrite(buf,1,cnt,f)

#define PerlIO_putc(f,c) fputc(c,f)

#else

#define FILEIOTYPE "PerlIO"

#define PerlIO_stdinF PerlIO_stdin ()
#define PerlIO_stdoutF PerlIO_stdout ()
#define PerlIO_stderrF PerlIO_stderr ()


#endif


/* Some helper macros for tied handles, taken from mod_perl 2.0 :-) */
/*
 * bleedperl change #11639 switch tied handle magic
 * from living in the gv to the GvIOp(gv), so we have to deal
 * with both to support 5.6.x
 */
#if ((PERL_REVISION == 5) && (PERL_VERSION >= 7))
#   define TIEHANDLE_SV(handle) (SV*)GvIOp((SV*)handle)
#else
#   define TIEHANDLE_SV(handle) (SV*)handle
#endif

#define HANDLE_GV(name) gv_fetchpv(name, TRUE, SVt_PVIO)



#ifdef APACHE
#define DefaultLog "/tmp/embperl.log"


static request_rec * pAllocReq = NULL ;
#endif



/* -------------------------------------------------------------------------------------
*
* begin output transaction
*
-------------------------------------------------------------------------------------- */

struct tBuf *   oBegin (/*i/o*/ register req * r)

    {
    EPENTRY1N (oBegin, r -> nMarker) ;
    
    r -> nMarker++ ;
    
    return r -> pLastBuf ;
    }

/* -------------------------------------------------------------------------------------
*
*  rollback output transaction (throw away all the output since corresponding begin)
*
-------------------------------------------------------------------------------------- */

void oRollbackOutput (/*i/o*/ register req * r,
			struct tBuf *   pBuf) 

    {
    EPENTRY1N (oRollback, r -> nMarker) ;

    if (pBuf == NULL)
        {
        if (r -> pLastFreeBuf)
            r -> pLastFreeBuf -> pNext = r -> pFirstBuf ;
        else 
            r -> pFreeBuf = r -> pFirstBuf ;
        
        r -> pLastFreeBuf = r -> pLastBuf ;
        
        r -> pFirstBuf   = NULL ;
        r -> nMarker     = 0 ;
        }
    else
	{
        if (r -> pLastBuf == pBuf || pBuf -> pNext == NULL)
            r -> nMarker-- ;
        else
            {
            r -> nMarker = pBuf -> pNext -> nMarker - 1 ;
            if (r -> pLastFreeBuf)
                r -> pLastFreeBuf -> pNext = pBuf -> pNext ;
            else
                r -> pFreeBuf = pBuf -> pNext ;
            r -> pLastFreeBuf = r -> pLastBuf ;
            }
        pBuf -> pNext = NULL ;
        }
        
    r -> pLastBuf = pBuf ;

    }

/* -------------------------------------------------------------------------------------
*
*  rollback output transaction  and errors(throw away all the output since corresponding
*  begin)
*
-------------------------------------------------------------------------------------- */

void oRollback (/*i/o*/ register req * r,
			struct tBuf *   pBuf) 

    {
    oRollbackOutput (r, pBuf) ;
    
    RollbackError (r) ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* commit output transaction (all the output since corresponding begin is vaild)*/
/*                                                                              */
/* ---------------------------------------------------------------------------- */

void oCommitToMem (/*i/o*/ register req * r,
			struct tBuf *   pBuf,
                   char *          pOut) 

    {
    EPENTRY1N (oCommit, r -> nMarker) ;

    
    if (pBuf == NULL)
        r -> nMarker = 0 ;
    else
        if (r -> pLastBuf == pBuf)
            r -> nMarker-- ;
        else
            r -> nMarker = pBuf -> pNext -> nMarker - 1 ;
    
    if (r -> nMarker == 0)
        {
        if (pBuf == NULL)
            pBuf = r -> pFirstBuf ;
        else
            pBuf = pBuf -> pNext ;
        
        if (pOut)
            {
            while (pBuf)
                {
                memmove (pOut, pBuf + 1, pBuf -> nSize) ;
                pOut += pBuf -> nSize ;
                pBuf = pBuf -> pNext ;
                }
            *pOut = '\0' ;                
            }
        else
            {
            while (pBuf)
                {
                owrite (r, pBuf + 1, pBuf -> nSize) ;
                pBuf = pBuf -> pNext ;
                }
            }
        }

    CommitError (r) ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* commit output transaction (all the output since corresponding begin is vaild)*/
/*                                                                              */
/* ---------------------------------------------------------------------------- */

void oCommit (/*i/o*/ register req *  r,
		      struct tBuf *   pBuf) 

    {
    EPENTRY1N (oCommit, r -> nMarker) ;

    oCommitToMem (r, pBuf, NULL) ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* write to a buffer                                                            */
/*                                                                              */
/* we will alloc a new buffer for every write                                   */
/* this is fast with apache palloc or for malloc if no free is call in between  */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int bufwrite (/*i/o*/ register req * r,
		     /*in*/ const void * ptr, size_t size) 


    {
    struct tBuf * pBuf ;

    EPENTRY1N (bufwrite, r -> nMarker) ;

    pBuf = (struct tBuf *)_malloc (r, size + sizeof (struct tBuf)) ;

    if (pBuf == NULL)
        return 0 ;

    memcpy (pBuf + 1,  ptr, size) ;
    pBuf -> pNext   = NULL ;
    pBuf -> nSize   = size ;
    pBuf -> nMarker = r -> nMarker ;

    if (r -> pLastBuf)
        {
        r -> pLastBuf -> pNext = pBuf ;
        pBuf -> nCount    = r -> pLastBuf -> nCount + size ;
        }
    else
        pBuf -> nCount    = size ;
        
    if (r -> pFirstBuf == NULL)
        r -> pFirstBuf = pBuf ;
    r -> pLastBuf = pBuf ;


    return size ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* free buffers                                                                 */
/*                                                                              */
/* free all buffers                                                             */
/* note: this is not nessecary for apache palloc, because all buffers are freed */
/*       at the end of the request                                              */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static void buffree (/*i/o*/ register req * r)

    {
    struct tBuf * pNext = NULL ;
    struct tBuf * pBuf ;

#ifdef APACHE
    if ((r -> bDebug & dbgMem) == 0 && pAllocReq != NULL)
        {
        r -> pFirstBuf    = NULL ;
        r -> pLastBuf     = NULL ;
        r -> pFreeBuf     = NULL ;
        r -> pLastFreeBuf = NULL ;
        return ; /* no need for apache to free memory */
        }
#endif
        
    /* first walk thru the used buffers */

    pBuf = r -> pFirstBuf ;
    while (pBuf)
        {
        pNext = pBuf -> pNext ;
        _free (r, pBuf) ;
        pBuf = pNext ;
        }

    r -> pFirstBuf = NULL ;
    r -> pLastBuf  = NULL ;


    /* now walk thru the unused buffers */
    
    pBuf = r -> pFreeBuf ;
    while (pBuf)
        {
        pNext = pBuf -> pNext ;
        _free (r, pBuf) ;
        pBuf = pNext ;
        }

    r -> pFreeBuf = NULL ;
    r -> pLastFreeBuf  = NULL ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* get the length outputed to buffers so far                                    */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

int GetContentLength (/*i/o*/ register req * r)
    {
    if (r -> pLastBuf)
        return r -> pLastBuf -> nCount ;
    else
        return 0 ;
    
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* set the name of the input file and open it                                   */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int OpenInput (/*i/o*/ register req * r,
			/*in*/ const char *  sFilename)

    {
    MAGIC *mg;
    GV *handle ;

#ifdef APACHE
    if (r -> pApacheReq)
        return ok ;
#endif
    
    handle = HANDLE_GV("STDIN") ;
    if (handle)
        {
        SV *iohandle = TIEHANDLE_SV(handle) ;
 
        if (iohandle && SvMAGICAL(iohandle) && (mg = mg_find((SV*)iohandle, 'q')) && mg->mg_obj) 
            {
            r -> ifdobj = mg->mg_obj ;
            if (r -> bDebug)
                {
                char *package = HvNAME(SvSTASH((SV*)SvRV(mg->mg_obj)));
                lprintf (r, "[%d]Open TIED STDIN %s...\n", r -> nPid, package) ;
                }
            return ok ;
            }
        }

    if (r -> ifd && r -> ifd != PerlIO_stdinF)
        PerlIO_close (r -> ifd) ;

    r -> ifd = NULL ;

    if (sFilename == NULL || *sFilename == '\0')
        {
        /*
        GV * io = gv_fetchpv("STDIN", TRUE, SVt_PVIO) ;
        if (io == NULL || (r -> ifd = IoIFP(io)) == NULL)
            {
            if (r -> bDebug)
                lprintf (r, "[%d]Cannot get Perl STDIN, open os stdin\n", r -> nPid) ;
            r -> ifd = PerlIO_stdinF ;
            }
        */
        
        r -> ifd = PerlIO_stdinF ;

        return ok ;
        }

    if ((r -> ifd = PerlIO_open (sFilename, "r")) == NULL)
        {
        strncpy (r -> errdat1, sFilename, sizeof (r -> errdat1) - 1) ;
        strncpy (r -> errdat2, Strerror(errno), sizeof (r -> errdat2) - 1) ; 
        return rcFileOpenErr ;
        }

    return ok ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* close input file                                                             */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int CloseInput (/*i/o*/ register req * r)

    {
    if (0) /* r -> ifdobj) */
	{	    
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(sp);
	XPUSHs(r -> ifdobj);
	PUTBACK;
	perl_call_method ("CLOSE", G_VOID | G_EVAL) ; 
        SPAGAIN ;
	FREETMPS;
	LEAVE;
	r -> ifdobj = NULL ;
	}


#ifdef APACHE
    if (r -> pApacheReq)
        return ok ;
#endif

    if (r -> ifd && r -> ifd != PerlIO_stdinF)
        PerlIO_close (r -> ifd) ;

    r -> ifd = NULL ;

    return ok ;
    }



/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* read block of data from input (web client)                                   */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int iread (/*i/o*/ register req * r,
	   /*in*/ void * ptr, size_t size) 

    {
    char * p = (char *)ptr ; /* workaround for aix c complier */
    
    if (size == 0)
        return 0 ;

    if (r -> ifdobj)
	{	    
	int num ;
	int n ;
	SV * pBufSV ;

	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(sp);
	XPUSHs(r -> ifdobj);
	XPUSHs(sv_2mortal(pBufSV = NEWSV(0, 0)));
	PUTBACK;
	num = perl_call_method ("READ", G_SCALAR) ; 
	SPAGAIN;
	n = 0 ;
	if (num > 0)
	    {
	    STRLEN  n = POPi ;
	    char * p ;
	    STRLEN l ;
	    if (n >= 0)
		{
		p = SvPV (pBufSV, l) ;
		if (l > size)
		    l = size ;
		if (l > n)
		    l = n ;
		memcpy (ptr, p, l) ;
		}
	    }
	PUTBACK;
	FREETMPS;
	LEAVE;
	return n ;
	}

#if defined (APACHE)
    if (r -> pApacheReq)
        {
        setup_client_block(r -> pApacheReq, REQUEST_CHUNKED_ERROR); 
        if(should_client_block(r -> pApacheReq))
            {
            int c ;
            int n = 0 ;
            while (1)
                {
                c = get_client_block(r -> pApacheReq, p, size); 
                if (c < 0 || c == 0)
                    return n ;
                n    	     += c ;
                p            += c ;
                size         -= c ;
                }
            }
        else
            return 0 ;
        } 
#endif

    return PerlIO_read (r -> ifd, p, size) ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* read line of data from input (web client)                                    */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


char * igets (/*i/o*/ register req * r,
			/*in*/ char * s,   int    size) 

    {
#if defined (APACHE)
    if (r -> pApacheReq)
        return NULL ;
#endif

#ifdef PerlIO
        {
        /*
        FILE * f = PerlIO_exportFILE (r -> ifd, 0) ;
        char * p = fgets (s, size, f) ;
        PerlIO_releaseFILE (r -> ifd, f) ;
        return p ;
        */
        return NULL ;
        }
#else
    return fgets (s, size, r -> ifd) ;
#endif
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* read HTML File into pBuf                                                     */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

int ReadHTML (/*i/o*/ register req * r,
	      /*in*/    char *    sInputfile,
              /*in*/    size_t *  nFileSize,
              /*out*/   SV   * *  ppBuf)

    {              
    SV   * pBufSV ;
    char * pData ;
#ifdef PerlIO
    PerlIO * ifd ;
#else
    FILE *   ifd ;
#endif
    
    if (r -> bDebug)
        lprintf (r, "[%d]Reading %s as input using %s ...\n", r -> nPid, sInputfile, FILEIOTYPE) ;

#ifdef WIN32
    if ((ifd = PerlIO_open (sInputfile, "rb")) == NULL)
#else
    if ((ifd = PerlIO_open (sInputfile, "r")) == NULL)
#endif        
        {
        strncpy (r -> errdat1, sInputfile, sizeof (r -> errdat1) - 1) ;
        strncpy (r -> errdat2, Strerror(errno), sizeof (r -> errdat2) - 1) ; 
        return rcFileOpenErr ;
        }

    if ((long)*nFileSize < 0)
	return rcFileOpenErr ;


    pBufSV = sv_2mortal (newSV(*nFileSize + 1)) ;
    pData = SvPVX(pBufSV) ;

#if EPC_ENABLE
    
    if (*nFileSize)
        {
        int rc ;
        char * syntax ;

#ifndef EP2
        syntax = (r -> pTokenTable && strcmp ((char *)r -> pTokenTable, "Text") == 0)?"Text":"Embperl" ;
#else
        syntax = r -> pTokenTable -> sName ;
#endif

        if ((rc = do_crypt_file (ifd, NULL, pData, *nFileSize, 0, syntax, EPC_HEADER)) <= 0)
            {
            if (rc < -1 || !EPC_UNENCYRPTED)
                {
                sprintf (r -> errdat1, "%d", rc) ;
                return rcCryptoWrongHeader + -rc - 1;
                }

            PerlIO_seek (ifd, 0, SEEK_SET) ;
            *nFileSize = PerlIO_read (ifd, pData, *nFileSize) ;
            }
        else
            *nFileSize = rc ;
        }
#else
    
    if (*nFileSize)
        *nFileSize = PerlIO_read (ifd, pData, *nFileSize) ;

#endif

    PerlIO_close (ifd) ;
    
    pData [*nFileSize] = '\0' ;
    SvCUR_set (pBufSV, *nFileSize) ;
    SvTEMP_off (pBufSV) ;
    SvPOK_on   (pBufSV) ;

    *ppBuf = pBufSV ;

    return ok ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* set the name of the output file and open it                                  */
/*                                                                              */
/* ---------------------------------------------------------------------------- */



int OpenOutput (/*i/o*/ register req * r,
			/*in*/ const char *  sFilename)

    {
    MAGIC *mg;
    GV *handle ;
    
    r -> pFirstBuf = NULL ; 
    r -> pLastBuf  = NULL ; 
    r -> nMarker   = 0 ;
    r -> pMemBuf   = NULL ;
    r -> nMemBufSize = 0 ;
    r -> pFreeBuf     = NULL ;
    r -> pLastFreeBuf = NULL ;


    
    if (r -> ofd && r -> ofd != PerlIO_stdoutF)
        PerlIO_close (r -> ofd) ;

    r -> ofd = NULL ;

    if (sFilename == NULL || *sFilename == '\0')
        {
#if defined (APACHE)
	if (r -> pApacheReq)
	    {
	    if (r -> bDebug)
		lprintf (r, "[%d]Using APACHE for output...\n", r -> nPid) ;
	    return ok ;
	    }
#endif

        handle = HANDLE_GV("STDOUT") ;
        if (handle)
            {
            SV *iohandle = TIEHANDLE_SV(handle) ;
 
            if (iohandle && SvMAGICAL(iohandle) && (mg = mg_find((SV*)iohandle, 'q')) && mg->mg_obj) 
                {
                r -> ofdobj = mg->mg_obj ;
                if (r -> bDebug)
                    {
                    char *package = HvNAME(SvSTASH((SV*)SvRV(mg->mg_obj)));
                    lprintf (r,  "[%d]Open TIED STDOUT %s for output...\n", r -> nPid, package) ;
                    }
                return ok ;
                }
            }
	
	r -> ofd = PerlIO_stdoutF ;
        
        if (r -> bDebug)
            {
#ifdef APACHE
             if (r -> pApacheReq)
                lprintf (r, "[%d]Open STDOUT to Apache for output...\n", r -> nPid) ;
             else
#endif
             lprintf (r, "[%d]Open STDOUT for output...\n", r -> nPid) ;
            }
        return ok ;
        }

    if (r -> bDebug)
        lprintf (r, "[%d]Open %s for output...\n", r -> nPid, sFilename) ;

#ifdef WIN32
    if ((r -> ofd = PerlIO_open (sFilename, "wb")) == NULL)
#else
    if ((r -> ofd = PerlIO_open (sFilename, "w")) == NULL)
#endif        
        {
        strncpy (r -> errdat1, sFilename, sizeof (r -> errdat1) - 1) ;
        strncpy (r -> errdat2, Strerror(errno), sizeof (r -> errdat2) - 1) ; 
        return rcFileOpenErr ;
        }

    return ok ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* close the output file                                                        */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int CloseOutput (/*i/o*/ register req * r)

    {
    
    /* make sure all buffers are freed */

    buffree (r) ; 

/* #if defined (APACHE)
    if (r -> pApacheReq)
        return ok ;
  #endif */

    if (0) /* r -> ofdobj) */
	{	    
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(sp);
	XPUSHs(r -> ifdobj);
	PUTBACK;
	perl_call_method ("CLOSE", G_VOID | G_EVAL) ; 
        SPAGAIN ;
	FREETMPS;
	LEAVE;
	r -> ofdobj = NULL ;
	}

    if (r -> ofd && r -> ofd != PerlIO_stdoutF)
        PerlIO_close (r -> ofd) ;

    r -> ofd = NULL ;

    return ok ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* set output to memory buffer                                                  */
/*                                                                              */
/* ---------------------------------------------------------------------------- */



void OutputToMemBuf (/*i/o*/ register req * r,
			/*in*/ char *  pBuf,
                     /*in*/ size_t  nBufSize)

    {
    if (pBuf == NULL)
	pBuf = _malloc (r, nBufSize) ;

    *pBuf = '\0' ;
    r -> pMemBuf	 = pBuf ;
    r -> pMemBufPtr      = pBuf ;
    r -> nMemBufSize     = nBufSize ;
    r -> nMemBufSizeFree = nBufSize ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* set output to standard                                                       */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


char * OutputToStd (/*i/o*/ register req * r)

    {
    char * p = r -> pMemBuf ;
    r -> pMemBuf         = NULL ;
    r -> nMemBufSize     = 0 ;
    r -> nMemBufSizeFree = 0 ;
    return p ;
    }



/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* puts to output (web client)                                                  */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

int oputs (/*i/o*/ register req * r,
			/*in*/ const char *  str) 

    {
    return owrite (r, str, strlen (str)) ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* write block of data to output (web client)                                   */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

int owrite (/*i/o*/ register req * r,
	    /*in*/ const void * ptr, size_t size) 

    {
    size_t n = size ;

    if (n == 0 || r -> bDisableOutput)
        return 0 ;

    if (r -> pMemBuf)
        {
        char * p ;
        size_t s = r -> nMemBufSize ;
        if (n >= r -> nMemBufSizeFree)
            {
            size_t oldsize = s ;
            if (s < n)
                s = n + r -> nMemBufSize ;
            
            r -> nMemBufSize      += s ;
            r -> nMemBufSizeFree  += s ;
            /*lprintf (r, "[%d]MEM:  Realloc pMemBuf, nMemSize = %d\n", nPid, nMemBufSize) ; */
            p = _realloc (r, r -> pMemBuf, oldsize, r -> nMemBufSize) ;
            if (p == NULL)
                {
                r -> nMemBufSize      -= s ;
                r -> nMemBufSizeFree  -= s ;
                return 0 ;
                }
            r -> pMemBufPtr = p + (r -> pMemBufPtr - r -> pMemBuf) ;
            r -> pMemBuf = p ;
            }
                
        memcpy (r -> pMemBufPtr, ptr, n) ;
        r -> pMemBufPtr += n ;
        *(r -> pMemBufPtr) = '\0' ;
        r -> nMemBufSizeFree -= n ;
        return n ;
        }

    
    if (r -> nMarker)
        return bufwrite (r, ptr, n) ;

    if (r -> ofdobj)
	{	    
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(sp);
	XPUSHs(r -> ofdobj);
	XPUSHs(sv_2mortal(newSVpv((char *)ptr,size)));
	PUTBACK;
	perl_call_method ("PRINT", G_SCALAR) ; 
        SPAGAIN ;
	FREETMPS;
	LEAVE;
	return size ;
	}


#if defined (APACHE)
    if (r -> pApacheReq && r -> ofd == NULL)
        {
        if (n > 0)
            {
            n = rwrite (ptr, n, r -> pApacheReq) ;
            if (r -> bDebug & dbgFlushOutput)
                rflush (r -> pApacheReq) ;
            return n ;
            }
        else
            return 0 ;
        }
#endif
    if (n > 0 && r -> ofd)
        {
        n = PerlIO_write (r -> ofd, (void *)ptr, size) ;

        if (r -> bDebug & dbgFlushOutput)
            PerlIO_flush (r -> ofd) ;
        }

    return n ;
    }



/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* write one char to output (web client)                                        */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


void oputc (/*i/o*/ register req * r,
			/*in*/ char c)

    {
    if (r -> nMarker || r -> pMemBuf || r -> ofdobj)
        {
        owrite (r, &c, 1) ;
        return ;
        }

#if defined (APACHE)
    if (r -> pApacheReq && r -> ofd == NULL)
        {
        rputc (c, r -> pApacheReq) ;
        if (r -> bDebug & dbgFlushOutput)
            rflush (r -> pApacheReq) ;
        return ;
        }
#endif
    PerlIO_putc (r -> ofd, c) ;

    if (r -> bDebug & dbgFlushOutput)
        PerlIO_flush (r -> ofd) ;
    }



/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* set the name of the log file and open it                                     */
/*                                                                              */
/* nMode = 0 open later, save filename only										*/
/* nMode = 1 open now															*/
/* nMode = 2 open with saved filename											*/
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int OpenLog (/*i/o*/ register req * r,
			/*in*/ const char *  sFilename,
             /*in*/ int           nMode)

    {
    if (sFilename == NULL)
        sFilename = "" ;

    if (r -> lfd && (nMode == 2 || strcmp (sLogFilename, sFilename) == 0))
        return ok ; /*already open */

    if (r -> lfd && r -> lfd != PerlIO_stdoutF)
        PerlIO_close (r -> lfd) ;  /* close old logfile */
   
    r -> lfd = NULL ;

    
    if (r -> bDebug == 0)
	return ok ; /* never write to logfile if debugging is disabled */	    
    
    if (nMode != 2)
        {
        strncpy (sLogFilename, sFilename, sizeof (sLogFilename) - 1) ;
        sLogFilename[sizeof (sLogFilename) - 1] = '\0' ;
        }

    if (*sLogFilename == '\0')
        {
        sLogFilename[0] = '\0' ;
        r -> lfd = PerlIO_stdoutF ;
        return ok ;
        }

    if (nMode == 0)
        return ok ;
    
    if ((r -> lfd = PerlIO_open (sLogFilename, "a")) == NULL)
        {
        strncpy (r -> errdat1, sLogFilename, sizeof (r -> errdat1) - 1) ;
        strncpy (r -> errdat2, Strerror(errno), sizeof (r -> errdat2) - 1) ; 
        return rcLogFileOpenErr ;
        }

    return ok ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* return the handle of the log file                                            */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int GetLogHandle (/*i/o*/ register req * r)

    {
    if (r -> lfd)
	return PerlIO_fileno (r -> lfd) ;

    return 0 ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* return the current posittion of the log file                                 */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


long GetLogFilePos (/*i/o*/ register req * r)

    {
    if (r -> lfd)
	return PerlIO_tell (r -> lfd) ;

    return 0 ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* close the log file                                                           */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int CloseLog (/*i/o*/ register req * r)

    {
    if (r -> lfd && r -> lfd != PerlIO_stdoutF)
        PerlIO_close (r -> lfd) ;

    r -> lfd = NULL ;

    return ok ;
    }



/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* flush the log file                                                           */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int FlushLog (/*i/o*/ register req * r)

    {
    if (r -> lfd != NULL)
        PerlIO_flush (r -> lfd) ;

    return ok ;
    }



/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* printf to log file                                                           */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

int lprintf (/*i/o*/ register req * r,
			/*in*/ const char *  sFormat,
             /*in*/ ...) 

    {
    va_list  ap ;
    int      n ;

    if (r -> lfd == NULL)
        return 0 ;
    
    va_start (ap, sFormat) ;
    
        {
        n = PerlIO_vprintf (r -> lfd, sFormat, ap) ;
        if (r -> bDebug & dbgFlushLog)
            PerlIO_flush (r -> lfd) ;
        }


    va_end (ap) ;

    return n ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* write block of data to log file                                              */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int lwrite (/*i/o*/ register req * r,
	    /*in*/  const void * ptr, 
            /*in*/  size_t size) 

    {
    int n ;

    if (r -> lfd == NULL)
        return 0 ;
    
    n = PerlIO_write (r -> lfd, (void *)ptr, size) ;

    if (r -> bDebug & dbgFlushLog)
        PerlIO_flush (r -> lfd) ;

    return n ;
    }




/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Memory Allocation                                                            */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


void _free (/*i/o*/ register req * r,
			void * p)

    {
    size_t size ;
    size_t * ps ;

#ifdef APACHE
    if (pAllocReq && !(r -> bDebug & dbgMem))
        return ;
#endif


    if (r -> bDebug & dbgMem)
        {
        /* we do it a bit complicted so it compiles also on aix */
        ps = (size_t *)p ;
        ps-- ;
        size = *ps ;
        p = ps ;
        r -> nAllocSize -= size ;
        lprintf (r, "[%d]MEM:  Free %d Bytes at %08x  Allocated so far %d Bytes\n" ,r -> nPid, size, p, r -> nAllocSize) ;
        }

#ifdef APACHE
    if (r -> pApacheReq == NULL)
#endif
        free (p) ;
    }

void * _malloc (/*i/o*/ register req * r, 
                        size_t  size)

    {
    void * p ;
    size_t * ps ;

#ifdef APACHE
    pAllocReq = r -> pApacheReq  ;

    if (r -> pApacheReq)
        {
        p = palloc (r -> pApacheReq -> pool, size + sizeof (size)) ;
        }
    else
#endif
        
        p = malloc (size + sizeof (size)) ;

    if (r -> bDebug & dbgMem)
        {
        /* we do it a bit complicted so it compiles also on aix */
        ps = (size_t *)p ;
        *ps = size ;
        p = ps + 1 ;

        r -> nAllocSize += size ;
        lprintf (r, "[%d]MEM:  Alloc %d Bytes at %08x   Allocated so far %d Bytes\n" ,r -> nPid, size, p, r -> nAllocSize) ;
        }

    return p ;
    }

void * _realloc (/*i/o*/ register req * r,  void * ptr, size_t oldsize, size_t  size)

    {
    void * p ;
    size_t * ps ;
    size_t sizeold ;
    
#ifdef APACHE
    if (r -> pApacheReq)
        {
        p = palloc (r -> pApacheReq -> pool, size + sizeof (size)) ;
        if (p == NULL)
            return NULL ;
        
        if (r -> bDebug & dbgMem)
            {
            /* we do it a bit complicted so it compiles also on aix */
            ps = (size_t *)p ;
            *ps = size ;
            p = ps + 1;
        
            ps = (size_t *)ptr ;
            ps-- ;
            sizeold = *ps ;
            r -> nAllocSize += size - sizeold ;

            lprintf (r, "[%d]MEM:  ReAlloc %d Bytes at %08x   Allocated so far %d Bytes\n" ,r -> nPid, size, p, r -> nAllocSize) ;
            }

        memcpy (p, ptr, oldsize) ; 
        }
    else
#endif
        if (r -> bDebug & dbgMem)
            {
            ps = (size_t *)ptr ;
            ps-- ;
            r -> nAllocSize -= *ps ;
        
            p = realloc (ps, size + sizeof (size)) ;
            if (p == NULL)
                return NULL ;

            /* we do it a bit complicted so it compiles also on aix */
            ps = (size_t *)p ;
            *ps = size ;
            p = ps + 1;
            r -> nAllocSize += size ;
            lprintf (r, "[%d]MEM:  ReAlloc %d Bytes at %08x   Allocated so far %d Bytes\n" ,r -> nPid, size, p, r -> nAllocSize) ;
            }
        else
            p = realloc (ptr, size + sizeof (size)) ;

    return p ;
    }


char * _memstrcat (/*i/o*/ register req * r,
			const char *s, ...) 

    {
    va_list ap ;
    char *  p ;
    char *  str ;
    char *  sp ;
    int     l ;
    int     sum ;

    EPENTRY(_memstrcat) ;

    va_start(ap, s) ;

    p = (char *)s ;
    sum = 0 ;
    while (p)
        {
        sum += strlen (p) ;
        lprintf (r, "sum = %d p = %s\n", sum, p) ;
        p = va_arg (ap, char *) ;
        }
    sum++ ;

    va_end (ap) ;

    sp = str = _malloc (r, sum+1) ;

    va_start(ap, s) ;

    p = (char *)s ;
    while (p)
        {
        l = strlen (p) ;
        lprintf (r, "l = %d p = %s\n", l, p) ;
	memcpy (str, p, l) ;
        str += l ;
        p = va_arg (ap, char *) ;
        }
    *str = '\0' ;

    va_end (ap) ;


    return sp ;
    }



char * _ep_strdup (/*i/o*/ register req * r,
                 /*in*/  const char * str)

    {
    char * p ;        
    int    len = strlen (str) ;

    p = (char *)_malloc (r, len + 1) ;

    if (p)
        strcpy (p, str) ;

    return p ;
    }
    


char * _ep_strndup (/*i/o*/ register req * r,
                  /*in*/  const char *   str,
                  /*in*/  int            len)

    {
    char * p ;        

    p = (char *)_malloc (r, len + 1) ;

    if (p)
        {
        strncpy (p, str, len) ;

        p[len] = '\0' ;
        }

    return p ;
    }
    
char * _ep_memdup (/*i/o*/ register req * r,
                  /*in*/  const char *   str,
                  /*in*/  int            len)

    {
    char * p ;        

    p = (char *)_malloc (r, len + 1) ;

    if (p)
        {
        memcpy (p, str, len) ;

        p[len] = '\0' ;
        }

    return p ;
    }
    
