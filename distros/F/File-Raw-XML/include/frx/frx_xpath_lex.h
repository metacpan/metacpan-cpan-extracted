#ifndef FRX_XPATH_LEX_H
#define FRX_XPATH_LEX_H

/* XPath 1.0 tokens.
 *
 * The whole expression is lexed into an array before the parser runs, so
 * that the parser has unbounded lookahead and the three disambiguation
 * rules of section 3.7 can be applied where the specification states
 * them:
 *
 *   - `*` is the MultiplyOperator, and an NCName is an OperatorName
 *     (and, or, mod, div), when there is a preceding token and it is not
 *     one of `@`, `::`, `(`, `[`, `,` or an Operator. That rule needs the
 *     previous token only, and is applied here.
 *   - An NCName followed by `(` is a NodeType or a FunctionName, and one
 *     followed by `::` is an AxisName. Both need the next token, so both
 *     are the parser's, which is why the array exists.
 *
 * A Number is `Digits ('.' Digits?)? | '.' Digits`: no sign, no exponent,
 * those being an operator and a name respectively. Once its extent is
 * known it is converted by strtod, which is the only correctly rounded
 * conversion available: accumulating the digits by hand drifts past
 * seventeen of them. strtod reads the decimal point of the ambient
 * LC_NUMERIC, which an embedding application may have set to a comma, so
 * the separator is discovered from the C library itself and written into
 * the buffer strtod is given.
 *
 * Names are NCNames and QNames under frx_utf8.h's tables, which are the
 * XML productions XPath refers to. `prefix:*` is one NAME token holding
 * the text as written; the parser splits it.
 *
 * The lexer allocates one growable array with malloc and the caller frees
 * it with frx_xlex_free. Nothing here touches a document.
 *
 * Needs frx_err.h, frx_buf.h, frx_utf8.h, frx_tree.h (frx_str). */

#include <stdio.h>      /* the one formatter the core uses; see below */

/* snprintf where the C library has it and sprintf where it does not.
 * Every use writes one double into a buffer that cannot be too small, so
 * the difference is not safety; it is that the platforms which deprecate
 * sprintf are exactly the ones that have snprintf, and a warning a reader
 * has to re-derive on every build is worth one macro. Strict C89 has
 * neither the declaration nor the deprecation. */
#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L
#  define FRX_FMT1(buf, cap, fmt, arg) ((void)snprintf((buf), (cap), (fmt), (arg)))
#elif !defined(__STRICT_ANSI__) && !defined(_MSC_VER)
#  define FRX_FMT1(buf, cap, fmt, arg) ((void)snprintf((buf), (cap), (fmt), (arg)))
#elif defined(_MSC_VER)
#  define FRX_FMT1(buf, cap, fmt, arg) ((void)_snprintf((buf), (cap), (fmt), (arg)))
#else
#  define FRX_FMT1(buf, cap, fmt, arg) ((void)sprintf((buf), (fmt), (arg)))
#endif

enum {
    FRX_XT_EOF = 0,
    FRX_XT_LPAREN, FRX_XT_RPAREN, FRX_XT_LBRACK, FRX_XT_RBRACK,
    FRX_XT_DOT, FRX_XT_DOTDOT, FRX_XT_AT, FRX_XT_COMMA, FRX_XT_COLON2,
    FRX_XT_SLASH, FRX_XT_SLASH2, FRX_XT_PIPE,
    FRX_XT_PLUS, FRX_XT_MINUS, FRX_XT_STAR,
    FRX_XT_EQ, FRX_XT_NE, FRX_XT_LT, FRX_XT_LE, FRX_XT_GT, FRX_XT_GE,
    FRX_XT_AND, FRX_XT_OR, FRX_XT_MOD, FRX_XT_DIV,
    FRX_XT_NAME, FRX_XT_VAR, FRX_XT_LITERAL, FRX_XT_NUMBER
};

typedef struct frx_xtok {
    int     kind;
    frx_str s;          /* a name, a variable's name, a literal's text */
    double  num;
    size_t  offset;     /* where it began in the expression */
} frx_xtok;

typedef struct frx_xlex {
    const char *in;
    size_t      len;
    size_t      at;
    frx_xtok   *t;
    int         n, cap;
    const char *err;    /* static; NULL while well-formed */
    size_t      err_at;
} frx_xlex;

static void
frx_xlex_init(frx_xlex *l, const char *in, size_t len)
{
    memset(l, 0, sizeof *l);
    l->in  = in;
    l->len = len;
}

static void
frx_xlex_free(frx_xlex *l)
{
    free(l->t);
    l->t = NULL;
    l->n = l->cap = 0;
}

static int
frx_xlex_fail(frx_xlex *l, size_t at, const char *what)
{
    if (!l->err) { l->err = what; l->err_at = at; }
    return 0;
}

static int
frx_xlex_push(frx_xlex *l, int kind, size_t offset)
{
    if (l->n == l->cap) {
        int ncap = l->cap ? l->cap * 2 : 32;
        frx_xtok *nt = (frx_xtok *)realloc(l->t, (size_t)ncap * sizeof *nt);
        if (!nt) return frx_xlex_fail(l, offset, "out of memory");
        l->t   = nt;
        l->cap = ncap;
    }
    memset(&l->t[l->n], 0, sizeof l->t[l->n]);
    l->t[l->n].kind   = kind;
    l->t[l->n].offset = offset;
    l->t[l->n].s      = FRX_EMPTY_STR;
    l->n++;
    return 1;
}

/* Is an operator what may stand here? Section 3.7's first rule, stated as
 * the set of preceding tokens after which one may not. */
static int
frx_xlex_op_ok(const frx_xlex *l)
{
    if (!l->n) return 0;
    switch (l->t[l->n - 1].kind) {
    case FRX_XT_AT:     case FRX_XT_COLON2: case FRX_XT_LPAREN:
    case FRX_XT_LBRACK: case FRX_XT_COMMA:
    case FRX_XT_SLASH:  case FRX_XT_SLASH2: case FRX_XT_PIPE:
    case FRX_XT_PLUS:   case FRX_XT_MINUS:  case FRX_XT_STAR:
    case FRX_XT_EQ:     case FRX_XT_NE:     case FRX_XT_LT:
    case FRX_XT_LE:     case FRX_XT_GT:     case FRX_XT_GE:
    case FRX_XT_AND:    case FRX_XT_OR:     case FRX_XT_MOD:
    case FRX_XT_DIV:
        return 0;
    default:
        return 1;
    }
}

/* the byte length of the NCName at p, 0 when there is none */
static size_t
frx_xlex_ncname(const char *p, size_t n)
{
    unsigned long cp;
    size_t k, at = 0;
    k = frx_utf8_decode((const unsigned char *)p, n, &cp);
    if (!k || !frx_is_name_start(cp)) return 0;
    at = k;
    for (;;) {
        k = frx_utf8_decode((const unsigned char *)p + at, n - at, &cp);
        if (!k || !frx_is_name_char(cp)) break;
        at += k;
    }
    return at;
}

/* what this C library writes, and therefore reads, as a decimal point */
static char
frx_xp_decimal_point(void)
{
    static char sep = 0;
    if (!sep) {
        char b[16];
        FRX_FMT1(b, sizeof b, "%.1f", 1.5);
        sep = b[1];
    }
    return sep;
}

/* Digits with at most one '.' and an optional leading '-', already known
 * to be exactly that, through strtod with the separator it wants. */
static double
frx_xp_atod(const char *p, size_t n)
{
    char   stackbuf[64];       /* not `small`: rpcndr.h defines it to char */
    char  *buf = stackbuf;
    char   sep = frx_xp_decimal_point();
    double v;
    size_t i;

    if (n + 1 > sizeof stackbuf) {
        buf = (char *)malloc(n + 1);
        if (!buf) return 0.0;
    }
    for (i = 0; i < n; i++) buf[i] = p[i] == '.' ? sep : p[i];
    buf[n] = '\0';
    v = strtod(buf, NULL);
    if (buf != stackbuf) free(buf);
    return v;
}

/* Digits ('.' Digits?)? | '.' Digits, already known to start here */
static int
frx_xlex_number(frx_xlex *l)
{
    size_t start = l->at;

    while (l->at < l->len && l->in[l->at] >= '0' && l->in[l->at] <= '9') l->at++;
    if (l->at < l->len && l->in[l->at] == '.') {
        l->at++;
        while (l->at < l->len && l->in[l->at] >= '0' && l->in[l->at] <= '9') l->at++;
    }
    if (!frx_xlex_push(l, FRX_XT_NUMBER, start)) return 0;
    l->t[l->n - 1].num = frx_xp_atod(l->in + start, l->at - start);
    return 1;
}

/* The expression is UTF-8 or it is refused, before a token is read. A
 * name is decoded scalar by scalar anyway, but a string literal is
 * copied through whole, and an expression that reached here as Latin-1
 * bytes would otherwise put those bytes in a result the Perl layer flags
 * as characters. Every string crossing this seam is UTF-8; this is where
 * that is checked for an expression. */
static int
frx_xlex_check_utf8(frx_xlex *l)
{
    size_t at = 0;
    unsigned long cp;
    while (at < l->len) {
        size_t k = frx_utf8_decode((const unsigned char *)l->in + at, l->len - at, &cp);
        if (!k)              return frx_xlex_fail(l, at, "the expression is not UTF-8");
        if (!frx_is_char(cp)) return frx_xlex_fail(l, at, "the expression holds a character XML has no name for");
        at += k;
    }
    return 1;
}

static int
frx_xlex_run(frx_xlex *l)
{
    if (!frx_xlex_check_utf8(l)) return 0;
    while (l->at < l->len) {
        char c = l->in[l->at];
        size_t start = l->at;

        if (frx_is_s((unsigned char)c)) { l->at++; continue; }

        switch (c) {
        case '(': l->at++; if (!frx_xlex_push(l, FRX_XT_LPAREN, start)) return 0; continue;
        case ')': l->at++; if (!frx_xlex_push(l, FRX_XT_RPAREN, start)) return 0; continue;
        case '[': l->at++; if (!frx_xlex_push(l, FRX_XT_LBRACK, start)) return 0; continue;
        case ']': l->at++; if (!frx_xlex_push(l, FRX_XT_RBRACK, start)) return 0; continue;
        case '@': l->at++; if (!frx_xlex_push(l, FRX_XT_AT, start)) return 0; continue;
        case ',': l->at++; if (!frx_xlex_push(l, FRX_XT_COMMA, start)) return 0; continue;
        case '+': l->at++; if (!frx_xlex_push(l, FRX_XT_PLUS, start)) return 0; continue;
        case '-': l->at++; if (!frx_xlex_push(l, FRX_XT_MINUS, start)) return 0; continue;
        case '|': l->at++; if (!frx_xlex_push(l, FRX_XT_PIPE, start)) return 0; continue;
        case '=': l->at++; if (!frx_xlex_push(l, FRX_XT_EQ, start)) return 0; continue;
        case '*':
            l->at++;
            if (!frx_xlex_push(l, frx_xlex_op_ok(l) ? FRX_XT_STAR : FRX_XT_NAME, start)) return 0;
            if (l->t[l->n - 1].kind == FRX_XT_NAME) {
                l->t[l->n - 1].s.p   = l->in + start;
                l->t[l->n - 1].s.len = 1;
            }
            continue;
        case '/':
            l->at++;
            if (l->at < l->len && l->in[l->at] == '/') {
                l->at++;
                if (!frx_xlex_push(l, FRX_XT_SLASH2, start)) return 0;
            } else if (!frx_xlex_push(l, FRX_XT_SLASH, start)) return 0;
            continue;
        case '!':
            if (l->at + 1 < l->len && l->in[l->at + 1] == '=') {
                l->at += 2;
                if (!frx_xlex_push(l, FRX_XT_NE, start)) return 0;
                continue;
            }
            return frx_xlex_fail(l, start, "'!' is only the start of '!='");
        case '<':
        case '>': {
            int ge = c == '>';
            l->at++;
            if (l->at < l->len && l->in[l->at] == '=') {
                l->at++;
                if (!frx_xlex_push(l, ge ? FRX_XT_GE : FRX_XT_LE, start)) return 0;
            } else if (!frx_xlex_push(l, ge ? FRX_XT_GT : FRX_XT_LT, start)) return 0;
            continue;
        }
        case '"':
        case '\'': {
            const char *end = (const char *)memchr(l->in + l->at + 1, c, l->len - l->at - 1);
            if (!end) return frx_xlex_fail(l, start, "a string literal is never closed");
            if (!frx_xlex_push(l, FRX_XT_LITERAL, start)) return 0;
            l->t[l->n - 1].s.p   = l->in + l->at + 1;
            l->t[l->n - 1].s.len = (size_t)(end - (l->in + l->at + 1));
            l->at = (size_t)(end - l->in) + 1;
            continue;
        }
        case '$': {
            size_t k;
            l->at++;
            k = frx_xlex_ncname(l->in + l->at, l->len - l->at);
            if (!k) return frx_xlex_fail(l, start, "'$' must be followed by a variable name");
            if (!frx_xlex_push(l, FRX_XT_VAR, start)) return 0;
            l->t[l->n - 1].s.p   = l->in + l->at;
            l->t[l->n - 1].s.len = k;
            l->at += k;
            /* a variable reference is a QName; a prefix is not resolvable
             * without a binding for variables, so only NCNames are taken */
            if (l->at < l->len && l->in[l->at] == ':')
                return frx_xlex_fail(l, start, "a variable name with a prefix is not bound");
            continue;
        }
        case ':':
            if (l->at + 1 < l->len && l->in[l->at + 1] == ':') {
                l->at += 2;
                if (!frx_xlex_push(l, FRX_XT_COLON2, start)) return 0;
                continue;
            }
            return frx_xlex_fail(l, start, "':' is only the start of '::' or the middle of a name");
        case '.':
            if (l->at + 1 < l->len && l->in[l->at + 1] == '.') {
                l->at += 2;
                if (!frx_xlex_push(l, FRX_XT_DOTDOT, start)) return 0;
                continue;
            }
            if (l->at + 1 < l->len && l->in[l->at + 1] >= '0' && l->in[l->at + 1] <= '9') {
                if (!frx_xlex_number(l)) return 0;
                continue;
            }
            l->at++;
            if (!frx_xlex_push(l, FRX_XT_DOT, start)) return 0;
            continue;
        default:
            break;
        }

        if (c >= '0' && c <= '9') {
            if (!frx_xlex_number(l)) return 0;
            continue;
        }

        {
            size_t k = frx_xlex_ncname(l->in + l->at, l->len - l->at);
            size_t total;
            if (!k) return frx_xlex_fail(l, start, "not a name, an operator or a literal");
            total = k;
            if (l->at + total + 1 < l->len && l->in[l->at + total] == ':'
                && l->in[l->at + total + 1] != ':') {
                if (l->in[l->at + total + 1] == '*') {
                    total += 2;                             /* prefix:* */
                } else {
                    size_t k2 = frx_xlex_ncname(l->in + l->at + total + 1,
                                                l->len - l->at - total - 1);
                    if (!k2) return frx_xlex_fail(l, start, "a colon must be followed by a name or '*'");
                    total += 1 + k2;
                }
            }
            if (total == k && frx_xlex_op_ok(l)) {
                int op = 0;
                if      (k == 3 && memcmp(l->in + l->at, "and", 3) == 0) op = FRX_XT_AND;
                else if (k == 2 && memcmp(l->in + l->at, "or",  2) == 0) op = FRX_XT_OR;
                else if (k == 3 && memcmp(l->in + l->at, "mod", 3) == 0) op = FRX_XT_MOD;
                else if (k == 3 && memcmp(l->in + l->at, "div", 3) == 0) op = FRX_XT_DIV;
                if (op) {
                    l->at += k;
                    if (!frx_xlex_push(l, op, start)) return 0;
                    continue;
                }
                return frx_xlex_fail(l, start, "an operator was expected here, and this name is not one");
            }
            if (!frx_xlex_push(l, FRX_XT_NAME, start)) return 0;
            l->t[l->n - 1].s.p   = l->in + l->at;
            l->t[l->n - 1].s.len = total;
            l->at += total;
            continue;
        }
    }
    return frx_xlex_push(l, FRX_XT_EOF, l->len);
}

#endif /* FRX_XPATH_LEX_H */
