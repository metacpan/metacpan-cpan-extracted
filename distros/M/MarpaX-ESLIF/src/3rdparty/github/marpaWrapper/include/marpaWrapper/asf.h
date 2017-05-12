#ifndef MARPAWRAPPER_ASF_H
#define MARPAWRAPPER_ASF_H

#include <genericStack.h>
#include <marpaWrapper/value.h>

/***********************/
/* Opaque object types */
/***********************/
typedef struct marpaWrapperAsf          marpaWrapperAsf_t;
typedef struct marpaWrapperAsfTraverser marpaWrapperAsfTraverser_t;
typedef struct marpaWrapperAsfValue     marpaWrapperAsfValue_t;

/* ------------------------------------------------------------- */
/* Ok callbacks: they return 0 if failure, 1 if ok, -1 if reject */
/* ------------------------------------------------------------- */
typedef short (*marpaWrapperAsfOkRuleCallback_t)(void *userDatavp, genericStack_t *parentRuleiStackp, int rulei, int arg0i, int argni);
typedef short (*marpaWrapperAsfOkSymbolCallback_t)(void *userDatavp, genericStack_t *parentRuleiStackp, int symboli, int argi);
typedef short (*marpaWrapperAsfOkNullingCallback_t)(void *userDatavp, genericStack_t *parentRuleiStackp, int symboli);

/* --------------- */
/* General options */
/* --------------- */
typedef struct marpaWrapperAsfOption {
  genericLogger_t *genericLoggerp;             /* Default: NULL. */
  short            highRankOnlyb;              /* Default: 1 */
  short            orderByRankb;               /* Default: 1 */
  short            ambiguousb;                 /* Default: 0 */
  int              maxParsesi;                 /* Default: 0 */
} marpaWrapperAsfOption_t;

/* A traverser always returns a false or a true value, and a "user-space" value in *valueip.  */
/* think to it as convienent ways to have an index in an output stack, managed in user-space. */
/* A false return value is indicating a failure and traversing will stop.                     */
typedef short (*traverserCallback_t)(marpaWrapperAsfTraverser_t *traverserp, void *userDatavp, int *valueip);

#ifdef __cplusplus
extern "C" {
#endif
  marpaWrapper_EXPORT marpaWrapperAsf_t        *marpaWrapperAsf_newp(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, marpaWrapperAsfOption_t *marpaWrapperAsfOptionp);
  marpaWrapper_EXPORT short                     marpaWrapperAsf_traverseb(marpaWrapperAsf_t *marpaWrapperAsfp, traverserCallback_t traverserCallbackp, void *userDatavp, int *valueip);
  marpaWrapper_EXPORT int                       marpaWrapperAsf_traverse_rh_lengthi(marpaWrapperAsfTraverser_t *traverserp);
  marpaWrapper_EXPORT short                     marpaWrapperAsf_traverse_symbolIdb(marpaWrapperAsfTraverser_t *traverserp, int *symbolIdi);
  marpaWrapper_EXPORT short                     marpaWrapperAsf_traverse_ruleIdb(marpaWrapperAsfTraverser_t *traverserp, int *ruleIdip);
  marpaWrapper_EXPORT short                     marpaWrapperAsf_traverse_nextb(marpaWrapperAsfTraverser_t *traverserp, short *nextbp);
  marpaWrapper_EXPORT short                     marpaWrapperAsf_traverse_rh_valueb(marpaWrapperAsfTraverser_t *traverserp, int rhIxi, int *valueip, int *lengthip);
  marpaWrapper_EXPORT marpaWrapperAsf_t        *marpaWrapperAsf_traverse_asfp(marpaWrapperAsfTraverser_t *traverserp);
  marpaWrapper_EXPORT marpaWrapperRecognizer_t *marpaWrapperAsf_recognizerp(marpaWrapperAsf_t *marpaWrapperAsfp);
  marpaWrapper_EXPORT short                     marpaWrapperAsf_genericLoggerp(marpaWrapperAsf_t *marpaWrapperAsfp, genericLogger_t **genericLoggerpp);
  marpaWrapper_EXPORT void                      marpaWrapperAsf_freev(marpaWrapperAsf_t *marpaWrapperAsfp);

  /* Valuation method simulation */
  marpaWrapper_EXPORT marpaWrapperAsfValue_t *marpaWrapperAsfValue_newp(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, marpaWrapperAsfOption_t *marpaWrapperAsfOptionp);
  marpaWrapper_EXPORT short                   marpaWrapperAsfValue_valueb(marpaWrapperAsfValue_t            *marpaWrapperAsfValuep,
                                                                          void                              *userDatavp,
                                                                          marpaWrapperAsfOkRuleCallback_t    okRuleCallbackp,
                                                                          marpaWrapperAsfOkSymbolCallback_t  okSymbolCallbackp,
                                                                          marpaWrapperAsfOkNullingCallback_t okNullingCallbackp,
                                                                          marpaWrapperValueRuleCallback_t    valueRuleCallbackp,
                                                                          marpaWrapperValueSymbolCallback_t  valueSymbolCallbackp,
                                                                          marpaWrapperValueNullingCallback_t valueNullingCallbackp);
  marpaWrapper_EXPORT short                   marpaWrapperAsfValue_value_startb(marpaWrapperAsfValue_t *marpaWrapperAsfValuep, int *startip);
  marpaWrapper_EXPORT short                   marpaWrapperAsfValue_value_lengthb(marpaWrapperAsfValue_t *marpaWrapperAsfValuep, int *lengthip);
  marpaWrapper_EXPORT void                    marpaWrapperAsfValue_freev(marpaWrapperAsfValue_t *marpaWrapperAsfValuep);
#ifdef __cplusplus
}
#endif

#endif /* MARPAWRAPPER_ASF_H */
