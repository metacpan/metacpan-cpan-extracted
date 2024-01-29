#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* Perl portability code */
#ifndef cxinc
#define cxinc()	Perl_cxinc(aTHX)
#endif

#ifdef	SV_UNDEF_RETURNS_NULL
#define MySvPV(sv, len)	    SvPV_flags(sv, len, SV_GMAGIC|SV_UNDEF_RETURNS_NULL)
#else
#define	MySvPV(sv, len)	    (SvOK(sv)?SvPV_flags(sv, len, SV_GMAGIC):((len=0), NULL))
#endif

#ifndef caller_cx
/* Copied from pp_ctl.c for pre 5.13.5 */
STATIC I32
S_dopoptosub_at(pTHX_ const PERL_CONTEXT *cxstk, I32 startingblock)
{
    dVAR;
    I32 i;
    for (i = startingblock; i >= 0; i--) {
	register const PERL_CONTEXT * const cx = &cxstk[i];
	switch (CxTYPE(cx)) {
	default:
	    continue;
	case CXt_EVAL:
	case CXt_SUB:
	case CXt_FORMAT:
	    return i;
	}
    }
    return i;
}
#define	dopoptosub_at(c,s)	S_dopoptosub_at(aTHX_ c,s)

STATIC const PERL_CONTEXT *
Perl_caller_cx(pTHX_ I32 count, const PERL_CONTEXT **dbcxp)
{
    I32 cxix = dopoptosub_at(cxstack, cxstack_ix);
    const PERL_CONTEXT *cx;
    const PERL_CONTEXT *ccstack = cxstack;
    const PERL_SI *top_si = PL_curstackinfo;

    for (;;) {
	while (cxix < 0 && top_si->si_type != PERLSI_MAIN) {
	    top_si = top_si->si_prev;
	    ccstack = top_si->si_cxstack;
	    cxix = dopoptosub_at(ccstack, top_si->si_cxix);
	}
	if (cxix < 0)
	    return NULL;
	if (PL_DBsub && GvCV(PL_DBsub) && cxix >= 0 &&
		ccstack[cxix].blk_sub.cv == GvCV(PL_DBsub))
	    count++;
	if (!count--)
	    break;
	cxix = dopoptosub_at(ccstack, cxix - 1);
    }

    cx = &ccstack[cxix];
    if (dbcxp) *dbcxp = cx;

    if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
        const I32 dbcxix = dopoptosub_at(ccstack, cxix - 1);
	if (PL_DBsub && GvCV(PL_DBsub) && dbcxix >= 0 && ccstack[dbcxix].blk_sub.cv == GvCV(PL_DBsub))
	    cx = &ccstack[dbcxix];
    }

    return cx;
}
#define caller_cx(count, dbcxp)	    Perl_caller_cx(aTHX_ count, dbcxp);
#endif

/*
 * Can't use standard SvPVutf8 because the potential upgrade is in place
 * and modifying a user scalar in any way is bad practice unless expected.
 */
STATIC char *
S_mySvPVutf8(pTHX_ SV *sv, STRLEN *const len) {
    if(!SvOK(sv)) {
	*len = 0;
	return NULL;
    }
    SvGETMAGIC(sv);
    if(!SvUTF8(sv)) {
	sv = sv_mortalcopy(sv);
	sv_utf8_upgrade_nomg(sv);
    }
    return  SvPV_nomg(sv, *len);
}
#define MySvPVutf8(sv, len) S_mySvPVutf8(aTHX_ sv, &len)

#include <lmdb.h>

/* My own exportable constants */
#define LMDB_OFLAGN	2
#define LMDB_ZEROCOPY	0x0001
#define LMDB_UTF8	0x0002

#include "const-c.inc"

#define	F_ISSET(w, f)	(((w) & (f)) == (f))
#define	TOHIWORD(F)	((F) << 16)
#define StoreUV(k, v)	(void)hv_store(RETVAL, (k), sizeof(k) - 1, newSVuv(v), 0)

typedef IV MyInt;

/* lifted from Perl core and simplified [rt.cpan.org #148421] */
STATIC UV
my_do_vecget(pTHX_ SV *sv, STRLEN offset, int size)
{
    STRLEN srclen;
    const I32 svpv_flags = ((PL_op->op_flags & OPf_MOD || LVRET)
                                          ? SV_UNDEF_RETURNS_NULL : 0);
    unsigned char *s = (unsigned char *)
                            SvPV_flags(sv, srclen, (svpv_flags|SV_GMAGIC));
    UV retnum = 0;

    if (!s) {
      s = (unsigned char *)"";
    }

    /* aka. PERL_ARGS_ASSERT_DO_VECGET */
    assert(sv);
    /* sanity checks to make sure the premises for our simplifications still hold */
    assert(LMDB_OFLAGN <= 8);
    if (size != LMDB_OFLAGN)
        Perl_croak(aTHX_ "This is a crippled version of vecget that supports size==%d (LMDB_OFLAGN)", LMDB_OFLAGN);

    if (SvUTF8(sv)) {
        if (Perl_sv_utf8_downgrade_flags(aTHX_ sv, TRUE, 0)) {
            /* PVX may have changed */
            s = (unsigned char *) SvPV_flags(sv, srclen, svpv_flags);
        }
        else {
            Perl_croak(aTHX_ "Use of strings with code points over 0xFF"
                             " as arguments to vec is forbidden");
        }
    }

    STRLEN bitoffs = ((offset % 8) * size) % 8;
    STRLEN uoffset = offset / (8 / size);

    if (uoffset >= srclen)
        return 0;

    retnum = (s[uoffset] >> bitoffs) & nBIT_MASK(size);
    return retnum;
}

static void
populateStat(pTHX_ HV** hashptr, int res, MDB_stat *stat)
{
    HV* RETVAL;
    if(res)
	croak("%s", mdb_strerror(res));
    RETVAL = newHV();
    StoreUV("psize", stat->ms_psize);
    StoreUV("depth", stat->ms_depth);
    StoreUV("branch_pages", stat->ms_branch_pages);
    StoreUV("leaf_pages", stat->ms_leaf_pages);
    StoreUV("overflow_pages", stat->ms_overflow_pages);
    StoreUV("entries", stat->ms_entries);
    *hashptr = RETVAL;
}

typedef	MDB_env*    LMDB__Env;
typedef	MDB_txn*    LMDB__Txn;
typedef	MDB_txn*    TxnOrNull;
typedef	MDB_dbi	    LMDB;
typedef	MDB_val	    DBD;
typedef	MDB_val	    DBK;
typedef	MDB_val	    DBKC;
typedef	MDB_cursor* LMDB__Cursor;
typedef	unsigned int flags_t;

#define MY_CXT_KEY  "LMDB_File::_guts" XS_VERSION

typedef struct {
    LMDB__Env envid;
    AV *DCmps;
    AV *Cmps;
    SV *OFlags;
    LMDB curdb;
    unsigned int cflags;
    SV *my_asv;
    SV *my_bsv;
    OP *lmdb_dcmp_cop;
} my_cxt_t;

START_MY_CXT

#define LMDB_OFLAGS TOHIWORD(my_do_vecget(aTHX_ MY_CXT.OFlags, dbi, LMDB_OFLAGN))
#define MY_CMP   *av_fetch(MY_CXT.Cmps, MY_CXT.curdb, 1)
#define MY_DCMP	 *av_fetch(MY_CXT.DCmps, MY_CXT.curdb, 1)

#define CHECK_ALLCUR	\
    envid = mdb_txn_env(txn);						    \
    if(envid != MY_CXT.envid) {                                             \
	SV* eidx = sv_2mortal(newSVuv(PTR2UV(MY_CXT.envid = envid)));	    \
	HE* enve = hv_fetch_ent(get_hv("LMDB::Env::Envs", 0), eidx, 0, 0);  \
	AV* hh = (AV*)SvRV(HeVAL(enve));				    \
	MY_CXT.DCmps = (AV *)SvRV(*av_fetch(hh, 1, 0));			    \
	MY_CXT.Cmps = (AV *)SvRV(*av_fetch(hh, 2, 0));			    \
	MY_CXT.OFlags = *av_fetch(hh, 3, 0);				    \
	MY_CXT.curdb = 0; /* Invalidate cached */			    \
    }									    \
    if(MY_CXT.curdb != dbi) {						    \
	MY_CXT.curdb = dbi;						    \
	mdb_dbi_flags(txn, dbi, &MY_CXT.cflags);			    \
	MY_CXT.cflags |= LMDB_OFLAGS;					    \
    }									    \
    my_cmpsv = MY_CMP;							    \
    my_dcmpsv = MY_DCMP


#define ISDBKINT    F_ISSET(MY_CXT.cflags, MDB_INTEGERKEY)
#define ISDBDINT    F_ISSET(MY_CXT.cflags, MDB_DUPSORT|MDB_INTEGERDUP)
#define LwZEROCOPY  F_ISSET(MY_CXT.cflags, TOHIWORD(LMDB_ZEROCOPY))
#define LwUTF8      F_ISSET(MY_CXT.cflags, TOHIWORD(LMDB_UTF8))

#define dCURSOR	    MDB_txn* txn; MDB_dbi dbi
#define PREC_FLGS(c) txn = mdb_cursor_txn(c); dbi = mdb_cursor_dbi(c); CHECK_ALLCUR

#define Sv2DBD(sv, data) \
    if(ISDBDINT) {						\
	SvIV_please(sv);					\
	data.mv_data = &(((XPVIV*)SvANY(sv))->xiv_iv);		\
	data.mv_size = sizeof(MyInt);				\
    }								\
    else data.mv_data = LwUTF8 ? MySvPVutf8(sv, data.mv_size)	\
			       : MySvPV(sv, data.mv_size)

/* ZeroCopy support
 *
 * The following code was originally copied from Leon Timmermans's File::Map module
 *
 * This software is copyright (c) 2008, 2009 by Leon Timmermans <leont@cpan.org>.
 * This is free software; you can redistribute it and/or modify it under
 * the same terms as perl itself.
 */

#define MMAP_MAGIC_NUMBER 0x4c4d

struct mmap_info {
    void* real_address; /* Currently unused */
    void* fake_address;
    size_t real_length; /* Currently unused */
    size_t fake_length;
    int isutf8;
#ifdef USE_ITHREADS
    perl_mutex count_mutex;
    perl_mutex data_mutex;
    PerlInterpreter* owner;
    perl_cond cond;
    int count;
#endif
};

static void
reset_var(pTHX_ SV* var, struct mmap_info* info) {
    SvPVX(var) = info->fake_address;
    SvLEN(var) = 0;
    SvCUR(var) = info->fake_length;
    SvPOK_only_UTF8(var);
#if DEBUG_AS_DUAL
    SvUV_set(var, PTR2UV(info->fake_address));
    SvIOK_on(var);
    SvIsUV_on(var);
#endif
}

static void
mmap_fixup(pTHX_ SV* var, struct mmap_info* info, const char* string, STRLEN len) {
    if (ckWARN(WARN_SUBSTR)) {
	Perl_warn(aTHX_ "Writing directly to a memory mapped var is not recommended");
	if (SvCUR(var) > info->fake_length)
	    Perl_warn(aTHX_ "Truncating new value to size of the memory map");
    }

    if (string && len)
	Copy(string, info->fake_address, MIN(len, info->fake_length), char);
    SV_CHECK_THINKFIRST_COW_DROP(var);
    if (SvROK(var))
	sv_unref_flags(var, SV_IMMEDIATE_UNREF);
    if (SvPOK(var))
	SvPV_free(var);
    reset_var(aTHX_ var, info);
}

static int
mmap_write(pTHX_ SV* var, MAGIC* magic) {
    struct mmap_info* info = (struct mmap_info*) magic->mg_ptr;
    if (!SvOK(var))
	mmap_fixup(aTHX_ var, info, NULL, 0);
    else if (!SvPOK(var)) {
	STRLEN len;
	const char* string = info->isutf8 ? MySvPVutf8(var, len) : SvPV(var, len);
	mmap_fixup(aTHX_ var, info, string, len);
    }
    else if (SvPVX(var) != info->fake_address)
	mmap_fixup(aTHX_ var, info, SvPVX(var), SvCUR(var));
    else
	SvPOK_only_UTF8(var);
    return 0;
}

static int
mmap_clear(pTHX_ SV* var, MAGIC* magic) {
    Perl_die(aTHX_ "Can't clear a mapped variable");
    return 0;
}

static int
mmap_free(pTHX_ SV* var, MAGIC* magic) {
	struct mmap_info* info = (struct mmap_info*) magic->mg_ptr;
#ifdef USE_ITHREADS
	MUTEX_LOCK(&info->count_mutex);
	if (--info->count == 0) {
		COND_DESTROY(&info->cond);
		MUTEX_DESTROY(&info->data_mutex);
		MUTEX_UNLOCK(&info->count_mutex);
		MUTEX_DESTROY(&info->count_mutex);
		PerlMemShared_free(info);
	}
	else {
		MUTEX_UNLOCK(&info->count_mutex);
	}
#else
	PerlMemShared_free(info);
#endif
	SvREADONLY_off(var);
	SvPV_free(var);
	SvPVX(var) = NULL;
	SvCUR(var) = 0;
	return 0;
}

#ifdef USE_ITHREADS
static int
mmap_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* param)
{
	struct mmap_info* info = (struct mmap_info*) magic->mg_ptr;
	MUTEX_LOCK(&info->count_mutex);
	assert(info->count);
	++info->count;
	MUTEX_UNLOCK(&info->count_mutex);
	return 0;
}
#else
#define mmap_dup 0
#endif

#ifdef MGf_LOCAL
static int
mmap_local(pTHX_ SV* var, MAGIC* magic)
{
	Perl_croak(aTHX_ "Can't localize file map");
}
#define mmap_local_tail , mmap_local
#else
#define mmap_local_tail
#endif

static MGVTBL
mmap_table  = { 0, mmap_write,  0, mmap_clear, mmap_free,  0, mmap_dup mmap_local_tail };

static void
check_new_variable(pTHX_ SV* var)
{
    if (SvTYPE(var) > SVt_PVMG && SvTYPE(var) != SVt_PVLV)
	Perl_croak(aTHX_ "Trying to map into a nonscalar!\n");
#ifdef sv_unmagicext
    sv_unmagicext(var, PERL_MAGIC_uvar, &mmap_table);
#else
    sv_unmagic(var, PERL_MAGIC_uvar);
#endif
    SV_CHECK_THINKFIRST_COW_DROP(var);
    if (SvREADONLY(var))
	Perl_croak(aTHX_ "%s", PL_no_modify);
    if (SvROK(var))
	sv_unref_flags(var, SV_IMMEDIATE_UNREF);
    if (SvNIOK(var))
	SvNIOK_off(var);
    if (SvPOK(var))
	SvPV_free(var);
    SvUPGRADE(var, SVt_PVMG);
}

static struct mmap_info*
initialize_mmap_info(
    pTHX_
    void* address,
    size_t len,
    ptrdiff_t correction,
    int isutf8
) {
    struct mmap_info* info = PerlMemShared_malloc(sizeof *info);
    info->real_address = address;
    info->fake_address = (char*)address + correction;
    info->real_length = len + correction;
    info->fake_length = len;
#ifdef USE_ITHREADS
    MUTEX_INIT(&info->count_mutex);
    MUTEX_INIT(&info->data_mutex);
    COND_INIT(&info->cond);
    info->count = 1;
#endif
    info->isutf8 = isutf8;
    return info;
}

static void
add_magic(
    pTHX_
    SV* var,
    struct mmap_info* info,
    const MGVTBL* table,
    int writable
) {
    MAGIC* magic = sv_magicext(var, NULL, PERL_MAGIC_uvar, table, (const char*) info, 0);
    magic->mg_private = MMAP_MAGIC_NUMBER;
#ifdef MGf_LOCAL
    magic->mg_flags |= MGf_LOCAL;
#endif
#ifdef USE_ITHREADS
    magic->mg_flags |= MGf_DUP;
#endif
    if(info->isutf8)
	SvUTF8_on(var);
    else
	SvUTF8_off(var);
    SvTAINTED_on(var);
    if (!writable)
	SvREADONLY_on(var);
}

static void
sv_setstatic(pTHX_ pMY_CXT_ SV *const sv, MDB_val *data, bool is_res)
{
    if(ISDBDINT && !is_res)
	    sv_setiv_mg(sv, *(MyInt *)data->mv_data);
    else {
	const PERL_CONTEXT *cx = caller_cx(0, NULL);
	int utf8 = LwUTF8 && !(CopHINTS_get(cx ? cx->blk_oldcop : PL_curcop) & HINT_BYTES);
	if(utf8 && !is_utf8_string(data->mv_data, data->mv_size)) {
	    if(ckWARN(WARN_UTF8))
		Perl_warn(aTHX_ "Malformed UTF-8 in get");
	    utf8 = 0;
	}
	if(LwZEROCOPY || is_res) {
	    struct mmap_info* info;
	    unsigned int eflags;
	    int writable;
	    check_new_variable(aTHX_ sv);
	    info = initialize_mmap_info(aTHX_ data->mv_data, data->mv_size, 0, utf8);
	    mdb_env_get_flags(MY_CXT.envid, &eflags);
	    writable = is_res ||
		(F_ISSET(eflags, MDB_WRITEMAP) && !F_ISSET(MY_CXT.cflags, MDB_RDONLY));
	    add_magic(aTHX_ sv, info, &mmap_table, writable);
	    reset_var(aTHX_ sv, info);
	} else {
	    sv_setpvn_mg(sv, data->mv_data, data->mv_size);
	    if(utf8) SvUTF8_on(sv);
	    else SvUTF8_off(sv);
	}
    }
}

/* Callback Handling */

static int
LMDB_cmp(const MDB_val *a, const MDB_val *b) {
    dTHX;
    dMY_CXT;
    dSP;
    int ret;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    sv_setpvn_mg(MY_CXT.my_asv, a->mv_data, a->mv_size);
    sv_setpvn_mg(MY_CXT.my_bsv, b->mv_data, b->mv_size);
    call_sv(SvRV(MY_CMP), G_SCALAR|G_NOARGS);
    SPAGAIN;
    ret = POPi;
    PUTBACK;
    FREETMPS; LEAVE;
    return ret;
}

#define CvValid(rcv)	(SvROK(rcv) && SvTYPE(SvRV(rcv)) == SVt_PVCV)

#define dMCOMMON    \
    dMY_CXT;	     \
    int needsave = 0; \
    SV *my_cmpsv;      \
    SV *my_dcmpsv;	\
    LMDB__Env envid


#define MY_PUSH_COMMON \
    if(CvValid(my_cmpsv)) {			\
	mdb_set_compare(txn, dbi, LMDB_cmp);	\
	needsave++;				\
    }						\
    if(UNLIKELY(needsave)) {			\
	SAVESPTR(MY_CXT.my_asv);		\
	SAVESPTR(MY_CXT.my_bsv);		\
    }

#ifdef dMULTICALL
/* If this perl has MULTICALL support, use it for the DATA comparer */
#if PERL_VERSION < 13 || (PERL_VERSION == 13 && PERL_SUBVERSION < 9)
#define FIXREFCOUNT if(CvDEPTH(multicall_cv) > 1) \
    SvREFCNT_inc_simple_void_NN(multicall_cv)
#else
#define FIXREFCOUNT
#endif
#if PERL_VERSION < 23 || (PERL_VERSION == 23 && PERL_SUBVERSION < 8)
#define MY_POP_MULTICALL \
    if(multicall_cv) {	\
	FIXREFCOUNT;	\
	POP_MULTICALL;	\
	newsp = newsp;	\
    }
#define MYMCINIT	multicall_cv = NULL
#else
#define MY_POP_MULTICALL    if(multicall_cop) { POP_MULTICALL; }
#if PERL_VERSION == 23 && PERL_SUBVERSION == 8
#define MYMCINIT	multicall_oldcatch = 0
#else
#define MYMCINIT
#endif
#endif

static int
LMDB_dcmp(const MDB_val *a, const MDB_val *b) {
    dTHX;
    dMY_CXT;
    sv_setpvn_mg(MY_CXT.my_asv, a->mv_data, a->mv_size);
    sv_setpvn_mg(MY_CXT.my_bsv, b->mv_data, b->mv_size);
    PL_op = MY_CXT.lmdb_dcmp_cop;
    CALLRUNOPS(aTHX);
    return SvIV(*PL_stack_sp);
}


#define dMY_MULTICALL \
    dMCOMMON;          \
    dMULTICALL;         \
    multicall_cop = NULL; \
    I32 gimme = G_SCALAR

#define MY_PUSH_MULTICALL \
    MYMCINIT;		  \
    if(CvValid(my_dcmpsv)) {			\
	PUSH_MULTICALL((CV *)SvRV(my_dcmpsv));	\
	MY_CXT.lmdb_dcmp_cop = multicall_cop;	\
	mdb_set_dupsort(txn, dbi, LMDB_dcmp);	\
	needsave++;				\
    }						\
    MY_PUSH_COMMON


#else /* NO MULTICALL support, use a slow path */

static int
LMDB_dcmp(const MDB_val *a, const MDB_val *b) {
    dTHX;
    dMY_CXT;
    dSP;
    int ret;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    sv_setpvn_mg(MY_CXT.my_asv, a->mv_data, a->mv_size);
    sv_setpvn_mg(MY_CXT.my_bsv, b->mv_data, b->mv_size);
    call_sv(SvRV(MY_DCMP), G_SCALAR|G_NOARGS);
    SPAGAIN;
    ret = POPi;
    PUTBACK;
    FREETMPS; LEAVE;
    return ret;
}

#define dMY_MULTICALL  dMCOMMON

#define MY_PUSH_MULTICALL  \
    if(CvValid(my_dcmpsv)) {			\
	mdb_set_dupsort(txn, dbi, LMDB_dcmp);	\
	needsave++;				\
    }						\
    MY_PUSH_COMMON

#define MY_POP_MULTICALL

#endif	/* dMULTICALL */

/* Error Handling */
#define DieOnErrSV  GvSV(gv_fetchpv("LMDB_File::die_on_err", 0, SVt_IV))
#define DieOnErr    SvTRUEx(DieOnErrSV)

#define LastErrSV   GvSV(gv_fetchpv("LMDB_File::last_err", 0, SVt_IV))

#define ProcError(res)   \
    if(UNLIKELY(res)) {				\
	sv_setiv(LastErrSV, res);		\
	sv_setpv(ERRSV, mdb_strerror(res));     \
	if(DieOnErr) croak(NULL);		\
	XSRETURN_IV(res);			\
    }

MODULE = LMDB_File	PACKAGE = LMDB::Env	PREFIX = mdb_env_

int
mdb_env_create(env)
	LMDB::Env   &env = NO_INIT
    POSTCALL:
	ProcError(RETVAL);
    OUTPUT:
	env

int
mdb_env_open(env, path, flags, mode)
	LMDB::Env   env
	const char *	path
	flags_t	flags
	int	mode
    PREINIT:
	dMY_CXT;
	AV* av;
	SV* eidx;
    POSTCALL:
	ProcError(RETVAL);
	eidx = sv_2mortal(newSVuv(PTR2UV(MY_CXT.envid = env)));
	av = newAV();
	av_store(av, 0, newRV_noinc((SV *)newAV())); /* Txns */
	av_store(av, 1, newRV_noinc((SV *)(MY_CXT.DCmps = newAV())));
	av_store(av, 2, newRV_noinc((SV *)(MY_CXT.Cmps = newAV())));
	av_store(av, 3, (MY_CXT.OFlags = newSVpv("",0))); /* FastMode */
	hv_store_ent(get_hv("LMDB::Env::Envs", 0), eidx, newRV_noinc((SV *)av), 0);

int
mdb_env_copy(env, path, flags = 0)
	LMDB::Env   env
	const char *	path
	unsigned flags
    CODE:
#if MDB_VERSION_PATCH < 14
	if(flags) croak("LMDB_File::copy: This version don't support flags");
	RETVAL = mdb_env_copy(env, path);
#else
	RETVAL = mdb_env_copy2(env, path, flags);
#endif
	ProcError(RETVAL);
    OUTPUT:
	RETVAL

int
mdb_env_copyfd(env, fd, flags = 0)
	LMDB::Env   env
	mdb_filehandle_t  fd
	unsigned flags
    CODE:
#if MDB_VERSION_PATCH < 14
	if(flags) croak("LMDB_File::copyfd: This version don't support flags");
	RETVAL = mdb_env_copyfd(env, fd);
#else
	RETVAL = mdb_env_copyfd2(env, fd, flags);
#endif
	ProcError(RETVAL);
    OUTPUT:
	RETVAL

HV*
mdb_env_stat(env)
	LMDB::Env   env
    PREINIT:
	MDB_stat stat;
    CODE:
	populateStat(aTHX_ &RETVAL, mdb_env_stat(env, &stat), &stat);
    OUTPUT:
	RETVAL

HV*
mdb_env_info(env)
	LMDB::Env   env
    PREINIT:
	MDB_envinfo stat;
	int res;
    CODE:
	res = mdb_env_info(env, &stat);
	ProcError(res);
	RETVAL = newHV();
	StoreUV("mapaddr", (uintptr_t)stat.me_mapaddr);
	StoreUV("mapsize", stat.me_mapsize);
	StoreUV("last_pgno", stat.me_last_pgno);
	StoreUV("last_txnid", stat.me_last_txnid);
	StoreUV("maxreaders", stat.me_maxreaders);
	StoreUV("numreaders", stat.me_numreaders);
    OUTPUT:
	RETVAL

int
mdb_env_sync(env, force=0)
	LMDB::Env   env
	int	force

void
mdb_env_close(env)
	LMDB::Env   env
    PREINIT:
	dMY_CXT;
	SV *eidx;
    POSTCALL:
	eidx = sv_2mortal(newSVuv(PTR2UV(env)));
	MY_CXT.envid = (LMDB__Env)hv_delete_ent(
	    get_hv("LMDB::Env::Envs", 0), eidx, G_DISCARD, 0
	);

int
mdb_env_set_flags(env, flags, onoff)
	LMDB::Env   env
	unsigned int	flags
	int	onoff

#define	CHANGEABLE	(MDB_NOSYNC|MDB_NOMETASYNC|MDB_MAPASYNC|MDB_NOMEMINIT)
#define	CHANGELESS	(MDB_FIXEDMAP|MDB_NOSUBDIR|MDB_RDONLY| \
	MDB_WRITEMAP|MDB_NOTLS|MDB_NOLOCK|MDB_NORDAHEAD)

int
mdb_env_get_flags(env, flags)
	LMDB::Env   env
	unsigned int &flags = NO_INIT
    POSTCALL:
	flags &= (CHANGEABLE|CHANGELESS);
    OUTPUT:
	flags

int
mdb_env_get_path(env, path)
	LMDB::Env   env
	const char * &path = NO_INIT
    OUTPUT:
	path

int
mdb_env_set_mapsize(env, size)
	LMDB::Env   env
	size_t	size
    POSTCALL:
	ProcError(RETVAL);

int
mdb_env_set_maxreaders(env, readers)
	LMDB::Env   env
	unsigned int	readers
    POSTCALL:
	ProcError(RETVAL);

int
mdb_env_get_maxreaders(env, readers)
	LMDB::Env   env
	unsigned int &readers = NO_INIT
    OUTPUT:
	readers
    POSTCALL:
	ProcError(RETVAL);

int
mdb_env_set_maxdbs(env, dbs)
	LMDB::Env   env
	int	dbs
    POSTCALL:
	ProcError(RETVAL);

int
mdb_env_get_maxkeysize(env)
	LMDB::Env   env

UV
mdb_env_id(env)
	LMDB::Env   env
    CODE:
	RETVAL = PTR2UV(env);
    OUTPUT:
	RETVAL

void
_clone()
    CODE:
    MY_CXT_CLONE;
    MY_CXT.envid = NULL;
    MY_CXT.curdb = 0;
    MY_CXT.my_asv = get_sv("::a", GV_ADDMULTI);
    MY_CXT.my_bsv = get_sv("::b", GV_ADDMULTI);

BOOT:
    MY_CXT_INIT;
    MY_CXT.my_asv = get_sv("::a", GV_ADDMULTI);
    MY_CXT.my_bsv = get_sv("::b", GV_ADDMULTI);


MODULE = LMDB_File	PACKAGE = LMDB::Txn	PREFIX = mdb_txn

int
mdb_txn_begin(env, parent, flags, txn)
	LMDB::Env   env
	TxnOrNull   parent
	flags_t	    flags
	LMDB::Txn   &txn = NO_INIT
    POSTCALL:
	ProcError(RETVAL);
    OUTPUT:
	txn

UV
mdb_txn_env(txn)
	LMDB::Txn   txn
    CODE:
	RETVAL= PTR2UV(mdb_txn_env(txn));
    OUTPUT:
	RETVAL

int
mdb_txn_commit(txn)
	LMDB::Txn   txn
    POSTCALL:
	ProcError(RETVAL);

void
mdb_txn_abort(txn)
	LMDB::Txn   txn

void
mdb_txn_reset(txn)
	LMDB::Txn   txn

int
mdb_txn_renew(txn)
	LMDB::Txn   txn
    POSTCALL:
	ProcError(RETVAL);

UV
mdb_txn_id(txn)
	LMDB::Txn   txn
    CODE:
	RETVAL = PTR2UV(txn);
    OUTPUT:
	RETVAL

MODULE = LMDB_File	PACKAGE = LMDB::Txn	PREFIX = mdb_txn_

#if MDB_VERSION_FULL > MDB_VERINT(0,9,14)
size_t
mdb_txn_id(txn)
	LMDB::Txn   txn

#endif

MODULE = LMDB_File	PACKAGE = LMDB::Txn	PREFIX = mdb

int
mdb_dbi_open(txn, name, flags, dbi)
	LMDB::Txn   txn
	const char * name = SvOK($arg) ? (const char *)SvPV_nolen($arg) : NULL;
	flags_t	flags
	LMDB	&dbi = NO_INIT
    PREINIT:
	dMY_CXT;
    POSTCALL:
	ProcError(RETVAL);
	mdb_dbi_flags(txn, dbi, &MY_CXT.cflags);
	MY_CXT.cflags |= LMDB_OFLAGS;
	MY_CXT.curdb = dbi;
    OUTPUT:
	dbi

MODULE = LMDB_File	PACKAGE = LMDB::Cursor	PREFIX = mdb_cursor_

int
mdb_cursor_open(txn, dbi, cursor)
	LMDB::Txn   txn
	LMDB	dbi
	LMDB::Cursor	&cursor = NO_INIT
    OUTPUT:
	cursor

void
mdb_cursor_close(cursor)
	LMDB::Cursor	cursor

int
mdb_cursor_count(cursor, count)
	LMDB::Cursor	cursor
	UV  &count = NO_INIT
    OUTPUT:
	count

int
mdb_cursor_dbi(cursor)
	LMDB::Cursor	cursor

int
mdb_cursor_renew(txn, cursor)
	LMDB::Txn   txn
	LMDB::Cursor	cursor

UV
mdb_cursor_txn(cursor)
	LMDB::Cursor	cursor
    CODE:
	RETVAL = PTR2UV(mdb_cursor_txn(cursor));
    OUTPUT:
	RETVAL

MODULE = LMDB_File	PACKAGE = LMDB::Cursor	PREFIX = mdb_cursor

int
mdb_cursor_get(cursor, key, data, op = MDB_NEXT)
    PREINIT:
	dMY_MULTICALL;
	dCURSOR;
    INPUT:
	LMDB::Cursor	cursor +PREC_FLGS($var);
	DBKC	&key
	DBD	&data
	MDB_cursor_op	op
    INIT:
	MY_PUSH_MULTICALL;
    POSTCALL:
	MY_POP_MULTICALL;
	ProcError(RETVAL);
    OUTPUT:
	key
	data

int
mdb_cursor_put(cursor, key, data, flags = 0, ...)
    PREINIT:
	dMY_MULTICALL;
	dCURSOR;
    INPUT:
	LMDB::Cursor	cursor +PREC_FLGS($var);
	DBKC	&key
	DBD	&data = NO_INIT
	flags_t	flags
    INIT:
	if(flags & MDB_RESERVE) {
	    size_t res_size;
	    size_t max_size = F_ISSET(MY_CXT.cflags, MDB_DUPSORT)
		? mdb_env_get_maxkeysize(envid)
		: 0xffffffff;
	    if(items != 5)
		croak("%s: MDB_RESERVE needs a length argument (1 .. %zu)",
		      "LMDB_File::_put", max_size);
	    res_size = SvUV(ST(5));
	    if(res_size == 0)
		croak("%s: MDB_RESERVE length must be > 0",
		      "LMDB_File::_put");
	    if(ISDBDINT && res_size != sizeof(MyInt))
		croak("%s: MDB_RESERVE with MDB_INTEGERDUP length should be %zu",
		      "LMDB_File::_put", sizeof(MyInt));
	    if(res_size > max_size)
		croak("%s: MDB_RESERVE length should be <= %zu", "LMDB_File::_put", max_size);
	    data.mv_size = res_size;
	    data.mv_data = NULL;
	} else {
	    /* Normal initialization */
	    Sv2DBD(ST(2), data);
	}
	MY_PUSH_MULTICALL;
    POSTCALL:
	MY_POP_MULTICALL;
	if((flags & MDB_NOOVERWRITE) && RETVAL == MDB_KEYEXIST) {
	    sv_setstatic(aTHX_ aMY_CXT_ ST(2), &data, 0);
	    SvSETMAGIC(ST(2));
	}
	ProcError(RETVAL);
	if(flags & MDB_RESERVE) {
	    sv_setstatic(aTHX_ aMY_CXT_ ST(2), &data, 1);
	    SvSETMAGIC(ST(2));
	}

int
mdb_cursor_del(cursor, flags = 0)
    PREINIT:
	dMY_MULTICALL;
	dCURSOR;
    INPUT:
	LMDB::Cursor	cursor +PREC_FLGS($var);
	flags_t		flags
    INIT:
	MY_PUSH_MULTICALL;
    POSTCALL:
	MY_POP_MULTICALL;
	ProcError(RETVAL);

MODULE = LMDB_File		PACKAGE = LMDB_File	    PREFIX = mdb

#ifdef __GNUC__
#pragma GCC diagnostic ignored "-Wmaybe-uninitialized"
#endif

INCLUDE: const-xs.inc

#ifdef __GNUC__
#pragma GCC diagnostic warning "-Wmaybe-uninitialized"
#endif

HV*
mdb_stat(txn, dbi)
	LMDB::Txn   txn
	LMDB	dbi
    PREINIT:
	MDB_stat    stat;
    CODE:
	populateStat(aTHX_ &RETVAL, mdb_stat(txn, dbi, &stat), &stat);
    OUTPUT:
	RETVAL

int
mdb_dbi_flags(txn, dbi, flags)
	LMDB::Txn   txn
	LMDB	dbi
	unsigned int &flags = NO_INIT
    POSTCALL:
	ProcError(RETVAL);
    OUTPUT:
	RETVAL
	flags

void
mdb_dbi_close(env, dbi)
	LMDB::Env   env
	LMDB	dbi

int
mdb_drop(txn, dbi, del)
	LMDB::Txn   txn
	LMDB	dbi
	int	del
    POSTCALL:
	ProcError(RETVAL);

=pod
int
mdb_set_compare(txn, dbi, cmp)
	LMDB::Txn   txn
	LMDB	dbi
	MDB_cmp_func *	cmp

int
mdb_set_dupsort(txn, dbi, cmp)
	LMDB::Txn   txn
	LMDB	dbi
	MDB_cmp_func *	cmp

int
mdb_set_relfunc(txn, dbi, rel)
	LMDB::Txn   txn
	LMDB	dbi
	MDB_rel_func *	rel

int
mdb_set_relctx(txn, dbi, ctx)
	LMDB::Txn   txn
	LMDB	dbi
	void *	ctx
=cut

int
mdb_get(txn, dbi, key, data)
    PREINIT:
	dMY_MULTICALL;
    INPUT:
	LMDB::Txn   txn +CHECK_ALLCUR;
	LMDB	dbi
	DBK	&key
	DBD	&data = NO_INIT
    INIT:
	MY_PUSH_MULTICALL;
    POSTCALL:
	MY_POP_MULTICALL;
	ProcError(RETVAL);
    OUTPUT:
	data

int
mdb_put(txn, dbi, key, data, flags = 0, ...)
    PREINIT:
	dMY_MULTICALL;
    INPUT:
	LMDB::Txn   txn +CHECK_ALLCUR;
	LMDB	 dbi
	DBK	&key
	DBD	&data = NO_INIT
	flags_t	flags
    INIT:
	if(flags & MDB_RESERVE) {
	    size_t res_size;
	    size_t max_size = F_ISSET(MY_CXT.cflags, MDB_DUPSORT)
		? mdb_env_get_maxkeysize(envid)
		: 0xffffffff;
	    if(items != 6)
		croak("%s: MDB_RESERVE needs a length argument (1 .. %zu)",
		      "LMDB_File::_put", max_size);
	    res_size = SvUV(ST(5));
	    if(res_size == 0)
		croak("%s: MDB_RESERVE length must be > 0",
		      "LMDB_File::_put");
	    if(ISDBDINT && res_size != sizeof(MyInt))
		croak("%s: MDB_RESERVE with MDB_INTEGERDUP length should be %zu",
		      "LMDB_File::_put", sizeof(MyInt));
	    if(res_size > max_size)
		croak("%s: MDB_RESERVE length should be <= %zu",
		      "LMDB_File::_put", max_size);
	    data.mv_size = res_size;
	    data.mv_data = NULL;
	} else {
	    /* Normal initialization */
	    Sv2DBD(ST(3), data);
	}
	MY_PUSH_MULTICALL;
    POSTCALL:
	MY_POP_MULTICALL;
	if((flags & MDB_NOOVERWRITE) && RETVAL == MDB_KEYEXIST) {
	    sv_setstatic(aTHX_ aMY_CXT_ ST(3), &data, 0);
	    SvSETMAGIC(ST(3));
	}
	ProcError(RETVAL);
	if(flags & MDB_RESERVE) {
	    sv_setstatic(aTHX_ aMY_CXT_ ST(3), &data, 1);
	    SvSETMAGIC(ST(3));
	}

int
mdb_del(txn, dbi, key, data)
    PREINIT:
	dMY_MULTICALL;
    INPUT:
	LMDB::Txn   txn +CHECK_ALLCUR;
	LMDB	dbi
	DBK	&key
	DBD	&data
    INIT:
	MY_PUSH_MULTICALL;
    CODE:
	RETVAL = mdb_del(txn, dbi, &key, (SvOK(ST(3)) ? &data : NULL));
	MY_POP_MULTICALL;
	ProcError(RETVAL);
    OUTPUT:
	RETVAL

int
mdb_cmp(txn, dbi, a, b)
    PREINIT:
	dMY_MULTICALL;
    INPUT:
	LMDB::Txn   txn +CHECK_ALLCUR;
	LMDB	dbi
	DBD	&a
	DBD	&b
    INIT:
	MY_PUSH_MULTICALL;
    POSTCALL:
	MY_POP_MULTICALL;

int
mdb_dcmp(txn, dbi, a, b)
    PREINIT:
	dMY_MULTICALL;
    INPUT:
	LMDB::Txn   txn +CHECK_ALLCUR;
	LMDB	dbi
	DBD	&a
	DBD	&b
    INIT:
	MY_PUSH_MULTICALL;
    POSTCALL:
	MY_POP_MULTICALL;

MODULE = LMDB_File		PACKAGE = LMDB_File	    PREFIX = mdb_

=pod
int
mdb_reader_list(env, func, ctx)
	LMDB::Env   env
	MDB_msg_func *	func
	void *	ctx
=cut

void
_resetcurdbi()
    CODE:
	dMY_CXT;
	MY_CXT.curdb = 0;

int
mdb_reader_check(env, dead)
	LMDB::Env   env
	int	&dead
    OUTPUT:
	dead

char *
mdb_strerror(err)
	int	err

char *
mdb_version(major, minor, patch)
	int	&major = NO_INIT
	int	&minor = NO_INIT
	int	&patch = NO_INIT
    OUTPUT:
	major
	minor
	patch
