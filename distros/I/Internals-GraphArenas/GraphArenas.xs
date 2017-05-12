#include "string.h"
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

typedef void (*SVFUNC2_t) (pTHX_ SV*, SV*);

static void
safe_write( const void *buf, size_t numbytes )
{
    if ( ! PerlIO_write( PerlIO_stdout(), buf, numbytes ) ) {
        croak( "Can't write to stdout: %s", strerror( errno ) );
    }
}

static void
do_graph_arenas(SV *sva, SV *sv)
{
    safe_write( &sva,         sizeof(SV*) );
    safe_write( &sv,          sizeof(SV*) );
    safe_write( &(SvANY(sv)), sizeof(SV*) );
}

static void
my_visit( SVFUNC2_t f, U32 flags, U32 mask)
{
    SV* sva;
    SV* sv;
    register SV* svend;

    for (sva = PL_sv_arenaroot; sva; sva = (SV*)SvANY(sva)) {
        svend = &sva[SvREFCNT(sva)];
        for (sv = sva + 1; sv < svend; ++sv) {
            if (SvTYPE(sv) != SVTYPEMASK
                && (sv->sv_flags & mask) == flags
                && SvREFCNT(sv))
            {
                (*f)( sva, sv );
            }
        }
    }
}

MODULE = Internals::GraphArenas PACKAGE = Internals

PROTOTYPES: DISABLE

void
graph_arenas()
    CODE:
        my_visit(do_graph_arenas, 0, 0);
