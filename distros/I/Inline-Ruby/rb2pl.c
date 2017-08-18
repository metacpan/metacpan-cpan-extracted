/****************************************************************************
 * rb2pl.c
 * Conversion routines between Ruby and Perl data types.
 ****************************************************************************/

#include "rb2pl.h"
#if RUBY_VERSION_MAJOR > 1 || (RUBY_VERSION_MAJOR == 1 && RUBY_VERSION_MINOR >= 9)
#include "ruby/st.h"
#else
#include "st.h"		/* ST_CONTINUE */
#endif

#define INL_MAGIC_NUM 0x2943545b
#define INL_MAGIC_KEY(mg_ptr) (((inline_magic *)mg_ptr)->key)
#define INL_MAGIC_CHECK(mg_ptr) (INL_MAGIC_KEY(mg_ptr) == INL_MAGIC_NUM)

/*============================================================================
 * class InlineRubyWrapper {
 *    // ctor, dtor:
 *    SV* new_InlineRubyWrapper(VALUE, SV*);
 *    int free_InlineRubyWrapper(SV* obj, MAGIC* mg);
 *
 *    // get magic
 *    inline_magic* data_InlineRubyWrapper(SV* self);
 *
 *    // isa? (class method)
 *    int isa_InlineRubyWrapper(SV* candidate);
 * };
 *==========================================================================*/
static int
free_InlineRubyWrapper(pTHX_ SV* obj, MAGIC* mg) {
    if (mg && mg->mg_type == '~' && INL_MAGIC_CHECK(mg->mg_ptr)) {
	SV* pl_obj = ((inline_magic*)mg->mg_ptr)->iter;
	if (pl_obj)
	    SvREFCNT_dec(pl_obj);
    }
    else {
	croak("ERROR: tried to free a non-Ruby object. Aborting.");
    }

    return 0;
}

SV *
new_InlineRubyWrapper(VALUE obj, SV* iter) {
    SV *wrapper = (SV*)newHV();
    SV *self = newRV_noinc(wrapper);
    MAGIC *mg;
    inline_magic priv;

    /* Initialize object */
    priv.key = INL_MAGIC_NUM;
    priv.rb_val = obj;
    priv.iter = iter;
    if (iter)
	SvREFCNT_inc(iter);

    /* bless inst into an Inline::Ruby::Object */
    sv_bless(self, gv_stashpv("Inline::Ruby::Object", 1));

    /* set up magic */
    sv_magic(wrapper, wrapper, '~', (char*)&priv, sizeof(priv));
    mg = mg_find(wrapper, '~');
    mg->mg_virtual = (MGVTBL*)malloc(sizeof(MGVTBL));
    mg->mg_virtual->svt_free = &free_InlineRubyWrapper;

#ifdef I_RB_DEBUG
    Printf(("new_InlineRubyWrapper\n"));
    /*sv_dump(self);
    sv_dump(wrapper);*/
#endif
    return self;
}

int
isa_InlineRubyWrapper(SV* obj) {
#ifdef I_RB_DEBUG
    Printf(("isa_InlineRubyWrapper(%p)\n", obj));
    if (obj) {
	/*sv_dump(obj);*/
	if (SvROK(obj)) {
	    Printf(("SvTYPE(SvRV(obj)) == %i\n", SvTYPE(SvRV(obj))));
	    /*sv_dump(SvRV(obj));*/
	}
    }
#endif
    if (obj && SvROK(obj) && SvTYPE(SvRV(obj)) == SVt_PVHV) {
	SV *wrapped = SvRV(obj);
	MAGIC *mg = mg_find(wrapped, '~');
	Printf(("Okay, object is magic...\n"));
	if (mg && mg->mg_ptr && INL_MAGIC_CHECK(mg->mg_ptr)) {
	    Printf(("Yay, magic found && matched!\n"));
	    return 1;	/* obj is magic, and of the correct type */
	}
	Printf(("Magic not found, or didn't match...\n"));
	return 0;	/* magic, but not the proper type */
    }
    return 0;		/* bloody muggles */
}

inline_magic*
data_InlineRubyWrapper(SV* self) {
    MAGIC *mg = mg_find(SvRV(self), '~');
    return (inline_magic *)mg->mg_ptr;
}

/*============================================================================
 * This class is strictly for Perl subs or closures only. This is great,
 * because Ruby Proc()s can't take blocks, and neither can Perl subs.
 *
 * class PerlProc {
 *    VALUE new_Proc(SV* cref);
 *    void free_PerlProc(VALUE self);
 *    SV* call_PerlProc(VALUE self);
 * };
 *==========================================================================*/
extern VALUE rb_ePerlException;
VALUE cPerlProc;
typedef struct PerlProc {
    SV* cref;
    I32 flags;
} PerlProc;

static void
free_PerlProc(void *data) {
    Safefree(data);
}

static VALUE
new_PerlProc(SV* cref) {
    PerlProc *data;
    VALUE self;

    Newz(527, data, 1, PerlProc);
    if (cref && SvTRUE(cref)) {
	data->cref = cref;
	SvREFCNT_inc(cref);
    }
    data->flags = G_SCALAR | G_EVAL | G_KEEPERR;
    self = Data_Wrap_Struct(cPerlProc, 0, free_PerlProc, data);
    return self;
}

static VALUE
call_PerlProc(VALUE self, VALUE args) {
    dSP;
    PerlProc *data;
    I32 count;
    I32 ax;
    SV *pl_args;
    VALUE rb_retval;

    Printf(("call_PerlProc()...\n"));

    Data_Get_Struct(self, PerlProc, data);

    pl_args = rb2pl(args);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
#ifdef	FLATTEN_CALLBACK_ARGS
    if (SvROK(pl_args) && SvTYPE(SvRV(pl_args)) == SVt_PVAV) {
	AV* av = (AV*) SvRV(pl_args);
	int len = av_len(av) + 1;
	int i;
	for (i=0; i<len; i++) {
	    XPUSHs(sv_2mortal(av_shift(av)));
	}
    }
    else
#endif
	XPUSHs(sv_2mortal(pl_args));
    PUTBACK;

    count = call_sv(data->cref, data->flags);

    if (SvTRUE(ERRSV)) {
	if (data->flags & G_SCALAR)
	{
	    (void)POPs;
	}
	rb_raise(rb_ePerlException, "%s", SvPV_nolen(ERRSV));
	return Qnil;	/* not reached */
    }

    SPAGAIN;
    SP -= count;
    ax = (SP - PL_stack_base) + 1;
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

static VALUE
arity_PerlProc(VALUE self, VALUE args) {
    return INT2FIX(-1);
}

static VALUE
eq_PerlProc(VALUE self, VALUE other) {
    return Qnil;
}

static VALUE
str_PerlProc(VALUE self, VALUE args) {
    return
	rb_str_new2("#<PerlProc: sub, closure, or code reference>");
}

extern VALUE rb_cProc;
void
Init_PerlProc() {
    cPerlProc = rb_define_class("PerlProc", rb_cProc);

    rb_undef_method(cPerlProc, "new");
    rb_define_method(cPerlProc, "call", call_PerlProc, -2);
    rb_define_method(cPerlProc, "arity", arity_PerlProc, 0);
    rb_define_method(cPerlProc, "[]", call_PerlProc, -2);
    rb_define_method(cPerlProc, "==", eq_PerlProc, 1);
    rb_define_method(cPerlProc, "to_s", str_PerlProc, 0);
}

/* Shamelessly stolen from hash.c, in the Ruby sources.
 * This is an iterator callback, which is used to populate the array of hash
 * keys. */
static int
keys_i(VALUE key, VALUE value, VALUE ary) {
    if (key == Qundef) return ST_CONTINUE;
    rb_ary_push(ary, key);
    return ST_CONTINUE;
}

SV *
rb2pl(VALUE obj) {
    SV *rval; /* declared for convenience */

#ifdef EXPOSE_PERL
	/* unwrap Perl objects */

	/* unwrap Perl code refs */
#endif

    switch(TYPE(obj)) {
	case T_OBJECT: /* an instance of a class */
	    rval = new_InlineRubyWrapper(obj, NULL);
	    return rval;
	case T_FIXNUM:
	    /* I haven't figured out how to ask Ruby about signed-ness, or
	     * whether it's a long. There are four macros I could use, and I'm
	     * just picking the one that seems safest: */
	    rval = newSViv(NUM2INT(obj));
	    return rval;
	case T_FLOAT:
	    rval = newSVnv(RFLOAT_VALUE(obj));
	    return rval;
	case T_STRING:
	    rval = newSVpvn(RSTRING_PTR(obj), RSTRING_LEN(obj));
	    return rval;

	case T_ARRAY:
	    {
		/* Convert the Ruby array into a Perl array */
		long i;
		AV *retval = newAV();
		for (i=0; i<RARRAY_LEN(obj); i++) {
		    SV *entry = rb2pl(rb_ary_entry(obj, i));
		    av_push(retval, entry);
		}
		rval = newRV_noinc((SV*)retval);
		return rval;
	    }
	case T_HASH:
	    {
		/* Convert the Ruby hash into a Perl hash */
		VALUE keys = rb_ary_new();
		VALUE key;
		long i;
		HV *retval = newHV();
		/* use keys_i() as a callback to populate the keys */
		st_foreach(RHASH_TBL(obj), &keys_i, keys);
		for (i=0; i<RARRAY_LEN(keys); i++) {
		    SV *entry;
		    char *key_c;
		    STRLEN klen;
		    key = rb_ary_entry(keys, i);
		    entry = rb2pl(rb_hash_aref(obj, key));
		    if (TYPE(key) != T_STRING) {
			/* Perl can only use strings as hash keys.
			 * Use the stringified key, and emit a warning if
			 * warnings are turned on. */
			key = rb_convert_type(key, T_STRING, "String", "to_s");
			/* warn("Warning: stringifying a hash-key may lose info!"); */
		    }
		    key_c = RSTRING_PTR(key);
		    klen = RSTRING_LEN(key);
		    (void)hv_store(retval, key_c, klen, entry, 0);
		}
		rval = newRV_noinc((SV*)retval);
		return rval;
	    }
	case T_FALSE:
	case T_NIL:
	    return &PL_sv_undef;
	case T_TRUE:
	    return newSViv(1);
	case T_SYMBOL:
	{
	    const char *name = rb_id2name(SYM2ID(obj));
	    return newSVpvn(name, strlen(name));
	}
	case T_FILE:
	    /* Why not pass this as a FILE *? */
	case T_REGEXP:
	    /* There's no reason not to translate regexps in the expected
	     * fashion. I suppose the most reasonable way to do this is to
	     * extract the regexp string and re-compile it in Perl. Could
	     * break down if Ruby supports looking up variables inside regexes
	     * as Perl does. */
	default:
	    warn("rb2pl: %i: unrecognized Ruby type\n", TYPE(obj));
	    return &PL_sv_undef;
    }
    return &PL_sv_undef; /* not reached */
}

VALUE
pl2rb(SV *obj) {
    VALUE o;
    if (isa_InlineRubyWrapper(obj)) {
	return INLINE_MAGIC(obj)->rb_val;
    }
#if 0
    else if (sv_isobject(obj)) {
	SV *obj_deref = SvRV(obj);
	HV *stash = SvSTASH(obj_deref);
	char *pkg = HvNAME(stash);
	SV *full_pkg = newSVpvf("main::%s::", pkg);
	VALUE pkg_rb;

	Printf(("A Perl object (%s). Wrapping...\n", SvPV(full_pkg, PL_na)));
    }
#endif
    else if (SvIOKp(obj)) {
	Printf(("integer: %i\n", SvIV(obj)));
	o = INT2FIX(SvIV(obj));
    }
    else if (SvNOKp(obj)) {
	Printf(("float: %f\n", SvNV(obj)));
	o = rb_float_new(SvNV(obj));
    }
    else if (SvPOKp(obj)) {
	STRLEN len;
	char *ptr = SvPV(obj, len);
	Printf(("string: %s\n", ptr));
	o = rb_str_new(ptr, len);
    }
    else if (SvROK(obj) && SvTYPE(SvRV(obj)) == SVt_PVAV) {
	AV *av = (AV*)SvRV(obj);
	int i;
	int len = av_len(av) + 1;
	o = rb_ary_new2(len);

	Printf(("array (%i)\n", len));

	for (i=0; i<len; i++) {
	    SV *tmp = *av_fetch(av, i, 0);
	    rb_ary_store(o, i, pl2rb(tmp));
	}
    }
    else if (SvROK(obj) && SvTYPE(SvRV(obj)) == SVt_PVHV) {
	HV *hv = (HV*)SvRV(obj);
	int len = hv_iterinit(hv);
	int i;

	o = rb_hash_new();

	Printf(("hash (%i)\n", len));

	for (i=0; i<len; i++) {
	    HE *next = hv_iternext(hv);
	    I32 len;
	    char *key = hv_iterkey(next, &len);
	    VALUE key_rb = rb_str_new(key, len);
	    VALUE val_rb = pl2rb(hv_iterval(hv, next));
	    rb_hash_aset(o, key_rb, val_rb);
	}
    }
    else if (SvROK(obj) && SvTYPE(SvRV(obj)) == SVt_PVCV) {
	/* wrap this up in a PerlSub_object */
	Printf(("Yo! Gots myself a coderef here. Wrapping...\n"));
	o = new_PerlProc(obj);
	Printf(("Result: %s\n", STR2CSTR(rb_inspect(o))));
    }
    else {
	o = Qnil;
    }
    Printf(("returning from pl2rb\n"));
    return o;
}
