/*-
 * Copyright 1997, 1999-2003 John-Mark Gurney.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */

#ifndef _FIBPRIV_H_
#define _FIBPRIV_H_

typedef int (*voidcmp)(void const *, void const *);
enum fh_type {min_keyed, max_keyed, callback};

struct fibheap_el {
	int		fhe_degree;
	int		fhe_mark;
	struct	fibheap_el *fhe_p;
	struct	fibheap_el *fhe_child;
	struct	fibheap_el *fhe_left;
	struct	fibheap_el *fhe_right;
	int		fhe_key;
	void	*fhe_data;
};
struct fibheap {
	SV*		comparator;
	int		fh_n;
	int		fh_Dl;
	struct	fibheap_el **fh_cons;
	struct	fibheap_el *fh_min;
	struct	fibheap_el *fh_root;
	enum	fh_type	fh_keys;
};

/*
 * global heap operations
 */

static inline void fh_initheap(struct fibheap *);
static void fh_insertrootlist(struct fibheap *h, struct fibheap_el *x);
static inline void fh_removerootlist(struct fibheap *, struct fibheap_el *);
static void fh_consolidate(struct fibheap *);
static inline void fh_heaplink(struct fibheap const *h, struct fibheap_el *y, struct fibheap_el *x);
static inline void fh_cut(struct fibheap *, struct fibheap_el *, struct fibheap_el *);
static void fh_cascading_cut(struct fibheap *, struct fibheap_el *);
static struct fibheap_el *fh_extractminel(struct fibheap *h);
static inline void fh_checkcons(struct fibheap * h);
static void fh_destroyheap(struct fibheap *h);
static inline void fh_emptyheap(struct fibheap *h);
static void fh_insertel(struct fibheap * h, struct fibheap_el *x);
static void fh_deleteel(struct fibheap *h, struct fibheap_el *x);

/*
 * specific node operations
 */

static inline struct fibheap_el *fhe_newelem(void);
static inline void fhe_initelem(struct fibheap_el *);
static inline void fhe_insertafter(struct fibheap_el *a, struct fibheap_el *b);
static inline void fhe_insertbefore(struct fibheap_el *a, struct fibheap_el *b);
static struct fibheap_el *fhe_remove(struct fibheap_el *a);
#define	fhe_destroy(x)	Safefree((x))

/*
 * general functions
 */
static inline int ceillog2(unsigned int a);

/* functions for key heaps */
static struct fibheap_el *fh_insertkey(struct fibheap *, int, void *);
static inline void fh_replacekey(struct fibheap *, struct fibheap_el *, int);
static void fh_replacekeydata(struct fibheap *, struct fibheap_el *, int, void *);

/* functions for void * heaps */
static struct fibheap *fh_makeheap(enum fh_type);
static voidcmp fh_setcmp(struct fibheap *, voidcmp);
static struct fibheap_el *fh_insert(struct fibheap *, void *);

/* shared functions */
static void *fh_extractmin(struct fibheap *);
static void *fh_min(struct fibheap const *);
static inline void fh_replacedata(struct fibheap *, struct fibheap_el *, void *);
static inline void fh_union(struct fibheap *, struct fibheap *);

/* compare */
static inline int int_key_min_compare(int a, int b);
static inline int int_key_max_compare(int a, int b);
static int data_compare(struct fibheap const *h, void const * a, void const * b);
static int fh_compare(struct fibheap const *h, struct fibheap_el const *a, struct fibheap_el const *b);
static inline int fh_comparedata(struct fibheap const *h, int key, void *data, struct fibheap_el const *b);

#endif /* _FIBPRIV_H_ */
