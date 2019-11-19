/* Only 5.2 and upwards is supported */

#include "lua.h"        /* As per CMake doc */
#include "lauxlib.h"    /* As per CMake doc */
#include "lualib.h"     /* As per CMake doc */
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <limits.h>
#include <float.h>
#include <marpaESLIFLua.h>
#include <marpaESLIF.h>
#include <genericStack.h>
#include "lua_newkeywords.c"
#include "lua_niledtable.c"

/* Shall this module determine automatically string encoding ? */
/* #define MARPAESLIFLUA_AUTO_ENCODING_DETECT */

/* Global table for the multiton pattern */
#define MARPAESLIFMULTITONSTABLE "__marpaESLIFLuaMultitonsTable"
/* Every key   is a marpaESLIFLuaContext light userdata */
/* Every value is a reference to the logger (reference to nil if there is none) */

/* Global table for the string-to-encoding */
#define MARPAESLIFSTRINGTOENCODINGTABLE "__marpaESLIFLuaStringToEncodingTable"
/* Every key   is a string (the original string) */
/* Every value is a string (the encoding) */

/* marpaESLIFLua correctly unreferences everything from the valuation, but it you */
/* prefer it not to use the global registry, then uncomment the next line -; */
/* #define MARPAESLIFLUA_USE_INTERNALREGISTRYINDEX */

/* Special "canarray" metatable flag name */
#define MARPAESLIF_CANARRAY "canarray"

/* Special "opaque" metatable flag name */
#define MARPAESLIF_OPAQUE "opaque"

#ifdef MARPAESLIFLUA_USE_INTERNALREGISTRYINDEX
/* Global table for our references */
#define MARPAESLIFLUAREGISTRYINDEX "__marpaESLIFLuaRegistryindex"
#endif

#ifndef MARPAESLIFLUA_CONTEXT
static char _MARPAESLIFLUA_CONTEXT;
#define MARPAESLIFLUA_CONTEXT &_MARPAESLIFLUA_CONTEXT
#endif

/* ESLIF proxy context */
/* This one is special because it is returned by marpaESLIFLua_marpaESLIF_new(?From)?i and         */
/* marpaESLIFLua_marpaESLIF_newFromUnmanagedi.                                                     */
/* In the first case, it is guaranteed that we own it and it is also stored in the multiton table. */
/* In the second case, we never own it and it is never stored in the multiton table.               */
/* We know the destroy workflows because there are two different entry points:                     */
/* - marpaESLIFLua_marpaESLIFMultitonsTable_freei                                                  */
/* - marpaESLIFLua_marpaESLIF_freei                                                                */
typedef struct marpaESLIFLuaContext {
  marpaESLIF_t *marpaESLIFp;
  short         multitonb;
} marpaESLIFLuaContext_t;

/* Logger proxy context */
typedef struct marpaESLIFLuaGenericLoggerContext {
  lua_State *L; /* Lua state */
  int logger_r; /* Lua logger reference */
} marpaESLIFLuaGenericLoggerContext_t;

/* Grammar proxy context */
typedef struct marpaESLIFLuaGrammarContext {
  lua_State              *L;                      /* Lua state */
  int                     eslif_r;                /* Lua eslif reference */
  marpaESLIFGrammar_t    *marpaESLIFGrammarp;
  short                   managedb;               /* True if we own marpaESLIFGrammarp */
  marpaESLIF_t           *marpaESLIFp;
} marpaESLIFLuaGrammarContext_t;

/* Recognizer proxy context */
typedef struct marpaESLIFLuaRecognizerContext {
  lua_State              *L;                      /* Lua state */
  int                     grammar_r;              /* Lua grammar reference */
  int                     recognizerInterface_r;  /* Lua recognizer interface reference */
  int                     recognizer_orig_r;      /* Lua original recognizer reference in case of newFrom() */
  char                   *actions;                /* Shallow copy of last resolved name */
  char                   *previousInputs;         /* Because we want to maintain lifetime of inputs lua string outside of stack */
  char                   *previousEncodings;      /* Because we want to maintain lifetime of encodings lua string outside of stack */
  marpaESLIFRecognizer_t *marpaESLIFRecognizerp;
  short                   managedb;               /* True if we own marpaESLIFRecognizerp */
  marpaESLIF_t           *marpaESLIFp;
} marpaESLIFLuaRecognizerContext_t;

/* Value proxy context */
typedef struct marpaESLIFLuaValueContext {
  lua_State         *L;                     /* Lua state */
  int                valueInterface_r;      /* Lua value reference */
  int                recognizerInterface_r; /* Lua recognizer reference - can be LUA_NOREF */
  int                grammar_r;             /* Lua grammar reference - can be LUA_NOREF */
  char              *actions;               /* Shallow copy of last resolved name */
  char              *previous_strings;      /* Latest stringification result */
  char              *previous_encodings;    /* Latest stringification encoding result */
  marpaESLIFValue_t *marpaESLIFValuep;
  short              managedb;              /* True if we own marpaESLIFValuep */
  char              *symbols;
  int                symboli;
  char              *rules;
  int                rulei;
  marpaESLIF_t      *marpaESLIFp;
} marpaESLIFLuaValueContext_t;

/* Global table for the duplicated marpaESLIFValueResult's during import */
#define MARPAESLIFOPAQUETABLE "__marpaESLIFLuaOpaqueTable"

static void                               marpaESLIFLua_stackdumpv(lua_State* L, int forcelookupi);
static void                               marpaESLIFLua_tabledumpv(lua_State *L, const char *texts, int indicei, unsigned int identi);
static void                               marpaESLIFLua_tabledump_usingpairsv(lua_State *L, const char *texts, int indicei, unsigned int identi);
static short                              marpaESLIFLua_paramIsLoggerInterfaceOrNilb(lua_State *L, int stacki);
static short                              marpaESLIFLua_paramIsRecognizerInterfacev(lua_State *L, int stacki);
static short                              marpaESLIFLua_paramIsValueInterfacev(lua_State *L, int stacki);
static short                              marpaESLIFLua_contextInitb(lua_State *L, marpaESLIFLuaContext_t *marpaESLIFLuaContextp, short unmanagedb);
static void                               marpaESLIFLua_contextFreev(marpaESLIFLuaContext_t *marpaESLIFLuaContextp, short multitonDestroyModeb);
static short                              marpaESLIFLua_grammarContextInitb(lua_State *L, marpaESLIF_t *marpaESLIFp, int eslifStacki, marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp, short unmanagedb);
static short                              marpaESLIFLua_recognizerContextInitb(lua_State *L, marpaESLIF_t *marpaESLIFp, int grammarStacki, int recognizerInterfaceStacki, int recognizerOrigStacki, marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp, short unmanagedb);
static short                              marpaESLIFLua_valueContextInitb(lua_State *L, marpaESLIF_t *marpaESLIFp, int grammarStacki, int recognizerStacki, int valueInterfaceStacki, marpaESLIFLuaValueContext_t    *marpaESLIFLuaValueContextp, short unmanagedb, short grammarStackiCanBeZerob);
static void                               marpaESLIFLua_grammarContextFreev(marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp, short onStackb);
static void                               marpaESLIFLua_recognizerContextCleanupv(marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp);
static void                               marpaESLIFLua_recognizerContextFreev(marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp, short onStackb);
static void                               marpaESLIFLua_valueContextCleanupv(marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp);
static void                               marpaESLIFLua_valueContextFreev(marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp, short onStackb);
static void                               marpaESLIFLua_genericLoggerCallbackv(void *userDatavp, genericLoggerLevel_t logLeveli, const char *msgs);
static int                                marpaESLIFLua_installi(lua_State *L);
static int                                marpaESLIFLua_versioni(lua_State *L);
static int                                marpaESLIFLua_versionMajori(lua_State *L);
static int                                marpaESLIFLua_versionMinori(lua_State *L);
static int                                marpaESLIFLua_versionPatchi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIF_newi(lua_State *L);
static int                                marpaESLIFLua_string_encodingi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIF_freei(lua_State *L);
static int                                marpaESLIFLua_marpaESLIF_versioni(lua_State *L);
static int                                marpaESLIFLua_marpaESLIF_versionMajori(lua_State *L);
static int                                marpaESLIFLua_marpaESLIF_versionMinori(lua_State *L);
static int                                marpaESLIFLua_marpaESLIF_versionPatchi(lua_State *L);
#ifdef MARPAESLIFLUA_EMBEDDED
static int                                marpaESLIFLua_marpaESLIF_newFromUnmanagedi(lua_State *L, marpaESLIF_t *marpaESLIFUnmanagedp);
#endif
static int                                marpaESLIFLua_marpaESLIFMultitonsTable_freei(lua_State *L);
#ifdef MARPAESLIFLUA_USE_INTERNALREGISTRYINDEX
static int                                marpaESLIFLua_marpaESLIFRegistryindex_freei(lua_State *L);
#endif
static int                                marpaESLIFLua_marpaESLIFGrammar_newi(lua_State *L);
#ifdef MARPAESLIFLUA_EMBEDDED
static int                                marpaESLIFLua_marpaESLIFGrammar_newFromUnmanagedi(lua_State *L, marpaESLIFGrammar_t *marpaESLIFGrammarUnmanagedp);
#endif
static int                                marpaESLIFLua_marpaESLIFGrammar_freei(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_ngrammari(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_currentLeveli(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_currentDescriptioni(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_descriptionByLeveli(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_currentRuleIdsi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_ruleIdsByLeveli(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_currentSymbolIdsi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_symbolIdsByLeveli(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_currentPropertiesi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_propertiesByLeveli(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_currentRulePropertiesi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_rulePropertiesByLeveli(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_currentSymbolPropertiesi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_symbolPropertiesByLeveli(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_ruleDisplayi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_symbolDisplayi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_ruleShowi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_ruleDisplayByLeveli(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_symbolDisplayByLeveli(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_ruleShowByLeveli(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_showi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_showByLeveli(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFGrammar_parsei(lua_State *L);
static short                              marpaESLIFLua_readerCallbackb(void *userDatavp, char **inputcpp, size_t *inputlp, short *eofbp, short *characterStreambp, char **encodingsp, size_t *encodinglp);
static marpaESLIFValueRuleCallback_t      marpaESLIFLua_valueRuleActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions);
static marpaESLIFValueSymbolCallback_t    marpaESLIFLua_valueSymbolActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions);
static marpaESLIFRecognizerIfCallback_t   marpaESLIFLua_recognizerIfActionResolver(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *actions);
static short                              marpaESLIFLua_valueRuleCallbackb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static short                              marpaESLIFLua_valueSymbolCallbackb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFValueResult_t *marpaESLIFValueResultp, int resulti);
static short                              marpaESLIFLua_recognizerIfCallbackb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFValueResultLexemep, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp);
static short                              marpaESLIFLua_valueCallbackb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, marpaESLIFValueResult_t *marpaESLIFValueResultLexemep, int resulti, short nullableb, short symbolb);
static short                              marpaESLIFLua_ifCallbackb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFValueResultLexemep, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp);
static void                               marpaESLIFLua_valueFreeCallbackv(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFValueResult_t *marpaESLIFValueResultp);
static void                               marpaESLIFLua_recognizerFreeCallbackv(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFValueResultp);
static void                               marpaESLIFLua_genericFreeCallbackv(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp);
static short                              marpaESLIFLua_importb(marpaESLIFValue_t *marpaESLIFValuep, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp);
static short                              marpaESLIFLua_pushValueb(marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp, marpaESLIFValue_t *marpaESLIFValuep, int stackindicei, marpaESLIFValueResult_t *marpaESLIFValueResultLexemep);
static short                              marpaESLIFLua_pushRecognizerb(marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFValueResultLexemep);
static short                              marpaESLIFLua_representationb(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp, char **encodingsp);
static int                                marpaESLIFLua_marpaESLIFRecognizer_newi(lua_State *L);
#ifdef MARPAESLIFLUA_EMBEDDED
static int                                marpaESLIFLua_marpaESLIFRecognizer_newFromUnmanagedi(lua_State *L, marpaESLIFRecognizer_t *marpaESLIFRecognizerUnmanagedp);
#endif
static int                                marpaESLIFLua_marpaESLIFRecognizer_freei(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_newFromi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_set_exhausted_flagi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_sharei(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_isCanContinuei(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_isExhaustedi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_scani(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_resumei(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_eventsi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_eventOnOffi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_lexemeAlternativei(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_lexemeCompletei(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_lexemeReadi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_lexemeTryi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_discardTryi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_lexemeExpectedi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_lexemeLastPausei(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_lexemeLastTryi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_discardLastTryi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_discardLasti(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_isEofi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_readi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_inputi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_progressLogi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_lastCompletedOffseti(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_lastCompletedLengthi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_lastCompletedLocationi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_linei(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_columni(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_locationi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_hookDiscardi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFRecognizer_hookDiscardSwitchi(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFValue_newi(lua_State *L);
#ifdef MARPAESLIFLUA_EMBEDDED
static int                                marpaESLIFLua_marpaESLIFValue_newFromUnmanagedi(lua_State *L, marpaESLIFValue_t *marpaESLIFValueUnmanagedp);
#endif
static int                                marpaESLIFLua_marpaESLIFValue_freei(lua_State *L);
static int                                marpaESLIFLua_marpaESLIFValue_valuei(lua_State *L);
static short                              marpaESLIFLua_stack_setb(lua_State *L, marpaESLIF_t *marpaESLIFp, marpaESLIFValue_t *marpaESLIFValuep, int resulti, marpaESLIFValueResult_t *marpaESLIFValueResultOutputp);
static short                              marpaESLIFLua_table_canarray_getb(lua_State *L, int indicei, short *canarraybp);
static short                              marpaESLIFLua_table_opaque_getb(lua_State *L, int indicei, short *opaquebp);
static int                                marpaESLIFLua_nexti(lua_State *L);
static short                              marpaESLIFLua_pairsb(int *rcip, lua_State *L, int idx, int *iteratorip, int *statevariableip);
static int                                marpaESLIFLua_marpaESLIFOpaque_freei(lua_State *L);
static short                              marpaESLIFLua_metatypeb(int *luaip, lua_State *L, int index);
static short                              marpaESLIFLua_createniledtableb(lua_State *L, int narr, int nrec, short arrayb);
static short                              marpaESLIFLua_metanextb(int *rcip, lua_State *L, int idx);

#define MARPAESLIFLUA_NOOP

static short marpaESLIFLua_lua_pushinteger(lua_State *L, lua_Integer n);
static short marpaESLIFLua_lua_setglobal (lua_State *L, const char *name);
static short marpaESLIFLua_lua_getglobal (int *luaip, lua_State *L, const char *name);
static short marpaESLIFLua_lua_type(int *luaip, lua_State *L, int index);
static short marpaESLIFLua_lua_pop(lua_State *L, int n);
static short marpaESLIFLua_lua_newtable(lua_State *L);
static short marpaESLIFLua_lua_pushcfunction(lua_State *L, lua_CFunction f);
static short marpaESLIFLua_lua_setfield(lua_State *L, int index, const char *k);
static short marpaESLIFLua_lua_setmetatable(lua_State *L, int index);
static short marpaESLIFLua_lua_insert(lua_State *L, int index);
static short marpaESLIFLua_lua_rawgeti(int *luaip, lua_State *L, int index, lua_Integer n);
static short marpaESLIFLua_lua_rawget(int *luaip, lua_State *L, int index);
static short marpaESLIFLua_lua_rawgetp(int *luaip, lua_State *L, int index, const void *p);
static short marpaESLIFLua_lua_remove(lua_State *L, int index);
static short marpaESLIFLua_lua_createtable(lua_State *L, int narr, int nrec);
static short marpaESLIFLua_lua_rawseti(lua_State *L, int index, lua_Integer i);
static short marpaESLIFLua_lua_seti(lua_State *L, int index, lua_Integer i);
static short marpaESLIFLua_lua_pushstring(const char **luasp, lua_State *L, const char *s);
static short marpaESLIFLua_lua_pushlstring(const char **luasp, lua_State *L, const char *s, size_t len);
static short marpaESLIFLua_lua_pushnil(lua_State *L);
static short marpaESLIFLua_lua_getfield(int *luaip, lua_State *L, int index, const char *k);
static short marpaESLIFLua_lua_call(lua_State *L, int nargs, int nresults);
static short marpaESLIFLua_lua_settop(lua_State *L, int index);
static short marpaESLIFLua_lua_copy(lua_State *L, int fromidx, int toidx);
static short marpaESLIFLua_lua_rawsetp(lua_State *L, int index, const void *p);
static short marpaESLIFLua_lua_rawset(lua_State *L, int index);
static short marpaESLIFLua_lua_pushboolean(lua_State *L, int b);
static short marpaESLIFLua_lua_pushnumber(lua_State *L, lua_Number n);
static short marpaESLIFLua_lua_pushlightuserdata(lua_State *L, void *p);
static short marpaESLIFLua_lua_newuserdata(void **rcpp, lua_State *L, size_t sz);
static short marpaESLIFLua_lua_pushvalue(lua_State *L, int index);
static short marpaESLIFLua_luaL_ref(int *rcip, lua_State *L, int t);
static short marpaESLIFLua_luaL_unref(lua_State *L, int t, int ref);
#ifndef marpaESLIFLua_luaL_error
#define marpaESLIFLua_luaL_error(L, fmt, ...) luaL_error(L, fmt)
#endif
#ifndef marpaESLIFLua_luaL_errorf
#define marpaESLIFLua_luaL_errorf(L, fmt, ...) luaL_error(L, fmt, __VA_ARGS__)
#endif
static short marpaESLIFLua_luaL_requiref(lua_State *L, const char *modname, lua_CFunction openf, int glb);
static short marpaESLIFLua_lua_touserdata(void **rcpp, lua_State *L, int idx);
static short marpaESLIFLua_lua_tointeger(lua_Integer *rcip, lua_State *L, int idx);
static short marpaESLIFLua_lua_tointegerx(lua_Integer *rcip, lua_State *L, int idx, int *isnum);
static short marpaESLIFLua_lua_tonumber(lua_Number *rcdp, lua_State *L, int idx);
static short marpaESLIFLua_lua_tonumberx(lua_Number *rcdp, lua_State *L, int idx, int *isnum);
static short marpaESLIFLua_lua_toboolean(int *rcip, lua_State *L, int idx);
static short marpaESLIFLua_luaL_tolstring(const char **rcp, lua_State *L, int idx, size_t *len);
static short marpaESLIFLua_lua_tolstring(const char **rcpp, lua_State *L, int idx, size_t *len);
static short marpaESLIFLua_lua_tostring(const char **rcpp, lua_State *L, int idx);
static short marpaESLIFLua_lua_compare(int *rcip, lua_State *L, int idx1, int idx2, int op);
static short marpaESLIFLua_lua_rawequal(int *rcip, lua_State *L, int idx1, int idx2);
static short marpaESLIFLua_lua_isnil(int *rcip, lua_State *L, int n);
static short marpaESLIFLua_lua_gettop(int *rcip, lua_State *L);
static short marpaESLIFLua_lua_absindex(int *rcip, lua_State *L, int idx);
static short marpaESLIFLua_lua_next(int *rcip, lua_State *L, int idx);
static short marpaESLIFLua_luaL_checklstring(const char **rcp, lua_State *L, int arg, size_t *l);
static short marpaESLIFLua_luaL_checkstring(const char **rcp, lua_State *L, int arg);
static short marpaESLIFLua_luaL_checkinteger(lua_Integer *rcp, lua_State *L, int arg);
static short marpaESLIFLua_lua_getmetatable(int *rcip, lua_State *L, int index);
static short marpaESLIFLua_luaL_callmeta(int *rcp, lua_State *L, int obj, const char *e);
static short marpaESLIFLua_luaL_getmetafield(int *rcp, lua_State *L, int obj, const char *e);
static short marpaESLIFLua_luaL_checktype(lua_State *L, int arg, int t);
static short marpaESLIFLua_lua_topointer(const void **rcpp, lua_State *L, int idx);
static short marpaESLIFLua_lua_rawlen(size_t *rcp, lua_State *L, int idx);
static short marpaESLIFLua_luaL_dostring(int *rcp, lua_State *L, const char *fn);
static short marpaESLIFLua_luaL_loadstring(int *rcp, lua_State *L, const char *s);
static short marpaESLIFLua_lua_pushglobaltable(lua_State *L);
static short marpaESLIFLua_lua_settable(lua_State *L, int idx);
static short marpaESLIFLua_lua_gettable(int *rcp, lua_State *L, int idx);

/* Grrr lua defines that with a macro */
#ifndef marpaESLIFLua_luaL_newlib
#define marpaESLIFLua_luaL_newlib(L, l) (luaL_newlib(L, l), 1)
#endif

#define MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, i) do {                  \
    if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) i)) goto err;  \
    if (! marpaESLIFLua_lua_setglobal(L, #i)) goto err;                 \
  } while (0)

#define MARPAESLIFLUA_GETORCREATEGLOBAL(L, name, gcp, mode) do {	\
    int _typei;                                                         \
    if (! marpaESLIFLua_lua_getglobal(NULL, L, name)) goto err;         \
    if (! marpaESLIFLua_lua_type(&_typei, L, -1)) goto err;             \
    if (_typei != LUA_TTABLE) {                                         \
      if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                      \
      if (! marpaESLIFLua_lua_newtable(L)) goto err;                    \
      if ((mode != NULL) || (gcp != NULL)) {				\
	if (! marpaESLIFLua_lua_newtable(L)) goto err;			\
	if (mode != NULL) {						\
	  MARPAESLIFLUA_STORE_ASCIISTRING(L, "__mode", mode);		\
	}								\
	if (gcp != NULL) {						\
	  if (! marpaESLIFLua_lua_pushcfunction(L, gcp)) goto err;	\
	  if (! marpaESLIFLua_lua_setfield(L, -2, "__gc")) goto err;	\
	}								\
	if (! marpaESLIFLua_lua_setmetatable(L, -2)) goto err;		\
      }									\
      if (! marpaESLIFLua_lua_setglobal(L, name)) goto err;		\
      if (! marpaESLIFLua_lua_getglobal(NULL, L, name)) goto err;	\
    }                                                                   \
} while (0)

#ifdef MARPAESLIFLUA_USE_INTERNALREGISTRYINDEX
#define MARPAESLIFLUA_REF(L, refi) do {                                 \
    MARPAESLIFLUA_GETORCREATEGLOBAL(L, MARPAESLIFLUAREGISTRYINDEX, marpaESLIFLua_marpaESLIFRegistryindex_freei, NULL /* mode */); \
    if (! marpaESLIFLua_lua_insert(L, -2)) goto err;                    \
    if (! marpaESLIFLua_luaL_ref(&(refi), L, -2)) goto err;             \
    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                        \
  } while (0);

#define MARPAESLIFLUA_UNREF(L, refi) do {                               \
    MARPAESLIFLUA_GETORCREATEGLOBAL(L, MARPAESLIFLUAREGISTRYINDEX, marpaESLIFLua_marpaESLIFRegistryindex_freei, NULL /* mode */); \
    if (! marpaESLIFLua_luaL_unref(L, -1, refi)) goto err;              \
    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                        \
  } while (0);

#define MARPAESLIFLUA_DEREF(L, refi) do {                               \
    MARPAESLIFLUA_GETORCREATEGLOBAL(L, MARPAESLIFLUAREGISTRYINDEX, marpaESLIFLua_marpaESLIFRegistryindex_freei, NULL /* mode */); \
    if (! marpaESLIFLua_lua_rawgeti(NULL, L, -1, refi)) goto err;       \
    if (! marpaESLIFLua_lua_remove(L, -2)) goto err;                    \
  } while (0);

#else /* MARPAESLIFLUA_USE_INTERNALREGISTRYINDEX */

#define MARPAESLIFLUA_REF(L, refi) do {                                 \
    if (! marpaESLIFLua_luaL_ref(&(refi), L, LUA_REGISTRYINDEX)) goto err; \
  } while (0);

#define MARPAESLIFLUA_UNREF(L, refi) do {                               \
    if (! marpaESLIFLua_luaL_unref(L, LUA_REGISTRYINDEX, refi)) goto err; \
  } while (0);

#define MARPAESLIFLUA_DEREF(L, refi) do {                               \
    if (! marpaESLIFLua_lua_rawgeti(NULL, L, LUA_REGISTRYINDEX, refi)) goto err; \
  } while (0);

#endif /* MARPAESLIFLUA_USE_INTERNALREGISTRYINDEX */

/* For every MARPAESLIFLUA_STORE_xxx macro, destination table is assumed to be at the top of the stack */
#define MARPAESLIFLUA_STORE_BY_KEY(L, key, valueproducer) do {          \
    valueproducer                                                       \
    if (! marpaESLIFLua_lua_setfield(L, -2, key)) goto err;             \
  } while (0)

#define MARPAESLIFLUA_STORE_FUNCTION(L, key, functionp)                 \
  MARPAESLIFLUA_STORE_BY_KEY(L, key, if (functionp == NULL) { if (! marpaESLIFLua_lua_pushnil(L)) goto err; } else { if (! marpaESLIFLua_lua_pushcfunction(L, functionp)) goto err; })

#define MARPAESLIFLUA_STORE_USERDATA(L, key, p)                         \
  MARPAESLIFLUA_STORE_BY_KEY(L, key, if (p == NULL)         { if (! marpaESLIFLua_lua_pushnil(L)) goto err; } else { if (! marpaESLIFLua_lua_pushlightuserdata(L, p)) goto err; })

#define MARPAESLIFLUA_STORE_STRING(L, key, stringp)                     \
  MARPAESLIFLUA_STORE_BY_KEY(L, key, if (stringp == NULL)   { if (! marpaESLIFLua_lua_pushnil(L)) goto err; } else { if (! marpaESLIFLua_lua_pushlstring(NULL, L, (const char *) stringp->bytep, stringp->bytel)) goto err; })

#define MARPAESLIFLUA_STORE_ASCIISTRING(L, key, asciis)                 \
  MARPAESLIFLUA_STORE_BY_KEY(L, key, if (asciis == NULL)    { if (! marpaESLIFLua_lua_pushnil(L)) goto err; } else { if (! marpaESLIFLua_lua_pushstring(NULL, L, asciis)) goto err; })

#define MARPAESLIFLUA_STORE_INTEGER(L, key, i)                          \
  MARPAESLIFLUA_STORE_BY_KEY(L, key, if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) i)) goto err;)

#define MARPAESLIFLUA_PUSH_INTEGER_ARRAY(L, integerl, integerp) do {    \
    size_t _iteratorl;                                                  \
                                                                        \
    if (! marpaESLIFLua_lua_createtable(L, (int) integerl, 0)) goto err; \
    if ((integerp != NULL) && (integerl > 0)) {                         \
      for (_iteratorl = 0; _iteratorl < integerl; _iteratorl++) {       \
        if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) integerp[_iteratorl])) goto err; \
        if (! marpaESLIFLua_lua_seti(L, -2, (lua_Integer) _iteratorl)) goto err; \
      }                                                                 \
    }                                                                   \
  } while (0)

#define MARPAESLIFLUA_PUSH_BOOLEAN_ARRAY(L, booleanl, booleanp) do {    \
    size_t _iteratorl;                                                  \
                                                                        \
    if (! marpaESLIFLua_lua_createtable(L, (int) booleanl, 0)) goto err; \
    if ((booleanp != NULL) && (booleanl > 0)) {                         \
      for (_iteratorl = 0; _iteratorl < booleanl; _iteratorl++) {       \
        if (! marpaESLIFLua_lua_pushboolean(L, (int) booleanp[_iteratorl])) goto err; \
        if (! marpaESLIFLua_lua_seti(L, -2, (lua_Integer) _iteratorl)) goto err; \
      }                                                                 \
    }                                                                   \
  } while (0)

#define MARPAESLIFLUA_PUSH_ASCIISTRING_ARRAY(L, stringl, stringp) do {  \
    size_t _iteratorl;                                                  \
                                                                        \
    if (! marpaESLIFLua_lua_createtable(L, (int) stringl, 0)) goto err; \
    if ((stringp != NULL) && (stringl > 0)) {                           \
      for (_iteratorl = 0; _iteratorl < stringl; _iteratorl++) {        \
        if (! marpaESLIFLua_lua_pushstring(NULL, L, stringp[_iteratorl])) goto err; \
        if (! marpaESLIFLua_lua_seti(L, -2, (lua_Integer) _iteratorl)) goto err; \
      }                                                                 \
    }                                                                   \
  } while (0)

#define MARPAESLIFLUA_STORE_INTEGER_ARRAY(L, key, integerl, integerp)   \
  MARPAESLIFLUA_STORE_BY_KEY(L, key, MARPAESLIFLUA_PUSH_INTEGER_ARRAY(L, integerl, integerp);)

#define MARPAESLIFLUA_STORE_BOOLEAN_ARRAY(L, key, booleanl, booleanp)   \
  MARPAESLIFLUA_STORE_BY_KEY(L, key, MARPAESLIFLUA_PUSH_BOOLEAN_ARRAY(L, booleanl, booleanp);)

#define MARPAESLIFLUA_STORE_BOOLEAN(L, key, b)                          \
  MARPAESLIFLUA_STORE_BY_KEY(L, key, if (! marpaESLIFLua_lua_pushboolean(L, (int) b)) goto err;)

#define MARPAESLIFLUA_STORE_ACTION(L, key, actionp)                     \
  MARPAESLIFLUA_STORE_BY_KEY(L, key,                                    \
                             if (actionp != NULL) {                     \
                               switch (actionp->type) {                 \
                               case MARPAESLIF_ACTION_TYPE_NAME:        \
                                 if (! marpaESLIFLua_lua_pushstring(NULL, L, actionp->u.names)) goto err; \
                                 break;                                 \
                               case MARPAESLIF_ACTION_TYPE_STRING:      \
                                 if (! marpaESLIFLua_lua_pushlstring(NULL, L, (const char *) actionp->u.stringp->bytep, actionp->u.stringp->bytel)) goto err; \
                                 break;                                 \
                               case MARPAESLIF_ACTION_TYPE_LUA:        \
                                 if (! marpaESLIFLua_lua_pushstring(NULL, L, actionp->u.luas)) goto err; \
                                 break;                                 \
                               default:                                 \
                                 marpaESLIFLua_luaL_errorf(L, "Unsupported action type %d", actionp->type); \
                                 goto err;                              \
                               }                                        \
                             } else {                                   \
                               if (! marpaESLIFLua_lua_pushnil(L)) goto err;                          \
                             }                                          \
                             )

/* This is vicious, but here it is: we assume that EVERY callback function refers to an object */
/* i.e. a function that has "self" as the first parameter. So nargs is always nargs+1 in reality */
/* This is the reason for lua_insert(L, -2) instead of lua_remove(L, -2) */
/* Nevertheless this is not true when we are embedded: then it is assumed that the function */
/* reside in the main namespace and have no object. We distinguish the two cases with the interface_r value: */
#define MARPAESLIFLUA_CALLBACK(L, interface_r, funcs, nargs, parameters) do { \
    int _typei;                                                         \
    if (interface_r != LUA_NOREF) {					\
      MARPAESLIFLUA_DEREF(L, interface_r);                              \
      if (! marpaESLIFLua_lua_getfield(NULL, L, -1, funcs)) goto err;   \
      if (! marpaESLIFLua_lua_type(&_typei, L, -1)) goto err;           \
      if (_typei != LUA_TFUNCTION) {                                    \
        marpaESLIFLua_luaL_errorf(L, "No such function %s", funcs);     \
        goto err;                                                       \
      }                                                                 \
      if (! marpaESLIFLua_lua_insert(L, -2)) goto err;                  \
      parameters                                                        \
      if (! marpaESLIFLua_lua_call(L, nargs + 1, LUA_MULTRET)) goto err; \
    } else {								\
      if (! marpaESLIFLua_lua_getglobal(NULL, L, funcs)) goto err;      \
      if (! marpaESLIFLua_lua_type(&_typei, L, -1)) goto err;           \
      if (_typei != LUA_TFUNCTION) {                                    \
        marpaESLIFLua_luaL_errorf(L, "No such function %s", funcs);     \
        goto err;                                                       \
      }                                                                 \
      parameters                                                        \
      if (! marpaESLIFLua_lua_call(L, nargs, LUA_MULTRET)) goto err;    \
    }                                                                   \
} while (0)
    
#define MARPAESLIFLUA_CALLBACKV(L, interface_r, funcs, nargs, parameters) do { \
  int _topi;                                                            \
                                                                        \
  if (! marpaESLIFLua_lua_gettop(&_topi, L)) goto err;                  \
  MARPAESLIFLUA_CALLBACK(L, interface_r, funcs, nargs, parameters);     \
  if (! marpaESLIFLua_lua_settop(L, _topi)) goto err;                   \
} while (0)
    
#define MARPAESLIFLUA_CALLBACKB(L, interface_r, funcs, nargs, parameters, bp) do { \
    int _topi;                                                          \
    int _newtopi;                                                       \
    int _typei;                                                         \
    int _tmpi;                                                          \
                                                                        \
    if (! marpaESLIFLua_lua_gettop(&_topi, L)) goto err;                \
    MARPAESLIFLUA_CALLBACK(L, interface_r, funcs, nargs, parameters);   \
    if (! marpaESLIFLua_lua_gettop(&_newtopi, L)) goto err;             \
    if (_newtopi != (_topi + 1)) {                                      \
      marpaESLIFLua_luaL_errorf(L, "Function %s must return exactly one value", funcs); \
      goto err;                                                         \
    }                                                                   \
    if (! marpaESLIFLua_lua_type(&_typei, L, -1)) goto err;             \
    if (_typei != LUA_TBOOLEAN) {                                       \
      marpaESLIFLua_luaL_errorf(L, "Function %s must return a boolean value, got %s", funcs, lua_typename(L, _typei)); \
      goto err;                                                         \
    }                                                                   \
    if (bp != NULL) {                                                   \
      if (! marpaESLIFLua_lua_toboolean(&_tmpi, L, -1)) goto err;       \
      *bp = (_tmpi != 0) ? 1 : 0;                                       \
    }                                                                   \
    if (! marpaESLIFLua_lua_settop(L, _topi)) goto err;                 \
} while (0)

#define MARPAESLIFLUA_CALLBACKI(L, interface_r, funcs, nargs, parameters, ip) do { \
    int _topi;                                                          \
    int _newtopi;                                                       \
    int _isnum;                                                         \
    int _typei;                                                         \
    lua_Integer _i;                                                     \
                                                                        \
    if (! marpaESLIFLua_lua_gettop(&_topi, L)) goto err;                \
    MARPAESLIFLUA_CALLBACK(L, interface_r, funcs, nargs, parameters);   \
    if (! marpaESLIFLua_lua_gettop(&_newtopi, L)) goto err;             \
    if (_newtopi != (_topi + 1)) {                                      \
      marpaESLIFLua_luaL_errorf(L, "Function %s must return exactly one value", funcs); \
      goto err;                                                         \
    }                                                                   \
    if (! marpaESLIFLua_lua_type(&_typei, L, -1)) goto err;             \
    if (_typei != LUA_TNUMBER) {                                        \
      marpaESLIFLua_luaL_errorf(L, "Function %s must return a number value, got %s", funcs, lua_typename(L, _typei)); \
      goto err;                                                         \
    }                                                                   \
    if (ip != NULL) {                                                   \
      if (! marpaESLIFLua_lua_tointegerx(&_i, L, -1, &_isnum)) goto err; \
      if (! _isnum) {                                                   \
        marpaESLIFLua_luaL_error(L, "Convertion to an integer failed"); \
        goto err;                                                       \
      }                                                                 \
      *ip = (int) _i;                                                   \
    }                                                                   \
    if (! marpaESLIFLua_lua_settop(L, _topi)) goto err;                                               \
} while (0)

/* Take care: if *sp is != NULL outside of the scope, caller's responsibility to free it */
#define MARPAESLIFLUA_CALLBACKS(L, interface_r, funcs, nargs, parameters, sp, lp) do { \
    int _topi;                                                          \
    int _newtopi;                                                       \
    const char *_s;                                                     \
    size_t _l;                                                          \
    int _typei;                                                         \
                                                                        \
    if (! marpaESLIFLua_lua_gettop(&_topi, L)) goto err;                \
    MARPAESLIFLUA_CALLBACK(L, interface_r, funcs, nargs, parameters);   \
    if (! marpaESLIFLua_lua_gettop(&_newtopi, L)) goto err;             \
    if (_newtopi != (_topi + 1)) {                                      \
      marpaESLIFLua_luaL_errorf(L, "Function %s must return exactly one value", funcs); \
      goto err;                                                         \
    }                                                                   \
    if (! marpaESLIFLua_lua_type(&_typei, L, -1)) goto err;             \
    switch (_typei) {                                                   \
    case LUA_TNIL:                                                      \
      *sp = NULL;                                                       \
      *lp = 0;                                                          \
      break;                                                            \
    case LUA_TSTRING:                                                   \
      if (! marpaESLIFLua_lua_tolstring(&_s, L, -1, &_l)) goto err;     \
      if (_s != NULL) {                                                 \
        *sp = malloc(_l);                                               \
        if (*sp == NULL) {                                              \
          marpaESLIFLua_luaL_errorf(L, "malloc failure, %s", strerror(errno));  \
          goto err;                                                     \
        }                                                               \
        memcpy(*sp, _s, _l);                                            \
        *lp = _l;                                                       \
      } else {                                                          \
        *sp = NULL;                                                     \
        *lp = 0;                                                        \
      }                                                                 \
      break;                                                            \
    default:                                                            \
      marpaESLIFLua_luaL_errorf(L, "Function %s must return a string value or nil, got %s", funcs, lua_typename(L, _typei)); \
      goto err;                                                         \
    }                                                                   \
    if (! marpaESLIFLua_lua_settop(L, _topi)) goto err;                                               \
} while (0)

/* -------------------- */
/* Push of ESLIF object */
/* -------------------- */
#define MARPAESLIFLUA_PUSH_MARPAESLIF_OBJECT(L, marpaESLIFLuaContextp) do { \
    if (! marpaESLIFLua_lua_newtable(L)) goto err;                      \
    MARPAESLIFLUA_STORE_USERDATA(L, "marpaESLIFLuaContextp",      marpaESLIFLuaContextp); \
    if (! marpaESLIFLua_lua_newtable(L)) goto err;                      \
    MARPAESLIFLUA_STORE_ASCIISTRING(L, "__mode", "v");                  \
    MARPAESLIFLUA_STORE_FUNCTION(L, "__gc",                       marpaESLIFLua_marpaESLIF_freei); \
    if (! marpaESLIFLua_lua_newtable(L)) goto err;                      \
    MARPAESLIFLUA_STORE_FUNCTION(L, "version",                    marpaESLIFLua_marpaESLIF_versioni); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "versionMajor",               marpaESLIFLua_marpaESLIF_versionMajori); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "versionMinor",               marpaESLIFLua_marpaESLIF_versionMinori); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "versionPatch",               marpaESLIFLua_marpaESLIF_versionPatchi); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "marpaESLIFGrammar_new",      marpaESLIFLua_marpaESLIFGrammar_newi); \
    if (! marpaESLIFLua_lua_setfield(L, -2, "__index")) goto err;       \
    if (! marpaESLIFLua_lua_setmetatable(L, -2)) goto err;              \
  } while (0)

/* ---------------------------- */
/* Push of ESLIF grammar object */
/* ---------------------------- */
#define MARPAESLIFLUA_PUSH_MARPAESLIFGRAMMAR_OBJECT(L, marpaESLIFLuaGrammarContextp) do { \
    if (! marpaESLIFLua_lua_newtable(L)) goto err;                      \
    MARPAESLIFLUA_STORE_USERDATA(L, "marpaESLIFLuaGrammarContextp", marpaESLIFLuaGrammarContextp); \
    if (! marpaESLIFLua_lua_newtable(L)) goto err;                      \
    MARPAESLIFLUA_STORE_ASCIISTRING(L, "__mode", "v");                  \
    MARPAESLIFLUA_STORE_FUNCTION(L, "__gc",                         marpaESLIFLua_marpaESLIFGrammar_freei); \
    if (! marpaESLIFLua_lua_newtable(L)) goto err;                      \
    MARPAESLIFLUA_STORE_FUNCTION(L, "ngrammar",                     marpaESLIFLua_marpaESLIFGrammar_ngrammari); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "currentLevel",                 marpaESLIFLua_marpaESLIFGrammar_currentLeveli); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "currentDescription",           marpaESLIFLua_marpaESLIFGrammar_currentDescriptioni); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "descriptionByLevel",           marpaESLIFLua_marpaESLIFGrammar_descriptionByLeveli); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "currentRuleIds",               marpaESLIFLua_marpaESLIFGrammar_currentRuleIdsi); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "ruleIdsByLevel",               marpaESLIFLua_marpaESLIFGrammar_ruleIdsByLeveli); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "currentSymbolIds",             marpaESLIFLua_marpaESLIFGrammar_currentSymbolIdsi); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "symbolIdsByLevel",             marpaESLIFLua_marpaESLIFGrammar_symbolIdsByLeveli); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "currentProperties",            marpaESLIFLua_marpaESLIFGrammar_currentPropertiesi); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "propertiesByLevel",            marpaESLIFLua_marpaESLIFGrammar_propertiesByLeveli); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "currentRuleProperties",        marpaESLIFLua_marpaESLIFGrammar_currentRulePropertiesi); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "rulePropertiesByLevel",        marpaESLIFLua_marpaESLIFGrammar_rulePropertiesByLeveli); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "currentSymbolProperties",      marpaESLIFLua_marpaESLIFGrammar_currentSymbolPropertiesi); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "symbolPropertiesByLevel",      marpaESLIFLua_marpaESLIFGrammar_symbolPropertiesByLeveli); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "ruleDisplay",                  marpaESLIFLua_marpaESLIFGrammar_ruleDisplayi); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "symbolDisplay",                marpaESLIFLua_marpaESLIFGrammar_symbolDisplayi); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "ruleShow",                     marpaESLIFLua_marpaESLIFGrammar_ruleShowi); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "ruleDisplayByLevel",           marpaESLIFLua_marpaESLIFGrammar_ruleDisplayByLeveli); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "symbolDisplayByLevel",         marpaESLIFLua_marpaESLIFGrammar_symbolDisplayByLeveli); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "ruleShowByLevel",              marpaESLIFLua_marpaESLIFGrammar_ruleShowByLeveli); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "show",                         marpaESLIFLua_marpaESLIFGrammar_showi); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "showByLevel",                  marpaESLIFLua_marpaESLIFGrammar_showByLeveli); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "parse",                        marpaESLIFLua_marpaESLIFGrammar_parsei); \
    MARPAESLIFLUA_STORE_FUNCTION(L, "marpaESLIFRecognizer_new",     marpaESLIFLua_marpaESLIFRecognizer_newi); \
    if (! marpaESLIFLua_lua_setfield(L, -2, "__index")) goto err;       \
    if (! marpaESLIFLua_lua_setmetatable(L, -2)) goto err;              \
  } while (0)

/* ------------------------------- */
/* Push of ESLIF recognizer object */
/* ------------------------------- */
#define MARPAESLIFLUA_PUSH_MARPAESLIFRECOGNIZER_OBJECT(L, marpaESLIFLuaRecognizerContextp) do { \
  if (! marpaESLIFLua_lua_newtable(L)) goto err;                        \
  MARPAESLIFLUA_STORE_USERDATA(L, "marpaESLIFLuaRecognizerContextp", marpaESLIFLuaRecognizerContextp); \
  if (! marpaESLIFLua_lua_newtable(L)) goto err;                        \
  MARPAESLIFLUA_STORE_ASCIISTRING(L, "__mode", "v");                    \
  MARPAESLIFLUA_STORE_FUNCTION(L, "__gc",                            marpaESLIFLua_marpaESLIFRecognizer_freei); \
  if (! marpaESLIFLua_lua_newtable(L)) goto err;                        \
  MARPAESLIFLUA_STORE_FUNCTION(L, "newFrom",                         marpaESLIFLua_marpaESLIFRecognizer_newFromi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "set_exhausted_flag",              marpaESLIFLua_marpaESLIFRecognizer_set_exhausted_flagi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "share",                           marpaESLIFLua_marpaESLIFRecognizer_sharei); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "isCanContinue",                   marpaESLIFLua_marpaESLIFRecognizer_isCanContinuei); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "isExhausted",                     marpaESLIFLua_marpaESLIFRecognizer_isExhaustedi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "scan",                            marpaESLIFLua_marpaESLIFRecognizer_scani); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "resume",                          marpaESLIFLua_marpaESLIFRecognizer_resumei); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "events",                          marpaESLIFLua_marpaESLIFRecognizer_eventsi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "eventOnOff",                      marpaESLIFLua_marpaESLIFRecognizer_eventOnOffi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "lexemeAlternative",               marpaESLIFLua_marpaESLIFRecognizer_lexemeAlternativei); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "lexemeComplete",                  marpaESLIFLua_marpaESLIFRecognizer_lexemeCompletei); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "lexemeRead",                      marpaESLIFLua_marpaESLIFRecognizer_lexemeReadi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "lexemeTry",                       marpaESLIFLua_marpaESLIFRecognizer_lexemeTryi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "discardTry",                      marpaESLIFLua_marpaESLIFRecognizer_discardTryi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "lexemeExpected",                  marpaESLIFLua_marpaESLIFRecognizer_lexemeExpectedi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "lexemeLastPause",                 marpaESLIFLua_marpaESLIFRecognizer_lexemeLastPausei); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "lexemeLastTry",                   marpaESLIFLua_marpaESLIFRecognizer_lexemeLastTryi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "discardLastTry",                  marpaESLIFLua_marpaESLIFRecognizer_discardLastTryi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "discardLast",                     marpaESLIFLua_marpaESLIFRecognizer_discardLasti); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "isEof",                           marpaESLIFLua_marpaESLIFRecognizer_isEofi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "read",                            marpaESLIFLua_marpaESLIFRecognizer_readi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "input",                           marpaESLIFLua_marpaESLIFRecognizer_inputi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "progressLog",                     marpaESLIFLua_marpaESLIFRecognizer_progressLogi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "lastCompletedOffset",             marpaESLIFLua_marpaESLIFRecognizer_lastCompletedOffseti); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "lastCompletedLength",             marpaESLIFLua_marpaESLIFRecognizer_lastCompletedLengthi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "lastCompletedLocation",           marpaESLIFLua_marpaESLIFRecognizer_lastCompletedLocationi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "line",                            marpaESLIFLua_marpaESLIFRecognizer_linei); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "column",                          marpaESLIFLua_marpaESLIFRecognizer_columni); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "location",                        marpaESLIFLua_marpaESLIFRecognizer_locationi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "hookDiscard",                     marpaESLIFLua_marpaESLIFRecognizer_hookDiscardi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "hookDiscardSwitch",               marpaESLIFLua_marpaESLIFRecognizer_hookDiscardSwitchi); \
  MARPAESLIFLUA_STORE_FUNCTION(L, "marpaESLIFValue_new",             marpaESLIFLua_marpaESLIFValue_newi); \
  if (! marpaESLIFLua_lua_setfield(L, -2, "__index")) goto err;         \
  if (! marpaESLIFLua_lua_setmetatable(L, -2)) goto err;                \
  } while (0)

/* ---------------------------- */
/* Push of ESLIF value object */
/* ---------------------------- */
#define MARPAESLIFLUA_PUSH_MARPAESLIFVALUE_OBJECT(L, marpaESLIFLuaValueContextp) do { \
    if (! marpaESLIFLua_lua_newtable(L)) goto err;                      \
    MARPAESLIFLUA_STORE_USERDATA(L, "marpaESLIFLuaValueContextp", marpaESLIFLuaValueContextp); \
    if (! marpaESLIFLua_lua_newtable(L)) goto err;                      \
    MARPAESLIFLUA_STORE_ASCIISTRING(L, "__mode", "v");                  \
    MARPAESLIFLUA_STORE_FUNCTION(L, "__gc",                       marpaESLIFLua_marpaESLIFValue_freei); \
    if (! marpaESLIFLua_lua_newtable(L)) goto err;                      \
    MARPAESLIFLUA_STORE_FUNCTION(L, "value",                      marpaESLIFLua_marpaESLIFValue_valuei); \
    if (! marpaESLIFLua_lua_setfield(L, -2, "__index")) goto err;       \
    if (! marpaESLIFLua_lua_setmetatable(L, -2)) goto err;              \
  } while (0)

#ifdef MARPAESLIFLUA_EMBEDDED
/* luaopen_marpaESLIFLua is to be called explicitely by the program that embeds marpaESLIFLua */
static
#endif
/****************************************************************************/
int luaopen_marpaESLIFLua(lua_State* L)
/****************************************************************************/
{
  static const char *funcs = "luaopen_marpaESLIFLua";

  if (! marpaESLIFLua_luaL_requiref(L, "marpaESLIFLua", marpaESLIFLua_installi, 1 /* global */)) goto err;

  return 1;

 err:
  return 0;
}

/****************************************************************************/
static int marpaESLIFLua_installi(lua_State *L)
/****************************************************************************/
{
  static const char     *funcs                        = "marpaESLIFLua_installi";
  static const luaL_Reg  marpaESLIFLua_installTable[] = {
    {"version",                     marpaESLIFLua_versioni},
    {"versionMajor",                marpaESLIFLua_versionMajori},
    {"versionMinor",                marpaESLIFLua_versionMinori},
    {"versionPatch",                marpaESLIFLua_versionPatchi},
    {"marpaESLIF_new",              marpaESLIFLua_marpaESLIF_newi},
    {NULL, NULL}
  };
  int                    rci;
  int                    metatablei;
  int                    typei;
  int                    dostringi;

  /* We load the new meta keywords */
  if (! marpaESLIFLua_luaL_dostring(&dostringi, L, MARPAESLIFLUA_NEWKEYWORDS)) goto err;
  if (dostringi != LUA_OK) {
    marpaESLIFLua_luaL_errorf(L, "Loading new keywords source failed with status %d", dostringi);
    goto err;
  }
  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  /* We load the niled table implementation */
  if (! marpaESLIFLua_luaL_dostring(&dostringi, L, MARPAESLIFLUA_NILEDTABLE)) goto err;
  if (dostringi != LUA_OK) {
    marpaESLIFLua_luaL_errorf(L, "Loading niled table source failed with status %d", dostringi);
    goto err;
  }
  /* NiledTable in on the stack */                                         /* Stack: NiledTable */
  if (! marpaESLIFLua_lua_getfield(NULL, L, -1, "niledarray")) goto err;   /* Stack: NiledTable, NiledTable.niledarray */
  if (! marpaESLIFLua_lua_getfield(NULL, L, -2, "niledtablekv")) goto err; /* Stack: NiledTable, NiledTable.niledarray, NiledTable.niledtablekv */
  if (! marpaESLIFLua_lua_setglobal(L, "niledtablekv")) goto err;          /* Stack: NiledTable, NiledTable.niledarray */
  if (! marpaESLIFLua_lua_setglobal(L, "niledarray")) goto err;            /* Stack: NiledTable */
  if (! marpaESLIFLua_lua_setglobal(L, "NiledTable")) goto err;            /* Stack: */

  /* Install marpaESLIF main entry points */
  if (! marpaESLIFLua_luaL_newlib(L, marpaESLIFLua_installTable)) goto err;

  /* Create constants */
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_EVENTTYPE_NONE);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_EVENTTYPE_COMPLETED);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_EVENTTYPE_NULLED);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_EVENTTYPE_PREDICTED);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_EVENTTYPE_BEFORE);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_EVENTTYPE_AFTER);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_EVENTTYPE_EXHAUSTED);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_EVENTTYPE_DISCARD);

  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_VALUE_TYPE_UNDEF);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_VALUE_TYPE_CHAR);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_VALUE_TYPE_SHORT);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_VALUE_TYPE_INT);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_VALUE_TYPE_LONG);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_VALUE_TYPE_FLOAT);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_VALUE_TYPE_DOUBLE);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_VALUE_TYPE_PTR);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_VALUE_TYPE_ARRAY);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_VALUE_TYPE_BOOL);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_VALUE_TYPE_STRING);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_VALUE_TYPE_ROW);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_VALUE_TYPE_TABLE);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_VALUE_TYPE_LONG_DOUBLE);
#ifdef MARPAESLIF_HAVE_LONG_LONG
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_VALUE_TYPE_LONG_LONG);
#endif

  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_RULE_IS_ACCESSIBLE);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_RULE_IS_NULLABLE);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_RULE_IS_NULLING);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_RULE_IS_LOOP);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_RULE_IS_PRODUCTIVE);

  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_SYMBOL_IS_ACCESSIBLE);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_SYMBOL_IS_NULLABLE);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_SYMBOL_IS_NULLING);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_SYMBOL_IS_PRODUCTIVE);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_SYMBOL_IS_START);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_SYMBOL_IS_TERMINAL);

  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_SYMBOL_EVENT_COMPLETION);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_SYMBOL_EVENT_NULLED);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_SYMBOL_EVENT_PREDICTION);

  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_SYMBOLTYPE_TERMINAL);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, MARPAESLIF_SYMBOLTYPE_META);

  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, GENERICLOGGER_LOGLEVEL_TRACE);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, GENERICLOGGER_LOGLEVEL_DEBUG);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, GENERICLOGGER_LOGLEVEL_INFO);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, GENERICLOGGER_LOGLEVEL_NOTICE);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, GENERICLOGGER_LOGLEVEL_WARNING);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, GENERICLOGGER_LOGLEVEL_ERROR);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, GENERICLOGGER_LOGLEVEL_CRITICAL);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, GENERICLOGGER_LOGLEVEL_ALERT);
  MARPAESLIFLUA_CREATEINTEGERCONSTANT(L, GENERICLOGGER_LOGLEVEL_EMERGENCY);

  /* We create the string.encoding() function - all strings share the same unique metatable */
  if (! marpaESLIFLua_lua_pushstring(NULL, L, "")) goto err;                              /* Stack: marpaESLIFLuaTable, "" */
  if (! marpaESLIFLua_lua_getmetatable(&metatablei, L, -1)) goto err;                     /* Stack: marpaESLIFLuaTable, "", metatable */
  if (metatablei == 0) {
    if (! marpaESLIFLua_lua_pop(L, 2)) goto err;                                          /* Stack: marpaESLIFLuaTable */
  } else {
    if (! marpaESLIFLua_lua_getfield(NULL, L, -1, "__index")) goto err;                   /* Stack: marpaESLIFLuaTable, "", metatable, metatable[__index] */
    if (! marpaESLIFLua_lua_type(&typei, L, -1)) goto err;
    if (typei != LUA_TTABLE) {
      if (! marpaESLIFLua_lua_pop(L, 3)) goto err;                                        /* Stack: marpaESLIFLuaTable */
    } else {
      if (! marpaESLIFLua_lua_pushcfunction(L, marpaESLIFLua_string_encodingi)) goto err; /* Stack: marpaESLIFLuaTable, "", metatable, metatable[__index], marpaESLIFLua_string_encodingi */
      if (! marpaESLIFLua_lua_setfield(L, -2, "encoding")) goto err;		          /* Stack: marpaESLIFLuaTable, "", metatable, metatable[__index] */
      if (! marpaESLIFLua_lua_pop(L, 3)) goto err;                                        /* Stack: marpaESLIFLuaTable */
    }
  }

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int marpaESLIFLua_versioni(lua_State *L)
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_versioni";
  int                topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 0) {
    marpaESLIFLua_luaL_error(L, "Usage: version()");
    goto err;
  }

  if (! marpaESLIFLua_lua_pushstring(NULL, L, MARPAESLIFLUA_VERSION)) goto err;

  return 1;

 err:
  return 0;
}

/****************************************************************************/
static int marpaESLIFLua_versionMajori(lua_State *L)
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_versionMajori";
  int                rci;
  int                topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 0) {
    marpaESLIFLua_luaL_error(L, "Usage: versionMajor()");
    goto err;
  }

  if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) MARPAESLIFLUA_VERSION_MAJOR)) goto err;

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int marpaESLIFLua_versionMinori(lua_State *L)
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_versionMinori";
  int                rci;
  int                topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 0) {
    marpaESLIFLua_luaL_error(L, "Usage: versionMinor()");
    goto err;
  }

  if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) MARPAESLIFLUA_VERSION_MINOR)) goto err;

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int marpaESLIFLua_versionPatchi(lua_State *L)
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_versionPatchi";
  int                rci;
  int                topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 0) {
    marpaESLIFLua_luaL_error(L, "Usage: versionPatch()");
    goto err;
  }

  if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) MARPAESLIFLUA_VERSION_PATCH)) goto err;

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int marpaESLIFLua_marpaESLIF_newi(lua_State *L)
/****************************************************************************/
{
  static const char                   *funcs                 = "marpaESLIFLua_marpaESLIF_newi";
  marpaESLIFLuaContext_t              *marpaESLIFLuaContextp = NULL;
  short                                loggerb;
  marpaESLIFLuaGenericLoggerContext_t *marpaESLIFLuaGenericLoggerContextp;
  genericLogger_t                     *genericLoggerp;
  marpaESLIFOption_t                   marpaESLIFOption;
  int                                  logger_r;
  int                                  rci;
  lua_Integer                          tmpi;
  int                                  rawequali;
  int                                  isnili;
  int                                  topi;
  int                                  nexti;
  int                                  iteratori;
  int                                  statevariablei;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;

  switch (topi) {
  case 0:
    loggerb = 0;
    break;
  case 1:
    loggerb = marpaESLIFLua_paramIsLoggerInterfaceOrNilb(L, 1);
    break;
  default:
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIF_new([logger]");
    goto err;
  }

  MARPAESLIFLUA_GETORCREATEGLOBAL(L, MARPAESLIFMULTITONSTABLE, marpaESLIFLua_marpaESLIFMultitonsTable_freei, NULL /* mode */); /* Stack: logger?, MARPAESLIFMULTITONSTABLE */

  if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                                     /* Stack: logger?, MARPAESLIFMULTITONSTABLE, nil */
  while (1) {
    if (! marpaESLIFLua_pairsb(&nexti, L, -2, &iteratori, &statevariablei)) goto err;               /* Stack: logger?, MARPAESLIFMULTITONSTABLE, marpaESLIFLuaContextp, r */
    if (nexti == 0) break;
    if (! marpaESLIFLua_lua_tointeger(&tmpi, L, -1)) goto err;
    logger_r = (int) tmpi;
    if (logger_r == LUA_NOREF) {
      if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                                 /* Stack: logger?, MARPAESLIFMULTITONSTABLE, marpaESLIFLuaContextp, r, nil */
    } else {
      MARPAESLIFLUA_DEREF(L, logger_r);                                                             /* Stack: logger?, MARPAESLIFMULTITONSTABLE, marpaESLIFLuaContextp, r, loggerp_from_registry */
    }
    rawequali = 0;
    isnili = 0;
    if (! loggerb) {
      if (! marpaESLIFLua_lua_isnil(&isnili, L, -1)) goto err;
    } else {
      if (! marpaESLIFLua_lua_rawequal(&rawequali, L, 1, -1)) goto err;
    }
    /* Look if MARPAESLIFMULTITONSTABLE already contains a reference to logger */
    if (((! loggerb) && isnili)
        ||
        ((  loggerb) && rawequali)) {
      if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaContextp, L, -3)) goto err;
      if (! marpaESLIFLua_lua_pop(L, 3)) goto err;                                                  /* Stack: logger?, MARPAESLIFMULTITONSTABLE */
      break;
    }
    if (! marpaESLIFLua_lua_pop(L, 2)) goto err;                                                    /* Stack: logger?, MARPAESLIFMULTITONSTABLE, marpaESLIFLuaContextp */
  }
  
  if (marpaESLIFLuaContextp == NULL) {
    if (loggerb) {
      marpaESLIFLuaGenericLoggerContextp = (marpaESLIFLuaGenericLoggerContext_t *) malloc(sizeof(marpaESLIFLuaGenericLoggerContext_t));
      if (marpaESLIFLuaGenericLoggerContextp == NULL) {
        marpaESLIFLua_luaL_errorf(L, "malloc failure, %s\n", strerror(errno));
        goto err;
      }

      marpaESLIFLuaGenericLoggerContextp->L = NULL;
      marpaESLIFLuaGenericLoggerContextp->logger_r = LUA_NOREF;

      /* Get logger reference */
      if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                                 /* Stack: logger, MARPAESLIFMULTITONSTABLE, nil */
      if (! marpaESLIFLua_lua_copy(L, 1, -1)) goto err;                                             /* Stack: logger, MARPAESLIFMULTITONSTABLE, logger */
      MARPAESLIFLUA_REF(L, logger_r);                                                               /* Stack: logger, MARPAESLIFMULTITONSTABLE */

      /* Fill genericLogger context */
      marpaESLIFLuaGenericLoggerContextp->L = L;
      marpaESLIFLuaGenericLoggerContextp->logger_r = logger_r;
      genericLoggerp = genericLogger_newp(marpaESLIFLua_genericLoggerCallbackv, marpaESLIFLuaGenericLoggerContextp, GENERICLOGGER_LOGLEVEL_TRACE);
      if (genericLoggerp == NULL) {
        MARPAESLIFLUA_UNREF(L, logger_r);
        free(marpaESLIFLuaGenericLoggerContextp);
        marpaESLIFLua_luaL_errorf(L, "genericLogger_newp failure, %s\n", strerror(errno));
        goto err;
      }
    } else {
      logger_r = LUA_NOREF;
      genericLoggerp = NULL;
    }

    marpaESLIFLuaContextp = malloc(sizeof(marpaESLIFLuaContext_t));
    if (marpaESLIFLuaContextp == NULL) {
      MARPAESLIFLUA_UNREF(L, logger_r); /* No effect if it is LUA_NOREF */
      free(marpaESLIFLuaGenericLoggerContextp);
      marpaESLIFLua_luaL_errorf(L, "malloc failure, %s\n", strerror(errno));
      goto err;
    }
    if (! marpaESLIFLua_contextInitb(L, marpaESLIFLuaContextp, 0 /* unmanagedb */)) goto err;

    marpaESLIFOption.genericLoggerp    = genericLoggerp;
    marpaESLIFLuaContextp->marpaESLIFp = marpaESLIF_newp(&marpaESLIFOption);
    if (marpaESLIFLuaContextp->marpaESLIFp == NULL) {
      MARPAESLIFLUA_UNREF(L, logger_r); /* No effect if it is LUA_NOREF */
      free(marpaESLIFLuaContextp);
      free(marpaESLIFLuaGenericLoggerContextp);
      marpaESLIFLua_luaL_errorf(L, "marpaESLIF_newp failure, %s\n", strerror(errno));
      goto err;
    }

    /* Link marpaESLIFp to logger_r */
    if (! marpaESLIFLua_lua_pushlightuserdata(L, (void *) marpaESLIFLuaContextp)) goto err;         /* Stack: logger?, MARPAESLIFMULTITONSTABLE, marpaESLIFLuaContextp */
    if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) logger_r)) goto err;                       /* Stack: logger?, MARPAESLIFMULTITONSTABLE, marpaESLIFLuaContextp, logger_r */
    if (! marpaESLIFLua_lua_settable(L, -3)) goto err;                                              /* Stack: logger?, MARPAESLIFMULTITONSTABLE */

    /* Remember it is in the multiton table */
    marpaESLIFLuaContextp->multitonb = 1;
  }

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  /* Push marpaESLIF object */
  MARPAESLIFLUA_PUSH_MARPAESLIF_OBJECT(L, marpaESLIFLuaContextp);

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int marpaESLIFLua_string_encodingi(lua_State *L)
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_string_encodingi";
  int                rci;
  int                topi;
  int                typei;
  const char        *encodings;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;

  switch (topi) {
  case 2:
    if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
    if (typei != LUA_TSTRING) {
      marpaESLIFLua_luaL_error(L, "First argument to string.encoding() must be a string");
      goto err;
    }
    if (! marpaESLIFLua_lua_type(&typei, L, 2)) goto err;
    if ((typei != LUA_TSTRING) && (typei != LUA_TNIL)) {
      marpaESLIFLua_luaL_error(L, "Second argument to string.encoding() must be a string giving the encoding or nil");
      goto err;
    }
    if (! marpaESLIFLua_lua_tostring(&encodings, L, 2)) goto err;
    MARPAESLIFLUA_GETORCREATEGLOBAL(L, MARPAESLIFSTRINGTOENCODINGTABLE, NULL /* gcp */, "k" /* mode */); /* Stack: string, encoding, MARPAESLIFSTRINGTOENCODINGTABLE */
    if (! marpaESLIFLua_lua_insert(L, -3)) goto err;                                                     /* Stack: MARPAESLIFSTRINGTOENCODINGTABLE, string, encoding */
    if (! marpaESLIFLua_lua_settable(L, -3)) goto err;                                                   /* Stack: MARPAESLIFSTRINGTOENCODINGTABLE */
    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                                                         /* Stack: */
    if (! marpaESLIFLua_lua_pushstring(NULL, L, encodings)) goto err;                                    /* Stack: encodings */
    break;
  case 1:
    if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
    if (typei != LUA_TSTRING) {
      marpaESLIFLua_luaL_error(L, "First argument to string.encoding() must be a string");
      goto err;
    }
    MARPAESLIFLUA_GETORCREATEGLOBAL(L, MARPAESLIFSTRINGTOENCODINGTABLE, NULL /* gcp */, "k" /* mode */); /* Stack: string, MARPAESLIFSTRINGTOENCODINGTABLE */
    if (! marpaESLIFLua_lua_insert(L, -2)) goto err;                                                     /* Stack: MARPAESLIFSTRINGTOENCODINGTABLE, string */
    if (! marpaESLIFLua_lua_gettable(NULL, L, -2)) goto err;                                             /* Stack: MARPAESLIFSTRINGTOENCODINGTABLE, encodings */
    if (! marpaESLIFLua_lua_remove(L, -2)) goto err;                                                     /* Stack: encodings */
    break;
  default:
    marpaESLIFLua_luaL_error(L, "Usage: string.encoding(string, string) where second string is the encoding");
    goto err;
  }

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int marpaESLIFLua_marpaESLIF_freei(lua_State *L)
/****************************************************************************/
{
  static const char      *funcs = "marpaESLIFLua_marpaESLIF_freei";
  marpaESLIFLuaContext_t *marpaESLIFLuaContextp;

  if (! marpaESLIFLua_lua_getfield(NULL, L, -1, "marpaESLIFLuaContextp")) goto err; /* Stack: {...}, marpaESLIFLuaContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;  /* Stack: {...} */

  marpaESLIFLua_contextFreev(marpaESLIFLuaContextp, 0 /* multitonDestroyModeb */);

  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;        /* Stack: */

  return 0;

 err:
  return 0;
}

/****************************************************************************/
static int marpaESLIFLua_marpaESLIF_versioni(lua_State *L)
/****************************************************************************/
{
  static const char      *funcs = "marpaESLIFLua_marpaESLIF_versioni";
  marpaESLIFLuaContext_t *marpaESLIFLuaContextp;
  char                   *versions;
  int                     typei;
  int                     topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: version(marpaESLIFp)");
    goto err;
  }

  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL, L, 1, "marpaESLIFLuaContextp")) goto err;   /* Stack: marpaESLIFTable, marpaESLIFLuaContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 2)) goto err;   /* Stack: */

  if (! marpaESLIF_versionb(marpaESLIFLuaContextp->marpaESLIFp, &versions)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIF_versionb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_pushstring(NULL, L, versions)) goto err;

  return 1;

 err:
  return 0;
}

/****************************************************************************/
static int marpaESLIFLua_marpaESLIF_versionMajori(lua_State *L)
/****************************************************************************/
{
  static const char      *funcs = "marpaESLIFLua_marpaESLIF_versionMajori";
  marpaESLIFLuaContext_t *marpaESLIFLuaContextp;
  int                     majori;
  int                     rci;
  int                     typei;
  int                     topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: version(marpaESLIFp)");
    goto err;
  }

  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL, L, 1, "marpaESLIFLuaContextp")) goto err;   /* Stack: marpaESLIFTable, marpaESLIFLuaContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 2)) goto err;   /* Stack: */

  if (! marpaESLIF_versionMajorb(marpaESLIFLuaContextp->marpaESLIFp, &majori)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIF_versionMajorb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) majori)) goto err;

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int marpaESLIFLua_marpaESLIF_versionMinori(lua_State *L)
/****************************************************************************/
{
  static const char      *funcs = "marpaESLIFLua_marpaESLIF_versionMinori";
  marpaESLIFLuaContext_t *marpaESLIFLuaContextp;
  int                     minori;
  int                     rci;
  int                     typei;
  int                     topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: version(marpaESLIFp)");
    goto err;
  }

  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL, L, 1, "marpaESLIFLuaContextp")) goto err;   /* Stack: marpaESLIFTable, marpaESLIFLuaContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 2)) goto err;   /* Stack: */

  if (! marpaESLIF_versionMinorb(marpaESLIFLuaContextp->marpaESLIFp, &minori)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIF_versionMinorb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) minori)) goto err;

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int marpaESLIFLua_marpaESLIF_versionPatchi(lua_State *L)
/****************************************************************************/
{
  static const char      *funcs = "marpaESLIFLua_marpaESLIF_versionPatchi";
  marpaESLIFLuaContext_t *marpaESLIFLuaContextp;
  int                     patchi;
  int                     rci;
  int                     typei;
  int                     topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: version(marpaESLIFp)");
    goto err;
  }

  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaContextp")) goto err;   /* Stack: marpaESLIFTable, marpaESLIFLuaContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 2)) goto err;   /* Stack: */

  if (! marpaESLIF_versionPatchb(marpaESLIFLuaContextp->marpaESLIFp, &patchi)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIF_versionPatchb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) patchi)) goto err;

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

#ifdef MARPAESLIFLUA_EMBEDDED
/****************************************************************************/
static int  marpaESLIFLua_marpaESLIF_newFromUnmanagedi(lua_State *L, marpaESLIF_t *marpaESLIFUnmanagedp)
/****************************************************************************/
{
  static const char      *funcs                  = "marpaESLIFLua_marpaESLIF_newFromUnmanagedi";
  marpaESLIFLuaContext_t  *marpaESLIFLuaContextp = NULL;

  marpaESLIFLuaContextp = malloc(sizeof(marpaESLIFLuaContext_t));
  if (marpaESLIFLuaContextp == NULL) {
    marpaESLIFLua_luaL_errorf(L, "malloc failure, %s\n", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_contextInitb(L, marpaESLIFLuaContextp, 1 /* unmanagedb */)) goto err;

  marpaESLIFLuaContextp->marpaESLIFp = marpaESLIFUnmanagedp;

  /* Push marpaESLIF object */
  MARPAESLIFLUA_PUSH_MARPAESLIF_OBJECT(L, marpaESLIFLuaContextp);

  return 1;
 err:
  return 0;
}
#endif /* MARPAESLIFLUA_EMBEDDED */

/****************************************************************************/
static void marpaESLIFLua_stackdumpv(lua_State* L, int forcelookupi)
/****************************************************************************/
/* Reference: https://groups.google.com/forum/#!topic/lua5/gc3Ghjo6ipg      */
/****************************************************************************/
{
  int topi   = lua_gettop(L);
  int starti = forcelookupi ? forcelookupi : 1;
  int endi   = forcelookupi ? forcelookupi : topi;
  int i;
  int t;

  if (! forcelookupi) {
    printf("total in stack %d\n", topi);
  }
  
  for (i = starti; i <= endi; i++) {

    t = lua_type(L, i); /* We voluntarily do not use luaunpanic */
    switch (t) {
    case LUA_TNIL:
      printf("  [%d] nil\n", i);
      break;
    case LUA_TNUMBER:
      printf("  [%d] number: %f\n", i, (double) lua_tonumber(L, i));
      break;
    case LUA_TBOOLEAN:
      printf("  [%d] boolean %s\n", i, lua_toboolean(L, i) ? "true" : "false");
      break;
    case LUA_TUSERDATA:
      printf("  [%d] userdata: %p\n", i, lua_touserdata(L, i));
      break;
    case LUA_TLIGHTUSERDATA:
      printf("  [%d] light userdata: %p\n", i, lua_touserdata(L, i));
      break;
    case LUA_TSTRING:
      printf("  [%d] string: '%s'\n", i, lua_tostring(L, i));
      break;
    default:  /* other values */
      printf("  [%d] %s\n", i, lua_typename(L, t));
      break;
    }
  }
  fflush(stdout);
}

/****************************************************************************/
static void marpaESLIFLua_tabledumpv(lua_State *L, const char *texts, int indicei, unsigned int identi)
/****************************************************************************/
/* Copy of https://github.com/Tieske/Lua_library_template/blob/master/udtype_example/udtype.c */
/****************************************************************************/
{
  const char *keys;
  const char *values;
  int         absindicei;

  absindicei = lua_absindex(L, indicei);

  if (texts != NULL) {
    fprintf(stdout, "[%s] table at indice %d (absolute indice %d, identi=%d)\n", texts, indicei, absindicei, identi);
  }

  lua_pushvalue(L, indicei);                                  /* Stack: ..., table */
  lua_pushnil(L);                                             /* Stack: ..., table, nil */
  while (lua_next(L,-2) != 0) {                               /* Stack: ..., table, key, value */
    keys = luaL_tolstring(L, -2, NULL);                       /* Stack: ..., table, key, value, keys */
    switch (lua_type(L, -2)) {
    case LUA_TTABLE:
      /* fprintf(stdout, "%*s%25s = { (%s)\n", identi, " ", keys, lua_typename(L, lua_type(L, -3))); */
      /* More lisibile without the typename IMHO */
      fprintf(stdout, "%*s%25s = {\n", identi, " ", keys);
      marpaESLIFLua_tabledumpv(L, NULL, -2, identi + 2);
      fprintf(stdout, "%*s%25s   }\n", identi, " ", " ");
      break;
    default:
      values = luaL_tolstring(L, -2, NULL);                   /* Stack: ..., table, key, value, keys, values */
      /* fprintf(stdout, "%*s%25s = %s (%s = %s)\n", identi, " ", keys, values, lua_typename(L, lua_type(L, -4)), lua_typename(L, lua_type(L, -3))); */
      /* More lisibile without the typename IMHO */
      fprintf(stdout, "%*s%25s = %s\n", identi, " ", keys, values);
      lua_pop(L, 1);                                          /* Stack: ..., table, key, value, keys */
      break;
    }
    lua_pop(L, 2);                                            /* Stack: ..., table, key */
  }                                                           /* Stack: ..., table */
  lua_pop(L, 1);                                              /* Stack: ... */

  if (lua_getmetatable(L, indicei)) {
    fprintf(stdout, "%*s%25s = {\n", identi, " ", "<metatable>");
    marpaESLIFLua_tabledumpv(L, NULL, -1, identi + 2);        /* Stack: ..., metatable */
    fprintf(stdout, "%*s%25s   }\n", identi, " ", " ");
    lua_pop(L, 1);                                            /* Stack: ... */
  }

  fflush(stdout);

  --identi;
}

/****************************************************************************/
static void marpaESLIFLua_tabledump_usingpairsv(lua_State *L, const char *texts, int indicei, unsigned int identi)
/****************************************************************************/
/* Copy of https://github.com/Tieske/Lua_library_template/blob/master/udtype_example/udtype.c */
/****************************************************************************/
{
  const char *keys;
  const char *values;
  int         absindicei;
  int         nexti;
  int         iteratori;
  int         statevariablei;
  int         getmetai;

  absindicei = lua_absindex(L, indicei);

  if (texts != NULL) {
    fprintf(stdout, "[%s] table at indice %d (absolute indice %d, identi=%d)\n", texts, indicei, absindicei, identi);
  }

  lua_pushvalue(L, indicei);                                  /* Stack: ..., table */
  lua_pushnil(L);                                             /* Stack: ..., table, nil */
  while (1) {
    marpaESLIFLua_pairsb(&nexti, L, -2, &iteratori, &statevariablei);
    if (! nexti) break;
    keys = luaL_tolstring(L, -2, NULL);                       /* Stack: ..., table, key, value, keys */
    switch (lua_type(L, -2)) {
    case LUA_TTABLE:
      /* Does it have a __tostring metamethod ? */
      getmetai = luaL_getmetafield(L, -2, "__tostring");
      if (getmetai != LUA_TNIL) {
	lua_pop(L, 1);
	values = luaL_tolstring(L, -2, NULL);                   /* Stack: ..., table, key, value, keys, values */
	fprintf(stdout, "%*s%25s = {} __tostring=%s\n", identi, " ", keys, values);
	lua_pop(L, 1);                                          /* Stack: ..., table, key, value, keys */
      } else {
	fprintf(stdout, "%*s%25s = {\n", identi, " ", keys);
	marpaESLIFLua_tabledump_usingpairsv(L, NULL, -2, identi + 2);
	fprintf(stdout, "%*s%25s   }\n", identi, " ", " ");
      }
      break;
    default:
      values = luaL_tolstring(L, -2, NULL);                   /* Stack: ..., table, key, value, keys, values */
      /* fprintf(stdout, "%*s%25s = %s (%s = %s)\n", identi, " ", keys, values, lua_typename(L, lua_type(L, -4)), lua_typename(L, lua_type(L, -3))); */
      /* More lisibile without the typename IMHO */
      fprintf(stdout, "%*s%25s = %s\n", identi, " ", keys, values);
      lua_pop(L, 1);                                          /* Stack: ..., table, key, value, keys */
      break;
    }
    lua_pop(L, 2);                                            /* Stack: ..., table, key */
  }                                                           /* Stack: ..., table */
  lua_pop(L, 1);                                              /* Stack: ... */

  /*
  if (lua_getmetatable(L, indicei)) {
    fprintf(stdout, "%*s%25s = {\n", identi, " ", "<metatable>");
    marpaESLIFLua_tabledump_usingpairsv(L, NULL, -1, identi + 2);
    fprintf(stdout, "%*s%25s   }\n", identi, " ", " ");
    lua_pop(L, 1);
  }
  */

  fflush(stdout);

  --identi;
}

/****************************************************************************/
static short marpaESLIFLua_paramIsLoggerInterfaceOrNilb(lua_State *L, int stacki)
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_paramIsLoggerInterfaceOrNilb";
  static const char *loggerFunctions[] = {
    "trace",
    "debug",
    "info",
    "notice",
    "warning",
    "error",
    "critical",
    "emergency"
  };
  int                i;
  short              loggerb;
  int                typei;

  if (! marpaESLIFLua_lua_type(&typei, L, stacki)) goto err;
  if (typei == LUA_TNIL) {
    loggerb = 0;
  } else {
    /* Verify that the logger can do all wanted methods */
    if (typei != LUA_TTABLE) {
      marpaESLIFLua_luaL_error(L, "logger interface must be a table");
      goto err;
    }
    for (i = 0; i < sizeof(loggerFunctions)/sizeof(loggerFunctions[0]); i++) {
      if (! marpaESLIFLua_lua_getfield(NULL,L, stacki, loggerFunctions[i])) goto err;                             /* Stack: stack1, ..., stacki, field */
      if (! marpaESLIFLua_lua_type(&typei, L, -1)) goto err;
      if (typei != LUA_TFUNCTION) {
        if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                           /* Stack: stack1, ..., stacki */
        marpaESLIFLua_luaL_errorf(L, "logger table must have a field named '%s' that is a function", loggerFunctions[i]);
        goto err;
      } else {
        if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                           /* Stack: stack1, ..., stacki */
      }
    }
    loggerb = 1;
  }

  return loggerb;

 err:
  return 0;
}

/****************************************************************************/
static short marpaESLIFLua_paramIsRecognizerInterfacev(lua_State *L, int stacki)
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_paramIsRecognizerInterfacev";
  static const char *recognizerFunctions[] = {
    "read",
    "isEof",
    "isCharacterStream",
    "encoding",
    "data",
    "isWithDisableThreshold",
    "isWithExhaustion",
    "isWithNewline",
    "isWithTrack"
  };
  int                i;
  int                typei;

  /* Verify that the recognizer can do all wanted methods */
  if (! marpaESLIFLua_lua_type(&typei, L, stacki)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "recognizer interface must be a table");
    goto err;
  }
  for (i = 0; i < sizeof(recognizerFunctions)/sizeof(recognizerFunctions[0]); i++) {
    if (! marpaESLIFLua_lua_getfield(NULL,L, stacki, recognizerFunctions[i])) goto err;                             /* Stack: stack1, ..., stacki, field */
    if (! marpaESLIFLua_lua_type(&typei, L, -1)) goto err;
    if (typei != LUA_TFUNCTION) {
      if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                               /* Stack: stack1, ..., stacki */
      marpaESLIFLua_luaL_errorf(L, "recognizer table must have a field named '%s' that is a function", recognizerFunctions[i]);
      goto err;
    } else {
      if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                               /* Stack: stack1, ..., stacki */
    }
  }

  return 1;

 err:
  return 0;
}

/****************************************************************************/
static short marpaESLIFLua_paramIsValueInterfacev(lua_State *L, int stacki)
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_paramIsValueInterfacev";
  static const char *valueFunctions[] = {
    "isWithHighRankOnly",
    "isWithOrderByRank",
    "isWithAmbiguous",
    "isWithNull",
    "maxParses",
    "setResult",
    "getResult"
  };
  int                i;
  int                typei;

  /* Verify that the recognizer can do all wanted methods */
  if (! marpaESLIFLua_lua_type(&typei, L, stacki)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "value interface must be a table");
    goto err;
  }
  for (i = 0; i < sizeof(valueFunctions)/sizeof(valueFunctions[0]); i++) {
    if (! marpaESLIFLua_lua_getfield(NULL,L, stacki, valueFunctions[i])) goto err;                             /* Stack: stack1, ..., stacki, field */
    if (! marpaESLIFLua_lua_type(&typei, L, -1)) goto err;
    if (typei != LUA_TFUNCTION) {
      if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                          /* Stack: stack1, ..., stacki */
      marpaESLIFLua_luaL_errorf(L, "value table must have a field named '%s' that is a function", valueFunctions[i]);
      goto err;
    } else {
      if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                          /* Stack: stack1, ..., stacki */
    }
  }

  return 1;

 err:
  return 0;
}

/****************************************************************************/
static short marpaESLIFLua_contextInitb(lua_State *L, marpaESLIFLuaContext_t *marpaESLIFLuaContextp, short unmanagedb /* not used */)
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_contextInitb";

  marpaESLIFLuaContextp->marpaESLIFp = NULL;
  marpaESLIFLuaContextp->multitonb   = 0;

  return 1;
}

/****************************************************************************/
static void marpaESLIFLua_contextFreev(marpaESLIFLuaContext_t *marpaESLIFLuaContextp, short multitonDestroyModeb)
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_contextFreev";

  if (marpaESLIFLuaContextp != NULL) {
    if (multitonDestroyModeb) {
      /* We own everything - no need for checks */
      if (marpaESLIFLuaContextp->marpaESLIFp != NULL) {
	marpaESLIF_freev(marpaESLIFLuaContextp->marpaESLIFp);
      }
      free(marpaESLIFLuaContextp);
    } else {
      /* We have to free the structure and only it when this is an unmanaged marpaESLIFp */
      if (! marpaESLIFLuaContextp->multitonb) {
        free(marpaESLIFLuaContextp);
      }
    }
  }
}

/****************************************************************************/
static short marpaESLIFLua_grammarContextInitb(lua_State *L, marpaESLIF_t *marpaESLIFp, int eslifStacki, marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp, short unmanagedb)
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_grammarContextInitb";

  marpaESLIFLuaGrammarContextp->L           = L;
  marpaESLIFLuaGrammarContextp->marpaESLIFp = marpaESLIFp;
  /* Get eslif reference - required */
  if (eslifStacki != 0) {
    if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                                   /* Stack: xxx, nil */
    if (! marpaESLIFLua_lua_copy(L, eslifStacki, -1)) goto err;                                     /* Stack: xxx, eslif */
    MARPAESLIFLUA_REF(L, marpaESLIFLuaGrammarContextp->eslif_r);      /* Stack: xxx */
  } else {
    if (unmanagedb) {
      marpaESLIFLuaGrammarContextp->eslif_r = LUA_NOREF;
    } else {
      marpaESLIFLua_luaL_error(L, "eslifStacki must be != 0");
      goto err;
    }
  }

  marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp = NULL;
  marpaESLIFLuaGrammarContextp->managedb           = 0;

  return 1;

 err:
  return 0;
}

/****************************************************************************/
static short  marpaESLIFLua_recognizerContextInitb(lua_State *L, marpaESLIF_t *marpaESLIFp, int grammarStacki, int recognizerInterfaceStacki, int recognizerOrigStacki, marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp, short unmanagedb)
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_recognizerContextInitb";

  marpaESLIFLuaRecognizerContextp->L           = L;
  marpaESLIFLuaRecognizerContextp->marpaESLIFp = marpaESLIFp;
  /* Get grammar reference - required */
  if (grammarStacki != 0) {
    if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                                   /* Stack: xxx, nil */
    if (! marpaESLIFLua_lua_copy(L, grammarStacki, -1)) goto err;                                   /* Stack: xxx, grammarTable */
    MARPAESLIFLUA_REF(L, marpaESLIFLuaRecognizerContextp->grammar_r); /* Stack: xxx */
  } else {
    if (unmanagedb) {
      marpaESLIFLuaRecognizerContextp->grammar_r = LUA_NOREF;
    } else {
      marpaESLIFLua_luaL_error(L, "grammarStacki must be != 0");
      goto err;
    }
  }
  /* Get recognizer reference - optional */
  if (recognizerInterfaceStacki != 0) {
    if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                                    /* Stack: xxx, nil */
    if (! marpaESLIFLua_lua_copy(L, recognizerInterfaceStacki, -1)) goto err;                        /* Stack: xxx, recognizerInterface */
    MARPAESLIFLUA_REF(L, marpaESLIFLuaRecognizerContextp->recognizerInterface_r);            /* Stack: xxx */
  } else {
    marpaESLIFLuaRecognizerContextp->recognizerInterface_r = LUA_NOREF;
  }
  /* Get original recognizer reference (in case of newFrom()) - optional */
  if (recognizerOrigStacki != 0) {
    if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                                           /* Stack: xxx, nil */
    if (! marpaESLIFLua_lua_copy(L, recognizerOrigStacki, -1)) goto err;                                    /* Stack: xxx, recognizerOrigInterface */
    MARPAESLIFLUA_REF(L, marpaESLIFLuaRecognizerContextp->recognizer_orig_r); /* Stack: xxx */
  } else {
    marpaESLIFLuaRecognizerContextp->recognizer_orig_r = LUA_NOREF;
  }
  marpaESLIFLuaRecognizerContextp->previousInputs        = NULL;
  marpaESLIFLuaRecognizerContextp->previousEncodings     = NULL;
  marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp = NULL;
  marpaESLIFLuaRecognizerContextp->managedb              = 0;

  return 1;

 err:
  return 0;
}

/****************************************************************************/
static void marpaESLIFLua_grammarContextFreev(marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp, short onStackb)
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_grammarContextFreev";
  lua_State         *L;

  if (marpaESLIFLuaGrammarContextp != NULL) {
    L = marpaESLIFLuaGrammarContextp->L;

    if (marpaESLIFLuaGrammarContextp->eslif_r != LUA_NOREF) {
      MARPAESLIFLUA_UNREF(L, marpaESLIFLuaGrammarContextp->eslif_r);
    }

    if (marpaESLIFLuaGrammarContextp->managedb) {
      if (marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp != NULL) {
	marpaESLIFGrammar_freev(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp);
	marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp = NULL;
      }
      marpaESLIFLuaGrammarContextp->managedb = 0;
    } else {
      marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp = NULL;
    }

    if (! onStackb) {
      free(marpaESLIFLuaGrammarContextp);
    }
  }

 err: /* Because of MARPAESLIFLUA_UNREF */
  return;
}

/****************************************************************************/
static void  marpaESLIFLua_recognizerContextCleanupv(marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp)
/****************************************************************************/
{
  if (marpaESLIFLuaRecognizerContextp != NULL) {
    if (marpaESLIFLuaRecognizerContextp->previousInputs != NULL) {
      free(marpaESLIFLuaRecognizerContextp->previousInputs);
      marpaESLIFLuaRecognizerContextp->previousInputs = NULL;
    }
    if (marpaESLIFLuaRecognizerContextp->previousEncodings != NULL) {
      free(marpaESLIFLuaRecognizerContextp->previousEncodings);
      marpaESLIFLuaRecognizerContextp->previousEncodings = NULL;
    }
  }
}

/****************************************************************************/
static void  marpaESLIFLua_recognizerContextFreev(marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp, short onStackb)
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_recognizerContextFreev";
  lua_State         *L;

  if (marpaESLIFLuaRecognizerContextp != NULL) {
    L = marpaESLIFLuaRecognizerContextp->L;

    marpaESLIFLua_recognizerContextCleanupv(marpaESLIFLuaRecognizerContextp);

    if (marpaESLIFLuaRecognizerContextp->grammar_r != LUA_NOREF) {
      MARPAESLIFLUA_UNREF(L, marpaESLIFLuaRecognizerContextp->grammar_r);
    }

    if (marpaESLIFLuaRecognizerContextp->recognizerInterface_r != LUA_NOREF) {
      MARPAESLIFLUA_UNREF(L, marpaESLIFLuaRecognizerContextp->recognizerInterface_r);
    }

    if (marpaESLIFLuaRecognizerContextp->recognizer_orig_r != LUA_NOREF) {
      MARPAESLIFLUA_UNREF(L, marpaESLIFLuaRecognizerContextp->recognizer_orig_r);
    }

    if (marpaESLIFLuaRecognizerContextp->managedb) {
      if (marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp != NULL) {
	marpaESLIFRecognizer_freev(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp);
	marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp = NULL;
      }
      marpaESLIFLuaRecognizerContextp->managedb = 0;
    } else {
      marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp = NULL;
    }

    if (! onStackb) {
      free(marpaESLIFLuaRecognizerContextp);
    }
  }

 err: /* Because of MARPAESLIFLUA_UNREF */
  return;
}

/****************************************************************************/
static void  marpaESLIFLua_valueContextCleanupv(marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp)
/****************************************************************************/
{
  if (marpaESLIFLuaValueContextp != NULL) {
    if (marpaESLIFLuaValueContextp->previous_strings != NULL) {
      free(marpaESLIFLuaValueContextp->previous_strings);
      marpaESLIFLuaValueContextp->previous_strings = NULL;
    }
    if (marpaESLIFLuaValueContextp->previous_encodings != NULL) {
      free(marpaESLIFLuaValueContextp->previous_encodings);
      marpaESLIFLuaValueContextp->previous_encodings = NULL;
    }
  }
}

/****************************************************************************/
static void  marpaESLIFLua_valueContextFreev(marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp, short onStackb)
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_valueContextFreev";
  lua_State         *L;

  if (marpaESLIFLuaValueContextp != NULL) {
    L = marpaESLIFLuaValueContextp->L;

    marpaESLIFLua_valueContextCleanupv(marpaESLIFLuaValueContextp);

    /* Decrement dependencies */
    if (marpaESLIFLuaValueContextp->valueInterface_r != LUA_NOREF) {
      MARPAESLIFLUA_UNREF(L, marpaESLIFLuaValueContextp->valueInterface_r);
    }
    if (marpaESLIFLuaValueContextp->recognizerInterface_r != LUA_NOREF) {
      MARPAESLIFLUA_UNREF(L, marpaESLIFLuaValueContextp->recognizerInterface_r);
    }
    if (marpaESLIFLuaValueContextp->grammar_r != LUA_NOREF) {
      MARPAESLIFLUA_UNREF(L, marpaESLIFLuaValueContextp->grammar_r);
    }

    if (marpaESLIFLuaValueContextp->managedb) {
      if (marpaESLIFLuaValueContextp->marpaESLIFValuep != NULL) {
        marpaESLIFValue_freev(marpaESLIFLuaValueContextp->marpaESLIFValuep);
        marpaESLIFLuaValueContextp->marpaESLIFValuep = NULL;
      }
      marpaESLIFLuaValueContextp->managedb = 0;
    } else {
      marpaESLIFLuaValueContextp->marpaESLIFValuep = NULL;
    }

    if (! onStackb) {
      free(marpaESLIFLuaValueContextp);
    }
  }

 err: /* Because of MARPAESLIFLUA_UNREF */
  return;
}

/****************************************************************************/
static short  marpaESLIFLua_valueContextInitb(lua_State *L, marpaESLIF_t *marpaESLIFp, int grammarStacki, int recognizerStacki, int valueInterfaceStacki, marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp, short unmanagedb, short grammarStackiCanBeZerob)
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_valueContextInitb";

  marpaESLIFLuaValueContextp->L           = L;
  marpaESLIFLuaValueContextp->marpaESLIFp = marpaESLIFp;

  /* Get value reference - required */
  if (valueInterfaceStacki != 0) {
    if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                                 /* Stack: xxx, nil */
    if (! marpaESLIFLua_lua_copy(L, valueInterfaceStacki, -1)) goto err;                          /* Stack: xxx, valueInterface */
    MARPAESLIFLUA_REF(L, marpaESLIFLuaValueContextp->valueInterface_r);                   /* Stack: xxx */
  } else {
    if (unmanagedb) {
      marpaESLIFLuaValueContextp->valueInterface_r = LUA_NOREF;
    } else {
      marpaESLIFLua_luaL_error(L, "valueInterfaceStacki must be != 0");
      goto err;
    }
  }
  /* Get recognizer reference - optional */
  if (recognizerStacki != 0) {
    if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                                 /* Stack: xxx, nil */
    if (! marpaESLIFLua_lua_copy(L, recognizerStacki, -1)) goto err;                              /* Stack: xxx, recognizer */
    MARPAESLIFLUA_REF(L, marpaESLIFLuaValueContextp->recognizerInterface_r);                      /* Stack: xxx */
  } else {
    /* Allowed to be unset when we come from parse */
    marpaESLIFLuaValueContextp->recognizerInterface_r = LUA_NOREF;
  }
  /* Get grammar reference - optional */
  if (grammarStacki != 0) {
    if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                                 /* Stack: xxx, nil */
    if (! marpaESLIFLua_lua_copy(L, grammarStacki, -1)) goto err;                                 /* Stack: xxx, grammar */
    MARPAESLIFLUA_REF(L, marpaESLIFLuaValueContextp->grammar_r);                                  /* Stack: xxx */
  } else {
    if (unmanagedb || grammarStackiCanBeZerob) { /* When we come for grammar parse(), it is legal to have grammarStacki == 0 */
      marpaESLIFLuaValueContextp->grammar_r = LUA_NOREF;
    } else {
      marpaESLIFLua_luaL_error(L, "grammarStacki must be != 0");
      goto err;
    }
  }
  marpaESLIFLuaValueContextp->actions            = NULL;
  marpaESLIFLuaValueContextp->previous_strings   = NULL;
  marpaESLIFLuaValueContextp->previous_encodings = NULL;
  marpaESLIFLuaValueContextp->marpaESLIFValuep   = NULL;
  marpaESLIFLuaValueContextp->managedb           = 0;
  marpaESLIFLuaValueContextp->symbols            = NULL;
  marpaESLIFLuaValueContextp->symboli            = -1;
  marpaESLIFLuaValueContextp->rules              = NULL;
  marpaESLIFLuaValueContextp->rulei              = -1;

  return 1;

 err:
  return 0;
}

/****************************************************************************/
static void marpaESLIFLua_genericLoggerCallbackv(void *userDatavp, genericLoggerLevel_t logLeveli, const char *msgs)
/****************************************************************************/
{
  static const char                   *funcs = "marpaESLIFLua_genericLoggerCallbackv";
  marpaESLIFLuaGenericLoggerContext_t *marpaESLIFLuaGenericLoggerContextp = (marpaESLIFLuaGenericLoggerContext_t *) userDatavp;
  int                                  logger_r             = marpaESLIFLuaGenericLoggerContextp->logger_r;
  lua_State                           *L                    = marpaESLIFLuaGenericLoggerContextp->L;
  const char                          *loggerfuncs;

  switch (logLeveli) {
  case GENERICLOGGER_LOGLEVEL_TRACE:
    loggerfuncs = "trace";
    break;
  case GENERICLOGGER_LOGLEVEL_DEBUG:
    loggerfuncs = "debug";
    break;
  case GENERICLOGGER_LOGLEVEL_INFO:
    loggerfuncs = "info";
    break;
  case GENERICLOGGER_LOGLEVEL_NOTICE:
    loggerfuncs = "notice";
    break;
  case GENERICLOGGER_LOGLEVEL_WARNING:
    loggerfuncs = "warning";
    break;
  case GENERICLOGGER_LOGLEVEL_ERROR:
    loggerfuncs = "error";
    break;
  case GENERICLOGGER_LOGLEVEL_CRITICAL:
    loggerfuncs = "critical";
    break;
  case GENERICLOGGER_LOGLEVEL_ALERT:
    loggerfuncs = "alert";
    break;
  case GENERICLOGGER_LOGLEVEL_EMERGENCY:
    loggerfuncs = "emergency";
    break;
  default:
    loggerfuncs = NULL;
    break;
  }

  if (loggerfuncs != NULL) {
    MARPAESLIFLUA_CALLBACKV(L, logger_r, loggerfuncs, 1 /* nargs */, if (! marpaESLIFLua_lua_pushstring(NULL, L, msgs)) goto err;);
  }

 err:
  return;
}

/****************************************************************************/
static int marpaESLIFLua_marpaESLIFMultitonsTable_freei(lua_State *L)
/****************************************************************************/
{
  static const char                   *funcs                              = "marpaESLIFLua_marpaESLIFMultitonsTable_freei";
  marpaESLIFLuaContext_t              *marpaESLIFLuaContextp              = NULL;
  marpaESLIFLuaGenericLoggerContext_t *marpaESLIFLuaGenericLoggerContextp = NULL;
  lua_Integer                          logger_r                           = LUA_NOREF;
  genericLogger_t                     *genericLoggerp                     = NULL;
  marpaESLIFOption_t                  *marpaESLIFOptionp;
  int                                  nexti;
  int                                  iteratori;
  int                                  statevariablei;

  /* Loop on MARPAESLIFMULTITONSTABLE */
  if (! marpaESLIFLua_lua_pushnil(L)) goto err;                       /* Stack: MARPAESLIFMULTITONSTABLE, nil */
  while (1) {
    if (! marpaESLIFLua_pairsb(&nexti, L, -2, &iteratori, &statevariablei)) goto err; /* Stack: MARPAESLIFMULTITONSTABLE, marpaESLIFLuaContextp, r */
    if (nexti == 0) break;
    if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaContextp, L, -2)) goto err;
    if (! marpaESLIFLua_lua_tointeger(&logger_r, L, -1)) goto err;

    if (logger_r != LUA_NOREF) {

      marpaESLIFOptionp = marpaESLIF_optionp(marpaESLIFLuaContextp->marpaESLIFp);
      if (marpaESLIFOptionp != NULL) {
        genericLoggerp = marpaESLIFOptionp->genericLoggerp;
        if (genericLoggerp != NULL) {
          marpaESLIFLuaGenericLoggerContextp = (marpaESLIFLuaGenericLoggerContext_t *) genericLogger_userDatavp_getp(genericLoggerp);
	  if (marpaESLIFLuaGenericLoggerContextp != NULL) {
	    MARPAESLIFLUA_UNREF(L, marpaESLIFLuaGenericLoggerContextp->logger_r); /* By construction marpaESLIFLuaGenericLoggerContextp->logger_r == logger_r */
	    free(marpaESLIFLuaGenericLoggerContextp);
	  }
	  genericLogger_freev(&genericLoggerp);
        }
      }
    }

    marpaESLIFLua_contextFreev(marpaESLIFLuaContextp, 1 /* multitonDestroyModeb */);

    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;        /* Stack: MARPAESLIFMULTITONSTABLE, marpaESLIFLuaContextp */
  }

  return 0;

 err:
  return 0;
}

#ifdef MARPAESLIFLUA_USE_INTERNALREGISTRYINDEX
/****************************************************************************/
static int marpaESLIFLua_marpaESLIFRegistryindex_freei(lua_State *L)
/****************************************************************************/
{
  static const char      *funcs = "marpaESLIFLua_marpaESLIFRegistryindex_freei";

  return 0;
}
#endif /* MARPAESLIFLUA_USE_INTERNALREGISTRYINDEX */

/****************************************************************************/
static int marpaESLIFLua_marpaESLIFGrammar_newi(lua_State *L)
/****************************************************************************/
{
  static const char              *funcs = "marpaESLIFLua_marpaESLIFGrammar_newi";
  marpaESLIFLuaContext_t         *marpaESLIFLuaContextp;
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  marpaESLIFGrammarOption_t      marpaESLIFGrammarOption = {
    NULL, /* bytep */
    0,    /* bytel */
    NULL, /* encodings */
    0     /* encodingl */
  };
  int                            typei;
  int                            topi;
  marpaESLIF_t                  *marpaESLIFp;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  switch (topi) {
  case 3:
    if (! marpaESLIFLua_luaL_checklstring((const char **) &(marpaESLIFGrammarOption.encodings), L, 3, &(marpaESLIFGrammarOption.encodingl))) goto err;
    /* Intentionnaly no break */
  case 2:
    if (! marpaESLIFLua_luaL_checklstring((const char **) &(marpaESLIFGrammarOption.bytep), L, 2, &(marpaESLIFGrammarOption.bytel))) goto err;

    if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
    if (typei != LUA_TTABLE) {
      marpaESLIFLua_luaL_error(L, "marpaESLIFp must be a table");
      goto err;
    }

    if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaContextp")) goto err;   /* Stack: ..., marpaESLIFLuaContextp */
    if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaContextp, L, -1)) goto err;
    break;
  default:
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_new(marpaESLIFp, string[, encoding])");
    goto err;
  }

  marpaESLIFLuaGrammarContextp = malloc(sizeof(marpaESLIFLuaGrammarContext_t));
  if (marpaESLIFLuaGrammarContextp == NULL) {
    marpaESLIFLua_luaL_errorf(L, "malloc failure, %s", strerror(errno));
    goto err;
  }

  marpaESLIFp = marpaESLIFLuaContextp->marpaESLIFp;
  if (! marpaESLIFLua_grammarContextInitb(L, marpaESLIFp, 1 /* eslifStacki */, marpaESLIFLuaGrammarContextp, 0 /* unmanagedb */)) goto err;

  marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp = marpaESLIFGrammar_newp(marpaESLIFp, &marpaESLIFGrammarOption);
  if (marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp == NULL) {
    int save_errno = errno;
    marpaESLIFLua_grammarContextFreev(marpaESLIFLuaGrammarContextp, 0 /* onStackb */);
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_newp failure, %s", strerror(save_errno));
    goto err;
  }
  marpaESLIFLuaGrammarContextp->managedb = 1;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  MARPAESLIFLUA_PUSH_MARPAESLIFGRAMMAR_OBJECT(L, marpaESLIFLuaGrammarContextp);

  return 1;

 err:
  return 0;
}

#ifdef MARPAESLIFLUA_EMBEDDED
/****************************************************************************/
static int marpaESLIFLua_marpaESLIFGrammar_newFromUnmanagedi(lua_State *L, marpaESLIFGrammar_t *marpaESLIFGrammarUnmanagedp)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_newFromUnmanagedi";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  marpaESLIF_t                  *marpaESLIFp;

  marpaESLIFLuaGrammarContextp = malloc(sizeof(marpaESLIFLuaGrammarContext_t));
  if (marpaESLIFLuaGrammarContextp == NULL) {
    marpaESLIFLua_luaL_errorf(L, "malloc failure, %s", strerror(errno));
    goto err;
  }

  marpaESLIFp = marpaESLIFGrammar_eslifp(marpaESLIFGrammarUnmanagedp);
  if (! marpaESLIFLua_grammarContextInitb(L, marpaESLIFp, 0 /* eslifStacki */, marpaESLIFLuaGrammarContextp, 1 /* unmanagedb */)) goto err;
  marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp = marpaESLIFGrammarUnmanagedp;
  marpaESLIFLuaGrammarContextp->managedb           = 0;

  MARPAESLIFLUA_PUSH_MARPAESLIFGRAMMAR_OBJECT(L, marpaESLIFLuaGrammarContextp);

  return 1;

 err:
  return 0;
}
#endif /* MARPAESLIFLUA_EMBEDDED */

/****************************************************************************/
static int marpaESLIFLua_marpaESLIFGrammar_freei(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_freei";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;

  if (! marpaESLIFLua_lua_getfield(NULL,L, -1, "marpaESLIFLuaGrammarContextp")) goto err; /* Stack: {...}, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;         /* Stack: {...} */

  marpaESLIFLua_grammarContextFreev(marpaESLIFLuaGrammarContextp, 0 /* onStackb */);

  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;         /* Stack: */

  return 0;

 err:
  return 0;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_ngrammari(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_ngrammari";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  int                            ngrammari;
  int                            rci;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_ngrammar(marpaESLIFGrammarp)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 2)) goto err;          /* Stack: */

  if (! marpaESLIFGrammar_ngrammarib(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, &ngrammari)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_ngrammarib failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) ngrammari)) goto err;   /* Stack: ngrammari */

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_currentLeveli(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_currentLeveli";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  int                            leveli;
  int                            rci;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_currentLevel(marpaESLIFGrammarp)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 2)) goto err;          /* Stack: */

  if (! marpaESLIFGrammar_grammar_currentb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, &leveli, NULL)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_grammar_currentb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) leveli)) goto err;   /* Stack: ngrammari */

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_currentDescriptioni(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_currentDescriptioni";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  marpaESLIFString_t            *descp;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_currentDescription(marpaESLIFGrammarp)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 2)) goto err;          /* Stack: */

  if (! marpaESLIFGrammar_grammar_currentb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, NULL, &descp)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_grammar_currentb failure, %s", strerror(errno));
    goto err;
  }
  if (! marpaESLIFLua_lua_pushlstring(NULL, L, (const char *) descp->bytep, descp->bytel)) goto err;

  return 1;

 err:
  return 0;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_descriptionByLeveli(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_descriptionByLeveli";
  lua_Integer                    leveli;
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  marpaESLIFString_t            *descp;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_descriptionByLevel(marpaESLIFGrammarp, leveli)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, leveli, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&leveli, L, 2)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 3)) goto err;          /* Stack: */

  if (! marpaESLIFGrammar_grammar_by_levelb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, (int) leveli, NULL, NULL, &descp)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_grammar_by_levelb failure, %s", strerror(errno));
    goto err;
  }
  if (! marpaESLIFLua_lua_pushlstring(NULL, L, (const char *) descp->bytep, descp->bytel)) goto err;

  return 1;

 err:
  return 0;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_currentRuleIdsi(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_currentRuleIdsi";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  int                           *ruleip;
  size_t                         rulel;
  int                            rci;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_currentRuleIds(marpaESLIFGrammarp)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 2)) goto err;          /* Stack: */

  if (! marpaESLIFGrammar_rulearray_currentb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, &ruleip, &rulel)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_rulearray_currentb failure, %s", strerror(errno));
    goto err;
  }
  if (rulel <= 0) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammar_rulearray_currentb returned no rule");
    goto err;
  }

  MARPAESLIFLUA_PUSH_INTEGER_ARRAY(L, rulel, ruleip);

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_ruleIdsByLeveli(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_ruleIdsByLeveli";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  lua_Integer                    leveli;
  int                           *ruleip;
  size_t                         rulel;
  int                            rci;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_ruleIdsByLevel(marpaESLIFGrammarp, leveli)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, leveli, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&leveli, L, 2)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 3)) goto err;          /* Stack: */

  if (! marpaESLIFGrammar_rulearray_by_levelb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, &ruleip, &rulel, (int) leveli, NULL)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_rulearray_by_levelb failure, %s", strerror(errno));
    goto err;
  }
  if (rulel <= 0) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammar_rulearray_by_levelb returned no rule");
    goto err;
  }

  MARPAESLIFLUA_PUSH_INTEGER_ARRAY(L, rulel, ruleip);

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_currentSymbolIdsi(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_currentSymbolIdsi";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  int                           *symbolip;
  size_t                         symboll;
  int                            rci;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_currentSymbolIds(marpaESLIFGrammarp)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 2)) goto err;          /* Stack: */

  if (! marpaESLIFGrammar_symbolarray_currentb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, &symbolip, &symboll)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_symbolarray_currentb failure, %s", strerror(errno));
    goto err;
  }
  if (symboll <= 0) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammar_symbolarray_currentb returned no symbol");
    goto err;
  }

  MARPAESLIFLUA_PUSH_INTEGER_ARRAY(L, symboll, symbolip);

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_symbolIdsByLeveli(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_symbolIdsByLeveli";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  lua_Integer                    leveli;
  int                           *symbolip;
  size_t                         symboll;
  int                            rci;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_symbolIdsByLevel(marpaESLIFGrammarp, leveli)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, leveli, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&leveli, L, 2)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 3)) goto err;          /* Stack: */

  if (! marpaESLIFGrammar_symbolarray_by_levelb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, &symbolip, &symboll, (int) leveli, NULL)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_symbolarray_by_levelb failure, %s", strerror(errno));
    goto err;
  }
  if (symboll <= 0) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammar_symbolarray_by_levelb returned no symbol");
    goto err;
  }

  MARPAESLIFLUA_PUSH_INTEGER_ARRAY(L, symboll, symbolip);

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_currentPropertiesi(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_currentPropertiesi";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  marpaESLIFGrammarProperty_t    grammarProperty;
  int                            rci;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_currentProperties(marpaESLIFGrammarp)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 2)) goto err;          /* Stack: */

  if (! marpaESLIFGrammar_grammarproperty_currentb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, &grammarProperty)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_grammarproperty_currentb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_createtable(L, 11, 0)) goto err;                                                 /* stack; {} */
  MARPAESLIFLUA_STORE_INTEGER      (L, "level",               grammarProperty.leveli);
  MARPAESLIFLUA_STORE_INTEGER      (L, "maxlevel",            grammarProperty.maxLeveli);
  MARPAESLIFLUA_STORE_STRING       (L, "description",         grammarProperty.descp);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "latm",                grammarProperty.latmb);
  MARPAESLIFLUA_STORE_ACTION       (L, "defaultSymbolAction", grammarProperty.defaultSymbolActionp);
  MARPAESLIFLUA_STORE_ACTION       (L, "defaultRuleAction",   grammarProperty.defaultRuleActionp);
  MARPAESLIFLUA_STORE_INTEGER      (L, "startId",             grammarProperty.starti);
  MARPAESLIFLUA_STORE_INTEGER      (L, "discardId",           grammarProperty.discardi);
  MARPAESLIFLUA_STORE_INTEGER_ARRAY(L, "symbolIds",           grammarProperty.nsymboll, grammarProperty.symbolip);
  MARPAESLIFLUA_STORE_INTEGER_ARRAY(L, "ruleIds",             grammarProperty.nrulel, grammarProperty.ruleip);

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_propertiesByLeveli(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_propertiesByLeveli";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  lua_Integer                    leveli;
  marpaESLIFGrammarProperty_t    grammarProperty;
  int                            rci;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_symbolIdsByLevel(marpaESLIFGrammarp, leveli)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, leveli, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&leveli, L, 2)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 3)) goto err;          /* Stack: */

  if (! marpaESLIFGrammar_grammarproperty_by_levelb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, &grammarProperty, (int) leveli, NULL /* descp */)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_grammarproperty_by_levelb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_createtable(L, 11, 0)) goto err;                                                 /* stack; {} */
  MARPAESLIFLUA_STORE_INTEGER      (L, "level",               grammarProperty.leveli);
  MARPAESLIFLUA_STORE_INTEGER      (L, "maxlevel",            grammarProperty.maxLeveli);
  MARPAESLIFLUA_STORE_STRING       (L, "description",         grammarProperty.descp);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "latm",                grammarProperty.latmb);
  MARPAESLIFLUA_STORE_ACTION       (L, "defaultSymbolAction", grammarProperty.defaultSymbolActionp);
  MARPAESLIFLUA_STORE_ACTION       (L, "defaultRuleAction",   grammarProperty.defaultRuleActionp);
  MARPAESLIFLUA_STORE_INTEGER      (L, "startId",             grammarProperty.starti);
  MARPAESLIFLUA_STORE_INTEGER      (L, "discardId",           grammarProperty.discardi);
  MARPAESLIFLUA_STORE_INTEGER_ARRAY(L, "symbolIds",           grammarProperty.nsymboll, grammarProperty.symbolip);
  MARPAESLIFLUA_STORE_INTEGER_ARRAY(L, "ruleIds",             grammarProperty.nrulel, grammarProperty.ruleip);

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_currentRulePropertiesi(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_currentRulePropertiesi";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  lua_Integer                    rulei;
  marpaESLIFRuleProperty_t       ruleProperty;
  int                            rci;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_currentRuleProperties(marpaESLIFGrammarp, rulei)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, rulei, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&rulei, L, 2)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 3)) goto err;          /* Stack: */

  if (! marpaESLIFGrammar_ruleproperty_currentb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, (int) rulei, &ruleProperty)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_ruleproperty_currentb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_createtable(L, 19, 0)) goto err;                                                 /* stack; {} */
  MARPAESLIFLUA_STORE_INTEGER      (L, "id",                       ruleProperty.idi);
  MARPAESLIFLUA_STORE_STRING       (L, "description",              ruleProperty.descp);
  MARPAESLIFLUA_STORE_ASCIISTRING  (L, "show",                     ruleProperty.asciishows);
  MARPAESLIFLUA_STORE_INTEGER      (L, "lhsId",                    ruleProperty.lhsi);
  MARPAESLIFLUA_STORE_INTEGER      (L, "separatorId",              ruleProperty.separatori);
  MARPAESLIFLUA_STORE_INTEGER_ARRAY(L, "rhsIds",                   ruleProperty.nrhsl, ruleProperty.rhsip);
  MARPAESLIFLUA_STORE_BOOLEAN_ARRAY(L, "skipIndices",              ruleProperty.nrhsl, ruleProperty.skipbp);
  MARPAESLIFLUA_STORE_INTEGER      (L, "exceptionId",              ruleProperty.exceptioni);
  MARPAESLIFLUA_STORE_ACTION       (L, "action",                   ruleProperty.actionp);
  MARPAESLIFLUA_STORE_ASCIISTRING  (L, "discardEvent",             ruleProperty.discardEvents);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "discardEventInitialState", ruleProperty.discardEventb);
  MARPAESLIFLUA_STORE_INTEGER      (L, "rank",                     ruleProperty.ranki);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "nullRanksHigh",            ruleProperty.nullRanksHighb);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "sequence",                 ruleProperty.sequenceb);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "proper",                   ruleProperty.properb);
  MARPAESLIFLUA_STORE_INTEGER      (L, "minimum",                  ruleProperty.minimumi);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "internal",                 ruleProperty.internalb);
  MARPAESLIFLUA_STORE_INTEGER      (L, "propertyBitSet",           ruleProperty.propertyBitSet);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "hideseparator",            ruleProperty.hideseparatorb);

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_rulePropertiesByLeveli(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_rulePropertiesByLeveli";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  lua_Integer                    leveli;
  lua_Integer                    rulei;
  marpaESLIFRuleProperty_t       ruleProperty;
  int                            rci;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 3) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_rulePropertiesByLevel(marpaESLIFGrammarp, leveli, rulei)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, leveli, rulei, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&leveli, L, 2)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&rulei, L, 3)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 4)) goto err;          /* Stack: */

  if (! marpaESLIFGrammar_ruleproperty_by_levelb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, (int) rulei, &ruleProperty, (int) leveli, NULL /* descp */)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_ruleproperty_by_levelb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_createtable(L, 19, 0)) goto err;                                                 /* stack; {} */
  MARPAESLIFLUA_STORE_INTEGER      (L, "id",                       ruleProperty.idi);
  MARPAESLIFLUA_STORE_STRING       (L, "description",              ruleProperty.descp);
  MARPAESLIFLUA_STORE_ASCIISTRING  (L, "show",                     ruleProperty.asciishows);
  MARPAESLIFLUA_STORE_INTEGER      (L, "lhsId",                    ruleProperty.lhsi);
  MARPAESLIFLUA_STORE_INTEGER      (L, "separatorId",              ruleProperty.separatori);
  MARPAESLIFLUA_STORE_INTEGER_ARRAY(L, "rhsIds",                   ruleProperty.nrhsl, ruleProperty.rhsip);
  MARPAESLIFLUA_STORE_BOOLEAN_ARRAY(L, "skipIndices",              ruleProperty.nrhsl, ruleProperty.skipbp);
  MARPAESLIFLUA_STORE_INTEGER      (L, "exceptionId",              ruleProperty.exceptioni);
  MARPAESLIFLUA_STORE_ACTION       (L, "action",                   ruleProperty.actionp);
  MARPAESLIFLUA_STORE_ASCIISTRING  (L, "discardEvent",             ruleProperty.discardEvents);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "discardEventInitialState", ruleProperty.discardEventb);
  MARPAESLIFLUA_STORE_INTEGER      (L, "rank",                     ruleProperty.ranki);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "nullRanksHigh",            ruleProperty.nullRanksHighb);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "sequence",                 ruleProperty.sequenceb);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "proper",                   ruleProperty.properb);
  MARPAESLIFLUA_STORE_INTEGER      (L, "minimum",                  ruleProperty.minimumi);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "internal",                 ruleProperty.internalb);
  MARPAESLIFLUA_STORE_INTEGER      (L, "propertyBitSet",           ruleProperty.propertyBitSet);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "hideseparator",            ruleProperty.hideseparatorb);

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_currentSymbolPropertiesi(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_currentSymbolPropertiesi";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  lua_Integer                    symboli;
  marpaESLIFSymbolProperty_t     symbolProperty;
  int                            rci;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_currentSymbolProperties(marpaESLIFGrammarp, symboli)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, leveli, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&symboli, L, 2)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 3)) goto err;

  if (! marpaESLIFGrammar_symbolproperty_currentb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, (int) symboli, &symbolProperty)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_symbolproperty_currentb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_createtable(L, 24, 0)) goto err;                                                 /* stack; {} */
  MARPAESLIFLUA_STORE_INTEGER      (L, "type",                       symbolProperty.type);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "start",                      symbolProperty.startb);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "discard",                    symbolProperty.discardb);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "discardRhs",                 symbolProperty.discardRhsb);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "lhs",                        symbolProperty.lhsb);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "top",                        symbolProperty.topb);
  MARPAESLIFLUA_STORE_INTEGER      (L, "id",                         symbolProperty.idi);
  MARPAESLIFLUA_STORE_STRING       (L, "description",                symbolProperty.descp);
  MARPAESLIFLUA_STORE_ASCIISTRING  (L, "eventBefore",                symbolProperty.eventBefores);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "eventBeforeInitialState",    symbolProperty.eventBeforeb);
  MARPAESLIFLUA_STORE_ASCIISTRING  (L, "eventAfter",                 symbolProperty.eventAfters);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "eventAfterInitialState",     symbolProperty.eventAfterb);
  MARPAESLIFLUA_STORE_ASCIISTRING  (L, "eventPredicted",             symbolProperty.eventPredicteds);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "eventPredictedInitialState", symbolProperty.eventPredictedb);
  MARPAESLIFLUA_STORE_ASCIISTRING  (L, "eventNulled",                symbolProperty.eventNulleds);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "eventNulledInitialState",    symbolProperty.eventNulledb);
  MARPAESLIFLUA_STORE_ASCIISTRING  (L, "eventCompleted",             symbolProperty.eventCompleteds);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "eventCompletedInitialState", symbolProperty.eventCompletedb);
  MARPAESLIFLUA_STORE_ASCIISTRING  (L, "discardEvent",               symbolProperty.discardEvents);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "discardEventInitialState",   symbolProperty.discardEventb);
  MARPAESLIFLUA_STORE_INTEGER      (L, "lookupResolvedLeveli",       symbolProperty.lookupResolvedLeveli);
  MARPAESLIFLUA_STORE_INTEGER      (L, "priority",                   symbolProperty.priorityi);
  MARPAESLIFLUA_STORE_ACTION       (L, "nullableAction",             symbolProperty.nullableActionp);
  MARPAESLIFLUA_STORE_INTEGER      (L, "propertyBitSet",             symbolProperty.propertyBitSet);
  MARPAESLIFLUA_STORE_INTEGER      (L, "eventBitSet",                symbolProperty.eventBitSet);
  MARPAESLIFLUA_STORE_ACTION       (L, "symbolAction",               symbolProperty.symbolActionp);
  MARPAESLIFLUA_STORE_ACTION       (L, "ifAction",                   symbolProperty.ifActionp);

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_symbolPropertiesByLeveli(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_symbolPropertiesByLeveli";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  lua_Integer                    leveli;
  lua_Integer                    symboli;
  marpaESLIFSymbolProperty_t     symbolProperty;
  int                            rci;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 3) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_symbolPropertiesByLevel(marpaESLIFGrammarp, leveli, symboli)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, leveli, symboli, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&leveli, L, 2)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&symboli, L, 3)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 4)) goto err;

  if (! marpaESLIFGrammar_symbolproperty_by_levelb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, (int) symboli, &symbolProperty, (int) leveli, NULL /* descp */)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_symbolproperty_by_levelb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_createtable(L, 24, 0)) goto err;                                                 /* stack; {} */
  MARPAESLIFLUA_STORE_INTEGER      (L, "type",                       symbolProperty.type);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "start",                      symbolProperty.startb);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "discard",                    symbolProperty.discardb);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "discardRhs",                 symbolProperty.discardRhsb);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "lhs",                        symbolProperty.lhsb);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "top",                        symbolProperty.topb);
  MARPAESLIFLUA_STORE_INTEGER      (L, "id",                         symbolProperty.idi);
  MARPAESLIFLUA_STORE_STRING       (L, "description",                symbolProperty.descp);
  MARPAESLIFLUA_STORE_ASCIISTRING  (L, "eventBefore",                symbolProperty.eventBefores);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "eventBeforeInitialState",    symbolProperty.eventBeforeb);
  MARPAESLIFLUA_STORE_ASCIISTRING  (L, "eventAfter",                 symbolProperty.eventAfters);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "eventAfterInitialState",     symbolProperty.eventAfterb);
  MARPAESLIFLUA_STORE_ASCIISTRING  (L, "eventPredicted",             symbolProperty.eventPredicteds);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "eventPredictedInitialState", symbolProperty.eventPredictedb);
  MARPAESLIFLUA_STORE_ASCIISTRING  (L, "eventNulled",                symbolProperty.eventNulleds);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "eventNulledInitialState",    symbolProperty.eventNulledb);
  MARPAESLIFLUA_STORE_ASCIISTRING  (L, "eventCompleted",             symbolProperty.eventCompleteds);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "eventCompletedInitialState", symbolProperty.eventCompletedb);
  MARPAESLIFLUA_STORE_ASCIISTRING  (L, "discardEvent",               symbolProperty.discardEvents);
  MARPAESLIFLUA_STORE_BOOLEAN      (L, "discardEventInitialState",   symbolProperty.discardEventb);
  MARPAESLIFLUA_STORE_INTEGER      (L, "lookupResolvedLeveli",       symbolProperty.lookupResolvedLeveli);
  MARPAESLIFLUA_STORE_INTEGER      (L, "priority",                   symbolProperty.priorityi);
  MARPAESLIFLUA_STORE_ACTION       (L, "nullableAction",             symbolProperty.nullableActionp);
  MARPAESLIFLUA_STORE_INTEGER      (L, "propertyBitSet",             symbolProperty.propertyBitSet);
  MARPAESLIFLUA_STORE_INTEGER      (L, "eventBitSet",                symbolProperty.eventBitSet);
  MARPAESLIFLUA_STORE_ACTION       (L, "symbolAction",               symbolProperty.symbolActionp);
  MARPAESLIFLUA_STORE_ACTION       (L, "ifAction",                   symbolProperty.ifActionp);

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_ruleDisplayi(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_ruleDisplayi";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  lua_Integer                    rulei;
  char                          *ruleDisplays;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_ruleDisplay(marpaESLIFGrammarp, rulei)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, rulei, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&rulei, L, 2)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 3)) goto err;

  if (! marpaESLIFGrammar_ruledisplayform_currentb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, (int) rulei, &ruleDisplays)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_ruledisplayform_currentb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_pushstring(NULL, L, (const char *) ruleDisplays)) goto err;

  return 1;

 err:
  return 0;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_symbolDisplayi(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_symbolDisplayi";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  lua_Integer                    symboli;
  char                          *symbolDisplays;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_symbolDisplay(marpaESLIFGrammarp, symboli)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, symboli, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&symboli, L, 2)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 3)) goto err;

  if (! marpaESLIFGrammar_symboldisplayform_currentb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, (int) symboli, &symbolDisplays)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_symboldisplayform_currentb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_pushstring(NULL, L, (const char *) symbolDisplays)) goto err;

  return 1;

 err:
  return 0;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_ruleShowi(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_ruleShowi";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  lua_Integer                    rulei;
  char                          *ruleShows;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_ruleShow(marpaESLIFGrammarp, rulei)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, rulei, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&rulei, L, 2)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 3)) goto err;

  if (! marpaESLIFGrammar_ruleshowform_currentb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, (int) rulei, &ruleShows)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_ruleshowform_currentb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_pushstring(NULL, L, (const char *) ruleShows)) goto err;

  return 1;

 err:
  return 0;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_ruleDisplayByLeveli(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_ruleDisplayByLeveli";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  lua_Integer                    leveli;
  lua_Integer                    rulei;
  char                          *ruleDisplays;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 3) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_ruleDisplayByLevel(marpaESLIFGrammarp, leveli, rulei)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, leveli, rulei, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&leveli, L, 2)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&rulei, L, 3)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 4)) goto err;

  if (! marpaESLIFGrammar_ruledisplayform_by_levelb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, (int) rulei, &ruleDisplays, (int) leveli, NULL)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_ruledisplayform_by_levelb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_pushstring(NULL, L, (const char *) ruleDisplays)) goto err;

  return 1;

 err:
  return 0;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_symbolDisplayByLeveli(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_symbolDisplayByLeveli";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  lua_Integer                    leveli;
  lua_Integer                    symboli;
  char                          *symbolDisplays;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 3) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_symbolDisplayByLevel(marpaESLIFGrammarp, leveli, symboli)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, leveli, symboli, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&leveli, L, 2)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&symboli, L, 3)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 4)) goto err;

  if (! marpaESLIFGrammar_symboldisplayform_by_levelb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, (int) symboli, &symbolDisplays, (int) leveli, NULL)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_symboldisplayform_by_levelb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_pushstring(NULL, L, (const char *) symbolDisplays)) goto err;

  return 1;

 err:
  return 0;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_ruleShowByLeveli(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_ruleShowByLeveli";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  lua_Integer                    leveli;
  lua_Integer                    rulei;
  char                          *ruleShows;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 3) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_ruleShowByLevel(marpaESLIFGrammarp, leveli, rulei)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, leveli, rulei, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&leveli, L, 2)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&rulei, L, 3)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 4)) goto err;

  if (! marpaESLIFGrammar_ruleshowform_by_levelb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, (int) rulei, &ruleShows, (int) leveli, NULL)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_ruleshowform_by_levelb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_pushstring(NULL, L, (const char *) ruleShows)) goto err;

  return 1;

 err:
  return 0;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_showi(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_showi";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  char                          *shows;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_show(marpaESLIFGrammarp)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 2)) goto err;

  if (! marpaESLIFGrammar_grammarshowform_currentb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, &shows)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_grammarshowform_currentb failure, %s", strerror(errno));
    goto err;
  }
  if (! marpaESLIFLua_lua_pushstring(NULL, L, (const char *) shows)) goto err;

  return 1;

 err:
  return 0;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_showByLeveli(lua_State *L)
/****************************************************************************/
{
  static const char             *funcs = "marpaESLIFLua_marpaESLIFGrammar_showByLeveli";
  marpaESLIFLuaGrammarContext_t *marpaESLIFLuaGrammarContextp;
  lua_Integer                    leveli;
  char                          *shows;
  int                            typei;
  int                            topi;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_showByLevel(marpaESLIFGrammarp, leveli)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, leveli, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_luaL_checkinteger(&leveli, L, 2)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 3)) goto err;

  if (! marpaESLIFGrammar_grammarshowform_by_levelb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, &shows, (int) leveli, NULL)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFGrammar_grammarshowform_by_levelb failure, %s", strerror(errno));
    goto err;
  }
  if (! marpaESLIFLua_lua_pushstring(NULL, L, (const char *) shows)) goto err;

  return 1;

 err:
  return 0;
}

/****************************************************************************/
static int  marpaESLIFLua_marpaESLIFGrammar_parsei(lua_State *L)
/****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFGrammar_parsei";
  marpaESLIFLuaGrammarContext_t    *marpaESLIFLuaGrammarContextp;
  marpaESLIFLuaRecognizerContext_t  marpaESLIFLuaRecognizerContext;
  marpaESLIFLuaValueContext_t       marpaESLIFLuaValueContext;
  marpaESLIFRecognizerOption_t      marpaESLIFRecognizerOption;
  marpaESLIFValueOption_t           marpaESLIFValueOption;
  int                               rci;
  int                               resultStacki;
  int                               typei;
  int                               topi;
  marpaESLIF_t                     *marpaESLIFp;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 3) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFGrammar_parse(marpaESLIFGrammarp, recognizerInterface, valueInterface)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, recognizerInterface, valueInterface, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  marpaESLIFLua_paramIsRecognizerInterfacev(L, 2);
  marpaESLIFLua_paramIsValueInterfacev(L, 3);

  marpaESLIFp = marpaESLIFLuaGrammarContextp->marpaESLIFp;
  if (! marpaESLIFLua_recognizerContextInitb(L, marpaESLIFp, 1 /* grammarStacki */, 2 /* recognizerInterfaceStacki */, 0 /* recognizerOrigStacki */, &marpaESLIFLuaRecognizerContext, 0 /* unmanagedb */)) goto err;
  if (! marpaESLIFLua_valueContextInitb(L, marpaESLIFp, 1 /* grammarStacki */, 0 /* recognizerStacki */, 3 /* valueInterfaceStacki */, &marpaESLIFLuaValueContext, 0 /* unmanagedb */, 0 /* grammarStackiCanBeZerob */)) goto err;
  
  if (! marpaESLIFLua_lua_pop(L, 3)) goto err;

  marpaESLIFRecognizerOption.userDatavp          = &marpaESLIFLuaRecognizerContext;
  marpaESLIFRecognizerOption.readerCallbackp     = marpaESLIFLua_readerCallbackb;
  MARPAESLIFLUA_CALLBACKB(L, marpaESLIFLuaRecognizerContext.recognizerInterface_r, "isWithDisableThreshold", 0 /* nargs */, MARPAESLIFLUA_NOOP, &(marpaESLIFRecognizerOption.disableThresholdb));
  MARPAESLIFLUA_CALLBACKB(L, marpaESLIFLuaRecognizerContext.recognizerInterface_r, "isWithExhaustion",       0 /* nargs */, MARPAESLIFLUA_NOOP, &(marpaESLIFRecognizerOption.exhaustedb));
  MARPAESLIFLUA_CALLBACKB(L, marpaESLIFLuaRecognizerContext.recognizerInterface_r, "isWithNewline",          0 /* nargs */, MARPAESLIFLUA_NOOP, &(marpaESLIFRecognizerOption.newlineb));
  MARPAESLIFLUA_CALLBACKB(L, marpaESLIFLuaRecognizerContext.recognizerInterface_r, "isWithTrack",            0 /* nargs */, MARPAESLIFLUA_NOOP, &(marpaESLIFRecognizerOption.trackb));
  marpaESLIFRecognizerOption.bufsizl           = 0; /* Recommended value */
  marpaESLIFRecognizerOption.buftriggerperci   = 50; /* Recommended value */
  marpaESLIFRecognizerOption.bufaddperci       = 50; /* Recommended value */
  marpaESLIFRecognizerOption.ifActionResolverp = marpaESLIFLua_recognizerIfActionResolver;

  marpaESLIFValueOption.userDatavp             = &marpaESLIFLuaValueContext;
  marpaESLIFValueOption.ruleActionResolverp    = marpaESLIFLua_valueRuleActionResolver;
  marpaESLIFValueOption.symbolActionResolverp  = marpaESLIFLua_valueSymbolActionResolver;
  marpaESLIFValueOption.importerp              = marpaESLIFLua_importb;
  MARPAESLIFLUA_CALLBACKB(L, marpaESLIFLuaValueContext.valueInterface_r, "isWithHighRankOnly", 0 /* nargs */, MARPAESLIFLUA_NOOP, &(marpaESLIFValueOption.highRankOnlyb));
  MARPAESLIFLUA_CALLBACKB(L, marpaESLIFLuaValueContext.valueInterface_r, "isWithOrderByRank",  0 /* nargs */, MARPAESLIFLUA_NOOP, &(marpaESLIFValueOption.orderByRankb));
  MARPAESLIFLUA_CALLBACKB(L, marpaESLIFLuaValueContext.valueInterface_r, "isWithAmbiguous",    0 /* nargs */, MARPAESLIFLUA_NOOP, &(marpaESLIFValueOption.ambiguousb));
  MARPAESLIFLUA_CALLBACKB(L, marpaESLIFLuaValueContext.valueInterface_r, "isWithNull",         0 /* nargs */, MARPAESLIFLUA_NOOP, &(marpaESLIFValueOption.nullb));
  MARPAESLIFLUA_CALLBACKI(L, marpaESLIFLuaValueContext.valueInterface_r, "maxParses",          0 /* nargs */, MARPAESLIFLUA_NOOP, &(marpaESLIFValueOption.maxParsesi));

  if ((rci = marpaESLIFGrammar_parseb(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, &marpaESLIFRecognizerOption, &marpaESLIFValueOption, NULL)) != 0) {
    if (! marpaESLIFLua_lua_gettop(&resultStacki, L)) goto err;
    /* marpaESLIFGrammar_parseb called the importer that pushed the final value to the stack */
    MARPAESLIFLUA_CALLBACKV(L, marpaESLIFLuaValueContext.valueInterface_r, "setResult", 1 /* nargs */, if (! marpaESLIFLua_lua_pushnil(L)) goto err; if (! marpaESLIFLua_lua_copy(L, resultStacki, -1)) goto err;);
    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;
  }

  marpaESLIFLua_valueContextFreev(&marpaESLIFLuaValueContext, 1 /* onStackb */);
  marpaESLIFLua_recognizerContextFreev(&marpaESLIFLuaRecognizerContext, 1 /* onStackb */);

  if (! marpaESLIFLua_lua_pushboolean(L, rci)) goto err;

  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static short marpaESLIFLua_readerCallbackb(void *userDatavp, char **inputcpp, size_t *inputlp, short *eofbp, short *characterStreambp, char **encodingsp, size_t *encodinglp)
/*****************************************************************************/
{
  static const char                *funcs                           = "marpaESLIFLua_readerCallbackb";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp = (marpaESLIFLuaRecognizerContext_t *) userDatavp;
  lua_State                        *L                               = marpaESLIFLuaRecognizerContextp->L;
  int                               recognizerInterface_r           = marpaESLIFLuaRecognizerContextp->recognizerInterface_r;
  char                             *inputs                          = NULL;
  char                             *encodings                       = NULL;
  size_t                            inputl;
  size_t                            encodingl;
  short                             callbackb;

  marpaESLIFLua_recognizerContextCleanupv(marpaESLIFLuaRecognizerContextp);

  /* Call the read interface */
  MARPAESLIFLUA_CALLBACKB(L, recognizerInterface_r, "read", 0 /* nargs */, MARPAESLIFLUA_NOOP, &callbackb);
  if (! callbackb) {
    marpaESLIFLua_luaL_errorf(L, "Recognizer read method failure, %s", strerror(errno));
    goto err;
  }

  /* Call the data interface */
  MARPAESLIFLUA_CALLBACKS(L, recognizerInterface_r, "data", 0 /* nargs */, MARPAESLIFLUA_NOOP, &inputs, &inputl);

  /* Call the encoding interface */
  MARPAESLIFLUA_CALLBACKS(L, recognizerInterface_r, "encoding", 0 /* nargs */, MARPAESLIFLUA_NOOP, &encodings, &encodingl);

  *inputcpp             = inputs;
  *inputlp              = (size_t) inputl;
  MARPAESLIFLUA_CALLBACKB(L, recognizerInterface_r, "isEof",             0 /* nargs */, MARPAESLIFLUA_NOOP, eofbp);
  MARPAESLIFLUA_CALLBACKB(L, recognizerInterface_r, "isCharacterStream", 0 /* nargs */, MARPAESLIFLUA_NOOP, characterStreambp);
  *encodingsp           = encodings;
  *encodinglp           = encodingl;

  marpaESLIFLuaRecognizerContextp->previousInputs    = (char *) inputs;
  marpaESLIFLuaRecognizerContextp->previousEncodings = (char *) encodings;

  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static marpaESLIFValueRuleCallback_t marpaESLIFLua_valueRuleActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions)
/*****************************************************************************/
{
  static const char           *funcs                      = "marpaESLIFLua_valueRuleActionResolver";
#ifdef MARPAESLIFLUA_EMBEDDED
  marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp = (marpaESLIFLuaValueContext_t *) marpaESLIFValuep->marpaESLIFLuaValueContextp;
#else
  marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp = (marpaESLIFLuaValueContext_t *) userDatavp;
#endif
  lua_State                   *L                          = marpaESLIFLuaValueContextp->L;

  /* Just remember the action name - lua will croak if calling this method fails */
  marpaESLIFLuaValueContextp->actions = actions;

  return marpaESLIFLua_valueRuleCallbackb;
}

/*****************************************************************************/
static marpaESLIFValueSymbolCallback_t marpaESLIFLua_valueSymbolActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions)
/*****************************************************************************/
{
  static const char           *funcs                      = "marpaESLIFLua_valueSymbolActionResolver";
#ifdef MARPAESLIFLUA_EMBEDDED
  marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp = (marpaESLIFLuaValueContext_t *) marpaESLIFValuep->marpaESLIFLuaValueContextp;
#else
  marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp = (marpaESLIFLuaValueContext_t *) userDatavp;
#endif
  lua_State                   *L                          = marpaESLIFLuaValueContextp->L;

  /* Just remember the action name - lua will croak if calling this method fails */
  marpaESLIFLuaValueContextp->actions = actions;

  return marpaESLIFLua_valueSymbolCallbackb;
}

/*****************************************************************************/
static marpaESLIFRecognizerIfCallback_t marpaESLIFLua_recognizerIfActionResolver(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, char *actions)
/*****************************************************************************/
{
  static const char           *funcs                      = "marpaESLIFLua_recognizerIfActionResolver";
#ifdef MARPAESLIFLUA_EMBEDDED
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp = (marpaESLIFLuaRecognizerContext_t *) marpaESLIFRecognizerp->marpaESLIFLuaRecognizerContextp;
#else
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp = (marpaESLIFLuaRecognizerContext_t *) userDatavp;
#endif
  lua_State                   *L                          = marpaESLIFLuaRecognizerContextp->L;

  /* Just remember the action name - lua will croak if calling this method fails */
  marpaESLIFLuaRecognizerContextp->actions = actions;

  return marpaESLIFLua_recognizerIfCallbackb;
}

/*****************************************************************************/
static short marpaESLIFLua_valueRuleCallbackb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  return marpaESLIFLua_valueCallbackb(userDatavp, marpaESLIFValuep, arg0i, argni, NULL /* marpaESLIFValueResultLexemep */, resulti, nullableb, 0 /* symbolb */);
}

/*****************************************************************************/
static short marpaESLIFLua_valueSymbolCallbackb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFValueResult_t *marpaESLIFValueResultp, int resulti)
/*****************************************************************************/
{
  return marpaESLIFLua_valueCallbackb(userDatavp, marpaESLIFValuep, -1 /* arg0i */, -1 /* argni */, marpaESLIFValueResultp, resulti, 0 /* nullableb */, 1 /* symbolb */);
}

/*****************************************************************************/
static short marpaESLIFLua_recognizerIfCallbackb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFValueResultLexemep, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp)
/*****************************************************************************/
{
  return marpaESLIFLua_ifCallbackb(userDatavp, marpaESLIFRecognizerp, marpaESLIFValueResultLexemep, marpaESLIFValueResultBoolp);
}

/*****************************************************************************/
static short marpaESLIFLua_valueCallbackb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, marpaESLIFValueResult_t *marpaESLIFValueResultLexemep, int resulti, short nullableb, short symbolb)
/*****************************************************************************/
/* The code doing rule and symbol callback to lua is shared. */
/* We distinguish the symbol case v.s. the rule case by testing bytep. */
/*****************************************************************************/
{
  static const char           *funcs                      = "marpaESLIFLua_valueCallbackb";
#ifdef MARPAESLIFLUA_EMBEDDED
  marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp = (marpaESLIFLuaValueContext_t *) marpaESLIFValuep->marpaESLIFLuaValueContextp;
#else
  marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp = (marpaESLIFLuaValueContext_t *) userDatavp;
#endif
  lua_State                   *L                          = marpaESLIFLuaValueContextp->L;
  char                        *encodings                  = NULL;
  int                          topi;
  int                          newtopi;
  int                          i;
  short                        rcb;

  /* Get value context */
  if (! marpaESLIFValue_contextb(marpaESLIFValuep, &(marpaESLIFLuaValueContextp->symbols), &(marpaESLIFLuaValueContextp->symboli), &(marpaESLIFLuaValueContextp->rules), &(marpaESLIFLuaValueContextp->rulei))) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFValue_contextb failure, %s", strerror(errno));
    goto err;
  }

  /* fprintf(stdout, "... action %s start\n", marpaESLIFLuaValueContextp->actions); fflush(stdout); fflush(stderr); */

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (symbolb) {
    MARPAESLIFLUA_CALLBACK(L, marpaESLIFLuaValueContextp->valueInterface_r, marpaESLIFLuaValueContextp->actions, 1 /* nargs */,
                           if (! marpaESLIFLua_pushValueb(marpaESLIFLuaValueContextp, marpaESLIFValuep, -1 /* stackindicei */, marpaESLIFValueResultLexemep)) goto err;
                           );
  } else {
    MARPAESLIFLUA_CALLBACK(L, marpaESLIFLuaValueContextp->valueInterface_r, marpaESLIFLuaValueContextp->actions, nullableb ? 0 : (argni - arg0i + 1) /* nargs */, 
                           if (! nullableb) {
                             for (i = arg0i; i <= argni; i++) {
                               if (! marpaESLIFLua_pushValueb(marpaESLIFLuaValueContextp, marpaESLIFValuep, i, NULL /* marpaESLIFValueResultLexemep */)) goto err;
                             }
                           }
                           );
  }

  if (! marpaESLIFLua_lua_gettop(&newtopi, L)) goto err;
  if (newtopi == topi) {
    if (! marpaESLIFLua_lua_pushnil(L)) goto err;
  } else {
    if (newtopi != (topi + 1)) {
      marpaESLIFLua_luaL_errorf(L, "Function %s must return exactly one or zero value", marpaESLIFLuaValueContextp->actions);
      goto err;
    }
  }

  if (! marpaESLIFLua_stack_setb(L, marpaESLIFLuaValueContextp->marpaESLIFp, marpaESLIFValuep, resulti, NULL /* marpaESLIFValueResultOutputp */)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /* After every valuation we clean the MARPAESLIFOPAQUETABLE global table */
  if (! marpaESLIFLua_lua_pushnil(L)) goto err;
  if (! marpaESLIFLua_lua_setglobal(L, MARPAESLIFOPAQUETABLE)) goto err;

  /* fprintf(stdout, "... action %s done\n", marpaESLIFLuaValueContextp->actions); fflush(stdout); fflush(stderr); */

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  if (encodings != NULL) {
    free(encodings);
  }
  return rcb;
}

/*****************************************************************************/
static short marpaESLIFLua_ifCallbackb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFValueResultLexemep, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp)
/*****************************************************************************/
{
  static const char           *funcs                      = "marpaESLIFLua_ifCallbackb";
#ifdef MARPAESLIFLUA_EMBEDDED
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp = (marpaESLIFLuaRecognizerContext_t *) marpaESLIFRecognizerp->marpaESLIFLuaRecognizerContextp;
#else
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp = (marpaESLIFLuaRecognizerContext_t *) userDatavp;
#endif
  lua_State                   *L                          = marpaESLIFLuaRecognizerContextp->L;
  int                          topi;
  int                          newtopi;
  int                          typei;
  int                          tmpi;
  short                        rcb;

  /* fprintf(stdout, "... action %s start\n", marpaESLIFLuaRecognizerContextp->actions); fflush(stdout); fflush(stderr); */

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  MARPAESLIFLUA_CALLBACK(L, marpaESLIFLuaRecognizerContextp->recognizerInterface_r, marpaESLIFLuaRecognizerContextp->actions, 1 /* nargs */,
                         if (! marpaESLIFLua_pushRecognizerb(marpaESLIFLuaRecognizerContextp, marpaESLIFRecognizerp, marpaESLIFValueResultLexemep)) goto err;
                         );

  if (! marpaESLIFLua_lua_gettop(&newtopi, L)) goto err;
  if (newtopi != (topi + 1)) {
    marpaESLIFLua_luaL_errorf(L, "Function %s must return exactly one value", marpaESLIFLuaRecognizerContextp->actions);
    goto err;
  }

  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TBOOLEAN) {
    marpaESLIFLua_luaL_errorf(L, "Function %s must return a boolean value", marpaESLIFLuaRecognizerContextp->actions);
    goto err;
  }

  if (! marpaESLIFLua_lua_toboolean(&tmpi, L, 1)) goto err;

  *marpaESLIFValueResultBoolp = (tmpi != 0) ? MARPAESLIFVALUERESULTBOOL_TRUE : MARPAESLIFVALUERESULTBOOL_FALSE;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /* fprintf(stdout, "... action %s done\n", marpaESLIFLuaRecognizerContextp->actions); fflush(stdout); fflush(stderr); */

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static void marpaESLIFLua_valueFreeCallbackv(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFValueResult_t *marpaESLIFValueResultp)
/*****************************************************************************/
{
  static const char           *funcs                      = "marpaESLIFLua_valueFreeCallbackv";
#ifdef MARPAESLIFLUA_EMBEDDED
  marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp = (marpaESLIFLuaValueContext_t *) marpaESLIFValuep->marpaESLIFLuaValueContextp;
#else
  marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp = (marpaESLIFLuaValueContext_t *) userDatavp;
#endif

  marpaESLIFLua_genericFreeCallbackv((void *) marpaESLIFLuaValueContextp->L, marpaESLIFValueResultp);
}

/*****************************************************************************/
static void marpaESLIFLua_recognizerFreeCallbackv(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFValueResultp)
/*****************************************************************************/
{
  static const char                *funcs                           = "marpaESLIFLua_recognizerFreeCallbackv";
#ifdef MARPAESLIFLUA_EMBEDDED
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp = (marpaESLIFLuaRecognizerContext_t *) marpaESLIFRecognizerp->marpaESLIFLuaRecognizerContextp;
#else
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp = (marpaESLIFLuaRecognizerContext_t *) userDatavp;
#endif

  marpaESLIFLua_genericFreeCallbackv((void *) marpaESLIFLuaRecognizerContextp->L, marpaESLIFValueResultp);
}

/*****************************************************************************/
static void marpaESLIFLua_genericFreeCallbackv(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp)
/*****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_genericFreeCallbackv";
  lua_State         *L     = (lua_State *) userDatavp;
  int               *ip;

  /* We can be callbacked on types ARRAY, STRING and PTR */
  switch (marpaESLIFValueResultp->type) {
  case MARPAESLIF_VALUE_TYPE_ARRAY:
    if (marpaESLIFValueResultp->u.a.p != NULL) {
      free(marpaESLIFValueResultp->u.a.p);
    }
    break;
  case MARPAESLIF_VALUE_TYPE_STRING:
    if (marpaESLIFValueResultp->u.s.p != NULL) {
      free(marpaESLIFValueResultp->u.s.p);
    }
    if (marpaESLIFValueResultp->u.s.encodingasciis != NULL) {
      free(marpaESLIFValueResultp->u.s.encodingasciis);
    }
    break;
  case MARPAESLIF_VALUE_TYPE_PTR:
    /* When we push a PTR, then it is a pointer to an integer that is a reference inside lua interpreter */
    ip = (int *) marpaESLIFValueResultp->u.p.p;
    if (ip != NULL) {
      MARPAESLIFLUA_UNREF(L, *ip);
      free(ip);
    }
    break;
  case MARPAESLIF_VALUE_TYPE_ROW:
    if (marpaESLIFValueResultp->u.r.p != NULL) {
      free(marpaESLIFValueResultp->u.r.p);
    }
    break;
  case MARPAESLIF_VALUE_TYPE_TABLE:
    if (marpaESLIFValueResultp->u.t.p != NULL) {
      free(marpaESLIFValueResultp->u.t.p);
    }
    break;
  default:
    break;
  }

 err:
  return;
}

/*****************************************************************************/
static short marpaESLIFLua_importb(marpaESLIFValue_t *marpaESLIFValuep, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp)
/*****************************************************************************/
{
  static const char           *funcs                      = "marpaESLIFLua_importb";
#ifdef MARPAESLIFLUA_EMBEDDED
  marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp = (marpaESLIFLuaValueContext_t *) marpaESLIFValuep->marpaESLIFLuaValueContextp;
#else
  marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp = (marpaESLIFLuaValueContext_t *) userDatavp;
#endif
  lua_State                   *L                          = marpaESLIFLuaValueContextp->L;
  size_t                       i;
  marpaESLIFValueResult_t     *marpaESLIFValueResultDupp;
  short                        rcb;

  switch (marpaESLIFValueResultp->type) {
  case MARPAESLIF_VALUE_TYPE_UNDEF:
    /* fprintf(stdout, "import undef\n"); fflush(stdout); fflush(stderr); */
    if (! marpaESLIFLua_lua_pushnil(L)) goto err;
    break;
  case MARPAESLIF_VALUE_TYPE_CHAR:
    /* fprintf(stdout, "import char\n"); fflush(stdout); fflush(stderr); */
    if (! marpaESLIFLua_lua_pushlstring(NULL, L, &(marpaESLIFValueResultp->u.c), 1)) goto err;
    break;
  case MARPAESLIF_VALUE_TYPE_SHORT:
    /* fprintf(stdout, "import short\n"); fflush(stdout); fflush(stderr); */
    if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) marpaESLIFValueResultp->u.b)) goto err;
    break;
  case MARPAESLIF_VALUE_TYPE_INT:
    /* fprintf(stdout, "import int\n"); fflush(stdout); fflush(stderr); */
    if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) marpaESLIFValueResultp->u.i)) goto err;
    break;
  case MARPAESLIF_VALUE_TYPE_LONG:
    /* fprintf(stdout, "import long\n"); fflush(stdout); fflush(stderr); */
    if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) marpaESLIFValueResultp->u.l)) goto err;
    break;
  case MARPAESLIF_VALUE_TYPE_FLOAT:
    /* fprintf(stdout, "import float\n"); fflush(stdout); fflush(stderr); */
    if (! marpaESLIFLua_lua_pushnumber(L, (lua_Number) marpaESLIFValueResultp->u.f)) goto err;
    break;
  case MARPAESLIF_VALUE_TYPE_DOUBLE:
    /* fprintf(stdout, "import double\n"); fflush(stdout); fflush(stderr); */
    if (! marpaESLIFLua_lua_pushnumber(L, (lua_Number) marpaESLIFValueResultp->u.d)) goto err;
    break;
  case MARPAESLIF_VALUE_TYPE_PTR:
    /* fprintf(stdout, "import ptr\n"); fflush(stdout); fflush(stderr); */
    if (marpaESLIFValueResultp->contextp == MARPAESLIFLUA_CONTEXT) {
      /* This is a pointer to an integer value that is a global reference to the real value */
      MARPAESLIFLUA_DEREF(L, * (int *) marpaESLIFValueResultp->u.p.p);
    } else {
      /* We want to maintain all the marpaESLIFValueResult properties: we duplicate it. */
      marpaESLIFValueResultDupp = (marpaESLIFValueResult_t *) malloc(sizeof(marpaESLIFValueResult_t));
      if (marpaESLIFValueResultDupp == NULL) {
        marpaESLIFLua_luaL_errorf(L, "malloc failure, %s", strerror(errno));
        goto err;
      }
      *marpaESLIFValueResultDupp = *marpaESLIFValueResultp;
      if (! marpaESLIFLua_lua_pushlightuserdata(L, marpaESLIFValueResultDupp->u.p.p)) goto err;
      /* We want to remember that marpaESLIFValueResultDupp->u.p.p is associated to marpaESLIFValueResultDupp */
      /* If case there would be more than another marpaESLIFValueResult or type PTR with the same PTR */
      /* it is considered as a user error if it would not have the exact and same context */
      MARPAESLIFLUA_GETORCREATEGLOBAL(L, MARPAESLIFOPAQUETABLE, marpaESLIFLua_marpaESLIFOpaque_freei /* gcp */, "" /* mode */);  /* Stack: ..., marpaESLIFValueResultp->u.p.p, MARPAESLIFOPAQUETABLE */
      if (! marpaESLIFLua_lua_pushlightuserdata(L, marpaESLIFValueResultDupp->u.p.p)) goto err;                                  /* Stack: ..., marpaESLIFValueResultp->u.p.p, MARPAESLIFOPAQUETABLE, marpaESLIFValueResultp->u.p.p */
      if (! marpaESLIFLua_lua_pushlightuserdata(L, marpaESLIFValueResultDupp)) goto err;                                         /* Stack: ..., marpaESLIFValueResultp->u.p.p, MARPAESLIFOPAQUETABLE, marpaESLIFValueResultp->u.p.p, marpaESLIFValueResultDupp */
      if (! marpaESLIFLua_lua_settable(L, -3)) goto err;                                                                         /* Stack: ..., marpaESLIFValueResultp->u.p.p, MARPAESLIFOPAQUETABLE */
      if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                                                                               /* Stack: ..., marpaESLIFValueResultp->u.p.p */
    }
    break;
  case MARPAESLIF_VALUE_TYPE_ARRAY:
    /* fprintf(stdout, "import array\n"); fflush(stdout); fflush(stderr); */
    if (! marpaESLIFLua_lua_pushlstring(NULL, L, marpaESLIFValueResultp->u.a.p, marpaESLIFValueResultp->u.a.sizel)) goto err;
    break;
  case MARPAESLIF_VALUE_TYPE_BOOL:
    /* fprintf(stdout, "import bool\n"); fflush(stdout); fflush(stderr); */
    if (! marpaESLIFLua_lua_pushboolean(L, (int) (marpaESLIFValueResultp->u.y == MARPAESLIFVALUERESULTBOOL_FALSE) ? 0 : 1)) goto err;
    break;
  case MARPAESLIF_VALUE_TYPE_STRING:
    /* fprintf(stdout, "import string\n"); fflush(stdout); fflush(stderr); */
    /* We take register this string in our MARPAESLIFSTRINGTOENCODINGTABLE internal table */
    MARPAESLIFLUA_GETORCREATEGLOBAL(L, MARPAESLIFSTRINGTOENCODINGTABLE, NULL /* gcp */, "k" /* mode */);                      /* Stack: ..., MARPAESLIFSTRINGTOENCODINGTABLE */
    if ((marpaESLIFValueResultp->u.s.p != NULL) && (marpaESLIFValueResultp->u.s.sizel > 0)) {
      if (! marpaESLIFLua_lua_pushlstring(NULL, L, (const char *) marpaESLIFValueResultp->u.s.p, marpaESLIFValueResultp->u.s.sizel)) goto err; /* Stack: ..., MARPAESLIFSTRINGTOENCODINGTABLE, string */
    } else {
      if (! marpaESLIFLua_lua_pushlstring(NULL, L, "", 0)) goto err;                                                          /* Stack: ..., MARPAESLIFSTRINGTOENCODINGTABLE, "" */
    }
    if (! marpaESLIFLua_lua_pushstring(NULL, L, marpaESLIFValueResultp->u.s.encodingasciis)) goto err;                        /* Stack: ..., MARPAESLIFSTRINGTOENCODINGTABLE, string, encodingasciis */
    if (! marpaESLIFLua_lua_settable(L, -3)) goto err;                                                                        /* Stack: ..., MARPAESLIFSTRINGTOENCODINGTABLE */
    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                                                                              /* Stack: ... */
    if (! marpaESLIFLua_lua_pushlstring(NULL, L, (const char *) marpaESLIFValueResultp->u.s.p, marpaESLIFValueResultp->u.s.sizel)) goto err; /* Stack: ..., string */
    break;
  case MARPAESLIF_VALUE_TYPE_ROW:
    /* fprintf(stdout, "import row\n"); fflush(stdout); fflush(stderr); */
    /* We received elements importer callbacks in order; i.e. 1, then 2, then 3... */
    /* We pushed that in lua stack, i.e. the lua stack then contains:  1 imported, then 2 imported, then 3 imported... */
    if (marpaESLIFValueResultp->u.r.sizel > INT_MAX) {
      marpaESLIFLua_luaL_errorf(L, "table size %ld too big, maximum is %d", (unsigned long) marpaESLIFValueResultp->u.r.sizel, INT_MAX);
      goto err;
    }
    if (! marpaESLIFLua_createniledtableb(L, (int) marpaESLIFValueResultp->u.r.sizel, 0, 1 /* arrayb */)) goto err;           /* Stack: val1, ..., valn, table */
    if (marpaESLIFValueResultp->u.r.sizel > 0) {
      for (i = marpaESLIFValueResultp->u.r.sizel; i > 0 ; i--) {
        if (! marpaESLIFLua_lua_insert(L, -2)) goto err;                                                                      /* Stack: val1, ..., table, valn */
        if (! marpaESLIFLua_lua_seti(L, -2, (int) i)) goto err;                                                               /* Stack: val1, ..., table */
      }
    }
    break;
  case MARPAESLIF_VALUE_TYPE_TABLE:
    /* fprintf(stdout, "import table\n"); fflush(stdout); fflush(stderr); */
    /* We received elements importer callbacks in order; i.e. key0, val0, ..., keyn, valn */
    /* We pushed that in lua stack, i.e. the lua stack then contains:  valn imported, keyn imported, ..., val0 imported, key0 imported */
    if (marpaESLIFValueResultp->u.t.sizel > INT_MAX) {
      marpaESLIFLua_luaL_errorf(L, "table size %ld too big, maximum is %d", (unsigned long) marpaESLIFValueResultp->u.t.sizel, INT_MAX);
      goto err;
    }
    if (! marpaESLIFLua_createniledtableb(L, (int) marpaESLIFValueResultp->u.r.sizel, 0, 0 /* arrayb */)) goto err;           /* Stack: keyn, valn, ..., key1, val1, table */

    /* By definition the stack contains t.sizel even elements that are {key,value} tuples */
    for (i = 0; i < marpaESLIFValueResultp->u.t.sizel; i++) {
      if (! marpaESLIFLua_lua_insert(L, -3)) goto err;                                                                        /* Stack: keyn, valn, ..., table, keyx, valx */
      if (! marpaESLIFLua_lua_settable(L, -3)) goto err;                                                                      /* Stack: keyn, valn, ..., table */
    }
    break;
  case MARPAESLIF_VALUE_TYPE_LONG_DOUBLE:
    /* fprintf(stdout, "import long double\n"); fflush(stdout); fflush(stderr); */
    if (! marpaESLIFLua_lua_pushnumber(L, (lua_Number) marpaESLIFValueResultp->u.ld)) goto err;
    break;
#ifdef MARPAESLIF_HAVE_LONG_LONG
  case MARPAESLIF_VALUE_TYPE_LONG_LONG:
    /* fprintf(stdout, "import long long\n"); fflush(stdout); fflush(stderr); */
    if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) marpaESLIFValueResultp->u.ll)) goto err;
    break;
#endif
  default:
    marpaESLIFLua_luaL_errorf(L, "Unknown result type %d to import", marpaESLIFValueResultp->type);
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
static short marpaESLIFLua_pushValueb(marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp, marpaESLIFValue_t *marpaESLIFValuep, int stackindicei, marpaESLIFValueResult_t *marpaESLIFValueResultLexemep)
/*****************************************************************************/
{
  static const char       *funcs = "marpaESLIFLua_pushValueb";
  lua_State               *L     = marpaESLIFLuaValueContextp->L;
  marpaESLIFValueResult_t *marpaESLIFValueResultp;

  /* fprintf(stdout, "... push value %s start\n", marpaESLIFLuaValueContextp->actions); fflush(stdout); fflush(stderr); */
  if (marpaESLIFValueResultLexemep != NULL) {
    marpaESLIFValueResultp             = marpaESLIFValueResultLexemep;
  } else {
    marpaESLIFValueResultp = marpaESLIFValue_stack_getp(marpaESLIFValuep, stackindicei);
    if (marpaESLIFValueResultp == NULL) {
      marpaESLIFLua_luaL_errorf(L, "marpaESLIFValueResultp is NULL at stack indice %d", stackindicei);
      goto err;
    }
  }

#ifdef MARPAESLIFLUA_EMBEDDED
  /* In embedded mode we must never trust userDatavp */
  if (! _marpaESLIFValue_eslif2hostb(marpaESLIFValuep, marpaESLIFValueResultp, NULL /* marpaESLIFValueResultResolvedp */, marpaESLIFLuaValueContextp /* forcedUserDatavp */, marpaESLIFLua_importb /* forcedImporterp */)) {
    marpaESLIFLua_luaL_errorf(L, "_marpaESLIFValue_eslif2hostb failure, %s", strerror(errno));
    goto err;
  }
#else
  if (! marpaESLIFValue_importb(marpaESLIFValuep, marpaESLIFValueResultp, NULL /* marpaESLIFValueResultResolvedp */)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFValue_importb failure, %s", strerror(errno));
    goto err;
  }
#endif

  /* fprintf(stdout, "... push value %s done\n", marpaESLIFLuaValueContextp->actions); fflush(stdout); fflush(stderr); */
  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static short marpaESLIFLua_pushRecognizerb(marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFValueResultLexemep)
/*****************************************************************************/
{
  static const char       *funcs = "marpaESLIFLua_pushRecognizerb";
  lua_State               *L     = marpaESLIFLuaRecognizerContextp->L;

  /* By definition, a lexeme is always of type ARRAY */
  if (marpaESLIFValueResultLexemep->type != MARPAESLIF_VALUE_TYPE_ARRAY) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFValueResultLexemep is of type %d != ARRAY (%d)", marpaESLIFValueResultLexemep->type, MARPAESLIF_VALUE_TYPE_ARRAY);
    goto err;
  }

  if (! marpaESLIFLua_lua_pushlstring(NULL, L, marpaESLIFValueResultLexemep->u.a.p, marpaESLIFValueResultLexemep->u.a.sizel)) goto err;

  /* fprintf(stdout, "... push value %s done\n", marpaESLIFLuaRecognizerContextp->actions); fflush(stdout); fflush(stderr); */
  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static short marpaESLIFLua_representationb(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp, char **encodingasciisp)
/*****************************************************************************/
{
  static const char           *funcs                      = "marpaESLIFLua_representationb";
  marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp = (marpaESLIFLuaValueContext_t *) userDatavp;
  lua_State                   *L                          = marpaESLIFLuaValueContextp->L;
  const char                  *s;
  size_t                       l;
  int                          callmetai;
  int                          typei;

  marpaESLIFLua_valueContextCleanupv(marpaESLIFLuaValueContextp);

  /* We always push a PTR */
  if (marpaESLIFValueResultp->type != MARPAESLIF_VALUE_TYPE_PTR) {
    marpaESLIFLua_luaL_errorf(L, "User-defined value type is not MARPAESLIF_VALUE_TYPE_PTR but %d", marpaESLIFValueResultp->type);
    goto err;
  }
  /* Our context is always MARPAESLIFLUA_CONTEXT */
  if (marpaESLIFValueResultp->contextp != MARPAESLIFLUA_CONTEXT) {
    marpaESLIFLua_luaL_errorf(L, "User-defined value context is not MARPAESLIFLUA_CONTEXT but %p", marpaESLIFValueResultp->contextp);
    goto err;
  }

  MARPAESLIFLUA_DEREF(L, * (int *) marpaESLIFValueResultp->u.p.p);
  /* Eventually call the __tostring metamethod if it exists */
  /* This will work with EVERY lua value. */
  if (! marpaESLIFLua_luaL_tolstring(&s, L, -1, &l)) goto err;
  if ((s != NULL) && (l > 0)) {
    /* No guarantee this will survive the lua call, so we keep an explicitly copy */
    /* until marpaESLIF also takes a copy. */
    marpaESLIFLuaValueContextp->previous_strings = (char *) malloc(l + 1);
    if (marpaESLIFLuaValueContextp->previous_strings == NULL) {
      marpaESLIFLua_luaL_errorf(L, "malloc failure, %s", strerror(errno));
      goto err;
    }
    memcpy(marpaESLIFLuaValueContextp->previous_strings, s, l);
    marpaESLIFLuaValueContextp->previous_strings[l] = '\0'; /* Hiden NUL byte */
    *inputcpp = marpaESLIFLuaValueContextp->previous_strings;
    *inputlp = l;
  }
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /* We restrict that to tables, because it requires a metatable that is possible only on... tables */
  /* Call the method __marpaESLIF_encoding if it exists */
  if (! marpaESLIFLua_lua_type(&typei, L, -1)) goto err;
  if (typei == LUA_TTABLE) {
    if (! marpaESLIFLua_luaL_callmeta(&callmetai, L, -1, "__marpaESLIF_encoding")) goto err;
    if (callmetai) {
      if (! marpaESLIFLua_lua_type(&typei, L, -1)) goto err;
      if (typei != LUA_TSTRING) {
        marpaESLIFLua_luaL_error(L, "'__marpaESLIF_encoding' must return a string");
        goto err;
      }
      if (! marpaESLIFLua_luaL_tolstring(&s, L, -1, &l)) goto err;
      if ((s != NULL) && (l > 0)) {
        /* No guarantee this will survive the lua call, so we keep an explicitly copy */
        /* until marpaESLIF also takes a copy. */
        marpaESLIFLuaValueContextp->previous_encodings = (char *) malloc(l + 1);
        if (marpaESLIFLuaValueContextp->previous_encodings == NULL) {
          marpaESLIFLua_luaL_errorf(L, "malloc failure, %s", strerror(errno));
          goto err;
        }
        memcpy(marpaESLIFLuaValueContextp->previous_encodings, s, l);
        marpaESLIFLuaValueContextp->previous_encodings[l] = '\0'; /* Hiden NUL byte */
        *encodingasciisp = marpaESLIFLuaValueContextp->previous_encodings;
      }
      if (! marpaESLIFLua_lua_pop(L, 1)) goto err;
    }
  }

  /* Always return a true value, else ::concat will abort */
  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_newi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_newi";
  marpaESLIFLuaGrammarContext_t    *marpaESLIFLuaGrammarContextp;
  marpaESLIFRecognizerOption_t      marpaESLIFRecognizerOption;
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  int                               typei;
  int                               topi;
  marpaESLIF_t                     *marpaESLIFp;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_new(marpaESLIFGrammarp, recognizerInterface)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaGrammarContextp")) goto err;   /* Stack: marpaESLIFGrammarTable, recognizerInterface, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  marpaESLIFLua_paramIsRecognizerInterfacev(L, 2);
  
  marpaESLIFLuaRecognizerContextp = (marpaESLIFLuaRecognizerContext_t *) malloc(sizeof(marpaESLIFLuaRecognizerContext_t));
  if (marpaESLIFLuaRecognizerContextp == NULL) {
    marpaESLIFLua_luaL_errorf(L, "malloc failure, %s", strerror(errno));
    goto err;
  }

  marpaESLIFp = marpaESLIFLuaGrammarContextp->marpaESLIFp;
  if (! marpaESLIFLua_recognizerContextInitb(L, marpaESLIFp, 1 /* grammarStacki */, 2 /* recognizerInterfaceStacki */, 0 /* recognizerOrigStacki */, marpaESLIFLuaRecognizerContextp, 0 /* unmanagedb */)) goto err;

  marpaESLIFRecognizerOption.userDatavp          = marpaESLIFLuaRecognizerContextp;
  marpaESLIFRecognizerOption.readerCallbackp     = marpaESLIFLua_readerCallbackb;
  MARPAESLIFLUA_CALLBACKB(L, marpaESLIFLuaRecognizerContextp->recognizerInterface_r, "isWithDisableThreshold", 0 /* nargs */, MARPAESLIFLUA_NOOP, &(marpaESLIFRecognizerOption.disableThresholdb));
  MARPAESLIFLUA_CALLBACKB(L, marpaESLIFLuaRecognizerContextp->recognizerInterface_r, "isWithExhaustion",       0 /* nargs */, MARPAESLIFLUA_NOOP, &(marpaESLIFRecognizerOption.exhaustedb));
  MARPAESLIFLUA_CALLBACKB(L, marpaESLIFLuaRecognizerContextp->recognizerInterface_r, "isWithNewline",          0 /* nargs */, MARPAESLIFLUA_NOOP, &(marpaESLIFRecognizerOption.newlineb));
  MARPAESLIFLUA_CALLBACKB(L, marpaESLIFLuaRecognizerContextp->recognizerInterface_r, "isWithTrack",            0 /* nargs */, MARPAESLIFLUA_NOOP, &(marpaESLIFRecognizerOption.trackb));
  marpaESLIFRecognizerOption.bufsizl           = 0; /* Recommended value */
  marpaESLIFRecognizerOption.buftriggerperci   = 50; /* Recommended value */
  marpaESLIFRecognizerOption.bufaddperci       = 50; /* Recommended value */
  marpaESLIFRecognizerOption.ifActionResolverp = marpaESLIFLua_recognizerIfActionResolver;

  marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp = marpaESLIFRecognizer_newp(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, &marpaESLIFRecognizerOption);
  marpaESLIFLuaRecognizerContextp->managedb = 1;

  if (marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp == NULL) {
    int save_errno = errno;
    marpaESLIFLua_recognizerContextFreev(marpaESLIFLuaRecognizerContextp, 0 /* onStackb */);
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_newp failure, %s", strerror(save_errno));
    goto err;
  }

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  MARPAESLIFLUA_PUSH_MARPAESLIFRECOGNIZER_OBJECT(L, marpaESLIFLuaRecognizerContextp);

  return 1;

 err:
  return 0;
}

#ifdef MARPAESLIFLUA_EMBEDDED
/****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_newFromUnmanagedi(lua_State *L, marpaESLIFRecognizer_t *marpaESLIFRecognizerUnmanagedp)
/****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_newFromUnmanagedi";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  marpaESLIF_t                     *marpaESLIFp;

  marpaESLIFLuaRecognizerContextp = (marpaESLIFLuaRecognizerContext_t *) malloc(sizeof(marpaESLIFLuaRecognizerContext_t));
  if (marpaESLIFLuaRecognizerContextp == NULL) {
    marpaESLIFLua_luaL_errorf(L, "malloc failure, %s", strerror(errno));
    goto err;
  }

  marpaESLIFp = marpaESLIFGrammar_eslifp(marpaESLIFRecognizer_grammarp(marpaESLIFRecognizerUnmanagedp));
  if (! marpaESLIFLua_recognizerContextInitb(L, marpaESLIFp, 0 /* grammarStacki */, 0 /* recognizerInterfaceStacki */, 0 /* recognizerOrigStacki */, marpaESLIFLuaRecognizerContextp, 1 /* unmanagedb */)) goto err;
  marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp = marpaESLIFRecognizerUnmanagedp;
  marpaESLIFLuaRecognizerContextp->managedb              = 0;

  /* We are in embedded code, this mean that we have access to marpaESLIFRecognizer structure */
  marpaESLIFRecognizerUnmanagedp->marpaESLIFLuaRecognizerContextp = marpaESLIFLuaRecognizerContextp;

  MARPAESLIFLUA_PUSH_MARPAESLIFRECOGNIZER_OBJECT(L, marpaESLIFLuaRecognizerContextp);

  return 1;

 err:
  return 0;
}
#endif /* MARPAESLIFLUA_EMBEDDED */

/****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_freei(lua_State *L)
/****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_freei";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;

  if (! marpaESLIFLua_lua_getfield(NULL,L, -1, "marpaESLIFLuaRecognizerContextp")) goto err; /* Stack: {...}, marpaESLIFLuaRecognizerContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  marpaESLIFLua_recognizerContextFreev(marpaESLIFLuaRecognizerContextp, 0 /* onStackb */);

  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  return 0;
 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_newFromi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_newFromi";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextFromp;
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  marpaESLIFLuaGrammarContext_t    *marpaESLIFLuaGrammarContextp;
  int                               typei;
  int                               topi;
  marpaESLIF_t                     *marpaESLIFp;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_newFrom(marpaESLIFRecognizerp, marpaESLIFGrammarp)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_type(&typei, L, 2)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFGrammarp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;       /* Stack: marpaESLIFRecognizerTable, marpaESLIFGrammarTable, marpaESLIFLuaRecognizerContextFromp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextFromp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  if (! marpaESLIFLua_lua_getfield(NULL,L, 2, "marpaESLIFLuaGrammarContextp")) goto err;          /* Stack: marpaESLIFRecognizerTable, marpaESLIFGrammarTable, marpaESLIFLuaGrammarContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaGrammarContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  marpaESLIFLuaRecognizerContextp = (marpaESLIFLuaRecognizerContext_t *) malloc(sizeof(marpaESLIFLuaRecognizerContext_t));
  if (marpaESLIFLuaRecognizerContextp == NULL) {
    marpaESLIFLua_luaL_errorf(L, "malloc failure, %s", strerror(errno));
    goto err;
  }

  marpaESLIFp = marpaESLIFLuaGrammarContextp->marpaESLIFp;
  if (! marpaESLIFLua_recognizerContextInitb(L, marpaESLIFp, 2 /* grammarStacki */, 0 /* recognizerInterfaceStacki */, 1 /* recognizerOrigStacki */, marpaESLIFLuaRecognizerContextp, 0 /* unmanagedb */)) goto err;

  marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp = marpaESLIFRecognizer_newFromp(marpaESLIFLuaGrammarContextp->marpaESLIFGrammarp, marpaESLIFLuaRecognizerContextFromp->marpaESLIFRecognizerp);
  marpaESLIFLuaRecognizerContextp->managedb              = 1;

  if (marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp == NULL) {
    int save_errno = errno;
    marpaESLIFLua_recognizerContextFreev(marpaESLIFLuaRecognizerContextp, 0 /* onStackb */);
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_newFromp failure, %s", strerror(save_errno));
    goto err;
  }

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  MARPAESLIFLUA_PUSH_MARPAESLIFRECOGNIZER_OBJECT(L, marpaESLIFLuaRecognizerContextp);

  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_set_exhausted_flagi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_set_exhausted_flagi";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  int                               typei;
  int                               tmpi;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_set_exhausted_flag(marpaESLIFRecognizerp, flag)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_type(&typei, L, 2)) goto err;
  if (typei != LUA_TBOOLEAN) {
    marpaESLIFLua_luaL_error(L, "flag must be a boolean");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;   /* Stack: marpaESLIFRecognizerTable, marpaESLIFGrammarTable, marpaESLIFLuaRecognizerContextFromp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  if (! marpaESLIFLua_lua_toboolean(&tmpi, L, 2)) goto err;
  if (! marpaESLIFRecognizer_set_exhausted_flagb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, (tmpi != 0) ? 1 : 0)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_set_exhausted_flagb failure, %s", strerror(errno));
    goto err;
  }

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  return 0;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_sharei(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_sharei";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextSharedp;
  int                               typei;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_sharei(marpaESLIFRecognizerp, marpaESLIFRecognizerSharedp)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_type(&typei, L, 2)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerSharedp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;   /* Stack: marpaESLIFRecognizerTable, marpaESLIFRecognizerSharedTable, marpaESLIFLuaRecognizerContextFromp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  if (! marpaESLIFLua_lua_getfield(NULL,L, 2, "marpaESLIFLuaRecognizerContextp")) goto err;         /* Stack: marpaESLIFRecognizerTable, marpaESLIFRecognizerSharedTable, marpaESLIFLuaRecognizerContextFromp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextSharedp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /*
   * The eventual previous reference on another shared recognizer has its refcount decreased.
   */
  if (marpaESLIFLuaRecognizerContextp->recognizer_orig_r != LUA_NOREF) {
    MARPAESLIFLUA_UNREF(L, marpaESLIFLuaRecognizerContextp->recognizer_orig_r);
  }

  if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                              /* Stack: marpaESLIFRecognizerTable, marpaESLIFRecognizerSharedTable, nil */
  if (! marpaESLIFLua_lua_copy(L, 2, -1)) goto err;                                          /* Stack: marpaESLIFRecognizerTable, marpaESLIFRecognizerSharedTable, marpaESLIFRecognizerSharedTable */
  MARPAESLIFLUA_REF(L, marpaESLIFLuaRecognizerContextp->recognizer_orig_r); /* Stack: marpaESLIFRecognizerTable, marpaESLIFRecognizerSharedTable */

  if (! marpaESLIFRecognizer_shareb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, marpaESLIFLuaRecognizerContextSharedp->marpaESLIFRecognizerp)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_shareb failure, %s", strerror(errno));
    goto err;
  }

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  return 0;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_isCanContinuei(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_isCanContinuei";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  short                             isCanContinueb;
  int                               typei;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_isCanContinue(marpaESLIFRecognizerp, marpaESLIFRecognizerSharedp)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;   /* Stack: marpaESLIFRecognizerTable, marpaESLIFRecognizerSharedTable, marpaESLIFLuaRecognizerContextFromp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_isCanContinueb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, &isCanContinueb)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_isCanContinueb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_pushboolean(L, isCanContinueb)) goto err;

  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_isExhaustedi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_isExhaustedi";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  short                             exhaustedb;
  int                               typei;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_isexhausted(marpaESLIFRecognizerp)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;   /* Stack: marpaESLIFRecognizerTable, marpaESLIFRecognizerSharedTable, marpaESLIFLuaRecognizerContextFromp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_isExhaustedb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, &exhaustedb)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_isExhaustedb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_pushboolean(L, exhaustedb)) goto err;

  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_scani(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_scani";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  short                             initialEventsb = 0;
  int                               typei;
  int                               tmpi;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  switch (topi) {
  case 2:
    if (! marpaESLIFLua_lua_type(&typei, L, 2)) goto err;
    if (typei != LUA_TBOOLEAN) {
      marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_scan(marpaESLIFRecognizerp, initialEvents)");
      goto err;
    }
    if (! marpaESLIFLua_lua_toboolean(&tmpi, L, 2)) goto err;
    initialEventsb = (tmpi != 0) ? 1 : 0;
    /* Intentionnaly no break here */
  case 1:
    if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
    if (typei != LUA_TTABLE) {
      marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
      goto err;
    }
    if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;   /* Stack: marpaESLIFRecognizerTable, initialEventsb?, marpaESLIFLuaRecognizerContextFromp */
    if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;
    break;
  default:
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_scan(marpaESLIFRecognizerp[, initialEvents])");
    goto err;
  }

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFLua_lua_pushboolean(L, marpaESLIFRecognizer_scanb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, initialEventsb, NULL /* continuebp */, NULL /* exhaustedbp */))) goto err;

  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_resumei(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_resumei";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  int                               isNumi;
  int                               deltaLengthi = 0;
  int                               typei;
  lua_Integer                       tmpi;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  switch (topi) {
  case 2:
    if (! marpaESLIFLua_lua_type(&typei, L, 2)) goto err;
    if (typei != LUA_TNUMBER) {
      marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_resume(marpaESLIFRecognizerp, deltaLength) (got typei=%d != %d)");
      goto err;
    }
    if (! marpaESLIFLua_lua_tointegerx(&tmpi, L, 2, &isNumi)) goto err;
    if (! isNumi) {
      marpaESLIFLua_luaL_error(L, "Failed to convert deltaLength argument to an integer");
      goto err;
    }
    deltaLengthi = (int) tmpi;
    if (deltaLengthi < 0) {
      marpaESLIFLua_luaL_error(L, "deltaLength argument cannot be negative");
      goto err;
    }
    /* Intentionnaly no break here */
  case 1:
    if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
    if (typei != LUA_TTABLE) {
      marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
      goto err;
    }
    if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;   /* Stack: marpaESLIFRecognizerTable, deltaLength?, marpaESLIFLuaRecognizerContextFromp */
    if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;
    break;
  default:
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_resume(marpaESLIFRecognizerp[, deltaLength])");
    goto err;
  }

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFLua_lua_pushboolean(L, marpaESLIFRecognizer_resumeb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, (size_t) deltaLengthi, NULL /* continuebp */, NULL /* exhaustedbp */))) goto err;

  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_eventsi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_eventsi";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  size_t                            i;
  size_t                            eventArrayl;
  marpaESLIFEvent_t                *eventArrayp;
  int                               rci;
  int                               typei;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_events(marpaESLIFRecognizerp)");
    goto err;
  }

  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;   /* Stack: marpaESLIFRecognizerTable, initialEventsb?, marpaESLIFLuaRecognizerContextFromp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_eventb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, &eventArrayl, &eventArrayp)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_eventb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_newtable(L)) goto err;                          /* Stack: {} */
  for (i = 0; i < eventArrayl; i++) {
    if (! marpaESLIFLua_lua_newtable(L)) goto err;                        /* Stack: {}, {} */
    MARPAESLIFLUA_STORE_INTEGER(L, "type", eventArrayp[i].type);          /* Stack: {}, {"type" => type} */
    MARPAESLIFLUA_STORE_ASCIISTRING(L, "symbol", eventArrayp[i].symbols); /* Stack: {}, {"type" => type, "symbol" => symbol} */
    MARPAESLIFLUA_STORE_ASCIISTRING(L, "event", eventArrayp[i].events);   /* Stack: {}, {"type" => type, "symbol" => symbol, "event" => event} */
    if (! marpaESLIFLua_lua_seti(L, 1, (lua_Integer) i)) goto err;        /* Stack: {i => {"type" => type, "symbol" => symbol, "event" => event}} */
  }

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_eventOnOffi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs     = "marpaESLIFLua_marpaESLIFRecognizer_eventOnOffi";
  marpaESLIFEventType_t             eventSeti = MARPAESLIF_EVENTTYPE_NONE;
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  const char                       *symbols;
  int                               isNumi;
  int                               codei;
  int                               typei;
  lua_Integer                       tmpi;
  int                               tmpb;
  int                               topi;
  int                               nexti;
  int                               iteratori;
  int                               statevariablei;

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 4) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_eventOnOff(marpaESLIFRecognizerp, symbol, eventTypes, onOff)");
    goto err;
  }

  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;   /* Stack: marpaESLIFRecognizerTable, symbol, eventTypes, onOff, marpaESLIFLuaRecognizerContextFromp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  if (! marpaESLIFLua_lua_type(&typei, L, 2)) goto err;
  if (typei != LUA_TSTRING) {
    marpaESLIFLua_luaL_error(L, "symbol must be a string");
    goto err;
  }
  if (! marpaESLIFLua_lua_tostring(&symbols, L, 2)) goto err;

  if (! marpaESLIFLua_lua_type(&typei, L, 3)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "eventTypes must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_pushnil(L)) goto err;
  while (1) {
    if (! marpaESLIFLua_pairsb(&nexti, L, 3, &iteratori, &statevariablei)) goto err;
    if (nexti == 0) break;
    if (! marpaESLIFLua_lua_tointegerx(&tmpi, L, -1, &isNumi)) goto err;
    if (! isNumi) {
      marpaESLIFLua_luaL_error(L, "Failed to convert event type to an integer");
      goto err;
    }
    codei = (int) tmpi;
    switch (codei) {
    case MARPAESLIF_EVENTTYPE_NONE:
      break;
    case MARPAESLIF_EVENTTYPE_COMPLETED:
    case MARPAESLIF_EVENTTYPE_NULLED:
    case MARPAESLIF_EVENTTYPE_PREDICTED:
    case MARPAESLIF_EVENTTYPE_BEFORE:
    case MARPAESLIF_EVENTTYPE_AFTER:
    case MARPAESLIF_EVENTTYPE_EXHAUSTED:
    case MARPAESLIF_EVENTTYPE_DISCARD:
      eventSeti |= codei;
      break;
    default:
      marpaESLIFLua_luaL_errorf(L, "Unknown code %d", (int) codei);
      goto err;
    }
    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;
  }

  if (! marpaESLIFLua_lua_type(&typei, L, 4)) goto err;
  if (typei != LUA_TBOOLEAN) {
    marpaESLIFLua_luaL_error(L, "onOff must be a boolean");
    goto err;
  }

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFLua_lua_toboolean(&tmpb, L, 4)) goto err;
  if (! marpaESLIFRecognizer_event_onoffb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, (char *) symbols, eventSeti, (tmpb != 0) ? 1 : 0)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_event_onoffb failure, %s", strerror(errno));
    goto err;
  }

  return 0;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_lexemeAlternativei(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_lexemeAlternativei";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  int                               isNumi;
  marpaESLIFAlternative_t           marpaESLIFAlternative;
  int                               typei;
  lua_Integer                       tmpi;
  int                               topi;
 
  marpaESLIFAlternative.lexemes        = NULL;
  marpaESLIFAlternative.grammarLengthl = 1; /* Default value */

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  switch (topi) {
  case 4:
    if (! marpaESLIFLua_lua_type(&typei, L, 4)) goto err;
    if (typei != LUA_TNUMBER) {
      marpaESLIFLua_luaL_error(L, "grammarLength must be a number");
      goto err;
    }
    if (! marpaESLIFLua_lua_tointegerx(&tmpi, L, 4, &isNumi)) goto err;
    if (! isNumi) {
      marpaESLIFLua_luaL_error(L, "Failed to convert grammarLengths to an integer");
      goto err;
    }
    marpaESLIFAlternative.grammarLengthl = (size_t) tmpi;
    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;  /* So that indice -1 points to the value */
    /* Intentionaly no break */
  case 3:
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
    if (typei != LUA_TTABLE) {
      marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
      goto err;
    }
    if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
    if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

    if (! marpaESLIFLua_lua_type(&typei, L, 2)) goto err;
    if (typei != LUA_TSTRING) {
      marpaESLIFLua_luaL_error(L, "name must be a string");
      goto err;
    }
    /* lexemes is valid until we remove it from the stack */
    if (! marpaESLIFLua_lua_tostring((const char **) &(marpaESLIFAlternative.lexemes), L, 2)) goto err;

    /* We convert value at indice -1 to a marpaESLIFValueResult */
    if (! marpaESLIFLua_stack_setb(L, marpaESLIFLuaRecognizerContextp->marpaESLIFp, NULL /* marpaESLIFValuep */, -1 /* resulti */, &(marpaESLIFAlternative.value))) goto err;
    break;
  default:
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_lexemeAlternative(marpaESLIFRecognizerp, name, value[, grammarLength])");
    goto err;
  }

  /* Commit the alternative */
  if (! marpaESLIFLua_lua_pushboolean(L, marpaESLIFRecognizer_lexeme_alternativeb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, &marpaESLIFAlternative))) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_lexemeCompletei(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_lexemeCompletei";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  size_t                            lengthl;
  int                               isNumi;
  int                               typei;
  lua_Integer                       tmpi;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_lexemeComplete(marpaESLIFRecognizerp, length)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  if (! marpaESLIFLua_lua_type(&typei, L, 2)) goto err;
  if (typei != LUA_TNUMBER) {
    marpaESLIFLua_luaL_error(L, "length must be a number");
    goto err;
  }
  if (! marpaESLIFLua_lua_tointegerx(&tmpi, L, 2, &isNumi)) goto err;
  if (! isNumi) {
    marpaESLIFLua_luaL_error(L, "Failed to convert length to an integer");
    goto err;
  }
  lengthl = (size_t) tmpi;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFLua_lua_pushboolean(L, marpaESLIFRecognizer_lexeme_completeb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, lengthl))) goto err;

  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_lexemeReadi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_lexemeReadi";
  size_t                            lengthl;
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  int                               isNumi;
  marpaESLIFAlternative_t           marpaESLIFAlternative;
  int                               typei;
  lua_Integer                       tmpi;
  int                               topi;
 
  marpaESLIFAlternative.lexemes        = NULL;
  marpaESLIFAlternative.grammarLengthl = 1; /* Default value */

  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  switch (topi) {
  case 5:
  if (! marpaESLIFLua_lua_type(&typei, L, 5)) goto err;
    if (typei != LUA_TNUMBER) {
      marpaESLIFLua_luaL_error(L, "grammarLength must be a number");
      goto err;
    }
    if (! marpaESLIFLua_lua_tointegerx(&tmpi, L, 5, &isNumi)) goto err;
    if (! isNumi) {
      marpaESLIFLua_luaL_error(L, "Failed to convert grammarLength to a number");
      goto err;
    }
    marpaESLIFAlternative.grammarLengthl = (size_t) tmpi;
    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;  /* So that indice -1 points to the length */
    /* Intentionnaly no break */
  case 4:
    if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
    if (typei != LUA_TTABLE) {
      marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
      goto err;
    }
    if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
    if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

    if (! marpaESLIFLua_lua_type(&typei, L, 2)) goto err;
    if (typei != LUA_TSTRING) {
      marpaESLIFLua_luaL_error(L, "name must be a string");
      goto err;
    }
    /* lexemes is valid until we remove it from the stack */
    if (! marpaESLIFLua_lua_tostring((const char **) &(marpaESLIFAlternative.lexemes), L, 2)) goto err;

    if (! marpaESLIFLua_lua_type(&typei, L, 4)) goto err;
    if (typei != LUA_TNUMBER) {
      marpaESLIFLua_luaL_error(L, "length must be a number");
      goto err;
    }
    if (! marpaESLIFLua_lua_tointegerx(&tmpi, L, 4, &isNumi)) goto err;
    if (! isNumi) {
      marpaESLIFLua_luaL_error(L, "Failed to convert length to a number");
      goto err;
    }
    lengthl = (size_t) tmpi;
    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;  /* So that indice -1 points to the value */

    /* We convert value at indice -1 to a marpaESLIFValueResult */
    if (! marpaESLIFLua_stack_setb(L, marpaESLIFLuaRecognizerContextp->marpaESLIFp, NULL /* marpaESLIFValuep */, -1 /* resulti */, &(marpaESLIFAlternative.value))) goto err;
    break;
  default:
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_lexemeRead(marpaESLIFRecognizerp, name, value, length[, grammarLength])");
    goto err;
  }

  /* Commit the alternative */
  if (! marpaESLIFLua_lua_pushboolean(L, marpaESLIFRecognizer_lexeme_readb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, &marpaESLIFAlternative, lengthl))) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_lexemeTryi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_lexemeTryi";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  const char                       *names;
  short                            rcb;
  int                              typei;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_lexemeTry(marpaESLIFRecognizerp, name)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  if (! marpaESLIFLua_lua_type(&typei, L, 2)) goto err;
  if (typei != LUA_TSTRING) {
    marpaESLIFLua_luaL_error(L, "name must be a string");
    goto err;
  }
  if (! marpaESLIFLua_lua_tostring(&names, L, 2)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_lexeme_tryb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, (char *) names, &rcb)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_lexeme_tryb failure, %s", strerror(errno));
    goto err;
  }
  
  if (! marpaESLIFLua_lua_pushboolean(L, rcb)) goto err;

  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_discardTryi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_discardTryi";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  short                             rcb;
  int                               typei;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_discardTry(marpaESLIFRecognizerp)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_discard_tryb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, &rcb)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_discard_tryb failure, %s", strerror(errno));
    goto err;
  }
  
  if (! marpaESLIFLua_lua_pushboolean(L, rcb)) goto err;

  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_lexemeExpectedi(lua_State *L)
/*****************************************************************************/
{
  static const char                 *funcs = "marpaESLIFLua_marpaESLIFRecognizer_lexemeExpectedi";
  marpaESLIFLuaRecognizerContext_t  *marpaESLIFLuaRecognizerContextp;
  size_t                             nLexeme;
  char                             **lexemesArrayp;
  int                                typei;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_lexemeExpected(marpaESLIFRecognizerp)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_lexeme_expectedb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, &nLexeme, &lexemesArrayp)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_lexeme_expectedb failure, %s", strerror(errno));
    goto err;
  }
  
  MARPAESLIFLUA_PUSH_ASCIISTRING_ARRAY(L, nLexeme, lexemesArrayp);

  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_lexemeLastPausei(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_lexemeLastPausei";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  const char                       *names;
  char                             *pauses;
  size_t                            pausel;
  int                               typei;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_lexemeLastPause(marpaESLIFRecognizerp, name)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  if (! marpaESLIFLua_lua_type(&typei, L, 2)) goto err;
  if (typei != LUA_TSTRING) {
    marpaESLIFLua_luaL_error(L, "name must be a string");
    goto err;
  }
  if (! marpaESLIFLua_lua_tostring(&names, L, 2)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_lexeme_last_pauseb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, (char *) names, &pauses, &pausel)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_lexeme_last_pauseb failure, %s", strerror(errno));
    goto err;
  }
  
  if ((pauses != NULL) && (pausel > 0)) {
    if (! marpaESLIFLua_lua_pushlstring(NULL, L, (const char *) pauses, pausel)) goto err;
  } else {
    if (! marpaESLIFLua_lua_pushnil(L)) goto err;
  }

  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_lexemeLastTryi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_lexemeLastTryi";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  const char                       *names;
  char                             *trys;
  size_t                            tryl;
  int                               typei;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_lexemeLastTry(marpaESLIFRecognizerp, name)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  if (! marpaESLIFLua_lua_type(&typei, L, 2)) goto err;
  if (typei != LUA_TSTRING) {
    marpaESLIFLua_luaL_error(L, "name must be a string");
    goto err;
  }
  if (! marpaESLIFLua_lua_tostring(&names, L, 2)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_lexeme_last_tryb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, (char *) names, &trys, &tryl)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_lexeme_last_tryb failure, %s", strerror(errno));
    goto err;
  }
  
  if ((trys != NULL) && (tryl > 0)) {
    if (! marpaESLIFLua_lua_pushlstring(NULL, L, (const char *) trys, tryl)) goto err;
  } else {
    if (! marpaESLIFLua_lua_pushnil(L)) goto err;
  }

  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_discardLastTryi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_discardLastTryi";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  char                             *trys;
  size_t                            tryl;
  int                               typei;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_discardLastTry(marpaESLIFRecognizerp)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_discard_last_tryb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, &trys, &tryl)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_discard_last_tryb failure, %s", strerror(errno));
    goto err;
  }
  
  if ((trys != NULL) && (tryl > 0)) {
    if (! marpaESLIFLua_lua_pushlstring(NULL, L, (const char *) trys, tryl)) goto err;
  } else {
    if (! marpaESLIFLua_lua_pushnil(L)) goto err;
  }

  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_discardLasti(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_discardLasti";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  char                             *lasts;
  size_t                            lastl;
  int                               typei;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_discardLast(marpaESLIFRecognizerp)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_discard_lastb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, &lasts, &lastl)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_discard_lastb failure, %s", strerror(errno));
    goto err;
  }
  
  if ((lasts != NULL) && (lastl > 0)) {
    if (! marpaESLIFLua_lua_pushlstring(NULL, L, (const char *) lasts, lastl)) goto err;
  } else {
    if (! marpaESLIFLua_lua_pushnil(L)) goto err;
  }

  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_isEofi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_isEofi";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  short                             eofb;
  int                               typei;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_isEof(marpaESLIFRecognizerp)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_isEofb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, &eofb)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_isEofb failure, %s", strerror(errno));
    goto err;
  }
  
  if (! marpaESLIFLua_lua_pushboolean(L, eofb ? 1 : 0)) goto err;
  
  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_readi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_readi";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  int                               typei;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_read(marpaESLIFRecognizerp)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFLua_lua_pushboolean(L, marpaESLIFRecognizer_readb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, NULL, NULL) ? 1 : 0)) goto err;
  
  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_inputi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_inputi";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  char                             *inputs;
  size_t                            inputl;
  int                               typei;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_read(marpaESLIFRecognizerp)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_inputb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, &inputs, &inputl)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_inputb failure, %s", strerror(errno));
    goto err;
  }

  if ((inputs != NULL) && (inputl > 0)) {
    if (! marpaESLIFLua_lua_pushlstring(NULL, L, (const char *) inputs, inputl)) goto err;
  } else {
    if (! marpaESLIFLua_lua_pushnil(L)) goto err;
  }
  
  return 1;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_progressLogi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_progressLogi";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  int                               starti;
  int                               endi;
  int                               leveli;
  int                               isNumi;
  int                               typei;
  lua_Integer                       tmpi;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 4) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_read(marpaESLIFRecognizerp, start, end, level)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  if (! marpaESLIFLua_lua_type(&typei, L, 2)) goto err;
  if (typei != LUA_TNUMBER) {
    marpaESLIFLua_luaL_error(L, "start must be a number");
    goto err;
  }
  if (! marpaESLIFLua_lua_tointegerx(&tmpi, L, 2, &isNumi)) goto err;
  if (! isNumi) {
    marpaESLIFLua_luaL_error(L, "Failed to convert start to an integer");
    goto err;
  }
  starti = (int) tmpi;

  if (! marpaESLIFLua_lua_type(&typei, L, 3)) goto err;
  if (typei != LUA_TNUMBER) {
    marpaESLIFLua_luaL_error(L, "end must be a number");
    goto err;
  }
  if (! marpaESLIFLua_lua_tointegerx(&tmpi, L, 3, &isNumi)) goto err;
  if (! isNumi) {
    marpaESLIFLua_luaL_error(L, "Failed to convert end to an integer");
    goto err;
  }
  endi = (int) tmpi;

  if (! marpaESLIFLua_lua_type(&typei, L, 4)) goto err;
  if (typei != LUA_TNUMBER) {
    marpaESLIFLua_luaL_error(L, "level must be a number");
    goto err;
  }
  if (! marpaESLIFLua_lua_tointegerx(&tmpi, L, 4, &isNumi)) goto err;
  if (! isNumi) {
    marpaESLIFLua_luaL_error(L, "Failed to convert level to an integer");
    goto err;
  }
  leveli = (int) tmpi;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  switch (leveli) {
  case GENERICLOGGER_LOGLEVEL_TRACE:
  case GENERICLOGGER_LOGLEVEL_DEBUG:
  case GENERICLOGGER_LOGLEVEL_INFO:
  case GENERICLOGGER_LOGLEVEL_NOTICE:
  case GENERICLOGGER_LOGLEVEL_WARNING:
  case GENERICLOGGER_LOGLEVEL_ERROR:
  case GENERICLOGGER_LOGLEVEL_CRITICAL:
  case GENERICLOGGER_LOGLEVEL_ALERT:
  case GENERICLOGGER_LOGLEVEL_EMERGENCY:
    break;
  default:
    marpaESLIFLua_luaL_errorf(L, "Unknown logger level %d", leveli);
    goto err;
    break;
  }

  if (! marpaESLIFRecognizer_progressLogb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, starti, endi, leveli)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_progressLogb failure, %s", strerror(errno));
    goto err;
  }
  
  return 0;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_lastCompletedOffseti(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_lastCompletedOffseti";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  const char                       *names;
  char                             *offsetp;
  size_t                            offsetl;
  int                               rci;
  int                               typei;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_lastCompletedOffset(marpaESLIFRecognizerp, name)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  if (! marpaESLIFLua_lua_type(&typei, L, 2)) goto err;
  if (typei != LUA_TSTRING) {
    marpaESLIFLua_luaL_error(L, "name must be a string");
    goto err;
  }
  if (! marpaESLIFLua_lua_tostring(&names, L, 2)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_last_completedb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, (char *) names, &offsetp, NULL /* lengthlp */)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_last_completedb failure, %s", strerror(errno));
    goto err;
  }

  offsetl = (size_t) offsetp;

  if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) offsetl)) goto err;

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_lastCompletedLengthi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_lastCompletedLenghti";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  const char                       *names;
  size_t                            lengthl;
  int                               rci;
  int                               typei;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_lastCompletedLength(marpaESLIFRecognizerp, name)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  if (! marpaESLIFLua_lua_type(&typei, L, 2)) goto err;
  if (typei != LUA_TSTRING) {
    marpaESLIFLua_luaL_error(L, "name must be a string");
    goto err;
  }
  if (! marpaESLIFLua_lua_tostring(&names, L, 2)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_last_completedb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, (char *) names, NULL /* offsetpp */, &lengthl)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_last_completedb failure, %s", strerror(errno));
    goto err;
  }
  
  if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) lengthl)) goto err;

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_lastCompletedLocationi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_lastCompletedLocationi";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  const char                       *names;
  char                             *offsetp;
  size_t                            lengthl;
  size_t                            offsetl;
  int                               rci;
  int                               typei;
  int                               topi;
 
  if (! marpaESLIFLua_lua_gettop(&topi, L)) goto err;
  if (topi != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_lastCompletedLocation(marpaESLIFRecognizerp, name)");
    goto err;
  }
  
  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  if (! marpaESLIFLua_lua_type(&typei, L, 2)) goto err;
  if (typei != LUA_TSTRING) {
    marpaESLIFLua_luaL_error(L, "name must be a string");
    goto err;
  }
  if (! marpaESLIFLua_lua_tostring(&names, L, 2)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_last_completedb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, (char *) names, &offsetp, &lengthl)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_last_completedb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_newtable(L)) goto err;
  offsetl = (size_t) offsetp;
  MARPAESLIFLUA_STORE_INTEGER(L, "offset", (lua_Integer) offsetl);
  MARPAESLIFLUA_STORE_INTEGER(L, "length", (lua_Integer) lengthl);

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_linei(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_linei";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  size_t                            linel;
  int                               rci;
  int                               typei;

  if (lua_gettop(L) != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_line(marpaESLIFRecognizerp)");
    goto err;
  }

  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_locationb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, &linel, NULL /* columnlp */)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_locationb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) linel)) goto err;

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_columni(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_columni";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  size_t                            columnl;
  int                               rci;
  int                               typei;

  if (lua_gettop(L) != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_column(marpaESLIFRecognizerp)");
    goto err;
  }

  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_locationb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, NULL /* linelp */, &columnl)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_locationb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) columnl)) goto err;

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_locationi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_locationi";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  size_t                            linel;
  size_t                            columnl;
  int                               rci;
  int                               typei;

  if (lua_gettop(L) != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_location(marpaESLIFRecognizerp)");
    goto err;
  }

  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_locationb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, &linel, &columnl)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_locationb failure, %s", strerror(errno));
    goto err;
  }

  if (! marpaESLIFLua_lua_createtable(L, 2, 0)) goto err;                                                 /* stack; {} */
  MARPAESLIFLUA_STORE_INTEGER(L, "line",   linel);
  MARPAESLIFLUA_STORE_INTEGER(L, "column", columnl);

  rci = 1;
  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_hookDiscardi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_hookDiscardi";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  short                             discardOnOffb;
  int                               typei;
  int                               tmpi;

  if (lua_gettop(L) != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_hookDiscard(marpaESLIFRecognizerp, discardOnOff)");
    goto err;
  }

  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  if (! marpaESLIFLua_lua_type(&typei, L, 2)) goto err;
  if (typei != LUA_TBOOLEAN) {
    marpaESLIFLua_luaL_error(L, "discardOnOff must be a boolean");
    goto err;
  }
  if (! marpaESLIFLua_lua_toboolean(&tmpi, L, 2)) goto err;
  discardOnOffb = (tmpi != 0) ? 1 : 0;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_hook_discardb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, discardOnOffb)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_hook_discardb failure, %s", strerror(errno));
    goto err;
  }

  return 0;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFRecognizer_hookDiscardSwitchi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFRecognizer_hookDiscardSwitchi";
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  int                               typei;

  if (lua_gettop(L) != 1) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFRecognizer_hookDiscardSwitch(marpaESLIFRecognizerp)");
    goto err;
  }

  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  if (! marpaESLIFRecognizer_hook_discard_switchb(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFRecognizer_hook_discard_switchb failure, %s", strerror(errno));
    goto err;
  }

  return 0;

 err:
  return 0;
}

/*****************************************************************************/
static int marpaESLIFLua_marpaESLIFValue_newi(lua_State *L)
/*****************************************************************************/
{
  static const char                *funcs = "marpaESLIFLua_marpaESLIFValue_newi";
  marpaESLIFValueOption_t           marpaESLIFValueOption;
  marpaESLIFLuaRecognizerContext_t *marpaESLIFLuaRecognizerContextp;
  marpaESLIFLuaValueContext_t      *marpaESLIFLuaValueContextp;
  int                               typei;
  marpaESLIF_t                     *marpaESLIFp;

  if (lua_gettop(L) != 2) {
    marpaESLIFLua_luaL_error(L, "Usage: marpaESLIFValue_new(marpaESLIFRecognizerp, valueInterface)");
    goto err;
  }

  if (! marpaESLIFLua_lua_type(&typei, L, 1)) goto err;
  if (typei != LUA_TTABLE) {
    marpaESLIFLua_luaL_error(L, "marpaESLIFRecognizerp must be a table");
    goto err;
  }
  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaRecognizerContextp")) goto err;
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaRecognizerContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  marpaESLIFLua_paramIsValueInterfacev(L, 2);

  marpaESLIFLuaValueContextp = (marpaESLIFLuaValueContext_t *) malloc(sizeof(marpaESLIFLuaValueContext_t));
  if (marpaESLIFLuaValueContextp == NULL) {
    marpaESLIFLua_luaL_errorf(L, "malloc failure, %s", strerror(errno));
    goto err;
  }

  marpaESLIFp = marpaESLIFLuaRecognizerContextp->marpaESLIFp;
  if (! marpaESLIFLua_valueContextInitb(L, marpaESLIFp, 0 /* grammarStacki */, 1 /* recognizerStacki */, 2 /* valueInterfaceStacki */, marpaESLIFLuaValueContextp, 0 /* unmanagedb */, 1 /* grammarStackiCanBeZerob */)) goto err;

  marpaESLIFValueOption.userDatavp             = marpaESLIFLuaValueContextp;
  marpaESLIFValueOption.ruleActionResolverp    = marpaESLIFLua_valueRuleActionResolver;
  marpaESLIFValueOption.symbolActionResolverp  = marpaESLIFLua_valueSymbolActionResolver;
  marpaESLIFValueOption.importerp              = marpaESLIFLua_importb;
  MARPAESLIFLUA_CALLBACKB(L, marpaESLIFLuaValueContextp->valueInterface_r, "isWithHighRankOnly", 0 /* nargs */, MARPAESLIFLUA_NOOP, &(marpaESLIFValueOption.highRankOnlyb));
  MARPAESLIFLUA_CALLBACKB(L, marpaESLIFLuaValueContextp->valueInterface_r, "isWithOrderByRank",  0 /* nargs */, MARPAESLIFLUA_NOOP, &(marpaESLIFValueOption.orderByRankb));
  MARPAESLIFLUA_CALLBACKB(L, marpaESLIFLuaValueContextp->valueInterface_r, "isWithAmbiguous",    0 /* nargs */, MARPAESLIFLUA_NOOP, &(marpaESLIFValueOption.ambiguousb));
  MARPAESLIFLUA_CALLBACKB(L, marpaESLIFLuaValueContextp->valueInterface_r, "isWithNull",         0 /* nargs */, MARPAESLIFLUA_NOOP, &(marpaESLIFValueOption.nullb));
  MARPAESLIFLUA_CALLBACKI(L, marpaESLIFLuaValueContextp->valueInterface_r, "maxParses",          0 /* nargs */, MARPAESLIFLUA_NOOP, &(marpaESLIFValueOption.maxParsesi));

  marpaESLIFLuaValueContextp->marpaESLIFValuep = marpaESLIFValue_newp(marpaESLIFLuaRecognizerContextp->marpaESLIFRecognizerp, &marpaESLIFValueOption);
  if (marpaESLIFLuaValueContextp->marpaESLIFValuep == NULL) {
    int save_errno = errno;
    marpaESLIFLua_valueContextFreev(marpaESLIFLuaValueContextp, 0 /* onStackb */);
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFValue_newp failure, %s", strerror(save_errno));
    goto err;
  }

  marpaESLIFLuaValueContextp->managedb = 1;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  MARPAESLIFLUA_PUSH_MARPAESLIFVALUE_OBJECT(L, marpaESLIFLuaValueContextp);

  return 1;

 err:
  return 0;
}

#ifdef MARPAESLIFLUA_EMBEDDED
/****************************************************************************/
static int marpaESLIFLua_marpaESLIFValue_newFromUnmanagedi(lua_State *L, marpaESLIFValue_t *marpaESLIFValueUnmanagedp)
/****************************************************************************/
{
  static const char           *funcs = "marpaESLIFLua_marpaESLIFValue_newFromUnmanagedi";
  marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp;
  marpaESLIF_t                *marpaESLIFp;

  marpaESLIFLuaValueContextp = malloc(sizeof(marpaESLIFLuaValueContext_t));
  if (marpaESLIFLuaValueContextp == NULL) {
    marpaESLIFLua_luaL_errorf(L, "malloc failure, %s", strerror(errno));
    goto err;
  }

  marpaESLIFp = marpaESLIFGrammar_eslifp(marpaESLIFRecognizer_grammarp(marpaESLIFValue_recognizerp(marpaESLIFValueUnmanagedp)));
  if (! marpaESLIFLua_valueContextInitb(L, marpaESLIFp, 0 /* grammarStacki */, 0 /* recognizerStacki */, 0 /* valueInterfaceStacki */, marpaESLIFLuaValueContextp, 1 /* unmanagedb */, 1 /* grammarStackiCanBeZerob */)) goto err;
  marpaESLIFLuaValueContextp->marpaESLIFValuep = marpaESLIFValueUnmanagedp;
  marpaESLIFLuaValueContextp->managedb           = 0;

  /* We are in embedded code, this mean that we have access to marpaESLIFValue structure */
  marpaESLIFValueUnmanagedp->marpaESLIFLuaValueContextp = marpaESLIFLuaValueContextp;

  MARPAESLIFLUA_PUSH_MARPAESLIFVALUE_OBJECT(L, marpaESLIFLuaValueContextp);

  return 1;

 err:
  return 0;
}
#endif /* MARPAESLIFLUA_EMBEDDED */

/****************************************************************************/
static int marpaESLIFLua_marpaESLIFValue_freei(lua_State *L)
/****************************************************************************/
{
  static const char           *funcs = "marpaESLIFLua_marpaESLIFValue_freei";
  marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp;

  if (! marpaESLIFLua_lua_getfield(NULL,L, -1, "marpaESLIFLuaValueContextp")) goto err; /* Stack: {...}, marpaESLIFLuaValueContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaValueContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  marpaESLIFLua_valueContextFreev(marpaESLIFLuaValueContextp, 0 /* onStackb */);

  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  return 0;

 err:
  return 0;
}

/****************************************************************************/
static int marpaESLIFLua_marpaESLIFValue_valuei(lua_State *L)
/****************************************************************************/
{
  static const char           *funcs = "marpaESLIFLua_marpaESLIFValue_valuei";
  marpaESLIFLuaValueContext_t *marpaESLIFLuaValueContextp;
  short                        valueb;
  int                          rci;
  int                          resultStacki;

  if (! marpaESLIFLua_lua_getfield(NULL,L, 1, "marpaESLIFLuaValueContextp")) goto err; /* Stack: {...}, marpaESLIFLuaValueContextp */
  if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFLuaValueContextp, L, -1)) goto err;
  if (! marpaESLIFLua_lua_pop(L, 1)) goto err;

  /* Clear the stack */
  if (! marpaESLIFLua_lua_settop(L, 0)) goto err;

  valueb = marpaESLIFValue_valueb(marpaESLIFLuaValueContextp->marpaESLIFValuep);
  if (valueb < 0) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFValue_valueb failure, %s", strerror(errno));
    goto err;
  }

  if (valueb > 0) {
    resultStacki = lua_gettop(L);
    /* marpaESLIFValue_valueb called the importer that pushed the final value to the stack */
    MARPAESLIFLUA_CALLBACKV(L, marpaESLIFLuaValueContextp->valueInterface_r, "setResult", 1 /* nargs */, if (! marpaESLIFLua_lua_pushnil(L)) goto err; if (! marpaESLIFLua_lua_copy(L, resultStacki, -1)) goto err;);
    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;
    rci = 1;
  } else {
    rci = 0;
  }

  if (! marpaESLIFLua_lua_pushboolean(L, rci)) goto err;

  return 1;

 err:
  return 0;
}

/****************************************************************************/
/* When MARPAESLIFLUA_EMBEDDED the file that includes this source must      */
/* provide the following implementations.                                   */
/****************************************************************************/
#ifndef MARPAESLIFLUA_EMBEDDED

/****************************************************************************/
static short marpaESLIFLua_lua_pushinteger(lua_State *L, lua_Integer n)
/****************************************************************************/
{
  lua_pushinteger(L, n); /* Native lua call */
  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_setglobal (lua_State *L, const char *name)
/****************************************************************************/
{
  lua_setglobal(L, name); /* Native lua call */
  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_getglobal (int *luaip, lua_State *L, const char *name)
/****************************************************************************/
{
  int luai;

#if LUA_VERSION_NUM < 503
  lua_getglobal(L, name); /* Native lua call */
  luai = lua_type(L, -1);
#else
  luai = lua_getglobal(L, name); /* Native lua call */
#endif
  if (luaip != NULL) *luaip = luai;

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_type(int *luaip, lua_State *L, int index)
/****************************************************************************/
{
  int luai;

  luai = lua_type(L, index); /* Native lua call */
  if (luaip != NULL) *luaip = luai;

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_pop(lua_State *L, int n)
/****************************************************************************/
{
  lua_pop(L, n); /* Native lua call */
  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_newtable(lua_State *L)
/****************************************************************************/
{
  lua_newtable(L); /* Native lua call */
  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushcfunction (lua_State *L, lua_CFunction f)
/****************************************************************************/
{
  lua_pushcfunction(L, f); /* Native lua call */
  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_setfield(lua_State *L, int index, const char *k)
/****************************************************************************/
{
  lua_setfield(L, index, k); /* Native lua call */
  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_setmetatable (lua_State *L, int index)
/****************************************************************************/
{

  lua_setmetatable(L, index); /* Native lua call */
  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_insert(lua_State *L, int index)
/****************************************************************************/
{
  lua_insert(L, index); /* Native lua call */
  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawgeti(int *luaip, lua_State *L, int index, lua_Integer n)
/****************************************************************************/
{
  int luai;

#if LUA_VERSION_NUM < 503
  lua_rawgeti(L, index, n); /* Native lua call */
  luai = lua_type(L, -1);
#else
  luai = lua_rawgeti(L, index, n); /* Native lua call */
#endif
  if (luaip != NULL) *luaip = luai;

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawget(int *luaip, lua_State *L, int index)
/****************************************************************************/
{
  int luai;

#if LUA_VERSION_NUM < 503
  lua_rawget(L, index); /* Native lua call */
  luai = lua_type(L, -1);
#else
  luai = lua_rawget(L, index); /* Native lua call */
#endif
  if (luaip != NULL) *luaip = luai;

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawgetp(int *luaip, lua_State *L, int index, const void *p)
/****************************************************************************/
{
  int luai;

#if LUA_VERSION_NUM < 503
  lua_rawgetp(L, index, p); /* Native lua call */
  luai = lua_type(L, -1);
#else
  luai = lua_rawgetp(L, index, p); /* Native lua call */
#endif
  if (luaip != NULL) *luaip = luai;

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_remove(lua_State *L, int index)
/****************************************************************************/
{
  lua_remove(L, index); /* Native lua call */

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_createtable(lua_State *L, int narr, int nrec)
/****************************************************************************/
{
  lua_createtable(L, narr, nrec); /* Native lua call */

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawseti(lua_State *L, int index, lua_Integer i)
/****************************************************************************/
{
  lua_rawseti(L, index, i); /* Native lua call */

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_seti(lua_State *L, int index, lua_Integer i)
/****************************************************************************/
{
#if LUA_VERSION_NUM < 503
  /* C.f. https://github.com/keplerproject/lua-compat-5.3/blob/master/c-api/compat-5.3c */
  luaL_checkstack(L, 1, "not enough stack slots available");
  index = lua_absindex(L, index);
  lua_pushinteger(L, i);                  /* Stack: ..., value at top of the stack, i */
  lua_insert(L, -2);                      /* Stack: ..., i, value at top of the stack */
  lua_settable(L, index);                 /* Stack: ... */
#else
  lua_seti(L, index, i); /* Native lua call */
#endif

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushstring(const char **luasp, lua_State *L, const char *s)
/****************************************************************************/
{
  const char *luas;

  luas = lua_pushstring(L, s); /* Native lua call */
  if (luasp != NULL) *luasp = luas;

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushlstring(const char **luasp, lua_State *L, const char *s, size_t len)
/****************************************************************************/
{
  const char *luas;

  luas = lua_pushlstring(L, s, len); /* Native lua call */
  if (luasp != NULL) *luasp = luas;

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushnil(lua_State *L)
/****************************************************************************/
{
  lua_pushnil(L); /* Native lua call */

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_getfield(int *luaip, lua_State *L, int index, const char *k)
/****************************************************************************/
{
  int luai;

#if LUA_VERSION_NUM < 503
  lua_getfield(L, index, k); /* Native lua call */
  luai = lua_type(L, -1);
#else
  luai = lua_getfield(L, index, k); /* Native lua call */
#endif
  if (luaip != NULL) *luaip = luai;

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_call(lua_State *L, int nargs, int nresults)
/****************************************************************************/
{
  lua_call(L, nargs, nresults); /* Native lua call */

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_settop(lua_State *L, int index)
/****************************************************************************/
{
  lua_settop(L, index); /* Native lua call */

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_copy(lua_State *L, int fromidx, int toidx)
/****************************************************************************/
{
  lua_copy(L, fromidx, toidx); /* Native lua call */

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawsetp(lua_State *L, int index, const void *p)
/****************************************************************************/
{
  lua_rawsetp(L, index, p); /* Native lua call */

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawset(lua_State *L, int index)
/****************************************************************************/
{
  lua_rawset(L, index); /* Native lua call */

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushboolean(lua_State *L, int b)
/****************************************************************************/
{
  lua_pushboolean(L, b); /* Native lua call */

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushnumber(lua_State *L, lua_Number n)
/****************************************************************************/
{
  lua_pushnumber(L, n); /* Native lua call */

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushlightuserdata(lua_State *L, void *p)
/****************************************************************************/
{
  lua_pushlightuserdata(L, p); /* Native lua call */

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_newuserdata(void **rcpp, lua_State *L, size_t sz)
/****************************************************************************/
{
  void *rcp;

  rcp = lua_newuserdata(L, sz);
  if (rcpp != NULL) *rcpp = rcp;

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushvalue(lua_State *L, int index)
/****************************************************************************/
{
  lua_pushvalue(L, index); /* Native lua call */

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_luaL_ref(int *rcip, lua_State *L, int t)
/****************************************************************************/
{
  int rci;

  rci = luaL_ref(L, t); /* Native lua call */
  if (rcip != NULL) *rcip = rci;

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_luaL_unref(lua_State *L, int t, int ref)
/****************************************************************************/
{
  luaL_unref(L, t, ref); /* Native lua call */
  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_luaL_requiref(lua_State *L, const char *modname, lua_CFunction openf, int glb)
/****************************************************************************/
{
  luaL_requiref(L, modname, openf, glb); /* Native lua call */
  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_touserdata(void **rcpp, lua_State *L, int idx)
/****************************************************************************/
{
  void *rcp;

  rcp = lua_touserdata(L, idx); /* Native lua call */
  if (rcpp != NULL) {
    *rcpp = rcp;
  }
  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_tointeger(lua_Integer *rcip, lua_State *L, int idx)
/****************************************************************************/
{
  lua_Integer rci;

  rci = lua_tointeger(L, idx);
  if (rcip != NULL) {
    *rcip = rci;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_tointegerx(lua_Integer *rcip, lua_State *L, int idx, int *isnum)
/****************************************************************************/
{
  lua_Integer rci;

  rci = lua_tointegerx(L, idx, isnum);
  if (rcip != NULL) {
    *rcip = rci;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_tonumber(lua_Number *rcdp, lua_State *L, int idx)
/****************************************************************************/
{
  lua_Number rcd;

  rcd = lua_tonumber(L, idx);
  if (rcdp != NULL) {
    *rcdp = rcd;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_tonumberx(lua_Number *rcdp, lua_State *L, int idx, int *isnum)
/****************************************************************************/
{
  lua_Number rcd;

  rcd = lua_tonumberx(L, idx, isnum);
  if (rcdp != NULL) {
    *rcdp = rcd;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_toboolean(int *rcip, lua_State *L, int idx)
/****************************************************************************/
{
  int rci;

  rci = lua_toboolean(L, idx);
  if (rcip != NULL) {
    *rcip = rci;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_luaL_tolstring(const char **rcpp, lua_State *L, int idx, size_t *len)
/****************************************************************************/
{
  const char *rcp;

  rcp = luaL_tolstring(L, idx, len);
  if (rcpp != NULL) {
    *rcpp = rcp;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_tolstring(const char **rcpp, lua_State *L, int idx, size_t *len)
/****************************************************************************/
{
  const char *rcp;

  rcp = lua_tolstring(L, idx, len);
  if (rcpp != NULL) {
    *rcpp = rcp;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_tostring(const char **rcpp, lua_State *L, int idx)
/****************************************************************************/
{
  const char *rcp;

  rcp = lua_tostring(L, idx);
  if (rcpp != NULL) {
    *rcpp = rcp;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_compare(int *rcip, lua_State *L, int idx1, int idx2, int op)
/****************************************************************************/
{
  int rci;

  rci = lua_compare(L, idx1, idx2, op);
  if (rcip != NULL) {
    *rcip = rci;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawequal(int *rcip, lua_State *L, int idx1, int idx2)
/****************************************************************************/
{
  int rci;

  rci = lua_rawequal(L, idx1, idx2);
  if (rcip != NULL) {
    *rcip = rci;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_isnil(int *rcip, lua_State *L, int n)
/****************************************************************************/
{
  int rci;

  rci = lua_isnil(L, n);
  if (rcip != NULL) {
    *rcip = rci;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_gettop(int *rcip, lua_State *L)
/****************************************************************************/
{
  int rci;

  rci = lua_gettop(L);
  if (rcip != NULL) {
    *rcip = rci;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_absindex(int *rcip, lua_State *L, int idx)
/****************************************************************************/
{
  int rci;

  rci = lua_absindex(L, idx);
  if (rcip != NULL) {
    *rcip = rci;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_next(int *rcip, lua_State *L, int idx)
/****************************************************************************/
{
  int rci;

  rci = lua_next(L, idx);
  if (rcip != NULL) {
    *rcip = rci;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_luaL_checklstring(const char **rcpp, lua_State *L, int arg, size_t *l)
/****************************************************************************/
{
  const char *rcp;

  rcp = luaL_checklstring(L, arg, l);
  if (rcpp != NULL) {
    *rcpp = rcp;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_luaL_checkstring(const char **rcpp, lua_State *L, int arg)
/****************************************************************************/
{
  const char *rcp;

  rcp = luaL_checkstring(L, arg);
  if (rcpp != NULL) {
    *rcpp = rcp;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_luaL_checkinteger(lua_Integer *rcp, lua_State *L, int arg)
/****************************************************************************/
{
  lua_Integer rc;

  rc = luaL_checkinteger(L, arg);
  if (rcp != NULL) {
    *rcp = rc;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_getmetatable(int *rcip, lua_State *L, int index)
/****************************************************************************/
{
  int rci;

  rci = lua_getmetatable(L, index);
  if (rcip != NULL) {
    *rcip = rci;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_luaL_callmeta(int *rcp, lua_State *L, int obj, const char *e)
/****************************************************************************/
{
  int rc;

  rc = luaL_callmeta(L, obj, e);
  if (rcp != NULL) {
    *rcp = rc;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_luaL_getmetafield(int *rcp, lua_State *L, int obj, const char *e)
/****************************************************************************/
{
  int rc;

  rc = luaL_getmetafield(L, obj, e);
  if (rcp != NULL) {
    *rcp = rc;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_luaL_checktype(lua_State *L, int arg, int t)
/****************************************************************************/
{
  luaL_checktype(L, arg, t);

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_topointer(const void **rcpp, lua_State *L, int idx)
/****************************************************************************/
{
  const void *rcp;

  rcp = lua_topointer(L, idx);
  if (rcpp != NULL) {
    *rcpp = rcp;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_rawlen(size_t *rcp, lua_State *L, int idx)
/****************************************************************************/
{
  size_t rc;

  rc = lua_rawlen(L, idx);
  if (rcp != NULL) {
    *rcp = rc;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_luaL_dostring(int *rcp, lua_State *L, const char *fn)
/****************************************************************************/
{
  int rc;

  rc = luaL_dostring(L, fn);
  if (rcp != NULL) {
    *rcp = rc;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_luaL_loadstring(int *rcp, lua_State *L, const char *fn)
/****************************************************************************/
{
  int rc;

  rc = luaL_loadstring(L, fn);
  if (rcp != NULL) {
    *rcp = rc;
  }

  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_pushglobaltable(lua_State *L)
/****************************************************************************/
{
  lua_pushglobaltable(L);
  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_settable(lua_State *L, int idx)
/****************************************************************************/
{
  lua_settable(L, idx);
  return 1;
}

/****************************************************************************/
static short marpaESLIFLua_lua_gettable(int *rcip, lua_State *L, int idx)
/****************************************************************************/
{
  int rci;

#if LUA_VERSION_NUM < 503
  lua_gettable(L, idx);
  rci = lua_type(L, -1);
#else
  rci = lua_gettable(L, idx);
#endif
  if (rcip != NULL) *rcip = rci;

  return 1;
}

#endif /* MARPAESLIFLUA_EMBEDDED */

/****************************************************************************/
static short marpaESLIFLua_stack_setb(lua_State *L, marpaESLIF_t *marpaESLIFp, marpaESLIFValue_t *marpaESLIFValuep, int resulti, marpaESLIFValueResult_t *marpaESLIFValueResultOutputp)
/****************************************************************************/
/* Take care: IF resulti is >= 0, then marpaESLIFValuep must be != NULL */
/****************************************************************************/
{
  static const char            *funcs          = "marpaESLIFLua_stack_setb";
  char                         *p              = NULL;
  char                         *encodingasciis = NULL;
  int                          *ip             = NULL;
  genericStack_t                marpaESLIFValueResultStack;
  genericStack_t               *marpaESLIFValueResultStackp = &(marpaESLIFValueResultStack);
  short                         eslifb;
  short                         rcb;
  int                           typei;
  marpaESLIFValueResult_t       marpaESLIFValueResult;
  marpaESLIFValueResult_t      *marpaESLIFValueResultp;
  lua_Integer                   tmpi;
  lua_Number                    tmpd;
  int                           tmpb;
  int                           isNumi;
  const char                   *tmps;
  size_t                        tmpl;
  size_t                        tablel;
  size_t			tableNextl;
  short                         tableIsArrayb;
  short                         tableIsRecursiveb;
  size_t                        i;
  int                           keyTypei;
  lua_Integer                   keyi;
  int                           keyIsNumi;
  int                           valueTypei;
  int                           isnili;
  int                           visitedTableIndicei;
  int                           nexti;
  int                           currenti;
  short                         canarrayb;
  lua_Integer                   arrayl;
  short                         opaqueb;
  int                           iteratori;
  int                           statevariablei;
  int                           encodingtypei;
  const char                   *encodings;
  marpaESLIFValueResult_t      *marpaESLIFValueResultDupp;
  const void                   *pointerp;
  int                           opaqueTypei;
#ifdef MARPAESLIFLUA_AUTO_ENCODING_DETECT
  short                         encodingheapb;
#endif

  /* fprintf(stdout, "export start\n"); fflush(stdout); fflush(stderr); */
  
  GENERICSTACK_INIT(marpaESLIFValueResultStackp);
  if (GENERICSTACK_ERROR(marpaESLIFValueResultStackp)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFValueResultStackp initialization failure, %s", strerror(errno));
    marpaESLIFValueResultStackp = NULL;
    goto err;
  }

  /* Unshift a "visited" table in the stack and remember its indice */
  if (! marpaESLIFLua_lua_createtable(L, 0, 0)) goto err;                                        /* Stack: xxx, visitedTable */
  if (! marpaESLIFLua_lua_insert(L, -2)) goto err;                                               /* Stack: visitedTable, xxx */
  if (! marpaESLIFLua_lua_absindex(&visitedTableIndicei, L, -2)) goto err;

  /* We synchronize the number of marpaESLIFValueResult in the internal stack with a "TO DO" items in the lua stack */
  if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                                 /* Stack: visitedTable, xxx, nil */
  if (! marpaESLIFLua_lua_copy(L, -2, -1)) goto err;                                            /* Stack: visitedTable, xxx, xxx */
  GENERICSTACK_PUSH_PTR(marpaESLIFValueResultStackp, &marpaESLIFValueResult);
  if (GENERICSTACK_ERROR(marpaESLIFValueResultStackp)) {
    marpaESLIFLua_luaL_errorf(L, "marpaESLIFValueResultStackp push failure, %s", strerror(errno));
    goto err;
  }

  /* From now on we work with visitedTable at indice visitedTableIndicei */
  /* Work item it always at indice -1 */
  
  while (GENERICSTACK_USED(marpaESLIFValueResultStackp) > 0) {
    /* fprintf(stderr, "GENERICSTACK_USED(marpaESLIFValueResultStackp)=%d\n", GENERICSTACK_USED(marpaESLIFValueResultStackp)); */
    marpaESLIFValueResultp = (marpaESLIFValueResult_t *) GENERICSTACK_POP_PTR(marpaESLIFValueResultStackp);
    /* fprintf(stderr, "GENERICSTACK_POP_PTR(marpaESLIFValueResultStackp) -> %p\n", marpaESLIFValueResultp); */

    if (! marpaESLIFLua_lua_absindex(&currenti, L, -1)) goto err;
    if (! marpaESLIFLua_metatypeb(&typei, L, currenti)) goto err;

    eslifb = 0;
    switch (typei) {
    case LUA_TNIL:
      /* fprintf(stderr, "UNDEF\n"); */
      marpaESLIFValueResultp->contextp        = MARPAESLIFLUA_CONTEXT;
      marpaESLIFValueResultp->representationp = NULL;
      marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_UNDEF;
      eslifb = 1;
      break;
    case LUA_TNUMBER:
      /* Is is a lua integer ? */
      if (! marpaESLIFLua_lua_tointegerx(&tmpi, L, currenti, &isNumi)) goto err;
      if (isNumi) {
        if ((tmpi >= SHRT_MIN) && (tmpi <= SHRT_MAX)) {
          /* Does it fit in a native C short ? */
          /* fprintf(stderr, "SHORT %d\n", (int) tmpi); */
          marpaESLIFValueResultp->contextp        = MARPAESLIFLUA_CONTEXT;
          marpaESLIFValueResultp->representationp = NULL;
          marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_SHORT;
          marpaESLIFValueResultp->u.b             = (short) tmpi;
          eslifb = 1;
        } else if ((tmpi >= INT_MIN) && (tmpi <= INT_MAX)) {
          /* Does it fit in a native C int ? */
          /* fprintf(stderr, "INT %d\n", (int) tmpi); */
          marpaESLIFValueResultp->contextp        = MARPAESLIFLUA_CONTEXT;
          marpaESLIFValueResultp->representationp = NULL;
          marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_INT;
          marpaESLIFValueResultp->u.i             = (int) tmpi;
          eslifb = 1;
        } else if ((tmpi >= LONG_MIN) && (tmpi <= LONG_MAX)) {
          /* Does it fit in a native C long ? */
          /* fprintf(stderr, "LONG %ld\n", (long) tmpi); */
          marpaESLIFValueResultp->contextp        = MARPAESLIFLUA_CONTEXT;
          marpaESLIFValueResultp->representationp = NULL;
          marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_LONG;
          marpaESLIFValueResultp->u.l             = (long) tmpi;
          eslifb = 1;
#ifdef MARPAESLIF_HAVE_LONG_LONG
        } else if ((tmpi >= MARPAESLIF_LLONG_MIN) && (tmpi <= MARPAESLIF_LLONG_MAX)) {
          /* Does it fit in a native C long long ? */
          /* fprintf(stderr, "LONG_LONG\n"); */
          marpaESLIFValueResultp->contextp        = MARPAESLIFLUA_CONTEXT;
          marpaESLIFValueResultp->representationp = NULL;
          marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_LONG_LONG;
          marpaESLIFValueResultp->u.ll            = (MARPAESLIF_LONG_LONG) tmpi;
          eslifb = 1;
#endif
        }
      }
#if defined(LUA_FLOAT_TYPE)
        /* Knowing which float type is used by lua is not that easy if we want to be */
        /* portable. From code introspection, IF the following defines exists: */
        /* LUA_FLOAT_FLOAT, LUA_FLOAT_DOUBLE, then, IF the following defines exists: */
        /* LUA_FLOAT_TYPE, then this give an internal representation that we can map to marpaESLIF. */
      else {
        if (! marpaESLIFLua_lua_tonumberx(&tmpd, L, currenti, &isNumi)) goto err;
        if (isNumi) {
#  if defined(LUA_FLOAT_FLOAT) && (LUA_FLOAT_FLOAT == LUA_FLOAT_TYPE)
          /* Lua uses native C float */
          /* fprintf(stderr, "FLOAT %f\n", (double) tmpd); */
          marpaESLIFValueResultp->contextp        = MARPAESLIFLUA_CONTEXT;
          marpaESLIFValueResultp->representationp = NULL;
          marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_FLOAT;
          marpaESLIFValueResultp->u.f             = tmpd; /* We volontarily do not typecast, there should be no warning */
          eslifb = 1;
#  else
#    if defined(LUA_FLOAT_DOUBLE) && (LUA_FLOAT_DOUBLE == LUA_FLOAT_TYPE)
          /* fprintf(stderr, "DOUBLE %f\n", (double) tmpd); */
          marpaESLIFValueResultp->contextp        = MARPAESLIFLUA_CONTEXT;
          marpaESLIFValueResultp->representationp = NULL;
          marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_DOUBLE;
          marpaESLIFValueResultp->u.d             = tmpd; /* We volontarily do not typecast, there should be no warning */
          eslifb = 1;
#    else
#      if defined(LUA_FLOAT_LONGDOUBLE) && (LUA_FLOAT_LONGDOUBLE == LUA_FLOAT_TYPE)
          /* fprintf(stderr, "LONG_DOUBLE\n"); */
          marpaESLIFValueResultp->contextp        = MARPAESLIFLUA_CONTEXT;
          marpaESLIFValueResultp->representationp = NULL;
          marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_LONG_DOUBLE;
          marpaESLIFValueResultp->u.ld            = tmpd; /* We volontarily do not typecast, there should be no warning */
          eslifb = 1;
#      endif
#    endif
#  endif /* defined(LUA_FLOAT_FLOAT) && (LUA_FLOAT_FLOAT == LUA_FLOAT_TYPE) */
        }
      }
#else
  #if defined(LUA_NUMBER_FLOAT)
      /* Lua uses native C float */
      /* fprintf(stderr, "FLOAT %f\n", (double) tmpd); */
      marpaESLIFValueResultp->contextp        = MARPAESLIFLUA_CONTEXT;
      marpaESLIFValueResultp->representationp = NULL;
      marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_FLOAT;
      marpaESLIFValueResultp->u.f             = tmpd; /* We volontarily do not typecast, there should be no warning */
      eslifb = 1;
  #else
    #if defined(LUA_NUMBER_DOUBLE)
      /* fprintf(stderr, "DOUBLE %f\n", (double) tmpd); */
      marpaESLIFValueResultp->contextp        = MARPAESLIFLUA_CONTEXT;
      marpaESLIFValueResultp->representationp = NULL;
      marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_DOUBLE;
      marpaESLIFValueResultp->u.d             = tmpd; /* We volontarily do not typecast, there should be no warning */
      eslifb = 1;
    #else
      #if defined(LUA_NUMBER_LONGDOUBLE) || defined(LUA_NUMBER_LONG_DOUBLE)
      /* fprintf(stderr, "LONG_DOUBLE\n"); */
      marpaESLIFValueResultp->contextp        = MARPAESLIFLUA_CONTEXT;
      marpaESLIFValueResultp->representationp = NULL;
      marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_LONG_DOUBLE;
      marpaESLIFValueResultp->u.ld            = tmpd; /* We volontarily do not typecast, there should be no warning */
      eslifb = 1;
      #endif
    #endif
  #endif
#endif /* defined(LUA_FLOAT_TYPE) */
      break;
    case LUA_TBOOLEAN:
      /* fprintf(stderr, "BOOL %s\n", (tmpb != 0) ? "true" : "false"); */
      if (! marpaESLIFLua_lua_toboolean(&tmpb, L, currenti)) goto err;
      marpaESLIFValueResultp->contextp        = MARPAESLIFLUA_CONTEXT;
      marpaESLIFValueResultp->representationp = NULL;
      marpaESLIFValueResultp->type            = MARPAESLIF_VALUE_TYPE_BOOL;
      marpaESLIFValueResultp->u.y             = (tmpb != 0) ? MARPAESLIFVALUERESULTBOOL_TRUE : MARPAESLIFVALUERESULTBOOL_FALSE;
      eslifb = 1;
      break;
    case LUA_TSTRING:
      if (! marpaESLIFLua_lua_tolstring(&tmps, L, currenti, &tmpl)) goto err;
      if (tmps == NULL) {
        /* Impossible since we checked the type */
        marpaESLIFLua_luaL_error(L, "lua_tolstring() returned NULL on a LUA_TSTRING thingy");
        goto err;
      }

      /* In Lua, the only thing that differentiate a string v.s. a byte array is the presence of the encoding information */
      /* This is nevertheless just acting as "boolean" thingy: any implementation is free to NOT keep the encoding information */
      /* because it is irrelevant when there is no byte */
#ifdef MARPAESLIFLUA_AUTO_ENCODING_DETECT
      encodingheapb = 0;
#endif
      MARPAESLIFLUA_GETORCREATEGLOBAL(L, MARPAESLIFSTRINGTOENCODINGTABLE, NULL /* gcp */, "k" /* mode */);                      /* Stack: ..., MARPAESLIFSTRINGTOENCODINGTABLE */
      if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                                                             /* Stack: ..., MARPAESLIFSTRINGTOENCODINGTABLE, nil */
      if (! marpaESLIFLua_lua_copy(L, currenti, -1)) goto err;                                                                  /* Stack: ..., MARPAESLIFSTRINGTOENCODINGTABLE, string */
      if (! marpaESLIFLua_lua_gettable(NULL, L, -2)) goto err;                                                                  /* Stack: ..., MARPAESLIFSTRINGTOENCODINGTABLE, encoding */
      if (! marpaESLIFLua_lua_type(&encodingtypei, L, -1)) goto err;
      if (encodingtypei == LUA_TSTRING) {
        if (! marpaESLIFLua_lua_tostring(&encodings, L, -1)) goto err;
      } else if (encodingtypei == LUA_TNIL) {
#ifdef MARPAESLIFLUA_AUTO_ENCODING_DETECT
        /* We try to guess the encoding */
        encodings = marpaESLIF_encodings(marpaESLIFp, p, tmpl);
        if (encodings != NULL) {
          encodingheapb = 1;
        }
#else
        encodings = NULL;
#endif
      } else {
        marpaESLIFLua_luaL_errorf(L, "MARPAESLIFSTRINGTOENCODINGTABLE value type must be a string or nil, got %d", encodingtypei);
        goto err;
      }

      if (encodings != NULL) {
        encodingasciis =
#ifdef MARPAESLIFLUA_AUTO_ENCODING_DETECT
          /* Duplicate the encoding - this is needed only if encodingheapb is 0 */
          /* When encodingheapb is 1 it is guaranteed to be already on the heap and not NULL */
          encodingheapb ? (char *) encodings
          :
#endif
          strdup(encodings);
        if (encodingasciis == NULL) {
          marpaESLIFLua_luaL_errorf(L, "strdup failure, %s", strerror(errno));
          goto err;
        }
      } else {
        encodingasciis = NULL;
      }

      if (encodingasciis == NULL) {
        if (tmpl > 0) {
          /* Duplicate the data */
          p = (char *) malloc(tmpl + 1); /* Hiden NUL byte */
          if (p == NULL) {
            marpaESLIFLua_luaL_errorf(L, "malloc failure, %s", strerror(errno));
            goto err;
          }
          if (tmpl > 0) {
            memcpy(p, tmps, tmpl);
          }
          p[tmpl] = '\0';
          /* fprintf(stderr, "ARRAY size %ld\n", (unsigned long) tmpl); */
          marpaESLIFValueResultp->type               = MARPAESLIF_VALUE_TYPE_ARRAY;
          marpaESLIFValueResultp->contextp           = MARPAESLIFLUA_CONTEXT;
          marpaESLIFValueResultp->representationp    = NULL;
          marpaESLIFValueResultp->u.a.p              = p;
          marpaESLIFValueResultp->u.a.shallowb       = 0;
          marpaESLIFValueResultp->u.a.sizel          = tmpl;
          marpaESLIFValueResultp->u.a.freeUserDatavp = L;
          marpaESLIFValueResultp->u.a.freeCallbackp  = marpaESLIFLua_genericFreeCallbackv;

          p = NULL; /* p is in marpaESLIFValueResultp */
        } else {
          /* fprintf(stderr, "ARRAY size %ld\n", (unsigned long) 0); */
          marpaESLIFValueResultp->type               = MARPAESLIF_VALUE_TYPE_ARRAY;
          marpaESLIFValueResultp->contextp           = MARPAESLIFLUA_CONTEXT;
          marpaESLIFValueResultp->representationp    = NULL;
          marpaESLIFValueResultp->u.a.p              = NULL;
          marpaESLIFValueResultp->u.a.shallowb       = 0;
          marpaESLIFValueResultp->u.a.sizel          = 0;
          marpaESLIFValueResultp->u.a.freeUserDatavp = NULL;
          marpaESLIFValueResultp->u.a.freeCallbackp  = NULL;
        }
      } else {
        if (tmpl > 0) {
          /* Duplicate the data */
          p = (char *) malloc(tmpl + 1); /* Hiden NUL byte */
          if (p == NULL) {
            marpaESLIFLua_luaL_errorf(L, "malloc failure, %s", strerror(errno));
            goto err;
          }
          if (tmpl > 0) {
            memcpy(p, tmps, tmpl);
          }
          p[tmpl] = '\0';
          /* fprintf(stderr, "STRING \"%s\"\n", p); */
          marpaESLIFValueResultp->type               = MARPAESLIF_VALUE_TYPE_STRING;
          marpaESLIFValueResultp->contextp           = MARPAESLIFLUA_CONTEXT;
          marpaESLIFValueResultp->representationp    = NULL;
          marpaESLIFValueResultp->u.s.p              = (unsigned char *) p;
          marpaESLIFValueResultp->u.s.shallowb       = 0;
          marpaESLIFValueResultp->u.s.sizel          = tmpl;
          marpaESLIFValueResultp->u.s.encodingasciis = encodingasciis;
          marpaESLIFValueResultp->u.s.freeUserDatavp = L;
          marpaESLIFValueResultp->u.s.freeCallbackp  = marpaESLIFLua_genericFreeCallbackv;

          p = NULL; /* p is in marpaESLIFValueResultp */
          encodingasciis = NULL; /* encodingasciis is in marpaESLIFValueResultp */
        } else {
          /* fprintf(stderr, "STRING \"\" (explicit empty string)\n"); */
          marpaESLIFValueResultp->type               = MARPAESLIF_VALUE_TYPE_STRING;
          marpaESLIFValueResultp->contextp           = MARPAESLIFLUA_CONTEXT;
          marpaESLIFValueResultp->representationp    = NULL;
          marpaESLIFValueResultp->u.s.p              = (unsigned char *) strdup("");
          if (marpaESLIFValueResultp->u.s.p == NULL) {
            marpaESLIFLua_luaL_errorf(L, "strdup failure, %s", strerror(errno));
            goto err;
          }
          marpaESLIFValueResultp->u.s.shallowb       = 0;
          marpaESLIFValueResultp->u.s.sizel          = 0;
          marpaESLIFValueResultp->u.s.encodingasciis = encodingasciis;
          marpaESLIFValueResultp->u.s.freeUserDatavp = L;
          marpaESLIFValueResultp->u.s.freeCallbackp  = marpaESLIFLua_genericFreeCallbackv;

          encodingasciis = NULL; /* encodingasciis is in marpaESLIFValueResultp */
        }
      }

      if (! marpaESLIFLua_lua_pop(L, 2)) goto err;                                                                              /* Stack: ... */
      eslifb = 1;
      break;
    case LUA_TTABLE:
      /* marpaESLIFLua_tabledump_usingpairsv(L, "", currenti, 0); */
      if (! marpaESLIFLua_table_opaque_getb(L, currenti, &opaqueb)) goto err;
      if (! opaqueb) {
        /* Check if this table contains internal fields (via methods in our case) that forces the type and the context */

        /* Check if the table can be translated to a true array */
        if (! marpaESLIFLua_table_canarray_getb(L, currenti, &canarrayb)) goto err;
        /* fprintf(stdout, "export table canarrayb=%d\n", (int) canarrayb); fflush(stdout); fflush(stderr); */

        /* Count the number of items. The only way to iterate first. We take this as the opportunity to check for circular reference */
        /* that can make lua loop. */
        if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                                   /* Stack: visitedTable, ..., xxx=table, nil */
        tablel = 0;
        tableIsArrayb = canarrayb;
        tableIsRecursiveb = 0;
        while (1) {
          if (! marpaESLIFLua_pairsb(&nexti, L, currenti, &iteratori, &statevariablei)) goto err;             /* Stack: visitedTable, ..., xxx=table, key, value */
          /* fprintf(stderr, "marpaESLIFLua_pairsb return nexti=%d\n", nexti); */
          if (nexti == 0) break;
          /* Improbable turnaround */
          tableNextl = tablel + 1;
          if (tableNextl < tablel) {
            marpaESLIFLua_luaL_error(L, "lua_Integer turnaround when computing table size");
            goto err;
          }
          tablel = tableNextl;

          /* If key is a table, is it already visited ? */
          if (! marpaESLIFLua_metatypeb(&keyTypei, L, -2)) goto err;
          /* fprintf(stdout, "export table keyTypei=%d\n", keyTypei); fflush(stdout); fflush(stderr); */
          if (keyTypei == LUA_TTABLE) {
            if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                               /* Stack: visitedTable, ..., xxx=table, key, value, nil */
            if (! marpaESLIFLua_lua_copy(L, -3, -1)) goto err;                                          /* Stack: visitedTable, ..., xxx=table, key, value, key */
            if (! marpaESLIFLua_lua_gettable(NULL, L, visitedTableIndicei)) goto err;                   /* Stack: visitedTable, ..., xxx=table, key, value, visitableTable[key] */
            isnili = 0;
            if (! marpaESLIFLua_lua_isnil(&isnili, L, -1)) goto err;
            if (! isnili) {
              if (! marpaESLIFLua_lua_pop(L, 3)) goto err;                                              /* Stack: visitedTable, ..., xxx=table */
              tableIsRecursiveb = 1;
              break;
            }
            if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                                                /* Stack: visitedTable, ..., xxx=table, key, value */
            if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                               /* Stack: visitedTable, ..., xxx=table, key, value, nil */
            if (! marpaESLIFLua_lua_copy(L, -3, -1)) goto err;                                          /* Stack: visitedTable, ..., xxx=table, key, value, key */
            if (! marpaESLIFLua_lua_pushboolean(L, 1)) goto err;                                        /* Stack: visitedTable, ..., xxx=table, key, value, key, true */
            /* Set visitableTable[key] = true */
            if (! marpaESLIFLua_lua_rawset(L, visitedTableIndicei)) goto err;                           /* Stack: visitedTable, ..., xxx=table, key, value */
            tableIsArrayb = 0;
          } else if (tableIsArrayb && (keyTypei == LUA_TNUMBER)) {
            /* Is key adjacent to the previous number ? */
            if (! marpaESLIFLua_lua_tointegerx(&keyi, L, -2, &keyIsNumi)) goto err;
            if (keyIsNumi) {
              if (keyi != tablel) {
                tableIsArrayb = 0;
              }
            } else {
              /* Should never happen at this stage */
              tableIsArrayb = 0;
            }
          } else {
            tableIsArrayb = 0;
          }

          /* If value is a table, is it already visited ? */
          if (! marpaESLIFLua_metatypeb(&valueTypei, L, -1)) goto err;
          /* fprintf(stdout, "export table valueTypei=%d\n", valueTypei); fflush(stdout); fflush(stderr); */
          if (valueTypei == LUA_TTABLE) {
            if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                               /* Stack: visitedTable, ..., xxx=table, key, value, nil */
            if (! marpaESLIFLua_lua_copy(L, -2, -1)) goto err;                                          /* Stack: visitedTable, ..., xxx=table, key, value, value */
            if (! marpaESLIFLua_lua_gettable(NULL, L, visitedTableIndicei)) goto err;                   /* Stack: visitedTable, ..., xxx=table, key, value, visitableTable[value] */
            isnili = 0;
            if (! marpaESLIFLua_lua_isnil(&isnili, L, -1)) goto err;
            if (! isnili) {
              if (! marpaESLIFLua_lua_pop(L, 3)) goto err;                                              /* Stack: visitedTable, ..., xxx=table */
              tableIsRecursiveb = 1;
              break;
            }
            if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                                                /* Stack: visitedTable, ..., xxx=table, key, value */
            if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                               /* Stack: visitedTable, ..., xxx=table, key, value, nil */
            if (! marpaESLIFLua_lua_copy(L, -2, -1)) goto err;                                          /* Stack: visitedTable, ..., xxx=table, key, value, value */
            if (! marpaESLIFLua_lua_pushboolean(L, 1)) goto err;                                        /* Stack: visitedTable, ..., xxx=table, key, value, value, true */
            /* Set visitableTable[value] = true */
            if (! marpaESLIFLua_lua_rawset(L, visitedTableIndicei)) goto err;                           /* Stack: visitedTable, ..., xxx=table, key, value */
          }

          if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                                                  /* Stack: visitedTable, ..., xxx=table, key */
        }                                                                                               /* Stack: visitedTable, ..., xxx=table */

        if (! tableIsRecursiveb) {
          if (tableIsArrayb) {
            /* Allocate a marpaESLIFValueResult of type ROW of size tablel where we will secialize only the values  */
            /* fprintf(stderr, "ROW size %ld\n", (unsigned long) tablel); */
            /* fprintf(stdout, "export row of size %ld\n", (unsigned long) tablel); fflush(stdout); fflush(stderr); */
            marpaESLIFValueResultp->contextp           = MARPAESLIFLUA_CONTEXT;
            marpaESLIFValueResultp->representationp    = NULL;
            marpaESLIFValueResultp->type               = MARPAESLIF_VALUE_TYPE_ROW;
            marpaESLIFValueResultp->u.r.shallowb       = 0;
            marpaESLIFValueResultp->u.r.sizel          = tablel; /* Number of value items */
	    marpaESLIFValueResultp->u.r.freeUserDatavp = L;
	    marpaESLIFValueResultp->u.r.freeCallbackp  = marpaESLIFLua_genericFreeCallbackv;
            if (tablel > 0) {
              marpaESLIFValueResultp->u.r.p            = (marpaESLIFValueResult_t *) malloc(tablel * sizeof(marpaESLIFValueResult_t));
              if (marpaESLIFValueResultp->u.r.p == NULL) {
                marpaESLIFLua_luaL_errorf(L, "malloc failure, %s", strerror(errno));
                goto err;
              }
              for (i = 0; i < tablel; i++) {
                marpaESLIFValueResultp->u.r.p[i].type  = MARPAESLIF_VALUE_TYPE_UNDEF;
              }
            } else {
              marpaESLIFValueResultp->u.r.p = NULL;
            }

            /* Process the table content - and push items in an order synchronized with marpaESLIFValueResult allocated array */
            for (i = 0, arrayl = 1; i < tablel; i++, arrayl++) {
              if (! marpaESLIFLua_lua_pushinteger(L, (lua_Integer) arrayl)) goto err;                  /* Stack: visitedTable, ..., xxx=table, i */
              if (! marpaESLIFLua_lua_gettable(NULL, L, currenti)) goto err;                           /* Stack: visitedTable, ..., xxx=table, table[i] */

              /* fprintf(stderr, "GENERICSTACK_PUSH_PTR(marpaESLIFValueResultStackp, %p)\n", &(marpaESLIFValueResultp->u.r.p[i])); */
              GENERICSTACK_PUSH_PTR(marpaESLIFValueResultStackp, &(marpaESLIFValueResultp->u.r.p[i]));
              if (GENERICSTACK_ERROR(marpaESLIFValueResultStackp)) {
                marpaESLIFLua_luaL_errorf(L, "marpaESLIFValueResultStackp push failure, %s", strerror(errno));
                goto err;
              }
            }
        
          } else {
            /* Pushing {key,value} items in order is irrelevant here because lua does NOT guarantee that lua_next preserves */
            /* the insertion order. */
            /* fprintf(stderr, "TABLE size %ld\n", (unsigned long) tablel); */
            /* marpaESLIFLua_tabledump_usingpairsv(L, "", currenti, 0); */
            marpaESLIFValueResultp->contextp           = MARPAESLIFLUA_CONTEXT;
            marpaESLIFValueResultp->representationp    = NULL;
            marpaESLIFValueResultp->type               = MARPAESLIF_VALUE_TYPE_TABLE;
            marpaESLIFValueResultp->u.t.shallowb       = 0;
            marpaESLIFValueResultp->u.t.sizel          = tablel; /* Number of key and value items */
	    marpaESLIFValueResultp->u.t.freeUserDatavp = L;
	    marpaESLIFValueResultp->u.t.freeCallbackp  = marpaESLIFLua_genericFreeCallbackv;
            if (tablel > 0) {
              marpaESLIFValueResultp->u.t.p            = (marpaESLIFValueResultPair_t *) malloc(tablel * sizeof(marpaESLIFValueResultPair_t));
              if (marpaESLIFValueResultp->u.t.p == NULL) {
                marpaESLIFLua_luaL_errorf(L, "malloc failure, %s", strerror(errno));
                goto err;
              }
              for (i = 0; i < tablel; i++) {
                marpaESLIFValueResultp->u.t.p[i].key.type   = MARPAESLIF_VALUE_TYPE_UNDEF;
                marpaESLIFValueResultp->u.t.p[i].value.type = MARPAESLIF_VALUE_TYPE_UNDEF;
              }

              /* Process the table content */
              if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                               /* Stack: visitedTable, ..., xxx=table, nil */
              tablel = 0;
              while (1) {
                if (! marpaESLIFLua_pairsb(&nexti, L, currenti, &iteratori, &statevariablei)) goto err;/* Stack: visitedTable, ..., xxx=table, key, value */
                /* fprintf(stderr, "marpaESLIFLua_pairsb return nexti=%d\n", nexti); */
                if (nexti == 0) break;

                /* Push room for key */
                /* fprintf(stderr, "GENERICSTACK_PUSH_PTR(marpaESLIFValueResultStackp, %p)\n", &(marpaESLIFValueResultp->u.t.p[tablel].key)); */
                GENERICSTACK_PUSH_PTR(marpaESLIFValueResultStackp, &(marpaESLIFValueResultp->u.t.p[tablel].key));
                if (GENERICSTACK_ERROR(marpaESLIFValueResultStackp)) {
                  marpaESLIFLua_luaL_errorf(L, "marpaESLIFValueResultStackp push failure, %s", strerror(errno));
                  goto err;
                }
                if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                             /* Stack: visitedTable, ..., xxx=table, key, value, nil */
                if (! marpaESLIFLua_lua_copy(L, -3, -1)) goto err;                                        /* Stack: visitedTable, ..., xxx=table, key, value, key */

                /* Push room for value */
                /* fprintf(stderr, "GENERICSTACK_PUSH_PTR(marpaESLIFValueResultStackp, %p)\n", &(marpaESLIFValueResultp->u.t.p[tablel].value)); */
                GENERICSTACK_PUSH_PTR(marpaESLIFValueResultStackp, &(marpaESLIFValueResultp->u.t.p[tablel].value));
                if (GENERICSTACK_ERROR(marpaESLIFValueResultStackp)) {
                  marpaESLIFLua_luaL_errorf(L, "marpaESLIFValueResultStackp push failure, %s", strerror(errno));
                  goto err;
                }
                if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                             /* Stack: visitedTable, ..., xxx=table, key, value, key, nil */
                if (! marpaESLIFLua_lua_copy(L, -3, -1)) goto err;                                        /* Stack: visitedTable, ..., xxx=table, key, value, key, value */

                if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                                              /* Stack: visitedTable, ..., xxx=table, key, value, key */

                tablel++;
              }                                                                                           /* Stack: visitedTable, ..., xxx=table, key, value */
            } else {
              marpaESLIFValueResultp->u.t.p = NULL;
            }
          }
          eslifb = 1;
        } else {        /* ! tableIsRecursiveb */
          eslifb = 0;
        }
      } /* ! opaqueb */
      break;
    case LUA_TLIGHTUSERDATA:
      /* fprintf(stderr, "LIGHT PTR\n"); */
      /* fprintf(stdout, "export ptr\n"); fflush(stdout); fflush(stderr); */
      if (! marpaESLIFLua_lua_topointer(&pointerp, L, currenti)) goto err;
      /* Is is a light user data that we created to duplicate a marpaESLIFValueResult ? */
      MARPAESLIFLUA_GETORCREATEGLOBAL(L, MARPAESLIFOPAQUETABLE, marpaESLIFLua_marpaESLIFOpaque_freei /* gcp */, "" /* mode */);  /* Stack: ..., MARPAESLIFOPAQUETABLE */
      if (! marpaESLIFLua_lua_rawgetp(&opaqueTypei, L, -1, pointerp)) goto err;                                                  /* Stack: ..., MARPAESLIFOPAQUETABLE, marpaESLIFValueResultDupp */
      if (! marpaESLIFLua_lua_topointer((const void **) &marpaESLIFValueResultDupp, L, -1)) goto err;
      if (! marpaESLIFLua_lua_pop(L, 2)) goto err;                                                                               /* Stack: ... */
      if (marpaESLIFValueResultDupp != NULL) {
        *marpaESLIFValueResultp = *marpaESLIFValueResultDupp;
      } else {
        marpaESLIFValueResultp->contextp           = MARPAESLIFLUA_CONTEXT;
        marpaESLIFValueResultp->representationp    = NULL;
        marpaESLIFValueResultp->type               = MARPAESLIF_VALUE_TYPE_PTR;
        marpaESLIFValueResultp->u.p.p              = (void *) pointerp;
        marpaESLIFValueResultp->u.p.shallowb       = 1;
	marpaESLIFValueResultp->u.p.freeUserDatavp = NULL;
	marpaESLIFValueResultp->u.p.freeCallbackp  = NULL;
      }
      eslifb = 1;
      break;
    default:
      break;
    }

    if (! eslifb) {
      /* This does not fit in marpaESLIF types, or it is a table that is forced to be opaque. Make it a reference into lua interpreter */
      ip = (int *) malloc(sizeof(int));
      if (ip == NULL) {
        marpaESLIFLua_luaL_errorf(L, "malloc failure, %s", strerror(errno));
        goto err;
      }

      if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                                    /* Stack: visitedTable, ..., xxx, nil */
      if (! marpaESLIFLua_lua_copy(L, -2, -1)) goto err;                                               /* Stack: visitedTable, ..., xxx, xxx */
      MARPAESLIFLUA_REF(L, *ip);                                                                       /* Stack: visitedTable, ..., xxx */

      /* fprintf(stderr, "PTR %p\n", ip); */
      marpaESLIFValueResultp->contextp           = MARPAESLIFLUA_CONTEXT;
      marpaESLIFValueResultp->representationp    = marpaESLIFLua_representationb;
      marpaESLIFValueResultp->type               = MARPAESLIF_VALUE_TYPE_PTR;
      marpaESLIFValueResultp->u.p.p              = ip;
      marpaESLIFValueResultp->u.p.shallowb       = 0;
      marpaESLIFValueResultp->u.r.freeUserDatavp = L;
      marpaESLIFValueResultp->u.r.freeCallbackp  = marpaESLIFLua_genericFreeCallbackv;
    }

    /* Remove current item in the to do list */
    if (! marpaESLIFLua_lua_remove(L, currenti)) goto err;

  }

  /* We remove the "visitedTable" */
  if (! marpaESLIFLua_lua_remove(L, visitedTableIndicei)) goto err;                                    /* Stack: xxx */

  if (resulti >= 0) {
    if (! marpaESLIFValue_stack_setb(marpaESLIFValuep, resulti, &marpaESLIFValueResult)) {
      marpaESLIFLua_luaL_errorf(L, "marpaESLIFValue_stack_setb failure, %s", strerror(errno));
      goto err;
    }
  }
  if (marpaESLIFValueResultOutputp != NULL) {
    *marpaESLIFValueResultOutputp = marpaESLIFValueResult;
  }

  rcb = 1;
  /* fprintf(stdout, "export done\n"); fflush(stdout); fflush(stderr); */
  goto done;

 err:
  if (encodingasciis != NULL) {
    free(encodingasciis);
  }
  if (p != NULL) {
    free(p);
  }
  if (ip != NULL) {
    free(ip);
  }
  rcb = 0;

 done:
  GENERICSTACK_RESET(marpaESLIFValueResultStackp);
  return rcb;
}

/****************************************************************************/
static short marpaESLIFLua_table_canarray_getb(lua_State *L, int indicei, short *canarraybp)
/****************************************************************************/
{
  static const char *funcs     = "marpaESLIFLua_table_canarray_getb";
  short              canarrayb = 1; /* Default is true */
  int                canarrayi;
  int                getmetai;

  if (! marpaESLIFLua_luaL_getmetafield(&getmetai, L, indicei, MARPAESLIF_CANARRAY)) goto err;    /* Stack: ..., MARPAESLIF_CANARRAY? */
  if (getmetai != LUA_TNIL) {
    if (getmetai != LUA_TBOOLEAN) {
      marpaESLIFLua_luaL_errorf(L, "'%s' must be a boolean value", MARPAESLIF_CANARRAY);
      goto err;
    }
    if (! marpaESLIFLua_lua_toboolean(&canarrayi, L, -1)) goto err;                               /* Stack: ..., MARPAESLIF_CANARRAY */
    canarrayb = canarrayi ? 1 : 0;
    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                                                  /* Stack: ... */
  }

  if (canarraybp != NULL) {
    *canarraybp = canarrayb;
  }

  return 1;

 err:
  errno = EINVAL;
  return 0;
}

/****************************************************************************/
static short marpaESLIFLua_table_opaque_getb(lua_State *L, int indicei, short *opaquebp)
/****************************************************************************/
{
  static const char *funcs   = "marpaESLIFLua_table_opaque_getb";
  short              opaqueb = 0; /* Default is false */
  int                opaquei;
  int                getmetai;

  if (! marpaESLIFLua_luaL_getmetafield(&getmetai, L, indicei, MARPAESLIF_OPAQUE)) goto err;     /* Stack: ..., MARPAESLIF_OPAQUE? */
  if (getmetai != LUA_TNIL) {
    if (getmetai != LUA_TBOOLEAN) {
      if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                                               /* Stack: ... */
      marpaESLIFLua_luaL_errorf(L, "'%s' must be a boolean value", MARPAESLIF_OPAQUE);
      goto err;
    }
    if (! marpaESLIFLua_lua_toboolean(&opaquei, L, -1)) goto err;                                /* Stack: ..., MARPAESLIF_OPAQUE */
    opaqueb = opaquei ? 1 : 0;
    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                                                 /* Stack: ... */
  }

  if (opaquebp != NULL) {
    *opaquebp = opaqueb;
  }

  return 1;

 err:
  errno = EINVAL;
  return 0;
}

/****************************************************************************/
static int marpaESLIFLua_nexti(lua_State *L)
/****************************************************************************/
{
  int rci;
  int nexti;

  if (! marpaESLIFLua_luaL_checktype(L, 1, LUA_TTABLE)) goto err;         /* Stack: table */
  if (! marpaESLIFLua_lua_settop(L, 2)) goto err;                         /* Stack: table, argument (create a 2nd argument if there isn't one) */
  if (! marpaESLIFLua_metanextb(&nexti, L, 1)) goto err;
  if (nexti) {
    rci = 2;                                                              /* Stack: key, value */
  } else {
    if (! marpaESLIFLua_lua_pushnil(L)) goto err;                         /* Stack: nil (end of loop indicator) */
    rci = 1;
  }

  goto done;

 err:
  rci = 0;

 done:
  return rci;
}

/****************************************************************************/
static short marpaESLIFLua_pairsb(int *rcip, lua_State *L, int idx, int *iteratorip, int *statevariableip)
/****************************************************************************/
/* This method uses pairs() if available. It must be called with non-NULL iteratorip and statevariableip variables */
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_pairsb";
  short              rcb;
  int                isnili;
  int                getmetai;
  int                iteratori;
  int                statevariablei;
  int                rci;

  /* First call ? */
  if (! marpaESLIFLua_lua_isnil(&isnili, L, -1)) goto err;
  if (isnili) {                                                                         /* Stack: ..., nil */
    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                                        /* Stack: ... */
    /* Is there a __pairs() metatable entry (assumed to be a method) */
    if (! marpaESLIFLua_luaL_getmetafield(&getmetai, L, idx, "__pairs")) goto err;
    if (getmetai == LUA_TNIL) {  /* no metamethod? */
      if (! marpaESLIFLua_lua_pushcfunction(L, marpaESLIFLua_nexti)) goto err;          /* Stack: ..., lua_next() */
      if (! marpaESLIFLua_lua_pushvalue(L, idx)) goto err;                              /* Stack: ..., lua_next(), table */
      if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                     /* Stack: ..., lua_next(), table, nil */
    } else {
      if (! marpaESLIFLua_lua_pushvalue(L, idx)) goto err;                              /* Stack: ..., __pairs(), table */
      if (! marpaESLIFLua_lua_call(L, 1, 3)) goto err;                                  /* Stack: ..., iterator, statevariable, initialvalue */
    }
    if (! marpaESLIFLua_lua_pushvalue(L, -3)) goto err;                                 /* Stack: ..., iterator, statevariable, initialvalue, iterator */
    if (! marpaESLIFLua_lua_pushvalue(L, -3)) goto err;                                 /* Stack: ..., iterator, statevariable, initialvalue, iterator, statevariable */
    MARPAESLIFLUA_REF(L, statevariablei);                                               /* Stack: ..., iterator, statevariable, initialvalue, iterator */
    *statevariableip = statevariablei;
    MARPAESLIFLUA_REF(L, iteratori);                                                    /* Stack: ..., iterator, statevariable, initialvalue */
    *iteratorip = iteratori;
  } else {                                                                              /* Stack: ..., key */
    MARPAESLIFLUA_DEREF(L, *iteratorip);                                                /* Stack: ..., key, iterator */
    if (! marpaESLIFLua_lua_insert(L, -2)) goto err;                                    /* Stack: ..., iterator, key */
    MARPAESLIFLUA_DEREF(L, *statevariableip);                                           /* Stack: ..., iterator, key, statevariable */
    if (! marpaESLIFLua_lua_insert(L, -2)) goto err;                                    /* Stack: ..., iterator, statevariable, key */
  }

  /* Get next key,value */
  if (! marpaESLIFLua_lua_call(L, 2, 2)) goto err;                                      /* Stack: ..., nextkey, nextvalue */
  if (! marpaESLIFLua_lua_isnil(&isnili, L, -2)) goto err;
  if (isnili) {                                                                         /* Stack: ..., nextkey=nil, nextvalue=<not considered> */
    MARPAESLIFLUA_UNREF(L, *iteratorip);
    MARPAESLIFLUA_UNREF(L, *statevariableip);
    if (! marpaESLIFLua_lua_pop(L, 2)) goto err;                                        /* Stack: ... */
    rci = 0;
  } else {
    rci = 1;
  }

  if (rcip != NULL) {
    *rcip = rci;
  }
  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/****************************************************************************/
static int marpaESLIFLua_marpaESLIFOpaque_freei(lua_State *L)
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_marpaESLIFOpaque_freei";
  int                nexti;
  int                iteratori;
  int                statevariablei;
  void              *p;
  void              *marpaESLIFValueResultDupp;

  /* Loop on MARPAESLIFOPAQUETABLE */
  if (! marpaESLIFLua_lua_pushnil(L)) goto err;                                            /* Stack: MARPAESLIFOPAQUETABLE, nil */
  while (1) {
    if (! marpaESLIFLua_pairsb(&nexti, L, -2, &iteratori, &statevariablei)) goto err;      /* Stack: MARPAESLIFOPAQUETABLE, p, marpaESLIFValueResultDupp */
    if (nexti == 0) break;
    if (! marpaESLIFLua_lua_touserdata(&p, L, -2)) goto err;
    if (! marpaESLIFLua_lua_touserdata((void **) &marpaESLIFValueResultDupp, L, -1)) goto err;

    if (marpaESLIFValueResultDupp != NULL) {
      free(marpaESLIFValueResultDupp);
    }

    if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                                           /* Stack: MARPAESLIFOPAQUETABLE, p */
  }

  return 0;

 err:
  return 0;
}

/****************************************************************************/
static short marpaESLIFLua_metatypeb(int *luaip, lua_State *L, int index)
/****************************************************************************/
/* This function does quite the same thing as the _G.type override          */
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_metatypeb";
  short              rcb;
  int                luai;
  int                getmetai;
  int                metatypei;
  int                metavaluetypei;
  const char        *types;

  if (! marpaESLIFLua_lua_type(&luai, L, index)) goto err;
  if ((luai == LUA_TTABLE) || (luai == LUA_TUSERDATA)) {
    /* Check if there is a __type meta field */
    getmetai = luaL_getmetafield(L, -1, "__type");
    if (getmetai != LUA_TNIL) {                                         /* Stack: ..., __type metafield */
      if (! marpaESLIFLua_lua_type(&metatypei, L, -1)) goto err;
      if (metatypei == LUA_TFUNCTION) {
        if (! marpaESLIFLua_lua_pushnil(L)) goto err;                   /* Stack: ..., __type(), nil */
        if (! marpaESLIFLua_lua_copy(L, index, -1)) goto err;           /* Stack: ..., __type(), value */
        if (! marpaESLIFLua_lua_call(L, 1, 1)) goto err;                /* Stack: ..., __type(value) */
        if (! marpaESLIFLua_lua_type(&metavaluetypei, L, -1)) goto err;
        if (metavaluetypei != LUA_TNIL) {
        tostring:
          if (! marpaESLIFLua_lua_tostring(&types, L, -1)) goto err;
          if (types != NULL) {
            /* The set of allowed strings is restricted... */
            if (strcmp(types, "nil") == 0) {
              luai = LUA_TNIL;
            } else if (strcmp(types, "number") == 0) {
              luai = LUA_TNUMBER;
            } else if (strcmp(types, "boolean") == 0) {
              luai = LUA_TBOOLEAN;
            } else if (strcmp(types, "string") == 0) {
              luai = LUA_TSTRING;
            } else if (strcmp(types, "table") == 0) {
              luai = LUA_TTABLE;
            } else if (strcmp(types, "function") == 0) {
              luai = LUA_TFUNCTION;
            } else if (strcmp(types, "userdata") == 0) {
              luai = LUA_TUSERDATA;
            } else if (strcmp(types, "lightuserdata") == 0) {
              luai = LUA_TLIGHTUSERDATA;                  /* Formally not allowed because light userdata can be accessed only via the C API */
            } else if (strcmp(types, "thread") == 0) {
              luai = LUA_TTHREAD;
            } else {
              marpaESLIFLua_luaL_errorf(L, "Unsupported type %s", types);
              goto err;
            }
          }
        }
        if (! marpaESLIFLua_lua_pop(L, 1)) goto err;
      } else {
        goto tostring;
      }
    }
  }

  if (luaip != NULL) {
    *luaip = luai;
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/****************************************************************************/
static short marpaESLIFLua_createniledtableb(lua_State *L, int narr, int nrec, short arrayb)
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_createniledtableb";
  short              rcb;

  if (! marpaESLIFLua_lua_getglobal(NULL, L, arrayb ? "niledarray" : "niledtablekv")) goto err;  /* Stack: ..., NiledTable */
  if (! marpaESLIFLua_lua_call(L, 0, 1)) goto err;                                               /* Stack: ..., NiledTable() */

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/****************************************************************************/
static short marpaESLIFLua_metanextb(int *rcip, lua_State *L, int idx)
/****************************************************************************/
/* This function does quite the same thing as the _G.next override          */
/* Note: it is ASSUMED that there is a key in the stack                     */
/****************************************************************************/
{
  static const char *funcs = "marpaESLIFLua_metanextb";
  short              rcb;
  int                rci;
  int                getmetai;
  int                metatypei;
  int                metakeytypei;

  /* Check if there is a __next meta field */
  getmetai = luaL_getmetafield(L, idx, "__next");
  if (getmetai != LUA_TNIL) {                                         /* Stack: ..., <key>, __next metafield */
    if (! marpaESLIFLua_lua_type(&metatypei, L, -1)) goto err;
    if (metatypei == LUA_TFUNCTION) {
      if (! marpaESLIFLua_lua_insert(L, -2)) goto err;                /* Stack: ..., __next(), <key> */
      if (! marpaESLIFLua_lua_pushnil(L)) goto err;                   /* Stack: ..., __next(), <key>, nil */
      if (! marpaESLIFLua_lua_copy(L, idx, -1)) goto err;             /* Stack: ..., __next(), <key>, table */
      if (! marpaESLIFLua_lua_insert(L, -2)) goto err;                /* Stack: ..., __next(), table, <key> */
      if (! marpaESLIFLua_lua_call(L, 2, 2)) goto err;                /* Stack: ..., nextkey, nextvalue */
      if (! marpaESLIFLua_metatypeb(&metakeytypei, L, -2)) goto err;
      if (metakeytypei == LUA_TNIL) {
        /* next key is nil: end of iteration */
        if (! marpaESLIFLua_lua_pop(L, 2)) goto err;                  /* Stack: ... (previous key was popped) */
        rci = 0;
      } else {
        rci = 1;
      }
    } else {
      if (! marpaESLIFLua_lua_insert(L, -2)) goto err;                /* Stack: ..., __next, <key> */
      if (! marpaESLIFLua_lua_pop(L, 1)) goto err;                    /* Stack: ..., __next */
      rci = 1;
    }
  } else {
    /* Call native next */
    if (! marpaESLIFLua_lua_next(&rci, L, idx)) goto err;
  }

  if (rcip != NULL) {
    *rcip = rci;
  }
    
  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

