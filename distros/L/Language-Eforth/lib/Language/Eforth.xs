#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "embed.h"

typedef embed_t* Language__Eforth;

/* TODO instead target some perl something? or just Capture::Tiny */
static int put_char(int ch, void *file)
{
    int ret = fputc(ch, file);
    fflush(file);
    return ret;
}

MODULE = Language::Eforth        PACKAGE = Language::Eforth        
PROTOTYPES: ENABLE

void
DESTROY(Language::Eforth self)
    CODE:
        free(self->m);
        Safefree(self);

UV
depth(Language::Eforth self)
    CODE:
        RETVAL = embed_depth(self);
    OUTPUT:
        RETVAL

# utility bloat
void
drain(Language::Eforth self)
    PREINIT:
        cell_t value;
        size_t depth, ss;
    PPCODE:
        depth = embed_depth(self);
        if (depth) {
            EXTEND(SP, ss = depth);
            while (depth) {
                embed_pop(self, &value);
                mPUSHu(value);
                depth--;
            }
            XSRETURN(ss);
        } else {
            XSRETURN(0);
        }

# NOTE the expression MUST end with a newline
void
eval(Language::Eforth self, SV *expr)
    CODE:
        if (!(SvOK(expr) && SvCUR(expr)))
            croak("invalid empty expression");
        embed_eval(self, (char *)SvPV_nolen(expr));

Language::Eforth
new( const char *class )
    PREINIT:
        embed_t *self;
        embed_opt_t opts;
    CODE:
        Newxz(self, 1, embed_t);
        if (!self) croak("could not allocate forth");
        self->m = calloc(EMBED_CORE_SIZE * sizeof(cell_t), 1);
        if (!(self->m)) croak("could not allocate memory");
        embed_default(self);
        opts         = embed_opt_default();
        opts.out     = stdout;
        opts.put     = put_char;
        opts.options = 0;
        self->o      = opts;
        /* KLUGE prime the engine so push works from the get-go */
        embed_eval(self, "\n");
        RETVAL = self;
    OUTPUT:
        RETVAL

void
pop(Language::Eforth self)
    PREINIT:
        cell_t value;
        int status;
        U8 gimme;
    PPCODE:
        status = embed_pop(self, &value);
        gimme = GIMME_V;
        if (gimme == G_VOID) {
            XSRETURN(0);
        } else if (gimme == G_SCALAR) {
            EXTEND(SP, 1);
            mPUSHu(value);
            XSRETURN(1);
        } else {
            EXTEND(SP, 2);
            mPUSHu(value);
            mPUSHi(status);
            XSRETURN(2);
        }

void
push(Language::Eforth self, ...)
    PREINIT:
        int i, status;
        SV *value;
    PPCODE:
        if (items < 2) croak("nothing to push");
        for (i = 1; i < items; i++) {
            value = ST(i);
            if (!SvOK(value)) croak("value must be defined");
            status = embed_push(self, SvUV(value));
            if (status) break;
        }
        EXTEND(SP, 2);
        mPUSHi(i - 1);
        mPUSHi(status);
        XSRETURN(2);

void
reset(Language::Eforth self)
    CODE:
        embed_reset(self);
