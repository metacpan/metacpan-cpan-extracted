/*
 * XML.xs - root XS file
 *
 * The perl headers and File::Raw's plugin registry, then the shims the 5.10
 * floor costs, then the C implementation headers from include/frx/ in
 * dependency order, then the per-package XS fragments from xs/ via
 * INCLUDE: (the Punk-Feed layout).
 *
 * One bundle for every package in the distribution. Each .pm under
 * lib/File/Raw/XML/ loads File::Raw::XML and nothing else, so whichever
 * module is loaded first bootstraps all of them.
 *
 * The rules every header under include/frx/ follows:
 *
 *  1. The core is perl-free. frx_arena, frx_buf, frx_err and everything
 *     built on them (utf8, lex, tree, ns, parse, c14n) use the C
 *     standard library and size_t and never call a Perl_* API or touch an
 *     SV. The SV layer is frx_obj.h, frx_plugin.h and frx_abi_impl.h. A
 *     stub perl.h under tools/stub/ compiles the core alone; so does a
 *     libFuzzer harness.
 *  2. Nothing recurses. max_depth is the caller's, so no function uses the
 *     C stack in proportion to document depth: an explicit open-element
 *     stack in the arena, and every walk iterative over first_child, next
 *     and parent.
 *  3. Allocation is malloc, realloc and free from <stdlib.h>, with the
 *     undefs in frx_compat.h so PERL_IMPLICIT_SYS cannot rewrite them.
 *     Never Newx: the stub perl.h has none.
 *  4. Errors are a struct, not a croak. frx_err is filled by the core and
 *     frx_err_format renders the one message shape; the Perl boundary
 *     croaks with it, the ABI returns NULL and a mortal SV.
 *  5. Every core function is ABI-shaped from day one: it never croaks and
 *     takes const frx_opts * / const frx_c14n * from frx_abi.h directly.
 *  6. C89 declarations at block top, no VLAs, no designated initialisers,
 *     no %zu. Everything static, one translation unit.
 *  7. Private test accessors are underscore XSUBs in xs/internal.xs.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "file_plugin.h"         /* File::Raw's registry, via ExtUtils::Depends */
#include "file_chunk.h"          /* and its pull reads, for Reader->from_file  */

/* The implementation headers, in dependency order. Each states its contract
 * at the top and names what must precede it. */

#include "frx/frx_compat.h"      /* what the 5.10 floor costs; must be first */

#include <stdlib.h>
#include <string.h>

#include "frx_abi.h"             /* the public types; the core is written against them */
#include "frx/frx_err.h"         /* the refusal shape (needs nothing)        */
#include "frx/frx_arena.h"       /* the allocator, frx_str (needs nothing)   */
#include "frx/frx_buf.h"         /* output bytes (needs nothing)             */
#include "frx/frx_uri.h"         /* URI references and the RFC 3986 join (needs buf) */
#include "frx/frx_utf8.h"        /* scalars, Char, Name (needs nothing)      */
#include "frx/frx_enc.h"         /* the transcoder, full only (needs err, utf8) */
#include "frx/frx_tree.h"        /* frx_node, frx_doc (needs abi, arena, utf8) */
#include "frx/frx_lex.h"         /* tokens, the entity frames (needs err, arena, buf, utf8, enc, tree) */
#include "frx/frx_dtd.h"         /* the DOCTYPE and the internal subset, full only (needs lex) */
#include "frx/frx_entity.h"      /* entity expansion and its budgets (needs lex, dtd) */
#include "frx/frx_ns.h"          /* scopes, interning, the rules (needs tree) */
#include "frx/frx_parse.h"       /* the driver, the index, the walkers (all) */
#include "frx/frx_reader.h"      /* the pull reader over the driver (needs parse, enc) */
#include "frx/frx_model.h"       /* content models to an automaton (needs dtd)  */
#include "frx/frx_validate.h"    /* the validity constraints (needs parse, model) */
#include "frx/frx_c14n.h"        /* the serialiser, the three algorithms     */
#include "frx/frx_write.h"       /* the general serialiser (needs c14n for its escapers) */
#include "frx/frx_edit.h"        /* the mutable tree (needs tree, ns, parse) */
#include "frx/frx_xmlattr.h"     /* xml:base, xml:lang, xml:space on a node (needs tree, uri) */
#include "frx/frx_xinclude.h"    /* XInclude 1.0 (needs parse, edit, xmlattr, enc) */
#include "frx/frx_xpath_lex.h"   /* XPath 1.0 tokens (needs err, buf, utf8, tree) */
#include "frx/frx_xpath_parse.h" /* the grammar to an AST (needs arena, xpath_lex) */
#include "frx/frx_xpath_eval.h"  /* the four types, the axes, the functions (needs parse) */
#include "frx/frx_xpath.h"       /* compile once, evaluate many (needs the three above) */
#include "frx/frx_abi_impl.h"    /* the table behind _abi_ptr (needs all of the core) */
#include "frx/frx_obj.h"         /* the SV layer: blessing, owner ref, options */
#include "frx/frx_plugin.h"      /* the File::Raw plugin (needs obj)         */

/* c14n(%opts) from an options HV: mode, comments, prefix_list, without.
 * The arrays live on the savestack for the call. doc_iv identifies the
 * document every `without` node must belong to. */
static void
frx_c14n_opts(pTHX_ HV *hv, SV *doc_iv, frx_c14n *c, const char *who)
{
    HE *he;
    c->mode        = FRX_C14N_EXC;
    c->comments    = 0;
    c->prefix_list = NULL;
    c->n_prefix    = 0;
    c->without     = NULL;
    c->n_without   = 0;
    if (!hv) return;
    hv_iterinit(hv);
    while ((he = hv_iternext(hv))) {
        I32 klen;
        const char *k = hv_iterkey(he, &klen);
        SV *v = hv_iterval(hv, he);
        if (klen == 4 && memcmp(k, "mode", 4) == 0) {
            STRLEN n;
            const char *m = SvPV(v, n);
            if      (n == 9  && memcmp(m, "exclusive", 9) == 0)      c->mode = FRX_C14N_EXC;
            else if (n == 9  && memcmp(m, "inclusive", 9) == 0)      c->mode = FRX_C14N_INC10;
            else if (n == 13 && memcmp(m, "inclusive-1.1", 13) == 0) c->mode = FRX_C14N_INC11;
            else croak("File::Raw::XML: %s: mode must be 'exclusive', 'inclusive' or "
                       "'inclusive-1.1', not '%.*s'", who, (int)n, m);
        } else if (klen == 8 && memcmp(k, "comments", 8) == 0) {
            c->comments = SvTRUE(v) ? 1 : 0;
        } else if (klen == 11 && memcmp(k, "prefix_list", 11) == 0) {
            AV *av;
            I32 n, i;
            const char **names;
            if (!SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVAV)
                croak("File::Raw::XML: %s: prefix_list must be an arrayref of prefixes", who);
            av = (AV *)SvRV(v);
            n  = (I32)(av_len(av) + 1);
            if (n) {
                Newx(names, n, const char *);
                SAVEFREEPV(names);
                for (i = 0; i < n; i++) {
                    SV **e = av_fetch(av, i, 0);
                    if (!e || !SvOK(*e))
                        croak("File::Raw::XML: %s: prefix_list must be an arrayref of prefixes", who);
                    names[i] = SvPV_nolen(*e);
                }
                c->prefix_list = names;
                c->n_prefix    = (int)n;
            }
        } else if (klen == 7 && memcmp(k, "without", 7) == 0) {
            AV *av;
            I32 n, i;
            const frx_node **nodes;
            if (!SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVAV)
                croak("File::Raw::XML: %s: without must be an arrayref of nodes", who);
            av = (AV *)SvRV(v);
            n  = (I32)(av_len(av) + 1);
            if (n) {
                Newx(nodes, n, const frx_node *);
                SAVEFREEPV(nodes);
                for (i = 0; i < n; i++) {
                    SV **e = av_fetch(av, i, 0);
                    SV *their_doc = NULL;
                    if (!e) croak("File::Raw::XML: %s: without must be an arrayref of nodes", who);
                    nodes[i] = frx_node_from_sv(aTHX_ *e, who, &their_doc);
                    if (their_doc != doc_iv)
                        croak("File::Raw::XML: %s: a without node belongs to another document", who);
                }
                c->without   = nodes;
                c->n_without = (int)n;
            }
        } else {
            croak("File::Raw::XML: %s: unknown option '%.*s'", who, (int)klen, k);
        }
    }
}

/* the canonical bytes of apex under c, as a +1 SV with no character flag */
static SV *
frx_c14n_sv(pTHX_ const frx_node *apex, const frx_c14n *c, const char *who)
{
    frx_buf b;
    SV *out;
    frx_buf_init(&b);
    if (!frx_c14n_render(apex, c, &b)) {
        frx_buf_free(&b);
        croak("File::Raw::XML: %s: out of memory", who);
    }
    out = newSVpvn(b.p ? b.p : "", b.len);
    frx_buf_free(&b);
    return out;
}

/* the explicit stack the _dump accessor walks with (rule 2) */
typedef struct frx_dump_frame {
    const frx_node *node;
    AV             *children;
} frx_dump_frame;

/* ---- the XPath SV layer ------------------------------------------------
 *
 * A compiled expression is a blessed IV with ext magic whose free hook
 * calls frx_xpath_free; it holds no document, so it carries no owner
 * reference and is the one object here that does not.
 *
 * An attribute and a namespace node in a result are not frx_nodes, so
 * they cannot be File::Raw::XML::Node. Each is a blessed IV carrying the
 * SAME owner reference a node does - the owning element in mg_ptr, the
 * document's inner IV in mg_obj - with the entry's index as the IV's own
 * value. So an Attr keeps its document alive exactly as a Node does, and
 * a distinct vtable per class is what keeps the three apart at the
 * invocant check. */

#define FRX_XPATH_CLASS "File::Raw::XML::XPath"
#define FRX_ATTR_CLASS  "File::Raw::XML::Attr"
#define FRX_NS_CLASS    "File::Raw::XML::Namespace"

static int
frx_xpath_mg_free(pTHX_ SV *sv, MAGIC *mg)
{
    frx_xpath *x = (frx_xpath *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (x) {
        frx_xpath_free(x);
        mg->mg_ptr = NULL;
    }
    return 0;
}

static MGVTBL frx_xpath_vtbl  = { NULL, NULL, NULL, NULL, frx_xpath_mg_free, NULL, NULL, NULL };
static MGVTBL frx_attr_vtbl   = { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL };
static MGVTBL frx_nsnode_vtbl = { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL };

static SV *
frx_xpath_bless(pTHX_ frx_xpath *x, const char *class_name)
{
    SV *iv = newSViv(0);
    sv_magicext(iv, NULL, PERL_MAGIC_ext, &frx_xpath_vtbl, (const char *)x, 0);
    return sv_bless(newRV_noinc(iv), gv_stashpv(class_name, GV_ADD));
}

static frx_xpath *
frx_xpath_from_sv(pTHX_ SV *sv, const char *meth)
{
    MAGIC *mg = frx_obj_magic(aTHX_ sv, &frx_xpath_vtbl);
    if (!mg || !mg->mg_ptr)
        croak("File::Raw::XML: %s: the invocant is not a " FRX_XPATH_CLASS, meth);
    return (frx_xpath *)mg->mg_ptr;
}

/* an attribute or namespace entry of the element owner, +1, blessed */
static SV *
frx_entry_bless(pTHX_ SV *doc_iv, const frx_node *owner, int index, int is_ns)
{
    SV *iv = newSViv(index);
    sv_magicext(iv, doc_iv, PERL_MAGIC_ext,
                is_ns ? &frx_nsnode_vtbl : &frx_attr_vtbl, (const char *)owner, 0);
    return sv_bless(newRV_noinc(iv),
                    gv_stashpv(is_ns ? FRX_NS_CLASS : FRX_ATTR_CLASS, GV_ADD));
}

static const frx_node *
frx_entry_from_sv(pTHX_ SV *sv, const char *meth, int is_ns, int *index, SV **doc_iv)
{
    MAGIC *mg = frx_obj_magic(aTHX_ sv, is_ns ? &frx_nsnode_vtbl : &frx_attr_vtbl);
    if (!mg || !mg->mg_ptr || !mg->mg_obj)
        croak("File::Raw::XML: %s: the invocant is not a %s", meth,
              is_ns ? FRX_NS_CLASS : FRX_ATTR_CLASS);
    if (index)  *index  = (int)SvIV(SvRV(sv));
    if (doc_iv) *doc_iv = mg->mg_obj;
    return (const frx_node *)mg->mg_ptr;
}

/* the frx_doc behind a document's inner IV */
static frx_doc *
frx_doc_of_iv(pTHX_ SV *doc_iv, const char *meth)
{
    MAGIC *mg = doc_iv ? mg_findext(doc_iv, PERL_MAGIC_ext, &frx_doc_vtbl) : NULL;
    if (!mg || !mg->mg_ptr)
        croak("File::Raw::XML: %s: the node has no document", meth);
    return (frx_doc *)mg->mg_ptr;
}

/* the context of an evaluation: a Document is its document node, a Node
 * is itself, and both name the document the results belong to */
static const frx_node *
frx_xpath_context(pTHX_ SV *sv, const char *meth, frx_doc **doc, SV **doc_iv)
{
    if (frx_obj_magic(aTHX_ sv, &frx_doc_vtbl)) {
        frx_doc *d = frx_doc_from_sv(aTHX_ sv, meth);
        *doc     = d;
        *doc_iv  = SvRV(sv);
        return d->document;
    }
    {
        const frx_node *n = frx_node_from_sv(aTHX_ sv, meth, doc_iv);
        *doc = frx_doc_of_iv(aTHX_ *doc_iv, meth);
        return n;
    }
}

/* one node-set entry as a mortal SV: a Node, an Attr or a Namespace */
static SV *
frx_xp_item_sv(pTHX_ SV *doc_iv, const frx_xp_item *it)
{
    switch (it->kind) {
    case FRX_XP_KATTR: return frx_entry_bless(aTHX_ doc_iv, it->node, it->index, 0);
    case FRX_XP_KNS:   return frx_entry_bless(aTHX_ doc_iv, it->node, it->index, 1);
    default:           return frx_node_bless(aTHX_ doc_iv, it->node);
    }
}

/* Compile expr under the options HV: ns, vars, max_expr_depth. Croaks in
 * the one message shape, with the offset counted in the expression. Every
 * variable the expression names must be in `vars`, and it is named in the
 * refusal when it is not. */
static frx_xpath *
frx_xpath_from_opts(pTHX_ SV *expr_sv, HV *opts, const char *who)
{
    STRLEN      elen;
    const char *expr = frx_input(aTHX_ expr_sv, &elen);
    frx_ns_map  map;
    frx_ns_binding *bind = NULL;
    HV         *vars = NULL;
    int         max_depth = 0;
    frx_xpath  *x;
    const char *err = NULL;
    size_t      at  = 0;
    int         i, n_vars;

    map.v = NULL;
    map.n = 0;

    if (opts) {
        HE *he;
        hv_iterinit(opts);
        while ((he = hv_iternext(opts))) {
            I32 klen;
            const char *k = hv_iterkey(he, &klen);
            SV *v = hv_iterval(opts, he);
            if (klen == 2 && memcmp(k, "ns", 2) == 0) {
                HV *nh;
                HE *nhe;
                I32 n;
                if (!SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVHV)
                    croak("File::Raw::XML: %s: ns must be a hashref of prefix => uri", who);
                nh = (HV *)SvRV(v);
                n  = hv_iterinit(nh);
                if (!n) continue;
                Newx(bind, n, frx_ns_binding);
                SAVEFREEPV(bind);
                i = 0;
                while ((nhe = hv_iternext(nh)) && i < (int)n) {
                    I32 plen;
                    bind[i].prefix = hv_iterkey(nhe, &plen);
                    bind[i].uri    = SvPV_nolen(hv_iterval(nh, nhe));
                    i++;
                }
                map.v = bind;
                map.n = i;
            } else if (klen == 4 && memcmp(k, "vars", 4) == 0) {
                if (!SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVHV)
                    croak("File::Raw::XML: %s: vars must be a hashref of name => value", who);
                vars = (HV *)SvRV(v);
            } else if (klen == 14 && memcmp(k, "max_expr_depth", 14) == 0) {
                max_depth = (int)SvIV(v);
            } else {
                croak("File::Raw::XML: %s: unknown option '%.*s'", who, (int)klen, k);
            }
        }
    }

    x = frx_xpath_compile(expr, (size_t)elen, &map, max_depth, &err, &at);
    if (!x) {
        char   msg[512];
        size_t n = frx_xpath_err_format(err, expr, (size_t)elen, at, msg, sizeof msg);
        croak("%.*s", (int)n, msg);
    }

    n_vars = frx_xpath_var_count(x);
    for (i = 0; i < n_vars; i++) {
        STRLEN      nlen;
        const char *name = frx_xpath_var_name(x, i, &nlen);
        SV        **slot = vars ? hv_fetch(vars, name, (I32)nlen, 0) : NULL;
        SV         *val;
        /* The name is in the compiled expression's arena, so a message
         * that quotes it has to be built before the expression is freed:
         * croak reads its arguments after the free otherwise, which is a
         * use-after-free ASan finds and a smoker reports as a bad
         * message. Truncated at 200 bytes, which no NCName reaches. */
        char        held[256];
        int         nheld = (int)(nlen > 200 ? 200 : nlen);
        if (!name) nheld = 0;
        else if (nheld) memcpy(held, name, (size_t)nheld);
        held[nheld] = '\0';
        if (!slot || !SvOK(*slot)) {
            frx_xpath_free(x);
            croak("File::Raw::XML: %s: the expression uses $%s and no value was given for it",
                  who, held);
        }
        val = *slot;
        if (SvROK(val)) {
            frx_xpath_free(x);
            croak("File::Raw::XML: %s: the value of $%s must be a string or a number",
                  who, held);
        }
        if (!SvPOK(val) && (SvIOK(val) || SvNOK(val))) {
            frx_xpath_bind_num(x, i, (double)SvNV(val));
        } else {
            STRLEN      vlen;
            const char *vp = frx_input(aTHX_ val, &vlen);
            if (!frx_xpath_bind_str(x, i, vp, (size_t)vlen)) {
                frx_xpath_free(x);
                croak("File::Raw::XML: %s: out of memory", who);
            }
        }
    }
    return x;
}

/* The result as a mortal AV the XSUB pushes from: a node-set is every
 * entry in document order, or just the first in scalar context, and each
 * of the other three types is one scalar. The value is freed here, so
 * every SV in the AV owns its own copy of what it holds. */
static AV *
frx_xp_result_av(pTHX_ frx_xp_val *v, SV *doc_iv, I32 gimme)
{
    AV *av = (AV *)sv_2mortal((SV *)newAV());
    int i;

    switch (v->kind) {
    case FRX_XV_NODESET:
        if (gimme == G_LIST) {
            for (i = 0; i < v->set.n; i++)
                av_push(av, frx_xp_item_sv(aTHX_ doc_iv, &v->set.v[i]));
        } else {
            av_push(av, v->set.n ? frx_xp_item_sv(aTHX_ doc_iv, &v->set.v[0]) : newSV(0));
        }
        break;
    case FRX_XV_BOOLEAN:
        av_push(av, newSViv(v->bl ? 1 : 0));
        break;
    case FRX_XV_NUMBER:
        av_push(av, newSVnv(v->num));
        break;
    default: {
        SV *s = newSVpvn(v->str.p ? v->str.p : "", v->str.len);
        SvUTF8_on(s);
        av_push(av, s);
        break;
    }
    }
    return av;
}

MODULE = File::Raw::XML    PACKAGE = File::Raw::XML

PROTOTYPES: DISABLE

BOOT:
    /* the `xml` plugin, against File::Raw's registry; Raw.so is resident
     * because XML.pm says `use File::Raw` before XSLoader::load */
    frx_plugin_register(aTHX);

INCLUDE: xs/internal.xs
INCLUDE: xs/codec.xs
INCLUDE: xs/document.xs
INCLUDE: xs/node.xs
INCLUDE: xs/reader.xs
INCLUDE: xs/xpath.xs
INCLUDE: xs/abi.xs
