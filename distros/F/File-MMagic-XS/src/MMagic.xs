#include "perl-mmagic-xs.h"

static int 
PerlFMM_mg_free(pTHX_ SV *const sv, MAGIC *const mg)
{
    fmmagic *m;
    fmmagic *md;
    PerlFMM *const state = (PerlFMM *) mg->mg_ptr;

    PERL_UNUSED_VAR(sv);
    for (m = state->magic; m; ) {
        md = m;
        m  = m->next;
        Safefree(md);
    }
    state->last = NULL;

    if (state->ext) {
        st_free_table(state->ext);
    }

    if (state->error != NULL) {
        SvREFCNT_dec(state->error);
        state->error = NULL;
    }
    Safefree(state);
    return 0;
}

static int
PerlFMM_mg_dup(pTHX_ MAGIC *const mg, CLONE_PARAMS *const param)
{
#ifdef USE_ITHREADS
    PerlFMM *const state = (PerlFMM*) mg->mg_ptr;
    PerlFMM *newstate;

    PERL_UNUSED_VAR(param);

    newstate = PerlFMM_clone(state);
    mg->mg_ptr = (char *) newstate;
#else
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
#endif
    return 0;
}

static MAGIC*
PerlFMM_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
    MAGIC* mg;

    assert(sv   != NULL);
    assert(vtbl != NULL);

    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if(mg->mg_virtual == vtbl){
            assert(mg->mg_type == PERL_MAGIC_ext);
            return mg;
        }
    }

    croak("File::MMagic::XS: Invalid File::MMagic::XS object was passed");
    return NULL; /* not reached */
}


static MGVTBL PerlFMM_vtbl = { /* for identity */
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    PerlFMM_mg_free, /* free */
    NULL, /* copy */
    PerlFMM_mg_dup, /* dup */
    NULL,  /* local */
};

#define PerlFMM__create PerlFMM_create

MODULE = File::MMagic::XS   PACKAGE = File::MMagic::XS   PREFIX = PerlFMM_

PROTOTYPES: ENABLE

PerlFMM *
PerlFMM__create(class_sv)
        SV *class_sv;

PerlFMM *
PerlFMM_clone(self)
        PerlFMM *self;
    PREINIT:
        SV *class_sv = ST(0);

SV *
PerlFMM_parse_magic_file(self, file)
        PerlFMM *self;
        char *file;

SV *
PerlFMM_fhmagic(self, svio)
        PerlFMM *self;
        SV *svio;

SV *
PerlFMM_fsmagic(self, filename)
        PerlFMM *self;
        char *filename;

SV *
PerlFMM_bufmagic(self, buf)
        PerlFMM *self;
        SV *buf;

SV *
PerlFMM_ascmagic(self, data)
        PerlFMM *self;
        char *data;

SV *
PerlFMM_get_mime(self, filename)
        PerlFMM *self;
        char *filename;

SV *
PerlFMM_add_magic(self, magic)
        PerlFMM *self;
        char *magic;

SV *
PerlFMM_add_file_ext(self, ext, mime)
        PerlFMM *self;
        char *ext;
        char *mime;

SV *
error(self)
        PerlFMM *self;
    CODE:
        if (! FMM_OK(self))
            croak("Object not initialized.");

        if (self->error == NULL) {
            RETVAL = newSV(0);
        } else {
            RETVAL = newSVsv(self->error);
        }
    OUTPUT:
        RETVAL


