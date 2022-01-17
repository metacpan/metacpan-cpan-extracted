#ifndef MARPAESLIF_INTERNAL_LUA_H
#define MARPAESLIF_INTERNAL_LUA_H

#include <luaunpanic.h>

static char _MARPAESLIF_EMBEDDED_CONTEXT_LUA;

#define MARPAESLIF_EMBEDDED_CONTEXT_LUA &_MARPAESLIF_EMBEDDED_CONTEXT_LUA

static inline lua_State    *_marpaESLIF_lua_newp(marpaESLIF_t *marpaESLIFp);
static inline void          _marpaESLIF_lua_freev(marpaESLIF_t *marpaESLIFp);
static inline void          _marpaESLIF_lua_grammar_freev(marpaESLIFGrammar_t *marpaESLIFGrammarp);
static inline short         _marpaESLIF_lua_grammar_precompileb(marpaESLIFGrammar_t *marpaESLIFGrammarp);
static inline short         _marpaESLIF_lua_value_precompileb(marpaESLIFValue_t *marpaESLIFValuep, char *luabytep, size_t luabytel, short stripb, int popi);
static inline void          _marpaESLIF_lua_value_freev(marpaESLIFValue_t *marpaESLIFValuep);
static inline void          _marpaESLIF_lua_recognizer_freev(marpaESLIFRecognizer_t *marpaESLIFRecognizerp);
static short                _marpaESLIF_lua_recognizer_ifactionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFValueResultp, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp);
static short                _marpaESLIF_lua_recognizer_regexactionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFCalloutBlockp, marpaESLIFValueResultInt_t *marpaESLIFValueResultOutp);
static short                _marpaESLIF_lua_recognizer_generatoractionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *contextp, marpaESLIFValueResultString_t *marpaESLIFValueResultOutp);
static short                _marpaESLIF_lua_value_actionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static short                _marpaESLIF_lua_value_symbolb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFValueResult_t *marpaESLIFValueResultp, int resulti);
static short                _marpaESLIF_lua_value_representationb(void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, char **inputcpp, size_t *inputlp, char **encodingasciisp, marpaESLIFRepresentationDispose_t *disposeCallbackpp, short *stringbp);
static short                _marpaESLIF_lua_recognizer_eventactionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFEvent_t *eventArrayp, size_t eventArrayl, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp);
static inline marpaESLIFGrammar_t *_marpaESLIF_lua_grammarp(marpaESLIF_t *marpaESLIFp, char *starts);
static short                _marpaESLIF_lua_value_action_functionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static short                _marpaESLIF_lua_value_symbol_functionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFValueResult_t *marpaESLIFValueResultp, int resulti);
static short                _marpaESLIF_lua_recognizer_ifaction_functionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFValueResultp, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp);
static short                _marpaESLIF_lua_recognizer_regexaction_functionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *marpaESLIFCalloutBlockp, marpaESLIFValueResultInt_t *marpaESLIFValueResultOutp);
static short                _marpaESLIF_lua_recognizer_generatoraction_functionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *contextp, marpaESLIFValueResultString_t *marpaESLIFValueResultOutp);
static short                _marpaESLIF_lua_recognizer_eventaction_functionb(void *userDatavp, marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFEvent_t *eventArrayp, size_t eventArrayl, marpaESLIFValueResultBool_t *marpaESLIFValueResultBoolp);
static inline short         _marpaESLIF_lua_recognizer_push_contextb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIF_symbol_t *symbolp);
static inline short         _marpaESLIF_lua_recognizer_pop_contextb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp);
static inline short         _marpaESLIF_lua_recognizer_get_contextp(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *contextp);
static inline short         _marpaESLIF_lua_recognizer_set_contextb(marpaESLIFRecognizer_t *marpaESLIFRecognizerp, marpaESLIFValueResult_t *contextp);

#endif /* MARPAESLIF_INTERNAL_LUA_H */

