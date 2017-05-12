#define PACKAGE_VERSION "0.23"
/*
 *  LibXDiff by Davide Libenzi ( File Differential Library )
 *  Copyright (C) 2003	Davide Libenzi
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  Davide Libenzi <davidel@xmailserver.org>
 *
 */

#include "xinclude.h"



#define XDL_MAX_COST_MIN 256
#define XDL_HEUR_MIN_COST 256
#define XDL_LINE_MAX (long)((1UL << (8 * sizeof(long) - 1)) - 1)
#define XDL_SNAKE_CNT 20
#define XDL_K_HEUR 4



typedef struct s_xdpsplit {
	long i1, i2;
	int min_lo, min_hi;
} xdpsplit_t;



/*
 * See "An O(ND) Difference Algorithm and its Variations", by Eugene Myers.
 * Basically considers a "box" (off1, off2, lim1, lim2) and scan from both
 * the forward diagonal starting from (off1, off2) and the backward diagonal
 * starting from (lim1, lim2). If the K values on the same diagonal crosses
 * returns the furthest point of reach. We might end up having to expensive
 * cases using this algorithm is full, so a little bit of heuristic is needed
 * to cut the search and to return a suboptimal point.
 */
static long xdl_split(unsigned long const *ha1, long off1, long lim1,
		      unsigned long const *ha2, long off2, long lim2,
		      long *kvdf, long *kvdb, int need_min, xdpsplit_t *spl,
		      xdalgoenv_t *xenv) {
	long dmin = off1 - lim2, dmax = lim1 - off2;
	long fmid = off1 - off2, bmid = lim1 - lim2;
	long odd = (fmid - bmid) & 1;
	long fmin = fmid, fmax = fmid;
	long bmin = bmid, bmax = bmid;
	long ec, d, i1, i2, prev1, best, dd, v, k;

	/*
	 * Set initial diagonal values for both forward and backward path.
	 */
	kvdf[fmid] = off1;
	kvdb[bmid] = lim1;

	for (ec = 1;; ec++) {
		int got_snake = 0;

		/*
		 * We need to extent the diagonal "domain" by one. If the next
		 * values exits the box boundaries we need to change it in the
		 * opposite direction because (max - min) must be a power of two.
		 * Also we initialize the extenal K value to -1 so that we can
		 * avoid extra conditions check inside the core loop.
		 */
		if (fmin > dmin)
			kvdf[--fmin - 1] = -1;
		else
			++fmin;
		if (fmax < dmax)
			kvdf[++fmax + 1] = -1;
		else
			--fmax;

		for (d = fmax; d >= fmin; d -= 2) {
			if (kvdf[d - 1] >= kvdf[d + 1])
				i1 = kvdf[d - 1] + 1;
			else
				i1 = kvdf[d + 1];
			prev1 = i1;
			i2 = i1 - d;
			for (; i1 < lim1 && i2 < lim2 && ha1[i1] == ha2[i2]; i1++, i2++);
			if (i1 - prev1 > xenv->snake_cnt)
				got_snake = 1;
			kvdf[d] = i1;
			if (odd && bmin <= d && d <= bmax && kvdb[d] <= i1) {
				spl->i1 = i1;
				spl->i2 = i2;
				spl->min_lo = spl->min_hi = 1;
				return ec;
			}
		}

		/*
		 * We need to extent the diagonal "domain" by one. If the next
		 * values exits the box boundaries we need to change it in the
		 * opposite direction because (max - min) must be a power of two.
		 * Also we initialize the extenal K value to -1 so that we can
		 * avoid extra conditions check inside the core loop.
		 */
		if (bmin > dmin)
			kvdb[--bmin - 1] = XDL_LINE_MAX;
		else
			++bmin;
		if (bmax < dmax)
			kvdb[++bmax + 1] = XDL_LINE_MAX;
		else
			--bmax;

		for (d = bmax; d >= bmin; d -= 2) {
			if (kvdb[d - 1] < kvdb[d + 1])
				i1 = kvdb[d - 1];
			else
				i1 = kvdb[d + 1] - 1;
			prev1 = i1;
			i2 = i1 - d;
			for (; i1 > off1 && i2 > off2 && ha1[i1 - 1] == ha2[i2 - 1]; i1--, i2--);
			if (prev1 - i1 > xenv->snake_cnt)
				got_snake = 1;
			kvdb[d] = i1;
			if (!odd && fmin <= d && d <= fmax && i1 <= kvdf[d]) {
				spl->i1 = i1;
				spl->i2 = i2;
				spl->min_lo = spl->min_hi = 1;
				return ec;
			}
		}

		if (need_min)
			continue;

		/*
		 * If the edit cost is above the heuristic trigger and if
		 * we got a good snake, we sample current diagonals to see
		 * if some of the, have reached an "interesting" path. Our
		 * measure is a function of the distance from the diagonal
		 * corner (i1 + i2) penalized with the distance from the
		 * mid diagonal itself. If this value is above the current
		 * edit cost times a magic factor (XDL_K_HEUR) we consider
		 * it interesting.
		 */
		if (got_snake && ec > xenv->heur_min) {
			for (best = 0, d = fmax; d >= fmin; d -= 2) {
				dd = d > fmid ? d - fmid: fmid - d;
				i1 = kvdf[d];
				i2 = i1 - d;
				v = (i1 - off1) + (i2 - off2) - dd;

				if (v > XDL_K_HEUR * ec && v > best &&
				    off1 + xenv->snake_cnt <= i1 && i1 < lim1 &&
				    off2 + xenv->snake_cnt <= i2 && i2 < lim2) {
					for (k = 1; ha1[i1 - k] == ha2[i2 - k]; k++)
						if (k == xenv->snake_cnt) {
							best = v;
							spl->i1 = i1;
							spl->i2 = i2;
							break;
						}
				}
			}
			if (best > 0) {
				spl->min_lo = 1;
				spl->min_hi = 0;
				return ec;
			}

			for (best = 0, d = bmax; d >= bmin; d -= 2) {
				dd = d > bmid ? d - bmid: bmid - d;
				i1 = kvdb[d];
				i2 = i1 - d;
				v = (lim1 - i1) + (lim2 - i2) - dd;

				if (v > XDL_K_HEUR * ec && v > best &&
				    off1 < i1 && i1 <= lim1 - xenv->snake_cnt &&
				    off2 < i2 && i2 <= lim2 - xenv->snake_cnt) {
					for (k = 0; ha1[i1 + k] == ha2[i2 + k]; k++)
						if (k == xenv->snake_cnt - 1) {
							best = v;
							spl->i1 = i1;
							spl->i2 = i2;
							break;
						}
				}
			}
			if (best > 0) {
				spl->min_lo = 0;
				spl->min_hi = 1;
				return ec;
			}
		}

		/*
		 * Enough is enough. We spent too much time here and now we collect
		 * the furthest reaching path using the (i1 + i2) measure.
		 */
		if (ec >= xenv->mxcost) {
			long fbest, fbest1, bbest, bbest1;

			fbest = -1;
			for (d = fmax; d >= fmin; d -= 2) {
				i1 = XDL_MIN(kvdf[d], lim1);
				i2 = i1 - d;
				if (lim2 < i2)
					i1 = lim2 + d, i2 = lim2;
				if (fbest < i1 + i2) {
					fbest = i1 + i2;
					fbest1 = i1;
				}
			}

			bbest = XDL_LINE_MAX;
			for (d = bmax; d >= bmin; d -= 2) {
				i1 = XDL_MAX(off1, kvdb[d]);
				i2 = i1 - d;
				if (i2 < off2)
					i1 = off2 + d, i2 = off2;
				if (i1 + i2 < bbest) {
					bbest = i1 + i2;
					bbest1 = i1;
				}
			}

			if ((lim1 + lim2) - bbest < fbest - (off1 + off2)) {
				spl->i1 = fbest1;
				spl->i2 = fbest - fbest1;
				spl->min_lo = 1;
				spl->min_hi = 0;
			} else {
				spl->i1 = bbest1;
				spl->i2 = bbest - bbest1;
				spl->min_lo = 0;
				spl->min_hi = 1;
			}
			return ec;
		}
	}

	return -1;
}


/*
 * Rule: "Divide et Impera". Recursively split the box in sub-boxes by calling
 * the box splitting function. Note that the real job (marking changed lines)
 * is done in the two boundary reaching checks.
 */
int xdl_recs_cmp(diffdata_t *dd1, long off1, long lim1,
		 diffdata_t *dd2, long off2, long lim2,
		 long *kvdf, long *kvdb, int need_min, xdalgoenv_t *xenv) {
	unsigned long const *ha1 = dd1->ha, *ha2 = dd2->ha;

	/*
	 * Shrink the box by walking through each diagonal snake (SW and NE).
	 */
	for (; off1 < lim1 && off2 < lim2 && ha1[off1] == ha2[off2]; off1++, off2++);
	for (; off1 < lim1 && off2 < lim2 && ha1[lim1 - 1] == ha2[lim2 - 1]; lim1--, lim2--);

	/*
	 * If one dimension is empty, then all records on the other one must
	 * be obviously changed.
	 */
	if (off1 == lim1) {
		char *rchg2 = dd2->rchg;
		long *rindex2 = dd2->rindex;

		for (; off2 < lim2; off2++)
			rchg2[rindex2[off2]] = 1;
	} else if (off2 == lim2) {
		char *rchg1 = dd1->rchg;
		long *rindex1 = dd1->rindex;

		for (; off1 < lim1; off1++)
			rchg1[rindex1[off1]] = 1;
	} else {
		long ec;
		xdpsplit_t spl;

		/*
		 * Divide ...
		 */
		if ((ec = xdl_split(ha1, off1, lim1, ha2, off2, lim2, kvdf, kvdb,
				    need_min, &spl, xenv)) < 0) {

			return -1;
		}

		/*
		 * ... et Impera.
		 */
		if (xdl_recs_cmp(dd1, off1, spl.i1, dd2, off2, spl.i2,
				 kvdf, kvdb, spl.min_lo, xenv) < 0 ||
		    xdl_recs_cmp(dd1, spl.i1, lim1, dd2, spl.i2, lim2,
				 kvdf, kvdb, spl.min_hi, xenv) < 0) {

			return -1;
		}
	}

	return 0;
}


int xdl_do_diff(mmfile_t *mf1, mmfile_t *mf2, xpparam_t const *xpp,
		xdfenv_t *xe) {
	long ndiags;
	long *kvd, *kvdf, *kvdb;
	xdalgoenv_t xenv;
	diffdata_t dd1, dd2;

	if (xdl_prepare_env(mf1, mf2, xpp, xe) < 0) {

		return -1;
	}

	/*
	 * Allocate and setup K vectors to be used by the differential algorithm.
	 * One is to store the forward path and one to store the backward path.
	 */
	ndiags = xe->xdf1.nreff + xe->xdf2.nreff + 3;
	if (!(kvd = (long *) xdl_malloc((2 * ndiags + 2) * sizeof(long)))) {

		xdl_free_env(xe);
		return -1;
	}
	kvdf = kvd;
	kvdb = kvdf + ndiags;
	kvdf += xe->xdf2.nreff + 1;
	kvdb += xe->xdf2.nreff + 1;

	xenv.mxcost = xdl_bogosqrt(ndiags);
	if (xenv.mxcost < XDL_MAX_COST_MIN)
		xenv.mxcost = XDL_MAX_COST_MIN;
	xenv.snake_cnt = XDL_SNAKE_CNT;
	xenv.heur_min = XDL_HEUR_MIN_COST;

	dd1.nrec = xe->xdf1.nreff;
	dd1.ha = xe->xdf1.ha;
	dd1.rchg = xe->xdf1.rchg;
	dd1.rindex = xe->xdf1.rindex;
	dd2.nrec = xe->xdf2.nreff;
	dd2.ha = xe->xdf2.ha;
	dd2.rchg = xe->xdf2.rchg;
	dd2.rindex = xe->xdf2.rindex;

	if (xdl_recs_cmp(&dd1, 0, dd1.nrec, &dd2, 0, dd2.nrec,
			 kvdf, kvdb, (xpp->flags & XDF_NEED_MINIMAL) != 0, &xenv) < 0) {

		xdl_free(kvd);
		xdl_free_env(xe);
		return -1;
	}

	xdl_free(kvd);

	return 0;
}


static xdchange_t *xdl_add_change(xdchange_t *xscr, long i1, long i2, long chg1, long chg2) {
	xdchange_t *xch;

	if (!(xch = (xdchange_t *) xdl_malloc(sizeof(xdchange_t))))
		return NULL;

	xch->next = xscr;
	xch->i1 = i1;
	xch->i2 = i2;
	xch->chg1 = chg1;
	xch->chg2 = chg2;

	return xch;
}


static int xdl_change_compact(xdfile_t *xdf, xdfile_t *xdfo) {
	long ix, ixo, ixs, ixref, grpsiz, nrec = xdf->nrec;
	char *rchg = xdf->rchg, *rchgo = xdfo->rchg;
	xrecord_t **recs = xdf->recs;

	/*
	 * This is the same of what GNU diff does. Move back and forward
	 * change groups for a consistent and pretty diff output. This also
	 * helps in finding joineable change groups and reduce the diff size.
	 */
	for (ix = ixo = 0;;) {
		/*
		 * Find the first changed line in the to-be-compacted file.
		 * We need to keep track of both indexes, so if we find a
		 * changed lines group on the other file, while scanning the
		 * to-be-compacted file, we need to skip it properly. Note
		 * that loops that are testing for changed lines on rchg* do
		 * not need index bounding since the array is prepared with
		 * a zero at position -1 and N.
		 */
		for (; ix < nrec && !rchg[ix]; ix++)
			while (rchgo[ixo++]);
		if (ix == nrec)
			break;

		/*
		 * Record the start of a changed-group in the to-be-compacted file
		 * and find the end of it, on both to-be-compacted and other file
		 * indexes (ix and ixo).
		 */
		ixs = ix;
		for (ix++; rchg[ix]; ix++);
		for (; rchgo[ixo]; ixo++);

		do {
			grpsiz = ix - ixs;

			/*
			 * If the line before the current change group, is equal to
			 * the last line of the current change group, shift backward
			 * the group.
			 */
			while (ixs > 0 && recs[ixs - 1]->ha == recs[ix - 1]->ha &&
			       XDL_RECMATCH(recs[ixs - 1], recs[ix - 1])) {
				rchg[--ixs] = 1;
				rchg[--ix] = 0;

				/*
				 * This change might have joined two change groups,
				 * so we try to take this scenario in account by moving
				 * the start index accordingly (and so the other-file
				 * end-of-group index).
				 */
				for (; rchg[ixs - 1]; ixs--);
				while (rchgo[--ixo]);
			}

			/*
			 * Record the end-of-group position in case we are matched
			 * with a group of changes in the other file (that is, the
			 * change record before the enf-of-group index in the other
			 * file is set).
			 */
			ixref = rchgo[ixo - 1] ? ix: nrec;

			/*
			 * If the first line of the current change group, is equal to
			 * the line next of the current change group, shift forward
			 * the group.
			 */
			while (ix < nrec && recs[ixs]->ha == recs[ix]->ha &&
			       XDL_RECMATCH(recs[ixs], recs[ix])) {
				rchg[ixs++] = 0;
				rchg[ix++] = 1;

				/*
				 * This change might have joined two change groups,
				 * so we try to take this scenario in account by moving
				 * the start index accordingly (and so the other-file
				 * end-of-group index). Keep tracking the reference
				 * index in case we are shifting together with a
				 * corresponding group of changes in the other file.
				 */
				for (; rchg[ix]; ix++);
				while (rchgo[++ixo])
					ixref = ix;
			}
		} while (grpsiz != ix - ixs);

		/*
		 * Try to move back the possibly merged group of changes, to match
		 * the recorded postion in the other file.
		 */
		while (ixref < ix) {
			rchg[--ixs] = 1;
			rchg[--ix] = 0;
			while (rchgo[--ixo]);
		}
	}

	return 0;
}


int xdl_build_script(xdfenv_t *xe, xdchange_t **xscr) {
	xdchange_t *cscr = NULL, *xch;
	char *rchg1 = xe->xdf1.rchg, *rchg2 = xe->xdf2.rchg;
	long i1, i2, l1, l2;

	/*
	 * Trivial. Collects "groups" of changes and creates an edit script.
	 */
	for (i1 = xe->xdf1.nrec, i2 = xe->xdf2.nrec; i1 >= 0 || i2 >= 0; i1--, i2--)
		if (rchg1[i1 - 1] || rchg2[i2 - 1]) {
			for (l1 = i1; rchg1[i1 - 1]; i1--);
			for (l2 = i2; rchg2[i2 - 1]; i2--);

			if (!(xch = xdl_add_change(cscr, i1, i2, l1 - i1, l2 - i2))) {
				xdl_free_script(cscr);
				return -1;
			}
			cscr = xch;
		}

	*xscr = cscr;

	return 0;
}


void xdl_free_script(xdchange_t *xscr) {
	xdchange_t *xch;

	while ((xch = xscr) != NULL) {
		xscr = xscr->next;
		xdl_free(xch);
	}
}


int xdl_diff(mmfile_t *mf1, mmfile_t *mf2, xpparam_t const *xpp,
	     xdemitconf_t const *xecfg, xdemitcb_t *ecb) {
	xdchange_t *xscr;
	xdfenv_t xe;

	if (xdl_do_diff(mf1, mf2, xpp, &xe) < 0) {

		return -1;
	}
	if (xdl_change_compact(&xe.xdf1, &xe.xdf2) < 0 ||
	    xdl_change_compact(&xe.xdf2, &xe.xdf1) < 0 ||
	    xdl_build_script(&xe, &xscr) < 0) {

		xdl_free_env(&xe);
		return -1;
	}
	if (xscr) {
		if (xdl_emit_diff(&xe, xscr, ecb, xecfg) < 0) {

			xdl_free_script(xscr);
			xdl_free_env(&xe);
			return -1;
		}
		xdl_free_script(xscr);
	}
	xdl_free_env(&xe);

	return 0;
}

/*
 *  LibXDiff by Davide Libenzi ( File Differential Library )
 *  Copyright (C) 2003  Davide Libenzi
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  Davide Libenzi <davidel@xmailserver.org>
 *
 */

#include "xinclude.h"


#define XDL_KPDIS_RUN 4
#define XDL_MAX_EQLIMIT 1024
#define XDL_SIMSCAN_WINDOWN 100


typedef struct s_xdlclass {
	struct s_xdlclass *next;
	unsigned long ha;
	char const *line;
	long size;
	long idx;
} xdlclass_t;

typedef struct s_xdlclassifier {
	unsigned int hbits;
	long hsize;
	xdlclass_t **rchash;
	chastore_t ncha;
	long count;
} xdlclassifier_t;



static int xdl_init_classifier(xdlclassifier_t *cf, long size) {
	long i;

	cf->hbits = xdl_hashbits((unsigned int) size);
	cf->hsize = 1 << cf->hbits;

	if (xdl_cha_init(&cf->ncha, sizeof(xdlclass_t), size / 4 + 1) < 0) {

		return -1;
	}
	if (!(cf->rchash = (xdlclass_t **) xdl_malloc(cf->hsize * sizeof(xdlclass_t *)))) {

		xdl_cha_free(&cf->ncha);
		return -1;
	}
	for (i = 0; i < cf->hsize; i++)
		cf->rchash[i] = NULL;

	cf->count = 0;

	return 0;
}


static void xdl_free_classifier(xdlclassifier_t *cf) {
	xdl_free(cf->rchash);
	xdl_cha_free(&cf->ncha);
}


static int xdl_classify_record(xdlclassifier_t *cf, xrecord_t **rhash, unsigned int hbits,
			       xrecord_t *rec) {
	long hi;
	char const *line;
	xdlclass_t *rcrec;

	line = rec->ptr;
	hi = (long) XDL_HASHLONG(rec->ha, cf->hbits);
	for (rcrec = cf->rchash[hi]; rcrec; rcrec = rcrec->next)
		if (rcrec->ha == rec->ha && rcrec->size == rec->size &&
		    !memcmp(line, rcrec->line, rec->size))
			break;

	if (!rcrec) {
		if (!(rcrec = xdl_cha_alloc(&cf->ncha))) {

			return -1;
		}
		rcrec->idx = cf->count++;
		rcrec->line = line;
		rcrec->size = rec->size;
		rcrec->ha = rec->ha;
		rcrec->next = cf->rchash[hi];
		cf->rchash[hi] = rcrec;
	}

	rec->ha = (unsigned long) rcrec->idx;

	hi = (long) XDL_HASHLONG(rec->ha, hbits);
	rec->next = rhash[hi];
	rhash[hi] = rec;

	return 0;
}


static int xdl_prepare_ctx(mmfile_t *mf, long narec, xpparam_t const *xpp,
			   xdlclassifier_t *cf, xdfile_t *xdf) {
	unsigned int hbits;
	long i, nrec, hsize, bsize;
	unsigned long hav;
	char const *blk, *cur, *top, *prev;
	xrecord_t *crec;
	xrecord_t **recs, **rrecs;
	xrecord_t **rhash;
	unsigned long *ha;
	char *rchg;
	long *rindex;

	if (xdl_cha_init(&xdf->rcha, sizeof(xrecord_t), narec / 4 + 1) < 0) {

		return -1;
	}
	if (!(recs = (xrecord_t **) xdl_malloc(narec * sizeof(xrecord_t *)))) {

		xdl_cha_free(&xdf->rcha);
		return -1;
	}

	hbits = xdl_hashbits((unsigned int) narec);
	hsize = 1 << hbits;
	if (!(rhash = (xrecord_t **) xdl_malloc(hsize * sizeof(xrecord_t *)))) {

		xdl_free(recs);
		xdl_cha_free(&xdf->rcha);
		return -1;
	}
	for (i = 0; i < hsize; i++)
		rhash[i] = NULL;

	nrec = 0;
	if ((cur = blk = xdl_mmfile_first(mf, &bsize)) != NULL) {
		for (top = blk + bsize;;) {
			if (cur >= top) {
				if (!(cur = blk = xdl_mmfile_next(mf, &bsize)))
					break;
				top = blk + bsize;
			}
			prev = cur;
			hav = xdl_hash_record(&cur, top);
			if (nrec >= narec) {
				narec *= 2;
				if (!(rrecs = (xrecord_t **) xdl_realloc(recs, narec * sizeof(xrecord_t *)))) {

					xdl_free(rhash);
					xdl_free(recs);
					xdl_cha_free(&xdf->rcha);
					return -1;
				}
				recs = rrecs;
			}
			if (!(crec = xdl_cha_alloc(&xdf->rcha))) {

				xdl_free(rhash);
				xdl_free(recs);
				xdl_cha_free(&xdf->rcha);
				return -1;
			}
			crec->ptr = prev;
			crec->size = (long) (cur - prev);
			crec->ha = hav;
			recs[nrec++] = crec;

			if (xdl_classify_record(cf, rhash, hbits, crec) < 0) {

				xdl_free(rhash);
				xdl_free(recs);
				xdl_cha_free(&xdf->rcha);
				return -1;
			}
		}
	}

	if (!(rchg = (char *) xdl_malloc(nrec + 2))) {

		xdl_free(rhash);
		xdl_free(recs);
		xdl_cha_free(&xdf->rcha);
		return -1;
	}
	memset(rchg, 0, nrec + 2);

	if (!(rindex = (long *) xdl_malloc((nrec + 1) * sizeof(long)))) {

		xdl_free(rchg);
		xdl_free(rhash);
		xdl_free(recs);
		xdl_cha_free(&xdf->rcha);
		return -1;
	}
	if (!(ha = (unsigned long *) xdl_malloc((nrec + 1) * sizeof(unsigned long)))) {

		xdl_free(rindex);
		xdl_free(rchg);
		xdl_free(rhash);
		xdl_free(recs);
		xdl_cha_free(&xdf->rcha);
		return -1;
	}

	xdf->nrec = nrec;
	xdf->recs = recs;
	xdf->hbits = hbits;
	xdf->rhash = rhash;
	xdf->rchg = rchg + 1;
	xdf->rindex = rindex;
	xdf->nreff = 0;
	xdf->ha = ha;
	xdf->dstart = 0;
	xdf->dend = nrec - 1;

	return 0;
}


static void xdl_free_ctx(xdfile_t *xdf) {
	xdl_free(xdf->rhash);
	xdl_free(xdf->rindex);
	xdl_free(xdf->rchg - 1);
	xdl_free(xdf->ha);
	xdl_free(xdf->recs);
	xdl_cha_free(&xdf->rcha);
}


static int xdl_clean_mmatch(char const *dis, long i, long s, long e) {
	long r, rdis0, rpdis0, rdis1, rpdis1;

	/*
	 * Limits the window the is examined during the similar-lines
	 * scan. The loops below stops when dis[i - r] == 1 (line that
	 * has no match), but there are corner cases where the loop
	 * proceed all the way to the extremities by causing huge
	 * performance penalties in case of big files.
	 */
	if (i - s > XDL_SIMSCAN_WINDOWN)
		s = i - XDL_SIMSCAN_WINDOWN;
	if (e - i > XDL_SIMSCAN_WINDOWN)
		e = i + XDL_SIMSCAN_WINDOWN;

	/*
	 * Scans the lines before 'i' to find a run of lines that either
	 * have no match (dis[j] == 0) or have multiple matches (dis[j] > 1).
	 * Note that we always call this function with dis[i] > 1, so the
	 * current line (i) is already a multimatch line.
	 */
	for (r = 1, rdis0 = 0, rpdis0 = 1; (i - r) >= s; r++) {
		if (!dis[i - r])
			rdis0++;
		else if (dis[i - r] == 2)
			rpdis0++;
		else
			break;
	}
	/*
	 * If the run before the line 'i' found only multimatch lines, we
	 * return 0 and hence we don't make the current line (i) discarded.
	 * We want to discard multimatch lines only when they appear in the
	 * middle of runs with nomatch lines (dis[j] == 0).
	 */
	if (rdis0 == 0)
		return 0;
	for (r = 1, rdis1 = 0, rpdis1 = 1; (i + r) <= e; r++) {
		if (!dis[i + r])
			rdis1++;
		else if (dis[i + r] == 2)
			rpdis1++;
		else
			break;
	}
	/*
	 * If the run after the line 'i' found only multimatch lines, we
	 * return 0 and hence we don't make the current line (i) discarded.
	 */
	if (rdis1 == 0)
		return 0;
	rdis1 += rdis0;
	rpdis1 += rpdis0;

	return rpdis1 * XDL_KPDIS_RUN < (rpdis1 + rdis1);
}


/*
 * Try to reduce the problem complexity, discard records that have no
 * matches on the other file. Also, lines that have multiple matches
 * might be potentially discarded if they happear in a run of discardable.
 */
static int xdl_cleanup_records(xdfile_t *xdf1, xdfile_t *xdf2) {
	long i, nm, rhi, nreff, mlim;
	unsigned long hav;
	xrecord_t **recs;
	xrecord_t *rec;
	char *dis, *dis1, *dis2;

	if (!(dis = (char *) xdl_malloc(xdf1->nrec + xdf2->nrec + 2))) {

		return -1;
	}
	memset(dis, 0, xdf1->nrec + xdf2->nrec + 2);
	dis1 = dis;
	dis2 = dis1 + xdf1->nrec + 1;

	if ((mlim = xdl_bogosqrt(xdf1->nrec)) > XDL_MAX_EQLIMIT)
		mlim = XDL_MAX_EQLIMIT;
	for (i = xdf1->dstart, recs = &xdf1->recs[xdf1->dstart]; i <= xdf1->dend; i++, recs++) {
		hav = (*recs)->ha;
		rhi = (long) XDL_HASHLONG(hav, xdf2->hbits);
		for (nm = 0, rec = xdf2->rhash[rhi]; rec; rec = rec->next)
			if (rec->ha == hav && ++nm == mlim)
				break;
		dis1[i] = (nm == 0) ? 0: (nm >= mlim) ? 2: 1;
	}

	if ((mlim = xdl_bogosqrt(xdf2->nrec)) > XDL_MAX_EQLIMIT)
		mlim = XDL_MAX_EQLIMIT;
	for (i = xdf2->dstart, recs = &xdf2->recs[xdf2->dstart]; i <= xdf2->dend; i++, recs++) {
		hav = (*recs)->ha;
		rhi = (long) XDL_HASHLONG(hav, xdf1->hbits);
		for (nm = 0, rec = xdf1->rhash[rhi]; rec; rec = rec->next)
			if (rec->ha == hav && ++nm == mlim)
				break;
		dis2[i] = (nm == 0) ? 0: (nm >= mlim) ? 2: 1;
	}

	for (nreff = 0, i = xdf1->dstart, recs = &xdf1->recs[xdf1->dstart];
	     i <= xdf1->dend; i++, recs++) {
		if (dis1[i] == 1 ||
		    (dis1[i] == 2 && !xdl_clean_mmatch(dis1, i, xdf1->dstart, xdf1->dend))) {
			xdf1->rindex[nreff] = i;
			xdf1->ha[nreff] = (*recs)->ha;
			nreff++;
		} else
			xdf1->rchg[i] = 1;
	}
	xdf1->nreff = nreff;

	for (nreff = 0, i = xdf2->dstart, recs = &xdf2->recs[xdf2->dstart];
	     i <= xdf2->dend; i++, recs++) {
		if (dis2[i] == 1 ||
		    (dis2[i] == 2 && !xdl_clean_mmatch(dis2, i, xdf2->dstart, xdf2->dend))) {
			xdf2->rindex[nreff] = i;
			xdf2->ha[nreff] = (*recs)->ha;
			nreff++;
		} else
			xdf2->rchg[i] = 1;
	}
	xdf2->nreff = nreff;

	xdl_free(dis);

	return 0;
}


/*
 * Early trim initial and terminal matching records.
 */
static int xdl_trim_ends(xdfile_t *xdf1, xdfile_t *xdf2) {
	long i, lim;
	xrecord_t **recs1, **recs2;

	recs1 = xdf1->recs;
	recs2 = xdf2->recs;
	for (i = 0, lim = XDL_MIN(xdf1->nrec, xdf2->nrec); i < lim;
	     i++, recs1++, recs2++)
		if ((*recs1)->ha != (*recs2)->ha)
			break;

	xdf1->dstart = xdf2->dstart = i;

	recs1 = xdf1->recs + xdf1->nrec - 1;
	recs2 = xdf2->recs + xdf2->nrec - 1;
	for (lim -= i, i = 0; i < lim; i++, recs1--, recs2--)
		if ((*recs1)->ha != (*recs2)->ha)
			break;

	xdf1->dend = xdf1->nrec - i - 1;
	xdf2->dend = xdf2->nrec - i - 1;

	return 0;
}


static int xdl_optimize_ctxs(xdfile_t *xdf1, xdfile_t *xdf2) {
	if (xdl_trim_ends(xdf1, xdf2) < 0 ||
	    xdl_cleanup_records(xdf1, xdf2) < 0) {

		return -1;
	}

	return 0;
}


int xdl_prepare_env(mmfile_t *mf1, mmfile_t *mf2, xpparam_t const *xpp,
		    xdfenv_t *xe) {
	long enl1, enl2;
	xdlclassifier_t cf;

	enl1 = xdl_guess_lines(mf1) + 1;
	enl2 = xdl_guess_lines(mf2) + 1;

	if (xdl_init_classifier(&cf, enl1 + enl2 + 1) < 0) {

		return -1;
	}

	if (xdl_prepare_ctx(mf1, enl1, xpp, &cf, &xe->xdf1) < 0) {

		xdl_free_classifier(&cf);
		return -1;
	}
	if (xdl_prepare_ctx(mf2, enl2, xpp, &cf, &xe->xdf2) < 0) {

		xdl_free_ctx(&xe->xdf1);
		xdl_free_classifier(&cf);
		return -1;
	}

	xdl_free_classifier(&cf);

	if (xdl_optimize_ctxs(&xe->xdf1, &xe->xdf2) < 0) {

		xdl_free_ctx(&xe->xdf2);
		xdl_free_ctx(&xe->xdf1);
		return -1;
	}

	return 0;
}


void xdl_free_env(xdfenv_t *xe) {
	xdl_free_ctx(&xe->xdf2);
	xdl_free_ctx(&xe->xdf1);
}

/*
 *  LibXDiff by Davide Libenzi ( File Differential Library )
 *  Copyright (C) 2003	Davide Libenzi
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  Davide Libenzi <davidel@xmailserver.org>
 *
 */

#include "xinclude.h"



#define XDL_MAX_FUZZ 3
#define XDL_MIN_SYNCLINES 4



typedef struct s_recinfo {
	char const *ptr;
	long size;
} recinfo_t;

typedef struct s_recfile {
	mmfile_t *mf;
	long nrec;
	recinfo_t *recs;
} recfile_t;

typedef struct s_hunkinfo {
	long s1, s2;
	long c1, c2;
	long cmn, radd, rdel, pctx, sctx;
} hunkinfo_t;

typedef struct s_patchstats {
	long adds, dels;
} patchstats_t;

typedef struct s_patch {
	recfile_t rf;
	hunkinfo_t hi;
	long hkrec;
	long hklen;
	long flags;
	patchstats_t ps;
	int fuzzies;
} patch_t;




static int xdl_load_hunk_info(char const *line, long size, hunkinfo_t *hki);
static int xdl_init_recfile(mmfile_t *mf, int ispatch, recfile_t *rf);
static void xdl_free_recfile(recfile_t *rf);
static char const *xdl_recfile_get(recfile_t *rf, long irec, long *size);
static int xdl_init_patch(mmfile_t *mf, long flags, patch_t *pch);
static void xdl_free_patch(patch_t *pch);
static int xdl_load_hunk(patch_t *pch, long hkrec);
static int xdl_first_hunk(patch_t *pch);
static int xdl_next_hunk(patch_t *pch);
static int xdl_line_match(patch_t *pch, const char *s, long ns, char const *m, long nm);
static int xdl_hunk_match(recfile_t *rf, long irec, patch_t *pch, int mode, int fuzz);
static int xdl_find_hunk(recfile_t *rf, long ibase, patch_t *pch, int mode,
			 int fuzz, long *hkpos, int *exact);
static int xdl_emit_rfile_line(recfile_t *rf, long line, xdemitcb_t *ecb);
static int xdl_flush_section(recfile_t *rf, long start, long top, xdemitcb_t *ecb);
static int xdl_apply_hunk(recfile_t *rf, long hkpos, patch_t *pch, int mode,
			  long *ibase, xdemitcb_t *ecb);
static int xdl_reject_hunk(recfile_t *rf, patch_t *pch, int mode,
			   xdemitcb_t *rjecb);
static int xdl_process_hunk(recfile_t *rff, patch_t *pch, long *ibase, int mode,
			    xdemitcb_t *ecb, xdemitcb_t *rjecb);




static int xdl_load_hunk_info(char const *line, long size, hunkinfo_t *hki) {
	char const *next;

	/*
	 * The diff header format should be:
	 *
	 *   @@ -OP,OC +NP,NC @@
	 *
	 * Unfortunately some software avoid to emit OP or/and NP in case
	 * of not existing old or new file (it should be mitted as zero).
	 * We need to handle both syntaxes.
	 */
	if (memcmp(line, "@@ -", 4))
		return -1;
	line += 4;
	size -= 4;

	if (!size || !XDL_ISDIGIT(*line))
		return -1;
	hki->s1 = xdl_atol(line, &next);
	size -= next - line;
	line = next;
	if (!size)
		return -1;
	if (*line == ',') {
		size--, line++;
		if (!size || !XDL_ISDIGIT(*line))
			return -1;
		hki->c1 = xdl_atol(line, &next);
		size -= next - line;
		line = next;
		if (!size || *line != ' ')
			return -1;
		size--, line++;
	} else if (*line == ' ') {
		size--, line++;
		hki->c1 = hki->s1;
		hki->s1 = 0;
	} else
		return -1;

	if (!size || *line != '+')
		return -1;
	size--, line++;
	if (!size || !XDL_ISDIGIT(*line))
		return -1;
	hki->s2 = xdl_atol(line, &next);
	size -= next - line;
	line = next;
	if (!size)
		return -1;
	if (*line == ',') {
		size--, line++;
		if (!size || !XDL_ISDIGIT(*line))
			return -1;
		hki->c2 = xdl_atol(line, &next);
		size -= next - line;
		line = next;
		if (!size || *line != ' ')
			return -1;
		size--, line++;
	} else if (*line == ' ') {
		size--, line++;
		hki->c2 = hki->s2;
		hki->s2 = 0;
	} else
		return -1;
	if (size < 2 || memcmp(line, "@@", 2) != 0)
		return -1;

	/*
	 * We start from zero, so decrement by one unless it's the special position
	 * '0' inside the unified diff (new or deleted file).
	 */
	if (hki->s1 > 0 && hki->c1 > 0)
		hki->s1--;
	if (hki->s2 > 0 && hki->c2 > 0)
		hki->s2--;

	return 0;
}


static int xdl_init_recfile(mmfile_t *mf, int ispatch, recfile_t *rf) {
	long narec, nrec, bsize;
	recinfo_t *recs, *rrecs;
	char const *blk, *cur, *top, *eol;

	narec = xdl_guess_lines(mf);
	if (!(recs = (recinfo_t *) xdl_malloc(narec * sizeof(recinfo_t)))) {

		return -1;
	}
	nrec = 0;
	if ((cur = blk = xdl_mmfile_first(mf, &bsize)) != NULL) {
		for (top = blk + bsize;;) {
			if (cur >= top) {
				if (!(cur = blk = xdl_mmfile_next(mf, &bsize)))
					break;
				top = blk + bsize;
			}
			if (nrec >= narec) {
				narec *= 2;
				if (!(rrecs = (recinfo_t *)
				      xdl_realloc(recs, narec * sizeof(recinfo_t)))) {

					xdl_free(recs);
					return -1;
				}
				recs = rrecs;
			}
			recs[nrec].ptr = cur;
			if (!(eol = memchr(cur, '\n', top - cur)))
				eol = top - 1;
			recs[nrec].size = (long) (eol - cur) + 1;
			if (ispatch && *cur == '\\' && nrec > 0 && recs[nrec - 1].size > 0 &&
			    recs[nrec - 1].ptr[recs[nrec - 1].size - 1] == '\n')
				recs[nrec - 1].size--;
			else
				nrec++;
			cur = eol + 1;
		}
	}
	rf->mf = mf;
	rf->nrec = nrec;
	rf->recs = recs;

	return 0;
}


static void xdl_free_recfile(recfile_t *rf) {

	xdl_free(rf->recs);
}


static char const *xdl_recfile_get(recfile_t *rf, long irec, long *size) {

	if (irec < 0 || irec >= rf->nrec)
		return NULL;
	*size = rf->recs[irec].size;

	return rf->recs[irec].ptr;
}


static int xdl_init_patch(mmfile_t *mf, long flags, patch_t *pch) {

	if (xdl_init_recfile(mf, 1, &pch->rf) < 0) {

		return -1;
	}
	pch->hkrec = 0;
	pch->hklen = 0;
	pch->flags = flags;
	pch->ps.adds = pch->ps.dels = 0;
	pch->fuzzies = 0;

	return 0;
}


static void xdl_free_patch(patch_t *pch) {

	xdl_free_recfile(&pch->rf);
}


static int xdl_load_hunk(patch_t *pch, long hkrec) {
	long size, i, nb;
	char const *line;

	for (;; hkrec++) {
		pch->hkrec = hkrec;
		if (!(line = xdl_recfile_get(&pch->rf, pch->hkrec, &size)))
			return 0;
		if (*line == '@')
			break;
	}
	if (xdl_load_hunk_info(line, size, &pch->hi) < 0) {

		return -1;
	}
	pch->hi.cmn = pch->hi.radd = pch->hi.rdel = pch->hi.pctx = pch->hi.sctx = 0;
	for (i = pch->hkrec + 1, nb = 0;
	     (line = xdl_recfile_get(&pch->rf, i, &size)) != NULL; i++) {
		if (*line == '@' || *line == '\n')
			break;
		if (*line == ' ') {
			nb++;
			pch->hi.cmn++;
		} else if (*line == '+') {
			if (pch->hi.radd + pch->hi.rdel == 0)
				pch->hi.pctx = nb;
			nb = 0;
			pch->hi.radd++;
		} else if (*line == '-') {
			if (pch->hi.radd + pch->hi.rdel == 0)
				pch->hi.pctx = nb;
			nb = 0;
			pch->hi.rdel++;
		} else {

			return -1;
		}
	}
	pch->hi.sctx = nb;
	if (pch->hi.cmn + pch->hi.radd != pch->hi.c2 ||
	    pch->hi.cmn + pch->hi.rdel != pch->hi.c1) {

		return -1;
	}
	pch->hklen = i - pch->hkrec - 1;

	return 1;
}


static int xdl_first_hunk(patch_t *pch) {

	return xdl_load_hunk(pch, 0);
}


static int xdl_next_hunk(patch_t *pch) {

	return xdl_load_hunk(pch, pch->hkrec + pch->hklen + 1);
}


static int xdl_line_match(patch_t *pch, const char *s, long ns, char const *m, long nm) {

	for (; ns > 0 && (s[ns - 1] == '\r' || s[ns - 1] == '\n'); ns--);
	for (; nm > 0 && (m[nm - 1] == '\r' || m[nm - 1] == '\n'); nm--);
	if (pch->flags & XDL_PATCH_IGNOREBSPACE) {
		for (; ns > 0 && (*s == ' ' || *s == '\t'); ns--, s++);
		for (; ns > 0 && (s[ns - 1] == ' ' || s[ns - 1] == '\t'); ns--);
		for (; nm > 0 && (*m == ' ' || *m == '\t'); nm--, m++);
		for (; nm > 0 && (m[nm - 1] == ' ' || m[nm - 1] == '\t'); nm--);
	}

	return ns == nm && memcmp(s, m, ns) == 0;
}


static int xdl_hunk_match(recfile_t *rf, long irec, patch_t *pch, int mode, int fuzz) {
	long i, j, z, fsize, psize, ptop, pfuzz, sfuzz, misses;
	char const *fline, *pline;

	/*
	 * Limit fuzz to not be greater than the prefix and suffix context.
	 */
	pfuzz = fuzz < pch->hi.pctx ? fuzz: pch->hi.pctx;
	sfuzz = fuzz < pch->hi.sctx ? fuzz: pch->hi.sctx;

	/*
	 * First loop through the prefix fuzz area. In this loop we simply
	 * note mismatching lines. We allow missing lines here, that is,
	 * some prefix context lines are missing.
	 */
	for (z = pfuzz, misses = 0, i = irec, j = pch->hkrec + 1,
	     ptop = pch->hkrec + 1 + pch->hklen - sfuzz;
	     z > 0 && i < rf->nrec && j < ptop; i++, j++, z--) {
		if (!(pline = xdl_recfile_get(&pch->rf, j, &psize)))
			return 0;
		if (!(fline = xdl_recfile_get(rf, i, &fsize)) ||
		    !xdl_line_match(pch, fline, fsize, pline + 1, psize - 1))
			misses++;
	}
	if (misses > fuzz)
		return 0;

	/*
	 * Strict match loop.
	 */
	for (; i < rf->nrec && j < ptop; i++, j++) {
		for (; j < ptop; j++) {
			if (!(pline = xdl_recfile_get(&pch->rf, j, &psize)))
				return 0;
			if (*pline == ' ' || *pline == mode)
				break;
		}
		if (j == ptop)
			break;
		if (!(fline = xdl_recfile_get(rf, i, &fsize)) ||
		    !xdl_line_match(pch, fline, fsize, pline + 1, psize - 1))
			return 0;
	}
	for (; j < ptop; j++)
		if (!(pline = xdl_recfile_get(&pch->rf, j, &psize)) ||
		    *pline == ' ' || *pline == mode)
			return 0;

	/*
	 * Finally loop through the suffix fuzz area. In this loop we simply
	 * note mismatching lines. We allow missing lines here, that is,
	 * some suffix context lines are missing.
	 */
	for (z = sfuzz; z > 0 && i < rf->nrec; i++, j++, z--) {
		if (!(pline = xdl_recfile_get(&pch->rf, j, &psize)))
			return 0;
		if (!(fline = xdl_recfile_get(rf, i, &fsize)) ||
		    !xdl_line_match(pch, fline, fsize, pline + 1, psize - 1))
			misses++;
	}

	return misses <= fuzz;
}


static int xdl_find_hunk(recfile_t *rf, long ibase, patch_t *pch, int mode,
			 int fuzz, long *hkpos, int *exact) {
	long hpos, hlen, i, j;
	long pos[2];

	hpos = mode == '-' ? pch->hi.s1: pch->hi.s2;
	hlen = mode == '-' ? pch->hi.cmn + pch->hi.rdel: pch->hi.cmn + pch->hi.radd;
	if (xdl_hunk_match(rf, hpos, pch, mode, fuzz)) {
		*hkpos = hpos;
		*exact = 1;
		return 1;
	}
	for (i = 1;; i++) {
		/*
		 * We allow a negative starting hunk position, up to the
		 * number of prefix context lines.
		 */
		j = 0;
		if (hpos - i >= ibase - pch->hi.pctx)
			pos[j++] = hpos - i;
		if (hpos + i + hlen <= rf->nrec)
			pos[j++] = hpos + i;
		if (!j)
			break;
		for (j--; j >= 0; j--)
			if (xdl_hunk_match(rf, pos[j], pch, mode, fuzz)) {
				*hkpos = pos[j];
				*exact = 0;
				return 1;
			}
	}

	return 0;
}


static int xdl_emit_rfile_line(recfile_t *rf, long line, xdemitcb_t *ecb) {
	mmbuffer_t mb;

	if (!(mb.ptr = (char *) xdl_recfile_get(rf, line, &mb.size)) ||
	    ecb->outf(ecb->priv, &mb, 1) < 0) {

		return -1;
	}

	return 0;
}


static int xdl_flush_section(recfile_t *rf, long start, long top, xdemitcb_t *ecb) {
	long i;

	for (i = start; i <= top; i++) {
		if (xdl_emit_rfile_line(rf, i, ecb) < 0) {

			return -1;
		}
	}

	return 0;
}


static int xdl_apply_hunk(recfile_t *rf, long hkpos, patch_t *pch, int mode,
			  long *ibase, xdemitcb_t *ecb) {
	long j, psize, ptop;
	char const *pline;
	mmbuffer_t mb;

	/*
	 * The hunk starting position (hkpos) can be negative, up to the number
	 * of prefix context lines. Since this function only emit the core of
	 * the hunk (the remaining lines are flushed by xdl_flush_section() calls)
	 * we need to normalize it by adding the number of prefix context lines.
	 * The normalized value of the starting position is then greater/equal
	 * to zero.
	 */
	hkpos += pch->hi.pctx;
	if (xdl_flush_section(rf, *ibase, hkpos - 1, ecb) < 0) {

		return -1;
	}
	*ibase = hkpos;
	for (j = pch->hkrec + 1 + pch->hi.pctx,
	     ptop = pch->hkrec + 1 + pch->hklen - pch->hi.sctx; j < ptop; j++) {
		if (!(pline = xdl_recfile_get(&pch->rf, j, &psize))) {

			return -1;
		}
		if (*pline == ' ') {
			if (xdl_emit_rfile_line(rf, *ibase, ecb) < 0) {

				return -1;
			}
			(*ibase)++;
		} else if (*pline != mode) {
			mb.ptr = (char *) pline + 1;
			mb.size = psize - 1;
			if (ecb->outf(ecb->priv, &mb, 1) < 0) {

				return -1;
			}
			pch->ps.adds++;
		} else {
			(*ibase)++;
			pch->ps.dels++;
		}
	}

	return 0;
}


static int xdl_reject_hunk(recfile_t *rf, patch_t *pch, int mode,
			   xdemitcb_t *rjecb) {
	long i, size, s1, s2, c1, c2;
	char const *line, *pre;
	mmbuffer_t mb;

	if (mode == '-') {
		s1 = pch->hi.s1;
		s2 = pch->hi.s2;
		c1 = pch->hi.c1;
		c2 = pch->hi.c2;
	} else {
		s1 = pch->hi.s2;
		s2 = pch->hi.s1;
		c1 = pch->hi.c2;
		c2 = pch->hi.c1;
	}
	s1 += pch->ps.adds - pch->ps.dels;
	if (xdl_emit_hunk_hdr(s1 + 1, c1, s2 + 1, c2, rjecb) < 0) {

		return -1;
	}
	for (i = pch->hkrec + 1;
	     (line = xdl_recfile_get(&pch->rf, i, &size)) != NULL; i++) {
		if (*line == '@' || *line == '\n')
			break;
		if (mode == '-' || *line == ' ') {
			mb.ptr = (char *) line;
			mb.size = size;
			if (rjecb->outf(rjecb->priv, &mb, 1) < 0) {

				return -1;
			}
		} else {
			pre = *line == '+' ? "-": "+";
			if (xdl_emit_diffrec(line + 1, size - 1, pre, strlen(pre),
					     rjecb) < 0) {

				return -1;
			}
		}
	}

	return 0;
}


static int xdl_process_hunk(recfile_t *rff, patch_t *pch, long *ibase, int mode,
			    xdemitcb_t *ecb, xdemitcb_t *rjecb) {
	int fuzz, exact, hlen, maxfuzz;
	long hkpos;

	hlen = mode == '-' ? pch->hi.cmn + pch->hi.rdel: pch->hi.cmn + pch->hi.radd;
	maxfuzz = XDL_MAX_FUZZ;
	if (hlen - maxfuzz < XDL_MIN_SYNCLINES)
		maxfuzz = hlen - XDL_MIN_SYNCLINES;
	if (maxfuzz < 0)
		maxfuzz = 0;
	for (fuzz = 0; fuzz <= maxfuzz; fuzz++) {
		if (xdl_find_hunk(rff, *ibase, pch, mode, fuzz,
				  &hkpos, &exact)) {
			if (xdl_apply_hunk(rff, hkpos, pch, mode,
					   ibase, ecb) < 0) {

				return -1;
			}
			if (!exact || fuzz)
				pch->fuzzies++;

			return 0;
		}
	}
	if (xdl_reject_hunk(rff, pch, mode, rjecb) < 0) {

		return -1;
	}

	return 0;
}


int xdl_patch(mmfile_t *mf, mmfile_t *mfp, int mode, xdemitcb_t *ecb,
	      xdemitcb_t *rjecb) {
	int hkres, exact;
	long hkpos, ibase;
	recfile_t rff;
	patch_t pch;

	if (xdl_init_recfile(mf, 0, &rff) < 0) {

		return -1;
	}
	if (xdl_init_patch(mfp, mode & ~XDL_PATCH_MODEMASK, &pch) < 0) {

		xdl_free_recfile(&rff);
		return -1;
	}
	mode &= XDL_PATCH_MODEMASK;
	ibase = 0;
	if ((hkres = xdl_first_hunk(&pch)) > 0) {
		do {
			if (xdl_process_hunk(&rff, &pch, &ibase, mode,
					     ecb, rjecb) < 0) {
				xdl_free_patch(&pch);
				xdl_free_recfile(&rff);
				return -1;
			}
		} while ((hkres = xdl_next_hunk(&pch)) > 0);
	}
	if (hkres < 0) {

		xdl_free_patch(&pch);
		xdl_free_recfile(&rff);
		return -1;
	}
	if (xdl_flush_section(&rff, ibase, rff.nrec - 1, ecb) < 0) {

		xdl_free_patch(&pch);
		xdl_free_recfile(&rff);
		return -1;
	}
	xdl_free_patch(&pch);
	xdl_free_recfile(&rff);

	return pch.fuzzies;
}

/*
 *  LibXDiff by Davide Libenzi ( File Differential Library )
 *  Copyright (C) 2003	Davide Libenzi
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  Davide Libenzi <davidel@xmailserver.org>
 *
 */

#include "xinclude.h"


#define XDL_MERGE3_BLKSIZE (1024 * 8)
#define XDL_MERGE3_CTXLEN 3



int xdl_merge3(mmfile_t *mmfo, mmfile_t *mmf1, mmfile_t *mmf2, xdemitcb_t *ecb,
	       xdemitcb_t *rjecb) {
	xpparam_t xpp;
	xdemitconf_t xecfg;
	xdemitcb_t xecb;
	mmfile_t mmfp;

	if (xdl_init_mmfile(&mmfp, XDL_MERGE3_BLKSIZE, XDL_MMF_ATOMIC) < 0) {

		return -1;
	}

	xpp.flags = 0;

	xecfg.ctxlen = XDL_MERGE3_CTXLEN;

	xecb.priv = &mmfp;
	xecb.outf = xdl_mmfile_outf;

	if (xdl_diff(mmfo, mmf2, &xpp, &xecfg, &xecb) < 0) {

		xdl_free_mmfile(&mmfp);
		return -1;
	}

	if (xdl_patch(mmf1, &mmfp, XDL_PATCH_NORMAL, ecb, rjecb) < 0) {

		xdl_free_mmfile(&mmfp);
		return -1;
	}

	xdl_free_mmfile(&mmfp);

	return 0;
}

/*
 *  LibXDiff by Davide Libenzi ( File Differential Library )
 *  Copyright (C) 2003	Davide Libenzi
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  Davide Libenzi <davidel@xmailserver.org>
 *
 */

#include "xinclude.h"


static long xdl_get_rec(xdfile_t *xdf, long ri, char const **rec) {

	*rec = xdf->recs[ri]->ptr;

	return xdf->recs[ri]->size;
}


static int xdl_emit_record(xdfile_t *xdf, long ri, char const *pre, xdemitcb_t *ecb) {
	long size, psize = strlen(pre);
	char const *rec;

	size = xdl_get_rec(xdf, ri, &rec);
	if (xdl_emit_diffrec(rec, size, pre, psize, ecb) < 0) {

		return -1;
	}

	return 0;
}


/*
 * Starting at the passed change atom, find the latest change atom to be included
 * inside the differential hunk according to the specified configuration.
 */
static xdchange_t *xdl_get_hunk(xdchange_t *xscr, xdemitconf_t const *xecfg) {
	xdchange_t *xch, *xchp;

	for (xchp = xscr, xch = xscr->next; xch; xchp = xch, xch = xch->next)
		if (xch->i1 - (xchp->i1 + xchp->chg1) > 2 * xecfg->ctxlen)
			break;

	return xchp;
}


int xdl_emit_diff(xdfenv_t *xe, xdchange_t *xscr, xdemitcb_t *ecb,
		  xdemitconf_t const *xecfg) {
	long s1, s2, e1, e2, lctx;
	xdchange_t *xch, *xche;

	for (xch = xche = xscr; xch; xch = xche->next) {
		xche = xdl_get_hunk(xch, xecfg);

		s1 = XDL_MAX(xch->i1 - xecfg->ctxlen, 0);
		s2 = XDL_MAX(xch->i2 - xecfg->ctxlen, 0);

		lctx = xecfg->ctxlen;
		lctx = XDL_MIN(lctx, xe->xdf1.nrec - (xche->i1 + xche->chg1));
		lctx = XDL_MIN(lctx, xe->xdf2.nrec - (xche->i2 + xche->chg2));

		e1 = xche->i1 + xche->chg1 + lctx;
		e2 = xche->i2 + xche->chg2 + lctx;

		/*
		 * Emit current hunk header.
		 */
		if (xdl_emit_hunk_hdr(s1 + 1, e1 - s1, s2 + 1, e2 - s2, ecb) < 0)
			return -1;

		/*
		 * Emit pre-context.
		 */
		for (; s1 < xch->i1; s1++)
			if (xdl_emit_record(&xe->xdf1, s1, " ", ecb) < 0)
				return -1;

		for (s1 = xch->i1, s2 = xch->i2;; xch = xch->next) {
			/*
			 * Merge previous with current change atom.
			 */
			for (; s1 < xch->i1 && s2 < xch->i2; s1++, s2++)
				if (xdl_emit_record(&xe->xdf1, s1, " ", ecb) < 0)
					return -1;

			/*
			 * Removes lines from the first file.
			 */
			for (s1 = xch->i1; s1 < xch->i1 + xch->chg1; s1++)
				if (xdl_emit_record(&xe->xdf1, s1, "-", ecb) < 0)
					return -1;

			/*
			 * Adds lines from the second file.
			 */
			for (s2 = xch->i2; s2 < xch->i2 + xch->chg2; s2++)
				if (xdl_emit_record(&xe->xdf2, s2, "+", ecb) < 0)
					return -1;

			if (xch == xche)
				break;
			s1 = xch->i1 + xch->chg1;
			s2 = xch->i2 + xch->chg2;
		}

		/*
		 * Emit post-context.
		 */
		for (s1 = xche->i1 + xche->chg1; s1 < e1; s1++)
			if (xdl_emit_record(&xe->xdf1, s1, " ", ecb) < 0)
				return -1;
	}

	return 0;
}

/*
 *  LibXDiff by Davide Libenzi ( File Differential Library )
 *  Copyright (C) 2003  Davide Libenzi
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  Davide Libenzi <davidel@xmailserver.org>
 *
 */

#include "xinclude.h"



#if !defined(HAVE_MEMCHR)

void *memchr(void const *p, int c, long n) {
	char const *pc = p;

	for (; n; n--, pc++)
		if (*pc == (char) c)
			return pc;
	return NULL;
}

#endif /* #if !defined(HAVE_MEMCHR) */


#if !defined(HAVE_MEMCMP)

int memcmp(void const *p1, void const *p2, long n) {
	char const *pc1 = p1, *pc2 = p2;

	for (; n; n--, pc1++, pc2++)
		if (*pc1 != *pc2)
			return *pc1 - *pc2;
	return 0;
}

#endif /* #if !defined(HAVE_MEMCMP) */


#if !defined(HAVE_MEMCPY)

void *memcpy(void *d, void const *s, long n) {
	char *dc = d;
	char const *sc = s;

	for (; n; n--, dc++, sc++)
		*dc = *sc;
	return d;
}

#endif /* #if !defined(HAVE_MEMCPY) */


#if !defined(HAVE_MEMSET)

void *memset(void *d, int c, long n) {
	char *dc = d;

	for (; n; n--, dc++)
		*dc = (char) c;
	return d;
}

#endif /* #if !defined(HAVE_MEMSET) */


#if !defined(HAVE_STRLEN)

long strlen(char const *s) {
	char const *tmp;

	for (tmp = s; *s; s++);
	return (long) (s - tmp);
}

#endif /* #if !defined(HAVE_STRLEN) */

/*
 *  LibXDiff by Davide Libenzi ( File Differential Library )
 *  Copyright (C) 2003	Davide Libenzi
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  Davide Libenzi <davidel@xmailserver.org>
 *
 */

#include "xinclude.h"



#define XDL_GUESS_NLINES 256




long xdl_bogosqrt(long n) {
	long i;

	/*
	 * Classical integer square root approximation using shifts.
	 */
	for (i = 1; n > 0; n >>= 2)
		i <<= 1;

	return i;
}


int xdl_emit_diffrec(char const *rec, long size, char const *pre, long psize,
		     xdemitcb_t *ecb) {
	int i = 2;
	mmbuffer_t mb[3];

	mb[0].ptr = (char *) pre;
	mb[0].size = psize;
	mb[1].ptr = (char *) rec;
	mb[1].size = size;
	if (size > 0 && rec[size - 1] != '\n') {
		mb[2].ptr = (char *) "\n\\ No newline at end of file\n";
		mb[2].size = strlen(mb[2].ptr);
		i++;
	}
	if (ecb->outf(ecb->priv, mb, i) < 0) {

		return -1;
	}

	return 0;
}


int xdl_init_mmfile(mmfile_t *mmf, long bsize, unsigned long flags) {

	mmf->flags = flags;
	mmf->head = mmf->tail = NULL;
	mmf->bsize = bsize;
	mmf->fsize = 0;
	mmf->rcur = mmf->wcur = NULL;
	mmf->rpos = 0;

	return 0;
}


void xdl_free_mmfile(mmfile_t *mmf) {
	mmblock_t *cur, *tmp;

	for (cur = mmf->head; (tmp = cur) != NULL;) {
		cur = cur->next;
		xdl_free(tmp);
	}
}


int xdl_mmfile_iscompact(mmfile_t *mmf) {

	return mmf->head == mmf->tail;
}


int xdl_seek_mmfile(mmfile_t *mmf, long off) {
	long bsize;

	if (xdl_mmfile_first(mmf, &bsize)) {
		do {
			if (off < bsize) {
				mmf->rpos = off;
				return 0;
			}
			off -= bsize;
		} while (xdl_mmfile_next(mmf, &bsize));
	}

	return -1;
}


long xdl_read_mmfile(mmfile_t *mmf, void *data, long size) {
	long rsize, csize;
	char *ptr = data;
	mmblock_t *rcur;

	for (rsize = 0, rcur = mmf->rcur; rcur && rsize < size;) {
		if (mmf->rpos >= rcur->size) {
			if (!(mmf->rcur = rcur = rcur->next))
				break;
			mmf->rpos = 0;
		}
		csize = XDL_MIN(size - rsize, rcur->size - mmf->rpos);
		memcpy(ptr, rcur->ptr + mmf->rpos, csize);
		rsize += csize;
		ptr += csize;
		mmf->rpos += csize;
	}

	return rsize;
}


long xdl_write_mmfile(mmfile_t *mmf, void const *data, long size) {
	long wsize, bsize, csize;
	mmblock_t *wcur;

	for (wsize = 0; wsize < size;) {
		wcur = mmf->wcur;
		if (wcur && (wcur->flags & XDL_MMB_READONLY))
			return wsize;
		if (!wcur || wcur->size == wcur->bsize ||
		    (mmf->flags & XDL_MMF_ATOMIC && wcur->size + size > wcur->bsize)) {
			bsize = XDL_MAX(mmf->bsize, size);
			if (!(wcur = (mmblock_t *) xdl_malloc(sizeof(mmblock_t) + bsize))) {

				return wsize;
			}
			wcur->flags = 0;
			wcur->ptr = (char *) wcur + sizeof(mmblock_t);
			wcur->size = 0;
			wcur->bsize = bsize;
			wcur->next = NULL;
			if (!mmf->head)
				mmf->head = wcur;
			if (mmf->tail)
				mmf->tail->next = wcur;
			mmf->tail = wcur;
			mmf->wcur = wcur;
		}
		csize = XDL_MIN(size - wsize, wcur->bsize - wcur->size);
		memcpy(wcur->ptr + wcur->size, (char const *) data + wsize, csize);
		wsize += csize;
		wcur->size += csize;
		mmf->fsize += csize;
	}

	return size;
}


long xdl_writem_mmfile(mmfile_t *mmf, mmbuffer_t *mb, int nbuf) {
	int i;
	long size;
	char *data;

	for (i = 0, size = 0; i < nbuf; i++)
		size += mb[i].size;
	if (!(data = (char *) xdl_mmfile_writeallocate(mmf, size)))
		return -1;
	for (i = 0; i < nbuf; i++) {
		memcpy(data, mb[i].ptr, mb[i].size);
		data += mb[i].size;
	}

	return size;
}


void *xdl_mmfile_writeallocate(mmfile_t *mmf, long size) {
	long bsize;
	mmblock_t *wcur;
	char *blk;

	if (!(wcur = mmf->wcur) || wcur->size + size > wcur->bsize) {
		bsize = XDL_MAX(mmf->bsize, size);
		if (!(wcur = (mmblock_t *) xdl_malloc(sizeof(mmblock_t) + bsize))) {

			return NULL;
		}
		wcur->flags = 0;
		wcur->ptr = (char *) wcur + sizeof(mmblock_t);
		wcur->size = 0;
		wcur->bsize = bsize;
		wcur->next = NULL;
		if (!mmf->head)
			mmf->head = wcur;
		if (mmf->tail)
			mmf->tail->next = wcur;
		mmf->tail = wcur;
		mmf->wcur = wcur;
	}

	blk = wcur->ptr + wcur->size;
	wcur->size += size;
	mmf->fsize += size;

	return blk;
}


long xdl_mmfile_ptradd(mmfile_t *mmf, char *ptr, long size, unsigned long flags) {
	mmblock_t *wcur;

	if (!(wcur = (mmblock_t *) xdl_malloc(sizeof(mmblock_t)))) {

		return -1;
	}
	wcur->flags = flags;
	wcur->ptr = ptr;
	wcur->size = wcur->bsize = size;
	wcur->next = NULL;
	if (!mmf->head)
		mmf->head = wcur;
	if (mmf->tail)
		mmf->tail->next = wcur;
	mmf->tail = wcur;
	mmf->wcur = wcur;

	mmf->fsize += size;

	return size;
}


long xdl_copy_mmfile(mmfile_t *mmf, long size, xdemitcb_t *ecb) {
	long rsize, csize;
	mmblock_t *rcur;
	mmbuffer_t mb;

	for (rsize = 0, rcur = mmf->rcur; rcur && rsize < size;) {
		if (mmf->rpos >= rcur->size) {
			if (!(mmf->rcur = rcur = rcur->next))
				break;
			mmf->rpos = 0;
		}
		csize = XDL_MIN(size - rsize, rcur->size - mmf->rpos);
		mb.ptr = rcur->ptr + mmf->rpos;
		mb.size = csize;
		if (ecb->outf(ecb->priv, &mb, 1) < 0) {

			return rsize;
		}
		rsize += csize;
		mmf->rpos += csize;
	}

	return rsize;
}


void *xdl_mmfile_first(mmfile_t *mmf, long *size) {

	if (!(mmf->rcur = mmf->head))
		return NULL;

	*size = mmf->rcur->size;

	return mmf->rcur->ptr;
}


void *xdl_mmfile_next(mmfile_t *mmf, long *size) {

	if (!mmf->rcur || !(mmf->rcur = mmf->rcur->next))
		return NULL;

	*size = mmf->rcur->size;

	return mmf->rcur->ptr;
}


long xdl_mmfile_size(mmfile_t *mmf) {

	return mmf->fsize;
}


int xdl_mmfile_cmp(mmfile_t *mmf1, mmfile_t *mmf2) {
	int cres;
	long size, bsize1, bsize2, size1, size2;
	char const *blk1, *cur1, *top1;
	char const *blk2, *cur2, *top2;

	if ((cur1 = blk1 = xdl_mmfile_first(mmf1, &bsize1)) != NULL)
		top1 = blk1 + bsize1;
	if ((cur2 = blk2 = xdl_mmfile_first(mmf2, &bsize2)) != NULL)
		top2 = blk2 + bsize2;
	if (!cur1) {
		if (!cur2 || xdl_mmfile_size(mmf2) == 0)
			return 0;
		return -*cur2;
	} else if (!cur2)
		return xdl_mmfile_size(mmf1) ? *cur1: 0;
	for (;;) {
		if (cur1 >= top1) {
			if ((cur1 = blk1 = xdl_mmfile_next(mmf1, &bsize1)) != NULL)
				top1 = blk1 + bsize1;
		}
		if (cur2 >= top2) {
			if ((cur2 = blk2 = xdl_mmfile_next(mmf2, &bsize2)) != NULL)
				top2 = blk2 + bsize2;
		}
		if (!cur1) {
			if (!cur2)
				break;
			return -*cur2;
		} else if (!cur2)
			return *cur1;
		size1 = top1 - cur1;
		size2 = top2 - cur2;
		size = XDL_MIN(size1, size2);
		if ((cres = memcmp(cur1, cur2, size)) != 0)
			return cres;
		cur1 += size;
		cur2 += size;
	}

	return 0;
}


int xdl_mmfile_compact(mmfile_t *mmfo, mmfile_t *mmfc, long bsize, unsigned long flags) {
	long fsize = xdl_mmfile_size(mmfo), size;
	char *data;
	char const *blk;

	if (xdl_init_mmfile(mmfc, bsize, flags) < 0) {

		return -1;
	}
	if (!(data = (char *) xdl_mmfile_writeallocate(mmfc, fsize))) {

		xdl_free_mmfile(mmfc);
		return -1;
	}
	if ((blk = (char const *) xdl_mmfile_first(mmfo, &size)) != NULL) {
		do {
			memcpy(data, blk, size);
			data += size;
		} while ((blk = (char const *) xdl_mmfile_next(mmfo, &size)) != NULL);
	}

	return 0;
}


int xdl_mmfile_outf(void *priv, mmbuffer_t *mb, int nbuf) {
	mmfile_t *mmf = priv;

	if (xdl_writem_mmfile(mmf, mb, nbuf) < 0) {

		return -1;
	}

	return 0;
}


int xdl_cha_init(chastore_t *cha, long isize, long icount) {

	cha->head = cha->tail = NULL;
	cha->isize = isize;
	cha->nsize = icount * isize;
	cha->ancur = cha->sncur = NULL;
	cha->scurr = 0;

	return 0;
}


void xdl_cha_free(chastore_t *cha) {
	chanode_t *cur, *tmp;

	for (cur = cha->head; (tmp = cur) != NULL;) {
		cur = cur->next;
		xdl_free(tmp);
	}
}


void *xdl_cha_alloc(chastore_t *cha) {
	chanode_t *ancur;
	void *data;

	if (!(ancur = cha->ancur) || ancur->icurr == cha->nsize) {
		if (!(ancur = (chanode_t *) xdl_malloc(sizeof(chanode_t) + cha->nsize))) {

			return NULL;
		}
		ancur->icurr = 0;
		ancur->next = NULL;
		if (cha->tail)
			cha->tail->next = ancur;
		if (!cha->head)
			cha->head = ancur;
		cha->tail = ancur;
		cha->ancur = ancur;
	}

	data = (char *) ancur + sizeof(chanode_t) + ancur->icurr;
	ancur->icurr += cha->isize;

	return data;
}


void *xdl_cha_first(chastore_t *cha) {
	chanode_t *sncur;

	if (!(cha->sncur = sncur = cha->head))
		return NULL;

	cha->scurr = 0;

	return (char *) sncur + sizeof(chanode_t) + cha->scurr;
}


void *xdl_cha_next(chastore_t *cha) {
	chanode_t *sncur;

	if (!(sncur = cha->sncur))
		return NULL;
	cha->scurr += cha->isize;
	if (cha->scurr == sncur->icurr) {
		if (!(sncur = cha->sncur = sncur->next))
			return NULL;
		cha->scurr = 0;
	}

	return (char *) sncur + sizeof(chanode_t) + cha->scurr;
}


long xdl_guess_lines(mmfile_t *mf) {
	long nl = 0, size, tsize = 0;
	char const *data, *cur, *top;

	if ((cur = data = xdl_mmfile_first(mf, &size)) != NULL) {
		for (top = data + size; nl < XDL_GUESS_NLINES;) {
			if (cur >= top) {
				tsize += (long) (cur - data);
				if (!(cur = data = xdl_mmfile_next(mf, &size)))
					break;
				top = data + size;
			}
			nl++;
			if (!(cur = memchr(cur, '\n', top - cur)))
				cur = top;
			else
				cur++;
		}
		tsize += (long) (cur - data);
	}

	if (nl && tsize)
		nl = xdl_mmfile_size(mf) / (tsize / nl);

	return nl + 1;
}


unsigned long xdl_hash_record(char const **data, char const *top) {
	unsigned long ha = 5381;
	char const *ptr = *data;

	for (; ptr < top && *ptr != '\n'; ptr++) {
		ha += (ha << 5);
		ha ^= (unsigned long) *ptr;
	}
	*data = ptr < top ? ptr + 1: ptr;

	return ha;
}


unsigned int xdl_hashbits(unsigned int size) {
	unsigned int val = 1, bits = 0;

	for (; val < size && bits < CHAR_BIT * sizeof(unsigned int); val <<= 1, bits++);
	return bits ? bits: 1;
}


int xdl_num_out(char *out, long val) {
	char *ptr, *str = out;
	char buf[32];

	ptr = buf + sizeof(buf) - 1;
	*ptr = '\0';
	if (val < 0) {
		*--ptr = '-';
		val = -val;
	}
	for (; val && ptr > buf; val /= 10)
		*--ptr = "0123456789"[val % 10];
	if (*ptr)
		for (; *ptr; ptr++, str++)
			*str = *ptr;
	else
		*str++ = '0';
	*str = '\0';

	return str - out;
}


long xdl_atol(char const *str, char const **next) {
	long val, base;
	char const *top;

	for (top = str; XDL_ISDIGIT(*top); top++);
	if (next)
		*next = top;
	for (val = 0, base = 1, top--; top >= str; top--, base *= 10)
		val += base * (long)(*top - '0');
	return val;
}


int xdl_emit_hunk_hdr(long s1, long c1, long s2, long c2, xdemitcb_t *ecb) {
	int nb = 0;
	mmbuffer_t mb;
	char buf[128];

	memcpy(buf, "@@ -", 4);
	nb += 4;

	nb += xdl_num_out(buf + nb, c1 ? s1: s1 - 1);

	memcpy(buf + nb, ",", 1);
	nb += 1;

	nb += xdl_num_out(buf + nb, c1);

	memcpy(buf + nb, " +", 2);
	nb += 2;

	nb += xdl_num_out(buf + nb, c2 ? s2: s2 - 1);

	memcpy(buf + nb, ",", 1);
	nb += 1;

	nb += xdl_num_out(buf + nb, c2);

	memcpy(buf + nb, " @@\n", 4);
	nb += 4;

	mb.ptr = buf;
	mb.size = nb;
	if (ecb->outf(ecb->priv, &mb, 1) < 0)
		return -1;

	return 0;
}

/*
 *  LibXDiff by Davide Libenzi ( File Differential Library )
 *  Copyright (C) 2003	Davide Libenzi
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  Davide Libenzi <davidel@xmailserver.org>
 *
 */

#include "xinclude.h"



/* largest prime smaller than 65536 */
#define BASE 65521L

/* NMAX is the largest n such that 255n(n+1)/2 + (n+1)(BASE-1) <= 2^32-1 */
#define NMAX 5552


#define DO1(buf, i)  { s1 += buf[i]; s2 += s1; }
#define DO2(buf, i)  DO1(buf, i); DO1(buf, i + 1);
#define DO4(buf, i)  DO2(buf, i); DO2(buf, i + 2);
#define DO8(buf, i)  DO4(buf, i); DO4(buf, i + 4);
#define DO16(buf)    DO8(buf, 0); DO8(buf, 8);



unsigned long xdl_adler32(unsigned long adler, unsigned char const *buf,
			  unsigned int len) {
	int k;
	unsigned long s1 = adler & 0xffff;
	unsigned long s2 = (adler >> 16) & 0xffff;

	if (!buf)
		return 1;

	while (len > 0) {
		k = len < NMAX ? len :NMAX;
		len -= k;
		while (k >= 16) {
			DO16(buf);
			buf += 16;
			k -= 16;
		}
		if (k != 0)
			do {
				s1 += *buf++;
				s2 += s1;
			} while (--k);
		s1 %= BASE;
		s2 %= BASE;
	}

	return (s2 << 16) | s1;
}

/*
 *  LibXDiff by Davide Libenzi ( File Differential Library )
 *  Copyright (C) 2003	Davide Libenzi
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  Davide Libenzi <davidel@xmailserver.org>
 *
 */

#include "xinclude.h"


typedef struct s_bdrecord {
	struct s_bdrecord *next;
	unsigned long fp;
	char const *ptr;
} bdrecord_t;

typedef struct s_bdfile {
	char const *data, *top;
	chastore_t cha;
	unsigned int fphbits;
	bdrecord_t **fphash;
} bdfile_t;



static int xdl_prepare_bdfile(mmbuffer_t *mmb, long fpbsize, bdfile_t *bdf) {
	unsigned int fphbits;
	long i, size, hsize;
	char const *base, *data, *top;
	bdrecord_t *brec;
	bdrecord_t **fphash;

	fphbits = xdl_hashbits((unsigned int) (mmb->size / fpbsize) + 1);
	hsize = 1 << fphbits;
	if (!(fphash = (bdrecord_t **) xdl_malloc(hsize * sizeof(bdrecord_t *)))) {

		return -1;
	}
	for (i = 0; i < hsize; i++)
		fphash[i] = NULL;

	if (xdl_cha_init(&bdf->cha, sizeof(bdrecord_t), hsize / 4 + 1) < 0) {

		xdl_free(fphash);
		return -1;
	}

	if (!(size = mmb->size)) {
		bdf->data = bdf->top = NULL;
	} else {
		bdf->data = data = base = mmb->ptr;
		bdf->top = top = mmb->ptr + mmb->size;

		if ((data += (size / fpbsize) * fpbsize) == top)
			data -= fpbsize;

		for (; data >= base; data -= fpbsize) {
			if (!(brec = (bdrecord_t *) xdl_cha_alloc(&bdf->cha))) {

				xdl_cha_free(&bdf->cha);
				xdl_free(fphash);
				return -1;
			}

			brec->fp = xdl_adler32(0, (unsigned char const *) data,
					       XDL_MIN(fpbsize, (long) (top - data)));
			brec->ptr = data;

			i = (long) XDL_HASHLONG(brec->fp, fphbits);
			brec->next = fphash[i];
			fphash[i] = brec;
		}
	}

	bdf->fphbits = fphbits;
	bdf->fphash = fphash;

	return 0;
}


static void xdl_free_bdfile(bdfile_t *bdf) {

	xdl_free(bdf->fphash);
	xdl_cha_free(&bdf->cha);
}


unsigned long xdl_mmb_adler32(mmbuffer_t *mmb) {

	return mmb->size ? xdl_adler32(0, (unsigned char const *) mmb->ptr, mmb->size): 0;
}


unsigned long xdl_mmf_adler32(mmfile_t *mmf) {
	unsigned long fp = 0;
	long size;
	char const *blk;

	if ((blk = (char const *) xdl_mmfile_first(mmf, &size)) != NULL) {
		do {
			fp = xdl_adler32(fp, (unsigned char const *) blk, size);
		} while ((blk = (char const *) xdl_mmfile_next(mmf, &size)) != NULL);
	}
	return fp;
}


int xdl_bdiff_mb(mmbuffer_t *mmb1, mmbuffer_t *mmb2, bdiffparam_t const *bdp, xdemitcb_t *ecb) {
	long i, rsize, size, bsize, csize, msize, moff;
	unsigned long fp;
	char const *blk, *base, *data, *top, *ptr1, *ptr2;
	bdrecord_t *brec;
	bdfile_t bdf;
	mmbuffer_t mb[2];
	unsigned char cpybuf[32];

	if ((bsize = bdp->bsize) < XDL_MIN_BLKSIZE)
		bsize = XDL_MIN_BLKSIZE;
	if (xdl_prepare_bdfile(mmb1, bsize, &bdf) < 0) {

		return -1;
	}

	/*
	 * Prepare and emit the binary patch file header. It will be used
	 * to verify that that file being patched matches in size and fingerprint
	 * the one that generated the patch.
	 */
	fp = xdl_mmb_adler32(mmb1);
	size = mmb1->size;
	XDL_LE32_PUT(cpybuf, fp);
	XDL_LE32_PUT(cpybuf + 4, size);

	mb[0].ptr = (char *) cpybuf;
	mb[0].size = 4 + 4;

	if (ecb->outf(ecb->priv, mb, 1) < 0) {

		xdl_free_bdfile(&bdf);
		return -1;
	}

	if ((blk = (char const *) mmb2->ptr) != NULL) {
		size = mmb2->size;
		for (base = data = blk, top = data + size; data < top;) {
			rsize = XDL_MIN(bsize, (long) (top - data));
			fp = xdl_adler32(0, (unsigned char const *) data, rsize);

			i = (long) XDL_HASHLONG(fp, bdf.fphbits);
			for (msize = 0, brec = bdf.fphash[i]; brec; brec = brec->next)
				if (brec->fp == fp) {
					csize = XDL_MIN((long) (top - data), (long) (bdf.top - brec->ptr));
					for (ptr1 = brec->ptr, ptr2 = data; csize && *ptr1 == *ptr2;
					     csize--, ptr1++, ptr2++);

					if ((csize = (long) (ptr1 - brec->ptr)) > msize) {
						moff = (long) (brec->ptr - bdf.data);
						msize = csize;
					}
				}

			if (msize < XDL_COPYOP_SIZE) {
				data++;
			} else {
				if (data > base) {
					i = (long) (data - base);
					if (i > 255) {
						cpybuf[0] = XDL_BDOP_INSB;
						XDL_LE32_PUT(cpybuf + 1, i);

						mb[0].ptr = (char *) cpybuf;
						mb[0].size = XDL_INSBOP_SIZE;
					} else {
						cpybuf[0] = XDL_BDOP_INS;
						cpybuf[1] = (unsigned char) i;

						mb[0].ptr = (char *) cpybuf;
						mb[0].size = 2;
					}
					mb[1].ptr = (char *) base;
					mb[1].size = i;

					if (ecb->outf(ecb->priv, mb, 2) < 0) {

						xdl_free_bdfile(&bdf);
						return -1;
					}
				}

				data += msize;

				cpybuf[0] = XDL_BDOP_CPY;
				XDL_LE32_PUT(cpybuf + 1, moff);
				XDL_LE32_PUT(cpybuf + 5, msize);

				mb[0].ptr = (char *) cpybuf;
				mb[0].size = XDL_COPYOP_SIZE;

				if (ecb->outf(ecb->priv, mb, 1) < 0) {

					xdl_free_bdfile(&bdf);
					return -1;
				}
				base = data;
			}
		}
		if (data > base) {
			i = (long) (data - base);
			if (i > 255) {
				cpybuf[0] = XDL_BDOP_INSB;
				XDL_LE32_PUT(cpybuf + 1, i);

				mb[0].ptr = (char *) cpybuf;
				mb[0].size = XDL_INSBOP_SIZE;
			} else {
				cpybuf[0] = XDL_BDOP_INS;
				cpybuf[1] = (unsigned char) i;

				mb[0].ptr = (char *) cpybuf;
				mb[0].size = 2;
			}
			mb[1].ptr = (char *) base;
			mb[1].size = i;

			if (ecb->outf(ecb->priv, mb, 2) < 0) {

				xdl_free_bdfile(&bdf);
				return -1;
			}
		}
	}

	xdl_free_bdfile(&bdf);

	return 0;
}


int xdl_bdiff(mmfile_t *mmf1, mmfile_t *mmf2, bdiffparam_t const *bdp, xdemitcb_t *ecb) {
	mmbuffer_t mmb1, mmb2;

	if (!xdl_mmfile_iscompact(mmf1) || !xdl_mmfile_iscompact(mmf2)) {

		return -1;
	}

	if ((mmb1.ptr = (char *) xdl_mmfile_first(mmf1, &mmb1.size)) == NULL)
		mmb1.size = 0;
	if ((mmb2.ptr = (char *) xdl_mmfile_first(mmf2, &mmb2.size)) == NULL)
		mmb2.size = 0;

	return xdl_bdiff_mb(&mmb1, &mmb2, bdp, ecb);
}


long xdl_bdiff_tgsize(mmfile_t *mmfp) {
	long tgsize = 0, size, off, csize;
	char const *blk;
	unsigned char const *data, *top;

	if ((blk = (char const *) xdl_mmfile_first(mmfp, &size)) == NULL ||
	    size < XDL_BPATCH_HDR_SIZE) {

		return -1;
	}
	blk += XDL_BPATCH_HDR_SIZE;
	size -= XDL_BPATCH_HDR_SIZE;

	do {
		for (data = (unsigned char const *) blk, top = data + size;
		     data < top;) {
			if (*data == XDL_BDOP_INS) {
				data++;
				csize = (long) *data++;
				tgsize += csize;
				data += csize;
			} else if (*data == XDL_BDOP_INSB) {
				data++;
				XDL_LE32_GET(data, csize);
				data += 4;
				tgsize += csize;
				data += csize;
			} else if (*data == XDL_BDOP_CPY) {
				data++;
				XDL_LE32_GET(data, off);
				data += 4;
				XDL_LE32_GET(data, csize);
				data += 4;
				tgsize += csize;
			} else {

				return -1;
			}
		}
	} while ((blk = (char const *) xdl_mmfile_next(mmfp, &size)) != NULL);

	return tgsize;
}

/*
 *  LibXDiff by Davide Libenzi ( File Differential Library )
 *  Copyright (C) 2003	Davide Libenzi
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  Davide Libenzi <davidel@xmailserver.org>
 *
 */

#include "xinclude.h"


#define XDL_MOBF_MINALLOC 128


typedef struct s_mmoffbuffer {
	long off, size;
	char *ptr;
} mmoffbuffer_t;



static int xdl_copy_range(mmfile_t *mmf, long off, long size, xdemitcb_t *ecb) {
	if (xdl_seek_mmfile(mmf, off) < 0) {

		return -1;
	}
	if (xdl_copy_mmfile(mmf, size, ecb) != size) {

		return -1;
	}

	return 0;
}


int xdl_bpatch(mmfile_t *mmf, mmfile_t *mmfp, xdemitcb_t *ecb) {
	long size, off, csize, osize;
	unsigned long fp, ofp;
	char const *blk;
	unsigned char const *data, *top;
	mmbuffer_t mb;

	if ((blk = (char const *) xdl_mmfile_first(mmfp, &size)) == NULL ||
	    size < XDL_BPATCH_HDR_SIZE) {

		return -1;
	}
	ofp = xdl_mmf_adler32(mmf);
	osize = xdl_mmfile_size(mmf);
	XDL_LE32_GET(blk, fp);
	XDL_LE32_GET(blk + 4, csize);
	if (fp != ofp || csize != osize) {

		return -1;
	}

	blk += XDL_BPATCH_HDR_SIZE;
	size -= XDL_BPATCH_HDR_SIZE;

	do {
		for (data = (unsigned char const *) blk, top = data + size;
		     data < top;) {
			if (*data == XDL_BDOP_INS) {
				data++;

				mb.size = (long) *data++;
				mb.ptr = (char *) data;
				data += mb.size;

				if (ecb->outf(ecb->priv, &mb, 1) < 0) {

					return -1;
				}
			} else if (*data == XDL_BDOP_INSB) {
				data++;
				XDL_LE32_GET(data, csize);
				data += 4;

				mb.size = csize;
				mb.ptr = (char *) data;
				data += mb.size;

				if (ecb->outf(ecb->priv, &mb, 1) < 0) {

					return -1;
				}
			} else if (*data == XDL_BDOP_CPY) {
				data++;
				XDL_LE32_GET(data, off);
				data += 4;
				XDL_LE32_GET(data, csize);
				data += 4;

				if (xdl_copy_range(mmf, off, csize, ecb) < 0) {

					return -1;
				}
			} else {

				return -1;
			}
		}
	} while ((blk = (char const *) xdl_mmfile_next(mmfp, &size)) != NULL);

	return 0;
}


static unsigned long xdl_mmob_adler32(mmoffbuffer_t *obf, int n) {
	unsigned long ha;

	for (ha = 0; n > 0; n--, obf++)
		ha = xdl_adler32(ha, (unsigned char const *) obf->ptr, obf->size);

	return ha;
}


static long xdl_mmob_size(mmoffbuffer_t *obf, int n) {

	return n > 0 ? obf[n - 1].off + obf[n - 1].size: 0;
}


static mmoffbuffer_t *xdl_mmob_new(mmoffbuffer_t **probf, int *pnobf, int *paobf) {
	int aobf;
	mmoffbuffer_t *cobf, *rrobf;

	if (*pnobf >= *paobf) {
		aobf = 2 * (*paobf) + 1;
		if ((rrobf = (mmoffbuffer_t *)
		     xdl_realloc(*probf, aobf * sizeof(mmoffbuffer_t))) == NULL) {

			return NULL;
		}
		*probf = rrobf;
		*paobf = aobf;
	}
	cobf = (*probf) + (*pnobf);
	(*pnobf)++;

	return cobf;
}


static int xdl_mmob_find_cntr(mmoffbuffer_t *obf, int n, long off) {
	int i, lo, hi;

	for (lo = -1, hi = n; hi - lo > 1;) {
		i = (hi + lo) / 2;
		if (off < obf[i].off)
			hi = i;
		else
			lo = i;
	}

	return (lo >= 0 && off >= obf[lo].off && off < obf[lo].off + obf[lo].size) ? lo: -1;
}


static int xdl_bmerge(mmoffbuffer_t *obf, int n, mmbuffer_t *mbfp, mmoffbuffer_t **probf,
		      int *pnobf) {
	int i, aobf, nobf;
	long ooff, off, csize;
	unsigned long fp, ofp;
	unsigned char const *data, *top;
	mmoffbuffer_t *robf, *cobf;

	if (mbfp->size < XDL_BPATCH_HDR_SIZE) {

		return -1;
	}
	data = (unsigned char const *) mbfp->ptr;
	top = data + mbfp->size;

	ofp = xdl_mmob_adler32(obf, n);
	XDL_LE32_GET(data, fp);
	data += 4;
	XDL_LE32_GET(data, csize);
	data += 4;
	if (fp != ofp || csize != xdl_mmob_size(obf, n)) {

		return -1;
	}
	aobf = XDL_MOBF_MINALLOC;
	nobf = 0;
	if ((robf = (mmoffbuffer_t *) xdl_malloc(aobf * sizeof(mmoffbuffer_t))) == NULL) {

		return -1;
	}

	for (ooff = 0; data < top;) {
		if (*data == XDL_BDOP_INS) {
			data++;

			if ((cobf = xdl_mmob_new(&robf, &nobf, &aobf)) == NULL) {

				xdl_free(robf);
				return -1;
			}
			cobf->off = ooff;
			cobf->size = (long) *data++;
			cobf->ptr = (char *) data;

			data += cobf->size;
			ooff += cobf->size;
		} else if (*data == XDL_BDOP_INSB) {
			data++;
			XDL_LE32_GET(data, csize);
			data += 4;

			if ((cobf = xdl_mmob_new(&robf, &nobf, &aobf)) == NULL) {

				xdl_free(robf);
				return -1;
			}
			cobf->off = ooff;
			cobf->size = csize;
			cobf->ptr = (char *) data;

			data += cobf->size;
			ooff += cobf->size;
		} else if (*data == XDL_BDOP_CPY) {
			data++;
			XDL_LE32_GET(data, off);
			data += 4;
			XDL_LE32_GET(data, csize);
			data += 4;

			if ((i = xdl_mmob_find_cntr(obf, n, off)) < 0) {

				xdl_free(robf);
				return -1;
			}
			off -= obf[i].off;
			for (; i < n && csize > 0; i++, off = 0) {
				if ((cobf = xdl_mmob_new(&robf, &nobf, &aobf)) == NULL) {

					xdl_free(robf);
					return -1;
				}
				cobf->off = ooff;
				cobf->size = XDL_MIN(csize, obf[i].size - off);
				cobf->ptr = obf[i].ptr + off;

				ooff += cobf->size;
				csize -= cobf->size;
			}
			if (csize > 0) {

				xdl_free(robf);
				return -1;
			}
		} else {

			xdl_free(robf);
			return -1;
		}
	}
	*probf = robf;
	*pnobf = nobf;

	return 0;
}


static int xdl_bmerge_synt(mmoffbuffer_t *obf, int n, xdemitcb_t *ecb) {
	int i;
	mmbuffer_t *mb;

	if ((mb = (mmbuffer_t *) xdl_malloc(n * sizeof(mmbuffer_t))) == NULL) {

		return -1;
	}
	for (i = 0; i < n; i++) {
		mb[i].ptr = obf[i].ptr;
		mb[i].size = obf[i].size;
	}
	if (ecb->outf(ecb->priv, mb, n) < 0) {

		xdl_free(mb);
		return -1;
	}
	xdl_free(mb);

	return 0;
}


int xdl_bpatch_multi(mmbuffer_t *base, mmbuffer_t *mbpch, int n, xdemitcb_t *ecb) {
	int i, nobf, fnobf;
	mmoffbuffer_t *obf, *fobf;

	nobf = 1;
	if ((obf = (mmoffbuffer_t *) xdl_malloc(nobf * sizeof(mmoffbuffer_t))) == NULL) {

		return -1;
	}
	obf->off = 0;
	obf->ptr = base->ptr;
	obf->size = base->size;
	for (i = 0; i < n; i++) {
		if (xdl_bmerge(obf, nobf, &mbpch[i], &fobf, &fnobf) < 0) {

			xdl_free(obf);
			return -1;
		}
		xdl_free(obf);

		obf = fobf;
		nobf = fnobf;
	}
	if (xdl_bmerge_synt(obf, nobf, ecb) < 0) {

		xdl_free(obf);
		return -1;
	}
	xdl_free(obf);

	return 0;
}

/*
 *  LibXDiff by Davide Libenzi ( File Differential Library )
 *  Copyright (C) 2003	Davide Libenzi
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  Davide Libenzi <davidel@xmailserver.org>
 *
 */

#include "xinclude.h"


char libxdiff_version[] = "LibXDiff v" PACKAGE_VERSION " by Davide Libenzi <davide@xmailserver.org>";

/*
 *  LibXDiff by Davide Libenzi ( File Differential Library )
 *  Copyright (C) 2003	Davide Libenzi
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  Davide Libenzi <davidel@xmailserver.org>
 *
 */

#include "xinclude.h"



static memallocator_t xmalt = {NULL, NULL, NULL};



int xdl_set_allocator(memallocator_t const *malt) {
	xmalt = *malt;
	return 0;
}


void *xdl_malloc(unsigned int size) {
	return xmalt.malloc ? xmalt.malloc(xmalt.priv, size): NULL;
}


void xdl_free(void *ptr) {
	if (xmalt.free)
		xmalt.free(xmalt.priv, ptr);
}


void *xdl_realloc(void *ptr, unsigned int size) {
	return xmalt.realloc ? xmalt.realloc(xmalt.priv, ptr, size): NULL;
}

/*
 *  xrabdiff by Davide Libenzi (Rabin's polynomial fingerprint based delta generator)
 *  Copyright (C) 2006  Davide Libenzi
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  Davide Libenzi <davidel@xmailserver.org>
 *
 *
 *  Hints, ideas and code for the implementation came from:
 *
 *  Rabin's original paper: http://www.xmailserver.org/rabin.pdf
 *  Chan & Lu's paper:      http://www.xmailserver.org/rabin_impl.pdf
 *  Broder's paper:         http://www.xmailserver.org/rabin_apps.pdf
 *  LBFS source code:       http://www.fs.net/sfswww/lbfs/
 *  Geert Bosch's post:     http://marc.theaimsgroup.com/?l=git&m=114565424620771&w=2
 *
 */

#include "xinclude.h"


#if !defined(XRABPLY_TYPE32) && !defined(XRABPLY_TYPE64)
#define XRABPLY_TYPE64 long long
#define XV64(v) ((xply_word) v ## ULL)
#endif

#include "xrabply.c"



#define XRAB_SLIDE(v, c) do {					\
		if (++wpos == XRAB_WNDSIZE) wpos = 0;		\
		v ^= U[wbuf[wpos]];				\
		wbuf[wpos] = (c);				\
		v = ((v << 8) | (c)) ^ T[v >> XRAB_SHIFT];	\
	} while (0)


#define XRAB_MINCPYSIZE 12
#define XRAB_WBITS (sizeof(xply_word) * 8)



typedef struct s_xrabctx {
	long idxsize;
	long *idx;
	unsigned char const *data;
	long size;
} xrabctx_t;

typedef struct s_xrabcpyi {
	long src;
	long tgt;
	long len;
} xrabcpyi_t;

typedef struct s_xrabcpyi_arena {
	long cnt, size;
	xrabcpyi_t *acpy;
} xrabcpyi_arena_t;



static void xrab_init_cpyarena(xrabcpyi_arena_t *aca) {
	aca->cnt = aca->size = 0;
	aca->acpy = NULL;
}


static void xrab_free_cpyarena(xrabcpyi_arena_t *aca) {
	xdl_free(aca->acpy);
}


static int xrab_add_cpy(xrabcpyi_arena_t *aca, xrabcpyi_t const *rcpy) {
	long size;
	xrabcpyi_t *acpy;

	if (aca->cnt >= aca->size) {
		size = 2 * aca->size + 1024;
		if ((acpy = (xrabcpyi_t *)
		     xdl_realloc(aca->acpy, size * sizeof(xrabcpyi_t))) == NULL)
			return -1;
		aca->acpy = acpy;
		aca->size = size;
	}
	aca->acpy[aca->cnt++] = *rcpy;

	return 0;
}


static long xrab_cmnseq(unsigned char const *data, long start, long size) {
	unsigned char ch = data[start];
	unsigned char const *ptr, *top;

	for (ptr = data + start + 1, top = data + size; ptr < top && ch == *ptr; ptr++);

	return (long) (ptr - (data + start + 1));
}


static int xrab_build_ctx(unsigned char const *data, long size, xrabctx_t *ctx) {
	long i, isize, idxsize, seq, wpos = 0;
	xply_word fp = 0, mask;
	unsigned char ch;
	unsigned char const *ptr, *eot;
	long *idx;
	unsigned char wbuf[XRAB_WNDSIZE];
	long maxoffs[256];
	long maxseq[256];
	xply_word maxfp[256];

	memset(wbuf, 0, sizeof(wbuf));
	memset(maxseq, 0, sizeof(maxseq));
	isize = 2 * (size / XRAB_WNDSIZE);
	for (idxsize = 1; idxsize < isize; idxsize <<= 1);
	mask = (xply_word) (idxsize - 1);
	if ((idx = (long *) xdl_malloc(idxsize * sizeof(long))) == NULL)
		return -1;
	memset(idx, 0, idxsize * sizeof(long));
	for (i = 0; i + XRAB_WNDSIZE < size; i += XRAB_WNDSIZE) {
		/*
		 * Generate a brand new hash for the current window. Here we could
		 * try to perform pseudo-loop unroll by 4 blocks if necessary, and
		 * if we force XRAB_WNDSIZE to be a multiple of 4, we could reduce
		 * the branch occurence inside XRAB_SLIDE by a factor of 4.
		 */
		for (ptr = data + i, eot = ptr + XRAB_WNDSIZE; ptr < eot; ptr++)
			XRAB_SLIDE(fp, *ptr);

		/*
		 * Try to scan for single value scans, and store them in the
		 * array according to the longest one. Before we do a fast check
		 * to avoid calling xrab_cmnseq() when not necessary.
		 */
		if ((ch = data[i]) == data[i + XRAB_WNDSIZE - 1] &&
		    (seq = xrab_cmnseq(data, i, size)) > XRAB_WNDSIZE &&
		    seq > maxseq[ch]) {
			maxseq[ch] = seq;
			maxfp[ch] = fp;
			maxoffs[ch] = i + XRAB_WNDSIZE;
			seq = (seq / XRAB_WNDSIZE) * XRAB_WNDSIZE;
			i += seq - XRAB_WNDSIZE;
		} else
			idx[fp & mask] = i + XRAB_WNDSIZE;
	}

	/*
	 * Restore back the logest sequences by overwriting target hash buckets.
	 */
	for (i = 0; i < 256; i++)
		if (maxseq[i])
			idx[maxfp[i] & mask] = maxoffs[i];
	ctx->idxsize = idxsize;
	ctx->idx = idx;
	ctx->data = data;
	ctx->size = size;

	return 0;
}


static void xrab_free_ctx(xrabctx_t *ctx) {

	xdl_free(ctx->idx);
}


static int xrab_diff(unsigned char const *data, long size, xrabctx_t *ctx,
		     xrabcpyi_arena_t *aca) {
	long i, offs, ssize, src, tgt, esrc, etgt, wpos = 0;
	xply_word fp = 0, mask;
	long const *idx;
	unsigned char const *sdata;
	xrabcpyi_t rcpy;
	unsigned char wbuf[XRAB_WNDSIZE];

	xrab_init_cpyarena(aca);
	memset(wbuf, 0, sizeof(wbuf));
	for (i = 0; i < XRAB_WNDSIZE - 1 && i < size; i++)
		XRAB_SLIDE(fp, data[i]);
	idx = ctx->idx;
	sdata = ctx->data;
	ssize = ctx->size;
	mask = (xply_word) (ctx->idxsize - 1);
	while (i < size) {
		unsigned char ch = data[i++];

		XRAB_SLIDE(fp, ch);
		offs = idx[fp & mask];

		/*
		 * Fast check here to probabilistically reduce false positives
		 * that would trigger the slow path below.
		 */
		if (offs == 0 || ch != sdata[offs - 1])
			continue;

		/*
		 * Stretch the match both sides as far as possible.
		 */
		src = offs - 1;
		tgt = i - 1;
		for (; tgt > 0 && src > 0 && data[tgt - 1] == sdata[src - 1];
		     tgt--, src--);
		esrc = offs;
		etgt = i;
		for (; etgt < size && esrc < ssize && data[etgt] == sdata[esrc];
		     etgt++, esrc++);

		/*
		 * Avoid considering copies smaller than the XRAB_MINCPYSIZE
		 * threshold.
		 */
		if (etgt - tgt >= XRAB_MINCPYSIZE) {
			rcpy.src = src;
			rcpy.tgt = tgt;
			rcpy.len = etgt - tgt;
			if (xrab_add_cpy(aca, &rcpy) < 0) {
				xrab_free_cpyarena(aca);
				return -1;
			}

			/*
			 * Fill up the new window and exit with 'i' properly set on exit.
			 */
			for (i = etgt - XRAB_WNDSIZE; i < etgt; i++)
				XRAB_SLIDE(fp, data[i]);
		}
	}

	return 0;
}


static int xrab_tune_cpyarena(unsigned char const *data, long size, xrabctx_t *ctx,
			      xrabcpyi_arena_t *aca) {
	long i, cpos;
	xrabcpyi_t *rcpy;

	for (cpos = size, i = aca->cnt - 1; i >= 0; i--) {
		rcpy = aca->acpy + i;
		if (rcpy->tgt >= cpos)
			rcpy->len = 0;
		else if (rcpy->tgt + rcpy->len > cpos) {
			if ((rcpy->len = cpos - rcpy->tgt) >= XRAB_MINCPYSIZE)
				cpos = rcpy->tgt;
			else
				rcpy->len = 0;
		} else
			cpos = rcpy->tgt;
	}

	return 0;
}


int xdl_rabdiff_mb(mmbuffer_t *mmb1, mmbuffer_t *mmb2, xdemitcb_t *ecb) {
	long i, cpos, size;
	unsigned long fp;
	xrabcpyi_t *rcpy;
	xrabctx_t ctx;
	xrabcpyi_arena_t aca;
	mmbuffer_t mb[2];
	unsigned char cpybuf[32];

	fp = xdl_mmb_adler32(mmb1);
	if (xrab_build_ctx((unsigned char const *) mmb1->ptr, mmb1->size,
			   &ctx) < 0)
		return -1;
	if (xrab_diff((unsigned char const *) mmb2->ptr, mmb2->size, &ctx,
		      &aca) < 0) {
		xrab_free_ctx(&ctx);
		return -1;
	}
	xrab_tune_cpyarena((unsigned char const *) mmb2->ptr, mmb2->size, &ctx,
			   &aca);
	xrab_free_ctx(&ctx);

	/*
	 * Prepare and emit the binary patch file header. It will be used
	 * to verify that that file being patched matches in size and fingerprint
	 * the one that generated the patch.
	 */
	size = mmb1->size;
	XDL_LE32_PUT(cpybuf, fp);
	XDL_LE32_PUT(cpybuf + 4, size);

	mb[0].ptr = (char *) cpybuf;
	mb[0].size = 4 + 4;
	if (ecb->outf(ecb->priv, mb, 1) < 0) {
		xrab_free_cpyarena(&aca);
		return -1;
	}
	for (cpos = 0, i = 0; i < aca.cnt; i++) {
		rcpy = aca.acpy + i;
		if (rcpy->len == 0)
			continue;
		if (cpos < rcpy->tgt) {
			size = rcpy->tgt - cpos;
			if (size > 255) {
				cpybuf[0] = XDL_BDOP_INSB;
				XDL_LE32_PUT(cpybuf + 1, size);
				mb[0].ptr = (char *) cpybuf;
				mb[0].size = XDL_INSBOP_SIZE;
			} else {
				cpybuf[0] = XDL_BDOP_INS;
				cpybuf[1] = (unsigned char) size;
				mb[0].ptr = (char *) cpybuf;
				mb[0].size = 2;
			}
			mb[1].ptr = mmb2->ptr + cpos;
			mb[1].size = size;
			if (ecb->outf(ecb->priv, mb, 2) < 0) {
				xrab_free_cpyarena(&aca);
				return -1;
			}
			cpos = rcpy->tgt;
		}
		cpybuf[0] = XDL_BDOP_CPY;
		XDL_LE32_PUT(cpybuf + 1, rcpy->src);
		XDL_LE32_PUT(cpybuf + 5, rcpy->len);
		mb[0].ptr = (char *) cpybuf;
		mb[0].size = XDL_COPYOP_SIZE;
		if (ecb->outf(ecb->priv, mb, 1) < 0) {
			xrab_free_cpyarena(&aca);
			return -1;
		}
		cpos += rcpy->len;
	}
	xrab_free_cpyarena(&aca);
	if (cpos < mmb2->size) {
		size = mmb2->size - cpos;
		if (size > 255) {
			cpybuf[0] = XDL_BDOP_INSB;
			XDL_LE32_PUT(cpybuf + 1, size);
			mb[0].ptr = (char *) cpybuf;
			mb[0].size = XDL_INSBOP_SIZE;
		} else {
			cpybuf[0] = XDL_BDOP_INS;
			cpybuf[1] = (unsigned char) size;
			mb[0].ptr = (char *) cpybuf;
			mb[0].size = 2;
		}
		mb[1].ptr = mmb2->ptr + cpos;
		mb[1].size = size;
		if (ecb->outf(ecb->priv, mb, 2) < 0)
			return -1;
	}

	return 0;
}


int xdl_rabdiff(mmfile_t *mmf1, mmfile_t *mmf2, xdemitcb_t *ecb) {
	mmbuffer_t mmb1, mmb2;

	if (!xdl_mmfile_iscompact(mmf1) || !xdl_mmfile_iscompact(mmf2))
		return -1;
	if ((mmb1.ptr = (char *) xdl_mmfile_first(mmf1, &mmb1.size)) == NULL)
		mmb1.size = 0;
	if ((mmb2.ptr = (char *) xdl_mmfile_first(mmf2, &mmb2.size)) == NULL)
		mmb2.size = 0;

	return xdl_rabdiff_mb(&mmb1, &mmb2, ecb);
}

