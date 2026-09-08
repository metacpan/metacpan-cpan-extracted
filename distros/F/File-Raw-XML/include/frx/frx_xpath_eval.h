#ifndef FRX_XPATH_EVAL_H
#define FRX_XPATH_EVAL_H

/* XPath 1.0 evaluation: four types, thirteen axes, 27 functions.
 *
 * NODE-SETS are arrays of (node, kind, index): kind selects the node
 * itself, its i'th attribute, or its i'th namespace node, because an
 * attribute is not an frx_node and a namespace node is not stored at all.
 * Document order among the three is XPath section 5's: the element, then
 * its namespace nodes, then its attributes, then its children. An
 * attribute and a namespace node therefore sort on their element's
 * `order` and are separated by kind, which is why the kind constants are
 * numbered in that order and never renumbered.
 *
 * NAMESPACE NODES are synthesised from the scope chain at evaluation and
 * never stored on the tree: the in-scope bindings, nearest per prefix,
 * with a binding to the empty URI (xmlns="") dropped because it declares
 * the absence of one, with xml always present, sorted by prefix so the
 * list is the same list every time an index into it is read back. XPath
 * leaves the relative order of namespace nodes to the implementation and
 * requires only that it be stable; this is the stable order chosen.
 * Synthesis is O(depth) per element and is paid again each time a
 * namespace item's name or value is read, which is the cost of not
 * carrying namespace nodes in a tree that has no use for them.
 *
 * RECURSION. Over the document, none (rule 2): every axis is an
 * iterative walk and every predicate is a loop. Over the AST, yes,
 * bounded by the depth the compiler capped at `max_expr_depth`, which is
 * the AST's depth and not the parser's, so a long chain of associative
 * operators is bounded too.
 *
 * NUMBERS are C doubles with the specification's semantics throughout:
 * NaN, the infinities and negative zero all reach the caller. The
 * number-to-string conversion is section 4.2's and not a printf format:
 * no exponent ever appears, an integer-valued double has no fraction, and
 * the digits are the shortest that read back as the same double. It finds
 * those digits through sprintf and strtod, which agree with each other
 * whatever LC_NUMERIC says, and then lays the decimal point out itself,
 * so a locale whose decimal separator is a comma cannot reach the output.
 *
 * Needs frx_buf.h, frx_utf8.h, frx_tree.h, frx_ns.h, frx_parse.h,
 * frx_xpath_parse.h. */

#include <math.h>
#include <float.h>

/* FRX_XP_KNODE, FRX_XP_KNS and FRX_XP_KATTR are frx_abi.h's, numbered in
 * document order among themselves and never renumbered. */

/* the four value types */
enum { FRX_XV_NODESET = 0, FRX_XV_BOOLEAN, FRX_XV_NUMBER, FRX_XV_STRING };

typedef struct frx_xp_item {
    const frx_node *node;    /* the node, or the owner element of an attribute
                              * or namespace entry */
    int             kind;
    int             index;
} frx_xp_item;

typedef struct frx_xp_set {
    frx_xp_item *v;
    int          n, cap;
} frx_xp_set;

typedef struct frx_xp_val {
    int         kind;
    int         bl;
    double      num;
    frx_buf     str;
    frx_xp_set  set;
} frx_xp_val;

typedef struct frx_xp_var {
    frx_str    name;
    frx_xp_val val;
} frx_xp_var;

typedef struct frx_xeval {
    frx_doc          *doc;
    const frx_xp_var *vars;
    int               n_vars;
    const char       *err;      /* static; NULL while all is well */
    int               failed;
} frx_xeval;

typedef struct frx_xctx {
    frx_xp_item item;
    int         position;       /* 1-based */
    int         size;
} frx_xctx;

static int frx_xp_eval(frx_xeval *e, const frx_xn *n, const frx_xctx *c, frx_xp_val *out);

static int
frx_xp_efail(frx_xeval *e, const char *what)
{
    if (!e->failed) { e->failed = 1; e->err = what; }
    return 0;
}

/* ---- doubles ----------------------------------------------------------- */

static double
frx_xp_nan(void)
{
    volatile double z = 0.0;
    return z / z;
}

static int
frx_xp_is_nan(double v)
{
    return v != v;
}

static int
frx_xp_is_inf(double v)
{
    return v > DBL_MAX || v < -DBL_MAX;
}

/* section 4.2: no exponent, no trailing zeros, the shortest digits that
 * read back as this double */
static void
frx_xp_num_str(frx_buf *out, double v)
{
    char   fmt[16];
    char   buf[512];
    char   digits[40];
    double av;
    int    p, i, ndig = 0, e10 = 0, neg = 0, dp;

    if (frx_xp_is_nan(v)) { frx_buf_append(out, "NaN"); return; }
    if (v == 0.0)         { frx_buf_append(out, "0");   return; }
    if (v < 0) { neg = 1; av = -v; } else av = v;
    if (frx_xp_is_inf(av)) { frx_buf_append(out, neg ? "-Infinity" : "Infinity"); return; }

    for (p = 0; p < 17; p++) {
        FRX_FMT1(fmt, sizeof fmt, "%%.%de", p);
        FRX_FMT1(buf, sizeof buf, fmt, av);
        if (strtod(buf, NULL) == av) break;
    }

    /* buf is  d<sep>ddde<sign>dd, where <sep> is whatever LC_NUMERIC said */
    i = 0;
    digits[ndig++] = buf[i++];
    if (buf[i] && buf[i] != 'e' && buf[i] != 'E') {
        i++;                                     /* the decimal separator */
        while (buf[i] >= '0' && buf[i] <= '9' && ndig < (int)sizeof digits)
            digits[ndig++] = buf[i++];
    }
    if (buf[i] == 'e' || buf[i] == 'E') {
        int sign = 1;
        i++;
        if      (buf[i] == '+') i++;
        else if (buf[i] == '-') { sign = -1; i++; }
        while (buf[i] >= '0' && buf[i] <= '9') e10 = e10 * 10 + (buf[i++] - '0');
        e10 *= sign;
    }
    while (ndig > 1 && digits[ndig - 1] == '0') ndig--;

    dp = e10 + 1;                                /* digits before the point */
    if (neg) frx_buf_append_ch(out, '-');
    if (dp <= 0) {
        frx_buf_append(out, "0.");
        for (i = 0; i < -dp; i++) frx_buf_append_ch(out, '0');
        frx_buf_append_n(out, digits, (size_t)ndig);
    } else if (dp >= ndig) {
        frx_buf_append_n(out, digits, (size_t)ndig);
        for (i = 0; i < dp - ndig; i++) frx_buf_append_ch(out, '0');
    } else {
        frx_buf_append_n(out, digits, (size_t)dp);
        frx_buf_append_ch(out, '.');
        frx_buf_append_n(out, digits + dp, (size_t)(ndig - dp));
    }
}

/* Section 4.4: optional space, optional '-', Digits ('.' Digits?)? or
 * '.' Digits, optional space; anything else is NaN. No sign but '-' and
 * no exponent, so the syntax is checked here and only the span that
 * passed reaches frx_xp_atod: strtod would take "1e5" and "+1", which
 * are not Numbers. */
static double
frx_xp_str_num(const char *p, size_t n)
{
    size_t at = 0, start;
    int    any = 0;

    while (at < n && frx_is_s((unsigned char)p[at])) at++;
    start = at;
    if (at < n && p[at] == '-') at++;
    while (at < n && p[at] >= '0' && p[at] <= '9') { at++; any = 1; }
    if (at < n && p[at] == '.') {
        at++;
        while (at < n && p[at] >= '0' && p[at] <= '9') { at++; any = 1; }
    }
    if (!any) return frx_xp_nan();
    {
        size_t end = at;
        while (at < n && frx_is_s((unsigned char)p[at])) at++;
        if (at != n) return frx_xp_nan();
        return frx_xp_atod(p + start, end - start);
    }
}

/* section 4.4: the integer closest to v, ties to positive infinity */
static double
frx_xp_round(double v)
{
    if (frx_xp_is_nan(v) || frx_xp_is_inf(v) || v == 0.0) return v;
    if (v < 0.0 && v >= -0.5) return -0.0;
    return floor(v + 0.5);
}

/* ---- buffers and values ------------------------------------------------ */

static void
frx_xp_buf_reset(frx_buf *b)
{
    b->len = 0;
    if (b->p) b->p[0] = '\0';
}

static void
frx_xp_val_init(frx_xp_val *v)
{
    memset(v, 0, sizeof *v);
    v->kind = FRX_XV_NODESET;
    frx_buf_init(&v->str);
}

static void
frx_xp_set_free(frx_xp_set *s)
{
    free(s->v);
    s->v = NULL;
    s->n = s->cap = 0;
}

static void
frx_xp_val_free(frx_xp_val *v)
{
    frx_buf_free(&v->str);
    frx_xp_set_free(&v->set);
}

static int
frx_xp_set_push(frx_xp_set *s, const frx_xp_item *it)
{
    if (s->n == s->cap) {
        int ncap = s->cap ? s->cap * 2 : 16;
        frx_xp_item *nv = (frx_xp_item *)realloc(s->v, (size_t)ncap * sizeof *nv);
        if (!nv) return 0;
        s->v   = nv;
        s->cap = ncap;
    }
    s->v[s->n++] = *it;
    return 1;
}

static int
frx_xp_set_push3(frx_xp_set *s, const frx_node *n, int kind, int index)
{
    frx_xp_item it;
    it.node  = n;
    it.kind  = kind;
    it.index = index;
    return frx_xp_set_push(s, &it);
}

static int
frx_xp_item_cmp(const void *pa, const void *pb)
{
    const frx_xp_item *a = (const frx_xp_item *)pa;
    const frx_xp_item *b = (const frx_xp_item *)pb;
    if (a->node->order != b->node->order) return a->node->order < b->node->order ? -1 : 1;
    if (a->kind  != b->kind)  return a->kind  < b->kind  ? -1 : 1;
    if (a->index != b->index) return a->index < b->index ? -1 : 1;
    return 0;
}

static void
frx_xp_set_sort(frx_xp_set *s)
{
    int i, w;
    if (s->n < 2) return;
    qsort(s->v, (size_t)s->n, sizeof *s->v, frx_xp_item_cmp);
    for (i = 1, w = 1; i < s->n; i++)
        if (frx_xp_item_cmp(&s->v[i], &s->v[w - 1]) != 0) s->v[w++] = s->v[i];
    s->n = w;
}

/* ---- namespace nodes --------------------------------------------------- */

typedef struct frx_xp_nsnode {
    frx_str prefix;
    frx_str uri;
} frx_xp_nsnode;

static int
frx_xp_nsnode_cmp(const void *pa, const void *pb)
{
    const frx_xp_nsnode *a = (const frx_xp_nsnode *)pa;
    const frx_xp_nsnode *b = (const frx_xp_nsnode *)pb;
    return frx_str_cmp(&a->prefix, &b->prefix);
}

/* the element's namespace nodes, malloc'd, sorted by prefix; 0 on an
 * allocation failure */
static int
frx_xp_ns_list(const frx_node *e, frx_xp_nsnode **out, int *n_out)
{
    static const frx_str xmlp = { "xml", 3 };
    static const frx_str xmlu = { FRX_XML_NS, sizeof FRX_XML_NS - 1 };
    const frx_scope *s;
    frx_xp_nsnode   *v = NULL;
    int              n = 0, cap = 0, i, j, seen;

    *out = NULL;
    *n_out = 0;
    for (s = e->scope; s; s = s->up) {
        for (i = 0; i < s->n_decls; i++) {
            const frx_nsdecl *d = &s->decls[i];
            seen = 0;
            for (j = 0; j < n; j++)
                if (frx_str_eq2(&v[j].prefix, &d->prefix)) { seen = 1; break; }
            if (seen) continue;
            if (n == cap) {
                int ncap = cap ? cap * 2 : 8;
                frx_xp_nsnode *nv = (frx_xp_nsnode *)realloc(v, (size_t)ncap * sizeof *nv);
                if (!nv) { free(v); return 0; }
                v = nv; cap = ncap;
            }
            v[n].prefix = d->prefix;
            v[n].uri    = d->uri;
            n++;
        }
    }
    /* an in-scope binding to the empty URI declares no namespace: xmlns=""
     * removes the default namespace node rather than adding one */
    for (i = 0, j = 0; i < n; i++)
        if (v[i].uri.len) v[j++] = v[i];
    n = j;
    if (n == cap) {
        int ncap = cap ? cap * 2 : 8;
        frx_xp_nsnode *nv = (frx_xp_nsnode *)realloc(v, (size_t)ncap * sizeof *nv);
        if (!nv) { free(v); return 0; }
        v = nv; cap = ncap;
    }
    v[n].prefix = xmlp;
    v[n].uri    = xmlu;
    n++;
    if (n > 1) qsort(v, (size_t)n, sizeof *v, frx_xp_nsnode_cmp);
    *out   = v;
    *n_out = n;
    return 1;
}

static int
frx_xp_ns_at(const frx_node *e, int i, frx_str *prefix, frx_str *uri)
{
    frx_xp_nsnode *v;
    int n;
    *prefix = *uri = FRX_EMPTY_STR;
    if (!frx_xp_ns_list(e, &v, &n)) return 0;
    if (i >= 0 && i < n) { *prefix = v[i].prefix; *uri = v[i].uri; }
    free(v);
    return 1;
}

/* ---- what an item is --------------------------------------------------- */

static const frx_node *
frx_xp_root_of(const frx_node *n)
{
    while (n->parent) n = n->parent;
    return n;
}

static int
frx_xp_item_string(frx_xeval *e, const frx_xp_item *it, frx_buf *out)
{
    switch (it->kind) {
    case FRX_XP_KATTR: {
        const frx_str *v = &it->node->attrs[it->index].value;
        frx_buf_append_n(out, v->p, v->len);
        break;
    }
    case FRX_XP_KNS: {
        frx_str prefix, uri;
        if (!frx_xp_ns_at(it->node, it->index, &prefix, &uri))
            return frx_xp_efail(e, "out of memory");
        frx_buf_append_n(out, uri.p, uri.len);
        break;
    }
    default:
        frx_text(it->node, out);
        break;
    }
    return out->failed ? frx_xp_efail(e, "out of memory") : 1;
}

/* the expanded name's three faces: local part, namespace URI, and the
 * name as it would be written */
static int
frx_xp_item_name(frx_xeval *e, const frx_xp_item *it, int which, frx_buf *out)
{
    const frx_node *n = it->node;
    const frx_str  *s = &FRX_EMPTY_STR;
    frx_str prefix, uri;

    switch (it->kind) {
    case FRX_XP_KATTR:
        s = which == 0 ? &n->attrs[it->index].local
          : which == 1 ? &n->attrs[it->index].ns
                       : &n->attrs[it->index].qname;
        break;
    case FRX_XP_KNS:
        if (!frx_xp_ns_at(n, it->index, &prefix, &uri))
            return frx_xp_efail(e, "out of memory");
        s = which == 1 ? &FRX_EMPTY_STR : &prefix;
        break;
    default:
        if (n->kind == FRX_ELEMENT)
            s = which == 0 ? &n->local : which == 1 ? &n->ns : &n->qname;
        else if (n->kind == FRX_PI && which != 1)
            s = &n->local;
        break;
    }
    frx_buf_append_n(out, s->p, s->len);
    return out->failed ? frx_xp_efail(e, "out of memory") : 1;
}

/* ---- conversions ------------------------------------------------------- */

static int
frx_xp_to_bool(frx_xeval *e, const frx_xp_val *v)
{
    (void)e;
    switch (v->kind) {
    case FRX_XV_NODESET: return v->set.n > 0;
    case FRX_XV_BOOLEAN: return v->bl != 0;
    case FRX_XV_NUMBER:  return !frx_xp_is_nan(v->num) && v->num != 0.0;
    default:             return v->str.len > 0;
    }
}

/* the string-value of a value: for a node-set, of its first node in
 * document order, the set already being sorted */
static int
frx_xp_to_str(frx_xeval *e, const frx_xp_val *v, frx_buf *out)
{
    frx_xp_buf_reset(out);
    switch (v->kind) {
    case FRX_XV_NODESET:
        if (v->set.n) return frx_xp_item_string(e, &v->set.v[0], out);
        return 1;
    case FRX_XV_BOOLEAN:
        frx_buf_append(out, v->bl ? "true" : "false");
        break;
    case FRX_XV_NUMBER:
        frx_xp_num_str(out, v->num);
        break;
    default:
        frx_buf_append_n(out, v->str.p ? v->str.p : "", v->str.len);
        break;
    }
    return out->failed ? frx_xp_efail(e, "out of memory") : 1;
}

static int
frx_xp_to_num(frx_xeval *e, const frx_xp_val *v, double *out)
{
    switch (v->kind) {
    case FRX_XV_BOOLEAN: *out = v->bl ? 1.0 : 0.0; return 1;
    case FRX_XV_NUMBER:  *out = v->num;            return 1;
    case FRX_XV_STRING:  *out = frx_xp_str_num(v->str.p ? v->str.p : "", v->str.len); return 1;
    default: {
        frx_buf b;
        int ok;
        frx_buf_init(&b);
        ok = frx_xp_to_str(e, v, &b);
        *out = ok ? frx_xp_str_num(b.p ? b.p : "", b.len) : frx_xp_nan();
        frx_buf_free(&b);
        return ok;
    }
    }
}

/* ---- UTF-8 by character ------------------------------------------------ */

static size_t
frx_xp_nchars(const char *p, size_t n)
{
    size_t at = 0, count = 0;
    unsigned long cp;
    while (at < n) {
        size_t k = frx_utf8_decode((const unsigned char *)p + at, n - at, &cp);
        at += k ? k : 1;
        count++;
    }
    return count;
}

/* ---- the axes ---------------------------------------------------------- */

/* the next node in document order that is not inside n */
static const frx_node *
frx_xp_after_subtree(const frx_node *n, const frx_node *root)
{
    while (n != root && !n->next) n = n->parent;
    return n == root ? NULL : n->next;
}

static int
frx_xp_is_ancestor(const frx_node *maybe, const frx_node *n)
{
    for (n = n->parent; n; n = n->parent)
        if (n == maybe) return 1;
    return 0;
}

/* does the node test hold for this item on this step's axis? */
static int
frx_xp_test(const frx_xn *step, const frx_xp_item *it)
{
    const frx_node *n = it->node;

    switch (step->test) {
    case FRX_XTEST_NODE:
        return 1;
    case FRX_XTEST_TEXT:
        return it->kind == FRX_XP_KNODE && n->kind == FRX_TEXT;
    case FRX_XTEST_COMMENT:
        return it->kind == FRX_XP_KNODE && n->kind == FRX_COMMENT;
    case FRX_XTEST_PI:
        if (it->kind != FRX_XP_KNODE || n->kind != FRX_PI) return 0;
        return step->str.len == 0 || frx_str_eq2(&n->local, &step->str);
    default:
        break;
    }

    /* a name test matches the principal node type of the axis and no other */
    if (step->axis == FRX_AX_ATTRIBUTE) {
        const frx_attr *a;
        if (it->kind != FRX_XP_KATTR) return 0;
        if (step->test == FRX_XTEST_STAR) return 1;
        a = &n->attrs[it->index];
        if (step->test == FRX_XTEST_NSSTAR) return frx_str_eq2(&a->ns, &step->ns);
        return frx_str_eq2(&a->local, &step->local) && frx_str_eq2(&a->ns, &step->ns);
    }
    if (step->axis == FRX_AX_NAMESPACE) {
        frx_str prefix, uri;
        if (it->kind != FRX_XP_KNS) return 0;
        if (step->test == FRX_XTEST_STAR) return 1;
        /* a namespace node's expanded name has a null URI and the prefix
         * as its local part, so only an unprefixed name test can match */
        if (step->test == FRX_XTEST_NSSTAR || step->ns.len) return 0;
        if (!frx_xp_ns_at(n, it->index, &prefix, &uri)) return 0;
        return frx_str_eq2(&prefix, &step->local);
    }
    if (it->kind != FRX_XP_KNODE || n->kind != FRX_ELEMENT) return 0;
    if (step->test == FRX_XTEST_STAR)   return 1;
    if (step->test == FRX_XTEST_NSSTAR) return frx_str_eq2(&n->ns, &step->ns);
    return frx_str_eq2(&n->local, &step->local) && frx_str_eq2(&n->ns, &step->ns);
}

static int
frx_xp_take(frx_xeval *e, const frx_xn *step, frx_xp_set *out,
            const frx_node *n, int kind, int index)
{
    frx_xp_item it;
    it.node  = n;
    it.kind  = kind;
    it.index = index;
    if (!frx_xp_test(step, &it)) return 1;
    if (!frx_xp_set_push(out, &it)) return frx_xp_efail(e, "out of memory");
    return 1;
}

static void
frx_xp_reverse(frx_xp_set *s, int from)
{
    int i = from, j = s->n - 1;
    while (i < j) {
        frx_xp_item t = s->v[i];
        s->v[i++] = s->v[j];
        s->v[j--] = t;
    }
}

/* every node on the axis, in the axis's own order (reverse document order
 * for the four reverse axes), filtered by the node test */
static int
frx_xp_axis(frx_xeval *e, const frx_xn *step, const frx_xp_item *ctx, frx_xp_set *out)
{
    const frx_node *self = ctx->node;
    const frx_node *n;
    int base = out->n;
    int i;

    switch (step->axis) {
    case FRX_AX_SELF:
        return frx_xp_take(e, step, out, self, ctx->kind, ctx->index);

    case FRX_AX_PARENT:
        if (ctx->kind != FRX_XP_KNODE)
            return frx_xp_take(e, step, out, self, FRX_XP_KNODE, 0);
        if (self->parent) return frx_xp_take(e, step, out, self->parent, FRX_XP_KNODE, 0);
        return 1;

    case FRX_AX_ANCESTOR_OR_SELF:
        if (!frx_xp_take(e, step, out, self, ctx->kind, ctx->index)) return 0;
        if (ctx->kind != FRX_XP_KNODE) {
            for (n = self; n; n = n->parent)
                if (!frx_xp_take(e, step, out, n, FRX_XP_KNODE, 0)) return 0;
            return 1;
        }
        for (n = self->parent; n; n = n->parent)
            if (!frx_xp_take(e, step, out, n, FRX_XP_KNODE, 0)) return 0;
        return 1;

    case FRX_AX_ANCESTOR:
        n = ctx->kind == FRX_XP_KNODE ? self->parent : self;
        for (; n; n = n->parent)
            if (!frx_xp_take(e, step, out, n, FRX_XP_KNODE, 0)) return 0;
        return 1;

    case FRX_AX_CHILD:
        if (ctx->kind != FRX_XP_KNODE) return 1;
        for (n = self->first_child; n; n = n->next)
            if (!frx_xp_take(e, step, out, n, FRX_XP_KNODE, 0)) return 0;
        return 1;

    case FRX_AX_DESCENDANT_OR_SELF:
        if (!frx_xp_take(e, step, out, self, ctx->kind, ctx->index)) return 0;
        if (ctx->kind != FRX_XP_KNODE) return 1;
        for (n = self->first_child; n; n = frx_walk_next(n, self))
            if (!frx_xp_take(e, step, out, n, FRX_XP_KNODE, 0)) return 0;
        return 1;

    case FRX_AX_DESCENDANT:
        if (ctx->kind != FRX_XP_KNODE) return 1;
        for (n = self->first_child; n; n = frx_walk_next(n, self))
            if (!frx_xp_take(e, step, out, n, FRX_XP_KNODE, 0)) return 0;
        return 1;

    case FRX_AX_FOLLOWING_SIBLING:
        if (ctx->kind != FRX_XP_KNODE) return 1;
        for (n = self->next; n; n = n->next)
            if (!frx_xp_take(e, step, out, n, FRX_XP_KNODE, 0)) return 0;
        return 1;

    case FRX_AX_PRECEDING_SIBLING:
        if (ctx->kind != FRX_XP_KNODE || !self->parent) return 1;
        for (n = self->parent->first_child; n && n != self; n = n->next)
            if (!frx_xp_take(e, step, out, n, FRX_XP_KNODE, 0)) return 0;
        frx_xp_reverse(out, base);               /* nearest first */
        return 1;

    case FRX_AX_FOLLOWING: {
        const frx_node *root = frx_xp_root_of(self);
        /* an attribute or namespace node stands just before its element's
         * children, so those are following it; the element's own subtree
         * is not following the element */
        n = ctx->kind == FRX_XP_KNODE
          ? frx_xp_after_subtree(self, root)
          : (self->first_child ? self->first_child : frx_xp_after_subtree(self, root));
        for (; n; n = frx_walk_next(n, root))
            if (!frx_xp_take(e, step, out, n, FRX_XP_KNODE, 0)) return 0;
        return 1;
    }

    case FRX_AX_PRECEDING: {
        const frx_node *root = frx_xp_root_of(self);
        for (n = root->first_child; n && n != self; n = frx_walk_next(n, root))
            if (!frx_xp_is_ancestor(n, self)
                && !frx_xp_take(e, step, out, n, FRX_XP_KNODE, 0)) return 0;
        frx_xp_reverse(out, base);               /* nearest first */
        return 1;
    }

    case FRX_AX_ATTRIBUTE:
        if (ctx->kind != FRX_XP_KNODE || self->kind != FRX_ELEMENT) return 1;
        for (i = 0; i < self->n_attrs; i++)
            if (!frx_xp_take(e, step, out, self, FRX_XP_KATTR, i)) return 0;
        return 1;

    case FRX_AX_NAMESPACE: {
        frx_xp_nsnode *v;
        int n_ns;
        if (ctx->kind != FRX_XP_KNODE || self->kind != FRX_ELEMENT) return 1;
        if (!frx_xp_ns_list(self, &v, &n_ns)) return frx_xp_efail(e, "out of memory");
        free(v);
        for (i = 0; i < n_ns; i++)
            if (!frx_xp_take(e, step, out, self, FRX_XP_KNS, i)) return 0;
        return 1;
    }

    default:
        return frx_xp_efail(e, "unknown axis");
    }
}

/* ---- steps and paths --------------------------------------------------- */

static int
frx_xp_filter_set(frx_xeval *e, const frx_xn *pred, frx_xp_set *s)
{
    int i, w = 0, n = s->n;
    for (i = 0; i < n; i++) {
        frx_xctx    c;
        frx_xp_val  v;
        int         keep;
        c.item     = s->v[i];
        c.position = i + 1;
        c.size     = n;
        frx_xp_val_init(&v);
        if (!frx_xp_eval(e, pred, &c, &v)) { frx_xp_val_free(&v); return 0; }
        /* a predicate that is a number selects by proximity position */
        keep = v.kind == FRX_XV_NUMBER ? v.num == (double)(i + 1) : frx_xp_to_bool(e, &v);
        frx_xp_val_free(&v);
        if (keep) s->v[w++] = s->v[i];
    }
    s->n = w;
    return 1;
}

static int
frx_xp_step_over(frx_xeval *e, const frx_xn *step, const frx_xp_set *in, frx_xp_set *out)
{
    frx_xp_set axis;
    int i, k, ok = 1;

    memset(&axis, 0, sizeof axis);
    for (i = 0; i < in->n && ok; i++) {
        axis.n = 0;
        ok = frx_xp_axis(e, step, &in->v[i], &axis);
        for (k = 0; ok && k < step->n_preds; k++)
            ok = frx_xp_filter_set(e, step->preds[k], &axis);
        for (k = 0; ok && k < axis.n; k++)
            if (!frx_xp_set_push(out, &axis.v[k])) ok = frx_xp_efail(e, "out of memory");
    }
    frx_xp_set_free(&axis);
    if (ok) frx_xp_set_sort(out);
    return ok;
}

static int
frx_xp_eval_path(frx_xeval *e, const frx_xn *path, const frx_xctx *c, frx_xp_val *out)
{
    frx_xp_set cur, next;
    int i, ok = 1;

    memset(&cur,  0, sizeof cur);
    memset(&next, 0, sizeof next);

    if (path->a) {
        frx_xp_val v;
        frx_xp_val_init(&v);
        if (!frx_xp_eval(e, path->a, c, &v)) { frx_xp_val_free(&v); return 0; }
        if (v.kind != FRX_XV_NODESET) {
            frx_xp_val_free(&v);
            return frx_xp_efail(e, "the left side of a path step is not a node-set");
        }
        cur = v.set;
        frx_buf_free(&v.str);
    } else if (path->absolute) {
        ok = frx_xp_set_push3(&cur, frx_xp_root_of(c->item.node), FRX_XP_KNODE, 0);
        if (!ok) (void)frx_xp_efail(e, "out of memory");
    } else {
        ok = frx_xp_set_push(&cur, &c->item);
        if (!ok) (void)frx_xp_efail(e, "out of memory");
    }

    for (i = 0; ok && i < path->n_steps; i++) {
        frx_xp_set tmp;
        next.n = 0;
        ok = frx_xp_step_over(e, path->steps[i], &cur, &next);
        tmp = cur; cur = next; next = tmp;
    }
    frx_xp_set_free(&next);
    if (!ok) { frx_xp_set_free(&cur); return 0; }
    out->kind = FRX_XV_NODESET;
    out->set  = cur;
    return 1;
}

/* ---- comparison, section 3.4 ------------------------------------------- */

static int
frx_xp_cmp_num(int op, double a, double b)
{
    switch (op) {
    case FRX_XN_EQ: return a == b;
    case FRX_XN_NE: return a != b;
    case FRX_XN_LT: return a <  b;
    case FRX_XN_LE: return a <= b;
    case FRX_XN_GT: return a >  b;
    default:        return a >= b;
    }
}

static int
frx_xp_set_str(frx_xeval *e, const frx_xp_set *s, int i, frx_buf *b)
{
    frx_xp_buf_reset(b);
    return frx_xp_item_string(e, &s->v[i], b);
}

static int
frx_xp_compare(frx_xeval *e, int op, const frx_xp_val *l, const frx_xp_val *r, int *res)
{
    int rel = op != FRX_XN_EQ && op != FRX_XN_NE;
    int i, j, ok = 1;
    frx_buf a, b;

    *res = 0;
    frx_buf_init(&a);
    frx_buf_init(&b);

    if (l->kind == FRX_XV_NODESET && r->kind == FRX_XV_NODESET) {
        for (i = 0; ok && !*res && i < l->set.n; i++) {
            if (!(ok = frx_xp_set_str(e, &l->set, i, &a))) break;
            for (j = 0; ok && !*res && j < r->set.n; j++) {
                if (!(ok = frx_xp_set_str(e, &r->set, j, &b))) break;
                if (rel) {
                    *res = frx_xp_cmp_num(op, frx_xp_str_num(a.p ? a.p : "", a.len),
                                              frx_xp_str_num(b.p ? b.p : "", b.len));
                } else {
                    int eq = a.len == b.len && (a.len == 0 || memcmp(a.p, b.p, a.len) == 0);
                    *res = op == FRX_XN_EQ ? eq : !eq;
                }
            }
        }
        goto done;
    }

    if (l->kind == FRX_XV_NODESET || r->kind == FRX_XV_NODESET) {
        const frx_xp_val *ns    = l->kind == FRX_XV_NODESET ? l : r;
        const frx_xp_val *other = l->kind == FRX_XV_NODESET ? r : l;
        int   flip = l->kind != FRX_XV_NODESET;   /* the node-set is on the right */
        int   effective = flip ? (op == FRX_XN_LT ? FRX_XN_GT : op == FRX_XN_GT ? FRX_XN_LT
                                : op == FRX_XN_LE ? FRX_XN_GE : op == FRX_XN_GE ? FRX_XN_LE : op)
                               : op;

        if (!rel && other->kind == FRX_XV_BOOLEAN) {
            int nb = ns->set.n > 0;
            *res = op == FRX_XN_EQ ? nb == (other->bl != 0) : nb != (other->bl != 0);
            goto done;
        }
        if (rel || other->kind == FRX_XV_NUMBER) {
            double x;
            if (!(ok = frx_xp_to_num(e, other, &x))) goto done;
            for (i = 0; ok && !*res && i < ns->set.n; i++) {
                if (!(ok = frx_xp_set_str(e, &ns->set, i, &a))) break;
                *res = frx_xp_cmp_num(effective, frx_xp_str_num(a.p ? a.p : "", a.len), x);
            }
            goto done;
        }
        if (!(ok = frx_xp_to_str(e, other, &b))) goto done;
        for (i = 0; ok && !*res && i < ns->set.n; i++) {
            int eq;
            if (!(ok = frx_xp_set_str(e, &ns->set, i, &a))) break;
            eq = a.len == b.len && (a.len == 0 || memcmp(a.p, b.p, a.len) == 0);
            *res = op == FRX_XN_EQ ? eq : !eq;
        }
        goto done;
    }

    if (rel) {
        double x, y;
        ok = frx_xp_to_num(e, l, &x) && frx_xp_to_num(e, r, &y);
        if (ok) *res = frx_xp_cmp_num(op, x, y);
        goto done;
    }
    if (l->kind == FRX_XV_BOOLEAN || r->kind == FRX_XV_BOOLEAN) {
        int x = frx_xp_to_bool(e, l), y = frx_xp_to_bool(e, r);
        *res = op == FRX_XN_EQ ? x == y : x != y;
        goto done;
    }
    if (l->kind == FRX_XV_NUMBER || r->kind == FRX_XV_NUMBER) {
        double x, y;
        ok = frx_xp_to_num(e, l, &x) && frx_xp_to_num(e, r, &y);
        if (ok) *res = frx_xp_cmp_num(op, x, y);
        goto done;
    }
    {
        int eq;
        ok = frx_xp_to_str(e, l, &a) && frx_xp_to_str(e, r, &b);
        eq = a.len == b.len && (a.len == 0 || memcmp(a.p, b.p, a.len) == 0);
        if (ok) *res = op == FRX_XN_EQ ? eq : !eq;
    }

done:
    frx_buf_free(&a);
    frx_buf_free(&b);
    return ok;
}

/* ---- the core function library, section 4 ------------------------------ */

/* The node-set an optional argument names, or a set of just the context
 * node. `one` is the caller's storage for that single entry, so the
 * borrowed set is never pushed to and never freed. */
static int
frx_xp_arg_set(frx_xeval *e, const frx_xn *n, const frx_xctx *c, frx_xp_val *tmp,
               const frx_xp_set **out, frx_xp_set *self, frx_xp_item *one)
{
    if (n->n_args == 0) {
        *one      = c->item;
        self->v   = one;
        self->n   = 1;
        self->cap = 0;
        *out = self;
        return 1;
    }
    if (!frx_xp_eval(e, n->args[0], c, tmp)) return 0;
    if (tmp->kind != FRX_XV_NODESET)
        return frx_xp_efail(e, "the argument must be a node-set");
    *out = &tmp->set;
    return 1;
}

/* the string an optional argument names, or the context node's */
static int
frx_xp_arg_str(frx_xeval *e, const frx_xn *n, const frx_xctx *c, int i, frx_buf *out)
{
    frx_xp_val v;
    int ok;
    if (i >= n->n_args) {
        frx_xp_buf_reset(out);
        return frx_xp_item_string(e, &c->item, out);
    }
    frx_xp_val_init(&v);
    ok = frx_xp_eval(e, n->args[i], c, &v) && frx_xp_to_str(e, &v, out);
    frx_xp_val_free(&v);
    return ok;
}

static int
frx_xp_arg_num(frx_xeval *e, const frx_xn *n, const frx_xctx *c, int i, double *out)
{
    frx_xp_val v;
    int ok;
    if (i >= n->n_args) {
        frx_buf b;
        frx_buf_init(&b);
        ok = frx_xp_item_string(e, &c->item, &b);
        *out = ok ? frx_xp_str_num(b.p ? b.p : "", b.len) : frx_xp_nan();
        frx_buf_free(&b);
        return ok;
    }
    frx_xp_val_init(&v);
    ok = frx_xp_eval(e, n->args[i], c, &v) && frx_xp_to_num(e, &v, out);
    frx_xp_val_free(&v);
    return ok;
}

static void
frx_xp_normalize_space(frx_buf *out, const char *p, size_t n)
{
    size_t i = 0, run;
    int wrote = 0;
    while (i < n) {
        while (i < n && frx_is_s((unsigned char)p[i])) i++;
        run = i;
        while (i < n && !frx_is_s((unsigned char)p[i])) i++;
        if (i > run) {
            if (wrote) frx_buf_append_ch(out, ' ');
            frx_buf_append_n(out, p + run, i - run);
            wrote = 1;
        }
    }
}

/* translate(), by character: a character of `from` maps to the character
 * of `to` at the same position, and to nothing when `to` is shorter */
static void
frx_xp_translate(frx_buf *out, const char *s, size_t sn,
                 const char *f, size_t fn, const char *t, size_t tn)
{
    size_t at = 0;
    unsigned long cp;
    while (at < sn) {
        size_t k = frx_utf8_decode((const unsigned char *)s + at, sn - at, &cp);
        size_t fa = 0, ti = 0, hit = 0;
        if (!k) k = 1;
        while (fa < fn) {
            unsigned long fc;
            size_t fk = frx_utf8_decode((const unsigned char *)f + fa, fn - fa, &fc);
            if (!fk) fk = 1;
            if (fk == k && memcmp(f + fa, s + at, k) == 0) { hit = 1; break; }
            fa += fk;
            ti++;
        }
        if (!hit) {
            frx_buf_append_n(out, s + at, k);
        } else {
            size_t ta = 0, seen = 0;
            while (ta < tn && seen < ti) {
                unsigned long tc;
                size_t tk = frx_utf8_decode((const unsigned char *)t + ta, tn - ta, &tc);
                if (!tk) tk = 1;
                ta += tk;
                seen++;
            }
            if (ta < tn) {
                unsigned long tc;
                size_t tk = frx_utf8_decode((const unsigned char *)t + ta, tn - ta, &tc);
                if (!tk) tk = 1;
                frx_buf_append_n(out, t + ta, tk);
            }
        }
        at += k;
    }
}

/* the characters of s whose 1-based position p satisfies lo <= p < hi; a
 * NaN bound excludes everything, which is what section 4.2's examples
 * with `0 div 0` require */
static void
frx_xp_substring(frx_buf *out, const char *s, size_t n, double lo, double hi)
{
    size_t at = 0;
    double pos = 1.0;
    unsigned long cp;
    while (at < n) {
        size_t k = frx_utf8_decode((const unsigned char *)s + at, n - at, &cp);
        if (!k) k = 1;
        if (pos >= lo && pos < hi) frx_buf_append_n(out, s + at, k);
        at += k;
        pos += 1.0;
    }
}

/* the element carrying the nearest xml:lang above (and at) the item */
static const frx_str *
frx_xp_lang_of(const frx_xp_item *it)
{
    const frx_node *n = it->node;
    for (; n; n = n->parent) {
        if (n->kind != FRX_ELEMENT) continue;
        {
            const frx_str *v = frx_attr_value(n, FRX_XML_NS, "lang");
            if (v) return v;
        }
    }
    return NULL;
}

static int
frx_xp_ascii_lower(int c)
{
    return c >= 'A' && c <= 'Z' ? c + 32 : c;
}

static int
frx_xp_lang_match(const frx_str *have, const char *want, size_t wn)
{
    size_t i;
    if (have->len < wn) return 0;
    for (i = 0; i < wn; i++)
        if (frx_xp_ascii_lower((unsigned char)have->p[i]) != frx_xp_ascii_lower((unsigned char)want[i]))
            return 0;
    return have->len == wn || have->p[wn] == '-';
}

/* id(): every whitespace-separated token looked up in the document's ID
 * index, over every attribute name the index was built from */
static int
frx_xp_id_lookup(frx_xeval *e, const char *p, size_t n, frx_xp_set *out)
{
    size_t i = 0;
    while (i < n) {
        size_t start;
        while (i < n && frx_is_s((unsigned char)p[i])) i++;
        start = i;
        while (i < n && !frx_is_s((unsigned char)p[i])) i++;
        if (i > start) {
            const frx_node *best = NULL;
            int k;
            for (k = 0; k < e->doc->n_id_attrs; k++) {
                const frx_node *hit = frx_by_id(e->doc, e->doc->id_attrs[k].p,
                                                p + start, i - start);
                if (hit && (!best || hit->order < best->order)) best = hit;
            }
            if (best && !frx_xp_set_push3(out, best, FRX_XP_KNODE, 0))
                return frx_xp_efail(e, "out of memory");
        }
    }
    return 1;
}

static int
frx_xp_func(frx_xeval *e, const frx_xn *n, const frx_xctx *c, frx_xp_val *out)
{
    frx_xp_val a0;
    frx_buf    s0, s1, s2;
    int        ok = 1;

    switch (n->func) {
    case FRX_FN_LAST:
        out->kind = FRX_XV_NUMBER;
        out->num  = (double)c->size;
        return 1;
    case FRX_FN_POSITION:
        out->kind = FRX_XV_NUMBER;
        out->num  = (double)c->position;
        return 1;
    case FRX_FN_TRUE:
    case FRX_FN_FALSE:
        out->kind = FRX_XV_BOOLEAN;
        out->bl   = n->func == FRX_FN_TRUE;
        return 1;
    default:
        break;
    }

    switch (n->func) {
    case FRX_FN_COUNT:
    case FRX_FN_SUM: {
        const frx_xp_set *set;
        frx_xp_val_init(&a0);
        if (!frx_xp_eval(e, n->args[0], c, &a0)) { frx_xp_val_free(&a0); return 0; }
        if (a0.kind != FRX_XV_NODESET) {
            frx_xp_val_free(&a0);
            return frx_xp_efail(e, "count() and sum() take a node-set");
        }
        set = &a0.set;
        out->kind = FRX_XV_NUMBER;
        if (n->func == FRX_FN_COUNT) {
            out->num = (double)set->n;
        } else {
            double total = 0.0;
            int i;
            frx_buf_init(&s0);
            for (i = 0; i < set->n; i++) {
                if (!(ok = frx_xp_set_str(e, set, i, &s0))) break;
                total += frx_xp_str_num(s0.p ? s0.p : "", s0.len);
            }
            frx_buf_free(&s0);
            out->num = total;
        }
        frx_xp_val_free(&a0);
        return ok;
    }

    case FRX_FN_ID: {
        frx_xp_val_init(&a0);
        if (!frx_xp_eval(e, n->args[0], c, &a0)) { frx_xp_val_free(&a0); return 0; }
        out->kind = FRX_XV_NODESET;
        frx_buf_init(&s0);
        if (a0.kind == FRX_XV_NODESET) {
            int i;
            for (i = 0; ok && i < a0.set.n; i++)
                ok = frx_xp_set_str(e, &a0.set, i, &s0)
                  && frx_xp_id_lookup(e, s0.p ? s0.p : "", s0.len, &out->set);
        } else {
            ok = frx_xp_to_str(e, &a0, &s0)
              && frx_xp_id_lookup(e, s0.p ? s0.p : "", s0.len, &out->set);
        }
        frx_buf_free(&s0);
        frx_xp_val_free(&a0);
        if (ok) frx_xp_set_sort(&out->set);
        return ok;
    }

    case FRX_FN_LOCAL_NAME:
    case FRX_FN_NAMESPACE_URI:
    case FRX_FN_NAME: {
        const frx_xp_set *set;
        frx_xp_set  self;
        frx_xp_item one;
        frx_xp_val_init(&a0);
        memset(&self, 0, sizeof self);
        if (!frx_xp_arg_set(e, n, c, &a0, &set, &self, &one)) { frx_xp_val_free(&a0); return 0; }
        out->kind = FRX_XV_STRING;
        if (set->n)
            ok = frx_xp_item_name(e, &set->v[0],
                                  n->func == FRX_FN_LOCAL_NAME ? 0
                                : n->func == FRX_FN_NAMESPACE_URI ? 1 : 2,
                                  &out->str);
        frx_xp_val_free(&a0);
        return ok;
    }

    case FRX_FN_STRING:
        out->kind = FRX_XV_STRING;
        return frx_xp_arg_str(e, n, c, 0, &out->str);

    case FRX_FN_CONCAT: {
        int i;
        out->kind = FRX_XV_STRING;
        frx_buf_init(&s0);
        for (i = 0; ok && i < n->n_args; i++) {
            frx_xp_val_init(&a0);
            ok = frx_xp_eval(e, n->args[i], c, &a0) && frx_xp_to_str(e, &a0, &s0);
            if (ok) frx_buf_append_n(&out->str, s0.p ? s0.p : "", s0.len);
            frx_xp_val_free(&a0);
        }
        frx_buf_free(&s0);
        return ok;
    }

    case FRX_FN_STARTS_WITH:
    case FRX_FN_CONTAINS:
    case FRX_FN_SUBSTRING_BEFORE:
    case FRX_FN_SUBSTRING_AFTER: {
        /* an frx_buf that never had to grow has a NULL p, which the empty
         * string reaches here as; the base of the search must not be it */
        const char *sp, *fp;
        size_t      at = 0;
        int         found = 0;
        frx_buf_init(&s0);
        frx_buf_init(&s1);
        ok = frx_xp_arg_str(e, n, c, 0, &s0) && frx_xp_arg_str(e, n, c, 1, &s1);
        sp = s0.p ? s0.p : "";
        fp = s1.p ? s1.p : "";
        if (ok && s1.len <= s0.len) {
            size_t last = s0.len - s1.len;
            for (at = 0; ; at++) {
                if (s1.len == 0 || memcmp(sp + at, fp, s1.len) == 0) { found = 1; break; }
                if (at == last) break;
            }
        }
        if (ok && n->func == FRX_FN_STARTS_WITH) {
            out->kind = FRX_XV_BOOLEAN;
            out->bl   = found && at == 0;
        } else if (ok && n->func == FRX_FN_CONTAINS) {
            out->kind = FRX_XV_BOOLEAN;
            out->bl   = found;
        } else if (ok) {
            out->kind = FRX_XV_STRING;
            if (found) {
                if (n->func == FRX_FN_SUBSTRING_BEFORE)
                    frx_buf_append_n(&out->str, sp, at);
                else
                    frx_buf_append_n(&out->str, sp + at + s1.len, s0.len - at - s1.len);
            }
        }
        frx_buf_free(&s0);
        frx_buf_free(&s1);
        return ok;
    }

    case FRX_FN_SUBSTRING: {
        double start = 0.0, len = 0.0, lo, hi;
        frx_buf_init(&s0);
        ok = frx_xp_arg_str(e, n, c, 0, &s0) && frx_xp_arg_num(e, n, c, 1, &start);
        if (ok && n->n_args > 2) ok = frx_xp_arg_num(e, n, c, 2, &len);
        if (ok) {
            lo = frx_xp_round(start);
            hi = n->n_args > 2 ? lo + frx_xp_round(len) : DBL_MAX;
            out->kind = FRX_XV_STRING;
            frx_xp_substring(&out->str, s0.p ? s0.p : "", s0.len, lo, hi);
        }
        frx_buf_free(&s0);
        return ok;
    }

    case FRX_FN_STRING_LENGTH:
        frx_buf_init(&s0);
        ok = frx_xp_arg_str(e, n, c, 0, &s0);
        out->kind = FRX_XV_NUMBER;
        if (ok) out->num = (double)frx_xp_nchars(s0.p ? s0.p : "", s0.len);
        frx_buf_free(&s0);
        return ok;

    case FRX_FN_NORMALIZE_SPACE:
        frx_buf_init(&s0);
        ok = frx_xp_arg_str(e, n, c, 0, &s0);
        out->kind = FRX_XV_STRING;
        if (ok) frx_xp_normalize_space(&out->str, s0.p ? s0.p : "", s0.len);
        frx_buf_free(&s0);
        return ok;

    case FRX_FN_TRANSLATE:
        frx_buf_init(&s0);
        frx_buf_init(&s1);
        frx_buf_init(&s2);
        ok = frx_xp_arg_str(e, n, c, 0, &s0)
          && frx_xp_arg_str(e, n, c, 1, &s1)
          && frx_xp_arg_str(e, n, c, 2, &s2);
        out->kind = FRX_XV_STRING;
        if (ok) frx_xp_translate(&out->str, s0.p ? s0.p : "", s0.len,
                                 s1.p ? s1.p : "", s1.len, s2.p ? s2.p : "", s2.len);
        frx_buf_free(&s0);
        frx_buf_free(&s1);
        frx_buf_free(&s2);
        return ok;

    case FRX_FN_BOOLEAN:
    case FRX_FN_NOT:
        frx_xp_val_init(&a0);
        ok = frx_xp_eval(e, n->args[0], c, &a0);
        out->kind = FRX_XV_BOOLEAN;
        if (ok) {
            int b = frx_xp_to_bool(e, &a0);
            out->bl = n->func == FRX_FN_NOT ? !b : b;
        }
        frx_xp_val_free(&a0);
        return ok;

    case FRX_FN_LANG: {
        const frx_str *have;
        frx_buf_init(&s0);
        ok = frx_xp_arg_str(e, n, c, 0, &s0);
        out->kind = FRX_XV_BOOLEAN;
        have = frx_xp_lang_of(&c->item);
        if (ok && have) out->bl = frx_xp_lang_match(have, s0.p ? s0.p : "", s0.len);
        frx_buf_free(&s0);
        return ok;
    }

    case FRX_FN_NUMBER:
        out->kind = FRX_XV_NUMBER;
        return frx_xp_arg_num(e, n, c, 0, &out->num);

    case FRX_FN_FLOOR:
    case FRX_FN_CEILING:
    case FRX_FN_ROUND: {
        double v = 0.0;
        ok = frx_xp_arg_num(e, n, c, 0, &v);
        out->kind = FRX_XV_NUMBER;
        if (ok) {
            if (frx_xp_is_nan(v) || frx_xp_is_inf(v) || v == 0.0) out->num = v;
            else if (n->func == FRX_FN_FLOOR)   out->num = floor(v);
            else if (n->func == FRX_FN_CEILING) out->num = ceil(v);
            else                                out->num = frx_xp_round(v);
        }
        return ok;
    }

    default:
        return frx_xp_efail(e, "unknown function");
    }
}

/* ---- the evaluator ----------------------------------------------------- */

static int
frx_xp_eval(frx_xeval *e, const frx_xn *n, const frx_xctx *c, frx_xp_val *out)
{
    frx_xp_val l, r;
    int ok;

    if (e->failed) return 0;

    switch (n->kind) {
    case FRX_XN_PATH:
        return frx_xp_eval_path(e, n, c, out);

    case FRX_XN_STEP: {
        frx_xn path;
        frx_xn *steps[1];
        memset(&path, 0, sizeof path);
        path.kind    = FRX_XN_PATH;
        steps[0]     = (frx_xn *)n;
        path.steps   = steps;
        path.n_steps = 1;
        return frx_xp_eval_path(e, &path, c, out);
    }

    case FRX_XN_LITERAL:
        out->kind = FRX_XV_STRING;
        frx_buf_append_n(&out->str, n->str.p, n->str.len);
        return out->str.failed ? frx_xp_efail(e, "out of memory") : 1;

    case FRX_XN_NUMBER:
        out->kind = FRX_XV_NUMBER;
        out->num  = n->num;
        return 1;

    case FRX_XN_VAR: {
        const frx_xp_val *v;
        if (n->var < 0 || n->var >= e->n_vars)
            return frx_xp_efail(e, "the expression uses a variable that was not given a value");
        v = &e->vars[n->var].val;
        out->kind = v->kind;
        out->bl   = v->bl;
        out->num  = v->num;
        if (v->kind == FRX_XV_STRING)
            frx_buf_append_n(&out->str, v->str.p ? v->str.p : "", v->str.len);
        return out->str.failed ? frx_xp_efail(e, "out of memory") : 1;
    }

    case FRX_XN_FUNC:
        return frx_xp_func(e, n, c, out);

    case FRX_XN_FILTER: {
        int i;
        if (!frx_xp_eval(e, n->a, c, out)) return 0;
        if (!n->n_preds) return 1;
        if (out->kind != FRX_XV_NODESET)
            return frx_xp_efail(e, "a predicate can only filter a node-set");
        for (i = 0; i < n->n_preds; i++)
            if (!frx_xp_filter_set(e, n->preds[i], &out->set)) return 0;
        return 1;
    }

    case FRX_XN_UNION: {
        int i;
        frx_xp_val_init(&l);
        frx_xp_val_init(&r);
        ok = frx_xp_eval(e, n->a, c, &l) && frx_xp_eval(e, n->b, c, &r);
        if (ok && (l.kind != FRX_XV_NODESET || r.kind != FRX_XV_NODESET))
            ok = frx_xp_efail(e, "'|' joins two node-sets and nothing else");
        if (ok) {
            out->kind = FRX_XV_NODESET;
            for (i = 0; ok && i < l.set.n; i++)
                if (!frx_xp_set_push(&out->set, &l.set.v[i])) ok = frx_xp_efail(e, "out of memory");
            for (i = 0; ok && i < r.set.n; i++)
                if (!frx_xp_set_push(&out->set, &r.set.v[i])) ok = frx_xp_efail(e, "out of memory");
            if (ok) frx_xp_set_sort(&out->set);
        }
        frx_xp_val_free(&l);
        frx_xp_val_free(&r);
        return ok;
    }

    case FRX_XN_OR:
    case FRX_XN_AND: {
        int b;
        frx_xp_val_init(&l);
        if (!frx_xp_eval(e, n->a, c, &l)) { frx_xp_val_free(&l); return 0; }
        b = frx_xp_to_bool(e, &l);
        frx_xp_val_free(&l);
        out->kind = FRX_XV_BOOLEAN;
        /* both operators short-circuit: section 3.4 says the right side is
         * not evaluated when the left settles it */
        if ((n->kind == FRX_XN_OR && b) || (n->kind == FRX_XN_AND && !b)) {
            out->bl = b;
            return 1;
        }
        frx_xp_val_init(&r);
        if (!frx_xp_eval(e, n->b, c, &r)) { frx_xp_val_free(&r); return 0; }
        out->bl = frx_xp_to_bool(e, &r);
        frx_xp_val_free(&r);
        return 1;
    }

    case FRX_XN_NEG: {
        double v;
        frx_xp_val_init(&l);
        ok = frx_xp_eval(e, n->a, c, &l) && frx_xp_to_num(e, &l, &v);
        frx_xp_val_free(&l);
        out->kind = FRX_XV_NUMBER;
        if (ok) out->num = -v;
        return ok;
    }

    case FRX_XN_EQ: case FRX_XN_NE: case FRX_XN_LT:
    case FRX_XN_LE: case FRX_XN_GT: case FRX_XN_GE: {
        int res = 0;
        frx_xp_val_init(&l);
        frx_xp_val_init(&r);
        ok = frx_xp_eval(e, n->a, c, &l) && frx_xp_eval(e, n->b, c, &r)
          && frx_xp_compare(e, n->kind, &l, &r, &res);
        frx_xp_val_free(&l);
        frx_xp_val_free(&r);
        out->kind = FRX_XV_BOOLEAN;
        out->bl   = res;
        return ok;
    }

    default: {
        double x = 0.0, y = 0.0;
        frx_xp_val_init(&l);
        frx_xp_val_init(&r);
        ok = frx_xp_eval(e, n->a, c, &l) && frx_xp_eval(e, n->b, c, &r)
          && frx_xp_to_num(e, &l, &x) && frx_xp_to_num(e, &r, &y);
        frx_xp_val_free(&l);
        frx_xp_val_free(&r);
        out->kind = FRX_XV_NUMBER;
        if (!ok) return 0;
        switch (n->kind) {
        case FRX_XN_ADD: out->num = x + y; break;
        case FRX_XN_SUB: out->num = x - y; break;
        case FRX_XN_MUL: out->num = x * y; break;
        /* IEEE gives what section 3.5 asks for on its own: a division by
         * zero is an infinity with the sign of the operands, 0 div 0 is
         * NaN, and mod by zero is NaN through fmod */
        case FRX_XN_DIV: out->num = x / y;      break;
        default:         out->num = fmod(x, y); break;
        }
        return 1;
    }
    }
}

#endif /* FRX_XPATH_EVAL_H */
