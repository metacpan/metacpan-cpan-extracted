/*
 * Lugh::Quant - Quantization Utilities for Lugh
 * 
 * Type constants and utilities for working with quantized tensors
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <ggml.h>
#include <string.h>

MODULE = Lugh::Quant    PACKAGE = Lugh::Quant

const char *
type_name(type)
    int type
CODE:
    if (type < 0 || type >= GGML_TYPE_COUNT) {
        RETVAL = "unknown";
    } else {
        RETVAL = ggml_type_name((enum ggml_type)type);
    }
OUTPUT:
    RETVAL

size_t
type_size(type)
    int type
CODE:
    if (type < 0 || type >= GGML_TYPE_COUNT) {
        croak("Invalid type: %d", type);
    }
    RETVAL = ggml_type_size((enum ggml_type)type);
OUTPUT:
    RETVAL

int64_t
blck_size(type)
    int type
CODE:
    if (type < 0 || type >= GGML_TYPE_COUNT) {
        croak("Invalid type: %d", type);
    }
    RETVAL = ggml_blck_size((enum ggml_type)type);
OUTPUT:
    RETVAL

int
is_quantized(type)
    int type
CODE:
    if (type < 0 || type >= GGML_TYPE_COUNT) {
        RETVAL = 0;
    } else {
        RETVAL = ggml_is_quantized((enum ggml_type)type) ? 1 : 0;
    }
OUTPUT:
    RETVAL

double
type_sizef(type)
    int type
CODE:
    if (type < 0 || type >= GGML_TYPE_COUNT) {
        croak("Invalid type: %d", type);
    }
    RETVAL = ggml_type_sizef((enum ggml_type)type);
OUTPUT:
    RETVAL

size_t
row_size(type, n_elements)
    int type
    int64_t n_elements
CODE:
    if (type < 0 || type >= GGML_TYPE_COUNT) {
        croak("Invalid type: %d", type);
    }
    RETVAL = ggml_row_size((enum ggml_type)type, n_elements);
OUTPUT:
    RETVAL

int
requires_imatrix(type)
    int type
CODE:
    if (type < 0 || type >= GGML_TYPE_COUNT) {
        croak("Invalid type: %d", type);
    }
    RETVAL = ggml_quantize_requires_imatrix((enum ggml_type)type) ? 1 : 0;
OUTPUT:
    RETVAL

int
type_count()
CODE:
    RETVAL = GGML_TYPE_COUNT;
OUTPUT:
    RETVAL

void
all_types()
PREINIT:
    int i;
PPCODE:
    EXTEND(SP, GGML_TYPE_COUNT);
    for (i = 0; i < GGML_TYPE_COUNT; i++) {
        const char *name = ggml_type_name((enum ggml_type)i);
        if (name && strlen(name) > 0) {
            mPUSHi(i);
        }
    }

void
all_quantized_types()
PREINIT:
    int i;
PPCODE:
    for (i = 0; i < GGML_TYPE_COUNT; i++) {
        if (ggml_is_quantized((enum ggml_type)i)) {
            XPUSHs(sv_2mortal(newSViv(i)));
        }
    }

int
type_from_name(name)
    const char *name
CODE:
    int i;
    RETVAL = -1;
    for (i = 0; i < GGML_TYPE_COUNT; i++) {
        const char *tname = ggml_type_name((enum ggml_type)i);
        if (tname && strEQ(tname, name)) {
            RETVAL = i;
            break;
        }
    }
OUTPUT:
    RETVAL

void
type_info(type)
    int type
PREINIT:
    HV *hv;
    const char *name;
CODE:
    if (type < 0 || type >= GGML_TYPE_COUNT) {
        croak("Invalid type: %d", type);
    }
    
    hv = newHV();
    name = ggml_type_name((enum ggml_type)type);
    
    hv_store(hv, "type", 4, newSViv(type), 0);
    hv_store(hv, "name", 4, newSVpv(name ? name : "unknown", 0), 0);
    hv_store(hv, "size", 4, newSVuv(ggml_type_size((enum ggml_type)type)), 0);
    hv_store(hv, "blck_size", 9, newSViv(ggml_blck_size((enum ggml_type)type)), 0);
    hv_store(hv, "sizef", 5, newSVnv(ggml_type_sizef((enum ggml_type)type)), 0);
    hv_store(hv, "is_quantized", 12, 
             newSViv(ggml_is_quantized((enum ggml_type)type) ? 1 : 0), 0);
    hv_store(hv, "requires_imatrix", 16,
             newSViv(ggml_quantize_requires_imatrix((enum ggml_type)type) ? 1 : 0), 0);
    
    ST(0) = sv_2mortal(newRV_noinc((SV*)hv));
    XSRETURN(1);

BOOT:
{
    dTHX;
    HV *stash = gv_stashpv("Lugh::Quant", GV_ADD);
    AV *export_ok;
    HV *export_tags;
    AV *types_tag;
    AV *funcs_tag;
    
    /* ========================================================================
     * Type Constants
     * ======================================================================== */
    
    /* Float types */
    newCONSTSUB(stash, "F32", newSViv(GGML_TYPE_F32));
    newCONSTSUB(stash, "F16", newSViv(GGML_TYPE_F16));
    newCONSTSUB(stash, "F64", newSViv(GGML_TYPE_F64));
    newCONSTSUB(stash, "BF16", newSViv(GGML_TYPE_BF16));
    
    /* Integer types */
    newCONSTSUB(stash, "I8", newSViv(GGML_TYPE_I8));
    newCONSTSUB(stash, "I16", newSViv(GGML_TYPE_I16));
    newCONSTSUB(stash, "I32", newSViv(GGML_TYPE_I32));
    newCONSTSUB(stash, "I64", newSViv(GGML_TYPE_I64));
    
    /* Basic quantization */
    newCONSTSUB(stash, "Q4_0", newSViv(GGML_TYPE_Q4_0));
    newCONSTSUB(stash, "Q4_1", newSViv(GGML_TYPE_Q4_1));
    newCONSTSUB(stash, "Q5_0", newSViv(GGML_TYPE_Q5_0));
    newCONSTSUB(stash, "Q5_1", newSViv(GGML_TYPE_Q5_1));
    newCONSTSUB(stash, "Q8_0", newSViv(GGML_TYPE_Q8_0));
    newCONSTSUB(stash, "Q8_1", newSViv(GGML_TYPE_Q8_1));
    
    /* K-quant types */
    newCONSTSUB(stash, "Q2_K", newSViv(GGML_TYPE_Q2_K));
    newCONSTSUB(stash, "Q3_K", newSViv(GGML_TYPE_Q3_K));
    newCONSTSUB(stash, "Q4_K", newSViv(GGML_TYPE_Q4_K));
    newCONSTSUB(stash, "Q5_K", newSViv(GGML_TYPE_Q5_K));
    newCONSTSUB(stash, "Q6_K", newSViv(GGML_TYPE_Q6_K));
    newCONSTSUB(stash, "Q8_K", newSViv(GGML_TYPE_Q8_K));
    
    /* IQ (importance-matrix quantization) types */
    newCONSTSUB(stash, "IQ1_S", newSViv(GGML_TYPE_IQ1_S));
    newCONSTSUB(stash, "IQ1_M", newSViv(GGML_TYPE_IQ1_M));
    newCONSTSUB(stash, "IQ2_XXS", newSViv(GGML_TYPE_IQ2_XXS));
    newCONSTSUB(stash, "IQ2_XS", newSViv(GGML_TYPE_IQ2_XS));
    newCONSTSUB(stash, "IQ2_S", newSViv(GGML_TYPE_IQ2_S));
    newCONSTSUB(stash, "IQ3_XXS", newSViv(GGML_TYPE_IQ3_XXS));
    newCONSTSUB(stash, "IQ3_S", newSViv(GGML_TYPE_IQ3_S));
    newCONSTSUB(stash, "IQ4_NL", newSViv(GGML_TYPE_IQ4_NL));
    newCONSTSUB(stash, "IQ4_XS", newSViv(GGML_TYPE_IQ4_XS));
    
    /* Ternary quantization */
    newCONSTSUB(stash, "TQ1_0", newSViv(GGML_TYPE_TQ1_0));
    newCONSTSUB(stash, "TQ2_0", newSViv(GGML_TYPE_TQ2_0));
    
    /* Microscaling quantization */
    newCONSTSUB(stash, "MXFP4", newSViv(GGML_TYPE_MXFP4));
    
    /* Type count */
    newCONSTSUB(stash, "TYPE_COUNT", newSViv(GGML_TYPE_COUNT));
    
    /* ========================================================================
     * Export Setup - Pure XS, no Exporter.pm needed
     * ======================================================================== */
    
    /* Create @EXPORT_OK */
    export_ok = get_av("Lugh::Quant::EXPORT_OK", GV_ADD);
    
    /* Type constants */
    av_push(export_ok, newSVpvs("F32"));
    av_push(export_ok, newSVpvs("F16"));
    av_push(export_ok, newSVpvs("BF16"));
    av_push(export_ok, newSVpvs("F64"));
    av_push(export_ok, newSVpvs("I8"));
    av_push(export_ok, newSVpvs("I16"));
    av_push(export_ok, newSVpvs("I32"));
    av_push(export_ok, newSVpvs("I64"));
    av_push(export_ok, newSVpvs("Q4_0"));
    av_push(export_ok, newSVpvs("Q4_1"));
    av_push(export_ok, newSVpvs("Q5_0"));
    av_push(export_ok, newSVpvs("Q5_1"));
    av_push(export_ok, newSVpvs("Q8_0"));
    av_push(export_ok, newSVpvs("Q8_1"));
    av_push(export_ok, newSVpvs("Q2_K"));
    av_push(export_ok, newSVpvs("Q3_K"));
    av_push(export_ok, newSVpvs("Q4_K"));
    av_push(export_ok, newSVpvs("Q5_K"));
    av_push(export_ok, newSVpvs("Q6_K"));
    av_push(export_ok, newSVpvs("Q8_K"));
    av_push(export_ok, newSVpvs("IQ1_S"));
    av_push(export_ok, newSVpvs("IQ1_M"));
    av_push(export_ok, newSVpvs("IQ2_XXS"));
    av_push(export_ok, newSVpvs("IQ2_XS"));
    av_push(export_ok, newSVpvs("IQ2_S"));
    av_push(export_ok, newSVpvs("IQ3_XXS"));
    av_push(export_ok, newSVpvs("IQ3_S"));
    av_push(export_ok, newSVpvs("IQ4_NL"));
    av_push(export_ok, newSVpvs("IQ4_XS"));
    av_push(export_ok, newSVpvs("TQ1_0"));
    av_push(export_ok, newSVpvs("TQ2_0"));
    av_push(export_ok, newSVpvs("MXFP4"));
    av_push(export_ok, newSVpvs("TYPE_COUNT"));
    
    /* Function names */
    av_push(export_ok, newSVpvs("type_name"));
    av_push(export_ok, newSVpvs("type_size"));
    av_push(export_ok, newSVpvs("blck_size"));
    av_push(export_ok, newSVpvs("type_sizef"));
    av_push(export_ok, newSVpvs("is_quantized"));
    av_push(export_ok, newSVpvs("requires_imatrix"));
    av_push(export_ok, newSVpvs("row_size"));
    av_push(export_ok, newSVpvs("type_count"));
    av_push(export_ok, newSVpvs("all_types"));
    av_push(export_ok, newSVpvs("all_quantized_types"));
    av_push(export_ok, newSVpvs("type_from_name"));
    av_push(export_ok, newSVpvs("type_info"));
    
    /* Create %EXPORT_TAGS */
    export_tags = get_hv("Lugh::Quant::EXPORT_TAGS", GV_ADD);
    
    /* :types tag */
    types_tag = newAV();
    av_push(types_tag, newSVpvs("F32"));
    av_push(types_tag, newSVpvs("F16"));
    av_push(types_tag, newSVpvs("BF16"));
    av_push(types_tag, newSVpvs("F64"));
    av_push(types_tag, newSVpvs("I8"));
    av_push(types_tag, newSVpvs("I16"));
    av_push(types_tag, newSVpvs("I32"));
    av_push(types_tag, newSVpvs("I64"));
    av_push(types_tag, newSVpvs("Q4_0"));
    av_push(types_tag, newSVpvs("Q4_1"));
    av_push(types_tag, newSVpvs("Q5_0"));
    av_push(types_tag, newSVpvs("Q5_1"));
    av_push(types_tag, newSVpvs("Q8_0"));
    av_push(types_tag, newSVpvs("Q8_1"));
    av_push(types_tag, newSVpvs("Q2_K"));
    av_push(types_tag, newSVpvs("Q3_K"));
    av_push(types_tag, newSVpvs("Q4_K"));
    av_push(types_tag, newSVpvs("Q5_K"));
    av_push(types_tag, newSVpvs("Q6_K"));
    av_push(types_tag, newSVpvs("Q8_K"));
    av_push(types_tag, newSVpvs("IQ1_S"));
    av_push(types_tag, newSVpvs("IQ1_M"));
    av_push(types_tag, newSVpvs("IQ2_XXS"));
    av_push(types_tag, newSVpvs("IQ2_XS"));
    av_push(types_tag, newSVpvs("IQ2_S"));
    av_push(types_tag, newSVpvs("IQ3_XXS"));
    av_push(types_tag, newSVpvs("IQ3_S"));
    av_push(types_tag, newSVpvs("IQ4_NL"));
    av_push(types_tag, newSVpvs("IQ4_XS"));
    av_push(types_tag, newSVpvs("TQ1_0"));
    av_push(types_tag, newSVpvs("TQ2_0"));
    av_push(types_tag, newSVpvs("MXFP4"));
    av_push(types_tag, newSVpvs("TYPE_COUNT"));
    hv_store(export_tags, "types", 5, newRV_noinc((SV*)types_tag), 0);
    
    /* :funcs tag */
    funcs_tag = newAV();
    av_push(funcs_tag, newSVpvs("type_name"));
    av_push(funcs_tag, newSVpvs("type_size"));
    av_push(funcs_tag, newSVpvs("blck_size"));
    av_push(funcs_tag, newSVpvs("type_sizef"));
    av_push(funcs_tag, newSVpvs("is_quantized"));
    av_push(funcs_tag, newSVpvs("requires_imatrix"));
    av_push(funcs_tag, newSVpvs("row_size"));
    av_push(funcs_tag, newSVpvs("type_count"));
    av_push(funcs_tag, newSVpvs("all_types"));
    av_push(funcs_tag, newSVpvs("all_quantized_types"));
    av_push(funcs_tag, newSVpvs("type_from_name"));
    av_push(funcs_tag, newSVpvs("type_info"));
    hv_store(export_tags, "funcs", 5, newRV_noinc((SV*)funcs_tag), 0);
    
    /* :all tag - reference to @EXPORT_OK */
    hv_store(export_tags, "all", 3, newRV_inc((SV*)export_ok), 0);
}
