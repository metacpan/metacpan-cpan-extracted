#include "marpaESLIF/internal/lua.h"
#include <setjmp.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <limits.h>

/* Revisit lua context that refers to values inside the lua interpreter */
#undef MARPAESLIFLUA_CONTEXT
#define MARPAESLIFLUA_CONTEXT MARPAESLIF_EMBEDDED_CONTEXT_LUA

/* Revisit some lua macros */
#undef marpaESLIFLua_luaL_error
#define marpaESLIFLua_luaL_error(L, string) luaunpanicL_error(NULL, L, string)
#undef marpaESLIFLua_luaL_errorf
#define marpaESLIFLua_luaL_errorf(L, formatstring, ...) luaunpanicL_error(NULL, L, formatstring, __VA_ARGS__)
#undef marpaESLIFLua_luaL_newlib
#define marpaESLIFLua_luaL_newlib(L, l) (! luaunpanicL_newlib(L, l))
#include "../src/bindings/lua/src/marpaESLIFLua.c"

#undef  FILENAMES
#define FILENAMES "lua.c" /* For logging */


static short _marpaESLIFValue_lua_newb(marpaESLIFValue_t *marpaESLIFValuep);
static short _marpaESLIFRecognizer_lua_newb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp);
static int   _marpaESLIFGrammar_lua_writeri(lua_State *L, const void* p, size_t sz, void* ud);

#define LOG_PANIC_STRING(containerp, f) do {                            \
    char *panicstring;							\
    if (luaunpanic_panicstring(&panicstring, containerp->L)) {          \
      MARPAESLIF_ERRORF(containerp->marpaESLIFp, "%s panic", #f);       \
    } else {								\
      MARPAESLIF_ERRORF(containerp->marpaESLIFp, "%s panic: %s", #f, panicstring); \
    }									\
  } while (0)

#define LOG_ERROR_STRING(containerp, f) do {                            \
    const char *errorstring;                                            \
    if (luaunpanic_tostring(&errorstring, containerp->L, -1)) {         \
      LOG_PANIC_STRING(containerp, luaunpanic_tostring);                \
      MARPAESLIF_ERRORF(containerp->marpaESLIFp, "%s failure", #f);     \
    } else {                                                            \
      if (errorstring == NULL) {                                        \
        MARPAESLIF_ERRORF(containerp->marpaESLIFp, "%s failure", #f);   \
      } else {								\
        MARPAESLIF_ERRORF(containerp->marpaESLIFp, "%s failure: %s", #f, errorstring); \
      }									\
    }                                                                   \
  } while (0)

#define LOG_LATEST_ERROR(containerp) do {                               \
    const char *errorstring;                                            \
    if (luaunpanic_tostring(&errorstring, containerp->L, -1)) {         \
      LOG_PANIC_STRING(containerp, luaunpanic_tostring);                \
      MARPAESLIF_ERRORF(containerp->marpaESLIFp, "%s failure", "luaunpanic_tostring"); \
    } else {                                                            \
      if (errorstring != NULL) {                                        \
        MARPAESLIF_ERROR(containerp->marpaESLIFp, errorstring);         \
      }									\
    }                                                                   \
  } while (0)

#define LUAL_CHECKVERSION(containerp) do {                              \
    if (luaunpanicL_checkversion(containerp->L)) {                      \
      LOG_PANIC_STRING(containerp, luaL_checkversion);                  \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUAL_OPENLIBS(containerp) do {                                 \
    if (luaunpanicL_openlibs(containerp->L)) {                         \
      LOG_PANIC_STRING(containerp, luaL_openlibs);                     \
      errno = ENOSYS;                                                  \
      goto err;                                                        \
    }                                                                  \
  } while (0)

#define LUA_PUSHNIL(containerp) do {                                   \
    if (luaunpanic_pushnil(containerp->L)) {                           \
      LOG_PANIC_STRING(containerp, lua_pushnil);                       \
      errno = ENOSYS;                                                  \
      goto err;                                                        \
    }                                                                  \
  } while (0)

#define LUA_PUSHLSTRING(containerp, s, l) do {                          \
    if (luaunpanic_pushlstring(NULL, containerp->L, s, l)) {            \
      LOG_PANIC_STRING(containerp, lua_pushlstring);                    \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUAL_DOSTRING(containerp, string) do {                          \
    int rc;                                                             \
    if (luaunpanicL_dostring(&rc, containerp->L, string)) {             \
      LOG_PANIC_STRING(containerp, luaL_dostring);                      \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    if (rc) {                                                           \
      LOG_ERROR_STRING(containerp, luaL_dostring);                      \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUA_PUSHLIGHTUSERDATA(containerp, p) do {                      \
    if (luaunpanic_pushlightuserdata(containerp->L, p)) {              \
      LOG_PANIC_STRING(containerp, lua_pushlightuserdata);             \
      errno = ENOSYS;                                                  \
      goto err;                                                        \
    }                                                                  \
  } while (0)

#define LUA_NEWTABLE(containerp) do {                                  \
    if (luaunpanic_newtable(containerp->L)) {                          \
      LOG_PANIC_STRING(containerp, lua_newtable);                      \
      errno = ENOSYS;                                                  \
      goto err;                                                        \
    }                                                                  \
  } while (0)

#define LUA_PUSHINTEGER(containerp, i) do {                            \
    if (luaunpanic_pushinteger(containerp->L, i)) {                    \
      LOG_PANIC_STRING(containerp, lua_pushinteger);                   \
      errno = ENOSYS;                                                  \
      goto err;                                                        \
    }                                                                  \
  } while (0)

#define LUA_PUSHNUMBER(containerp, x) do {                             \
    if (luaunpanic_pushnumber(containerp->L, x)) {                     \
      LOG_PANIC_STRING(containerp, lua_pushnumber);                    \
      errno = ENOSYS;                                                  \
      goto err;                                                        \
    }                                                                  \
  } while (0)

#define LUA_PUSHBOOLEAN(containerp, b) do {                            \
    if (luaunpanic_pushboolean(containerp->L, b)) {                    \
      LOG_PANIC_STRING(containerp, lua_pushboolean);                   \
      errno = ENOSYS;                                                  \
      goto err;                                                        \
    }                                                                  \
  } while (0)

#define LUA_DUMP(containerp, writer, data, strip) do {                  \
    int _rci = -1;                                                      \
    if (luaunpanic_dump(&_rci, containerp->L, writer, data, strip)) {   \
      LOG_PANIC_STRING(containerp, lua_dump);                           \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    if (_rci != 0) {                                                    \
      LOG_ERROR_STRING(containerp, lua_dump);                           \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUA_RAWGETI(rcp, containerp, idx, n) do {                       \
    if (luaunpanic_rawgeti(rcp, containerp->L, idx, n)) {               \
      LOG_PANIC_STRING(containerp, lua_rawgeti);                        \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUA_GETFIELDI(rcp, containerp, idx, k) do {                     \
    if (luaunpanic_getfield(rcp, containerp->L, idx, k)) {              \
      LOG_PANIC_STRING(containerp, lua_getfield);                       \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUA_RAWSETI(containerp, idx, n) do {                            \
    if (luaunpanic_rawseti(containerp->L, idx, n)) {                    \
      LOG_PANIC_STRING(containerp, lua_rawseti);                        \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUA_REMOVE(containerp, idx) do {                                \
    if (luaunpanic_remove(containerp->L, idx)) {                        \
      LOG_PANIC_STRING(containerp, lua_remove);                         \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUA_GETGLOBAL(rcp, containerp, name) do {                       \
    if (luaunpanic_getglobal(rcp, containerp->L, name)) {               \
      LOG_PANIC_STRING(containerp, lua_getglobal);                      \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUA_SETGLOBAL(containerp, name) do {                            \
    if (luaunpanic_setglobal(containerp->L, name)) {                    \
      LOG_PANIC_STRING(containerp, lua_setglobal);                      \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUAL_LOADBUFFER(containerp, s, sz, n) do {                      \
    int _rci = -1;                                                      \
    if (luaunpanicL_loadbuffer(&_rci, containerp->L, s, sz, n)) {       \
      LOG_PANIC_STRING(containerp, luaL_loadbuffer);                    \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    if (_rci != 0) {                                                    \
      LOG_ERROR_STRING(containerp, luaL_loadbuffer);                    \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUA_CALL(containerp, n, r) do {                                 \
    if (luaunpanic_call(containerp->L, n, r)) {                         \
      LOG_PANIC_STRING(containerp, lua_call);                           \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUA_SETTOP(containerp, idx) do {                             \
    if (luaunpanic_settop(containerp->L, idx)) {                     \
      LOG_PANIC_STRING(containerp, lua_settop);                      \
      errno = ENOSYS;                                                \
      goto err;                                                      \
    }                                                                \
  } while (0)

#define LUA_GETTOP(rcp, containerp) do {			     \
    if (luaunpanic_settop(rcp, containerp->L)) {		     \
      LOG_PANIC_STRING(containerp, lua_gettop);                      \
      errno = ENOSYS;                                                \
      goto err;                                                      \
    }                                                                \
  } while (0)

#define LUA_TYPE(containerp, rcp, idx) do {                          \
    if (luaunpanic_type(rcp, containerp->L, idx)) {                  \
      LOG_PANIC_STRING(containerp, lua_type);                        \
      errno = ENOSYS;                                                \
      goto err;                                                      \
    }                                                                \
  } while (0)

#define LUA_TOBOOLEAN(containerp, rcp, idx) do {                     \
    if (luaunpanic_toboolean(rcp, containerp->L, idx)) {             \
      LOG_PANIC_STRING(containerp, lua_toboolean);                   \
      errno = ENOSYS;                                                \
      goto err;                                                      \
    }                                                                \
  } while (0)

#define LUA_TONUMBER(containerp, rcp, idx) do {                         \
    int isnum;                                                          \
    if (luaunpanic_tonumberx(rcp, containerp->L, idx, &isnum)) {        \
      LOG_PANIC_STRING(containerp, lua_tonumberx);                      \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    if (! isnum) {                                                      \
      MARPAESLIF_ERROR(containerp->marpaESLIFp, "lua_tonumberx failure"); \
    }                                                                   \
  } while (0)

#define LUA_TOLSTRING(containerp, rcpp, idx, lenp) do {                 \
    if (luaunpanic_tolstring(rcpp, containerp->L, idx, lenp)) {         \
      LOG_PANIC_STRING(containerp, lua_tolstring);                      \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUA_TOPOINTER(containerp, rcpp, idx) do {                    \
    if (luaunpanic_topointer(rcpp, containerp->L, idx)) {            \
      LOG_PANIC_STRING(containerp, lua_topointer);                   \
      errno = ENOSYS;                                                \
      goto err;                                                      \
    }                                                                \
  } while (0)

#define LUA_TOUSERDATA(containerp, rcpp, idx) do {                    \
    if (luaunpanic_touserdata((void **) rcpp, containerp->L, idx)) {  \
      LOG_PANIC_STRING(containerp, lua_touserdata);                   \
      errno = ENOSYS;                                                 \
      goto err;                                                       \
    }                                                                 \
  } while (0)

#define LUAL_REQUIREF(containerp, modname, openf, glb) do {             \
    if (luaunpanicL_requiref(containerp->L, modname, openf, glb)) {     \
      LOG_PANIC_STRING(containerp, lual_requiref);                      \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUA_POP(containerp, n) do {                             \
    if (luaunpanic_pop(containerp->L, n)) {                     \
      LOG_PANIC_STRING(containerp, lua_pop);                    \
      errno = ENOSYS;                                           \
      goto err;                                                 \
    }                                                           \
  } while (0)

#define LUA_PCALL(containerp, n, r, f) do {                             \
    int _rci;                                                           \
    if (luaunpanic_pcall(&_rci, containerp->L, n, r, f)) {              \
      LOG_PANIC_STRING(containerp, lua_pcall);                          \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    if (_rci != 0) {                                                    \
      LOG_ERROR_STRING(containerp, lua_pcall);                          \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUAL_SETFUNCS(containerp, l, nup) do {                          \
    if (luaunpanicL_setfuncs(containerp->L, l, nup)) {                  \
      LOG_PANIC_STRING(containerp, lua_pcall);                          \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

/*****************************************************************************/
static short _marpaESLIFValue_lua_newb(marpaESLIFValue_t *marpaESLIFValuep)
/*****************************************************************************/
/* This function is called only if there is at least one <luascript/>        */
/*****************************************************************************/
{
  marpaESLIFGrammar_t *marpaESLIFGrammarp;
  short                rcb;

  if (marpaESLIFValuep->L != NULL) {
    /* Already done */
    rcb = 1;
    goto done;
  }

  marpaESLIFGrammarp = marpaESLIFValuep->marpaESLIFRecognizerp->marpaESLIFGrammarp;

  /* Create Lua state */
  if (luaunpanicL_newstate(&(marpaESLIFValuep->L))) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "luaunpanicL_newstate failure");
    errno = ENOSYS;
    goto err;
  }
  if (marpaESLIFValuep->L == NULL) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "luaunpanicL_success but lua_State is NULL");
    errno = ENOSYS;
    goto err;
  }

  /* Open all available libraries */
  LUAL_OPENLIBS(marpaESLIFValuep);

  /* Check Lua version */
  LUAL_CHECKVERSION(marpaESLIFValuep);

  /* Load the marpaESLIFLua library built-in */
  LUAL_REQUIREF(marpaESLIFValuep, "marpaESLIFLua", marpaESLIFLua_installi, 1);

  /* Inject global variables */
  if (! marpaESLIFLua_marpaESLIF_newFromUnmanagedi(marpaESLIFValuep->L, marpaESLIFValuep->marpaESLIFp)) goto err;                      /* stack: marpaESLIFLua, marpaESLIF */
  LUA_SETGLOBAL(marpaESLIFValuep, "marpaESLIF");                                                                                       /* stack: marpaESLIFLua */

  if (! marpaESLIFLua_marpaESLIFGrammar_newFromUnmanagedi(marpaESLIFValuep->L, marpaESLIFValuep->marpaESLIFRecognizerp->marpaESLIFGrammarp)) goto err; /* stack: marpaESLIFLua, marpaESLIFGrammar */
  LUA_SETGLOBAL(marpaESLIFValuep, "marpaESLIFGrammar");                                                                                /* stack: marpaESLIFLua */

  if (! marpaESLIFLua_marpaESLIFRecognizer_newFromUnmanagedi(marpaESLIFValuep->L, marpaESLIFValuep->marpaESLIFRecognizerp)) goto err;  /* stack: marpaESLIFLua, marpaESLIFRecognizer */
  LUA_SETGLOBAL(marpaESLIFValuep, "marpaESLIFRecognizer");                                                                             /* stack: marpaESLIFLua */

  if (! marpaESLIFLua_marpaESLIFValue_newFromUnmanagedi(marpaESLIFValuep->L, marpaESLIFValuep)) goto err;                              /* stack: marpaESLIFLua, marpaESLIFValue */
  LUA_SETGLOBAL(marpaESLIFValuep, "marpaESLIFValue");                                                                                  /* stack: marpaESLIFLua */

  LUA_POP(marpaESLIFValuep, 1);                                                                                                        /* stack: */

  /* We load byte code generated during grammar validation */
  if ((marpaESLIFGrammarp->luabytep != NULL) && (marpaESLIFGrammarp->luabytel > 0)) {
    LUAL_LOADBUFFER(marpaESLIFValuep, marpaESLIFGrammarp->luaprecompiledp, marpaESLIFGrammarp->luaprecompiledl, "=<luaScript/>");
    LUA_PCALL(marpaESLIFValuep, 0, LUA_MULTRET, 0);
    /* Clear the stack */
    LUA_SETTOP(marpaESLIFValuep, 0);
  }

  rcb = 1;
  goto done;

 err:
  if (marpaESLIFValuep->L != NULL) {
    if (luaunpanic_close(marpaESLIFValuep->L)) {
      LOG_PANIC_STRING(marpaESLIFValuep, lua_close);
    }
    marpaESLIFValuep->L = NULL;
  }
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFRecognizer_lua_newb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp)
/*****************************************************************************/
/* This function is called only if there is at least one <luascript/>        */
/*****************************************************************************/
{
  marpaESLIFGrammar_t *marpaESLIFGrammarp;
  short                rcb;

  if (marpaESLIFRecognizerp->L != NULL) {
    /* Already done */
    rcb = 1;
    goto done;
  }

  marpaESLIFGrammarp = marpaESLIFRecognizerp->marpaESLIFGrammarp;

  /* Create Lua state */
  if (luaunpanicL_newstate(&(marpaESLIFRecognizerp->L))) {
    MARPAESLIF_ERROR(marpaESLIFRecognizerp->marpaESLIFp, "luaunpanicL_newstate failure");
    errno = ENOSYS;
    goto err;
  }
  if (marpaESLIFRecognizerp->L == NULL) {
    MARPAESLIF_ERROR(marpaESLIFRecognizerp->marpaESLIFp, "luaunpanicL_success but lua_State is NULL");
    errno = ENOSYS;
    goto err;
  }

  /* Open all available libraries */
  LUAL_OPENLIBS(marpaESLIFRecognizerp);

  /* Check Lua version */
  LUAL_CHECKVERSION(marpaESLIFRecognizerp);

  /* Load the marpaESLIFLua library built-in */
  LUAL_REQUIREF(marpaESLIFRecognizerp, "marpaESLIFLua", marpaESLIFLua_installi, 1);

  /* Inject global variables */
  if (! marpaESLIFLua_marpaESLIF_newFromUnmanagedi(marpaESLIFRecognizerp->L, marpaESLIFRecognizerp->marpaESLIFp)) goto err;            /* stack: marpaESLIFLua, marpaESLIF */
  LUA_SETGLOBAL(marpaESLIFRecognizerp, "marpaESLIF");                                                                                  /* stack: marpaESLIFLua */

  if (! marpaESLIFLua_marpaESLIFGrammar_newFromUnmanagedi(marpaESLIFRecognizerp->L, marpaESLIFRecognizerp->marpaESLIFGrammarp)) goto err; /* stack: marpaESLIFLua, marpaESLIFGrammar */
  LUA_SETGLOBAL(marpaESLIFRecognizerp, "marpaESLIFGrammar");                                                                           /* stack: marpaESLIFLua */

  if (! marpaESLIFLua_marpaESLIFRecognizer_newFromUnmanagedi(marpaESLIFRecognizerp->L, marpaESLIFRecognizerp)) goto err;               /* stack: marpaESLIFLua, marpaESLIFRecognizer */
  LUA_SETGLOBAL(marpaESLIFRecognizerp, "marpaESLIFRecognizer");                                                                        /* stack: marpaESLIFLua */

  LUA_POP(marpaESLIFRecognizerp, 1);                                                                                                   /* stack: */

  /* We load byte code generated during grammar validation */
  if ((marpaESLIFGrammarp->luabytep != NULL) && (marpaESLIFGrammarp->luabytel > 0)) {
    LUAL_LOADBUFFER(marpaESLIFRecognizerp, marpaESLIFGrammarp->luaprecompiledp, marpaESLIFGrammarp->luaprecompiledl, "=<luaScript/>");
    LUA_PCALL(marpaESLIFRecognizerp, 0, LUA_MULTRET, 0);
    /* Clear the stack */
    LUA_SETTOP(marpaESLIFRecognizerp, 0);
  }

  rcb = 1;
  goto done;

 err:
  if (marpaESLIFRecognizerp->L != NULL) {
    if (luaunpanic_close(marpaESLIFRecognizerp->L)) {
      LOG_PANIC_STRING(marpaESLIFRecognizerp, lua_close);
    }
    marpaESLIFRecognizerp->L = NULL;
  }
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static void _marpaESLIFValue_lua_freev(marpaESLIFValue_t *marpaESLIFValuep)
/*****************************************************************************/
{
  if (marpaESLIFValuep->L != NULL) {
    if (luaunpanic_close(marpaESLIFValuep->L)) {
      LOG_PANIC_STRING(marpaESLIFValuep, luaunpanic_close);
    }
    marpaESLIFValuep->L = NULL;
  }
}

/*****************************************************************************/
static void _marpaESLIFRecognizer_lua_freev(marpaESLIFRecognizer_t *marpaESLIFRecognizerp)
/*****************************************************************************/
{
  if (marpaESLIFRecognizerp->L != NULL) {
    if (luaunpanic_close(marpaESLIFRecognizerp->L)) {
      LOG_PANIC_STRING(marpaESLIFRecognizerp, luaunpanic_close);
    }
    marpaESLIFRecognizerp->L = NULL;
  }
}

/*****************************************************************************/
static short _marpaESLIFValue_lua_actionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  static const char             *funcs                 = "_marpaESLIFValue_lua_actionb";
  marpaESLIFRecognizer_t        *marpaESLIFRecognizerp = marpaESLIFValuep->marpaESLIFRecognizerp;
  marpaESLIFValueRuleCallback_t  ruleCallbackp;
  short                          rcb;

  /* Create the lua state if needed */
  if (! _marpaESLIFValue_lua_newb(marpaESLIFValuep)) {
    goto err;
  }

  ruleCallbackp = marpaESLIFLua_valueRuleActionResolver(userDatavp, marpaESLIFValuep, marpaESLIFValuep->actions);
  if (ruleCallbackp == NULL) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Lua bindings returned no rule callback");
    goto err; /* Lua will shutdown anyway */
  }

  rcb = ruleCallbackp(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb);

  if (! rcb) goto err;

  goto done;

 err:
  LOG_LATEST_ERROR(marpaESLIFValuep);
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFValue_lua_symbolb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFValueResult_t *marpaESLIFValueResultp, int resulti)
/*****************************************************************************/
{
  static const char               *funcs                 = "_marpaESLIFValue_lua_symbolb";
  marpaESLIFRecognizer_t          *marpaESLIFRecognizerp = marpaESLIFValuep->marpaESLIFRecognizerp;
  marpaESLIFValueSymbolCallback_t  symbolCallbackp;
  short                            rcb;

  /* Create the lua state if needed */
  if (! _marpaESLIFValue_lua_newb(marpaESLIFValuep)) {
    goto err;
  }

  symbolCallbackp = marpaESLIFLua_valueSymbolActionResolver(userDatavp, marpaESLIFValuep, marpaESLIFValuep->actions);
  if (symbolCallbackp == NULL) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Lua bindings returned no symbol callback");
    goto err; /* Lua will shutdown anyway */
  }

  rcb = symbolCallbackp(userDatavp, marpaESLIFValuep, marpaESLIFValueResultp, resulti);

  if (! rcb) goto err;

  goto done;

 err:
  LOG_LATEST_ERROR(marpaESLIFValuep);
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFRecognizer_lua_ifactionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFValueResultp, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp)
/*****************************************************************************/
{
  static const char                *funcs = "_marpaESLIFRecognizer_lua_ifactionb";
  marpaESLIFRecognizerIfCallback_t  ifCallbackp;
  short                             rcb;

  /* Create the lua state if needed */
  if (! _marpaESLIFRecognizer_lua_newb(marpaESLIFRecognizerp)) {
    goto err;
  }

  ifCallbackp = marpaESLIFLua_recognizerIfActionResolver(userDatavp, marpaESLIFRecognizerp, marpaESLIFRecognizerp->ifactions);
  if (ifCallbackp == NULL) {
    MARPAESLIF_ERROR(marpaESLIFRecognizerp->marpaESLIFp, "Lua bindings returned no if-action callback");
    goto err; /* Lua will shutdown anyway */
  }

  rcb = ifCallbackp(userDatavp, marpaESLIFRecognizerp, marpaESLIFValueResultp, marpaESLIFValueResultBoolp);

  if (! rcb) goto err;

  goto done;

 err:
  LOG_LATEST_ERROR(marpaESLIFRecognizerp);
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFGrammar_lua_precompileb(marpaESLIFGrammar_t *marpaESLIFGrammarp)
/*****************************************************************************/
{
  short  rcb;
  struct _container {
    lua_State *L;
    marpaESLIF_t *marpaESLIFp;
  } container = {
    NULL,
    marpaESLIFGrammar_eslifp(marpaESLIFGrammarp)
  };
  struct _container *containerp = &container;

  if ((marpaESLIFGrammarp->luabytep != NULL) && (marpaESLIFGrammarp->luabytel > 0)) {

    /* Create Lua state */
    if (luaunpanicL_newstate(&(containerp->L))) {
      MARPAESLIF_ERROR(marpaESLIFGrammarp->marpaESLIFp, "luaunpanicL_newstate failure");
      errno = ENOSYS;
      goto err;
    }
    if (containerp->L == NULL) {
      MARPAESLIF_ERROR(marpaESLIFGrammarp->marpaESLIFp, "luaunpanicL_success but lua_State is NULL");
      errno = ENOSYS;
      goto err;
    }

    /* Check Lua version */
    LUAL_CHECKVERSION(containerp);

    /* Compiles lua script present in the grammar */
    LUAL_LOADBUFFER(containerp, marpaESLIFGrammarp->luabytep, marpaESLIFGrammarp->luabytel, "=<luaScript/>");

    /* Result is a "function" at the top of the stack - we now have to dump it so that lua knows about it  */
    LUA_DUMP(containerp, _marpaESLIFGrammar_lua_writeri, marpaESLIFGrammarp, 0 /* strip */);

    /* Clear the stack */
    LUA_SETTOP(containerp, 0);
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  /* In any case, free the lua_State, that we temporary created */
  if (containerp->L != NULL) {
    if (luaunpanic_close(containerp->L)) {
      LOG_PANIC_STRING(containerp, luaunpanic_close);
    }
  }

  return rcb;
}

/*****************************************************************************/
static int _marpaESLIFGrammar_lua_writeri(lua_State *L, const void* p, size_t sz, void* ud)
/*****************************************************************************/
{
  marpaESLIFGrammar_t *marpaESLIFGrammarp = (marpaESLIFGrammar_t *) ud;
  char                *q;
  int                  rci;

  if (sz > 0) {
    if (marpaESLIFGrammarp->luaprecompiledp == NULL) {
      marpaESLIFGrammarp->luaprecompiledp = (char *) malloc(sz);
      if (marpaESLIFGrammarp->luaprecompiledp == NULL) {
        MARPAESLIF_ERRORF(marpaESLIFGrammarp->marpaESLIFp, "malloc failure, %s", strerror(errno));
        goto err;
      }
      q = marpaESLIFGrammarp->luaprecompiledp;
    } else {
      q = (char *) realloc(marpaESLIFGrammarp->luaprecompiledp, marpaESLIFGrammarp->luaprecompiledl + sz);
      if (q == NULL) {
        MARPAESLIF_ERRORF(marpaESLIFGrammarp->marpaESLIFp, "malloc failure, %s", strerror(errno));
        goto err;
      }
      marpaESLIFGrammarp->luaprecompiledp = q;
      q += marpaESLIFGrammarp->luaprecompiledl;
    }

    memcpy(q, p, sz);
    marpaESLIFGrammarp->luaprecompiledl += sz;
  }

  rci = 0;
  goto end;
  
 err:
  rci = 1;
  
 end:
  return rci;
}

/****************************************************************************/
/* When MARPAESLIFLUA_EMBEDDED the file that includes this source must      */
/* provide the following implementations.                                   */
/****************************************************************************/

/****************************************************************************/
static short marpaESLIFLua_lua_pushinteger(lua_State *L, lua_Integer n)
/****************************************************************************/
{
  return ! luaunpanic_pushinteger(L, n);
}

/****************************************************************************/
static short marpaESLIFLua_lua_setglobal(lua_State *L, const char *name)
/****************************************************************************/
{
  return ! luaunpanic_setglobal(L, name);
}

/****************************************************************************/
static short marpaESLIFLua_lua_getglobal(int *luaip, lua_State *L, const char *name)
/****************************************************************************/
{
  return ! luaunpanic_getglobal(luaip, L, name);
}

/****************************************************************************/
static short marpaESLIFLua_lua_type(int *luaip, lua_State *L, int index)
/****************************************************************************/
{
  return ! luaunpanic_type(luaip, L, index);
}

/****************************************************************************/
static short marpaESLIFLua_lua_pop(lua_State *L, int n)
/****************************************************************************/
{
  return ! luaunpanic_pop(L, n);
}

/****************************************************************************/
static short marpaESLIFLua_lua_newtable(lua_State *L)
/****************************************************************************/
{
  return ! luaunpanic_newtable(L);
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushcfunction(lua_State *L, lua_CFunction f)
/****************************************************************************/
{
  return ! luaunpanic_pushcfunction(L, f);
}

/****************************************************************************/
static short marpaESLIFLua_lua_setfield(lua_State *L, int index, const char *k)
/****************************************************************************/
{
  return ! luaunpanic_setfield(L, index, k);
}

/****************************************************************************/
static short marpaESLIFLua_lua_setmetatable(lua_State *L, int index)
/****************************************************************************/
{
  return ! luaunpanic_setmetatable(NULL, L, index);
}

/****************************************************************************/
static short marpaESLIFLua_lua_insert(lua_State *L, int index)
/****************************************************************************/
{
  return ! luaunpanic_insert(L, index);
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawgeti(int *luaip, lua_State *L, int index, lua_Integer n)
/****************************************************************************/
{
  return ! luaunpanic_rawgeti(luaip, L, index, n);
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawget(int *luaip, lua_State *L, int index)
/****************************************************************************/
{
  return ! luaunpanic_rawget(luaip, L, index);
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawgetp(int *luaip, lua_State *L, int index, const void *p)
/****************************************************************************/
{
  return ! luaunpanic_rawgetp(luaip, L, index, p);
}

/****************************************************************************/
static short marpaESLIFLua_lua_remove(lua_State *L, int index)
/****************************************************************************/
{
  return ! luaunpanic_remove(L, index);
}

/****************************************************************************/
static short marpaESLIFLua_lua_createtable(lua_State *L, int narr, int nrec)
/****************************************************************************/
{
  return ! luaunpanic_createtable(L, narr, nrec);
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawseti(lua_State *L, int index, lua_Integer i)
/****************************************************************************/
{
  return ! luaunpanic_rawseti(L, index, i);
}

/****************************************************************************/
static short marpaESLIFLua_lua_seti(lua_State *L, int index, lua_Integer i)
/****************************************************************************/
{
  return ! luaunpanic_seti(L, index, i);
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushstring(const char **luasp, lua_State *L, const char *s)
/****************************************************************************/
{
  return ! luaunpanic_pushstring(luasp, L, s);
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushlstring(const char **luasp, lua_State *L, const char *s, size_t len)
/****************************************************************************/
{
  return ! luaunpanic_pushlstring(luasp, L, s, len);
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushnil(lua_State *L)
/****************************************************************************/
{
  return ! luaunpanic_pushnil(L);
}

/****************************************************************************/
static short marpaESLIFLua_lua_getfield(int *luaip, lua_State *L, int index, const char *k)
/****************************************************************************/
{
  return ! luaunpanic_getfield(luaip, L, index, k);
}

/****************************************************************************/
static short marpaESLIFLua_lua_call(lua_State *L, int nargs, int nresults)
/****************************************************************************/
{
  return ! luaunpanic_call(L, nargs, nresults);
}

/****************************************************************************/
static short marpaESLIFLua_lua_settop(lua_State *L, int index)
/****************************************************************************/
{
  return ! luaunpanic_settop(L, index);
}

/****************************************************************************/
static short marpaESLIFLua_lua_copy(lua_State *L, int fromidx, int toidx)
/****************************************************************************/
{
  return ! luaunpanic_copy(L, fromidx, toidx);
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawsetp(lua_State *L, int index, const void *p)
/****************************************************************************/
{
  return ! luaunpanic_rawsetp(L, index, p);
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawset(lua_State *L, int index)
/****************************************************************************/
{
  return ! luaunpanic_rawset(L, index);
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushboolean(lua_State *L, int b)
/****************************************************************************/
{
  return ! luaunpanic_pushboolean(L, b);
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushnumber(lua_State *L, lua_Number n)
/****************************************************************************/
{
  return ! luaunpanic_pushnumber(L, n);
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushlightuserdata(lua_State *L, void *p)
/****************************************************************************/
{
  return ! luaunpanic_pushlightuserdata(L, p);
}

/****************************************************************************/
static short marpaESLIFLua_lua_newuserdata(void **rcpp, lua_State *L, size_t sz)
/****************************************************************************/
{
  return ! luaunpanic_newuserdata(rcpp, L, sz);
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushvalue(lua_State *L, int index)
/****************************************************************************/
{
  return ! luaunpanic_pushvalue(L, index);
}

/****************************************************************************/
static short marpaESLIFLua_luaL_ref(int *rcip, lua_State *L, int t)
/****************************************************************************/
{
  return ! luaunpanicL_ref(rcip, L, t);
}

/****************************************************************************/
static short marpaESLIFLua_luaL_unref(lua_State *L, int t, int ref)
/****************************************************************************/
{
  return ! luaunpanicL_unref(L, t, ref);
}

/****************************************************************************/
static short marpaESLIFLua_luaL_requiref(lua_State *L, const char *modname, lua_CFunction openf, int glb)
/****************************************************************************/
{
  return ! luaunpanicL_requiref(L, modname, openf, glb);
}

/****************************************************************************/
static short marpaESLIFLua_lua_touserdata(void **rcpp, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_touserdata(rcpp, L, idx);
}

/****************************************************************************/
static short marpaESLIFLua_lua_tointeger(lua_Integer *rcip, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_tointeger(rcip, L, idx);
}

/****************************************************************************/
static short marpaESLIFLua_lua_tointegerx(lua_Integer *rcip, lua_State *L, int idx, int *isnum)
/****************************************************************************/
{
  return ! luaunpanic_tointegerx(rcip, L, idx, isnum);
}

/****************************************************************************/
static short marpaESLIFLua_lua_tonumber(lua_Number *rcdp, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_tonumber(rcdp, L, idx);
}

/****************************************************************************/
static short marpaESLIFLua_lua_tonumberx(lua_Number *rcdp, lua_State *L, int idx, int *isnum)
/****************************************************************************/
{
  return ! luaunpanic_tonumberx(rcdp, L, idx, isnum);
}

/****************************************************************************/
static short marpaESLIFLua_lua_toboolean(int *rcip, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_toboolean(rcip, L, idx);
}

/****************************************************************************/
static short marpaESLIFLua_luaL_tolstring(const char **rcp, lua_State *L, int idx, size_t *len)
/****************************************************************************/
{
  return ! luaunpanicL_tolstring(rcp, L, idx, len);
}

/****************************************************************************/
static short marpaESLIFLua_lua_tolstring(const char **rcpp, lua_State *L, int idx, size_t *len)
/****************************************************************************/
{
  return ! luaunpanic_tolstring(rcpp, L, idx, len);
}

/****************************************************************************/
static short marpaESLIFLua_lua_tostring(const char **rcpp, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_tostring(rcpp, L, idx);
}

/****************************************************************************/
static short marpaESLIFLua_lua_compare(int *rcip, lua_State *L, int idx1, int idx2, int op)
/****************************************************************************/
{
  return ! luaunpanic_compare(rcip, L, idx1, idx2, op);
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawequal(int *rcip, lua_State *L, int idx1, int idx2)
/****************************************************************************/
{
  return ! luaunpanic_rawequal(rcip, L, idx1, idx2);
}

/****************************************************************************/
static short marpaESLIFLua_lua_isnil(int *rcip, lua_State *L, int n)
/****************************************************************************/
{
  return ! luaunpanic_isnil(rcip, L, n);
}

/****************************************************************************/
static short marpaESLIFLua_lua_gettop(int *rcip, lua_State *L)
/****************************************************************************/
{
  return ! luaunpanic_gettop(rcip, L);
}

/****************************************************************************/
static short marpaESLIFLua_lua_absindex(int *rcip, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_absindex(rcip, L, idx);
}

/****************************************************************************/
static short marpaESLIFLua_lua_next(int *rcip, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_next(rcip, L, idx);
}

/****************************************************************************/
static short marpaESLIFLua_luaL_checklstring(const char **rcp, lua_State *L, int arg, size_t *l)
/****************************************************************************/
{
  return ! luaunpanicL_checklstring(rcp, L, arg, l);
}

/****************************************************************************/
static short marpaESLIFLua_luaL_checkstring(const char **rcp, lua_State *L, int arg)
/****************************************************************************/
{
  return ! luaunpanicL_checkstring(rcp, L, arg);
}

/****************************************************************************/
static short marpaESLIFLua_luaL_checkinteger(lua_Integer *rcp, lua_State *L, int arg)
/****************************************************************************/
{
  return ! luaunpanicL_checkinteger(rcp, L, arg);
}

/****************************************************************************/
static short marpaESLIFLua_lua_getmetatable(int *rcip, lua_State *L, int index)
/****************************************************************************/
{
  return ! luaunpanic_getmetatable(rcip, L, index);
}

/****************************************************************************/
static short marpaESLIFLua_luaL_callmeta(int *rcp, lua_State *L, int obj, const char *e)
/****************************************************************************/
{
  return ! luaunpanicL_callmeta(rcp, L, obj, e);
}

/****************************************************************************/
static short marpaESLIFLua_luaL_getmetafield(int *rcp, lua_State *L, int obj, const char *e)
/****************************************************************************/
{
  return ! luaunpanicL_getmetafield(rcp, L, obj, e);
}

/****************************************************************************/
static short marpaESLIFLua_luaL_checktype(lua_State *L, int arg, int t)
/****************************************************************************/
{
  return ! luaunpanicL_checktype(L, arg, t);
}

/****************************************************************************/
static short marpaESLIFLua_lua_topointer(const void **rcpp, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_topointer(rcpp, L, idx);
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawlen(size_t *rcp, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_rawlen(rcp, L, idx);
}

/****************************************************************************/
static short marpaESLIFLua_luaL_dostring(int *rcp, lua_State *L, const char *fn)
/****************************************************************************/
{
  return ! luaunpanicL_dostring(rcp, L, fn);
}

/****************************************************************************/
static short marpaESLIFLua_luaL_loadstring(int *rcp, lua_State *L, const char *fn)
/****************************************************************************/
{
  return ! luaunpanicL_loadstring(rcp, L, fn);
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushglobaltable(lua_State *L)
/****************************************************************************/
{
  return ! luaunpanic_pushglobaltable(L);
}

/****************************************************************************/
static short marpaESLIFLua_lua_settable(lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_settable(L, idx);
}

/****************************************************************************/
static short marpaESLIFLua_lua_gettable(int *rcp, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_gettable(rcp, L, idx);
}

/****************************************************************************/
static short _marpaESLIFValue_lua_representationb(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp, char **encodingasciisp)
/****************************************************************************/
{
  static const char                *funcs = "_marpaESLIFValue_lua_representationb";
  /* Internal function: we force userDatavp to be marpaESLIFValuep */
  marpaESLIFValue_t                *marpaESLIFValuep = (marpaESLIFValue_t *) userDatavp;
  marpaESLIFRecognizer_t           *marpaESLIFRecognizerp = marpaESLIFValuep->marpaESLIFRecognizerp;
  marpaESLIFLuaValueContext_t      *marpaESLIFLuaValueContextp;
  marpaESLIFRepresentation_t        representationCallbackp;
  int                               typei;
  short                             rcb;

  /* Create the lua state if needed */
  if (! _marpaESLIFValue_lua_newb(marpaESLIFValuep)) {
    goto err;
  }

  /* Remember that we pushed the "marpaESLIFValue" global ? */
  LUA_GETGLOBAL(&typei, marpaESLIFValuep, "marpaESLIFValue");                    /* stack: ..., marpaESLIFValueTable */
  if (typei != LUA_TTABLE) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Lua marpaESLIFValue global is not a table");
    goto err; /* Lua will shutdown anyway */
  }
  /* And this marpaESLIFValue is a table with a key "marpaESLIFValueContextp" */
  LUA_GETFIELDI(&typei, marpaESLIFValuep, -1, "marpaESLIFLuaValueContextp");     /* stack: ..., marpaESLIFValueTable, marpaESLIFLuaValueContextp */
  if (typei != LUA_TLIGHTUSERDATA) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Lua marpaESLIFLuaValueContextp is not a light userdata");
    goto err; /* Lua will shutdown anyway */
  }
  LUA_TOUSERDATA(marpaESLIFValuep, &marpaESLIFLuaValueContextp, -1);
  LUA_POP(marpaESLIFValuep, 2);                                                  /* stack: ... */

  /* Proxy to the lua representation callback action - then userDatavp has to be marpaESLIFLuaValueContextp */
  representationCallbackp = marpaESLIFLua_representationb;

  rcb = representationCallbackp((void *) marpaESLIFLuaValueContextp /* userDatavp */, marpaESLIFValueResultp, inputcpp, inputlp, encodingasciisp);
  if (! rcb) goto err;

  goto done;

 err:
  LOG_LATEST_ERROR(marpaESLIFValuep);
  rcb = 0;

 done:
  return rcb;
}

