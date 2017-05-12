#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef PERL_UNUSED_DECL
#   undef PERL_UNUSED_DECL
#endif

#include "ppport.h"

#include "const-c.inc"

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

/* Support Lua 5.2 */
#if LUA_VERSION_NUM >= 502
#define lua_strlen(L,i) lua_rawlen(L, (i))
#endif

SV *UNDEF, *LuaNil, NIL;
AV *INLINE_RETURN;

/* Called when Lua >= 5.2 closes a Perl filehandle - We don't currently
 * do anything with this.  So we end up leaking :stdio layers (as we
 * also do with 5.1).
 */
static int close_attempt(lua_State *L) { return 0; }


void push_ary	    (lua_State *, AV*);
void push_hash	    (lua_State *, HV*);
void push_val	    (lua_State *, SV*);
void push_func	    (lua_State *, CV*);

SV* bool_ref	    (lua_State *, int);
SV* table_ref	    (lua_State *, int);
SV* func_ref	    (lua_State *L);
SV* user_data	    (lua_State *L);
SV* luaval_to_perl  (lua_State *, int, int*);

static lua_State *INTERPRETER = NULL;

int
is_lua_nil (SV* val) {
    if (sv_isobject(val) && SvIV(SvRV(val)) == (IV)&PL_sv_undef &&
	strEQ(HvNAME(SvSTASH(SvRV(val))), "Inline::Lua::Nil"))
	return 1;
    return 0;
}

/* Non-destructively translate a a number to a string.
 * lua_tostring() can't be used as it turns the value
 * on the stack into a string. */
char *
num2string (lua_Number n, I32 *klen) {
    char s[32];
    char *str;
    STRLEN len;
    sprintf(s, LUA_NUMBER_FMT, n);
    len = *klen = strlen(s)+1;
    New(0, str, len, char);
    Copy(s, str, len, char);
    return str;
}

/* The C-closure responsible for calling Perl functions
 * that were passed to Lua functions by reference.
 * The codereference is passed as lightuserdata and
 * always resides at lua_upvalueindex(1) */
int
trigger_cv (lua_State *L) {
    dSP;
    register int i;
    int dopop;
    int nargs = lua_gettop(L);
    int nresults;

    CV *cv = (CV*)lua_touserdata(L, lua_upvalueindex(1));
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    for (i = 1; i <= nargs; i++) {
	SV *sv = luaval_to_perl(L, i, &dopop);
	XPUSHs(sv_2mortal(sv));
    }
    lua_settop(L, 0);
    PUTBACK;

    nresults = call_sv((SV*)cv, G_ARRAY);

    SPAGAIN;

    /* again the reversed order of values
     * in the Lua stack bites, so we
     * cannot use POPs here */
    for (i = 0; i < nresults; i++) {
	int offset = nresults - i - 1;
	SV *val = *(sp - offset);
	push_val(L, val);
    }
    /* pop all in one go */
    sp -= nresults;

    PUTBACK;
    FREETMPS;
    LEAVE;

    return nresults;
}

/* The callback used by lua_dump to serialize the
 * bytecode */
int
dumper (lua_State *L, const void *p, size_t size, void *f) {
    fwrite(p, size, 1, (FILE*)f);
    return 0;
}

/* push a Perl array onto the Lua stack */
void
push_ary (lua_State *L, AV *av) {
    register int i;
    lua_newtable(L);

    for (i = 0; i <= av_len(av); i++) {
	SV **ptr = av_fetch(av, i, FALSE);
	lua_pushnumber(L, (lua_Number)i+1);
	if (ptr)
	    push_val(L, *ptr);
	else
	    lua_pushnil(L);
	lua_settable(L, -3);
    }
}

/* push a Perl hash onto the Lua stack */
void
push_hash (lua_State *L, HV *hv) {
    register HE* he;

    lua_newtable(L);
    hv_iterinit(hv);

    while (he = hv_iternext(hv)) {
	I32 len;
	char *key;
	key = hv_iterkey(he, &len);
	lua_pushlstring(L, key, len);
	push_val(L, hv_iterval(hv, he));
	lua_settable(L, -3);
    }
}

/* push a Perl function reference onto the Lua stack */
void
push_func (lua_State *L, CV *cv) {
    lua_pushlightuserdata(L, cv);
    lua_pushcclosure(L, trigger_cv, 1);
}

/* turn the Perl glob-reference into a FILE* and push it
 * along with the appropriate metatable onto the Lua stack */
void
push_io (lua_State *L, PerlIO *pio) {
#if LUA_VERSION_NUM < 502
    FILE **fp = (FILE**)lua_newuserdata(L, sizeof(FILE*));
    *fp = PerlIO_exportFILE(pio, NULL);
    luaL_getmetatable(L, "FILE*");
    lua_setmetatable(L, -2);
#else
    // Lua 5.2+
    // We need a close function or Lua thinks the file handle is closed
    luaL_Stream *p = (luaL_Stream *)lua_newuserdata(L, sizeof(luaL_Stream));
    p->f = PerlIO_exportFILE(pio, NULL);
    p->closef = &close_attempt;
    luaL_setmetatable(L, LUA_FILEHANDLE);
#endif
}


/* push a generic reference into the Lua stack:
 * calls one of push_(ary|hash|func|io) */
void
push_ref (lua_State *L, SV *val) {

    switch (SvTYPE(SvRV(val))) {
	case SVt_PVAV:
	    push_ary(L, (AV*)SvRV(val));
	    return;
	case SVt_PVHV:
	    push_hash(L, (HV*)SvRV(val));
	    return;
	case SVt_PVCV:
	    push_func(L, (CV*)SvRV(val));
	    return;
	case SVt_PVGV:
	    push_io(L, IoIFP(sv_2io(SvRV(val))));
	    return;
	default:
	    if (sv_derived_from(val, "Inline::Lua::Boolean")) {
	        lua_pushboolean(L, !!SvIV(SvRV(val)));
	        return;
	    } else {
	        croak("Attempt to pass unsupported reference type (%s) to Lua", sv_reftype(SvRV(val), 0));
	    }
    }
}

/* push a Perl value onto the Lua stack:
 * does the right thing for any Perl type
 * handled by Inline::Lua */
void
push_val (lua_State *L, SV *val) {

    if (is_lua_nil(val)) {
	lua_pushnil(L);
	return;
    }

    if (!val || val == &PL_sv_undef || !SvOK(val)) {
	if (!UNDEF || UNDEF == &PL_sv_undef || !SvOK(UNDEF))
	    lua_pushnil(L);
	else
	    /* otherwise we can safely call push_val again
	     * because Inline::Lua::_undef is defined */
	    push_val(L, UNDEF);
	return;
    }

    switch (SvTYPE(val)) {
	case SVt_IV:
            if(SvROK(val)) {
                push_ref(L, val);
            } else {
                lua_pushnumber(L, (lua_Number)SvIV(val));
            }
	    return;
	case SVt_NV:
	    lua_pushnumber(L, (lua_Number)SvNV(val));
	    return;
	case SVt_PV: case SVt_PVIV:
	case SVt_PVNV: case SVt_PVMG:
	    {
		STRLEN n_a;
		char *cval = SvPV(val, n_a);
		lua_pushlstring(L, cval, n_a);
		return;
	    }
    }
}

/* Turns a Lua type into a Perl type and returns it.
 * 'dopop' is set to 1 if the caller has to do a lua_pop.
 * The only case where this does not happen is if the value
 * is a LUA_TFUNCTION (luaL_ref() already pops it off). */
SV*
luaval_to_perl (lua_State *L, int idx, int *dopop) {
    *dopop = 1;
    switch (lua_type(L, idx)) {
	case LUA_TNIL:
	    return &PL_sv_undef;
	case LUA_TBOOLEAN:
	    return bool_ref(L, lua_toboolean(L, idx));
	case LUA_TNUMBER:
	    return newSVnv(lua_tonumber(L, idx));
	case LUA_TSTRING:
	    return newSVpvn(lua_tostring(L, idx), lua_strlen(L, idx));
	case LUA_TTABLE:
	    return table_ref(L, idx);
	case LUA_TFUNCTION:
	    *dopop = 0;
	    return func_ref(L);
	default:
	    abort();
    }
}

/* Handles the return values of a complete Lua script
 * upon compilation. Return values are converted into
 * Perl types, unshifted into INLINE_RETURN and popped
 * off the Lua stack */
AV*
lua_main_return (lua_State *L, int idx, int num) {
    register int i;
    int nargs = idx - num + 1;

    for (i = 0; i < nargs; i++) {
	int top = idx-i;
	av_unshift(INLINE_RETURN, 1);
	switch (lua_type(L, top)) {
	    case LUA_TNIL:
		av_store(INLINE_RETURN, 0, &PL_sv_undef);
	    case LUA_TBOOLEAN:
		    av_store(INLINE_RETURN, 0, bool_ref(L, lua_toboolean(L, top)));
		    break;
	    case LUA_TNUMBER:
		    av_store(INLINE_RETURN, 0, newSVnv(lua_tonumber(L, top)));
		    break;
	    case LUA_TSTRING:
		    av_store(INLINE_RETURN, 0, newSVpvn(lua_tostring(L, top), lua_strlen(L, top)));
		    break;
	    case LUA_TTABLE:
		    av_store(INLINE_RETURN, 0, table_ref(L, top));
		    break;
	    case LUA_TFUNCTION:
		    av_store(INLINE_RETURN, 0, func_ref(L));
		    break;
	    case LUA_TUSERDATA:
		    av_store(INLINE_RETURN, 0, user_data(L));
		    break;
	    default:
		    croak("Attempt to return unsupported Lua type (%s)", lua_typename(L, lua_type(L, idx)));
	}
    }
    return INLINE_RETURN;
}

/* Lua tables are both an array and a hash but this can't be known in advance.
 * Initially it is assumed that the Lua table can be turned into a plain Perl
 * array. However, once a stringy key is found the strategy has to be switched
 * and the array populated so far is converted into a hash */
HV *
ary_to_hash (AV *ary) {
    register int i;
    int len = av_len(ary);
    HV *hv = newHV();
    SV *key = newSViv(0);
    for (i = 0; i <= len; i++) {
	if (!av_exists(ary, i))
	    continue;
	sv_setiv(key, i+1);	/* +1 because Lua tables start at 1 */
	hv_store_ent(hv, key, *av_fetch(ary, i, FALSE), 0);
    }
    SvREFCNT_dec(key);
    return hv;
}

/* Adds a key/value pair from a Lua table to 'any'.
 * 'any' is a pointer to either an AV* or HV*. When it was
 * an array and the current key is a string, 'isary' is set
 * to false and the array transformed into a hash */
int
add_pair (lua_State *L, SV **any, int *isary) {
#define KEY -2
#define VAL -1
    int dopop;

    if (*isary && lua_type(L, KEY) != LUA_TNUMBER) {
	HV *tbl = ary_to_hash((AV*)*any);
	*isary = 0;
	*any = (SV*)tbl;
    }

    if (*isary) {
	int idx = lua_tonumber(L, KEY);
	SV *val = luaval_to_perl(L, lua_gettop(L), &dopop);
	SvREFCNT_inc(val);
	if (!av_store((AV*)*any, idx-1, val))
	    SvREFCNT_dec(val);
    }
    else {
	const char *key;
	I32 klen;
	SV *val;
	int free = 0;
	switch (lua_type(L, KEY)) {
	    case LUA_TNUMBER:
		{
		lua_Number n = lua_tonumber(L, KEY);
		key = (const char*)num2string(n, &klen);
		free = 1;
		break;
		}
	    case LUA_TSTRING:
		key = lua_tostring(L, KEY);
		klen = lua_strlen(L, KEY);
		break;
	    default:
		croak("Illegal type (%s) in table subscript", lua_typename(L, lua_type(L, KEY)));
	}
	val = luaval_to_perl(L, lua_gettop(L), &dopop);
	SvREFCNT_inc(val);
	if (!hv_store((HV*)*any, key, klen, val, 0))
	    SvREFCNT_dec(val);
	if (free)
	    Safefree(key);
    }

    return dopop;
}

/* Return our Inline::Lua::Boolean datatype.
 *
 * TODO: Try to do this only once (or twice), and return the same TRUE or
 * FALSE reference subsequently. */
SV*
bool_ref (lua_State *L, int b) {
    if (b) {
        return eval_pv("Inline::Lua::Boolean::TRUE", 1);
    } else {
        return eval_pv("Inline::Lua::Boolean::FALSE", 1);
    }
}

/* The Lua table being in the stack at 'idx' is turned into a
 * Perl AV _or_ HV (depending on whether the lua table has a stringy
 * key in it and a reference to that is returned */
SV*
table_ref (lua_State *L, int idx) {
    int isary = 1;	/* initially we always assume it's an array */
    AV *tbl = newAV();

    assert(idx >= 1);

    lua_pushnil(L);
    while (lua_next(L, idx) != 0) {
	if (add_pair(L, (SV**)&tbl,  &isary))
	    lua_pop(L, 1);
    }
    return newRV_noinc((SV*)tbl);
}

/* When a Lua function returns a function to perl, a reference
 * to this function is put into LUA_REGISTRY. Here we call
 * 'create_func_ref' which returns a Perl closure which does
 *	sub { $lua->call( $func, -1, @_ ) }
 * Calling this closure would then trigger the Lua function. */
SV*
func_ref (lua_State *L) {
    dSP;

    SV *lua = sv_newmortal();
    SV *func = newSViv(luaL_ref(L, LUA_REGISTRYINDEX));
    SV *funcref;

    sv_setref_pv(lua, "Inline::Lua", (void*)L);

    ENTER;
    PUSHMARK(SP);
    XPUSHs(lua);		/* $lua */
    XPUSHs(sv_2mortal(func));	/* $func */
    PUTBACK;

    call_pv("Inline::Lua::create_func_ref", G_SCALAR);

    SPAGAIN;
    funcref = POPs;
    SvREFCNT_inc(funcref);
    PUTBACK;
    LEAVE;
    return funcref;
}

/* Handles userdata variables.
 * Those could be filehandles, for instance */

SV*
user_data (lua_State *L) {
    FILE **f = luaL_checkudata(L, 1, "FILE*");

    if (!f)
	croak("Attempt to return unsupported Lua type (userdata)");

    if (*f) {
	PerlIO *pio = PerlIO_importFILE(*f, NULL);
	GV *gv = newGVgen("Inline::Lua");
	if (do_open(gv, "+<&", 3, FALSE, 0, 0, pio)) {
	    SV *sv = NEWSV(0,0);
	    sv_setsv(sv, sv_bless(newRV((SV*)gv), gv_stashpv("Inline::Lua", 1)));
	    return sv;
	} else
	    return &PL_sv_undef;
    } else
	croak("Attempt to return closed filehandle");
}


MODULE = Inline::Lua		PACKAGE = Inline::Lua

BOOT:
{
    LuaNil = get_sv("Inline::Lua::Nil", 1);
    sv_setref_pv(LuaNil, "Inline::Lua::Nil", (void*)&PL_sv_undef);
    SvREADONLY_on(LuaNil);
    INLINE_RETURN = newAV();
}

INCLUDE: const-xs.inc

void
register_undef (CLASS, undef)
	SV *CLASS;
	SV *undef;
    CODE:
    {
	UNDEF = undef;
	SvREFCNT_inc(undef);
    }

lua_State *
interpreter (CLASS, ...)
	char *CLASS;
    CODE:
	{
	    char *from_file = NULL;
	    STRLEN n_a;

	    if (items > 1)
		from_file = SvPV(ST(1), n_a);

	    if (!INTERPRETER) {
		RETVAL = INTERPRETER = luaL_newstate();
		if (INTERPRETER) {
		    luaL_openlibs(INTERPRETER);
		}
	    }
	    else
		RETVAL = INTERPRETER;
	}
    OUTPUT:
	RETVAL

void
destroy (lua)
	lua_State *lua;
    CODE:
    {
	lua_close(lua);
    }

void
compile (lua, code, file, dump)
	lua_State *lua;
	SV *code;
	char *file;
	I32 dump;
    CODE:
    {
	STRLEN len;
	char *codestr = SvPV(code, len);
	int i = 1;
	int status;

	status = luaL_loadbuffer(lua, codestr, len, "_INLINED_LUA");

	if (dump && status == 0) {
	    FILE *f = fopen(file, "w");
	    if (f) {
		lua_dump(lua, dumper, (void*)f);
		fclose(f);
	    } else
		croak("Error outputting bytecode to %s: %s\n", file, strerror(errno));
	    XSRETURN_YES;
	}

	switch (status) {
	    case 0:
		{
		int nargs = lua_gettop(lua);
		if ((lua_pcall(lua, 0, LUA_MULTRET, 0)) == 0) {
		    if (lua_gettop(lua) - nargs >= 0)
			INLINE_RETURN = lua_main_return(lua, lua_gettop(lua), nargs);
		    lua_pop(lua, lua_gettop(lua));
		    XSRETURN_YES;
		}
		else
		    croak("error: %s", lua_tostring(lua, -1));
		break;
		}
	    case LUA_ERRSYNTAX:
		croak("Couldn't compile inline code");
	}
    }

void
call (lua, func, nargs, ...)
	lua_State *lua;
	SV *func;
	int nargs;
    PPCODE:
    {
	char *name;
	int ref;
	int i = 0, j, status;
	int actual_args = 0;

	if (SvPOK(func)) {
	    STRLEN n_a;
	    name = SvPV(func, n_a);
	    lua_getglobal(lua, name);
	} else {
	    /* function reference */
	    lua_rawgeti(lua, LUA_REGISTRYINDEX, SvIV(func));
	}


	/* push arguments */
	for (i = 0; i < items-3; i++, nargs--, actual_args++) {
	    push_val(lua, ST(i+3));
	}

	/* if less arguments were passed than mentioned in the
	 * lua function prototype, pad with 'nil' */
	if (nargs >= 0)
	    for (i = nargs; i > 0; nargs--, actual_args++, i--)
		push_val(lua, NULL);
	status = lua_pcall(lua, actual_args, LUA_MULTRET, 0);

	if (status != 0) {
            SV *error_msg = mess("error: %s\n", lua_tostring(lua, -1));
            lua_pop(lua, 1);
	    croak_sv(error_msg);
        }

	/* return args to caller:
	 * lua functions appear to push their return values in reverse order */
	nargs = lua_gettop(lua);
	EXTEND(SP, nargs);
	j = 1;
	while (i = lua_gettop(lua)) {
	    switch(lua_type(lua, i)) {
		case LUA_TNIL:
		    ST(nargs - j++) = &PL_sv_undef;
		    break;
		case LUA_TNUMBER:
		    ST(nargs - j++) = sv_2mortal(newSVnv(lua_tonumber(lua, i)));
		    break;
		case LUA_TBOOLEAN:
		    ST(nargs - j++) = sv_2mortal(bool_ref(lua, lua_toboolean(lua, i)));
		    break;
		case LUA_TSTRING:
		    {
		    STRLEN len = lua_strlen(lua, i);
		    ST(nargs - j++) = sv_2mortal(newSVpvn(lua_tostring(lua, i), len));
		    }
		    break;
		case LUA_TTABLE:
		    ST(nargs - j++) = sv_2mortal(table_ref(lua, i));
		    break;
		case LUA_TFUNCTION:
		    {
		    ST(nargs - j++) = sv_2mortal(func_ref(lua));
		    goto no_pop;
		    }
		case LUA_TUSERDATA:
		    ST(nargs - j++) = sv_2mortal(user_data(lua));
		    break;
		default:
		    croak("Attempt to return unsupported Lua type (%s)", lua_typename(lua, lua_type(lua, i)));
	    }
	    lua_pop(lua, 1);
	    no_pop:
	    continue;
	}
	XSRETURN(j-1);
    }

void
main_returns (CLASS)
	char *CLASS;
    PPCODE:
	{
	    register int i;
	    int len = av_len(INLINE_RETURN) + 1;
	    EXTEND(SP, len);
	    for (i = 0; i < len; i++) {
		SV **ptr = av_fetch(INLINE_RETURN, i, FALSE);
		if (ptr)
		    PUSHs(*ptr);
		else
		    PUSHs(&PL_sv_undef);
	    }
	    XSRETURN(len);
	}
