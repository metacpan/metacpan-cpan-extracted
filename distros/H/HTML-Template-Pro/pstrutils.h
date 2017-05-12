/* -*- c -*- 
 * File: pstring.h
 * Author: Igor Vlasenko <vlasenko@imath.kiev.ua>
 * Created: Fri Jul  1 20:11:51 2005
 *
 * $Id$
 */

#ifndef _PSTRUTILS_H
#define _PSTRUTILS_H	1

#include "pbuffer.h"

static 
PSTRING lowercase_pstring (pbuffer*, PSTRING);
static 
int is_pstring_true (PSTRING s);
static 
PSTRING escape_pstring (pbuffer* StrBuffer, PSTRING pstring, int escapeopt);

/*
static
void lowercase_pstring_inplace (PSTRING pstring);
*/
#endif /* pstrutils.h */
