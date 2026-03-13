/*
 * Legba.xs - Ultra-fast global slot storage for Perl
 *
 * Named after Papa Legba, the Vodou gatekeeper of crossroads.
 *
 * Uses custom ops for maximum speed:
 * - No subroutine call overhead
 * - Direct SV* pointer stored in op structure
 * - Single pointer dereference for get/set
 *
 * Registry is a single SV whose PVX is a raw array of SV* pointers.
 * Access is: ((SV**)SvPVX(registry))[idx] - pure pointer arithmetic.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* Compatibility macros for op sibling handling (5.22+) */
#ifndef OpSIBLING
#  define OpSIBLING(o) ((o)->op_sibling)
#endif

#ifndef OpMORESIB_set
#  define OpMORESIB_set(o, sib) ((o)->op_sibling = (sib))
#endif

#ifndef OpLASTSIB_set
#  define OpLASTSIB_set(o, parent) ((o)->op_sibling = NULL)
#endif

/* cGVOPx_gv compatibility */
#ifndef cGVOPx_gv
#  define cGVOPx_gv(o) ((GV*)cSVOPx(o)->op_sv)
#endif

/* The global registry - single SV with PVX as SV*[] array */
static SV *registry = NULL;

/* Name->index mapping (only used at compile time) */
static HV *slot_index = NULL;
static IV next_slot = 0;
static IV registry_size = 0;

/* Macros for direct slot access - no function call overhead */
#define SLOT_ARRAY ((SV**)SvPVX(registry))
#define SLOT_AT(idx) (SLOT_ARRAY[idx])

/* Custom op type for slot access - XOP API requires 5.14+ */
#if PERL_VERSION >= 14
static XOP slot_xop;
#endif
static Perl_ppaddr_t slot_op_ppaddr;

/* Custom OP structure with slot SV* embedded */
typedef struct {
    BASEOP
    SV *slot;  /* Direct pointer to slot SV */
} SLOTOP;

/* pp function for slot getter - maximum speed, no EXTEND check */
PERL_STATIC_INLINE OP* pp_slot_get(pTHX) {
    dSP;
    SLOTOP *slotop = (SLOTOP*)PL_op;
    /* Direct stack push - we know there's room for 1 value */
    EXTEND(SP, 1);
    PUSHs(slotop->slot);
    PUTBACK;
    return NORMAL;
}

/* pp function for slot setter - executes as an op, no sub call */  
PERL_STATIC_INLINE OP* pp_slot_set(pTHX) {
    dSP;
    SLOTOP *slotop = (SLOTOP*)PL_op;
    SV *value = POPs;
    sv_setsv(slotop->slot, value);
    PUSHs(slotop->slot);
    PUTBACK;
    return NORMAL;
}

/* Grow registry if needed */
static void grow_registry(pTHX_ IV needed) {
    if (needed > registry_size) {
        IV new_size = needed * 2;
        if (new_size < 8) new_size = 8;
        SvGROW(registry, new_size * sizeof(SV*));
        /* Zero new slots */
        Zero(SLOT_ARRAY + registry_size, new_size - registry_size, SV*);
        registry_size = new_size;
    }
}

/* Get or create slot SV for a name (only called at import time) */
static SV* get_or_create_slot(pTHX_ const char *name, STRLEN len) {
    SV **svp;
    IV idx;
    
    /* Check if slot already exists */
    svp = hv_fetch(slot_index, name, len, 0);
    if (svp && SvIOK(*svp)) {
        idx = SvIV(*svp);
        return SLOT_AT(idx);
    }
    
    /* Create new slot in registry */
    idx = next_slot++;
    hv_store(slot_index, name, len, newSViv(idx), 0);
    
    grow_registry(aTHX_ idx + 1);
    SV *slot = newSV(0);
    SLOT_AT(idx) = slot;
    return slot;
}

/* Create a custom slot op */
static OP* newSLOTOP(pTHX_ SV *slot, bool is_setter) {
    SLOTOP *slotop;
    NewOp(1101, slotop, 1, SLOTOP);
    slotop->op_type = OP_CUSTOM;
    slotop->op_ppaddr = is_setter ? pp_slot_set : pp_slot_get;
    slotop->op_flags = OPf_WANT_SCALAR;
    slotop->op_private = 0;
    slotop->slot = slot;
    return (OP*)slotop;
}

/* Magic vtable to mark CVs as slot accessors */
static MGVTBL slot_accessor_vtbl = {0, 0, 0, 0, 0, 0, 0, 0};

/* Check if a CV is a slot accessor */
#define CV_IS_SLOT_ACCESSOR(cv) (SvMAGICAL((SV*)cv) && mg_findext((SV*)cv, PERL_MAGIC_ext, &slot_accessor_vtbl))

/* Get slot from CV magic */
static SV* cv_get_slot(pTHX_ CV *cv) {
    MAGIC *mg = mg_findext((SV*)cv, PERL_MAGIC_ext, &slot_accessor_vtbl);
    return mg ? (SV*)mg->mg_ptr : NULL;
}

/* Old entersub checker */
static Perl_check_t old_entersub_checker;

/* Our entersub checker - replaces slot accessor calls with custom ops */
static OP* legba_ck_entersub(pTHX_ OP *entersubop) {
    OP *aop, *cvop;
    CV *cv;
    GV *gv;
    SV *slot;
    SLOTOP *slotop;
    bool has_args = FALSE;
    
    /* Call original checker first */
    entersubop = old_entersub_checker(aTHX_ entersubop);
    
    /* Find the CV being called - it's the last kid */
    aop = cUNOPx(entersubop)->op_first;
    if (!aop) return entersubop;
    
    /* Skip pushmark and args to find cvop */
    for (cvop = aop; OpSIBLING(cvop); cvop = OpSIBLING(cvop)) {
        if (cvop != aop && cvop->op_type != OP_PUSHMARK && cvop->op_type != OP_NULL) {
            has_args = TRUE;
        }
    }
    
    /* Only optimize no-arg calls (getters) for now */
    /* Setters fall back to XS accessor which is still fast */
    if (has_args) return entersubop;
    
    /* cvop should be rv2cv(gv) or similar */
    if (cvop->op_type != OP_RV2CV) return entersubop;
    if (!cUNOPx(cvop)->op_first) return entersubop;
    if (cUNOPx(cvop)->op_first->op_type != OP_GV) return entersubop;
    
    gv = cGVOPx_gv(cUNOPx(cvop)->op_first);
    if (!gv || !GvCV(gv)) return entersubop;
    
    cv = GvCV(gv);
    slot = cv_get_slot(aTHX_ cv);
    if (!slot) return entersubop;
    
    /* This is a slot getter call - replace with custom op */
    NewOp(1101, slotop, 1, SLOTOP);
    slotop->op_type = OP_CUSTOM;
    slotop->op_ppaddr = pp_slot_get;
    slotop->op_flags = entersubop->op_flags & OPf_WANT;
    slotop->op_private = 0;
    slotop->op_next = entersubop->op_next;
    slotop->slot = slot;
    
    /* Free old op tree */
    op_free(entersubop);
    
    return (OP*)slotop;
}

/* The slot accessor - fallback for when checker doesn't run */
XS(slot_accessor)
{
    dXSARGS;
    SV *slot;
    
    slot = (SV*)CvXSUBANY(cv).any_ptr;
    
    if (items == 0) {
        ST(0) = slot;
        XSRETURN(1);
    } else {
        sv_setsv(slot, ST(0));
        ST(0) = slot;
        XSRETURN(1);
    }
}

MODULE = Legba    PACKAGE = Legba

PROTOTYPES: DISABLE

BOOT:
{
    /* Initialize the global registry SV with PVX as SV*[] array */
    registry = newSV(0);
    SvUPGRADE(registry, SVt_PV);
    SvGROW(registry, 8 * sizeof(SV*));
    SvPOK_on(registry);
    Zero(SvPVX(registry), 8, SV*);
    registry_size = 8;
    
    /* Initialize name->index mapping */
    slot_index = newHV();
    next_slot = 0;
    
    /* Install entersub checker to optimize slot accessor calls */
    old_entersub_checker = PL_check[OP_ENTERSUB];
    PL_check[OP_ENTERSUB] = legba_ck_entersub;
    
    /* Register custom op - XOP API requires 5.14+ */
#if PERL_VERSION >= 14
    XopENTRY_set(&slot_xop, xop_name, "slot");
    XopENTRY_set(&slot_xop, xop_desc, "slot access");
    XopENTRY_set(&slot_xop, xop_class, OA_BASEOP);
    Perl_custom_op_register(aTHX_ pp_slot_get, &slot_xop);
#endif
}

# Create a getter op - returns OP* as UV
UV
_make_get_op(slot_name)
        SV *slot_name
    PREINIT:
        const char *name;
        STRLEN len;
        SV *slot;
        OP *op;
    CODE:
        name = SvPV(slot_name, len);
        slot = get_or_create_slot(aTHX_ name, len);
        op = newSLOTOP(aTHX_ slot, FALSE);
        RETVAL = PTR2UV(op);
    OUTPUT:
        RETVAL

# Create a setter op - returns OP* as UV
UV
_make_set_op(slot_name)
        SV *slot_name
    PREINIT:
        const char *name;
        STRLEN len;
        SV *slot;
        OP *op;
    CODE:
        name = SvPV(slot_name, len);
        slot = get_or_create_slot(aTHX_ name, len);
        op = newSLOTOP(aTHX_ slot, TRUE);
        RETVAL = PTR2UV(op);
    OUTPUT:
        RETVAL

# Internal: get slot value by name
SV*
_get(name)
        SV *name
    PREINIT:
        const char *n;
        STRLEN len;
        SV **svp;
        IV idx;
    CODE:
        n = SvPV(name, len);
        svp = hv_fetch(slot_index, n, len, 0);
        if (svp && SvIOK(*svp)) {
            idx = SvIV(*svp);
            RETVAL = SvREFCNT_inc(SLOT_AT(idx));
        } else {
            RETVAL = newSV(0);
        }
    OUTPUT:
        RETVAL

# Internal: set slot value by name
SV*
_set(name, value)
        SV *name
        SV *value
    PREINIT:
        const char *n;
        STRLEN len;
        SV *slot;
    CODE:
        n = SvPV(name, len);
        slot = get_or_create_slot(aTHX_ n, len);
        sv_setsv(slot, value);
        RETVAL = SvREFCNT_inc(slot);
    OUTPUT:
        RETVAL

# Internal: check if slot exists
int
_exists(name)
        SV *name
    PREINIT:
        const char *n;
        STRLEN len;
    CODE:
        n = SvPV(name, len);
        RETVAL = hv_exists(slot_index, n, len);
    OUTPUT:
        RETVAL

# Internal: delete a slot (sets to undef)
void
_delete(name)
        SV *name
    PREINIT:
        const char *n;
        STRLEN len;
        SV **svp;
        IV idx;
    CODE:
        n = SvPV(name, len);
        svp = hv_fetch(slot_index, n, len, 0);
        if (svp && SvIOK(*svp)) {
            idx = SvIV(*svp);
            sv_setsv(SLOT_AT(idx), &PL_sv_undef);
        }

# Internal: list all slot names
void
_keys()
    PREINIT:
        HE *entry;
        I32 len;
    PPCODE:
        hv_iterinit(slot_index);
        while ((entry = hv_iternext(slot_index))) {
            char *key = hv_iterkey(entry, &len);
            mXPUSHp(key, len);
        }

# Internal: clear all slots (reset to undef)
void
_clear()
    PREINIT:
        IV i;
    CODE:
        for (i = 0; i < next_slot; i++) {
            if (SLOT_AT(i)) sv_setsv(SLOT_AT(i), &PL_sv_undef);
        }

# Install an accessor function into a package - stores SV* directly for speed
void
_install_accessor(pkg, slot_name)
        SV *pkg
        SV *slot_name
    PREINIT:
        const char *pkg_name;
        const char *name;
        STRLEN pkg_len, name_len;
        char *full_name;
        CV *cv;
        CV *existing;
        SV *slot;
        HV *stash;
        SV **svp;
    CODE:
        pkg_name = SvPV(pkg, pkg_len);
        name = SvPV(slot_name, name_len);
        
        /* Check if accessor already exists in target package */
        stash = gv_stashpvn(pkg_name, pkg_len, 0);
        if (stash) {
            svp = hv_fetch(stash, name, name_len, 0);
            if (svp && isGV(*svp) && (existing = GvCV((GV*)*svp)) && CV_IS_SLOT_ACCESSOR(existing)) {
                /* Already installed as slot accessor, skip */
                return;
            }
        }
        
        /* Get or create slot SV */
        slot = get_or_create_slot(aTHX_ name, name_len);
        
        /* Create full sub name: Package::slot_name */
        Newx(full_name, pkg_len + name_len + 3, char);
        sprintf(full_name, "%s::%s", pkg_name, name);
        
        /* Create the accessor CV - store SV* directly, no lookup needed */
        cv = newXS(full_name, slot_accessor, __FILE__);
        CvXSUBANY(cv).any_ptr = (void*)slot;
        
        /* Mark CV as slot accessor with magic - stores slot ptr for checker */
        sv_magicext((SV*)cv, NULL, PERL_MAGIC_ext, &slot_accessor_vtbl, (char*)slot, 0);
        
        Safefree(full_name);

# Get direct slot SV pointer as UV (for embedding in custom ops)
UV
_slot_ptr(slot_name)
        SV *slot_name
    PREINIT:
        const char *name;
        STRLEN len;
        SV *slot;
    CODE:
        name = SvPV(slot_name, len);
        slot = get_or_create_slot(aTHX_ name, len);
        RETVAL = PTR2UV(slot);
    OUTPUT:
        RETVAL

# Get the global registry SV (PVX is array of SV* pointers)
SV*
_registry()
    CODE:
        RETVAL = SvREFCNT_inc(registry);
    OUTPUT:
        RETVAL

# import - called by 'use Legba qw/slot1 slot2/;'
void
import(...)
    PREINIT:
        const char *pkg_name;
        STRLEN pkg_len;
        I32 i;
        const char *name;
        STRLEN name_len;
        SV *slot;
        char *full_name;
        CV *cv;
        CV *existing;
        HV *stash;
        SV **svp;
        GV *gv;
    PPCODE:
        /* Get caller package from COP stash */
        stash = CopSTASH(PL_curcop);
        if (stash) {
            pkg_name = HvNAME(stash);
            pkg_len = HvNAMELEN(stash);
        } else {
            stash = PL_defstash;
            pkg_name = "main";
            pkg_len = 4;
        }
        
        /* Install accessor for each slot name */
        for (i = 1; i < items; i++) {
            name = SvPV(ST(i), name_len);
            
            /* Check if accessor already exists in caller's package */
            svp = hv_fetch(stash, name, name_len, 0);
            if (svp && isGV(*svp) && (existing = GvCV((GV*)*svp)) && CV_IS_SLOT_ACCESSOR(existing)) {
                /* Already installed as slot accessor, skip */
                continue;
            }
            
            /* Get or create slot SV */
            slot = get_or_create_slot(aTHX_ name, name_len);
            
            /* Create full sub name: Package::slot_name */
            Newx(full_name, pkg_len + name_len + 3, char);
            sprintf(full_name, "%s::%s", pkg_name, name);
            
            /* Create the accessor CV */
            cv = newXS(full_name, slot_accessor, __FILE__);
            CvXSUBANY(cv).any_ptr = (void*)slot;
            
            /* Mark CV as slot accessor with magic */
            sv_magicext((SV*)cv, NULL, PERL_MAGIC_ext, &slot_accessor_vtbl, (char*)slot, 0);
            
            Safefree(full_name);
        }
        XSRETURN(0);
