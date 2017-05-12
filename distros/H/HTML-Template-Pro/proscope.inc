/* -*- c -*- 
 * File: proscope.c
 * Author: Igor Vlasenko <vlasenko@imath.kiev.ua>
 * Created: Thu May 26 15:25:57 2005
 *
 * $Id$
 */

#include <stdlib.h>
#include "proscope.h"
#include "tmpllog.h"

#define START_NUMBER_OF_NESTED_LOOPS 64

static
void 
Scope_init(struct scope_stack* scopestack) {
  scopestack->max=START_NUMBER_OF_NESTED_LOOPS;
  scopestack->root=(struct ProScopeEntry*) malloc ((scopestack->max) * sizeof(struct ProScopeEntry));
  if (NULL==scopestack->root) tmpl_log(TMPL_LOG_ERROR, "DIE:_Scope_init:internal error:not enough memory\n");
  scopestack->level=-1;
}

static
void 
Scope_free(struct scope_stack* scopestack) {
  free(scopestack->root);
  scopestack->max=-1;
  scopestack->level=-1;
}

INLINE
static
int curScopeLevel(const struct scope_stack* scopestack) {
  return scopestack->level;
}

INLINE
static
struct ProScopeEntry* getCurrentScope(const struct scope_stack* scopestack) {
  return scopestack->root+scopestack->level;
}

INLINE
static
struct ProScopeEntry* 
getScope(const struct scope_stack* scopestack, int depth) {
  return &(scopestack->root)[depth];
}

static
void 
popScope(struct scope_stack* scopestack) {
  if (scopestack->level>0) scopestack->level--;
  else tmpl_log(TMPL_LOG_ERROR, "WARN:PopScope:internal error:scope is exhausted\n");
}

static
void 
_pushScope(struct scope_stack* scopestack) {
  if (scopestack->max<0) {
    tmpl_log(TMPL_LOG_ERROR, "WARN:PushScope:internal warning:why scope is empty?\n");
    Scope_init(scopestack);
  }
  ++scopestack->level;
  if (scopestack->level>scopestack->max) 
    {
      if (scopestack->max<START_NUMBER_OF_NESTED_LOOPS) scopestack->max=START_NUMBER_OF_NESTED_LOOPS;
      scopestack->max*=2;
      scopestack->root=(struct ProScopeEntry*) realloc (scopestack->root, (scopestack->max) * sizeof(struct ProScopeEntry));
    }
}

static
void 
pushScopeLoop(struct scope_stack* scopestack, int loop_count, void *loops_AV) {
  struct ProScopeEntry* CurrentScope;
  _pushScope(scopestack);
  CurrentScope=scopestack->root+scopestack->level;
  CurrentScope->loop=-1;
  CurrentScope->loop_count = loop_count;
  CurrentScope->flags=0;
  CurrentScope->loops_AV=loops_AV;
  CurrentScope->param_HV=NULL;
}

static
void 
pushScopeMap(struct scope_stack* scopestack, void *param_HV, int flags) {
  struct ProScopeEntry* CurrentScope;
  _pushScope(scopestack);
  CurrentScope=scopestack->root+scopestack->level;
  CurrentScope->flags=flags;
  CurrentScope->loops_AV=NULL;
  CurrentScope->param_HV=param_HV;
}

static
void 
Scope_reset(struct scope_stack* scopestack, int keep_count) {
  int init_level=-1;
  // TODO; find out scope level
  if (scopestack->max<0) {
    tmpl_log(TMPL_LOG_ERROR, "ERROR:Scope_reset:internal error:scope is empty.\n");
    Scope_init(scopestack);
    scopestack->level=init_level;
  } else {
    scopestack->level=keep_count+init_level;
  }
}
