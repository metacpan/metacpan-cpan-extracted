#define PERL_NO_GET_CONTEXT	/* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* perl force */

#include "aesth.h"

typedef struct private {
    SV *state_sv;
    SV *force_sv;
    SV *closure;
} *private;

declare_aesth(perl);

define_setup(perl) {
    private private;
    I32 count;
    SV *s;
    aglo_state tmp;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newRV(force_sv)));
    PUSHs(s = sv_2mortal(newRV(state_sv)));
    PUTBACK;

    tmp = C_CHECK(state_sv, "Graph::Layout::Aesthetic", "state_sv");
    if (tmp != state) croak("state is not the struct referred by state_sv");

    /* We don't check the class of force_sv. If the user wants to do evil
       things, let him */

    /* Temporarily increase refcounts on things we need later just in case
       the "setup" method destroys their last reference */
    sv_2mortal(SvREFCNT_inc(state_sv));
    sv_2mortal(SvREFCNT_inc(force_sv));
    count = call_method("setup", G_SCALAR);
    if (count != 1) croak("Forced scalar context call succeeded in returning %d values. This is impossible", (int) count);

    SPAGAIN;

    Newc(__LINE__, private, sizeof(struct private) + (2*state->dimensions-1) * sizeof(aglo_real), char, struct private);
    private->closure  = SvREFCNT_inc(POPs);
    private->state_sv = newRV(state_sv);
    /* private->state_sv is effectively a self-reference */
    sv_rvweaken(private->state_sv);
    private->force_sv = newRV(force_sv);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return private;
}

define_cleanup(perl) {
    I32 count;
    SV *f = PRIVATE->force_sv;
    SV *s = PRIVATE->state_sv;
    SV *c = PRIVATE->closure;

    dSP;

    Safefree(private);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 3);
    PUSHs(sv_2mortal(f));
    PUSHs(sv_2mortal(s));
    PUSHs(sv_2mortal(c));
    PUTBACK;

    count = call_method("cleanup", G_VOID);
    if (count) {
        if (count < 0) croak("Forced void context call of 'cleanup' succeeded in returning %d values. This is impossible", (int) count);
        SPAGAIN;
        SP -= count;
        PUTBACK;
    }

    FREETMPS;
    LEAVE;
    return;
}

define_aesth(perl) {
    I32 count;
    aglo_vertex j, v;
    aglo_unsigned i, d;
    AV *gav, *av;
    SV *gradient_sv;
    dSP;

    ENTER;
    SAVETMPS;

    gav = newAV();
    gradient_sv = sv_2mortal(newRV_noinc((SV *) gav));
    
    d = state->dimensions;
    v = state->graph->vertices;
    av_extend(gav, v-1);
    for (j=0; j<v; j++) {
        av = newAV();
        av_push(gav, newRV_noinc((SV *) av));
        
        av_extend(av, d-1);
        for (i=0; i<d; i++) av_push(av, newSVnv(*gradient++));
    }
    
    PUSHMARK(SP);
    EXTEND(SP, 4);
    PUSHs(PRIVATE->force_sv);
    PUSHs(PRIVATE->state_sv);
    PUSHs(gradient_sv);
    PUSHs(PRIVATE->closure);
    PUTBACK;

    count = call_method("gradient", G_VOID);
    if (count) {
        if (count < 0) croak("Forced void context call of 'gradient' succeeded in returning %d values. This is impossible", (int) count);
        SPAGAIN;
        SP -= count;
        PUTBACK;
    }

    if (!SvROK(gradient_sv))
        croak("Gradient is not a reference anymore");
    gav = (AV*) SvRV(gradient_sv);
    if (SvTYPE(gav) != SVt_PVAV)
        croak("Gradient is not an array reference anymore");

    if (av_len(gav)+1 != v)
        croak("Expected force->gradient to return a size %"UVuf
              " list, but got %"UVuf" values", (UV) v, (UV) (av_len(gav)+1));

    while (v) {
        SV **sp, *sv;

        sp = av_fetch(gav, --v, 0);
        if (!sp) croak("Gradient for vertex %"UVuf" is unset", (UV) v);
        sv = *sp;
        SvGETMAGIC(sv);
        if (!SvOK(sv)) 
            croak("Gradient for vertex %"UVuf" is undefined", (UV) v);
        if (!SvROK(sv))
            croak("Gradient for vertex %"UVuf" is not a reference", (UV) v);
        av = (AV*) SvRV(sv);
        if (SvTYPE(av) != SVt_PVAV)
            croak("Gradient for vertex %"UVuf" is not an array reference",
                  (UV) v);
        if (av_len(av)+1 != d)
            croak("Gradient for vertex %"UVuf" is a reference to an array of size %"UVuf", expected %"UVuf, (UV) v, (UV) (av_len(av)+1), (UV) d);
        gradient -= d;
        for (i=0; i<d; i++) {
            sp = av_fetch(av, i, 0);
            if (!sp) croak("Gradient for vertex %"UVuf", coordinate %"UVuf" is unset", (UV) v, (UV) i);
            sv = *sp;
            gradient[i] = (aglo_real) SvNV(sv);
        }
    }
    FREETMPS;
    LEAVE;
    return;
}

MODULE = Graph::Layout::Aesthetic::Force::Perl		PACKAGE = Graph::Layout::Aesthetic::Force::Perl
PROTOTYPES: ENABLE

SV *
new(const char *class)
  PREINIT:
    aglo_force force;
  CODE:
    New(__LINE__, force, 1, struct aglo_force);
    force->aesth_gradient = ae_perl;
    force->aesth_setup	  = ae_setup_perl;
    force->aesth_cleanup  = ae_cleanup_perl;
    force->private_data   = force->user_data = NULL;
    RETVAL = NEWSV(1, 0);
    sv_setref_pv(RETVAL, class, (void*) force);
  OUTPUT:
    RETVAL

void
setup(SV *force, SV *state)
  PPCODE:
    PERL_UNUSED_VAR(force);
    PERL_UNUSED_VAR(state);
    EXTEND(SP, 1);
    PUSHs(&PL_sv_undef);

void
cleanup(SV *force, SV *state, SV *closure)
  PPCODE:
    PERL_UNUSED_VAR(force);
    PERL_UNUSED_VAR(state);
    PERL_UNUSED_VAR(closure);
