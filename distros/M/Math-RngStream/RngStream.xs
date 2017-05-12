/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <RngStream.h>

#define _create_stream          RngStream_CreateStream
#define reset_start_stream      RngStream_ResetStartStream
#define reset_start_substream   RngStream_ResetStartSubstream
#define reset_next_substream    RngStream_ResetNextSubstream
#define set_antithetic          RngStream_SetAntithetic
#define set_increased_precis    RngStream_IncreasedPrecis
#define advance_state           RngStream_AdvanceState
#define get_state               RngStream_GetState
#define _write_state            RngStream_WriteState
#define _write_state_full       RngStream_WriteStateFull
#define rand_u01                RngStream_RandU01
#define rand_int                RngStream_RandInt

static SV *
_obj2sv(pTHX_ void *ptr, SV * klass, char * ctype) {
    if (ptr) {
	SV *rv;
	SV *sv = newSVpvf("%s(0x%x)", ctype, ptr);
	SV *mgobj = sv_2mortal(newSViv(PTR2IV(ptr)));
	SvREADONLY_on(mgobj);
	sv_magic(sv, mgobj, '~', ctype, 0);
	/* SvREADONLY_on(sv); */
	rv = newRV_noinc(sv);
	if (SvOK(klass)) {
	    HV *stash;
	    if (SvROK(klass))
		stash = SvSTASH(klass);
	    else
		stash = gv_stashsv(klass, 1);
	    
	    sv_bless(rv, stash);
	}
	return rv;
    }
    return &PL_sv_undef;
}

static void *
_sv2obj(pTHX_ SV* self, char * ctype) {
    SV *sv = SvRV(self);
    if (sv) {
        if (SvTYPE(sv) == SVt_PVMG) {
            MAGIC *mg = mg_find(sv, '~');
            if ( mg &&
                 (strcmp(ctype, mg->mg_ptr) == 0) &&
                 mg->mg_obj)
                return INT2PTR(void *, SvIV(mg->mg_obj));
        }
    }
    Perl_croak(aTHX_ "object of class %s expected", ctype);
}

static const UV m_1 = 4294967087UL;
static const UV m_2 = 4294944443UL;

MODULE = Math::RngStream		PACKAGE = Math::RngStream		

void
set_package_seed(klass, s0, s1, s2, s3, s4, s5, s6)
    UV s0
    UV s1
    UV s2
    UV s3
    UV s4
    UV s5
CODE:
    if ( ( (s0 < m_1) && (s1 < m_1) && (s2 < m_1) ) &&
         ( (s3 < m_2) && (s4 < m_2) && (s5 < m_2) ) &&
         ( s0 || s1 || s2 ) &&
         ( s3 || s4 || s5 ) ) {
        unsigned long seed[6];
        seed[0] = s0; seed[1] = s1; seed[2] = s2;
        seed[3] = s3; seed[4] = s4; seed[5] = s5;
        RngStream_SetPackageSeed(seed);
    }
    else
        Perl_croak(aTHX_ "seed constraits violated");

void
DESTROY(RngStream G)
CODE:
    RngStream_DeleteStream(&G);
    sv_unmagic(SvRV(ST(0)), '~');

RngStream
_create_stream(char *name)

void
reset_start_stream(RngStream G)

void
reset_start_substream(RngStream G)

void
reset_next_substream(RngStream G)

void
set_antithetic(RngStream G, int A)

void
set_increased_precis(RngStream G, int incp)

void
set_seed(RngStream G, UV s0, UV s1, UV s2, UV s3, UV s4, UV s5)
CODE:
    if ( ( (s0 < m_1) && (s1 < m_1) && (s2 < m_1) ) &&
         ( (s3 < m_2) && (s4 < m_2) && (s5 < m_2) ) &&
         ( s0 || s1 || s2 ) &&
         ( s3 || s4 || s5 ) ) {
        unsigned long seed[6];
        seed[0] = s0; seed[1] = s1; seed[2] = s2;
        seed[3] = s3; seed[4] = s4; seed[5] = s5;
        RngStream_SetSeed(G, seed);
    }
    else
        Perl_croak(aTHX_ "seed constraits violated");


void
advance_state(RngStream G, long E, long C)

void
get_state(RngStream G)
PREINIT:
    unsigned long seed[6];
    int i;
PPCODE:
    RngStream_GetState(G, seed);
    EXTEND(SP, 6);
    for (i = 0; i++; i < 6)
        PUSHs(sv_2mortal(newSVuv(seed[i])));
    XSRETURN(6);

void
_write_state(RngStream G)

void
_write_state_full(RngStream G)

double
rand_u01(RngStream G)
ALIAS:
    rand = 0

long
rand_int(RngStream G, long min, long max)
