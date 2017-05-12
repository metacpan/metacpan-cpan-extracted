static
int get_escape_option(struct tmplpro_state *state, PSTRING OptEscape)
{
  /* int escape = HTML_TEMPLATE_OPT_ESCAPE_NO; */
  int escape = state->param->default_escape;
  if (OptEscape.begin<OptEscape.endnext) {
    switch (*OptEscape.begin) {
    case '1': case 'H': case 'h': 	/* HTML*/
      escape = HTML_TEMPLATE_OPT_ESCAPE_HTML;
      break;
    case 'U': case 'u': 		/* URL */
      escape = HTML_TEMPLATE_OPT_ESCAPE_URL;
      break;
    case 'J': case 'j':		/* JS  */
      escape = HTML_TEMPLATE_OPT_ESCAPE_JS;
      break;
    case '0': case 'N': case 'n': /* 0 or NONE */
      escape = HTML_TEMPLATE_OPT_ESCAPE_NO;
      break;
    default:
      state->param->found_syntax_error=1;
      log_state(state,TMPL_LOG_ERROR, " unsupported value of ESCAPE=%.*s\n",(int)(OptEscape.endnext-OptEscape.begin),OptEscape.begin);
    }
  }
  return escape;
}

static
void init_tmpl_var_case_buffers (struct tmplpro_param *param) {
  param->lowercase_varname.begin = NULL;
  param->lowercase_varname.endnext = NULL;
  param->uppercase_varname.begin = NULL;
  param->uppercase_varname.endnext = NULL;
}

static 
ABSTRACT_VALUE* get_abstract_value (struct tmplpro_param *param, int scope_level, PSTRING name) {
  ABSTRACT_VALUE* retval = NULL;
  ABSTRACT_MAP* param_HV = getScope(&param->var_scope_stack, scope_level)->param_HV;
  ABSTRACT_DATASTATE* data_state = param->ext_data_state;
  get_ABSTRACT_VALUE_functype getval_func = param->GetAbstractValFuncPtr;
  int tmpl_var_case = param->tmpl_var_case;
  if ((tmpl_var_case & ASK_NAME_MASK) == ASK_NAME_DEFAULT
      || tmpl_var_case & ASK_NAME_AS_IS) {
    retval = getval_func(data_state, param_HV, name);
    if (retval != NULL) return retval;
  }
  if (tmpl_var_case & ASK_NAME_LOWERCASE) {
    if (param->lowercase_varname.begin == NULL) {
      param->lowercase_varname=lowercase_pstring(&param->lowercase_varname_buffer, name);
    }
    retval = getval_func(data_state, param_HV, param->lowercase_varname);
    if (retval != NULL) return retval;
  }
  if (tmpl_var_case & ASK_NAME_UPPERCASE) {
    if (param->uppercase_varname.begin == NULL) {
      param->uppercase_varname=uppercase_pstring(&param->uppercase_varname_buffer, name);
    }
    retval = getval_func(data_state, param_HV, param->uppercase_varname);
    if (retval != NULL) return retval;
  }
  return retval;
}

static
ABSTRACT_VALUE* walk_through_nested_loops (struct tmplpro_param *param, PSTRING name) {
  int CurLevel;
  ABSTRACT_VALUE* valptr;
  init_tmpl_var_case_buffers (param);
  /* Shigeki Morimoto path_like_variable_scope extension */
  if (param->path_like_variable_scope) {
    if(*(name.begin) == '/' || strncmp(name.begin, "../", 3) == 0){
      PSTRING tmp_name;
      int GoalHash;
      if(*(name.begin) == '/'){
	tmp_name.begin   = name.begin+1; // skip '/'
	tmp_name.endnext = name.endnext;
	GoalHash = 0;
      }else{
	tmp_name.begin   = name.begin;
	tmp_name.endnext = name.endnext;
	GoalHash = curScopeLevel(&param->var_scope_stack);
	while(strncmp(tmp_name.begin, "../", 3) == 0){
	  tmp_name.begin   = tmp_name.begin + 3; // skip '../'
	  GoalHash --;
	}
      }
      return get_abstract_value(param, GoalHash, tmp_name);
    }
  }
  /* end Shigeki Morimoto path_like_variable_scope extension */

  CurLevel = curScopeLevel(&param->var_scope_stack);
  valptr = get_abstract_value(param, CurLevel, name);
  if (valptr) return valptr;
  /* optional strict scoping; does it have much sence?
    if ((STRICT_SCOPING==param->global_vars)) return NULL;
  */

  /* loop-bounded scoping; */
  if (0==param->global_vars) {
    while (isScopeMap(getScope(&param->var_scope_stack,CurLevel)) && --CurLevel>=0) {
      valptr = get_abstract_value(param, CurLevel, name);
      if (valptr!=NULL) return valptr;
    }
    return NULL;
  }

  while (--CurLevel>=0) {
    valptr = get_abstract_value(param, CurLevel, name);
    if (valptr!=NULL) return valptr;
  }
  return NULL;
}

TMPLPRO_LOCAL
PSTRING _get_variable_value (struct tmplpro_param *param, PSTRING name) {
  PSTRING varvalue ={NULL, NULL};
  ABSTRACT_VALUE* abstrval;
  if (param->loop_context_vars) {
    varvalue=get_loop_context_vars_value(param, name);
  }
  if (varvalue.begin==NULL) {
    abstrval=walk_through_nested_loops(param, name);
    if (abstrval!=NULL) varvalue=(param->AbstractVal2pstringFuncPtr)(param->ext_data_state, abstrval);
  }
  if (debuglevel>=TMPL_LOG_DEBUG2) {
    if (name.begin!=NULL) {
      tmpl_log(TMPL_LOG_DEBUG2,"_get_variable_value: name = %.*s ",(int)(name.endnext-name.begin),name.begin);
    } else {
      tmpl_log(TMPL_LOG_DEBUG2,"_get_variable_value: name = NULL ");
    }
    if (varvalue.begin!=NULL) {
      tmpl_log(TMPL_LOG_DEBUG2,"value = %.*s\n",(int)(varvalue.endnext-varvalue.begin),varvalue.begin);
    } else {
      tmpl_log(TMPL_LOG_DEBUG2,"value = UNDEF\n");
    }
  }
  return varvalue;
}

static
PSTRING get_variable_option (struct tmplpro_state *state, const PSTRING* const TagOptVal) {
  PSTRING varvalue ={NULL, NULL};
  PSTRING defvalue = TagOptVal[TAG_OPT_DEFAULT];
  if (TagOptVal[TAG_OPT_EXPR].begin!=NULL) {
    varvalue=parse_expr(TagOptVal[TAG_OPT_EXPR], state);
  } else {
    varvalue=_get_variable_value(state->param, TagOptVal[TAG_OPT_NAME]);
  }
  if (varvalue.begin==NULL) {
    if (defvalue.begin!=defvalue.endnext) {
      varvalue=defvalue;
    }
  }
  return varvalue;
}


static 
void 
tag_handler_var (struct tmplpro_state *state, const PSTRING* const TagOptVal)
{
  PSTRING varvalue;
  int escapeopt;
  /*
  if (debuglevel>=TMPL_LOG_DEBUG2) {
    log_state(state,TMPL_LOG_DEBUG2,"Entered tag_handler_var\n");
    }*/
  if (! state->is_visible) return;
  varvalue = get_variable_option(state, TagOptVal);
  escapeopt = get_escape_option(state,TagOptVal[TAG_OPT_ESCAPE]);
  if (varvalue.begin==NULL) return;

  if (escapeopt!=HTML_TEMPLATE_OPT_ESCAPE_NO) {
    varvalue=escape_pstring(&state->param->escape_pstring_buffer, varvalue, escapeopt);
  }
  (state->param->WriterFuncPtr)(state->param->ext_writer_state,varvalue.begin,varvalue.endnext);
}

static 
void 
tag_handler_include (struct tmplpro_state *state, const PSTRING* const TagOptVal)
{
  struct tmplpro_param* param;
  char* filename;
  int x;
  PSTRING varvalue;
  PSTRING defvalue;

  if (! state->is_visible) return;
  param=state->param;
  if (param->no_includes) {
    log_state(state,TMPL_LOG_ERROR, "HTML::Template::Pro : Illegal attempt to use TMPL_INCLUDE in template file : (no_includes => 1)\n");
    return;
  }
  if (param->max_includes && param->max_includes < param->cur_includes) {
    log_state(state,TMPL_LOG_INFO, "HTML::Template::Pro : TMPL_INCLUDE: max_includes exceeded.\n");
    return;
  }
  param->cur_includes++;

  varvalue=TagOptVal[TAG_OPT_NAME];
  defvalue = TagOptVal[TAG_OPT_DEFAULT];

  if (TagOptVal[TAG_OPT_EXPR].begin!=NULL) {
    varvalue=parse_expr(TagOptVal[TAG_OPT_EXPR], state);
  };
  if (varvalue.begin==varvalue.endnext && defvalue.begin!=defvalue.endnext) varvalue=defvalue;
  /* pstrdup */
  {
    const long len = varvalue.endnext-varvalue.begin;
    filename =(char*) malloc(len+1);
    for (x=0;x<len;x++) {
      *(filename+x)=*(varvalue.begin+x);
    }
    *(filename+len)=0;
  }
  /* end pstrdup */
  tmplpro_exec_tmpl_filename (param,filename);
  free (filename);
  param->cur_includes--; 
  return;
}

static 
int 
is_var_true(struct tmplpro_state *state, const PSTRING* const TagOptVal) 
{
  register int ifval=-1; /*not yet defined*/
  if (TagOptVal[TAG_OPT_EXPR].begin!=NULL) {
    /*
    if (debuglevel>=TMPL_LOG_DEBUG2) {
      tmpl_log(TMPL_LOG_DEBUG2,"is_var_true: expr = %.*s\n",(int)(TagOptVal[TAG_OPT_EXPR].endnext-TagOptVal[TAG_OPT_EXPR].begin),TagOptVal[TAG_OPT_EXPR].begin);
      }*/
    ifval=is_pstring_true(parse_expr(TagOptVal[TAG_OPT_EXPR], state));
  } else
    if (state->param->loop_context_vars) {
      PSTRING loop_var=get_loop_context_vars_value(state->param, TagOptVal[TAG_OPT_NAME]);
      if (loop_var.begin!=NULL) {
	ifval=is_pstring_true(loop_var);
      }
    }
  if (ifval==-1) {
    is_ABSTRACT_VALUE_true_functype userSuppliedIsTrueFunc;
    ABSTRACT_VALUE* abstrval=walk_through_nested_loops(state->param, TagOptVal[TAG_OPT_NAME]);
    if (abstrval==NULL) return 0;
    userSuppliedIsTrueFunc = state->param->IsAbstractValTrueFuncPtr;
    if (userSuppliedIsTrueFunc!=NULL) {
      ifval=(userSuppliedIsTrueFunc)(state->param->ext_data_state, abstrval);
    } else {
      ifval=is_pstring_true((state->param->AbstractVal2pstringFuncPtr)(state->param->ext_data_state, abstrval));
    }
  }
  return ifval;
}

static 
void 
tag_handler_if (struct tmplpro_state *state, const PSTRING* const TagOptVal)
{
  struct tagstack_entry iftag;
  iftag.tag=HTML_TEMPLATE_TAG_IF;
  iftag.vcontext=state->is_visible;
  iftag.position=state->cur_pos; /* unused */
  /* state->is_visible && means that we do not evaluate variable in shadow */
  if (state->is_visible && is_var_true(state,TagOptVal)) {
    iftag.value=1;
    /* state->is_visible is not touched */
  } else {
    iftag.value=0;
    state->is_visible=0;
  }
  tagstack_push(&(state->tag_stack), iftag);
  if (debuglevel>=TMPL_LOG_DEBUG2) log_state(state,TMPL_LOG_DEBUG2,"tag_handler_if:visible context =%d value=%d ",iftag.vcontext,iftag.value);
}

static 
void 
tag_handler_unless (struct tmplpro_state *state, const PSTRING* const TagOptVal)
{
  struct tagstack_entry iftag;
  iftag.tag=HTML_TEMPLATE_TAG_UNLESS;
  iftag.vcontext=state->is_visible;
  iftag.position=state->cur_pos; /* unused */
  /* state->is_visible && means that we do not evaluate variable in shadow */
  if (state->is_visible && !is_var_true(state,TagOptVal)) {
    iftag.value=1;
    /* state->is_visible is not touched */
  } else {
    iftag.value=0;
    state->is_visible=0;
  }
  tagstack_push(&(state->tag_stack), iftag);
  if (debuglevel>=TMPL_LOG_DEBUG2) log_state(state,TMPL_LOG_DEBUG2,"tag_handler_unless:visible context =%d value=%d ",iftag.vcontext,iftag.value);
}

static 
INLINE
int
test_stack (int tag)
{
  //  return (tagstack_notempty(&(state->tag_stack)) && (tagstack_top(&(state->tag_stack))->tag==tag));
  return 1;
}

static 
void 
tag_stack_debug  (struct tmplpro_state *state, int stack_tag_type)
{
  if (stack_tag_type) {
    if (tagstack_notempty(&(state->tag_stack))) {
      struct tagstack_entry* iftag=tagstack_top(&(state->tag_stack));
      if (iftag->tag!=stack_tag_type) {
	log_state(state,TMPL_LOG_ERROR, "ERROR: tag mismatch with %s\n",TAGNAME[iftag->tag]);
      }
    } else {
      log_state(state,TMPL_LOG_ERROR, "ERROR: opening tag %s not found\n",TAGNAME[stack_tag_type]);
    }
  }
}

static 
struct tagstack_entry tagstack_smart_pop(struct tmplpro_state *state)
{
  int is_underflow=0;
  struct tagstack_entry curtag=tagstack_pop(&(state->tag_stack), &is_underflow);
  if (is_underflow) {
    log_state(state,TMPL_LOG_ERROR,"stack underflow:tag stack is empty. Cased by closing tag w/o matching opening tag.\n");
  }
  return curtag;
}

static
void 
tag_handler_closeif (struct tmplpro_state *state, const PSTRING* const TagOptVal)
{
  struct tagstack_entry iftag;
  if (! test_stack(HTML_TEMPLATE_TAG_IF)) {
    tag_stack_debug(state,HTML_TEMPLATE_TAG_IF);
    return;
  }
  iftag=tagstack_smart_pop(state);
  if (0==state->is_visible) state->last_processed_pos=state->cur_pos;
  state->is_visible=iftag.vcontext;
}

static 
void 
tag_handler_closeunless (struct tmplpro_state *state, const PSTRING* const TagOptVal)
{
  struct tagstack_entry iftag;
  if (! test_stack(HTML_TEMPLATE_TAG_UNLESS)) {
    tag_stack_debug(state,HTML_TEMPLATE_TAG_UNLESS);
    return;
  }
  iftag=tagstack_smart_pop(state);
  if (0==state->is_visible) state->last_processed_pos=state->cur_pos;
  state->is_visible=iftag.vcontext;
}

static 
void 
tag_handler_else (struct tmplpro_state *state, const PSTRING* const TagOptVal)
{
  struct tagstack_entry* iftag;
  if (! test_stack(HTML_TEMPLATE_TAG_IF) && 
      ! test_stack(HTML_TEMPLATE_TAG_UNLESS)) {
    tag_stack_debug(state,HTML_TEMPLATE_TAG_ELSE);
    return;
  }
  iftag=tagstack_top(&(state->tag_stack));
  if (0==state->is_visible) state->last_processed_pos=state->cur_pos;
  if (iftag->value) {
    state->is_visible=0;
  } else if (1==iftag->vcontext) {
    state->is_visible=1;
  }
  if (debuglevel>=TMPL_LOG_DEBUG2) log_state(state,TMPL_LOG_DEBUG2,"else:(pos " MOD_TD ") visible:context =%d, set to %d ",
			     TO_PTRDIFF_T(iftag->position - state->top),iftag->vcontext,state->is_visible);
}

static 
void 
tag_handler_elsif (struct tmplpro_state *state, const PSTRING* const TagOptVal)
{
  struct tagstack_entry *iftag;
  if (! test_stack(HTML_TEMPLATE_TAG_IF) && 
      ! test_stack(HTML_TEMPLATE_TAG_UNLESS)) {
    tag_stack_debug(state,HTML_TEMPLATE_TAG_ELSIF);
    return;
  }
  iftag=tagstack_top(&(state->tag_stack));
  if (0==state->is_visible) state->last_processed_pos=state->cur_pos;
  if (iftag->value) {
    state->is_visible=0;
  } else if (1==iftag->vcontext) {
    /* test only if vcontext==true; if the whole tag if..endif itself is invisible, skip the is_var_true test */
    /*TODO: it is reasonable to skip is_var_true test in if/unless too */
    if (is_var_true(state,TagOptVal)) {
      iftag->value=1;
      state->is_visible=1;
    } else {
      iftag->value=0;
      state->is_visible=0;
    }
  }
  if (debuglevel>=TMPL_LOG_DEBUG2) log_state(state,TMPL_LOG_DEBUG2,"elsif:(pos " MOD_TD ") visible:context =%d, set to %d ",
			     TO_PTRDIFF_T(iftag->position - state->top), iftag->vcontext, state->is_visible);
}

static 
int 
next_loop (struct tmplpro_state* state) {
#ifdef DEBUG
  log_state(state,TMPL_LOG_DEBUG2,"next_loop:before NextLoopFuncPtr\n");
#endif
  struct ProScopeEntry* currentScope = getCurrentScope(&state->param->var_scope_stack);
  if (!isScopeLoop(currentScope)) {
    log_state(state,TMPL_LOG_ERROR, "next_loop:at scope level %d: internal error - loop is null\n", curScopeLevel(&state->param->var_scope_stack));
    return 0;
  }
  if (++currentScope->loop < currentScope->loop_count || currentScope->loop_count< 0) {
    ABSTRACT_MAP* arrayvalptr=(state->param->GetAbstractMapFuncPtr)(state->param->ext_data_state, currentScope->loops_AV,currentScope->loop);
    if ((arrayvalptr!=NULL)) {
      currentScope->param_HV=arrayvalptr;
      return 1;
    } else {
      /* either undefined loop ended normally or defined loop ended ubnormally */
      if (currentScope->loop_count>0) log_state(state,TMPL_LOG_ERROR, "PARAM:LOOP:next_loop(%d): callback returned null scope\n", currentScope->loop);
    }
  }
  if (state->param->ExitLoopScopeFuncPtr) state->param->ExitLoopScopeFuncPtr(state->param->ext_data_state, currentScope->loops_AV);
  popScope(&state->param->var_scope_stack);
  return 0;
}

static 
int init_loop (struct tmplpro_state *state, const PSTRING* const TagOptVal) {
  int loop_count;
  ABSTRACT_ARRAY* loopptr=(ABSTRACT_ARRAY*) walk_through_nested_loops(state->param,TagOptVal[TAG_OPT_NAME]);
  if (loopptr==NULL) {
    return 0;
  } else {
    /* set loop array */
    loopptr = (*state->param->AbstractVal2abstractArrayFuncPtr)(state->param->ext_data_state, loopptr);
    if (loopptr == NULL)
      {
	log_state(state,TMPL_LOG_ERROR, "PARAM:LOOP:loop argument:loop was expected but not found.\n");
	return 0;
      }
    loop_count = (*state->param->GetAbstractArrayLengthFuncPtr)(state->param->ext_data_state, loopptr);
    /* 0 is an empty array; <0 is an undefined array (iterated until next_loop==NULL */
    if (0==loop_count) return 0;
    pushScopeLoop(&state->param->var_scope_stack, loop_count, loopptr);
    return 1;
  }
}

static 
void 
tag_handler_loop (struct tmplpro_state *state, const PSTRING* const TagOptVal)
{
  struct tagstack_entry iftag;
  iftag.tag=HTML_TEMPLATE_TAG_LOOP;
  iftag.vcontext=state->is_visible;
  iftag.value=0;
  iftag.position=state->cur_pos; /* loop start - to restore in </tmpl_loop> */
#ifdef DEBUG
  log_state(state,TMPL_LOG_DEBUG2,"tag_handler_loop:before InitLoopFuncPtr\n");
#endif
  if (state->is_visible && init_loop(state,TagOptVal) && next_loop(state)) {
    iftag.value=1; /* the loop is non - empty */
  } else {
    /* empty loop is equal to <if false> ... </if> */
    state->is_visible=0;
  }
#ifdef DEBUG
  log_state(state,TMPL_LOG_DEBUG2,"tag_handler_loop:after InitLoopFuncPtr\n");
#endif
  tagstack_push(&(state->tag_stack), iftag);
}

static 
void 
tag_handler_closeloop (struct tmplpro_state *state, const PSTRING* const TagOptVal)
{
  struct tagstack_entry* iftag_ptr;
  if (! test_stack(HTML_TEMPLATE_TAG_LOOP)) {
    tag_stack_debug(state,HTML_TEMPLATE_TAG_LOOP);
    return;
  }
  iftag_ptr=tagstack_top(&(state->tag_stack));
  if (iftag_ptr->value==1 && next_loop(state)) {
    /* continue loop */
    state->cur_pos=iftag_ptr->position;
    state->last_processed_pos=iftag_ptr->position;
    return;
  } else {
    /* finish loop */
    struct tagstack_entry iftag;
    iftag=tagstack_smart_pop(state);
    state->is_visible=iftag.vcontext;
    state->last_processed_pos=state->cur_pos;
  }
}

static 
void 
tag_handler_unknown (struct tmplpro_state *state, const PSTRING* const TagOptVal)
{
  log_state(state,TMPL_LOG_ERROR,"tag_handler_unknown: unknown tag\n");
}

/*
 * Local Variables:
 * mode: c 
 * End: 
 */
