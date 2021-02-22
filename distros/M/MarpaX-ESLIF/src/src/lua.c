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

#define MARPAESLIFLUA_LOG_PANIC_STRING(containerp, f) do {              \
    char *panicstring;							\
    if (luaunpanic_panicstring(&panicstring, containerp->L)) {          \
      MARPAESLIF_ERRORF(containerp->marpaESLIFp, "%s panic", #f);       \
    } else {								\
      MARPAESLIF_ERRORF(containerp->marpaESLIFp, "%s panic: %s", #f, panicstring); \
    }									\
  } while (0)

#define MARPAESLIFLUA_LOG_ERROR_STRING(containerp, f) do {              \
    const char *errorstring;                                            \
    if (luaunpanic_tostring(&errorstring, containerp->L, -1)) {         \
      MARPAESLIFLUA_LOG_PANIC_STRING(containerp, luaunpanic_tostring);  \
      MARPAESLIF_ERRORF(containerp->marpaESLIFp, "%s failure", #f);     \
    } else {                                                            \
      if (errorstring == NULL) {                                        \
        MARPAESLIF_ERRORF(containerp->marpaESLIFp, "%s failure", #f);   \
      } else {								\
        MARPAESLIF_ERRORF(containerp->marpaESLIFp, "%s failure: %s", #f, errorstring); \
      }									\
    }                                                                   \
  } while (0)

#define MARPAESLIFLUA_LOG_LATEST_ERROR(containerp) do {                 \
    const char *errorstring;                                            \
    if (luaunpanic_tostring(&errorstring, containerp->L, -1)) {         \
      MARPAESLIFLUA_LOG_PANIC_STRING(containerp, luaunpanic_tostring);  \
      MARPAESLIF_ERRORF(containerp->marpaESLIFp, "%s failure", "luaunpanic_tostring"); \
    } else {                                                            \
      if (errorstring != NULL) {                                        \
        MARPAESLIF_ERROR(containerp->marpaESLIFp, errorstring);         \
      }									\
    }                                                                   \
  } while (0)

#define LUAL_CHECKVERSION(containerp) do {                              \
    if (MARPAESLIF_UNLIKELY(luaunpanicL_checkversion(containerp->L))) { \
      MARPAESLIFLUA_LOG_PANIC_STRING(containerp, luaL_checkversion);    \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUAL_OPENLIBS(containerp) do {                                 \
    if (MARPAESLIF_UNLIKELY(luaunpanicL_openlibs(containerp->L))) {    \
      MARPAESLIFLUA_LOG_PANIC_STRING(containerp, luaL_openlibs);       \
      errno = ENOSYS;                                                  \
      goto err;                                                        \
    }                                                                  \
  } while (0)

#define LUA_DUMP(containerp, writer, data, strip) do {                  \
    int _rci = -1;                                                      \
    if (MARPAESLIF_UNLIKELY(luaunpanic_dump(&_rci, containerp->L, writer, data, strip))) { \
      MARPAESLIFLUA_LOG_PANIC_STRING(containerp, lua_dump);             \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    if (MARPAESLIF_UNLIKELY(_rci != 0)) {                               \
      MARPAESLIFLUA_LOG_ERROR_STRING(containerp, lua_dump);             \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUA_GETFIELDI(rcp, containerp, idx, k) do {                     \
    if (MARPAESLIF_UNLIKELY(luaunpanic_getfield(rcp, containerp->L, idx, k))) { \
      MARPAESLIFLUA_LOG_PANIC_STRING(containerp, lua_getfield);         \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUA_GETGLOBAL(rcp, containerp, name) do {                       \
    if (MARPAESLIF_UNLIKELY(luaunpanic_getglobal(rcp, containerp->L, name))) { \
      MARPAESLIFLUA_LOG_PANIC_STRING(containerp, lua_getglobal);        \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUA_SETGLOBAL(containerp, name) do {                            \
    if (MARPAESLIF_UNLIKELY(luaunpanic_setglobal(containerp->L, name))) { \
      MARPAESLIFLUA_LOG_PANIC_STRING(containerp, lua_setglobal);        \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUAL_LOADBUFFER(containerp, s, sz, n) do {                      \
    int _rci = -1;                                                      \
    if (MARPAESLIF_UNLIKELY(luaunpanicL_loadbuffer(&_rci, containerp->L, s, sz, n))) { \
      MARPAESLIFLUA_LOG_PANIC_STRING(containerp, luaL_loadbuffer);      \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    if (MARPAESLIF_UNLIKELY(_rci != 0)) {                               \
      MARPAESLIFLUA_LOG_ERROR_STRING(containerp, luaL_loadbuffer);      \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUAL_CHECKSTACK(containerp, extra, msg) do {                    \
    if (MARPAESLIF_UNLIKELY(luaunpanicL_checkstack(containerp->L, extra, msg))) { \
      MARPAESLIFLUA_LOG_PANIC_STRING(containerp, luaL_checkstack);      \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUA_SETTOP(containerp, idx) do {                             \
    if (MARPAESLIF_UNLIKELY(luaunpanic_settop(containerp->L, idx))) {   \
      MARPAESLIFLUA_LOG_PANIC_STRING(containerp, lua_settop);        \
      errno = ENOSYS;                                                \
      goto err;                                                      \
    }                                                                \
  } while (0)

#define LUA_TOUSERDATA(containerp, rcpp, idx) do {                    \
    if (MARPAESLIF_UNLIKELY(luaunpanic_touserdata((void **) rcpp, containerp->L, idx))) { \
      MARPAESLIFLUA_LOG_PANIC_STRING(containerp, lua_touserdata);     \
      errno = ENOSYS;                                                 \
      goto err;                                                       \
    }                                                                 \
  } while (0)

#define LUAL_REQUIREF(containerp, modname, openf, glb) do {             \
    if (MARPAESLIF_UNLIKELY(luaunpanicL_requiref(containerp->L, modname, openf, glb))) { \
      MARPAESLIFLUA_LOG_PANIC_STRING(containerp, lual_requiref);        \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
  } while (0)

#define LUA_POP(containerp, n) do {                             \
    if (MARPAESLIF_UNLIKELY(luaunpanic_pop(containerp->L, n))) {        \
      MARPAESLIFLUA_LOG_PANIC_STRING(containerp, lua_pop);      \
      errno = ENOSYS;                                           \
      goto err;                                                 \
    }                                                           \
  } while (0)

#define LUA_PCALL(containerp, n, r, f) do {                             \
    int _rci;                                                           \
    if (MARPAESLIF_UNLIKELY(luaunpanic_pcall(&_rci, containerp->L, n, r, f))) { \
      MARPAESLIFLUA_LOG_PANIC_STRING(containerp, lua_pcall);            \
      errno = ENOSYS;                                                   \
      goto err;                                                         \
    }                                                                   \
    if (MARPAESLIF_UNLIKELY(_rci != 0)) {                               \
      MARPAESLIFLUA_LOG_ERROR_STRING(containerp, lua_pcall);            \
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
  short rcb;

  if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_lua_newb(marpaESLIFValuep->marpaESLIFRecognizerp))) {
    goto err;
  }

  /* Get a shallow copy */
  marpaESLIFValuep->L = marpaESLIFValuep->marpaESLIFRecognizerp->L;

  /* Inject current valuator */
  if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_marpaESLIFValue_newFromUnmanagedi(marpaESLIFValuep->L, marpaESLIFValuep))) goto err;         /* stack: marpaESLIFValue */
  LUA_SETGLOBAL(marpaESLIFValuep, "marpaESLIFValue");                                                                                  /* stack: */

  rcb = 1;
  goto done;

 err:
  _marpaESLIFValue_lua_freev(marpaESLIFValuep);
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
  marpaESLIFGrammar_t    *marpaESLIFGrammarp;
  marpaESLIFRecognizer_t *marpaESLIFRecognizerTopp;
  short                   rcb;

  /* Lua state is owned by the top-level recognizer */
  marpaESLIFRecognizerTopp = marpaESLIFRecognizerp->marpaESLIFRecognizerTopp;

  if (marpaESLIFRecognizerTopp->L != NULL) {
    /* lua_State already created: get a shallow copy */
    marpaESLIFRecognizerp->L = marpaESLIFRecognizerTopp->L;
    goto inject_current_recognizer;
  }

  marpaESLIFGrammarp = marpaESLIFRecognizerTopp->marpaESLIFGrammarp;

  /* Create Lua state */
  if (MARPAESLIF_UNLIKELY(luaunpanicL_newstate(&(marpaESLIFRecognizerTopp->L)))) {
    MARPAESLIF_ERROR(marpaESLIFRecognizerTopp->marpaESLIFp, "luaunpanicL_newstate failure");
    errno = ENOSYS;
    goto err;
  }
  if (MARPAESLIF_UNLIKELY(marpaESLIFRecognizerTopp->L == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFRecognizerTopp->marpaESLIFp, "luaunpanicL_success but lua_State is NULL");
    errno = ENOSYS;
    goto err;
  }

  /* Open all available libraries */
  LUAL_OPENLIBS(marpaESLIFRecognizerTopp);

  /* Check Lua version */
  LUAL_CHECKVERSION(marpaESLIFRecognizerTopp);

  /* Load the marpaESLIFLua library built-in */
  LUAL_REQUIREF(marpaESLIFRecognizerTopp, "marpaESLIFLua", marpaESLIFLua_installi, 1);

  /* Inject global variables */
  if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_marpaESLIF_newFromUnmanagedi(marpaESLIFRecognizerTopp->L, marpaESLIFRecognizerTopp->marpaESLIFp))) goto err; /* stack: marpaESLIFLua, marpaESLIF */
  LUA_SETGLOBAL(marpaESLIFRecognizerTopp, "marpaESLIF");                                                                                  /* stack: marpaESLIFLua */

  if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_marpaESLIFGrammar_newFromUnmanagedi(marpaESLIFRecognizerTopp->L, marpaESLIFRecognizerTopp->marpaESLIFGrammarp))) goto err; /* stack: marpaESLIFLua, marpaESLIFGrammar */
  LUA_SETGLOBAL(marpaESLIFRecognizerTopp, "marpaESLIFGrammar");                                                                           /* stack: marpaESLIFLua */

  LUA_POP(marpaESLIFRecognizerTopp, 1);                                                                                                   /* stack: */

  /* We load byte code generated during grammar validation */
  if ((marpaESLIFGrammarp->luabytep != NULL) && (marpaESLIFGrammarp->luabytel > 0)) {
    LUAL_LOADBUFFER(marpaESLIFRecognizerTopp, marpaESLIFGrammarp->luaprecompiledp, marpaESLIFGrammarp->luaprecompiledl, "=<luaScript/>");
    LUA_PCALL(marpaESLIFRecognizerTopp, 0, LUA_MULTRET, 0);
    /* Clear the stack */
    LUA_SETTOP(marpaESLIFRecognizerTopp, 0);
  }

  /* Top level recognizer owns lua state, and we do not */
  marpaESLIFRecognizerp->L  = marpaESLIFRecognizerTopp->L;

 inject_current_recognizer:
  if (MARPAESLIF_UNLIKELY(! marpaESLIFLua_marpaESLIFRecognizer_newFromUnmanagedi(marpaESLIFRecognizerp->L, marpaESLIFRecognizerp))) goto err;               /* stack: marpaESLIFRecognizer */
  LUA_SETGLOBAL(marpaESLIFRecognizerp, "marpaESLIFRecognizer");                                                                        /* stack: */

  rcb = 1;
  goto done;

 err:
  _marpaESLIFRecognizer_lua_freev(marpaESLIFRecognizerp);
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static void _marpaESLIFValue_lua_freev(marpaESLIFValue_t *marpaESLIFValuep)
/*****************************************************************************/
{
  /* It is virtual: L is always owned by the top-level recognizer */
  marpaESLIFValuep->L = NULL;
}

/*****************************************************************************/
static void _marpaESLIFRecognizer_lua_freev(marpaESLIFRecognizer_t *marpaESLIFRecognizerp)
/*****************************************************************************/
{
  if (marpaESLIFRecognizerp->L != NULL) {
    /* It is owned by the top-level recognizer */
    if (marpaESLIFRecognizerp == marpaESLIFRecognizerp->marpaESLIFRecognizerTopp) {
      if (luaunpanic_close(marpaESLIFRecognizerp->L)) {
        MARPAESLIFLUA_LOG_PANIC_STRING(marpaESLIFRecognizerp, luaunpanic_close);
      }
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
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFValue_lua_newb(marpaESLIFValuep))) {
    goto err;
  }

  ruleCallbackp = marpaESLIFLua_valueRuleActionResolver(userDatavp, marpaESLIFValuep, marpaESLIFValuep->actions);
  if (MARPAESLIF_UNLIKELY(ruleCallbackp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Lua bindings returned no rule callback");
    goto err; /* Lua will shutdown anyway */
  }

  rcb = ruleCallbackp(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb);

  if (MARPAESLIF_UNLIKELY(! rcb)) goto err;

  goto done;

 err:
  MARPAESLIFLUA_LOG_LATEST_ERROR(marpaESLIFValuep);
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
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFValue_lua_newb(marpaESLIFValuep))) {
    goto err;
  }

  symbolCallbackp = marpaESLIFLua_valueSymbolActionResolver(userDatavp, marpaESLIFValuep, marpaESLIFValuep->actions);
  if (MARPAESLIF_UNLIKELY(symbolCallbackp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Lua bindings returned no symbol callback");
    goto err; /* Lua will shutdown anyway */
  }

  rcb = symbolCallbackp(userDatavp, marpaESLIFValuep, marpaESLIFValueResultp, resulti);

  if (MARPAESLIF_UNLIKELY(! rcb)) goto err;

  goto done;

 err:
  MARPAESLIFLUA_LOG_LATEST_ERROR(marpaESLIFValuep);
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
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_lua_newb(marpaESLIFRecognizerp))) {
    goto err;
  }

  ifCallbackp = marpaESLIFLua_recognizerIfActionResolver(userDatavp, marpaESLIFRecognizerp, marpaESLIFRecognizerp->ifactions);
  if (MARPAESLIF_UNLIKELY(ifCallbackp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFRecognizerp->marpaESLIFp, "Lua bindings returned no if-action callback");
    goto err; /* Lua will shutdown anyway */
  }

  rcb = ifCallbackp(userDatavp, marpaESLIFRecognizerp, marpaESLIFValueResultp, marpaESLIFValueResultBoolp);

  if (MARPAESLIF_UNLIKELY(! rcb)) goto err;

  goto done;

 err:
  MARPAESLIFLUA_LOG_LATEST_ERROR(marpaESLIFRecognizerp);
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFRecognizer_lua_regexactionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFCalloutBlockp, marpaESLIFValueResultInt_t *marpaESLIFValueResultOutp)
/*****************************************************************************/
{
  static const char                   *funcs = "_marpaESLIFRecognizer_lua_regexactionb";
  marpaESLIFRecognizerRegexCallback_t  regexCallbackp;
  short                                rcb;

  /* Create the lua state if needed */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_lua_newb(marpaESLIFRecognizerp))) {
    goto err;
  }

  regexCallbackp = marpaESLIFLua_recognizerRegexActionResolver(userDatavp, marpaESLIFRecognizerp, marpaESLIFRecognizerp->regexactions);
  if (MARPAESLIF_UNLIKELY(regexCallbackp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFRecognizerp->marpaESLIFp, "Lua bindings returned no regex-action callback");
    goto err; /* Lua will shutdown anyway */
  }

  rcb = regexCallbackp(userDatavp, marpaESLIFRecognizerp, marpaESLIFCalloutBlockp, marpaESLIFValueResultOutp);

  if (MARPAESLIF_UNLIKELY(! rcb)) goto err;

  goto done;

 err:
  MARPAESLIFLUA_LOG_LATEST_ERROR(marpaESLIFRecognizerp);
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
    if (MARPAESLIF_UNLIKELY(luaunpanicL_newstate(&(containerp->L)))) {
      MARPAESLIF_ERROR(marpaESLIFGrammarp->marpaESLIFp, "luaunpanicL_newstate failure");
      errno = ENOSYS;
      goto err;
    }
    if (MARPAESLIF_UNLIKELY(containerp->L == NULL)) {
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
      MARPAESLIFLUA_LOG_PANIC_STRING(containerp, luaunpanic_close);
    }
    containerp->L = NULL;
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
      if (MARPAESLIF_UNLIKELY(marpaESLIFGrammarp->luaprecompiledp == NULL)) {
        MARPAESLIF_ERRORF(marpaESLIFGrammarp->marpaESLIFp, "malloc failure, %s", strerror(errno));
        goto err;
      }
      q = marpaESLIFGrammarp->luaprecompiledp;
    } else {
      q = (char *) realloc(marpaESLIFGrammarp->luaprecompiledp, marpaESLIFGrammarp->luaprecompiledl + sz);
      if (MARPAESLIF_UNLIKELY(q == NULL)) {
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
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_pushinteger(L, n));
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
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_getglobal(luaip, L, name));
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
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_newtable(L));
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushcfunction(lua_State *L, lua_CFunction f)
/****************************************************************************/
{
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_pushcfunction(L, f));
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
  return ((index <= 0) || marpaESLIFLua_luaL_checkstack(L, index, "Cannot grow stack")) && (! luaunpanic_insert(L, index));
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawgeti(int *luaip, lua_State *L, int index, lua_Integer n)
/****************************************************************************/
{
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_rawgeti(luaip, L, index, n));
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawget(int *luaip, lua_State *L, int index)
/****************************************************************************/
{
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_rawget(luaip, L, index));
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawgetp(int *luaip, lua_State *L, int index, const void *p)
/****************************************************************************/
{
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_rawgetp(luaip, L, index, p));
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
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_createtable(L, narr, nrec));
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
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_pushstring(luasp, L, s));
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushlstring(const char **luasp, lua_State *L, const char *s, size_t len)
/****************************************************************************/
{
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_pushlstring(luasp, L, s, len));
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushnil(lua_State *L)
/****************************************************************************/
{
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_pushnil(L));
}

/****************************************************************************/
static short marpaESLIFLua_luaL_checkstack(lua_State *L, int extra, const char *msg)
/****************************************************************************/
{
  return ! luaunpanicL_checkstack(L, extra, msg);
}

/****************************************************************************/
static short marpaESLIFLua_lua_getfield(int *luaip, lua_State *L, int index, const char *k)
/****************************************************************************/
{
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_getfield(luaip, L, index, k));
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
  return (index <= 0 || marpaESLIFLua_luaL_checkstack(L, index, "Cannot grow stack")) && (! luaunpanic_settop(L, index));
}

/****************************************************************************/
static short marpaESLIFLua_lua_copy(lua_State *L, int fromidx, int toidx)
/****************************************************************************/
{
  return (toidx <= 0 || marpaESLIFLua_luaL_checkstack(L, toidx, "Cannot grow stack")) && (! luaunpanic_copy(L, fromidx, toidx));
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
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_pushboolean(L, b));
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushnumber(lua_State *L, lua_Number n)
/****************************************************************************/
{
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_pushnumber(L, n));
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushlightuserdata(lua_State *L, void *p)
/****************************************************************************/
{
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_pushlightuserdata(L, p));
}

/****************************************************************************/
static short marpaESLIFLua_lua_newuserdata(void **rcpp, lua_State *L, size_t sz)
/****************************************************************************/
{
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_newuserdata(rcpp, L, sz));
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushvalue(lua_State *L, int index)
/****************************************************************************/
{
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_pushvalue(L, index));
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
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanicL_requiref(L, modname, openf, glb));
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
  return marpaESLIFLua_luaL_checkstack(L, 2, "Cannot grow stack by 2") && (! luaunpanic_next(rcip, L, idx));
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
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_getmetatable(rcip, L, index));
}

/****************************************************************************/
static short marpaESLIFLua_luaL_callmeta(int *rcip, lua_State *L, int obj, const char *e)
/****************************************************************************/
{
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanicL_callmeta(rcip, L, obj, e));
}

/****************************************************************************/
static short marpaESLIFLua_luaL_getmetafield(int *rcip, lua_State *L, int obj, const char *e)
/****************************************************************************/
{
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanicL_getmetafield(rcip, L, obj, e));
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
static short marpaESLIFLua_luaL_dostring(int *rcip, lua_State *L, const char *fn)
/****************************************************************************/
{
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanicL_dostring(rcip, L, fn));
}

/****************************************************************************/
static short marpaESLIFLua_luaL_loadstring(int *rcip, lua_State *L, const char *fn)
/****************************************************************************/
{
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanicL_loadstring(rcip, L, fn));
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushglobaltable(lua_State *L)
/****************************************************************************/
{
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_pushglobaltable(L));
}

/****************************************************************************/
static short marpaESLIFLua_lua_settable(lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_settable(L, idx);
}

/****************************************************************************/
static short marpaESLIFLua_lua_gettable(int *rcip, lua_State *L, int idx)
/****************************************************************************/
{
  return marpaESLIFLua_luaL_checkstack(L, 1, "Cannot grow stack by 1") && (! luaunpanic_gettable(rcip, L, idx));
}

/****************************************************************************/
static short marpaESLIFLua_lua_isinteger(int *rcip, lua_State *L, int idx)
/****************************************************************************/
{
  return ! luaunpanic_isinteger(rcip, L, idx);
}

/****************************************************************************/
static short _marpaESLIFValue_lua_representationb(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp, char **encodingasciisp, marpaESLIFRepresentationDispose_t *disposeCallbackpp)
/****************************************************************************/
{
  static const char                *funcs = "_marpaESLIFValue_lua_representationb";
  /* Internal function: we force userDatavp to be marpaESLIFValuep */
  marpaESLIFValue_t                *marpaESLIFValuep = (marpaESLIFValue_t *) userDatavp;
  marpaESLIFRecognizer_t           *marpaESLIFRecognizerp = marpaESLIFValuep->marpaESLIFRecognizerp;
  marpaESLIFLuaValueContext_t      *marpaESLIFLuaValueContextp;
  int                               typei;
  short                             rcb;

  /* Create the lua state if needed */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFValue_lua_newb(marpaESLIFValuep))) {
    goto err;
  }

  /* Remember that we pushed the "marpaESLIFValue" global ? */
  LUA_GETGLOBAL(&typei, marpaESLIFValuep, "marpaESLIFValue");                    /* stack: ..., marpaESLIFValueTable */
  if (MARPAESLIF_UNLIKELY(typei != LUA_TTABLE)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Lua marpaESLIFValue global is not a table");
    goto err; /* Lua will shutdown anyway */
  }
  /* And this marpaESLIFValue is a table with a key "marpaESLIFValueContextp" */
  LUA_GETFIELDI(&typei, marpaESLIFValuep, -1, "marpaESLIFLuaValueContextp");     /* stack: ..., marpaESLIFValueTable, marpaESLIFLuaValueContextp */
  if (MARPAESLIF_UNLIKELY(typei != LUA_TLIGHTUSERDATA)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Lua marpaESLIFLuaValueContextp is not a light userdata");
    goto err; /* Lua will shutdown anyway */
  }
  LUA_TOUSERDATA(marpaESLIFValuep, &marpaESLIFLuaValueContextp, -1);
  LUA_POP(marpaESLIFValuep, 2);                                                  /* stack: ... */

  /* Proxy to the lua representation callback action - then userDatavp has to be marpaESLIFLuaValueContextp */
  rcb = marpaESLIFLua_representationb((void *) marpaESLIFLuaValueContextp /* userDatavp */, marpaESLIFValueResultp, inputcpp, inputlp, encodingasciisp, disposeCallbackpp);
  if (MARPAESLIF_UNLIKELY(! rcb)) goto err;

  goto done;

 err:
  MARPAESLIFLUA_LOG_LATEST_ERROR(marpaESLIFValuep);
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIFRecognizer_lua_eventactionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFEvent_t *eventArrayp, size_t eventArrayl, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp)
/*****************************************************************************/
{
  static const char                   *funcs = "_marpaESLIFRecognizer_lua_eventactionb";
  marpaESLIFRecognizerEventCallback_t  eventCallbackp;
  short                                rcb;

  /* Create the lua state if needed */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_lua_newb(marpaESLIFRecognizerp))) {
    goto err;
  }

  eventCallbackp = marpaESLIFLua_recognizerEventActionResolver(userDatavp, marpaESLIFRecognizerp, marpaESLIFRecognizerp->eventactions);
  if (MARPAESLIF_UNLIKELY(eventCallbackp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFRecognizerp->marpaESLIFp, "Lua bindings returned no event-action callback");
    goto err; /* Lua will shutdown anyway */
  }

  rcb = eventCallbackp(userDatavp, marpaESLIFRecognizerp, eventArrayp, eventArrayl, marpaESLIFValueResultBoolp);

  if (MARPAESLIF_UNLIKELY(! rcb)) goto err;

  goto done;

 err:
  MARPAESLIFLUA_LOG_LATEST_ERROR(marpaESLIFRecognizerp);
  rcb = 0;

 done:
  return rcb;
}

