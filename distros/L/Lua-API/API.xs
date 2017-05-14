#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>

#include "ppport.h"

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#if LUA_VERSION_NUM < 501

#error "This requires at least version 5.1 of Lua"

#endif

#include "const-c.inc"

#define MY_CXT_KEY "Lua::API::_guts" XS_VERSION

typedef struct {
    HV *OOB;
} my_cxt_t;

START_MY_CXT


/*-------------------------------------------------------------------*/
/* Support for out-of-band data

   Lua interfaces to C functions, not Perl ones, and they must be
   declared at compile time (can't create them on the fly) so we
   use trampoline C functions to call Perl.  Sometimes its possible
   to attach routing information (via Lua C closures) so that the
   trampoline knows which Perl function to call.  Sometimes its not.

   In the latter case, for certain classes of uses (such as hooks) we
   can deduce which Perl function to call based upon some extra piece
   of data needs to be stored somewhere.  This provides that facility.

   We keep track of the out-of-band data in a Perl hash, keyed off of
   a pointer address (like an inside-out object). We could
   have created a LuaInterpreter Object which contains both the
   lua_State pointer and any other instance specific data, but that
   makes using the automated XS calling of Lua functions much more
   messy.

*/

/* The OOB hash stores data keyed off of a pointer.  Its values are
   hashes */

static
HV* get_oob_entry( void *ptr )
{
    dMY_CXT;
    HV* oob;

    {
	SV ** svp = hv_fetch( MY_CXT.OOB, (const char*) &ptr, sizeof(ptr), 1 );
	if ( svp == NULL )
	    croak( "Perl Lua::API: error getting OOB hash\n" );

	/* if not defined, has not yet been created; do so */
	if ( ! SvOK( *svp) )
	{
	    HV *t_hv = newHV();
	    SV *t_rv = newRV_inc( (SV*) t_hv );
	    svp = hv_store( MY_CXT.OOB, (const char*) &ptr, sizeof(ptr), t_rv, 0);
	}

	oob = (HV*) SvRV(*svp);

	if ( SVt_PVHV != SvTYPE(oob) )
	    croak( "Perl Lua::API: OOB entry  %p is not a hash\n", (void *) ptr );
    }

    return oob;
}

static
SV * delete_oob_entry( void *ptr )
{
    dMY_CXT;

    return hv_delete( MY_CXT.OOB, (const char*) &ptr, sizeof(ptr), 0 );
}


/*-------------------------------------------------------------------*/
/* Mapping lua_State* to Lua::API::State objects

   When Lua calls the trampolines, its passes in a lua_State*.  Perl,
   however, wants a Lua::API::State object.  We could create them on the
   fly from the lua_State* (since there's nothing in the Lua::API::State
   object but a lua_State*), but then Lua::API::State::DESTROY would get
   called whenever the temporary objects are destroyed, which
   is not good.

   Instead, we keep track of the original Lua::API::State object in the OOB
   hash.
 */

static
SV* get_Perl_object( void *ptr )
{
    SV** svp = hv_fetch( get_oob_entry( ptr ), "object", 5, 0 );
    if ( svp == NULL )
	croak( "Perl Lua::API::get_Perl_object: error getting object\n" );

    return *svp;
}

static
void set_Perl_object( void *ptr, SV* object )
{
    HV* oob = get_oob_entry( ptr );

    /* store Perl Lua::API::State object keyed off of lua_State pointer */
    SV** svp = hv_fetch( oob, "object", 5, 1 );

    if ( svp == NULL )
	croak( "Perl Lua::API::set_Perl_object: error getting object\n" );

    sv_setsv( *svp, object );
}

#if 0

/*-------------------------------------------------------------------*/
/* panic function to catch errors thrown from Lua API calls.  This is
   used to turn them into Perl exceptions */

static
int set_panic( lua_State *L, jump_buf *env)
{
    HV* oob = get_oob_entry( L );
    SV** svp = hv_fetch(oob, "panic", 5, 1 );

    if ( svp == NULL )
	croak( "Perl Lua::API: error getting panic state\n" );

    if ( env )
    {
	sv_setpvn( *svp, env, sizeof(*env) );
    }

    else
    {
	hv_delete( oob, "panic", 4, G_DISCARD );
    }
}

static
int panic( Lua_State *L )
{
    HV* oob = get_oob_entry( L );
    SV** svp = hv_fetch(oob, "panic", 5, 1 );

    if ( svp == NULL )
	croak( "Perl Lua::API: error getting panic state\n" );



}
#endif

/*-------------------------------------------------------------------*/
/* Support for hooks */


static
void set_hook( lua_State *L, SV* func )
{
    HV* oob = get_oob_entry( L );
    SV** svp = hv_fetch( oob, "hook", 4, 1 );

    if ( svp == NULL )
	croak( "Perl Lua::API: error getting hook\n" );

    if ( SvOK(func) )
    {
	sv_setsv( *svp, func );
    }

    else
    {
	hv_delete( oob, "hook", 4, G_DISCARD );
    }
}

/* trampoline */
static
void l2p_hook( lua_State *L, lua_Debug *ar )
{
    char *error = NULL;
    STRLEN error_len;
    SV** svp;
    HV* oob = get_oob_entry( L );
    SV* hook;
    dSP;

    svp = hv_fetch( oob, "hook", 4, 0 );
    if ( svp == NULL )
	croak( "Perl Lua::API: error getting hook\n" );
    hook = *svp;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    XPUSHs(get_Perl_object(L));
    XPUSHs(get_Perl_object(ar));

    PUTBACK;

    call_sv( hook, G_EVAL | G_DISCARD );

    SPAGAIN;

    /* catch exceptions */
    if (SvTRUE(ERRSV))
    {
       POPs;

       error = SvPV( ERRSV, error_len );
       /* If this is an exception thrown by Lua::API::State::error(),
          everything is already on the Lua stack and nothing further
          needs to be done.  If not, need to set up stack.
        */
       if ( ! sv_isa( ERRSV, "Lua::API::State::Error" ) )
	  lua_pushstring( L, error );
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    if ( error )
       lua_error( L );
}


/*-------------------------------------------------------------------*/
/* Support for pushcfunction and pushcclosure.
 *
 * The SV pointer is stored as the *last* upvalue for the trampoline
 * routine.  Perl routines which use lua_Debug.nups to get the number
 * of upvalues must decrement it by one to get their true upvalue
 * count.
 *
 */

static
int l2p_closure( lua_State *L )
{
    dSP;
    SV *func;
    char *error = NULL;
    STRLEN error_len;
    int count;
    lua_Debug ar;

    lua_getstack( L, 0, &ar );

    lua_getinfo( L, "u", &ar );

    func = (SV*) lua_touserdata( L, lua_upvalueindex( ar.nups ) );

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(get_Perl_object(L));

    PUTBACK;

    count = call_sv( func, G_EVAL | G_SCALAR);

    /* catch exceptions */
    if (SvTRUE(ERRSV))
    {
       POPs;

       error = SvPV( ERRSV, error_len );
       /* If this is an exception thrown by Lua::API::State::error(),
          everything is already on the Lua stack and nothing further
          needs to be done.  If not, need to set up stack.
        */
       if ( ! sv_isa( ERRSV, "Lua::API::State::Error" ) )
	  lua_pushstring( L, error );
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    if ( error )
       lua_error( L );


    return count;
}

/*-------------------------------------------------------------------*/
/* Support for lua_cpcall.
 *
 * lua_cpcall calls a C function directly with a lightuserdata value
 * on the stack. We can't use a closure to wrap the Perl SV, so, we
 * wrap it explicitly in a structure.  This is the trampoline routine
 * which unwraps it and calls the Perl routine
 *
 */

typedef struct {
    SV *sv;    /* Perl function to call */
    void *ud;  /* user data pointer */
} CPCallData;

static
int l2p_cpcall( lua_State *L ) {
    dSP;
    int count;
    char *error = NULL;
    STRLEN error_len;
    CPCallData *data;


    /* grab our structure... */
    data = (CPCallData *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* ...and replace it with the user data */
    lua_pushlightuserdata( L, data->ud );

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(get_Perl_object(L));
    PUTBACK;

    count = call_sv( (SV*) data->sv, G_EVAL | G_DISCARD);

    SPAGAIN;

    /* catch exceptions */
    if (SvTRUE(ERRSV))
    {
       POPs;

       error = SvPV( ERRSV, error_len );
       /* If this is an exception thrown by Lua::API::State::error(),
          everything is already on the Lua stack and nothing further
          needs to be done.  If not, need to set up stack.
        */
       if ( ! sv_isa( ERRSV, "Lua::API::State::Error" ) )
	  lua_pushstring( L, error );
    }


    PUTBACK;
    FREETMPS;
    LEAVE;

    if ( error )
       lua_error( L );

    return count;
}

/*-------------------------------------------------------------------*/

/* put Lua error object on stack using lua_error. call only from XS
routines.  */

static int
call_lua_error( lua_State *L )
{
  return lua_error( L );
}

static void
throw_lua_error( lua_State *L, char *error )
{
   lua_pushcfunction( L, &call_lua_error );
   lua_pushstring(L, error );
   lua_pcall( L, 1, 0, 0 ); 
}

/* based on code in lauxlib.c */
static void
throw_luaL_error( lua_State *L, const char *fmt, ... )
{
   lua_pushcfunction( L, &call_lua_error );
   va_list argp;
   va_start(argp, fmt);
   luaL_where(L, 1);
   lua_pushvfstring(L, fmt, argp);
   va_end(argp);
   lua_concat(L, 2);
   lua_pcall( L, 1, 0, 0 ); 
}


/*-------------------------------------------------------------------*/


#include "wrap.h"


/*-------------------------------------------------------------------*/

MODULE = Lua::API		PACKAGE = Lua::API

INCLUDE: const-xs.inc

BOOT:
{
    MY_CXT_INIT;
    MY_CXT.OOB = newHV();
}

 # oh, ick

const char *
RELEASE( )
      CODE:
        RETVAL = LUA_RELEASE;
      OUTPUT:
        RETVAL

const char *
COPYRIGHT( )
      CODE :
        RETVAL = LUA_COPYRIGHT;
      OUTPUT:
        RETVAL

MODULE = Lua::API		PACKAGE = Lua::API::State		PREFIX = lua_

lua_CFunction
lua_atpanic(L, panicf)
	lua_State *	L
	lua_CFunction	panicf

void
lua_call(L, nargs, nresults)
	lua_State *	L
	int	nargs
	int	nresults

 # call either lua_checkstack or luaL_checkstack based upon the number
 # of parameters
void
lua_checkstack(L, sz, ...)
	lua_State *	L
	int	  sz
	PPCODE:
	  /* call lua_checkstack */
	  if ( items == 2 )
	  {
	    int status = lua_checkstack( L, sz );
            EXTEND(SP, 1);
            PUSHs(sv_2mortal(newSViv(status)));
	  }
	  /* emulate luaL_checkstack */
	  else if ( items == 3 )
	  {
	    const char *msg = (const char*) SvPV_nolen(ST(2));
	    if ( !lua_checkstack( L, sz ) )
	    {
	       throw_luaL_error( L, "stack overflow (%s)", msg );
	       SV *rv = newSV(0);
	       SV *sv = newSVrv( rv, "Lua::API::State::Error" );
	       sv_setsv((SV*) get_sv("@", GV_ADD), rv);
	       croak(NULL);
	    }
	  }
	  else
	  {
	    croak_xs_usage( cv, "L,sz,[msg]" );
	  }

 # void
 # lua_close(L)
 # 	lua_State *	L


void
lua_concat(L, n)
	lua_State *	L
	int	n

int
lua_cpcall(L, func, ud)
	lua_State *	L
	SV *func
	SV *ud
      PREINIT:
	CPCallData data = { func, ud };
      CODE:
	RETVAL = lua_cpcall( L, l2p_cpcall, &data );
      OUTPUT:
	RETVAL

void
lua_createtable(L, narr, nrec)
	lua_State *	L
	int	narr
	int	nrec

 # No support for lua_Writer

 # int
 # lua_dump(L, writer, data)
 # 	lua_State *	L
 # 	lua_Writer	writer
 # 	void *	data
 #

int
lua_equal(L, idx1, idx2)
	lua_State *	L
	int	idx1
	int	idx2

int
lua_gc(L, what, data)
	lua_State *	L
	int	what
	int	data

lua_Alloc
lua_getallocf(L, ud)
	lua_State *	L
	void **	ud

void
lua_getfenv(L, idx)
	lua_State *	L
	int	idx

void
lua_getfield(L, idx, k)
	lua_State *	L
	int	idx
	const char *	k

int
lua_getgccount(L)
	lua_State *	L

void
lua_getglobal(L, name)
	lua_State *	L
	const char *	name

lua_Hook
lua_gethook(L)
	lua_State *	L

int
lua_gethookcount(L)
	lua_State *	L

int
lua_gethookmask(L)
	lua_State *	L

int
lua_getinfo(L, what, ar)
	lua_State *	L
	const char *	what
	lua_Debug *	ar

const char *
lua_getlocal(L, ar, n)
	lua_State *	L
	const lua_Debug *	ar
	int	n

void
lua_getmetatable(L, ...)
	lua_State *	L
      PPCODE:
	if ( items != 1 )
	    croak_xs_usage( cv, "L,(objindex|name)" );
	if ( looks_like_number( ST(1) ) )
	{
	    int	objindex = (int)SvIV(ST(1));
	    int RETVAL = lua_getmetatable(L, objindex);
	    EXTEND(SP,1);
	    PUSHs(sv_2mortal(newSViv(RETVAL)));
	}
        else
	{
	    const char *n = (const char *)SvPV_nolen(ST(1));
	    luaL_getmetatable(L, n);
	    XSRETURN_EMPTY;
	}

void
lua_getregistry(L)
	lua_State *	L

int
lua_getstack(L, level, ar)
	lua_State *	L
	int	level
	lua_Debug *	ar

void
lua_gettable(L, idx)
	lua_State *	L
	int	idx

int
lua_gettop(L)
	lua_State *	L

const char *
lua_getupvalue(L, funcindex, n)
	lua_State *	L
	int	funcindex
	int	n

void
lua_insert(L, idx)
	lua_State *	L
	int	idx

int
lua_isboolean(L, index)
	lua_State *	L
	int	index

int
lua_iscfunction(L, idx)
	lua_State *	L
	int	idx

int
lua_isfunction(L, index)
	lua_State *	L
	int	index

int
lua_islightuserdata(L, index)
	lua_State *	L
	int	index

int
lua_isnil(L, index)
	lua_State *	L
	int	index

int
lua_isnone(L, index)
	lua_State *	L
	int	index

int
lua_isnoneornil(L, index)
	lua_State *	L
	int	index

int
lua_isnumber(L, idx)
	lua_State *	L
	int	idx

int
lua_isstring(L, idx)
	lua_State *	L
	int	idx

int
lua_istable(L, index)
	lua_State *	L
	int	index

int
lua_isthread(L, index)
	lua_State *	L
	int	index

int
lua_isuserdata(L, idx)
	lua_State *	L
	int	idx

int
lua_lessthan(L, idx1, idx2)
	lua_State *	L
	int	idx1
	int	idx2

 # No support for lua_Reader

 # int
 # lua_load(L, reader, dt, chunkname)
 # 	lua_State *	L
 # 	lua_Reader	reader
 # 	void *	dt
 # 	const char *	chunkname


 # There is currently no support for setting another allocator.
 # luaL_newstate() is used instead.  If an allocator is ever
 # supported, then newstate() should be written to accept either no
 # arguments (and use luaL_newstate) or two (and use lua_newstate).

 # lua_State *
 # lua_newstate(f, ud)
 #         lua_Alloc       f
 #         void *  ud

void
lua_newtable(L)
	lua_State *	L

lua_State *
lua_newthread(L)
	lua_State *	L

void *
lua_newuserdata(L, sz)
	lua_State *	L
	size_t	sz

int
lua_next(L, idx)
	lua_State *	L
	int	idx

size_t
lua_objlen(L, idx)
	lua_State *	L
	int	idx


int
lua_pcall(L, nargs, nresults, errfunc)
	lua_State *	L
	int	nargs
	int	nresults
	int	errfunc

void
lua_pop(L, index)
	lua_State *	L
	int	index

void
lua_pushboolean(L, b)
	lua_State *	L
	int	b

void
lua_pushcclosure(L, fn, n)
	lua_State *	L
	SV *	fn
	int	n
	PREINIT:
	SV *sv_c = newSVsv(fn);
        CODE:
        lua_pushlightuserdata(L, sv_c );
        lua_pushcclosure(L, l2p_closure, n+1 );

void
lua_pushcfunction(L, f)
	lua_State *	L
	SV *f
	PREINIT:
	SV *sv_c = newSVsv(f);
        CODE:
        lua_pushlightuserdata(L, sv_c );
        lua_pushcclosure(L, l2p_closure, 1 );


 # This is (temporarily) in API.pm
 # const char *
 # lua_pushfstring(L, fmt, ...)
 # 	lua_State *	L
 #	const char *	fmt

void
lua_pushinteger(L, n)
	lua_State *	L
	lua_Integer	n

void
lua_pushlightuserdata(L, p)
	lua_State *	L
	void *	p

void
lua_pushlstring(L, s, l)
	lua_State *	L
	const char *	s
	size_t	l

void
lua_pushliteral(L, s)
	lua_State *	L
	const char *	s
       CODE:
         lua_pushlstring(L,s,strlen(s));

void
lua_pushnil(L)
	lua_State *	L

void
lua_pushnumber(L, n)
	lua_State *	L
	lua_Number	n

void
lua_pushstring(L, s)
	lua_State *	L
	const char *	s

int
lua_pushthread(L)
	lua_State *	L

void
lua_pushvalue(L, idx)
	lua_State *	L
	int	idx

 # This is (temporarily) in Lua/API.pm
 # const char *
 # lua_pushvfstring(L, fmt, argp)
 # 	lua_State *	L
 # 	const char *	fmt
 # 	va_list	argp

int
lua_rawequal(L, idx1, idx2)
	lua_State *	L
	int	idx1
	int	idx2

void
lua_rawget(L, idx)
	lua_State *	L
	int	idx

void
lua_rawgeti(L, idx, n)
	lua_State *	L
	int	idx
	int	n

void
lua_rawset(L, idx)
	lua_State *	L
	int	idx

void
lua_rawseti(L, idx, n)
	lua_State *	L
	int	idx
	int	n


void
lua_remove(L, idx)
	lua_State *	L
	int	idx

void
lua_replace(L, idx)
	lua_State *	L
	int	idx

int
lua_resume(L, narg)
	lua_State *	L
	int	narg

 # There is currently no support for setting another allocator.

 # void
 # lua_setallocf(L, f, ud)
 # 	lua_State *	L
 # 	lua_Alloc	f
 # 	void *	ud

int
lua_setfenv(L, idx)
	lua_State *	L
	int	idx

void
lua_setfield(L, idx, k)
	lua_State *	L
	int	idx
	const char *	k

void
lua_setglobal(L, s)
	lua_State *	L
	const char *	s

int
lua_sethook(L, func, mask, count)
	lua_State *	L
	SV	*func
	int	mask
	int	count
     CODE:
        set_hook( L, func );
	RETVAL = lua_sethook( L, SvOK(func) ? l2p_hook : NULL, mask, count );

void
lua_setlevel(from, to)
	lua_State *	from
	lua_State *	to

const char *
lua_setlocal(L, ar, n)
	lua_State *	L
	const lua_Debug *	ar
	int	n

int
lua_setmetatable(L, objindex)
	lua_State *	L
	int	objindex

void
lua_settable(L, idx)
	lua_State *	L
	int	idx

void
lua_settop(L, idx)
	lua_State *	L
	int	idx

const char *
lua_setupvalue(L, funcindex, n)
	lua_State *	L
	int	funcindex
	int	n

int
lua_status(L)
	lua_State *	L

size_t
lua_strlen(L, index)
	lua_State *	L
	int	index

int
lua_toboolean(L, idx)
	lua_State *	L
	int	idx

lua_CFunction
lua_tocfunction(L, idx)
	lua_State *	L
	int	idx

lua_Integer
lua_tointeger(L, idx)
	lua_State *	L
	int	idx

const char *
lua_tolstring(L, idx, len)
	lua_State *	L
	int	idx
	size_t &len

lua_Number
lua_tonumber(L, idx)
	lua_State *	L
	int	idx

const void *
lua_topointer(L, idx)
	lua_State *	L
	int	idx

const char *
lua_tostring(L, index)
	lua_State *	L
	int	index

lua_State *
lua_tothread(L, idx)
	lua_State *	L
	int	idx

SV *
lua_touserdata(L, idx)
	lua_State *	L
	int	idx

int
lua_type(L, idx)
	lua_State *	L
	int	idx

const char *
lua_typename(L, tp)
	lua_State *	L
	int	tp

void
lua_xmove(from, to, n)
	lua_State *	from
	lua_State *	to
	int	n

int
lua_yield(L, nresults)
	lua_State *	L
	int	nresults

int
luaopen_base(L)
	lua_State *	L

int
luaopen_debug(L)
	lua_State *	L

int
luaopen_io(L)
	lua_State *	L

int
luaopen_math(L)
	lua_State *	L

int
luaopen_os(L)
	lua_State *	L

int
luaopen_package(L)
	lua_State *	L

int
luaopen_string(L)
	lua_State *	L

int
luaopen_table(L)
	lua_State *	L



MODULE = Lua::API		PACKAGE = Lua::API::State		PREFIX = luaL_

INCLUDE: xs.h

void
luaL_openlibs(L)
	lua_State *	L

void
luaL_buffinit(L, B)
	lua_State *	L
	luaL_Buffer *	B

int
luaL_callmeta(L, obj, e)
	lua_State *	L
	int	obj
	const char *	e

int
luaL_dofile(L, fn)
	lua_State *	L
	const char *	fn

int
luaL_dostring(L, s)
	lua_State *	L
	const char *	s

 # implemented in Lua/API.pm
 # int
 # luaL_error(L, fmt, ...)
 # 	lua_State *	L
 # 	const char *	fmt

const char *
luaL_findtable(L, idx, fname, szhint)
	lua_State *	L
	int	idx
	const char *	fname
	int	szhint

int
luaL_getmetafield(L, obj, e)
	lua_State *	L
	int	obj
	const char *	e

const char *
luaL_gsub(L, s, p, r)
	lua_State *	L
	const char *	s
	const char *	p
	const char *	r

int
luaL_loadbuffer(L, buff, sz, name)
	lua_State *	L
	const char *	buff
	size_t	sz
	const char *	name

int
luaL_loadfile(L, filename)
	lua_State *	L
	const char *	filename

int
luaL_loadstring(L, s)
	lua_State *	L
	const char *	s

int
luaL_newmetatable(L, tname)
	lua_State *	L
	const char *	tname

lua_State *
luaL_newstate(CLASS)
	char *CLASS = NO_INIT
    PROTOTYPE: $
    ALIAS:
	open = 1
	new = 2
    PPCODE:
        RETVAL = luaL_newstate();
	ST(0) = sv_newmortal();
        sv_setref_iv(ST(0), "Lua::API::State", PTR2IV(RETVAL));
	set_Perl_object( RETVAL, ST(0) );
        XSRETURN(1);


int
luaL_ref(L, t)
	lua_State *	L
	int	t

 # implemented in Lua/API.pm
 # void
 # luaL_register(L, libname, l)
 # 	lua_State *	L
 # 	const char *	libname
 # 	const luaL_Reg *	l

void
luaL_unref(L, t, ref)
	lua_State *	L
	int	t
	int	ref

void
luaL_where(L, lvl)
	lua_State *	L
	int	lvl


MODULE = Lua::API		PACKAGE = Lua::API::State

void
DESTROY( lua_State * L )
     ALIAS:
       close = 1
     CODE:
 	if ( NULL != delete_oob_entry( L ) )
	    lua_close( L );


  # These functions are wrapped in Lua/API.pm, which calls them
  # explicitly, so don't remove the prefix

int
lua_error(L)
	lua_State *	L

void
lua_register(L, name, f)
	lua_State *	L
	const char *	name
 	SV *	f
	PREINIT:
	SV *sv_c = newSVsv(f);
        CODE:
        lua_pushlightuserdata(L, sv_c );
        lua_pushcclosure(L, l2p_closure, 1 );
	lua_setglobal(L, name );

int
lua_getmetatable(L, index)
	lua_State *	L
	int             index

void
luaL_getmetatable(L, n)
	lua_State *	L
	const char *	n

const char *
lua_typename(L, tp)
	lua_State *	L
	int	tp

const char *
luaL_typename(L, i)
	lua_State *	L
	int	i

MODULE = Lua::API		PACKAGE = Lua::API::Debug

lua_Debug *
new(CLASS)
	char *CLASS = NO_INIT
    PROTOTYPE: $
    PPCODE:
        Newxz( RETVAL, 1, lua_Debug );
	ST(0) = sv_newmortal();
        sv_setref_iv(ST(0), "Lua::API::Debug", PTR2IV(RETVAL));
	set_Perl_object( RETVAL, ST(0) );
        XSRETURN(1);

void
DESTROY(THIS)
	lua_Debug * THIS;
    CODE:
        delete_oob_entry( THIS );
        Safefree(THIS);

int
event(THIS)
	lua_Debug * THIS
    PROTOTYPE: $
    CODE:
	RETVAL = THIS->event;
    OUTPUT:
	RETVAL

const char *
name(THIS)
	lua_Debug * THIS
    PROTOTYPE: $
    CODE:
	RETVAL = THIS->name;
    OUTPUT:
	RETVAL

const char *
namewhat(THIS)
	lua_Debug * THIS
    PROTOTYPE: $
    CODE:
	RETVAL = THIS->namewhat;
    OUTPUT:
	RETVAL

const char *
what(THIS)
	lua_Debug * THIS
    PROTOTYPE: $
    CODE:
	RETVAL = THIS->what;
    OUTPUT:
	RETVAL

const char *
source(THIS)
	lua_Debug * THIS
    PROTOTYPE: $
    CODE:
	RETVAL = THIS->source;
    OUTPUT:
	RETVAL

int
currentline(THIS)
	lua_Debug * THIS
    PROTOTYPE: $
    CODE:
	RETVAL = THIS->currentline;
    OUTPUT:
	RETVAL

int
nups(THIS)
	lua_Debug * THIS
    PROTOTYPE: $
    CODE:
	RETVAL = THIS->nups;
    OUTPUT:
	RETVAL

int
linedefined(THIS)
	lua_Debug * THIS
    PROTOTYPE: $
    CODE:
	RETVAL = THIS->linedefined;
    OUTPUT:
	RETVAL

int
lastlinedefined(THIS)
	lua_Debug * THIS
    PROTOTYPE: $
    CODE:
	RETVAL = THIS->lastlinedefined;
    OUTPUT:
	RETVAL

char *
short_src(THIS)
	lua_Debug * THIS
    PROTOTYPE: $
    CODE:
	RETVAL = THIS->short_src;
    OUTPUT:
	RETVAL

MODULE = Lua::API		PACKAGE = Lua::API::Buffer		PREFIX = luaL_

luaL_Buffer *
new(CLASS)
	char *CLASS = NO_INIT
    PROTOTYPE: $
    PPCODE:
        Newxz( RETVAL, 1, luaL_Buffer );
	ST(0) = sv_newmortal();
        sv_setref_iv(ST(0), "Lua::API::Buffer", PTR2IV(RETVAL));
	set_Perl_object( RETVAL, ST(0) );
        XSRETURN(1);

void
DESTROY(THIS)
	luaL_Buffer * THIS;
    CODE:
        delete_oob_entry( THIS );
        Safefree(THIS);


void
luaL_addchar(B, c)
	luaL_Buffer *	B
	char	c

void
luaL_addlstring(B, s, l)
	luaL_Buffer *	B
	const char *	s
	size_t	l

void
luaL_addsize(B, n)
	luaL_Buffer *	B
	size_t	n

void
luaL_addstring(B, s)
	luaL_Buffer *	B
	const char *	s

void
luaL_addvalue(B)
	luaL_Buffer *	B

char *
luaL_prepbuffer(B)
	luaL_Buffer *	B

void
luaL_pushresult(B)
	luaL_Buffer *	B

