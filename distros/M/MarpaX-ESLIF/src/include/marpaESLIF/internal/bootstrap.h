#ifndef MARPAESLIF_INTERNAL_BOOTSTRAP_H
#define MARPAESLIF_INTERNAL_BOOTSTRAP_H

#include "marpaESLIF.h"

/* This file contain the declaration of all bootstrap actions, i.e. the ESLIF grammar itself */
/* This is an example of how to use the API */

typedef enum _marpaESLIFBootstrapStackTypeEnum {
  marpaESLIFBootstrapStackTypeEnum_NA = 0,
  marpaESLIFBootstrapStackTypeEnum_OP_DECLARE,
  marpaESLIFBootstrapStackTypeEnum_SYMBOL_NAME,
  marpaESLIFBootstrapStackTypeEnum_RHS_PRIMARY,
  marpaESLIFBootstrapStackTypeEnum_LUA_FUNCTIONCALL,
  marpaESLIFBootstrapStackTypeEnum_LUA_FUNCTIONDECL,
  marpaESLIFBootstrapStackTypeEnum_RHS_ALTERNATIVE,
  marpaESLIFBootstrapStackTypeEnum_RHS,
  marpaESLIFBootstrapStackTypeEnum_LHS,
  marpaESLIFBootstrapStackTypeEnum_START_SYMBOL,
  marpaESLIFBootstrapStackTypeEnum_LUA_SYMBOL,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_ACTION,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_LEFT_ASSOCIATION,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_RIGHT_ASSOCIATION,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_GROUP_ASSOCIATION,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_SEPARATOR,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_PROPER,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_VERBOSE,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_HIDESEPARATOR,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_RANK,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_NULL_RANKING,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_PRIORITY,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_PAUSE,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_LATM,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_DISCARD_IS_FALLBACK,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_NAMING,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_SYMBOLACTION,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_EVENT_INITIALIZATION,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_IFACTION,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_REGEXACTION,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_EVENTACTION,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_DEFAULTENCODING,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_FALLBACKENCODING,
  marpaESLIFBootstrapStackTypeEnum_ADVERB_LIST_ITEMS,
  marpaESLIFBootstrapStackTypeEnum_ALTERNATIVE,
  marpaESLIFBootstrapStackTypeEnum_ALTERNATIVES,
  marpaESLIFBootstrapStackTypeEnum_PRIORITIES,
  marpaESLIFBootstrapStackTypeEnum_SINGLE_SYMBOL,
  marpaESLIFBootstrapStackTypeEnum_SYMBOL,
  marpaESLIFBootstrapStackTypeEnum_TERMINAL,
  marpaESLIFBootstrapStackTypeEnum_GRAMMAR_REFERENCE,
  marpaESLIFBootstrapStackTypeEnum_INACESSIBLE_TREATMENT,
  marpaESLIFBootstrapStackTypeEnum_ON_OR_OFF,
  marpaESLIFBootstrapStackTypeEnum_QUANTIFIER,
  marpaESLIFBootstrapStackTypeEnum_EVENT_INITIALIZER,
  marpaESLIFBootstrapStackTypeEnum_EVENT_INITIALIZATION,
  marpaESLIFBootstrapStackTypeEnum_ALTERNATIVE_NAME,
  marpaESLIFBootstrapStackTypeEnum_ARRAY,
  marpaESLIFBootstrapStackTypeEnum_STRING,
  marpaESLIFBootstrapStackTypeEnum_LUA_FUNCTION,
  marpaESLIFBootstrapStackTypeEnum_ACTION,
  _marpaESLIFBootstrapStackTypeEnum_LAST
} marpaESLIFBootstrapStackTypeEnum_t;

static char _MARPAESLIF_BOOTSTRAP_STACK_TYPE[_marpaESLIFBootstrapStackTypeEnum_LAST];

#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_NA                                &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_NA])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_OP_DECLARE                        &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_OP_DECLARE])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_SYMBOL_NAME                       &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_SYMBOL_NAME])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_RHS_PRIMARY                       &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_RHS_PRIMARY])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_LUA_FUNCTIONCALL                  &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_LUA_FUNCTIONCALL])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_LUA_FUNCTIONDECL                  &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_LUA_FUNCTIONDECL])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_RHS_ALTERNATIVE                   &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_RHS_ALTERNATIVE])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_RHS                               &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_RHS])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_LHS                               &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_LHS])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_START_SYMBOL                      &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_START_SYMBOL])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_LUA_SYMBOL                        &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_LUA_SYMBOL])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_ACTION                &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_ACTION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_LEFT_ASSOCIATION      &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_LEFT_ASSOCIATION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_RIGHT_ASSOCIATION     &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_RIGHT_ASSOCIATION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_GROUP_ASSOCIATION     &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_GROUP_ASSOCIATION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_SEPARATOR             &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_SEPARATOR])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_PROPER                &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_PROPER])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_VERBOSE               &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_VERBOSE])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_HIDESEPARATOR         &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_HIDESEPARATOR])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_RANK                  &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_RANK])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_NULL_RANKING          &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_NULL_RANKING])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_PRIORITY              &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_PRIORITY])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_PAUSE                 &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_PAUSE])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_LATM                  &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_LATM])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_DISCARD_IS_FALLBACK   &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_DISCARD_IS_FALLBACK])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_NAMING                &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_NAMING])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_SYMBOLACTION          &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_SYMBOLACTION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_EVENT_INITIALIZATION  &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_EVENT_INITIALIZATION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_IFACTION              &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_IFACTION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_REGEXACTION           &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_REGEXACTION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_EVENTACTION           &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_EVENTACTION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_DEFAULTENCODING       &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_DEFAULTENCODING])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_FALLBACKENCODING      &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_ITEM_FALLBACKENCODING])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_LIST_ITEMS                 &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ADVERB_LIST_ITEMS])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ALTERNATIVE                       &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ALTERNATIVE])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ALTERNATIVES                      &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ALTERNATIVES])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_PRIORITIES                        &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_PRIORITIES])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_SINGLE_SYMBOL                     &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_SINGLE_SYMBOL])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_SYMBOL                            &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_SYMBOL])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_TERMINAL                          &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_TERMINAL])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_GRAMMAR_REFERENCE                 &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_GRAMMAR_REFERENCE])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_INACESSIBLE_TREATMENT             &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_INACESSIBLE_TREATMENT])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ON_OR_OFF                         &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ON_OR_OFF])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_QUANTIFIER                        &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_QUANTIFIER])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_EVENT_INITIALIZER                 &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_EVENT_INITIALIZER])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_EVENT_INITIALIZATION              &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_EVENT_INITIALIZATION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ALTERNATIVE_NAME                  &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ALTERNATIVE_NAME])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ARRAY                             &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ARRAY])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_STRING                            &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_STRING])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_LUA_FUNCTION                      &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_LUA_FUNCTION])
#define MARPAESLIF_BOOTSTRAP_STACK_TYPE_ACTION                            &(_MARPAESLIF_BOOTSTRAP_STACK_TYPE[marpaESLIFBootstrapStackTypeEnum_ACTION])

/* Forward declarations */
typedef enum   marpaESLIF_bootstrap_stack_context               marpaESLIF_bootstrap_stack_context_t;
typedef enum   marpaESLIF_bootstrap_adverb_list_item_type       marpaESLIF_bootstrap_adverb_list_item_type_t;
typedef enum   marpaESLIF_bootstrap_pause_type                  marpaESLIF_bootstrap_pause_type_t;
typedef enum   marpaESLIF_bootstrap_single_symbol_type          marpaESLIF_bootstrap_single_symbol_type_t;
typedef enum   marpaESLIF_bootstrap_terminal_type               marpaESLIF_bootstrap_terminal_type_t;
typedef enum   marpaESLIF_bootstrap_rhs_primary_type            marpaESLIF_bootstrap_rhs_primary_type_t;
typedef enum   marpaESLIF_bootstrap_rhs_alternative_type        marpaESLIF_bootstrap_rhs_alternative_type_t;
typedef enum   marpaESLIF_bootstrap_grammar_reference_type      marpaESLIF_bootstrap_grammar_reference_type_t;
typedef enum   marpaESLIF_bootstrap_inaccessible_treatment_type marpaESLIF_bootstrap_inaccessible_treatment_type_t;
typedef enum   marpaESLIF_bootstrap_on_or_off_type              marpaESLIF_bootstrap_on_or_off_type_t;
typedef enum   marpaESLIF_bootstrap_event_initializer_type      marpaESLIF_bootstrap_event_initializer_type_t;
typedef enum   marpaESLIF_bootstrap_event_declaration_type      marpaESLIF_bootstrap_event_declaration_type_t;

typedef struct marpaESLIF_bootstrap_utf_string                 marpaESLIF_bootstrap_utf_string_t;
typedef struct marpaESLIF_bootstrap_single_symbol              marpaESLIF_bootstrap_single_symbol_t;
typedef struct marpaESLIF_bootstrap_symbol                     marpaESLIF_bootstrap_symbol_t;
typedef struct marpaESLIF_bootstrap_lhs                        marpaESLIF_bootstrap_lhs_t;
typedef struct marpaESLIF_bootstrap_start_symbol               marpaESLIF_bootstrap_start_symbol_t;
typedef struct marpaESLIF_bootstrap_terminal                   marpaESLIF_bootstrap_terminal_t;
typedef struct marpaESLIF_bootstrap_adverb_list_item           marpaESLIF_bootstrap_adverb_list_item_t;
typedef struct marpaESLIF_bootstrap_grammar_reference          marpaESLIF_bootstrap_grammar_reference_t;
typedef struct marpaESLIF_bootstrap_symbol_and_reference       marpaESLIF_bootstrap_symbol_and_reference_t;
typedef struct marpaESLIF_bootstrap_rhs_primary                marpaESLIF_bootstrap_rhs_primary_t;
typedef        marpaESLIF_lua_functiondecl_t                   marpaESLIF_bootstrap_lua_functiondecl_t;
typedef struct marpaESLIF_bootstrap_rhs_alternative            marpaESLIF_bootstrap_rhs_alternative_t;
typedef struct marpaESLIF_bootstrap_rhs_alternative_priorities marpaESLIF_bootstrap_rhs_alternative_priorities_t;
typedef struct marpaESLIF_bootstrap_rhs_alternative_exception  marpaESLIF_bootstrap_rhs_alternative_exception_t;
typedef struct marpaESLIF_bootstrap_rhs_alternative_quantified marpaESLIF_bootstrap_rhs_alternative_quantified_t;
typedef struct marpaESLIF_bootstrap_alternative                marpaESLIF_bootstrap_alternative_t;
typedef struct marpaESLIF_bootstrap_event_initialization       marpaESLIF_bootstrap_event_initialization_t;
typedef struct marpaESLIF_bootstrap_lua_function               marpaESLIF_bootstrap_lua_function_t;

enum marpaESLIF_bootstrap_adverb_list_item_type {
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_NA = 0,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_ACTION,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_LEFT_ASSOCIATION,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_RIGHT_ASSOCIATION,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_GROUP_ASSOCIATION,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_SEPARATOR,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_PROPER,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_VERBOSE,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_HIDESEPARATOR,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_RANK,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_NULL_RANKING,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_PRIORITY,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_PAUSE,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_LATM,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_DISCARD_IS_FALLBACK,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_NAMING,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_SYMBOLACTION,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_EVENT_INITIALIZATION,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_IFACTION,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_REGEXACTION,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_EVENTACTION,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_DEFAULTENCODING,
  MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_FALLBACKENCODING
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
  MARPAESLIF_BOOTSTRAP_SINGLE_SYMBOL_TYPE_TERMINAL
};

struct marpaESLIF_bootstrap_symbol {
  char *symbols;
};

struct marpaESLIF_bootstrap_lhs {
  char                                    *symbols;
  marpaESLIF_bootstrap_lua_functiondecl_t *declp;
};

struct marpaESLIF_bootstrap_start_symbol {
  char                          *symbols;
  marpaESLIF_lua_functioncall_t *callp;
};

enum marpaESLIF_bootstrap_terminal_type {
  MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE_NA = 0,
  MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE_CHARACTER_CLASS,
  MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE_REGULAR_EXPRESSION,
  MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE_QUOTED_STRING,
  MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__EOF,
  MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__EOL,
  MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__SOL,
  MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__EMPTY
};

struct marpaESLIF_bootstrap_terminal {
  marpaESLIF_bootstrap_terminal_type_t type;
  union {
    marpaESLIF_bootstrap_utf_string_t *characterClassp;
    marpaESLIF_bootstrap_utf_string_t *regularExpressionp;
    marpaESLIF_bootstrap_utf_string_t *stringp;
  } u;
};

struct marpaESLIF_bootstrap_single_symbol {
  marpaESLIF_bootstrap_single_symbol_type_t type;
  union {
    marpaESLIF_bootstrap_symbol_t     *symbolp;
    marpaESLIF_bootstrap_terminal_t   *terminalp;
  } u;
};

struct marpaESLIF_bootstrap_adverb_list_item {
  marpaESLIF_bootstrap_adverb_list_item_type_t type;
  union {
    marpaESLIF_action_t                         *actionp;
    short                                        left_associationb;
    short                                        right_associationb;
    short                                        group_associationb;
    marpaESLIF_bootstrap_rhs_primary_t          *separatorRhsPrimaryp;
    short                                        properb;
    short                                        verboseb;
    short                                        hideseparatorb;
    int                                          ranki;
    short                                        nullRanksHighb;
    int                                          priorityi;
    marpaESLIF_bootstrap_pause_type_t            pausei;
    short                                        latmb;
    short                                        discardIsFallbackb;
    marpaESLIF_bootstrap_utf_string_t           *namingp;
    marpaESLIF_action_t                         *symbolactionp;
    marpaESLIF_bootstrap_event_initialization_t *eventInitializationp;
    marpaESLIF_action_t                         *ifactionp;
    marpaESLIF_action_t                         *regexactionp;
    marpaESLIF_action_t                         *eventactionp;
    char                                        *defaultEncodings;
    char                                        *fallbackEncodings;
  } u;
};

enum marpaESLIF_bootstrap_rhs_alternative_type {
  MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_NA = 0,
  MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_RHS_PRIMARY,
  MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_PRIORITIES,
  MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_EXCEPTION,
  MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_QUANTIFIED
};

enum marpaESLIF_bootstrap_rhs_primary_type {
  MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_NA = 0,
  MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_SINGLE_SYMBOL,
  MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_SYMBOL_AND_REFERENCE,
  MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_GENERATOR_ACTION,
  MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_NAME
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

struct marpaESLIF_bootstrap_symbol_and_reference {
  marpaESLIF_bootstrap_symbol_t            *symbolp;
  marpaESLIF_bootstrap_grammar_reference_t *grammarReferencep;
};

struct marpaESLIF_bootstrap_rhs_alternative_priorities {
  short                               skipb;
  short                               lookaheadb;
  genericStack_t                     *alternativesStackp;
};

struct marpaESLIF_bootstrap_rhs_alternative_exception {
  short                               skipb;
  short                               lookaheadb;
  marpaESLIF_bootstrap_rhs_primary_t *rhsPrimaryp;
  marpaESLIF_bootstrap_rhs_primary_t *rhsPrimaryExceptionp;
  genericStack_t                     *adverbListItemStackp;
};

struct marpaESLIF_bootstrap_rhs_alternative_quantified {
  short                               skipb;
  short                               lookaheadb;
  marpaESLIF_bootstrap_rhs_primary_t *rhsPrimaryp;
  int                                 minimumi;
  genericStack_t                     *adverbListItemStackp;
};

struct marpaESLIF_bootstrap_rhs_primary {
  marpaESLIF_lua_functioncall_t           *callp;
  marpaESLIF_bootstrap_rhs_primary_type_t  type;
  union {
    marpaESLIF_bootstrap_single_symbol_t        *singleSymbolp;
    marpaESLIF_bootstrap_symbol_and_reference_t *symbolAndReferencep;
    marpaESLIF_action_t                         *generatorActionp;
    marpaESLIF_bootstrap_utf_string_t            name;

  } u;
};

struct marpaESLIF_bootstrap_rhs_alternative {
  marpaESLIF_bootstrap_rhs_alternative_type_t type;
  union {
    marpaESLIF_bootstrap_rhs_primary_t                *rhsPrimaryp;
    marpaESLIF_bootstrap_rhs_alternative_priorities_t  priorities;
    marpaESLIF_bootstrap_rhs_alternative_exception_t   exception;
    marpaESLIF_bootstrap_rhs_alternative_quantified_t  quantified;
  } u;
};

struct marpaESLIF_bootstrap_alternative {
  genericStack_t      *rhsAlternativeStackp;
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

struct marpaESLIF_bootstrap_lua_function {
  char   *luas;
  char   *actions;
  short   luacb;
  char   *luacstripp;
  size_t  luacstripl;
};

static marpaESLIFValueRuleCallback_t _marpaESLIF_bootstrap_ruleActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions);

#endif /* MARPAESLIF_INTERNAL_BOOTSTRAP_H */

