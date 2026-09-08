#ifndef FRX_MODEL_H
#define FRX_MODEL_H

/* Content models compiled to a deterministic automaton.
 *
 * frx_dtd.h stores each ELEMENT declaration's content model as the token
 * list it was written as: parentheses, names, `,` and `|`, and the `?`,
 * `*` and `+` that follow whatever they modify. This turns that list
 * into something a document can be run against, once per element type,
 * and never looks at the tokens again.
 *
 * THE CONSTRUCTION is Glushkov's. Every name in the model is a position;
 * a particle has a `nullable` flag, a set of positions it can start
 * with, and a set it can end with; and `follow[p]` is every position
 * that may come directly after position p. They are built bottom up by
 * folding the token list with an explicit stack of groups (rule 2: the
 * model is the DTD author's text, and nothing here recurses over it):
 *
 *   leaf p   nullable 0, first {p}, last {p}
 *   A , B    follow[q] |= first(B) for q in last(A)
 *            nullable  nA && nB
 *            first     first(A) + (nA ? first(B) : {})
 *            last      last(B)  + (nB ? last(A)  : {})
 *   A | B    nullable  nA || nB, first and last the unions
 *   A?       nullable 1
 *   A*       follow[q] |= first(A) for q in last(A), nullable 1
 *   A+       follow[q] |= first(A) for q in last(A)
 *
 * The automaton's states are the positions plus a start state. From the
 * start, a name takes you to the position in first(root) carrying it;
 * from position p, to the one in follow[p]. It accepts when the position
 * it stops on is in last(root), or when nothing was read and the root is
 * nullable.
 *
 * THAT IS ONLY AN AUTOMATON IF THE MODEL IS DETERMINISTIC, which is
 * exactly XML 1.0's requirement in section 3.2.1 and its appendix E: a
 * processor must be able to tell which position a name matches without
 * looking ahead. Stated in these terms it is one check: no two positions
 * in first(root) carry the same name, and no two positions in any
 * follow[p] carry the same name. `((a, b) | (a, c))` fails it, because
 * an `a` at the start could be either position; `(a, (b | c))` is the
 * deterministic rewrite. The check is a validity constraint, so it is
 * made only when the caller asked to validate, and a model that fails it
 * is reported with its declaration's offset and validated no further.
 *
 * MIXED CONTENT is not compiled: `(#PCDATA | a | b)*` admits its names
 * in any order and any number, so the whole of it is the name list, and
 * the only thing to check at build time is that no name is in it twice
 * (VC: No Duplicate Types).
 *
 * The cost of a pathological model is memory in the DTD, never time in
 * the document: the run over one element's children is a loop with a
 * single current position.
 *
 * Needs frx_arena.h, frx_tree.h, frx_dtd.h. */

typedef struct frx_cm_dfa {
    const frx_str  *name;       /* name[i], the name at position i */
    int             n_pos;
    const int      *first;      /* the positions the start state goes to */
    int             n_first;
    const int      *last;       /* the accepting positions */
    int             n_last;
    const int     **follow;     /* follow[i], the positions after position i */
    const int      *n_follow;
    int             nullable;   /* the empty sequence is accepted */
    int             mixed;      /* a mixed model: `name` is the whole of it */
} frx_cm_dfa;

enum { FRX_MODEL_OK = 0, FRX_MODEL_NOMEM, FRX_MODEL_NONDET, FRX_MODEL_DUPTYPE };

/* ---- growable position sets, malloc'd for the build only --------------- */

typedef struct frx_pset {
    int *v;
    int  n, cap;
} frx_pset;

static int
frx_pset_add(frx_pset *s, int p)
{
    int i;
    for (i = 0; i < s->n; i++) if (s->v[i] == p) return 1;
    if (s->n == s->cap) {
        int ncap = s->cap ? s->cap * 2 : 8;
        int *nv = (int *)realloc(s->v, (size_t)ncap * sizeof *nv);
        if (!nv) return 0;
        s->v = nv; s->cap = ncap;
    }
    s->v[s->n++] = p;
    return 1;
}

static int
frx_pset_union(frx_pset *d, const frx_pset *s)
{
    int i;
    for (i = 0; i < s->n; i++) if (!frx_pset_add(d, s->v[i])) return 0;
    return 1;
}

/* a particle: what it may start with, end with, and whether it may be empty */
typedef struct frx_cm_part {
    int      nullable;
    frx_pset first;
    frx_pset last;
} frx_cm_part;

static void
frx_cm_part_free(frx_cm_part *p)
{
    free(p->first.v);
    free(p->last.v);
    memset(p, 0, sizeof *p);
}

/* one group being read: what has been combined, its separator, and the
 * operand a modifier would apply to */
typedef struct frx_cm_frame {
    frx_cm_part acc;
    int         have_acc;
    int         sep;            /* ',' or '|', 0 until the first one */
    frx_cm_part pending;
    int         have_pending;
} frx_cm_frame;

typedef struct frx_cm_build {
    frx_pset     *follow;       /* follow[i], one per position */
    frx_str      *name;         /* name[i], borrowed from the model tokens */
    int           n_pos, cap_pos;
    frx_cm_frame *stack;
    int           sp, cap_stack;
    int           failed;
} frx_cm_build;

static void
frx_cm_build_free(frx_cm_build *b)
{
    int i;
    for (i = 0; i < b->n_pos; i++) free(b->follow[i].v);
    for (i = 0; i < b->sp; i++) {
        frx_cm_part_free(&b->stack[i].acc);
        frx_cm_part_free(&b->stack[i].pending);
    }
    free(b->follow);
    free(b->name);
    free(b->stack);
    memset(b, 0, sizeof *b);
}

static int
frx_cm_new_pos(frx_cm_build *b, const frx_str *name)
{
    if (b->n_pos == b->cap_pos) {
        int ncap = b->cap_pos ? b->cap_pos * 2 : 16;
        frx_pset *nf = (frx_pset *)realloc(b->follow, (size_t)ncap * sizeof *nf);
        frx_str  *nn;
        if (!nf) { b->failed = 1; return -1; }
        b->follow = nf;
        nn = (frx_str *)realloc(b->name, (size_t)ncap * sizeof *nn);
        if (!nn) { b->failed = 1; return -1; }
        b->name    = nn;
        b->cap_pos = ncap;
    }
    memset(&b->follow[b->n_pos], 0, sizeof b->follow[b->n_pos]);
    b->name[b->n_pos] = *name;
    return b->n_pos++;
}

/* follow[q] gains every position of s, for every q in the set l */
static int
frx_cm_link(frx_cm_build *b, const frx_pset *l, const frx_pset *s)
{
    int i;
    for (i = 0; i < l->n; i++)
        if (!frx_pset_union(&b->follow[l->v[i]], s)) return 0;
    return 1;
}

/* acc = acc `sep` p, consuming p */
static int
frx_cm_combine(frx_cm_build *b, frx_cm_part *acc, frx_cm_part *p, int sep)
{
    int ok = 1;
    if (sep == ',') {
        ok = frx_cm_link(b, &acc->last, &p->first);
        if (ok && acc->nullable) ok = frx_pset_union(&acc->first, &p->first);
        if (ok) {
            if (p->nullable) { ok = frx_pset_union(&acc->last, &p->last); }
            else             { free(acc->last.v); acc->last = p->last; memset(&p->last, 0, sizeof p->last); }
        }
        acc->nullable = acc->nullable && p->nullable;
    } else {
        ok = frx_pset_union(&acc->first, &p->first) && frx_pset_union(&acc->last, &p->last);
        acc->nullable = acc->nullable || p->nullable;
    }
    frx_cm_part_free(p);
    if (!ok) b->failed = 1;
    return ok;
}

static int
frx_cm_fold_pending(frx_cm_build *b, frx_cm_frame *f)
{
    if (!f->have_pending) return 1;
    if (!f->have_acc) {
        f->acc          = f->pending;
        f->have_acc     = 1;
        memset(&f->pending, 0, sizeof f->pending);
        f->have_pending = 0;
        return 1;
    }
    f->have_pending = 0;
    return frx_cm_combine(b, &f->acc, &f->pending, f->sep ? f->sep : ',');
}

static int
frx_cm_push_frame(frx_cm_build *b)
{
    if (b->sp == b->cap_stack) {
        int ncap = b->cap_stack ? b->cap_stack * 2 : 16;
        frx_cm_frame *ns = (frx_cm_frame *)realloc(b->stack, (size_t)ncap * sizeof *ns);
        if (!ns) { b->failed = 1; return 0; }
        b->stack     = ns;
        b->cap_stack = ncap;
    }
    memset(&b->stack[b->sp], 0, sizeof b->stack[b->sp]);
    b->sp++;
    return 1;
}

/* ---- mixed content ------------------------------------------------------ */

/* `(#PCDATA | a | b)*`: the names, with a repeat refused as VC: No
 * Duplicate Types */
static int
frx_model_mixed(frx_arena *a, const frx_eldecl *ed, frx_cm_dfa **out)
{
    frx_cm_dfa *d;
    frx_str    *names;
    int i, n = 0, k = 0, j;

    for (i = 0; i < ed->n_model; i++)
        if (ed->model[i].kind == FRX_CM_NAME) n++;
    d = (frx_cm_dfa *)frx_arena_alloc(a, sizeof *d);
    if (!d) return FRX_MODEL_NOMEM;
    memset(d, 0, sizeof *d);
    d->mixed    = 1;
    d->nullable = 1;
    if (n) {
        names = (frx_str *)frx_arena_alloc(a, (size_t)n * sizeof *names);
        if (!names) return FRX_MODEL_NOMEM;
        for (i = 0; i < ed->n_model; i++) {
            if (ed->model[i].kind != FRX_CM_NAME) continue;
            for (j = 0; j < k; j++)
                if (frx_str_eq2(&names[j], &ed->model[i].name)) return FRX_MODEL_DUPTYPE;
            names[k++] = ed->model[i].name;
        }
        d->name  = names;
        d->n_pos = k;
    }
    *out = d;
    return FRX_MODEL_OK;
}

/* ---- the automaton ------------------------------------------------------ */

/* no two positions of the set carry the same name */
static int
frx_model_deterministic(const frx_cm_build *b, const frx_pset *s)
{
    int i, j;
    for (i = 0; i < s->n; i++)
        for (j = i + 1; j < s->n; j++)
            if (frx_str_eq2(&b->name[s->v[i]], &b->name[s->v[j]])) return 0;
    return 1;
}

static const int *
frx_model_copy_set(frx_arena *a, const frx_pset *s, int *n)
{
    int *v;
    *n = s->n;
    if (!s->n) return NULL;
    v = (int *)frx_arena_alloc(a, (size_t)s->n * sizeof *v);
    if (!v) return NULL;
    memcpy(v, s->v, (size_t)s->n * sizeof *v);
    return v;
}

/* The element's content model as an automaton in the arena. One of
 * FRX_MODEL_*; *out is filled only on FRX_MODEL_OK. Only MIXED and
 * CHILDREN reach here: EMPTY and ANY are not models and the validator
 * answers them without one. */
static int
frx_model_build(frx_arena *a, const frx_eldecl *ed, frx_cm_dfa **out)
{
    frx_cm_build b;
    frx_cm_dfa  *d;
    frx_cm_part  root;
    int i, rc = FRX_MODEL_OK;

    *out = NULL;
    if (ed->content == FRX_CONTENT_MIXED) return frx_model_mixed(a, ed, out);

    memset(&b, 0, sizeof b);
    memset(&root, 0, sizeof root);

    for (i = 0; i < ed->n_model && !b.failed; i++) {
        const frx_cm_tok *t = &ed->model[i];
        frx_cm_frame     *f;
        switch (t->kind) {
        case '(':
            if (!frx_cm_push_frame(&b)) break;
            continue;
        case FRX_CM_NAME: {
            int p;
            if (b.sp == 0) { b.failed = 1; break; }
            p = frx_cm_new_pos(&b, &t->name);
            if (p < 0) break;
            f = &b.stack[b.sp - 1];
            if (f->have_pending) frx_cm_part_free(&f->pending);
            memset(&f->pending, 0, sizeof f->pending);
            if (!frx_pset_add(&f->pending.first, p) || !frx_pset_add(&f->pending.last, p)) {
                b.failed = 1;
                break;
            }
            f->pending.nullable = 0;
            f->have_pending     = 1;
            continue;
        }
        case '?': case '*': case '+': {
            /* a modifier applies to the operand just read, which after a
             * closing parenthesis is the group, and after the outermost
             * one is the whole model */
            frx_cm_part *p;
            if (b.sp == 0) {
                p = &root;
            } else {
                f = &b.stack[b.sp - 1];
                p = f->have_pending ? &f->pending : &f->acc;
            }
            if (t->kind != '?' && !frx_cm_link(&b, &p->last, &p->first)) { b.failed = 1; break; }
            if (t->kind != '+') p->nullable = 1;
            continue;
        }
        case ',': case '|':
            if (b.sp == 0) { b.failed = 1; break; }
            f = &b.stack[b.sp - 1];
            if (!f->sep) f->sep = t->kind;
            if (!frx_cm_fold_pending(&b, f)) break;
            continue;
        case ')': {
            frx_cm_part done;
            if (b.sp == 0) { b.failed = 1; break; }
            f = &b.stack[b.sp - 1];
            if (!frx_cm_fold_pending(&b, f)) break;
            done = f->acc;
            b.sp--;
            if (b.sp == 0) {
                root = done;
            } else {
                frx_cm_frame *up = &b.stack[b.sp - 1];
                if (up->have_pending) frx_cm_part_free(&up->pending);
                up->pending      = done;
                up->have_pending = 1;
            }
            continue;
        }
        default:
            continue;
        }
        break;
    }

    if (b.failed) { rc = FRX_MODEL_NOMEM; goto done; }

    /* the determinism check, section 3.2.1, stated over the sets */
    if (!frx_model_deterministic(&b, &root.first)) { rc = FRX_MODEL_NONDET; goto done; }
    for (i = 0; i < b.n_pos; i++)
        if (!frx_model_deterministic(&b, &b.follow[i])) { rc = FRX_MODEL_NONDET; goto done; }

    d = (frx_cm_dfa *)frx_arena_alloc(a, sizeof *d);
    if (!d) { rc = FRX_MODEL_NOMEM; goto done; }
    memset(d, 0, sizeof *d);
    d->nullable = root.nullable;
    d->n_pos    = b.n_pos;
    if (b.n_pos) {
        frx_str  *names = (frx_str *)frx_arena_alloc(a, (size_t)b.n_pos * sizeof *names);
        const int **fol = (const int **)frx_arena_alloc(a, (size_t)b.n_pos * sizeof *fol);
        int      *nfol  = (int *)frx_arena_alloc(a, (size_t)b.n_pos * sizeof *nfol);
        if (!names || !fol || !nfol) { rc = FRX_MODEL_NOMEM; goto done; }
        memcpy(names, b.name, (size_t)b.n_pos * sizeof *names);
        for (i = 0; i < b.n_pos; i++) {
            fol[i] = frx_model_copy_set(a, &b.follow[i], &nfol[i]);
            if (!fol[i] && nfol[i]) { rc = FRX_MODEL_NOMEM; goto done; }
        }
        d->name     = names;
        d->follow   = fol;
        d->n_follow = nfol;
    }
    d->first = frx_model_copy_set(a, &root.first, &d->n_first);
    if (!d->first && d->n_first) { rc = FRX_MODEL_NOMEM; goto done; }
    d->last = frx_model_copy_set(a, &root.last, &d->n_last);
    if (!d->last && d->n_last) { rc = FRX_MODEL_NOMEM; goto done; }
    *out = d;

done:
    frx_cm_part_free(&root);
    frx_cm_build_free(&b);
    return rc;
}

/* ---- running it --------------------------------------------------------- */

/* the position a name goes to from `at` (-1 for the start state), or -1
 * when the name may not stand there */
static int
frx_model_step(const frx_cm_dfa *d, int at, const frx_str *name)
{
    const int *set = at < 0 ? d->first : d->follow[at];
    int n = at < 0 ? d->n_first : d->n_follow[at];
    int i;
    for (i = 0; i < n; i++)
        if (frx_str_eq2(&d->name[set[i]], name)) return set[i];
    return -1;
}

static int
frx_model_accepts(const frx_cm_dfa *d, int at)
{
    int i;
    if (at < 0) return d->nullable;
    for (i = 0; i < d->n_last; i++) if (d->last[i] == at) return 1;
    return 0;
}

/* mixed content: is this one of the names the model lists? */
static int
frx_model_mixed_has(const frx_cm_dfa *d, const frx_str *name)
{
    int i;
    for (i = 0; i < d->n_pos; i++) if (frx_str_eq2(&d->name[i], name)) return 1;
    return 0;
}

#endif /* FRX_MODEL_H */
