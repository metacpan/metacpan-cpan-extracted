#pragma SWIG nowarn=302,451,509

%{
#include "mzscheme.c"
%}

%typemap(in) Perl_Scalar {
    $1 = (void *)$input;
}

%typemap(out) Perl_Scalar {
    $result = newSVsv((SV *)$1);
    sv_2mortal($result);
    argvi++;
}

%typemap(in) Scheme_Object ** {
    $1 = _mzscheme_from_perl_arrayref_to_objects($input);
};

%typemap(freearg) Scheme_Object ** {
    free($1);
}

%typemap(out) Scheme_Object ** {
    $result = newRV((SV *)_mzscheme_objects_AV((void **)$1, (char *)&SWIGTYPE_p_Scheme_Object));
    sv_2mortal($result);
    argvi++;
}

void            mzscheme_init();
Scheme_Object*  mzscheme_make_perl_prim_w_arity(Perl_Scalar cv_ref, const char *name, int mina, int maxa, const char *sigil);
Scheme_Object*  mzscheme_make_perl_object_w_arity(Perl_Scalar object, const char *name, int mina, int maxa, const char *sigil);
Scheme_Object * mzscheme_from_perl_scalar (Perl_Scalar sv);
Scheme_Object * mzscheme_from_perl_symbol (Perl_Scalar sv);
Scheme_Object * mzscheme_from_perl_arrayref (Perl_Scalar sv);
Scheme_Object * mzscheme_from_perl_hashref (Perl_Scalar sv);
Perl_Scalar     mzscheme_to_perl_scalar (Scheme_Object *obj);

Scheme_Object * mzscheme_do_apply(Scheme_Object *f, int c, Scheme_Object **args);
Scheme_Object * mzscheme_do_eval(Scheme_Object *expr, Scheme_Env *env);
Scheme_Object * mzscheme_do_eval_string_all(char *str, Scheme_Env *env, int all);

int             MZSCHEME_REFADDR(Perl_Scalar sv);
int             MZSCHEME_UNDEFP(Scheme_Object *obj);
int             MZSCHEME_ALISTP(Scheme_Object *obj);
int             MZSCHEME_CODE_REFP(Scheme_Object *obj);
int             MZSCHEME_HASH_REFP(Scheme_Object *obj);
int             MZSCHEME_ARRAY_REFP(Scheme_Object *obj);
int             MZSCHEME_GLOB_REFP(Scheme_Object *obj);
int             MZSCHEME_SCALAR_REFP(Scheme_Object *obj);
int             MZSCHEME_PERLP(Scheme_Object *obj);

Scheme_Type     SCHEME_TYPE(Scheme_Object *obj);
int             SCHEME_PROCP(Scheme_Object *obj);
int             SCHEME_SYNTAXP(Scheme_Object *obj);
int             SCHEME_PRIMP(Scheme_Object *obj);
int             SCHEME_CLSD_PRIMP(Scheme_Object *obj);
int             SCHEME_CONTP(Scheme_Object *obj);
int             SCHEME_ECONTP(Scheme_Object *obj);
int             SCHEME_PROC_STRUCTP(Scheme_Object *obj);
int             SCHEME_STRUCT_PROCP(Scheme_Object *obj);
int             SCHEME_GENERICP(Scheme_Object *obj);
int             SCHEME_CLOSUREP(Scheme_Object *obj);

int             SCHEME_CHARP(Scheme_Object *obj);
int             SCHEME_STRINGP(Scheme_Object *obj);
int             SCHEME_SYMBOLP(Scheme_Object *obj);
int             SCHEME_STRSYMP(Scheme_Object *obj);

int             SCHEME_BOOLP(Scheme_Object *obj);
int             SCHEME_FALSEP(Scheme_Object *obj);
int             SCHEME_TRUEP(Scheme_Object *obj);
int             SCHEME_EOFP(Scheme_Object *obj);
int             SCHEME_VOIDP(Scheme_Object *obj);

int             SCHEME_NULLP(Scheme_Object *obj);
int             SCHEME_PAIRP(Scheme_Object *obj);

int             SCHEME_LISTP(Scheme_Object *obj);
int             SCHEME_VECTORP(Scheme_Object *obj);

int             SCHEME_BOXP(Scheme_Object *obj);

int             SCHEME_BUCKTP(Scheme_Object *obj);
int             SCHEME_HASHTP(Scheme_Object *obj);

int             SCHEME_INPORTP(Scheme_Object *obj);
int             SCHEME_OUTPORTP(Scheme_Object *obj);

char            SCHEME_CHAR_VAL(Scheme_Object *obj);
int             SCHEME_INT_VAL(Scheme_Object *obj);
double          SCHEME_DBL_VAL(Scheme_Object *obj);
float           SCHEME_FLT_VAL(Scheme_Object *obj);
#ifdef MZ_USE_SINGLE_FLOATS
float           SCHEME_FLOAT_VAL(Scheme_Object *obj);
#else
double          SCHEME_FLOAT_VAL(Scheme_Object *obj);
#endif
char *          SCHEME_STR_VAL(Scheme_Object *obj);
char *          SCHEME_STRTAG_VAL(Scheme_Object *obj);
char *          SCHEME_STRLEN_VAL(Scheme_Object *obj);
char *          SCHEME_SYM_VAL(Scheme_Object *obj);
int             SCHEME_SYM_LEN(Scheme_Object *obj);
unsigned long   SCHEME_SYMSTR_OFFSET(Scheme_Object *obj);
char *          SCHEME_STRSYM_VAL(Scheme_Object *obj);
Scheme_Object*  SCHEME_BOX_VAL(Scheme_Object *obj);
int             SCHEME_VEC_SIZE(Scheme_Object *obj);
Scheme_Object** SCHEME_VEC_ELS(Scheme_Object *obj);
Scheme_Object** SCHEME_VEC_BASE(Scheme_Object *obj);

Scheme_Object*  SCHEME_CAR(Scheme_Object *obj);
Scheme_Object*  SCHEME_CDR(Scheme_Object *obj);
Scheme_Object*  SCHEME_CADR(Scheme_Object *obj);
Scheme_Object*  SCHEME_CAAR(Scheme_Object *obj);
Scheme_Object*  SCHEME_CDDR(Scheme_Object *obj);

/*
#define SCHEME_ENVBOX_VAL(obj)  (*((Scheme_Object **)(obj)))
#define SCHEME_WEAK_BOX_VAL(obj) SCHEME_BOX_VAL(obj)

#define SCHEME_PTR_VAL(obj)  (((Scheme_Small_Object *)(obj))->u.ptr_val)
#define SCHEME_PTR1_VAL(obj) ((obj)->u.two_ptr_val.ptr1)
#define SCHEME_PTR2_VAL(obj) ((obj)->u.two_ptr_val.ptr2)
#define SCHEME_IPTR_VAL(obj) ((obj)->u.ptr_int_val.ptr)
#define SCHEME_LPTR_VAL(obj) ((obj)->u.ptr_long_val.ptr)
#define SCHEME_INT1_VAL(obj) ((obj)->u.two_int_val.int1)
#define SCHEME_INT2_VAL(obj) ((obj)->u.two_int_val.int2)
#define SCHEME_PINT_VAL(obj) ((obj)->u.ptr_int_val.pint)
#define SCHEME_PLONG_VAL(obj) ((obj)->u.ptr_long_val.pint)
*/

#define SCHEME_CPTR_VAL(obj) SCHEME_PTR1_VAL(obj)
#define SCHEME_CPTR_TYPE(obj) ((char *)SCHEME_PTR2_VAL(obj))

int             scheme_case_sensitive;
Scheme_Config   *scheme_config;
Scheme_Env      *scheme_basic_env(void);

Scheme_Object   *scheme_make_integer(int i);
Scheme_Object   *scheme_make_character(char ch);
Scheme_Object   *scheme_set_param(Scheme_Config *c, int pos, Scheme_Object *o);
Scheme_Object   *scheme_get_param(Scheme_Config *c, int pos);

Scheme_Object   *scheme_alloc_object();
Scheme_Object   *scheme_alloc_small_object();
Scheme_Object   *scheme_alloc_stubborn_object();
Scheme_Object   *scheme_alloc_stubborn_small_object();
Scheme_Object   *scheme_alloc_eternal_object();
Scheme_Object   *scheme_alloc_eternal_small_object();

#include "mzscheme_wrap.h"

