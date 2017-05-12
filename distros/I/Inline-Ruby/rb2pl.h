#ifndef RB2PL_H
#define RB2PL_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#undef yyparse
#undef yylex
#undef yyerror
#undef yylval
#undef yychar
#undef yydebug
#include "ruby.h"

#ifndef RFLOAT_VALUE
#define RFLOAT_VALUE(o) RFLOAT(o)->value
#endif

#ifndef RSTRING_LEN
#define RSTRING_LEN(o) RSTRING(o)->len
#endif

#ifndef RSTRING_PTR
#define RSTRING_PTR(o) RSTRING(o)->ptr
#endif

/*
 * See:
 *
 * - http://stackoverflow.com/questions/4631251/rvm-ruby-1-9-2-symbol-not-found-str2cstr
 *
 * - https://www.ruby-forum.com/topic/215406
 * */
#ifndef STR2CSTR
#define STR2CSTR(x) StringValuePtr(x)
#endif
/*
 * See:
 *
 * - http://jgarber.lighthouseapp.com/projects/13054/tickets/102-ruby-191-rarrayx-len-should-be-rarray_lenx
 *
 * */
#ifndef RARRAY_LEN
#define RARRAY_LEN(arr) (RARRAY(arr)->len)
#endif
#ifndef RARRAY_PTR
#define RARRAY_PTR(arr) (RARRAY(arr)->ptr)
#endif

#ifndef RHASH_TBL
#define RHASH_TBL(o) RHASH(o)->tbl
#endif

/*============================================================================
 * To save a little time, I check the calling context and don't convert
 * the arguments if I'm in void context, flatten lists in list context,
 * and return only one element in scalar context.
 * 
 * If this turns out to be a bad idea, it's easy enough to turn off.
 *==========================================================================*/
#define	CHECK_CONTEXT

/*============================================================================
 * If FLATTEN_ARRAYS is turned on, then a return value which is a single array
 * is flattened onto the Perl return list (if the sub is called in array
 * context). This has no effect unless CHECK_CONTEXT is also defined.
 * 
 * NOTE: if enabled, you can't tell the difference between a return value of
 * "3" and ["3"]. In Ruby you can only return one value from a subroutine, so
 * "return 1, 2, 3" is identical to "return [1, 2, 3]" -- the Ruby compiler
 * just creates the array for you.
 *==========================================================================*/
/*#define	FLATTEN_ARRAYS*/

/*============================================================================
 * If FLATTEN_CALLBACK_ARGS is turned on, then when a Perl iterator subroutine
 * is called from Ruby, the Ruby arg will be flattened into the Perl call
 * stack if the type of the Ruby argument is an array.
 *
 * NOTE: if enabled, you can't tell the difference between 'yield [3]' and
 * 'yield 3'. In Ruby this doesn't happen because code blocks know how many
 * arguments they need, so the interpreter knows whether it should pass them a
 * single argument or the unmodified list. This is a particularly annoying
 * problem with Inline::Ruby.
 *==========================================================================*/
#define	FLATTEN_CALLBACK_ARGS

#ifdef I_RB_DEBUG
#  define Printf(x)	printf x
#else
#  define Printf(x)	/* empty */
#endif

#ifndef pTHX_
#  define pTHX_
#  define aTHX_
#  define pTHX
#  define aTHX
#endif

#ifndef call_sv
#  define call_pv perl_call_pv
#  define call_sv perl_call_sv
#endif

#ifndef SvPV_nolen
#  define SvPV_nolen(x) SvPV(x,PL_na)
#endif

typedef struct {
    int		key;	/* an identifier key -- make sure it came from Inline */
    VALUE	rb_val;	/* a Ruby object (or class name) */
    SV*		iter;	/* a Perl iterator */
} inline_magic;

/* InlineRubyWrapper */
#define INLINE_MAGIC(obj)	data_InlineRubyWrapper(obj)
#define UNWRAP_RUBY_OBJ(obj)	( INLINE_MAGIC(obj)->rb_val )
extern SV* new_InlineRubyWrapper(VALUE rb_val, SV* iter);
extern int isa_InlineRubyWrapper(SV* candidate);
extern inline_magic* data_InlineRubyWrapper(SV* self);

/* InlineRubyPerlProc */
extern void Init_PerlProc();

extern SV* rb2pl (VALUE obj);
extern VALUE pl2rb(SV* obj);

#endif
