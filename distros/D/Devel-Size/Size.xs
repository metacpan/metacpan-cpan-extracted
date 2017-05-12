/* -*- mode: C -*- */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#ifndef PERL_COMBI_VERSION
#define PERL_COMBI_VERSION (PERL_REVISION * 1000000 + PERL_VERSION * 1000 + \
				PERL_SUBVERSION)
#endif

/* Not yet in ppport.h */
#ifndef CvISXSUB
#  define CvISXSUB(cv)  (CvXSUB(cv) ? TRUE : FALSE)
#endif
#ifndef SvRV_const
#  define SvRV_const(rv) SvRV(rv)
#endif
#ifndef SvOOK_offset
#  define SvOOK_offset(sv, len) STMT_START { len = SvIVX(sv); } STMT_END
#endif
#ifndef SvIsCOW
#  define SvIsCOW(sv)           ((SvFLAGS(sv) & (SVf_FAKE | SVf_READONLY)) == \
                                    (SVf_FAKE | SVf_READONLY))
#endif
#ifndef SvIsCOW_shared_hash
#  define SvIsCOW_shared_hash(sv)   (SvIsCOW(sv) && SvLEN(sv) == 0)
#endif
#ifndef SvSHARED_HEK_FROM_PV
#  define SvSHARED_HEK_FROM_PV(pvx) \
        ((struct hek*)(pvx - STRUCT_OFFSET(struct hek, hek_key)))
#endif

#if PERL_VERSION < 6
#  define PL_opargs opargs
#  define PL_op_name op_name
#endif

#ifdef _MSC_VER 
/* "structured exception" handling is a Microsoft extension to C and C++.
   It's *not* C++ exception handling - C++ exception handling can't capture
   SEGVs and suchlike, whereas this can. There's no known analagous
    functionality on other platforms.  */
#  include <excpt.h>
#  define TRY_TO_CATCH_SEGV __try
#  define CAUGHT_EXCEPTION __except(EXCEPTION_EXECUTE_HANDLER)
#else
#  define TRY_TO_CATCH_SEGV if(1)
#  define CAUGHT_EXCEPTION else
#endif

#ifdef __GNUC__
# define __attribute__(x)
#endif

#if 0 && defined(DEBUGGING)
#define dbg_printf(x) printf x
#else
#define dbg_printf(x)
#endif

#define TAG /* printf( "# %s(%d)\n", __FILE__, __LINE__ ) */
#define carp puts

/* The idea is to have a tree structure to store 1 bit per possible pointer
   address. The lowest 16 bits are stored in a block of 8092 bytes.
   The blocks are in a 256-way tree, indexed by the reset of the pointer.
   This can cope with 32 and 64 bit pointers, and any address space layout,
   without excessive memory needs. The assumption is that your CPU cache
   works :-) (And that we're not going to bust it)  */

#define BYTE_BITS    3
#define LEAF_BITS   (16 - BYTE_BITS)
#define LEAF_MASK   0x1FFF

struct state {
    UV total_size;
    bool regex_whine;
    bool fm_whine;
    bool dangle_whine;
    bool go_yell;
    /* My hunch (not measured) is that for most architectures pointers will
       start with 0 bits, hence the start of this array will be hot, and the
       end unused. So put the flags next to the hot end.  */
    void *tracking[256];
};

/* 
    Checks to see if thing is in the bitstring. 
    Returns true or false, and
    notes thing in the segmented bitstring.
 */
static bool
check_new(struct state *st, const void *const p) {
    unsigned int bits = 8 * sizeof(void*);
    const size_t raw_p = PTR2nat(p);
    /* This effectively rotates the value right by the number of low always-0
       bits in an aligned pointer. The assmption is that most (if not all)
       pointers are aligned, and these will be in the same chain of nodes
       (and hence hot in the cache) but we can still deal with any unaligned
       pointers.  */
    const size_t cooked_p
	= (raw_p >> ALIGN_BITS) | (raw_p << (bits - ALIGN_BITS));
    const U8 this_bit = 1 << (cooked_p & 0x7);
    U8 **leaf_p;
    U8 *leaf;
    unsigned int i;
    void **tv_p = (void **) (st->tracking);

    if (NULL == p) return FALSE;
    TRY_TO_CATCH_SEGV { 
        const char c = *(const char *)p;
    }
    CAUGHT_EXCEPTION {
        if (st->dangle_whine) 
            warn( "Devel::Size: Encountered invalid pointer: %p\n", p );
        return FALSE;
    }
    TAG;    

    bits -= 8;
    /* bits now 24 (32 bit pointers) or 56 (64 bit pointers) */

    /* First level is always present.  */
    do {
	i = (unsigned int)((cooked_p >> bits) & 0xFF);
	if (!tv_p[i])
	    Newxz(tv_p[i], 256, void *);
	tv_p = (void **)(tv_p[i]);
	bits -= 8;
    } while (bits > LEAF_BITS + BYTE_BITS);
    /* bits now 16 always */
#if PERL_COMBI_VERSION > 5008008 || (!defined(MULTIPLICITY) && !defined(USE_THREADS))
    /* 5.8.8 and earlier have an assert() macro that uses Perl_croak, hence
       needs a my_perl under multiplicity. Similarly, under 5.005 threads
       Perl_croak needs a thr. In both cases, just skip the assert.  */
    assert(bits == 16);
#endif
    leaf_p = (U8 **)tv_p;
    i = (unsigned int)((cooked_p >> bits) & 0xFF);
    if (!leaf_p[i])
	Newxz(leaf_p[i], 1 << LEAF_BITS, U8);
    leaf = leaf_p[i];

    TAG;    

    i = (unsigned int)((cooked_p >> BYTE_BITS) & LEAF_MASK);

    if(leaf[i] & this_bit)
	return FALSE;

    leaf[i] |= this_bit;
    return TRUE;
}

static void
free_tracking_at(void **tv, int level)
{
    int i = 255;

    if (--level) {
	/* Nodes */
	do {
	    if (tv[i]) {
		free_tracking_at((void **) tv[i], level);
		Safefree(tv[i]);
	    }
	} while (i--);
    } else {
	/* Leaves */
	do {
	    if (tv[i])
		Safefree(tv[i]);
	} while (i--);
    }
}

static void
free_state(struct state *st)
{
    const int top_level = (sizeof(void *) * 8 - LEAF_BITS - BYTE_BITS) / 8;
    free_tracking_at((void **)st->tracking, top_level);
    Safefree(st);
}

/* For now, this is somewhat a compatibility bodge until the plan comes
   together for fine grained recursion control. total_size() would recurse into
   hash and array members, whereas sv_size() would not. However, sv_size() is
   called with CvSTASH() of a CV, which means that if it (also) starts to
   recurse fully, then the size of any CV now becomes the size of the entire
   symbol table reachable from it, and potentially the entire symbol table, if
   any subroutine makes a reference to a global (such as %SIG). The historical
   implementation of total_size() didn't report "everything", and changing the
   only available size to "everything" doesn't feel at all useful.  */

#define NO_RECURSION 0
#define SOME_RECURSION 1
#define TOTAL_SIZE_RECURSION 2

static void sv_size(pTHX_ struct state *, const SV *const, const int recurse);

typedef enum {
    OPc_NULL,   /* 0 */
    OPc_BASEOP, /* 1 */
    OPc_UNOP,   /* 2 */
    OPc_BINOP,  /* 3 */
    OPc_LOGOP,  /* 4 */
    OPc_LISTOP, /* 5 */
    OPc_PMOP,   /* 6 */
    OPc_SVOP,   /* 7 */
    OPc_PADOP,  /* 8 */
    OPc_PVOP,   /* 9 */
    OPc_LOOP,   /* 10 */
    OPc_COP /* 11 */
#ifdef OA_CONDOP
    , OPc_CONDOP /* 12 */
#endif
#ifdef OA_GVOP
    , OPc_GVOP /* 13 */
#endif
#ifdef OA_METHOP
    , OPc_METHOP
#endif
#ifdef OA_UNOP_AUX
    , OPc_UNAUXOP
#endif

} opclass;

static opclass
cc_opclass(const OP * const o)
{
    if (!o)
    return OPc_NULL;
    TRY_TO_CATCH_SEGV {
        if (o->op_type == 0)
        return (o->op_flags & OPf_KIDS) ? OPc_UNOP : OPc_BASEOP;

        if (o->op_type == OP_SASSIGN)
        return ((o->op_private & OPpASSIGN_BACKWARDS) ? OPc_UNOP : OPc_BINOP);

    #ifdef USE_ITHREADS
        if (o->op_type == OP_GV || o->op_type == OP_GVSV || o->op_type == OP_AELEMFAST)
        return OPc_PADOP;
    #endif

        if ((o->op_type == OP_TRANS)) {
          return OPc_BASEOP;
        }

        switch (PL_opargs[o->op_type] & OA_CLASS_MASK) {
        case OA_BASEOP: TAG;
        return OPc_BASEOP;

        case OA_UNOP: TAG;
        return OPc_UNOP;

        case OA_BINOP: TAG;
        return OPc_BINOP;

        case OA_LOGOP: TAG;
        return OPc_LOGOP;

        case OA_LISTOP: TAG;
        return OPc_LISTOP;

        case OA_PMOP: TAG;
        return OPc_PMOP;

        case OA_SVOP: TAG;
        return OPc_SVOP;

#ifdef OA_PADOP
        case OA_PADOP: TAG;
        return OPc_PADOP;
#endif

#ifdef OA_GVOP
        case OA_GVOP: TAG;
        return OPc_GVOP;
#endif

#ifdef OA_PVOP_OR_SVOP
        case OA_PVOP_OR_SVOP: TAG;
            /*
             * Character translations (tr///) are usually a PVOP, keeping a 
             * pointer to a table of shorts used to look up translations.
             * Under utf8, however, a simple table isn't practical; instead,
             * the OP is an SVOP, and the SV is a reference to a swash
             * (i.e., an RV pointing to an HV).
             */
        return (o->op_private & (OPpTRANS_TO_UTF|OPpTRANS_FROM_UTF))
            ? OPc_SVOP : OPc_PVOP;
#endif

        case OA_LOOP: TAG;
        return OPc_LOOP;

        case OA_COP: TAG;
        return OPc_COP;

        case OA_BASEOP_OR_UNOP: TAG;
        /*
         * UNI(OP_foo) in toke.c returns token UNI or FUNC1 depending on
         * whether parens were seen. perly.y uses OPf_SPECIAL to
         * signal whether a BASEOP had empty parens or none.
         * Some other UNOPs are created later, though, so the best
         * test is OPf_KIDS, which is set in newUNOP.
         */
        return (o->op_flags & OPf_KIDS) ? OPc_UNOP : OPc_BASEOP;

        case OA_FILESTATOP: TAG;
        /*
         * The file stat OPs are created via UNI(OP_foo) in toke.c but use
         * the OPf_REF flag to distinguish between OP types instead of the
         * usual OPf_SPECIAL flag. As usual, if OPf_KIDS is set, then we
         * return OPc_UNOP so that walkoptree can find our children. If
         * OPf_KIDS is not set then we check OPf_REF. Without OPf_REF set
         * (no argument to the operator) it's an OP; with OPf_REF set it's
         * an SVOP (and op_sv is the GV for the filehandle argument).
         */
        return ((o->op_flags & OPf_KIDS) ? OPc_UNOP :
    #ifdef USE_ITHREADS
            (o->op_flags & OPf_REF) ? OPc_PADOP : OPc_BASEOP);
    #else
            (o->op_flags & OPf_REF) ? OPc_SVOP : OPc_BASEOP);
    #endif
        case OA_LOOPEXOP: TAG;
        /*
         * next, last, redo, dump and goto use OPf_SPECIAL to indicate that a
         * label was omitted (in which case it's a BASEOP) or else a term was
         * seen. In this last case, all except goto are definitely PVOP but
         * goto is either a PVOP (with an ordinary constant label), an UNOP
         * with OPf_STACKED (with a non-constant non-sub) or an UNOP for
         * OP_REFGEN (with goto &sub) in which case OPf_STACKED also seems to
         * get set.
         */
        if (o->op_flags & OPf_STACKED)
            return OPc_UNOP;
        else if (o->op_flags & OPf_SPECIAL)
            return OPc_BASEOP;
        else
            return OPc_PVOP;

#ifdef OA_CONDOP
        case OA_CONDOP: TAG;
	    return OPc_CONDOP;
#endif

#ifdef OA_METHOP
	case OA_METHOP: TAG;
	    return OPc_METHOP;
#endif
#ifdef OA_UNOP_AUX
	case OA_UNOP_AUX: TAG;
	    return OPc_UNAUXOP;
#endif
        }
        warn("Devel::Size: Can't determine class of operator %s, assuming BASEOP\n",
         PL_op_name[o->op_type]);
    }
    CAUGHT_EXCEPTION { }
    return OPc_BASEOP;
}

/* Figure out how much magic is attached to the SV and return the
   size */
static void
magic_size(pTHX_ const SV * const thing, struct state *st) {
  MAGIC *magic_pointer = SvMAGIC(thing);

  /* Have we seen the magic pointer?  (NULL has always been seen before)  */
  while (check_new(st, magic_pointer)) {
    st->total_size += sizeof(MAGIC);
    /* magic vtables aren't freed when magic is freed, so don't count them.
       (They are static structures. Anything that assumes otherwise is buggy.)
    */


    TRY_TO_CATCH_SEGV {
	sv_size(aTHX_ st, magic_pointer->mg_obj, TOTAL_SIZE_RECURSION);
	if (magic_pointer->mg_len == HEf_SVKEY) {
	    sv_size(aTHX_ st, (SV *)magic_pointer->mg_ptr, TOTAL_SIZE_RECURSION);
	}
#if defined(PERL_MAGIC_utf8) && defined (PERL_MAGIC_UTF8_CACHESIZE)
	else if (magic_pointer->mg_type == PERL_MAGIC_utf8) {
	    if (check_new(st, magic_pointer->mg_ptr)) {
		st->total_size += PERL_MAGIC_UTF8_CACHESIZE * 2 * sizeof(STRLEN);
	    }
	}
#endif
	else if (magic_pointer->mg_len > 0) {
	    if (check_new(st, magic_pointer->mg_ptr)) {
		st->total_size += magic_pointer->mg_len;
	    }
	}

        /* Get the next in the chain */
        magic_pointer = magic_pointer->mg_moremagic;
    }
    CAUGHT_EXCEPTION { 
        if (st->dangle_whine) 
            warn( "Devel::Size: Encountered bad magic at: %p\n", magic_pointer );
    }
  }
}

static void
check_new_and_strlen(struct state *st, const char *const p) {
    if(check_new(st, p))
	st->total_size += 1 + strlen(p);
}

static void
regex_size(const REGEXP * const baseregex, struct state *st) {
    if(!check_new(st, baseregex))
	return;
  st->total_size += sizeof(REGEXP);
#if (PERL_VERSION < 11)     
  /* Note the size of the paren offset thing */
  st->total_size += sizeof(I32) * baseregex->nparens * 2;
  st->total_size += strlen(baseregex->precomp);
#else
  st->total_size += sizeof(struct regexp);
  st->total_size += sizeof(I32) * SvANY(baseregex)->nparens * 2;
  /*st->total_size += strlen(SvANY(baseregex)->subbeg);*/
#endif
  if (st->go_yell && !st->regex_whine) {
    carp("Devel::Size: Calculated sizes for compiled regexes are incompatible, and probably always will be");
    st->regex_whine = 1;
  }
}

static void
op_size(pTHX_ const OP * const baseop, struct state *st)
{
    TRY_TO_CATCH_SEGV {
	TAG;
	if(!check_new(st, baseop))
	    return;
	TAG;
	op_size(aTHX_ baseop->op_next, st);
	TAG;
	switch (cc_opclass(baseop)) {
	case OPc_BASEOP: TAG;
	    st->total_size += sizeof(struct op);
	    TAG;break;
	case OPc_UNOP: TAG;
	    st->total_size += sizeof(struct unop);
	    op_size(aTHX_ ((UNOP *)baseop)->op_first, st);
	    TAG;break;
	case OPc_BINOP: TAG;
	    st->total_size += sizeof(struct binop);
	    op_size(aTHX_ ((BINOP *)baseop)->op_first, st);
	    op_size(aTHX_ ((BINOP *)baseop)->op_last, st);
	    TAG;break;
	case OPc_LOGOP: TAG;
	    st->total_size += sizeof(struct logop);
	    op_size(aTHX_ ((BINOP *)baseop)->op_first, st);
	    op_size(aTHX_ ((LOGOP *)baseop)->op_other, st);
	    TAG;break;
#ifdef OA_CONDOP
	case OPc_CONDOP: TAG;
	    st->total_size += sizeof(struct condop);
	    op_size(aTHX_ ((BINOP *)baseop)->op_first, st);
	    op_size(aTHX_ ((CONDOP *)baseop)->op_true, st);
	    op_size(aTHX_ ((CONDOP *)baseop)->op_false, st);
	    TAG;break;
#endif
	case OPc_LISTOP: TAG;
	    st->total_size += sizeof(struct listop);
	    op_size(aTHX_ ((LISTOP *)baseop)->op_first, st);
	    op_size(aTHX_ ((LISTOP *)baseop)->op_last, st);
	    TAG;break;
	case OPc_PMOP: TAG;
	    st->total_size += sizeof(struct pmop);
	    op_size(aTHX_ ((PMOP *)baseop)->op_first, st);
	    op_size(aTHX_ ((PMOP *)baseop)->op_last, st);
#if PERL_VERSION < 9 || (PERL_VERSION == 9 && PERL_SUBVERSION < 5)
	    op_size(aTHX_ ((PMOP *)baseop)->op_pmreplroot, st);
	    op_size(aTHX_ ((PMOP *)baseop)->op_pmreplstart, st);
#endif
	    /* This is defined away in perl 5.8.x, but it is in there for
	       5.6.x */
#ifdef PM_GETRE
	    regex_size(PM_GETRE((PMOP *)baseop), st);
#else
	    regex_size(((PMOP *)baseop)->op_pmregexp, st);
#endif
	    TAG;break;
	case OPc_SVOP: TAG;
	    st->total_size += sizeof(struct pmop);
	    if (!(baseop->op_type == OP_AELEMFAST
		  && baseop->op_flags & OPf_SPECIAL)) {
		/* not an OP_PADAV replacement */
		sv_size(aTHX_ st, ((SVOP *)baseop)->op_sv, SOME_RECURSION);
	    }
	    TAG;break;
#ifdef OA_PADOP
      case OPc_PADOP: TAG;
	  st->total_size += sizeof(struct padop);
	  TAG;break;
#endif
#ifdef OA_GVOP
      case OPc_GVOP: TAG;
	  st->total_size += sizeof(struct gvop);
	  sv_size(aTHX_ st, ((GVOP *)baseop)->op_gv, SOME_RECURSION);
	  TAG;break;
#endif
	case OPc_PVOP: TAG;
	    check_new_and_strlen(st, ((PVOP *)baseop)->op_pv);
	    TAG;break;
	case OPc_LOOP: TAG;
	    st->total_size += sizeof(struct loop);
	    op_size(aTHX_ ((LOOP *)baseop)->op_first, st);
	    op_size(aTHX_ ((LOOP *)baseop)->op_last, st);
	    op_size(aTHX_ ((LOOP *)baseop)->op_redoop, st);
	    op_size(aTHX_ ((LOOP *)baseop)->op_nextop, st);
	    op_size(aTHX_ ((LOOP *)baseop)->op_lastop, st);
	    TAG;break;
	case OPc_COP: TAG;
        {
          COP *basecop;
          basecop = (COP *)baseop;
          st->total_size += sizeof(struct cop);

          /* Change 33656 by nicholas@mouse-mill on 2008/04/07 11:29:51
          Eliminate cop_label from struct cop by storing a label as the first
          entry in the hints hash. Most statements don't have labels, so this
          will save memory. Not sure how much. 
          The check below will be incorrect fail on bleadperls
          before 5.11 @33656, but later than 5.10, producing slightly too
          small memory sizes on these Perls. */
#if (PERL_VERSION < 11)
          check_new_and_strlen(st, basecop->cop_label);
#endif
#ifdef USE_ITHREADS
          check_new_and_strlen(st, basecop->cop_file);
#if PERL_VERSION < 17 || (PERL_VERSION == 17 && PERL_SUBVERSION == 0)
	  /* This pointer is owned by the COP, and freed with it.  */
          check_new_and_strlen(st, basecop->cop_stashpv);
#else
	  /* A per-interpreter pointer for this stash is allocated in
	     PL_stashpad. */
	  if (check_new(st, PL_stashpad + basecop->cop_stashoff))
	      st->total_size += sizeof(PL_stashpad[basecop->cop_stashoff]);
#endif
#else
	  sv_size(aTHX_ st, (SV *)basecop->cop_filegv, SOME_RECURSION);
#endif

        }
        TAG;break;
#ifdef OA_METHOP
	case OPc_METHOP: TAG;
	    st->total_size += sizeof(struct methop);
	    if (baseop->op_type == OP_METHOD)
		op_size(aTHX_ ((UNOP *)baseop)->op_first, st);
	    else
		sv_size(aTHX_ st, cMETHOPx_meth(baseop), SOME_RECURSION);
#if PERL_VERSION*1000+PERL_SUBVERSION >= 21007
	    if (baseop->op_type == OP_METHOD_REDIR || baseop->op_type == OP_METHOD_REDIR_SUPER) {
		SV *rclass = cMETHOPx_rclass(baseop);
		if(SvTYPE(rclass) != SVt_PVHV)
		    sv_size(aTHX_ st, rclass, SOME_RECURSION);
	    }
#endif
	    TAG;break;
#endif
#ifdef OA_UNOP_AUX
	case OPc_UNAUXOP: TAG;
	    st->total_size += sizeof(struct unop_aux) + sizeof(UNOP_AUX_item) * (cUNOP_AUXx(baseop)->op_aux[-1].uv+1);
	    op_size(aTHX_ ((UNOP *)baseop)->op_first, st);
	    if (baseop->op_type == OP_MULTIDEREF) {
		UNOP_AUX_item *items = cUNOP_AUXx(baseop)->op_aux;
		UV actions = items->uv;
		bool last = 0;
		bool is_hash = 0;
		while (!last) {
		    switch (actions & MDEREF_ACTION_MASK) {
			case MDEREF_reload:
			    actions = (++items)->uv;
			    continue;
			case MDEREF_HV_padhv_helem:
			case MDEREF_HV_gvhv_helem:
			case MDEREF_HV_gvsv_vivify_rv2hv_helem:
			case MDEREF_HV_padsv_vivify_rv2hv_helem:
			    is_hash = 1;
			case MDEREF_AV_padav_aelem:
			case MDEREF_AV_gvav_aelem:
			case MDEREF_AV_gvsv_vivify_rv2av_aelem:
			case MDEREF_AV_padsv_vivify_rv2av_aelem:
			    ++items;
			    goto do_elem;
			case MDEREF_HV_pop_rv2hv_helem:
			case MDEREF_HV_vivify_rv2hv_helem:
			    is_hash = 1;
			case MDEREF_AV_pop_rv2av_aelem:
			case MDEREF_AV_vivify_rv2av_aelem:
			do_elem:
			    switch (actions & MDEREF_INDEX_MASK) {
				case MDEREF_INDEX_none:
				    last = 1;
				    break;
				case MDEREF_INDEX_const:
				    ++items;
				    if (is_hash) {
#ifdef USE_ITHREADS
					SV *key = PAD_SVl(items->pad_offset);
#else
					SV *key = items->sv;
#endif
					sv_size(aTHX_ st, key, SOME_RECURSION);
				    }
				    break;
				case MDEREF_INDEX_padsv:
				case MDEREF_INDEX_gvsv:
				    ++items;
				    break;
			    }
			    if (actions & MDEREF_FLAG_last)
				last = 1;
			    is_hash = 0;
			    break;
			default:
			    last = 1;
			    break;
		    }
		    actions >>= MDEREF_SHIFT;
		}
	    }
	    TAG;break;
#endif
      default:
        TAG;break;
      }
  }
  CAUGHT_EXCEPTION {
      if (st->dangle_whine) 
          warn( "Devel::Size: Encountered dangling pointer in opcode at: %p\n", baseop );
  }
}

static void
hek_size(pTHX_ struct state *st, HEK *hek, U32 shared)
{
    /* Hash keys can be shared. Have we seen this before? */
    if (!check_new(st, hek))
	return;
    st->total_size += HEK_BASESIZE + hek->hek_len
#if PERL_VERSION < 8
	+ 1 /* No hash key flags prior to 5.8.0  */
#else
	+ 2
#endif
	;
    if (shared) {
#if PERL_VERSION < 10
	st->total_size += sizeof(struct he);
#else
	st->total_size += STRUCT_OFFSET(struct shared_he, shared_he_hek);
#endif
    }
}


#if PERL_VERSION < 8 || PERL_SUBVERSION < 9
#  define SVt_LAST 16
#endif

#ifdef PURIFY
#  define MAYBE_PURIFY(normal, pure) (pure)
#  define MAYBE_OFFSET(struct_name, member) 0
#else
#  define MAYBE_PURIFY(normal, pure) (normal)
#  define MAYBE_OFFSET(struct_name, member) STRUCT_OFFSET(struct_name, member)
#endif

const U8 body_sizes[SVt_LAST] = {
#if PERL_VERSION < 9
     0,                                                       /* SVt_NULL */
     MAYBE_PURIFY(sizeof(IV), sizeof(XPVIV)),                 /* SVt_IV */
     MAYBE_PURIFY(sizeof(NV), sizeof(XPVNV)),                 /* SVt_NV */
     sizeof(XRV),                                             /* SVt_RV */
     sizeof(XPV),                                             /* SVt_PV */
     sizeof(XPVIV),                                           /* SVt_PVIV */
     sizeof(XPVNV),                                           /* SVt_PVNV */
     sizeof(XPVMG),                                           /* SVt_PVMG */
     sizeof(XPVBM),                                           /* SVt_PVBM */
     sizeof(XPVLV),                                           /* SVt_PVLV */
     sizeof(XPVAV),                                           /* SVt_PVAV */
     sizeof(XPVHV),                                           /* SVt_PVHV */
     sizeof(XPVCV),                                           /* SVt_PVCV */
     sizeof(XPVGV),                                           /* SVt_PVGV */
     sizeof(XPVFM),                                           /* SVt_PVFM */
     sizeof(XPVIO)                                            /* SVt_PVIO */
#elif PERL_VERSION == 10 && PERL_SUBVERSION == 0
     0,                                                       /* SVt_NULL */
     0,                                                       /* SVt_BIND */
     0,                                                       /* SVt_IV */
     MAYBE_PURIFY(sizeof(NV), sizeof(XPVNV)),                 /* SVt_NV */
     0,                                                       /* SVt_RV */
     MAYBE_PURIFY(sizeof(xpv_allocated), sizeof(XPV)),        /* SVt_PV */
     MAYBE_PURIFY(sizeof(xpviv_allocated), sizeof(XPVIV)),/* SVt_PVIV */
     sizeof(XPVNV),                                           /* SVt_PVNV */
     sizeof(XPVMG),                                           /* SVt_PVMG */
     sizeof(XPVGV),                                           /* SVt_PVGV */
     sizeof(XPVLV),                                           /* SVt_PVLV */
     MAYBE_PURIFY(sizeof(xpvav_allocated), sizeof(XPVAV)),/* SVt_PVAV */
     MAYBE_PURIFY(sizeof(xpvhv_allocated), sizeof(XPVHV)),/* SVt_PVHV */
     MAYBE_PURIFY(sizeof(xpvcv_allocated), sizeof(XPVCV)),/* SVt_PVCV */
     MAYBE_PURIFY(sizeof(xpvfm_allocated), sizeof(XPVFM)),/* SVt_PVFM */
     sizeof(XPVIO),                                           /* SVt_PVIO */
#elif PERL_VERSION == 10 && PERL_SUBVERSION == 1
     0,                                                       /* SVt_NULL */
     0,                                                       /* SVt_BIND */
     0,                                                       /* SVt_IV */
     MAYBE_PURIFY(sizeof(NV), sizeof(XPVNV)),                 /* SVt_NV */
     0,                                                       /* SVt_RV */
     sizeof(XPV) - MAYBE_OFFSET(XPV, xpv_cur),                /* SVt_PV */
     sizeof(XPVIV) - MAYBE_OFFSET(XPV, xpv_cur),              /* SVt_PVIV */
     sizeof(XPVNV),                                           /* SVt_PVNV */
     sizeof(XPVMG),                                           /* SVt_PVMG */
     sizeof(XPVGV),                                           /* SVt_PVGV */
     sizeof(XPVLV),                                           /* SVt_PVLV */
     sizeof(XPVAV) - MAYBE_OFFSET(XPVAV, xav_fill),           /* SVt_PVAV */
     sizeof(XPVHV) - MAYBE_OFFSET(XPVHV, xhv_fill),           /* SVt_PVHV */
     sizeof(XPVCV) - MAYBE_OFFSET(XPVCV, xpv_cur),            /* SVt_PVCV */
     sizeof(XPVFM) - MAYBE_OFFSET(XPVFM, xpv_cur),            /* SVt_PVFM */
     sizeof(XPVIO)                                            /* SVt_PVIO */
#elif PERL_VERSION < 13
     0,                                                       /* SVt_NULL */
     0,                                                       /* SVt_BIND */
     0,                                                       /* SVt_IV */
     MAYBE_PURIFY(sizeof(NV), sizeof(XPVNV)),                 /* SVt_NV */
     sizeof(XPV) - MAYBE_OFFSET(XPV, xpv_cur),                /* SVt_PV */
     sizeof(XPVIV) - MAYBE_OFFSET(XPV, xpv_cur),              /* SVt_PVIV */
     sizeof(XPVNV),                                           /* SVt_PVNV */
     sizeof(XPVMG),                                           /* SVt_PVMG */
     sizeof(regexp) - MAYBE_OFFSET(regexp, xpv_cur),          /* SVt_REGEXP */
     sizeof(XPVGV),                                           /* SVt_PVGV */
     sizeof(XPVLV),                                           /* SVt_PVLV */
     sizeof(XPVAV) - MAYBE_OFFSET(XPVAV, xav_fill),           /* SVt_PVAV */
     sizeof(XPVHV) - MAYBE_OFFSET(XPVHV, xhv_fill),           /* SVt_PVHV */
     sizeof(XPVCV) - MAYBE_OFFSET(XPVCV, xpv_cur),            /* SVt_PVCV */
     sizeof(XPVFM) - MAYBE_OFFSET(XPVFM, xpv_cur),            /* SVt_PVFM */
     sizeof(XPVIO)                                            /* SVt_PVIO */
#else
     0,                                                       /* SVt_NULL */
     0,                                                       /* SVt_BIND */
     0,                                                       /* SVt_IV */
     MAYBE_PURIFY(sizeof(NV), sizeof(XPVNV)),                 /* SVt_NV */
     sizeof(XPV) - MAYBE_OFFSET(XPV, xpv_cur),                /* SVt_PV */
     sizeof(XPVIV) - MAYBE_OFFSET(XPV, xpv_cur),              /* SVt_PVIV */
     sizeof(XPVNV) - MAYBE_OFFSET(XPV, xpv_cur),              /* SVt_PVNV */
     sizeof(XPVMG),                                           /* SVt_PVMG */
     sizeof(regexp),                                          /* SVt_REGEXP */
     sizeof(XPVGV),                                           /* SVt_PVGV */
     sizeof(XPVLV),                                           /* SVt_PVLV */
     sizeof(XPVAV),                                           /* SVt_PVAV */
     sizeof(XPVHV),                                           /* SVt_PVHV */
     sizeof(XPVCV),                                           /* SVt_PVCV */
     sizeof(XPVFM),                                           /* SVt_PVFM */
     sizeof(XPVIO)                                            /* SVt_PVIO */
#endif
};

#if PERL_COMBI_VERSION < 5008001
typedef AV PADLIST;
#endif

static void
padlist_size(pTHX_ struct state *const st, const PADLIST * const padl,
	const int recurse) {

#if PERL_VERSION*1000+PERL_SUBVERSION >= 21007
/* This is, as ever, excessively nosey with the implementation, and hence
   fragile. */
    SSize_t i;
    const PADNAMELIST *pnl;

    if (!check_new(st, padl))
	return;
    st->total_size += sizeof(PADLIST);

    st->total_size += sizeof(PADNAMELIST);
    pnl = PadlistNAMES(padl);
    st->total_size += pnl->xpadnl_max * sizeof(PADNAME *);
    i = PadnamelistMAX(pnl) + 1;
    while (--i) {
        const PADNAME *const pn =
		PadnamelistARRAY(pnl)[i];
        if (!pn || pn == &PL_padname_undef || pn == &PL_padname_const)
            continue;
        if (!check_new(st, pn))
            continue;
        st->total_size += STRUCT_OFFSET(struct padname_with_str, xpadn_str[0])
            + PadnameLEN(pn) + 1;
    }

    i = PadlistMAX(padl) + 1;
    st->total_size += sizeof(PAD*) * i;
    while (--i)
	sv_size(aTHX_ st, (SV*)PadlistARRAY(padl)[i], recurse);

#elif defined PadlistNAMES

    SSize_t i;
    if (!check_new(st, padl))
	return;
    st->total_size += sizeof(PADLIST);
    sv_size(aTHX_ st, (SV*)PadlistNAMES(padl), TOTAL_SIZE_RECURSION);
    i = PadlistMAX(padl) + 1;
    st->total_size += sizeof(PAD*) * i;
    while (--i)
	sv_size(aTHX_ st, (SV*)PadlistARRAY(padl)[i], recurse);

#else 

    sv_size(aTHX_ st, (SV*)padl, recurse);

#endif
}

static void
sv_size(pTHX_ struct state *const st, const SV * const orig_thing,
	const int recurse) {
  const SV *thing = orig_thing;
  U32 type;

  if(!check_new(st, thing))
      return;

  type = SvTYPE(thing);
  if (type > SVt_LAST) {
      warn("Devel::Size: Unknown variable type: %d encountered\n", type);
      return;
  }
  st->total_size += sizeof(SV) + body_sizes[type];

  if (SvMAGICAL(thing)) {
      magic_size(aTHX_ thing, st);
  }

  switch (type) {
#if (PERL_VERSION < 11)
    /* Is it a reference? */
  case SVt_RV: TAG;
#else
  case SVt_IV: TAG;
#endif
    if(recurse && SvROK(thing))
	sv_size(aTHX_ st, SvRV_const(thing), recurse);
    TAG;break;

  case SVt_PVAV: TAG;
    /* Is there anything in the array? */
    if (AvMAX(thing) != -1) {
      /* an array with 10 slots has AvMax() set to 9 - te 2007-04-22 */
      st->total_size += sizeof(SV *) * (AvMAX(thing) + 1);
      dbg_printf(("total_size: %li AvMAX: %li av_len: $i\n", st->total_size, AvMAX(thing), av_len((AV*)thing)));

      if (recurse >= TOTAL_SIZE_RECURSION) {
	  SSize_t i = AvFILLp(thing) + 1;

	  while (i--)
	      sv_size(aTHX_ st, AvARRAY(thing)[i], recurse);
      }
    }
    /* Add in the bits on the other side of the beginning */

    dbg_printf(("total_size %li, sizeof(SV *) %li, AvARRAY(thing) %li, AvALLOC(thing)%li , sizeof(ptr) %li \n", 
    st->total_size, sizeof(SV*), AvARRAY(thing), AvALLOC(thing), sizeof( thing )));

    /* under Perl 5.8.8 64bit threading, AvARRAY(thing) was a pointer while AvALLOC was 0,
       resulting in grossly overstated sized for arrays. Technically, this shouldn't happen... */
    if (AvALLOC(thing) != 0) {
      st->total_size += (sizeof(SV *) * (AvARRAY(thing) - AvALLOC(thing)));
      }
#if (PERL_VERSION < 9)
    /* Is there something hanging off the arylen element?
       Post 5.9.something this is stored in magic, so will be found there,
       and Perl_av_arylen_p() takes a non-const AV*, hence compilers rightly
       complain about AvARYLEN() passing thing to it.  */
    sv_size(aTHX_ st, AvARYLEN(thing), recurse);
#endif
    TAG;break;
  case SVt_PVHV: TAG;
    /* Now the array of buckets */
    st->total_size += (sizeof(HE *) * (HvMAX(thing) + 1));
    /* Now walk the bucket chain */
    if (HvARRAY(thing)) {
      HE *cur_entry;
      UV cur_bucket = 0;
      for (cur_bucket = 0; cur_bucket <= HvMAX(thing); cur_bucket++) {
        cur_entry = *(HvARRAY(thing) + cur_bucket);
        while (cur_entry) {
          st->total_size += sizeof(HE);
	  hek_size(aTHX_ st, cur_entry->hent_hek, HvSHAREKEYS(thing));
	  if (recurse >= TOTAL_SIZE_RECURSION)
	      sv_size(aTHX_ st, HeVAL(cur_entry), recurse);
          cur_entry = cur_entry->hent_next;
        }
      }
    }
#ifdef HvAUX
    if (SvOOK(thing)) {
	/* This direct access is arguably "naughty": */
	struct mro_meta *meta = HvAUX(thing)->xhv_mro_meta;
#if PERL_VERSION > 13 || PERL_SUBVERSION > 8
	/* As is this: */
	I32 count = HvAUX(thing)->xhv_name_count;

	if (count) {
	    HEK **names = HvAUX(thing)->xhv_name_u.xhvnameu_names;
	    if (count < 0)
		count = -count;
	    while (--count)
		hek_size(aTHX_ st, names[count], 1);
	}
	else
#endif
	{
	    hek_size(aTHX_ st, HvNAME_HEK(thing), 1);
	}

	st->total_size += sizeof(struct xpvhv_aux);
	if (meta) {
	    st->total_size += sizeof(struct mro_meta);
	    sv_size(aTHX_ st, (SV *)meta->mro_nextmethod, TOTAL_SIZE_RECURSION);
#if PERL_VERSION > 10 || (PERL_VERSION == 10 && PERL_SUBVERSION > 0)
	    sv_size(aTHX_ st, (SV *)meta->isa, TOTAL_SIZE_RECURSION);
#endif
#if PERL_VERSION > 10
	    sv_size(aTHX_ st, (SV *)meta->mro_linear_all, TOTAL_SIZE_RECURSION);
	    sv_size(aTHX_ st, meta->mro_linear_current, TOTAL_SIZE_RECURSION);
#else
	    sv_size(aTHX_ st, (SV *)meta->mro_linear_dfs, TOTAL_SIZE_RECURSION);
	    sv_size(aTHX_ st, (SV *)meta->mro_linear_c3, TOTAL_SIZE_RECURSION);
#endif
	}
    }
#else
    check_new_and_strlen(st, HvNAME_get(thing));
#endif
    TAG;break;


  case SVt_PVFM: TAG;
    if (PERL_VERSION*1000+PERL_SUBVERSION < 21006 || !CvISXSUB(thing))
	padlist_size(aTHX_ st, CvPADLIST(thing), SOME_RECURSION);
    sv_size(aTHX_ st, (SV *)CvOUTSIDE(thing), recurse);

    if (st->go_yell && !st->fm_whine) {
      carp("Devel::Size: Calculated sizes for FMs are incomplete");
      st->fm_whine = 1;
    }
    goto freescalar;

  case SVt_PVCV: TAG;
    sv_size(aTHX_ st, (SV *)CvSTASH(thing), SOME_RECURSION);
    sv_size(aTHX_ st, (SV *)SvSTASH(thing), SOME_RECURSION);
    sv_size(aTHX_ st, (SV *)CvGV(thing), SOME_RECURSION);
    if (PERL_VERSION*1000+PERL_SUBVERSION < 21006 || !CvISXSUB(thing))
	padlist_size(aTHX_ st, CvPADLIST(thing), SOME_RECURSION);
    sv_size(aTHX_ st, (SV *)CvOUTSIDE(thing), recurse);
    if (CvISXSUB(thing)) {
	sv_size(aTHX_ st, cv_const_sv((CV *)thing), recurse);
    } else if (CvROOT(thing)) {
	op_size(aTHX_ CvSTART(thing), st);
	op_size(aTHX_ CvROOT(thing), st);
    }
    goto freescalar;

  case SVt_PVIO: TAG;
    /* Some embedded char pointers */
    check_new_and_strlen(st, ((XPVIO *) SvANY(thing))->xio_top_name);
    check_new_and_strlen(st, ((XPVIO *) SvANY(thing))->xio_fmt_name);
    check_new_and_strlen(st, ((XPVIO *) SvANY(thing))->xio_bottom_name);
    /* Throw the GVs on the list to be walked if they're not-null */
    sv_size(aTHX_ st, (SV *)((XPVIO *) SvANY(thing))->xio_top_gv, recurse);
    sv_size(aTHX_ st, (SV *)((XPVIO *) SvANY(thing))->xio_bottom_gv, recurse);
    sv_size(aTHX_ st, (SV *)((XPVIO *) SvANY(thing))->xio_fmt_gv, recurse);

    /* Only go trotting through the IO structures if they're really
       trottable. If USE_PERLIO is defined we can do this. If
       not... we can't, so we don't even try */
#ifdef USE_PERLIO
    /* Dig into xio_ifp and xio_ofp here */
    warn("Devel::Size: Can't size up perlio layers yet\n");
#endif
    goto freescalar;

  case SVt_PVLV: TAG;
#if (PERL_VERSION < 9)
    goto freescalar;
#endif

  case SVt_PVGV: TAG;
    if(isGV_with_GP(thing)) {
#ifdef GvNAME_HEK
	hek_size(aTHX_ st, GvNAME_HEK(thing), 1);
#else	
	st->total_size += GvNAMELEN(thing);
#endif
#ifdef GvFILE_HEK
	hek_size(aTHX_ st, GvFILE_HEK(thing), 1);
#elif defined(GvFILE)
#  if !defined(USE_ITHREADS) || (PERL_VERSION > 8 || (PERL_VERSION == 8 && PERL_SUBVERSION > 8))
	/* With itreads, before 5.8.9, this can end up pointing to freed memory
	   if the GV was created in an eval, as GvFILE() points to CopFILE(),
	   and the relevant COP has been freed on scope cleanup after the eval.
	   5.8.9 adds a binary compatible fudge that catches the vast majority
	   of cases. 5.9.something added a proper fix, by converting the GP to
	   use a shared hash key (porperly reference counted), instead of a
	   char * (owned by who knows? possibly no-one now) */
	check_new_and_strlen(st, GvFILE(thing));
#  endif
#endif
	/* Is there something hanging off the glob? */
	if (check_new(st, GvGP(thing))) {
	    st->total_size += sizeof(GP);
	    sv_size(aTHX_ st, (SV *)(GvGP(thing)->gp_sv), recurse);
	    sv_size(aTHX_ st, (SV *)(GvGP(thing)->gp_form), recurse);
	    sv_size(aTHX_ st, (SV *)(GvGP(thing)->gp_av), recurse);
	    sv_size(aTHX_ st, (SV *)(GvGP(thing)->gp_hv), recurse);
	    sv_size(aTHX_ st, (SV *)(GvGP(thing)->gp_egv), recurse);
	    sv_size(aTHX_ st, (SV *)(GvGP(thing)->gp_cv), recurse);
	}
#if (PERL_VERSION >= 9)
	TAG; break;
#endif
    }
#if PERL_VERSION <= 8
  case SVt_PVBM: TAG;
#endif
  case SVt_PVMG: TAG;
  case SVt_PVNV: TAG;
  case SVt_PVIV: TAG;
  case SVt_PV: TAG;
  freescalar:
    if(recurse && SvROK(thing))
	sv_size(aTHX_ st, SvRV_const(thing), recurse);
    else if (SvIsCOW_shared_hash(thing))
	hek_size(aTHX_ st, SvSHARED_HEK_FROM_PV(SvPVX(thing)), 1);
    else
	st->total_size += SvLEN(thing);

    if(SvOOK(thing)) {
	STRLEN len;
	SvOOK_offset(thing, len);
	st->total_size += len;
    }
    TAG;break;

  }
  return;
}

static struct state *
new_state(pTHX)
{
    SV *warn_flag;
    struct state *st;

    Newxz(st, 1, struct state);
    st->go_yell = TRUE;
    if (NULL != (warn_flag = perl_get_sv("Devel::Size::warn", FALSE))) {
	st->dangle_whine = st->go_yell = SvIV(warn_flag) ? TRUE : FALSE;
    }
    if (NULL != (warn_flag = perl_get_sv("Devel::Size::dangle", FALSE))) {
	st->dangle_whine = SvIV(warn_flag) ? TRUE : FALSE;
    }
    check_new(st, &PL_sv_undef);
    check_new(st, &PL_sv_no);
    check_new(st, &PL_sv_yes);
#if PERL_VERSION > 8 || (PERL_VERSION == 8 && PERL_SUBVERSION > 0)
    check_new(st, &PL_sv_placeholder);
#endif
    return st;
}

MODULE = Devel::Size        PACKAGE = Devel::Size       

PROTOTYPES: DISABLE

UV
size(orig_thing)
     SV *orig_thing
ALIAS:
    total_size = TOTAL_SIZE_RECURSION
CODE:
{
  SV *thing = orig_thing;
  struct state *st = new_state(aTHX);
  
  /* If they passed us a reference then dereference it. This is the
     only way we can check the sizes of arrays and hashes */
  if (SvROK(thing)) {
    thing = SvRV(thing);
  }

  sv_size(aTHX_ st, thing, ix);
  RETVAL = st->total_size;
  free_state(st);
}
OUTPUT:
  RETVAL
