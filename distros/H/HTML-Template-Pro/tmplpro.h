/*! \file tmplpro.h
    \brief libhtmltmplpro API header.
    
    An official libhtmltmplpro API header.

    \author Igor Vlasenko <vlasenko@imath.kiev.ua>
*/

#ifndef _TMPLPRO_H
#define _TMPLPRO_H	1

#include "pabidecl.h"
#include "pstring.h"
#include "exprtype.h"
#include "pabstract.h"
#include "proparam.h"

/*
 * generic load/first use library and unload/last use library hooks.
 */
TMPLPRO_API void APICALL tmplpro_procore_init(void);
TMPLPRO_API void APICALL tmplpro_procore_done(void);

TMPLPRO_API const char* APICALL tmplpro_version(void);

struct tmplpro_param;
/* 
 * Constructor and destructor of tmplpro_param. 
 * Note that struct tmplpro_param is not part of the interface
 * and is subject to change without notice.
 */
TMPLPRO_API struct tmplpro_param* APICALL tmplpro_param_init(void);
TMPLPRO_API void APICALL tmplpro_param_free(struct tmplpro_param*);

TMPLPRO_API int APICALL tmplpro_exec_tmpl (struct tmplpro_param*);
TMPLPRO_API PSTRING APICALL tmplpro_tmpl2pstring (struct tmplpro_param *param, int *exitcode);


TMPLPRO_API void APICALL tmplpro_clear_option_param_map(struct tmplpro_param *param);
TMPLPRO_API int APICALL tmplpro_count_option_param_map(struct tmplpro_param *param);
TMPLPRO_API int APICALL tmplpro_push_option_param_map(struct tmplpro_param *param, ABSTRACT_MAP* map, EXPR_int64 flags);

TMPLPRO_API int APICALL tmplpro_get_int_option(struct tmplpro_param* param, const char *p, int* failure_ptr);
TMPLPRO_API int APICALL tmplpro_set_int_option(struct tmplpro_param* param, const char *p, int value);
TMPLPRO_API void APICALL tmplpro_reset_int_options(struct tmplpro_param* param);

TMPLPRO_API int APICALL tmplpro_errno(struct tmplpro_param* param);
TMPLPRO_API const char* APICALL tmplpro_errmsg(struct tmplpro_param* param);

TMPLPRO_API int APICALL tmplpro_set_log_file(struct tmplpro_param* param, const char* logfilename);
TMPLPRO_API size_t APICALL tmplpro_param_allocated_memory_info(struct tmplpro_param* param);



struct exprval;
TMPLPRO_API void APICALL tmplpro_set_expr_as_int64 (ABSTRACT_EXPRVAL*,EXPR_int64);
TMPLPRO_API void APICALL tmplpro_set_expr_as_double (ABSTRACT_EXPRVAL*,double);
TMPLPRO_API void APICALL tmplpro_set_expr_as_string (ABSTRACT_EXPRVAL*, const char*);
TMPLPRO_API void APICALL tmplpro_set_expr_as_pstring (ABSTRACT_EXPRVAL*,PSTRING);
TMPLPRO_API void APICALL tmplpro_set_expr_as_null (ABSTRACT_EXPRVAL*);

TMPLPRO_API int  APICALL tmplpro_get_expr_type (ABSTRACT_EXPRVAL*);
TMPLPRO_API EXPR_int64 APICALL tmplpro_get_expr_as_int64 (ABSTRACT_EXPRVAL*);
TMPLPRO_API double APICALL tmplpro_get_expr_as_double (ABSTRACT_EXPRVAL*);
TMPLPRO_API PSTRING APICALL tmplpro_get_expr_as_pstring (ABSTRACT_EXPRVAL*);


#define ASK_NAME_DEFAULT	0
#define ASK_NAME_AS_IS		1
#define ASK_NAME_LOWERCASE	2
#define ASK_NAME_UPPERCASE	4
#define ASK_NAME_MASK	(ASK_NAME_AS_IS|ASK_NAME_LOWERCASE|ASK_NAME_UPPERCASE)
/* future compatibility: not yet implemented */
#define ASK_NAME_CAPITALIZED	8
#define ASK_NAME_LCFIRST	16
#define ASK_NAME_UCFIRST	32
/* define ASK_NAME_MASK	(ASK_NAME_AS_IS|ASK_NAME_LOWERCASE|ASK_NAME_UPPERCASE|ASK_NAME_CAPITALIZED|ASK_NAME_LCFIRST|ASK_NAME_UCFIRST) */

#define HTML_TEMPLATE_OPT_ESCAPE_NO   0
#define HTML_TEMPLATE_OPT_ESCAPE_HTML 1
#define HTML_TEMPLATE_OPT_ESCAPE_URL  2
#define HTML_TEMPLATE_OPT_ESCAPE_JS   3

#endif /* tmplpro.h */



/*! \fn void tmplpro_procore_init(void);
    \brief generic load library/first use initializer.

    Initializer of global internal structures.
    Should be called before first use of the library.

    \warning May not be thread safe. Should be called once.
*/

/*! \fn void tmplpro_procore_done(void);
    \brief generic load/first use library and unload/last use library hooks.

    Deinitializer of global internal structures.
    Should be called before unloading the library.

    \warning May not be thread safe. Should be called once.
*/

/*! \fn const char* tmplpro_version(void);
    \brief version of the library
    \return version string.
*/

/*! \fn struct tmplpro_param* tmplpro_param_init(void);
    \brief Constructor of tmplpro_param.
*/

/*! \fn void tmplpro_param_free(struct tmplpro_param*);
    \brief Destructor of tmplpro_param.
*/

/*! \fn int tmplpro_exec_tmpl (struct tmplpro_param*);
    \brief main method of libhtmltmplpro.
*/

/*! \fn PSTRING tmplpro_tmpl2pstring (struct tmplpro_param*, int* exitcode);
    \brief main method of libhtmltmplpro. Returns processed template as a C string.

    Note that returned PSTRING resides in an internal tmplpro buffer.
    A caller should copy its contents as it will be rewritten in the next 
    call to tmplpro_tmpl2pstring. It is libhtmltmplpro ( tmplpro_param_free() )
    responsibility to free the buffer's memory during the destruction 
    of param object.
*/

/*! \fn void tmplpro_set_expr_as_int64 (ABSTRACT_EXPRVAL*,EXPR_int64);
    \brief method to return int64 value from callback of call_expr_userfnc_functype.

    It should only be used in a callback of call_expr_userfnc_functype.
*/

/*! \fn void tmplpro_set_expr_as_double (ABSTRACT_EXPRVAL*,double);
    \brief method to return double value from callback of call_expr_userfnc_functype.

    It should only be used in a callback of call_expr_userfnc_functype.
*/

/*! \fn void tmplpro_set_expr_as_string (ABSTRACT_EXPRVAL*,char*);
    \brief method to return C string value from callback of call_expr_userfnc_functype.

    It should only be used in a callback of call_expr_userfnc_functype.
*/

/*! \fn void tmplpro_set_expr_as_pstring (ABSTRACT_EXPRVAL*,PSTRING);
    \brief method to return PSTRING value from callback of call_expr_userfnc_functype.

    It should only be used in a callback of call_expr_userfnc_functype.
*/

/*! \fn void tmplpro_set_expr_as_null (ABSTRACT_EXPRVAL*);
    \brief method to return null from callback of call_expr_userfnc_functype.

    It should only be used in a callback of call_expr_userfnc_functype.
*/

/*! \fn EXPR_int64 tmplpro_get_expr_as_int64 (ABSTRACT_EXPRVAL*);
    \brief method for callback of push_expr_arglist_functype to retrieve a value as int64.
*/

/*! \fn double tmplpro_get_expr_as_double (ABSTRACT_EXPRVAL*);
    \brief method for callback of push_expr_arglist_functype to retrieve a value as double.

    It should only be used in a callback of push_expr_arglist_functype.
*/

/*! \fn PSTRING tmplpro_get_expr_as_pstring (ABSTRACT_EXPRVAL*);
    \brief method for callback of push_expr_arglist_functype to retrieve a value as PSTRING.

    It should only be used in a callback of push_expr_arglist_functype.
*/

/*! \fn int  tmplpro_get_expr_type (ABSTRACT_EXPRVAL*);
    \brief method for callback of push_expr_arglist_functype to determine the type of a value.

    It should only be used in a callback of push_expr_arglist_functype.
*/

/*! \fn int  tmplpro_get_int_option(struct tmplpro_param* param, const char *p, int* failure_ptr);
    \brief string-based option getter, useful for dynamic languages.

    non-NULL failure_ptr is used to return exit code. 
    Note that exit code is also available via tmplpro_errno/tmplpro_errmsg.
    Non-null exit code indicates failure (invalid option).
*/

/*! \fn int  tmplpro_set_int_option(struct tmplpro_param* param, const char *p, int val);
    \brief string-based option setter, useful for dynamic languages.
    
    returns exit code, also available via tmplpro_errno/tmplpro_errmsg.
    Non-null exit code indicates failure (invalid option or invalid option value).
*/

/*! \fn void  tmplpro_reset_int_options(struct tmplpro_param* param);
    \brief reset integer userspace options to their default values.
*/

/*! \fn int  tmplpro_errno(struct tmplpro_param* param);
    \brief exit code of the last function call.

    Exit code of the last function call. 
    (For functions that return exit status).

*/

/*! \fn const char* tmplpro_errmsg(struct tmplpro_param* param);
    \brief exit message of the last function call.

    A exit status message of the last function call. 
    (For functions that return exit status).
*/

/** \struct tmplpro_param

    \brief main htmltmplpro class.
    
    Main htmltmplpro class. Passed by reference.
    Its internal structure is hidden and is not part of the API.

    Constructor is  tmplpro_param_init()
    
    Destructor is tmplpro_param_free()

    Main methods are tmplpro_exec_tmpl(), tmplpro_tmpl2pstring()

 */

/** \struct exprval

    \brief EXPR="..." variable class.
    
    EXPR="..." expression variable class. Passed by reference.
    Its internal structure is hidden and is not part of the API.
    It can contain string, 64-bit integer or double.

    Methods:
    \li tmplpro_set_expr_as_null(ABSTRACT_EXPRVAL*)
    \li tmplpro_set_expr_as_int64(ABSTRACT_EXPRVAL*,EXPR_int64)
    \li tmplpro_set_expr_as_double(ABSTRACT_EXPRVAL*,double)
    \li tmplpro_set_expr_as_string(ABSTRACT_EXPRVAL*,const char*)
    \li tmplpro_set_expr_as_pstring(ABSTRACT_EXPRVAL*,PSTRING)

    \li tmplpro_get_expr_type(ABSTRACT_EXPRVAL*)
    \li tmplpro_get_expr_as_int64(ABSTRACT_EXPRVAL*)
    \li tmplpro_get_expr_as_double(ABSTRACT_EXPRVAL*)
    \li tmplpro_get_expr_as_pstring(ABSTRACT_EXPRVAL*)
 */


/*! \mainpage
 *
 * \section intro_sec Introduction
 *
 * \include README
 *
 * \section compile_sec Compilation
 *
 * \subsection autoconf
 *  
 * \subsection CMake
 * etc...
 *  
 * \section api_sec History of API and ABI changes
 *
 * \include API
 *
 */
