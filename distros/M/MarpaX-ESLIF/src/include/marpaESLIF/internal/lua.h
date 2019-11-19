#ifndef MARPAESLIF_INTERNAL_LUA_H
#define MARPAESLIF_INTERNAL_LUA_H

#include <marpaESLIF.h>
#include <luaunpanic.h>

static char _MARPAESLIF_EMBEDDED_CONTEXT_LUA;

#define MARPAESLIF_EMBEDDED_CONTEXT_LUA &_MARPAESLIF_EMBEDDED_CONTEXT_LUA

static short _marpaESLIFGrammar_lua_precompileb(marpaESLIFGrammar_t *marpaESLIFGrammarp);
static void  _marpaESLIFRecognizer_lua_freev(marpaESLIFRecognizer_t *marpaESLIFRecognizerp);
static short _marpaESLIFRecognizer_lua_ifactionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFValueResultp, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp);
static void  _marpaESLIFValue_lua_freev(marpaESLIFValue_t *marpaESLIFValuep);
static short _marpaESLIFValue_lua_actionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static short _marpaESLIFValue_lua_symbolb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFValueResult_t *marpaESLIFValueResultp, int resulti);
static short _marpaESLIFValue_lua_representationb(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp, char **encodingasciisp);

#endif /* MARPAESLIF_INTERNAL_LUA_H */

