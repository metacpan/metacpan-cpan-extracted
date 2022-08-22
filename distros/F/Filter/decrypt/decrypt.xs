/* 
 * Filename : decrypt.xs
 * 
 * Author   : Reini Urban
 * Date     : Di 16. Aug 7:59:10 CEST 2022
 * Version  : 1.64
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "../Call/ppport.h"

#ifdef FDEBUG
static int fdebug = 0;
#endif

/* constants specific to the encryption format */
#define CRYPT_MAGIC_1	0xff
#define CRYPT_MAGIC_2	0x00

#define HEADERSIZE	2
#define BLOCKSIZE	4


#define SET_LEN(sv,len) \
        do { SvPVX(sv)[len] = '\0'; SvCUR_set(sv, len); } while (0)


static unsigned XOR [BLOCKSIZE] = {'P', 'e', 'r', 'l' } ;


/* Internal defines */
#ifdef PERL_FILTER_EXISTS
#  define CORE_FILTER_COUNT \
    (PL_parser && PL_parser->rsfp_filters ? av_len(PL_parser->rsfp_filters) : 0)
#else
#  define CORE_FILTER_COUNT \
    (PL_rsfp_filters ? av_len(PL_rsfp_filters) : 0)
#endif

#define FILTER_COUNT(s)		IoPAGE(s)
#define FILTER_LINE_NO(s)	IoLINES(s)
#define FIRST_TIME(s)		IoLINES_LEFT(s)

#define ENCRYPT_GV(s)		IoTOP_GV(s)
#define ENCRYPT_SV(s)		((SV*) ENCRYPT_GV(s))
#define ENCRYPT_BUFFER(s)	SvPVX(ENCRYPT_SV(s))
#define CLEAR_ENCRYPT_SV(s)	SvCUR_set(ENCRYPT_SV(s), 0)

#define DECRYPT_SV(s)		s
#define DECRYPT_BUFFER(s)	SvPVX(DECRYPT_SV(s))
#define CLEAR_DECRYPT_SV(s)	SvCUR_set(DECRYPT_SV(s), 0)
#define DECRYPT_BUFFER_LEN(s)	SvCUR(DECRYPT_SV(s))
#define DECRYPT_OFFSET(s) 	IoPAGE_LEN(s)
#define SET_DECRYPT_BUFFER_LEN(s,n)	SvCUR_set(DECRYPT_SV(s), n)

static unsigned
Decrypt(SV *in_sv, SV *out_sv)
{
	/* Here is where the actual decryption takes place */

    	unsigned char * in_buffer  = (unsigned char *) SvPVX(in_sv) ;
    	unsigned char * out_buffer ;
    	unsigned size = SvCUR(in_sv) ;
    	unsigned index = size ;
    	int i ;

	/* make certain that the output buffer is big enough 		*/
	/* as the output from the decryption can never be larger than	*/
	/* the input buffer, make it that size				*/
	SvGROW(out_sv, size) ;
	out_buffer = (unsigned char *) SvPVX(out_sv) ;

        /* XOR */
        for (i = 0 ; i < size ; ++i) 
            out_buffer[i] = (unsigned char)( XOR[i] ^ in_buffer[i] ) ;

	/* input has been consumed, so set length to 0 */
	SET_LEN(in_sv, 0) ;

	/* set decrypt buffer length */
	SET_LEN(out_sv, index) ;

	/* return the size of the decrypt buffer */
 	return (index) ;
}

static int
ReadBlock(int idx, SV *sv, unsigned size)
{   /* read *exactly* size bytes from the next filter */
    int i = size;
    while (1) {
        int n = FILTER_READ(idx, sv, i) ;
        if (n <= 0 && i==size)  /* eof/error when nothing read so far */
            return n ;
        if (n <= 0)             /* eof/error when something already read */
            return size - i;
        if (n == i)
            return size ;
        i -= n ;
    }
}

static void
preDecrypt(int idx)
{
    /*	If the encrypted data starts with a header or needs to do some
	initialisation it can be done here 

	In this case the encrypted data has to start with a fingerprint,
	so that is checked.
    */

    SV * sv = FILTER_DATA(idx) ;
    unsigned char * buffer ;


    /* read the header */
    if (ReadBlock(idx+1, sv, HEADERSIZE) != HEADERSIZE)
	croak("truncated file") ;

    buffer = (unsigned char *) SvPVX(sv) ;

    /* check for fingerprint of encrypted data */
    if (buffer[0] != CRYPT_MAGIC_1 || buffer[1] != CRYPT_MAGIC_2) 
            croak( "bad encryption format" );
}

static void
postDecrypt()
{
}

static I32
filter_decrypt(pTHX_ int idx, SV *buf_sv, int maxlen)
{
    SV   *my_sv = FILTER_DATA(idx);
    char *nl = "\n";
    char *p;
    char *out_ptr;
    int n;

    /* check if this is the first time through */
    if (FIRST_TIME(my_sv)) {

	/* Mild paranoia mode - make sure that no extra filters have 	*/
	/* been applied on the same line as the use Filter::decrypt	*/
        if (CORE_FILTER_COUNT > FILTER_COUNT(my_sv) )
	    croak("too many filters") ; 

	/* As this is the first time through, so deal with any 		*/
	/* initialisation required 					*/
        preDecrypt(idx) ;

	FIRST_TIME(my_sv) = FALSE ;
        SET_LEN(DECRYPT_SV(my_sv), 0) ;
        SET_LEN(ENCRYPT_SV(my_sv), 0) ;
        DECRYPT_OFFSET(my_sv)    = 0 ;
    }

#ifdef FDEBUG
    if (fdebug)
	warn("**** In filter_decrypt - maxlen = %d, len buf = %d idx = %d\n", 
		maxlen, SvCUR(buf_sv), idx ) ;
#endif

    while (1) {

	/* anything left from last time */
	if ((n = SvCUR(DECRYPT_SV(my_sv)))) {

	    out_ptr = SvPVX(DECRYPT_SV(my_sv)) + DECRYPT_OFFSET(my_sv) ;

	    if (maxlen) { 
		/* want a block */ 
#ifdef FDEBUG
		if (fdebug)
		    warn("BLOCK(%d): size = %d, maxlen = %d\n", 
			idx, n, maxlen) ;
#endif

	        sv_catpvn(buf_sv, out_ptr, maxlen > n ? n : maxlen );
		if(n <= maxlen) {
        	    DECRYPT_OFFSET(my_sv) = 0 ;
	            SET_LEN(DECRYPT_SV(my_sv), 0) ;
		}
		else {
        	    DECRYPT_OFFSET(my_sv) += maxlen ;
	            SvCUR_set(DECRYPT_SV(my_sv), n - maxlen) ;
		}
	        return SvCUR(buf_sv);
	    }
	    else {
		/* want lines */
                if ((p = ninstr(out_ptr, out_ptr + n, nl, nl + 1))) {

	            sv_catpvn(buf_sv, out_ptr, p - out_ptr + 1);

	            n = n - (p - out_ptr + 1);
		    DECRYPT_OFFSET(my_sv) += (p - out_ptr + 1) ;
	            SvCUR_set(DECRYPT_SV(my_sv), n) ;
#ifdef FDEBUG 
	            if (fdebug)
		        warn("recycle %d - leaving %d, returning %d [%.999s]", 
				idx, n, SvCUR(buf_sv), SvPVX(buf_sv)) ;
#endif

	            return SvCUR(buf_sv);
	        }
	        else /* no EOL, so append the complete buffer */
	            sv_catpvn(buf_sv, out_ptr, n) ;
	    }
	    
	}


	SET_LEN(DECRYPT_SV(my_sv), 0) ;
        DECRYPT_OFFSET(my_sv) = 0 ;

	/* read from the file into the encrypt buffer */
 	if ( (n = ReadBlock(idx+1, ENCRYPT_SV(my_sv), BLOCKSIZE)) <= 0)
	{
	    /* Either EOF or an error */

#ifdef FDEBUG
	    if (fdebug)
	        warn ("filter_read %d returned %d , returning %d\n", idx, n,
	            (SvCUR(buf_sv)>0) ? SvCUR(buf_sv) : n);
#endif

	    /* If the decrypt code needs to tidy up on EOF/error, 
		now is the time  - here is a hook */
	    postDecrypt() ; 

	    filter_del(filter_decrypt);  

 
            /* If error, return the code */
            if (n < 0)
                return n ;

	    /* return what we have so far else signal eof */
	    return (SvCUR(buf_sv)>0) ? SvCUR(buf_sv) : n;
	}

#ifdef FDEBUG
	if (fdebug)
	    warn("  filter_decrypt(%d): sub-filter returned %d: '%.999s'",
		idx, n, SvPV(my_sv,PL_na));
#endif

	/* Now decrypt a block */
	n = Decrypt(ENCRYPT_SV(my_sv), DECRYPT_SV(my_sv)) ;

#ifdef FDEBUG 
	if (fdebug) 
	    warn("Decrypt (%d) returned %d [%.999s]\n", idx, n, SvPVX(DECRYPT_SV(my_sv)) ) ;
#endif 

    }
}


MODULE = Filter::decrypt	PACKAGE = Filter::decrypt

PROTOTYPES:	DISABLE

BOOT:
    /* Check for the presence of the Perl Compiler. B::C[C], B::Deparse. Bytecode works fine */
    if (get_hv("B::C::",0) || get_av("B::NULL::ISA",0)) {
        croak("Aborting, Compiler detected") ;
    }
#ifndef BYPASS
    /* Don't run if this module is dynamically linked */
    if (!isALPHA(SvPV(GvSV(CvFILEGV(cv)), PL_na)[0]))
	croak("module is dynamically linked. Recompile as a static module") ;
#ifdef DEBUGGING
	/* Don't run if compiled with DEBUGGING */
	croak("recompile without -DDEBUGGING") ;
#endif
        
	/* Double check that DEBUGGING hasn't been enabled */
	if (PL_debug)
	    croak("debugging flags detected") ;
#endif


void
import(module)
    SV *	module
    PPCODE:
    {

        SV * sv = newSV(BLOCKSIZE) ;

	/* make sure the Perl debugger isn't enabled */
	if( PL_perldb )
	    croak("debugger disabled") ;

        filter_add(filter_decrypt, sv) ;
	FIRST_TIME(sv) = TRUE ;

        ENCRYPT_GV(sv) = (GV*) newSV(BLOCKSIZE) ;
        (void)SvPOK_only(DECRYPT_SV(sv));
        (void)SvPOK_only(ENCRYPT_SV(sv));
        SET_LEN(DECRYPT_SV(sv), 0) ;
        SET_LEN(ENCRYPT_SV(sv), 0) ;


        /* remember how many filters are enabled */
        FILTER_COUNT(sv) = CORE_FILTER_COUNT ;
	/* and the line number */
	FILTER_LINE_NO(sv) = PL_curcop->cop_line ;

    }

void
unimport(...)
    PPCODE:
    /* filter_del(filter_decrypt); */
