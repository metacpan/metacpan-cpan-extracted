%{
#include "prelude.h"
#include "storage.h"
#include "connect.h"
#include "machdep.h"
#include "server.h"
void primObserve () { }
void primBkpt () { }
void primSetBkpt () { }
%}

#define Void void
#define DLLIMPORT(rty) rty
#define DLLEXPORT(rty) rty
#define HAVE_PROTOTYPES 1

#define Void     void   /* older compilers object to: typedef void Void;   */
#if !defined(_XLIB_H_)  /* clashes with similar declaration in Xlib.h      */
typedef unsigned Bool;
#endif
#if !defined(TRUE)
#define TRUE     (1)
#endif
#if !defined(FALSE)
#define FALSE    (0)
#endif
#ifndef _XtIntrinsic_h
typedef char    *String;
#endif
typedef int      Int;
typedef signed char Int8;
typedef short    Int16;
typedef long     Long;
typedef int      Char;
typedef unsigned Unsigned;
typedef void*    Pointer;

%include "array.i"
%include "vtable.i"
#include "server.h"
