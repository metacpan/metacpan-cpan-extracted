#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pv_flags
#define NEED_vnewSVpvf
#define NEED_warner
#include "ppport.h"

#include "const-c.inc"

/*#define DEBUG*/
#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
  PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
  (PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#ifndef UNLIKELY
#  define UNLIKELY(x) (x)
#endif
#ifndef LIKELY
#  define LIKELY(x) (x)
#endif

#ifndef OpSIBLING
#define OpSIBLING(o) o->op_sibling
#endif

#ifndef OpMORESIB_set
#define OpMORESIB_set(o, sib) (o->op_sibling = sib)
#endif

#define OPT_MY 1
#define OPT_ALIAS 2

#ifdef DEBUG
static void analyse_op_tree(pTHX_ OP *o, int depth){
    for(int i=0; i<depth; ++i)
        printf("  ");
    printf("%s=%p op_next=%p op_flags=%X op_private=%X\n", OP_NAME(o), (void*)o, (void*)o->op_next, o->op_flags, o->op_private);
    if( o->op_flags & OPf_KIDS )
        for(OP *kid=cUNOPo->op_first; kid; kid=OpSIBLING(kid))
            analyse_op_tree(aTHX_ kid, depth+1);
}
#endif

static int sv_alias_get(pTHX_ SV* sv, MAGIC *mg){
#ifdef DEBUG
    puts("sv_alias_get");
#endif
    sv_setsv_flags(sv, mg->mg_obj, SV_GMAGIC);
    return 0;
}
static int sv_alias_set(pTHX_ SV* sv, MAGIC *mg){
#ifdef DEBUG
    puts("sv_alias_set");
#endif
    sv_setsv_flags(mg->mg_obj, sv, 0);
    SvSETMAGIC(mg->mg_obj);
    return 0;
}
static MGVTBL sv_alias_vtbl = {
    sv_alias_get,
    sv_alias_set,
    (U32 (*)(pTHX_ SV*, MAGIC*)) NULL,
    (int (*)(pTHX_ SV*, MAGIC*)) NULL,
    (int (*)(pTHX_ SV*, MAGIC*)) NULL
};

static void prepare_anonlist_node(pTHX_ OP * parent, OP * o, U32 opt);
static void prepare_anonhash_node(pTHX_ OP * parent, OP * o, U32 opt);

static inline void my_sv_set(pTHX_ SV ** dst, SV ** src, U32 is_alias){
    if( src ){
        if( is_alias ){
            sv_magicext(*dst, *src, PERL_MAGIC_ext, &sv_alias_vtbl, NULL, 0);
        }
        else{
            SvGETMAGIC(*src);
            SvSetMagicSV_nosteal(*dst, *src);
        }
    }
    else{
        if( is_alias ){
            warn("take alias on a non-exist magic element");
            SvSetSV(*dst, &PL_sv_undef);
        }
        else{
            SvSetMagicSV(*dst, &PL_sv_undef);
        }
    }
}

static inline int anonlist_set_common(pTHX_ SV * sv, MAGIC * mg, U32 opt){
    SV ** list_holder = (SV**)(mg->mg_ptr + sizeof(I32*));
    I32 * const_index = *(I32**)mg->mg_ptr;
    I32 nitems = (mg->mg_len - sizeof(I32*)) / sizeof(SV*);

#ifdef DEBUG
    printf("anonlist_set opt=%u, nitems=%d\nconst_index =", (unsigned int)opt, (int)nitems);
    for(I32 i=0; const_index[i]<nitems; ++i)
        printf(" %d", const_index[i]);
    printf(" %d\n", nitems);
#endif

    if( !SvROK(sv) ){
        warn("assign non-ref value but SvTYPE=%d to a list pattern", SvTYPE(sv));
        return 0;
    }

    SV * src = SvRV(sv);
    if( SvTYPE(src)!=SVt_PVAV ){
        warn("assign non array ref value but a ref of SvTYPE=%d to a list pattern", SvTYPE(SvRV(sv)));
        return 0;
    }

    I32 key = 0;
    for(I32 i=0; i<nitems; ++i, ++list_holder){
        if( i==*const_index ){
            if( SvOK(*list_holder) )
                key = (I32) SvIV(*list_holder);
            else
                ++key;
            ++const_index;
        }
        else{
            switch( SvTYPE(*list_holder) ){
                case SVt_PVAV:
                    {
                        AV *dst = (AV*)(*list_holder);
                        int magic = SvMAGICAL(dst) != 0;
                        I32 last_key = key < 0 ? -1 : AvFILL((AV*)src);

                        ENTER;
                        SAVEFREESV(SvREFCNT_inc_simple_NN((SV*)dst));
                        av_clear(dst);
                        av_extend(dst, last_key+1-key);
                        I32 j = 0;
                        while( key <= last_key ){
                            SV ** ptr_val = av_fetch((AV*)src, key, 0);
                            SV * new_sv = newSV(0);
                            my_sv_set(aTHX_ &new_sv, ptr_val, i != -*const_index-1 && opt & OPT_ALIAS);
                            SV ** didstore = av_store(dst, j, new_sv);
                            if( magic ){
                                if( !didstore )
                                    sv_2mortal(new_sv);
                                SvSETMAGIC(new_sv);
                            }
                            ++j;
                            ++key;
                        }
#if PERL_VERSION_GE(5,14,0)
                        if( PL_delaymagic & DM_ARRAY_ISA )
                            SvSETMAGIC(*list_holder);
#endif
                        LEAVE;
                    }
                    break;
                case SVt_PVHV:
                    {
                        HV *dst = (HV*)(*list_holder);
                        int magic = SvMAGICAL(dst) != 0;
                        I32 last_key = key < 0 ? -1 : AvFILL((AV*)src);

                        if( key <= last_key && ((last_key - key) & 1) == 0 )
                            Perl_warner(aTHX_ packWARN(WARN_MISC), "Odd number of elements in hash assignment");

                        ENTER;
                        SAVEFREESV(SvREFCNT_inc_simple_NN((SV*)dst));
                        hv_clear(dst);
                        while( key <= last_key ){
                            SV ** ptr_key = av_fetch((AV*)src, key, 0);
                            SV ** ptr_val = key < last_key ? av_fetch((AV*)src, key+1, 0) : NULL;
                            SV * new_key;
                            if( ptr_key )
                                if( SvGMAGICAL(*ptr_key) )
                                    new_key = sv_mortalcopy(*ptr_key);
                                else
                                    new_key = *ptr_key;
                            else
                                new_key = newSV(0);
                            SV * new_val = newSV(0);
                            my_sv_set(aTHX_ &new_val, ptr_val, i != -*const_index-1 && opt & OPT_ALIAS);
                            HE * didstore = hv_store_ent(dst, new_key, new_val, 0);
                            if( magic ){
                                if( !didstore )
                                    sv_2mortal(new_val);
                                SvSETMAGIC(new_val);
                            }
                            key += 2;
                        }
                        LEAVE;
                    }
                    break;
                default:
                    {
                        SV ** ptr_val = av_fetch((AV*)src, key, 0);
                        my_sv_set(aTHX_ list_holder, ptr_val, (i != -*const_index-1 && opt & OPT_ALIAS));
                    }
            }
            if( i == -*const_index-1 )
                ++const_index;
            ++key;
        }
    }
    return 0;
}
static int anonlist_set(pTHX_ SV * sv, MAGIC * mg){
    return anonlist_set_common(aTHX_ sv, mg, 0);
}
static int anonlist_alias_set(pTHX_ SV * sv, MAGIC * mg){
    return anonlist_set_common(aTHX_ sv, mg, OPT_ALIAS);
}

static inline int anonhash_set_common(pTHX_ SV * sv, MAGIC * mg, U32 opt){
    SV * src;
    char *key = "";
    STRLEN keylen = 0;
    SV ** list_holder = (SV**)(mg->mg_ptr + sizeof(I32*));
    I32 * const_index = *(I32**)mg->mg_ptr;
    I32 nitems = (mg->mg_len - sizeof(I32*)) / sizeof(SV*);

#ifdef DEBUG
    printf("anonhash_set opt=%u\n", (unsigned int)opt);
#endif

    if( !SvROK(sv) ){
        warn("assign non-ref value to a hash pattern");
        return 0;
    }

    src = SvRV(sv);
    switch( SvTYPE(src) ){
        case SVt_PVHV:
        case SVt_PVAV:
            break;
        default:
            warn("assign non hash ref value but a ref to a SvTYPE=%d to a hash pattern", SvTYPE(src));
            return 0;
    }

    for(I32 i=0; i<nitems; ++i, ++list_holder){
        if( i==*const_index ){
            key = SvPV(*list_holder, keylen);
#ifdef DEBUG
            printf("got key: %s\n", key);
#endif
            ++const_index;
        }
        else{
            if( SvTYPE(src)==SVt_PVHV ){
                SV ** ptr_val = hv_fetch((HV*)src, key, keylen, 0);
#ifdef DEBUG
                if( ptr_val )
                    printf("got val: %s\n", SvPV_nolen(*ptr_val));
                else
                    printf("got val: NULL\n");
#endif
                my_sv_set(aTHX_ list_holder, ptr_val, (i != -*const_index-1 && opt & OPT_ALIAS));
            }
            else{ /* SvTYPE(src)==SVt_PVAV */
                I32 j = AvFILL((AV*)src);
                if( j>=0 )
                    if( j & 1 )
                        --j;
                    else
                        warn("assign an array with odd number of elements to a hash pattern");

                while( j>=0 ){
                    SV ** target_key_ptr = av_fetch((AV*)src, j, 0);
                    int found;
                    if( target_key_ptr ){
                        STRLEN target_keylen;
                        char * target_key = SvPV(*target_key_ptr, target_keylen);
                        found = (keylen == target_keylen && 0 == memcmp(key, target_key, keylen));
                    }
                    else{
                        found = (keylen == 0);
                    }

                    if( found )
                        break;
                    j -= 2;
                }

                U32 is_alias = (i != -*const_index-1 && opt & OPT_ALIAS);
                if( j>=0 ){ /* found */
                    SV ** target_val_ptr = av_fetch((AV*)src, j+1, (is_alias ? 1 : 0));
                    my_sv_set(aTHX_ list_holder, target_val_ptr, is_alias);
                }
                else{ /* not found */
                    my_sv_set(aTHX_ list_holder, NULL, is_alias);
                }
            }
            if( i == -*const_index-1 )
                ++const_index;
        }
    }
    return 0;
}
static int anonhash_alias_set(pTHX_ SV * sv, MAGIC * mg){
    return anonhash_set_common(aTHX_ sv, mg, OPT_ALIAS);
}
static int anonhash_set(pTHX_ SV * sv, MAGIC * mg){
    return anonhash_set_common(aTHX_ sv, mg, 0);
}

static inline void init_set_vtbl(MGVTBL *vtbl, int(*setter)(pTHX_ SV*, MAGIC*)){
    vtbl->svt_get = NULL;
    vtbl->svt_set = setter;
    vtbl->svt_len = NULL;
    vtbl->svt_clear = NULL;
    vtbl->svt_free = NULL;
}
static MGVTBL anonlist_vtbl, anonlist_alias_vtbl, anonhash_vtbl, anonhash_alias_vtbl;

static inline OP * my_pp_anonlisthash_common(pTHX_ MGVTBL *vtbl){
    dVAR; dSP; dMARK;
    int nitems = SP-MARK;
    I32 holder_size = nitems * sizeof(SV*) + sizeof(I32*);
    char * list_holder = alloca(holder_size);

    Copy(MARK+1, list_holder + sizeof(I32*), nitems, SV*);
    *(I32**)list_holder = (I32*)SvPVX(cSVOPx_sv(OpSIBLING(PL_op)));

    SP = MARK+1;

    SV * ret = SETs(sv_2mortal(newSV(0)));
    SvUPGRADE(ret, SVt_PVMG);
    sv_magicext(ret, ret, PERL_MAGIC_ext, vtbl, list_holder, holder_size);

    RETURN;
}
static OP * my_pp_anonlist(pTHX){
    return my_pp_anonlisthash_common(aTHX_ &anonlist_vtbl);
}
static OP * my_pp_anonlist_alias(pTHX){
    return my_pp_anonlisthash_common(aTHX_ &anonlist_alias_vtbl);
}
static OP * my_pp_anonhash(pTHX){
    return my_pp_anonlisthash_common(aTHX_ &anonhash_vtbl);
}
static OP * my_pp_anonhash_alias(pTHX){
    return my_pp_anonlisthash_common(aTHX_ &anonhash_alias_vtbl);
}

#ifndef PadlistARRAY
typedef AV PADNAMELIST;
typedef SV PADNAME;
#endif

#ifndef padnamelist_fetch
#  define padnamelist_fetch(a,b) *av_fetch(a,b,FALSE)
#endif

/* Taken from pp_ctl.c in 5.8.8 */
/* Thanks to Daniel Silva (dsilva @ github) */
static CV*
THX_find_runcv(pTHX_ U32 *db_seqp)
{
    PERL_SI      *si;

    if (db_seqp)
        *db_seqp = PL_curcop->cop_seq;
    for (si = PL_curstackinfo; si; si = si->si_prev) {
        I32 ix;
        for (ix = si->si_cxix; ix >= 0; ix--) {
            const PERL_CONTEXT *cx = &(si->si_cxstack[ix]);
            if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
                CV * const cv = cx->blk_sub.cv;
                /* skip DB:: code */
                if (db_seqp && PL_debstash && CvSTASH(cv) == PL_debstash) {
                    *db_seqp = cx->blk_oldcop->cop_seq;
                    continue;
                }
                return cv;
            }
            else if (CxTYPE(cx) == CXt_EVAL && !CxTRYBLOCK(cx))
                return PL_compcv;
        }
    }
    return PL_main_cv;
}
#ifndef find_runcv
#  define find_runcv(d) THX_find_runcv(aTHX_ d)
#endif

static OP* my_pp_fetch_next_padname(pTHX){
#ifdef DEBUG
    puts("my_pp_fetch_next_padname");
#endif

    CV *curr_cv = find_runcv(NULL);
    if( curr_cv && CvPADLIST(curr_cv) ){
        PADNAMELIST* padlist_av =
#ifdef PadlistARRAY
            PadlistNAMES(CvPADLIST(curr_cv));
#else
            (AV*)(*av_fetch((AV*)CvPADLIST(curr_cv), 0, FALSE));
#endif
        PADNAME* padname_sv = padnamelist_fetch(
            padlist_av,
            OpSIBLING(PL_op)->op_targ
        );

        STRLEN padnamelen;
        char * padname;
#ifdef PadlistARRAY
        padnamelen = PadnameLEN(padname_sv);
        padname = PadnamePV(padname_sv);
#else
        padname = SvPV(padname_sv, padnamelen);
#endif

        if( padnamelen>=3 && padname[0]=='$' && padname[1]=='#' ){
#ifdef DEBUG
            printf("got name: %s\n", padname+2);
#endif
            sv_setpvn(cSVOP_sv, padname+2, padnamelen-2);
        }
        else{
#ifdef DEBUG
            printf("got name: %s\n", padname+1);
#endif
            sv_setpvn(cSVOP_sv, padname+1, padnamelen-1);
        }
    }

    PL_op->op_ppaddr = PL_ppaddr[OP_CONST];

#ifdef DEBUG
    puts("my_pp_fetch_next_padname end");
#endif

    return PL_ppaddr[OP_CONST](aTHXR);
}

static void prepare_anonlisthash_list1(pTHX_ OP *o, U32 opt, UV *const_count, UV *pattern_count, int *last_is_const_p){
    for(OP *kid=cLISTOPo->op_first; kid; kid=OpSIBLING(kid))
        switch( kid->op_type ){
            case OP_PUSHMARK:
                break;
            case OP_NULL:
            case OP_LIST:
                if( kid->op_flags & OPf_KIDS )
                    prepare_anonlisthash_list1(aTHX_ kid, opt, const_count, pattern_count, last_is_const_p);
                break;
            case OP_ANONLIST:
                ++*pattern_count;
                prepare_anonlist_node(aTHX_ o, kid, opt);
                kid = OpSIBLING(kid); /* skip pattern structure op node */
                if( last_is_const_p )
                    *last_is_const_p = 0;
                break;
            case OP_ANONHASH:
                ++*pattern_count;
                prepare_anonhash_node(aTHX_ o, kid, opt);
                kid = OpSIBLING(kid); /* skip pattern structure op node */
                if( last_is_const_p )
                    *last_is_const_p = 0;
                break;
            case OP_CONST:
            case OP_UNDEF:
                ++*const_count;
                if( last_is_const_p )
                    *last_is_const_p = 1;
                break;
            case OP_PADAV:
            case OP_PADHV:
            case OP_RV2AV:
            case OP_RV2HV:
                kid->op_flags |= OPf_REF;
                /* fall through */
            case OP_PADSV:
            case OP_RV2SV:
                if( last_is_const_p ){
                    if( *last_is_const_p )
                        *last_is_const_p = 0;
                    else
                        ++*const_count;
                }
                break;
            default:
                croak("invalid des pattern (can't contain %s)", OP_NAME(kid));
        }
}
static void prepare_anonlisthash_list2(pTHX_ OP *o, U32 opt, I32 *const_index_buffer, I32 *p, I32 *q, int *last_is_const_p){
    OP *kid0 = cLISTOPo->op_first;
    for(OP *kid=OpSIBLING(kid0); kid; kid0=kid, kid=OpSIBLING(kid)){
        if( (kid->op_flags & OPf_KIDS) && (kid->op_type == OP_LIST || kid->op_type == OP_NULL) ){
            prepare_anonlisthash_list2(aTHX_ kid, opt, const_index_buffer, p, q, last_is_const_p);
            continue;
        }
        if( kid->op_type == OP_CONST || kid->op_type == OP_UNDEF ){
            const_index_buffer[(*p)++] = *q;
            if( last_is_const_p )
                *last_is_const_p = 1;
        }
        else if( kid->op_type == OP_ANONLIST || kid->op_type == OP_ANONHASH ){
            const_index_buffer[(*p)++] = -*q-1;
            kid = OpSIBLING(kid);
            if( last_is_const_p )
                *last_is_const_p = 0;
        }
        else{
            if( last_is_const_p ){
                if( *last_is_const_p ){
                    *last_is_const_p = 0;
                }
                else{
#ifdef DEBUG
                    printf("put const index\n");
#endif
                    const_index_buffer[(*p)++] = (*q)++;
                    switch( kid->op_type ){
                        case OP_PADSV:
                        case OP_PADAV:
                        case OP_PADHV: {
                            OP * keyname_op = newSVOP(OP_CUSTOM, 0, newSV(0));
                            keyname_op->op_ppaddr = my_pp_fetch_next_padname;
#ifdef op_sibling_splice
                            op_sibling_splice(o, kid0, 0, keyname_op);
#else
                            OpMORESIB_set(kid0, keyname_op);
                            OpMORESIB_set(keyname_op, kid);
#endif
                            break;
                        }
                        case OP_RV2SV:
                        case OP_RV2AV:
                        case OP_RV2HV:
                            if( kid->op_flags & OPf_KIDS ){
                                OP * gvop = kUNOP->op_first;
                                if( gvop->op_type == OP_GVSV || gvop->op_type == OP_GV ){
#ifdef GvNAME_HEK
                                    HEK * gv_name_hek = GvNAME_HEK(cGVOPx_gv(gvop));
                                    SV * keyname_sv = newSVpvn(HEK_KEY(gv_name_hek), HEK_LEN(gv_name_hek));
#else
                                    GV * gv = cGVOPx_gv(gvop);
                                    SV * keyname_sv = newSVpvn(GvNAME(gv), GvNAMELEN(gv));
#endif
                                    OP * keyname_op = newSVOP(OP_CONST, 0, keyname_sv);
#ifdef op_sibling_splice
                                    op_sibling_splice(o, kid0, 0,
                                                      keyname_op);
#else
                                    OpMORESIB_set(kid0, keyname_op);
                                    OpMORESIB_set(keyname_op, kid);
#endif
                                }
                            }
                            break;
                    }
                }
            }
        }
        ++*q;
    }
}
static void prepare_anonlisthash_node(pTHX_ OP *parent, OP *o, U32 opt,
                                            int is_hash){
    UV const_count = 0;
    UV pattern_count = 0;
    PERL_UNUSED_ARG(parent);

    if( is_hash ){
        int last_is_const = 0;
        prepare_anonlisthash_list1(aTHX_ o, opt, &const_count, &pattern_count, &last_is_const);
    }
    else{
        prepare_anonlisthash_list1(aTHX_ o, opt, &const_count, &pattern_count, NULL);
    }

#ifdef DEBUG
    printf("const_count=%u, pattern_count=%u\n", (unsigned int)const_count, (unsigned int)pattern_count);
#endif

    I32 p = 0, q = 0;
    I32 buffer_len = (const_count+pattern_count+1) * sizeof(I32);

    SV *buffer_sv = newSV(buffer_len+1);
    *(SvPVX(buffer_sv)+buffer_len) = '\0';

    I32 * const_index_buffer = (I32*)SvPVX(buffer_sv);

    if( is_hash ){
        int last_is_const = 0;
        prepare_anonlisthash_list2(aTHX_ o, opt, const_index_buffer, &p, &q, &last_is_const);
    }
    else{
        prepare_anonlisthash_list2(aTHX_ o, opt, const_index_buffer, &p, &q, NULL);
    }
    const_index_buffer[p] = q;

    #ifdef DEBUG
    printf("const_index:");
    for(I32 i=0; i<=p; ++i)
        printf(" %d", const_index_buffer[i]);
    puts("");
    #endif

    OP *buffer_op = newSVOP(OP_CONST, 0, buffer_sv);
    buffer_op->op_type = OP_NULL;
    buffer_op->op_targ = OP_CONST;
#ifdef op_sibling_splice
    op_sibling_splice(parent, o, 0, buffer_op);
#else
    OpMORESIB_set(buffer_op, OpSIBLING(o));
    OpMORESIB_set(o, buffer_op);
#endif
}

static void prepare_anonlist_node(pTHX_ OP * parent, OP * o, U32 opt){
#ifdef DEBUG
    printf("prepare anonlist node\n");
#endif
    prepare_anonlisthash_node(aTHX_ parent, o, opt, 0);
    if( opt & OPT_ALIAS )
        o->op_ppaddr = my_pp_anonlist_alias;
    else
        o->op_ppaddr = my_pp_anonlist;
}

static void prepare_anonhash_node(pTHX_ OP * parent, OP * o, U32 opt){
#ifdef DEBUG
    printf("prepare anonhash node\n");
#endif
    prepare_anonlisthash_node(aTHX_ parent, o, opt, 1);
    if( opt & OPT_ALIAS )
        o->op_ppaddr = my_pp_anonhash_alias;
    else
        o->op_ppaddr = my_pp_anonhash;
}

static unsigned int traverse_args(pTHX_ U32 opt, unsigned int found_index,
                                        OP * parent, OP * o){
    if( o->op_type == OP_NULL ){
        if( o->op_flags & OPf_KIDS )
            for(OP *kid=cUNOPo->op_first; kid; kid=OpSIBLING(kid))
                found_index = traverse_args(aTHX_ opt, found_index, o,kid);
        return found_index;
    }

    /* use the second kid (the first arg) */
    if( found_index==1 ){
        switch( o->op_type ){
           case OP_ANONLIST:
                prepare_anonlist_node(aTHX_ parent, o, opt);
                break;
           case OP_ANONHASH:
                prepare_anonhash_node(aTHX_ parent, o, opt);
                break;
           default:
                croak("des arg must be exactly an anonymous list or anonymous hash");
        }
    }
    else if( found_index==4 ){
        croak("des arg must be exactly an anonymous list or anonymous hash");
    }

    return found_index+1;
}

static OP* my_pp_entersub(pTHX){
    dVAR;
    dMARK; /* drop the first pushmark */
    dSP;
    POPs; /* drop the sub name */
#ifdef DEBUG
    printf("my_pp_entersub\n");
#endif
    RETURN;
}

static OP* des_check(pTHX_ OP* o, GV *namegv, SV *ckobj){
#ifdef DEBUG
    analyse_op_tree(aTHX_ o, 0);
#endif
    if( o->op_flags & OPf_KIDS ){
        unsigned int found_index = 0;
        for(OP *kid=cUNOPo->op_first; kid; kid=OpSIBLING(kid))
            found_index = traverse_args(aTHX_ 0, found_index, o, kid);
        o->op_ppaddr = my_pp_entersub;
    }
    return o;
}

static OP* des_alias_check(pTHX_ OP* o, GV *namegv, SV *ckobj){
#ifdef DEBUG
    analyse_op_tree(aTHX_ o, 0);
#endif
    if( o->op_flags & OPf_KIDS ){
        unsigned int found_index = 0;
        for(OP *kid=cUNOPo->op_first; kid; kid=OpSIBLING(kid))
            found_index = traverse_args(aTHX_ OPT_ALIAS,found_index,o,kid);
        o->op_ppaddr = my_pp_entersub;
    }
    return o;
}

#if !PERL_VERSION_GE(5,14,0)
static CV* my_des_cvs[2];
static OP* (*orig_entersub_check)(pTHX_ OP*);
static OP* my_entersub_check(pTHX_ OP* o){
    CV *cv = NULL;
    OP *cvop = OpSIBLING(((OpSIBLING(cUNOPo->op_first)) ? cUNOPo : ((UNOP*)cUNOPo->op_first))->op_first);
    while( OpSIBLING(cvop) )
        cvop = OpSIBLING(cvop);
    if( cvop->op_type == OP_RV2CV && !(o->op_private & OPpENTERSUB_AMPER) ){
        SVOP *tmpop = (SVOP*)((UNOP*)cvop)->op_first;
        switch (tmpop->op_type) {
            case OP_GV: {
                GV *gv = cGVOPx_gv(tmpop);
                cv = GvCVu(gv);
                if (!cv)
                    tmpop->op_private |= OPpEARLY_CV;
            } break;
            case OP_CONST: {
                SV *sv = cSVOPx_sv(tmpop);
                if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV)
                    cv = (CV*)SvRV(sv);
            } break;
        }
        if( cv==my_des_cvs[0] )
            return des_check(aTHX_ o, NULL, NULL);
        if( cv==my_des_cvs[1] )
            return des_alias_check(aTHX_ o, NULL, NULL);
    }
    return orig_entersub_check(aTHX_ o);
}
#endif

MODULE = DestructAssign		PACKAGE = DestructAssign		

INCLUDE: const-xs.inc

BOOT:
    init_set_vtbl(&anonlist_vtbl, anonlist_set);
    init_set_vtbl(&anonlist_alias_vtbl, anonlist_alias_set);
    init_set_vtbl(&anonhash_vtbl, anonhash_set);
    init_set_vtbl(&anonhash_alias_vtbl, anonhash_alias_set);
#if PERL_VERSION_GE(5,14,0)
    cv_set_call_checker(get_cv("DestructAssign::des", TRUE), des_check, &PL_sv_undef);
    cv_set_call_checker(get_cv("DestructAssign::des_alias", TRUE), des_alias_check, &PL_sv_undef);
#else
    my_des_cvs[0] = get_cv("DestructAssign::des", TRUE);
    my_des_cvs[1] = get_cv("DestructAssign::des_alias", TRUE);
    orig_entersub_check = PL_check[OP_ENTERSUB];
    PL_check[OP_ENTERSUB] = my_entersub_check;
#endif
