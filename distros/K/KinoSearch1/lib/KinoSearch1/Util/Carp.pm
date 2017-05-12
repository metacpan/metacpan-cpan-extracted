package KinoSearch1::Util::Carp;

1;

__END__

__H__

#ifndef H_KINOSEARCH_UTIL_CARP
#define H_KINOSEARCH_UTIL_CARP 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1UtilMemManager.h"

void Kino1_confess (char*, ...);

#endif /* include guard */

__C__

#include "KinoSearch1UtilCarp.h"

void Kino1_confess (char* pat, ...) {
    va_list args;
    SV      *error_sv;

    dSP;

    error_sv = newSV(0);
    
    va_start(args, pat);
    sv_vsetpvf(error_sv, pat, &args);
    va_end(args);

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs( sv_2mortal(error_sv) );
    PUTBACK;
    call_pv("Carp::confess", G_DISCARD);
    FREETMPS;
    LEAVE;
}



__END__

==begin devdocs

==head1 NAME

KinoSearch1::Util::Carp - stack traces from C

==head1 DESCRIPTION

This module makes it possible to invoke Carp::confess() from C.  Modules that
use it will need to "use Carp;" -- which is usually taken care of by "use
KinoSearch1::Util::ToolSet;".

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut
