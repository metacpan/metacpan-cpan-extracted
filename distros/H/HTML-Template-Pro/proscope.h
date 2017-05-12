/* -*- c -*- 
 * File: proscope.h
 * Author: Igor Vlasenko <vlasenko@imath.kiev.ua>
 * Created: Thu May 26 15:13:10 2005
 *
 * $Id$
 */

#ifndef _PROSCOPE_H
#define _PROSCOPE_H	1

#include "pabstract.h"

struct scope_stack {
  int level;
  int max;
  struct ProScopeEntry* root;
};

struct ProScopeEntry {
  int flags;		/* type of scope */
  int  loop; 		/* current loop */
  int  loop_count;	/* total number of loops or negative value if unknown */
  /* objects are wrapper-specific so pointer is void */
  ABSTRACT_ARRAY* loops_AV;	/* pointer to array of loop's dictionaries */
  ABSTRACT_MAP*   param_HV;	/* pointer to dictionary of current loop   */
};

#define isScopeLoop(X) ((X)->loops_AV!=NULL)
#define isScopeMap(X) ((X)->loops_AV==NULL)

#endif /* _PROSCOPE_H */
