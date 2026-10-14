#ifndef HAMT_SV_H
#define HAMT_SV_H

/* The core's three value macros over an SV, and the seed. This is the one
 * header between perl and the core: it comes after perl.h and before every
 * other hamt/ header.
 *
 * `cx` is the interpreter on a perl that has one to pass and NULL on a perl
 * that does not, so a release reaches the right interpreter without a dTHX
 * lookup for every value. */

#ifdef PERL_IMPLICIT_CONTEXT
#  define HAMT_CX ((void *)aTHX)
#else
#  define HAMT_CX NULL
#endif

/* Not during global destruction. By then perl is freeing every scalar in an
 * order of its own, and one this library still holds may already be gone;
 * every object has had its DESTROY, so nothing is lost but memory the process
 * is about to give back anyway. */
static void hamt_sv_release_cx(void *cx, SV *sv) {
    dTHXa(cx);
    PERL_UNUSED_ARG(cx);
    if (PL_dirty) return;
    SvREFCNT_dec(sv);
}

/* Equal as `equals` means it by default: the same scalar; or two references
 * to the same thing; or two non-references that are the same string. Two
 * undefs are equal and an undef equals nothing else. */
static int hamt_sv_eq_cx(void *cx, SV *a, SV *b) {
    dTHXa(cx);
    PERL_UNUSED_ARG(cx);
    if (a == b) return 1;
    if (SvROK(a) || SvROK(b))
        return SvROK(a) && SvROK(b) && SvRV(a) == SvRV(b);
    if (!SvOK(a) || !SvOK(b))
        return !SvOK(a) && !SvOK(b);
    return sv_eq(a, b) ? 1 : 0;
}

#define HAMT_VAL_RETAIN(cx, v)  SvREFCNT_inc_simple_void_NN((SV *)(v))
#define HAMT_VAL_RELEASE(cx, v) hamt_sv_release_cx((cx), (SV *)(v))
#define HAMT_VAL_EQ(cx, a, b)   hamt_sv_eq_cx((cx), (SV *)(a), (SV *)(b))
#define HAMT_FATAL(msg)         Perl_croak_nocontext("HAMT: %s", (msg))

/* Every block the core holds, counted. A set has no values whose
 * destruction could show that a trie was freed, so this is what lets a test
 * say "nothing was leaked" about one; it costs an increment. It is one
 * number for the process and nothing locks it, so it means something only
 * while one thread is using the library, which is when the tests read it.
 *
 * malloc and free here are the C library's: hamt_compat.h, which follows,
 * takes back the names XSUB.h redefines. */
static long hamt_live_blocks = 0;

/* One pool, used by the interpreter that loaded the library and by no
 * other: a pool is one thread's, and a second interpreter is a second
 * thread. Any other interpreter allocates and frees directly. Both make
 * blocks of the same sizes, so it does not matter which of them frees a
 * block the other allocated.
 *
 * The pool is not perl's memory, so nothing perl frees on its way out can
 * leave it dangling: it is closed when the interpreter exits and whatever is
 * freed after that goes straight back to the C library.
 *
 * HAMT_NO_POOL at compile time takes it out, for a build that a memory
 * checker is going to read. */
#include "hamt/hamt_compat.h"
#include "hamt/hamt_pool.h"

#ifndef HAMT_NO_POOL
static hamt_pool hamt_pool_one;
static void     *hamt_pool_owner = NULL;
#  define HAMT_POOL_FOR(cx) \
      ((hamt_pool_one.open && (cx) == hamt_pool_owner) ? &hamt_pool_one : NULL)
#else
#  define HAMT_POOL_FOR(cx) ((hamt_pool *)NULL)
#endif

static void *hamt_xs_alloc(void *cx, size_t bytes) {
    void *p = hamt_pool_alloc(HAMT_POOL_FOR(cx), bytes);
    PERL_UNUSED_ARG(cx);
    if (p) hamt_live_blocks++;
    return p;
}
static void hamt_xs_free(void *cx, void *p, size_t bytes) {
    PERL_UNUSED_ARG(cx);
    hamt_live_blocks--;
    hamt_pool_free(HAMT_POOL_FOR(cx), p, bytes);
}

#define HAMT_ALLOC(cx, bytes)   hamt_xs_alloc((cx), (bytes))
#define HAMT_FREE(cx, p, bytes) hamt_xs_free((cx), (p), (bytes))

#endif
