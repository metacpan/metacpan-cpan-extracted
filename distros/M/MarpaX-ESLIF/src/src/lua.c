/* #define MARPAESLIFLUA_FORCE_GC */ /* Force Lua GC before and after any call - to be used only when debugging */

/* luaunpanic is great but introduces the setjmp cost that is non-negligible.            */
/* We consider that there are calls to Lua that are safe. If they fail, this mean        */
/* that ESLIF was buggy.                                                                 */
/* The following macros are used to decide which implementation we take:                 */
/* - The luaunpanic, then we are responsible to do the method                            */
/* - The native, then we take the implementation in src/bindings/lua/src/marpaESLIFLua.c */
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_ASSERTSTACK
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHINTEGER
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_SETGLOBAL
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_GETGLOBAL
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TYPE
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_POP
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_NEWTABLE
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHCFUNCTION
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_SETFIELD
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_SETMETATABLE
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_INSERT
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_RAWGETI
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_RAWGET
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_RAWGETP
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_REMOVE
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_CREATETABLE
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_RAWSETI
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_SETI
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHSTRING
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHLSTRING
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHNIL
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_GETFIELD
/* #define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_CALL */
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_SETTOP
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_COPY
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_RAWSETP
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_RAWSET
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHBOOLEAN
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHNUMBER
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHLIGHTUSERDATA
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_NEWUSERDATA
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHVALUE
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_REF
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_UNREF
/* #define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_REQUIREF */
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TOUSERDATA
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TOINTEGER
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TOINTEGERX
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TONUMBER
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TONUMBERX
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TOBOOLEAN
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_TOLSTRING
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TOLSTRING
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TOSTRING
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_COMPARE
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_RAWEQUAL
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_ISNIL
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_GETTOP
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_ABSINDEX
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_NEXT
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_CHECKLSTRING
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_CHECKSTRING
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_CHECKINTEGER
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_OPTINTEGER
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_GETMETATABLE
/* #define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_CALLMETA */
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_GETMETAFIELD
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_CHECKTYPE
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TOPOINTER
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_RAWLEN
/* #define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_DOSTRING */
/* #define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_LOADSTRING */
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHGLOBALTABLE
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_SETTABLE
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_GETTABLE
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_ISINTEGER
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_CHECKUDATA
#define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_NEWTHREAD
/* #define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_CHECKVERSION */
/* #define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_OPENLIBS */
/* #define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_DUMP */
/* #define MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_LOADBUFFER */

#include "marpaESLIF/internal/lua.h"
#include <setjmp.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#ifdef HAVE_LIMITS_H
#  include <limits.h>
#endif

/* Revisit lua context that refers to values inside the lua interpreter */
#undef MARPAESLIFLUA_CONTEXT
#define MARPAESLIFLUA_CONTEXT MARPAESLIF_EMBEDDED_CONTEXT_LUA

/* Revisit some lua macros */
#undef marpaESLIFLua_luaL_error
#define marpaESLIFLua_luaL_error(L, string) luaunpanicL_error(NULL, L, "%s", string)
#undef marpaESLIFLua_luaL_errorf
#define marpaESLIFLua_luaL_errorf(L, formatstring, ...) luaunpanicL_error(NULL, L, formatstring, __VA_ARGS__)
#undef marpaESLIFLua_luaL_newlib
#define marpaESLIFLua_luaL_newlib(L, l) (! luaunpanicL_newlib(L, l))
#include "../src/bindings/lua/src/marpaESLIFLua.c"

#undef  FILENAMES
#define FILENAMES "lua.c" /* For logging */

static inline lua_State *_marpaESLIF_lua_grammar_newp(marpaESLIFGrammar_t *marpaESLIFGrammarp);
static inline lua_State *_marpaESLIF_lua_recognizer_newp(marpaESLIFRecognizer_t *marpaESLIFRecognizerp);
static inline lua_State *_marpaESLIF_lua_value_newp(marpaESLIFValue_t *marpaESLIFValuep);
static inline int        _marpaESLIF_lua_writeri(marpaESLIF_t *marpaESLIFp, char **luaprecompiledpp, size_t *luaprecompiledlp, const void* p, size_t sz);
static int               _marpaESLIF_lua_grammar_writeri(lua_State *L, const void* p, size_t sz, void* ud);
static int               _marpaESLIF_lua_recognizer_writeri(lua_State *L, const void* p, size_t sz, void* ud);
static int               _marpaESLIF_lua_value_writeri(lua_State *L, const void* p, size_t sz, void* ud);
static inline short      _marpaESLIF_lua_value_function_loadb(marpaESLIFValue_t *marpaESLIFValuep);
static inline short      _marpaESLIF_lua_recognizer_function_loadb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp);
static inline short      _marpaESLIF_lua_recognizer_function_precompileb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *luabytep, size_t luabytel, short stripb, int popi);

/* Just to be sure that the compiler would not generate instructions */
/* we exceptionnaly put a semicolumn after the while (0)             */
#ifdef MARPAESLIFLUA_FORCE_GC
#  define LUA_GC(marpaESLIFp, L, what, data) do {                       \
    int _rci = -1;                                                      \
    if (MARPAESLIF_UNLIKELY(luaunpanic_gc(&_rci, L, what, data) || _rci)) { \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, lua_gc);           \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0);
#else
/* No-op: we let Lua decide */
#  define LUA_GC(marpaESLIFp, L, what, data)
#endif

#define MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, f) do {          \
    if (MARPAESLIF_LIKELY(L != NULL)) {                                 \
      const char *_errorstring;                                         \
      if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_lua_tostring(&_errorstring, L, -1))) { \
        MARPAESLIF_ERRORF(marpaESLIFp, "%s failure", #f);               \
      } else {                                                          \
          if (MARPAESLIF_UNLIKELY(_errorstring == NULL)) {              \
          MARPAESLIF_ERRORF(marpaESLIFp, "%s failure", #f);             \
        } else {                                                        \
          MARPAESLIF_ERRORF(marpaESLIFp, "%s", _errorstring);           \
        }                                                               \
      }                                                                 \
    } else {                                                            \
      MARPAESLIF_ERRORF(marpaESLIFp, "%s failure", #f);                 \
    }                                                                   \
  } while (0)

#define LUAL_CHECKVERSION(marpaESLIFp, L) do {                          \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
    if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_luaL_checkversion(L))) {    \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, luaL_checkversion); \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

#define LUAL_OPENLIBS(marpaESLIFp, L) do {                              \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
    if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_luaL_openlibs(L))) {        \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, luaL_openlibs);    \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

#define LUA_DUMP(marpaESLIFp, L, writer, data, strip) do {              \
    int _rci = -1;                                                      \
                                                                        \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
    if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_lua_dump(&_rci, L, writer, data, strip) || _rci)) { \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, lua_dump);         \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

#define LUA_GETFIELD(rcp, marpaESLIFp, L, idx, k) do {                  \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
    if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_lua_getfield(1 /* checkstackb */, rcp, L, idx, k))) { \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, lua_getfield);     \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

#define LUA_REMOVE(marpaESLIFp, L, idx) do {                            \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
    if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_lua_remove(L, idx))) {      \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, lua_remove);       \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

#define LUA_GETGLOBAL(rcp, marpaESLIFp, L, name) do {                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
    if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_lua_getglobal(1 /* checkstackb */, rcp, L, name))) { \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, lua_getglobal);    \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

#define LUA_SETGLOBAL(marpaESLIFp, L, name) do {                        \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
    if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_lua_setglobal(L, name))) {  \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, lua_setglobal);    \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

#define LUAL_LOADBUFFER(marpaESLIFp, L, s, sz, n) do {                  \
    int _rci = -1;                                                      \
                                                                        \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
      if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_luaL_loadbuffer(1 /* checkstackb */, &_rci, L, s, sz, n) || _rci)) { \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, luaL_loadbuffer);  \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

#define LUAL_LOADSTRING(marpaESLIFp, L, s) do {                         \
    int _rci = -1;                                                      \
                                                                        \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
      if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_luaL_loadstring(1 /* checkstackb */, &_rci, L, s) || _rci)) { \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, luaL_loadstring);  \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

#define LUA_GETTOP(marpaESLIFp, L, rcip) do {                           \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
    if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_lua_gettop(rcip, L))) {     \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, lua_gettop);       \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

#define LUA_SETTOP(marpaESLIFp, L, idx) do {                            \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
    if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_lua_settop(L, idx))) {      \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, lua_settop);       \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

#define LUA_INSERT(marpaESLIFp, L, idx) do {                            \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
    if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_lua_insert(1 /* checkstackb */, L, idx))) { \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, lua_insert);       \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

#define LUA_TOUSERDATA(marpaESLIFp, L, rcpp, idx) do {                  \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
    if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_lua_touserdata((void **) rcpp, L, idx))) { \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, lua_touserdata);   \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

#define LUAL_REQUIREF(marpaESLIFp, L, modname, openf, glb) do {         \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
      if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_luaL_requiref(1 /* checkstackb */, L, modname, openf, glb))) { \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, lual_requiref);    \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

#define LUA_NEWSTATE(marpaESLIFp, Lp) do {                              \
    if (MARPAESLIF_UNLIKELY(luaunpanicL_newstate(Lp))) {                \
      /* No L at this stage */                                          \
      MARPAESLIF_ERROR(marpaESLIFp, "luaL_newstate failure");           \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    /* Meaninful only now ;) */                                         \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

#define LUA_CLOSE(marpaESLIFp, L) do {                                  \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
    if (MARPAESLIF_UNLIKELY(luaunpanic_close(L))) {                     \
      /* A priori L was not close, so we can reuse it no ? */           \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, lua_close);        \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    /* No GC here of course ;) */                                       \
  } while (0)

#define LUA_POP(marpaESLIFp, L, n) do {                                 \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
    if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_lua_pop(L, n))) {           \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, lua_pop);          \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

#define LUA_CALL(marpaESLIFp, L, n, r) do {                             \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
    if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_lua_call(L, n, r))) {       \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, lua_call);         \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

#define LUA_PUSHSTRING(sp, marpaESLIFp, L, s) do {                      \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
      if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_lua_pushstring(1 /* checkstackb */, sp, L, s))) { \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, lua_pushstring);   \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

#define LUA_PUSHNIL(marpaESLIFp, L) do {                                \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
      if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_lua_pushnil(1 /* checkstackb */, L))) { \
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, lua_pushnil);      \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)                            \
  } while (0)

/*****************************************************************************/
static inline lua_State *_marpaESLIF_lua_newp(marpaESLIF_t *marpaESLIFp)
/*****************************************************************************/
{
  lua_State *L;

  /* Create Lua state */
  LUA_NEWSTATE(marpaESLIFp, &L);

  /* Open all available libraries */
  LUAL_OPENLIBS(marpaESLIFp, L);

  /* Check Lua version */
  LUAL_CHECKVERSION(marpaESLIFp, L);

  /* Load the marpaESLIFLua library built-in */
  LUAL_REQUIREF(marpaESLIFp, L, "marpaESLIFLua", marpaESLIFLua_installi, 1);                                                    /* stack: marpaESLIFLua */
  LUA_POP(marpaESLIFp, L, 1);                                                                                                   /* stack: */

  /* Inject current marpaESLIFp */
  if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_marpaESLIF_newFromUnmanagedi(L, marpaESLIFp))) {                                     /* stack: marpaESLIF */
    MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, marpaESLIFLua_marpaESLIF_newFromUnmanagedi);
    errno = ENOSYS;
    goto err;
  }
  LUA_SETGLOBAL(marpaESLIFp, L, "marpaESLIF");                                                                                  /* stack: */

  goto done;

 err:
  L = NULL;

 done:
  return L;
}

/*****************************************************************************/
static short _marpaESLIF_lua_value_actionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  static const char             *funcs                 = "_marpaESLIF_lua_value_actionb";
  marpaESLIF_t                  *marpaESLIFp           = marpaESLIFValuep->marpaESLIFp;
  int                            topi                  = -1;
  lua_State                     *L;
  marpaESLIFValueRuleCallback_t  ruleCallbackp;
  short                          rcb;

  L = _marpaESLIF_lua_value_newp(marpaESLIFValuep);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  LUA_GETTOP(marpaESLIFp, L, &topi);

  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
  ruleCallbackp = marpaESLIFLua_valueRuleActionResolver(userDatavp, marpaESLIFValuep, marpaESLIFValuep->actions);
  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
  if (MARPAESLIF_UNLIKELY(MARPAESLIF_UNLIKELY(ruleCallbackp == NULL))) {
    MARPAESLIF_ERROR(marpaESLIFp, "Lua bindings returned no rule callback");
    errno = ENOSYS;
    goto err; /* Lua will shutdown anyway */
  }

  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
  if (MARPAESLIF_UNLIKELY(! ruleCallbackp(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb))) {
    MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, ruleCallbackp);
    errno = ENOSYS;
    goto err;
  }
  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)

  if (topi >= 0) {
    LUA_SETTOP(marpaESLIFp, L, topi);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_lua_value_symbolb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFValueResult_t *marpaESLIFValueResultp, int resulti)
/*****************************************************************************/
{
  static const char               *funcs       = "_marpaESLIF_lua_value_symbolb";
  marpaESLIF_t                    *marpaESLIFp = marpaESLIFValuep->marpaESLIFp;
  int                              topi        = -1;
  lua_State                       *L;
  marpaESLIFValueSymbolCallback_t  symbolCallbackp;
  short                            rcb;

  L = _marpaESLIF_lua_value_newp(marpaESLIFValuep);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  LUA_GETTOP(marpaESLIFp, L, &topi);

  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
  symbolCallbackp = marpaESLIFLua_valueSymbolActionResolver(userDatavp, marpaESLIFValuep, marpaESLIFValuep->actions);
  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
  if (MARPAESLIF_UNLIKELY(symbolCallbackp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFp, "Lua bindings returned no symbol callback");
    errno = ENOSYS;
    goto err; /* Lua will shutdown anyway */
  }

  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
  if (MARPAESLIF_UNLIKELY(! symbolCallbackp(userDatavp, marpaESLIFValuep, marpaESLIFValueResultp, resulti))) {
    MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, symbolCallbackp);
    errno = ENOSYS;
    goto err;
  }
  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)

  if (topi >= 0) {
    LUA_SETTOP(marpaESLIFp, L, topi);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_lua_recognizer_ifactionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFValueResultp, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp)
/*****************************************************************************/
{
  static const char                *funcs       = "_marpaESLIF_lua_recognizer_ifactionb";
  marpaESLIF_t                     *marpaESLIFp = marpaESLIFRecognizerp->marpaESLIFp;
  int                               topi        = -1;
  lua_State                        *L;
  marpaESLIFRecognizerIfCallback_t  ifCallbackp;
  short                             rcb;

  L = _marpaESLIF_lua_recognizer_newp(marpaESLIFRecognizerp);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  LUA_GETTOP(marpaESLIFp, L, &topi);

  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
  ifCallbackp = marpaESLIFLua_recognizerIfActionResolver(userDatavp, marpaESLIFRecognizerp, marpaESLIFRecognizerp->actions);
  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
  if (MARPAESLIF_UNLIKELY(ifCallbackp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFp, "Lua bindings returned no if-action callback");
    errno = ENOSYS;
    goto err; /* Lua will shutdown anyway */
  }

  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
  if (MARPAESLIF_UNLIKELY(! ifCallbackp(userDatavp, marpaESLIFRecognizerp, marpaESLIFValueResultp, marpaESLIFValueResultBoolp))) {
    MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, ifCallbackp);
    errno = ENOSYS;
    goto err;
  }
  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)

  if (topi >= 0) {
    LUA_SETTOP(marpaESLIFp, L, topi);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_lua_recognizer_regexactionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFCalloutBlockp, marpaESLIFValueResultInt_t *marpaESLIFValueResultOutp)
/*****************************************************************************/
{
  static const char                   *funcs       = "_marpaESLIF_lua_recognizer_regexactionb";
  marpaESLIF_t                        *marpaESLIFp = marpaESLIFRecognizerp->marpaESLIFp;
  int                                  topi        = -1;
  lua_State                           *L;
  marpaESLIFRecognizerRegexCallback_t  regexCallbackp;
  short                                rcb;

  L = _marpaESLIF_lua_recognizer_newp(marpaESLIFRecognizerp);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  LUA_GETTOP(marpaESLIFp, L, &topi);

  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
  regexCallbackp = marpaESLIFLua_recognizerRegexActionResolver(userDatavp, marpaESLIFRecognizerp, marpaESLIFRecognizerp->actions);
  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
  if (MARPAESLIF_UNLIKELY(regexCallbackp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFp, "Lua bindings returned no regex-action callback");
    errno = ENOSYS;
    goto err; /* Lua will shutdown anyway */
  }

  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
  if (MARPAESLIF_UNLIKELY(! regexCallbackp(userDatavp, marpaESLIFRecognizerp, marpaESLIFCalloutBlockp, marpaESLIFValueResultOutp))) {
    MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, regexCallbackp);
    errno = ENOSYS;
    goto err;
  }
  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)

  if (topi >= 0) {
    LUA_SETTOP(marpaESLIFp, L, topi);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_lua_recognizer_generatoractionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *contextp, marpaESLIFValueResultString_t *marpaESLIFValueResultOutp)
/*****************************************************************************/
{
  static const char                       *funcs       = "_marpaESLIF_lua_recognizer_generatoractionb";
  marpaESLIF_t                            *marpaESLIFp = marpaESLIFRecognizerp->marpaESLIFp;
  int                                      topi        = -1;
  lua_State                               *L;
  marpaESLIFRecognizerGeneratorCallback_t  generatorCallbackp;
  short                                    rcb;

  L = _marpaESLIF_lua_recognizer_newp(marpaESLIFRecognizerp);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  LUA_GETTOP(marpaESLIFp, L, &topi);

  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
  generatorCallbackp = marpaESLIFLua_recognizerGeneratorActionResolver(userDatavp, marpaESLIFRecognizerp, marpaESLIFRecognizerp->actions);
  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
  if (MARPAESLIF_UNLIKELY(generatorCallbackp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFp, "Lua bindings returned no symbol-generator callback");
    errno = ENOSYS;
    goto err; /* Lua will shutdown anyway */
  }

  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
  if (MARPAESLIF_UNLIKELY(! generatorCallbackp(userDatavp, marpaESLIFRecognizerp, contextp, marpaESLIFValueResultOutp))) {
    MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, generatorCallbackp);
    errno = ENOSYS;
    goto err;
  }
  LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)

  if (topi >= 0) {
    LUA_SETTOP(marpaESLIFp, L, topi);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIF_lua_grammar_precompileb(marpaESLIFGrammar_t *marpaESLIFGrammarp)
/*****************************************************************************/
{
  marpaESLIF_t *marpaESLIFp = marpaESLIFGrammarp->marpaESLIFp;
  short         haveBufferb = ((marpaESLIFGrammarp->luabytep != NULL) && (marpaESLIFGrammarp->luabytel > 0)) ? 1 : 0;
  lua_State    *L;
  short         rcb;

  if (haveBufferb) {

    /* Create a lua state if needed */
    L = _marpaESLIF_lua_grammar_newp(marpaESLIFGrammarp);
    if (MARPAESLIF_UNLIKELY(L == NULL)) {
      goto err;
    }

    if (haveBufferb) {
      LUAL_LOADBUFFER(marpaESLIFp, L, marpaESLIFGrammarp->luabytep, marpaESLIFGrammarp->luabytel, "=<luascript/>");
      /* Result is a "function" at the top of the stack */
      LUA_CALL(marpaESLIFp, L, 0, LUA_MULTRET);                                                                                   /* stack: output1, output2, etc... */
      /* Clear the stack */
      LUA_SETTOP(marpaESLIFp, L, 0);                                                                                              /* stack: */
    }
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static inline lua_State *_marpaESLIF_lua_grammar_newp(marpaESLIFGrammar_t *marpaESLIFGrammarp)
/*****************************************************************************/
{
  lua_State                  *L = marpaESLIFGrammarp->Lsharep->L;
  marpaESLIF_t               *marpaESLIFp;
  
  if (L == NULL) {
    marpaESLIFp = marpaESLIFGrammarp->marpaESLIFp;

    L = _marpaESLIF_lua_newp(marpaESLIFp);
    if (MARPAESLIF_UNLIKELY(L == NULL)) {
      goto err;
    }
    marpaESLIFGrammarp->Lsharep->L = L;

    /* Inject current marpaESLIFGrammar */
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
    if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_marpaESLIFGrammar_newFromUnmanagedi(L, marpaESLIFGrammarp))) {                        /* stack: marpaESLIFGrammar */
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, marpaESLIFLua_marpaESLIFGrammar_newFromUnmanagedi);
      errno = ENOSYS;
      goto err;
    }
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
    LUA_SETGLOBAL(marpaESLIFp, L, "marpaESLIFGrammar");                                                                           /* stack: */
  }

  goto done;

 err:
  L = NULL;

 done:
  return L;
}

/*****************************************************************************/
static inline lua_State *_marpaESLIF_lua_recognizer_newp(marpaESLIFRecognizer_t *marpaESLIFRecognizerp)
/*****************************************************************************/
/* This function can never be called with a NULL marpaESLIFRecognizerp->Lsharep */
/*****************************************************************************/
{
  static const char          *funcs       = "_marpaESLIF_lua_recognizer_newp";
  marpaESLIF_t               *marpaESLIFp = marpaESLIFRecognizerp->marpaESLIFp;
  marpaESLIFGrammar_Lshare_t *Lsharep     = marpaESLIFRecognizerp->Lsharep;
  marpaESLIFRecognizer_t     *marpaESLIFRecognizerUnsharedp;
  lua_State                  *L;

  if (MARPAESLIF_UNLIKELY(_marpaESLIF_lua_grammar_newp(marpaESLIFRecognizerp->marpaESLIFGrammarp) == NULL)) {
    goto err;
  }
  L = Lsharep->L;

  if (Lsharep->marpaESLIFRecognizerUnsharedTopp == NULL) {
    /* Get the unshared top-level recognizer */
    marpaESLIFRecognizerUnsharedp = marpaESLIFRecognizerp;
    while (marpaESLIFRecognizerUnsharedp->marpaESLIFRecognizerSharedp != NULL) {
      marpaESLIFRecognizerUnsharedp = marpaESLIFRecognizerUnsharedp->marpaESLIFRecognizerSharedp;
    }
    Lsharep->marpaESLIFRecognizerUnsharedTopp = marpaESLIFRecognizerUnsharedp->marpaESLIFRecognizerTopp;

    /* Instantiate a marpaESLIFContextStack object */
    LUA_GETGLOBAL(NULL, marpaESLIFp, L, "marpaESLIFContextStack");                                                /* stack: marpaESLIFContextStack */
    LUA_GETFIELD(NULL, marpaESLIFp, L, -1, "new");                                                                /* stack: marpaESLIFContextStack, marpaESLIFContextStack.new */
    LUA_REMOVE(marpaESLIFp, L, -2);                                                                               /* stack: marpaESLIFContextStack.new */
    LUA_CALL(marpaESLIFp, L, 0, 1);                                                                               /* stack: marpaESLIFContextStack.new() output */
    LUA_SETGLOBAL(marpaESLIFp, L, "marpaESLIFContextStackp");                                                     /* stack: */

    /* Reset last injected pointers */
    LUA_PUSHNIL(marpaESLIFp, L);                                                                                  /* stack: nil */
    LUA_SETGLOBAL(marpaESLIFp, L, "marpaESLIFRecognizer");                                                        /* stack: */
    Lsharep->marpaESLIFRecognizerLastInjectedp = NULL;

    LUA_PUSHNIL(marpaESLIFp, L);                                                                                  /* stack: nil */
    LUA_SETGLOBAL(marpaESLIFp, L, "marpaESLIFValue");                                                             /* stack: */
    Lsharep->marpaESLIFValueLastInjectedp      = NULL;
  }

  /* No need to reinject the same recognizer twice */
  if (Lsharep->marpaESLIFRecognizerLastInjectedp != marpaESLIFRecognizerp) {
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
    if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_marpaESLIFRecognizer_newFromUnmanagedi(L, marpaESLIFRecognizerp))) {  /* stack: marpaESLIFRecognizer */
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, marpaESLIFLua_marpaESLIFRecognizer_newFromUnmanagedi);
      errno = ENOSYS;
      goto err;
    }
    LUA_GC(marpaESLIFp, L, LUA_GCCOLLECT, 0)
    Lsharep->marpaESLIFRecognizerLastInjectedp = marpaESLIFRecognizerp;
    LUA_SETGLOBAL(marpaESLIFp, L, "marpaESLIFRecognizer");                                                        /* stack: */
  }

  goto done;

 err:
  L = NULL;

 done:
  return L;
}

/*****************************************************************************/
static inline lua_State *_marpaESLIF_lua_value_newp(marpaESLIFValue_t *marpaESLIFValuep)
/*****************************************************************************/
/* Valuator reuses the recognizer's L. It just updates the global.           */
/* This function can never be called with a NULL marpaESLIFValuep->Lsharep.  */
/*****************************************************************************/
{
  marpaESLIFGrammar_Lshare_t *Lsharep = marpaESLIFValuep->Lsharep;
  lua_State                  *L;

  if (MARPAESLIF_UNLIKELY(_marpaESLIF_lua_recognizer_newp(marpaESLIFValuep->marpaESLIFRecognizerp) == NULL)) {
    errno = ENOSYS;
    goto err;
  }
  L = Lsharep->L;

  /* No need to reinject the same valuator twice */
  if (Lsharep->marpaESLIFValueLastInjectedp != marpaESLIFValuep) {

    LUA_GC(marpaESLIFValuep->marpaESLIFp, L, LUA_GCCOLLECT, 0)
    if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_marpaESLIFValue_newFromUnmanagedi(L, marpaESLIFValuep))) {                   /* stack: marpaESLIFValue */
      MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFValuep->marpaESLIFp, L, marpaESLIFLua_marpaESLIFValue_newFromUnmanagedi);
      errno = ENOSYS;
      goto err;
    }
    LUA_GC(marpaESLIFValuep->marpaESLIFp, L, LUA_GCCOLLECT, 0)
    LUA_SETGLOBAL(marpaESLIFValuep->marpaESLIFp, L, "marpaESLIFValue");                                                  /* stack: */
    Lsharep->marpaESLIFValueLastInjectedp = marpaESLIFValuep;
  }

  goto done;

 err:
  L = NULL;

 done:
  return L;
}

/*****************************************************************************/
static inline void _marpaESLIF_lua_freev(marpaESLIF_t *marpaESLIFp)
/*****************************************************************************/
{
  if (marpaESLIFp->Lshare.L != NULL) {
    LUA_CLOSE(marpaESLIFp, marpaESLIFp->Lshare.L);
    marpaESLIFp->Lshare.L = NULL;
  }
 err:
  return;
}

/*****************************************************************************/
static inline void _marpaESLIF_lua_grammar_freev(marpaESLIFGrammar_t *marpaESLIFGrammarp)
/*****************************************************************************/
{
  marpaESLIFGrammar_Lshare_t *Lsharep = marpaESLIFGrammarp->Lsharep;

  if (Lsharep->L != NULL) {
    if (Lsharep == &(marpaESLIFGrammarp->_Lshare)) {
      /* This grammar is the owner of Lshare */
      LUA_CLOSE(marpaESLIFGrammarp->marpaESLIFp, Lsharep->L);
      Lsharep->L                                  = NULL;
      Lsharep->marpaESLIFRecognizerUnsharedTopp   = NULL;
      Lsharep->marpaESLIFRecognizerLastInjectedp  = NULL;
      Lsharep->marpaESLIFValueLastInjectedp       = NULL;
    }
  }
 err:
  return;
}

/*****************************************************************************/
static inline void _marpaESLIF_lua_value_freev(marpaESLIFValue_t *marpaESLIFValuep)
/*****************************************************************************/
/* Valuator reuses the recognizer's L. It just updates the global.           */
/* This function can never be called with a NULL marpaESLIFValuep->Lsharep.  */
/*****************************************************************************/
{
  marpaESLIFGrammar_Lshare_t *Lsharep = marpaESLIFValuep->Lsharep;

  /* We do not want to call lua if it is not in use */
  if ((Lsharep->L != NULL) && (Lsharep->marpaESLIFRecognizerUnsharedTopp != NULL)) {
    LUA_PUSHNIL(marpaESLIFValuep->marpaESLIFp, Lsharep->L);                                                           /* stack: nil */
    LUA_SETGLOBAL(marpaESLIFValuep->marpaESLIFp, Lsharep->L, "marpaESLIFValue");                                      /* stack: */
    Lsharep->marpaESLIFValueLastInjectedp = NULL;
  }

 err:
  return;
}

/*****************************************************************************/
static inline void _marpaESLIF_lua_recognizer_freev(marpaESLIFRecognizer_t *marpaESLIFRecognizerp)
/*****************************************************************************/
{
  marpaESLIFGrammar_Lshare_t *Lsharep = marpaESLIFRecognizerp->Lsharep;

  /* There exist fake recognizers where grammarp is NULL */
  if (Lsharep != NULL) {

    /* We do not want to call lua if it is not in use */
    if ((Lsharep->L != NULL) && (Lsharep->marpaESLIFRecognizerUnsharedTopp != NULL)) {
      if (Lsharep->marpaESLIFRecognizerUnsharedTopp == marpaESLIFRecognizerp) {
        /* Remove the marpaESLIFContextStack object */
        LUA_PUSHNIL(marpaESLIFRecognizerp->marpaESLIFp, Lsharep->L);                                                    /* stack: nil */
          LUA_SETGLOBAL(marpaESLIFRecognizerp->marpaESLIFp, Lsharep->L, "marpaESLIFContextStackp");                       /* stack: */
          Lsharep->marpaESLIFRecognizerUnsharedTopp = NULL;
      }

      LUA_PUSHNIL(marpaESLIFRecognizerp->marpaESLIFp, Lsharep->L);                                                      /* stack: nil */
      LUA_SETGLOBAL(marpaESLIFRecognizerp->marpaESLIFp, Lsharep->L, "marpaESLIFRecognizer");                            /* stack: */
      Lsharep->marpaESLIFRecognizerLastInjectedp = NULL;
    }
  }

 err:
  return;
}

/*****************************************************************************/
static inline short _marpaESLIF_lua_value_precompileb(marpaESLIFValue_t *marpaESLIFValuep, char *luabytep, size_t luabytel, short stripb, int popi)
/*****************************************************************************/
{
  marpaESLIF_t *marpaESLIFp = marpaESLIFValuep->marpaESLIFp;
  lua_State    *L;
  short         rcb;

  L = _marpaESLIF_lua_value_newp(marpaESLIFValuep);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  /* Compiles lua script */
  LUAL_LOADBUFFER(marpaESLIFp, L, luabytep, luabytel, "=<luafunction/>");

  /* Result is a "function" at the top of the stack - we now have to dump it so that lua knows about it  */
  LUA_DUMP(marpaESLIFp, L, _marpaESLIF_lua_value_writeri, marpaESLIFValuep, stripb);

  if (popi > 0) {
    LUA_POP(marpaESLIFp, L, popi);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static inline int _marpaESLIF_lua_writeri(marpaESLIF_t *marpaESLIFp, char **luaprecompiledpp, size_t *luaprecompiledlp, const void* p, size_t sz)
/*****************************************************************************/
{
  char *q;
  int   rci;

  if (sz > 0) {
    if (*luaprecompiledpp == NULL) {
      *luaprecompiledpp = (char *) malloc(sz);
      if (MARPAESLIF_UNLIKELY(*luaprecompiledpp == NULL)) {
        MARPAESLIF_ERRORF(marpaESLIFp, "malloc failure, %s", strerror(errno));
        goto err;
      }
      q = *luaprecompiledpp;
      *luaprecompiledlp = sz;
    } else {
      q = (char *) realloc(*luaprecompiledpp, *luaprecompiledlp + sz);
      if (MARPAESLIF_UNLIKELY(q == NULL)) {
        MARPAESLIF_ERRORF(marpaESLIFp, "malloc failure, %s", strerror(errno));
        goto err;
      }
      *luaprecompiledpp = q;
      q += *luaprecompiledlp;
      *luaprecompiledlp += sz;
    }

    memcpy(q, p, sz);
  }

  rci = 0;
  goto end;
  
 err:
  rci = 1;
  
 end:
  return rci;
}

/*****************************************************************************/
static int _marpaESLIF_lua_grammar_writeri(lua_State *L, const void* p, size_t sz, void* ud)
/*****************************************************************************/
{
  marpaESLIFGrammar_t *marpaESLIFGrammarp = (marpaESLIFGrammar_t *) ud;

  return _marpaESLIF_lua_writeri(marpaESLIFGrammarp->marpaESLIFp, &(marpaESLIFGrammarp->luaprecompiledp), &(marpaESLIFGrammarp->luaprecompiledl), p, sz);
}

/****************************************************************************/
static int _marpaESLIF_lua_value_writeri(lua_State *L, const void* p, size_t sz, void* ud)
/****************************************************************************/
{
  marpaESLIFValue_t *marpaESLIFValuep = (marpaESLIFValue_t *) ud;

  return _marpaESLIF_lua_writeri(marpaESLIFValuep->marpaESLIFp, &(marpaESLIFValuep->luaprecompiledp), &(marpaESLIFValuep->luaprecompiledl), p, sz);
}

/****************************************************************************/
static int _marpaESLIF_lua_recognizer_writeri(lua_State *L, const void* p, size_t sz, void* ud)
/****************************************************************************/
{
  marpaESLIFRecognizer_t *marpaESLIFRecognizerp = (marpaESLIFRecognizer_t *) ud;

  return _marpaESLIF_lua_writeri(marpaESLIFRecognizerp->marpaESLIFp, &(marpaESLIFRecognizerp->luaprecompiledp), &(marpaESLIFRecognizerp->luaprecompiledl), p, sz);
}

/****************************************************************************/
/* When MARPAESLIFLUA_EMBEDDED the file that includes this source must      */
/* provide the following implementations.                                   */
/****************************************************************************/

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_ASSERTSTACK
/****************************************************************************/
static inline short marpaESLIFLua_lua_assertstack(lua_State *L, int extra)
/****************************************************************************/
/* Check if current stack size is large enough for a single new element.    */
/* If not, try to grow the stack.                                           */
/****************************************************************************/
{
  int rci;

  /* Make sure there are extra free stack slots in the stack */
  if (MARPAESLIF_UNLIKELY(luaunpanic_checkstack(&rci, L, extra))) {
    marpaESLIFLua_luaL_error(L, "lua_checkstack failure");
    return 0;
  }
  if (MARPAESLIF_UNLIKELY(! rci)) {
    marpaESLIFLua_luaL_errorf(L, "Cannot ensure there are at least %d free stack slots", extra);
  }

  return 1;
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHINTEGER
/****************************************************************************/
static inline short marpaESLIFLua_lua_pushinteger(short checkstackb, lua_State *L, lua_Integer n)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_pushinteger(L, n));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_SETGLOBAL
/****************************************************************************/
static inline short marpaESLIFLua_lua_setglobal(lua_State *L, const char *name)
/****************************************************************************/
{
  return ! luaunpanic_setglobal(L, name);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_GETGLOBAL
/****************************************************************************/
static inline short marpaESLIFLua_lua_getglobal(short checkstackb, int *luaip, lua_State *L, const char *name)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_getglobal(luaip, L, name));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TYPE
/****************************************************************************/
static inline short marpaESLIFLua_lua_type(int *luaip, lua_State *L, int index)
/****************************************************************************/
{
  return ! luaunpanic_type(luaip, L, index);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_POP
/****************************************************************************/
static inline short marpaESLIFLua_lua_pop(lua_State *L, int n)
/****************************************************************************/
{
  return ! luaunpanic_pop(L, n);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_NEWTABLE
/****************************************************************************/
static inline short marpaESLIFLua_lua_newtable(short checkstackb, lua_State *L)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_newtable(L));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHCFUNCTION
/****************************************************************************/
static inline short marpaESLIFLua_lua_pushcfunction(short checkstackb, lua_State *L, lua_CFunction f)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_pushcfunction(L, f));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_SETFIELD
/****************************************************************************/
static inline short marpaESLIFLua_lua_setfield(lua_State *L, int index, const char *k)
/****************************************************************************/
{
  return ! luaunpanic_setfield(L, index, k);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_SETMETATABLE
/****************************************************************************/
static inline short marpaESLIFLua_lua_setmetatable(lua_State *L, int index)
/****************************************************************************/
{
  return ! luaunpanic_setmetatable(NULL, L, index);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_INSERT
/****************************************************************************/
static inline short marpaESLIFLua_lua_insert(short checkstackb, lua_State *L, int index)
/****************************************************************************/
{
  return ((index <= 0) || (! checkstackb) || marpaESLIFLua_lua_assertstack(L, index /* extra */)) && (! luaunpanic_insert(L, index));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_RAWGETI
/****************************************************************************/
static inline short marpaESLIFLua_lua_rawgeti(short checkstackb, int *luaip, lua_State *L, int index, lua_Integer n)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_rawgeti(luaip, L, index, n));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_RAWGET
/****************************************************************************/
static inline short marpaESLIFLua_lua_rawget(short checkstackb, int *luaip, lua_State *L, int index)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_rawget(luaip, L, index));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_RAWGETP
/****************************************************************************/
static inline short marpaESLIFLua_lua_rawgetp(short checkstackb, int *luaip, lua_State *L, int index, const void *p)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_rawgetp(luaip, L, index, p));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_REMOVE
/****************************************************************************/
static inline short marpaESLIFLua_lua_remove(lua_State *L, int index)
/****************************************************************************/
{
  return ! luaunpanic_remove(L, index);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_CREATETABLE
/****************************************************************************/
static inline short marpaESLIFLua_lua_createtable(short checkstackb, lua_State *L, int narr, int nrec)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_createtable(L, narr, nrec));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_RAWSETI
/****************************************************************************/
static inline short marpaESLIFLua_lua_rawseti(lua_State *L, int index, lua_Integer i)
/****************************************************************************/
{
  return ! luaunpanic_rawseti(L, index, i);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_SETI
/****************************************************************************/
static inline short marpaESLIFLua_lua_seti(lua_State *L, int index, lua_Integer i)
/****************************************************************************/
{
  return ! luaunpanic_seti(L, index, i);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHSTRING
/****************************************************************************/
static inline short marpaESLIFLua_lua_pushstring(short checkstackb, const char **luasp, lua_State *L, const char *s)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_pushstring(luasp, L, s));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHLSTRING
/****************************************************************************/
static inline short marpaESLIFLua_lua_pushlstring(short checkstackb, const char **luasp, lua_State *L, const char *s, size_t len)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_pushlstring(luasp, L, s, len));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHNIL
/****************************************************************************/
static inline short marpaESLIFLua_lua_pushnil(short checkstackb, lua_State *L)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_pushnil(L));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_GETFIELD
/****************************************************************************/
static inline short marpaESLIFLua_lua_getfield(short checkstackb, int *luaip, lua_State *L, int index, const char *k)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_getfield(luaip, L, index, k));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_CALL
/****************************************************************************/
static inline short marpaESLIFLua_lua_call(lua_State *L, int nargs, int nresults)
/****************************************************************************/
/* Note that lua_call adjusts natively the stack.                           */
/****************************************************************************/
{
  return ! luaunpanic_call(L, nargs, nresults);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_SETTOP
/****************************************************************************/
static inline short marpaESLIFLua_lua_settop(lua_State *L, int index)
/****************************************************************************/
{
  return ! luaunpanic_settop(L, index);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_COPY
/****************************************************************************/
static inline short marpaESLIFLua_lua_copy(lua_State *L, int fromidx, int toidx)
/****************************************************************************/
/* Note that caller is responsible to give valid indices.                   */
/****************************************************************************/
{
  return ! luaunpanic_copy(L, fromidx, toidx);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_RAWSETP
/****************************************************************************/
static inline short marpaESLIFLua_lua_rawsetp(lua_State *L, int index, const void *p)
/****************************************************************************/
{
  return ! luaunpanic_rawsetp(L, index, p);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_RAWSET
/****************************************************************************/
static inline short marpaESLIFLua_lua_rawset(lua_State *L, int index)
/****************************************************************************/
{
  return ! luaunpanic_rawset(L, index);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHBOOLEAN
/****************************************************************************/
static inline short marpaESLIFLua_lua_pushboolean(short checkstackb, lua_State *L, int b)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_pushboolean(L, b));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHNUMBER
/****************************************************************************/
static inline short marpaESLIFLua_lua_pushnumber(short checkstackb, lua_State *L, lua_Number n)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_pushnumber(L, n));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHLIGHTUSERDATA
/****************************************************************************/
static inline short marpaESLIFLua_lua_pushlightuserdata(short checkstackb, lua_State *L, void *p)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_pushlightuserdata(L, p));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_NEWUSERDATA
/****************************************************************************/
static inline short marpaESLIFLua_lua_newuserdata(short checkstackb, void **rcpp, lua_State *L, size_t sz)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_newuserdata(rcpp, L, sz));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHVALUE
/****************************************************************************/
static inline short marpaESLIFLua_lua_pushvalue(short checkstackb, lua_State *L, int index)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_pushvalue(L, index));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_REF
/****************************************************************************/
static inline short marpaESLIFLua_luaL_ref(int *rcip, lua_State *L, int t)
/****************************************************************************/
{
  return ! luaunpanicL_ref(rcip, L, t);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_UNREF
/****************************************************************************/
static inline short marpaESLIFLua_luaL_unref(lua_State *L, int t, int ref)
/****************************************************************************/
{
  return ! luaunpanicL_unref(L, t, ref);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_REQUIREF
/****************************************************************************/
static inline short marpaESLIFLua_luaL_requiref(short checkstackb, lua_State *L, const char *modname, lua_CFunction openf, int glb)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanicL_requiref(L, modname, openf, glb));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TOUSERDATA
/****************************************************************************/
static inline short marpaESLIFLua_lua_touserdata(void **rcpp, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_touserdata(rcpp, L, idx);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TOINTEGER
/****************************************************************************/
static inline short marpaESLIFLua_lua_tointeger(lua_Integer *rcip, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_tointeger(rcip, L, idx);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TOINTEGERX
/****************************************************************************/
static inline short marpaESLIFLua_lua_tointegerx(lua_Integer *rcip, lua_State *L, int idx, int *isnum)
/****************************************************************************/
{
  return ! luaunpanic_tointegerx(rcip, L, idx, isnum);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TONUMBER
/****************************************************************************/
static inline short marpaESLIFLua_lua_tonumber(lua_Number *rcdp, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_tonumber(rcdp, L, idx);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TONUMBERX
/****************************************************************************/
static inline short marpaESLIFLua_lua_tonumberx(lua_Number *rcdp, lua_State *L, int idx, int *isnum)
/****************************************************************************/
{
  return ! luaunpanic_tonumberx(rcdp, L, idx, isnum);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TOBOOLEAN
/****************************************************************************/
static inline short marpaESLIFLua_lua_toboolean(int *rcip, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_toboolean(rcip, L, idx);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_TOLSTRING
/****************************************************************************/
static inline short marpaESLIFLua_luaL_tolstring(const char **rcp, lua_State *L, int idx, size_t *len)
/****************************************************************************/
{
  return ! luaunpanicL_tolstring(rcp, L, idx, len);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TOLSTRING
/****************************************************************************/
static inline short marpaESLIFLua_lua_tolstring(const char **rcpp, lua_State *L, int idx, size_t *len)
/****************************************************************************/
{
  return ! luaunpanic_tolstring(rcpp, L, idx, len);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TOSTRING
/****************************************************************************/
static inline short marpaESLIFLua_lua_tostring(const char **rcpp, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_tostring(rcpp, L, idx);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_COMPARE
/****************************************************************************/
static inline short marpaESLIFLua_lua_compare(int *rcip, lua_State *L, int idx1, int idx2, int op)
/****************************************************************************/
{
  return ! luaunpanic_compare(rcip, L, idx1, idx2, op);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_RAWEQUAL
/****************************************************************************/
static inline short marpaESLIFLua_lua_rawequal(int *rcip, lua_State *L, int idx1, int idx2)
/****************************************************************************/
{
  return ! luaunpanic_rawequal(rcip, L, idx1, idx2);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_ISNIL
/****************************************************************************/
static inline short marpaESLIFLua_lua_isnil(int *rcip, lua_State *L, int n)
/****************************************************************************/
{
  return ! luaunpanic_isnil(rcip, L, n);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_GETTOP
/****************************************************************************/
static inline short marpaESLIFLua_lua_gettop(int *rcip, lua_State *L)
/****************************************************************************/
{
  return ! luaunpanic_gettop(rcip, L);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_ABSINDEX
/****************************************************************************/
static inline short marpaESLIFLua_lua_absindex(int *rcip, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_absindex(rcip, L, idx);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_NEXT
/****************************************************************************/
static inline short marpaESLIFLua_lua_next(short checkstackb, int *rcip, lua_State *L, int idx)
/****************************************************************************/
/* It pops a key and pushes a key-value pair.                               */
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_next(rcip, L, idx));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_CHECKLSTRING
/****************************************************************************/
static inline short marpaESLIFLua_luaL_checklstring(const char **rcp, lua_State *L, int arg, size_t *l)
/****************************************************************************/
{
  return ! luaunpanicL_checklstring(rcp, L, arg, l);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_CHECKSTRING
/****************************************************************************/
static inline short marpaESLIFLua_luaL_checkstring(const char **rcp, lua_State *L, int arg)
/****************************************************************************/
{
  return ! luaunpanicL_checkstring(rcp, L, arg);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_CHECKINTEGER
/****************************************************************************/
static inline short marpaESLIFLua_luaL_checkinteger(lua_Integer *rcp, lua_State *L, int arg)
/****************************************************************************/
{
  return ! luaunpanicL_checkinteger(rcp, L, arg);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_OPTINTEGER
/****************************************************************************/
static inline short marpaESLIFLua_luaL_optinteger(lua_Integer *rcp, lua_State *L, int arg, lua_Integer def)
/****************************************************************************/
{
  return ! luaunpanicL_optinteger(rcp, L, arg, def);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_GETMETATABLE
/****************************************************************************/
static inline short marpaESLIFLua_lua_getmetatable(short checkstackb, int *rcip, lua_State *L, int index)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_getmetatable(rcip, L, index));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_CALLMETA
/****************************************************************************/
static inline short marpaESLIFLua_luaL_callmeta(short checkstackb, int *rcip, lua_State *L, int obj, const char *e)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanicL_callmeta(rcip, L, obj, e));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_GETMETAFIELD
/****************************************************************************/
static inline short marpaESLIFLua_luaL_getmetafield(short getstackb, int *rcip, lua_State *L, int obj, const char *e)
/****************************************************************************/
{
  return ! luaunpanicL_getmetafield(rcip, L, obj, e);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_CHECKTYPE
/****************************************************************************/
static inline short marpaESLIFLua_luaL_checktype(lua_State *L, int arg, int t)
/****************************************************************************/
{
  return ! luaunpanicL_checktype(L, arg, t);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_TOPOINTER
/****************************************************************************/
static inline short marpaESLIFLua_lua_topointer(const void **rcpp, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_topointer(rcpp, L, idx);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_RAWLEN
/****************************************************************************/
static inline short marpaESLIFLua_lua_rawlen(size_t *rcp, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_rawlen(rcp, L, idx);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_DOSTRING
/****************************************************************************/
static inline short marpaESLIFLua_luaL_dostring(short checkstackb, int *rcip, lua_State *L, const char *fn)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanicL_dostring(rcip, L, fn));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_LOADSTRING
/****************************************************************************/
static inline short marpaESLIFLua_luaL_loadstring(short checkstackb, int *rcip, lua_State *L, const char *fn)
/****************************************************************************/
{
  return ((! checkstackb) | marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanicL_loadstring(rcip, L, fn));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_PUSHGLOBALTABLE
/****************************************************************************/
static inline short marpaESLIFLua_lua_pushglobaltable(short checkstackb, lua_State *L)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_pushglobaltable(L));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_SETTABLE
/****************************************************************************/
static inline short marpaESLIFLua_lua_settable(lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_settable(L, idx);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_GETTABLE
/****************************************************************************/
static inline short marpaESLIFLua_lua_gettable(int *rcip, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_gettable(rcip, L, idx);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_ISINTEGER
/****************************************************************************/
static inline short marpaESLIFLua_lua_isinteger(int *rcip, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_isinteger(rcip, L, idx);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_CHECKUDATA
/****************************************************************************/
static inline short marpaESLIFLua_luaL_checkudata(void **rcpp, lua_State *L, int ud, const char *tname)
/****************************************************************************/
{
  return ! luaunpanicL_checkudata(rcpp, L, ud, tname);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_NEWTHREAD
/****************************************************************************/
static inline short marpaESLIFLua_lua_newthread(short checkstackb, lua_State **Lp, lua_State *L)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanic_newthread(Lp, L));
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_CHECKVERSION
/****************************************************************************/
static inline short marpaESLIFLua_luaL_checkversion(lua_State *L)
/****************************************************************************/
{
  return ! luaunpanicL_checkversion(L);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_OPENLIBS
/****************************************************************************/
static inline short marpaESLIFLua_luaL_openlibs(lua_State *L)
/****************************************************************************/
{
  return ! luaunpanicL_openlibs(L);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUA_DUMP
/****************************************************************************/
static inline short marpaESLIFLua_lua_dump(int *rcip, lua_State *L, lua_Writer writer, void *data, int strip)
/****************************************************************************/
{
  return ! luaunpanic_dump(rcip, L, writer, data, strip);
}
#endif

#ifndef MARPAESLIFLUA_EMBEDDED_NATIVECALL_LUAL_LOADBUFFER
/****************************************************************************/
static inline short marpaESLIFLua_luaL_loadbuffer(short checkstackb, int *rcp, lua_State *L, const char *buff, size_t sz, const char *name)
/****************************************************************************/
{
  return ((! checkstackb) || marpaESLIFLua_lua_assertstack(L, 1 /* extra */)) && (! luaunpanicL_loadbuffer(rcp, L, buff, sz, name));
}
#endif

/****************************************************************************/
static short _marpaESLIF_lua_value_representationb(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp, char **encodingasciisp, marpaESLIFRepresentationDispose_t *disposeCallbackpp, short *stringbp)
/****************************************************************************/
{
  static const char                *funcs                 = "_marpaESLIF_lua_value_representationb";
  /* Internal function: we force userDatavp to be marpaESLIFValuep */
  marpaESLIFValue_t                *marpaESLIFValuep      = (marpaESLIFValue_t *) userDatavp;
  marpaESLIF_t                     *marpaESLIFp           = marpaESLIFValuep->marpaESLIFp;
  lua_State                        *L;
  marpaESLIFLuaValueContext_t      *marpaESLIFLuaValueContextp;
  int                               typei;
  short                             rcb;

  L = _marpaESLIF_lua_value_newp(marpaESLIFValuep);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  /* Remember that we pushed the "marpaESLIFValue" global ? */
  LUA_GETGLOBAL(&typei, marpaESLIFp, L, "marpaESLIFValue");                    /* stack: ..., marpaESLIFValueTable */
  if (MARPAESLIF_UNLIKELY(typei != LUA_TTABLE)) {
    MARPAESLIF_ERROR(marpaESLIFp, "Lua marpaESLIFValue global is not a table");
    errno = ENOSYS;
    goto err; /* Lua will shutdown anyway */
  }
  /* And this marpaESLIFValue is a table with a key "marpaESLIFValueContextp" */
  LUA_GETFIELD(&typei, marpaESLIFp, L, -1, "marpaESLIFLuaValueContextp");     /* stack: ..., marpaESLIFValueTable, marpaESLIFLuaValueContextp */
  if (MARPAESLIF_UNLIKELY(typei != LUA_TLIGHTUSERDATA)) {
    MARPAESLIF_ERROR(marpaESLIFp, "Lua marpaESLIFLuaValueContextp is not a light userdata");
    errno = ENOSYS;
    goto err; /* Lua will shutdown anyway */
  }
  LUA_TOUSERDATA(marpaESLIFp, L, &marpaESLIFLuaValueContextp, -1);
  LUA_POP(marpaESLIFp, L, 2);                                                  /* stack: ... */

  /* Proxy to the lua representation callback action - then userDatavp has to be marpaESLIFLuaValueContextp */
  if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_representationb((void *) marpaESLIFLuaValueContextp /* userDatavp */, marpaESLIFValueResultp, inputcpp, inputlp, encodingasciisp, disposeCallbackpp, stringbp))) {
    MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, marpaESLIFLua_representationb);
    errno = ENOSYS;
    goto err;
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_lua_recognizer_eventactionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFEvent_t *eventArrayp, size_t eventArrayl, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp)
/*****************************************************************************/
{
  static const char                   *funcs       = "_marpaESLIF_lua_recognizer_eventactionb";
  marpaESLIF_t                        *marpaESLIFp = marpaESLIFRecognizerp->marpaESLIFp;
  lua_State                           *L;
  marpaESLIFRecognizerEventCallback_t  eventCallbackp;
  short                                rcb;

  L = _marpaESLIF_lua_recognizer_newp(marpaESLIFRecognizerp);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  eventCallbackp = marpaESLIFLua_recognizerEventActionResolver(userDatavp, marpaESLIFRecognizerp, marpaESLIFRecognizerp->actions);
  if (MARPAESLIF_UNLIKELY(eventCallbackp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFp, "Lua bindings returned no event-action callback");
    errno = ENOSYS;
    goto err; /* Lua will shutdown anyway */
  }

  if (MARPAESLIF_UNLIKELY(! eventCallbackp(userDatavp, marpaESLIFRecognizerp, eventArrayp, eventArrayl, marpaESLIFValueResultBoolp))) {
    MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, eventCallbackp);
    errno = ENOSYS;
    goto err;
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static inline marpaESLIFGrammar_t *_marpaESLIF_lua_grammarp(marpaESLIF_t *marpaESLIFp, char *starts)
/*****************************************************************************/
{
  static const char *luas =
    "#\n"
    "# Special entry just to make ESLIF happy\n"
    "#\n"
    "dummy ::= 'not used'\n"
    "#\n"
    "# Special entries used to hook the lua grammar in ESLIF\n"
    "#\n"
    "<lua funcbody after lparen>            :[2]:= <lua optional parlist> ')' <lua block> <lua keyword end>\n"
    "<lua args after lparen>                :[2]:= <lua optional explist> ')' action => ::lua->listSize\n"
    "<lua optional parlist after lparen>    :[2]:= <lua optional parlist> ')' action => ::lua->listSize\n"
    "\n"
    "<luascript>\n"
    "  function addDotDotDotToTable(namelist, comma, dotdotdot)\n"
    "     namelist[#namelist + 1] = dotdotdot\n"
    "     return namelist\n"
    "  end\n"
    "  \n"
    "  function listSize(list, rparen)\n"
    "    return #list\n"
    "  end\n"
    "  \n"
    "</luascript>\n"
    "\n"
    "#\n"
    "# -----------------------------------------------------------------------\n"
    "# Lua 5.3.4 grammar. Based on perl package MarpaX::Languages::Lua::Parser\n"
    "# -----------------------------------------------------------------------\n"
    "#\n"
    ":desc                                  :[2]:= 'Lua 5.3'\n"
    "\n"
    ":discard                               :[2]:= /\\s+/\n"
    ":discard                               :[2]:= /--(?:\\[(?!=*\\[)|(?!\\[))[^\\n]*/\n"
    ":discard                               :[2]:= /--\\[(=*)\\[.*?\\]\\1\\]/s\n"
    "\n"
    "<lua chunk>                            :[2]:=\n"
    "<lua chunk>                            :[2]:= <lua stat list>\n"
    "                                            | <lua stat list> <lua laststat>\n"
    "                                            | <lua stat list> <lua laststat> ';'\n"
    "                                            | <lua laststat> ';'\n"
    "                                            | <lua laststat>\n"
    "<lua stat list>                        :[2]:= <lua stat>\n"
    "                                            | <lua stat> ';'\n"
    "                                            | <lua stat list> <lua stat> rank => -1\n"
    "                                            | <lua stat list> <lua stat> ';'\n"
    "<lua block>                            :[2]:= <lua chunk>\n"
    "<lua stat>                             :[2]:= <lua varlist> '=' <lua explist>\n"
    "                                            | <lua functioncall> rank => -1\n"
    "                                            | <lua label>\n"
    "                                            | <lua keyword goto> <lua Name>\n"
    "                                            | <lua keyword do> <lua block> <lua keyword end>\n"
    "                                            | <lua keyword while> <lua exp> <lua keyword do> <lua block> <lua keyword end>\n"
    "                                            | <lua keyword repeat> <lua block> <lua keyword until> <lua exp>\n"
    "                                            | <lua keyword if> <lua exp> <lua keyword then> <lua block> <lua elseif sequence> <lua optional else block> <lua keyword end>\n"
    "                                            | <lua keyword for> <lua Name> '=' <lua exp> ',' <lua exp> ',' <lua exp> <lua keyword do> <lua block> <lua keyword end>\n"
    "                                            | <lua keyword for> <lua Name> '=' <lua exp> ',' <lua exp> <lua keyword do> <lua block> <lua keyword end>\n"
    "                                            | <lua keyword for> <lua namelist> <lua keyword in> <lua explist> <lua keyword do> <lua block> <lua keyword end>\n"
    "                                            | <lua keyword function> <lua funcname> <lua funcbody>\n"
    "                                            | <lua keyword local> <lua keyword function> <lua Name> <lua funcbody>\n"
    "                                            | <lua keyword local> <lua namelist> <lua optional namelist initialization>\n"
    "                                            | ';'\n"
    "<lua elseif sequence>                  :[2]:=\n"
    "<lua elseif sequence>                  :[2]:= <lua elseif sequence> <lua elseif block>\n"
    "<lua elseif block>                     :[2]:= <lua keyword elseif> <lua exp> <lua keyword then> <lua block>\n"
    "<lua optional else block>              :[2]:=\n"
    "<lua optional else block>              :[2]:= <lua keyword else> <lua block>\n"
    "<lua optional namelist initialization> :[2]:=\n"
    "<lua optional namelist initialization> :[2]:= '=' <lua explist>\n"
    "<lua laststat>                         :[2]:= <lua keyword return> <lua optional explist>\n"
    "                                            | <lua keyword break>\n"
    "<lua optional explist>                 :[2]:=                                        action => ::row #Empty table\n"
    "<lua optional explist>                 :[2]:= <lua explist>                          action => ::shift\n"
    "<lua funcname>                         :[2]:= <lua dotted name> <lua optional colon name element>\n"
    "<lua dotted name>                      :[2]:= <lua Name>+ separator => '.' proper => 1\n"
    "<lua optional colon name element>      :[2]:=\n"
    "<lua optional colon name element>      :[2]:= ':' <lua Name>\n"
    "<lua varlist>                          :[2]:= <lua var>+ separator => ',' proper => 1\n"
    "<lua var>                              :[2]:= <lua Name>\n"
    "                                            | <lua prefixexp> '[' <lua exp> ']'\n"
    "                                            | <lua prefixexp> '.' <lua Name>\n"
    "<lua namelist>                         :[2]:= <lua Name>+ separator => ',' proper => 1 hide-separator => 1           action => ::row # Table of arguments\n"
    "<lua explist>                          :[2]:= <lua exp>+  separator => ',' proper => 1 hide-separator => 1           action => ::row # Table of expressions\n"
    "<lua exp>                              :[2]:= <lua var>\n"
    "                                            | '(' <lua exp> ')' assoc => group\n"
    "                                           || <lua exp> <lua args> assoc => right\n"
    "                                           || <lua exp> ':' <lua Name> <lua args> assoc => right\n"
    "                                            | <lua keyword nil>\n"
    "                                            | <lua keyword false>\n"
    "                                            | <lua keyword true>\n"
    "                                            | <lua Number>\n"
    "                                            | <lua String>\n"
    "                                            | '...'\n"
    "                                            | <lua tableconstructor>\n"
    "                                            | <lua function>\n"
    "                                           || <lua exp> '^' <exponent> assoc => right\n"
    "                                           || '-' <lua exp>\n"
    "                                            | <lua keyword not> <lua exp>\n"
    "                                            | '#' <lua exp>\n"
    "                                            | '~' <lua exp>\n"
    "                                           || <lua exp> '*' <lua exp>\n"
    "                                            | <lua exp> '/' <lua exp>\n"
    "                                            | <lua exp> '//' <lua exp>\n"
    "                                            | <lua exp> '%' <lua exp>\n"
    "                                           || <lua exp> '+' <lua exp>\n"
    "                                            | <lua exp> '-' <lua exp>\n"
    "                                           || <lua exp> '..' <lua exp> assoc => right\n"
    "                                           || <lua exp> '<<' <lua exp>\n"
    "                                            | <lua exp> '>>' <lua exp>\n"
    "                                           || <lua exp> '&' <lua exp>\n"
    "                                           || <lua exp> '~' <lua exp>\n"
    "                                           || <lua exp> '|' <lua exp>\n"
    "                                           || <lua exp> '<' <lua exp>\n"
    "                                            | <lua exp> '<=' <lua exp>\n"
    "                                            | <lua exp> '>' <lua exp>\n"
    "                                            | <lua exp> '>=' <lua exp>\n"
    "                                            | <lua exp> '==' <lua exp> rank => 1\n"
    "                                            | <lua exp> '~=' <lua exp>\n"
    "                                           || <lua exp> <lua keyword and> <lua exp> rank => 1\n"
    "                                           || <lua exp> <lua keyword or> <lua exp>\n"
    "<exponent>                             :[2]:= <lua var>\n"
    "                                            | '(' <lua exp> ')'\n"
    "                                           || <exponent> <lua args>\n"
    "                                           || <exponent> ':' <lua Name> <lua args>\n"
    "                                            | <lua keyword nil>\n"
    "                                            | <lua keyword false>\n"
    "                                            | <lua keyword true>\n"
    "                                            | <lua Number>\n"
    "                                            | <lua String>\n"
    "                                            | '...'\n"
    "                                            | <lua tableconstructor>\n"
    "                                            | <lua function>\n"
    "                                           || <lua keyword not> <exponent>\n"
    "                                            | '#' <exponent>\n"
    "                                            | '-' <exponent>\n"
    "<lua prefixexp>                        :[2]:= <lua var>\n"
    "                                            | <lua functioncall>\n"
    "                                            | '(' <lua exp> ')'\n"
    "<lua functioncall>                     :[2]:= <lua prefixexp> <lua args>\n"
    "                                            | <lua prefixexp> ':' <lua Name> <lua args>\n"
    "<lua args>                             :[2]:= '(' <lua optional explist> ')'\n"
    "                                            | <lua tableconstructor>\n"
    "                                            | <lua String>\n"
    "<lua function>                         :[2]:= <lua keyword function> <lua funcbody>\n"
    "<lua funcbody>                         :[2]:= '(' <lua optional parlist> ')' <lua block> <lua keyword end>\n"
    "<lua optional parlist>                 :[2]:=                             action => ::row # Empty table\n"
    "<lua optional parlist>                 :[2]:= <lua namelist>              action => ::shift\n"
    "                                            | <lua namelist> ',' '...'    action => ::lua->addDotDotDotToTable\n"
    "                                            | '...'                       action => ::row # Table with one entry\n"
    " \n"
    "# A lone comma is not allowed in an empty fieldlist,\n"
    "# apparently. This is why I use a dedicated rule\n"
    "# for an empty table and a '+' sequence,\n"
    "# instead of a '*' sequence.\n"
    " \n"
    "<lua tableconstructor>                 :[2]:= '{' '}'\n"
    "                                            | '{' <lua fieldlist> '}'\n"
    "<lua fieldlist>                        :[2]:= <lua field>+ separator => [,;]\n"
    "<lua field>                            :[2]:= '[' <lua exp> ']' '=' <lua exp>\n"
    "                                            | <lua Name> '=' <lua exp>\n"
    "                                            | <lua exp>\n"
    "<lua label>                            :[2]:= '::' <lua Name> '::'\n"
    "<lua Name>                             :[2]:= <LUA NAME> - <LUA RESERVED KEYWORDS>\n"
    "<lua String>                           :[2]:= /'(?:[^\\\\']*(?:\\\\.[^\\\\']*)*)'|\"(?:[^\\\\\"]*(?:\\\\.[^\\\\\"]*)*)\"|\\[(=*)\\[.*?\\]\\1\\]/su\n"
    "\n"
    "# A lua number can start with '.' if the later is followed by at least one (hex) digit\n"
    "<lua Number>                           :[2]:= /(?:\\.[0-9]+|[0-9]+(?:\\.[0-9]*)?)(?:[eE][+-]?[0-9]+)?/ \n"
    "                                            | /0[xX](?:\\.[a-fA-F0-9]+|[a-fA-F0-9]+(?:\\.[a-fA-F0-9]*)?)(?:\\.[a-fA-F0-9]*)?(?:[pP][+-]?[0-9]+)?/ \n"
    "\n"
    "\n"
    "<lua keyword and>                      :[3]:= 'and'\n"
    "<lua keyword break>                    :[3]:= 'break'\n"
    "<lua keyword do>                       :[3]:= 'do'\n"
    "<lua keyword else>                     :[3]:= 'else'\n"
    "<lua keyword elseif>                   :[3]:= 'elseif'\n"
    "<lua keyword end>                      :[3]:= 'end'\n"
    "<lua keyword false>                    :[3]:= 'false'\n"
    "<lua keyword for>                      :[3]:= 'for'\n"
    "<lua keyword function>                 :[3]:= 'function'\n"
    "<lua keyword if>                       :[3]:= 'if'\n"
    "<lua keyword in>                       :[3]:= 'in'\n"
    "<lua keyword local>                    :[3]:= 'local'\n"
    "<lua keyword nil>                      :[3]:= 'nil'\n"
    "<lua keyword not>                      :[3]:= 'not'\n"
    "<lua keyword or>                       :[3]:= 'or'\n"
    "<lua keyword repeat>                   :[3]:= 'repeat'\n"
    "<lua keyword return>                   :[3]:= 'return'\n"
    "<lua keyword then>                     :[3]:= 'then'\n"
    "<lua keyword true>                     :[3]:= 'true'\n"
    "<lua keyword until>                    :[3]:= 'until'\n"
    "<lua keyword while>                    :[3]:= 'while'\n"
    "<lua keyword goto>                     :[3]:= 'goto'\n"
    " \n"
    "<LUA NAME>                             :[3]:= /[a-zA-Z_][a-zA-Z_0-9]*/\n"
    "<LUA RESERVED KEYWORDS>                :[3]:= 'and'\n"
    "                                            | 'break'\n"
    "                                            | 'do'\n"
    "                                            | 'else'\n"
    "                                            | 'elseif'\n"
    "                                            | 'end'\n"
    "                                            | 'false'\n"
    "                                            | 'for'\n"
    "                                            | 'function'\n"
    "                                            | 'if'\n"
    "                                            | 'in'\n"
    "                                            | 'local'\n"
    "                                            | 'nil'\n"
    "                                            | 'not'\n"
    "                                            | 'or'\n"
    "                                            | 'repeat'\n"
    "                                            | 'return'\n"
    "                                            | 'then'\n"
    "                                            | 'true'\n"
    "                                            | 'until'\n"
    "                                            | 'while'\n"
    "                                            | 'goto'\n"
    "\n"
    ;
  char                      *grammars;
  size_t                     grammarl;
  marpaESLIFGrammarOption_t  marpaESLIFGrammarOption;
  marpaESLIFGrammar_t       *rcp;

  if (starts == NULL) {
    grammars = (char *) luas;
    grammarl = strlen(grammars);
  } else {
    grammarl = strlen(luas)
      + strlen("\n:start :[2]:= <")
      + strlen(starts)
      + strlen(">\n");
    grammars = (char *) malloc(grammarl + 1);
    if (MARPAESLIF_UNLIKELY(grammars == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFp, "malloc failure, %s", strerror(errno));
      goto err;
    }
    strcpy(grammars, luas);
    strcat(grammars, "\n:start :[2]:= <");
    strcat(grammars, starts);
    strcat(grammars, ">\n");
  }
  marpaESLIFGrammarOption.bytep     = grammars;
  marpaESLIFGrammarOption.bytel     = grammarl;
  marpaESLIFGrammarOption.encodings = "ASCII";
  marpaESLIFGrammarOption.encodingl = 5;

  rcp = _marpaESLIFGrammar_newp(marpaESLIFp, &marpaESLIFGrammarOption, 0 /* startGrammarIsLexemeb */, &(marpaESLIFp->Lshare), 0 /* bootstrapb */);
  goto done;

 err:
  rcp = NULL;

 done:
  if ((grammars != NULL) && (grammars != (char *) luas)) {
    free(grammars);
  }
  return rcp;
}

/*****************************************************************************/
static short _marpaESLIF_lua_value_action_functionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  static const char *funcs       = "_marpaESLIF_lua_value_action_functionb";
  marpaESLIF_t      *marpaESLIFp = marpaESLIFValuep->marpaESLIFp;
  int                topi        = -1;
  lua_State         *L;
  short              rcb;

  L = _marpaESLIF_lua_value_newp(marpaESLIFValuep);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  LUA_GETTOP(marpaESLIFp, L, &topi);

  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_lua_value_function_loadb(marpaESLIFValuep))) {
    goto err;
  }

  if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_valueCallbackb(userDatavp, marpaESLIFValuep, arg0i, argni, NULL /* marpaESLIFValueResultLexemep */, resulti, nullableb, 0 /* symbolb */, 1 /* precompiledb */))) {
    MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, marpaESLIFLua_valueCallbackb);
    errno = ENOSYS;
    goto err;
  }

  if (topi >= 0) {
    LUA_SETTOP(marpaESLIFp, L, topi);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_lua_value_symbol_functionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFValueResult_t *marpaESLIFValueResultp, int resulti)
/*****************************************************************************/
{
  static const char *funcs       = "_marpaESLIF_lua_value_symbol_functionb";
  marpaESLIF_t      *marpaESLIFp = marpaESLIFValuep->marpaESLIFp;
  int                topi        = -1;
  lua_State         *L;
  short              rcb;

  L = _marpaESLIF_lua_value_newp(marpaESLIFValuep);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  LUA_GETTOP(marpaESLIFp, L, &topi);

  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_lua_value_function_loadb(marpaESLIFValuep))) {
    goto err;
  }

  if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_valueCallbackb(userDatavp, marpaESLIFValuep, -1 /* arg0i */, -1 /* argni */, marpaESLIFValueResultp, resulti, 0 /* nullableb */, 1 /* symbolb */, 1 /* precompiledb */))) {
    MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, marpaESLIFLua_valueCallbackb);
    errno = ENOSYS;
    goto err;
  }

  if (topi >= 0) {
    LUA_SETTOP(marpaESLIFp, L, topi);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_lua_recognizer_ifaction_functionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFValueResultp, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp)
/*****************************************************************************/
{
  static const char *funcs       = "_marpaESLIF_lua_recognizer_ifaction_functionb";
  marpaESLIF_t      *marpaESLIFp = marpaESLIFRecognizerp->marpaESLIFp;
  int                topi        = -1;
  lua_State         *L;
  short              rcb;

  L = _marpaESLIF_lua_recognizer_newp(marpaESLIFRecognizerp);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  LUA_GETTOP(marpaESLIFp, L, &topi);

  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_lua_recognizer_function_loadb(marpaESLIFRecognizerp))) {
    goto err;
  }

  if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_ifCallbackb(userDatavp, marpaESLIFRecognizerp, marpaESLIFValueResultp, marpaESLIFValueResultBoolp, 1 /* precompiledb */))) {
    MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, marpaESLIFLua_ifCallbackb);
    errno = ENOSYS;
    goto err;
  }

  if (topi >= 0) {
    LUA_SETTOP(marpaESLIFp, L, topi);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_lua_recognizer_regexaction_functionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFCalloutBlockp, marpaESLIFValueResultInt_t *marpaESLIFValueResultOutp)
/*****************************************************************************/
{
  static const char *funcs       = "_marpaESLIF_lua_recognizer_regexaction_functionb";
  marpaESLIF_t      *marpaESLIFp = marpaESLIFRecognizerp->marpaESLIFp;
  int                topi        = -1;
  lua_State         *L;
  short              rcb;

  L = _marpaESLIF_lua_recognizer_newp(marpaESLIFRecognizerp);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  LUA_GETTOP(marpaESLIFp, L, &topi);

  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_lua_recognizer_function_loadb(marpaESLIFRecognizerp))) {
    goto err;
  }

  if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_regexCallbackb(userDatavp, marpaESLIFRecognizerp, marpaESLIFCalloutBlockp, marpaESLIFValueResultOutp, 1 /* precompiledb */))) {
    MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, marpaESLIFLua_regexCallbackb);
    errno = ENOSYS;
    goto err;
  }

  if (topi >= 0) {
    LUA_SETTOP(marpaESLIFp, L, topi);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_lua_recognizer_generatoraction_functionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *contextp, marpaESLIFValueResultString_t *marpaESLIFValueResultOutp)
/*****************************************************************************/
{
  static const char *funcs       = "_marpaESLIF_lua_recognizer_generatoraction_functionb";
  marpaESLIF_t      *marpaESLIFp = marpaESLIFRecognizerp->marpaESLIFp;
  int                topi        = -1;
  lua_State         *L;
  short              rcb;

  L = _marpaESLIF_lua_recognizer_newp(marpaESLIFRecognizerp);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  LUA_GETTOP(marpaESLIFp, L, &topi);

  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_lua_recognizer_function_loadb(marpaESLIFRecognizerp))) {
    goto err;
  }

  if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_generatorCallbackb(userDatavp, marpaESLIFRecognizerp, contextp, 1 /* precompiledb */, marpaESLIFValueResultOutp))) {
    MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, marpaESLIFLua_generatorCallbackb);
    errno = ENOSYS;
    goto err;
  }

  if (topi >= 0) {
    LUA_SETTOP(marpaESLIFp, L, topi);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_lua_recognizer_eventaction_functionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFEvent_t *eventArrayp, size_t eventArrayl, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp)
/*****************************************************************************/
{
  static const char *funcs        = "_marpaESLIF_lua_recognizer_eventaction_functionb";
  marpaESLIF_t       *marpaESLIFp = marpaESLIFRecognizerp->marpaESLIFp;
  int                topi         = -1;
  lua_State         *L;
  short              rcb;

  L = _marpaESLIF_lua_recognizer_newp(marpaESLIFRecognizerp);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  LUA_GETTOP(marpaESLIFp, L, &topi);

  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_lua_recognizer_function_loadb(marpaESLIFRecognizerp))) {
    goto err;
  }

  if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_eventCallbackb(userDatavp, marpaESLIFRecognizerp, eventArrayp, eventArrayl, marpaESLIFValueResultBoolp, 1 /* precompiledb */))) {
    MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, marpaESLIFLua_eventCallbackb);
    errno = ENOSYS;
    goto err;
  }

  if (topi >= 0) {
    LUA_SETTOP(marpaESLIFp, L, topi);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIF_lua_value_function_loadb(marpaESLIFValue_t *marpaESLIFValuep)
/*****************************************************************************/
{
  char         *actions     = marpaESLIFValuep->actionp->u.luaFunction.actions;
  marpaESLIF_t *marpaESLIFp = marpaESLIFValuep->marpaESLIFp;
  lua_State    *L;
  short         rcb;

  L = _marpaESLIF_lua_value_newp(marpaESLIFValuep);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  if (marpaESLIFValuep->actionp->u.luaFunction.luacb) {
    if (marpaESLIFValuep->actionp->u.luaFunction.luacp == NULL) {
      /* We precompile the unstripped version if not already done */
      if (MARPAESLIF_UNLIKELY(! _marpaESLIF_lua_value_precompileb(marpaESLIFValuep, actions, strlen(actions), 0 /* stripb */, 0 /* popi */))) {
        goto err;
      }
      marpaESLIFValuep->actionp->u.luaFunction.luacp = marpaESLIFValuep->luaprecompiledp;
      marpaESLIFValuep->actionp->u.luaFunction.luacl = marpaESLIFValuep->luaprecompiledl;

      marpaESLIFValuep->luaprecompiledp = NULL;
      marpaESLIFValuep->luaprecompiledl = 0;
    } else {
      /* We inject it */
      LUAL_LOADBUFFER(marpaESLIFp, L, marpaESLIFValuep->actionp->u.luaFunction.luacp, marpaESLIFValuep->actionp->u.luaFunction.luacl, "=<luafunction/>");
    }
  } else {
    LUAL_LOADSTRING(marpaESLIFp, L, actions);
  }

  /* We injected a function that returns a function */
  LUA_CALL(marpaESLIFp, L, 0, 1);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIF_lua_recognizer_function_loadb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp)
/*****************************************************************************/
{
  char         *actions     = marpaESLIFRecognizerp->actionp->u.luaFunction.actions;
  marpaESLIF_t *marpaESLIFp = marpaESLIFRecognizerp->marpaESLIFp;
  lua_State    *L;
  short         rcb;

  L = _marpaESLIF_lua_recognizer_newp(marpaESLIFRecognizerp);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  if (marpaESLIFRecognizerp->actionp->u.luaFunction.luacb) {
    if (marpaESLIFRecognizerp->actionp->u.luaFunction.luacp == NULL) {
      /* We precompile the unstripped version if not already done */
      if (MARPAESLIF_UNLIKELY(! _marpaESLIF_lua_recognizer_function_precompileb(marpaESLIFRecognizerp, actions, strlen(actions), 0 /* stripb */, 0 /* popi */))) {
        goto err;
      }
      marpaESLIFRecognizerp->actionp->u.luaFunction.luacp = marpaESLIFRecognizerp->luaprecompiledp;
      marpaESLIFRecognizerp->actionp->u.luaFunction.luacl = marpaESLIFRecognizerp->luaprecompiledl;

      marpaESLIFRecognizerp->luaprecompiledp = NULL;
      marpaESLIFRecognizerp->luaprecompiledl = 0;
    } else {
      /* We inject it */
      LUAL_LOADBUFFER(marpaESLIFp, L, marpaESLIFRecognizerp->actionp->u.luaFunction.luacp, marpaESLIFRecognizerp->actionp->u.luaFunction.luacl, "=<luafunction/>");
    }
  } else {
    LUAL_LOADSTRING(marpaESLIFp, L, actions);
  }

  /* We injected a function that returns a function */
  LUA_CALL(marpaESLIFp, L, 0, 1);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIF_lua_recognizer_function_precompileb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *luabytep, size_t luabytel, short stripb, int popi)
/*****************************************************************************/
{
  marpaESLIF_t *marpaESLIFp = marpaESLIFRecognizerp->marpaESLIFp;
  lua_State    *L;
  short         rcb;

  L = _marpaESLIF_lua_recognizer_newp(marpaESLIFRecognizerp);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  /* Compiles lua script */
  LUAL_LOADBUFFER(marpaESLIFp, L, luabytep, luabytel, "=<luafunction/>");

  /* Result is a "function" at the top of the stack - we now have to dump it so that lua knows about it  */
  LUA_DUMP(marpaESLIFp, L, _marpaESLIF_lua_recognizer_writeri, marpaESLIFRecognizerp, stripb);

  if (popi > 0) {
    LUA_POP(marpaESLIFp, L, popi);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIF_lua_recognizer_push_contextb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIF_symbol_t *symbolp)
/*****************************************************************************/
/* Note: by def, symbolp->callp is != NULL, symbolp->declp may be NULL,      */
/* symbolp->parameterizedRhsLhsp is != NULL                                  */
/*****************************************************************************/
{
  static const char            *funcs                = "_marpaESLIF_lua_recognizer_push_contextb";
  marpaESLIF_t                 *marpaESLIFp          = marpaESLIFRecognizerp->marpaESLIFp;
  genericLogger_t              *genericLoggerp       = NULL;
  char                         *parlistWithoutParens = NULL;
  int                           topi                 = -1;
  lua_State                    *L;
#ifndef MARPAESLIF_NTRACE
  int                           i;
  char                         *p;
  char                         *p2;
  char                          c;
#endif
  marpaESLIF_stringGenerator_t  marpaESLIF_stringGenerator;
  short                         rcb;

  marpaESLIF_stringGenerator.s = NULL;

  L = _marpaESLIF_lua_recognizer_newp(marpaESLIFRecognizerp);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  LUA_GETTOP(marpaESLIFp, L, &topi);

  /* --------------------------------------------------------------------------------------------- */
  /* return function()                                                                             */
  /*   local PARLIST = table.unpack(marpaESLIFContextStackp:get())                                 */
  /*   marpaESLIFContextStackp:push(table.pack(EXPLIST))                                           */
  /* end                                                                                           */
  /* --------------------------------------------------------------------------------------------- */
  if (symbolp->pushContextActionp == NULL) {
    /* We initialize the correct action content. */
    symbolp->pushContextActionp = (marpaESLIF_action_t *) malloc(sizeof(marpaESLIF_action_t));
    if (MARPAESLIF_UNLIKELY(symbolp->pushContextActionp == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFp, "malloc failure, %s", strerror(errno));
      goto err;
    }
    symbolp->pushContextActionp->type                     = MARPAESLIF_ACTION_TYPE_LUA_FUNCTION;
    symbolp->pushContextActionp->u.luaFunction.luas       = NULL; /* Original action as per the grammar - not used */
    symbolp->pushContextActionp->u.luaFunction.actions    = NULL; /* The action injected into lua */
    symbolp->pushContextActionp->u.luaFunction.luacb      = 0;    /* True if action is precompiled */
    symbolp->pushContextActionp->u.luaFunction.luacp      = NULL; /* Precompiled chunk. Not NULL only when luacb is true and action as been used at least once */
    symbolp->pushContextActionp->u.luaFunction.luacl      = 0;    /* Precompiled chunk length */
    symbolp->pushContextActionp->u.luaFunction.luacstripp = NULL; /* Precompiled stripped chunk - not used */
    symbolp->pushContextActionp->u.luaFunction.luacstripl = 0;    /* Precompiled stripped chunk length */

    marpaESLIF_stringGenerator.marpaESLIFp = marpaESLIFRecognizerp->marpaESLIFp;
    marpaESLIF_stringGenerator.s           = NULL;
    marpaESLIF_stringGenerator.l           = 0;
    marpaESLIF_stringGenerator.okb         = 0;
    marpaESLIF_stringGenerator.allocl      = 0;

    genericLoggerp = GENERICLOGGER_CUSTOM(_marpaESLIF_generateStringWithLoggerCallback, (void *) &marpaESLIF_stringGenerator, GENERICLOGGER_LOGLEVEL_TRACE);
    if (MARPAESLIF_UNLIKELY(genericLoggerp == NULL)) {
      goto err;
    }

    GENERICLOGGER_TRACE(genericLoggerp,
                        "return function()\n"
                        );
    if (MARPAESLIF_UNLIKELY(! marpaESLIF_stringGenerator.okb)) {
      goto err;
    }
    if ((symbolp->declp != NULL) && (symbolp->declp->sizei > 0)) {
      parlistWithoutParens = strdup(symbolp->declp->luaparlists);
      if (MARPAESLIF_UNLIKELY(parlistWithoutParens == NULL)) {
        MARPAESLIF_ERRORF(marpaESLIFp, "strdup failure, %s", strerror(errno));
        goto err;
      }
      parlistWithoutParens[0] = ' '; /* First character will be a space, this is why we say local%s just below */
      parlistWithoutParens[strlen(parlistWithoutParens) - 1] = '\0';
      GENERICLOGGER_TRACEF(genericLoggerp, "  local%s = table.unpack(marpaESLIFContextStackp:get())\n", parlistWithoutParens);
      if (MARPAESLIF_UNLIKELY(! marpaESLIF_stringGenerator.okb)) {
        goto err;
      }
    }
#ifndef MARPAESLIF_NTRACE
    if (parlistWithoutParens != NULL) {
      /* Enclose parlist members with '' */
      p = parlistWithoutParens;
      for (i = 0; i < symbolp->declp->sizei; i++) {
        /* Get start of symbol */
        c = *p;
        while (1) {
          if ((c == '_') || ((c >= '0') && (c <= '9')) || ((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z'))) {
            break;
          }
          c = *++p;
        }
        /* Put NUL at end of symbol */
        p2 = p;
        c = *++p2;
        while (1) {
          if ((c == '_') || ((c >= '0') && (c <= '9')) || ((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z'))) {
            c = *++p2;
            continue;
          }
          break;
        }
        *p2 = '\0';
        GENERICLOGGER_TRACEF(genericLoggerp, "  print('[%d][lua] Parameter %s = '..tostring(%s))\n", marpaESLIFRecognizerp->leveli, p, p);
        if (MARPAESLIF_UNLIKELY(! marpaESLIF_stringGenerator.okb)) {
          goto err;
        }
        *p2 = c;
        p = ++p2;
      }
    }
    GENERICLOGGER_TRACEF(genericLoggerp, "  print('[%d][lua] Pushed: %s')\n", marpaESLIFRecognizerp->leveli, symbolp->callp->luaexplists);
#endif
    GENERICLOGGER_TRACEF(genericLoggerp, "  marpaESLIFContextStackp:push(table.pack%s)\n", symbolp->callp->luaexplists);
    if (MARPAESLIF_UNLIKELY(! marpaESLIF_stringGenerator.okb)) {
      goto err;
    }
    GENERICLOGGER_TRACE(genericLoggerp, "end\n");
    if (MARPAESLIF_UNLIKELY(! marpaESLIF_stringGenerator.okb)) {
      goto err;
    }

    /* Action is always precompiled unless declp or callp says it should not */
    if ((! symbolp->callp->luaexplistcb) || ((symbolp->declp != NULL) && (! symbolp->declp->luaparlistcb))) {
      symbolp->pushContextActionp->u.luaFunction.luacb = 0;
    } else {
      symbolp->pushContextActionp->u.luaFunction.luacb = 1;
    }

    symbolp->pushContextActionp->u.luaFunction.actions = marpaESLIF_stringGenerator.s;
    marpaESLIF_stringGenerator.s = NULL;

    MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Generated action:\n%s", symbolp->pushContextActionp->u.luaFunction.actions);
  }

  /* Call the context action */
  marpaESLIFRecognizerp->actionp = symbolp->pushContextActionp;
  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_lua_recognizer_function_loadb(marpaESLIFRecognizerp))) {
    goto err;
  }

  if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_pushContextb(marpaESLIFRecognizerp))) {
    MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, marpaESLIFLua_pushContextb);
    errno = ENOSYS;
    goto err;
  }

  if (topi >= 0) {
    LUA_SETTOP(marpaESLIFp, L, topi);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  if (marpaESLIF_stringGenerator.s != NULL) {
    free(marpaESLIF_stringGenerator.s);
  }
  GENERICLOGGER_FREE(genericLoggerp);
  if (parlistWithoutParens != NULL) {
    free(parlistWithoutParens);
  }
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIF_lua_recognizer_pop_contextb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp)
/*****************************************************************************/
{
  static const char *funcs       = "_marpaESLIF_lua_recognizer_pop_contextb";
  marpaESLIF_t      *marpaESLIFp = marpaESLIFRecognizerp->marpaESLIFp;
  int                topi        = -1;
  lua_State         *L;
  const char        *pops        =
    "return function()\n"
    "  marpaESLIFContextStackp:pop()\n"
    "end\n";
  short              rcb;

  L = _marpaESLIF_lua_recognizer_newp(marpaESLIFRecognizerp);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  LUA_GETTOP(marpaESLIFp, L, &topi);

  /* ---------------------------------------------------------------------------------------------------------------- */
  /* return function()                                                                                                */
  /*   marpaESLIFContextStackp:pop()                                                                                  */
  /* end                                                                                                              */
  /* ---------------------------------------------------------------------------------------------------------------- */
  if (marpaESLIFRecognizerp->popContextActionp == NULL) {
    /* We initialize the correct action content. */
    marpaESLIFRecognizerp->popContextActionp = (marpaESLIF_action_t *) malloc(sizeof(marpaESLIF_action_t));
    if (MARPAESLIF_UNLIKELY(marpaESLIFRecognizerp->popContextActionp == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFp, "malloc failure, %s", strerror(errno));
      goto err;
    }
    marpaESLIFRecognizerp->popContextActionp->type                     = MARPAESLIF_ACTION_TYPE_LUA_FUNCTION;
    marpaESLIFRecognizerp->popContextActionp->u.luaFunction.luas       = NULL; /* Original action as per the grammar - not used */
    marpaESLIFRecognizerp->popContextActionp->u.luaFunction.actions    = NULL; /* The action injected into lua */
    marpaESLIFRecognizerp->popContextActionp->u.luaFunction.luacb      = 1;    /* True if action is precompiled */
    marpaESLIFRecognizerp->popContextActionp->u.luaFunction.luacp      = NULL; /* Precompiled chunk. Not NULL only when luacb is true and action as been used at least once */
    marpaESLIFRecognizerp->popContextActionp->u.luaFunction.luacl      = 0;    /* Precompiled chunk length */
    marpaESLIFRecognizerp->popContextActionp->u.luaFunction.luacstripp = NULL; /* Precompiled stripped chunk - not used */
    marpaESLIFRecognizerp->popContextActionp->u.luaFunction.luacstripl = 0;    /* Precompiled stripped chunk length */

    marpaESLIFRecognizerp->popContextActionp->u.luaFunction.actions = strdup(pops);
    if (MARPAESLIF_UNLIKELY(marpaESLIFRecognizerp->popContextActionp->u.luaFunction.actions == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFRecognizerp->marpaESLIFp, "strdup failure, %s", strerror(errno));
      goto err;
    }

    MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Generated action:\n%s", marpaESLIFRecognizerp->popContextActionp->u.luaFunction.actions);
  }

  marpaESLIFRecognizerp->actionp = marpaESLIFRecognizerp->popContextActionp;
  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_lua_recognizer_function_loadb(marpaESLIFRecognizerp))) {
    goto err;
  }

  if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_popContextb(marpaESLIFRecognizerp))) {
    MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, marpaESLIFLua_popContextb);
    errno = ENOSYS;
    goto err;
  }

  if (topi >= 0) {
    LUA_SETTOP(marpaESLIFp, L, topi);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIF_lua_recognizer_get_contextp(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *contextp)
/*****************************************************************************/
{
  static const char *funcs       = "_marpaESLIF_lua_recognizer_get_contextp";
  marpaESLIF_t      *marpaESLIFp = marpaESLIFRecognizerp->marpaESLIFp;
  int                topi        = -1;
  lua_State         *L;
  const char        *gets        =
    "return function()\n"
    "  return marpaESLIFContextStackp:get()\n"
    "end\n";
  short              rcb;

  L = _marpaESLIF_lua_recognizer_newp(marpaESLIFRecognizerp);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  LUA_GETTOP(marpaESLIFp, L, &topi);

  /* ---------------------------------------------------------------------------------------------------------------- */
  /* return function()                                                                                                */
  /*   return marpaESLIFContextStackp:get()                                                                           */
  /* end                                                                                                              */
  /* ---------------------------------------------------------------------------------------------------------------- */
  if (marpaESLIFRecognizerp->getContextActionp == NULL) {
    /* We initialize the correct action content. */
    marpaESLIFRecognizerp->getContextActionp = (marpaESLIF_action_t *) malloc(sizeof(marpaESLIF_action_t));
    if (MARPAESLIF_UNLIKELY(marpaESLIFRecognizerp->getContextActionp == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFp, "malloc failure, %s", strerror(errno));
      goto err;
    }
    marpaESLIFRecognizerp->getContextActionp->type                     = MARPAESLIF_ACTION_TYPE_LUA_FUNCTION;
    marpaESLIFRecognizerp->getContextActionp->u.luaFunction.luas       = NULL; /* Original action as per the grammar - not used */
    marpaESLIFRecognizerp->getContextActionp->u.luaFunction.actions    = NULL; /* The action injected into lua */
    marpaESLIFRecognizerp->getContextActionp->u.luaFunction.luacb      = 1;    /* True if action is precompiled */
    marpaESLIFRecognizerp->getContextActionp->u.luaFunction.luacp      = NULL; /* Precompiled chunk. Not NULL only when luacb is true and action as been used at least once */
    marpaESLIFRecognizerp->getContextActionp->u.luaFunction.luacl      = 0;    /* Precompiled chunk length */
    marpaESLIFRecognizerp->getContextActionp->u.luaFunction.luacstripp = NULL; /* Precompiled stripped chunk - not used */
    marpaESLIFRecognizerp->getContextActionp->u.luaFunction.luacstripl = 0;    /* Precompiled stripped chunk length */

    marpaESLIFRecognizerp->getContextActionp->u.luaFunction.actions = strdup(gets);
    if (MARPAESLIF_UNLIKELY(marpaESLIFRecognizerp->getContextActionp->u.luaFunction.actions == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFp, "strdup failure, %s", strerror(errno));
      goto err;
    }

    MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Generated action:\n%s", marpaESLIFRecognizerp->getContextActionp->u.luaFunction.actions);
  }

  marpaESLIFRecognizerp->actionp = marpaESLIFRecognizerp->getContextActionp;
  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_lua_recognizer_function_loadb(marpaESLIFRecognizerp))) {
    goto err;
  }

  if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_getContextb(marpaESLIFRecognizerp, contextp))) {
    MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, marpaESLIFLua_getContextb);
    errno = ENOSYS;
    goto err;
  }

  if (topi >= 0) {
    LUA_SETTOP(marpaESLIFp, L, topi);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIF_lua_recognizer_set_contextb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *contextp)
/*****************************************************************************/
{
  static const char *funcs       = "_marpaESLIF_lua_recognizer_set_contextb";
  marpaESLIF_t      *marpaESLIFp = marpaESLIFRecognizerp->marpaESLIFp;
  int                topi        = -1;
  lua_State         *L;
  const char        *sets        =
    "return function(context)\n"
    "  marpaESLIFContextStackp:set(context)\n"
    "end\n";
  short              rcb;

  L = _marpaESLIF_lua_recognizer_newp(marpaESLIFRecognizerp);
  if (MARPAESLIF_UNLIKELY(L == NULL)) {
    errno = ENOSYS;
    goto err;
  }

  LUA_GETTOP(marpaESLIFp, L, &topi);

  /* ---------------------------------------------------------------------------------------------------------------- */
  /* return function()                                                                                                */
  /*   return marpaESLIFContextStackp:set()                                                                           */
  /* end                                                                                                              */
  /* ---------------------------------------------------------------------------------------------------------------- */
  if (marpaESLIFRecognizerp->setContextActionp == NULL) {
    /* We initialize the correct action content. */
    marpaESLIFRecognizerp->setContextActionp = (marpaESLIF_action_t *) malloc(sizeof(marpaESLIF_action_t));
    if (MARPAESLIF_UNLIKELY(marpaESLIFRecognizerp->setContextActionp == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFp, "malloc failure, %s", strerror(errno));
      goto err;
    }
    marpaESLIFRecognizerp->setContextActionp->type                     = MARPAESLIF_ACTION_TYPE_LUA_FUNCTION;
    marpaESLIFRecognizerp->setContextActionp->u.luaFunction.luas       = NULL; /* Original action as per the grammar - not used */
    marpaESLIFRecognizerp->setContextActionp->u.luaFunction.actions    = NULL; /* The action injected into lua */
    marpaESLIFRecognizerp->setContextActionp->u.luaFunction.luacb      = 1;    /* True if action is precompiled */
    marpaESLIFRecognizerp->setContextActionp->u.luaFunction.luacp      = NULL; /* Precompiled chunk. Not NULL only when luacb is true and action as been used at least once */
    marpaESLIFRecognizerp->setContextActionp->u.luaFunction.luacl      = 0;    /* Precompiled chunk length */
    marpaESLIFRecognizerp->setContextActionp->u.luaFunction.luacstripp = NULL; /* Precompiled stripped chunk - not used */
    marpaESLIFRecognizerp->setContextActionp->u.luaFunction.luacstripl = 0;    /* Precompiled stripped chunk length */

    marpaESLIFRecognizerp->setContextActionp->u.luaFunction.actions = strdup(sets);
    if (MARPAESLIF_UNLIKELY(marpaESLIFRecognizerp->setContextActionp->u.luaFunction.actions == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFp, "strdup failure, %s", strerror(errno));
      goto err;
    }

    MARPAESLIFRECOGNIZER_TRACEF(marpaESLIFRecognizerp, funcs, "Generated action:\n%s", marpaESLIFRecognizerp->setContextActionp->u.luaFunction.actions);
  }

  marpaESLIFRecognizerp->actionp = marpaESLIFRecognizerp->setContextActionp;
  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_lua_recognizer_function_loadb(marpaESLIFRecognizerp))) {
    goto err;
  }

  if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_setContextb(marpaESLIFRecognizerp, contextp))) {
    MARPAESLIFLUA_LOG_ERROR_STRING(marpaESLIFp, L, ruleCallbackp);
    errno = ENOSYS;
    goto err;
  }

  if (topi >= 0) {
    LUA_SETTOP(marpaESLIFp, L, topi);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}
