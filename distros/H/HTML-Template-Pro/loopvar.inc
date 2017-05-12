static 
const char* const innerloopname[]={
  "", "first__", "last__", "inner__", "odd__", "counter__"
};

static 
const char* const INNERLOOPNAME[]={
  "", "FIRST__", "LAST__", "INNER__", "ODD__", "COUNTER__"
};

#define HTML_TEMPLATE_INNER_LOOP_VAR_FIRST   1
#define HTML_TEMPLATE_INNER_LOOP_VAR_LAST    2
#define HTML_TEMPLATE_INNER_LOOP_VAR_INNER   3
#define HTML_TEMPLATE_INNER_LOOP_VAR_ODD     4
#define HTML_TEMPLATE_INNER_LOOP_VAR_COUNTER 5

#define HTML_TEMPLATE_FIRST_INNER_LOOP 1
#define HTML_TEMPLATE_LAST_INNER_LOOP  5


static 
int 
try_inner_loop_variable (PSTRING name)
{ 
  int i;
  const char* cur_pos;
  const char* pattern;
  const char* PATTERN;
  for (i=HTML_TEMPLATE_FIRST_INNER_LOOP; i<=HTML_TEMPLATE_LAST_INNER_LOOP; i++) {
    cur_pos=name.begin;
    pattern=innerloopname[i];
    PATTERN=INNERLOOPNAME[i];
    while (*pattern && cur_pos<name.endnext) {
      if (*pattern == *cur_pos || *PATTERN == *cur_pos) {
	pattern++;
	PATTERN++;
	cur_pos++;
      } else {
	break;
      }
    }
    if (cur_pos==name.endnext) {
      return i;
    }
  }
  return 0;
}

static 
PSTRING 
get_loop_context_vars_value (struct tmplpro_param *param, PSTRING name) {
  static const char* const FalseString="0";
  static const char* const TrueString ="1";
  int loop;
  PSTRING retval={NULL,NULL};
  const struct ProScopeEntry* const currentScope = getCurrentScope(&param->var_scope_stack);
  if (isScopeLoop(currentScope)
      && name.endnext-name.begin>4
      && '_'==*(name.begin)
      && '_'==*(name.begin+1)
      ) { 
    /* we can meet loop variables here -- try it first */
    /* length of its name >4 */
    /* __first__ __last__ __inner__ __odd__ __counter__ */
    PSTRING shiftedname; /* (PSTRING) {name.begin+2,name.endnext} */
    shiftedname.begin=name.begin+2;
    shiftedname.endnext=name.endnext;
    switch (try_inner_loop_variable(shiftedname)) {
    case 0:  break;
    case HTML_TEMPLATE_INNER_LOOP_VAR_FIRST: 
      if (currentScope->loop==0) {  /* first__ */
	retval.begin=TrueString; retval.endnext=TrueString+1;
      } else {
	retval.begin=FalseString; retval.endnext=FalseString+1;
      }; break;
    case HTML_TEMPLATE_INNER_LOOP_VAR_LAST: 
      if (currentScope->loop==(currentScope->loop_count-1)) {
	retval.begin=TrueString; retval.endnext=TrueString+1;
      } else {
	retval.begin=FalseString; retval.endnext=FalseString+1;
      }; break;
    case HTML_TEMPLATE_INNER_LOOP_VAR_ODD: 
      if ((currentScope->loop%2)==0) {
	retval.begin=TrueString; retval.endnext=TrueString+1;
      } else {
	retval.begin=FalseString; retval.endnext=FalseString+1;
      }; break;
    case HTML_TEMPLATE_INNER_LOOP_VAR_INNER: 
      if (currentScope->loop>0 && 
	  (currentScope->loop_count<0 /* loop_count < 0 if number of loops is unknown/undefined */
	   || currentScope->loop < (currentScope->loop_count-1))) {
	retval.begin=TrueString; retval.endnext=TrueString+1;
      } else {
	retval.begin=FalseString; retval.endnext=FalseString+1;
      }; break;
    case HTML_TEMPLATE_INNER_LOOP_VAR_COUNTER: 
      {
	char* const buffer = param->loopvarbuf;
	loop=currentScope->loop+1;
	snprintf(buffer,sizeof(param->loopvarbuf),"%d",loop);
	retval.begin=buffer; retval.endnext=buffer+strlen(buffer);
      }
      break;
    }
  }
  return retval;
}

/*
 * Local Variables:
 * mode: c 
 * End: 
 */
