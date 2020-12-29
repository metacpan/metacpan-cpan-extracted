/*
  qsort_r.c from freebsd source code, original file:

  https://www.leidinger.net/FreeBSD/dox/libkern/html/d7/da4/qsort_8c_source.html
*/


typedef int json_create_cmp_t(void *, const void *, const void *);
static inline char *json_create_med3(char *, char *, char *, json_create_cmp_t *, void *);
static inline void json_create_swapfunc(char *, char *, size_t, int, int);

#define json_create_swapcode(TYPE, parmi, parmj, n) {	\
        size_t i = (n) / sizeof (TYPE);                 \
        TYPE *pi = (TYPE *) (parmi);			\
        TYPE *pj = (TYPE *) (parmj);			\
        do {                                            \
	    TYPE    t = *pi;				\
	    *pi++ = *pj;				\
	    *pj++ = t;					\
        } while (--i > 0);                              \
}

#define JSON_CREATE_SWAPINIT(TYPE, a, es) swaptype_ ## TYPE =	\
        ((char *)a - (char *)0) % sizeof(TYPE) ||		\
        es % sizeof(TYPE) ? 2 : es == sizeof(TYPE) ? 0 : 1;

#define JSON_CREATE_MIN(a,b) (((a)<(b))?(a):(b))

static inline void
json_create_swapfunc(char *a, char *b, size_t n, int swaptype_long, int swaptype_int)
{
        if (swaptype_long <= 1)
                json_create_swapcode(long, a, b, n)
        else if (swaptype_int <= 1)
                json_create_swapcode(int, a, b, n)
        else
                json_create_swapcode(char, a, b, n)
}

#define json_create_swap(a, b)						\
    if (swaptype_long == 0) {						\
	long t = *(long *)(a);						\
	*(long *)(a) = *(long *)(b);					\
	*(long *)(b) = t;						\
    } else if (swaptype_int == 0) {					\
	int t = *(int *)(a);						\
	*(int *)(a) = *(int *)(b);					\
	*(int *)(b) = t;						\
    } else								\
	json_create_swapfunc(a, b, es, swaptype_long, swaptype_int)

#define json_create_vecswap(a, b, n)                                \
        if ((n) > 0) json_create_swapfunc(a, b, n, swaptype_long, swaptype_int)

static inline char *
json_create_med3(char *a, char *b, char *c, json_create_cmp_t *cmp, void *thunk)
{
    return cmp(thunk, a, b) < 0 ?
	(cmp(thunk, b, c) < 0 ? b : (cmp(thunk, a, c) < 0 ? c : a ))
	:(cmp(thunk, b, c) > 0 ? b : (cmp(thunk, a, c) < 0 ? a : c ));
}

void
json_create_qsort_r(void *a, size_t n, size_t es, void *thunk, json_create_cmp_t *cmp)
{
    char *pa, *pb, *pc, *pd, *pl, *pm, *pn;
    size_t d1, d2;
    int cmp_result;
    int swaptype_long, swaptype_int, swap_cnt;

loop:   JSON_CREATE_SWAPINIT(long, a, es);
        JSON_CREATE_SWAPINIT(int, a, es);
        swap_cnt = 0;
        if (n < 7) {
                for (pm = (char *)a + es; pm < (char *)a + n * es; pm += es)
                        for (pl = pm; 
                             pl > (char *)a && cmp(thunk, pl - es, pl) > 0;
                             pl -= es)
                                json_create_swap(pl, pl - es);
                return;
        }
        pm = (char *)a + (n / 2) * es;
        if (n > 7) {
                pl = a;
                pn = (char *)a + (n - 1) * es;
                if (n > 40) {
                        size_t d = (n / 8) * es;

                        pl = json_create_med3(pl, pl + d, pl + 2 * d, cmp, thunk);
                        pm = json_create_med3(pm - d, pm, pm + d, cmp, thunk);
                        pn = json_create_med3(pn - 2 * d, pn - d, pn, cmp, thunk);
                }
                pm = json_create_med3(pl, pm, pn, cmp, thunk);
        }
        json_create_swap(a, pm);
        pa = pb = (char *)a + es;

        pc = pd = (char *)a + (n - 1) * es;
        for (;;) {
                while (pb <= pc && (cmp_result = cmp(thunk, pb, a)) <= 0) {
                        if (cmp_result == 0) {
                                swap_cnt = 1;
                                json_create_swap(pa, pb);
                                pa += es;
                        }
                        pb += es;
                }
                while (pb <= pc && (cmp_result = cmp(thunk, pc, a)) >= 0) {
                        if (cmp_result == 0) {
                                swap_cnt = 1;
                                json_create_swap(pc, pd);
                                pd -= es;
                        }
                        pc -= es;
                }
                if (pb > pc)
                        break;
                json_create_swap(pb, pc);
                swap_cnt = 1;
                pb += es;
                pc -= es;
        }
        if (swap_cnt == 0) {  /* Switch to insertion sort */
                for (pm = (char *)a + es; pm < (char *)a + n * es; pm += es)
                        for (pl = pm; 
                             pl > (char *)a && cmp(thunk, pl - es, pl) > 0;
                             pl -= es)
                                json_create_swap(pl, pl - es);
                return;
        }

        pn = (char *)a + n * es;
        d1 = JSON_CREATE_MIN(pa - (char *)a, pb - pa);
        json_create_vecswap(a, pb - d1, d1);
        d1 = JSON_CREATE_MIN(pd - pc, pn - pd - es);
        json_create_vecswap(pb, pn - d1, d1);

        d1 = pb - pa;
        d2 = pd - pc;
        if (d1 <= d2) {
                /* Recurse on left partition, then iterate on right partition */
                if (d1 > es) {
                        json_create_qsort_r(a, d1 / es, es, thunk, cmp);
                }
                if (d2 > es) {
                        /* Iterate rather than recurse to save stack space */
                        /* qsort(pn - d2, d2 / es, es, cmp); */
                        a = pn - d2;
                        n = d2 / es;
                        goto loop;
                }
        } else {
                /* Recurse on right partition, then iterate on left partition */
                if (d2 > es) {
                        json_create_qsort_r(pn - d2, d2 / es, es, thunk, cmp);
                }
                if (d1 > es) {
                        /* Iterate rather than recurse to save stack space */
                        /* qsort(a, d1 / es, es, cmp); */
                        n = d1 / es;
                        goto loop;
                }
        }
}

#undef JSON_CREATE_MIN
#undef json_create_swap
#undef json_create_swapcode
#undef JSON_CREATE_SWAPINIT
#undef json_create_vecswap
