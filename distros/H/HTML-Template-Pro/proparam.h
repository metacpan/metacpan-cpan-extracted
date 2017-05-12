
/*! \file proparam.h
    \brief Getters and setters for libhtmltmplpro options.

    Public interface to get and set libhtmltmplpro options.
 
    \author Igor Vlasenko <vlasenko@imath.kiev.ua>
    \warning This header file should never be included directly.
    Include <tmplpro.h> instead.
*/

/* generated; do not edit */
#ifndef _PROPARAM_H
#define _PROPARAM_H	1

struct tmplpro_param;

/*! \fn int tmplpro_get_option_global_vars(struct tmplpro_param*);
    \brief get value of global_vars option.

    see HTML::Template::Pro perl module documentation for global_vars option.

    \param param -- pointer to an internal state.
*/
TMPLPRO_API int APICALL tmplpro_get_option_global_vars(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_global_vars(struct tmplpro_param*,int);
    \brief set value of global_vars option.

    see HTML::Template::Pro perl module documentation for global_vars option.

    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_global_vars(struct tmplpro_param*,int);

/*! \fn int tmplpro_get_option_max_includes(struct tmplpro_param*);
    \brief get value of max_includes option.

    see HTML::Template::Pro perl module documentation for max_includes option.

    \param param -- pointer to an internal state.
*/
TMPLPRO_API int APICALL tmplpro_get_option_max_includes(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_max_includes(struct tmplpro_param*,int);
    \brief set value of max_includes option.

    see HTML::Template::Pro perl module documentation for max_includes option.

    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_max_includes(struct tmplpro_param*,int);

/*! \fn int tmplpro_get_option_debug(struct tmplpro_param*);
    \brief get value of debug option.

    see HTML::Template::Pro perl module documentation for debug option.

    \param param -- pointer to an internal state.
*/
TMPLPRO_API int APICALL tmplpro_get_option_debug(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_debug(struct tmplpro_param*,int);
    \brief set value of debug option.

    see HTML::Template::Pro perl module documentation for debug option.

    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_debug(struct tmplpro_param*,int);

/*! \fn int tmplpro_get_option_tmpl_var_case(struct tmplpro_param*);
    \brief get value of tmpl_var_case option.

    see HTML::Template::Pro perl module documentation for tmpl_var_case option.

    \param param -- pointer to an internal state.
*/
TMPLPRO_API int APICALL tmplpro_get_option_tmpl_var_case(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_tmpl_var_case(struct tmplpro_param*,int);
    \brief set value of tmpl_var_case option.

    see HTML::Template::Pro perl module documentation for tmpl_var_case option.

    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_tmpl_var_case(struct tmplpro_param*,int);

/*! \fn int tmplpro_get_option_no_includes(struct tmplpro_param*);
    \brief get value of no_includes option.

    see HTML::Template::Pro perl module documentation for no_includes option.

    \param param -- pointer to an internal state.
*/
TMPLPRO_API int APICALL tmplpro_get_option_no_includes(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_no_includes(struct tmplpro_param*,int);
    \brief set value of no_includes option.

    see HTML::Template::Pro perl module documentation for no_includes option.

    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_no_includes(struct tmplpro_param*,int);

/*! \fn int tmplpro_get_option_loop_context_vars(struct tmplpro_param*);
    \brief get value of loop_context_vars option.

    see HTML::Template::Pro perl module documentation for loop_context_vars option.

    \param param -- pointer to an internal state.
*/
TMPLPRO_API int APICALL tmplpro_get_option_loop_context_vars(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_loop_context_vars(struct tmplpro_param*,int);
    \brief set value of loop_context_vars option.

    see HTML::Template::Pro perl module documentation for loop_context_vars option.

    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_loop_context_vars(struct tmplpro_param*,int);

/*! \fn int tmplpro_get_option_strict(struct tmplpro_param*);
    \brief get value of strict option.

    see HTML::Template::Pro perl module documentation for strict option.

    \param param -- pointer to an internal state.
*/
TMPLPRO_API int APICALL tmplpro_get_option_strict(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_strict(struct tmplpro_param*,int);
    \brief set value of strict option.

    see HTML::Template::Pro perl module documentation for strict option.

    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_strict(struct tmplpro_param*,int);

/*! \fn int tmplpro_get_option_filters(struct tmplpro_param*);
    \brief get value of filters option.

    see HTML::Template::Pro perl module documentation for filters option.

    \param param -- pointer to an internal state.
*/
TMPLPRO_API int APICALL tmplpro_get_option_filters(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_filters(struct tmplpro_param*,int);
    \brief set value of filters option.

    see HTML::Template::Pro perl module documentation for filters option.

    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_filters(struct tmplpro_param*,int);

/*! \fn int tmplpro_get_option_default_escape(struct tmplpro_param*);
    \brief get value of default_escape option.

    see HTML::Template::Pro perl module documentation for default_escape option.

    \param param -- pointer to an internal state.
*/
TMPLPRO_API int APICALL tmplpro_get_option_default_escape(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_default_escape(struct tmplpro_param*,int);
    \brief set value of default_escape option.

    see HTML::Template::Pro perl module documentation for default_escape option.

    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_default_escape(struct tmplpro_param*,int);

/*! \fn const char* tmplpro_get_option_filename(struct tmplpro_param*);
    \brief get value of filename option.

    see HTML::Template::Pro perl module documentation for filename option.

    \param param -- pointer to an internal state.
*/
TMPLPRO_API const char* APICALL tmplpro_get_option_filename(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_filename(struct tmplpro_param*,const char*);
    \brief set value of filename option.

    see HTML::Template::Pro perl module documentation for filename option.

    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_filename(struct tmplpro_param*,const char*);

/*! \fn PSTRING tmplpro_get_option_scalarref(struct tmplpro_param*);
    \brief get value of scalarref option.

    see HTML::Template::Pro perl module documentation for scalarref option.

    \param param -- pointer to an internal state.
*/
TMPLPRO_API PSTRING APICALL tmplpro_get_option_scalarref(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_scalarref(struct tmplpro_param*,PSTRING);
    \brief set value of scalarref option.

    see HTML::Template::Pro perl module documentation for scalarref option.

    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_scalarref(struct tmplpro_param*,PSTRING);

/*! \fn int tmplpro_get_option_path_like_variable_scope(struct tmplpro_param*);
    \brief get value of path_like_variable_scope option.

    see HTML::Template::Pro perl module documentation for path_like_variable_scope option.

    \param param -- pointer to an internal state.
*/
TMPLPRO_API int APICALL tmplpro_get_option_path_like_variable_scope(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_path_like_variable_scope(struct tmplpro_param*,int);
    \brief set value of path_like_variable_scope option.

    see HTML::Template::Pro perl module documentation for path_like_variable_scope option.

    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_path_like_variable_scope(struct tmplpro_param*,int);

/*! \fn int tmplpro_get_option_search_path_on_include(struct tmplpro_param*);
    \brief get value of search_path_on_include option.

    see HTML::Template::Pro perl module documentation for search_path_on_include option.

    \param param -- pointer to an internal state.
*/
TMPLPRO_API int APICALL tmplpro_get_option_search_path_on_include(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_search_path_on_include(struct tmplpro_param*,int);
    \brief set value of search_path_on_include option.

    see HTML::Template::Pro perl module documentation for search_path_on_include option.

    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_search_path_on_include(struct tmplpro_param*,int);

/*! \fn char** tmplpro_get_option_path(struct tmplpro_param*);
    \brief get value of path option.

    see HTML::Template::Pro perl module documentation for path option.

    \param param -- pointer to an internal state.
*/
TMPLPRO_API char** APICALL tmplpro_get_option_path(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_path(struct tmplpro_param*,char**);
    \brief set value of path option.

    see HTML::Template::Pro perl module documentation for path option.

    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_path(struct tmplpro_param*,char**);

/*! \fn char* tmplpro_get_option_template_root(struct tmplpro_param*);
    \brief get value of template_root option.

    see HTML::Template::Pro perl module documentation for template_root option.

    \param param -- pointer to an internal state.
*/
TMPLPRO_API char* APICALL tmplpro_get_option_template_root(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_template_root(struct tmplpro_param*,char*);
    \brief set value of template_root option.

    see HTML::Template::Pro perl module documentation for template_root option.

    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_template_root(struct tmplpro_param*,char*);

/*! \fn writer_functype tmplpro_get_option_WriterFuncPtr(struct tmplpro_param*);
    \brief get address of callback of ::writer_functype
    \param param -- pointer to an internal state.
*/
TMPLPRO_API writer_functype APICALL tmplpro_get_option_WriterFuncPtr(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_WriterFuncPtr(struct tmplpro_param*,writer_functype);
    \brief set callback of ::writer_functype
    \param param -- pointer to an internal state.
    \param val -- callback address to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_WriterFuncPtr(struct tmplpro_param*,writer_functype);

/*! \fn get_ABSTRACT_VALUE_functype tmplpro_get_option_GetAbstractValFuncPtr(struct tmplpro_param*);
    \brief get address of callback of ::get_ABSTRACT_VALUE_functype
    \param param -- pointer to an internal state.
*/
TMPLPRO_API get_ABSTRACT_VALUE_functype APICALL tmplpro_get_option_GetAbstractValFuncPtr(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_GetAbstractValFuncPtr(struct tmplpro_param*,get_ABSTRACT_VALUE_functype);
    \brief set callback of ::get_ABSTRACT_VALUE_functype
    \param param -- pointer to an internal state.
    \param val -- callback address to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_GetAbstractValFuncPtr(struct tmplpro_param*,get_ABSTRACT_VALUE_functype);

/*! \fn ABSTRACT_VALUE2PSTRING_functype tmplpro_get_option_AbstractVal2pstringFuncPtr(struct tmplpro_param*);
    \brief get address of callback of ::ABSTRACT_VALUE2PSTRING_functype
    \param param -- pointer to an internal state.
*/
TMPLPRO_API ABSTRACT_VALUE2PSTRING_functype APICALL tmplpro_get_option_AbstractVal2pstringFuncPtr(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_AbstractVal2pstringFuncPtr(struct tmplpro_param*,ABSTRACT_VALUE2PSTRING_functype);
    \brief set callback of ::ABSTRACT_VALUE2PSTRING_functype
    \param param -- pointer to an internal state.
    \param val -- callback address to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_AbstractVal2pstringFuncPtr(struct tmplpro_param*,ABSTRACT_VALUE2PSTRING_functype);

/*! \fn ABSTRACT_VALUE2ABSTRACT_ARRAY_functype tmplpro_get_option_AbstractVal2abstractArrayFuncPtr(struct tmplpro_param*);
    \brief get address of callback of ::ABSTRACT_VALUE2ABSTRACT_ARRAY_functype
    \param param -- pointer to an internal state.
*/
TMPLPRO_API ABSTRACT_VALUE2ABSTRACT_ARRAY_functype APICALL tmplpro_get_option_AbstractVal2abstractArrayFuncPtr(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_AbstractVal2abstractArrayFuncPtr(struct tmplpro_param*,ABSTRACT_VALUE2ABSTRACT_ARRAY_functype);
    \brief set callback of ::ABSTRACT_VALUE2ABSTRACT_ARRAY_functype
    \param param -- pointer to an internal state.
    \param val -- callback address to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_AbstractVal2abstractArrayFuncPtr(struct tmplpro_param*,ABSTRACT_VALUE2ABSTRACT_ARRAY_functype);

/*! \fn get_ABSTRACT_ARRAY_length_functype tmplpro_get_option_GetAbstractArrayLengthFuncPtr(struct tmplpro_param*);
    \brief get address of callback of ::get_ABSTRACT_ARRAY_length_functype
    \param param -- pointer to an internal state.
*/
TMPLPRO_API get_ABSTRACT_ARRAY_length_functype APICALL tmplpro_get_option_GetAbstractArrayLengthFuncPtr(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_GetAbstractArrayLengthFuncPtr(struct tmplpro_param*,get_ABSTRACT_ARRAY_length_functype);
    \brief set callback of ::get_ABSTRACT_ARRAY_length_functype
    \param param -- pointer to an internal state.
    \param val -- callback address to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_GetAbstractArrayLengthFuncPtr(struct tmplpro_param*,get_ABSTRACT_ARRAY_length_functype);

/*! \fn get_ABSTRACT_MAP_functype tmplpro_get_option_GetAbstractMapFuncPtr(struct tmplpro_param*);
    \brief get address of callback of ::get_ABSTRACT_MAP_functype
    \param param -- pointer to an internal state.
*/
TMPLPRO_API get_ABSTRACT_MAP_functype APICALL tmplpro_get_option_GetAbstractMapFuncPtr(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_GetAbstractMapFuncPtr(struct tmplpro_param*,get_ABSTRACT_MAP_functype);
    \brief set callback of ::get_ABSTRACT_MAP_functype
    \param param -- pointer to an internal state.
    \param val -- callback address to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_GetAbstractMapFuncPtr(struct tmplpro_param*,get_ABSTRACT_MAP_functype);

/*! \fn is_ABSTRACT_VALUE_true_functype tmplpro_get_option_IsAbstractValTrueFuncPtr(struct tmplpro_param*);
    \brief get address of callback of ::is_ABSTRACT_VALUE_true_functype
    \param param -- pointer to an internal state.
*/
TMPLPRO_API is_ABSTRACT_VALUE_true_functype APICALL tmplpro_get_option_IsAbstractValTrueFuncPtr(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_IsAbstractValTrueFuncPtr(struct tmplpro_param*,is_ABSTRACT_VALUE_true_functype);
    \brief set callback of ::is_ABSTRACT_VALUE_true_functype
    \param param -- pointer to an internal state.
    \param val -- callback address to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_IsAbstractValTrueFuncPtr(struct tmplpro_param*,is_ABSTRACT_VALUE_true_functype);

/*! \fn find_file_functype tmplpro_get_option_FindFileFuncPtr(struct tmplpro_param*);
    \brief get address of callback of ::find_file_functype
    \param param -- pointer to an internal state.
*/
TMPLPRO_API find_file_functype APICALL tmplpro_get_option_FindFileFuncPtr(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_FindFileFuncPtr(struct tmplpro_param*,find_file_functype);
    \brief set callback of ::find_file_functype
    \param param -- pointer to an internal state.
    \param val -- callback address to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_FindFileFuncPtr(struct tmplpro_param*,find_file_functype);

/*! \fn load_file_functype tmplpro_get_option_LoadFileFuncPtr(struct tmplpro_param*);
    \brief get address of callback of ::load_file_functype
    \param param -- pointer to an internal state.
*/
TMPLPRO_API load_file_functype APICALL tmplpro_get_option_LoadFileFuncPtr(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_LoadFileFuncPtr(struct tmplpro_param*,load_file_functype);
    \brief set callback of ::load_file_functype
    \param param -- pointer to an internal state.
    \param val -- callback address to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_LoadFileFuncPtr(struct tmplpro_param*,load_file_functype);

/*! \fn unload_file_functype tmplpro_get_option_UnloadFileFuncPtr(struct tmplpro_param*);
    \brief get address of callback of ::unload_file_functype
    \param param -- pointer to an internal state.
*/
TMPLPRO_API unload_file_functype APICALL tmplpro_get_option_UnloadFileFuncPtr(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_UnloadFileFuncPtr(struct tmplpro_param*,unload_file_functype);
    \brief set callback of ::unload_file_functype
    \param param -- pointer to an internal state.
    \param val -- callback address to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_UnloadFileFuncPtr(struct tmplpro_param*,unload_file_functype);

/*! \fn exit_loop_scope_functype tmplpro_get_option_ExitLoopScopeFuncPtr(struct tmplpro_param*);
    \brief get address of callback of ::exit_loop_scope_functype
    \param param -- pointer to an internal state.
*/
TMPLPRO_API exit_loop_scope_functype APICALL tmplpro_get_option_ExitLoopScopeFuncPtr(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_ExitLoopScopeFuncPtr(struct tmplpro_param*,exit_loop_scope_functype);
    \brief set callback of ::exit_loop_scope_functype
    \param param -- pointer to an internal state.
    \param val -- callback address to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_ExitLoopScopeFuncPtr(struct tmplpro_param*,exit_loop_scope_functype);

/*! \fn ABSTRACT_WRITER* tmplpro_get_option_ext_writer_state(struct tmplpro_param*);
    \brief get value of an external pointer that will be passed to a callback. see ::ABSTRACT_WRITER.
    \param param -- pointer to an internal state.
*/
TMPLPRO_API ABSTRACT_WRITER* APICALL tmplpro_get_option_ext_writer_state(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_ext_writer_state(struct tmplpro_param*,ABSTRACT_WRITER*);
    \brief set external pointer that will be passed to a callback. see ::ABSTRACT_WRITER.
    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_ext_writer_state(struct tmplpro_param*,ABSTRACT_WRITER*);

/*! \fn ABSTRACT_FILTER* tmplpro_get_option_ext_filter_state(struct tmplpro_param*);
    \brief get value of an external pointer that will be passed to a callback. see ::ABSTRACT_FILTER.
    \param param -- pointer to an internal state.
*/
TMPLPRO_API ABSTRACT_FILTER* APICALL tmplpro_get_option_ext_filter_state(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_ext_filter_state(struct tmplpro_param*,ABSTRACT_FILTER*);
    \brief set external pointer that will be passed to a callback. see ::ABSTRACT_FILTER.
    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_ext_filter_state(struct tmplpro_param*,ABSTRACT_FILTER*);

/*! \fn ABSTRACT_FINDFILE* tmplpro_get_option_ext_findfile_state(struct tmplpro_param*);
    \brief get value of an external pointer that will be passed to a callback. see ::ABSTRACT_FINDFILE.
    \param param -- pointer to an internal state.
*/
TMPLPRO_API ABSTRACT_FINDFILE* APICALL tmplpro_get_option_ext_findfile_state(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_ext_findfile_state(struct tmplpro_param*,ABSTRACT_FINDFILE*);
    \brief set external pointer that will be passed to a callback. see ::ABSTRACT_FINDFILE.
    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_ext_findfile_state(struct tmplpro_param*,ABSTRACT_FINDFILE*);

/*! \fn ABSTRACT_DATASTATE* tmplpro_get_option_ext_data_state(struct tmplpro_param*);
    \brief get value of an external pointer that will be passed to a callback. see ::ABSTRACT_DATASTATE.
    \param param -- pointer to an internal state.
*/
TMPLPRO_API ABSTRACT_DATASTATE* APICALL tmplpro_get_option_ext_data_state(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_ext_data_state(struct tmplpro_param*,ABSTRACT_DATASTATE*);
    \brief set external pointer that will be passed to a callback. see ::ABSTRACT_DATASTATE.
    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_ext_data_state(struct tmplpro_param*,ABSTRACT_DATASTATE*);

/*! \fn ABSTRACT_CALLER* tmplpro_get_option_ext_calluserfunc_state(struct tmplpro_param*);
    \brief get value of an external pointer that will be passed to a callback. see ::ABSTRACT_CALLER.
    \param param -- pointer to an internal state.
*/
TMPLPRO_API ABSTRACT_CALLER* APICALL tmplpro_get_option_ext_calluserfunc_state(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_ext_calluserfunc_state(struct tmplpro_param*,ABSTRACT_CALLER*);
    \brief set external pointer that will be passed to a callback. see ::ABSTRACT_CALLER.
    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_ext_calluserfunc_state(struct tmplpro_param*,ABSTRACT_CALLER*);

/*! \fn init_expr_arglist_functype tmplpro_get_option_InitExprArglistFuncPtr(struct tmplpro_param*);
    \brief get address of callback of ::init_expr_arglist_functype
    \param param -- pointer to an internal state.
*/
TMPLPRO_API init_expr_arglist_functype APICALL tmplpro_get_option_InitExprArglistFuncPtr(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_InitExprArglistFuncPtr(struct tmplpro_param*,init_expr_arglist_functype);
    \brief set callback of ::init_expr_arglist_functype
    \param param -- pointer to an internal state.
    \param val -- callback address to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_InitExprArglistFuncPtr(struct tmplpro_param*,init_expr_arglist_functype);

/*! \fn free_expr_arglist_functype tmplpro_get_option_FreeExprArglistFuncPtr(struct tmplpro_param*);
    \brief get address of callback of ::free_expr_arglist_functype
    \param param -- pointer to an internal state.
*/
TMPLPRO_API free_expr_arglist_functype APICALL tmplpro_get_option_FreeExprArglistFuncPtr(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_FreeExprArglistFuncPtr(struct tmplpro_param*,free_expr_arglist_functype);
    \brief set callback of ::free_expr_arglist_functype
    \param param -- pointer to an internal state.
    \param val -- callback address to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_FreeExprArglistFuncPtr(struct tmplpro_param*,free_expr_arglist_functype);

/*! \fn push_expr_arglist_functype tmplpro_get_option_PushExprArglistFuncPtr(struct tmplpro_param*);
    \brief get address of callback of ::push_expr_arglist_functype
    \param param -- pointer to an internal state.
*/
TMPLPRO_API push_expr_arglist_functype APICALL tmplpro_get_option_PushExprArglistFuncPtr(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_PushExprArglistFuncPtr(struct tmplpro_param*,push_expr_arglist_functype);
    \brief set callback of ::push_expr_arglist_functype
    \param param -- pointer to an internal state.
    \param val -- callback address to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_PushExprArglistFuncPtr(struct tmplpro_param*,push_expr_arglist_functype);

/*! \fn call_expr_userfnc_functype tmplpro_get_option_CallExprUserfncFuncPtr(struct tmplpro_param*);
    \brief get address of callback of ::call_expr_userfnc_functype
    \param param -- pointer to an internal state.
*/
TMPLPRO_API call_expr_userfnc_functype APICALL tmplpro_get_option_CallExprUserfncFuncPtr(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_CallExprUserfncFuncPtr(struct tmplpro_param*,call_expr_userfnc_functype);
    \brief set callback of ::call_expr_userfnc_functype
    \param param -- pointer to an internal state.
    \param val -- callback address to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_CallExprUserfncFuncPtr(struct tmplpro_param*,call_expr_userfnc_functype);

/*! \fn is_expr_userfnc_functype tmplpro_get_option_IsExprUserfncFuncPtr(struct tmplpro_param*);
    \brief get address of callback of ::is_expr_userfnc_functype
    \param param -- pointer to an internal state.
*/
TMPLPRO_API is_expr_userfnc_functype APICALL tmplpro_get_option_IsExprUserfncFuncPtr(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_IsExprUserfncFuncPtr(struct tmplpro_param*,is_expr_userfnc_functype);
    \brief set callback of ::is_expr_userfnc_functype
    \param param -- pointer to an internal state.
    \param val -- callback address to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_IsExprUserfncFuncPtr(struct tmplpro_param*,is_expr_userfnc_functype);

/*! \fn ABSTRACT_FUNCMAP* tmplpro_get_option_expr_func_map(struct tmplpro_param*);
    \brief get value of an external pointer that will be passed to a callback. see ::ABSTRACT_FUNCMAP.
    \param param -- pointer to an internal state.
*/
TMPLPRO_API ABSTRACT_FUNCMAP* APICALL tmplpro_get_option_expr_func_map(struct tmplpro_param*);

/*! \fn void tmplpro_set_option_expr_func_map(struct tmplpro_param*,ABSTRACT_FUNCMAP*);
    \brief set external pointer that will be passed to a callback. see ::ABSTRACT_FUNCMAP.
    \param param -- pointer to an internal state.
    \param val -- value to set.
*/
TMPLPRO_API void APICALL tmplpro_set_option_expr_func_map(struct tmplpro_param*,ABSTRACT_FUNCMAP*);


#endif /* proparam.h */
