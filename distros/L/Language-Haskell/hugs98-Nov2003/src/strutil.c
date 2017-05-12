/*
 * String utilities needed throughout the Hugs codebase.
 */ 
#include "prelude.h"
#include "storage.h"
#include "connect.h"
#include "errors.h"
#include "strutil.h"

/* --------------------------------------------------------------------------
 * String manipulation routines:
 * ------------------------------------------------------------------------*/

String strCopy(s)         /* make malloced copy of a string   */
String s; {
    if (s) {
	char *t;
	if ((t=(char *)malloc(strlen(s)+1))==0) {
	    ERRMSG(0) "String storage space exhausted"
	    EEND;
	}
	strcpy(t, s);
	return t;
    }
    return NULL;
}

String strnCopy(s,n)      /* make malloced copy of a substring */
String s;
Int n; {
    if (s) {
	char *t;
	if ((Int)strlen(s) < n)
	    n = strlen(s);
	if ((t=(char *)malloc(n+1))==0) {
	    ERRMSG(0) "String storage space exhausted"
	    EEND;
	}
	strncpy(t, s, n);
	t[n] = '\0';
	return t;
    }
    return NULL;
}

/* Given a string containing a possibly qualified name,
 * split it up into a module and a name portion.
 */
Void splitQualString(nm, pMod, pName) 
String nm;
String* pMod;
String* pName; {
  String dot;

  /* Find the last occurrence of '.' */
  dot = strrchr(nm, '.');
  
  if (!dot) {
    *pMod = NULL;
    *pName = nm;
  } else {
    /* The module portion consists of everything upto the last dot. */
    *pMod = strnCopy(nm, dot - nm);

    /* Copy everything after the last '.' to the name string */
    *pName = strCopy(dot+1);
  }

}
