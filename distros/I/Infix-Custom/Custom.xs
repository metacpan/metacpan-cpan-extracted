#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* Custom infix operators hang off core's PL_infix_plugin, added in 5.38.
 * Detect it and compile the whole machinery only there; on older perls this
 * translation unit is just the bootstrap plus a warning import(). */
#ifdef PERL_VERSION_GE
#  if PERL_VERSION_GE(5,38,0)
#    define IC_HAVE_INFIX 1
#  endif
#elif (PERL_REVISION == 5 && PERL_VERSION >= 38) || PERL_REVISION > 5
#  define IC_HAVE_INFIX 1
#endif

#ifdef IC_HAVE_INFIX

typedef OP   *(*ic_build_fn)(pTHX_ SV **, OP *, OP *, struct Perl_custom_infix *);
typedef void  (*ic_parse_fn)(pTHX_ SV **, struct Perl_custom_infix *);

/* One registry entry per declared operator.
 *
 * `cdef` MUST be the first member: core hands our build_op callback a pointer
 * to it, and we recover the whole entry by casting that pointer back (the same
 * container-of trick XS::Parse::Infix uses). */
typedef struct ic_entry {
    struct Perl_custom_infix  cdef;        /* prec / parse / build_op           */
    char                     *glyph;       /* operator bytes (UTF-8), owned     */
    STRLEN                    glyph_len;
    char                     *hintkey;     /* "Infix::Custom/" + hex(glyph)      */
    STRLEN                    hintkey_len;
    IV                        id;          /* hint value that activates us       */
    CV                       *cv;          /* call mode: the sub to invoke       */
    OPCODE                    optype;      /* op mode: native binop to build     */
    struct ic_entry          *next;
} ic_entry;

static ic_entry           *ic_registry = NULL;   /* newest first */
static IV                   ic_next_id  = 1;
static Perl_infix_plugin_t  ic_next_infix_plugin;

/* ---- precedence vocabulary ------------------------------------------------
 * Friendly name -> the value of core's enum Perl_custom_infix_precedence
 * (perl.h). Associativity is a fixed property of each tier, so choosing a
 * precedence is also choosing associativity. Returns -1 for an unknown name. */
static IV
ic_prec_value(const char *name)
{
    if (strEQ(name, "low"))             return INFIX_PREC_LOW;
    if (strEQ(name, "logical_or_low"))  return INFIX_PREC_LOGICAL_OR_LOW;
    if (strEQ(name, "logical_and_low")) return INFIX_PREC_LOGICAL_AND_LOW;
    if (strEQ(name, "assign"))          return INFIX_PREC_ASSIGN;
    if (strEQ(name, "logical_or"))      return INFIX_PREC_LOGICAL_OR;
    if (strEQ(name, "logical_and"))     return INFIX_PREC_LOGICAL_AND;
    if (strEQ(name, "rel"))             return INFIX_PREC_REL;
    if (strEQ(name, "add"))             return INFIX_PREC_ADD;
    if (strEQ(name, "mul"))             return INFIX_PREC_MUL;
    if (strEQ(name, "pow"))             return INFIX_PREC_POW;
    if (strEQ(name, "high"))            return INFIX_PREC_HIGH;
    return -1;
}

/* Map a perl operator symbol to its OP code (version-correct, unlike hardcoding
 * numbers on the Perl side). Returns OP_NULL for an unknown symbol. */
static OPCODE
ic_opcode(const char *sym)
{
    if (strEQ(sym, "+"))  return OP_ADD;
    if (strEQ(sym, "-"))  return OP_SUBTRACT;
    if (strEQ(sym, "*"))  return OP_MULTIPLY;
    if (strEQ(sym, "/"))  return OP_DIVIDE;
    if (strEQ(sym, "%"))  return OP_MODULO;
    if (strEQ(sym, "**")) return OP_POW;
    if (strEQ(sym, "."))  return OP_CONCAT;
    if (strEQ(sym, "x"))  return OP_REPEAT;
    if (strEQ(sym, "|"))  return OP_BIT_OR;
    if (strEQ(sym, "&"))  return OP_BIT_AND;
    if (strEQ(sym, "^"))  return OP_BIT_XOR;
    if (strEQ(sym, "<<")) return OP_LEFT_SHIFT;
    if (strEQ(sym, ">>")) return OP_RIGHT_SHIFT;
    return OP_NULL;
}

/* Canonical hint key: "Infix::Custom/" + lowercase hex of the glyph's UTF-8
 * bytes. Hex keeps the key pure-ASCII, so setting %^H here and reading it in
 * the dispatcher never disagree over the UTF-8 flag on a wide operator. Caller
 * frees the returned buffer with Safefree(). */
static char *
ic_hintkey(pTHX_ const char *glyph, STRLEN glyph_len, STRLEN *out_len)
{
    static const char hexd[] = "0123456789abcdef";
    STRLEN plen = sizeof("Infix::Custom/") - 1;
    STRLEN klen = plen + glyph_len * 2;
    char *k, *p;
    STRLEN i;

    Newx(k, klen + 1, char);
    Copy("Infix::Custom/", k, plen, char);
    p = k + plen;
    for (i = 0; i < glyph_len; i++) {
        unsigned char b = (unsigned char)glyph[i];
        *p++ = hexd[b >> 4];
        *p++ = hexd[b & 0xf];
    }
    *p = '\0';
    *out_len = klen;
    return k;
}

/* Is entry `e` lexically active at the current point of compilation? Read the
 * compile-time hints hash (%^H) and compare the stored id. A per-glyph key with
 * the id as value lets nested scopes rebind the same glyph: the innermost
 * scope's id is the one visible here. */
static int
ic_active(pTHX_ ic_entry *e)
{
    HV *hints = GvHV(PL_hintgv);
    SV **hent;
    if (!hints)
        return 0;
    hent = hv_fetch(hints, e->hintkey, (I32)e->hintkey_len, 0);
    return hent && *hent && SvIOK(*hent) && SvIV(*hent) == e->id;
}

/* Call mode: `lhs OP rhs` -> cv(lhs, rhs), an entersub over
 * (pushmark, lhs, rhs, <const \&cv>). */
static OP *
ic_build_call(pTHX_ SV **opdata, OP *lhs, OP *rhs, struct Perl_custom_infix *def)
{
    ic_entry *e = (ic_entry *)def;
    OP *cvop, *list;
    PERL_UNUSED_ARG(opdata);

    cvop = newSVOP(OP_CONST, 0, newRV_inc((SV *)e->cv));
    list = op_append_elem(OP_LIST,
               op_append_elem(OP_LIST, lhs, rhs),
               cvop);
    return newUNOP(OP_ENTERSUB, OPf_STACKED, list);
}

/* Op mode: `lhs OP rhs` -> a native binary op (no sub-call overhead). */
static OP *
ic_build_binop(pTHX_ SV **opdata, OP *lhs, OP *rhs, struct Perl_custom_infix *def)
{
    ic_entry *e = (ic_entry *)def;
    PERL_UNUSED_ARG(opdata);
    return newBINOP(e->optype, 0, lhs, rhs);
}

/* Method mode parse stage: consume the bareword identifier that follows the
 * operator (the method name) before the parser tries to read it as a normal
 * term -- which would trip `strict subs`. Store it in *opdata for build. */
static void
ic_parse_ident(pTHX_ SV **opdata, struct Perl_custom_infix *def)
{
    SV *name = newSVpvs("");
    I32 c;
    PERL_UNUSED_ARG(def);

    lex_read_space(0);
    while ((c = lex_peek_unichar(0)) != -1 && isWORDCHAR(c)) {
        sv_catpvf(name, "%c", (int)c);
        lex_read_unichar(0);
    }
    *opdata = name;

    /* The infix-plugin API is strictly binary: after we return, the parser
     * still parses an rhs operand. We have already consumed the method name,
     * so inject a dummy `undef` for it to read; ic_build_method discards it. */
    lex_stuff_pvs(" undef ", 0);
}

/* Method mode build: `lhs OP name` -> cv(lhs, "name"), reusing call mode but
 * with the captured bareword as a constant string instead of a parsed rhs. */
static OP *
ic_build_method(pTHX_ SV **opdata, OP *lhs, OP *rhs, struct Perl_custom_infix *def)
{
    ic_entry *e = (ic_entry *)def;
    SV *name = (opdata && *opdata) ? *opdata : NULL;
    OP *cvop, *nameop, *list;

    if (rhs)                       /* method mode does not use a parsed rhs */
        op_free(rhs);
    nameop = newSVOP(OP_CONST, 0, name ? newSVsv(name) : newSVpvs(""));
    cvop   = newSVOP(OP_CONST, 0, newRV_inc((SV *)e->cv));
    list = op_append_elem(OP_LIST,
               op_append_elem(OP_LIST, lhs, nameop),
               cvop);
    return newUNOP(OP_ENTERSUB, OPf_STACKED, list);
}

/* The dispatcher core calls for every candidate infix operator. Among the
 * operators that match the input AND are lexically in scope, the longest glyph
 * wins (so `|>` beats a registered `|`). Anything we don't claim chains to the
 * plugin installed before us. */
static STRLEN
ic_infix_plugin(pTHX_ char *opname, STRLEN oplen,
                struct Perl_custom_infix **def)
{
    ic_entry *e, *best = NULL;

    for (e = ic_registry; e; e = e->next) {
        if (e->glyph_len <= oplen
            && memEQ(opname, e->glyph, e->glyph_len)
            && ic_active(aTHX_ e)
            && (!best || e->glyph_len > best->glyph_len))
            best = e;
    }

    if (best) {
        *def = &best->cdef;
        return best->glyph_len;
    }
    return ic_next_infix_plugin(aTHX_ opname, oplen, def);
}

/* Add an operator to the global registry; returns its activation id. */
static IV
ic_register(pTHX_ SV *glyph_sv, IV prec, CV *cv, OPCODE optype,
            ic_build_fn build_op, ic_parse_fn parse)
{
    STRLEN len;
    char *g = SvPVutf8(glyph_sv, len);
    ic_entry *e;

    Newxz(e, 1, ic_entry);
    e->glyph         = savepvn(g, len);
    e->glyph_len     = len;
    e->id            = ic_next_id++;
    e->cv            = cv ? (CV *)SvREFCNT_inc((SV *)cv) : NULL;
    e->optype        = optype;
    e->cdef.prec     = (enum Perl_custom_infix_precedence)prec;
    e->cdef.parse    = parse;
    e->cdef.build_op = build_op;
    e->hintkey       = ic_hintkey(aTHX_ e->glyph, e->glyph_len, &e->hintkey_len);
    e->next          = ic_registry;
    ic_registry      = e;
    return e->id;
}

/* Activate operator `id` for the glyph in the current lexical scope: set
 * %^H{ hintkey } = id and flag the hints hash for per-scope save/restore (this
 * is what `$^H{...} = ...` does under the hood). */
static void
ic_set_hint(pTHX_ SV *glyph_sv, IV id)
{
    STRLEN len, klen;
    char *g = SvPVutf8(glyph_sv, len);
    char *key = ic_hintkey(aTHX_ g, len, &klen);
    HV *hints = GvHV(PL_hintgv);

    if (hints) {
        (void)hv_store(hints, key, (I32)klen, newSViv(id), 0);
        PL_hints |= HINT_LOCALIZE_HH;
    }
    Safefree(key);
}

static void
ic_del_hint(pTHX_ SV *glyph_sv)
{
    STRLEN len, klen;
    char *g = SvPVutf8(glyph_sv, len);
    char *key = ic_hintkey(aTHX_ g, len, &klen);
    HV *hints = GvHV(PL_hintgv);

    if (hints)
        (void)hv_delete(hints, key, (I32)klen, G_DISCARD);
    Safefree(key);
}

/* Drop every Infix::Custom hint from the current scope (`no Infix::Custom;`). */
static void
ic_del_all_hints(pTHX)
{
    HV *hints = GvHV(PL_hintgv);
    HE *he;
    AV *doomed;
    SSize_t i;

    if (!hints)
        return;
    doomed = (AV *)sv_2mortal((SV *)newAV());   /* collect keys, then delete */
    hv_iterinit(hints);
    while ((he = hv_iternext(hints))) {
        STRLEN kl;
        char *k = HePV(he, kl);
        if (kl >= sizeof("Infix::Custom/") - 1
            && memEQ(k, "Infix::Custom/", sizeof("Infix::Custom/") - 1))
            av_push(doomed, newSVpvn(k, kl));
    }
    for (i = 0; i <= av_top_index(doomed); i++) {
        SV **kp = av_fetch(doomed, i, 0);
        if (kp && *kp) {
            STRLEN kl;
            char *k = SvPV(*kp, kl);
            (void)hv_delete(hints, k, (I32)kl, G_DISCARD);
        }
    }
}

/* A sample C build_op, used only by the test suite to exercise the build_op
 * escape hatch. Lowers `lhs OP rhs` to a (distinctive) native subtraction. */
static OP *
ic_sample_build(pTHX_ SV **opdata, OP *lhs, OP *rhs, struct Perl_custom_infix *def)
{
    PERL_UNUSED_ARG(opdata);
    PERL_UNUSED_ARG(def);
    return newBINOP(OP_SUBTRACT, 0, lhs, rhs);
}

/* Parse @_ for import(): fill in the requested glyph and one of the three
 * lowering modes plus the precedence name. Croaks on malformed input. */
static void
ic_do_import(pTHX_ I32 ax, I32 items)
{
    SV *op_sv = NULL, *call_sv = NULL, *prec_sv = NULL;
    SV *binop_sv = NULL, *build_sv = NULL;
    bool method = FALSE;
    I32 i, start = 1;                       /* ST(0) is the class */
    IV prec, id, modes;

    if (items <= 1)                          /* bare `use Infix::Custom;` */
        return;

    /* shorthand: (CLASS, GLYPH, \&code, ...rest) */
    if (items >= 3 && !SvROK(ST(1))
        && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVCV) {
        op_sv = ST(1);
        call_sv = ST(2);
        start = 3;
    }

    if ((items - start) % 2 != 0)
        croak("Infix::Custom: odd number of options");

    for (i = start; i + 1 < items; i += 2) {
        const char *k = SvPV_nolen(ST(i));
        SV *v = ST(i + 1);
        if      (strEQ(k, "op"))       op_sv    = v;
        else if (strEQ(k, "call"))     call_sv  = v;
        else if (strEQ(k, "binop"))    binop_sv = v;
        else if (strEQ(k, "build_op")) build_sv = v;
        else if (strEQ(k, "prec"))     prec_sv  = v;
        else if (strEQ(k, "method"))   method   = SvTRUE(v);
        else croak("Infix::Custom: unknown option '%s'", k);
    }

    if (!op_sv || !SvOK(op_sv) || !SvCUR(op_sv))
        croak("Infix::Custom: missing 'op' (the operator glyph)");
    {
        STRLEN gl;
        const char *g = SvPV(op_sv, gl);
        STRLEN j;
        for (j = 0; j < gl; j++)
            if (isSPACE(g[j]))
                croak("Infix::Custom: operator glyph may not contain whitespace");
    }

    modes = (call_sv ? 1 : 0) + (binop_sv ? 1 : 0) + (build_sv ? 1 : 0);
    if (modes == 0)
        croak("Infix::Custom: give one of 'call', 'binop' or 'build_op'");
    if (modes > 1)
        croak("Infix::Custom: give only one of 'call', 'binop' or 'build_op'");

    prec = ic_prec_value(prec_sv ? SvPV_nolen(prec_sv) : "low");
    if (prec < 0)
        croak("Infix::Custom: unknown prec '%s' (low logical_or_low "
              "logical_and_low assign logical_or logical_and rel add mul pow "
              "high)", prec_sv ? SvPV_nolen(prec_sv) : "low");

    if (method && !call_sv)
        croak("Infix::Custom: 'method' requires 'call'");

    if (call_sv) {
        CV *cv;
        if (SvROK(call_sv) && SvTYPE(SvRV(call_sv)) == SVt_PVCV)
            cv = (CV *)SvRV(call_sv);
        else                                    /* a sub name */
            cv = get_cv(SvPV_nolen(call_sv), 0);
        if (!cv)
            croak("Infix::Custom: 'call' is not a sub or CODE reference");
        if (method)
            /* RHS is a bareword method name, captured by the parse stage. */
            id = ic_register(aTHX_ op_sv, prec, cv, OP_NULL,
                             ic_build_method, ic_parse_ident);
        else
            id = ic_register(aTHX_ op_sv, prec, cv, OP_NULL,
                             ic_build_call, NULL);
    }
    else if (binop_sv) {
        OPCODE ot = ic_opcode(SvPV_nolen(binop_sv));
        if (ot == OP_NULL)
            croak("Infix::Custom: unknown binop '%s'", SvPV_nolen(binop_sv));
        id = ic_register(aTHX_ op_sv, prec, NULL, ot, ic_build_binop, NULL);
    }
    else {
        ic_build_fn fn = INT2PTR(ic_build_fn, SvIV(build_sv));
        if (!fn)
            croak("Infix::Custom: 'build_op' must be a non-null function pointer");
        id = ic_register(aTHX_ op_sv, prec, NULL, OP_NULL, fn, NULL);
    }

    ic_set_hint(aTHX_ op_sv, id);
}

#endif /* IC_HAVE_INFIX */

MODULE = Infix::Custom        PACKAGE = Infix::Custom

BOOT:
#ifdef IC_HAVE_INFIX
    wrap_infix_plugin(ic_infix_plugin, &ic_next_infix_plugin);
#endif

void
import(...)
PPCODE:
#ifdef IC_HAVE_INFIX
    ic_do_import(aTHX_ ax, items);
    XSRETURN_EMPTY;
#else
{
    static int warned = 0;
    PERL_UNUSED_VAR(ax);
    if (items > 1 && !warned) {
        warned = 1;
        warn("Infix::Custom: custom infix operators require perl 5.38+; "
             "declarations are inert on this perl (%s)\n", "<5.38");
    }
    XSRETURN_EMPTY;
}
#endif

void
unimport(...)
PPCODE:
#ifdef IC_HAVE_INFIX
{
    I32 i;
    if (items <= 1)
        ic_del_all_hints(aTHX);
    else
        for (i = 1; i < items; i++)
            ic_del_hint(aTHX_ ST(i));
    XSRETURN_EMPTY;
}
#else
    PERL_UNUSED_VAR(ax);
    XSRETURN_EMPTY;
#endif

IV
_sample_build_op()
CODE:
#ifdef IC_HAVE_INFIX
    RETVAL = PTR2IV(ic_sample_build);
#else
    RETVAL = 0;
#endif
OUTPUT:
    RETVAL
