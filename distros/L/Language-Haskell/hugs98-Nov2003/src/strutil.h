/*
 * String utilities needed throughout the Hugs codebase.
 */ 
#ifndef __STRUTIL_H__
#define __STRUTIL_H__

/* string copy operator, allocates new via malloc() */
extern String strCopy Args((String));

/* substring copy operator, allocates new via malloc() */
extern String strnCopy Args((String, Int));

/* Given a string containing a possibly qualified name,
 * split it up into a module and a name portion.
 */
extern Void splitQualString Args((String, String*, String*));

#endif /* __STRUTIL_H__ */
