#ifndef MARPAESLIF_INTERNAL_LUA_H
#define MARPAESLIF_INTERNAL_LUA_H

#include <luaunpanic.h>

static char _MARPAESLIF_EMBEDDED_CONTEXT_LUA;

#define MARPAESLIF_EMBEDDED_CONTEXT_LUA &_MARPAESLIF_EMBEDDED_CONTEXT_LUA

static short _marpaESLIF_lua_newb(marpaESLIF_t *marpaESLIFp);
static void  _marpaESLIF_lua_freev(marpaESLIF_t *marpaESLIFp);
static short _marpaESLIFGrammar_lua_precompileb(marpaESLIFGrammar_t *marpaESLIFGrammarp);
static void  _marpaESLIFGrammar_lua_freev(marpaESLIFGrammar_t *marpaESLIFGrammarp);
static void  _marpaESLIFRecognizer_lua_freev(marpaESLIFRecognizer_t *marpaESLIFRecognizerp);
static void  _marpaESLIFValue_lua_freev(marpaESLIFValue_t *marpaESLIFValuep);
static short _marpaESLIFValue_lua_precompileb(marpaESLIFValue_t *marpaESLIFValuep, char *luabytep, size_t luabytel, short stripb, int popi);
static short _marpaESLIFRecognizer_lua_ifactionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFValueResultp, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp);
static short _marpaESLIFRecognizer_lua_regexactionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFCalloutBlockp, marpaESLIFValueResultInt_t *marpaESLIFValueResultOutp);
static short _marpaESLIFRecognizer_lua_generatoractionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *contextp, marpaESLIFValueResultString_t *marpaESLIFValueResultOutp);
static short _marpaESLIFValue_lua_actionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static short _marpaESLIFValue_lua_symbolb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFValueResult_t *marpaESLIFValueResultp, int resulti);
static short _marpaESLIFValue_lua_representationb(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp, char **encodingasciisp, marpaESLIFRepresentationDispose_t *disposeCallbackpp, short *stringbp);
static short _marpaESLIFRecognizer_lua_eventactionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFEvent_t *eventArrayp, size_t eventArrayl, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp);
static marpaESLIFGrammar_t *_marpaESLIF_luaGrammarp(marpaESLIF_t *marpaESLIFp, char *starts);
static short _marpaESLIFValue_lua_action_functionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static short _marpaESLIFValue_lua_symbol_functionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFValueResult_t *marpaESLIFValueResultp, int resulti);
static short _marpaESLIFRecognizer_lua_ifaction_functionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFValueResultp, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp);
static short _marpaESLIFRecognizer_lua_regexaction_functionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFCalloutBlockp, marpaESLIFValueResultInt_t *marpaESLIFValueResultOutp);
static short _marpaESLIFRecognizer_lua_generatoraction_functionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *contextp, marpaESLIFValueResultString_t *marpaESLIFValueResultOutp);
static short _marpaESLIFRecognizer_lua_eventaction_functionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFEvent_t *eventArrayp, size_t eventArrayl, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp);
static short _marpaESLIFRecognizer_lua_push_contextb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIF_symbol_t *symbolp);
static short _marpaESLIFRecognizer_lua_pop_contextb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp);
static short _marpaESLIFRecognizer_lua_get_contextp(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *contextp);
static short _marpaESLIFRecognizer_lua_set_contextb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *contextp);

#endif /* MARPAESLIF_INTERNAL_LUA_H */

