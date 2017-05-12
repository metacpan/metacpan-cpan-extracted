
#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"

MODULE=List::Slice       PACKAGE=List::Slice

void
head(size,...)
PROTOTYPE: $@
ALIAS:
    head = 0
    tail = 1
PPCODE:
{
    int size = 0;
    int start = 0;
    int end = 0;
    int i = 0;

    size = SvIV( ST(0) );

    if ( ix == 0 ) {
        start = 1;
        end = start + size;
        if ( size < 0 ) {
            end += items - 1;
        }
        if ( end > items ) {
            end = items;
        }
    }
    else {
        end = items;
        if ( size < 0 ) {
            start = -size + 1;
        }
        else {
            start = end - size;
        }
        if ( start < 1 ) {
            start = 1;
        }
    }

    if ( end < start ) {
        XSRETURN(0);
    }
    else {
        EXTEND( SP, end - start );
        for ( i = start; i <= end; i++ ) {
            PUSHs( sv_2mortal( newSVsv( ST(i) ) ) );
        }
        XSRETURN( end - start );
    }
}
