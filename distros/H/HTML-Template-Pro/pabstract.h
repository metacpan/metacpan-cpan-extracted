/*! \file pabstract.h
    \brief description of callbacks.
    
    In order to interact with core library a wrapper should provide 
    some callback functions. 
    This file specifies which callbacks can be provided.

    \author Igor Vlasenko <vlasenko@imath.kiev.ua>
    \warning This header file should never be included directly.
    Include <tmplpro.h> instead.
*/

#ifndef _PROABSTRACT_H
#define _PROABSTRACT_H	1

#include "pstring.h"
#include "pabidecl.h"

struct tmplpro_param;
struct exprval;

typedef void ABSTRACT_WRITER;
typedef void ABSTRACT_FINDFILE;
typedef void ABSTRACT_FILTER;
typedef void ABSTRACT_CALLER;
typedef void ABSTRACT_DATASTATE;

typedef void ABSTRACT_ARRAY;
typedef void ABSTRACT_MAP;
typedef void ABSTRACT_VALUE;

typedef void ABSTRACT_FUNCMAP;
typedef void ABSTRACT_ARGLIST;
typedef void ABSTRACT_USERFUNC;
typedef struct exprval ABSTRACT_EXPRVAL;


typedef void BACKCALL (*writer_functype) (ABSTRACT_WRITER*,const char* begin, const char* endnext);

typedef ABSTRACT_VALUE* BACKCALL (*get_ABSTRACT_VALUE_functype) (ABSTRACT_DATASTATE*, ABSTRACT_MAP*, PSTRING name);
typedef PSTRING BACKCALL (*ABSTRACT_VALUE2PSTRING_functype) (ABSTRACT_DATASTATE*, ABSTRACT_VALUE*);
/* optional */
typedef int BACKCALL (*is_ABSTRACT_VALUE_true_functype) (ABSTRACT_DATASTATE*, ABSTRACT_VALUE*);

typedef ABSTRACT_ARRAY* BACKCALL (*ABSTRACT_VALUE2ABSTRACT_ARRAY_functype) (ABSTRACT_DATASTATE*, ABSTRACT_VALUE*);
typedef int BACKCALL (*get_ABSTRACT_ARRAY_length_functype) (ABSTRACT_DATASTATE*, ABSTRACT_ARRAY*);
typedef ABSTRACT_MAP* BACKCALL (*get_ABSTRACT_MAP_functype) (ABSTRACT_DATASTATE*, ABSTRACT_ARRAY*,int);

/* optional notifier */
typedef void BACKCALL (*exit_loop_scope_functype) (ABSTRACT_DATASTATE*, ABSTRACT_ARRAY*);

typedef const char* BACKCALL (*find_file_functype) (ABSTRACT_FINDFILE*, const char* filename, const char* prevfilename);

/* optional; we can use wrapper to load file and apply its filters before running itself */
/* note that this function should allocate region 1 byte nore than the file size	 */
typedef PSTRING BACKCALL (*load_file_functype) (ABSTRACT_FILTER*, const char* filename);
typedef int     BACKCALL (*unload_file_functype) (ABSTRACT_FILTER*, PSTRING memarea);

/* -------- Expr extension------------ */

/* those are needed for EXPR= extension */
typedef ABSTRACT_USERFUNC* BACKCALL (*is_expr_userfnc_functype) (ABSTRACT_FUNCMAP*, PSTRING name);
typedef ABSTRACT_ARGLIST*  BACKCALL (*init_expr_arglist_functype) (ABSTRACT_CALLER*);
typedef void BACKCALL (*push_expr_arglist_functype) (ABSTRACT_ARGLIST*, ABSTRACT_EXPRVAL*);
typedef void BACKCALL (*free_expr_arglist_functype) (ABSTRACT_ARGLIST*);
typedef void BACKCALL (*call_expr_userfnc_functype) (ABSTRACT_CALLER*, ABSTRACT_ARGLIST*, ABSTRACT_USERFUNC*, ABSTRACT_EXPRVAL* return_value);

/* ------- end Expr extension -------- */

#endif /* _PROABSTRACT_H */

/** \typedef typedef void (*writer_functype) (ABSTRACT_WRITER*,const char* begin, const char* endnext);

    \brief optional callback for writing or accumulating a piece of generated text.

    \param begin, endnext - pointers to memory area containing the output string.
    \param ABSTRACT_WRITER* - pointer stored by tmplpro_set_option_ext_writer_state() or NULL if nothing was stored.

    Note that outpot string is NOT 0-terminated. Instead, 2 pointers are used, as in PSTRING.
    This callback is called multiple times. 
    This callback is optional: if not provided, a built-in stub will output to STDOUT.

    @see tmplpro_set_option_WriterFuncPtr
    @see tmplpro_set_option_ext_writer_state
 */

/** \typedef typedef ABSTRACT_VALUE* (*get_ABSTRACT_VALUE_functype) (ABSTRACT_MAP*, PSTRING name);
    \brief required callback to get a variable value.

    \param PSTRING name - a name as in &lt;TMPL_VAR NAME="var1"&gt;
    \param ABSTRACT_MAP*  pointer returned by callback of get_ABSTRACT_MAP_functype.
    \return NULL if NAME not found or a non-null pointer to be passed to callback 
    of ABSTRACT_VALUE2PSTRING_functype or ABSTRACT_VALUE2ABSTRACT_ARRAY_functype.
    @see tmplpro_set_option_GetAbstractValFuncPtr
 */

/** \typedef typedef PSTRING (*ABSTRACT_VALUE2PSTRING_functype) (ABSTRACT_VALUE*);
    \brief required callback to transform into PSTRING a variable name passed to callback of get_ABSTRACT_VALUE_functype.

    \param ABSTRACT_VALUE*  optional pointer returned by callback of get_ABSTRACT_VALUE_functype.
    \return PSTRING to a memory area. The memery area can be safely freed in the next call
    to ABSTRACT_VALUE2PSTRING_functype.

    @see tmplpro_set_option_AbstractVal2pstringFuncPtr
 */

/** \typedef typedef int (*is_ABSTRACT_VALUE_true_functype) (ABSTRACT_VALUE*);
    \brief optional callback to fine-tune is ABSTRACT_VALUE* is true or false.

    \param ABSTRACT_VALUE*  optional pointer returned by callback of get_ABSTRACT_VALUE_functype.
    \return 0(false) or 1(true).

    By default a stub is used that guesses true or false according to PSTRING form of ABSTRACT_VALUE.
    
    @see tmplpro_set_option_IsAbstractValTrueFuncPtr
 */

/** \typedef typedef ABSTRACT_ARRAY* (*ABSTRACT_VALUE2ABSTRACT_ARRAY_functype) (ABSTRACT_VALUE*);
    \brief required callback to transform into ABSTRACT_ARRAY a variable name passed to callback of get_ABSTRACT_VALUE_functype.

    \param ABSTRACT_VALUE*  optional pointer returned by callback of get_ABSTRACT_VALUE_functype.
    \return NULL if NAME can not be converted to ABSTRACT_ARRAY or a non-null pointer that will be passed 
     then to callbacks of get_ABSTRACT_ARRAY_length_functype and get_ABSTRACT_MAP_functype.

    @see tmplpro_set_option_AbstractVal2abstractArrayFuncPtr
 */

/** \typedef typedef int (*get_ABSTRACT_ARRAY_length_functype) (ABSTRACT_ARRAY*);
    \brief optional callback to specify a length of the loop.

    \param ABSTRACT_ARRAY*  optional pointer returned by callback of ABSTRACT_VALUE2ABSTRACT_ARRAY_functype.
    \return the length of the loop or a special value of -1 that indicates that loop has an undefined length
    (useful when one need to iterate over large number of records in database or lines in a file).

    By default a stub is used that returns -1.
    
    @see tmplpro_set_option_GetAbstractArrayLengthFuncPtr
 */

/** \typedef typedef ABSTRACT_MAP* (*get_ABSTRACT_MAP_functype) (ABSTRACT_ARRAY*,int n);
    \brief required callback to transform into ABSTRACT_ARRAY a variable name passed to callback of get_ABSTRACT_VALUE_functype.

    \param ABSTRACT_ARRAY* optional pointer returned by callback of ABSTRACT_VALUE2ABSTRACT_ARRAY_functype.
    \param n - number of current loop iteration.
    \return NULL if loop can no nore be iterated or a non-null pointer that will be passed 
    to callback of get_ABSTRACT_VALUE_functype.

    @see tmplpro_set_option_GetAbstractMapFuncPtr
 */

/** \typedef typedef void (*end_loop_functype) (ABSTRACT_MAP* root_param_map, int newlevel);
    \brief optional callback to notify a front-end that the current loop is exited.

    \param ABSTRACT_MAP*  optional pointer stored by tmplpro_set_option_root_param_map().
    \param newlevel current depth of nested loops (0 means a root scope).

    This callback is useful for front-end implementations which does not return pointers 
    to real objects. In that case the corresponding ABSTRACT_MAP*, ABSTRACT_ARRAY*, and ABSTRACT_VALUE*
    pointers are fake non-null values, so instead of those pointers this callback  can be used.

    @see tmplpro_set_option_EndLoopFuncPtr
 */

/** \typedef typedef void (*select_loop_scope_functype) (ABSTRACT_MAP* root_param_map, int level);
    \brief optional callback to select a loop.

    \param ABSTRACT_MAP*  optional pointer stored by tmplpro_set_option_root_param_map().
    \param int level level at which a loop will be selected.

    This callback is useful for front-end implementations which does not return pointers 
    to real objects. In that case the corresponding ABSTRACT_MAP*, ABSTRACT_ARRAY*, and ABSTRACT_VALUE*
    pointers are fake non-null values, so instead of those pointers this callback can be used.

    @see tmplpro_set_option_SelectLoopScopeFuncPtr
 */

/** \typedef typedef const char* (*find_file_functype) (ABSTRACT_FINDFILE*, const char* filename, const char* prevfilename);
    \brief optional callback to fine-tune the algorythm of finding template file by name.

    \param ABSTRACT_FINDFILE*  optional pointer stored by tmplpro_set_option_ext_writer_state().
    \param filename  file to be found.
    \param prevfilename fully qualified path to containing file, if any.
    \return fully qualified path to a file to be loaded.

    By default a stub is used (as of 0.82, with limited functionality).
    
    @see tmplpro_set_option_FindFileFuncPtr
 */

/** \typedef typedef PSTRING (*load_file_functype) (ABSTRACT_FILTER*, const char* filename);
    \brief optional callback to load and preprocess (filter) files.

    Only called if filters option is true (set by tmplpro_set_option_filters() ).

    \param ABSTRACT_FILTER*  optional pointer stored by tmplpro_set_option_ext_filter_state().
    \param filename fully qualified path to a file to be loaded 
    (as returned by callback of find_file_functype).
    \return PSTRING of memory area loaded.

    @see tmplpro_set_option_filters
    @see tmplpro_set_option_LoadFileFuncPtr
 */

/** \typedef typedef int (*unload_file_functype) (ABSTRACT_FILTER*, PSTRING memarea);
    \brief optional callback to free memory accuired by a callback of load_file_functype.

    Only called if filters option is true (set by tmplpro_set_option_filters() ).

    \param ABSTRACT_FILTER*  optional pointer stored by tmplpro_set_option_ext_filter_state().
    \param memarea pointers to loaded area
    (as returned by callback of load_file_functype).
    \return 0 on success, non-zero otherwise.

    @see tmplpro_set_option_filters
    @see tmplpro_set_option_UnloadFileFuncPtr
 */

/** \typedef typedef ABSTRACT_USERFUNC* (*is_expr_userfnc_functype) (ABSTRACT_FUNCMAP*, PSTRING name);
    \brief optional callback for support of user-provided functions.

    \param ABSTRACT_FUNCMAP*  optional pointer stored by tmplpro_set_option_expr_func_map().
    \param name  name of function
    \return NULL if there is no user function with such a name or non-null value to be passed 
    to callback of call_expr_userfnc_functype.

    \warning if is_expr_userfnc_functype callback is set, then callbacks of 
    init_expr_arglist_functype, push_expr_arglist_functype, free_expr_arglist_functype 
    and call_expr_userfnc_functype also should be set.

    @see tmplpro_set_option_IsExprUserfncFuncPtr
 */

/** \typedef typedef ABSTRACT_ARGLIST* (*init_expr_arglist_functype) (ABSTRACT_CALLER*);
    \brief optional callback to initialize the list of arguments for a user-provided function.

    Note that if function calls are nested, then the calls to a callbacks of 
    ::init_expr_arglist_functype, ::push_expr_arglist_functype, ::free_expr_arglist_functype
    will also be nested.

    \param ABSTRACT_CALLER*  optional pointer stored by tmplpro_set_option_ext_calluserfunc_state().
    \return value to be passed to callbacks of push_expr_arglist_functype, 
    free_expr_arglist_functype and call_expr_userfnc_functype.

    @see tmplpro_set_option_InitExprArglistFuncPtr
 */

/** \typedef typedef void (*free_expr_arglist_functype) (ABSTRACT_ARGLIST*);
    \brief optional callback to release the list of arguments for a user-provided function.

    Note that if function calls are nested, then the calls to a callbacks of 
    ::init_expr_arglist_functype, ::push_expr_arglist_functype, ::free_expr_arglist_functype
    will also be nested.

    \param ABSTRACT_ARGLIST*  optional pointer returned by callback of init_expr_arglist_functype.

    @see tmplpro_set_option_FreeExprArglistFuncPtr
 */

/** \typedef typedef void (*push_expr_arglist_functype) (ABSTRACT_ARGLIST*, ABSTRACT_EXPRVAL*);
    \brief optional callback to add new value to the list of arguments for a user-provided function.

    Note that if function calls are nested, then the calls to a callbacks of 
    ::init_expr_arglist_functype, ::push_expr_arglist_functype, ::free_expr_arglist_functype
    will also be nested.

    \param ABSTRACT_ARGLIST*  optional pointer returned by callback of init_expr_arglist_functype.
    \param ABSTRACT_EXPRVAL*  pointer required by tmplpro_get_expr_* functions to retrieve the value
    (a place the pushed value is stored).

    A value to be added to the list of arguments for a user-provided function is not passed 
    as argument to a callback of push_expr_arglist_functype. Instead, a pointer to 
    struct tmplpro_param is passed, and the callback function should discover the value's type 
    using tmplpro_get_expr_type() function, and then should retrieve the value 
    using one of the functions 
    \li tmplpro_get_expr_as_int64()
    \li tmplpro_get_expr_as_double()
    \li tmplpro_get_expr_as_pstring()

    @see tmplpro_set_option_PushExprArglistFuncPtr
 */

/** \typedef typedef void (*call_expr_userfnc_functype) (ABSTRACT_CALLER*, ABSTRACT_ARGLIST*, ABSTRACT_USERFUNC*, ABSTRACT_EXPRVAL*);

    \brief optional callback to call a user-provided function with a current list of arguments.

    \param ABSTRACT_CALLER*  optional pointer stored by tmplpro_set_option_ext_calluserfunc_state().
    \param ABSTRACT_ARGLIST*  optional pointer returned by callback of init_expr_arglist_functype.
    \param ABSTRACT_USERFUNC* optional pointer returned by callback of is_expr_userfnc_functype.
    \param ABSTRACT_EXPRVAL*  pointer required by tmplpro_set_expr_as_* functions 
    (a place the return value will be stored).

    To return the result user function returned the callback of call_expr_userfnc_functype should 
    call one of the functions 
    \li tmplpro_set_expr_as_null()
    \li tmplpro_set_expr_as_int64()
    \li tmplpro_set_expr_as_double()
    \li tmplpro_set_expr_as_string()
    \li tmplpro_set_expr_as_pstring()
    passing them the ABSTRACT_EXPRVAL* as argument.

    @see tmplpro_set_option_CallExprUserfncFuncPtr
 */

/** \typedef typedef void ABSTRACT_WRITER

    \brief optional pointer to be passed to a callback of ::writer_functype.

    Optional pointer to store internal state for a callback of ::writer_functype.
    If used, it should be stored beforehand with tmplpro_set_option_ext_writer_state().
    @see tmplpro_set_option_ext_writer_state
 */

/** \typedef typedef void ABSTRACT_FINDFILE

    \brief optional pointer to be passed to a callback of ::find_file_functype.

    Optional pointer to store internal state for a callback of ::find_file_functype.
    If used, it should be stored beforehand with tmplpro_set_option_ext_findfile_state().
    @see tmplpro_set_option_ext_findfile_state
 */

/** \typedef typedef void ABSTRACT_FILTER

    \brief optional pointer to be passed to a callback of ::load_file_functype / ::unload_file_functype.

    Optional pointer to store internal state for a callback of ::load_file_functype / ::unload_file_functype.
    If used, it should be stored beforehand with tmplpro_set_option_ext_filter_state().
    @see tmplpro_set_option_ext_filter_state
 */

/** \typedef typedef void ABSTRACT_CALLER

    \brief optional pointer to be passed to a callback of ::call_expr_userfnc_functype.

    Optional pointer to store internal state for a callback of ::call_expr_userfnc_functype.
    If used, it should be stored beforehand with tmplpro_set_option_ext_calluserfunc_state().
    @see tmplpro_set_option_ext_calluserfunc_state
 */

/** \typedef typedef void ABSTRACT_DATASTATE

    \brief optional pointer to be passed to data manipulation callbacks of 
    ::get_ABSTRACT_VALUE_functype, ::ABSTRACT_VALUE2ABSTRACT_ARRAY_functype, 
    ::get_ABSTRACT_ARRAY_length_functype, ::is_ABSTRACT_VALUE_true_functype,
    ::get_ABSTRACT_MAP_functype, exit_loop_scope_functype.

    Optional pointer to store internal state for a callback of 
    ::get_ABSTRACT_VALUE_functype, ::ABSTRACT_VALUE2ABSTRACT_ARRAY_functype, 
    ::get_ABSTRACT_ARRAY_length_functype, ::is_ABSTRACT_VALUE_true_functype,
    ::get_ABSTRACT_MAP_functype, exit_loop_scope_functype.
    If used, it should be stored beforehand with tmplpro_set_option_ext_data_state().
    @see tmplpro_set_option_ext_data_state
 */


/** \typedef typedef void ABSTRACT_ARRAY

    \brief optional pointer representing a loop.

    It is returned from a callback of ::ABSTRACT_VALUE2ABSTRACT_ARRAY_functype
    and is passed to callbacks of ::get_ABSTRACT_ARRAY_length_functype 
    and ::get_ABSTRACT_MAP_functype.
 */

/** \typedef typedef void ABSTRACT_MAP

    \brief optional pointer representing a root scope or a loop scope.

    Pointer for the loop scope is returned from a callback of ::get_ABSTRACT_MAP_functype.
    Pointer of the root scope should be stored beforehead using tmplpro_set_option_root_param_map().
    Both types of pointers are passed to callback of ::get_ABSTRACT_VALUE_functype.
    Also, root scope pointer is passed to callbacks of ::end_loop_functype and
    ::select_loop_scope_functype.
    @see tmplpro_set_option_root_param_map
 */

/** \typedef typedef void ABSTRACT_VALUE

    \brief optional pointer representing an abstract value that can be converted to a sting or loop.
    
    It is returned from callback of ::get_ABSTRACT_VALUE_functype and passed to
    callbacks of ::ABSTRACT_VALUE2ABSTRACT_ARRAY_functype and ::ABSTRACT_VALUE2PSTRING_functype.
 */

/** \typedef typedef void ABSTRACT_FUNCMAP

    \brief optional pointer to be passed to a callback of ::is_expr_userfnc_functype.

    If used, it should be stored beforehand with tmplpro_set_option_expr_func_map().
    @see tmplpro_set_option_expr_func_map
 */

/** \typedef typedef void ABSTRACT_ARGLIST

    \brief optional pointer representing a list accumulating arguments to user function call.
    
    It is returned from a callback of ::init_expr_arglist_functype
    and is passed to callbacks of ::push_expr_arglist_functype, ::call_expr_userfnc_functype
    and ::free_expr_arglist_functype.
 */

/** \typedef typedef void ABSTRACT_USERFUNC

    \brief optional pointer representing user function.

    It is returned from a callback of ::is_expr_userfnc_functype
    and is passed to callback of ::call_expr_userfnc_functype.
 */

/** \typedef typedef void ABSTRACT_EXPRVAL

    \brief optional pointer representing user function argument or return value.

    It is passed to callbacks of ::push_expr_arglist_functype and ::call_expr_userfnc_functype.
 */

/*
 *  Local Variables:
 *  mode: c
 *  End:
 */
