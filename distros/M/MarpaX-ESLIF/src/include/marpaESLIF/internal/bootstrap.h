#ifndef MARPAESLIF_INTERNAL_BOOTSTRAP_H
#define MARPAESLIF_INTERNAL_BOOTSTRAP_H

#include <marpaESLIF.h>

/* This file contain the declaration of all bootstrap actions, i.e. the ESLIF grammar itself */
/* This is an example of how to use the API */

typedef enum _marpaESLIFBootstrapStackTypeEnum {
  marpaESLIFBootstrapStackTypeEnum_NA = 0,
  marpaESLIFBootstrapStackTypeEnum_OP_DECLARE,
  marpaESLIFBootstrapStackTypeEnum_SYMBOL_NAME,
  marpaESLIFBootstrapStackTypeEnum_RHS_PRIMARY,
  marpaESLIFBootstrapStackTypeEnum_RHS,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_ACTION,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_LEFT_ASSOCIATION,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_RIGHT_ASSOCIATION,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_GROUP_ASSOCIATION,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_SEPARATOR,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_PROPER,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_HIDESEPARATOR,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_RANK,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_NULL_RANKING,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_PRIORITY,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_PAUSE,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_LATM,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_NAMING,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_SYMBOLACTION,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_EVENT_INITIALIZATION,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_IFACTION,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_LIST_ITEMS,
  marpaESLIFBootstrapStackTypeEnum_ALTERNATIVE,
  marpaESLIFBootstrapStackTypeEnum_ALTERNATIVES,
  marpaESLIFBootstrapStackTypeEnum_PRIORITIES,
  marpaESLIFBootstrapStackTypeEnum_SINGLE_SYMBOL,
  marpaESLIFBootstrapStackTypeEnum_GRAMMAR_REFERENCE,
  marpaESLIFBootstrapStackTypeEnum_INACESSIBLE_TREATMENT,
  marpaESLIFBootstrapStackTypeEnum_ON_OR_OFF,
  marpaESLIFBootstrapStackTypeEnum_QUANTIFIER,
  marpaESLIFBootstrapStackTypeEnum_EVENT_INITIALIZER,
  marpaESLIFBootstrapStackTypeEnum_EVENT_INITIALIZATION,
  marpaESLIFBootstrapStackTypeEnum_ALTERNATIVE_NAME,
  marpaESLIFBootstrapStackTypeEnum_ARRAY,
  marpaESLIFBootstrapStackTypeEnum_STRING,
  _marpaESLIFBootstrapStackTypeEnum_LAST
} marpaESLIFBootstrapStackTypeEnum_t;

static char _MARPAESLIF_BOOTSTRAP_STACK_TYPE[_marpaESLIFBootstrapStackTypeEnum_LAST];

#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_NA                               &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_NA])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_OP_DECLARE                       &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_OP_DECLARE])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_SYMBOL_NAME                      &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_SYMBOL_NAME])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_RHS_PRIMARY                      &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_RHS_PRIMARY])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_RHS                              &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_RHS])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_ACTION               &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_ACTION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_LEFT_ASSOCIATION     &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_LEFT_ASSOCIATION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_RIGHT_ASSOCIATION    &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_RIGHT_ASSOCIATION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_GROUP_ASSOCIATION    &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_GROUP_ASSOCIATION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_SEPARATOR            &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_SEPARATOR])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_PROPER               &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_PROPER])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_HIDESEPARATOR        &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_HIDESEPARATOR])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_RANK                 &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_RANK])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_NULL_RANKING         &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_NULL_RANKING])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_PRIORITY             &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_PRIORITY])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_PAUSE                &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_PAUSE])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_LATM                 &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_LATM])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_NAMING               &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_NAMING])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_SYMBOLACTION         &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_SYMBOLACTION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_EVENT_INITIALIZATION &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_EVENT_INITIALIZATION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_IFACTION             &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_IFACTION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_LIST_ITEMS                &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_LIST_ITEMS])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ALTERNATIVE                      &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ALTERNATIVE])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ALTERNATIVES                     &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ALTERNATIVES])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_PRIORITIES                       &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_PRIORITIES])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_SINGLE_SYMBOL                    &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_SINGLE_SYMBOL])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_GRAMMAR_REFERENCE                &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_GRAMMAR_REFERENCE])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_INACESSIBLE_TREATMENT            &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_INACESSIBLE_TREATMENT])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ON_OR_OFF                        &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ON_OR_OFF])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_QUANTIFIER                       &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_QUANTIFIER])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_EVENT_INITIALIZER                &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_EVENT_INITIALIZER])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_EVENT_INITIALIZATION             &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_EVENT_INITIALIZATION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ALTERNATIVE_NAME                 &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ALTERNATIVE_NAME])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ARRAY                            &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ARRAY])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_STRING                           &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_STRING])

#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_START MARPAESLIF_BOOTSTRAP_STACK_TYPE_NA
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_END MARPAESLIF_BOOTSTRAP_STACK_TYPE_STRING

/* Forward declarations */
typedef enum   marpaESLIF_bootstrap_stack_context               marpaESLIF_bootstrap_stack_context_t;
typedef enum   marpaESLIF_bootstrap_adverb_list_item_type       marpaESLIF_bootstrap_adverb_list_item_type_t;
typedef enum   marpaESLIF_bootstrap_pause_type                  marpaESLIF_bootstrap_pause_type_t;
typedef enum   marpaESLIF_bootstrap_single_symbol_type          marpaESLIF_bootstrap_single_symbol_type_t;
typedef enum   marpaESLIF_bootstrap_rhs_primary_type            marpaESLIF_bootstrap_rhs_primary_type_t;
typedef enum   marpaESLIF_bootstrap_grammar_reference_type      marpaESLIF_bootstrap_grammar_reference_type_t;
typedef enum   marpaESLIF_bootstrap_inaccessible_treatment_type marpaESLIF_bootstrap_inaccessible_treatment_type_t;
typedef enum   marpaESLIF_bootstrap_on_or_off_type              marpaESLIF_bootstrap_on_or_off_type_t;
typedef enum   marpaESLIF_bootstrap_event_initializer_type      marpaESLIF_bootstrap_event_initializer_type_t;
typedef enum   marpaESLIF_bootstrap_event_declaration_type      marpaESLIF_bootstrap_event_declaration_type_t;

typedef struct marpaESLIF_bootstrap_utf_string                marpaESLIF_bootstrap_utf_string_t;
typedef struct marpaESLIF_bootstrap_single_symbol             marpaESLIF_bootstrap_single_symbol_t;
typedef struct marpaESLIF_bootstrap_adverb_list_item          marpaESLIF_bootstrap_adverb_list_item_t;
typedef struct marpaESLIF_bootstrap_grammar_reference         marpaESLIF_bootstrap_grammar_reference_t;
typedef struct marpaESLIF_bootstrap_symbol_name_and_reference marpaESLIF_bootstrap_symbol_name_and_reference_t;
typedef struct marpaESLIF_bootstrap_rhs_primary               marpaESLIF_bootstrap_rhs_primary_t;
typedef struct marpaESLIF_bootstrap_rhs_primary_exception     marpaESLIF_bootstrap_rhs_primary_exception_t;
typedef struct marpaESLIF_bootstrap_rhs_primary_quantified    marpaESLIF_bootstrap_rhs_primary_quantified_t;
typedef struct marpaESLIF_bootstrap_alternative               marpaESLIF_bootstrap_alternative_t;
typedef struct marpaESLIF_bootstrap_event_initialization      marpaESLIF_bootstrap_event_initialization_t;

enum marpaESLIF_bootstrap_adverb_list_item_type {
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_NA = 0,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_ACTION,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_LEFT_ASSOCIATION,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_RIGHT_ASSOCIATION,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_GROUP_ASSOCIATION,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_SEPARATOR,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_PROPER,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_HIDESEPARATOR,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_RANK,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_NULL_RANKING,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_PRIORITY,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_PAUSE,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_LATM,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_NAMING,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_SYMBOLACTION,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_EVENT_INITIALIZATION,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_IFACTION
};

enum marpaESLIF_bootstrap_pause_type {
  MARPAESLIF_BOOTSTRAP_PAUSE_TYPE_NA = 0,
  MARPAESLIF_BOOTSTRAP_PAUSE_TYPE_BEFORE,
  MARPAESLIF_BOOTSTRAP_PAUSE_TYPE_AFTER
};

struct marpaESLIF_bootstrap_utf_string {
  char  *bytep;
  size_t bytel;
  char  *modifiers;
};

enum marpaESLIF_bootstrap_single_symbol_type {
  MARPAESLIF_BOOTSTRAP_SINGLE_SYMBOL_TYPE_NA = 0,
  MARPAESLIF_BOOTSTRAP_SINGLE_SYMBOL_TYPE_SYMBOL,
  MARPAESLIF_BOOTSTRAP_SINGLE_SYMBOL_TYPE_CHARACTER_CLASS,
  MARPAESLIF_BOOTSTRAP_SINGLE_SYMBOL_TYPE_REGULAR_EXPRESSION,
  MARPAESLIF_BOOTSTRAP_SINGLE_SYMBOL_TYPE_QUOTED_STRING
};

struct marpaESLIF_bootstrap_single_symbol {
  marpaESLIF_bootstrap_single_symbol_type_t type;
  union {
    char *symbols;
    marpaESLIF_bootstrap_utf_string_t *characterClassp;
    marpaESLIF_bootstrap_utf_string_t *regularExpressionp;
    marpaESLIF_bootstrap_utf_string_t *quotedStringp;
  } u;
};

struct marpaESLIF_bootstrap_adverb_list_item {
  marpaESLIF_bootstrap_adverb_list_item_type_t type;
  union {
    marpaESLIF_action_t                         *actionp;
    short                                        left_associationb;
    short                                        right_associationb;
    short                                        group_associationb;
    marpaESLIF_bootstrap_single_symbol_t        *separatorSingleSymbolp;
    short                                        properb;
    short                                        hideseparatorb;
    int                                          ranki;
    short                                        nullRanksHighb;
    int                                          priorityi;
    marpaESLIF_bootstrap_pause_type_t            pausei;
    short                                        latmb;
    marpaESLIF_bootstrap_utf_string_t           *namingp;
    marpaESLIF_action_t                         *symbolactionp;
    marpaESLIF_bootstrap_event_initialization_t *eventInitializationp;
    marpaESLIF_action_t                         *ifactionp;
  } u;
};

enum marpaESLIF_bootstrap_rhs_primary_type {
  MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_NA = 0,
  MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_SINGLE_SYMBOL,
  MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_SYMBOL_NAME_AND_REFERENCE,
  MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_PRIORITIES,
  MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_EXCEPTION,
  MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_QUANTIFIED
};

enum marpaESLIF_bootstrap_grammar_reference_type {
  MARPAESLIF_BOOTSTRAP_GRAMMAR_REFERENCE_TYPE_NA = 0,
  MARPAESLIF_BOOTSTRAP_GRAMMAR_REFERENCE_TYPE_STRING,
  MARPAESLIF_BOOTSTRAP_GRAMMAR_REFERENCE_TYPE_SIGNED_INTEGER,
  MARPAESLIF_BOOTSTRAP_GRAMMAR_REFERENCE_TYPE_UNSIGNED_INTEGER
};

struct marpaESLIF_bootstrap_grammar_reference {
  marpaESLIF_bootstrap_grammar_reference_type_t type;
  union {
    marpaESLIF_bootstrap_utf_string_t *quotedStringp;
    int                                signedIntegeri;
    unsigned int                       unsignedIntegeri;
  } u;
};

enum marpaESLIF_bootstrap_event_declaration_type {
  MARPAESLIF_BOOTSTRAP_EVENT_DECLARATION_TYPE_PREDICTED = 0,
  MARPAESLIF_BOOTSTRAP_EVENT_DECLARATION_TYPE_NULLED,
  MARPAESLIF_BOOTSTRAP_EVENT_DECLARATION_TYPE_COMPLETED
};

struct marpaESLIF_bootstrap_symbol_name_and_reference {
  char                                     *symbols;
  marpaESLIF_bootstrap_grammar_reference_t *grammarReferencep;
};

struct marpaESLIF_bootstrap_rhs_primary_exception {
  marpaESLIF_bootstrap_rhs_primary_t *rhsPrimaryp;
  marpaESLIF_bootstrap_rhs_primary_t *rhsPrimaryExceptionp;
  genericStack_t                     *adverbListItemStackp;
};

struct marpaESLIF_bootstrap_rhs_primary_quantified {
  marpaESLIF_bootstrap_rhs_primary_t *rhsPrimaryp;
  int                                 minimumi;
  genericStack_t                     *adverbListItemStackp;
};

struct marpaESLIF_bootstrap_rhs_primary {
  short                                    skipb;
  marpaESLIF_symbol_t                     *symbolShallowp;
  marpaESLIF_bootstrap_rhs_primary_type_t  type;
  union {
    marpaESLIF_bootstrap_single_symbol_t             *singleSymbolp;
    marpaESLIF_bootstrap_symbol_name_and_reference_t *symbolNameAndReferencep;
    genericStack_t                                   *alternativesStackp;
    marpaESLIF_bootstrap_rhs_primary_exception_t      exception;
    marpaESLIF_bootstrap_rhs_primary_quantified_t     quantified;
  } u;
};

struct marpaESLIF_bootstrap_alternative {
  genericStack_t      *rhsPrimaryStackp;
  genericStack_t      *adverbListItemStackp;
  int                  priorityi;         /* Used when there is the loosen "||" operator */
  marpaESLIF_symbol_t *forcedLhsp;        /* ditto */
};

enum marpaESLIF_bootstrap_inaccessible_treatment_type {
  MARPAESLIF_BOOTSTRAP_INACCESSIBLE_TREATMENT_TYPE_WARN = 0,
  MARPAESLIF_BOOTSTRAP_INACCESSIBLE_TREATMENT_TYPE_OK,
  MARPAESLIF_BOOTSTRAP_INACCESSIBLE_TREATMENT_TYPE_FATAL
};

enum marpaESLIF_bootstrap_on_or_off_type {
  MARPAESLIF_BOOTSTRAP_ON_OR_OFF_TYPE_ON = 0,
  MARPAESLIF_BOOTSTRAP_ON_OR_OFF_TYPE_OFF
};

enum marpaESLIF_bootstrap_event_initializer_type {
  MARPAESLIF_BOOTSTRAP_EVENT_INITIALIZER_TYPE_ON = 0,
  MARPAESLIF_BOOTSTRAP_EVENT_INITIALIZER_TYPE_OFF
};

struct marpaESLIF_bootstrap_event_initialization {
  char                                         *eventNames;
  marpaESLIF_bootstrap_event_initializer_type_t initializerb;
};

static marpaESLIFValueRuleCallback_t _marpaESLIF_bootstrap_ruleActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions);

#endif /* MARPAESLIF_INTERNAL_BOOTSTRAP_H */

