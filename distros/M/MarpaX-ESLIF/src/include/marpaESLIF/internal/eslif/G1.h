#ifndef MARPAESLIF_INTERNAL_ESLIF_G1_H
#define MARPAESLIF_INTERNAL_ESLIF_G1_H

#include "marpaESLIF/internal/eslif/L0_join_G1.h"

/* Description of internal G1 grammar */

/* It is very important here to list all the terminals first, and in order compatible */
/* with bootstrap_grammar_G1_terminals[] and bootstrap_grammar_G1_rules[] */
typedef enum bootstrap_grammar_G1_enum {
  G1_TERMINAL__START = 0,
  G1_TERMINAL__DESC,
  G1_TERMINAL_SEMICOLON,
  G1_TERMINAL_LEFT_BRACKET,
  G1_TERMINAL_RIGHT_BRACKET,
  G1_TERMINAL__DISCARD,
  G1_TERMINAL__DEFAULT,
  G1_TERMINAL_DEFAULT,
  G1_TERMINAL_EQUAL,
  G1_TERMINAL__LEXEME,
  G1_TERMINAL_EVENT,
  G1_TERMINAL_COMPLETED,
  G1_TERMINAL_NULLED,
  G1_TERMINAL_PREDICTED,
  G1_TERMINAL_IS,
  G1_TERMINAL_INACCESSIBLE,
  G1_TERMINAL_BY,
  G1_TERMINAL_WARN,
  G1_TERMINAL_OK,
  G1_TERMINAL_FATAL,
  G1_TERMINAL_MINUS,
  G1_TERMINAL_ACTION,
  G1_TERMINAL_SYMBOL_ACTION,
  G1_TERMINAL_FREE_ACTION,
  G1_TERMINAL_THEN,
  G1_TERMINAL_AUTORANK,
  G1_TERMINAL_ASSOC,
  G1_TERMINAL_LEFT,
  G1_TERMINAL_RIGHT,
  G1_TERMINAL_GROUP,
  G1_TERMINAL_SEPARATOR,
  G1_TERMINAL_PROPER,
  G1_TERMINAL_HIDESEPARATOR,
  G1_TERMINAL_RANK,
  G1_TERMINAL_NULL_RANKING,
  G1_TERMINAL_NULL,
  G1_TERMINAL_LOW,
  G1_TERMINAL_HIGH,
  G1_TERMINAL_PRIORITY,
  G1_TERMINAL_PAUSE,
  G1_TERMINAL_ON,
  G1_TERMINAL_OFF,
  G1_TERMINAL_LATM,
  G1_TERMINAL_BLESS,
  G1_TERMINAL_NAME,
  G1_TERMINAL_COMMA,
  G1_TERMINAL_LPAREN,
  G1_TERMINAL_RPAREN,
  G1_TERMINAL_STAR,
  G1_TERMINAL_PLUS,
  G1_TERMINAL___SHIFT,
  G1_TERMINAL___TRANSFER,
  G1_TERMINAL___UNDEF,
  G1_TERMINAL___ASCII,
  G1_TERMINAL___CONVERT,
  G1_TERMINAL___CONCAT,
  G1_TERMINAL___COPY,
  G1_TERMINAL_LEFT_ANGLE,
  G1_TERMINAL_RIGHT_ANGLE,
  G1_TERMINAL_AT_SIGN,
  G1_TERMINAL__SYMBOL,
  G1_TERMINAL_BEFORE,
  G1_TERMINAL_AFTER,
  G1_TERMINAL_SIGNED_INTEGER,
  G1_TERMINAL_UNSIGNED_INTEGER,
  G1_TERMINAL__DISCARD_ON,
  G1_TERMINAL__DISCARD_OFF,
  G1_TERMINAL_STRING_LITERAL_START,
  G1_TERMINAL_STRING_LITERAL_END,
  G1_TERMINAL_BACKSLASH,
  G1_TERMINAL_STRING_LITERAL_NOT_ESCAPED,
  G1_TERMINAL_STRING_LITERAL_ESCAPED_CHAR,
  G1_TERMINAL_STRING_LITERAL_ESCAPED_HEX,
  G1_TERMINAL_STRING_LITERAL_ESCAPED_CODEPOINT,
  G1_TERMINAL_STRING_LITERAL_ESCAPED_LARGE_CODEPOINT,
  /* ----- Non terminals ------ */
  G1_META_STATEMENTS,
  G1_META_STATEMENT,
  G1_META_START_RULE,
  G1_META_DESC_RULE,
  G1_META_EMPTY_RULE,
  G1_META_NULL_STATEMENT,
  G1_META_STATEMENT_GROUP,
  G1_META_PRIORITY_RULE,
  G1_META_QUANTIFIED_RULE,
  G1_META_DISCARD_RULE,
  G1_META_DEFAULT_RULE,
  G1_META_LEXEME_RULE,
  G1_META_COMPLETION_EVENT_DECLARATION,
  G1_META_NULLED_EVENT_DECLARATION,
  G1_META_PREDICTION_EVENT_DECLARATION,
  G1_META_INACCESSIBLE_STATEMENT,
  G1_META_INACCESSIBLE_TREATMENT,
  G1_META_EXCEPTION_STATEMENT,
  G1_META_AUTORANK_STATEMENT,
  G1_META_OP_DECLARE,
  G1_META_OP_DECLARE_ANY_GRAMMAR,
  G1_META_OP_DECLARE_TOP_GRAMMAR,
  G1_META_OP_DECLARE_LEX_GRAMMAR,
  G1_META_OP_LOOSEN,
  G1_META_OP_EQUAL_PRIORITY,
  G1_META_PRIORITIES,
  G1_META_ALTERNATIVES,
  G1_META_ALTERNATIVE,
  G1_META_ADVERB_LIST,
  G1_META_ADVERB_LIST_ITEMS,
  G1_META_ADVERB_ITEM,
  G1_META_ACTION,
  G1_META_SYMBOL_ACTION,
  G1_META_FREE_ACTION,
  G1_META_LEFT_ASSOCIATION,
  G1_META_RIGHT_ASSOCIATION,
  G1_META_GROUP_ASSOCIATION,
  G1_META_SEPARATOR_SPECIFICATION,
  G1_META_PROPER_SPECIFICATION,
  G1_META_HIDESEPARATOR_SPECIFICATION,
  G1_META_RANK_SPECIFICATION,
  G1_META_NULL_RANKING_SPECIFICATION,
  G1_META_NULL_RANKING_CONSTANT,
  G1_META_PRIORITY_SPECIFICATION,
  G1_META_PAUSE_SPECIFICATION,
  G1_META_EVENT_SPECIFICATION,
  G1_META_EVENT_INITIALIZATION,
  G1_META_EVENT_INITIALIZER,
  G1_META_ON_OR_OFF,
  G1_META_LATM_SPECIFICATION,
  G1_META_NAMING,
  G1_META_NULL_ADVERB,
  G1_META_ALTERNATIVE_NAME,
  G1_META_EVENT_NAME,
  G1_META_LHS,
  G1_META_RHS,
  G1_META_RHS_PRIMARY,
  G1_META_SINGLE_SYMBOL,
  G1_META_SYMBOL,
  G1_META_SYMBOL_NAME,
  G1_META_ACTION_NAME,
  G1_META_FREE_NAME,
  G1_META_SYMBOLACTION_NAME,
  G1_META_QUANTIFIER,
  G1_META_GRAMMAR_REFERENCE,
  G1_META_SIGNED_INTEGER,
  G1_META_UNSIGNED_INTEGER,
  G1_META_STRING_LITERAL,
  G1_META_STRING_LITERAL_UNIT,
  G1_META_STRING_LITERAL_INSIDE,
  G1_META_STRING_LITERAL_INSIDE_ANY,
  G1_META_DISCARD_OFF,
  G1_META_DISCARD_ON,
  /* This symbol is special, c.f. bootstrap_grammar_G1_metas[] array below: it has the discard flag on */
  G1_META_DISCARD,
  /* These meta identifiers are handled by L0 */
  G1_META_FALSE,
  G1_META_TRUE,
  G1_META_STANDARD_NAME,
  G1_META_QUOTED_NAME,
  G1_META_QUOTED_STRING,
  G1_META_CHARACTER_CLASS,
  G1_META_REGULAR_EXPRESSION,
  G1_META_BARE_NAME,
  G1_META_BRACKETED_NAME,
  G1_META_RESTRICTED_ASCII_GRAPH_NAME,
  G1_META_WHITESPACE,
  G1_META_PERL_COMMENT,
  G1_META_CPLUSPLUS_COMMENT
} bootstrap_grammar_G1_enum_t;

/* All non-terminals are listed here */
bootstrap_grammar_meta_t bootstrap_grammar_G1_metas[] = {
  /* Identifier                               Description                              Start  Discard :discard[on] :discard[off] */
  { G1_META_STATEMENTS,                       "statements",                                1,       0,           0,            0 },
  { G1_META_STATEMENT,                        "statement",                                 0,       0,           0,            0 },
  { G1_META_START_RULE,                       "start rule",                                0,       0,           0,            0 },
  { G1_META_DESC_RULE,                        "desc rule",                                 0,       0,           0,            0 },
  { G1_META_EMPTY_RULE,                       "empty rule",                                0,       0,           0,            0 },
  { G1_META_NULL_STATEMENT,                   "null statement",                            0,       0,           0,            0 },
  { G1_META_STATEMENT_GROUP,                  "statement group",                           0,       0,           0,            0 },
  { G1_META_PRIORITY_RULE,                    "priority rule",                             0,       0,           0,            0 },
  { G1_META_QUANTIFIED_RULE,                  "quantified rule",                           0,       0,           0,            0 },
  { G1_META_DISCARD_RULE,                     "discard rule",                              0,       0,           0,            0 },
  { G1_META_DEFAULT_RULE,                     "default rule",                              0,       0,           0,            0 },
  { G1_META_LEXEME_RULE,                      "lexeme rule",                               0,       0,           0,            0 },
  { G1_META_COMPLETION_EVENT_DECLARATION,     "completion event declaration",              0,       0,           0,            0 },
  { G1_META_NULLED_EVENT_DECLARATION,         "nulled event declaration",                  0,       0,           0,            0 },
  { G1_META_PREDICTION_EVENT_DECLARATION,     "prediction event declaration",              0,       0,           0,            0 },
  { G1_META_INACCESSIBLE_STATEMENT,           "inaccessible statement",                    0,       0,           0,            0 },
  { G1_META_INACCESSIBLE_TREATMENT,           "inaccessible treatment",                    0,       0,           0,            0 },
  { G1_META_EXCEPTION_STATEMENT,              "exception statement",                       0,       0,           0,            0 },
  { G1_META_AUTORANK_STATEMENT,               "autorank statement",                        0,       0,           0,            0 },
  { G1_META_OP_DECLARE,                       "op declare",                                0,       0,           0,            0 },
  { G1_META_OP_DECLARE_ANY_GRAMMAR,           L0_JOIN_G1_META_OP_DECLARE_ANY_GRAMMAR,      0,       0,           0,            0 },
  { G1_META_OP_DECLARE_TOP_GRAMMAR,           L0_JOIN_G1_META_OP_DECLARE_TOP_GRAMMAR,      0,       0,           0,            0 },
  { G1_META_OP_DECLARE_LEX_GRAMMAR,           L0_JOIN_G1_META_OP_DECLARE_LEX_GRAMMAR,      0,       0,           0,            0 },
  { G1_META_OP_LOOSEN,                        L0_JOIN_G1_META_OP_LOOSEN,                   0,       0,           0,            0 },
  { G1_META_OP_EQUAL_PRIORITY,                L0_JOIN_G1_META_OP_EQUAL_PRIORITY,           0,       0,           0,            0 },
  { G1_META_PRIORITIES,                       "priorities",                                0,       0,           0,            0 },
  { G1_META_ALTERNATIVES,                     "alternatives",                              0,       0,           0,            0 },
  { G1_META_ALTERNATIVE,                      "alternative",                               0,       0,           0,            0 },
  { G1_META_ADVERB_LIST,                      "adverb list",                               0,       0,           0,            0 },
  { G1_META_ADVERB_LIST_ITEMS,                "adverb list items",                         0,       0,           0,            0 },
  { G1_META_ADVERB_ITEM,                      "adverb item",                               0,       0,           0,            0 },
  { G1_META_ACTION,                           "action",                                    0,       0,           0,            0 },
  { G1_META_SYMBOL_ACTION,                    "symbol action",                             0,       0,           0,            0 },
  { G1_META_FREE_ACTION,                      "free action",                               0,       0,           0,            0 },
  { G1_META_LEFT_ASSOCIATION,                 "left association",                          0,       0,           0,            0 },
  { G1_META_RIGHT_ASSOCIATION,                "right association",                         0,       0,           0,            0 },
  { G1_META_GROUP_ASSOCIATION,                "group association",                         0,       0,           0,            0 },
  { G1_META_SEPARATOR_SPECIFICATION,          "separator specification",                   0,       0,           0,            0 },
  { G1_META_PROPER_SPECIFICATION,             "proper specification",                      0,       0,           0,            0 },
  { G1_META_HIDESEPARATOR_SPECIFICATION,      "hide separator specification",              0,       0,           0,            0 },
  { G1_META_RANK_SPECIFICATION,               "rank specification",                        0,       0,           0,            0 },
  { G1_META_NULL_RANKING_SPECIFICATION,       "null ranking specification",                0,       0,           0,            0 },
  { G1_META_NULL_RANKING_CONSTANT,            "null ranking constant",                     0,       0,           0,            0 },
  { G1_META_PRIORITY_SPECIFICATION,           "priority specification",                    0,       0,           0,            0 },
  { G1_META_PAUSE_SPECIFICATION,              "pause specification",                       0,       0,           0,            0 },
  { G1_META_EVENT_SPECIFICATION,              "event specification",                       0,       0,           0,            0 },
  { G1_META_EVENT_INITIALIZATION,             "event initialization",                      0,       0,           0,            0 },
  { G1_META_EVENT_INITIALIZER,                "event initializer",                         0,       0,           0,            0 },
  { G1_META_ON_OR_OFF,                        "on or off",                                 0,       0,           0,            0 },
  { G1_META_LATM_SPECIFICATION,               "latm specification",                        0,       0,           0,            0 },
  { G1_META_NAMING,                           "naming",                                    0,       0,           0,            0 },
  { G1_META_NULL_ADVERB,                      "null adverb",                               0,       0,           0,            0 },
  { G1_META_ALTERNATIVE_NAME,                 "alternative name",                          0,       0,           0,            0 },
  { G1_META_EVENT_NAME,                       "event name",                                0,       0,           0,            0 },
  { G1_META_LHS,                              "lhs",                                       0,       0,           0,            0 },
  { G1_META_RHS,                              "rhs",                                       0,       0,           0,            0 },
  { G1_META_RHS_PRIMARY,                      "rhs primary",                               0,       0,           0,            0 },
  { G1_META_SINGLE_SYMBOL,                    "single symbol",                             0,       0,           0,            0 },
  { G1_META_SYMBOL,                           "symbol",                                    0,       0,           0,            0 },
  { G1_META_SYMBOL_NAME,                      "symbol name",                               0,       0,           0,            0 },
  { G1_META_ACTION_NAME,                      "action name",                               0,       0,           0,            0 },
  { G1_META_FREE_NAME,                        "free name",                                 0,       0,           0,            0 },
  { G1_META_SYMBOLACTION_NAME,                "symbol action name",                        0,       0,           0,            0 },
  { G1_META_QUANTIFIER,                       "quantifier",                                0,       0,           0,            0 },
  { G1_META_GRAMMAR_REFERENCE,                "grammar reference",                         0,       0,           0,            0 },
  { G1_META_SIGNED_INTEGER,                   "signed integer",                            0,       0,           0,            0 },
  { G1_META_UNSIGNED_INTEGER,                 "unsigned integer",                          0,       0,           0,            0 },
  { G1_META_STRING_LITERAL,                   "string literal",                            0,       0,           0,            0 },
  { G1_META_STRING_LITERAL_UNIT,              "string literal unit",                       0,       0,           0,            0 },
  { G1_META_STRING_LITERAL_INSIDE,            "string literal inside",                     0,       0,           0,            0 },
  { G1_META_STRING_LITERAL_INSIDE_ANY,        "string literal inside any",                 0,       0,           0,            0 },
  { G1_META_DISCARD_OFF,                      "discard off",                               0,       0,           0,            1 },
  { G1_META_DISCARD_ON,                       "discard on",                                0,       0,           1,            0 },
  { G1_META_DISCARD,                          ":discard",                                  0,       1,           0,            0 },
  /* L0 join */
  { G1_META_FALSE,                            L0_JOIN_G1_META_FALSE,                       0,       0,           0,            0 },
  { G1_META_TRUE,                             L0_JOIN_G1_META_TRUE,                        0,       0,           0,            0 },
  { G1_META_STANDARD_NAME,                    L0_JOIN_G1_META_STANDARD_NAME,               0,       0,           0,            0 },
  { G1_META_QUOTED_NAME,                      L0_JOIN_G1_META_QUOTED_NAME,                 0,       0,           0,            0 },
  { G1_META_QUOTED_STRING,                    L0_JOIN_G1_META_QUOTED_STRING,               0,       0,           0,            0 },
  { G1_META_CHARACTER_CLASS,                  L0_JOIN_G1_META_CHARACTER_CLASS,             0,       0,           0,            0 },
  { G1_META_REGULAR_EXPRESSION,               L0_JOIN_G1_META_REGULAR_EXPRESSION,          0,       0,           0,            0 },
  { G1_META_BARE_NAME,                        L0_JOIN_G1_META_BARE_NAME,                   0,       0,           0,            0 },
  { G1_META_BRACKETED_NAME,                   L0_JOIN_G1_META_BRACKETED_NAME,              0,       0,           0,            0 },
  { G1_META_RESTRICTED_ASCII_GRAPH_NAME,      L0_JOIN_G1_META_RESTRICTED_ASCII_GRAPH_NAME, 0,       0,           0,            0 },
  { G1_META_WHITESPACE,                       L0_JOIN_G1_META_WHITESPACE,                  0,       0,           0,            0 },
  { G1_META_PERL_COMMENT,                     L0_JOIN_G1_META_PERL_COMMENT,                0,       0,           0,            0 },
  { G1_META_CPLUSPLUS_COMMENT,                L0_JOIN_G1_META_CPLUSPLUS_COMMENT,           0,       0,           0,            0 }
};

/* Here it is very important that all the string constants are UTF-8 compatible - this is the case */

bootstrap_grammar_terminal_t bootstrap_grammar_G1_terminals[] = {
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  /*                                                             TERMINALS                                                             */
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { G1_TERMINAL__START, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "':start'",
#ifndef MARPAESLIF_NTRACE
    ":start", ":sta",
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL__DESC, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "':desc'",
#ifndef MARPAESLIF_NTRACE
    ":desc", ":de"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_SEMICOLON, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "';'",
#ifndef MARPAESLIF_NTRACE
    ";", ""
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_LEFT_BRACKET, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'{'",
#ifndef MARPAESLIF_NTRACE
    "{", ""
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_RIGHT_BRACKET, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'}'",
#ifndef MARPAESLIF_NTRACE
    "}", ""
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL__DISCARD, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "':discard'",
#ifndef MARPAESLIF_NTRACE
    ":discard", ":dis"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL__DEFAULT, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "':default'",
#ifndef MARPAESLIF_NTRACE
    ":default", ":def"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_DEFAULT, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'default'",
#ifndef MARPAESLIF_NTRACE
    "default", "def"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_EQUAL, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'='",
#ifndef MARPAESLIF_NTRACE
    "=", ""
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL__LEXEME, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "':lexeme'",
#ifndef MARPAESLIF_NTRACE
    ":lexeme", ":lexe"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_EVENT, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'event'",
#ifndef MARPAESLIF_NTRACE
    "event", "eve"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_COMPLETED, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'completed'",
#ifndef MARPAESLIF_NTRACE
    "completed", "comp"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_NULLED, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'nulled'",
#ifndef MARPAESLIF_NTRACE
    "nulled", "nul"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_PREDICTED, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'predicted'",
#ifndef MARPAESLIF_NTRACE
    "predicted", "pre"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_IS, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'is'",
#ifndef MARPAESLIF_NTRACE
    "is", "i"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_INACCESSIBLE, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'inaccessible'",
#ifndef MARPAESLIF_NTRACE
    "inaccessible", "inac"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_BY, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'by'",
#ifndef MARPAESLIF_NTRACE
    "by", "b"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_WARN, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'warn'",
#ifndef MARPAESLIF_NTRACE
    "warn", "wa"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_OK,  MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'ok'",
#ifndef MARPAESLIF_NTRACE
    "ok", "o"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_FATAL, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'fatal'",
#ifndef MARPAESLIF_NTRACE
    "fatal", "fata"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_MINUS, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'-'",
#ifndef MARPAESLIF_NTRACE
    "-", ""
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_ACTION, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'action'",
#ifndef MARPAESLIF_NTRACE
    "action", "act"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_SYMBOL_ACTION, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'symbol-action'",
#ifndef MARPAESLIF_NTRACE
    "symbol-action", "sym"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_FREE_ACTION, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'free-action'",
#ifndef MARPAESLIF_NTRACE
    "free-action", "free-actio"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_THEN, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'=>'",
#ifndef MARPAESLIF_NTRACE
    "=>", "="
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_AUTORANK, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'autorank'",
#ifndef MARPAESLIF_NTRACE
    "autorank", "auto"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_ASSOC, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'assoc'",
#ifndef MARPAESLIF_NTRACE
    "assoc", "asso"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_LEFT, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'left'",
#ifndef MARPAESLIF_NTRACE
    "left", "lef"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_RIGHT, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'right'",
#ifndef MARPAESLIF_NTRACE
    "right", "r"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_GROUP, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'group'",
#ifndef MARPAESLIF_NTRACE
    "group", "gr"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_SEPARATOR, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'separator'",
#ifndef MARPAESLIF_NTRACE
    "separator", "sep"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_PROPER, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'proper'",
#ifndef MARPAESLIF_NTRACE
    "proper", "pro"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_HIDESEPARATOR, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'hide-separator'",
#ifndef MARPAESLIF_NTRACE
    "hide-separator", "hide-"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_RANK, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'rank'",
#ifndef MARPAESLIF_NTRACE
    "rank", "ra"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_NULL_RANKING, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'null-ranking'",
#ifndef MARPAESLIF_NTRACE
    "null-ranking", "null-"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_NULL, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'null'",
#ifndef MARPAESLIF_NTRACE
    "null", "nul"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_LOW, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'low'",
#ifndef MARPAESLIF_NTRACE
    "low", "lo"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_HIGH, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'high'",
#ifndef MARPAESLIF_NTRACE
    "high", "hi"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_PRIORITY, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'priority'",
#ifndef MARPAESLIF_NTRACE
    "priority", "prio"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_PAUSE, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'pause'",
#ifndef MARPAESLIF_NTRACE
    "pause", "pa"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_ON, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'on'",
#ifndef MARPAESLIF_NTRACE
    "on", "o"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_OFF, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'off'",
#ifndef MARPAESLIF_NTRACE
    "off", "of"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_LATM, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'latm'",
#ifndef MARPAESLIF_NTRACE
    "latm", "lat"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_BLESS, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'bless'",
#ifndef MARPAESLIF_NTRACE
    "bless", "bl"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_NAME, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'name'",
#ifndef MARPAESLIF_NTRACE
    "name", "nam"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_COMMA, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "','",
#ifndef MARPAESLIF_NTRACE
    ",", ""
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_LPAREN, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'('",
#ifndef MARPAESLIF_NTRACE
    "(", ""
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_RPAREN, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "')'",
#ifndef MARPAESLIF_NTRACE
    ")", ""
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_STAR, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'*'",
#ifndef MARPAESLIF_NTRACE
    "*", ""
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_PLUS, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'+'",
#ifndef MARPAESLIF_NTRACE
    "+", ""
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL___SHIFT, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'::shift'",
#ifndef MARPAESLIF_NTRACE
    "::shift", "::s"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL___TRANSFER, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'::transfer'",
#ifndef MARPAESLIF_NTRACE
    "::transfer", "::tra"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL___UNDEF, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'::undef'",
#ifndef MARPAESLIF_NTRACE
    "::undef", ":"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL___ASCII, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'::ascii'",
#ifndef MARPAESLIF_NTRACE
    "::ascii", "::asci"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL___CONVERT, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    "::convert\\[[^\\]]+\\]",
#ifndef MARPAESLIF_NTRACE
    "::convert[ASCII//IGNORE//TRANSLIT]", "::convert[UT"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL___CONCAT, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'::concat'",
#ifndef MARPAESLIF_NTRACE
    "::concat", "::c"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL___COPY, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    "::copy\\[\\d+\\]",
#ifndef MARPAESLIF_NTRACE
    "::copy[2]", "::c"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_LEFT_ANGLE, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'<'",
#ifndef MARPAESLIF_NTRACE
    "<", NULL
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_RIGHT_ANGLE, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'>'",
#ifndef MARPAESLIF_NTRACE
    ">", NULL
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_AT_SIGN, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'@'",
#ifndef MARPAESLIF_NTRACE
    "@", NULL
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL__SYMBOL, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "':symbol'",
#ifndef MARPAESLIF_NTRACE
    ":symbol", ":symb"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_BEFORE, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'before'",
#ifndef MARPAESLIF_NTRACE
    "before", "bef"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_AFTER, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'after'",
#ifndef MARPAESLIF_NTRACE
    "after", "afte"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_SIGNED_INTEGER, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    "[+-]?\\d+",
#ifndef MARPAESLIF_NTRACE
    "-10", "+"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_UNSIGNED_INTEGER, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    "\\d+",
    NULL, NULL
  },
  { G1_TERMINAL__DISCARD_ON, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "':discard[on]'",
#ifndef MARPAESLIF_NTRACE
    ":discard[on]", ":dis"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL__DISCARD_OFF, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "':discard[off]'",
#ifndef MARPAESLIF_NTRACE
    ":discard[off]", ":dis"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_STRING_LITERAL_START, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'::u8\"'",
#ifndef MARPAESLIF_NTRACE
    "::u8\"", "::u8"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_STRING_LITERAL_END, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'\"'",
    NULL, NULL
  },
  { G1_TERMINAL_BACKSLASH, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'\\\\'",
    NULL, NULL
  },
  { G1_TERMINAL_STRING_LITERAL_NOT_ESCAPED, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    "[^\"\\\\\\n]",
    NULL, NULL
  },
  { G1_TERMINAL_STRING_LITERAL_ESCAPED_CHAR, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    "[\"'?\\\\abfnrtve]",
    NULL, NULL
  },
  { G1_TERMINAL_STRING_LITERAL_ESCAPED_HEX, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    "x\\{[a-fA-F0-9]{2}\\}",
#ifndef MARPAESLIF_NTRACE
    "x{0a}", "x{0"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_STRING_LITERAL_ESCAPED_CODEPOINT, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    "u\\{[a-fA-F0-9]{4}\\}",
#ifndef MARPAESLIF_NTRACE
    "u{000a}", "u{00"
#else
    NULL, NULL
#endif
  },
  { G1_TERMINAL_STRING_LITERAL_ESCAPED_LARGE_CODEPOINT, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    "U\\{[a-fA-F0-9]{8}\\}",
#ifndef MARPAESLIF_NTRACE
    "U{0000000a}", "U{000000"
#else
    NULL, NULL
#endif
  }
};

/* When bootstrapping we decide for convenience that the description is also the action name */
bootstrap_grammar_rule_t bootstrap_grammar_G1_rules[] = {
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb  hideseparatorb  actions
  */
  { G1_META_STATEMENTS,                       G1_RULE_STATEMENTS,                             MARPAESLIF_RULE_TYPE_SEQUENCE,    1, { G1_META_STATEMENT                            },  0,                        -1,       0,              0, G1_ACTION_STATEMENTS   },
  { G1_META_STATEMENT,                        G1_RULE_STATEMENT_01,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_START_RULE                           }, -1,                        -1,      -1,              0, G1_ACTION_STATEMENT_01 },
  { G1_META_STATEMENT,                        G1_RULE_STATEMENT_02,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_DESC_RULE                            }, -1,                        -1,      -1,              0, G1_ACTION_STATEMENT_02 },
  { G1_META_STATEMENT,                        G1_RULE_STATEMENT_03,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_EMPTY_RULE                           }, -1,                        -1,      -1,              0, G1_ACTION_STATEMENT_03 },
  { G1_META_STATEMENT,                        G1_RULE_STATEMENT_04,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_NULL_STATEMENT                       }, -1,                        -1,      -1,              0, G1_ACTION_STATEMENT_04 },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_STATEMENT,                        G1_RULE_STATEMENT_05,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_STATEMENT_GROUP                      }, -1,                        -1,      -1,              0, G1_ACTION_STATEMENT_05 },
  { G1_META_STATEMENT,                        G1_RULE_STATEMENT_06,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_PRIORITY_RULE                        }, -1,                        -1,      -1,              0, G1_ACTION_STATEMENT_06 },
  { G1_META_STATEMENT,                        G1_RULE_STATEMENT_07,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_QUANTIFIED_RULE                      }, -1,                        -1,      -1,              0, G1_ACTION_STATEMENT_07 },
  { G1_META_STATEMENT,                        G1_RULE_STATEMENT_08,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_DISCARD_RULE                         }, -1,                        -1,      -1,              0, G1_ACTION_STATEMENT_08 },
  { G1_META_STATEMENT,                        G1_RULE_STATEMENT_09,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_DEFAULT_RULE                         }, -1,                        -1,      -1,              0, G1_ACTION_STATEMENT_09 },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_STATEMENT,                        G1_RULE_STATEMENT_12,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_LEXEME_RULE                          }, -1,                        -1,      -1,              0, G1_ACTION_STATEMENT_12 },
  { G1_META_STATEMENT,                        G1_RULE_STATEMENT_13,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_COMPLETION_EVENT_DECLARATION         }, -1,                        -1,      -1,              0, G1_ACTION_STATEMENT_13 },
  { G1_META_STATEMENT,                        G1_RULE_STATEMENT_14,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_NULLED_EVENT_DECLARATION             }, -1,                        -1,      -1,              0, G1_ACTION_STATEMENT_14 },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_STATEMENT,                        G1_RULE_STATEMENT_15,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_PREDICTION_EVENT_DECLARATION         }, -1,                        -1,      -1,              0, G1_ACTION_STATEMENT_15 },
  { G1_META_STATEMENT,                        G1_RULE_STATEMENT_16,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_INACCESSIBLE_STATEMENT               }, -1,                        -1,      -1,              0, G1_ACTION_STATEMENT_16 },
  { G1_META_STATEMENT,                        G1_RULE_STATEMENT_17,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_EXCEPTION_STATEMENT                  }, -1,                        -1,      -1,              0, G1_ACTION_STATEMENT_17 },
  { G1_META_STATEMENT,                        G1_RULE_STATEMENT_18,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_AUTORANK_STATEMENT                   }, -1,                        -1,      -1,              0, G1_ACTION_STATEMENT_18 },
  { G1_META_START_RULE,                       G1_RULE_START_RULE,                             MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL__START,
                                                                                                                                     G1_META_OP_DECLARE,
                                                                                                                                     G1_META_SYMBOL                               }, -1,                        -1,      -1,              0, G1_ACTION_START_RULE },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_DESC_RULE,                        G1_RULE_DESC_RULE,                              MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL__DESC,
                                                                                                                                     G1_META_OP_DECLARE,
                                                                                                                                     G1_META_QUOTED_NAME                          }, -1,                        -1,      -1,              0, G1_ACTION_DESC_RULE },
  { G1_META_EMPTY_RULE,                       G1_RULE_EMPTY_RULE,                             MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_META_LHS,
                                                                                                                                     G1_META_OP_DECLARE,
                                                                                                                                     G1_META_ADVERB_LIST                          }, -1,                        -1,      -1,              0, G1_ACTION_EMPTY_RULE },
  { G1_META_NULL_STATEMENT,                   G1_RULE_NULL_STATEMENT,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL_SEMICOLON                        }, -1,                        -1,      -1,              0, G1_ACTION_NULL_STATEMENT },
  { G1_META_STATEMENT_GROUP,                  G1_RULE_STATEMENT_GROUP,                        MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_LEFT_BRACKET,
                                                                                                                                     G1_META_STATEMENTS,
                                                                                                                                     G1_TERMINAL_RIGHT_BRACKET                    }, -1,                        -1,      -1,              0, G1_ACTION_STATEMENT_GROUP },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_PRIORITY_RULE,                    G1_RULE_PRIORITY_RULE,                          MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_META_LHS,
                                                                                                                                     G1_META_OP_DECLARE,
                                                                                                                                     G1_META_PRIORITIES                           }, -1,                        -1,      -1,              0, G1_ACTION_PRIORITY_RULE },
  { G1_META_QUANTIFIED_RULE,                  G1_RULE_QUANTIFIED_RULE,                        MARPAESLIF_RULE_TYPE_ALTERNATIVE, 5, { G1_META_LHS,
                                                                                                                                     G1_META_OP_DECLARE,
                                                                                                                                     G1_META_RHS_PRIMARY,
                                                                                                                                     G1_META_QUANTIFIER,
                                                                                                                                     G1_META_ADVERB_LIST                          }, -1,                        -1,      -1,              0, G1_ACTION_QUANTIFIED_RULE },
  { G1_META_DISCARD_RULE,                     G1_RULE_DISCARD_RULE,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 4, { G1_TERMINAL__DISCARD,
                                                                                                                                     G1_META_OP_DECLARE,
                                                                                                                                     G1_META_RHS_PRIMARY,
                                                                                                                                     G1_META_ADVERB_LIST                          }, -1,                        -1,      -1,              0, G1_ACTION_DISCARD_RULE },
  { G1_META_DEFAULT_RULE,                     G1_RULE_DEFAULT_RULE,                          MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL__DEFAULT,
                                                                                                                                     G1_META_OP_DECLARE,
                                                                                                                                     G1_META_ADVERB_LIST                          }, -1,                        -1,      -1,              0, G1_ACTION_DEFAULT_RULE },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_LEXEME_RULE,                      G1_RULE_LEXEME_RULE,                            MARPAESLIF_RULE_TYPE_ALTERNATIVE, 4, { G1_TERMINAL__LEXEME,
                                                                                                                                     G1_META_OP_DECLARE,
                                                                                                                                     G1_META_SYMBOL,
                                                                                                                                     G1_META_ADVERB_LIST                          }, -1,                        -1,      -1,              0, G1_ACTION_LEXEME_RULE },
  { G1_META_COMPLETION_EVENT_DECLARATION,     G1_RULE_COMPLETION_EVENT_DECLARATION_1,         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 5, { G1_TERMINAL_EVENT,
                                                                                                                                     G1_META_EVENT_INITIALIZATION,
                                                                                                                                     G1_TERMINAL_EQUAL,
                                                                                                                                     G1_TERMINAL_COMPLETED,
                                                                                                                                     G1_META_SYMBOL_NAME                          }, -1,                        -1,      -1,              0, G1_ACTION_COMPLETION_EVENT_DECLARATION_1 },
  { G1_META_COMPLETION_EVENT_DECLARATION,     G1_RULE_COMPLETION_EVENT_DECLARATION_2,         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 5, { G1_TERMINAL_EVENT,
                                                                                                                                     G1_META_EVENT_INITIALIZATION,
                                                                                                                                     G1_META_OP_DECLARE,
                                                                                                                                     G1_TERMINAL_COMPLETED,
                                                                                                                                     G1_META_SYMBOL_NAME                          }, -1,                        -1,      -1,              0, G1_ACTION_COMPLETION_EVENT_DECLARATION_2 },
  { G1_META_NULLED_EVENT_DECLARATION,         G1_RULE_NULLED_EVENT_DECLARATION_1,             MARPAESLIF_RULE_TYPE_ALTERNATIVE, 5, { G1_TERMINAL_EVENT,
                                                                                                                                     G1_META_EVENT_INITIALIZATION,
                                                                                                                                     G1_TERMINAL_EQUAL,
                                                                                                                                     G1_TERMINAL_NULLED,
                                                                                                                                     G1_META_SYMBOL_NAME                          }, -1,                        -1,      -1,              0, G1_ACTION_NULLED_EVENT_DECLARATION_1 },
  { G1_META_NULLED_EVENT_DECLARATION,         G1_RULE_NULLED_EVENT_DECLARATION_1,             MARPAESLIF_RULE_TYPE_ALTERNATIVE, 5, { G1_TERMINAL_EVENT,
                                                                                                                                     G1_META_EVENT_INITIALIZATION,
                                                                                                                                     G1_META_OP_DECLARE,
                                                                                                                                     G1_TERMINAL_NULLED,
                                                                                                                                     G1_META_SYMBOL_NAME                          }, -1,                        -1,      -1,              0, G1_ACTION_NULLED_EVENT_DECLARATION_1 },
  { G1_META_PREDICTION_EVENT_DECLARATION,     G1_RULE_PREDICTED_EVENT_DECLARATION_1,          MARPAESLIF_RULE_TYPE_ALTERNATIVE, 5, { G1_TERMINAL_EVENT,
                                                                                                                                     G1_META_EVENT_INITIALIZATION,
                                                                                                                                     G1_TERMINAL_EQUAL,
                                                                                                                                     G1_TERMINAL_PREDICTED,
                                                                                                                                     G1_META_SYMBOL_NAME                          }, -1,                        -1,      -1,              0, G1_ACTION_PREDICTED_EVENT_DECLARATION_1 },
  { G1_META_PREDICTION_EVENT_DECLARATION,     G1_RULE_PREDICTED_EVENT_DECLARATION_2,          MARPAESLIF_RULE_TYPE_ALTERNATIVE, 5, { G1_TERMINAL_EVENT,
                                                                                                                                     G1_META_EVENT_INITIALIZATION,
                                                                                                                                     G1_META_OP_DECLARE,
                                                                                                                                     G1_TERMINAL_PREDICTED,
                                                                                                                                     G1_META_SYMBOL_NAME                          }, -1,                        -1,      -1,              0, G1_ACTION_PREDICTED_EVENT_DECLARATION_2 },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_INACCESSIBLE_STATEMENT,           G1_RULE_INACCESSIBLE_STATEMENT,                 MARPAESLIF_RULE_TYPE_ALTERNATIVE, 5, { G1_TERMINAL_INACCESSIBLE,
                                                                                                                                     G1_TERMINAL_IS,
                                                                                                                                     G1_META_INACCESSIBLE_TREATMENT,
                                                                                                                                     G1_TERMINAL_BY,
                                                                                                                                     G1_TERMINAL_DEFAULT                          }, -1,                        -1,      -1,              0, G1_ACTION_INACCESSIBLE_STATEMENT },
  { G1_META_INACCESSIBLE_TREATMENT,           G1_RULE_INACCESSIBLE_TREATMENT_1,               MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL_WARN                             }, -1,                        -1,      -1,              0, G1_ACTION_INACCESSIBLE_TREATMENT_1 },
  { G1_META_INACCESSIBLE_TREATMENT,           G1_RULE_INACCESSIBLE_TREATMENT_2,               MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL_OK                               }, -1,                        -1,      -1,              0, G1_ACTION_INACCESSIBLE_TREATMENT_2 },
  { G1_META_INACCESSIBLE_TREATMENT,           G1_RULE_INACCESSIBLE_TREATMENT_3,               MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL_FATAL                            }, -1,                        -1,      -1,              0, G1_ACTION_INACCESSIBLE_TREATMENT_3 },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_EXCEPTION_STATEMENT,              G1_RULE_EXCEPTION_STATEMENT,                    MARPAESLIF_RULE_TYPE_ALTERNATIVE, 6, { G1_META_LHS,
                                                                                                                                     G1_META_OP_DECLARE,
                                                                                                                                     G1_META_RHS_PRIMARY,
                                                                                                                                     G1_TERMINAL_MINUS,
                                                                                                                                     G1_META_RHS_PRIMARY,
                                                                                                                                     G1_META_ADVERB_LIST                          }, -1,                        -1,      -1,              0, G1_ACTION_EXCEPTION_STATEMENT },
  { G1_META_AUTORANK_STATEMENT,               G1_RULE_AUTORANK_STATEMENT,                     MARPAESLIF_RULE_TYPE_ALTERNATIVE, 5, { G1_TERMINAL_AUTORANK,
                                                                                                                                     G1_TERMINAL_IS,
                                                                                                                                     G1_META_ON_OR_OFF,
                                                                                                                                     G1_TERMINAL_BY,
                                                                                                                                     G1_TERMINAL_DEFAULT                          }, -1,                        -1,      -1,              0, G1_ACTION_AUTORANK_STATEMENT },
  { G1_META_OP_DECLARE,                       G1_RULE_OP_DECLARE_1,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_OP_DECLARE_TOP_GRAMMAR               }, -1,                        -1,      -1,              0, G1_ACTION_OP_DECLARE_1 },
  { G1_META_OP_DECLARE,                       G1_RULE_OP_DECLARE_2,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_OP_DECLARE_LEX_GRAMMAR               }, -1,                        -1,      -1,              0, G1_ACTION_OP_DECLARE_2 },
  { G1_META_OP_DECLARE,                       G1_RULE_OP_DECLARE_3,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_OP_DECLARE_ANY_GRAMMAR               }, -1,                        -1,      -1,              0, G1_ACTION_OP_DECLARE_3 },
  { G1_META_PRIORITIES,                       G1_RULE_PRIORITIES,                             MARPAESLIF_RULE_TYPE_SEQUENCE,    1, { G1_META_ALTERNATIVES                         },  1,         G1_META_OP_LOOSEN,       1,              1, G1_ACTION_PRIORITIES },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_ALTERNATIVES,                     G1_RULE_ALTERNATIVES,                           MARPAESLIF_RULE_TYPE_SEQUENCE,    1, { G1_META_ALTERNATIVE                          },  1, G1_META_OP_EQUAL_PRIORITY,       1,              1, G1_ACTION_ALTERNATIVES },
  { G1_META_ALTERNATIVE,                      G1_RULE_ALTERNATIVE,                            MARPAESLIF_RULE_TYPE_ALTERNATIVE, 2, { G1_META_RHS,
                                                                                                                                     G1_META_ADVERB_LIST                          }, -1,                        -1,      -1,              0, G1_ACTION_ALTERNATIVE },
  { G1_META_ADVERB_LIST,                      G1_RULE_ADVERB_LIST,                            MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_ADVERB_LIST_ITEMS                    }, -1,                        -1,      -1,              0, G1_ACTION_ADVERB_LIST },
  { G1_META_ADVERB_LIST_ITEMS,                G1_RULE_ADVERB_LIST_ITEMS,                      MARPAESLIF_RULE_TYPE_SEQUENCE,    1, { G1_META_ADVERB_ITEM                          },  0,                        -1,       0,              0, G1_ACTION_ADVERB_LIST_ITEMS },
  { G1_META_ADVERB_ITEM,                      G1_RULE_ADVERB_ITEM_01,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_ACTION                               }, -1,                        -1,      -1,              0, G1_ACTION_ADVERB_ITEM_01 },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_ADVERB_ITEM,                      G1_RULE_ADVERB_ITEM_02,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_LEFT_ASSOCIATION                     }, -1,                        -1,      -1,              0, G1_ACTION_ADVERB_ITEM_03 },
  { G1_META_ADVERB_ITEM,                      G1_RULE_ADVERB_ITEM_03,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_RIGHT_ASSOCIATION                    }, -1,                        -1,      -1,              0, G1_ACTION_ADVERB_ITEM_04 },
  { G1_META_ADVERB_ITEM,                      G1_RULE_ADVERB_ITEM_04,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_GROUP_ASSOCIATION                    }, -1,                        -1,      -1,              0, G1_ACTION_ADVERB_ITEM_05 },
  { G1_META_ADVERB_ITEM,                      G1_RULE_ADVERB_ITEM_05,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_SEPARATOR_SPECIFICATION              }, -1,                        -1,      -1,              0, G1_ACTION_ADVERB_ITEM_06 },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_ADVERB_ITEM,                      G1_RULE_ADVERB_ITEM_06,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_PROPER_SPECIFICATION                 }, -1,                        -1,      -1,              0, G1_ACTION_ADVERB_ITEM_07 },
  { G1_META_ADVERB_ITEM,                      G1_RULE_ADVERB_ITEM_07,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_RANK_SPECIFICATION                   }, -1,                        -1,      -1,              0, G1_ACTION_ADVERB_ITEM_08 },
  { G1_META_ADVERB_ITEM,                      G1_RULE_ADVERB_ITEM_08,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_NULL_RANKING_SPECIFICATION           }, -1,                        -1,      -1,              0, G1_ACTION_ADVERB_ITEM_09 },
  { G1_META_ADVERB_ITEM,                      G1_RULE_ADVERB_ITEM_09,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_PRIORITY_SPECIFICATION               }, -1,                        -1,      -1,              0, G1_ACTION_ADVERB_ITEM_10 },
  { G1_META_ADVERB_ITEM,                      G1_RULE_ADVERB_ITEM_10,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_PAUSE_SPECIFICATION                  }, -1,                        -1,      -1,              0, G1_ACTION_ADVERB_ITEM_11 },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_ADVERB_ITEM,                      G1_RULE_ADVERB_ITEM_11,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_LATM_SPECIFICATION                   }, -1,                        -1,      -1,              0, G1_ACTION_ADVERB_ITEM_12 },
  { G1_META_ADVERB_ITEM,                      G1_RULE_ADVERB_ITEM_12,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_NAMING                               }, -1,                        -1,      -1,              0, G1_ACTION_ADVERB_ITEM_13 },
  { G1_META_ADVERB_ITEM,                      G1_RULE_ADVERB_ITEM_13,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_NULL_ADVERB                          }, -1,                        -1,      -1,              0, G1_ACTION_ADVERB_ITEM_13 },
  { G1_META_ADVERB_ITEM,                      G1_RULE_ADVERB_ITEM_14,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_SYMBOL_ACTION                        }, -1,                        -1,      -1,              0, G1_ACTION_ADVERB_ITEM_14 },
  { G1_META_ADVERB_ITEM,                      G1_RULE_ADVERB_ITEM_15,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_FREE_ACTION                          }, -1,                        -1,      -1,              0, G1_ACTION_ADVERB_ITEM_15 },
  { G1_META_ADVERB_ITEM,                      G1_RULE_ADVERB_ITEM_16,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_EVENT_SPECIFICATION                  }, -1,                        -1,      -1,              0, G1_ACTION_ADVERB_ITEM_16 },
  { G1_META_ADVERB_ITEM,                      G1_RULE_ADVERB_ITEM_17,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_HIDESEPARATOR_SPECIFICATION          }, -1,                        -1,      -1,              0, G1_ACTION_ADVERB_ITEM_17 },
  { G1_META_ACTION,                           G1_RULE_ACTION_1,                               MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_ACTION,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_META_ACTION_NAME                          }, -1,                        -1,      -1,              0, G1_ACTION_ACTION_1 },
  { G1_META_ACTION,                           G1_RULE_ACTION_2,                               MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_ACTION,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_META_STRING_LITERAL                       }, -1,                        -1,      -1,              0, G1_ACTION_ACTION_2 },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_LEFT_ASSOCIATION,                 G1_RULE_LEFT_ASSOCIATION,                       MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_ASSOC,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_TERMINAL_LEFT                             }, -1,                        -1,      -1,              0, G1_ACTION_LEFT_ASSOCIATION },
  { G1_META_RIGHT_ASSOCIATION,                G1_RULE_RIGHT_ASSOCIATION,                      MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_ASSOC,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_TERMINAL_RIGHT                            }, -1,                        -1,      -1,              0, G1_ACTION_RIGHT_ASSOCIATION },
  { G1_META_GROUP_ASSOCIATION,                G1_RULE_GROUP_ASSOCIATION,                      MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_ASSOC,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_TERMINAL_GROUP                            }, -1,                        -1,      -1,              0, G1_ACTION_GROUP_ASSOCIATION },
  { G1_META_SEPARATOR_SPECIFICATION,          G1_RULE_SEPARATOR_SPECIFICATION,                MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_SEPARATOR,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_META_SINGLE_SYMBOL                        }, -1,                        -1,      -1,              0, G1_ACTION_SEPARATOR_SPECIFICATION },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_PROPER_SPECIFICATION,             G1_RULE_PROPER_SPECIFICATION_1,                 MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_PROPER,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_META_FALSE                                }, -1,                        -1,      -1,              0, G1_ACTION_PROPER_SPECIFICATION_1 },
  { G1_META_PROPER_SPECIFICATION,             G1_RULE_PROPER_SPECIFICATION_2,                 MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_PROPER,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_META_TRUE                                 }, -1,                        -1,      -1,              0, G1_ACTION_PROPER_SPECIFICATION_2 },
  { G1_META_HIDESEPARATOR_SPECIFICATION,      G1_RULE_HIDESEPARATOR_SPECIFICATION_1,          MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_HIDESEPARATOR,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_META_FALSE                                }, -1,                        -1,      -1,              0, G1_ACTION_HIDESEPARATOR_SPECIFICATION_1 },
  { G1_META_HIDESEPARATOR_SPECIFICATION,      G1_RULE_HIDESEPARATOR_SPECIFICATION_2,          MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_HIDESEPARATOR,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_META_TRUE                                 }, -1,                        -1,      -1,              0, G1_ACTION_HIDESEPARATOR_SPECIFICATION_2 },
  { G1_META_RANK_SPECIFICATION,               G1_RULE_RANK_SPECIFICATION,                     MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_RANK,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_META_SIGNED_INTEGER                       }, -1,                        -1,      -1,              0, G1_ACTION_RANK_SPECIFICATION },
  { G1_META_NULL_RANKING_SPECIFICATION,       G1_RULE_NULL_RANKING_SPECIFICATION_1,           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_NULL_RANKING,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_META_NULL_RANKING_CONSTANT                }, -1,                        -1,      -1,              0, G1_ACTION_NULL_RANKING_SPECIFICATION_1 },
  { G1_META_NULL_RANKING_SPECIFICATION,       G1_RULE_NULL_RANKING_SPECIFICATION_2,           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 4, { G1_TERMINAL_NULL,
                                                                                                                                     G1_TERMINAL_RANK,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_META_NULL_RANKING_CONSTANT                }, -1,                        -1,      -1,              0, G1_ACTION_NULL_RANKING_SPECIFICATION_2 },
  { G1_META_NULL_RANKING_CONSTANT,            G1_RULE_NULL_RANKING_CONSTANT_1,                MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL_LOW                              }, -1,                        -1,      -1,              0, G1_ACTION_NULL_RANKING_CONSTANT_1 },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_NULL_RANKING_CONSTANT,            G1_RULE_NULL_RANKING_CONSTANT_2,                MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL_HIGH                             }, -1,                        -1,      -1,              0, G1_ACTION_NULL_RANKING_CONSTANT_2 },
  { G1_META_PRIORITY_SPECIFICATION,           G1_RULE_PRIORITY_SPECIFICATION,                 MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_PRIORITY,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_META_SIGNED_INTEGER                       }, -1,                        -1,      -1,              0, G1_ACTION_PRIORITY_SPECIFICATION },
  { G1_META_PAUSE_SPECIFICATION,              G1_RULE_PAUSE_SPECIFICATION_1,                  MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_PAUSE,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_TERMINAL_BEFORE                           }, -1,                        -1,      -1,              0, G1_ACTION_PAUSE_SPECIFICATION_1 },
  { G1_META_PAUSE_SPECIFICATION,              G1_RULE_PAUSE_SPECIFICATION_2,                  MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_PAUSE,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_TERMINAL_AFTER                            }, -1,                        -1,      -1,              0, G1_ACTION_PAUSE_SPECIFICATION_2 },
  { G1_META_EVENT_SPECIFICATION,              G1_RULE_EVENT_SPECIFICATION,                    MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_EVENT,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_META_EVENT_INITIALIZATION                 }, -1,                        -1,      -1,              0, G1_ACTION_EVENT_SPECIFICATION },
  { G1_META_EVENT_INITIALIZATION,             G1_RULE_EVENT_INITIALIZATION,                   MARPAESLIF_RULE_TYPE_ALTERNATIVE, 2, { G1_META_EVENT_NAME,
                                                                                                                                     G1_META_EVENT_INITIALIZER                    }, -1,                        -1,      -1,              0, G1_ACTION_EVENT_INITIALIZATION },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_EVENT_INITIALIZER,                G1_RULE_EVENT_INITIALIZER_1,                    MARPAESLIF_RULE_TYPE_ALTERNATIVE, 2, { G1_TERMINAL_EQUAL,
                                                                                                                                     G1_META_ON_OR_OFF                            }, -1,                        -1,      -1,              0, G1_ACTION_EVENT_INITIALIZER_1 },
  { G1_META_ON_OR_OFF,                        G1_RULE_ON_OR_OFF_1,                            MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL_ON                               }, -1,                        -1,      -1,              0, G1_ACTION_ON_OR_OFF_1 },
  { G1_META_ON_OR_OFF,                        G1_RULE_ON_OR_OFF_2,                            MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL_OFF                              }, -1,                        -1,      -1,              0, G1_ACTION_ON_OR_OFF_2 },
  { G1_META_EVENT_INITIALIZER,                G1_RULE_EVENT_INITIALIZER_2,                    MARPAESLIF_RULE_TYPE_ALTERNATIVE, 0, { -1                                           }, -1,                        -1,      -1,              0, G1_ACTION_EVENT_INITIALIZER_2 },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_LATM_SPECIFICATION,               G1_RULE_LATM_SPECIFICATION_1,                   MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_LATM,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_META_FALSE                                }, -1,                        -1,      -1,              0, G1_ACTION_LATM_SPECIFICATION_1 },
  { G1_META_LATM_SPECIFICATION,               G1_RULE_LATM_SPECIFICATION_2,                   MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_LATM,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_META_TRUE                                 }, -1,                        -1,      -1,              0, G1_ACTION_LATM_SPECIFICATION_2 },
  { G1_META_NAMING,                           G1_RULE_NAMING,                                 MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_NAME,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_META_ALTERNATIVE_NAME                     }, -1,                        -1,      -1,              0, G1_ACTION_NAMING },
  { G1_META_NULL_ADVERB,                      G1_RULE_NULL_ADVERB,                            MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL_COMMA                            }, -1,                        -1,      -1,              0, G1_ACTION_NULL_ADVERB },
  { G1_META_SYMBOL_ACTION,                    G1_RULE_SYMBOL_ACTION_1,                        MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_SYMBOL_ACTION,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_META_SYMBOLACTION_NAME                    }, -1,                        -1,      -1,              0, G1_ACTION_SYMBOLACTION_1 },
  { G1_META_SYMBOL_ACTION,                    G1_RULE_SYMBOL_ACTION_2,                        MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_SYMBOL_ACTION,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_META_STRING_LITERAL                       }, -1,                        -1,      -1,              0, G1_ACTION_SYMBOLACTION_2 },
  { G1_META_FREE_ACTION,                      G1_RULE_FREE_ACTION,                            MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_TERMINAL_FREE_ACTION,
                                                                                                                                     G1_TERMINAL_THEN,
                                                                                                                                     G1_META_FREE_NAME                            }, -1,                        -1,      -1,              0, G1_ACTION_FREEACTION },
  { G1_META_ALTERNATIVE_NAME,                 G1_RULE_ALTERNATIVE_NAME_1,                     MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_STANDARD_NAME                        }, -1,                        -1,      -1,              0, G1_ACTION_ALTERNATIVE_NAME_1 },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_ALTERNATIVE_NAME,                 G1_RULE_ALTERNATIVE_NAME_2,                     MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_QUOTED_NAME                          }, -1,                        -1,      -1,              0, G1_ACTION_ALTERNATIVE_NAME_2 },
  { G1_META_EVENT_NAME,                       G1_RULE_EVENT_NAME_1,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_RESTRICTED_ASCII_GRAPH_NAME          }, -1,                        -1,      -1,              0, G1_ACTION_EVENT_NAME_1 },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_EVENT_NAME,                       G1_RULE_EVENT_NAME_2,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL__SYMBOL                          }, -1,                        -1,      -1,              0, G1_ACTION_EVENT_NAME_2 },
  { G1_META_EVENT_NAME,                       G1_RULE_EVENT_NAME_3,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL__DISCARD_ON                      }, -1,                        -1,      -1,              0, G1_ACTION_EVENT_NAME_3 },
  { G1_META_EVENT_NAME,                       G1_RULE_EVENT_NAME_4,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL__DISCARD_OFF                     }, -1,                        -1,      -1,              0, G1_ACTION_EVENT_NAME_4 },
  { G1_META_LHS,                              G1_RULE_LHS,                                    MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_SYMBOL_NAME                          }, -1,                        -1,      -1,              0, G1_ACTION_LHS },
  { G1_META_RHS,                              G1_RULE_RHS,                                    MARPAESLIF_RULE_TYPE_SEQUENCE,    1, { G1_META_RHS_PRIMARY                          },  1,                        -1,       0,              0, G1_ACTION_RHS },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_RHS_PRIMARY,                      G1_RULE_RHS_PRIMARY_1,                          MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_SINGLE_SYMBOL                        }, -1,                        -1,      -1,              0, G1_ACTION_RHS_PRIMARY_1 },
  { G1_META_RHS_PRIMARY,                      G1_RULE_RHS_PRIMARY_2,                          MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { G1_META_SYMBOL_NAME,
                                                                                                                                     G1_TERMINAL_AT_SIGN,
                                                                                                                                     G1_META_GRAMMAR_REFERENCE                    }, -1,                        -1,      -1,              0, G1_ACTION_RHS_PRIMARY_2 },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_SINGLE_SYMBOL,                    G1_RULE_SINGLE_SYMBOL_1,                        MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_SYMBOL                               }, -1,                        -1,      -1,              0, G1_ACTION_SINGLE_SYMBOL_1 },
  { G1_META_SINGLE_SYMBOL,                    G1_RULE_SINGLE_SYMBOL_2,                        MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_CHARACTER_CLASS                      }, -1,                        -1,      -1,              0, G1_ACTION_SINGLE_SYMBOL_2 },
  { G1_META_SINGLE_SYMBOL,                    G1_RULE_SINGLE_SYMBOL_3,                        MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_REGULAR_EXPRESSION                   }, -1,                        -1,      -1,              0, G1_ACTION_SINGLE_SYMBOL_3 },
  { G1_META_SINGLE_SYMBOL,                    G1_RULE_SINGLE_SYMBOL_4,                        MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_QUOTED_STRING                        }, -1,                        -1,      -1,              0, G1_ACTION_SINGLE_SYMBOL_4 },
  { G1_META_SYMBOL,                           G1_RULE_SYMBOL,                                 MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_SYMBOL_NAME                          }, -1,                        -1,      -1,              0, G1_ACTION_SYMBOL },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_SYMBOL_NAME,                      G1_RULE_SYMBOL_NAME_1,                          MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_BARE_NAME                            }, -1,                        -1,      -1,              0, G1_ACTION_SYMBOL_NAME_1 },
  { G1_META_SYMBOL_NAME,                      G1_RULE_SYMBOL_NAME_2,                          MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_BRACKETED_NAME                       }, -1,                        -1,      -1,              0, G1_ACTION_SYMBOL_NAME_2 },
  { G1_META_ACTION_NAME,                      G1_RULE_ACTION_NAME_1,                          MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_RESTRICTED_ASCII_GRAPH_NAME          }, -1,                        -1,      -1,              0, G1_ACTION_ACTION_NAME_1 },
  { G1_META_ACTION_NAME,                      G1_RULE_ACTION_NAME_2,                          MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL___SHIFT                          }, -1,                        -1,      -1,              0, G1_ACTION_ACTION_NAME_2 },
  { G1_META_ACTION_NAME,                      G1_RULE_ACTION_NAME_3,                          MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL___UNDEF                          }, -1,                        -1,      -1,              0, G1_ACTION_ACTION_NAME_3 },
  { G1_META_ACTION_NAME,                      G1_RULE_ACTION_NAME_4,                          MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL___ASCII                          }, -1,                        -1,      -1,              0, G1_ACTION_ACTION_NAME_4 },
  { G1_META_ACTION_NAME,                      G1_RULE_ACTION_NAME_5,                          MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL___CONVERT                        }, -1,                        -1,      -1,              0, G1_ACTION_ACTION_NAME_5 },
  { G1_META_ACTION_NAME,                      G1_RULE_ACTION_NAME_6,                          MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL___CONCAT                         }, -1,                        -1,      -1,              0, G1_ACTION_ACTION_NAME_6 },
  { G1_META_ACTION_NAME,                      G1_RULE_ACTION_NAME_7,                          MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL___COPY                           }, -1,                        -1,      -1,              0, G1_ACTION_ACTION_NAME_7 },
  { G1_META_FREE_NAME,                        G1_RULE_ACTION_FREE_NAME,                       MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_RESTRICTED_ASCII_GRAPH_NAME          }, -1,                        -1,      -1,              0, G1_ACTION_FREE_NAME },
  { G1_META_SYMBOLACTION_NAME,                G1_RULE_SYMBOLACTION_NAME_1,                    MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_RESTRICTED_ASCII_GRAPH_NAME          }, -1,                        -1,      -1,              0, G1_ACTION_SYMBOLACTION_NAME_1 },
  { G1_META_SYMBOLACTION_NAME,                G1_RULE_SYMBOLACTION_NAME_2,                    MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL___TRANSFER                       }, -1,                        -1,      -1,              0, G1_ACTION_SYMBOLACTION_NAME_2 },
  { G1_META_SYMBOLACTION_NAME,                G1_RULE_SYMBOLACTION_NAME_3,                    MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL___UNDEF                          }, -1,                        -1,      -1,              0, G1_ACTION_SYMBOLACTION_NAME_3 },
  { G1_META_SYMBOLACTION_NAME,                G1_RULE_SYMBOLACTION_NAME_4,                    MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL___ASCII                          }, -1,                        -1,      -1,              0, G1_ACTION_SYMBOLACTION_NAME_4 },
  { G1_META_SYMBOLACTION_NAME,                G1_RULE_SYMBOLACTION_NAME_5,                    MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL___CONVERT                        }, -1,                        -1,      -1,              0, G1_ACTION_SYMBOLACTION_NAME_5 },
  { G1_META_SYMBOLACTION_NAME,                G1_RULE_SYMBOLACTION_NAME_6,                    MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL___CONCAT                         }, -1,                        -1,      -1,              0, G1_ACTION_SYMBOLACTION_NAME_6 },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_QUANTIFIER,                       G1_RULE_QUANTIFIER_1,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL_STAR                             }, -1,                        -1,      -1,              0, G1_ACTION_QUANTIFIER_1 },
  { G1_META_QUANTIFIER,                       G1_RULE_QUANTIFIER_2,                           MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL_PLUS                             }, -1,                        -1,      -1,              0, G1_ACTION_QUANTIFIER_2 },
  { G1_META_SIGNED_INTEGER,                   G1_RULE_SIGNED_INTEGER,                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL_SIGNED_INTEGER                   }, -1,                        -1,      -1,              0, G1_ACTION_SIGNED_INTEGER },
  { G1_META_UNSIGNED_INTEGER,                 G1_RULE_UNSIGNED_INTEGER,                       MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL_UNSIGNED_INTEGER                 }, -1,                        -1,      -1,              0, G1_ACTION_UNSIGNED_INTEGER },
  { G1_META_GRAMMAR_REFERENCE,                G1_RULE_GRAMMAR_REFERENCE_1,                    MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_QUOTED_STRING                        }, -1,                        -1,      -1,              0, G1_ACTION_GRAMMAR_REFERENCE_1 },
  { G1_META_GRAMMAR_REFERENCE,                G1_RULE_GRAMMAR_REFERENCE_2,                    MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_SIGNED_INTEGER                       }, -1,                        -1,      -1,              0, G1_ACTION_GRAMMAR_REFERENCE_2 },
  { G1_META_GRAMMAR_REFERENCE,                G1_RULE_GRAMMAR_REFERENCE_3,                    MARPAESLIF_RULE_TYPE_ALTERNATIVE, 2, { G1_TERMINAL_EQUAL,
                                                                                                                                     G1_META_UNSIGNED_INTEGER                     }, -1,                        -1,      -1,              0, G1_ACTION_GRAMMAR_REFERENCE_3 },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_DISCARD,                          G1_RULE_DISCARD_1,                              MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_WHITESPACE                           }, -1,                        -1,      -1,              0, NULL },
  { G1_META_DISCARD,                          G1_RULE_DISCARD_2,                              MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_PERL_COMMENT                         }, -1,                        -1,      -1,              0, NULL },
  { G1_META_DISCARD,                          G1_RULE_DISCARD_3,                              MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_META_CPLUSPLUS_COMMENT                    }, -1,                        -1,      -1,              0, NULL },

  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_STRING_LITERAL,                   G1_RULE_STRING_LITERAL,                         MARPAESLIF_RULE_TYPE_SEQUENCE,    1, { G1_META_STRING_LITERAL_UNIT                  },  1,                        -1,      -1,              0, G1_ACTION_STRING_LITERAL },
  { G1_META_STRING_LITERAL_UNIT,              G1_RULE_STRING_LITERAL_UNIT,                    MARPAESLIF_RULE_TYPE_ALTERNATIVE, 5, { G1_TERMINAL_STRING_LITERAL_START,
                                                                                                                                     G1_META_DISCARD_OFF,
                                                                                                                                     G1_META_STRING_LITERAL_INSIDE_ANY,
                                                                                                                                     G1_TERMINAL_STRING_LITERAL_END,
                                                                                                                                     G1_META_DISCARD_ON                           }, -1,                        -1,      -1,              0, G1_ACTION_STRING_LITERAL_UNIT },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_DISCARD_OFF,                      G1_RULE_DISCARD_OFF,                            MARPAESLIF_RULE_TYPE_ALTERNATIVE, 0, { -1                                           }, -1,                        -1,      -1,              0, G1_ACTION_DISCARD_OFF },
  { G1_META_DISCARD_ON,                       G1_RULE_DISCARD_ON,                             MARPAESLIF_RULE_TYPE_ALTERNATIVE, 0, { -1                                           }, -1,                        -1,      -1,              0, G1_ACTION_DISCARD_ON },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { G1_META_STRING_LITERAL_INSIDE_ANY,        G1_RULE_STRING_LITERAL_INSIDE_ANY,              MARPAESLIF_RULE_TYPE_SEQUENCE,    1, { G1_META_STRING_LITERAL_INSIDE                },  0,                        -1,      -1,              0, G1_ACTION_STRING_LITERAL_INSIDE_ANY },
  { G1_META_STRING_LITERAL_INSIDE,            G1_RULE_STRING_LITERAL_INSIDE_1,                MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { G1_TERMINAL_STRING_LITERAL_NOT_ESCAPED       }, -1,                        -1,      -1,              0, G1_ACTION_STRING_LITERAL_INSIDE_1 },
  { G1_META_STRING_LITERAL_INSIDE,            G1_RULE_STRING_LITERAL_INSIDE_2,                MARPAESLIF_RULE_TYPE_ALTERNATIVE, 2, { G1_TERMINAL_BACKSLASH,
                                                                                                                                     G1_TERMINAL_STRING_LITERAL_ESCAPED_CHAR      }, -1,                        -1,      -1,              0, G1_ACTION_STRING_LITERAL_INSIDE_2 },
  { G1_META_STRING_LITERAL_INSIDE,            G1_RULE_STRING_LITERAL_INSIDE_3,                MARPAESLIF_RULE_TYPE_ALTERNATIVE, 2, { G1_TERMINAL_BACKSLASH,
                                                                                                                                     G1_TERMINAL_STRING_LITERAL_ESCAPED_HEX       }, -1,                        -1,      -1,              0, G1_ACTION_STRING_LITERAL_INSIDE_3 },
  { G1_META_STRING_LITERAL_INSIDE,            G1_RULE_STRING_LITERAL_INSIDE_4,                MARPAESLIF_RULE_TYPE_ALTERNATIVE, 2, { G1_TERMINAL_BACKSLASH,
                                                                                                                                     G1_TERMINAL_STRING_LITERAL_ESCAPED_CODEPOINT }, -1,                        -1,      -1,              0, G1_ACTION_STRING_LITERAL_INSIDE_4 },
  { G1_META_STRING_LITERAL_INSIDE,            G1_RULE_STRING_LITERAL_INSIDE_4,                MARPAESLIF_RULE_TYPE_ALTERNATIVE, 2, { G1_TERMINAL_BACKSLASH,
                                                                                                                                     G1_TERMINAL_STRING_LITERAL_ESCAPED_LARGE_CODEPOINT }, -1,                  -1,      -1,              0, G1_ACTION_STRING_LITERAL_INSIDE_5 }
};

#endif /* MARPAESLIF_INTERNAL_ESLIF_G1_H */
