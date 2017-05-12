
typedef SV* Perl_Scalar;
typedef struct {
    int         magic;
    Perl_Scalar sv;
    char        sigil;
} Perl_Callback;

Scheme_Object*      mzscheme_from_perl_scalar (Perl_Scalar sv);

AV*                 _mzscheme_objects_AV (void **objects, char *type);
Scheme_Object*      _mzscheme_closed_prim_CV (void *d, int argc, Scheme_Object **argv);
Scheme_Object*      _mzscheme_closed_prim_OBJ (void *callback, int argc, Scheme_Object **argv);
Scheme_Object**     _mzscheme_from_perl_arrayref_to_objects (Perl_Scalar sv);

#define Perl_Callback_MAGIC  '&'

#define Perl_Context_AUTO    NULL
#define Perl_Context_VOID    '!'

#define Perl_Context_BOOLEAN '?'
#define Perl_Context_SCALAR  '$'
#define Perl_Context_STRING  '~'
#define Perl_Context_NUMBER  '+'
#define Perl_Context_CHAR    '.'

#define Perl_Context_LIST    '@'
#define Perl_Context_VECTOR  '^'
#define Perl_Context_HASH    '%'
#define Perl_Context_ALIST   '&'

#define Perl_To_SYMBOL

#define Perl_Context(sigil) \
    ( (sigil == Perl_Context_VOID) ? G_VOID : \
      ((sigil == Perl_Context_BOOLEAN) || \
       (sigil == Perl_Context_SCALAR) || \
       (sigil == Perl_Context_STRING) || \
       (sigil == Perl_Context_NUMBER) || \
       (sigil == Perl_Context_CHAR)) ? G_SCALAR : \
       G_ARRAY )

#define MZSCHEME_REFADDR(sv) (SvROK(sv) ? (int)PTR2UV(SvRV(sv)) : 0)
#define MZSCHEME_UNDEFP(obj)  SAME_OBJ((obj), scheme_void) || \
                              SAME_OBJ((obj), scheme_undefined) || \
                              SAME_OBJ((obj), scheme_false) || \
                              SAME_OBJ((obj), scheme_eof)
#define MZSCHEME_ALISTP(obj)  _mzscheme_alistp(obj)

#define MZSCHEME_CODE_REFP(obj)   SCHEME_PROCP(obj)
#define MZSCHEME_HASH_REFP(obj)   SCHEME_HASHTP(obj) || MZSCHEME_ALISTP(obj)
#define MZSCHEME_ARRAY_REFP(obj)  SCHEME_LISTP(obj) || SCHEME_VECTORP(obj)
#define MZSCHEME_GLOB_REFP(obj)   SCHEME_INPORTP(obj) || SCHEME_OUTPORTP(obj)
#define MZSCHEME_SCALAR_REFP(obj) SCHEME_BOXP(obj)

#define MZSCHEME_PERLP(obj) (SCHEME_CLSD_PRIMP(obj) && \
    ((Perl_Callback *)SCHEME_CLSD_PRIM_DATA(obj))->magic == Perl_Callback_MAGIC)

#define MZSCHEME_DO(expr) \
    Scheme_Object *port = scheme_make_string_output_port(); \
    scheme_set_param(scheme_config, MZCONFIG_ERROR_PORT, port); \
    if (scheme_setjmp(scheme_error_buf)) { \
        if (PL_in_eval) { \
            sv_setpv(ERRSV, scheme_get_string_output(port)); \
            return scheme_undefined; \
        } \
        else { \
            croak("%s", scheme_get_string_output(port)); \
        } \
    } \
    else { \
        return expr; \
    }

