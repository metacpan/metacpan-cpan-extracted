#ifndef XSH_MEM_H
#define XSH_MEM_H 1

#include "util.h" /* XSH_ASSERT() */

#ifdef DEBUGGING
# ifdef Poison
#  define XSH_POISON(D, N, T)      Poison((D), (N), T)
# endif
# ifdef PoisonNew
#  define XSH_POISON_NEW(D, N, T)  PoisonNew((D), (N), T)
#  define XSH_HAS_POISON_NEW       1
# endif
# ifdef PoisonFree
#  define XSH_POISON_FREE(D, N, T) PoisonFree((D), (N), T)
#  define XSH_HAS_POISON_FREE      1
# endif
#endif

#ifdef XSH_POISON
# ifndef XSH_POISON_NEW
#  define XSH_POISON_NEW(D, N, T)  XSH_POISON(D, N, T)
#  define XSH_HAS_POISON_NEW       1
# endif
# ifndef XSH_POISON_FREE
#  define XSH_POISON_FREE(D, N, T) XSH_POISON(D, N, T)
#  define XSH_HAS_POISON_FREE      1
# endif
#endif

#ifndef XSH_HAS_POISON_NEW
# define XSH_HAS_POISON_NEW  0
#endif
#ifndef XSH_HAS_POISON_FREE
# define XSH_HAS_POISON_FREE 0
#endif

/* --- Shared memory ------------------------------------------------------- */

/* Context for PerlMemShared_*() functions */
#ifdef PERL_IMPLICIT_SYS
# define pPMS  pTHX
# define pPMS_ pTHX_
# define aPMS  aTHX
# define aPMS_ aTHX_
#else
# define pPMS  void
# define pPMS_
# define aPMS
# define aPMS_
#endif

/* ... xsh_shared_alloc() .................................................. */

#if XSH_HAS_POISON_NEW

static void *xsh_shared_alloc(pPMS_ size_t size) {
#define xsh_shared_alloc(S) xsh_shared_alloc(aPMS_ (S))
 void *p;

 p = PerlMemShared_malloc(size);
 XSH_ASSERT(p);

 XSH_POISON_NEW(p, size, char);

 return p;
}

#else  /*  XSH_HAS_POISON_NEW */

#define xsh_shared_alloc(S) PerlMemShared_malloc(S)

#endif /* !XSH_HAS_POISON_NEW */

#define XSH_SHARED_ALLOC(D, N, T) ((D) = xsh_shared_alloc((N) * sizeof(T)))

/* ... xsh_shared_calloc() ................................................. */

#define xsh_shared_calloc(C, S) PerlMemShared_calloc((C), (S))

#define XSH_SHARED_CALLOC(D, N, T) ((D) = xsh_shared_calloc((N), sizeof(T)))

/* ... xsh_shared_free() ................................................... */

#if XSH_HAS_POISON_FREE

static void xsh_shared_free(pPMS_ void *p, size_t size) {
#define xsh_shared_free(P, S) xsh_shared_free(aPMS_ (P), (S))
 if (p)
  XSH_POISON_FREE(p, size, char);

 PerlMemShared_free(p);

 return;
}

#else  /*  XSH_HAS_POISON_FREE */

#define xsh_shared_free(P, S) PerlMemShared_free(P)

#endif /* !XSH_HAS_POISON_FREE */

#define XSH_SHARED_FREE(D, N, T) (xsh_shared_free((D), (N) * sizeof(T)), (D) = NULL)

/* ... xsh_shared_realloc() ................................................ */

#if XSH_HAS_POISON_NEW && XSH_HAS_POISON_FREE

static void *xsh_shared_realloc(pPMS_ void *p, size_t old_size, size_t new_size) {
#define xsh_shared_realloc(P, OS, NS) xsh_shared_realloc(aPMS_ (P), (OS), (NS))
 void *q;

 if (!p)
  return xsh_shared_alloc(new_size);

 if (!new_size) {
  xsh_shared_free(p, old_size);
  return xsh_shared_alloc(1);
 }

 if (new_size < old_size)
  XSH_POISON_FREE(((char *) p) + new_size, old_size - new_size, char);

 q = PerlMemShared_realloc(p, new_size);
 XSH_ASSERT(q);

 if (old_size < new_size)
  XSH_POISON_NEW(((char *) q) + old_size, new_size - old_size, char);

 return q;
}

#else  /*  XSH_HAS_POISON_NEW && XSH_HAS_POISON_FREE */

#define xsh_shared_realloc(P, OS, NS) PerlMemShared_realloc((P), (NS))

#endif /* !XSH_HAS_POISON_NEW || !XSH_HAS_POISON_FREE */

#define XSH_SHARED_REALLOC(D, OL, NL, T) ((D) = xsh_shared_realloc((D), (OL) * sizeof(T), (NL) * sizeof(T)))

/* ... xsh_shared_recalloc() ............................................... */

static void *xsh_shared_recalloc(pPMS_ void *p, size_t old_size, size_t new_size) {
#define xsh_shared_recalloc(P, OS, NS) xsh_shared_recalloc(aPMS_ (P), (OS), (NS))
 void *q;

#ifdef XSH_POISON_FREE
 if (new_size < old_size)
  XSH_POISON_FREE(((char *) p) + new_size, old_size - new_size, char);
#endif /* XSH_POISON_FREE */

 q = PerlMemShared_realloc(p, new_size);
 XSH_ASSERT(q);

 if (old_size < new_size)
  Zero(((char *) q) + old_size, new_size - old_size, char);

 return q;
}

#define XSH_SHARED_RECALLOC(D, OL, NL, T) ((D) = xsh_shared_recalloc((D), (OL) * sizeof(T), (NL) * sizeof(T)))

/* --- Interpreter-local memory -------------------------------------------- */

#ifndef Newx
# define Newx(D, N, T) New(0, (D), (N), T)
#endif

#ifndef PERL_POISON

#if XSH_HAS_POISON_NEW
# define XSH_LOCAL_ALLOC(D, N, T)  (Newx((D), (N), T), XSH_POISON_NEW((D), (N), T))
#endif

#if XSH_HAS_POISON_FREE
# define XSH_LOCAL_FREE(D, N, T) (XSH_POISON_FREE((D), (N), T), Safefree(D))
#endif

#if XSH_HAS_POISON_NEW && XSH_HAS_POISON_FREE
# define XSH_LOCAL_REALLOC(D, OL, NL, T) ((((D) && ((NL) < (OL))) ? XSH_POISON_FREE(((T *) (D)) + (NL), (OL) - (NL), T) : NOOP), Renew((D), (NL), T), (((OL) < (NL)) ? XSH_POISON_NEW(((T *) (D)) + (OL), (NL) - (OL), T) : NOOP))
#endif

#endif /* !PERL_POISON */

#ifndef XSH_LOCAL_ALLOC
# define XSH_LOCAL_ALLOC(D, N, T) Newx((D), (N), T)
#endif

#define XSH_LOCAL_CALLOC(D, N, T) Newxz((D), (N), T)

#ifndef XSH_LOCAL_FREE
# define XSH_LOCAL_FREE(D, N, T)  Safefree(D)
#endif

#ifndef XSH_LOCAL_REALLOC
# define XSH_LOCAL_REALLOC(D, OL, NL, T) Renew((D), (NL), T)
#endif

#endif /* XSH_MEM_H */
