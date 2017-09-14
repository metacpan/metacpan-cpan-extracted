/*============================================================================
 * Ruby.xs
 * Inline::Ruby method bindings.
 *
 * Here's a quick map of this file:
 *
 * XS:
 * Inline::Ruby::rb_eval			===> evaluates ruby code
 * Inline::Ruby::rb_call_function		\
 * Inline::Ruby::rb_call_class_method		 ====> call_ruby_method()
 * Inline::Ruby::rb_call_instance_method	/
 *
 * C:
 * call_ruby_method
 *   |__ my_error_wrapper
 *   |  |__ rb_funcall2				===> calls Ruby method
 *   |  \__ rb_iterate
 *   |     |__ my_iter_it
 *   |     |  \__ rb_funcall2			===> calls Ruby method
 *   |     |
 *   |     \__ my_iter_bl			===> calls Perl iterator
 *   |
 *   \__ my_error_trap				===> throws Perl exception
 *==========================================================================*/

/* perl stuff */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "rb2pl.h"
#ifdef	EXPOSE_PERL
# include "perlmodule.h"
#endif


/*============================================================================
 * This macro creates and fills a ruby array from the Perl call stack. It
 * relies on the Perl dXSARGS() macro having been called before it; XS does
 * this automatically. It also requires NUM_FIXED_ARGS to be defined.
 *==========================================================================*/
#define INIT_RUBY_ARGV(name) {						     \
    int i;								     \
    name = rb_ary_new2(items >= NUM_FIXED_ARGS ? items-NUM_FIXED_ARGS : 0);  \
    for (i = NUM_FIXED_ARGS; i < items; i++) {				     \
	VALUE tmp = pl2rb(ST(i));					     \
	rb_ary_push(name, tmp);						     \
    }									     \
}

/*============================================================================
 * These macros either flatten the return value (converted into Perl
 * variables) onto the Perl stack, or return it preserved.
 *==========================================================================*/
#define FLATTEN_RETVAL(name) {						     \
    if (GIMME_V == G_ARRAY && SvROK(name) && 				     \
	    SvTYPE(SvRV(name)) == SVt_PVAV)				     \
    {									     \
	AV* av = (AV*)SvRV(name);					     \
	int len = av_len(av) + 1;					     \
	int i;								     \
	for (i=0; i<len; i++) {						     \
	    XPUSHs(sv_2mortal(av_shift(av)));				     \
	}								     \
    }									     \
    else {								     \
	XPUSHs(name);							     \
    }									     \
}
#define PRESERVE_RETVAL(name) XPUSHs(name)

/* The PerlException class */
VALUE rb_ePerlException;
static void
Init_PerlException() {
    rb_ePerlException = rb_define_class("PerlException", rb_eStandardError);
}

/*============================================================================
 * Initializes the Ruby interpreter. This is copied for the most part from
 * main.c in the Ruby sources.
 *==========================================================================*/
#ifdef	CREATE_RUBY
extern VALUE rb_progname;
extern VALUE rb_argv;
extern VALUE rb_argv0;
static void
do_rbinit() {
    char *argv[] = { "ruby" };
    int argc = sizeof(argv)/sizeof(argv[0]);

#ifdef RUBY_INIT_STACK
    RUBY_INIT_STACK;
#endif
    /* set up the initial ruby interpreter */
    ruby_init();

    /* Set the program name, argv, and argv0 to the right things */
    ruby_script("Inline::Ruby");
    rb_argv0 = rb_str_new2(argv[0]);
    ruby_set_argv(argc, argv);

    /* Allow loading of dynamic libraries */
    ruby_init_loadpath();
    /* #if-ing out because maybe no longer needed and not supported in
     * recent MRIs:
     *
     * http://my.opera.com/subjam/blog/embedding-ruby-in-c-programs
     *
     * */
#if 0
    Init_ext();
#endif

    /* Set up our own types */
    Init_PerlException();
    Init_PerlProc();
}
#endif

/*============================================================================
 * This is an iterator method, which just calls the real Ruby block. The
 * callback block is invoked whenever the Ruby code calls "yield". Look at the
 * definition of my_iter_bl(), below.
 *==========================================================================*/
static VALUE
my_iter_it(fake)
    VALUE fake;
{
    VALUE obj, method, args;

    Printf(("Note: in my_iter_it(%p)\n", (void *) fake));
    Printf(("Type: TYPE(fake) = %i\n", TYPE(fake)));
    obj		= rb_ary_entry(fake, 0);
    method	= rb_ary_entry(fake, 1);
    args	= rb_ary_entry(fake, 2);

    Printf(("============================\n"));
    Printf(("About to call rb_funcall2...\n"));
    Printf(("obj = %s (%i)\n", STR2CSTR(rb_inspect(obj)), TYPE(obj)));
    Printf(("method = %s (%i)\n", STR2CSTR(rb_inspect(method)), TYPE(method)));
    Printf(("args = %s (%i)\n", STR2CSTR(rb_inspect(args)), TYPE(args)));
    Printf(("============================\n"));
    return rb_funcall2(obj, rb_intern(STR2CSTR(method)),
		       RARRAY_LEN(args), RARRAY_PTR(args));
}

/*
 * This function was contributed by mauke.
 */
static void my_do_chomp(SV * sv)
{
    char * p;
    STRLEN n;

    p = SvPV_force(sv, n);
    if (n && p[n - 1] == '\n')
    {
        n--; p[n] = '\0';
        SvCUR_set(sv, n);
    }
}

/*============================================================================
 * This is the iterator block invoked whenever the Ruby code calls yield(). It
 * is passed an optional value each time it's called (opt), which contains the
 * Perl subroutine ref to forward the call to. The arguments to the block come
 * in 'res'.
 *==========================================================================*/
static VALUE
my_iter_bl(res, cv)
    VALUE	res;
    SV*		cv;
{
    dSP;

    SV* args;
    I32 count;			/* how many values returned on Perl stack */
    I32 ax;
    VALUE rb_retval;

    Printf(("Note: inside my_iter_bl...\n"));
    Printf(("Note: TYPE(res) == %i\n", TYPE(res)));

    Printf(("Note: the ruby args are: %s\n", STR2CSTR(rb_inspect(res))));

    args = rb2pl(res);	/* convert the Ruby args to Perl args */

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

#ifdef	FLATTEN_CALLBACK_ARGS
    if (SvROK(args) && SvTYPE(SvRV(args)) == SVt_PVAV) {
	AV* av = (AV*) SvRV(args);
	int len = av_len(av) + 1;
	int i;
	for (i=0; i<len; i++) {
	    XPUSHs(sv_2mortal(av_shift(av)));
	}
    }
    else
#endif
	XPUSHs(sv_2mortal(args));

    PUTBACK;

    count = call_sv(cv, G_SCALAR | G_EVAL | G_KEEPERR);

    SPAGAIN;

    /* Perl stack magic (to enable using ST(n)) */
    SP -= count;
    ax = (SP - PL_stack_base) + 1;

    /* Check the eval first */
    if (SvTRUE(ERRSV)) {
	/* Must clean up the stack if we died with G_SCALAR */
	POPs;

	/* stringify the Perl error into the Ruby error */
	my_do_chomp(ERRSV);
	rb_raise(rb_ePerlException, "%s", SvPV_nolen(ERRSV));
	return Qnil;	/* not reached */
    }

    if (count == 0)
	rb_retval = Qnil;
    else if (count == 1)
	rb_retval = pl2rb(ST(0));
    else {
	int i;
	rb_retval = rb_ary_new2(count);
	for (i=0; i<count; i++) {
	    rb_ary_push(rb_retval, pl2rb(ST(i)));
	}
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return rb_retval;
}

/*============================================================================
 * This is called whenever there's an uncaught exception in some Ruby code
 * being run by Inline::Ruby. It sets Perl's global error object to an
 * Inline::Ruby::Exception object. It stringifies nicely into the same string
 * as Ruby's error message. You can also call methods on it. See the doc.
 *==========================================================================*/
static VALUE
my_error_trap(arg, error)
    VALUE	arg;
    VALUE	error;
{
    dSP;
    HV*	wrapper;
    SV*	ref;

    wrapper = newHV();

    Printf(("Note: Ruby threw an exception!!!\n"));
    Printf(("Note: %s\n", STR2CSTR(rb_inspect(error))));

    /* Create a wrapper */
    (void)hv_store(wrapper, "_rb_exc", 7, newSViv((IV)error), 0);
    ref = newRV_noinc((SV*)wrapper);

    /* Throw a Perl exception */
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv("Inline::Ruby::Exception", 0)));
    XPUSHs(sv_2mortal(ref));
    PUTBACK;

    call_pv("Inline::Ruby::Exception::new", G_VOID | G_DISCARD);

    FREETMPS;
    LEAVE;

    /* not reached */
    return Qnil;
}

/*============================================================================
 * This wrapper is called by call_ruby_method(), to protect blocks of code
 * from uncaught exceptions. Ruby walks up the exception tree looking for an
 * exception handler, and will walk off the tree into segfault land if you
 * don't provide a top-level rescue block. So we do.
 *==========================================================================*/
static VALUE
my_error_wrapper(arg)
    VALUE	arg;
{
    VALUE	obj;
    char*	method;
    SV*		iter;
    VALUE	argv;
    VALUE	retv;

    /* Extract the arguments */
    obj = rb_ary_entry(arg, 0);
    {
        VALUE method_obj = rb_ary_entry(arg, 1);
        method = STR2CSTR(method_obj);
    }
    iter = (SV*)rb_ary_entry(arg, 2);
    argv = rb_ary_entry(arg, 3);

    /* If 'iter' points to a Perl subroutine, run an iterator instead of just
     * a boring old function. */
    if (iter && SvROK(iter) && SvTYPE(SvRV(iter)) == SVt_PVCV) {
	VALUE it_args;
	it_args = rb_ary_new3(3, obj, rb_str_new2(method), argv);
	Printf(("Note: calling rb_interate(%p, %p, %p, %p)\n",
	       my_iter_it, (void *) it_args, my_iter_bl, iter));
	retv = rb_iterate(&my_iter_it, it_args, &my_iter_bl, (VALUE)iter);
    }
    else {
	Printf(("calling func\n"));
	retv = rb_funcall2(obj, rb_intern(method),
			   RARRAY_LEN(argv), RARRAY_PTR(argv));
    }
    /* If we get here, there were no exceptions */
    Printf(("No exceptions thrown, clearing ERRSV!\n"));
    sv_setpvf(ERRSV, "%s", "");
    return retv;
}

/* This serves to wrap the eval() in a rescue() block */
static VALUE
my_eval_string(str)
    VALUE	str;
{
    return rb_eval_string(STR2CSTR(str));
}

/*============================================================================
 * This is my generic ruby method caller. It will call either global
 * functions, class methods, or instance methods. There's a simple way to tell
 * which is which. The first argument is either a string (the name of the
 * class), an object (the object to call the method on), or undef (indicates a
 * global function). The second is the name of the method to call. The third
 * is an optional iterator function.
 *==========================================================================*/
static SV*
call_ruby_method(obj, method, iter, argv)
    VALUE	obj;
    char*	method;
    SV*		iter;
    VALUE	argv;
{
    VALUE	wrap_argv;
    VALUE	rb_retval;

    Printf(("call_ruby_method(%p, '%s', %p)\n", (void *) obj, method, iter));

    /* If obj is a string, it is the name the class upon which to call the
     * class method. */
    if (TYPE(obj) == T_STRING) {
	Printf(("call_ruby_method: obj is a class; getting a handle...\n"));
	obj = rb_const_get(rb_cObject, rb_intern(STR2CSTR(obj)));
    }

    /* Because we want to "wrap" the call in a rescue block, we use rb_rescue.
     * The block we call is yet another wrapper, which just forwards the call
     * to the real function: */
    wrap_argv = rb_ary_new3(4, obj, rb_str_new2(method), (VALUE)iter, argv);
    rb_retval = rb_rescue2(&my_error_wrapper, wrap_argv, &my_error_trap, Qnil,
			   rb_eException, 0);

    if (!rb_retval) {
	croak("Error: rb_funcall2() returned a NULL C pointer");
	return &PL_sv_undef;	/* not reached */
    }

#ifdef	CHECK_CONTEXT
    if (GIMME_V == G_VOID)
	return &PL_sv_undef;
#endif

    return rb2pl(rb_retval);
}

MODULE = Inline::Ruby	PACKAGE = Inline::Ruby	PREFIX = my_

BOOT:
#ifdef	CREATE_RUBY
do_rbinit();
rb_gc_start(); /* important */
rb_funcall(rb_stdout, rb_intern("sync="), 1, 1);
#endif

PROTOTYPES: DISABLE

#=============================================================================
# This is called to evaluate ruby code (duh!). It uses rb_rescue to trap any
# compile errors raised by the interpreter. If an exception is thrown we
# return an undef, and set the global variable "$@".
#=============================================================================
int
config_var(str)
	char*	str
    CODE:
	if (strEQ(str, "CHECK_CONTEXT"))
#ifdef	CHECK_CONTEXT
	    RETVAL = 1;
#else
	    RETVAL = 0;
#endif
	else if (strEQ(str, "FLATTEN_ARRAYS"))
#ifdef	FLATTEN_ARRAYS
	    RETVAL = 1;
#else
	    RETVAL = 0;
#endif
	else if (strEQ(str, "FLATTEN_CALLBACK_ARGS"))
#ifdef	FLATTEN_CALLBACK_ARGS
	    RETVAL = 1;
#else
	    RETVAL = 0;
#endif
	else {
	    if (PL_dowarn)
		warn("Inline::Ruby::config_var: unknown config var '%s'", str);
	    XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL

#=============================================================================
# This is called to evaluate ruby code (duh!). It uses rb_rescue to trap any
# compile errors raised by the interpreter. If an exception is thrown we
# return an undef, and set the global variable "$@".
#=============================================================================
void
my_rb_eval(str)
	char*	str
    PREINIT:
	SV*	pl_retval;
    PPCODE:
	Printf(("About to evaluate some Ruby code:\n"));
        Printf(("%s\n", str));
        Printf(("__END__"));
#ifdef rb_set_errinfo
    rb_set_errinfo(Qnil); /* reset GET_THREAD()->errinfo */
#endif
	pl_retval = rb2pl(rb_rescue2(&my_eval_string, rb_str_new2(str),
				  &my_error_trap, Qnil, rb_eException, 0));
	Printf(("Done.\n"));
#if defined CHECK_CONTEXT && defined FLATTEN_ARRAYS
	FLATTEN_RETVAL(pl_retval);
#else
	PRESERVE_RETVAL(pl_retval);
#endif

#=============================================================================
# This sub calls a global ruby method. It takes the name of the method to run,
# an optional iterator, and any arguments to the method.
#=============================================================================
#undef	NUM_FIXED_ARGS
#define	NUM_FIXED_ARGS 1
void
my_rb_call_function(FNAME, ...)
	char*	FNAME
    PREINIT:
	VALUE	argv;
	SV*	pl_retval;
    PPCODE:
	Printf(("rb_call_function(\"%s\")\n", FNAME));
	INIT_RUBY_ARGV(argv);
	pl_retval = call_ruby_method(Qnil, FNAME, NULL, argv);
#if defined CHECK_CONTEXT && defined FLATTEN_ARRAYS
	FLATTEN_RETVAL(pl_retval);
#else
	PRESERVE_RETVAL(pl_retval);
#endif

#=============================================================================
# This is called whenever you need to call a class method. It takes the name
# of the class, the method name, an iterator block, and any arguments to the
# method. If the iterator block is not a reference to a Perl subroutine, it is
# not passed to the ruby method.
#=============================================================================
#undef  NUM_FIXED_ARGS
#define NUM_FIXED_ARGS 2
void
my_rb_call_class_method(KLASS, mname, ...)
	char*	KLASS
	char*	mname
    PREINIT:
	VALUE	klass;
	VALUE	argv;
	SV*	pl_retval;
    PPCODE:
	Printf(("rb_call_class_method('%s', '%s', ...)\n",KLASS,mname));

	INIT_RUBY_ARGV(argv);
	klass = rb_str_new2(KLASS);
	pl_retval = call_ruby_method(klass, mname, NULL, argv);
#if defined CHECK_CONTEXT && defined FLATTEN_ARRAYS
	FLATTEN_RETVAL(pl_retval);
#else
	PRESERVE_RETVAL(pl_retval);
#endif

#=============================================================================
# This is called whenever you need to call an instance method. It takes the
# instance of the class, the method name, an iterator block, and any arguments
# to the method. If the iterator block is not a reference to a Perl
# subroutine, it is not passed to the ruby method.
#=============================================================================
#undef  NUM_FIXED_ARGS
#define NUM_FIXED_ARGS 2
void
my_rb_call_instance_method(_inst, mname, ...)
	SV*	_inst
	char*	mname
    PREINIT:
	VALUE	inst;
	VALUE	argv;
	SV*	pl_retval;
	SV*	iter;
    PPCODE:
	Printf(("rb_call_instance_method(%p, '%s', ...)\n",
		_inst, mname));

	if (isa_InlineRubyWrapper(_inst)) {
	    inst = UNWRAP_RUBY_OBJ(_inst);
	    iter = INLINE_MAGIC(_inst)->iter;
	    Printf(("inst (%p) successfully passed the PVMG test\n", (void *) inst));
	}
	else {
	    croak("Object is not a wrapped Inline::Ruby::Object object");
	    XSRETURN_EMPTY;
	}

	INIT_RUBY_ARGV(argv);
	pl_retval = call_ruby_method(inst, mname, iter, argv);
#if defined CHECK_CONTEXT && defined FLATTEN_ARRAYS
	FLATTEN_RETVAL(pl_retval);
#else
	PRESERVE_RETVAL(pl_retval);
#endif

#=============================================================================
# This sub calls a global ruby method. It takes the name of the method to run,
# an optional iterator, and any arguments to the method.
#=============================================================================
SV*
my_rb_iter(obj, iter=NULL)
	SV*	obj
	SV*	iter
    CODE:
	/* Case 1: obj is an instance method */
	if (items == 2 && isa_InlineRubyWrapper(obj)) {
	    RETVAL = rb2pl(pl2rb(obj));	/* deep copy */
	    INLINE_MAGIC(RETVAL)->iter = iter;
	    SvREFCNT_inc(iter);
	}
	/* Case 2: obj is a class name */
	else if (items == 2 && SvTYPE(obj) == SVt_PV) {
	    RETVAL = new_InlineRubyWrapper(rb_str_new2(SvPV_nolen(obj)), iter);
	}
	else if (items == 1)
	    RETVAL = new_InlineRubyWrapper(Qnil, obj);	/* pass sub in obj */
	else
	    RETVAL = new_InlineRubyWrapper(Qnil, iter);
    OUTPUT:
	RETVAL

MODULE = Inline::Ruby	PACKAGE = Inline::Ruby::Object

void
DESTROY(obj)
        SV*	obj
    CODE:
	if (isa_InlineRubyWrapper(obj)) {
        /*
        XXX - this somehow conflicts with free_InlineRubyWrapper,
        so it's commented out until we find a way to get them work together:

 	    VALUE rb_object = UNWRAP_RUBY_OBJ(obj);
	    */
	    /* talk to the ruby garbage collector */
	}

MODULE = Inline::Ruby	PACKAGE = Inline::Ruby::Exception

#define RETRIEVE_CACHE(m) { \
    SV **svp = hv_fetch(wrapper, m, strlen(m), FALSE); \
    if (svp)                                           \
        XSRETURN_PV(SvPV_nolen(*svp));                 \
}

#define STORE_CACHE(m, v) (void)hv_store(wrapper, m, strlen(m), v, 0)

SV*
message(obj)
	SV*	obj
    ALIAS:
	Inline::Ruby::Exception::inspect	= 1
	Inline::Ruby::Exception::backtrace	= 2
    PREINIT:
	HV*     wrapper;
	char*	method;
    CODE:
	if (SvROK(obj) && SvTYPE(SvRV(obj)) == SVt_PVHV) {
	    wrapper = (HV*)SvRV(obj);
	}
	else {
	    croak("Not an Inline::Ruby::Exception object");
	    XSRETURN_EMPTY;
	}
	switch(ix) {
	    case 0:
		method = "message";
		RETRIEVE_CACHE(method);
		break;
	    case 1:
		method = "inspect";
		RETRIEVE_CACHE(method);
		break;
	    case 2:
		method = "backtrace";
		RETRIEVE_CACHE(method);
		break;
	    default:
		croak("Internal error in Inline::Ruby::Exception");
		XSRETURN_EMPTY;
	}
	VALUE rb_exception = (VALUE)SvIV(*hv_fetch(wrapper, "_rb_exc", 7, FALSE));
	RETVAL = rb2pl(rb_funcall(rb_exception, rb_intern(method), 0));
	STORE_CACHE(method, newSVsv(RETVAL));
    OUTPUT:
	RETVAL

SV*
type(obj)
	SV*	obj
    PREINIT:
	HV*     wrapper;
	char*   method;
    CODE:
	if (SvROK(obj) && SvTYPE(SvRV(obj)) == SVt_PVHV) {
	    wrapper = (HV*)SvRV(obj);
	}
	else {
	    croak("Not an Inline::Ruby::Exception object");
	    XSRETURN_EMPTY;
	}
	method = "type";
	RETRIEVE_CACHE(method);
	{
	    VALUE rb_exception = (VALUE)SvIV(*hv_fetch(wrapper, "_rb_exc", 7, FALSE));
	    VALUE klass = rb_funcall(rb_exception, rb_intern("class"), 0);
	    RETVAL = rb2pl(rb_funcall(klass, rb_intern("name"), 0));
	    STORE_CACHE(method, newSVsv(RETVAL));
	}
    OUTPUT:
	RETVAL

#undef RETRIEVE_CACHE
#undef STORE_CACHE
