/* generated; do not edit */
#include "pabidecl.h"
#include "pabstract.h"
#include "pparam.h"
#include "proparam.h"


API_IMPL 
int 
APICALL tmplpro_get_option_global_vars(struct tmplpro_param* param) {
    return param->global_vars;
}

API_IMPL 
void
APICALL tmplpro_set_option_global_vars(struct tmplpro_param* param, int val) {
    param->global_vars=val;
}

API_IMPL 
int 
APICALL tmplpro_get_option_max_includes(struct tmplpro_param* param) {
    return param->max_includes;
}

API_IMPL 
void
APICALL tmplpro_set_option_max_includes(struct tmplpro_param* param, int val) {
    param->max_includes=val;
}

API_IMPL 
int 
APICALL tmplpro_get_option_debug(struct tmplpro_param* param) {
    return param->debug;
}

API_IMPL 
void
APICALL tmplpro_set_option_debug(struct tmplpro_param* param, int val) {
    param->debug=val;
}

API_IMPL 
int 
APICALL tmplpro_get_option_tmpl_var_case(struct tmplpro_param* param) {
    return param->tmpl_var_case;
}

API_IMPL 
void
APICALL tmplpro_set_option_tmpl_var_case(struct tmplpro_param* param, int val) {
    param->tmpl_var_case=val;
}

API_IMPL 
int 
APICALL tmplpro_get_option_no_includes(struct tmplpro_param* param) {
    return (int) param->no_includes;
}

API_IMPL 
void
APICALL tmplpro_set_option_no_includes(struct tmplpro_param* param, int val) {
    param->no_includes=(flag)val;
}

API_IMPL 
int 
APICALL tmplpro_get_option_loop_context_vars(struct tmplpro_param* param) {
    return (int) param->loop_context_vars;
}

API_IMPL 
void
APICALL tmplpro_set_option_loop_context_vars(struct tmplpro_param* param, int val) {
    param->loop_context_vars=(flag)val;
}

API_IMPL 
int 
APICALL tmplpro_get_option_strict(struct tmplpro_param* param) {
    return (int) param->strict;
}

API_IMPL 
void
APICALL tmplpro_set_option_strict(struct tmplpro_param* param, int val) {
    param->strict=(flag)val;
}

API_IMPL 
int 
APICALL tmplpro_get_option_filters(struct tmplpro_param* param) {
    return (int) param->filters;
}

API_IMPL 
void
APICALL tmplpro_set_option_filters(struct tmplpro_param* param, int val) {
    param->filters=(flag)val;
}

API_IMPL 
int 
APICALL tmplpro_get_option_default_escape(struct tmplpro_param* param) {
    return param->default_escape;
}

API_IMPL 
void
APICALL tmplpro_set_option_default_escape(struct tmplpro_param* param, int val) {
    param->default_escape=val;
}

API_IMPL 
const char* 
APICALL tmplpro_get_option_filename(struct tmplpro_param* param) {
    return param->filename;
}

API_IMPL 
void
APICALL tmplpro_set_option_filename(struct tmplpro_param* param, const char* val) {
    param->filename=val;
    if (NULL!=val) {
      param->scalarref.begin=NULL;
      param->scalarref.endnext=NULL;
}
}

API_IMPL 
PSTRING 
APICALL tmplpro_get_option_scalarref(struct tmplpro_param* param) {
    return param->scalarref;
}

API_IMPL 
void
APICALL tmplpro_set_option_scalarref(struct tmplpro_param* param, PSTRING val) {
    param->scalarref=val;
    if (NULL!=val.begin) param->filename=NULL;
}

API_IMPL 
int 
APICALL tmplpro_get_option_path_like_variable_scope(struct tmplpro_param* param) {
    return (int) param->path_like_variable_scope;
}

API_IMPL 
void
APICALL tmplpro_set_option_path_like_variable_scope(struct tmplpro_param* param, int val) {
    param->path_like_variable_scope=(flag)val;
}

API_IMPL 
int 
APICALL tmplpro_get_option_search_path_on_include(struct tmplpro_param* param) {
    return (int) param->search_path_on_include;
}

API_IMPL 
void
APICALL tmplpro_set_option_search_path_on_include(struct tmplpro_param* param, int val) {
    param->search_path_on_include=(flag)val;
}

API_IMPL 
char** 
APICALL tmplpro_get_option_path(struct tmplpro_param* param) {
    return param->path;
}

API_IMPL 
void
APICALL tmplpro_set_option_path(struct tmplpro_param* param, char** val) {
    param->path=val;
}

API_IMPL 
char* 
APICALL tmplpro_get_option_template_root(struct tmplpro_param* param) {
    return param->template_root;
}

API_IMPL 
void
APICALL tmplpro_set_option_template_root(struct tmplpro_param* param, char* val) {
    param->template_root=val;
}

API_IMPL 
writer_functype 
APICALL tmplpro_get_option_WriterFuncPtr(struct tmplpro_param* param) {
    return param->WriterFuncPtr;
}

API_IMPL 
void
APICALL tmplpro_set_option_WriterFuncPtr(struct tmplpro_param* param, writer_functype val) {
    param->WriterFuncPtr=val;
}

API_IMPL 
get_ABSTRACT_VALUE_functype 
APICALL tmplpro_get_option_GetAbstractValFuncPtr(struct tmplpro_param* param) {
    return param->GetAbstractValFuncPtr;
}

API_IMPL 
void
APICALL tmplpro_set_option_GetAbstractValFuncPtr(struct tmplpro_param* param, get_ABSTRACT_VALUE_functype val) {
    param->GetAbstractValFuncPtr=val;
}

API_IMPL 
ABSTRACT_VALUE2PSTRING_functype 
APICALL tmplpro_get_option_AbstractVal2pstringFuncPtr(struct tmplpro_param* param) {
    return param->AbstractVal2pstringFuncPtr;
}

API_IMPL 
void
APICALL tmplpro_set_option_AbstractVal2pstringFuncPtr(struct tmplpro_param* param, ABSTRACT_VALUE2PSTRING_functype val) {
    param->AbstractVal2pstringFuncPtr=val;
}

API_IMPL 
ABSTRACT_VALUE2ABSTRACT_ARRAY_functype 
APICALL tmplpro_get_option_AbstractVal2abstractArrayFuncPtr(struct tmplpro_param* param) {
    return param->AbstractVal2abstractArrayFuncPtr;
}

API_IMPL 
void
APICALL tmplpro_set_option_AbstractVal2abstractArrayFuncPtr(struct tmplpro_param* param, ABSTRACT_VALUE2ABSTRACT_ARRAY_functype val) {
    param->AbstractVal2abstractArrayFuncPtr=val;
}

API_IMPL 
get_ABSTRACT_ARRAY_length_functype 
APICALL tmplpro_get_option_GetAbstractArrayLengthFuncPtr(struct tmplpro_param* param) {
    return param->GetAbstractArrayLengthFuncPtr;
}

API_IMPL 
void
APICALL tmplpro_set_option_GetAbstractArrayLengthFuncPtr(struct tmplpro_param* param, get_ABSTRACT_ARRAY_length_functype val) {
    param->GetAbstractArrayLengthFuncPtr=val;
}

API_IMPL 
get_ABSTRACT_MAP_functype 
APICALL tmplpro_get_option_GetAbstractMapFuncPtr(struct tmplpro_param* param) {
    return param->GetAbstractMapFuncPtr;
}

API_IMPL 
void
APICALL tmplpro_set_option_GetAbstractMapFuncPtr(struct tmplpro_param* param, get_ABSTRACT_MAP_functype val) {
    param->GetAbstractMapFuncPtr=val;
}

API_IMPL 
is_ABSTRACT_VALUE_true_functype 
APICALL tmplpro_get_option_IsAbstractValTrueFuncPtr(struct tmplpro_param* param) {
    return param->IsAbstractValTrueFuncPtr;
}

API_IMPL 
void
APICALL tmplpro_set_option_IsAbstractValTrueFuncPtr(struct tmplpro_param* param, is_ABSTRACT_VALUE_true_functype val) {
    param->IsAbstractValTrueFuncPtr=val;
}

API_IMPL 
find_file_functype 
APICALL tmplpro_get_option_FindFileFuncPtr(struct tmplpro_param* param) {
    return param->FindFileFuncPtr;
}

API_IMPL 
void
APICALL tmplpro_set_option_FindFileFuncPtr(struct tmplpro_param* param, find_file_functype val) {
    param->FindFileFuncPtr=val;
}

API_IMPL 
load_file_functype 
APICALL tmplpro_get_option_LoadFileFuncPtr(struct tmplpro_param* param) {
    return param->LoadFileFuncPtr;
}

API_IMPL 
void
APICALL tmplpro_set_option_LoadFileFuncPtr(struct tmplpro_param* param, load_file_functype val) {
    param->LoadFileFuncPtr=val;
}

API_IMPL 
unload_file_functype 
APICALL tmplpro_get_option_UnloadFileFuncPtr(struct tmplpro_param* param) {
    return param->UnloadFileFuncPtr;
}

API_IMPL 
void
APICALL tmplpro_set_option_UnloadFileFuncPtr(struct tmplpro_param* param, unload_file_functype val) {
    param->UnloadFileFuncPtr=val;
}

API_IMPL 
exit_loop_scope_functype 
APICALL tmplpro_get_option_ExitLoopScopeFuncPtr(struct tmplpro_param* param) {
    return param->ExitLoopScopeFuncPtr;
}

API_IMPL 
void
APICALL tmplpro_set_option_ExitLoopScopeFuncPtr(struct tmplpro_param* param, exit_loop_scope_functype val) {
    param->ExitLoopScopeFuncPtr=val;
}

API_IMPL 
ABSTRACT_WRITER* 
APICALL tmplpro_get_option_ext_writer_state(struct tmplpro_param* param) {
    return param->ext_writer_state;
}

API_IMPL 
void
APICALL tmplpro_set_option_ext_writer_state(struct tmplpro_param* param, ABSTRACT_WRITER* val) {
    param->ext_writer_state=val;
}

API_IMPL 
ABSTRACT_FILTER* 
APICALL tmplpro_get_option_ext_filter_state(struct tmplpro_param* param) {
    return param->ext_filter_state;
}

API_IMPL 
void
APICALL tmplpro_set_option_ext_filter_state(struct tmplpro_param* param, ABSTRACT_FILTER* val) {
    param->ext_filter_state=val;
}

API_IMPL 
ABSTRACT_FINDFILE* 
APICALL tmplpro_get_option_ext_findfile_state(struct tmplpro_param* param) {
    return param->ext_findfile_state;
}

API_IMPL 
void
APICALL tmplpro_set_option_ext_findfile_state(struct tmplpro_param* param, ABSTRACT_FINDFILE* val) {
    param->ext_findfile_state=val;
}

API_IMPL 
ABSTRACT_DATASTATE* 
APICALL tmplpro_get_option_ext_data_state(struct tmplpro_param* param) {
    return param->ext_data_state;
}

API_IMPL 
void
APICALL tmplpro_set_option_ext_data_state(struct tmplpro_param* param, ABSTRACT_DATASTATE* val) {
    param->ext_data_state=val;
}

API_IMPL 
ABSTRACT_CALLER* 
APICALL tmplpro_get_option_ext_calluserfunc_state(struct tmplpro_param* param) {
    return param->ext_calluserfunc_state;
}

API_IMPL 
void
APICALL tmplpro_set_option_ext_calluserfunc_state(struct tmplpro_param* param, ABSTRACT_CALLER* val) {
    param->ext_calluserfunc_state=val;
}

API_IMPL 
init_expr_arglist_functype 
APICALL tmplpro_get_option_InitExprArglistFuncPtr(struct tmplpro_param* param) {
    return param->InitExprArglistFuncPtr;
}

API_IMPL 
void
APICALL tmplpro_set_option_InitExprArglistFuncPtr(struct tmplpro_param* param, init_expr_arglist_functype val) {
    param->InitExprArglistFuncPtr=val;
}

API_IMPL 
free_expr_arglist_functype 
APICALL tmplpro_get_option_FreeExprArglistFuncPtr(struct tmplpro_param* param) {
    return param->FreeExprArglistFuncPtr;
}

API_IMPL 
void
APICALL tmplpro_set_option_FreeExprArglistFuncPtr(struct tmplpro_param* param, free_expr_arglist_functype val) {
    param->FreeExprArglistFuncPtr=val;
}

API_IMPL 
push_expr_arglist_functype 
APICALL tmplpro_get_option_PushExprArglistFuncPtr(struct tmplpro_param* param) {
    return param->PushExprArglistFuncPtr;
}

API_IMPL 
void
APICALL tmplpro_set_option_PushExprArglistFuncPtr(struct tmplpro_param* param, push_expr_arglist_functype val) {
    param->PushExprArglistFuncPtr=val;
}

API_IMPL 
call_expr_userfnc_functype 
APICALL tmplpro_get_option_CallExprUserfncFuncPtr(struct tmplpro_param* param) {
    return param->CallExprUserfncFuncPtr;
}

API_IMPL 
void
APICALL tmplpro_set_option_CallExprUserfncFuncPtr(struct tmplpro_param* param, call_expr_userfnc_functype val) {
    param->CallExprUserfncFuncPtr=val;
}

API_IMPL 
is_expr_userfnc_functype 
APICALL tmplpro_get_option_IsExprUserfncFuncPtr(struct tmplpro_param* param) {
    return param->IsExprUserfncFuncPtr;
}

API_IMPL 
void
APICALL tmplpro_set_option_IsExprUserfncFuncPtr(struct tmplpro_param* param, is_expr_userfnc_functype val) {
    param->IsExprUserfncFuncPtr=val;
}

API_IMPL 
ABSTRACT_FUNCMAP* 
APICALL tmplpro_get_option_expr_func_map(struct tmplpro_param* param) {
    return param->expr_func_map;
}

API_IMPL 
void
APICALL tmplpro_set_option_expr_func_map(struct tmplpro_param* param, ABSTRACT_FUNCMAP* val) {
    param->expr_func_map=val;
}
