#include <luaunpanic.h>
#include <stdlib.h>
#include <setjmp.h>
#include <errno.h>
#include <string.h>
#include <stdarg.h>
#include <stddef.h>

#include "luaunpanic_macros.h"
#include "try_throw_catch.h"

typedef struct luaunpanic_userdata {
  char     *panicstring; /* Latest panic string */
  size_t    envpmallocl; /* Allocated size */
  size_t    envpusedl;   /* Used size */
  jmp_buf  *envp;        /* envpusedl jump buffers */
} luaunpanic_userdata_t;

static char *LUAUNPANIC_DEFAULT_PANICSTRING = "";
static char *LUAUNPANIC_UNKNOWN_PANICSTRING = "Could not retreive last error string";
#define LUAUNPANIC_PANIC 1

/****************************************************************************/
static int luaunpanic_atpanic(lua_State *L)
/****************************************************************************/
{
  luaunpanic_userdata_t *LW = (luaunpanic_userdata_t *) lua_getuserdata(L);

  if (LW != NULL) {
    /* free eventual previous error string */
    if (LW->panicstring != NULL) {
      if ((LW->panicstring != LUAUNPANIC_DEFAULT_PANICSTRING) && (LW->panicstring != LUAUNPANIC_UNKNOWN_PANICSTRING)) {
        free(LW->panicstring);
      }
    }

    /* Get current stack information */
    LW->panicstring = (char *) lua_tostring(L, -1);
    /* Always get a duplicate so that we own it */
    if (LW->panicstring != NULL) {
      LW->panicstring = strdup(LW->panicstring);
      if (LW->panicstring == NULL) {
        /* Bad luck -; */
        LW->panicstring = LUAUNPANIC_UNKNOWN_PANICSTRING;
      }
    }
    /* Jump to recovery point */
    THROW(LW, LUAUNPANIC_PANIC);
  }
  /* Done */
  return 0;
}

/****************************************************************************/
short luaunpanic_panicstring(char **panicstringp, lua_State *L)
/****************************************************************************/
{
  luaunpanic_userdata_t *LW;
  short rc;

  if (L == NULL) {
    errno = EINVAL;
    goto err;
  }

  LW = lua_getuserdata(L);
  if (LW == NULL) {
    errno = EINVAL;
    goto err;
  }
  
  if (panicstringp != NULL) {
    *panicstringp = LW->panicstring;
  }

  rc = 0;
  goto done;

 err:
  rc = 1;

 done:
  return rc;
}

/****************************************************************************/
short luaunpanic_newstate(lua_State **Lp, lua_Alloc f, void *ud)
/****************************************************************************/
{
  luaunpanic_userdata_t *LW;
  lua_State *L;
  short rc;

  LW = (luaunpanic_userdata_t *) malloc(sizeof(luaunpanic_userdata_t));
  if (LW == NULL) {
    goto err;
  }

  LW->panicstring = LUAUNPANIC_DEFAULT_PANICSTRING;
  LW->envpmallocl = 0;
  LW->envpusedl   = 0;
  LW->envp        = NULL;

  L = lua_newstate(f, ud);
  if (L == NULL) {
    free(LW);
    goto err;
  }

  /* Set our userdata and panic handler - these functions never fails */
  lua_setuserdata(L, (void *) LW);
  lua_atpanic(L, &luaunpanic_atpanic);

  if (Lp != NULL) {
    *Lp = L;
  }
  rc = 0;
  goto done;

 err:
  rc = 1;

 done:
  return rc;
}

/****************************************************************************/
short luaunpanic_close(lua_State *L)
/****************************************************************************/
{
  short rc = 1;
  luaunpanic_userdata_t *LW;

  if (L == NULL) {
    errno = EINVAL;
  } else {
    LW = lua_getuserdata(L);
    if (LW != NULL) {
      /* Take care, the macros are using LW so we have to manage it as well */
      TRY(LW) {
        lua_close(L);
        rc = 0;
      } FINALLY(LW) {
        if (LW->panicstring != NULL) {
          if ((LW->panicstring != LUAUNPANIC_DEFAULT_PANICSTRING) && (LW->panicstring != LUAUNPANIC_UNKNOWN_PANICSTRING)) {
            free(LW->panicstring);
          }
        }
        if (LW->envp != NULL) {
          free(LW->envp);
        }
        free(LW);
	LW = NULL;
      }
      ETRY(LW);
    } else {
      /* L is not coming from luaunpanic ? You're on your own. */
      lua_close(L);
      rc = 0;
    }
  }

  return rc;
}

static short _luaunpanic_newthread(lua_State **LNp, lua_State *L)
{
  short rc = 1;
  luaunpanic_userdata_t *LW;
  if (L == NULL) {
    errno = EINVAL;
  } else {
    LW = lua_getuserdata(L);
    if (LW != NULL) {
      if (LW->panicstring != NULL) {
        if ((LW->panicstring != LUAUNPANIC_DEFAULT_PANICSTRING) && (LW->panicstring != LUAUNPANIC_UNKNOWN_PANICSTRING)) {
          free(LW->panicstring);
        }
        LW->panicstring = LUAUNPANIC_DEFAULT_PANICSTRING;
      }
      TRY(LW) {
        lua_State *LN = lua_newthread(L);
        if (LNp != NULL) {
	  *LNp = LN;
	}
	rc = 0;
      }
      ETRY(LW);
    } else {
      lua_State *LN = lua_newthread(L);
      if (LNp != NULL) {
	*LNp = LN;
      }
      rc = 0;
    }
  }
  return rc;
}

/****************************************************************************/
short luaunpanic_newthread(lua_State **Lp, lua_State *L)
/****************************************************************************/
{
  luaunpanic_userdata_t *LW = (luaunpanic_userdata_t *) lua_getuserdata(L);
  lua_State *LN;
  short rc;

  if (_luaunpanic_newthread(&LN, L)) {
    goto err;
  }

  /* Set our userdata and panic handler - this is shared with parent */
  lua_setuserdata(LN, (void *) LW);
  lua_atpanic(LN, &luaunpanic_atpanic);

  if (Lp != NULL) {
    *Lp = LN;
  }

  rc = 0;
  goto done;

 err:
  rc = 1;

 done:
  return rc;
}

/****************************************************************************/
short luaunpanicL_newstate(lua_State **Lp)
/****************************************************************************/
{
  luaunpanic_userdata_t *LW;
  lua_State *L;
  short rc;

  LW = (luaunpanic_userdata_t *) malloc(sizeof(luaunpanic_userdata_t));
  if (LW == NULL) {
    goto err;
  }

  LW->panicstring = LUAUNPANIC_DEFAULT_PANICSTRING;
  LW->envpmallocl = 0;
  LW->envpusedl   = 0;
  LW->envp        = NULL;

  L = luaL_newstate();
  if (L == NULL) {
    free(LW);
    goto err;
  }

  /* Set our userdata and panic handler - these functions never fails */
  lua_setuserdata(L, (void *) LW);
  lua_atpanic(L, &luaunpanic_atpanic);

  if (Lp != NULL) {
    *Lp = L;
  }
  rc = 0;
  goto done;

 err:
  rc = 1;

 done:
  return rc;
}

/* From now on we can use generic wrappers */

/*
** ***********************************************************************
** lua.h wrapper
** ***********************************************************************
*/
/*
** version
*/
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
/* MACRO                        wrappername              L_decl_hook,     outputttype         nativecall                      nativeparameters */
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_version,      ,                const lua_Number *, lua_version(L),                 lua_State *L)
/*
** basic stack manipulation
*/
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
/* MACRO                        wrappername              L_decl_hook,     outputttype         nativecall                      nativeparameters */
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_absindex,     ,                int,                lua_absindex(L, idx),           lua_State *L, int idx)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_gettop,       ,                int,                lua_gettop(L),                  lua_State *L)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_settop,       ,                                    lua_settop(L, idx),             lua_State *L, int idx)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_pushvalue,    ,                                    lua_pushvalue(L, idx),          lua_State *L, int idx)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_rotate,       ,                                    lua_rotate(L, idx, n),          lua_State *L, int idx, int n)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_copy,         ,                                    lua_copy(L, fromidx, toidx),    lua_State *L, int fromidx, int toidx)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_checkstack,   ,                int,                lua_checkstack(L, n),           lua_State *L, int n)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_xmove,        ,                                    lua_xmove(L, to, n),            lua_State *L, lua_State *to, int n)
/*
** access functions (stack -> C)
*/
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
/* MACRO                        wrappername              L_decl_hook,     outputttype         nativecall                      nativeparameters */
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_isnumber,     ,                int,                lua_isnumber(L, idx),           lua_State *L, int idx)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_isstring,     ,                int,                lua_isstring(L, idx),           lua_State *L, int idx)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_iscfunction,  ,                int,                lua_iscfunction(L, idx),        lua_State *L, int idx)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_isinteger,    ,                int,                lua_isinteger(L, idx),          lua_State *L, int idx)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_isuserdata,   ,                int,                lua_isuserdata(L, idx),         lua_State *L, int idx)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_type,         ,                int,                lua_type(L, idx),               lua_State *L, int idx)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_typename,     ,                const char *,       lua_typename(L, tp),            lua_State *L, int tp)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_tonumberx,    ,                lua_Number,         lua_tonumberx(L, idx, isnum),   lua_State *L, int idx, int *isnum)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_tointegerx,   ,                lua_Integer,        lua_tointegerx(L, idx, isnum),  lua_State *L, int idx, int *isnum)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_toboolean,    ,                int,                lua_toboolean(L, idx),          lua_State *L, int idx)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_tolstring,    ,                const char *,       lua_tolstring(L, idx, len),     lua_State *L, int idx, size_t *len)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_rawlen,       ,                size_t,             lua_rawlen(L, idx),             lua_State *L, int idx)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_tocfunction,  ,                lua_CFunction,      lua_tocfunction(L, idx),        lua_State *L, int idx)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_touserdata,   ,                void *,             lua_touserdata(L, idx),         lua_State *L, int idx)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_tothread,     ,                lua_State *,        lua_tothread(L, idx),           lua_State *L, int idx)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_topointer,    ,                const void *,       lua_topointer(L, idx),          lua_State *L, int idx)
/*
** Comparison and arithmetic functions
*/
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
/* MACRO                        wrappername              L_decl_hook,     outputttype         nativecall                      nativeparameters */
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_arith,        ,                                    lua_arith(L, op),               lua_State *L, int op)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_rawequal,     ,                int,                lua_rawequal(L, idx1, idx2),    lua_State *L, int idx1, int idx2)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_compare,      ,                int,                lua_compare(L, idx1, idx2, op), lua_State *L, int idx1, int idx2, int op)
/*
** push functions (C -> stack)
*/
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
/* MACRO                        wrappername              L_decl_hook,     outputttype         nativecall                      nativeparameters */
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_pushnil,      ,                                    lua_pushnil(L),                 lua_State *L)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_pushnumber,   ,                                    lua_pushnumber(L, n),           lua_State *L, lua_Number n)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_pushinteger,  ,                                    lua_pushinteger(L, n),          lua_State *L, lua_Integer n)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_pushlstring,  ,                const char *,       lua_pushlstring(L, s, len),     lua_State *L, const char *s, size_t len)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_pushstring,   ,                const char *,       lua_pushstring(L, s),           lua_State *L, const char *s)
#ifdef C_VA_COPY
LUAUNPANIC2ON_NON_VOID_FUNCTION(luaunpanic_pushvfstring, ,                const char *,       lua_pushvfstring(L, fmt, argpcopy), argp, argpcopy, lua_State *L, const char *fmt, va_list argp)
#else
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_pushvfstring, ,                const char *,       lua_pushvfstring(L, fmt, argp), lua_State *L, const char *fmt, va_list argp)
#endif
LUAUNPANIC3ON_NON_VOID_FUNCTION(luaunpanic_pushfstring,  ,                const char *,       lua_pushvfstring(L, fmt, ap),   fmt, ap, lua_State *L, const char *fmt, ...)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_pushcclosure, ,                                    lua_pushcclosure(L, fn, n),     lua_State *L, lua_CFunction fn, int n)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_pushboolean,  ,                                    lua_pushboolean(L, b),          lua_State *L, int b)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_pushlightuserdata,,                                lua_pushlightuserdata(L, p),    lua_State *L, void *p)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_pushthread,   ,                int,                lua_pushthread(L),              lua_State *L)
/*
** get functions (Lua -> stack)
*/
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
/* MACRO                        wrappername              L_decl_hook,     outputttype         nativecall                      nativeparameters */
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_getglobal,    ,                int,                lua_getglobal(L, name),         lua_State *L, const char *name)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_gettable,     ,                int,                lua_gettable(L, idx),           lua_State *L, int idx)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_getfield,     ,                int,                lua_getfield(L, idx, k),        lua_State *L, int idx, const char *k)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_geti,         ,                int,                lua_geti(L, idx, n),            lua_State *L, int idx, lua_Integer n)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_rawget,       ,                int,                lua_rawget(L, idx),             lua_State *L, int idx)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_rawgeti,      ,                int,                lua_rawgeti(L, idx, n),         lua_State *L, int idx, lua_Integer n)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_rawgetp,      ,                int,                lua_rawgetp(L, idx, p),         lua_State *L, int idx, const void *p)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_createtable,  ,                                    lua_createtable(L, narr, nrec), lua_State *L, int narr, int nrec)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_newuserdata,  ,                void *,             lua_newuserdata(L, sz),         lua_State *L, size_t sz)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_getmetatable, ,                int,                lua_getmetatable(L, objindex),  lua_State *L, int objindex)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_getuservalue, ,                int,                lua_getuservalue(L, idx),       lua_State *L, int idx)
/*
** set functions (stack -> Lua)
*/
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
/* MACRO                        wrappername              L_decl_hook,     outputttype         nativecall                      nativeparameters */
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_setglobal,    ,                                    lua_setglobal(L, name),         lua_State *L, const char *name)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_settable,     ,                                    lua_settable(L, idx),           lua_State *L, int idx)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_setfield,     ,                                    lua_setfield(L, idx, k),        lua_State *L, int idx, const char *k)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_seti,         ,                                    lua_seti(L, idx, n),            lua_State *L, int idx, lua_Integer n)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_rawset,       ,                                    lua_rawset(L, idx),             lua_State *L, int idx)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_rawseti,      ,                                    lua_rawseti(L, idx, n),         lua_State *L, int idx, lua_Integer n)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_rawsetp,      ,                                    lua_rawsetp(L, idx, p),         lua_State *L, int idx, const void *p)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_setmetatable, ,                int,                lua_setmetatable(L, objindex),  lua_State *L, int objindex)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_setuservalue, ,                                    lua_setuservalue(L, idx),       lua_State *L, int idx)
/*
** 'load' and 'call' functions (load and run Lua code)
*/
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
/* MACRO                        wrappername              L_decl_hook,     outputttype         nativecall                      nativeparameters */
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_callk,        ,                                    lua_callk(L, nargs, nresults, ctx, k), lua_State *L, int nargs, int nresults, lua_KContext ctx, lua_KFunction k)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_pcallk,       ,                int,                lua_pcallk(L, nargs, nresults, errfunc, ctx, k), lua_State *L, int nargs, int nresults, int errfunc, lua_KContext ctx, lua_KFunction k)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_load,         ,                int,                lua_load(L, reader, dt, chunkname, mode), lua_State *L, lua_Reader reader, void *dt, const char *chunkname, const char *mode)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_dump,         ,                int,                lua_dump(L, writer, data, strip), lua_State *L, lua_Writer writer, void *data, int strip)
/*
** coroutine functions
*/
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
/* MACRO                        wrappername              L_decl_hook,     outputttype         nativecall                      nativeparameters */
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_yieldk,       ,                int,                lua_yieldk(L, nresults, ctx, k), lua_State *L, int nresults, lua_KContext ctx, lua_KFunction k)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_resume,       ,                int,                lua_resume(L, from, narg),      lua_State *L, lua_State *from, int narg)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_status,       ,                int,                lua_status(L),                  lua_State *L)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_isyieldable,  ,                int,                lua_isyieldable(L),             lua_State *L)
/*
** garbage-collection function and options
*/
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
/* MACRO                        wrappername              L_decl_hook,     outputttype         nativecall                      nativeparameters */
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_gc,           ,                int,                lua_gc(L, what, data),          lua_State *L, int what, int data)
/*
** miscellaneous functions
*/
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_error,        ,                int,                lua_error(L),                   lua_State *L)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_next,         ,                int,                lua_next(L, idx),               lua_State *L, int idx)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_concat,       ,                                    lua_concat(L, n),               lua_State *L, int n)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_len,          ,                                    lua_len(L, idx),                lua_State *L, int idx)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_stringtonumber,,               size_t,             lua_stringtonumber(L, s),       lua_State *L, const char *s)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_getallocf,    ,                lua_Alloc,          lua_getallocf(L, ud),           lua_State *L, void **ud)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_setallocf,    ,                                    lua_setallocf(L, f, ud),        lua_State *L, lua_Alloc f, void *ud)
/*
** some useful macros that must be replaced by functions
*/
LUAUNPANIC_IS_XXX(function, ==, LUA_TFUNCTION)
LUAUNPANIC_IS_XXX(table, ==, LUA_TTABLE)
LUAUNPANIC_IS_XXX(lightuserdata, ==, LUA_TLIGHTUSERDATA)
LUAUNPANIC_IS_XXX(nil, ==, LUA_TNIL)
LUAUNPANIC_IS_XXX(boolean, ==, LUA_TBOOLEAN)
LUAUNPANIC_IS_XXX(thread, ==, LUA_TTHREAD)
LUAUNPANIC_IS_XXX(none, ==, LUA_TNONE)
LUAUNPANIC_IS_XXX(noneornil, <=, 0)
/*
** compatibility macros for unsigned conversions that must be replaced by functions
*/
#if defined(LUA_COMPAT_APIINTCASTS)
short luaunpanic_tounsignedx(lua_Unsigned *rcp, lua_State *L, int idx, int *isnum)
{
  lua_Integer luarc;

  if (luaunpanic_tointegerx(&luarc, L, idx, isnum)) {
    return 1;
  }
  if (rcp != NULL) {
    *rcp = (lua_Unsigned) luarc;
  }
  return 0;
}
#endif
/*
** Debug API
*/
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
/* MACRO                        wrappername              L_decl_hook,     outputttype         nativecall                      nativeparameters */
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_getstack,     ,                int,                lua_getstack(L, level, ar),     lua_State *L, int level, lua_Debug *ar)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_getinfo,      ,                int,                lua_getinfo(L, what, ar),       lua_State *L, const char *what, lua_Debug *ar)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_getlocal,     ,                const char *,       lua_getlocal(L, ar, n),         lua_State *L, const lua_Debug *ar, int n)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_setlocal,     ,                const char *,       lua_setlocal(L, ar, n),         lua_State *L, const lua_Debug *ar, int n)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_getupvalue,   ,                const char *,       lua_getupvalue(L, funcindex, n), lua_State *L, int funcindex, int n)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_setupvalue,   ,                const char *,       lua_setupvalue(L, funcindex, n), lua_State *L, int funcindex, int n)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_upvalueid,    ,                void *,             lua_upvalueid(L, fidx, n),      lua_State *L, int fidx, int n)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_upvaluejoin,  ,                                    lua_upvaluejoin(L, fidx1, n1, fidx2, n2), lua_State *L, int fidx1, int n1, int fidx2, int n2)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanic_sethook,      ,                                    lua_sethook(L, func, mask, count), lua_State *L, lua_Hook func, int mask, int count)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_gethook,      ,                lua_Hook,           lua_gethook(L),                 lua_State *L)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_gethookmask,  ,                int,                lua_gethookmask(L),             lua_State *L)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanic_gethookcount, ,                int,                lua_gethookcount(L),            lua_State *L)

/*
** ***********************************************************************
** lauxlib.h wrapper
** ***********************************************************************
*/
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
/* MACRO                        wrappername              L_decl_hook,     outputttype         nativecall                      nativeparameters */
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_checkversion_,,                                   luaL_checkversion_(L, ver, sz), lua_State *L, lua_Number ver, size_t sz)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_getmetafield,,                int,                luaL_getmetafield(L, obj, e),   lua_State *L, int obj, const char *e)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_callmeta,    ,                int,                luaL_callmeta(L, obj, e),       lua_State *L, int obj, const char *e)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_tolstring,   ,                const char *,       luaL_tolstring(L, idx, len),    lua_State *L, int idx, size_t *len)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_argerror,    ,                int,                luaL_argerror(L, arg, extramsg), lua_State *L, int arg, const char *extramsg)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_checklstring,,                const char *,       luaL_checklstring(L, arg, l),   lua_State *L, int arg, size_t *l)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_optlstring,  ,                const char *,       luaL_optlstring(L, arg, def, l), lua_State *L, int arg, const char *def, size_t *l)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_checknumber, ,                lua_Number,         luaL_checknumber(L, arg),       lua_State *L, int arg)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_optnumber,   ,                lua_Number,         luaL_optnumber(L, arg, def),    lua_State *L, int arg, lua_Number def)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_checkinteger,,                lua_Integer,        luaL_checkinteger(L, arg),      lua_State *L, int arg)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_optinteger,  ,                lua_Integer,        luaL_optinteger(L, arg, def),   lua_State *L, int arg, lua_Integer def)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_checkstack,  ,                                    luaL_checkstack(L, sz, msg),    lua_State *L, int sz, const char *msg)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_checktype,   ,                                    luaL_checktype(L, arg, t),      lua_State *L, int arg, int t)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_checkany,    ,                                    luaL_checkany(L, arg),          lua_State *L, int arg)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_newmetatable,,                int,                luaL_newmetatable(L, tname),    lua_State *L, const char *tname)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_setmetatable,,                                    luaL_setmetatable(L, tname),    lua_State *L, const char *tname)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_testudata,   ,                void *,             luaL_testudata(L, ud, tname),   lua_State *L, int ud, const char *tname)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_checkudata,  ,                void *,             luaL_checkudata(L, ud, tname),  lua_State *L, int ud, const char *tname)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_where,       ,                                    luaL_where(L, lvl),             lua_State *L, int lvl)
/* This function needs to be writen explicitle because of the ... */
short luaunpanicL_error (int *rcp, lua_State *L, const char *fmt, ...)
{
  va_list argp;

  va_start(argp, fmt);

  if (luaunpanicL_where(L, 1)) {
    va_end(argp);
    return 1;
  }
  if (luaunpanic_pushvfstring(NULL, L, fmt, argp)) {
    va_end(argp);
    return 1;
  }
  va_end(argp);
  if (luaunpanic_concat(L, 2)) {
    return 1;
  }
  return luaunpanic_error(rcp, L);
}

/* LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_error(int *rcp,lua_State *L, const char *fmt, ...); */
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_checkoption, ,      int,                luaL_checkoption(L, arg, def, lst), lua_State *L, int arg, const char *def, const char *const lst[])
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_fileresult,  ,      int,                luaL_fileresult(L, stat, fname), lua_State *L, int stat, const char *fname)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_execresult,  ,      int,                luaL_execresult(L, stat),       lua_State *L, int stat)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_ref,         ,      int,                luaL_ref(L, t),                 lua_State *L, int t)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_unref,       ,                          luaL_unref(L, t, ref),          lua_State *L, int t, int ref)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_loadfilex,   ,      int,                luaL_loadfilex(L, filename, mode), lua_State *L, const char *filename, const char *mode)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_loadbufferx, ,      int,                luaL_loadbufferx(L, buff, sz, name, mode), lua_State *L, const char *buff, size_t sz, const char *name, const char *mode)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_loadstring,  ,      int,                luaL_loadstring(L, s),          lua_State *L, const char *s)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_len,         ,      lua_Integer,        luaL_len(L, idx),               lua_State *L, int idx)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_gsub,        ,      const char *,       luaL_gsub(L, s, p, r),          lua_State *L, const char *s, const char *p, const char *r)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_setfuncs,    ,                          luaL_setfuncs(L, l, nup),       lua_State *L, const luaL_Reg *l, int nup)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_getsubtable, ,      int,                luaL_getsubtable(L, idx, fname), lua_State *L, int idx, const char *fname)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_traceback,   ,                          luaL_traceback(L, L1, msg, level), lua_State *L, lua_State *L1, const char *msg, int level)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_requiref,    ,                          luaL_requiref(L, modname, openf, glb), lua_State *L, const char *modname, lua_CFunction openf, int glb)
/*
** some useful macros that must be replaced by functions
*/
short luaunpanicL_typename(const char **rcpp, lua_State *L, int tp)
{
  int luatype;

  if (luaunpanic_type(&luatype, L, tp)) {
    return 1;
  }
  return luaunpanic_typename(rcpp, L, luatype);
}

short luaunpanicL_dofile(int *rcp, lua_State *L, const char *fn)
{
  int rc;

  if (luaunpanicL_loadfile(&rc, L, fn)) {
    return 1;
  }

  /* No "panic", but luaL_loadfile itself failed */
  if (rc) {
    if (rcp != NULL) {
      *rcp = rc;
    }
    return 1;
  }

  return luaunpanic_pcall(rcp, L, 0, LUA_MULTRET, 0);
}

short luaunpanicL_dostring(int *rcp, lua_State *L, const char *fn)
{
  int rc;

  if (luaunpanicL_loadstring(&rc, L, fn)) {
    return 1;
  }
  
  /* No "panic", but luaL_loadstring itself failed */
  if (rc) {
    if (rcp != NULL) {
      *rcp = rc;
    }
    return 1;
  }

  return luaunpanic_pcall(rcp, L, 0, LUA_MULTRET, 0);
}
/*
** Generic Buffer manipulation
*/
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
/* MACRO                        wrappername              L_decl_hook,     outputttype         nativecall                      nativeparameters */
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_buffinit,    ,                                    luaL_buffinit(L, B), lua_State *L, luaL_Buffer *B)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_prepbuffsize,lua_State *L = B->L;, char *,        luaL_prepbuffsize(B, sz), luaL_Buffer *B, size_t sz)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_addlstring,  lua_State *L = B->L;,                luaL_addlstring(B, s, l), luaL_Buffer *B, const char *s, size_t l)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_addstring,   lua_State *L = B->L;,                luaL_addstring(B, s), luaL_Buffer *B, const char *s)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_addvalue,    lua_State *L = B->L;,                luaL_addvalue(B), luaL_Buffer *B)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_pushresult,  lua_State *L = B->L;,                luaL_pushresult(B), luaL_Buffer *B)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_pushresultsize,lua_State *L = B->L;,              luaL_pushresultsize(B, sz), luaL_Buffer *B, size_t sz)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicL_buffinitsize,,                char *,             luaL_buffinitsize(L, B, sz), lua_State *L, luaL_Buffer *B, size_t sz)
#if defined(LUA_COMPAT_MODULE)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_pushmodule,  ,                                    luaL_pushmodule(L, modname, sizehint), lua_State *L, const char *modname, int sizehint);
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_openlib,     ,                                    luaL_openlib(L, libname, l, nup), lua_State *L, const char *libname, const luaL_Reg *l, int nup)
#endif
/*
** ***********************************************************************
** lualib.h wrapper
** ***********************************************************************
*/
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
/* MACRO                        wrappername              L_decl_hook,     outputttype         nativecall                      nativeparameters */
/* ------------------------------------------------------------------------------------------------------------------------------------------- */
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicopen_base,     ,                int,                luaopen_base(L),                lua_State *L)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicopen_coroutine,,                int,                luaopen_coroutine(L),           lua_State *L)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicopen_table,    ,                int,                luaopen_table(L),               lua_State *L)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicopen_io,       ,                int,                luaopen_io(L),                  lua_State *L)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicopen_os,       ,                int,                luaopen_os(L),                  lua_State *L)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicopen_string,   ,                int,                luaopen_string(L),              lua_State *L)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicopen_utf8,     ,                int,                luaopen_utf8(L),                lua_State *L)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicopen_bit32,    ,                int,                luaopen_bit32(L),               lua_State *L)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicopen_math,     ,                int,                luaopen_math(L),                lua_State *L)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicopen_debug,    ,                int,                luaopen_debug(L),               lua_State *L)
LUAUNPANIC_ON_NON_VOID_FUNCTION(luaunpanicopen_package,  ,                int,                luaopen_package(L),             lua_State *L)
LUAUNPANIC_ON_VOID_FUNCTION    (luaunpanicL_openlibs,    ,                                    luaL_openlibs(L),               lua_State *L)
