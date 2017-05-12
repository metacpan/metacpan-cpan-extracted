/*-
 * Copyright 1997-2003 John-Mark Gurney.
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

/*
 *
 *	updated in 2009, by Sergey Aleynikov
 *  for safe usage inside perl
 *  see copyright notice in Fast.pod
 *
 */

#include "fibpriv.h"

#define swap(type, a, b)		\
		do {			\
			type c;		\
			c = a;		\
			a = b;		\
			b = c;		\
		} while (0)		\

#define INT_BITS        (sizeof(int) * 8)

static inline int
ceillog2(unsigned int a) {
	int oa;
	int i;
	unsigned int b;

	oa = a;
	b = INT_BITS / 2;
	i = 0;
	while (b) {
		i = (i << 1);
		if (a >= (1 << b)) {
			a /= (1 << b);
			i = i | 1;
		} else
			a &= (1 << b) - 1;
		b /= 2;
	}
	if ((1 << i) == oa){
		return i;
	}else{
		return i + 1;
	}
}

/*
 * Private Heap Functions
 */
static void
fh_deleteel(struct fibheap *h, struct fibheap_el *x) {
	void *data;
	int key;

	data = x->fhe_data;
	key = x->fhe_key;

	switch(h->fh_keys){
		case min_keyed:
			fh_replacekey(h, x, INT_MIN);
			break;

		case max_keyed:
			fh_replacekey(h, x, INT_MAX);
			break;

		case callback:
			fh_replacedata(h, x, NULL);
			break;
	}

	if (fh_extractminel(h) != x) {
		/*
		 * XXX - This should never happen as fh_replace should set it
		 * to min.
		 */
		croak("Extracted minimum was not the expected one");
	}

	x->fhe_data = data;
	x->fhe_key = key;
}

static inline void
fh_initheap(struct fibheap *heap) {
	heap->fh_Dl = -1;
}

static inline void
fh_emptyheap(struct fibheap *h) {
	SV* elem;
	/*
	 * We could do this even faster by walking each binomial tree, but
	 * this is simpler to code.
	 */
	while (elem = (SV*)fh_extractmin(h)){
		SvREFCNT_dec(elem);
	}
}

static void
fh_destroyheap(struct fibheap *h) {
	if(h->fh_keys == callback)
		SvREFCNT_dec(h->comparator);

	if (h->fh_cons != NULL)
		Safefree(h->fh_cons);

	Safefree(h);
}

/*
 * Public Heap Functions
 */
static inline struct fibheap *
fh_makeheap(enum fh_type type) {
	struct fibheap *n;

	Newxz(n, 1, struct fibheap);
	fh_initheap(n);
	n->fh_keys = type;

	return n;
}

static inline void
fh_union(struct fibheap *ha, struct fibheap *hb) {
	struct fibheap_el *x;

	if (ha->fh_root == NULL || hb->fh_root == NULL) {
		/* either one or both are empty */
		if (ha->fh_root == NULL) {
			fh_destroyheap(ha);
			ha = hb;
			return;
		} else {
			fh_destroyheap(hb);
			return;
		}
	}
	ha->fh_root->fhe_left->fhe_right = hb->fh_root;
	hb->fh_root->fhe_left->fhe_right = ha->fh_root;
	x = ha->fh_root->fhe_left;
	ha->fh_root->fhe_left = hb->fh_root->fhe_left;
	hb->fh_root->fhe_left = x;
	ha->fh_n += hb->fh_n;

	/* set fh_min if necessary */
	if (fh_compare(ha, hb->fh_min, ha->fh_min) < 0)
		ha->fh_min = hb->fh_min;

	fh_destroyheap(hb);
}

/*
 * Public Key Heap Functions
 */
static inline struct fibheap_el *
fh_insertkey(struct fibheap *h, int key, void *data) {
	struct fibheap_el *x;

	x = fhe_newelem();

	/* just insert on root list, and make sure it's not the new min */
	x->fhe_data = data;
	x->fhe_key = key;

	fh_insertel(h, x);

	return x;
}

static inline void
fh_replacedata(struct fibheap *h, struct fibheap_el *x, void *data){
	fh_replacekeydata(h, x, x->fhe_key, data);
}

static inline void
fh_replacekey(struct fibheap *h, struct fibheap_el *x, int key) {
	fh_replacekeydata(h, x, key, x->fhe_data);
}

static void
fh_replacekeydata(struct fibheap *h, struct fibheap_el *x, int key, void *data) {
	int okey;
	struct fibheap_el *y;
	int r;

	okey = x->fhe_key;

	/*
	 * we can increase a key by deleting and reinserting, that
	 * requires O(lgn) time.
	 */
	if ((r = fh_comparedata(h, key, data, x)) > 0) {
		fh_deleteel(h, x);

		x->fhe_data = data;
		x->fhe_key = key;

		fh_insertel(h, x);

		return;
	}

	x->fhe_data = data;
	x->fhe_key = key;

	/* because they are equal, we don't have to do anything */
	if (r == 0)
		return;

	y = x->fhe_p;

	if (h->fh_keys != callback && okey == key)
		return;

	if (y != NULL && fh_compare(h, x, y) <= 0) {
		fh_cut(h, x, y);
		fh_cascading_cut(h, y);
	}

	/*
	 * the = is so that the call from fh_deleteel will delete the proper
	 * element.
	 */
	if (fh_compare(h, x, h->fh_min) <= 0)
		h->fh_min = x;
}

/*
 * Public void * Heap Functions
 */
/*
 * this will return these values:
 *	NULL	failed for some reason
 *	ptr	token to use for manipulation of data
 */
static inline struct fibheap_el *
fh_insert(struct fibheap *h, void *data) {
	struct fibheap_el *x;

	x = fhe_newelem();

	/* just insert on root list, and make sure it's not the new min */
	x->fhe_data = data;

	fh_insertel(h, x);

	return x;
}

static inline void *
fh_min(struct fibheap const *h) {
	if (h->fh_min == NULL)
		return NULL;
	return h->fh_min->fhe_data;
}

static void *
fh_extractmin(struct fibheap *h) {
	struct fibheap_el *z;
	void *ret;

	ret = NULL;

	if (h->fh_min != NULL) {
		z = fh_extractminel(h);
		ret = z->fhe_data;
		fhe_destroy(z);
	}

	return ret;
}

/*
 * begin of private element fuctions
 */
static struct fibheap_el *
fh_extractminel(struct fibheap *h) {
	struct fibheap_el *ret;
	struct fibheap_el *x, *y, *orig;

	ret = h->fh_min;

	orig = NULL;
	/* put all the children on the root list */
	/* for true consistancy, we should use fhe_remove */
	for(x = ret->fhe_child; x != orig && x != NULL;) {
		if (orig == NULL)
			orig = x;
		y = x->fhe_right;
		x->fhe_p = NULL;
		fh_insertrootlist(h, x);
		x = y;
	}
	/* remove minimum from root list */
	fh_removerootlist(h, ret);
	h->fh_n--;

	/* if we aren't empty, consolidate the heap */
	if (h->fh_n == 0)
		h->fh_min = NULL;
	else {
		h->fh_min = ret->fhe_right;
		fh_consolidate(h);
	}

	return ret;
}

static void
fh_insertrootlist(struct fibheap *h, struct fibheap_el *x) {
	if (h->fh_root == NULL) {
		h->fh_root = x;
		x->fhe_left = x;
		x->fhe_right = x;
		return;
	}

	fhe_insertafter(h->fh_root, x);
}

static inline void
fh_removerootlist(struct fibheap *h, struct fibheap_el *x) {
	if (x->fhe_left == x)
		h->fh_root = NULL;
	else
		h->fh_root = fhe_remove(x);
}

static void
fh_consolidate(struct fibheap *h) {
	struct fibheap_el **a;
	struct fibheap_el *w;
	struct fibheap_el *y;
	struct fibheap_el *x;
	int i;
	int d;
	int D;

	fh_checkcons(h);

	/* assign a the value of h->fh_cons so I don't have to rewrite code */
	D = h->fh_Dl + 1;
	a = h->fh_cons;

	for (i = 0; i < D; i++)
		a[i] = NULL;

	while ((w = h->fh_root) != NULL) {
		x = w;
		fh_removerootlist(h, w);
		d = x->fhe_degree;
		/* XXX - assert that d < D */
		while(a[d] != NULL) {
			y = a[d];
			if (fh_compare(h, x, y) > 0)
				swap(struct fibheap_el *, x, y);
			fh_heaplink(h, y, x);
			a[d] = NULL;
			d++;
		}
		a[d] = x;
	}
	h->fh_min = NULL;
	for (i = 0; i < D; i++)
		if (a[i] != NULL) {
			fh_insertrootlist(h, a[i]);
			if (h->fh_min == NULL || fh_compare(h, a[i], h->fh_min) < 0)
				h->fh_min = a[i];
		}
}

static inline void
fh_heaplink(struct fibheap const *h, struct fibheap_el *y, struct fibheap_el *x) {
	/* make y a child of x */
	if (x->fhe_child == NULL)
		x->fhe_child = y;
	else
		fhe_insertbefore(x->fhe_child, y);
	y->fhe_p = x;
	x->fhe_degree++;
	y->fhe_mark = 0;
}

static inline void
fh_cut(struct fibheap *h, struct fibheap_el *x, struct fibheap_el *y) {
	fhe_remove(x);
	y->fhe_degree--;
	fh_insertrootlist(h, x);
	x->fhe_p = NULL;
	x->fhe_mark = 0;
}

static void
fh_cascading_cut(struct fibheap *h, struct fibheap_el *y) {
	struct fibheap_el *z;

	while ((z = y->fhe_p) != NULL) {
		if (y->fhe_mark == 0) {
			y->fhe_mark = 1;
			return;
		} else {
			fh_cut(h, y, z);
			y = z;
		}
	}
}

/*
 * begining of handling elements of fibheap
 */
static inline struct fibheap_el *
fhe_newelem() {
	struct fibheap_el *e;

	Newxz(e, 1, struct fibheap_el);
	fhe_initelem(e);

	return e;
}

static inline void
fhe_initelem(struct fibheap_el *e) {
	e->fhe_left = e;
	e->fhe_right = e;
}

static inline void
fhe_insertafter(struct fibheap_el *a, struct fibheap_el *b) {
	if (a == a->fhe_right) {
		a->fhe_right = b;
		a->fhe_left = b;
		b->fhe_right = a;
		b->fhe_left = a;
	} else {
		b->fhe_right = a->fhe_right;
		a->fhe_right->fhe_left = b;
		a->fhe_right = b;
		b->fhe_left = a;
	}
}

static inline void
fhe_insertbefore(struct fibheap_el *a, struct fibheap_el *b) {
	fhe_insertafter(a->fhe_left, b);
}

static struct fibheap_el *
fhe_remove(struct fibheap_el *x) {
	struct fibheap_el *ret;

	if (x == x->fhe_left)
		ret = NULL;
	else
		ret = x->fhe_left;

	/* fix the parent pointer */
	if (x->fhe_p != NULL && x->fhe_p->fhe_child == x)
		x->fhe_p->fhe_child = ret;

	x->fhe_right->fhe_left = x->fhe_left;
	x->fhe_left->fhe_right = x->fhe_right;

	/* clear out hanging pointers */
	x->fhe_p = NULL;
	x->fhe_left = x;
	x->fhe_right = x;

	return ret;
}

static inline void
fh_checkcons(struct fibheap *h) {
	int oDl;

	/* make sure we have enough memory allocated to "reorganize" */
	if (h->fh_Dl == -1 || h->fh_n > (1 << h->fh_Dl)) {
		oDl = h->fh_Dl;
		if ((h->fh_Dl = ceillog2(h->fh_n) + 1) < 8)
			h->fh_Dl = 8;
		if (oDl != h->fh_Dl)
			Renew(h->fh_cons, h->fh_Dl + 1, struct fibheap_el **);
	}
}

static inline int
int_key_min_compare(int a, int b){
	if (a < b)
		return -1;
	if (a == b)
		return 0;
	return 1;
}

static inline int
int_key_max_compare(int a, int b){
	if (a > b)
		return -1;
	if (a == b)
		return 0;
	return 1;
}

static int
data_compare(struct fibheap const *h, void const * a, void const * b){
	int iret;
	GV* local_a;
	GV* local_b;

	if(a == NULL)
		return -1;

	if(b == NULL)
		return 1;

	dSP;

/*	ENTER; SAVETMPS;	*/

	local_a = gv_fetchpv("a", TRUE, SVt_PV);
	local_b = gv_fetchpv("b", TRUE, SVt_PV);

	SAVESPTR(GvSV(local_a));
	SAVESPTR(GvSV(local_b));

	GvSV(local_a) = a;
	GvSV(local_b) = b;

	PUSHMARK(SP);
	iret = call_sv(h->comparator, G_SCALAR | G_NOARGS);
	SPAGAIN;

	if (iret != 1){
		croak("Your order routine didn't return a value");
	}
	iret = POPi;
	PUTBACK;

	if(iret < -1 || iret > 1){
		croak("Your order routine returned something odd: %d", iret);
	}

/*	FREETMPS; LEAVE;	*/

	return iret;
}

static int
fh_compare(struct fibheap const *h, struct fibheap_el const *a, struct fibheap_el const *b) {
	switch (h->fh_keys) {
		case min_keyed:
			return int_key_min_compare(a->fhe_key, b->fhe_key);

		case max_keyed:
			return int_key_max_compare(a->fhe_key, b->fhe_key);

		case callback:
			return data_compare(h, a->fhe_data, b->fhe_data);
	}
}

static inline int
fh_comparedata(struct fibheap const *h, int key, void *data, struct fibheap_el const *b) {
	struct fibheap_el a;

	a.fhe_key = key;
	a.fhe_data = data;

	return fh_compare(h, &a, b);
}

static void
fh_insertel(struct fibheap *h, struct fibheap_el *x) {
	fh_insertrootlist(h, x);

	if (h->fh_min == NULL || fh_compare(h, x, h->fh_min) < 0)
		h->fh_min = x;

	h->fh_n++;
}
