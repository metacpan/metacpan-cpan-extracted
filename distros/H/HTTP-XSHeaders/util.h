#ifndef UTIL_H_
#define UTIL_H_

/*
 * Utility functions called from our XSUB.
 */

#include "hlist.h"
#include "plist.h"

/*
 * Clone an object, either from its class or from an existing object; put a
 * clone of old_list (if any) as the initial values for the cloned object.
*/
SV* clone_from(pTHX_ SV* klass, SV* self, HList* old_list);

/*
 * Set the value for a given header; call recursively into set_scalar and
 * set_array, depending of whether pval is a scalar or an array.
 */
void set_value (pTHX_ HList* h, const char* ckey, SV* pval);
void set_scalar(pTHX_ HList* h, const char* ckey, SV* pval);
void set_array (pTHX_ HList* h, const char* ckey, AV* pval);

/*
 * Return to Perl all values in an HList.
 */
void return_hlist(pTHX_ HList* list, const char* func, int want);

/*
 * Return to Perl all values in a PList.
 */
void return_plist(pTHX_ PList* list, const char* func, int want);

/*
 * Format into str all values in an HList, using endl as end of line
 * separator; if sort is true, sort key names before.
 */
char* format_all(pTHX_ HList* h, int sort, const char* endl, int* size);

#endif
