/*
  defines_no_args test
*/
#define MACRO_NO_ARGS_01
#define MACRO_NO_ARGS_02 something

/*
  defines_args test
*/
#define MACRO_NO_ARGS_03(a)
#define MACRO_NO_ARGS_04 (b,    c) something(b) + else(c) \
continued
/*
  parsed_fdecls test
*/
int func1(int x1, double *x2, float *( f1)(int x11, double x12));
int func2(int x1, double *x2, float *(*f1)(int x11, double x12));
int func3(int   , double *  , float *(*  )(int    , double    ));
int func4(int   , double *  , float *(*  )(int    , double    ));
/*
  typedef_hash, typedef_texts, typedefs_maybe tests
*/
typedef int myInt_type;
typedef enum myEnum1_e {X11 = 0, X12} myEnumType1_t, *myEnumType1p_t;
typedef enum {X21 = 0, X22} myEnumType2_t, *myEnumType2p_t;
typedef struct myStruct1 {int x;} myStructType1_t, *myStructType1p_t;
typedef struct {int x;} myStructType2_t, *myStructType2p_t;
typedef struct opaqueStruct myOpaqueStruct_t, *myOpaqueStructp_t;
/*
  vdecls, vdecl_hash tests
*/
extern int vint1;
extern double * vdouble2p;
