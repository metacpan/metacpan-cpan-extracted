/* -*- c -*- 
 * File: pparam.h
 * Author: Igor Vlasenko <vlasenko@imath.kiev.ua>
 * Created: Thu Jul  9 20:05:37 2009
 */

#ifndef _PPARAM_H
#define _PPARAM_H	1

#include "proscope.h"
#include "pbuffer.h"
#include "exprval.h" /* TODO: remove together with buffer */

/* for wrappers; flag better always be int32 - useful for Mono */
#if HAVE_INTTYPES_H
# include <inttypes.h>
   typedef int32_t flag;
#else
# if HAVE_STDINT_H
#  include <stdint.h>
   typedef int32_t flag;
# else
   typedef int flag;
# endif
#endif

struct tmplpro_param {
  int global_vars;
  int max_includes; /*default:16 */
  int debug;
  int tmpl_var_case;
  flag no_includes;
  flag loop_context_vars;
  flag strict;
  /* filters --- indicates whether to use 
   * external file loader hook specified as LoadFileFuncPtr. 
   * Set it to 1 if you want to preprocess file with filters
   * before they'll be processed by exec_tmpl */
  flag filters;
  int default_escape; /* one of HTML_TEMPLATE_OPT_ESCAPE_* */
  const char* filename; /* template file */
  PSTRING scalarref; /* memory area */
  flag path_like_variable_scope;
  flag search_path_on_include;
  char** path;
  char* template_root;
  /* flag vanguard_compatibility_mode; */

  /* hooks to perl or other container */
  /* HTML::Template callback hooks */
  writer_functype WriterFuncPtr;
  get_ABSTRACT_VALUE_functype GetAbstractValFuncPtr;
  ABSTRACT_VALUE2PSTRING_functype AbstractVal2pstringFuncPtr;
  ABSTRACT_VALUE2ABSTRACT_ARRAY_functype AbstractVal2abstractArrayFuncPtr;
  get_ABSTRACT_ARRAY_length_functype GetAbstractArrayLengthFuncPtr;
  get_ABSTRACT_MAP_functype GetAbstractMapFuncPtr;
  /* user-supplied --- optional; we use it for full emulation of perl quirks */
  is_ABSTRACT_VALUE_true_functype IsAbstractValTrueFuncPtr;
  find_file_functype FindFileFuncPtr;
  load_file_functype LoadFileFuncPtr;
unload_file_functype UnloadFileFuncPtr;
  exit_loop_scope_functype ExitLoopScopeFuncPtr;
  /* external state references to be supplied to callbacks */
  ABSTRACT_WRITER* ext_writer_state;
  ABSTRACT_FILTER* ext_filter_state;
  ABSTRACT_FINDFILE* ext_findfile_state;
  ABSTRACT_DATASTATE* ext_data_state;
  ABSTRACT_CALLER* ext_calluserfunc_state;
  /* HTML::Template::Expr hooks */
  init_expr_arglist_functype InitExprArglistFuncPtr;
  free_expr_arglist_functype FreeExprArglistFuncPtr;
  /**
     important note: 
     PushExprArglistFuncPtr should always copy the supplied pstring arg
     as it could point to a temporary location.
   */
  push_expr_arglist_functype PushExprArglistFuncPtr;
  call_expr_userfnc_functype CallExprUserfncFuncPtr;
  is_expr_userfnc_functype   IsExprUserfncFuncPtr;
  ABSTRACT_FUNCMAP*  expr_func_map;

  /* private */
  /* flags to be declared */
  /* TODO use in walk_through_nested_loops */
  flag warn_unused;

  /* private */
  int found_syntax_error;
  int htp_errno;

  int cur_includes; /* internal counter of include depth */
  const char* masterpath; /* file that has included this file, or NULL */

  /* variable scope (nested loops) passed to include */
  struct scope_stack var_scope_stack;
  int param_map_count; /* internal counter of pushed scope roots */

  /* private buffer of builtin tmpl2string */
  pbuffer builtin_tmpl2string_buffer;
  /* private buffer of builtin_findfile */
  pbuffer builtin_findfile_buffer;
  /* private buffer of write_chars_to_pbuffer */
  pbuffer builtin_writer_buffer;
  /* private buffers of walk_through_nested_loops */
  PSTRING lowercase_varname;
  pbuffer lowercase_varname_buffer;
  PSTRING uppercase_varname;
  pbuffer uppercase_varname_buffer;

  /* private buffer for escape_pstring */
  pbuffer escape_pstring_buffer;
  /* private buffer for get_loop_context_vars_value */
  char loopvarbuf[20]; /* for snprintf %d */
};

#endif /* _PPARAM_H */

/*
 *  Local Variables:
 *  mode: c
 *  End:
 */
