/* 
 * Filename : tee.xs
 * 
 * Author   : Paul Marquess 
 * Date     : 26th March 2000
 * Version  : 1.01
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "../Call/ppport.h"

static I32
filter_tee(pTHX_ int idx, SV *buf_sv, int maxlen)
{
    I32 len;
#if PERL_VERSION > 8 || (PERL_VERSION == 8 && PERL_SUBVERSION > 8)
    PerlIO * fil = (PerlIO*) IoOFP(FILTER_DATA(idx));
#else
    PerlIO * fil = (PerlIO*) SvIV(FILTER_DATA(idx));
#endif
    int old_len = SvCUR(buf_sv) ;
 
    if ( (len = FILTER_READ(idx+1, buf_sv, maxlen)) <=0 ) {
        /* error or eof */
	PerlIO_close(fil) ;
        filter_del(filter_tee);      /* remove me from filter stack */
        return len;
    }

    /* write to the tee'd file */
    PerlIO_write(fil, SvPVX(buf_sv) + old_len, len - old_len) ;

    return SvCUR(buf_sv);
}

MODULE = Filter::tee	PACKAGE = Filter::tee

PROTOTYPES:	DISABLE

void
import(module, filename)
    SV *	module = NO_INIT
    char *	filename
    CODE:
#if PERL_VERSION > 8 || (PERL_VERSION == 8 && PERL_SUBVERSION > 8)
	SV   * stream = newSV_type(SVt_PVIO);
#else
        SV   * stream = newSViv(0);
#endif
	PerlIO * fil ;
	char * mode = "wb" ;

	filter_add(filter_tee, stream);
	/* check for append */
	if (*filename == '>') {
	    ++ filename ;
	    if (*filename == '>') {
	        ++ filename ;
		mode = "ab" ;
	    }
	}
	if ((fil = PerlIO_open(filename, mode)) == NULL) 
	    croak("Filter::tee - cannot open file '%s': %s", 
			filename, Strerror(errno)) ;

	/* save the tee'd file handle. */
#if PERL_VERSION > 8 || (PERL_VERSION == 8 && PERL_SUBVERSION > 8)
        IoOFP(stream) = (PerlIO*) fil;
#else
	SvIV_set(stream, (PerlIO*) fil);
#endif

