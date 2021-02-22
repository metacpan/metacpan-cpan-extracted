#ifndef MARPAWRAPPER_RECOGNIZER_H
#define MARPAWRAPPER_RECOGNIZER_H

#include <marpaWrapper/grammar.h>

/***********************/
/* Opaque object types */
/***********************/
typedef struct marpaWrapperRecognizer marpaWrapperRecognizer_t;

/* --------------- */
/* General options */
/* --------------- */
typedef struct marpaWrapperRecognizerOption {
  genericLogger_t *genericLoggerp;             /* Default: NULL. */
  short            disableThresholdb;          /* Default: 0.    */
  short            exhaustionEventb;           /* Default: 0     */
} marpaWrapperRecognizerOption_t;

typedef struct marpaWrapperRecognizerProgress {
  int earleySetIdi;
  int earleySetOrigIdi;
  int rulei;
  int positioni;
} marpaWrapperRecognizerProgress_t;

typedef struct marpaWrapperRecognizerContext {
  int   valuei;
  void *valuep;
} marpaWrapperRecognizerContext_t;

typedef char *(*marpaWrapperRecognizerSymbolDescriptionCallback_t)(void *userDatavp, int symboli);
typedef void  (*marpaWrapperRecognizerContextFreeCallback_t)(void *userDatavp, marpaWrapperRecognizerContext_t *contextp);

#ifdef __cplusplus
extern "C" {
#endif
  marpaWrapper_EXPORT marpaWrapperRecognizer_t    *marpaWrapperRecognizer_newp(marpaWrapperGrammar_t *marpaWrapperGrammarp, marpaWrapperRecognizerOption_t *marpaWrapperRecognizerOptionp);
  marpaWrapper_EXPORT short                        marpaWrapperRecognizer_alternativeb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, int symboli, int valuei, int lengthi);
  marpaWrapper_EXPORT short                        marpaWrapperRecognizer_completeb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp);
  marpaWrapper_EXPORT short                        marpaWrapperRecognizer_latestb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, int *earleySetIdip);
  marpaWrapper_EXPORT short                        marpaWrapperRecognizer_readb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, int symboli, int valuei, int lengthi);
  marpaWrapper_EXPORT short                        marpaWrapperRecognizer_event_onoffb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, int symboli, marpaWrapperGrammarEventType_t eventSeti, int onoffb);
  marpaWrapper_EXPORT short                        marpaWrapperRecognizer_expectedb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, size_t *nSymbollp, int **symbolArraypp);
  marpaWrapper_EXPORT short                        marpaWrapperRecognizer_isExpectedb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, int symboli, short *isExpectedbp);
  marpaWrapper_EXPORT short                        marpaWrapperRecognizer_exhaustedb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, short *exhaustedbp);
  marpaWrapper_EXPORT short                        marpaWrapperRecognizer_progressb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, int starti, int endi, size_t *nProgresslp, marpaWrapperRecognizerProgress_t **progresspp);
  marpaWrapper_EXPORT short                        marpaWrapperRecognizer_progressLogb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, int starti, int endi, genericLoggerLevel_t logleveli, void *userDatavp, marpaWrapperRecognizerSymbolDescriptionCallback_t symbolDescriptionCallbackp);
  marpaWrapper_EXPORT marpaWrapperGrammar_t       *marpaWrapperRecognizer_grammarp(marpaWrapperRecognizer_t *marpaWrapperRecognizerp);
  marpaWrapper_EXPORT short                        marpaWrapperRecognizer_contextSetb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, marpaWrapperRecognizerContext_t context);
  marpaWrapper_EXPORT short                        marpaWrapperRecognizer_contextGetb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, int i, marpaWrapperRecognizerContext_t *contextp);
  marpaWrapper_EXPORT short                        marpaWrapperRecognizer_currentEarlemeb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, int *ip);
  marpaWrapper_EXPORT short                        marpaWrapperRecognizer_earlemeb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, int i, int *ip);
  marpaWrapper_EXPORT short                        marpaWrapperRecognizer_furthestEarlemeb(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, int *ip);
  marpaWrapper_EXPORT void                         marpaWrapperRecognizer_freev(marpaWrapperRecognizer_t *marpaWrapperRecognizerp);
#ifdef __cplusplus
}
#endif

#endif /* MARPAWRAPPER_RECOGNIZER_H */
