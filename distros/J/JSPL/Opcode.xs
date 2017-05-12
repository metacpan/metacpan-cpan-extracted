#include "JS.h"

#include "jsopcode.h"

/* SM 1.7.0 compat */
#ifndef JOF_ATOM
#define JOF_ATOM    JOF_CONST
#endif

typedef struct PJS_CodeSpec PJS_CodeSpec;
struct PJS_CodeSpec {
    const char *jsop;
    const char *op_name;
    int8 op_len;
    int8 op_uses;
    int8 op_defs;
    uint8 op_prec;
    uint32 op_format;
};

static const char js_arguments_str[]  = "arguments";
static const char js_new_str[]        = "new";
static const char js_typeof_str[]     = "typeof";
static const char js_void_str[]       = "void";
static const char js_null_str[]       = "null";
static const char js_this_str[]       = "this";
static const char js_false_str[]      = "false";
static const char js_true_str[]       = "true";
static const char js_throw_str[]      = "throw";
static const char js_in_str[]         = "in";
static const char js_instanceof_str[] = "instanceof";
static const char js_getter_str[]     = "getter";
static const char js_setter_str[]     = "setter";

const PJS_CodeSpec jsp_CodeSpec[] = {
#define OPDEF(op,val,name, token,len,nuses,ndefs,prec,format) \
    {#op, name, len, nuses, ndefs, prec, format},
#include "jsopcode.tbl"
#undef OPDEF
};

PJS_GTYPEDEF(PJS_CodeSpec, SM__Opcode);
#define MYNAMESP    NAMESPACE"SM::Opcode"
#include "op-const-c.inc"

#ifndef INDEX_LEN
#define INDEX_LEN   JUMP_OFFSET_LEN
#endif

static uintN
GetVariableBytecodeLength(jsbytecode *pc)
{
    JSOp op;
    uintN jmplen, ncases;
    jsint low, high;

    op = (JSOp) *pc;
    JS_ASSERT(jsp_CodeSpec[op].op_len == -1);
    switch (op) {
      case JSOP_TABLESWITCHX:
        jmplen = JUMPX_OFFSET_LEN;
        goto do_table;
      case JSOP_TABLESWITCH:
        jmplen = JUMP_OFFSET_LEN;
      do_table:
        /* Structure: default-jump case-low case-high case1-jump ... */
        pc += jmplen;
        low = GET_JUMP_OFFSET(pc);
        pc += JUMP_OFFSET_LEN;
        high = GET_JUMP_OFFSET(pc);
        ncases = (uintN)(high - low + 1);
        return 1 + jmplen + INDEX_LEN + INDEX_LEN + ncases * jmplen;

      case JSOP_LOOKUPSWITCHX:
        jmplen = JUMPX_OFFSET_LEN;
        goto do_lookup;
      default:
        JS_ASSERT(op == JSOP_LOOKUPSWITCH);
        jmplen = JUMP_OFFSET_LEN;
      do_lookup:
        /* Structure: default-jump case-count (case1-value case1-jump) ... */
        pc += jmplen;
        ncases = GET_UINT16(pc);
        return 1 + jmplen + INDEX_LEN + ncases * (INDEX_LEN + jmplen);
    }
}


MODULE = JSPL::SM::Opcode    PACKAGE = JSPL::SM::Opcode

BOOT:
    AV* smops = get_av(MYNAMESP"::Opcodes", 1);
    HV* stash = gv_stashpv(MYNAMESP, 0);
    int i;
    for(i = 0; i < JSOP_LIMIT; i++) {
	SV *rop = newSV(0);
	sv_setref_pv(rop, MYNAMESP, (void *)&(jsp_CodeSpec[i]));
	av_store(smops, i, rop);
	newCONSTSUB(stash, jsp_CodeSpec[i].jsop, newSViv(i));
    }


const char *
name(op)
    JSPL::SM::Opcode op;
    ALIAS:
	id = 1
    CODE:
	RETVAL = ix ? op->jsop : op->op_name;
    OUTPUT:
	RETVAL

int
len(op)
    JSPL::SM::Opcode op;
    ALIAS:
	uses = 1
	defs = 2
	prec = 3
	format = 4
    CODE:
	RETVAL = 0;
	switch(ix) {
	    case 0: RETVAL = op->op_len;  break;
	    case 1: RETVAL = op->op_uses; break;
	    case 2: RETVAL = op->op_defs; break;
	    case 3: RETVAL = op->op_prec; break;
	    case 4: RETVAL = op->op_format; break;
	}
    OUTPUT:
	RETVAL

int
_var_len(pc)
    char *pc;
    CODE:
	RETVAL = GetVariableBytecodeLength((jsbytecode *)pc);
    OUTPUT:
	RETVAL

#ifdef __GNUC__
#pragma GCC diagnostic ignored "-Wuninitialized"
#endif
INCLUDE: op-const-xs.inc
