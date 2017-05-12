/*###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#   For use with Apache httpd and mod_perl, see also Apache copyright.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: epio.c 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/


#include "ep.h"
#include "epmacro.h"
#include "crypto/epcrypto.h"



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
//#define HANDLE_GV(name) gv_fetchpv(name, GV_ADD, SVt_PVIO)



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
    EPENTRY1N (oBegin, r -> Component.pOutput -> nMarker) ;
    
    r -> Component.pOutput -> nMarker++ ;
    
    return r -> Component.pOutput -> pLastBuf ;
    }

/* -------------------------------------------------------------------------------------
*
*  rollback output transaction (throw away all the output since corresponding begin)
*
-------------------------------------------------------------------------------------- */

void oRollbackOutput (/*i/o*/ register req * r,
			struct tBuf *   pBuf) 

    {
    EPENTRY1N (oRollback, r -> Component.pOutput -> nMarker) ;

    if (pBuf == NULL)
        {
        if (r -> Component.pOutput -> pLastFreeBuf)
            r -> Component.pOutput -> pLastFreeBuf -> pNext = r -> Component.pOutput -> pFirstBuf ;
        else 
            r -> Component.pOutput -> pFreeBuf = r -> Component.pOutput -> pFirstBuf ;
        
        r -> Component.pOutput -> pLastFreeBuf = r -> Component.pOutput -> pLastBuf ;
        
        r -> Component.pOutput -> pFirstBuf   = NULL ;
        r -> Component.pOutput -> nMarker     = 0 ;
        }
    else
	{
        if (r -> Component.pOutput -> pLastBuf == pBuf || pBuf -> pNext == NULL)
            r -> Component.pOutput -> nMarker-- ;
        else
            {
            r -> Component.pOutput -> nMarker = pBuf -> pNext -> nMarker - 1 ;
            if (r -> Component.pOutput -> pLastFreeBuf)
                r -> Component.pOutput -> pLastFreeBuf -> pNext = pBuf -> pNext ;
            else
                r -> Component.pOutput -> pFreeBuf = pBuf -> pNext ;
            r -> Component.pOutput -> pLastFreeBuf = r -> Component.pOutput -> pLastBuf ;
            }
        pBuf -> pNext = NULL ;
        }
        
    r -> Component.pOutput -> pLastBuf = pBuf ;

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
    
    /* RollbackError (r) ; */
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
    EPENTRY1N (oCommit, r -> Component.pOutput -> nMarker) ;

    
    if (pBuf == NULL)
        r -> Component.pOutput -> nMarker = 0 ;
    else
        if (r -> Component.pOutput -> pLastBuf == pBuf)
            r -> Component.pOutput -> nMarker-- ;
        else
            r -> Component.pOutput -> nMarker = pBuf -> pNext -> nMarker - 1 ;
    
    if (r -> Component.pOutput -> nMarker == 0)
        {
        if (pBuf == NULL)
            pBuf = r -> Component.pOutput -> pFirstBuf ;
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

    /* CommitError (r) ; */
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* commit output transaction (all the output since corresponding begin is vaild)*/
/*                                                                              */
/* ---------------------------------------------------------------------------- */

void oCommit (/*i/o*/ register req *  r,
		      struct tBuf *   pBuf) 

    {
    EPENTRY1N (oCommit, r -> Component.pOutput -> nMarker) ;

    oCommitToMem (r, pBuf, NULL) ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* write to a buffer                                                            */
/*                                                                              */
/* we will alloc a new buffer for every write                                   */
/* this is fast with ep_palloc                                                  */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int bufwrite (/*i/o*/ register req * r,
		     /*in*/ const void * ptr, size_t size) 


    {
    struct tBuf * pBuf ;

    EPENTRY1N (bufwrite, r -> Component.pOutput -> nMarker) ;

    pBuf = (struct tBuf *)ep_palloc (r -> Component.pOutput -> pPool, size + sizeof (struct tBuf)) ;

    if (pBuf == NULL)
        return 0 ;

    memcpy (pBuf + 1,  ptr, size) ;
    pBuf -> pNext   = NULL ;
    pBuf -> nSize   = size ;
    pBuf -> nMarker = r -> Component.pOutput -> nMarker ;

    if (r -> Component.pOutput -> pLastBuf)
        {
        r -> Component.pOutput -> pLastBuf -> pNext = pBuf ;
        pBuf -> nCount    = r -> Component.pOutput -> pLastBuf -> nCount + size ;
        }
    else
        pBuf -> nCount    = size ;
        
    if (r -> Component.pOutput -> pFirstBuf == NULL)
        r -> Component.pOutput -> pFirstBuf = pBuf ;
    r -> Component.pOutput -> pLastBuf = pBuf ;


    return size ;
    }

#if 0
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
    if ((r -> Component.Config.bDebug & dbgMem) == 0 && pAllocReq != NULL)
        {
        r -> Component.pOutput -> pFirstBuf    = NULL ;
        r -> Component.pOutput -> pLastBuf     = NULL ;
        r -> Component.pOutput -> pFreeBuf     = NULL ;
        r -> Component.pOutput -> pLastFreeBuf = NULL ;
        return ; /* no need for apache to free memory */
        }
#endif
        
    /* first walk thru the used buffers */

    pBuf = r -> Component.pOutput -> pFirstBuf ;
    while (pBuf)
        {
        pNext = pBuf -> pNext ;
        _free (r, pBuf) ;
        pBuf = pNext ;
        }

    r -> Component.pOutput -> pFirstBuf = NULL ;
    r -> Component.pOutput -> pLastBuf  = NULL ;


    /* now walk thru the unused buffers */
    
    pBuf = r -> Component.pOutput -> pFreeBuf ;
    while (pBuf)
        {
        pNext = pBuf -> pNext ;
        _free (r, pBuf) ;
        pBuf = pNext ;
        }

    r -> Component.pOutput -> pFreeBuf = NULL ;
    r -> Component.pOutput -> pLastFreeBuf  = NULL ;
    }
#endif

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* get the length outputed to buffers so far                                    */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

int GetContentLength (/*i/o*/ register req * r)
    {
    if (r -> Component.pOutput -> pLastBuf)
        return r -> Component.pOutput -> pLastBuf -> nCount ;
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
    epTHX ;

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
	    r -> Component.ifdobj = mg->mg_obj ;
	    if (r -> Component.Config.bDebug)
	        {
	        char *package = HvNAME(SvSTASH((SV*)SvRV(mg->mg_obj)));
	        lprintf (r -> pApp,  "[%d]Open TIED STDIN %s...\n", r -> pThread -> nPid, package) ;
	        }
	    return ok ;
	    }
        }

    if (r -> Component.ifd && r -> Component.ifd != PerlIO_stdinF)
        PerlIO_close (r -> Component.ifd) ;

    r -> Component.ifd = NULL ;

    if (sFilename == NULL || *sFilename == '\0')
        {
        /*
        GV * io = gv_fetchpv("STDIN", TRUE, SVt_PVIO) ;
        if (io == NULL || (r -> Component.ifd = IoIFP(io)) == NULL)
            {
            if (r -> Component.Config.bDebug)
                lprintf (r -> pApp,  "[%d]Cannot get Perl STDIN, open os stdin\n", r -> pThread -> nPid) ;
            r -> Component.ifd = PerlIO_stdinF ;
            }
        */
        
        r -> Component.ifd = PerlIO_stdinF ;

        return ok ;
        }

    if ((r -> Component.ifd = PerlIO_open (sFilename, "r")) == NULL)
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
    epTHX ;

#if 0
    if (0) /* r -> Component.ifdobj) */
	{	    
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(sp);
	XPUSHs(r -> Component.ifdobj);
	PUTBACK;
	perl_call_method ("CLOSE", G_VOID | G_EVAL) ; 
        SPAGAIN ;
	FREETMPS;
	LEAVE;
	r -> Component.ifdobj = NULL ;
	}
#endif

#ifdef APACHE
    if (r -> pApacheReq)
        return ok ;
#endif

    if (r -> Component.ifd && r -> Component.ifd != PerlIO_stdinF)
        PerlIO_close (r -> Component.ifd) ;

    r -> Component.ifd = NULL ;

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
    epTHX ;
    
    if (size == 0)
        return 0 ;

    if (r -> Component.ifdobj)
	{	    
	int num ;
	int n ;
	SV * pBufSV ;

	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(sp);
	XPUSHs(r -> Component.ifdobj);
	XPUSHs(sv_2mortal(pBufSV = NEWSV(0, 0)));
	XPUSHs(sv_2mortal(newSViv (size)));
	PUTBACK;
	num = perl_call_method ("READ", G_SCALAR) ; 
	SPAGAIN;
	n = 0 ;
	if (num > 0)
	    {
	    STRLEN  n = POPu ;
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
        ap_setup_client_block(r -> pApacheReq, REQUEST_CHUNKED_ERROR); 
        if(ap_should_client_block(r -> pApacheReq))
            {
            int c ;
            int n = 0 ;
            while (1)
                {
                c = ap_get_client_block(r -> pApacheReq, p, size); 
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

    return PerlIO_read (r -> Component.ifd, p, size) ;
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
        FILE * f = PerlIO_exportFILE (r -> Component.ifd, 0) ;
        char * p = fgets (s, size, f) ;
        PerlIO_releaseFILE (r -> Component.ifd, f) ;
        return p ;
        */
        return NULL ;
        }
#else
    return fgets (s, size, r -> Component.ifd) ;
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
    epTHX ;
    
    if (r -> Component.Config.bDebug)
        lprintf (r -> pApp,  "[%d]Reading %s as input using %s (%d Bytes)...\n", r -> pThread -> nPid, sInputfile, FILEIOTYPE, *nFileSize) ;

#ifdef WIN32
    if ((ifd = PerlIO_open (sInputfile, "rb")) == NULL)
#else
    if ((ifd = PerlIO_open (sInputfile, "r")) == NULL)
#endif        
        {
        strncpy (r -> errdat1, sInputfile, sizeof (r -> errdat1) - 1) ;
        strncpy (r -> errdat2, Strerror(errno), sizeof (r -> errdat2) - 1) ; 
        if (errno == EACCES)
            return rcForbidden ;
        else if (errno == ENOENT)
            return rcNotFound ;
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
        int fileno = PerlIO_fileno (ifd) ;
        FILE * ifile = fdopen(fileno, "r") ;
	if (!ifile)
            {  
            strncpy (r -> errdat1, sInputfile, sizeof (r -> errdat1) - 1) ;
            strncpy (r -> errdat2, Strerror(errno), sizeof (r -> errdat2) - 1) ; 
            return rcFileOpenErr ;
            }

#ifndef EP2
        syntax = (r -> Component.pTokenTable && strcmp ((char *)r -> Component.pTokenTable, "Text") == 0)?"Text":"Embperl" ;
#else
        syntax = r -> Component.Config.sSyntax ;
#endif

        if ((rc = do_crypt_file (ifile, NULL, pData, *nFileSize, 0, syntax, EPC_HEADER)) <= 0)
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
        fclose (ifile) ;
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
    epTHX ;
    
    r -> Component.pOutput -> pFirstBuf = NULL ; 
    r -> Component.pOutput -> pLastBuf  = NULL ; 
    r -> Component.pOutput -> nMarker   = 0 ;
    r -> Component.pOutput -> pMemBuf   = NULL ;
    r -> Component.pOutput -> nMemBufSize = 0 ;
    r -> Component.pOutput -> pFreeBuf     = NULL ;
    r -> Component.pOutput -> pLastFreeBuf = NULL ;


    
    if (r -> Component.pOutput -> ofd && r -> Component.pOutput -> ofd != PerlIO_stdoutF && !r -> Component.pOutput -> no_ofd_close)
        PerlIO_close (r -> Component.pOutput -> ofd) ;

    r -> Component.pOutput -> ofd = NULL ;
    r -> Component.pOutput -> no_ofd_close = 0 ;

    if (sFilename == NULL || *sFilename == '\0')
        {
#if defined (APACHE)
	if (r -> pApacheReq)
	    {
	    if (r -> Component.Config.bDebug)
		lprintf (r -> pApp,  "[%d]Using APACHE for output...\n", r -> pThread -> nPid) ;
	    return ok ;
	    }
#endif

        handle = HANDLE_GV("STDOUT") ;
        if (handle)
            {
            SV *iohandle = TIEHANDLE_SV(handle) ;

	    if (iohandle && SvMAGICAL(iohandle) && (mg = mg_find((SV*)iohandle, 'q')) && mg->mg_obj) 
	        {
	        r -> Component.pOutput -> ofdobj = mg->mg_obj ;
	        if (r -> Component.Config.bDebug)
		    {
		    char *package = HvNAME(SvSTASH((SV*)SvRV(mg->mg_obj)));
		    lprintf (r -> pApp,  "[%d]Open TIED STDOUT %s for output...\n", r -> pThread -> nPid, package) ;
		    }
	        return ok ;
	        }

            r -> Component.pOutput -> ofd = IoOFP(GvIOn(handle)) ;
            if (r -> Component.pOutput -> ofd)
                {
                r -> Component.pOutput -> no_ofd_close = 1 ;
                return ok ;
                }
            }
        
	r -> Component.pOutput -> ofd = PerlIO_stdoutF ;
        
        if (r -> Component.Config.bDebug)
            {
#ifdef APACHE
             if (r -> pApacheReq)
                lprintf (r -> pApp,  "[%d]Open STDOUT to Apache for output...\n", r -> pThread -> nPid) ;
             else
#endif
             lprintf (r -> pApp,  "[%d]Open STDOUT for output...\n", r -> pThread -> nPid) ;
            }
        return ok ;
        }

    if (r -> Component.Config.bDebug)
        lprintf (r -> pApp,  "[%d]Open %s for output...\n", r -> pThread -> nPid, sFilename) ;

#ifdef WIN32
    if ((r -> Component.pOutput -> ofd = PerlIO_open (sFilename, "wb")) == NULL)
#else
    if ((r -> Component.pOutput -> ofd = PerlIO_open (sFilename, "w")) == NULL)
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


int CloseOutput (/*in*/ tReq *             r,
                        tComponentOutput * pOutput)

    {
    epTHX ;
    
    if (!pOutput)
        return ok ;

#if 0
    if (0) /* r -> Component.pOutput -> ofdobj) */
	{	    
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(sp);
	XPUSHs(pOutput -> ofdobj);
	PUTBACK;
	perl_call_method ("CLOSE", G_VOID | G_EVAL) ; 
        SPAGAIN ;
	FREETMPS;
	LEAVE;
	pOutput -> ofdobj = NULL ;
	}
#endif

    if (pOutput -> ofd && pOutput -> ofd != PerlIO_stdoutF && !pOutput -> no_ofd_close)
        PerlIO_close (pOutput -> ofd) ;

    pOutput -> ofd = NULL ;

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
	pBuf = ep_palloc (r -> Component.pOutput -> pPool, nBufSize) ;

    *pBuf = '\0' ;
    r -> Component.pOutput -> pMemBuf	 = pBuf ;
    r -> Component.pOutput -> pMemBufPtr      = pBuf ;
    r -> Component.pOutput -> nMemBufSize     = nBufSize ;
    r -> Component.pOutput -> nMemBufSizeFree = nBufSize ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* set output to standard                                                       */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


char * OutputToStd (/*i/o*/ register req * r)

    {
    char * p = r -> Component.pOutput -> pMemBuf ;
    r -> Component.pOutput -> pMemBuf         = NULL ;
    r -> Component.pOutput -> nMemBufSize     = 0 ;
    r -> Component.pOutput -> nMemBufSizeFree = 0 ;
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
    epTHX ;

    if (n == 0 || r -> Component.pOutput -> bDisableOutput)
        return 0 ;

    if (r -> Component.pOutput -> pMemBuf)
        {
        char * p ;
        size_t s = r -> Component.pOutput -> nMemBufSize ;
        if (n >= r -> Component.pOutput -> nMemBufSizeFree)
            {
            size_t oldsize = s ;
            if (s < n)
                s = n + r -> Component.pOutput -> nMemBufSize ;
            
            r -> Component.pOutput -> nMemBufSize      += s ;
            r -> Component.pOutput -> nMemBufSizeFree  += s ;
            /*lprintf (r -> pApp,  "[%d]MEM:  Realloc pMemBuf, nMemSize = %d\n", nPid, nMemBufSize) ; */
            
            p = ep_palloc (r -> Component.pOutput -> pPool, r -> Component.pOutput -> nMemBufSize) ;
            if (p == NULL)
                {
                r -> Component.pOutput -> nMemBufSize      -= s ;
                r -> Component.pOutput -> nMemBufSizeFree  -= s ;
                return 0 ;
                }
            memcpy (p, r -> Component.pOutput -> pMemBuf, oldsize) ;
            r -> Component.pOutput -> pMemBufPtr = p + (r -> Component.pOutput -> pMemBufPtr - r -> Component.pOutput -> pMemBuf) ;
            r -> Component.pOutput -> pMemBuf = p ;
            }
                
        memcpy (r -> Component.pOutput -> pMemBufPtr, ptr, n) ;
        r -> Component.pOutput -> pMemBufPtr += n ;
        *(r -> Component.pOutput -> pMemBufPtr) = '\0' ;
        r -> Component.pOutput -> nMemBufSizeFree -= n ;
        return n ;
        }

    
    if (r -> Component.pOutput -> nMarker)
        return bufwrite (r, ptr, n) ;

    if (r -> Component.pOutput -> ofdobj)
	{	    
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(sp);
	XPUSHs(r -> Component.pOutput -> ofdobj);
	XPUSHs(sv_2mortal(newSVpv((char *)ptr,size)));
	PUTBACK;
	perl_call_method ("PRINT", G_SCALAR) ; 
        SPAGAIN ;
	FREETMPS;
	LEAVE;
	return size ;
	}

#if defined (APACHE)
    if (r -> pApacheReq && r -> Component.pOutput -> ofd == NULL)
        {
        if (n > 0)
            {
            n = ap_rwrite (ptr, n, r -> pApacheReq) ;
            if (r -> Component.Config.bDebug & dbgFlushOutput)
                ap_rflush (r -> pApacheReq) ;
            return n ;
            }
        else
            return 0 ;
        }
#endif
    if (n > 0 && r -> Component.pOutput -> ofd)
        {
        n = PerlIO_write (r -> Component.pOutput -> ofd, (void *)ptr, size) ;

        if (r -> Component.Config.bDebug & dbgFlushOutput)
            PerlIO_flush (r -> Component.pOutput -> ofd) ;
        }

    return n ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* flush output                                                                 */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

void oflush (/*i/o*/ register req * r)

    {
    epTHX_

#if defined (APACHE)
    if (r -> pApacheReq && r -> Component.pOutput -> ofd == NULL)
        {
        ap_rflush (r -> pApacheReq) ;
        return ;
        }
#endif
    if (r -> Component.pOutput -> ofd)
        {
        PerlIO_flush (r -> Component.pOutput -> ofd) ;
        }

    return ;
    }



/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* write one char to output (web client)                                        */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


void oputc (/*i/o*/ register req * r,
			/*in*/ char c)

    {
    epTHX ;
    
    if (r -> Component.pOutput -> nMarker || r -> Component.pOutput -> pMemBuf || r -> Component.pOutput -> ofdobj)
        {
        owrite (r, &c, 1) ;
        return ;
        }

#if defined (APACHE)
    if (r -> pApacheReq && r -> Component.pOutput -> ofd == NULL)
        {
        ap_rputc (c, r -> pApacheReq) ;
        if (r -> Component.Config.bDebug & dbgFlushOutput)
            ap_rflush (r -> pApacheReq) ;
        return ;
        }
#endif
    PerlIO_putc (r -> Component.pOutput -> ofd, c) ;

    if (r -> Component.Config.bDebug & dbgFlushOutput)
        PerlIO_flush (r -> Component.pOutput -> ofd) ;
    }



/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* log file open                                                                */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int OpenLog    (/*i/o*/ tApp *       a)

    {
    epaTHX ;
    
    if (a -> lfd)
        return ok ; /*already open */

    if (a -> lfd && a -> lfd != PerlIO_stdoutF)
        PerlIO_close (a -> lfd) ;  /* close old logfile */
   
    a -> lfd = NULL ;

    
    if (a -> Config.bDebug == 0)
	return ok ; /* never write to logfile if debugging is disabled */	    
    
    if (!a -> Config.sLog && a -> Config.sLog[0] == '\0')
        {
        a -> lfd = PerlIO_stdoutF ;
        return ok ;
        }

    if ((a -> lfd = PerlIO_open (a -> Config.sLog, "a")) == NULL)
        {
        tReq * r = a -> pThread -> pCurrReq ;        
        if (r)
            {
            strncpy (r -> errdat1, a -> Config.sLog, sizeof (r -> errdat1) - 1) ;
            strncpy (r -> errdat2, Strerror(errno), sizeof (r -> errdat2) - 1) ; 
            }
        return rcLogFileOpenErr ;
        }

    return ok ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* return the handle of the log file                                            */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int GetLogHandle (/*i/o*/ tApp *       a)

    {
    epaTHX  ;

    if (a -> lfd)
	return PerlIO_fileno (a -> lfd) ;

    return 0 ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* return the current posittion of the log file                                 */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


long GetLogFilePos (/*i/o*/ tApp *       a)

    {
    epaTHX  ;

    if (a -> lfd)
	return PerlIO_tell (a -> lfd) ;

    return 0 ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* close the log file                                                           */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int CloseLog (/*i/o*/ tApp *       a)

    {
    epaTHX  ;

    if (a -> lfd && a -> lfd != PerlIO_stdoutF)
        PerlIO_close (a -> lfd) ;

    a -> lfd = NULL ;

    return ok ;
    }



/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* flush the log file                                                           */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int FlushLog (/*i/o*/ tApp *       a)

    {
    epaTHX  ;

    if (a -> lfd != NULL)
        PerlIO_flush (a -> lfd) ;

    return ok ;
    }



/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* printf to log file                                                           */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

int lprintf (/*i/o*/ tApp *       a,
	     /*in*/ const char *  sFormat,
             /*in*/ ...) 

    {
    va_list  ap ;
    int      n ;
    epaTHX  ;

    if (a -> lfd == NULL)
        return 0 ;
    
    va_start (ap, sFormat) ;
    
        {
        n = PerlIO_vprintf (a -> lfd, sFormat, ap) ;
        if (a -> Config.bDebug & dbgFlushLog)
            PerlIO_flush (a -> lfd) ;
        }


    va_end (ap) ;

    return n ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* write block of data to log file                                              */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int lwrite (/*i/o*/ tApp *       a,
	    /*in*/  const void * ptr, 
            /*in*/  size_t size) 

    {
    int n ;
    epaTHX  ;

    if (a -> lfd == NULL)
        return 0 ;
    
    n = PerlIO_write (a -> lfd, (void *)ptr, size) ;

    if (a -> Config.bDebug & dbgFlushLog)
        PerlIO_flush (a -> lfd) ;

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
#ifdef APACHE
    if (pAllocReq && !(r -> Component.Config.bDebug & dbgMem))
        return ;
#endif


#ifdef ALLOCSIZE
    if (r -> Component.Config.bDebug & dbgMem)
        {
        size_t size ;
        size_t * ps ;

        /* we do it a bit complicted so it compiles also on aix */
        ps = (size_t *)p ;
        ps-- ;
        size = *ps ;
        p = ps ;
        r -> nAllocSize -= size ;
        lprintf (r -> pApp,  "[%d]MEM:  Free %d Bytes at %08x  Allocated so far %d Bytes\n" ,r -> pThread -> nPid, size, p, r -> nAllocSize) ;
        }
#endif

#ifdef APACHE
    if (r -> pApacheReq == NULL)
#endif
        {
        epTHX ;
        free (p) ;
        }
    }

void * _malloc (/*i/o*/ register req * r, 
                        size_t  size)

    {
    void * p ;

#ifdef APACHE
    pAllocReq = r -> pApacheReq  ;

    if (r -> pApacheReq)
        {
        p = apr_palloc (r -> pApacheReq -> pool, size + sizeof (size)) ;
        }
    else
#endif
        {
        epTHX ;
        
        p = malloc (size + sizeof (size)) ;
        }

#ifdef ALLOCSIZE
    if (r -> Component.Config.bDebug & dbgMem)
        {
        size_t * ps ;
        /* we do it a bit complicted so it compiles also on aix */
        ps = (size_t *)p ;
        *ps = size ;
        p = ps + 1 ;

        r -> nAllocSize += size ;
        lprintf (r -> pApp,  "[%d]MEM:  Alloc %d Bytes at %08x   Allocated so far %d Bytes\n" ,r -> pThread -> nPid, size, p, r -> nAllocSize) ;
        }
#endif

    return p ;
    }

void * _realloc (/*i/o*/ register req * r,  void * ptr, size_t oldsize, size_t  size)

    {
    void * p ;
    
#ifdef APACHE
    if (r -> pApacheReq)
        {
        p = apr_palloc (r -> pApacheReq -> pool, size + sizeof (size)) ;
        if (p == NULL)
            return NULL ;
        
#ifdef ALLOCSIZE
        if (r -> Component.Config.bDebug & dbgMem)
            {
            size_t * ps ;
            size_t sizeold ;
            /* we do it a bit complicted so it compiles also on aix */
            ps = (size_t *)p ;
            *ps = size ;
            p = ps + 1;
        
            ps = (size_t *)ptr ;
            ps-- ;
            sizeold = *ps ;
            r -> nAllocSize += size - sizeold ;

            lprintf (r -> pApp,  "[%d]MEM:  ReAlloc %d Bytes at %08x   Allocated so far %d Bytes\n" ,r -> pThread -> nPid, size, p, r -> nAllocSize) ;
            }
#endif

        memcpy (p, ptr, oldsize) ; 
        }
    else
#endif
#ifdef ALLOCSIZE
        if (r -> Component.Config.bDebug & dbgMem)
            {
            size_t * ps ;
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
            lprintf (r -> pApp,  "[%d]MEM:  ReAlloc %d Bytes at %08x   Allocated so far %d Bytes\n" ,r -> pThread -> nPid, size, p, r -> nAllocSize) ;
            }
        else
#endif
            {
            epTHX ;
            p = realloc (ptr, size + sizeof (size)) ;
            }

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
        lprintf (r -> pApp,  "sum = %d p = %s\n", sum, p) ;
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
        lprintf (r -> pApp,  "l = %d p = %s\n", l, p) ;
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
    
