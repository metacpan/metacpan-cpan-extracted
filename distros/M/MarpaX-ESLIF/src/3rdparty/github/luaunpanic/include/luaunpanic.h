#ifndef LUAUNPANIC_H
#define LUAUNPANIC_H

#include <luaunpanic/lua/lua.h>
#include <luaunpanic/lua/lauxlib.h>
#include <luaunpanic/lua/lualib.h>
#include <luaunpanic/export.h>

/* A bit tedious, but here it is:
 *
 * we wrap any lua function with a function that always have the same high-level API:
 * 
 * type lua_xxx(...args...)
 * is wrapped into a function:
 * short lua_xxx_wrapper(type *luaunpanic_result, ...args...)
 *
 * void lua_xxx(...args...)
 * is wrapped into a function:
 * short lua_xxx_wrapper(...args...)
 *
 * In any case, 1 is returned in case of panic (AND ONLY PANIC), 0 in case of success (following lua return code convention)
 *
 * When the output of the wrapper is a false value, it is guaranteed that *luaunpanic_result
 * (if available) contains the result of the native lua call.
 *
 * In other words,
 * a non void lua call, like:
 * -------------------------
 * if (lua_call(xxx)) { yyy } else { zzz }
 *
 * should be translated to:
 *
 * if (luaunpanic_call(&luarc, xxx) || luarcrc) { yyy } else { zzz }
 * 
 * a void lua call, like:
 * -------------------------
 * lua_call(xxx);
 *
 * should be translated to:
 *
 * if (luaunpanic_call(xxx)) goto err;
 * 
 */

#ifdef __cplusplus
extern "C" {
#endif
  /*
  ** error string in case of panic
  */
  luaunpanic_EXPORT short luaunpanic_panicstring(char **panicstringp, lua_State *L);
  /*
  ** ***********************************************************************
  ** lua.h wrapper
  ** ***********************************************************************
  */
  /*
  ** state manipulation
  */
  luaunpanic_EXPORT short luaunpanic_newstate(lua_State **Lp, lua_Alloc f, void *ud);
  luaunpanic_EXPORT short luaunpanic_close(lua_State *L);
  luaunpanic_EXPORT short luaunpanic_newthread(lua_State **Lp, lua_State *L);
  luaunpanic_EXPORT short luaunpanicL_newstate(lua_State **Lp);
  /*
  ** version
  */
  luaunpanic_EXPORT short luaunpanic_version(const lua_Number **rcp, lua_State *L);
  /*
  ** basic stack manipulation
  */
  luaunpanic_EXPORT short luaunpanic_absindex(int *rcp, lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_gettop(int *rcp, lua_State *L);
  luaunpanic_EXPORT short luaunpanic_settop(lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_pushvalue(lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_rotate(lua_State *L, int idx, int n);
  luaunpanic_EXPORT short luaunpanic_copy(lua_State *L, int fromidx, int toidx);
  luaunpanic_EXPORT short luaunpanic_checkstack(int *rcp, lua_State *L, int n);
  luaunpanic_EXPORT short luaunpanic_xmove(lua_State *from, lua_State *to, int n);
  /*
  ** access functions (stack -> C)
  */
  luaunpanic_EXPORT short luaunpanic_isnumber(int *rcp, lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_isstring(int *rcp, lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_iscfunction(int *rcp, lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_isinteger(int *rcp, lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_isuserdata(int *rcp, lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_type(int *rcp, lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_typename(const char **rcpp, lua_State *L, int tp);
  luaunpanic_EXPORT short luaunpanic_tonumberx(lua_Number *rcp, lua_State *L, int idx, int *isnum);
  luaunpanic_EXPORT short luaunpanic_tointegerx(lua_Integer *rcp, lua_State *L, int idx, int *isnum);
  luaunpanic_EXPORT short luaunpanic_toboolean(int *rcp, lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_tolstring(const char **rcpp, lua_State *L, int idx, size_t *len);
  luaunpanic_EXPORT short luaunpanic_rawlen(size_t *rcp, lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_tocfunction(lua_CFunction *rcp, lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_touserdata(void **rcpp, lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_tothread(lua_State **rcpp, lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_topointer(const void **rcpp, lua_State *L, int idx);
  /*
  ** Comparison and arithmetic functions
  */
  luaunpanic_EXPORT short luaunpanic_arith(lua_State *L, int op);
  luaunpanic_EXPORT short luaunpanic_rawequal(int *rcp, lua_State *L, int idx1, int idx2);
  luaunpanic_EXPORT short luaunpanic_compare(int *rcp, lua_State *L, int idx1, int idx2, int op);
  /*
  ** push functions (C -> stack)
  */
  luaunpanic_EXPORT short luaunpanic_pushnil(lua_State *L);
  luaunpanic_EXPORT short luaunpanic_pushnumber(lua_State *L, lua_Number n);
  luaunpanic_EXPORT short luaunpanic_pushinteger(lua_State *L, lua_Integer n);
  luaunpanic_EXPORT short luaunpanic_pushlstring(const char **rcpp, lua_State *L, const char *s, size_t len);
  luaunpanic_EXPORT short luaunpanic_pushstring(const char **rcpp, lua_State *L, const char *s);
  luaunpanic_EXPORT short luaunpanic_pushvfstring(const char **rcpp, lua_State *L, const char *fmt, va_list argp);
  luaunpanic_EXPORT short luaunpanic_pushfstring(const char **rcpp, lua_State *L, const char *fmt, ...);
  luaunpanic_EXPORT short luaunpanic_pushcclosure(lua_State *L, lua_CFunction fn, int n);
  luaunpanic_EXPORT short luaunpanic_pushboolean(lua_State *L, int b);
  luaunpanic_EXPORT short luaunpanic_pushlightuserdata(lua_State *L, void *p);
  luaunpanic_EXPORT short luaunpanic_pushthread(int *rcp, lua_State *L);
  /*
  ** get functions (Lua -> stack)
  */
  luaunpanic_EXPORT short luaunpanic_getglobal(int *rcp, lua_State *L, const char *name);
  luaunpanic_EXPORT short luaunpanic_gettable(int *rcp, lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_getfield(int *rcp, lua_State *L, int idx, const char *k);
  luaunpanic_EXPORT short luaunpanic_geti(int *rcp, lua_State *L, int idx, lua_Integer n);
  luaunpanic_EXPORT short luaunpanic_rawget(int *rcp, lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_rawgeti(int *rcp, lua_State *L, int idx, lua_Integer n);
  luaunpanic_EXPORT short luaunpanic_rawgetp(int *rcp, lua_State *L, int idx, const void *p);
  luaunpanic_EXPORT short luaunpanic_createtable(lua_State *L, int narr, int nrec);
  luaunpanic_EXPORT short luaunpanic_newuserdata(void **rcpp, lua_State *L, size_t sz);
  luaunpanic_EXPORT short luaunpanic_getmetatable(int *rcp, lua_State *L, int objindex);
  luaunpanic_EXPORT short luaunpanic_getuservalue(int *rcp, lua_State *L, int idx);
  /*
  ** set functions (stack -> Lua)
  */
  luaunpanic_EXPORT short luaunpanic_setglobal(lua_State *L, const char *name);
  luaunpanic_EXPORT short luaunpanic_settable(lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_setfield(lua_State *L, int idx, const char *k);
  luaunpanic_EXPORT short luaunpanic_seti(lua_State *L, int idx, lua_Integer n);
  luaunpanic_EXPORT short luaunpanic_rawset(lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_rawseti(lua_State *L, int idx, lua_Integer n);
  luaunpanic_EXPORT short luaunpanic_rawsetp(lua_State *L, int idx, const void *p);
  luaunpanic_EXPORT short luaunpanic_setmetatable(int *rcp, lua_State *L, int objindex);
  luaunpanic_EXPORT short luaunpanic_setuservalue(lua_State *L, int idx);
  /*
  ** 'load' and 'call' functions (load and run Lua code)
  */
  luaunpanic_EXPORT short luaunpanic_callk(lua_State *L, int nargs, int nresults, lua_KContext ctx, lua_KFunction k);
  luaunpanic_EXPORT short luaunpanic_pcallk(int *rcp, lua_State *L, int nargs, int nresults, int errfunc, lua_KContext ctx, lua_KFunction k);
  luaunpanic_EXPORT short luaunpanic_load(int *rcp, lua_State *L, lua_Reader reader, void *dt, const char *chunkname, const char *mode);
  luaunpanic_EXPORT short luaunpanic_dump(int *rcp, lua_State *L, lua_Writer writer, void *data, int strip);
  /*
  ** coroutine functions
  */
  luaunpanic_EXPORT short luaunpanic_yieldk(int *rcp, lua_State *L, int nresults, lua_KContext ctx, lua_KFunction k);
  luaunpanic_EXPORT short luaunpanic_resume(int *rcp, lua_State *L, lua_State *from, int narg);
  luaunpanic_EXPORT short luaunpanic_status(int *rcp, lua_State *L);
  luaunpanic_EXPORT short luaunpanic_isyieldable(int *rcp, lua_State *L);
  /*
  ** garbage-collection function and options
  */
  luaunpanic_EXPORT short luaunpanic_gc(int *rcp, lua_State *L, int what, int data);
  /*
  ** miscellaneous functions
  */
  luaunpanic_EXPORT short luaunpanic_error(int *rcp, lua_State *L);
  luaunpanic_EXPORT short luaunpanic_next(int *rcp, lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_concat(lua_State *L, int n);
  luaunpanic_EXPORT short luaunpanic_len(lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanic_stringtonumber(size_t *rcp, lua_State *L, const char *s);
  luaunpanic_EXPORT short luaunpanic_getallocf(lua_Alloc *rcp, lua_State *L, void **ud);
  luaunpanic_EXPORT short luaunpanic_setallocf(lua_State *L, lua_Alloc f, void *ud);
  /*
  ** some useful macros that must be replaced by functions
  */
  luaunpanic_EXPORT short luaunpanic_isfunction(int *rcp, lua_State *L, int n);
  luaunpanic_EXPORT short luaunpanic_istable(int *rcp, lua_State *L, int n);
  luaunpanic_EXPORT short luaunpanic_islightuserdata(int *rcp, lua_State *L, int n);
  luaunpanic_EXPORT short luaunpanic_isnil(int *rcp, lua_State *L, int n);
  luaunpanic_EXPORT short luaunpanic_isboolean(int *rcp, lua_State *L, int n);
  luaunpanic_EXPORT short luaunpanic_isthread(int *rcp, lua_State *L, int n);
  luaunpanic_EXPORT short luaunpanic_isnone(int *rcp, lua_State *L, int n);
  luaunpanic_EXPORT short luaunpanic_isnoneornil(int *rcp, lua_State *L, int n);
  /*
  ** compatibility macros for unsigned conversions that must be replaced by functions
  */
#if defined(LUA_COMPAT_APIINTCASTS)
  luaunpanic_EXPORT short luaunpanic_tounsignedx(lua_Unsigned *rcp, lua_State *L, int idx, int *isnum);
#endif
  /*
  ** Debug API
  */
  luaunpanic_EXPORT short luaunpanic_getstack(int *rcp, lua_State *L, int level, lua_Debug *ar);
  luaunpanic_EXPORT short luaunpanic_getinfo(int *rcp, lua_State *L, const char *what, lua_Debug *ar);
  luaunpanic_EXPORT short luaunpanic_getlocal(const char **rcp, lua_State *L, const lua_Debug *ar, int n);
  luaunpanic_EXPORT short luaunpanic_setlocal(const char **rcp, lua_State *L, const lua_Debug *ar, int n);
  luaunpanic_EXPORT short luaunpanic_getupvalue(const char **rcp, lua_State *L, int funcindex, int n);
  luaunpanic_EXPORT short luaunpanic_setupvalue(const char **rcp, lua_State *L, int funcindex, int n);
  luaunpanic_EXPORT short luaunpanic_upvalueid(void **rcp, lua_State *L, int fidx, int n);
  luaunpanic_EXPORT short luaunpanic_upvaluejoin(lua_State *L, int fidx1, int n1, int fidx2, int n2);
  luaunpanic_EXPORT short luaunpanic_sethook(lua_State *L, lua_Hook func, int mask, int count);
  luaunpanic_EXPORT short luaunpanic_gethook(lua_Hook *rcp, lua_State *L);
  luaunpanic_EXPORT short luaunpanic_gethookmask(int *rcp, lua_State *L);
  luaunpanic_EXPORT short luaunpanic_gethookcount(int *rcp, lua_State *L);
  /*
  ** ***********************************************************************
  ** lauxlib.h wrapper
  ** ***********************************************************************
  */
  luaunpanic_EXPORT short luaunpanicL_checkversion_(lua_State *L, lua_Number ver, size_t sz);
  luaunpanic_EXPORT short luaunpanicL_getmetafield(int *rcp, lua_State *L, int obj, const char *e);
  luaunpanic_EXPORT short luaunpanicL_callmeta(int *rcp, lua_State *L, int obj, const char *e);
  luaunpanic_EXPORT short luaunpanicL_tolstring(const char **rcp, lua_State *L, int idx, size_t *len);
  luaunpanic_EXPORT short luaunpanicL_argerror(int *rcp, lua_State *L, int arg, const char *extramsg);
  luaunpanic_EXPORT short luaunpanicL_checklstring(const char **rcp, lua_State *L, int arg, size_t *l);
  luaunpanic_EXPORT short luaunpanicL_optlstring(const char **rcp, lua_State *L, int arg, const char *def, size_t *l);
  luaunpanic_EXPORT short luaunpanicL_checknumber(lua_Number *rcp, lua_State *L, int arg);
  luaunpanic_EXPORT short luaunpanicL_optnumber(lua_Number *rcp, lua_State *L, int arg, lua_Number def);
  luaunpanic_EXPORT short luaunpanicL_checkinteger(lua_Integer *rcp, lua_State *L, int arg);
  luaunpanic_EXPORT short luaunpanicL_optinteger(lua_Integer *rcp, lua_State *L, int arg, lua_Integer def);
  luaunpanic_EXPORT short luaunpanicL_checkstack(lua_State *L, int sz, const char *msg);
  luaunpanic_EXPORT short luaunpanicL_checktype(lua_State *L, int arg, int t);
  luaunpanic_EXPORT short luaunpanicL_checkany(lua_State *L, int arg);
  luaunpanic_EXPORT short luaunpanicL_newmetatable(int *rcp, lua_State *L, const char *tname);
  luaunpanic_EXPORT short luaunpanicL_setmetatable(lua_State *L, const char *tname);
  luaunpanic_EXPORT short luaunpanicL_testudata(void **rcp, lua_State *L, int ud, const char *tname);
  luaunpanic_EXPORT short luaunpanicL_checkudata(void **rcp, lua_State *L, int ud, const char *tname);
  luaunpanic_EXPORT short luaunpanicL_where(lua_State *L, int lvl);
  luaunpanic_EXPORT short luaunpanicL_error(int *rcp, lua_State *L, const char *fmt, ...);
  luaunpanic_EXPORT short luaunpanicL_checkoption(int *rcp, lua_State *L, int arg, const char *def, const char *const lst[]);
  luaunpanic_EXPORT short luaunpanicL_fileresult(int *rcp, lua_State *L, int stat, const char *fname);
  luaunpanic_EXPORT short luaunpanicL_execresult(int *rcp, lua_State *L, int stat);
  luaunpanic_EXPORT short luaunpanicL_ref(int *rcp, lua_State *L, int t);
  luaunpanic_EXPORT short luaunpanicL_unref(lua_State *L, int t, int ref);
  luaunpanic_EXPORT short luaunpanicL_loadfilex(int *rcp, lua_State *L, const char *filename, const char *mode);
  luaunpanic_EXPORT short luaunpanicL_loadbufferx(int *rcp, lua_State *L, const char *buff, size_t sz, const char *name, const char *mode);
  luaunpanic_EXPORT short luaunpanicL_loadstring(int *rcp, lua_State *L, const char *s);
  luaunpanic_EXPORT short luaunpanicL_len(lua_Integer *rcp, lua_State *L, int idx);
  luaunpanic_EXPORT short luaunpanicL_gsub(const char **rcp, lua_State *L, const char *s, const char *p, const char *r);
  luaunpanic_EXPORT short luaunpanicL_setfuncs(lua_State *L, const luaL_Reg *l, int nup);
  luaunpanic_EXPORT short luaunpanicL_getsubtable(int *rcp, lua_State *L, int idx, const char *fname);
  luaunpanic_EXPORT short luaunpanicL_traceback(lua_State *L, lua_State *L1, const char *msg, int level);
  luaunpanic_EXPORT short luaunpanicL_requiref(lua_State *L, const char *modname, lua_CFunction openf, int glb);
  /*
  ** some useful macros that must be replaced by functions
  */
  luaunpanic_EXPORT short luaunpanicL_typename(const char **rcpp, lua_State *L, int tp);
  luaunpanic_EXPORT short luaunpanicL_dofile(int *rcp, lua_State *L, const char *fn);
  luaunpanic_EXPORT short luaunpanicL_dostring(int *rcp, lua_State *L, const char *fn);
  /*
  ** Generic Buffer manipulation
  */
  luaunpanic_EXPORT short luaunpanicL_buffinit(lua_State *L, luaL_Buffer *B);
  luaunpanic_EXPORT short luaunpanicL_prepbuffsize(char **rcp, luaL_Buffer *B, size_t sz);
  luaunpanic_EXPORT short luaunpanicL_addlstring(luaL_Buffer *B, const char *s, size_t l);
  luaunpanic_EXPORT short luaunpanicL_addstring(luaL_Buffer *B, const char *s);
  luaunpanic_EXPORT short luaunpanicL_addvalue(luaL_Buffer *B);
  luaunpanic_EXPORT short luaunpanicL_pushresult(luaL_Buffer *B);
  luaunpanic_EXPORT short luaunpanicL_pushresultsize(luaL_Buffer *B, size_t sz);
  luaunpanic_EXPORT short luaunpanicL_buffinitsize(char **rcp, lua_State *L, luaL_Buffer *B, size_t sz);
#if defined(LUA_COMPAT_MODULE)
  luaunpanic_EXPORT short luaunpanicL_pushmodule(lua_State *L, const char *modname, int sizehint);
  luaunpanic_EXPORT short luaunpanicL_openlib(lua_State *L, const char *libname, const luaL_Reg *l, int nup);
#endif
  /*
  ** some useful macros that must be replaced by functions
  */
  /*
  ** ***********************************************************************
  ** lualib.h wrapper
  ** ***********************************************************************
  */
  luaunpanic_EXPORT short luaunpanicopen_base(int *rcp, lua_State *L);
  luaunpanic_EXPORT short luaunpanicopen_coroutine(int *rcp, lua_State *L);
  luaunpanic_EXPORT short luaunpanicopen_table(int *rcp, lua_State *L);
  luaunpanic_EXPORT short luaunpanicopen_io(int *rcp, lua_State *L);
  luaunpanic_EXPORT short luaunpanicopen_os(int *rcp, lua_State *L);
  luaunpanic_EXPORT short luaunpanicopen_string(int *rcp, lua_State *L);
  luaunpanic_EXPORT short luaunpanicopen_utf8(int *rcp, lua_State *L);
  luaunpanic_EXPORT short luaunpanicopen_bit32(int *rcp, lua_State *L);
  luaunpanic_EXPORT short luaunpanicopen_math(int *rcp, lua_State *L);
  luaunpanic_EXPORT short luaunpanicopen_debug(int *rcp, lua_State *L);
  luaunpanic_EXPORT short luaunpanicopen_package(int *rcp, lua_State *L);
  luaunpanic_EXPORT short luaunpanicL_openlibs(lua_State *L);
#ifdef __cplusplus
}
#endif /* __cplusplus */

/*
** ***********************************************************************
** lua.h macro wrapper
** ***********************************************************************
*/
#define luaunpanic_call(L,n,r)           luaunpanic_callk(L, (n), (r), 0, NULL)
#define luaunpanic_pcall(rcp, L,n,r,f)   luaunpanic_pcallk(rcp, L, (n), (r), (f), 0, NULL)
#define luaunpanic_yield(rcp, L,n)       luaunpanic_yieldk(rcp, L, (n), 0, NULL)
#define luaunpanic_getextraspace(rcp, L) (if (rcp != NULL) { rcp = ((void *)((char *)(L) - LUA_EXTRASPACE)); }, 0)
#define luaunpanic_tonumber(rcp, L,i)    luaunpanic_tonumberx(rcp, L,(i),NULL)
#define luaunpanic_tointeger(rcp, L,i)   luaunpanic_tointegerx(rcp, L,(i),NULL)
#define luaunpanic_pop(L,n)              luaunpanic_settop(L, -(n)-1)
#define luaunpanic_newtable(L)           luaunpanic_createtable(L, 0, 0)
#define luaunpanic_register(L,n,f)       (luaunpanic_pushcfunction(L, (f)) || luaunpanic_setglobal(L, (n)))
#define luaunpanic_pushcfunction(L,f)    luaunpanic_pushcclosure(L, (f), 0)
#define luaunpanic_pushliteral(rcp, L, s) luaunpanic_pushstring(rcp, L, "" s)
#define luaunpanic_pushglobaltable(L)    luaunpanic_rawgeti(NULL, L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS)
#define luaunpanic_tostring(rcp, L,i)    luaunpanic_tolstring(rcp, L, (i), NULL)
#define luaunpanic_insert(L,idx)	 luaunpanic_rotate(L, (idx), 1)
#define luaunpanic_remove(L,idx)         (luaunpanic_rotate(L, (idx), -1) || luaunpanic_pop(L, 1))
#define luaunpanic_replace(L,idx)        (luaunpanic_copy(L, -1, (idx)) || luaunpanic_pop(L, 1))
/*
** compatibility macros for unsigned conversions
*/
#if defined(LUA_COMPAT_APIINTCASTS)
#define luaunpanic_pushunsigned(L,n) luaunpanic_pushinteger(L, (lua_Integer)(n))
#define luaunpanic_tounsigned(rcp, L,i) luaunpanic_tounsignedx(rcp, L,(i),NULL)
#endif
/*
** ***********************************************************************
** lauxlib.h macro wrapper
** ***********************************************************************
*/
#define luaunpanicL_checkversion(L)    luaunpanicL_checkversion_(L, LUA_VERSION_NUM, LUAL_NUMSIZES)
#define luaunpanicL_loadfile(rcp, L,f) luaunpanicL_loadfilex(rcp,L,f,NULL)
/*
** some useful macros
*/
#define luaunpanicL_newlibtable(L,l) luaunpanic_createtable(L, 0, sizeof(l)/sizeof((l)[0]) - 1)
#define luaunpanicL_newlib(L,l)      (luaunpanicL_checkversion(L) || luaunpanicL_newlibtable(L,l) || luaunpanicL_setfuncs(L,l,0))
/* luaunpanicL_argcheck explicitely not wrapped, uses a hack on luaL_argerror() that, when successful and no error handler never returns -; */
#define luaunpanicL_checkstring(rcp, L,n) (luaunpanicL_checklstring(rcp, L, (n), NULL))
#define luaunpanicL_optstring(rcp, L,n,d) (luaunpanicL_optlstring(rcp, L, (n), (d), NULL))
#define luaunpanicL_getmetatable(rcp, L,n) (luaunpanic_getfield(rcp, L, LUA_REGISTRYINDEX, (n)))
/* luaunL_opt(L,f,n,d) cannot be wrapped easily */
#define luaunpanicL_loadbuffer(rcp, L,s,sz,n) luaunpanicL_loadbufferx(rcp, L,s,sz,n,NULL)
#define luaunpanicL_addchar(B,c) (((B)->n < (B)->size || (!luaunpanicL_prepbuffsize(NULL, (B), 1))) ? 0 : ((B)->b[(B)->n++] = (c), 0)) /* unsafe */
#define luaunpanicL_addsize(B,s) ((B)->n += (s), 0)

/* compatibility with old module system */
#if defined(LUA_COMPAT_MODULE)
#define luaunpanicL_register(L,n,l) (luaunpanicL_openlib(L,(n),(l),0))
#endif

#endif /* LUAUNPANIC_H */
