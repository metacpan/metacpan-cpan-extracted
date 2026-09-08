#ifndef FRX_XPATH_PARSE_H
#define FRX_XPATH_PARSE_H

/* The XPath 1.0 grammar, section 3, to an AST in the expression's arena.
 *
 * Recursive descent. Recursion over the expression is allowed, unlike
 * recursion over a document (rule 2), because the expression's depth is
 * the caller's own text and not an attacker's input; `max_expr_depth`
 * (default 64) bounds it here so the evaluator, which recurses over the
 * same AST, inherits the same bound.
 *
 * Every string an AST node holds is copied into the arena, so a compiled
 * expression outlives the bytes it was compiled from and is independent
 * of any document.
 *
 * NAME RESOLUTION IS AT COMPILE. A prefix in a name test is looked up in
 * the caller's map and stored as a URI; an unmapped prefix is a compile
 * error. There is no mode that reads the document's own declarations,
 * which would make an expression's meaning depend on where it is
 * evaluated. An unprefixed name test resolves to no namespace, which is
 * XPath 1.0 section 2.3: a QName without a prefix expands to a null
 * namespace URI, never to the default one.
 *
 * The abbreviations of section 2.5 are expanded here and nowhere else:
 * `//` becomes `/descendant-or-self::node()/`, `.` becomes `self::node()`,
 * `..` becomes `parent::node()`, and `@x` becomes `attribute::x`. That is
 * why `//a[1]` is not the first `a` in the document: the predicate belongs
 * to the `child::a` step, whose proximity position is among one parent's
 * children.
 *
 * Needs frx_arena.h, frx_utf8.h, frx_tree.h, frx_xpath_lex.h. */

#define FRX_XP_MAX_EXPR_DEPTH 64

/* frx_ns_binding and frx_ns_map are frx_abi.h's: a consumer compiles an
 * expression under one, so their shape is public. */

/* axes, section 2.2 */
enum {
    FRX_AX_CHILD = 0, FRX_AX_DESCENDANT, FRX_AX_PARENT, FRX_AX_ANCESTOR,
    FRX_AX_FOLLOWING_SIBLING, FRX_AX_PRECEDING_SIBLING, FRX_AX_FOLLOWING,
    FRX_AX_PRECEDING, FRX_AX_ATTRIBUTE, FRX_AX_NAMESPACE, FRX_AX_SELF,
    FRX_AX_DESCENDANT_OR_SELF, FRX_AX_ANCESTOR_OR_SELF
};

/* node tests, section 2.3 */
enum {
    FRX_XTEST_NAME = 0,   /* ns + local          */
    FRX_XTEST_STAR,       /* *                   */
    FRX_XTEST_NSSTAR,     /* prefix:*  (ns only) */
    FRX_XTEST_NODE,       /* node()              */
    FRX_XTEST_TEXT,       /* text()              */
    FRX_XTEST_COMMENT,    /* comment()           */
    FRX_XTEST_PI          /* processing-instruction(target?) */
};

/* the 27 core functions of section 4 */
enum {
    FRX_FN_LAST = 1, FRX_FN_POSITION, FRX_FN_COUNT, FRX_FN_ID,
    FRX_FN_LOCAL_NAME, FRX_FN_NAMESPACE_URI, FRX_FN_NAME,
    FRX_FN_STRING, FRX_FN_CONCAT, FRX_FN_STARTS_WITH, FRX_FN_CONTAINS,
    FRX_FN_SUBSTRING_BEFORE, FRX_FN_SUBSTRING_AFTER, FRX_FN_SUBSTRING,
    FRX_FN_STRING_LENGTH, FRX_FN_NORMALIZE_SPACE, FRX_FN_TRANSLATE,
    FRX_FN_BOOLEAN, FRX_FN_NOT, FRX_FN_TRUE, FRX_FN_FALSE, FRX_FN_LANG,
    FRX_FN_NUMBER, FRX_FN_SUM, FRX_FN_FLOOR, FRX_FN_CEILING, FRX_FN_ROUND
};

/* AST node kinds */
enum {
    FRX_XN_OR = 1, FRX_XN_AND,
    FRX_XN_EQ, FRX_XN_NE, FRX_XN_LT, FRX_XN_LE, FRX_XN_GT, FRX_XN_GE,
    FRX_XN_ADD, FRX_XN_SUB, FRX_XN_MUL, FRX_XN_DIV, FRX_XN_MOD,
    FRX_XN_UNION, FRX_XN_NEG,
    FRX_XN_PATH, FRX_XN_STEP,
    FRX_XN_LITERAL, FRX_XN_NUMBER, FRX_XN_VAR, FRX_XN_FUNC, FRX_XN_FILTER
};

typedef struct frx_xn frx_xn;
struct frx_xn {
    int       kind;
    frx_xn   *a, *b;         /* operands; FILTER's primary; PATH's leading filter */
    int       axis;          /* STEP */
    int       test;          /* STEP */
    frx_str   ns, local;     /* STEP: the resolved name test */
    frx_xn  **preds;         /* STEP, FILTER */
    int       n_preds;
    frx_xn  **steps;         /* PATH */
    int       n_steps;
    int       absolute;      /* PATH: begins at the root */
    frx_str   str;           /* LITERAL, VAR's name, PI target */
    double    num;           /* NUMBER */
    int       func;          /* FUNC */
    int       var;           /* VAR: index into the expression's variables */
    frx_xn  **args;          /* FUNC */
    int       n_args;
    int       d;             /* this subtree's depth, capped at max_expr_depth */
};

/* what the parser collects beside the AST: every variable named, once,
 * so the compiled expression can carry one value per name */
typedef struct frx_xvars {
    frx_str *name;
    int      n, cap;
} frx_xvars;

typedef struct frx_xparse {
    const frx_xtok   *t;
    int               n, i;
    frx_arena        *arena;
    const frx_ns_map *ns;
    frx_xvars        *vars;
    int               depth, max_depth;
    const char       *err;
    size_t            err_at;
} frx_xparse;

static frx_xn *frx_xp_expr(frx_xparse *p);

static void *
frx_xp_fail(frx_xparse *p, const char *what)
{
    if (!p->err) {
        p->err    = what;
        p->err_at = p->i < p->n ? p->t[p->i].offset : 0;
    }
    return NULL;
}

static const frx_xtok *
frx_xp_peek(const frx_xparse *p, int ahead)
{
    int k = p->i + ahead;
    return k < p->n ? &p->t[k] : &p->t[p->n - 1];   /* the EOF token */
}

static int
frx_xp_at(const frx_xparse *p, int kind)
{
    return frx_xp_peek(p, 0)->kind == kind;
}

static int
frx_xp_eat(frx_xparse *p, int kind)
{
    if (!frx_xp_at(p, kind)) return 0;
    p->i++;
    return 1;
}

static frx_xn *
frx_xp_new(frx_xparse *p, int kind)
{
    frx_xn *n = (frx_xn *)frx_arena_alloc(p->arena, sizeof *n);
    if (!n) return (frx_xn *)frx_xp_fail(p, "out of memory");
    memset(n, 0, sizeof *n);
    n->kind  = kind;
    n->d     = 1;
    n->ns    = n->local = n->str = FRX_EMPTY_STR;
    return n;
}

/* The AST's own depth, which is what the evaluator recurses down and is
 * not the same as the parser's. `a and b and c and ...` is one loop here
 * and a left-leaning chain there, so counting productions alone would let
 * a long chain of associative operators reach a stack the parser never
 * touched. Every composite node passes through this on the way out. */
static frx_xn *
frx_xp_depth_ok(frx_xparse *p, frx_xn *n)
{
    int i, d = 0;
    if (!n) return NULL;
    if (n->a && n->a->d > d) d = n->a->d;
    if (n->b && n->b->d > d) d = n->b->d;
    for (i = 0; i < n->n_preds; i++) if (n->preds[i]->d > d) d = n->preds[i]->d;
    for (i = 0; i < n->n_args;  i++) if (n->args[i]->d  > d) d = n->args[i]->d;
    for (i = 0; i < n->n_steps; i++) if (n->steps[i]->d > d) d = n->steps[i]->d;
    n->d = d + 1;
    if (n->d > p->max_depth)
        return (frx_xn *)frx_xp_fail(p, "the expression nests deeper than max_expr_depth");
    return n;
}

/* a growable array of frx_xn * in the arena: the arena never reallocates,
 * so growth allocates a new block and the old one is simply left behind.
 * Every list here is a handful of entries. */
static int
frx_xp_push(frx_xparse *p, frx_xn ***v, int *n, int *cap, frx_xn *item)
{
    if (!item) return 0;
    if (*n == *cap) {
        int ncap = *cap ? *cap * 2 : 4;
        frx_xn **nv = (frx_xn **)frx_arena_alloc(p->arena, (size_t)ncap * sizeof *nv);
        if (!nv) { (void)frx_xp_fail(p, "out of memory"); return 0; }
        if (*n) memcpy(nv, *v, (size_t)*n * sizeof *nv);
        *v   = nv;
        *cap = ncap;
    }
    (*v)[(*n)++] = item;
    return 1;
}

static frx_str
frx_xp_dup(frx_xparse *p, const frx_str *s)
{
    frx_str out = frx_arena_strndup(p->arena, s->p ? s->p : "", s->len);
    if (!out.p) (void)frx_xp_fail(p, "out of memory");
    return out;
}

/* the URI the caller's map binds to prefix; NULL when it binds none */
static const char *
frx_xp_ns_uri(const frx_ns_map *m, const char *prefix, size_t plen)
{
    int i;
    if (plen == 3 && memcmp(prefix, "xml", 3) == 0) return FRX_XML_NS;
    if (!m) return NULL;
    for (i = 0; i < m->n; i++) {
        const char *k = m->v[i].prefix ? m->v[i].prefix : "";
        if (strlen(k) == plen && (plen == 0 || memcmp(k, prefix, plen) == 0))
            return m->v[i].uri ? m->v[i].uri : "";
    }
    return NULL;
}

static int
frx_xp_axis_by_name(const frx_str *s)
{
    static const struct { const char *n; int a; } A[] = {
        { "ancestor",           FRX_AX_ANCESTOR },
        { "ancestor-or-self",   FRX_AX_ANCESTOR_OR_SELF },
        { "attribute",          FRX_AX_ATTRIBUTE },
        { "child",              FRX_AX_CHILD },
        { "descendant",         FRX_AX_DESCENDANT },
        { "descendant-or-self", FRX_AX_DESCENDANT_OR_SELF },
        { "following",          FRX_AX_FOLLOWING },
        { "following-sibling",  FRX_AX_FOLLOWING_SIBLING },
        { "namespace",          FRX_AX_NAMESPACE },
        { "parent",             FRX_AX_PARENT },
        { "preceding",          FRX_AX_PRECEDING },
        { "preceding-sibling",  FRX_AX_PRECEDING_SIBLING },
        { "self",               FRX_AX_SELF }
    };
    size_t i;
    for (i = 0; i < sizeof A / sizeof A[0]; i++)
        if (frx_str_eq(s, A[i].n, strlen(A[i].n))) return A[i].a;
    return -1;
}

/* a NodeType name, or 0 */
static int
frx_xp_nodetype(const frx_str *s)
{
    if (frx_str_eq(s, "node", 4))                   return FRX_XTEST_NODE;
    if (frx_str_eq(s, "text", 4))                   return FRX_XTEST_TEXT;
    if (frx_str_eq(s, "comment", 7))                return FRX_XTEST_COMMENT;
    if (frx_str_eq(s, "processing-instruction", 22)) return FRX_XTEST_PI;
    return 0;
}

typedef struct frx_xp_fn { const char *n; int id; int min; int max; } frx_xp_fn;

static const frx_xp_fn *
frx_xp_func_by_name(const frx_str *s)
{
    static const frx_xp_fn F[] = {
        { "last",              FRX_FN_LAST,             0,  0 },
        { "position",          FRX_FN_POSITION,         0,  0 },
        { "count",             FRX_FN_COUNT,            1,  1 },
        { "id",                FRX_FN_ID,               1,  1 },
        { "local-name",        FRX_FN_LOCAL_NAME,       0,  1 },
        { "namespace-uri",     FRX_FN_NAMESPACE_URI,    0,  1 },
        { "name",              FRX_FN_NAME,             0,  1 },
        { "string",            FRX_FN_STRING,           0,  1 },
        { "concat",            FRX_FN_CONCAT,           2, -1 },
        { "starts-with",       FRX_FN_STARTS_WITH,      2,  2 },
        { "contains",          FRX_FN_CONTAINS,         2,  2 },
        { "substring-before",  FRX_FN_SUBSTRING_BEFORE, 2,  2 },
        { "substring-after",   FRX_FN_SUBSTRING_AFTER,  2,  2 },
        { "substring",         FRX_FN_SUBSTRING,        2,  3 },
        { "string-length",     FRX_FN_STRING_LENGTH,    0,  1 },
        { "normalize-space",   FRX_FN_NORMALIZE_SPACE,  0,  1 },
        { "translate",         FRX_FN_TRANSLATE,        3,  3 },
        { "boolean",           FRX_FN_BOOLEAN,          1,  1 },
        { "not",               FRX_FN_NOT,              1,  1 },
        { "true",              FRX_FN_TRUE,             0,  0 },
        { "false",             FRX_FN_FALSE,            0,  0 },
        { "lang",              FRX_FN_LANG,             1,  1 },
        { "number",            FRX_FN_NUMBER,           0,  1 },
        { "sum",               FRX_FN_SUM,              1,  1 },
        { "floor",             FRX_FN_FLOOR,            1,  1 },
        { "ceiling",           FRX_FN_CEILING,          1,  1 },
        { "round",             FRX_FN_ROUND,            1,  1 }
    };
    size_t i;
    for (i = 0; i < sizeof F / sizeof F[0]; i++)
        if (frx_str_eq(s, F[i].n, strlen(F[i].n))) return &F[i];
    return NULL;
}

/* the index of name in the expression's variable list, adding it once */
static int
frx_xp_var_index(frx_xparse *p, const frx_str *name)
{
    frx_xvars *vs = p->vars;
    int i;
    for (i = 0; i < vs->n; i++)
        if (frx_str_eq2(&vs->name[i], name)) return i;
    if (vs->n == vs->cap) {
        int ncap = vs->cap ? vs->cap * 2 : 8;
        frx_str *nn = (frx_str *)realloc(vs->name, (size_t)ncap * sizeof *nn);
        if (!nn) { (void)frx_xp_fail(p, "out of memory"); return -1; }
        vs->name = nn;
        vs->cap  = ncap;
    }
    vs->name[vs->n] = frx_xp_dup(p, name);
    if (!vs->name[vs->n].p) return -1;
    return vs->n++;
}

/* ---- the productions --------------------------------------------------- */

/* NodeTest, with the axis already known: the principal node type decides
 * what a name test matches, and that is the evaluator's business */
static int
frx_xp_node_test(frx_xparse *p, frx_xn *step)
{
    const frx_xtok *t = frx_xp_peek(p, 0);

    if (t->kind == FRX_XT_NAME && frx_xp_peek(p, 1)->kind == FRX_XT_LPAREN) {
        int nt = frx_xp_nodetype(&t->s);
        if (nt) {
            p->i += 2;
            step->test = nt;
            if (nt == FRX_XTEST_PI && frx_xp_at(p, FRX_XT_LITERAL)) {
                step->str = frx_xp_dup(p, &frx_xp_peek(p, 0)->s);
                if (!step->str.p) return 0;
                p->i++;
            }
            if (!frx_xp_eat(p, FRX_XT_RPAREN))
                return frx_xp_fail(p, "a node type takes no argument but processing-instruction's target") != NULL;
            return 1;
        }
    }
    if (t->kind != FRX_XT_NAME)
        return frx_xp_fail(p, "a node test was expected") != NULL;
    p->i++;
    {
        const char *colon = (const char *)memchr(t->s.p, ':', t->s.len);
        frx_str prefix, local;
        if (!colon) {
            if (t->s.len == 1 && t->s.p[0] == '*') { step->test = FRX_XTEST_STAR; return 1; }
            step->test  = FRX_XTEST_NAME;
            step->ns    = FRX_EMPTY_STR;         /* never the default namespace */
            step->local = frx_xp_dup(p, &t->s);
            return step->local.p != NULL;
        }
        prefix.p   = t->s.p;
        prefix.len = (size_t)(colon - t->s.p);
        local.p    = colon + 1;
        local.len  = t->s.len - prefix.len - 1;
        {
            const char *uri = frx_xp_ns_uri(p->ns, prefix.p, prefix.len);
            frx_str u;
            if (!uri) {
                p->i--;                          /* report at the name */
                return frx_xp_fail(p, "the prefix of a name test is not in the expression's namespace map") != NULL;
            }
            u.p   = uri;
            u.len = strlen(uri);
            step->ns = frx_xp_dup(p, &u);
            if (!step->ns.p) return 0;
        }
        if (local.len == 1 && local.p[0] == '*') { step->test = FRX_XTEST_NSSTAR; return 1; }
        step->test  = FRX_XTEST_NAME;
        step->local = frx_xp_dup(p, &local);
        return step->local.p != NULL;
    }
}

static int
frx_xp_predicates(frx_xparse *p, frx_xn ***v, int *n, int *cap)
{
    int pcap = *cap;
    while (frx_xp_at(p, FRX_XT_LBRACK)) {
        frx_xn *e;
        p->i++;
        e = frx_xp_expr(p);
        if (!e) return 0;
        if (!frx_xp_eat(p, FRX_XT_RBRACK))
            return frx_xp_fail(p, "a predicate is never closed with ']'") != NULL;
        if (!frx_xp_push(p, v, n, &pcap, e)) return 0;
    }
    *cap = pcap;
    return 1;
}

static frx_xn *
frx_xp_step(frx_xparse *p)
{
    frx_xn *s;
    int cap = 0;

    if (frx_xp_at(p, FRX_XT_DOT) || frx_xp_at(p, FRX_XT_DOTDOT)) {
        int dotdot = frx_xp_at(p, FRX_XT_DOTDOT);
        p->i++;
        s = frx_xp_new(p, FRX_XN_STEP);
        if (!s) return NULL;
        s->axis = dotdot ? FRX_AX_PARENT : FRX_AX_SELF;
        s->test = FRX_XTEST_NODE;
        return s;
    }

    s = frx_xp_new(p, FRX_XN_STEP);
    if (!s) return NULL;
    s->axis = FRX_AX_CHILD;
    if (frx_xp_eat(p, FRX_XT_AT)) {
        s->axis = FRX_AX_ATTRIBUTE;
    } else if (frx_xp_at(p, FRX_XT_NAME) && frx_xp_peek(p, 1)->kind == FRX_XT_COLON2) {
        int ax = frx_xp_axis_by_name(&frx_xp_peek(p, 0)->s);
        if (ax < 0) return (frx_xn *)frx_xp_fail(p, "not one of the thirteen axis names");
        s->axis = ax;
        p->i += 2;
    }
    if (!frx_xp_node_test(p, s)) return NULL;
    if (!frx_xp_predicates(p, &s->preds, &s->n_preds, &cap)) return NULL;
    return frx_xp_depth_ok(p, s);
}

/* `//` is `/descendant-or-self::node()/`, spelled out here */
static frx_xn *
frx_xp_dos_step(frx_xparse *p)
{
    frx_xn *s = frx_xp_new(p, FRX_XN_STEP);
    if (!s) return NULL;
    s->axis = FRX_AX_DESCENDANT_OR_SELF;
    s->test = FRX_XTEST_NODE;
    return s;
}

static int
frx_xp_starts_step(const frx_xparse *p)
{
    const frx_xtok *t = frx_xp_peek(p, 0);
    switch (t->kind) {
    case FRX_XT_AT: case FRX_XT_DOT: case FRX_XT_DOTDOT: case FRX_XT_NAME:
        return 1;
    default:
        return 0;
    }
}

static int
frx_xp_rel_path(frx_xparse *p, frx_xn *path)
{
    int cap = path->n_steps;
    for (;;) {
        if (!frx_xp_push(p, &path->steps, &path->n_steps, &cap, frx_xp_step(p))) return 0;
        if (frx_xp_eat(p, FRX_XT_SLASH)) continue;
        if (frx_xp_eat(p, FRX_XT_SLASH2)) {
            if (!frx_xp_push(p, &path->steps, &path->n_steps, &cap, frx_xp_dos_step(p))) return 0;
            continue;
        }
        return 1;
    }
}

static frx_xn *
frx_xp_location_path(frx_xparse *p)
{
    frx_xn *path = frx_xp_new(p, FRX_XN_PATH);
    if (!path) return NULL;
    if (frx_xp_eat(p, FRX_XT_SLASH2)) {
        int cap = 0;
        path->absolute = 1;
        if (!frx_xp_push(p, &path->steps, &path->n_steps, &cap, frx_xp_dos_step(p))) return NULL;
        if (!frx_xp_rel_path(p, path)) return NULL;
        return frx_xp_depth_ok(p, path);
    }
    if (frx_xp_eat(p, FRX_XT_SLASH)) {
        path->absolute = 1;
        if (!frx_xp_starts_step(p)) return path;      /* `/` alone: the root */
        if (!frx_xp_rel_path(p, path)) return NULL;
        return frx_xp_depth_ok(p, path);
    }
    if (!frx_xp_rel_path(p, path)) return NULL;
    return frx_xp_depth_ok(p, path);
}

static frx_xn *
frx_xp_function_call(frx_xparse *p)
{
    const frx_xtok  *t = frx_xp_peek(p, 0);
    const frx_xp_fn *f = frx_xp_func_by_name(&t->s);
    frx_xn *n;
    int cap = 0;

    if (!f) return (frx_xn *)frx_xp_fail(p, "not one of the 27 core functions");
    n = frx_xp_new(p, FRX_XN_FUNC);
    if (!n) return NULL;
    n->func = f->id;
    p->i += 2;                                       /* the name and the '(' */
    if (!frx_xp_at(p, FRX_XT_RPAREN)) {
        for (;;) {
            if (!frx_xp_push(p, &n->args, &n->n_args, &cap, frx_xp_expr(p))) return NULL;
            if (frx_xp_eat(p, FRX_XT_COMMA)) continue;
            break;
        }
    }
    if (!frx_xp_eat(p, FRX_XT_RPAREN))
        return (frx_xn *)frx_xp_fail(p, "an argument list is never closed with ')'");
    if (n->n_args < f->min || (f->max >= 0 && n->n_args > f->max)) {
        p->i--;
        return (frx_xn *)frx_xp_fail(p, "the function was given the wrong number of arguments");
    }
    return frx_xp_depth_ok(p, n);
}

static frx_xn *
frx_xp_primary(frx_xparse *p)
{
    const frx_xtok *t = frx_xp_peek(p, 0);
    frx_xn *n;

    switch (t->kind) {
    case FRX_XT_VAR:
        n = frx_xp_new(p, FRX_XN_VAR);
        if (!n) return NULL;
        n->str = frx_xp_dup(p, &t->s);
        if (!n->str.p) return NULL;
        n->var = frx_xp_var_index(p, &t->s);
        if (n->var < 0) return NULL;
        p->i++;
        return n;
    case FRX_XT_LPAREN:
        p->i++;
        n = frx_xp_expr(p);
        if (!n) return NULL;
        if (!frx_xp_eat(p, FRX_XT_RPAREN))
            return (frx_xn *)frx_xp_fail(p, "a parenthesised expression is never closed");
        return n;
    case FRX_XT_LITERAL:
        n = frx_xp_new(p, FRX_XN_LITERAL);
        if (!n) return NULL;
        n->str = frx_xp_dup(p, &t->s);
        if (!n->str.p) return NULL;
        p->i++;
        return n;
    case FRX_XT_NUMBER:
        n = frx_xp_new(p, FRX_XN_NUMBER);
        if (!n) return NULL;
        n->num = t->num;
        p->i++;
        return n;
    case FRX_XT_NAME:
        return frx_xp_function_call(p);
    default:
        return (frx_xn *)frx_xp_fail(p, "an expression was expected");
    }
}

/* does a PathExpr begin with a FilterExpr rather than a LocationPath? */
static int
frx_xp_starts_filter(const frx_xparse *p)
{
    const frx_xtok *t = frx_xp_peek(p, 0);
    if (t->kind == FRX_XT_VAR || t->kind == FRX_XT_LPAREN
        || t->kind == FRX_XT_LITERAL || t->kind == FRX_XT_NUMBER) return 1;
    /* a FunctionName is a QName that is not a NodeType */
    return t->kind == FRX_XT_NAME
        && frx_xp_peek(p, 1)->kind == FRX_XT_LPAREN
        && !frx_xp_nodetype(&t->s);
}

static frx_xn *
frx_xp_path_expr(frx_xparse *p)
{
    frx_xn *filter, *path;
    int cap = 0;

    if (!frx_xp_starts_filter(p)) return frx_xp_location_path(p);

    filter = frx_xp_new(p, FRX_XN_FILTER);
    if (!filter) return NULL;
    filter->a = frx_xp_primary(p);
    if (!filter->a) return NULL;
    if (!frx_xp_predicates(p, &filter->preds, &filter->n_preds, &cap)) return NULL;

    if (!frx_xp_at(p, FRX_XT_SLASH) && !frx_xp_at(p, FRX_XT_SLASH2))
        return frx_xp_depth_ok(p, filter);
    if (!frx_xp_depth_ok(p, filter)) return NULL;

    path = frx_xp_new(p, FRX_XN_PATH);
    if (!path) return NULL;
    path->a = filter;
    if (frx_xp_eat(p, FRX_XT_SLASH2)) {
        int c2 = 0;
        if (!frx_xp_push(p, &path->steps, &path->n_steps, &c2, frx_xp_dos_step(p))) return NULL;
    } else {
        p->i++;                                      /* the '/' */
    }
    if (!frx_xp_rel_path(p, path)) return NULL;
    return frx_xp_depth_ok(p, path);
}

static frx_xn *
frx_xp_union(frx_xparse *p)
{
    frx_xn *l = frx_xp_path_expr(p);
    while (l && frx_xp_at(p, FRX_XT_PIPE)) {
        frx_xn *n;
        p->i++;
        n = frx_xp_new(p, FRX_XN_UNION);
        if (!n) return NULL;
        n->a = l;
        n->b = frx_xp_path_expr(p);
        if (!n->b) return NULL;
        l = frx_xp_depth_ok(p, n);
    }
    return l;
}

/* the second recursion over the expression, and so the second place the
 * depth is counted: `- - - -x` is a chain of UnaryExpr and nothing else
 * on the way down calls frx_xp_expr */
static frx_xn *
frx_xp_unary(frx_xparse *p)
{
    if (frx_xp_at(p, FRX_XT_MINUS)) {
        frx_xn *n;
        if (++p->depth > p->max_depth) {
            p->depth--;
            return (frx_xn *)frx_xp_fail(p, "the expression nests deeper than max_expr_depth");
        }
        p->i++;
        n = frx_xp_new(p, FRX_XN_NEG);
        if (n) n->a = frx_xp_unary(p);
        p->depth--;
        return (n && n->a) ? frx_xp_depth_ok(p, n) : NULL;
    }
    return frx_xp_union(p);
}

/* one left-associative binary level, driven by a table of (token, kind) */
static frx_xn *
frx_xp_binary(frx_xparse *p, const int *pairs, int n_pairs, frx_xn *(*next)(frx_xparse *))
{
    frx_xn *l = next(p);
    for (;;) {
        int i, kind = 0;
        if (!l) return NULL;
        for (i = 0; i < n_pairs; i++)
            if (frx_xp_at(p, pairs[i * 2])) { kind = pairs[i * 2 + 1]; break; }
        if (!kind) return l;
        p->i++;
        {
            frx_xn *n = frx_xp_new(p, kind);
            if (!n) return NULL;
            n->a = l;
            n->b = next(p);
            if (!n->b) return NULL;
            l = frx_xp_depth_ok(p, n);
        }
    }
}

static frx_xn *
frx_xp_multiplicative(frx_xparse *p)
{
    static const int ops[] = { FRX_XT_STAR, FRX_XN_MUL,
                               FRX_XT_DIV,  FRX_XN_DIV,
                               FRX_XT_MOD,  FRX_XN_MOD };
    return frx_xp_binary(p, ops, 3, frx_xp_unary);
}

static frx_xn *
frx_xp_additive(frx_xparse *p)
{
    static const int ops[] = { FRX_XT_PLUS, FRX_XN_ADD, FRX_XT_MINUS, FRX_XN_SUB };
    return frx_xp_binary(p, ops, 2, frx_xp_multiplicative);
}

static frx_xn *
frx_xp_relational(frx_xparse *p)
{
    static const int ops[] = { FRX_XT_LT, FRX_XN_LT, FRX_XT_LE, FRX_XN_LE,
                               FRX_XT_GT, FRX_XN_GT, FRX_XT_GE, FRX_XN_GE };
    return frx_xp_binary(p, ops, 4, frx_xp_additive);
}

static frx_xn *
frx_xp_equality(frx_xparse *p)
{
    static const int ops[] = { FRX_XT_EQ, FRX_XN_EQ, FRX_XT_NE, FRX_XN_NE };
    return frx_xp_binary(p, ops, 2, frx_xp_relational);
}

static frx_xn *
frx_xp_and(frx_xparse *p)
{
    static const int ops[] = { FRX_XT_AND, FRX_XN_AND };
    return frx_xp_binary(p, ops, 1, frx_xp_equality);
}

static frx_xn *
frx_xp_or(frx_xparse *p)
{
    static const int ops[] = { FRX_XT_OR, FRX_XN_OR };
    return frx_xp_binary(p, ops, 1, frx_xp_and);
}

/* the one place the expression's depth is counted: every production above
 * reaches the next through here */
static frx_xn *
frx_xp_expr(frx_xparse *p)
{
    frx_xn *n;
    if (p->err) return NULL;
    if (++p->depth > p->max_depth) {
        p->depth--;
        return (frx_xn *)frx_xp_fail(p, "the expression nests deeper than max_expr_depth");
    }
    n = frx_xp_or(p);
    p->depth--;
    return n;
}

#endif /* FRX_XPATH_PARSE_H */
