/* -*- mode: C -*- */

/* TODO
 *
 * Refactor this to split out D:M code from Devel::Size code.
 * Start migrating Devel::Size's Size.xs towards the new code.
 *
 */

#undef NDEBUG /* XXX */
#include <assert.h>

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define DPPP_PL_parser_NO_DUMMY
#define NEED_my_snprintf
#define NEED_pv_escape
#define NEED_pv_pretty
#define NEED_PL_parser
#include "ppport.h"
#ifndef PERL_PV_ESCAPE_NONASCII
#define PERL_PV_ESCAPE_NONASCII 0
#endif

#include "smptr_tbl.c" /* XXX ought to link it */

#include "refcounted_he.h"

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
#ifndef MUTABLE_AV
#define MUTABLE_AV(p) ((AV*)p)
#endif
#ifndef MUTABLE_SV
#define MUTABLE_SV(p) ((SV*)p)
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


/* the values are arbitrary but chosen to be mnemonic */
/* XXX we don't yet account for pointers that might be chased from
 * structures that don't "own" a ref count, we just treat all pointers
 * to SVs as owning a ref - this may need refining
 */
#define FOLLOW_SINGLE_NOW   11 /* refcnt=1, follow now */
#define FOLLOW_SINGLE_DONE  12 /* refcnt=1, already followed */
#define FOLLOW_MULTI_DEFER  20 /* refcnt>1, follow later */
#define FOLLOW_MULTI_NOW    21 /* refcnt>1, follow now */
#define FOLLOW_MULTI_DONE   22 /* refcnt>1, already followed */

/* detail types to control simplification of node tree */
#define NPf_DETAIL_REFCNT1      0x01
#define NPf_DETAIL_COPFILE      0x02
#define NPf_DETAIL_HEK          0x04

#define SMopt_IS_TEST           0x01


/*
 * A 'Node Path' is a chain of node structures.
 *
 * Nodes represent either an 'item' (eg a struct) in memory or a 'link'
 * (pointer) from the previous node in the chain (an item) to another item.
 * Attributes aren't represented in memory, they're output directly and
 * associated with the previous node that was output.
 *
 * Nodes are output lazily, triggered by the need to output an attributes.
 * When an attribute needs to be output the chain of nodes is chased
 * and any nodes that haven't already been output are.
 */

typedef struct npath_node_st npath_node_t;
struct npath_node_st {
    npath_node_t *prev;
    const void *id;
    U8 type;
    U8 flags;
    UV seqn;
    U16 depth;
};

struct state {
    UV total_size;
    int recurse;
    bool recurse_into_weak;
    bool regex_whine;
    bool fm_whine;
    bool dangle_whine;
    bool perlio_whine;
    bool go_yell;
    int trace_level;
    UV hide_detail;
    UV opts;
    SV *tmp_sv;
    /* My hunch (not measured) is that for most architectures pointers will
       start with 0 bits, hence the start of this array will be hot, and the
       end unused. So put the flags next to the hot end.  */
    void *tracking[256];

    /* we use a pointer table to record the count of the number of times we've
     * seen an SV (for SVs with refcnt > 1) so that we only recurse into it
     * once we've 'seen' and thus accounted for all the refs to it */
    SMPTR_TBL_t *sv_refcnt_ptr_table;
    /* the initial SV the size func was called for is given a free pass
     * so it's counted regardless of it's ref count. TODO find a more elegant
     * way to do this, perhps by pre-loading the pointer table */
    SV *sv_refcnt_to_ignore;

    NV start_time_nv;
    UV multi_refcnt;
    /* callback hooks and data */
    void (*add_attr_cb)(pTHX_ struct state *st, npath_node_t *npath_node, UV attr_type, const char *name, UV value);
    void (*free_state_cb)(pTHX_ struct state *st);
    void *state_cb_data; /* free'd by free_state() after free_state_cb() call */
    /* this stuff wil be moved to state_cb_data later */
    UV seqn;
    FILE *node_stream_fh;
    char *node_stream_name;
};

#define ADD_SIZE(st, leafname, bytes) \
  STMT_START { \
    NPathAddSizeCb(st, leafname, bytes); \
    (st)->total_size += (bytes); \
  } STMT_END


#define PATH_TRACKING
#ifdef PATH_TRACKING

#define pPATH npath_node_t *NPathArg

/* A subtle point here is that dNPathNodes and NPathPushNode leave NP pointing
 * to the next unused slot (though with prev already filled in)
 * whereas NPathLink leaves NP unchanged, it just fills in the slot NP points
 * to and passes that NP value to the function being called.
 * seqn==0 indicates the node is new (hasn't been output yet)
 */
#define dNPathNodes(nodes, prev_np) \
            npath_node_t name_path_nodes[nodes+1]; /* +1 for NPathLink */ \
            npath_node_t *NP = &name_path_nodes[0]; \
            memzero(name_path_nodes, sizeof(name_path_nodes)); /* safety/debug */ \
            if(st->trace_level>=9)fprintf(stderr,"dNPathNodes (%d, %p)\n", nodes, prev_np);\
            NP->seqn = NP->type = 0; NP->id = Nullch; /* safety/debug */ \
            NP->prev = prev_np
#define _NPathPushNode(nodeid, nodetype) \
    STMT_START { \
            NP->id = nodeid; \
            NP->type = nodetype; \
            NP->seqn = 0; \
            if(st->trace_level>=9)fprintf(stderr,"NPathPushNode (%p <-) %p <- [%ld %p]\n", NP->prev, NP, (long)nodetype,nodeid);\
            NP++; \
            NP->id = Nullch; /* safety/debug */ \
            NP->seqn = 0; \
            NP->type = 0; \
            NP->prev = (NP-1); \
    } STMT_END
#define NPathPushNode(nodeid, nodetype) \
    STMT_START { \
        assert(nodetype != NPtype_LINK); \
        /* ensure that we hang a non-link on a link */ \
        assert(!NP->prev || NP->prev->type == NPtype_LINK); \
        _NPathPushNode(nodeid, nodetype); \
    } STMT_END
#define NPathPushPlaceholderNode \
    STMT_START { \
        _NPathPushNode((void*)0xAB, NPtype_PLACEHOLDER); /* poison */ \
    } STMT_END
#define NPathPushLink(nodeid) \
    STMT_START { \
        /* ensure that we don't hang a link on a link */ \
        assert(NP->prev && NP->prev->type != NPtype_LINK); \
        _NPathPushNode(nodeid, NPtype_LINK); \
    } STMT_END


#define NPathSetNode(nodeid, nodetype) \
    STMT_START { \
            assert(nodetype != NPtype_LINK); \
            assert((NP-1)->seqn /* was output */ || (NP-1)->type == NPtype_PLACEHOLDER); \
            (NP-1)->id = nodeid; \
            (NP-1)->type = nodetype; \
            if(st->trace_level>=9)fprintf(stderr,"NPathSetNode (%p <-) %p <- [%d %p]\n", (NP-1)->prev, (NP-1), nodetype,nodeid);\
            (NP-1)->seqn = 0; \
    } STMT_END
#define NPathPopNode \
    STMT_START { \
            --NP; \
            NP->type = 0; NP->id = Nullch; /* safety/debug */ \
    } STMT_END

/* dNPathUseParent points NP directly the the parents' name_path_nodes array
 * So the function can only safely call ADD_*() but not NPathLink, unless the
 * caller has spare nodes in its name_path_nodes.
 */
#define dNPathUseParent(prev_np) npath_node_t *NP = (((prev_np+1)->prev = prev_np), prev_np+1)

#define NPtype_NAME     0x01
#define NPtype_LINK     0x02
#define NPtype_SV       0x03
#define NPtype_MAGIC    0x04
#define NPtype_OP       0x05
#define NPtype_PLACEHOLDER  0x06
#define NPtype_max          0x06

/* XXX these should possibly be generalized into flag bits */
#define NPattr_LEAFSIZE 0x00
#define NPattr_LABEL    0x01
#define NPattr_PADFAKE  0x02
#define NPattr_PADNAME  0x03
#define NPattr_PADTMP   0x04
#define NPattr_NOTE     0x05
#define NPattr_ADDR     0x06
#define NPattr_REFCNT   0x07
#define NPattr_max      0x07

#define _ADD_ATTR_NP(st, attr_type, attr_name, attr_value, np) \
  STMT_START { \
    if (st->add_attr_cb) { \
      st->add_attr_cb(aTHX_ st, np, attr_type, attr_name, attr_value); \
    } \
  } STMT_END

#define ADD_ATTR(st, attr_type, attr_name, attr_value) \
    _ADD_ATTR_NP(st, attr_type, attr_name, attr_value, NP-1)

#define _ADD_LINK_ATTR_NP(st, attr_type, attr_name, attr_value, np) \
  STMT_START {								\
    if (st->add_attr_cb) assert(np->type == NPtype_LINK);		\
    _ADD_ATTR_NP(st, attr_type, attr_name, attr_value, np); \
  } STMT_END;

/* emit an attribute for the link that's the top node,
 * typically *after* a foo_size(..., NPathLink("Bar"), ...) call
 */
#define ADD_LINK_ATTR_TO_TOP(st, attr_type, attr_name, attr_value)		\
    _ADD_LINK_ATTR_NP(st, attr_type, attr_name, attr_value, NP)

/* emit an attribute for the link that's the previous node,
 * typically *inside* a foo_size() sub before NPathPushNode() is called
 * i.e., the NPathLink() that was an argument to the foo_size() sub.
 */
#define ADD_LINK_ATTR_TO_PREV(st, attr_type, attr_name, attr_value)		\
    _ADD_LINK_ATTR_NP(st, attr_type, attr_name, attr_value, NP->prev)


#define _NPathLink(np, nid, ntype)   (((np)->id=nid), ((np)->type=ntype), ((np)->seqn=0))
#define NPathLink(nid)               (_NPathLink(NP, nid, NPtype_LINK), NP)

/* add a link and a name node to the path - a special case for op_size */
#define NPathLinkAndNode(nid, nid2)  (_NPathLink(NP, nid, NPtype_LINK), _NPathLink(NP+1, nid2, NPtype_NAME), ((NP+1)->prev=NP), (NP+1))
#define NPathOpLink  (NPathArg)
#define NPathAddSizeCb(st, name, bytes) \
  STMT_START { \
    if (st->add_attr_cb) { \
      st->add_attr_cb(aTHX_ st, NP->prev, NPattr_LEAFSIZE, (name), (bytes)); \
    } \
  } STMT_END

#define DUMP_NPATH_NODES(np, depth) \
  STMT_START { \
    if (st->trace_level) \
        np_walk_all_nodes(aTHX_ st, np, np_debug_node_dump, depth) \
  } STMT_END

#else

#define NPathAddSizeCb(st, name, bytes)
#define pPATH void *npath_dummy /* XXX ideally remove */
#define dNPathNodes(nodes, prev_np)  dNOOP
#define NPathLink(nodeid, nodetype)  NULL
#define NPathOpLink NULL
#define ADD_ATTR(st, attr_type, attr_name, attr_value) NOOP

#endif /* PATH_TRACKING */


#if (PERL_BCDVERSION <= 0x5008008)
#  define SVt_LAST 16
#endif


#ifdef PATH_TRACKING

static const char *svtypenames[SVt_LAST] = {
#if PERL_VERSION < 9
  "NULL", "IV", "NV", "RV", "PV", "PVIV", "PVNV", "PVMG", "PVBM", "PVLV", "PVAV", "PVHV", "PVCV", "PVGV", "PVFM", "PVIO",
#elif PERL_VERSION == 10 && PERL_SUBVERSION == 0
  "NULL", "BIND", "IV", "NV", "RV", "PV", "PVIV", "PVNV", "PVMG", "PVGV", "PVLV", "PVAV", "PVHV", "PVCV", "PVFM", "PVIO",
#elif PERL_VERSION == 10 && PERL_SUBVERSION == 1
  "NULL", "BIND", "IV", "NV", "RV", "PV", "PVIV", "PVNV", "PVMG", "PVGV", "PVLV", "PVAV", "PVHV", "PVCV", "PVFM", "PVIO",
#elif PERL_VERSION < 13
  "NULL", "BIND", "IV", "NV", "PV", "PVIV", "PVNV", "PVMG", "REGEXP", "PVGV", "PVLV", "PVAV", "PVHV", "PVCV", "PVFM", "PVIO",
#else
  "NULL", "BIND", "IV", "NV", "PV", "PVIV", "PVNV", "PVMG", "REGEXP", "PVGV", "PVLV", "PVAV", "PVHV", "PVCV", "PVFM", "PVIO",
#endif
};

static NV
gettimeofday_nv(pTHX)
{
#ifdef HAS_GETTIMEOFDAY
    struct timeval when;
    gettimeofday(&when, (struct timezone *) 0);
    return when.tv_sec + (when.tv_usec / 1000000.0);
#else
    if (u2time) {
        UV time_of_day[2];
        (*u2time)(aTHX_ &time_of_day);
        return time_of_day[0] + (time_of_day[1] / 1000000.0);
    }
    return (NV)time();
#endif
}


static const char *
svtypename(const SV *sv)
{
    int type = SvTYPE(sv);
    if (type > SVt_LAST)
        return "SVt_UNKNOWN";
    return (type == SVt_IV && SvROK(sv)) ? "RV" : svtypenames[type];
}


int
np_print_node_name(pTHX_ FILE *fp, npath_node_t *npath_node)
{
    switch (npath_node->type) {
    case NPtype_SV: { /* id is pointer to the SV that sv_size() was called on */
        const SV *sv = (SV*)npath_node->id;
        int type = SvTYPE(sv);
        fprintf(fp, "SV(%s)", svtypename(sv));
        break;
    }
    case NPtype_OP: { /* id is pointer to the OP op_size was called on */
        OP *op = (OP*)npath_node->id;
        fprintf(fp, "OP(%s)", OP_NAME(op));
        break;
    }
    case NPtype_MAGIC: { /* id is pointer to the MAGIC struct */
        MAGIC *magic_pointer = (MAGIC*)npath_node->id;
        /* XXX it would be nice if we could reuse mg_names.c [sigh] */
        fprintf(fp, "MAGIC(%c)", magic_pointer->mg_type ? magic_pointer->mg_type : '0');
        break;
    }
    case NPtype_LINK:
        fprintf(fp, "%s", (const char *)npath_node->id);
        break;
    case NPtype_NAME:
        fprintf(fp, "%s", (const char *)npath_node->id);
        break;
    case NPtype_PLACEHOLDER:
        croak("Unset placeholder encountered");
        break;
    default:    /* assume id is a string pointer */
        fprintf(fp, "UNKNOWN(%d,%p)", npath_node->type, npath_node->id);
        break;
    }
    return 0;
}

void
np_dump_indent(pTHX_ int depth) {
    while (depth-- > 0)
        fprintf(stderr, ":   ");
}


/* recurse up node path ->prev chain till a node with a seqn is found
 * (ie a node that has already been processed), then calls cb for each
 * as it unwinds the recursion. Sets seqn and depth as it unwinds.
 */
int
np_walk_new_nodes(pTHX_ struct state *st,
    npath_node_t *npath_node,
    npath_node_t *npath_node_deeper,
    int (*cb)(pTHX_ struct state *st, npath_node_t *npath_node, npath_node_t *npath_node_deeper))
{
    if (npath_node->seqn) /* node already output */
        return 0;

    if (npath_node->prev) {
        np_walk_new_nodes(aTHX_ st, npath_node->prev, npath_node, cb); /* recurse */
        npath_node->depth = npath_node->prev->depth + 1;
    }
    else npath_node->depth = 0;
    npath_node->seqn = ++st->seqn;

    if (cb) {
        if (cb(aTHX_ st, npath_node, npath_node_deeper)) {
            /* the callback wants us to 'ignore' this node */
            assert(npath_node->prev);
            assert(npath_node->depth);
            assert(npath_node_deeper);
            npath_node->depth--;
            npath_node->seqn = --st->seqn;
            npath_node_deeper->prev = npath_node->prev;
        }
    }

    return 0;
}

void
np_walk_all_nodes(pTHX_ struct state *st,
    npath_node_t *npath_node,
    int (*cb)(pTHX_ struct state *st, npath_node_t *npath_node),
    int depth /* -1 for all */)
{
    if (npath_node->prev && depth)
        np_walk_all_nodes(aTHX_ st, npath_node->prev, cb, --depth); /* recurse */
    cb(aTHX_ st, npath_node);
}

int
np_dump_formatted_node(pTHX_ struct state *st, npath_node_t *npath_node, npath_node_t *npath_node_deeper) {
    PERL_UNUSED_ARG(st);
    PERL_UNUSED_ARG(npath_node_deeper);
    np_dump_indent(aTHX_ npath_node->depth);
    np_print_node_name(aTHX_ stderr, npath_node);
    if (npath_node->type == NPtype_LINK)
        fprintf(stderr, "->"); /* cosmetic */
    fprintf(stderr, "\t\t[#%ld @%u] ", npath_node->seqn, npath_node->depth);
    if (st->trace_level >= 2)
        fprintf(stderr, " %p", npath_node);
    fprintf(stderr, "\n");
    return 0;
}

int
np_dump_node_path(pTHX_ struct state *st, npath_node_t *npath_node) {
    if (npath_node->prev) {
        np_dump_node_path(aTHX_ st, npath_node->prev);
        fprintf(stderr, "/");
    }
    np_print_node_name(aTHX_ stderr, npath_node);
    return 0;
}

void
np_dump_node_path_info(pTHX_ struct state *st, npath_node_t *npath_node, UV attr_type, const char *attr_name, UV attr_value)
{
    if (st->trace_level >= 8)
        warn("np_dump_node_path_info(np=%p, type=%lu, name=%p, value=%lu):\n",
            npath_node, attr_type, attr_name, attr_value);

    if (attr_type == NPattr_LEAFSIZE && !attr_value)
        return; /* ignore zero sized leaf items */

    np_walk_new_nodes(aTHX_ st, npath_node, NULL, np_dump_formatted_node);
    np_dump_indent(aTHX_ npath_node->depth+1);
    switch (attr_type) {
    case NPattr_LEAFSIZE:
        fprintf(stderr, "+%ld %s =%ld", attr_value, attr_name, attr_value+st->total_size);
        break;
    case NPattr_LABEL:
        fprintf(stderr, "~NAMED('%s') %lu", attr_name, attr_value);
        break;
    case NPattr_NOTE:
        fprintf(stderr, "~note %s %lu (%p)", attr_name, attr_value, (void*)attr_value);
        break;
    case NPattr_ADDR:
        fprintf(stderr, "~addr %lu (%p)", attr_value, (void*)attr_value);
        break;
    case NPattr_PADTMP:
    case NPattr_PADNAME:
    case NPattr_PADFAKE:
        fprintf(stderr, "~pad%lu %s %lu", attr_type, attr_name, attr_value);
        break;
    case NPattr_REFCNT:
        fprintf(stderr, "~refcnt %lu", attr_value);
        break;
    default:
        fprintf(stderr, "~?[type %lu unknown]? %s %lu", attr_type, attr_name, attr_value);
        break;
    }
    fprintf(stderr, "\n");
}

int
np_debug_node_dump(pTHX_ struct state *st, npath_node_t *npath_node) {
    PERL_UNUSED_ARG(st);
    fprintf(stderr, "%p [^%p #%-4ld @%-4u] type=%0x id=%p",
        npath_node, npath_node->prev, npath_node->seqn, npath_node->depth,
        npath_node->type, npath_node->id);
    if (npath_node->type == NPtype_LINK)
        fprintf(stderr, " -> ");
    else
        fprintf(stderr, " is ");
    np_print_node_name(aTHX_ stderr, npath_node);
    fprintf(stderr, "\n");
    return 0;
}


int
np_stream_formatted_node(pTHX_ struct state *st, npath_node_t *npath_node, npath_node_t *npath_node_deeper) {
    PERL_UNUSED_ARG(npath_node_deeper);
    fprintf(st->node_stream_fh, "-%u %lu %u ",
        npath_node->type, npath_node->seqn, (unsigned)npath_node->depth
    );
    np_print_node_name(aTHX_ st->node_stream_fh, npath_node);
    fprintf(st->node_stream_fh, "\n");
    return 0;
}

void
np_stream_node_path_info(pTHX_ struct state *st, npath_node_t *npath_node, UV attr_type, const char *attr_name, UV attr_value)
{
    if (!attr_type && !attr_value)
        return; /* ignore zero sized leaf items */
    np_walk_new_nodes(aTHX_ st, npath_node, NULL, np_stream_formatted_node);
    if (attr_type) { /* Attribute type, name and value */
        fprintf(st->node_stream_fh, "%lu %lu ", attr_type, npath_node->seqn);
    }
    else { /* Leaf name and memory size */
        fprintf(st->node_stream_fh, "L %lu ", npath_node->seqn);
    }
    fprintf(st->node_stream_fh, "%lu %s\n", attr_value, attr_name);
}


#endif /* PATH_TRACKING */


#define check_new(st, p)    _check_new(st, p, 1)
#define not_yet_sized(st, p)  _check_new(st, p, 0)

/* 
    Checks to see if thing is in the bitstring. 
    Returns true or false, AND
    notes thing in the segmented bitstring if record is true
 */
static bool
_check_new(struct state *st, const void *const p, bool record) {
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
        char c = *(const char *)p;
	PERL_UNUSED_VAR(c);
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
#if !defined(MULTIPLICITY) || PERL_VERSION > 8 || (PERL_VERSION == 8 && PERL_SUBVERSION > 8)
    /* 5.8.8 and early have an assert() macro that uses Perl_croak, hence needs
       a my_perl under multiplicity  */
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

    if (record)
        leaf[i] |= this_bit;
    return TRUE;
}

static UV
get_sv_follow_seencnt(pTHX_ struct state *st, const SV *const sv)
{
    return PTR2UV(smptr_table_fetch(aTHX_ st->sv_refcnt_ptr_table, (void*)sv));
}

static int
get_sv_follow_state(pTHX_ struct state *st, const SV *const sv)
{
    UV seen_cnt;

    /* For SVs we defer calling check_new() until we've 'seen' the SV
     * at least as often as the reference count. 
     */
    if (SvREFCNT(sv) <= 1 || sv == st->sv_refcnt_to_ignore || SvIMMORTAL(sv)) {
        return (check_new(st, sv)) ? FOLLOW_SINGLE_NOW : FOLLOW_SINGLE_DONE;
    }

    seen_cnt = 1 + PTR2UV(smptr_table_fetch(aTHX_ st->sv_refcnt_ptr_table, (void*)sv));
    smptr_table_store(aTHX_ st->sv_refcnt_ptr_table, (void*)sv, (void*)seen_cnt);

    ++st->multi_refcnt;
    if (st->trace_level >= 9)
        warn("get_sv_follow_state %p refcnt %u seen %lu\n", sv, SvREFCNT(sv), seen_cnt);

    if (seen_cnt < SvREFCNT(sv)) {
        return FOLLOW_MULTI_DEFER;
    }
    if (check_new(st, sv)) {
        return FOLLOW_MULTI_NOW;
    }
    if (seen_cnt > SvREFCNT(sv)) {
        if (st->trace_level >= 2)
            warn("Seen sv %p %lu times but ref count is only %d\n", sv, seen_cnt, SvREFCNT(sv));
        if (st->trace_level >= 7)
            sv_dump((SV*)sv);
    }

    return FOLLOW_MULTI_DONE;
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
free_state(pTHX_ struct state *st)
{
    const int top_level = (sizeof(void *) * 8 - LEAF_BITS - BYTE_BITS) / 8;
    if (st->trace_level) {
        warn("free_state %p: total_size %ld\n", st, st->total_size);
        if (st->multi_refcnt)
            warn("multi_refcnt: %lu\n", st->multi_refcnt);
    }
    if (st->free_state_cb)
        st->free_state_cb(aTHX_ st);
    if (st->state_cb_data)
        Safefree(st->state_cb_data);
    free_tracking_at((void **)st->tracking, top_level);
    if (st->sv_refcnt_ptr_table)
        smptr_table_free(aTHX_ st->sv_refcnt_ptr_table);
    SvREFCNT_dec(st->tmp_sv);
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

#define RECURSE_INTO_NONE   0
#define RECURSE_INTO_OWNED  1
#define RECURSE_INTO_ALL    3 /* not used */
/* weak refs are handled differently */

static bool sv_size(pTHX_ struct state *, pPATH, const SV *const);

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
magic_size(pTHX_ const SV * const thing, struct state *st, pPATH) {
  dNPathNodes(1, NPathArg);
  MAGIC *magic_pointer = SvMAGIC(thing); /* caller ensures thing is SvMAGICAL */

  NPathPushPlaceholderNode;

  /* Have we seen the magic pointer?  (NULL has always been seen before)  */
  while (check_new(st, magic_pointer)) {

    NPathSetNode(magic_pointer, NPtype_MAGIC);

    ADD_SIZE(st, "mg", sizeof(MAGIC));
    /* magic vtables aren't freed when magic is freed, so don't count them.
       (They are static structures. Anything that assumes otherwise is buggy.)
    */


    TRY_TO_CATCH_SEGV {
        /* XXX only chase mg_obj if mg->mg_flags & MGf_REFCOUNTED ? */
	sv_size(aTHX_ st, NPathLink("mg_obj"), magic_pointer->mg_obj);
	if (magic_pointer->mg_len == HEf_SVKEY) {
	    sv_size(aTHX_ st, NPathLink("mg_ptr"), (SV *)magic_pointer->mg_ptr);
	}
#if defined(PERL_MAGIC_utf8) && defined (PERL_MAGIC_UTF8_CACHESIZE)
	else if (magic_pointer->mg_type == PERL_MAGIC_utf8) {
	    if (check_new(st, magic_pointer->mg_ptr)) {
		ADD_SIZE(st, "PERL_MAGIC_utf8", PERL_MAGIC_UTF8_CACHESIZE * 2 * sizeof(STRLEN));
	    }
	}
#endif
        /* XXX also handle mg->mg_type == PERL_MAGIC_utf8 ? */
	else if (magic_pointer->mg_len > 0) {
            if(0)do_magic_dump(0, Perl_debug_log, magic_pointer, 0, 0, FALSE, 0);
	    if (check_new(st, magic_pointer->mg_ptr)) {
		ADD_SIZE(st, "mg_len", magic_pointer->mg_len);
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

#define cv_name(cv) S_cv_name(aTHX_ cv)
char *
S_cv_name(pTHX_ CV *cv)
{
#ifdef CvNAME_HEK
    if (CvNAMED(cv))
        return HEK_KEY(CvNAME_HEK(cv));
#endif
    if (CvGV(cv))
        return GvNAME(CvGV(cv));
    if (CvANON(cv))
        return "CvANON";
    if (cv == PL_main_cv)
        return "MAIN";
    if (CvEVAL(cv))
        return "CvEVAL";
    if (CvSPECIAL(cv))
        return "CvSPECIAL";
    return NULL;
}

#define str_size(st, p, ppath) S_str_size(aTHX_ st, p, ppath, 0)
#define str_size_detail(st, p, ppath, detail_type) S_str_size(aTHX_ st, p, ppath, detail_type)
static void
S_str_size(pTHX_ struct state *st, const char *const p, pPATH, UV detail_type) {
    dNPathNodes(1, NPathArg);
    if(check_new(st, p)) {
        if (detail_type & st->hide_detail) {
            /* add the size to the item that's prev to the calling link */
            NP = NPathArg->prev;
            ADD_SIZE(st, NPathArg->id, 1 + strlen(p));
        }
        else {
            /* use the link name as the item name and size attr name */
            NPathPushNode(NPathArg->id, NPtype_NAME);
            ADD_SIZE(st, NPathArg->id, 1 + strlen(p));
        }
    }
}

static void
regex_size(pTHX_ const REGEXP * const baseregex, struct state *st, pPATH) {
    dNPathNodes(1, NPathArg);
    if(!check_new(st, baseregex))
	return;
  NPathPushNode("REGEXP", NPtype_NAME);
  ADD_SIZE(st, "REGEXP", sizeof(REGEXP));
#if (PERL_VERSION < 11)     
  /* Note the size of the paren offset thing */
  ADD_SIZE(st, "nparens", sizeof(I32) * baseregex->nparens * 2);
  ADD_SIZE(st, "precomp", strlen(baseregex->precomp));
#else
  ADD_SIZE(st, "regexp", sizeof(struct regexp));
  ADD_SIZE(st, "nparens", sizeof(I32) * SvANY(baseregex)->nparens * 2);
  /*ADD_SIZE(st, strlen(SvANY(baseregex)->subbeg));*/
#endif
  if (st->go_yell && !st->regex_whine) {
    carp("Calculated sizes for compiled regexes are incomplete");
    st->regex_whine = 1;
  }
}

static int
hek_size(pTHX_ struct state *st, HEK *hek, U32 shared, pPATH)
{
    dNPathNodes(1, NPathArg);
    int use_node_for_hek = !(st->hide_detail & NPf_DETAIL_HEK);

    /* Hash keys can be shared. Have we seen this before? */
    if (!check_new(st, hek)) {
        if (use_node_for_hek)
            ADD_LINK_ATTR_TO_PREV(st, NPattr_ADDR, "", PTR2UV(hek));
	return 0;
    }
    if (use_node_for_hek) {
        NPathPushNode((shared)?"HEK.shared":"hek", NPtype_NAME);
        ADD_ATTR(st, NPattr_ADDR, "", PTR2UV(hek));

    }
    else NP = NP->prev;

    ADD_SIZE(st, "hek_len", HEK_BASESIZE + hek->hek_len
#if PERL_VERSION < 8
	+ 1 /* No hash key flags prior to 5.8.0  */
#else
	+ 2
#endif
    );
    if (shared) {
#if PERL_VERSION < 10
	ADD_SIZE(st, "he", sizeof(struct he));
#else
	ADD_SIZE(st, "shared_he", STRUCT_OFFSET(struct shared_he, shared_he_hek));
#endif
        /* XXX when shared is true we could perhaps to allocate
        * (size of the hek / shared_he_he.he_valu.hent_refcount)
        * rather than let the first use of the key carry the cost
        */
    }
    return 1;
}

#if (PERL_BCDVERSION >= 0x5009004)
static void
refcounted_he_size(pTHX_ struct state *st, struct refcounted_he *he, pPATH)
{
  dNPathNodes(1, NPathArg);
  if (!check_new(st, he))
    return;
  /* see Perl_refcounted_he_new() in hv.c */
  NPathPushNode("refcounted_he", NPtype_NAME);
  ADD_SIZE(st, "refcounted_he", sizeof(struct refcounted_he));

#ifdef USE_ITHREADS
  ADD_SIZE(st, "refcounted_he_data", he->refcounted_he_keylen);
#else
  hek_size(aTHX_ st, he->refcounted_he_hek, 0, NPathLink("refcounted_he_hek"));
#endif

  if (he->refcounted_he_next)
    refcounted_he_size(aTHX_ st, he->refcounted_he_next, NPathLink("refcounted_he_next"));
}
#endif

static void op_size_class(pTHX_ const OP * const baseop, opclass op_class, bool skip_op_struct, struct state *st, pPATH);

static void
op_size(pTHX_ const OP * const baseop, struct state *st, pPATH)
{
  op_size_class(aTHX_ baseop, cc_opclass(baseop), 0, st, NPathArg);
}

static void
op_size_class(pTHX_ const OP * const baseop, opclass op_class, bool skip_op_struct, struct state *st, pPATH)
{
    /* op_size recurses to follow the chain of opcodes.  For the node path we
     * don't want the chain to be 'nested' in the path so we use dNPathUseParent().
     * Also, to avoid a link-to-a-link the caller should use NPathLinkAndNode()
     * instead of NPathLink().
     */
    dNPathUseParent(NPathArg);

    TRY_TO_CATCH_SEGV {
	TAG;
	if(!check_new(st, baseop))
	    return;
	TAG;

/* segv on OPc_LISTOP op_size(baseop->op_last) is, I suspect, the first symptom of need to handle slabbed allocation of OPs */
#if (PERL_BCDVERSION >= 0x5017000)
if(0)do_op_dump(0, Perl_debug_log, baseop);
#endif

	op_size(aTHX_ baseop->op_next, st, NPathOpLink);
#ifdef PELR_MAD
	madprop_size(aTHX_ st, NPathOpLink, baseop->op_madprop);
#endif
	TAG;
	switch (op_class) {
	case OPc_BASEOP: TAG;
	    if (!skip_op_struct)
		ADD_SIZE(st, "op", sizeof(struct op));
	    TAG;break;
	case OPc_UNOP: TAG;
	    if (!skip_op_struct)
		ADD_SIZE(st, "unop", sizeof(struct unop));
	    op_size(aTHX_ ((UNOP *)baseop)->op_first, st, NPathOpLink);
	    TAG;break;
	case OPc_BINOP: TAG;
	    if (!skip_op_struct)
		ADD_SIZE(st, "binop", sizeof(struct binop));
	    op_size(aTHX_ ((BINOP *)baseop)->op_first, st, NPathOpLink);
	    op_size(aTHX_ ((BINOP *)baseop)->op_last, st, NPathOpLink);
	    TAG;break;
	case OPc_LOGOP: TAG;
	    if (!skip_op_struct)
		ADD_SIZE(st, "logop", sizeof(struct logop));
	    op_size(aTHX_ ((BINOP *)baseop)->op_first, st, NPathOpLink);
	    op_size(aTHX_ ((LOGOP *)baseop)->op_other, st, NPathOpLink);
	    TAG;break;
#ifdef OA_CONDOP
	case OPc_CONDOP: TAG;
	    if (!skip_op_struct)
		ADD_SIZE(st, "condop", sizeof(struct condop));
	    op_size(aTHX_ ((BINOP *)baseop)->op_first, st, NPathOpLink);
	    op_size(aTHX_ ((CONDOP *)baseop)->op_true, st, NPathOpLink);
	    op_size(aTHX_ ((CONDOP *)baseop)->op_false, st, NPathOpLink);
	    TAG;break;
#endif
	case OPc_LISTOP: TAG;
	    if (!skip_op_struct)
		ADD_SIZE(st, "listop", sizeof(struct listop));
	    op_size(aTHX_ ((LISTOP *)baseop)->op_first, st, NPathOpLink);
	    op_size(aTHX_ ((LISTOP *)baseop)->op_last, st, NPathOpLink);
	    TAG;break;
	case OPc_PMOP: TAG;
	    if (!skip_op_struct)
		ADD_SIZE(st, "pmop", sizeof(struct pmop));
	    op_size(aTHX_ ((PMOP *)baseop)->op_first, st, NPathOpLink);
	    op_size(aTHX_ ((PMOP *)baseop)->op_last, st, NPathOpLink);
#if PERL_VERSION < 9 || (PERL_VERSION == 9 && PERL_SUBVERSION < 5)
	    op_size(aTHX_ ((PMOP *)baseop)->op_pmreplroot, st, NPathOpLink);
	    op_size(aTHX_ ((PMOP *)baseop)->op_pmreplstart, st, NPathOpLink);
#endif
	    /* This is defined away in perl 5.8.x, but it is in there for
	       5.6.x */
#ifdef PM_GETRE
	    regex_size(aTHX_ PM_GETRE((PMOP *)baseop), st, NPathLink("PM_GETRE"));
#else
	    regex_size(aTHX_ ((PMOP *)baseop)->op_pmregexp, st, NPathLink("op_pmregexp"));
#endif
	    TAG;break;
	case OPc_SVOP: TAG;
	    if (!skip_op_struct)
		ADD_SIZE(st, "svop", sizeof(struct svop));
	    if (!(baseop->op_type == OP_AELEMFAST
		  && baseop->op_flags & OPf_SPECIAL)) {
		/* not an OP_PADAV replacement */
		sv_size(aTHX_ st, NPathLink("SVOP"), ((SVOP *)baseop)->op_sv);
	    }
	    TAG;break;
#ifdef OA_PADOP
	case OPc_PADOP: TAG;
	    if (!skip_op_struct)
		ADD_SIZE(st, "padop", sizeof(struct padop));
	    TAG;break;
#endif
#ifdef OA_GVOP
	case OPc_GVOP: TAG;
	    if (!skip_op_struct)
		ADD_SIZE(st, "gvop", sizeof(struct gvop));
	    sv_size(aTHX_ st, NPathLink("GVOP"), ((GVOP *)baseop)->op_gv);
	    TAG;break;
#endif
	case OPc_PVOP: TAG;
	    str_size(st, ((PVOP *)baseop)->op_pv, NPathLink("op_pv"));
	    TAG;break;
	case OPc_LOOP: TAG;
	    if (!skip_op_struct)
		ADD_SIZE(st, "loop", sizeof(struct loop));
	    op_size(aTHX_ ((LOOP *)baseop)->op_first, st, NPathOpLink);
	    op_size(aTHX_ ((LOOP *)baseop)->op_last, st, NPathOpLink);
	    op_size(aTHX_ ((LOOP *)baseop)->op_redoop, st, NPathOpLink);
	    op_size(aTHX_ ((LOOP *)baseop)->op_nextop, st, NPathOpLink);
	    op_size(aTHX_ ((LOOP *)baseop)->op_lastop, st, NPathOpLink);
	    TAG;break;
	case OPc_COP: TAG;
        {
          COP *basecop;
          basecop = (COP *)baseop;
	  if (!skip_op_struct)
	    ADD_SIZE(st, "cop", sizeof(struct cop));

          /* Change 33656 by nicholas@mouse-mill on 2008/04/07 11:29:51
          Eliminate cop_label from struct cop by storing a label as the first
          entry in the hints hash. Most statements don't have labels, so this
          will save memory. Not sure how much. 
          The check below will be incorrect fail on bleadperls
          before 5.11 @33656, but later than 5.10, producing slightly too
          small memory sizes on these Perls. */
#if (PERL_VERSION < 11)
          str_size(st, basecop->cop_label, NPathLink("cop_label"));
#endif
#ifdef USE_ITHREADS
          /* XXX many duplicates here - waste memory and clutter the graph */
          /* could treat and attribute instead of a node */
          str_size_detail(st, basecop->cop_file, NPathLink("cop_file"), NPf_DETAIL_COPFILE);
#else
	  sv_size(aTHX_ st, NPathLink("cop_filegv"), (SV *)basecop->cop_filegv);
#endif
          /* CopSTASH isn't ref counted, so isn't 'owned' by the COP */
          /* sv_size(aTHX_ st, NPathLink("CopSTASH"), (SV *)CopSTASH(basecop)); */

#if (PERL_BCDVERSION >= 0x5009004)
#  if (PERL_BCDVERSION < 0x5013007)
#    define COPHH struct refcounted_he
#  endif
#  ifndef CopHINTHASH_get
#    define CopHINTHASH_get(c)  ((COPHH*)((c)->cop_hints_hash))
#  endif
	  refcounted_he_size(aTHX_ st, CopHINTHASH_get(basecop), NPathLink("CopHINTHASH"));
#endif
        }
        TAG;break;
      default:
        TAG;break;
      }
  }
  CAUGHT_EXCEPTION {
      if (st->dangle_whine) 
          warn( "Devel::Size: Encountered dangling pointer in opcode at: %p\n", baseop );
  }
}

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


/* based on Perl_do_dump_pad() - wraps sv_size and adds ADD_ATTR calls for the pad names */
static void
padlist_size(pTHX_ struct state *const st, pPATH, PADLIST *padl)
{
#ifdef PadlistNAMES
    dNPathNodes(2, NPathArg);
#else
    dNPathUseParent(NPathArg);
#endif
    const AV *pad_name;
    const AV *pad;
    SV **pname;
    SV **ppad;
    I32 ix;

    if (!padl)
        return;
    if( 0 && !check_new(st, padl)) /* XXX ? */
        return;

#ifdef PadlistNAMES

    pad_name = *PadlistARRAY(padl);
    pad = PadlistARRAY(padl)[1];
    pname = AvARRAY(pad_name);
    ppad = AvARRAY(pad);

    NPathPushNode("PADLIST", NPtype_NAME);

    ADD_SIZE(st, "PADLIST", sizeof(PADLIST));
    /* add attributes describing the pads */
    for (ix = 1; ix <= AvFILLp(pad_name); ix++) {
        const SV *namesv = pname[ix];
        if (namesv && namesv == &PL_sv_undef) {
            namesv = NULL;
        }
        if (namesv) {
            /* SvFAKE: On a pad name SV, that slot in the frame AV is a REFCNT'ed reference to a lexical from "outside" */
            if (SvFAKE(namesv))
                ADD_ATTR(st, NPattr_PADFAKE, SvPVX_const(namesv), ix);
            else
                ADD_ATTR(st, NPattr_PADNAME, SvPVX_const(namesv), ix);
        }
        else {
            ADD_ATTR(st, NPattr_PADTMP, "SVs_PADTMP", ix);
        }
    }
    sv_size(aTHX_ st, NPathLink("PadlistNAMES"), (SV*)PadlistNAMES(padl));

    ix = PadlistMAX(padl) + 1;
    ADD_SIZE(st, "PADs", sizeof(PAD*) * ix);

    for (ix = 1; ix <= PadlistMAX(padl); ix++) {
	sv_size(aTHX_ st, NPathLink("elem"), (SV*)PadlistARRAY(padl)[ix]);
        if (NP->seqn) /* link was emitted, so we can add attr XXX encapsulate */
            ADD_LINK_ATTR_TO_TOP(st, NPattr_NOTE, "i", ix);
    }

#else
    /* XXX rework this to have the same node structure as above? */
    pad_name = MUTABLE_AV(*av_fetch(MUTABLE_AV(padl), 0, FALSE));
    pname = AvARRAY(pad_name);

    for (ix = 1; ix <= AvFILLp(pad_name); ix++) {
        const SV *namesv = pname[ix];
        if (namesv && namesv == &PL_sv_undef) {
            namesv = NULL;
        }
        if (namesv) {
            /* SvFAKE: On a pad name SV, that slot in the frame AV is a REFCNT'ed reference to a lexical from "outside" */
            if (SvFAKE(namesv))
                ADD_ATTR(st, NPattr_PADFAKE, SvPVX_const(namesv), ix);
            else
                ADD_ATTR(st, NPattr_PADNAME, SvPVX_const(namesv), ix);
        }
        else {
            ADD_ATTR(st, NPattr_PADTMP, "SVs_PADTMP", ix);
        }

    }
    sv_size(aTHX_ st, NPathArg, (SV*)padl);
#endif
}


/* returns true if the NPathLink argument was 'used' ie output */
static bool
sv_size(pTHX_ struct state *const st, pPATH, const SV * const orig_thing)
{
  const SV *thing = orig_thing;
  dNPathNodes(3, NPathArg);
  U32 type;
  int do_NPathNoteAddr = 0;

  if (NULL == thing)
      return 0;

  int follow_state = get_sv_follow_state(aTHX_ st, orig_thing);
  if (st->trace_level >= 2) {
    warn("sv_size 0x%p: %s refcnt=%d, seen=%lu, follow=%d, type=%d\n",
        thing, svtypename(thing), SvREFCNT(thing),
        get_sv_follow_seencnt(aTHX_ st, thing),
        follow_state, SvTYPE(thing));
    if (st->trace_level >= 9)
        do_sv_dump(0, Perl_debug_log, (SV *)thing, 0, 2, 0, 40);
  }

  switch (follow_state) {
  case FOLLOW_SINGLE_NOW:
        /* only give addr attribute to SVs with refcnt=1 if asked */
        if (!(st->hide_detail & NPf_DETAIL_REFCNT1) && NP->prev)
            ADD_LINK_ATTR_TO_PREV(st, NPattr_ADDR, "", PTR2UV(thing));
        break;
  case FOLLOW_SINGLE_DONE:
        /* we don't output addr note for refcnt=1 (FOLLOW_SINGLE_NOW)
         * so there's no point in outputting one here.
         * The SvIMMORTAL's also pass through here.
         */
        if (!(st->hide_detail & NPf_DETAIL_REFCNT1))
            ADD_LINK_ATTR_TO_PREV(st, NPattr_ADDR, "", PTR2UV(thing));
        return 0;
  case FOLLOW_MULTI_DEFER:
        ADD_LINK_ATTR_TO_PREV(st, NPattr_ADDR, "", PTR2UV(thing));
        if (get_sv_follow_seencnt(aTHX_ st, thing) == 1) {
            /* XXX use name of link here ? */
            ADD_LINK_ATTR_TO_PREV(st, NPattr_LABEL, svtypename(thing), 0);
            ADD_LINK_ATTR_TO_PREV(st, NPattr_REFCNT, "", SvREFCNT(thing));
        }
        return 0;
  case FOLLOW_MULTI_DONE:
        ADD_LINK_ATTR_TO_PREV(st, NPattr_ADDR, "", PTR2UV(thing));
        return 0;
  case FOLLOW_MULTI_NOW:
        ADD_LINK_ATTR_TO_PREV(st, NPattr_ADDR, "", PTR2UV(thing));
        do_NPathNoteAddr=1;
        break;
  }

  type = SvTYPE(thing);
  if (type > SVt_LAST) {
      fprintf(stderr, "%s SV type: %u encountered at ",
        (SvTYPE(thing) == (svtype)SVTYPEMASK) ? "Freed" : "Unknown", type);
      np_dump_node_path(aTHX_ st, NP);
      fprintf(stderr, ":\n");
      sv_dump((SV*)thing);
      return 0;
  }
  NPathPushNode(thing, NPtype_SV);
  if (do_NPathNoteAddr || !NPathArg)
    ADD_ATTR(st, NPattr_ADDR, "", PTR2UV(thing));
  ADD_SIZE(st, "sv_head", sizeof(SV));
  ADD_SIZE(st, "sv_body", body_sizes[type]);

  switch (type) {
#if (PERL_VERSION < 11)
    /* Is it a reference? */
  case SVt_RV: TAG;
#else
  case SVt_IV: TAG;
#endif
    if(st->recurse && SvROK(thing)) {
        if (SvWEAKREF(thing) && st->recurse_into_weak) {
            sv_size(aTHX_ st, NPathLink("weakRV"), SvRV_const(thing));
        }
        else {
            sv_size(aTHX_ st, NPathLink("RV"), SvRV_const(thing));
        }
    }
    TAG;break;

  case SVt_PVAV: TAG;
    /* Is there anything in the array? */
    if (AvMAX(thing) != -1) {
        SSize_t i;
        /* an array with 10 slots has AvMax() set to 9 - te 2007-04-22 */
        ADD_SIZE(st, "av_max", sizeof(SV *) * (AvMAX(thing) + 1));
        ADD_ATTR(st, NPattr_NOTE, "av_len", av_len((AV*)thing));
        dbg_printf(("total_size: %li AvMAX: %li av_len: $i\n", st->total_size, AvMAX(thing), av_len((AV*)thing)));

        for (i=0; i <= AvFILLp(thing); ++i) { /* in natural order */
            sv_size(aTHX_ st, NPathLink("elem"), AvARRAY(thing)[i]);
            if (NP->seqn) /* link was emitted, so we can add attr XXX encapsulate */
                ADD_LINK_ATTR_TO_TOP(st, NPattr_NOTE, "i", i);
        }
    }
    /* Add in the bits on the other side of the beginning */

    dbg_printf(("total_size %li, sizeof(SV *) %li, AvARRAY(thing) %li, AvALLOC(thing)%li , sizeof(ptr) %li \n", 
        st->total_size, sizeof(SV*), AvARRAY(thing), AvALLOC(thing), sizeof( thing )));

    /* under Perl 5.8.8 64bit threading, AvARRAY(thing) was a pointer while AvALLOC was 0,
       resulting in grossly overstated sized for arrays. Technically, this shouldn't happen... */
    if (AvALLOC(thing) != 0) {
      ADD_SIZE(st, "AvALLOC", (sizeof(SV *) * (AvARRAY(thing) - AvALLOC(thing))));
      }
#if (PERL_VERSION < 9)
    /* Is there something hanging off the arylen element?
       Post 5.9.something this is stored in magic, so will be found there,
       and Perl_av_arylen_p() takes a non-const AV*, hence compilers rightly
       complain about AvARYLEN() passing thing to it.  */
    sv_size(aTHX_ st, NPathLink("ARYLEN"), AvARYLEN(thing));
#endif
    TAG;break;

  case SVt_PVHV: TAG;
    /* Now the array of buckets */
#ifdef HvENAME
    if (HvENAME(thing)) { ADD_ATTR(st, NPattr_LABEL, HvENAME(thing), 0); }
#else
    if (HvNAME(thing))  { ADD_ATTR(st, NPattr_LABEL, HvNAME(thing), 0); }
#endif
    if (orig_thing == (SV*)PL_strtab) {
        ADD_ATTR(st, NPattr_LABEL, "PL_strtab", 0);
    }
    ADD_SIZE(st, "hv_max", (sizeof(HE *) * (HvMAX(thing) + 1)));
    /* Now walk the bucket chain */
    if (HvARRAY(thing)) {
      HE *cur_entry;
      UV cur_bucket = 0;

      for (cur_bucket = 0; cur_bucket <= HvMAX(thing); cur_bucket++) {
        cur_entry = *(HvARRAY(thing) + cur_bucket);
        while (cur_entry) {
            HEK *hek = cur_entry->hent_hek;

            if (!(st->hide_detail & NPf_DETAIL_HEK)) {
                NPathPushLink("HE");
                NPathPushNode("HE", NPtype_NAME);
            }

            ADD_SIZE(st, "he", sizeof(HE));
            hek_size(aTHX_ st, hek, HvSHAREKEYS(thing), NPathLink("hent_hek"));
            if (orig_thing == (SV*)PL_strtab) {
                /* For PL_strtab the HeVAL is used as a refcnt */
                ADD_SIZE(st, "shared_hek", HeKLEN(cur_entry));
            }
            else {
                if (sv_size(aTHX_ st, NPathLink("HeVAL"), HeVAL(cur_entry))) {
                    /* give a safe short hint of the key string */
                    pv_pretty(st->tmp_sv, HEK_KEY(hek), HEK_LEN(hek), 20,
                        NULL, NULL, PERL_PV_ESCAPE_NONASCII|PERL_PV_PRETTY_ELLIPSES);
                    ADD_LINK_ATTR_TO_TOP(st, NPattr_LABEL, SvPVX(st->tmp_sv), 0);
                }
            }

            if (!(st->hide_detail & NPf_DETAIL_HEK)) {
                NPathPopNode;
                NPathPopNode;
            }
            cur_entry = cur_entry->hent_next;
        }
      } /* bucket chain */
    }

#ifdef HvAUX
    if (SvOOK(thing)) {
	/* This direct access is arguably "naughty": */
	struct mro_meta *meta = HvAUX(thing)->xhv_mro_meta;
#if PERL_VERSION > 13 || PERL_SUBVERSION > 8 /* XXX plain || seems like a bug */
	/* As is this: */
	I32 count = HvAUX(thing)->xhv_name_count;

	if (count) {
	    HEK **names = HvAUX(thing)->xhv_name_u.xhvnameu_names;
	    if (count < 0)
		count = -count;
	    while (--count)
		hek_size(aTHX_ st, names[count], 1, NPathLink("HvAUXelem"));
	}
	else
#endif
	{
	    hek_size(aTHX_ st, HvNAME_HEK(thing), 1, NPathLink("HvNAME_HEK"));
	}

	ADD_SIZE(st, "xpvhv_aux", sizeof(struct xpvhv_aux));
	if (meta) {
	    ADD_SIZE(st, "mro_meta", sizeof(struct mro_meta));
	    sv_size(aTHX_ st, NPathLink("mro_nextmethod"), (SV *)meta->mro_nextmethod);
#if PERL_VERSION > 10 || (PERL_VERSION == 10 && PERL_SUBVERSION > 0)
	    sv_size(aTHX_ st, NPathLink("isa"), (SV *)meta->isa);
#endif
#if PERL_VERSION > 10
	    sv_size(aTHX_ st, NPathLink("mro_linear_all"), (SV *)meta->mro_linear_all);
	    sv_size(aTHX_ st, NPathLink("mro_linear_current"), meta->mro_linear_current);
#else
	    sv_size(aTHX_ st, NPathLink("mro_linear_dfs"), (SV *)meta->mro_linear_dfs);
	    sv_size(aTHX_ st, NPathLink("mro_linear_c3"), (SV *)meta->mro_linear_c3);
#endif
	}
    }
#else
    str_size(st, HvNAME_get(thing), NPathLink("HvNAME"));
#endif /* HvAUX */
    TAG;break;


  case SVt_PVFM: TAG;
    padlist_size(aTHX_ st, NPathLink("CvPADLIST"), CvPADLIST(thing));
    sv_size(aTHX_ st, NPathLink("CvOUTSIDE"), (SV *)CvOUTSIDE(thing));

    if (st->go_yell && !st->fm_whine) {
      carp("Devel::Size: Calculated sizes for FMs are incomplete");
      st->fm_whine = 1;
    }
    goto freescalar;

  case SVt_PVCV: TAG;
    ADD_ATTR(st, NPattr_LABEL, cv_name((CV *)thing), 0);
    sv_size(aTHX_ st, NPathLink("CvGV"), (SV *)CvGV(thing));
    padlist_size(aTHX_ st, NPathLink("CvPADLIST"), CvPADLIST(thing));
    if (!CvWEAKOUTSIDE(thing)) /* XXX */
        sv_size(aTHX_ st, NPathLink("CvOUTSIDE"), (SV *)CvOUTSIDE(thing));
    if (CvISXSUB(thing)) {
	sv_size(aTHX_ st, NPathLink("cv_const_sv"), cv_const_sv((CV *)thing));
    } else {
	/* Note that we don't chase CvSTART */
	op_size(aTHX_ CvROOT(thing), st, NPathLinkAndNode("CvROOT", "OPs"));
    }
    goto freescalar;

  case SVt_PVIO: TAG;
    /* Some embedded char pointers */
    str_size(st, ((XPVIO *) SvANY(thing))->xio_top_name, NPathLink("xio_top_name"));
    str_size(st, ((XPVIO *) SvANY(thing))->xio_fmt_name, NPathLink("xio_fmt_name"));
    str_size(st, ((XPVIO *) SvANY(thing))->xio_bottom_name, NPathLink("xio_bottom_name"));
    /* Throw the GVs on the list to be walked if they're not-null */
    sv_size(aTHX_ st, NPathLink("xio_top_gv"), (SV *)((XPVIO *) SvANY(thing))->xio_top_gv);
    sv_size(aTHX_ st, NPathLink("xio_bottom_gv"), (SV *)((XPVIO *) SvANY(thing))->xio_bottom_gv);
    sv_size(aTHX_ st, NPathLink("xio_fmt_gv"), (SV *)((XPVIO *) SvANY(thing))->xio_fmt_gv);

    /* Only go trotting through the IO structures if they're really
       trottable. If USE_PERLIO is defined we can do this. If
       not... we can't, so we don't even try */
#ifdef USE_PERLIO
    /* Dig into xio_ifp and xio_ofp here */
    if (st->go_yell && !st->perlio_whine) {
        carp("Calculated sizes for perlio layers are incomplete\n");
        st->perlio_whine = 1;
    }
#endif
    goto freescalar;

  case SVt_PVLV: TAG;
#if (PERL_VERSION < 9)
    goto freescalar;
#endif

  case SVt_PVGV: TAG;
    if(isGV_with_GP(thing)) {
#ifdef GvNAME_HEK
	hek_size(aTHX_ st, GvNAME_HEK(thing), 1, NPathLink("GvNAME_HEK"));
#else	
	ADD_SIZE(st, "GvNAMELEN", GvNAMELEN(thing));
#endif
        ADD_ATTR(st, NPattr_LABEL, GvNAME(thing), 0);
#ifdef GvFILE_HEK
	hek_size(aTHX_ st, GvFILE_HEK(thing), 1, NPathLink("GvFILE_HEK"));
#elif defined(GvFILE)
/* XXX this coredumped for me in t/recurse.t with a non-threaded 5.8.9
 * so I've changed the condition to be more restricive
 *#  if !defined(USE_ITHREADS) || (PERL_VERSION > 8 || (PERL_VERSION == 8 && PERL_SUBVERSION > 8))
 */
#  if (PERL_VERSION > 8 || (PERL_VERSION == 8 && PERL_SUBVERSION > 9))
	/* With itreads, before 5.8.9, this can end up pointing to freed memory
	   if the GV was created in an eval, as GvFILE() points to CopFILE(),
	   and the relevant COP has been freed on scope cleanup after the eval.
	   5.8.9 adds a binary compatible fudge that catches the vast majority
	   of cases. 5.9.something added a proper fix, by converting the GP to
	   use a shared hash key (porperly reference counted), instead of a
	   char * (owned by who knows? possibly no-one now) */
	str_size(st, GvFILE(thing), NPathLink("GvFILE"));
#  endif
#endif
	/* Is there something hanging off the glob? */
	if (check_new(st, GvGP(thing))) {
	    ADD_SIZE(st, "GP", sizeof(GP));
	    sv_size(aTHX_ st, NPathLink("gp_sv"), (SV *)(GvGP(thing)->gp_sv));
	    sv_size(aTHX_ st, NPathLink("gp_av"), (SV *)(GvGP(thing)->gp_av));
	    sv_size(aTHX_ st, NPathLink("gp_hv"), (SV *)(GvGP(thing)->gp_hv));
	    /* Do not follow CVs in the method cache - for now we assume we'll find
	     * them via another path with a better name. (Once we have proper
	     * refcnt handling then special cases like this can all be removed.)
	     */
	    if (!GvGP(thing)->gp_cvgen)
		sv_size(aTHX_ st, NPathLink("gp_cv"), (SV *)(GvGP(thing)->gp_cv));
	    sv_size(aTHX_ st, NPathLink("gp_egv"), (SV *)(GvGP(thing)->gp_egv));
	    sv_size(aTHX_ st, NPathLink("gp_form"), (SV *)(GvGP(thing)->gp_form));
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
    if(st->recurse && SvROK(thing))
	sv_size(aTHX_ st, NPathLink("RV"), SvRV_const(thing));
    else if (SvIsCOW_shared_hash(thing))
	hek_size(aTHX_ st, SvSHARED_HEK_FROM_PV(SvPVX(thing)), 1, NPathLink("SvSHARED_HEK_FROM_PV"));
    else
	ADD_SIZE(st, "SvLEN", SvLEN(thing));

    if(SvOOK(thing)) {
	STRLEN len;
	SvOOK_offset(thing, len);
	ADD_SIZE(st, "SvOOK", len);
    }
    TAG;break;

  }

  if (type >= SVt_PVMG) {
    if (SvMAGICAL(thing))
      magic_size(aTHX_ thing, st, NPathLink("MG"));
#ifdef SvOURSTASH
    /* SVpad_OUR shares same flag bit as SVpbm_VALID and others */
    if (type == SVt_PVGV && SvPAD_OUR(thing) && SvOURSTASH(thing))
      sv_size(aTHX_ st, NPathLink("SvOURSTASH"), (SV *)SvOURSTASH(thing));
#endif
    if (SvOBJECT(thing))
      sv_size(aTHX_ st, NPathLink("SvSTASH"), (SV *)SvSTASH(thing));
  }

  return 1;
}

static void
free_memnode_state(pTHX_ struct state *st)
{
    if (st->node_stream_fh && st->node_stream_name && *st->node_stream_name) {
        Pid_t pid = getpid();
        NV dur = gettimeofday_nv(aTHX)-st->start_time_nv;
        if (st->opts & SMopt_IS_TEST) {
            pid = 0; dur = 0;
        }
        fprintf(st->node_stream_fh, "E %lu %d %" NVgf " %s\n",
            st->total_size, pid, dur, "unnamed");
        if (*st->node_stream_name == '|') {
            if (pclose(st->node_stream_fh)) /* XXX PerlIO! */
                warn("%s exited with an error status\n", st->node_stream_name);
        }
        else {
            if (fclose(st->node_stream_fh))
                warn("Error closing %s: %s\n", st->node_stream_name, strerror(errno));
        }
    }
}

static struct state *
new_state(pTHX_ SV *root_sv, UV bool_opts)
{
    SV *sv;
    struct state *st;
    char *sizeme_hide = PerlEnv_getenv("SIZEME_HIDE"); /* XXX hack */

    Newxz(st, 1, struct state);
    st->start_time_nv = gettimeofday_nv(aTHX);
    st->opts = bool_opts;
    st->recurse = RECURSE_INTO_OWNED;
    st->go_yell = TRUE;
    if (sizeme_hide) {
        st->hide_detail = (*sizeme_hide) ? atoi(sizeme_hide) : NPf_DETAIL_REFCNT1;
    }
    if (NULL != (sv = get_sv("Devel::Size::warn", FALSE))) {
	st->dangle_whine = st->go_yell = SvIV(sv) ? TRUE : FALSE;
    }
    if (NULL != (sv = get_sv("Devel::Size::dangle", FALSE))) {
	st->dangle_whine = SvIV(sv) ? TRUE : FALSE;
    }
    if (NULL != (sv = get_sv("Devel::Size::trace", FALSE))) {
	st->trace_level = SvIV(sv);
        if (st->trace_level)
            warn("Devel::Size::trace=%d\n", st->trace_level);
    }
    check_new(st, &PL_sv_undef);
    check_new(st, &PL_sv_no);
    check_new(st, &PL_sv_yes);
#if (PERL_BCDVERSION >= 0x5008000)
    check_new(st, &PL_sv_placeholder);
#endif
    st->tmp_sv = newSV(0);
    check_new(st, st->tmp_sv);

    st->sv_refcnt_to_ignore = root_sv;
    st->sv_refcnt_ptr_table = smptr_table_new(aTHX);

#ifdef PATH_TRACKING
    /* XXX quick hack */
    st->node_stream_name = PerlEnv_getenv("SIZEME");
    if (st->node_stream_name) {
        Pid_t pid = getpid();
        NV start_time = st->start_time_nv;
        if (*st->node_stream_name) {
            if (*st->node_stream_name == '|') /* XXX PerlIO! */
                st->node_stream_fh = popen(st->node_stream_name+1, "w");
            else
                st->node_stream_fh = fopen(st->node_stream_name, "wb");
            if (!st->node_stream_fh)
                croak("Can't open '%s' for writing: %s", st->node_stream_name, strerror(errno));
            if(0)setlinebuf(st->node_stream_fh); /* XXX temporary for debugging */
            st->add_attr_cb = np_stream_node_path_info;
            if (st->opts & SMopt_IS_TEST) {
                pid = 0;
                start_time = 0;
            }
            fprintf(st->node_stream_fh, "S %d %d %" NVgf " %s\n",
                1, pid, start_time, "unnamed");
        }
        else 
            st->add_attr_cb = np_dump_node_path_info;
    }
    st->free_state_cb = free_memnode_state;
#endif

    return st;
}


/* based on S_visit() in sv.c */
static void
unseen_sv_size(pTHX_ struct state *st, pPATH)
{
    dVAR;
    SV* sva;
    U32 arena_count;
    int want_type;
    dNPathNodes(3, NPathArg);

    if (st->trace_level)
        fprintf(stderr, "sweeping arenas for unseen SVs\n");

    NPathPushNode("unseen", NPtype_NAME);

    /* by this point we should have visited all the SVs
     * so now we'll run through all the SVs via the arenas
     * in order to find any that we've missed for some reason.
     * Once the rest of the code is finding ALL the SVs then any
     * found here will be leaks.
     * Meanwhile, this can find many thousands...
     */

    /* we break this down by type to be more useful (and avoid lots of
     * SVs with the same path
     */
    for (want_type = SVt_LAST-1; want_type >= 0; --want_type) {
        char path_link_group[40];
        sprintf(path_link_group, "arena-%s", svtypenames[want_type]);

        for (sva = PL_sv_arenaroot; sva; sva = MUTABLE_SV(SvANY(sva))) {
            const SV * const svend = &sva[SvREFCNT(sva)];
            SV* sv;

            if (st->trace_level >= 7)
                fprintf(stderr, "%s start: %ld\n", path_link_group, st->total_size);

            for (sv = sva + 1; sv < svend; ++sv) {
                if (SvTYPE(sv) != (svtype)SVTYPEMASK && SvREFCNT(sv)) {
                    /* is a live SV */
                    if (SvTYPE(sv) == want_type && not_yet_sized(st, sv)) {
                        NPathPushLink(path_link_group);
                        NPathPushNode(path_link_group, NPtype_NAME);
                        if (sv_size(aTHX_ st, NPathLink("arena"), sv)) {
                            /* TODO - resolve these 'unseen' SVs by expanding the coverage of perl_size() */
                            /* you can enable the sv_dump below and try to work out what the SVs are */
                            ADD_LINK_ATTR_TO_TOP(st, NPattr_ADDR, "", PTR2UV(sv)); /* TODO control via detail */
                            if (st->trace_level > 2) {
                                fprintf(stderr, "UNSEEN ");
                                sv_dump(sv);
                            }
                        }
                        NPathPopNode;
                        NPathPopNode;
                    }
                }
                else { /* is a dead SV */
                    /* will be sized via PL_sv_root later */
                }
            }

            if (st->trace_level >= 7)
                fprintf(stderr, "%s   end: %ld\n", path_link_group, st->total_size);

        }
    }
}


static UV
deferred_by_refcnt_size(pTHX_ struct state *st, pPATH, int cycle)
{
    dNPathNodes(1, NPathArg);
    char node_name[20];
    SMPTR_TBL_ENT_t **ary;
    UV visited = 0;
    int i;

    if (st->trace_level)
        fprintf(stderr, "sweeping probable ref loops, cycle %d\n", cycle);

    NPathPushNode("cycle", NPtype_NAME);
    sprintf(node_name, "cycle-%d", cycle);
    ADD_ATTR(st, NPattr_LABEL, node_name, 0);

    /* visit each item in sv_refcnt_ptr_table */
    /* TODO ought to be abstracted and moved into smptr_tbl.c */
    st->sv_refcnt_ptr_table->tbl_split_disabled = TRUE;
    ary = st->sv_refcnt_ptr_table->tbl_ary;
    for (i=0; i <= st->sv_refcnt_ptr_table->tbl_max; i++, ary++) {
        SMPTR_TBL_ENT_t *tblent = *ary;
        for (; tblent; tblent = tblent->next) {
            const SV *sv = tblent->oldval;

            UV visitcnt = PTR2UV(tblent->newval);
            UV refcnt = SvREFCNT(sv);
            if (visitcnt < refcnt) {
                if (st->trace_level >= 6)
                    fprintf(stderr, "SVs 0x%p with refcnt %d has been seen %lu times\n", sv, SvREFCNT(sv), visitcnt);
                /* prime the visitcnt so we'll follow the sv on the sv_size call that follows */
                smptr_table_store(aTHX_ st->sv_refcnt_ptr_table, (void*)sv, INT2PTR(void*, refcnt-1));
                sv_size(aTHX_ st, NPathLink("cycle"), sv);
                ++visited;
            }
        }
    }
    st->sv_refcnt_ptr_table->tbl_split_disabled = FALSE;
    if (st->sv_refcnt_ptr_table->tbl_split_needed)
        smptr_table_split(aTHX_ st->sv_refcnt_ptr_table);

    NPathPopNode;

    if (st->trace_level)
        fprintf(stderr, "visited %lu deferred SVs on cycle %d\n", visited, cycle);

    return visited;
}

#ifdef PERL_MAD
static void
madprop_size(pTHX_ struct state *const st, pPATH, MADPROP *prop)
{
  dNPathNodes(2, NPathArg);
  if (!check_new(st, prop))
    return;
  NPathPushNode("MADPROP", NPtype_NAME);
  ADD_SIZE(st, "MADPROP", sizeof(MADPROP));
  ADD_SIZE(st, "val", prop->mad_vlen);
  /* XXX recurses, so should perhaps be handled like op_size to avoid the chain */
  if (prop->mad_next)
    madprop_size(aTHX_ st, NPathLink("mad_next"), prop->mad_next);
}
#endif

#if (PERL_BCDVERSION >= 0x5009005)
static void
parser_size(pTHX_ struct state *const st, pPATH, yy_parser *parser)
{
  yy_stack_frame *ps;
  dNPathNodes(2, NPathArg);
  if (!check_new(st, parser))
    return;
  NPathPushNode("yy_parser", NPtype_NAME);
  ADD_SIZE(st, "yy_parser", sizeof(yy_parser));

  NPathPushLink("stack");
  NPathPushNode("stack", NPtype_NAME);
  ADD_SIZE(st, "yy_stack_frames", parser->stack_size * sizeof(yy_stack_frame));
  ADD_ATTR(st, NPattr_NOTE, "n", parser->stack_size);
  for (ps = parser->stack; ps <= parser->ps; ps++) {
#if (PERL_BCDVERSION >= 0x5011002) /* roughly */
    if (sv_size(aTHX_ st, NPathLink("compcv"), (SV*)ps->compcv))
        ADD_LINK_ATTR_TO_TOP(st, NPattr_NOTE, "i", ps - parser->ps);
#else /* prior to perl 8c63ea58  Dec 8 2009 */
    if (sv_size(aTHX_ st, NPathLink("comppad"), (SV*)ps->comppad))
        ADD_LINK_ATTR_TO_TOP(st, NPattr_NOTE, "i", ps - parser->ps);
#endif
  }
  NPathPopNode;
  NPathPopNode;

  sv_size(aTHX_ st, NPathLink("lex_repl"), (SV*)parser->lex_repl);
  sv_size(aTHX_ st, NPathLink("lex_stuff"), (SV*)parser->lex_stuff);
  sv_size(aTHX_ st, NPathLink("linestr"), (SV*)parser->linestr);
  sv_size(aTHX_ st, NPathLink("in_my_stash"), (SV*)parser->in_my_stash);
  /*sv_size(aTHX_ st, NPathLink("rsfp"), parser->rsfp); */
  sv_size(aTHX_ st, NPathLink("rsfp_filters"), (SV*)parser->rsfp_filters);
#ifdef PERL_MAD
  sv_size(aTHX_ st, NPathLink("endwhite"), parser->endwhite);
  sv_size(aTHX_ st, NPathLink("nextwhite"), parser->nextwhite);
  sv_size(aTHX_ st, NPathLink("skipwhite"), parser->skipwhite);
  sv_size(aTHX_ st, NPathLink("thisclose"), parser->thisclose);
  madprop_size(aTHX_ st, NPathLink("thismad"), parser->thismad);
  sv_size(aTHX_ st, NPathLink("thisopen"), parser->thisopen);
  sv_size(aTHX_ st, NPathLink("thisstuff"), parser->thisstuff);
  sv_size(aTHX_ st, NPathLink("thistoken"), parser->thistoken);
  sv_size(aTHX_ st, NPathLink("thiswhite"), parser->thiswhite);
#endif
  op_size_class(aTHX_ (OP*)parser->saved_curcop, OPc_COP, 0,
		st, NPathLinkAndNode("saved_curcop", "OPs"));

  if (parser->old_parser)
    parser_size(aTHX_ st, NPathLink("old_parser"), parser->old_parser);
}
#endif


static void
perl_size(pTHX_ struct state *const st, pPATH)
{
  dNPathNodes(5, NPathArg); /* extra levels for NPathLinkAndNode etc */

  /* if(!check_new(st, interp)) return; */
  NPathPushNode("PerlInterpreter", NPtype_NAME);
#if defined(MULTIPLICITY)
  ADD_SIZE(st, "PerlInterpreter", sizeof(PerlInterpreter));
#endif
/*
 *      perl
 *          PL_defstash
 *          others
 *      unknown <== = O/S Heap size - perl - free_malloc_space
 */
  /* start with PL_defstash to get everything reachable from \%main:: */
  sv_size(aTHX_ st, NPathLink("PL_defstash"), (SV*)PL_defstash);

  NPathPushLink("others");
  NPathPushNode("others", NPtype_NAME); /* group these (typically much smaller) items */
  sv_size(aTHX_ st, NPathLink("PL_defgv"), (SV*)PL_defgv);
  sv_size(aTHX_ st, NPathLink("PL_incgv"), (SV*)PL_incgv);
  sv_size(aTHX_ st, NPathLink("PL_rs"), (SV*)PL_rs);
  sv_size(aTHX_ st, NPathLink("PL_fdpid"), (SV*)PL_fdpid);
  sv_size(aTHX_ st, NPathLink("PL_modglobal"), (SV*)PL_modglobal);
  sv_size(aTHX_ st, NPathLink("PL_errors"), (SV*)PL_errors);
  sv_size(aTHX_ st, NPathLink("PL_stashcache"), (SV*)PL_stashcache);
  sv_size(aTHX_ st, NPathLink("PL_curstname"), (SV*)PL_curstname);
  sv_size(aTHX_ st, NPathLink("PL_patchlevel"), (SV*)PL_patchlevel);
#ifdef PL_apiversion
  sv_size(aTHX_ st, NPathLink("PL_apiversion"), (SV*)PL_apiversion);
#endif
#ifdef PL_registered_mros
  sv_size(aTHX_ st, NPathLink("PL_registered_mros"), (SV*)PL_registered_mros);
#endif
#ifdef USE_ITHREADS
  sv_size(aTHX_ st, NPathLink("PL_regex_padav"), (SV*)PL_regex_padav);
#endif
  sv_size(aTHX_ st, NPathLink("PL_warnhook"), (SV*)PL_warnhook);
  sv_size(aTHX_ st, NPathLink("PL_diehook"), (SV*)PL_diehook);
  sv_size(aTHX_ st, NPathLink("PL_endav"), (SV*)PL_endav);
  sv_size(aTHX_ st, NPathLink("PL_main_cv"), (SV*)PL_main_cv);
  /*sv_size(aTHX_ st, NPathLink("PL_main_root"), (SV*)PL_main_root); is OP? */
  /*sv_size(aTHX_ st, NPathLink("PL_main_start"), (SV*)PL_main_start); is OP? */
  sv_size(aTHX_ st, NPathLink("PL_envgv"), (SV*)PL_envgv);
  sv_size(aTHX_ st, NPathLink("PL_hintgv"), (SV*)PL_hintgv);
  sv_size(aTHX_ st, NPathLink("PL_e_script"), (SV*)PL_e_script);
  sv_size(aTHX_ st, NPathLink("PL_encoding"), (SV*)PL_encoding);
#ifdef PL_ofsgv
  sv_size(aTHX_ st, NPathLink("PL_ofsgv"), (SV*)PL_ofsgv);
#endif
  sv_size(aTHX_ st, NPathLink("PL_statname"), (SV*)PL_statname);
  sv_size(aTHX_ st, NPathLink("PL_statgv"), (SV*)PL_statgv);
  sv_size(aTHX_ st, NPathLink("PL_argvout_stack"), (SV*)PL_argvout_stack);

  sv_size(aTHX_ st, NPathLink("PL_beginav"), (SV*)PL_beginav);
  sv_size(aTHX_ st, NPathLink("PL_beginav_save"), (SV*)PL_beginav_save);
  sv_size(aTHX_ st, NPathLink("PL_checkav_save"), (SV*)PL_checkav_save);
#ifdef PL_unitcheckav
  sv_size(aTHX_ st, NPathLink("PL_unitcheckav"), (SV*)PL_unitcheckav);
#endif
#ifdef PL_unitcheckav_save
  sv_size(aTHX_ st, NPathLink("PL_unitcheckav_save"), (SV*)PL_unitcheckav_save);
#endif
  sv_size(aTHX_ st, NPathLink("PL_endav"), (SV*)PL_endav);
  sv_size(aTHX_ st, NPathLink("PL_checkav"), (SV*)PL_checkav);
  sv_size(aTHX_ st, NPathLink("PL_initav"), (SV*)PL_initav);

#ifdef PL_isarev
  sv_size(aTHX_ st, NPathLink("PL_isarev"), (SV*)PL_isarev);
#endif
  sv_size(aTHX_ st, NPathLink("PL_fdpid"), (SV*)PL_fdpid);
  sv_size(aTHX_ st, NPathLink("PL_preambleav"), (SV*)PL_preambleav);
  sv_size(aTHX_ st, NPathLink("PL_ors_sv"), (SV*)PL_ors_sv);
  sv_size(aTHX_ st, NPathLink("PL_modglobal"), (SV*)PL_modglobal);
  sv_size(aTHX_ st, NPathLink("PL_custom_op_names"), (SV*)PL_custom_op_names);
  sv_size(aTHX_ st, NPathLink("PL_custom_op_descs"), (SV*)PL_custom_op_descs);
#ifdef PL_custom_ops
  sv_size(aTHX_ st, NPathLink("PL_custom_ops"), (SV*)PL_custom_ops);
#endif
  sv_size(aTHX_ st, NPathLink("PL_compcv"), (SV*)PL_compcv);
  sv_size(aTHX_ st, NPathLink("PL_DBcv"), (SV*)PL_DBcv);
#ifdef PERL_USES_PL_PIDSTATUS
  sv_size(aTHX_ st, NPathLink("PL_pidstatus"), (SV*)PL_pidstatus);
#endif
  sv_size(aTHX_ st, NPathLink("PL_subname"), (SV*)PL_subname);
  sv_size(aTHX_ st, NPathLink("PL_toptarget"), (SV*)PL_toptarget);
  sv_size(aTHX_ st, NPathLink("PL_bodytarget"), (SV*)PL_bodytarget);
#ifdef USE_LOCALE_NUMERIC
  sv_size(aTHX_ st, NPathLink("PL_numeric_radix_sv"), (SV*)PL_numeric_radix_sv);
  str_size(st, PL_numeric_name, NPathLink("PL_numeric_name"));
#endif
#ifdef USE_LOCALE_COLLATE
  str_size(st, PL_collation_name, NPathLink("PL_collation_name"));
#endif
  str_size(st, PL_origfilename, NPathLink("PL_origfilename"));
  str_size(st, PL_inplace, NPathLink("PL_inplace"));
  str_size(st, PL_osname, NPathLink("PL_osname"));
  if (PL_op_mask && check_new(st, PL_op_mask))
    ADD_SIZE(st, "PL_op_mask", PL_maxo);
  if (PL_exitlistlen && check_new(st, PL_exitlist))
    ADD_SIZE(st, "PL_exitlist", (PL_exitlistlen * sizeof(PerlExitListEntry *))
                              + (PL_exitlistlen * sizeof(PerlExitListEntry)));
#ifdef PERL_IMPLICIT_CONTEXT
#ifdef PL_my_cxt_size
  if (PL_my_cxt_size && check_new(st, PL_my_cxt_list)) {
    ADD_SIZE(st, "PL_my_cxt_list", (PL_my_cxt_size * sizeof(void *)));
#ifdef PERL_GLOBAL_STRUCT_PRIVATE
    ADD_SIZE(st, "PL_my_cxt_keys", (PL_my_cxt_size * sizeof(char *)));
#endif
  }
#endif
#endif

#ifdef PL_stashpad
    if (1) { /* PL_stashpad */
        PADOFFSET o = 0;
        for (; o < PL_stashpadmax; ++o) {
            if (PL_stashpad[o])
                sv_size(aTHX_ st, NPathLink("PL_stashpad"), (SV*)PL_stashpad[o]);
        }
    }
#else
    /* XXX ??? */
#endif

  op_size_class(aTHX_ (OP*)&PL_compiling, OPc_COP, 1, st, NPathLinkAndNode("PL_compiling", "OPs"));
  op_size_class(aTHX_ (OP*)PL_curcopdb, OPc_COP, 0, st, NPathLinkAndNode("PL_curcopdb", "OPs"));

#if (PERL_BCDVERSION >= 0x5009005)
  parser_size(aTHX_ st, NPathLink("PL_parser"), PL_parser);
#endif

  if (1) {
    int i;
    /* count character classes  */
#ifdef POSIX_SWASH_COUNT
    for (i = 0; i < POSIX_SWASH_COUNT; i++) {
        sv_size(aTHX_ st, NPathLink("PL_utf8_swash_ptrs"), PL_utf8_swash_ptrs[i]);
    }
#else
    /* XXX ??? */
#endif
    sv_size(aTHX_ st, NPathLink("PL_utf8_mark"), PL_utf8_mark);
    sv_size(aTHX_ st, NPathLink("PL_utf8_toupper"), PL_utf8_toupper);
    sv_size(aTHX_ st, NPathLink("PL_utf8_totitle"), PL_utf8_totitle);
    sv_size(aTHX_ st, NPathLink("PL_utf8_tolower"), PL_utf8_tolower);
    sv_size(aTHX_ st, NPathLink("PL_utf8_tofold"), PL_utf8_tofold);
    sv_size(aTHX_ st, NPathLink("PL_utf8_idstart"), PL_utf8_idstart);
    sv_size(aTHX_ st, NPathLink("PL_utf8_idcont"), PL_utf8_idcont);
#ifdef PL_utf8_foldclosures
    sv_size(aTHX_ st, NPathLink("PL_utf8_foldclosures"), (SV*)PL_utf8_foldclosures);
#endif
#ifdef POSIX_CC_COUNT
    for (i = 0; i < POSIX_CC_COUNT; i++) {
        sv_size(aTHX_ st, NPathLink("PL_Posix_ptrs"), PL_Posix_ptrs[i]);
        sv_size(aTHX_ st, NPathLink("PL_L1Posix_ptrs"), PL_L1Posix_ptrs[i]);
        sv_size(aTHX_ st, NPathLink("PL_XPosix_ptrs"), PL_XPosix_ptrs[i]);
    }
#endif
  }

  /* TODO stacks: cur, main, tmps, mark, scope, save */
  /* TODO PL_exitlist */
  /* TODO PL_reentrant_buffers etc */
  /* TODO environ */
  /* TODO PerlIO? PL_known_layers PL_def_layerlist PL_perlio_fd_refcnt etc */
  /* TODO threads? */
  /* TODO anything missed? */

  /* --- by this point we should have seen all reachable SVs --- */

  /* in theory we shouldn't have any elements in PL_strtab that haven't been seen yet */
  sv_size(aTHX_ st, NPathLink("PL_strtab.unseen"), (SV*)PL_strtab);

  /* iterate over our sv_refcnt_ptr_table looking for any SVs that haven't been */
  /* seen as often as their refcnt and follow them now */
  if (1) {
    int cycle = 0;
    NPathPushLink("ref_loops");
    NPathPushNode("ref_loops", NPtype_NAME);
    /* loop so that if we visited any SVs then try again since we may have encountered some
     * more SVs that haven't been visited yet
     */
    while (deferred_by_refcnt_size(aTHX_ st, NPathLink("ref_loops"), ++cycle))
        (void)1;
    NPathPopNode;
    NPathPopNode;
  }

  /* iterate over all SVs to find any we've not accounted for yet */
  /* once the code above is visiting all SVs, any found here have been leaked */
  unseen_sv_size(aTHX_ st, NPathLink("unaccounted"));

  NPathPopNode; /* others node */
  NPathPopNode; /* others link */

  NPathPushLink("freed");
  NPathPushNode("freed", NPtype_NAME);

  /* unused space in sv head arenas */
  if (PL_sv_root) {
    SV *p = PL_sv_root;
    UV free_heads = 1;
#  define SvARENA_CHAIN(sv)     SvANY(sv) /* XXX breaks encapsulation*/
    while ((p = MUTABLE_SV(SvARENA_CHAIN(p)))) {
        if (!check_new(st, p)) /* sanity check */
            warn("Free'd SV head 0x%p unexpectedly already seen", p);
        ++free_heads;
    }
    NPathPushLink("free_sv_heads");
    NPathPushNode("free_sv_heads", NPtype_NAME);
    ADD_SIZE(st, "sv", free_heads * sizeof(SV));
    ADD_ATTR(st, NPattr_NOTE, "n", free_heads);
    NPathPopNode;
    NPathPopNode;
  }

  if (1) {
    int sv_type;
    for (sv_type = SVt_LAST-1; sv_type >= 0; --sv_type) {
        void **next;
        UV free_bodies = 0;
        UV body_size = body_sizes[sv_type];
        char nodename[40];
        const char *typename = svtypenames[sv_type];

        for (next = &PL_body_roots[sv_type]; *next; next = *next) {
            ++free_bodies;
        }
        if (!free_bodies)
            continue;

        switch (sv_type) { /* see struct body_details comments in sv.c */
        case SVt_NULL:
            typename = "HE";
            body_size = sizeof(HE);
            break;
        case SVt_IV:
            typename = "ptr_tbl_ent";
            body_size = sizeof(struct ptr_tbl_ent);
            break;
        }
        sprintf(nodename, "free_sv_bodies.%s", typename);

        NPathPushLink("free_sv_bodies");
        NPathPushNode("free_sv_bodies", NPtype_NAME);

        ADD_SIZE(st, "sv_bodies", free_bodies * body_size);
        ADD_ATTR(st, NPattr_NOTE, "n", free_bodies);
        ADD_ATTR(st, NPattr_LABEL, nodename, 0);

        NPathPopNode;
        NPathPopNode;
    }
  }

}


static void
malloc_free_size(pTHX_ struct state *const st, pPATH)
{
    dNPathNodes(3, NPathArg);

# ifdef _MALLOC_MALLOC_H_ /* OSX. Not sure where else mstats is available */
# define HAS_MSTATS
# endif
# ifdef HAS_MSTATS
    /* some systems have the SVID2/XPG mallinfo structure and function */
    struct mstats ms = mstats(); /* mstats() first */
# endif
    NPathPushNode("malloc", NPtype_NAME);

# ifdef HAS_MSTATS
    NPathPushLink("bytes_free");
    NPathPushNode("bytes_free", NPtype_NAME);
    ADD_SIZE(st, "bytes_free", ms.bytes_free);
    ADD_ATTR(st, NPattr_NOTE, "bytes_total", ms.bytes_total);
    ADD_ATTR(st, NPattr_NOTE, "bytes_used",  ms.bytes_used);
    ADD_ATTR(st, NPattr_NOTE, "chunks_used", ms.chunks_used);
    ADD_ATTR(st, NPattr_NOTE, "chunks_free", ms.chunks_free);
    NPathPopNode;
    NPathPopNode;

    /* TODO get heap size from OS and add a node: unknown = heapsize - perl - ms.bytes_free */
    /* for now we use malloc bytes_total as a good approximation */
    NPathPushLink("unknown");
    NPathPushNode("unknown", NPtype_NAME);
    ADD_SIZE(st, "unknown", ms.bytes_total - st->total_size);
    NPathPopNode;
    NPathPopNode;

# else
    ADD_ATTR(st, NPattr_NOTE, "no_malloc_info", 0);
    /* XXX ? */
# endif
}


static UV
perform(SV *actions_sv, SV *options_sv)
{
    dTHX;
    UV total_size;
#define MaxPathNodeCount 100
    /* XXX this has some leaks if it croaks */
    struct state *st = new_state(aTHX_ (SV*)NULL, SMopt_IS_TEST);
    dNPathNodes(MaxPathNodeCount, NULL);
    SSize_t i;
    HV *options_hv;

    if (!SvROK(actions_sv) || SvTYPE(SvRV(actions_sv)) != SVt_PVAV)
        croak("perform needs an array reference");

    if (options_sv && (!SvROK(options_sv) || SvTYPE(SvRV(options_sv)) != SVt_PVAV))
        croak("perform options must be a hash reference");
    options_hv = (options_sv) ? (HV*)SvRV(options_sv) : (HV*)sv_2mortal((SV*)newHV());

    /* [ [ "action", ...args... ], [ ... ], ... ] */
    for (i=0; i <= AvFILLp((AV*)SvRV(actions_sv)); ++i) {
        SV *act_spec_sv = AvARRAY((AV*)SvRV(actions_sv))[i];
        AV *act_spec_av;
        int action_argcount;
        char *action_name;

        if (!act_spec_sv || !SvROK(act_spec_sv) || SvTYPE(SvRV(act_spec_sv)) != SVt_PVAV)
            croak("perform: action[%lu] isn't an array ref", i);
        act_spec_av = (AV*)SvRV(act_spec_sv);
        action_argcount = av_len(act_spec_av);
        action_name = SvPV_nolen(AvARRAY(act_spec_av)[0]);

#define IS_ACTION(wanted_name, wanted_argcount) \
    (strEQ(action_name, wanted_name) \
        && ((action_argcount != wanted_argcount) \
            ? (croak("action[%lu] %s needs %d args but has %d", i, action_name, wanted_argcount, action_argcount),1) \
            : 1) )
#define ACTION_ARG_PV(argnum) (SvPV_nolen(AvARRAY(act_spec_av)[argnum]))
#define ACTION_ARG_UV(argnum) (SvUV(      AvARRAY(act_spec_av)[argnum]))

        if (st->trace_level)
            warn("perform %s\n", action_name);
        if (IS_ACTION("pushnode", 2)) {
            NPathPushNode(ACTION_ARG_PV(1), ACTION_ARG_UV(2));
        }
        else if (IS_ACTION("pushlink", 1)) {
            NPathPushLink(ACTION_ARG_PV(1));
        }
        else if (IS_ACTION("popnode", 0)) {
            NPathPopNode;
        }
        else if (IS_ACTION("addsize", 2)) {
            ADD_SIZE(st, ACTION_ARG_PV(1), ACTION_ARG_UV(2));
        }
        else if (IS_ACTION("addattr", 3)) {
            UV attr_type = ACTION_ARG_UV(1);
            char *attr_name = ACTION_ARG_PV(2);
            UV attr_value = ACTION_ARG_UV(3);
            ADD_ATTR(st, attr_type, attr_name, attr_value);
        }
        else {
            croak("perform: Unknown action '%s' at index %lu", action_name, i);
        }
    }

    total_size = st->total_size;
    if (st->trace_level)
        warn("perform complete - total_size %lu\n", total_size);
    free_state(aTHX_ st);
    return total_size;
}


MODULE = Devel::SizeMe        PACKAGE = Devel::SizeMe::TestWrite

PROTOTYPES: DISABLE

UV
perform(SV *actions_sv, SV *options_sv=NULL)
OUTPUT:
    RETVAL


MODULE = Devel::SizeMe        PACKAGE = Devel::SizeMe::Core

PROTOTYPES: DISABLE


UV
constant()
    PROTOTYPE:
    ALIAS:
        NPtype_NAME	    = NPtype_NAME
        NPtype_LINK	    = NPtype_LINK
        NPtype_SV	    = NPtype_SV
        NPtype_MAGIC	    = NPtype_MAGIC
        NPtype_OP	    = NPtype_OP
        NPtype_PLACEHOLDER  = NPtype_PLACEHOLDER
        NPtype_max          = NPtype_max
        NPattr_LEAFSIZE	    = NPattr_LEAFSIZE
        NPattr_LABEL	    = NPattr_LABEL
        NPattr_PADFAKE	    = NPattr_PADFAKE
        NPattr_PADNAME	    = NPattr_PADNAME
        NPattr_PADTMP	    = NPattr_PADTMP
        NPattr_NOTE	    = NPattr_NOTE
        NPattr_ADDR	    = NPattr_ADDR
        NPattr_REFCNT	    = NPattr_REFCNT
        NPattr_max	    = NPattr_max
    CODE:
        RETVAL = ix;
    OUTPUT:
        RETVAL


MODULE = Devel::SizeMe        PACKAGE = Devel::SizeMe

UV
size(orig_thing)
     SV *orig_thing
ALIAS:
    total_size = RECURSE_INTO_OWNED
CODE:
{
  SV *thing = orig_thing;
  struct state *st;
  
  /* If they passed us a reference then dereference it. This is the
     only way we can check the sizes of arrays and hashes */
  if (SvROK(thing)) {
    thing = SvRV(thing);
  }

  st = new_state(aTHX_ thing, 0);
  st->recurse = ix;
  sv_size(aTHX_ st, NULL, thing);
  RETVAL = st->total_size;
  free_state(aTHX_ st);
}
OUTPUT:
  RETVAL


UV
perl_size()
CODE:
{
  /* just the current perl interpreter */
  /* PL_defstash works around the main:: => :: ref loop */
  struct state *st = new_state(aTHX_ (SV*)PL_defstash, 0);
  st->recurse = RECURSE_INTO_OWNED;
  perl_size(aTHX_ st, NULL);
  RETVAL = st->total_size;
  free_state(aTHX_ st);
}
OUTPUT:
  RETVAL

UV
heap_size()
CODE:
{
  /* the current perl interpreter plus malloc, in the context of total heap size */

  struct state *st = new_state(aTHX_ (SV*)PL_defstash, 0);
  dNPathNodes(1, NULL);
  NPathPushNode("heap", NPtype_NAME);

  st->recurse = RECURSE_INTO_OWNED;
  perl_size(aTHX_ st, NPathLink("perl_interp"));
  /* TODO size memory used by Devel::SizeMe here (so it's subtracted from malloc.unknown) */
  malloc_free_size(aTHX_ st, NPathLink("malloc")); /* call last */

  RETVAL = st->total_size;
  free_state(aTHX_ st);
}
OUTPUT:
  RETVAL

