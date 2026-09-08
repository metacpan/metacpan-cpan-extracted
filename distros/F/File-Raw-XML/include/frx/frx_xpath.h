#ifndef FRX_XPATH_H
#define FRX_XPATH_H

/* A compiled XPath 1.0 expression: compile once, evaluate many times.
 *
 * The compiled object owns an arena holding its AST and every string in
 * it, and a variable table the caller fills before evaluating. It is
 * independent of any document: the same object evaluates against as many
 * documents as the caller has, and holds none of them alive.
 *
 * The prefix map is the caller's and is read only at compile. Nothing
 * here ever reads a document's own namespace declarations, so an
 * expression means the same thing wherever it is evaluated.
 *
 * `order` IS RENUMBERED HERE. Document order is what a node-set is
 * sorted by, and an edit (frx_edit.h) marks it stale rather than paying
 * to keep it current, so every evaluation calls frx_tree.h's
 * frx_doc_renumber first. It walks the document once and costs nothing
 * when no edit has happened. That call is the only thing under this
 * header that writes to a document.
 *
 * Needs frx_arena.h, frx_tree.h, frx_parse.h, frx_xpath_lex.h,
 * frx_xpath_parse.h, frx_xpath_eval.h. */

typedef struct frx_xpath {
    frx_arena   arena;
    frx_xn     *ast;
    frx_xp_var *vars;
    int         n_vars;
    int         max_depth;
} frx_xpath;

static void
frx_xpath_free(frx_xpath *x)
{
    int i;
    if (!x) return;
    for (i = 0; i < x->n_vars; i++) frx_xp_val_free(&x->vars[i].val);
    free(x->vars);
    frx_arena_free(&x->arena);
    free(x);
}

/* Compile expr under the caller's prefix map. NULL on refusal, with *err
 * a static message and *err_at the byte offset in expr it was found at.
 * max_depth of 0 means the default. */
static frx_xpath *
frx_xpath_compile(const char *expr, size_t len, const frx_ns_map *ns,
                  int max_depth, const char **err, size_t *err_at)
{
    frx_xpath  *x;
    frx_xlex    lex;
    frx_xparse  ps;
    frx_xvars   vars;
    int         i;

    *err    = NULL;
    *err_at = 0;

    x = (frx_xpath *)malloc(sizeof *x);
    if (!x) { *err = "out of memory"; return NULL; }
    memset(x, 0, sizeof *x);
    frx_arena_init(&x->arena);
    x->max_depth = max_depth > 0 ? max_depth : FRX_XP_MAX_EXPR_DEPTH;

    frx_xlex_init(&lex, expr, len);
    if (!frx_xlex_run(&lex)) {
        *err    = lex.err ? lex.err : "the expression cannot be read";
        *err_at = lex.err_at;
        frx_xlex_free(&lex);
        frx_xpath_free(x);
        return NULL;
    }

    memset(&vars, 0, sizeof vars);
    memset(&ps, 0, sizeof ps);
    ps.t         = lex.t;
    ps.n         = lex.n;
    ps.arena     = &x->arena;
    ps.ns        = ns;
    ps.vars      = &vars;
    ps.max_depth = x->max_depth;

    x->ast = frx_xp_expr(&ps);
    if (x->ast && ps.i != ps.n - 1)
        (void)frx_xp_fail(&ps, "the expression has more after its end");
    if (!x->ast || ps.err) {
        *err    = ps.err ? ps.err : "the expression cannot be parsed";
        *err_at = ps.err_at;
        free(vars.name);
        frx_xlex_free(&lex);
        frx_xpath_free(x);
        return NULL;
    }

    if (vars.n) {
        x->vars = (frx_xp_var *)malloc((size_t)vars.n * sizeof *x->vars);
        if (!x->vars) {
            *err = "out of memory";
            free(vars.name);
            frx_xlex_free(&lex);
            frx_xpath_free(x);
            return NULL;
        }
        for (i = 0; i < vars.n; i++) {
            x->vars[i].name = vars.name[i];    /* in the arena, and it stays */
            frx_xp_val_init(&x->vars[i].val);
            x->vars[i].val.kind = FRX_XV_STRING;
        }
        x->n_vars = vars.n;
    }
    free(vars.name);
    frx_xlex_free(&lex);
    return x;
}

/* An evaluation result on the heap, for a caller that cannot see the
 * struct. frx_xp_val_free releases what the result holds; these two put
 * it on the heap and take it back, which is what the C ABI hands out. */
static frx_xp_val *
frx_xpath_result_new(void)
{
    frx_xp_val *v = (frx_xp_val *)malloc(sizeof *v);
    if (v) frx_xp_val_init(v);
    return v;
}

static void
frx_xpath_result_destroy(frx_xp_val *v)
{
    if (!v) return;
    frx_xp_val_free(v);
    free(v);
}

static int
frx_xpath_var_count(const frx_xpath *x)
{
    return x->n_vars;
}

static const char *
frx_xpath_var_name(const frx_xpath *x, int i, size_t *len)
{
    if (len) *len = x->vars[i].name.len;
    return x->vars[i].name.p;
}

static int
frx_xpath_bind_str(frx_xpath *x, int i, const char *p, size_t n)
{
    frx_xp_val *v = &x->vars[i].val;
    v->kind = FRX_XV_STRING;
    frx_xp_buf_reset(&v->str);
    frx_buf_append_n(&v->str, p, n);
    return !v->str.failed;
}

static void
frx_xpath_bind_num(frx_xpath *x, int i, double d)
{
    frx_xp_val *v = &x->vars[i].val;
    v->kind = FRX_XV_NUMBER;
    v->num  = d;
}

static void
frx_xpath_bind_bool(frx_xpath *x, int i, int b)
{
    frx_xp_val *v = &x->vars[i].val;
    v->kind = FRX_XV_BOOLEAN;
    v->bl   = b != 0;
}

/* Evaluate against ctx, a node of d. `out` is filled and the caller frees
 * it with frx_xp_val_free. 0 with *err set on a failure, which is an
 * allocation or one of the type errors the specification calls an error. */
static int
frx_xpath_eval_at(frx_xpath *x, frx_doc *d, const frx_node *ctx,
                  frx_xp_val *out, const char **err)
{
    frx_xeval e;
    frx_xctx  c;

    *err = NULL;
    frx_xp_val_init(out);
    if (d) frx_doc_renumber(d);      /* frx_tree.h's; a no-op unless an edit set the flag */

    memset(&e, 0, sizeof e);
    e.doc    = d;
    e.vars   = x->vars;
    e.n_vars = x->n_vars;

    memset(&c, 0, sizeof c);
    c.item.node  = ctx;
    c.item.kind  = FRX_XP_KNODE;
    c.item.index = 0;
    c.position   = 1;
    c.size       = 1;

    if (!frx_xp_eval(&e, x->ast, &c, out) || e.failed) {
        *err = e.err ? e.err : "the expression could not be evaluated";
        frx_xp_val_free(out);
        frx_xp_val_init(out);
        return 0;
    }
    return 1;
}

/* the compile refusal in the one message shape, over the expression */
static size_t
frx_xpath_err_format(const char *what, const char *expr, size_t len, size_t at,
                     char *out, size_t cap)
{
    frx_err e;
    frx_err_set(&e, FRX_E_SYNTAX, at, what);
    return frx_err_format(&e, expr, len, out, cap);
}

#endif /* FRX_XPATH_H */
