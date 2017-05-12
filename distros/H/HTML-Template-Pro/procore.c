#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "tmplpro.h"
#include "pconst.h"
#include "procore.h"
#include "prostate.h"
#include "provalue.h"
#include "tagstack.h"
#include "pbuffer.h"
#include "parse_expr.h"
#include "pparam.h"
#include "optint.h"
#include "proscope.h"
#include "proscope.inc"
#include "pstrutils.inc"
#include "pmiscdef.h" /*for snprintf */
/* for mmap_load_file & mmap_unload_file */
#include "loadfile.inc"
#include "loopvar.inc"

#define HTML_TEMPLATE_NO_TAG     -1
#define HTML_TEMPLATE_BAD_TAG     0
#define HTML_TEMPLATE_FIRST_TAG_USED 1
#define HTML_TEMPLATE_TAG_VAR     1
#define HTML_TEMPLATE_TAG_INCLUDE 2
#define HTML_TEMPLATE_TAG_LOOP    3
#define HTML_TEMPLATE_TAG_IF      4
#define HTML_TEMPLATE_TAG_ELSE    5
#define HTML_TEMPLATE_TAG_UNLESS  6
#define HTML_TEMPLATE_TAG_ELSIF   7
#define HTML_TEMPLATE_LAST_TAG_USED  7

static 
const char* const tagname[]={
    "Bad or unsupported tag", /* 0 */
    "var", "include", "loop", "if", "else", "unless", "elsif"
};

static 
const char* const TAGNAME[]={
    "Bad or unsupported tag", /* 0 */
    "VAR", "INCLUDE", "LOOP", "IF", "ELSE", "UNLESS", "ELSIF"
};

static int debuglevel=0;

#define TAG_OPT_NAME 0
#define TAG_OPT_EXPR 1
#define TAG_OPT_ESCAPE 2
#define TAG_OPT_DEFAULT 3
#define MIN_TAG_OPT 0
#define MAX_TAG_OPT 3

static const char* const tagopt[]={"name", "expr", "escape", "default" };
static const char* const TAGOPT[]={"NAME", "EXPR", "ESCAPE", "DEFAULT" };

#include "prostate.inc"
#include "tags.inc"

static const char const tag_can_be_closed[]={
  1 /*Bad or unsupported tag*/,
  0 /*VAR*/,
  0 /*INCLUDE*/,
  1 /*LOOP*/,
  1 /*IF*/,
  0 /*ELSE*/,
  1 /*UNLESS*/,
  1 /*ELSIF*/,
  0 /**/,
};

static const char const tag_has_opt[][6]={
  /* "name", "expr", "escape", "default", todo, todo */

  { 0, 0, 0, 0, 0, 0 }, /*Bad or unsupported tag*/
  { 1, 1, 1, 1, 0, 0 }, /*VAR*/
  { 1, 1, 0, 1, 0, 0 }, /*INCLUDE*/
  { 1, 0, 0, 0, 0, 0 }, /*LOOP*/
  { 1, 1, 0, 0, 0, 0 }, /*IF*/
  { 0, 0, 0, 0, 0, 0 }, /*ELSE*/
  { 1, 1, 0, 0, 0, 0 }, /*UNLESS*/
  { 1, 1, 0, 0, 0, 0 }, /*ELSIF*/
  { 0, 0, 0, 0, 0, 0 }, /**/
};

typedef void (*tag_handler_func)(struct tmplpro_state *state, const PSTRING* const TagOptVal);

static const tag_handler_func const output_closetag_handler[]={
  tag_handler_unknown,	/*Bad or unsupported tag*/
  tag_handler_unknown,	/*VAR*/
  tag_handler_unknown,	/*INCLUDE*/
  tag_handler_closeloop,	/*LOOP*/
  tag_handler_closeif,	/*IF*/
  tag_handler_unknown,	/*ELSE*/
  tag_handler_closeunless,	/*UNLESS*/
  tag_handler_unknown,	/*ELSIF*/
  tag_handler_unknown,	/**/
};
static const tag_handler_func const output_opentag_handler[]={
  tag_handler_unknown,	/*Bad or unsupported tag*/
  tag_handler_var,	/*VAR*/
  tag_handler_include,	/*INCLUDE*/
  tag_handler_loop,	/*LOOP*/
  tag_handler_if,	/*IF*/
  tag_handler_else,	/*ELSE*/
  tag_handler_unless,	/*UNLESS*/
  tag_handler_elsif,	/*ELSIF*/
  tag_handler_unknown,	/**/
};

static 
int 
is_string(struct tmplpro_state *state, const char* pattern,const char* PATTERN)
{
  const char* cur_pos=state->cur_pos;
  register const char* const next_to_end = state->next_to_end;
  while (*pattern && cur_pos<next_to_end) {
    if (*pattern == *cur_pos || *PATTERN == *cur_pos) {
      pattern++;
      PATTERN++;
      cur_pos++;
    } else {
      return 0;
    }
  }
  if (cur_pos>=next_to_end) return 0;
  state->cur_pos=cur_pos;
  return 1;
}

static 
INLINE 
void 
jump_over_space(struct tmplpro_state *state)
{
  register const char* const next_to_end = state->next_to_end;
  while (isspace(*(state->cur_pos)) && state->cur_pos<next_to_end) {state->cur_pos++;};
}

static 
INLINE
void 
jump_to_char(struct tmplpro_state *state, char c)
{
  register const char* const next_to_end = state->next_to_end;
  while (c!=*(state->cur_pos) && state->cur_pos<next_to_end) {state->cur_pos++;};
}

static 
PSTRING 
read_tag_parameter_value (struct tmplpro_state *state)
{
  PSTRING modifier_value;
  char cur_char;
  char quote_char=0;
  register const char* cur_pos;
  const char* const next_to_end=state->next_to_end;
  jump_over_space(state);
  cur_pos=state->cur_pos;
  cur_char=*cur_pos;
  if (('"'==cur_char) || ('\''==cur_char)) {
    quote_char=*cur_pos;
    cur_pos++;
  }
  modifier_value.begin=cur_pos;
  cur_char=*cur_pos;
  if (quote_char) {
    while (quote_char!=cur_char 
#ifdef COMPAT_ON_BROKEN_QUOTE
/* compatibility mode; HTML::Template doesn't allow '>' inside quotes */
	   && ('>' != quote_char)
#endif
	   && cur_pos<next_to_end) {
      cur_pos++;
      cur_char=*cur_pos;
    }
  } else {
    while ('>'!=cur_char && ! isspace(cur_char) && cur_pos<next_to_end) {
      cur_pos++;
      cur_char=*cur_pos;
    }
  }
  if (cur_pos>=next_to_end) {
    log_state(state,TMPL_LOG_ERROR,"quote char %c at pos " MOD_TD " is not terminated\n",
	     quote_char,TO_PTRDIFF_T(state->cur_pos - state->top));
    modifier_value.endnext=modifier_value.begin;
    jump_over_space(state);
    return modifier_value;
  }
  modifier_value.endnext=cur_pos;
  if (quote_char) {
    if (quote_char==*cur_pos) {
      cur_pos++;
    } else {
      log_state(state,TMPL_LOG_ERROR,"found %c instead of end quote %c at pos " MOD_TD "\n",
	       *cur_pos,quote_char,TO_PTRDIFF_T(cur_pos - state->top));
    }
  }
  state->cur_pos=cur_pos;
  /* if (debuglevel) log_state(state,TMPL_LOG_DEBUG2," at pos " MOD_TD "",TO_PTRDIFF_T(state->cur_pos-state->top)); */
  jump_over_space(state);
  return modifier_value;
}

static 
int 
try_tag_parameter (struct tmplpro_state *state,const char *modifier,const char *MODIFIER)
{
  const char* const initial_pos=state->cur_pos;
  jump_over_space(state);
  if (is_string(state, modifier, MODIFIER)) {
    jump_over_space(state);
    if ('='==*(state->cur_pos)) {
      state->cur_pos++;
      jump_over_space(state);
      return 1;
    }
  }
  state->cur_pos=initial_pos;
  return 0;
}

static 
void 
try_tmpl_var_options (struct tmplpro_state *state, int tag_type, PSTRING* TagOptVal)
{
  int i;
  int opt_found = 1;
  /* reading parameter */
  while (opt_found) {
    int found_in_loop=0;
    for (i=MIN_TAG_OPT; i<=MAX_TAG_OPT; i++) {
      if (
	  /* we will complain about syntax errors later;
	     tag_has_opt[tag_type][i] && */
	  try_tag_parameter(state, tagopt[i], TAGOPT[i])) {
	TagOptVal[i] = read_tag_parameter_value(state);
	found_in_loop=1;
	if (debuglevel) log_state(state,TMPL_LOG_DEBUG,"in tag %s: found option %s=%.*s\n", TAGNAME[tag_type], TAGOPT[i],(int)(TagOptVal[i].endnext-TagOptVal[i].begin),TagOptVal[i].begin);
      }
    }
    if (!found_in_loop) opt_found = 0;
  }
}

static 
void 
process_tmpl_tag(struct tmplpro_state *state)
{
  const int is_tag_closed=state->is_tag_closed;

  int tag_type=HTML_TEMPLATE_BAD_TAG;
  PSTRING TagOptVal[MAX_TAG_OPT+1];

  int i;
  for (i=MIN_TAG_OPT; i<=MAX_TAG_OPT; i++) {
    TagOptVal[i].begin = NULL;
    TagOptVal[i].endnext = NULL;
  }

  for (i=HTML_TEMPLATE_FIRST_TAG_USED; i<=HTML_TEMPLATE_LAST_TAG_USED; i++) {
    if (is_string(state, tagname[i], TAGNAME[i])) {
      tag_type=i;
      state->tag=tag_type;
      if (debuglevel) {
	if (is_tag_closed) {
	  tmpl_log(TMPL_LOG_DEBUG, "found </TMPL_%s> at pos " MOD_TD "\n",TAGNAME[i], TO_PTRDIFF_T(state->cur_pos-state->top));
	} else {
	  tmpl_log(TMPL_LOG_DEBUG, "found <TMPL_%s> at pos " MOD_TD "\n",TAGNAME[i], TO_PTRDIFF_T(state->cur_pos-state->top));
	}
      }
      break;
    }
  }
  if (HTML_TEMPLATE_BAD_TAG==tag_type) {
    state->param->found_syntax_error=1;
    log_state(state,TMPL_LOG_ERROR, "found bad/unsupported tag at pos " MOD_TD "\n", TO_PTRDIFF_T(state->cur_pos-state->top));
    /* TODO: flush its data ---  */
    state->cur_pos++;
    return;
  }

  if (is_tag_closed && !tag_can_be_closed[tag_type]) {
    state->param->found_syntax_error=1;
    log_state(state,TMPL_LOG_ERROR, "incorrect closed tag </TMPL_%s> at pos " MOD_TD "\n",
	     TAGNAME[tag_type], TO_PTRDIFF_T(state->cur_pos-state->top));
  }

  if (is_tag_closed || ! tag_has_opt[tag_type][TAG_OPT_NAME]) {
    /* tag has no parameter */
#ifdef COMPAT_ALLOW_NAME_IN_CLOSING_TAG
    /* requested compatibility mode 
       to try reading NAME inside </closing tags NAME="  ">
       (useful for comments?) */
    try_tag_parameter(state, tagopt[TAG_OPT_NAME], TAGOPT[TAG_OPT_NAME]);
    read_tag_parameter_value(state);
#endif
  } else {
    try_tmpl_var_options(state, tag_type, TagOptVal);
    /* suport for short syntax */
    if (TagOptVal[TAG_OPT_NAME].begin == NULL && 
	tag_has_opt[tag_type][TAG_OPT_NAME] && 
	(!tag_has_opt[tag_type][TAG_OPT_EXPR] || TagOptVal[TAG_OPT_EXPR].begin == NULL )) {
      TagOptVal[TAG_OPT_NAME]=read_tag_parameter_value(state);
      try_tmpl_var_options(state, tag_type, TagOptVal);
    }

    if (TagOptVal[TAG_OPT_NAME].begin == NULL && 
	tag_has_opt[tag_type][TAG_OPT_NAME] && 
	(!tag_has_opt[tag_type][TAG_OPT_EXPR] || TagOptVal[TAG_OPT_EXPR].begin == NULL )) {
      state->param->found_syntax_error=1;
      log_state(state,TMPL_LOG_ERROR,"NAME or EXPR is required for TMPL_%s\n", TAGNAME[tag_type]);
    }
    for (i=MIN_TAG_OPT; i<=MAX_TAG_OPT; i++) {
      if (TagOptVal[i].begin!=NULL && ! tag_has_opt[tag_type][i]) {
	state->param->found_syntax_error=1;
	log_state(state,TMPL_LOG_ERROR,"TMPL_%s does not support %s= option\n", TAGNAME[tag_type], TAGOPT[i]);
      }
    }
  }

  if (state->is_tag_commented) {
    /* try read comment end */
    /* jump_over_space(state); it should be already done :( */
    jump_over_space(state);
    if (state->cur_pos<state->next_to_end-2 && '-'==*(state->cur_pos) && '-'==*(state->cur_pos+1)) {
      state->cur_pos+=2;
    }
  }
  /* template tags could also be decorated as xml <tmpl_TAG /> */
  if (!is_tag_closed && '/'==*(state->cur_pos)) state->cur_pos++;

  if ('>'==*(state->cur_pos)) {
    state->cur_pos++;
  } else {
    state->param->found_syntax_error=1;
    log_state(state,TMPL_LOG_ERROR,"end tag:found %c instead of > at pos " MOD_TD "\n",
	     *state->cur_pos, TO_PTRDIFF_T(state->cur_pos-state->top));
  }
  /* flush run chars (if in SHOW mode) */
  if (state->is_visible) {
    (state->param->WriterFuncPtr)(state->param->ext_writer_state,state->last_processed_pos,state->tag_start);
    state->last_processed_pos=state->cur_pos;
  }
  if (is_tag_closed) {
    output_closetag_handler[tag_type](state,TagOptVal);
  } else {
    output_opentag_handler[tag_type](state,TagOptVal);
  }
}


/* max offset to ensure we are not out of file when try <!--/  */
#define TAG_WIDTH_OFFSET 4
static 
void 
process_state (struct tmplpro_state * state)
{
  static const char* const metatag="tmpl_";
  static const char* const METATAG="TMPL_";
  int is_tag_closed;
  int is_tag_commented;
  register const char* const last_safe_pos=state->next_to_end-TAG_WIDTH_OFFSET;
  /* constructor */
  tagstack_init(&(state->tag_stack));
  /* magic; 256 > 50 (50 is min.required for double to string conversion */
  pbuffer_init_as(&(state->expr_left_pbuffer), 256); 
  pbuffer_init_as(&(state->expr_right_pbuffer), 256);

  if (debuglevel) tmpl_log(TMPL_LOG_DEBUG,"process_state:initiated at scope stack depth = %d\n", 
			   curScopeLevel(&state->param->var_scope_stack));

  while (state->cur_pos < last_safe_pos) {
    register const char* cur_pos=state->cur_pos;
    while ('<'!=*(cur_pos++)) {
      if (cur_pos >= last_safe_pos) {
	goto exit_mainloop;
      }
    };
    state->tag_start=cur_pos-1;
    is_tag_closed=0;
    is_tag_commented=0;
    state->cur_pos=cur_pos;
    if (('!'==*(cur_pos)) && ('-'==*(cur_pos+1)) && ('-'==*(cur_pos+2))) {
      state->cur_pos+=3;
      jump_over_space(state);
      is_tag_commented=1;
    }
    if ('/'==*(state->cur_pos)) {
      state->cur_pos++;
      is_tag_closed=1;
    }
    if (is_string(state,metatag,METATAG)) {
      state->is_tag_commented=is_tag_commented;
      state->is_tag_closed=is_tag_closed;
      process_tmpl_tag(state);
    }
  }
  exit_mainloop:;
  (state->param->WriterFuncPtr)(state->param->ext_writer_state,state->last_processed_pos,state->next_to_end);

  /* destructor */
  pbuffer_free(&(state->expr_right_pbuffer));
  pbuffer_free(&(state->expr_left_pbuffer));
  tagstack_free(&(state->tag_stack));
  if (debuglevel) tmpl_log(TMPL_LOG_DEBUG,"process_state:finished\n");
}

static 
void 
init_state (struct tmplpro_state *state, struct tmplpro_param *param)
{
  /* initializing state */
  state->param=param;
  state->last_processed_pos=state->top;
  state->cur_pos=state->top;
  state->tag=HTML_TEMPLATE_NO_TAG;
  state->is_visible=1;
}

static
int 
tmplpro_exec_tmpl_filename (struct tmplpro_param *param, const char* filename)
{
  struct tmplpro_state state;
  int mmapstatus;
  PSTRING memarea;
  int retval = 0;
  const char* saved_masterpath;
  /* 
   * param->masterpath is path to upper level template 
   * (or NULL in toplevel) which called <include filename>.
   * we use it to calculate filepath for filename.
   * Then filename becames upper level template for its <include>.
   */
  const char* filepath=(param->FindFileFuncPtr)(param->ext_findfile_state,filename, param->masterpath);
  if (NULL==filepath) return ERR_PRO_FILE_NOT_FOUND;
  /* filepath should be alive for every nested template */
  filepath = strdup(filepath);
  if (NULL==filepath) return ERR_PRO_NOT_ENOUGH_MEMORY;
  saved_masterpath=param->masterpath; /* saving current file name */
  param->masterpath=filepath;
  if (param->filters) memarea=(param->LoadFileFuncPtr)(param->ext_filter_state,filepath);
  else memarea=mmap_load_file(filepath);
  if (memarea.begin == NULL) {
    retval = ERR_PRO_CANT_OPEN_FILE;
    goto cleanup_filepath;
  }
  state.top =memarea.begin;
  state.next_to_end=memarea.endnext;
  if (memarea.begin < memarea.endnext) {
    /* to avoid crash with empty file */
    init_state(&state,param);
    if (debuglevel) log_state(&state,TMPL_LOG_DEBUG, "exec_tmpl: loading %s\n",filename);
    process_state(&state);
  }
  /* destroying */
  if (param->filters) mmapstatus=(param->UnloadFileFuncPtr)(param->ext_filter_state,memarea);
  else mmapstatus=mmap_unload_file(memarea);
 cleanup_filepath:
  if (filepath!=NULL) free((void*) filepath);
  param->masterpath=saved_masterpath;
  return retval;
}

static
int 
tmplpro_exec_tmpl_scalarref (struct tmplpro_param *param, PSTRING memarea)
{
  struct tmplpro_state state;
  const char* saved_masterpath=param->masterpath; /* saving current file name */
  param->masterpath=NULL; /* no upper file */
  state.top = memarea.begin;
  state.next_to_end=memarea.endnext;
  if (memarea.begin != memarea.endnext) {
    init_state(&state,param);
    process_state(&state);
  }
  /* exit cleanup code */
  param->masterpath=saved_masterpath;
  return 0;
}

#include "builtin_findfile.inc"
#include "callback_stubs.inc"

API_IMPL 
int 
APICALL
tmplpro_exec_tmpl (struct tmplpro_param *param)
{
  int exitcode=0;
  param->htp_errno=0;
  if (param->GetAbstractValFuncPtr==NULL ||
       param->AbstractVal2pstringFuncPtr==NULL ||
       param->AbstractVal2abstractArrayFuncPtr==NULL ||
       /*param->GetAbstractArrayLengthFuncPtr==NULL ||*/
       param->GetAbstractMapFuncPtr==NULL ||
      (param->IsExprUserfncFuncPtr!=NULL && param->IsExprUserfncFuncPtr != stub_is_expr_userfnc_func &&
       (param->InitExprArglistFuncPtr==NULL ||
	param->PushExprArglistFuncPtr==NULL ||
	param->FreeExprArglistFuncPtr==NULL ||
	param->CallExprUserfncFuncPtr==NULL))
      )
    {
      tmpl_log(TMPL_LOG_ERROR,"tmplpro_exec_tmpl: required callbacks are missing:");
      if (param->GetAbstractValFuncPtr==NULL) tmpl_log(TMPL_LOG_ERROR," GetAbstractValFuncPtr");
      if (param->AbstractVal2pstringFuncPtr==NULL) tmpl_log(TMPL_LOG_ERROR," AbstractVal2pstringFuncPtr");
      if (param->AbstractVal2abstractArrayFuncPtr==NULL) tmpl_log(TMPL_LOG_ERROR," AbstractVal2abstractArrayFuncPtr");
      if (param->GetAbstractMapFuncPtr==NULL) tmpl_log(TMPL_LOG_ERROR," GetAbstractMapFuncPtr");
      if ((param->IsExprUserfncFuncPtr!=NULL &&
	   (param->InitExprArglistFuncPtr==NULL ||
	    param->PushExprArglistFuncPtr==NULL ||
	    param->FreeExprArglistFuncPtr==NULL ||
	    param->CallExprUserfncFuncPtr==NULL))
	  ) tmpl_log(TMPL_LOG_ERROR," one of the Expr callbacks");
      tmpl_log(TMPL_LOG_ERROR,". The library is not initialized properly.\n");
      return ERR_PRO_INVALID_ARGUMENT;
  }
  if (param->filters &&
      (param->LoadFileFuncPtr==NULL ||
       param->UnloadFileFuncPtr==NULL)) {
    tmpl_log(TMPL_LOG_ERROR,"tmplpro_exec_tmpl: filters is set but filter callbacks are missing.\n");
  }
  /* set up stabs */
  if (NULL==param->WriterFuncPtr) param->WriterFuncPtr = stub_write_chars_to_stdout;
  if (NULL==param->ext_findfile_state) param->ext_findfile_state = param;
  if (NULL==param->FindFileFuncPtr) {
    param->FindFileFuncPtr = stub_find_file_func;
    param->ext_findfile_state = param;
    /*pbuffer_init(&param->builtin_findfile_buffer);*/
  }
  if (NULL==param->IsExprUserfncFuncPtr) param->IsExprUserfncFuncPtr = stub_is_expr_userfnc_func;
  if (NULL==param->LoadFileFuncPtr) param->LoadFileFuncPtr = stub_load_file_func;
  if (NULL==param->UnloadFileFuncPtr) param->UnloadFileFuncPtr = stub_unload_file_func;
  if (NULL==param->GetAbstractArrayLengthFuncPtr) param->GetAbstractArrayLengthFuncPtr = stub_get_ABSTRACT_ARRAY_length_func;

  Scope_reset(&param->var_scope_stack, param->param_map_count);
  /* reset other internals */
  param->cur_includes=0; /* internal counter of include depth */
  param->found_syntax_error=0;
  /*masterpath=NULL;*/


  /* TODO: hackaround;*/
  debuglevel=param->debug;
  tmpl_log_set_level(debuglevel);

  if (param->scalarref.begin) exitcode = tmplpro_exec_tmpl_scalarref(param, param->scalarref);
  else if (param->filename) exitcode = tmplpro_exec_tmpl_filename(param, param->filename);
  else {
    tmpl_log(TMPL_LOG_ERROR,"tmplpro_exec_tmpl: neither scalarref nor filename was specified.\n");
    exitcode = ERR_PRO_INVALID_ARGUMENT;
  }
  if (param->strict && param->found_syntax_error && 0==exitcode) exitcode = ERR_PRO_TEMPLATE_SYNTAX_ERROR;
  param->htp_errno=exitcode;
  return exitcode;
}

API_IMPL
PSTRING
APICALL
tmplpro_tmpl2pstring (struct tmplpro_param *param, int *retvalptr)
{
  int exitcode;
  PSTRING retval;
  struct builtin_writer_state state;
  writer_functype save_writer_func = param->WriterFuncPtr;
  ABSTRACT_WRITER* save_writer_state = param->ext_writer_state;
  param->WriterFuncPtr = stub_write_chars_to_pbuffer;
  param->ext_writer_state = &state;
  state.bufptr=&param->builtin_tmpl2string_buffer;
  pbuffer_resize(state.bufptr, 4000);
  state.size = 0;
  exitcode = tmplpro_exec_tmpl (param);
  param->WriterFuncPtr = save_writer_func;
  param->ext_writer_state = save_writer_state;
  if (NULL!=retvalptr) *retvalptr=exitcode;
  retval.begin = pbuffer_string(state.bufptr);
  retval.endnext = retval.begin+state.size;
  *((char*) retval.endnext)='\0';
  return retval;
}

API_IMPL 
void 
APICALL
tmplpro_clear_option_param_map(struct tmplpro_param *param)
{
  param->param_map_count=0;
  Scope_reset(&param->var_scope_stack,param->param_map_count);
}

API_IMPL 
int 
APICALL
tmplpro_push_option_param_map(struct tmplpro_param *param, ABSTRACT_MAP* map, EXPR_int64 flags)
{
  pushScopeMap(&param->var_scope_stack, map, (int) flags);
  return ++(param->param_map_count);
}

API_IMPL 
int 
APICALL
tmplpro_count_option_param_map(struct tmplpro_param *param)
{
  return param->param_map_count;
}


API_IMPL 
void 
APICALL
tmplpro_procore_init(void)
{
}

API_IMPL 
void 
APICALL
tmplpro_procore_done(void)
{
}

/* internal initialization of struct tmplpro_param */
API_IMPL 
struct tmplpro_param* 
APICALL
tmplpro_param_init(void)
{
  struct tmplpro_param* param=(struct tmplpro_param*) malloc (sizeof(struct tmplpro_param));
  if (param==NULL) return param;
  /* filling initial struct tmplpro_param with 0 */
  memset (param, 0, sizeof(struct tmplpro_param));
  /* current level of inclusion */
  /* param->cur_includes=0; */
  /* not to use external file loader */
  /* param->filters=0;
     param->default_escape=HTML_TEMPLATE_OPT_ESCAPE_NO;
     param->masterpath=NULL; *//* we are not included by something *//*
     param->expr_func_map=NULL;
     param->expr_func_arglist=NULL;
  */
  _reset_int_options_set_nonzero_defaults(param);
  Scope_init(&param->var_scope_stack);
  /* no need for them due to memset 0
  pbuffer_preinit(&param->builtin_findfile_buffer);
  pbuffer_preinit(&param->builtin_tmpl2string_buffer);
  pbuffer_preinit(&param->lowercase_varname_buffer);
  pbuffer_preinit(&param->uppercase_varname_buffer);
  pbuffer_preinit(&param->escape_pstring_buffer);
  */
  return param;
}

API_IMPL 
void
APICALL
tmplpro_param_free(struct tmplpro_param* param)
{
  pbuffer_free(&param->builtin_findfile_buffer);
  pbuffer_free(&param->builtin_tmpl2string_buffer);
  pbuffer_free(&param->lowercase_varname_buffer);
  pbuffer_free(&param->uppercase_varname_buffer);
  pbuffer_free(&param->escape_pstring_buffer);
  Scope_free(&param->var_scope_stack);
  free(param);
}

API_IMPL 
int
APICALL
tmplpro_errno(struct tmplpro_param* param)
{
  return param->htp_errno;
}

API_IMPL 
const char*
APICALL
tmplpro_errmsg(struct tmplpro_param* param)
{
  return  errlist[param->htp_errno];
}

API_IMPL 
int
APICALL
tmplpro_set_log_file(struct tmplpro_param* param, const char* logfilename)
{
  FILE *file_p;
  if (NULL==logfilename) {
    if (tmpl_log_stream!=NULL) {
      fclose(tmpl_log_stream);
      tmpl_log_stream=NULL;
    }
    tmpl_log_set_callback(tmpl_log_default_callback);
    return 0;
  }
  file_p = fopen(logfilename, "a");
  if (!file_p) {
    tmpl_log(TMPL_LOG_ERROR,"tmplpro_set_log_file: can't create log file [%s]\n",logfilename);
    return ERR_PRO_FILE_NOT_FOUND;
  } else {
    if (tmpl_log_stream!=NULL) fclose(tmpl_log_stream);
    tmpl_log_stream=file_p;
    tmpl_log_set_callback(tmpl_log_stream_callback);
    return 0;
  }
}

API_IMPL 
size_t
APICALL
tmplpro_param_allocated_memory_info(struct tmplpro_param* param)
{
  return 0L +
    pbuffer_size(&param->builtin_findfile_buffer) +
    pbuffer_size(&param->builtin_tmpl2string_buffer) +
    pbuffer_size(&param->lowercase_varname_buffer) +
    pbuffer_size(&param->uppercase_varname_buffer) +
    pbuffer_size(&param->escape_pstring_buffer) +
    (1+curScopeLevel(&param->var_scope_stack)) * sizeof(struct scope_stack);
}

#include "tagstack.inc"

/*
 * Local Variables:
 * mode: c 
 * End: 
 */
