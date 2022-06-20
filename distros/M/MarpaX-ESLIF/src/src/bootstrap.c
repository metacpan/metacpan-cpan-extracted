#include "marpaESLIF/internal/bootstrap.h"

#undef  FILENAMES
#define FILENAMES "bootstrap.c" /* For logging */

/* For fake and internal terminals, avoid an unnecessary call to ASCII conversion of the content */
static const char  *_marpaESLIF_bootstrap_descEncodingInternals = "ASCII";
static const char  *_marpaESLIF_bootstrap_descInternals = "INTERNAL";
static const size_t _marpaESLIF_bootstrap_descInternall = 8; /* strlen("INTERNAL") */
static const char  *_marpaESLIF_bootstrap_lua_return_function_lparens = "return function(";

/* For ::lua-> action prefix */
static const char *LUA_ACTION_PREFIX = "::lua->";

/* This file contain the definition of all bootstrap actions, i.e. the ESLIF grammar itself */
/* This is an example of how to use the API */

static inline void _marpaESLIF_bootstrap_rhs_primary_freev(marpaESLIF_bootstrap_rhs_primary_t *rhsPrimaryp);
static inline void _marpaESLIF_bootstrap_lhs_freev(marpaESLIF_bootstrap_lhs_t *lhsp);
static inline void _marpaESLIF_bootstrap_start_symbol_freev(marpaESLIF_bootstrap_start_symbol_t *startSymbolp);
static inline void _marpaESLIF_bootstrap_lua_function_freev(marpaESLIF_bootstrap_lua_function_t *luaFunctionp);
static inline void _marpaESLIF_bootstrap_rhs_alternative_freev(marpaESLIF_bootstrap_rhs_alternative_t *rhsAlternativep);
static inline void _marpaESLIF_bootstrap_symbol_and_reference_freev(marpaESLIF_bootstrap_symbol_and_reference_t *symbolAndReferencep);
static inline void _marpaESLIF_bootstrap_utf_string_freev(marpaESLIF_bootstrap_utf_string_t *stringp, short onStackb);
static inline marpaESLIF_bootstrap_utf_string_t *_marpaESLIF_bootstrap_utf_string_newp(marpaESLIF_t *marpaESLIFp);
static inline void _marpaESLIF_bootstrap_rhs_freev(genericStack_t *rhsAlternativeStackp);
static inline void _marpaESLIF_bootstrap_adverb_list_item_freev(marpaESLIF_bootstrap_adverb_list_item_t *adverbListItemp);
static inline void _marpaESLIF_bootstrap_adverb_list_items_freev(genericStack_t *adverbListItemStackp);
static inline void _marpaESLIF_bootstrap_alternative_freev(marpaESLIF_bootstrap_alternative_t *alternativep);
static inline void _marpaESLIF_bootstrap_alternatives_freev(genericStack_t *alternativeStackp);
static inline void _marpaESLIF_bootstrap_priorities_freev(genericStack_t *alternativesStackp);
static inline void _marpaESLIF_bootstrap_single_symbol_freev(marpaESLIF_bootstrap_single_symbol_t *singleSymbolp);
static inline void _marpaESLIF_bootstrap_symbol_freev(marpaESLIF_bootstrap_symbol_t *symbolp);
static inline void _marpaESLIF_bootstrap_terminal_freev(marpaESLIF_bootstrap_terminal_t *terminalp);
static inline void _marpaESLIF_bootstrap_grammar_reference_freev(marpaESLIF_bootstrap_grammar_reference_t *grammarReferencep);
static inline void _marpaESLIF_bootstrap_event_initialization_freev(marpaESLIF_bootstrap_event_initialization_t *eventInitializationp);
static        void _marpaESLIF_bootstrap_freeDefaultActionv(void *userDatavNotUsedp, marpaESLIFValueResult_t *marpaESLIFValueResultp);
static inline marpaESLIF_bootstrap_utf_string_t *_marpaESLIF_bootstrap_unquote_string_literalp(marpaESLIFValue_t *marpaESLIFValuep, void *bytep, size_t bytel, short allowEmptyStringb);

static inline marpaESLIF_grammar_bootstrap_t *_marpaESLIF_bootstrap_check_grammarBootstrapp(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, int leveli, marpaESLIF_bootstrap_utf_string_t *stringp);
static inline marpaESLIF_symbol_t  *_marpaESLIF_bootstrap_check_lhsp(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_lhs_t *bootstrapLhsp);
static inline marpaESLIF_symbol_t  *_marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, char *asciinames, short createb, short forcecreateb, short lhsb, marpaESLIF_lua_functiondecl_t *declp, short rhsb, marpaESLIF_lua_functioncall_t *callp);
static inline short                 _marpaESLIF_bootstrap_search_terminal_by_descriptionb(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_terminal_type_t terminalType, marpaESLIF_bootstrap_utf_string_t *stringp, marpaESLIF_symbol_t **symbolpp);
static inline marpaESLIF_symbol_t  *_marpaESLIF_bootstrap_find_terminal_by_namep(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_utf_string_t *stringp);
static inline short                 _marpaESLIF_bootstrap_search_terminal_pseudob(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_terminal_type_t terminalType, marpaESLIF_symbol_t **symbolpp);
static inline marpaESLIF_symbol_t  *_marpaESLIF_bootstrap_check_terminal_by_typep(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_terminal_type_t terminalType, marpaESLIF_bootstrap_utf_string_t *stringp, short createb, short pseudob, short forcecreateb, char *descEncodings, char *descs, size_t descl, short characterClassb);
static inline marpaESLIF_symbol_t  *_marpaESLIF_bootstrap_check_quotedStringp(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_utf_string_t *quotedStringp, short createb, short forcecreateb);
static inline marpaESLIF_symbol_t  *_marpaESLIF_bootstrap_check_builtinp(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_terminal_type_t type, short createb, short forcecreateb);
static inline marpaESLIF_symbol_t  *_marpaESLIF_bootstrap_check_regexp(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_utf_string_t *regexp, short createb, short forcecreateb, short characterClassb);
static inline marpaESLIF_symbol_t  *_marpaESLIF_bootstrap_check_singleSymbolp(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_single_symbol_t *singleSymbolp, short createb, short forcecreateb, short lhsb, marpaESLIF_lua_functiondecl_t *declp, short rhsb, marpaESLIF_lua_functioncall_t *callp);
static inline marpaESLIF_symbol_t  *_marpaESLIF_bootstrap_check_symbolp(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_symbol_t *symbolp, short createb, short forcecreateb, short lhsb, marpaESLIF_lua_functiondecl_t *declp, short rhsb, marpaESLIF_lua_functioncall_t *callp);
static inline marpaESLIF_symbol_t  *_marpaESLIF_bootstrap_check_terminalp(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_terminal_t *terminalp, short createb, short forcecreateb, short lhsb, marpaESLIF_lua_functiondecl_t *declp, short rhsb, marpaESLIF_lua_functioncall_t *callp);
static inline marpaESLIF_symbol_t  *_marpaESLIF_bootstrap_check_rhsPrimaryp(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_rhs_primary_t *rhsPrimaryp, short createb, short forcecreateb);
static inline marpaESLIF_symbol_t  *_marpaESLIF_bootstrap_check_rhsAlternativep(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_rhs_alternative_t *rhsAlternativep, short createb, marpaESLIF_lua_functiondecl_t *declp);
static inline short _marpaESLIF_bootstrap_unpack_adverbListItemStackb(marpaESLIFValue_t                            *marpaESLIFValuep,
                                                                      char                                         *contexts,
                                                                      genericStack_t                               *adverbListItemStackp,
                                                                      marpaESLIF_action_t                         **actionpp,
                                                                      short                                        *left_associationbp,
                                                                      short                                        *right_associationbp,
                                                                      short                                        *group_associationbp,
                                                                      marpaESLIF_bootstrap_rhs_primary_t         **separatorRhsPrimarypp,
                                                                      short                                        *properbp,
                                                                      short                                       **verbosebpp,
                                                                      short                                        *hideseparatorbp,
                                                                      int                                          *rankip,
                                                                      short                                        *nullRanksHighbp,
                                                                      int                                         **priorityipp,
                                                                      marpaESLIF_bootstrap_pause_type_t            *pauseip,
                                                                      short                                        *latmbp,
                                                                      short                                        *discardIsFallbackbp,
                                                                      marpaESLIF_bootstrap_utf_string_t           **namingpp,
                                                                      marpaESLIF_action_t                         **symbolactionpp,
                                                                      marpaESLIF_bootstrap_event_initialization_t **eventInitializationpp,
                                                                      marpaESLIF_action_t                         **ifactionpp,
                                                                      marpaESLIF_action_t                         **regexactionpp,
                                                                      marpaESLIF_action_t                         **eventactionpp,
                                                                      char                                        **defaultEncodingsp,
                                                                      char                                        **fallbackEncodingsp
                                                                      );
static inline short _marpaESLIF_bootstrap_G1_action_event_declarationb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb, marpaESLIF_bootstrap_event_declaration_type_t type);
static inline marpaESLIF_bootstrap_utf_string_t *_marpaESLIF_bootstrap_regex_to_stringb(marpaESLIF_t *marpaESLIFp, void *bytep, size_t bytel);
static inline marpaESLIF_bootstrap_utf_string_t *_marpaESLIF_bootstrap_characterClass_to_stringp(marpaESLIF_t *marpaESLIFp, void *bytep, size_t bytel);
static inline int _marpaESLIF_bootstrap_ord2utfb(marpaESLIF_uint32_t uint32, PCRE2_UCHAR *bufferp);
static inline short _marpaESLIF_bootstrap_G1_action_rhs_alternative_prioritiesb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb, short skipb, short lookaheadb);
static inline short _marpaESLIF_bootstrap_G1_action_rhs_alternative_exceptionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb, short skipb, short lookaheadb);
static inline short _marpaESLIF_bootstrap_G1_action_rhs_alternative_quantifiedb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb, short skipb, short lookaheadb);
static inline short _marpaESLIF_bootstrap_G1_action_terminal_pseudob(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, marpaESLIF_bootstrap_terminal_type_t type, int resulti);

static        short _marpaESLIF_bootstrap_G1_action_symbol_name_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_symbol_name_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_op_declare_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_op_declare_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_op_declare_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_rhsb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_adverb_list_itemsb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_action_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_action_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_action_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_string_literalb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_string_literal_inside_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_string_literal_inside_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_string_literal_inside_4b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_string_literal_inside_5b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_symbolaction_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_symbolaction_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_symbolaction_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_left_associationb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_right_associationb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_group_associationb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_separator_specificationb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_rhs_alternative_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_rhs_alternative_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_rhs_alternative_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_rhs_alternative_4b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_rhs_alternative_5b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_rhs_alternative_6b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_rhs_alternative_7b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_rhs_alternative_8b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_rhs_alternative_9b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_rhs_alternative_10b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_rhs_primary_no_parameter_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_rhs_primary_no_parameter_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_rhs_primary_no_parameter_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_rhs_primary_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_rhs_primary_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_alternativeb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_alternativesb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_prioritiesb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_priority_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static inline short _marpaESLIF_bootstrap_G1_action_priority_loosen_ruleb(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_symbol_t *lhsp, genericStack_t *alternativesStackp, marpaESLIF_lua_functiondecl_t *declp);
static inline short _marpaESLIF_bootstrap_G1_action_priority_flat_ruleb(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_symbol_t *lhsp, genericStack_t *alternativesStackp, char *contexts, marpaESLIF_lua_functiondecl_t *declp);
static        short _marpaESLIF_bootstrap_G1_action_single_symbol_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_single_symbol_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_terminal_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_terminal_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_terminal_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_terminal_4b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_terminal_5b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_terminal_6b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_terminal_7b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_terminal_8b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_symbolb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_grammar_reference_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_grammar_reference_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_grammar_reference_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_inaccessible_treatment_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_inaccessible_treatment_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_inaccessible_treatment_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_inaccessible_statementb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_on_or_off_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_on_or_off_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_autorank_statementb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_quantifier_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_quantifier_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_quantified_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_start_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_desc_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_empty_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_default_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_latm_specification_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_latm_specification_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_discard_is_fallback_specification_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_discard_is_fallback_specification_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_proper_specification_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_proper_specification_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_verbose_specification_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_verbose_specification_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_hideseparator_specification_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_hideseparator_specification_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_rank_specificationb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_null_ranking_specification_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_null_ranking_specification_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_null_ranking_constant_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_null_ranking_constant_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_pause_specification_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_pause_specification_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_priority_specificationb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_event_initializer_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_event_initializer_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_event_initializationb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_event_specificationb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_lexeme_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_terminal_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_symbol_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static inline short __marpaESLIF_bootstrap_G1_action_symbol_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb, marpaESLIF_symbol_type_t wantedType);
static        short _marpaESLIF_bootstrap_G1_action_discard_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_completion_event_declaration_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_completion_event_declaration_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_nulled_event_declaration_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_nulled_event_declaration_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_predicted_event_declaration_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_predicted_event_declaration_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_alternative_name_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_namingb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_exception_statementb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_luascript_statementb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_ifactionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_regexactionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_generatoractionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_eventactionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_defaultencodingb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_fallbackencodingb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_lua_functionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static inline short _marpaESLIF_bootstrap_G1_action_genericb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb, char *contexts, void *contextp);
static        short _marpaESLIF_bootstrap_G1_action_lua_functioncallb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_lua_functiondeclb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_lhs_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_lhs_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_start_symbol_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static        short _marpaESLIF_bootstrap_G1_action_start_symbol_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb);
static inline marpaESLIF_rule_t *_marpaESLIF_bootstrap_check_rulep(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, char *descEncodings, char *descs, size_t descl, int lhsi, size_t nrhsl, int *rhsip, int exceptioni, int ranki, short nullRanksHighb, short sequenceb, int minimumi, int separatori, short properb, marpaESLIF_action_t *actionp, short hideseparatorb, short *skipbp, marpaESLIF_lua_functiondecl_t *declp, marpaESLIF_lua_functioncall_t **callpp, marpaESLIF_lua_functioncall_t *separatorcallp);
static short marpaESLIFValueImport(marpaESLIFValue_t *marpaESLIFValuep, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, short haveUndefb);
static inline marpaESLIF_bootstrap_terminal_t *_marpaESLIF_bootstrap_quotedstring_to_terminalp(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, void *bytep, size_t bytel, marpaESLIF_terminal_t *modifiersp);
static inline marpaESLIF_bootstrap_terminal_t *_marpaESLIF_bootstrap_regex_to_terminalp(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, void *bytep, size_t bytel);

/* Helpers */
#define MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, indicei, _p, _l) do { \
    marpaESLIFValueResult_t *_marpaESLIFValueResultp;                   \
                                                                        \
    _marpaESLIFValueResultp = _marpaESLIFValue_stack_getp(marpaESLIFValuep, indicei); \
    if (MARPAESLIF_UNLIKELY(_marpaESLIFValueResultp == NULL)) {         \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    if (MARPAESLIF_UNLIKELY(_marpaESLIFValueResultp->type != MARPAESLIF_VALUE_TYPE_ARRAY)) { \
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "marpaESLIFValueResultp->type is not ARRAY (got %d, %s)", _marpaESLIFValueResultp->type, _marpaESLIF_value_types(_marpaESLIFValueResultp->type)); \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    _p = _marpaESLIFValueResultp->u.a.p;                                \
    _l = _marpaESLIFValueResultp->u.a.sizel;                            \
  } while (0)

#define MARPAESLIF_BOOTSTRAP_GET_ASCII(marpaESLIFValuep, indicei, _p) do { \
    marpaESLIFValueResult_t *_marpaESLIFValueResultp;                   \
                                                                        \
    _marpaESLIFValueResultp = _marpaESLIFValue_stack_getp(marpaESLIFValuep, indicei); \
    if (MARPAESLIF_UNLIKELY(_marpaESLIFValueResultp == NULL)) {         \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    if (MARPAESLIF_UNLIKELY(_marpaESLIFValueResultp->type != MARPAESLIF_VALUE_TYPE_STRING)) { \
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "marpaESLIFValueResultp->type is not STRING (got %d, %s)", _marpaESLIFValueResultp->type, _marpaESLIF_value_types(_marpaESLIFValueResultp->type)); \
      goto err;                                                         \
    }                                                                   \
    if (MARPAESLIF_UNLIKELY(strcmp(_marpaESLIFValueResultp->u.s.encodingasciis, "ASCII") != 0)) { \
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "marpaESLIFValueResultp->u.s.encodingasciis is not \"ASCII\", got \"%s\"", _marpaESLIFValueResultp->u.s.encodingasciis); \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    _p = (char *) _marpaESLIFValueResultp->u.s.p;                       \
  } while (0)

/* We do not mind about shallowness, because only us can push a PTR, and our PTRs are never shallow */
#define MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, indicei, _p) do { \
    marpaESLIFValueResult_t _marpaESLIFValueResult;                     \
                                                                        \
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFValue_stack_getAndForgetb(marpaESLIFValuep, indicei, &_marpaESLIFValueResult))) { \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    if (MARPAESLIF_UNLIKELY(_marpaESLIFValueResult.type != MARPAESLIF_VALUE_TYPE_PTR)) { \
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "marpaESLIFValueResult.type is not PTR (got %d, %s)", _marpaESLIFValueResult.type, _marpaESLIF_value_types(_marpaESLIFValueResult.type)); \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    _p        = _marpaESLIFValueResult.u.p.p;                           \
  } while (0)

#define MARPAESLIF_BOOTSTRAP_GETANDFORGET_ASCII(marpaESLIFValuep, indicei, _p, _shallowb) do { \
    marpaESLIFValueResult_t _marpaESLIFValueResult;                     \
                                                                        \
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFValue_stack_getAndForgetb(marpaESLIFValuep, indicei, &_marpaESLIFValueResult))) { \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    if (MARPAESLIF_UNLIKELY(_marpaESLIFValueResult.type != MARPAESLIF_VALUE_TYPE_STRING)) { \
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "marpaESLIFValueResult.type is not STRING (got %d, %s)", _marpaESLIFValueResult.type, _marpaESLIF_value_types(_marpaESLIFValueResult.type)); \
      goto err;                                                         \
    }                                                                   \
    if (MARPAESLIF_UNLIKELY(_marpaESLIFValueResult.u.s.encodingasciis == NULL)) { \
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "marpaESLIFValueResult.u.s.encodingasciis is NULL"); \
      goto err;                                                         \
    }                                                                   \
    if (MARPAESLIF_UNLIKELY(strcmp(_marpaESLIFValueResult.u.s.encodingasciis, "ASCII") != 0)) { \
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "marpaESLIFValueResult.u.s.encodingasciis is not \"ASCII\", got \"%s\"", _marpaESLIFValueResult.u.s.encodingasciis); \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    /* Encoding is always allocated */                                  \
    free(_marpaESLIFValueResult.u.s.encodingasciis);                    \
                                                                        \
    _p        = (char *) _marpaESLIFValueResult.u.s.p;                  \
    _shallowb = _marpaESLIFValueResult.u.s.shallowb;                    \
  } while (0)

#define MARPAESLIF_BOOTSTRAP_IS_UNDEF(marpaESLIFValuep, indicei, rcb) do { \
    marpaESLIFValueResult_t *_marpaESLIFValueResultp;                   \
                                                                        \
    _marpaESLIFValueResultp = _marpaESLIFValue_stack_getp(marpaESLIFValuep, indicei); \
    if (MARPAESLIF_UNLIKELY(_marpaESLIFValueResultp == NULL)) {         \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    rcb = (_marpaESLIFValueResultp->type == MARPAESLIF_VALUE_TYPE_UNDEF); \
  } while (0)

#define MARPAESLIF_BOOTSTRAP_IS_INT(marpaESLIFValuep, indicei, rcb) do { \
    marpaESLIFValueResult_t *_marpaESLIFValueResultp;                   \
                                                                        \
    _marpaESLIFValueResultp = _marpaESLIFValue_stack_getp(marpaESLIFValuep, indicei); \
    if (MARPAESLIF_UNLIKELY(_marpaESLIFValueResultp == NULL)) {         \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    rcb = (_marpaESLIFValueResultp->type == MARPAESLIF_VALUE_TYPE_INT); \
  } while (0)

#define MARPAESLIF_BOOTSTRAP_GET_CONTEXT(marpaESLIFValuep, indicei, _contextp) do { \
    marpaESLIFValueResult_t *_marpaESLIFValueResultp;                   \
                                                                        \
    _marpaESLIFValueResultp = _marpaESLIFValue_stack_getp(marpaESLIFValuep, indicei); \
    if (MARPAESLIF_UNLIKELY(_marpaESLIFValueResultp == NULL)) {         \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    _contextp = _marpaESLIFValueResultp->contextp;                      \
  } while (0)

#define MARPAESLIF_BOOTSTRAP_GET_BOOL(marpaESLIFValuep, indicei, _y) do { \
    marpaESLIFValueResult_t *_marpaESLIFValueResultp;                   \
                                                                        \
    _marpaESLIFValueResultp = _marpaESLIFValue_stack_getp(marpaESLIFValuep, indicei); \
    if (MARPAESLIF_UNLIKELY(_marpaESLIFValueResultp == NULL)) {         \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    if (MARPAESLIF_UNLIKELY(_marpaESLIFValueResultp->type != MARPAESLIF_VALUE_TYPE_BOOL)) { \
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "marpaESLIFValueResultp->type is not BOOL (got %d, %s)", _marpaESLIFValueResultp->type, _marpaESLIF_value_types(_marpaESLIFValueResultp->type)); \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    _y = _marpaESLIFValueResultp->u.y;                                  \
  } while (0)

#define MARPAESLIF_BOOTSTRAP_GET_SHORT(marpaESLIFValuep, indicei, _b) do { \
    marpaESLIFValueResult_t *_marpaESLIFValueResultp;                   \
                                                                        \
    _marpaESLIFValueResultp = _marpaESLIFValue_stack_getp(marpaESLIFValuep, indicei); \
    if (MARPAESLIF_UNLIKELY(_marpaESLIFValueResultp == NULL)) {         \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    if (MARPAESLIF_UNLIKELY(_marpaESLIFValueResultp->type != MARPAESLIF_VALUE_TYPE_SHORT)) { \
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "marpaESLIFValueResultp->type is not SHORT (got %d, %s)", _marpaESLIFValueResultp->type, _marpaESLIF_value_types(_marpaESLIFValueResultp->type)); \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    _b = _marpaESLIFValueResultp->u.b;                                  \
  } while (0)

#define MARPAESLIF_BOOTSTRAP_GET_INT(marpaESLIFValuep, indicei, _i) do { \
    marpaESLIFValueResult_t *_marpaESLIFValueResultp;                   \
                                                                        \
    _marpaESLIFValueResultp = _marpaESLIFValue_stack_getp(marpaESLIFValuep, indicei); \
    if (MARPAESLIF_UNLIKELY(_marpaESLIFValueResultp == NULL)) {         \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    if (MARPAESLIF_UNLIKELY(_marpaESLIFValueResultp->type != MARPAESLIF_VALUE_TYPE_INT)) { \
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "marpaESLIFValueResultp->type is not INT (got %d, %s)", _marpaESLIFValueResultp->type, _marpaESLIF_value_types(_marpaESLIFValueResultp->type)); \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    _i = _marpaESLIFValueResultp->u.i;                                  \
  } while (0)

/* Stack set macros - we use the _marpaESLIFValue_stack_setb() instead of marpaESLIFValue_stack_setb() */
/* because we are inside marpaESLIF and know what we are doing -; */
/* The _marpaESLIFValue_stack_setb() is equivalent to marpaESLIFValue_stack_setb(), but with no check on the arguments */

#define MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, indicei, _contextp, _p) do { \
    marpaESLIFValueResult_t _marpaESLIFValueResult;                     \
                                                                        \
    _marpaESLIFValueResult.type               = MARPAESLIF_VALUE_TYPE_PTR; \
    _marpaESLIFValueResult.contextp           = _contextp;              \
    _marpaESLIFValueResult.representationp    = NULL;                   \
    _marpaESLIFValueResult.u.p.p              = _p;                     \
    _marpaESLIFValueResult.u.p.freeCallbackp  = _marpaESLIF_bootstrap_freeDefaultActionv; \
    _marpaESLIFValueResult.u.p.freeUserDatavp = NULL;                   \
    _marpaESLIFValueResult.u.p.shallowb       = 0;                      \
                                                                        \
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFValue_stack_setb(marpaESLIFValuep, indicei, &_marpaESLIFValueResult))) { \
      goto err;                                                         \
    }                                                                   \
                                                                        \
  } while (0)

#define MARPAESLIF_BOOTSTRAP_SET_ARRAY(marpaESLIFValuep, indicei, _contextp, _p, _l) do { \
    marpaESLIFValueResult_t _marpaESLIFValueResult;                     \
                                                                        \
    _marpaESLIFValueResult.type               = MARPAESLIF_VALUE_TYPE_ARRAY; \
    _marpaESLIFValueResult.contextp           = _contextp;              \
    _marpaESLIFValueResult.representationp    = NULL;                   \
    _marpaESLIFValueResult.u.a.p              = _p;                     \
    _marpaESLIFValueResult.u.a.freeCallbackp  = _marpaESLIF_bootstrap_freeDefaultActionv; \
    _marpaESLIFValueResult.u.a.freeUserDatavp = NULL;                   \
    _marpaESLIFValueResult.u.a.shallowb       = 0;                      \
    _marpaESLIFValueResult.u.a.sizel          = _l;                     \
                                                                        \
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFValue_stack_setb(marpaESLIFValuep, indicei, &_marpaESLIFValueResult))) { \
      goto err;                                                         \
    }                                                                   \
                                                                        \
  } while (0)

#define MARPAESLIF_BOOTSTRAP_SET_UNDEF(marpaESLIFValuep, indicei, _contextp) do { \
    marpaESLIFValueResult_t _marpaESLIFValueResult;                     \
                                                                        \
    _marpaESLIFValueResult.type            = MARPAESLIF_VALUE_TYPE_UNDEF; \
    _marpaESLIFValueResult.contextp        = _contextp;                 \
    _marpaESLIFValueResult.representationp = NULL;                      \
                                                                        \
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFValue_stack_setb(marpaESLIFValuep, indicei, &_marpaESLIFValueResult))) { \
      goto err;                                                         \
    }                                                                   \
                                                                        \
  } while (0)

#define MARPAESLIF_BOOTSTRAP_SET_INT(marpaESLIFValuep, indicei, _contextp, _i) do { \
    marpaESLIFValueResult_t _marpaESLIFValueResult;                     \
                                                                        \
    _marpaESLIFValueResult.type            = MARPAESLIF_VALUE_TYPE_INT; \
    _marpaESLIFValueResult.contextp        = _contextp;                 \
    _marpaESLIFValueResult.representationp = NULL;                      \
    _marpaESLIFValueResult.u.i             = _i;                        \
                                                                        \
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFValue_stack_setb(marpaESLIFValuep, indicei, &_marpaESLIFValueResult))) { \
      goto err;                                                         \
    }                                                                   \
                                                                        \
  } while (0)

#define MARPAESLIF_BOOTSTRAP_SET_BOOL(marpaESLIFValuep, indicei, _contextp, _y) do { \
    marpaESLIFValueResult_t _marpaESLIFValueResult;                     \
                                                                        \
    _marpaESLIFValueResult.type            = MARPAESLIF_VALUE_TYPE_BOOL; \
    _marpaESLIFValueResult.contextp        = _contextp;                 \
    _marpaESLIFValueResult.representationp = NULL;                      \
    _marpaESLIFValueResult.u.y             = _y;                        \
                                                                        \
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFValue_stack_setb(marpaESLIFValuep, indicei, &_marpaESLIFValueResult))) { \
      goto err;                                                         \
    }                                                                   \
                                                                        \
  } while (0)

#define MARPAESLIF_BOOTSTRAP_SET_SHORT(marpaESLIFValuep, indicei, _contextp, _b) do { \
    marpaESLIFValueResult_t _marpaESLIFValueResult;                     \
                                                                        \
    _marpaESLIFValueResult.type            = MARPAESLIF_VALUE_TYPE_SHORT; \
    _marpaESLIFValueResult.contextp        = _contextp;                 \
    _marpaESLIFValueResult.representationp = NULL;                      \
    _marpaESLIFValueResult.u.b             = _b;                        \
                                                                        \
    if (MARPAESLIF_UNLIKELY(! _marpaESLIFValue_stack_setb(marpaESLIFValuep, indicei, &_marpaESLIFValueResult))) { \
      goto err;                                                         \
    }                                                                   \
                                                                        \
  } while (0)

/* We use the \x notation in case the current compiler does not know all the escape sequences */
#define MARPAESLIF_BOOTSTRAP_DST_OR_VALCHAR(marpaESLIFValuep, dst, valchar) do { \
    unsigned char _valchar = (unsigned char) (valchar);                 \
    switch (_valchar) {                                                 \
    case '0':                                                           \
      dst |= 0x00;                                                      \
      break;                                                            \
    case '1':                                                           \
      dst |= 0x01;                                                      \
      break;                                                            \
    case '2':                                                           \
      dst |= 0x02;                                                      \
      break;                                                            \
    case '3':                                                           \
      dst |= 0x03;                                                      \
      break;                                                            \
    case '4':                                                           \
      dst |= 0x04;                                                      \
      break;                                                            \
    case '5':                                                           \
      dst |= 0x05;                                                      \
      break;                                                            \
    case '6':                                                           \
      dst |= 0x06;                                                      \
      break;                                                            \
    case '7':                                                           \
      dst |= 0x07;                                                      \
      break;                                                            \
    case '8':                                                           \
      dst |= 0x08;                                                      \
      break;                                                            \
    case '9':                                                           \
      dst |= 0x09;                                                      \
      break;                                                            \
    case 'a':                                                           \
    case 'A':                                                           \
      dst |= 0x0A;                                                      \
      break;                                                            \
    case 'b':                                                           \
    case 'B':                                                           \
      dst |= 0x0B;                                                      \
      break;                                                            \
    case 'c':                                                           \
    case 'C':                                                           \
      dst |= 0x0C;                                                      \
      break;                                                            \
    case 'd':                                                           \
    case 'D':                                                           \
      dst |= 0x0D;                                                      \
      break;                                                            \
    case 'e':                                                           \
    case 'E':                                                           \
      dst |= 0x0E;                                                      \
      break;                                                            \
    case 'f':                                                           \
    case 'F':                                                           \
      dst |= 0x0F;                                                      \
      break;                                                            \
    default:                                                            \
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unsupported hexadecimal character '%c' (0x%lx)", _valchar, (unsigned long) _valchar); \
      goto err;                                                         \
    }                                                                   \
  } while (0)

/*****************************************************************************/
static inline void  _marpaESLIF_bootstrap_rhs_primary_freev(marpaESLIF_bootstrap_rhs_primary_t *rhsPrimaryp)
/*****************************************************************************/
{
  if (rhsPrimaryp != NULL) {
    _marpaESLIF_lua_functioncall_freev(rhsPrimaryp->callp);
    switch (rhsPrimaryp->type) {
    case MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_SINGLE_SYMBOL:
      _marpaESLIF_bootstrap_single_symbol_freev(rhsPrimaryp->u.singleSymbolp);
      break;
    case MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_SYMBOL_AND_REFERENCE:
      _marpaESLIF_bootstrap_symbol_and_reference_freev(rhsPrimaryp->u.symbolAndReferencep);
      break;
    case MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_GENERATOR_ACTION:
      _marpaESLIF_action_freev(rhsPrimaryp->u.generatorActionp);
      break;
    case MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_NAME:
      _marpaESLIF_bootstrap_utf_string_freev(&(rhsPrimaryp->u.name), 1 /* onStackb */);
      break;
    default:
      break;
    }
    free(rhsPrimaryp);
  }
}

/*****************************************************************************/
static inline void _marpaESLIF_bootstrap_lhs_freev(marpaESLIF_bootstrap_lhs_t *bootstrapLhsp)
/*****************************************************************************/
{
  if (bootstrapLhsp != NULL) {
    if (bootstrapLhsp->symbols != NULL) {
      free(bootstrapLhsp->symbols);
    }
    _marpaESLIF_lua_functiondecl_freev(bootstrapLhsp->declp);
    free(bootstrapLhsp);
  }
}

/*****************************************************************************/
static inline void _marpaESLIF_bootstrap_start_symbol_freev(marpaESLIF_bootstrap_start_symbol_t *startSymbolp)
/*****************************************************************************/
{
  if (startSymbolp != NULL) {
    if (startSymbolp->symbols != NULL) {
      free(startSymbolp->symbols);
    }
    _marpaESLIF_lua_functioncall_freev(startSymbolp->callp);
    free(startSymbolp);
  }
}

/*****************************************************************************/
static inline void _marpaESLIF_bootstrap_lua_function_freev(marpaESLIF_bootstrap_lua_function_t *luaFunctionp)
/*****************************************************************************/
{
  if (luaFunctionp != NULL) {
    if (luaFunctionp->luas != NULL) {
      free(luaFunctionp->luas);
    }
    if (luaFunctionp->actions != NULL) {
      free(luaFunctionp->actions);
    }
    if (luaFunctionp->luacstripp != NULL) {
      free(luaFunctionp->luacstripp);
    }
    free(luaFunctionp);
  }
}

/*****************************************************************************/
static inline void  _marpaESLIF_bootstrap_rhs_alternative_freev(marpaESLIF_bootstrap_rhs_alternative_t *rhsAlternativep)
/*****************************************************************************/
{
  if (rhsAlternativep != NULL) {
    switch (rhsAlternativep->type) {
    case MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_RHS_PRIMARY:
      _marpaESLIF_bootstrap_rhs_primary_freev(rhsAlternativep->u.rhsPrimaryp);
      break;
    case MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_PRIORITIES:
      _marpaESLIF_bootstrap_priorities_freev(rhsAlternativep->u.priorities.alternativesStackp);
      break;
    case MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_EXCEPTION:
      _marpaESLIF_bootstrap_rhs_primary_freev(rhsAlternativep->u.exception.rhsPrimaryp);
      _marpaESLIF_bootstrap_rhs_primary_freev(rhsAlternativep->u.exception.rhsPrimaryExceptionp);
      _marpaESLIF_bootstrap_adverb_list_items_freev(rhsAlternativep->u.exception.adverbListItemStackp);
      break;
    case MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_QUANTIFIED:
      _marpaESLIF_bootstrap_rhs_primary_freev(rhsAlternativep->u.quantified.rhsPrimaryp);
      _marpaESLIF_bootstrap_adverb_list_items_freev(rhsAlternativep->u.quantified.adverbListItemStackp);
      break;
    default:
      break;
    }
    free(rhsAlternativep);
  }
}

/*****************************************************************************/
static inline void _marpaESLIF_bootstrap_symbol_and_reference_freev(marpaESLIF_bootstrap_symbol_and_reference_t *symbolAndReferencep)
/*****************************************************************************/
{
  if (symbolAndReferencep != NULL) {
    _marpaESLIF_bootstrap_symbol_freev(symbolAndReferencep->symbolp);
    _marpaESLIF_bootstrap_grammar_reference_freev(symbolAndReferencep->grammarReferencep);
    free(symbolAndReferencep);
  }
}

/*****************************************************************************/
static inline void  _marpaESLIF_bootstrap_utf_string_freev(marpaESLIF_bootstrap_utf_string_t *stringp, short onStackb)
/*****************************************************************************/
{
  if (stringp != NULL) {
    if (stringp->substitutionBytep != NULL) {
      free(stringp->substitutionBytep);
    }
    if (stringp->substitutionModifiers != NULL) {
      free(stringp->substitutionModifiers);
    }
    if (stringp->bytep != NULL) {
      free(stringp->bytep);
    }
    if (stringp->modifiers != NULL) {
      free(stringp->modifiers);
    }
    if (! onStackb) {
      free(stringp);
    }
  }
}

/*****************************************************************************/
static inline void _marpaESLIF_bootstrap_rhs_freev(genericStack_t *rhsAlternativeStackp)
/*****************************************************************************/
{
  int i;

  if (rhsAlternativeStackp != NULL) {
    for (i = 0; i < GENERICSTACK_USED(rhsAlternativeStackp); i++) {
      if (GENERICSTACK_IS_PTR(rhsAlternativeStackp, i)) {
        _marpaESLIF_bootstrap_rhs_alternative_freev((marpaESLIF_bootstrap_rhs_alternative_t *) GENERICSTACK_GET_PTR(rhsAlternativeStackp, i));
      }
    }
    GENERICSTACK_FREE(rhsAlternativeStackp);
  }
}

/*****************************************************************************/
static inline void  _marpaESLIF_bootstrap_adverb_list_items_freev(genericStack_t *adverbListItemStackp)
/*****************************************************************************/
{
  int i;

  if (adverbListItemStackp != NULL) {
    for (i = 0; i < GENERICSTACK_USED(adverbListItemStackp); i++) {
      if (GENERICSTACK_IS_PTR(adverbListItemStackp, i)) {
        _marpaESLIF_bootstrap_adverb_list_item_freev((marpaESLIF_bootstrap_adverb_list_item_t *) GENERICSTACK_GET_PTR(adverbListItemStackp, i));
      }
    }
    GENERICSTACK_FREE(adverbListItemStackp);
  }
}

/*****************************************************************************/
static inline void _marpaESLIF_bootstrap_alternative_freev(marpaESLIF_bootstrap_alternative_t *alternativep)
/*****************************************************************************/
{
  if (alternativep != NULL) {
    _marpaESLIF_bootstrap_rhs_freev(alternativep->rhsAlternativeStackp);
    _marpaESLIF_bootstrap_adverb_list_items_freev(alternativep->adverbListItemStackp);
    free(alternativep);
  }
}

/*****************************************************************************/
static inline void _marpaESLIF_bootstrap_alternatives_freev(genericStack_t *alternativeStackp)
/*****************************************************************************/
{
  int i;

  if (alternativeStackp != NULL) {
    for (i = 0; i < GENERICSTACK_USED(alternativeStackp); i++) {
      if (GENERICSTACK_IS_PTR(alternativeStackp, i)) {
        _marpaESLIF_bootstrap_alternative_freev((marpaESLIF_bootstrap_alternative_t *) GENERICSTACK_GET_PTR(alternativeStackp, i));
      }
    }
    GENERICSTACK_FREE(alternativeStackp);
  }
}

/*****************************************************************************/
static inline void _marpaESLIF_bootstrap_priorities_freev(genericStack_t *alternativesStackp)
/*****************************************************************************/
{
  int i;

  if (alternativesStackp != NULL) {
    for (i = 0; i < GENERICSTACK_USED(alternativesStackp); i++) {
      if (GENERICSTACK_IS_PTR(alternativesStackp, i)) {
        _marpaESLIF_bootstrap_alternatives_freev((genericStack_t *) GENERICSTACK_GET_PTR(alternativesStackp, i));
      }
    }
    GENERICSTACK_FREE(alternativesStackp);
  }
}

/*****************************************************************************/
static inline void _marpaESLIF_bootstrap_single_symbol_freev(marpaESLIF_bootstrap_single_symbol_t *singleSymbolp)
/*****************************************************************************/
{
  if (singleSymbolp != NULL) {
    switch (singleSymbolp->type) {
    case MARPAESLIF_BOOTSTRAP_SINGLE_SYMBOL_TYPE_SYMBOL:
      _marpaESLIF_bootstrap_symbol_freev(singleSymbolp->u.symbolp);
      break;
    case MARPAESLIF_BOOTSTRAP_SINGLE_SYMBOL_TYPE_TERMINAL:
      _marpaESLIF_bootstrap_terminal_freev(singleSymbolp->u.terminalp);
      break;
    default:
      break;
    }
    free(singleSymbolp);
  }
}

/*****************************************************************************/
static inline void _marpaESLIF_bootstrap_symbol_freev(marpaESLIF_bootstrap_symbol_t *symbolp)
/*****************************************************************************/
{
  if (symbolp != NULL) {
    if (symbolp->symbols != NULL) {
      free(symbolp->symbols);
    }
    free(symbolp);
  }
}

/*****************************************************************************/
static inline void _marpaESLIF_bootstrap_terminal_freev(marpaESLIF_bootstrap_terminal_t *terminalp)
/*****************************************************************************/
{
  if (terminalp != NULL) {
    switch (terminalp->type) {
    case MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE_CHARACTER_CLASS:
      _marpaESLIF_bootstrap_utf_string_freev(terminalp->u.characterClassp, 0 /* onStackb */);
      break;
    case MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE_REGULAR_EXPRESSION:
      _marpaESLIF_bootstrap_utf_string_freev(terminalp->u.regularExpressionp, 0 /* onStackb */);
      break;
    case MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE_QUOTED_STRING:
      _marpaESLIF_bootstrap_utf_string_freev(terminalp->u.stringp, 0 /* onStackb */);
      break;
    case MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__EOF:
      /* No op - here for clarity */
      break;
    case MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__EOL:
      /* No op - here for clarity */
      break;
    case MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__SOL:
      /* No op - here for clarity */
      break;
    case MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__EMPTY:
      /* No op - here for clarity */
      break;
    default:
      break;
    }
    free(terminalp);
  }
}

/*****************************************************************************/
static inline void _marpaESLIF_bootstrap_grammar_reference_freev(marpaESLIF_bootstrap_grammar_reference_t *grammarReferencep)
/*****************************************************************************/
{
  if (grammarReferencep != NULL) {
    switch (grammarReferencep->type) {
    case MARPAESLIF_BOOTSTRAP_GRAMMAR_REFERENCE_TYPE_STRING:
      _marpaESLIF_bootstrap_utf_string_freev(grammarReferencep->u.quotedStringp, 0 /* onStackb */);
      break;
    default:
      break;
    }
    free(grammarReferencep);
  }
}

/*****************************************************************************/
static inline void _marpaESLIF_bootstrap_event_initialization_freev(marpaESLIF_bootstrap_event_initialization_t *eventInitializationp)
/*****************************************************************************/
{
  if (eventInitializationp != NULL) {
    if (eventInitializationp->eventNames != NULL) {
      free(eventInitializationp->eventNames);
    }
    free(eventInitializationp);
  }
}

/*****************************************************************************/
static inline marpaESLIF_grammar_bootstrap_t *_marpaESLIF_bootstrap_check_grammarBootstrapp(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, int leveli, marpaESLIF_bootstrap_utf_string_t *stringp)
/*****************************************************************************/
{
  marpaESLIF_grammar_bootstrap_t *grammarBootstrapp = NULL;
  marpaESLIF_string_t             desc;
  marpaESLIF_string_t            *descp;
  marpaWrapperGrammarOption_t     marpaWrapperGrammarOption;

  if (marpaESLIFGrammarBootstrapp->grammarBootstrapStackp == NULL) {
    /* Make sure that the stack of grammars exist - Take care this is a stack inside Grammar structure */
    marpaESLIFGrammarBootstrapp->grammarBootstrapStackp = &(marpaESLIFGrammarBootstrapp->_grammarBootstrapStack);
    GENERICSTACK_INIT(marpaESLIFGrammarBootstrapp->grammarBootstrapStackp);
    if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(marpaESLIFGrammarBootstrapp->grammarBootstrapStackp))) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "marpaESLIFGrammarBootstrapp->grammarBootstrapStackp initialization failure, %s", strerror(errno));
      marpaESLIFGrammarBootstrapp->grammarBootstrapStackp = NULL;
      goto err;
    }
  }

  if (stringp != NULL) {
    desc.bytep          = stringp->bytep;
    desc.bytel          = stringp->bytel;
    desc.encodingasciis = "UTF-8";
    desc.asciis         = NULL;
    descp = &desc;
    grammarBootstrapp = _marpaESLIF_grammar_bootstrap_findp(marpaESLIFValuep->marpaESLIFp, marpaESLIFGrammarBootstrapp->grammarBootstrapStackp, leveli, descp);
  } else {
    descp = NULL;
    grammarBootstrapp = _marpaESLIF_grammar_bootstrap_findp(marpaESLIFValuep->marpaESLIFp, marpaESLIFGrammarBootstrapp->grammarBootstrapStackp, leveli, NULL);
  }

  if (grammarBootstrapp == NULL) {
    /* Create it */

    marpaWrapperGrammarOption.genericLoggerp    = marpaESLIFValuep->marpaESLIFp->marpaESLIFOption.genericLoggerp;
    marpaWrapperGrammarOption.warningIsErrorb   = marpaESLIFGrammarBootstrapp->warningIsErrorb;
    marpaWrapperGrammarOption.warningIsIgnoredb = marpaESLIFGrammarBootstrapp->warningIsIgnoredb;
    marpaWrapperGrammarOption.autorankb         = marpaESLIFGrammarBootstrapp->autorankb;

    grammarBootstrapp = _marpaESLIF_grammar_bootstrap_newp(marpaESLIFValuep->marpaESLIFp,
                                                           marpaESLIFGrammarBootstrapp,
                                                           &marpaWrapperGrammarOption,
                                                           leveli,
                                                           0, /* symbolStackSizei */
                                                           0, /* ruleStackSizei */
                                                           descp);
    if (MARPAESLIF_UNLIKELY(grammarBootstrapp == NULL)) {
      goto err;
    }
    GENERICSTACK_SET_PTR(marpaESLIFGrammarBootstrapp->grammarBootstrapStackp, grammarBootstrapp, leveli);
    if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(marpaESLIFGrammarBootstrapp->grammarBootstrapStackp))) {
      _marpaESLIF_grammar_bootstrap_freev(grammarBootstrapp);
      goto err;
    }
  }

  /* Note: grammarBootstrapp may be NULL here */
  goto done;

 err:
  grammarBootstrapp = NULL;

 done:
  return grammarBootstrapp;
}

/*****************************************************************************/
static inline marpaESLIF_symbol_t  *_marpaESLIF_bootstrap_check_lhsp(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_lhs_t *bootstrapLhsp)
/*****************************************************************************/
{
  return _marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, bootstrapLhsp->symbols, 1 /* createb */, 0 /* forcecreateb */, 1 /* lhsb */, bootstrapLhsp->declp, 0 /* rhsb */, NULL /* callp */);
}

/*****************************************************************************/
static inline marpaESLIF_symbol_t *_marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, char *asciinames, short createb, short forcecreateb, short lhsb, marpaESLIF_lua_functiondecl_t *declp, short rhsb, marpaESLIF_lua_functioncall_t *callp)
/*****************************************************************************/
/* lhsb says we are checking the meta symbol for an LHS                      */
/* rhsb says we are checking the meta symbol for an RHS                      */
/*****************************************************************************/
{
  static const char             *funcs             = "_marpaESLIF_bootstrap_check_meta_by_namep";
  genericStack_t                *symbolStackp      = grammarBootstrapp->symbolStackp;
  marpaESLIF_symbol_t           *symbolp           = NULL;
  marpaESLIF_meta_t             *metap             = NULL;
  marpaESLIF_symbol_t           *symbol_i_p;
  int                            parami;
  int                            i;
  short                          parameterizedRhsb;

  /* It is not legal to have both lhsb and rshb */
  if (lhsb && rhsb) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "lhsb and rhsb are set");
    goto err;
  }

  /* declp is only for lhsb, callp is only for rhsp */
  if (declp != NULL) {
    if (rhsb) {
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "declp is set but this is an rhs context");
      goto err;
    }
    parami            = declp->sizei;
    parameterizedRhsb = 0;
  } else if (callp != NULL) {
    if (lhsb) {
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "callp is set but this is an lhs context");
      goto err;
    }
    parami            = callp->sizei;
    parameterizedRhsb = 1;
    /* We always force the creation of a parameterized RHS, so that is is always a grammar terminal */
    forcecreateb      = 1;
  } else {
    parami = -1;
    parameterizedRhsb = 0;
  }
  
  for (i = 0; i < GENERICSTACK_USED(symbolStackp); i++) {
    MARPAESLIF_INTERNAL_GET_SYMBOL_FROM_STACK(marpaESLIFValuep->marpaESLIFp, symbol_i_p, symbolStackp, i);
    if (symbol_i_p->type != MARPAESLIF_SYMBOL_TYPE_META) {
      continue;
    }
    if (strcmp(symbol_i_p->u.metap->asciinames, asciinames) == 0) {
      /* We do not want to reuse a parameterized RHS that would match the name if we are in an LHS context */
      if ((! lhsb) || (! symbol_i_p->parameterizedRhsb)) {
	symbolp = symbol_i_p;
	break;
      }
    }
  }

  /* If symbol already exist but with a different number of parameters, this is incoherent unless we are in the generator action context */
  if ((symbolp != NULL) && (symbolp->parami != parami) && (strcmp(asciinames, ".") != 0)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Symbol %s is defined multiple times with different number of parameters (%d != %d)", asciinames, symbolp->parami, parami);
    symbolp = NULL;
    goto err;
  }

  if (forcecreateb || (createb && (symbolp == NULL))) {

    metap = _marpaESLIF_meta_newp(marpaESLIFValuep->marpaESLIFp, grammarBootstrapp->marpaWrapperGrammarStartp, MARPAWRAPPERGRAMMAR_EVENTTYPE_NONE, asciinames, NULL /* descEncodings */, NULL /* descs */, 0 /* descl */, 0 /* lazyb */);
    if (MARPAESLIF_UNLIKELY(metap == NULL)) {
      goto err;
    }

    MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Creating meta symbol %s in grammar level %d", metap->descp->asciis, grammarBootstrapp->leveli);
    symbolp = _marpaESLIF_symbol_newp(marpaESLIFValuep->marpaESLIFp, NULL /* marpaESLIFSymbolOptionp */);
    if (MARPAESLIF_UNLIKELY(symbolp == NULL)) {
      goto err;
    }
    symbolp->type              = MARPAESLIF_SYMBOL_TYPE_META;
    symbolp->parami            = parami;
    symbolp->u.metap           = metap;
    symbolp->idi               = metap->idi;
    symbolp->descp             = metap->descp;
    symbolp->parameterizedRhsb = parameterizedRhsb;
    metap = NULL; /* metap is now in symbolp */

    GENERICSTACK_SET_PTR(grammarBootstrapp->symbolStackp, symbolp, symbolp->idi);
    if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(grammarBootstrapp->symbolStackp))) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "symbolStackp push failure, %s", strerror(errno));
      goto err;
    }
  }

  goto done;

 err:
  _marpaESLIF_meta_freev(metap);
  _marpaESLIF_symbol_freev(symbolp);
  symbolp = NULL;

 done:
  return symbolp;
}

/*****************************************************************************/
static inline short _marpaESLIF_bootstrap_search_terminal_by_descriptionb(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_terminal_type_t terminalType, marpaESLIF_bootstrap_utf_string_t *stringp, marpaESLIF_symbol_t **symbolpp)
/*****************************************************************************/
{
  genericStack_t        *symbolStackp          = grammarBootstrapp->symbolStackp;
  marpaESLIF_symbol_t   *symbolp               = NULL;
  marpaESLIF_terminal_t *terminalp             = NULL;
  marpaESLIF_terminal_t *substitutionTerminalp = NULL;
  marpaESLIF_symbol_t   *symbol_i_p;
  int                    i;
  short                  rcb;

  /* Create a fake terminal (it has existence only in memory) - the description is the content itself */
  /* If there is a substitution then the terminal must be a regex. */
  terminalp = _marpaESLIF_terminal_newp(marpaESLIFValuep->marpaESLIFp,
                                        NULL, /* marpaWrapperGrammarStartp: this is what make the terminal only in memory */
                                        MARPAWRAPPERGRAMMAR_EVENTTYPE_NONE,
                                        (char *) _marpaESLIF_bootstrap_descEncodingInternals,
                                        (char *) _marpaESLIF_bootstrap_descInternals,
                                        _marpaESLIF_bootstrap_descInternall,
                                        terminalType,
                                        stringp->modifiers,
                                        stringp->bytep,
                                        stringp->bytel,
                                        NULL, /* testFullMatchs */
                                        NULL, /* testPartialMatchs */
                                        0, /* pseudob */
                                        0, /* characterClassb */
                                        (stringp->substitutionBytep != NULL) ? MARPAESLIF_TERMINAL_TYPE_REGEX : MARPAESLIF_TERMINAL_TYPE_NA, /* wantType */
                                        0 /* substitutionb */);
  if (MARPAESLIF_UNLIKELY(terminalp == NULL)) {
    goto err;
  }

  /* Idem if there is a substition - can happen only with regular expressions */
  if (stringp->substitutionBytep != NULL) {
    substitutionTerminalp = _marpaESLIF_terminal_newp(marpaESLIFValuep->marpaESLIFp,
                                                      NULL, /* marpaWrapperGrammarStartp: this is what make the terminal only in memory */
                                                      MARPAWRAPPERGRAMMAR_EVENTTYPE_NONE,
                                                      (char *) _marpaESLIF_bootstrap_descEncodingInternals,
                                                      (char *) _marpaESLIF_bootstrap_descInternals,
                                                      _marpaESLIF_bootstrap_descInternall,
                                                      MARPAESLIF_TERMINAL_TYPE_STRING, /* terminalType */
                                                      stringp->substitutionModifiers,
                                                      stringp->substitutionBytep,
                                                      stringp->substitutionBytel,
                                                      NULL, /* testFullMatchs */
                                                      NULL, /* testPartialMatchs */
                                                      0, /* pseudob */
                                                      0, /* characterClassb */
                                                      MARPAESLIF_TERMINAL_TYPE_NA, /* wantType */
                                                      1 /* substitutionb */);
    if (MARPAESLIF_UNLIKELY(substitutionTerminalp == NULL)) {
      goto err;
    }
  }

  for (i = 0; i < GENERICSTACK_USED(symbolStackp); i++) {
    MARPAESLIF_INTERNAL_GET_SYMBOL_FROM_STACK(marpaESLIFValuep->marpaESLIFp, symbol_i_p, symbolStackp, i);
    if (symbol_i_p->type != MARPAESLIF_SYMBOL_TYPE_TERMINAL) {
      continue;
    }
    /* Pattern options */
    if (symbol_i_p->u.terminalp->patterni != terminalp->patterni) {
      continue;
    }
    /* Pattern content */
    if (symbol_i_p->u.terminalp->patternl != terminalp->patternl) {
      continue;
    }
    if (memcmp(symbol_i_p->u.terminalp->patterns, terminalp->patterns, terminalp->patternl) != 0) {
      continue;
    }

    if (stringp->substitutionBytep != NULL) {
      /* Substitution pattern options */
      if (symbol_i_p->u.terminalp->substitutionPatterni != substitutionTerminalp->patterni) {
        continue;
      }
      /* Substitution pattern content */
      if (symbol_i_p->u.terminalp->substitutionPatternl != substitutionTerminalp->patternl) {
        continue;
      }
      if (memcmp(symbol_i_p->u.terminalp->substitutionPatterns, substitutionTerminalp->patterns, substitutionTerminalp->patternl) != 0) {
        continue;
      }
    }

    /* Got it */
    symbolp = symbol_i_p;
    break;
  }

  if (symbolpp != NULL) {
    *symbolpp = symbolp;
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  _marpaESLIF_terminal_freev(terminalp);
  _marpaESLIF_terminal_freev(substitutionTerminalp);
  return rcb;
}

/*****************************************************************************/
static inline marpaESLIF_symbol_t *_marpaESLIF_bootstrap_find_terminal_by_namep(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_utf_string_t *stringp)
/*****************************************************************************/
{
  genericStack_t        *symbolStackp = grammarBootstrapp->symbolStackp;
  marpaESLIF_symbol_t   *symbolp      = NULL;
  marpaESLIF_symbol_t   *symbol_i_p;
  int                    i;
  marpaESLIF_string_t    desc;

  desc.bytep          = stringp->bytep;
  desc.bytel          = stringp->bytel;
  desc.encodingasciis = "UTF-8";
  desc.asciis         = NULL;

  for (i = 0; i < GENERICSTACK_USED(symbolStackp); i++) {
    MARPAESLIF_INTERNAL_GET_SYMBOL_FROM_STACK(marpaESLIFValuep->marpaESLIFp, symbol_i_p, symbolStackp, i);
    if (symbol_i_p->type != MARPAESLIF_SYMBOL_TYPE_TERMINAL) {
      continue;
    }
    /* Only terminals that has the name adverb. We detect that by making sure */
    /* that symbolp->descp != symbolp->u.terminalp->descp */
    if (symbol_i_p->descp == symbol_i_p->u.terminalp->descp) {
      continue;
    }
    if (! _marpaESLIF_string_eqb(symbol_i_p->descp, &desc)) {
      continue;
    }
    /* Got it */
    symbolp = symbol_i_p;
    break;
  }

 err: /* When compiled without MARPAESLIF_NTRACE */
  return symbolp;
}

/*****************************************************************************/
static inline short _marpaESLIF_bootstrap_search_terminal_pseudob(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_terminal_type_t terminalType, marpaESLIF_symbol_t **symbolpp)
/*****************************************************************************/
{
  genericStack_t        *symbolStackp = grammarBootstrapp->symbolStackp;
  marpaESLIF_symbol_t   *symbolp      = NULL;
  marpaESLIF_symbol_t   *symbol_i_p;
  int                    i;
  short                  rcb;

  for (i = 0; i < GENERICSTACK_USED(symbolStackp); i++) {
    MARPAESLIF_INTERNAL_GET_SYMBOL_FROM_STACK(marpaESLIFValuep->marpaESLIFp, symbol_i_p, symbolStackp, i);
    if (symbol_i_p->type != MARPAESLIF_SYMBOL_TYPE_TERMINAL) {
      continue;
    }
    if (! symbol_i_p->u.terminalp->pseudob) {
      continue;
    }
    if (symbol_i_p->u.terminalp->type != terminalType) {
      continue;
    }
    /* Got it */
    symbolp = symbol_i_p;
    break;
  }

  if (symbolpp != NULL) {
    *symbolpp = symbolp;
  }

  rcb = 1;
  goto done;

#ifndef MARPAESLIF_NTRACE
err: /* For MARPAESLIF_INTERNAL_GET_SYMBOL_FROM_STACK */
  rcb = 0;
#endif

done:
  return rcb;
}

/*****************************************************************************/
static inline marpaESLIF_symbol_t  *_marpaESLIF_bootstrap_check_terminal_by_typep(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_terminal_type_t terminalType, marpaESLIF_bootstrap_utf_string_t *stringp, short createb, short pseudob, short forcecreateb, char *descEncodings, char *descs, size_t descl, short characterClassb)
/*****************************************************************************/
{
  static const char     *funcs                 = "_marpaESLIF_bootstrap_check_terminal_by_typep";
  marpaESLIF_symbol_t   *symbolp               = NULL;
  marpaESLIF_terminal_t *terminalp             = NULL;
  marpaESLIF_terminal_t *substitutionTerminalp = NULL;
  marpaESLIF_string_t   *descp                 = NULL;

  if (pseudob) {
    if (MARPAESLIF_UNLIKELY(! _marpaESLIF_bootstrap_search_terminal_pseudob(marpaESLIFValuep, grammarBootstrapp, terminalType, &symbolp))) {
      goto err;
    }
  } else {
    if (MARPAESLIF_UNLIKELY(! _marpaESLIF_bootstrap_search_terminal_by_descriptionb(marpaESLIFValuep, grammarBootstrapp, terminalType, stringp, &symbolp))) {
      goto err;
    }
  }

  if (forcecreateb || (createb && (symbolp == NULL))) {
    terminalp = _marpaESLIF_terminal_newp(marpaESLIFValuep->marpaESLIFp,
                                          grammarBootstrapp->marpaWrapperGrammarStartp,
                                          MARPAWRAPPERGRAMMAR_EVENTTYPE_NONE,
                                          descEncodings,
                                          descs,
                                          descl,
                                          terminalType,
                                          pseudob ? NULL : stringp->modifiers,
                                          pseudob ? NULL : stringp->bytep,
                                          pseudob ? 0 : stringp->bytel,
                                          NULL, /* testFullMatchs */
                                          NULL, /* testPartialMatchs */
                                          pseudob,
                                          characterClassb,
                                          ((! pseudob) && (stringp->substitutionBytep != NULL)) ? MARPAESLIF_TERMINAL_TYPE_REGEX : MARPAESLIF_TERMINAL_TYPE_NA, /* wantType */
                                          0 /* substitutionb */);
    if (MARPAESLIF_UNLIKELY(terminalp == NULL)) {
      goto err;
    }
    MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Creating terminal symbol %s in grammar level %d", terminalp->descp->asciis, grammarBootstrapp->leveli);
    
    if ((! pseudob) && (stringp->substitutionBytep != NULL)) {
      substitutionTerminalp = _marpaESLIF_terminal_newp(marpaESLIFValuep->marpaESLIFp,
                                                        grammarBootstrapp->marpaWrapperGrammarStartp,
                                                        MARPAWRAPPERGRAMMAR_EVENTTYPE_NONE,
                                                        NULL, /* descEncodings */
                                                        NULL, /* descs */
                                                        0, /* descl */
                                                        MARPAESLIF_TERMINAL_TYPE_STRING,
                                                        stringp->substitutionModifiers,
                                                        stringp->substitutionBytep,
                                                        stringp->substitutionBytel,
                                                        NULL, /* testFullMatchs */
                                                        NULL, /* testPartialMatchs */
                                                        0, /* pseudob */
                                                        0, /* characterClassb */
                                                        MARPAESLIF_TERMINAL_TYPE_NA, /* wantType */
                                                        1 /* substitutionb */);
      if (MARPAESLIF_UNLIKELY(substitutionTerminalp == NULL)) {
        goto err;
      }
      MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Creating substitution terminal symbol %s in grammar level %d", substitutionTerminalp->descp->asciis, grammarBootstrapp->leveli);
    }

    symbolp = _marpaESLIF_symbol_newp(marpaESLIFValuep->marpaESLIFp, NULL /* marpaESLIFSymbolOptionp */);
    if (MARPAESLIF_UNLIKELY(symbolp == NULL)) {
      goto err;
    }
    symbolp->type        = MARPAESLIF_SYMBOL_TYPE_TERMINAL;
    symbolp->u.terminalp = terminalp;
    symbolp->idi         = terminalp->idi;
    symbolp->descp       = terminalp->descp;
    terminalp = NULL; /* terminalp is now in symbolp */

    if ((! pseudob) && (stringp->substitutionBytep != NULL)) {
      descp = _marpaESLIF_terminal_add_substitution_desc_to_terminal_descp(marpaESLIFValuep->marpaESLIFp, symbolp->u.terminalp, substitutionTerminalp);
      if (descp == NULL) {
	goto err;
      }

      /* Replace description */
      _marpaESLIF_string_freev(symbolp->u.terminalp->descp, 0 /* onStackb */);
      symbolp->descp = symbolp->u.terminalp->descp = descp;
      descp = NULL; /* descp is now in symbolp->u.terminalp */
    }

    GENERICSTACK_SET_PTR(grammarBootstrapp->symbolStackp, symbolp, symbolp->idi);
    if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(grammarBootstrapp->symbolStackp))) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "symbolStackp push failure, %s", strerror(errno));
      goto err;
    }
  }

  goto done;
  
 err:
  _marpaESLIF_terminal_freev(terminalp);
  _marpaESLIF_terminal_freev(substitutionTerminalp);
  _marpaESLIF_symbol_freev(symbolp);
  _marpaESLIF_string_freev(descp, 0 /* onStackb */);
  symbolp = NULL;

 done:
  return symbolp;
}

/*****************************************************************************/
static inline marpaESLIF_symbol_t *_marpaESLIF_bootstrap_check_quotedStringp(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_utf_string_t *quotedStringp, short createb, short forcecreateb)
/*****************************************************************************/
{
  return _marpaESLIF_bootstrap_check_terminal_by_typep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, MARPAESLIF_TERMINAL_TYPE_STRING, quotedStringp, createb, 0 /* pseudob */, forcecreateb, NULL /* descEncodings */, NULL /* descs */, 0 /* descl */, 0 /* characterClassb */);
}

/*****************************************************************************/
static inline marpaESLIF_symbol_t  *_marpaESLIF_bootstrap_check_builtinp(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_terminal_type_t type, short createb, short forcecreateb)
/*****************************************************************************/
{
  marpaESLIF_symbol_t *symbolp;

  switch (type) {
  case MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__EOF:
    symbolp = _marpaESLIF_bootstrap_check_terminal_by_typep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, MARPAESLIF_TERMINAL_TYPE__EOF, NULL, createb, 1 /* pseudob */, forcecreateb, NULL /* descEncodings */, NULL /* descs */, 0 /* descl */, 0 /* characterClassb */);
    if (symbolp != NULL) {
      /* Remember that the grammar has :eof somewhere */
      grammarBootstrapp->marpaESLIFGrammarBootstrapp->hasPseudoTerminalb = 1;
      grammarBootstrapp->marpaESLIFGrammarBootstrapp->hasEofPseudoTerminalb = 1;
    }
    break;

  case MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__EOL:
    symbolp = _marpaESLIF_bootstrap_check_terminal_by_typep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, MARPAESLIF_TERMINAL_TYPE__EOL, NULL, createb, 1 /* pseudob */, forcecreateb, NULL /* descEncodings */, NULL /* descs */, 0 /* descl */, 0 /* characterClassb */);
    if (symbolp != NULL) {
      /* Remember that the grammar has :eol somewhere */
      grammarBootstrapp->marpaESLIFGrammarBootstrapp->hasPseudoTerminalb = 1;
      grammarBootstrapp->marpaESLIFGrammarBootstrapp->hasEolPseudoTerminalb = 1;
    }
    break;

  case MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__SOL:
    symbolp = _marpaESLIF_bootstrap_check_terminal_by_typep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, MARPAESLIF_TERMINAL_TYPE__SOL, NULL, createb, 1 /* pseudob */, forcecreateb, NULL /* descEncodings */, NULL /* descs */, 0 /* descl */, 0 /* characterClassb */);
    if (symbolp != NULL) {
      /* Remember that the grammar has :sol somewhere */
      grammarBootstrapp->marpaESLIFGrammarBootstrapp->hasPseudoTerminalb = 1;
      grammarBootstrapp->marpaESLIFGrammarBootstrapp->hasSolPseudoTerminalb = 1;
    }
    break;

  case MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__EMPTY:
    symbolp = _marpaESLIF_bootstrap_check_terminal_by_typep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, MARPAESLIF_TERMINAL_TYPE__EMPTY, NULL, createb, 1 /* pseudob */, forcecreateb, NULL /* descEncodings */, NULL /* descs */, 0 /* descl */, 0 /* characterClassb */);
    if (symbolp != NULL) {
      /* Remember that the grammar has :sol somewhere */
      grammarBootstrapp->marpaESLIFGrammarBootstrapp->hasPseudoTerminalb = 1;
      grammarBootstrapp->marpaESLIFGrammarBootstrapp->hasEmptyPseudoTerminalb = 1;
    }
    break;

  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unsupported terminal builtin type %d", type);
    symbolp = NULL;
    break;
  }

  return symbolp;
}

/*****************************************************************************/
static inline marpaESLIF_symbol_t *_marpaESLIF_bootstrap_check_regexp(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_utf_string_t *regexp, short createb, short forcecreateb, short characterClassb)
/*****************************************************************************/
{
  return _marpaESLIF_bootstrap_check_terminal_by_typep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, MARPAESLIF_TERMINAL_TYPE_REGEX, regexp, createb, 0 /* pseudob */, forcecreateb, NULL /* descEncodings */, NULL /* descs */, 0 /* descl */, characterClassb);
}

/*****************************************************************************/
static inline marpaESLIF_symbol_t *_marpaESLIF_bootstrap_check_singleSymbolp(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_single_symbol_t *singleSymbolp, short createb, short forcecreateb, short lhsb, marpaESLIF_lua_functiondecl_t *declp, short rhsb, marpaESLIF_lua_functioncall_t *callp)
/*****************************************************************************/
{
  marpaESLIF_symbol_t *symbolp = NULL;

  switch (singleSymbolp->type) {
  case MARPAESLIF_BOOTSTRAP_SINGLE_SYMBOL_TYPE_SYMBOL:
    symbolp = _marpaESLIF_bootstrap_check_symbolp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, singleSymbolp->u.symbolp, createb, forcecreateb, lhsb, declp, rhsb, callp);
    break;
  case MARPAESLIF_BOOTSTRAP_SINGLE_SYMBOL_TYPE_TERMINAL:
    symbolp = _marpaESLIF_bootstrap_check_terminalp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, singleSymbolp->u.terminalp, createb, forcecreateb, lhsb, declp, rhsb, callp);
    if ((symbolp != NULL) && (callp != NULL)) {
      /* A terminal cannot be parameterized */
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Terminal %s%s%s cannot be parameterized", symbolp->descp->asciis, callp->luaexplistcb ? "-->" : "->", callp->luaexplists);
      goto err;
    }
    break;
  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unsupported singleSymbolp->type = %d", singleSymbolp->type);
    goto err;
  }

  goto done;
  
 err:
  symbolp = NULL;

 done:
  return symbolp;
}

/*****************************************************************************/
static inline marpaESLIF_symbol_t *_marpaESLIF_bootstrap_check_symbolp(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_symbol_t *symbolp, short createb, short forcecreateb, short lhsb, marpaESLIF_lua_functiondecl_t *declp, short rhsb, marpaESLIF_lua_functioncall_t *callp)
/*****************************************************************************/
{
  return _marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, symbolp->symbols, createb, forcecreateb, lhsb, declp, rhsb, callp);
}

/*****************************************************************************/
static inline marpaESLIF_symbol_t *_marpaESLIF_bootstrap_check_terminalp(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_terminal_t *terminalp, short createb, short forcecreateb, short lhsb, marpaESLIF_lua_functiondecl_t *declp, short rhsb, marpaESLIF_lua_functioncall_t *callp)
/*****************************************************************************/
{
  marpaESLIF_symbol_t *symbolp = NULL;

  switch (terminalp->type) {
  case MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE_CHARACTER_CLASS:
    symbolp = _marpaESLIF_bootstrap_check_regexp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, terminalp->u.characterClassp, createb, forcecreateb, 1 /* characterClassb */);
    break;
  case MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE_REGULAR_EXPRESSION:
    symbolp = _marpaESLIF_bootstrap_check_regexp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, terminalp->u.regularExpressionp, createb, forcecreateb, 0 /* characterClassb */);
    break;
  case MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE_QUOTED_STRING:
    symbolp = _marpaESLIF_bootstrap_check_quotedStringp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, terminalp->u.stringp, createb, forcecreateb);
    break;
  case MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__EOF:
    symbolp = _marpaESLIF_bootstrap_check_builtinp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, terminalp->type, createb, forcecreateb);
    break;
  case MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__EOL:
    symbolp = _marpaESLIF_bootstrap_check_builtinp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, terminalp->type, createb, forcecreateb);
    break;
  case MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__SOL:
    symbolp = _marpaESLIF_bootstrap_check_builtinp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, terminalp->type, createb, forcecreateb);
    break;
  case MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__EMPTY:
    symbolp = _marpaESLIF_bootstrap_check_builtinp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, terminalp->type, createb, forcecreateb);
    break;
  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unsupported terminalp->type = %d", terminalp->type);
    goto err;
  }

  goto done;
  
 err:
  symbolp = NULL;

 done:
  return symbolp;
}

/*****************************************************************************/
static inline marpaESLIF_symbol_t  *_marpaESLIF_bootstrap_check_rhsAlternativep(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_rhs_alternative_t *rhsAlternativep, short createb, marpaESLIF_lua_functiondecl_t *declp)
/*****************************************************************************/
{
  static const char                  *funcs        = "_marpaESLIF_bootstrap_check_rhsAlternativep";
  marpaESLIF_symbol_t                *symbolp      = NULL;
  marpaESLIF_symbol_t                *lookaheadp   = NULL;
  marpaESLIF_rule_t                  *rulep        = NULL;
  marpaESLIF_symbol_t                *ruledSymbolp;
  char                                tmps[1024];
  marpaESLIF_symbol_t                *rhsp;
  marpaESLIF_symbol_t                *rhsExceptionp;
  marpaESLIF_action_t                *actionp;
  int                                 ranki;
  short                               nullRanksHighb;
  marpaESLIF_bootstrap_utf_string_t  *namingp;
  short                               properb;
  short                               hideseparatorb;
  marpaESLIF_symbol_t                *separatorp;
  marpaESLIF_bootstrap_rhs_primary_t *separatorRhsPrimaryp;

  switch (rhsAlternativep->type) {
  case MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_RHS_PRIMARY:
    symbolp = _marpaESLIF_bootstrap_check_rhsPrimaryp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, rhsAlternativep->u.rhsPrimaryp, createb, 0 /* forcecreateb */);
    break;
  case MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_PRIORITIES:
    /* It is almost exactly like:
       <priority rule>                ::= <lhs> <op declare> <priorities>
       except that <lhs> here is unknown and we create it on the fly.
       <op declare> implicitly correspond to current grammar.
    */
    sprintf(tmps, "Internal[%d]", marpaESLIFGrammarBootstrapp->internalRuleCounti++);
    symbolp = _marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, tmps, 1 /* createb */, 0 /* forcecreateb */, 1 /* lhsb */, declp, 0 /* rhsb */, NULL /* callp */);
    if (MARPAESLIF_UNLIKELY(symbolp == NULL)) {
      goto err;
    }
    if (rhsAlternativep->u.priorities.lookaheadb) {
      /* We let previous symbol alone: this will become a lookahead symbol that is a lexeme and we will force it to point to a new symbol */
      sprintf(tmps, "Internal[%d]", marpaESLIFGrammarBootstrapp->internalRuleCounti++);
      lookaheadp = _marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, tmps, 1 /* createb */, 0 /* forcecreateb */, 1 /* lhsb */, declp, 0 /* rhsb */, NULL /* callp */);
      if (MARPAESLIF_UNLIKELY(symbolp == NULL)) {
        goto err;
      }
      symbolp->lookupLevelDeltai = 0;
      symbolp->lookupSymbolp     = lookaheadp;
      symbolp->lookaheadb        = rhsAlternativep->u.priorities.lookaheadb;

      marpaESLIFGrammarBootstrapp->hasLookaheadMetab = 1;

      ruledSymbolp = lookaheadp;
    } else {
      ruledSymbolp = symbolp;
    }

    if (MARPAESLIF_UNLIKELY(! _marpaESLIF_bootstrap_G1_action_priority_loosen_ruleb(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, ruledSymbolp, rhsAlternativep->u.priorities.alternativesStackp, declp))) {
      goto err;
    }
    break;
  case MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_EXCEPTION:
    /* It is almost exactly like:
       <exception statement> ::= lhs <op declare> <rhs primary> '-' <rhs primary> <adverb list>
       except that <lhs> here is unknown and we create it on the fly.
       <op declare> implicitly correspond to current grammar.
    */
    sprintf(tmps, "Internal[%d]", marpaESLIFGrammarBootstrapp->internalRuleCounti++);
    symbolp = _marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, tmps, 1 /* createb */, 0 /* forcecreateb */, 1 /* lhsb */, declp, 0 /* rhsb */, NULL /* callp */);
    if (MARPAESLIF_UNLIKELY(symbolp == NULL)) {
      goto err;
    }
    if (rhsAlternativep->u.exception.lookaheadb) {
      /* We let previous symbol alone: this will become a lookahead symbol that is a lexeme and we will force it to point to a new symbol */
      sprintf(tmps, "Internal[%d]", marpaESLIFGrammarBootstrapp->internalRuleCounti++);
      lookaheadp = _marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, tmps, 1 /* createb */, 0 /* forcecreateb */, 1 /* lhsb */, declp, 0 /* rhsb */, NULL /* callp */);
      if (MARPAESLIF_UNLIKELY(symbolp == NULL)) {
        goto err;
      }
      symbolp->lookupLevelDeltai = 0;
      symbolp->lookupSymbolp     = lookaheadp;
      symbolp->lookaheadb        = rhsAlternativep->u.exception.lookaheadb;

      marpaESLIFGrammarBootstrapp->hasLookaheadMetab = 1;

      ruledSymbolp = lookaheadp;
    } else {
      ruledSymbolp = symbolp;
    }
    /* Check the rhs primary - we know it has to be a lexeme, and a lexeme cannot be parameterized. */
    if (rhsAlternativep->u.exception.rhsPrimaryp->callp != NULL) {
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Left side of an exception rule cannot be parameterized");
      goto err;
    }
    /* Note that we force the symbol to be unique - this is because the exception is part of the symbol definition */
    rhsp = _marpaESLIF_bootstrap_check_rhsPrimaryp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, rhsAlternativep->u.exception.rhsPrimaryp, 1 /* createb */, 1 /* forcecreateb */);
    if (MARPAESLIF_UNLIKELY(rhsp == NULL)) {
      goto err;
    }
    /* Check the rhs primary exception. */
    if (rhsAlternativep->u.exception.rhsPrimaryExceptionp->callp != NULL) {
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Right side of an exception rule cannot be parameterized");
      goto err;
    }
    rhsExceptionp = _marpaESLIF_bootstrap_check_rhsPrimaryp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, rhsAlternativep->u.exception.rhsPrimaryExceptionp, 1 /* createb */, 0 /* forcecreateb */);
    if (MARPAESLIF_UNLIKELY(rhsExceptionp == NULL)) {
      goto err;
    }
    /* Check the adverb list */
    if (MARPAESLIF_UNLIKELY(! _marpaESLIF_bootstrap_unpack_adverbListItemStackb(marpaESLIFValuep,
                                                                                "exception rule",
                                                                                rhsAlternativep->u.exception.adverbListItemStackp,
                                                                                &actionp,
                                                                                NULL, /* left_associationbp */
                                                                                NULL, /* right_associationbp */
                                                                                NULL, /* group_associationbp */
                                                                                NULL, /* separatorRhsPrimaryp */
                                                                                NULL, /* properbp */
                                                                                NULL, /* verbosebpp */
                                                                                NULL, /* hideseparatorbp */
                                                                                &ranki,
                                                                                &nullRanksHighb,
                                                                                NULL, /* priorityipp */
                                                                                NULL, /* pauseip */
                                                                                NULL, /* latmbp */
                                                                                NULL, /* discardIsFallbackbp */
                                                                                &namingp,
                                                                                NULL, /* symbolactionpp */
                                                                                NULL, /* eventInitializationpp */
                                                                                NULL, /* ifactionpp */
                                                                                NULL, /* regexactionpp */
                                                                                NULL, /* eventactionpp */
                                                                                NULL, /* defaultEncodingsp */
                                                                                NULL /* fallbackEncodings */
                                                                                ))) {
      goto err;
    }
    /* If naming is not NULL, it is guaranteed to be an UTF-8 thingy */
    MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Creating exception rule %s(declp) ::= %s - %s", ruledSymbolp->descp->asciis, rhsp->descp->asciis, rhsExceptionp->descp->asciis);
    rulep = _marpaESLIF_bootstrap_check_rulep(marpaESLIFValuep,
                                              marpaESLIFGrammarBootstrapp,
                                              grammarBootstrapp,
                                              (namingp != NULL) ? (char *) MARPAESLIF_UTF8_STRING : NULL, /* descEncodings */
                                              (namingp != NULL) ? namingp->bytep : NULL, /* descs */
                                              (namingp != NULL) ? namingp->bytel : 0, /* descl */
                                              ruledSymbolp->idi,
                                              1, /* nrhsl */
                                              &(rhsp->idi), /* rhsip */
                                              rhsExceptionp->idi,
                                              ranki,
                                              0, /*nullRanksHighb */
                                              0, /* sequenceb */
                                              0, /* minimumi */
                                              -1, /* separatori */
                                              0, /* properb */
                                              actionp,
                                              0 /* hideseparatorb */,
                                              NULL, /* skipbp */
                                              declp,
                                              NULL, /* callpp - An exception consist only of lexemes, that can never be parameterized */
                                              NULL /* separatorcallp */);
    if (MARPAESLIF_UNLIKELY(rulep == NULL)) {
      goto err;
    }
    GENERICSTACK_SET_PTR(grammarBootstrapp->ruleStackp, rulep, rulep->idi);
    if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(grammarBootstrapp->ruleStackp))) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "ruleStackp set failure, %s", strerror(errno));
      goto err;
    }
    rulep = NULL; /* rulep is in grammarBootstrapp->ruleStackp */
    break;
  case MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_QUANTIFIED:
    /* It is almost exactly like:
       <quantified rule> ::= <lhs> <op declare> <rhs primary> <quantifier> <adverb list>
       except that <lhs> here is unknown and we create it on the fly.
       <op declare> implicitly correspond to current grammar.
    */
    sprintf(tmps, "Internal[%d]", marpaESLIFGrammarBootstrapp->internalRuleCounti++);
    symbolp = _marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, tmps, 1 /* createb */, 0 /* forcecreateb */, 1 /* lhsb */, declp, 0 /* rhsb */, NULL /* callp */);
    if (MARPAESLIF_UNLIKELY(symbolp == NULL)) {
      goto err;
    }
    if (rhsAlternativep->u.quantified.lookaheadb) {
      /* We let previous symbol alone: this will become a lookahead symbol that is a lexeme and we will force it to point to a new symbol */
      sprintf(tmps, "Internal[%d]", marpaESLIFGrammarBootstrapp->internalRuleCounti++);
      lookaheadp = _marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, tmps, 1 /* createb */, 0 /* forcecreateb */, 1 /* lhsb */, declp, 0 /* rhsb */, NULL /* callp */);
      if (MARPAESLIF_UNLIKELY(symbolp == NULL)) {
        goto err;
      }
      symbolp->lookupLevelDeltai = 0;
      symbolp->lookupSymbolp     = lookaheadp;
      symbolp->lookaheadb        = rhsAlternativep->u.quantified.lookaheadb;

      marpaESLIFGrammarBootstrapp->hasLookaheadMetab = 1;

      ruledSymbolp = lookaheadp;
    } else {
      ruledSymbolp = symbolp;
    }
    /* Check the rhs primary */
    rhsp = _marpaESLIF_bootstrap_check_rhsPrimaryp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, rhsAlternativep->u.quantified.rhsPrimaryp, 1 /* createb */, 0 /* forcecreateb */);
    if (MARPAESLIF_UNLIKELY(rhsp == NULL)) {
      goto err;
    }
    /* Check the adverb list */
    if (MARPAESLIF_UNLIKELY(! _marpaESLIF_bootstrap_unpack_adverbListItemStackb(marpaESLIFValuep,
                                                                                "quantified rule",
                                                                                rhsAlternativep->u.quantified.adverbListItemStackp,
                                                                                &actionp,
                                                                                NULL, /* left_associationbp */
                                                                                NULL, /* right_associationbp */
                                                                                NULL, /* group_associationbp */
                                                                                &separatorRhsPrimaryp,
                                                                                &properb,
                                                                                NULL, /* verbosebpp */
                                                                                &hideseparatorb,
                                                                                &ranki,
                                                                                &nullRanksHighb,
                                                                                NULL, /* priorityipp */
                                                                                NULL, /* pauseip */
                                                                                NULL, /* latmbp */
                                                                                NULL, /* discardIsFallbackbp */
                                                                                &namingp,
                                                                                NULL, /* symbolactionsp */
                                                                                NULL, /* eventInitializationpp */
                                                                                NULL, /* ifactionpp */
                                                                                NULL, /* regexactionpp */
                                                                                NULL, /* eventactionpp */
                                                                                NULL, /* defaultEncodingsp */
                                                                                NULL /* fallbackEncodings */
                                                                                ))) {
      goto err;
    }
    if (separatorRhsPrimaryp != NULL) {
      /* Check the separator */
      separatorp = _marpaESLIF_bootstrap_check_rhsPrimaryp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, separatorRhsPrimaryp, 1 /* createb */, 0 /* forcecreateb */);
      if (MARPAESLIF_UNLIKELY(separatorp == NULL)) {
        goto err;
      }
    } else {
      separatorp = NULL;
    }
    /* If naming is not NULL, it is guaranteed to be an UTF-8 thingy */
#ifndef MARPAESLIF_NTRACE
    if (separatorp != NULL) {
      MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Creating alternative rule %s(declp) ::= %s(callp)%s ranki=>%d separator=>%s(separatorcallp) proper=>%d hide-separator=>%d null-ranking=>%s at grammar level %d", ruledSymbolp->descp->asciis, rhsp->descp->asciis, rhsAlternativep->u.quantified.minimumi ? "+" : "*", ranki, separatorp->descp->asciis, (int) properb, (int) hideseparatorb, nullRanksHighb ? "high" : "low", grammarBootstrapp->leveli);
    } else {
      MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Creating alternative rule %s ::= %s%s ranki=>%d null-ranking=>%s at grammar level %d", ruledSymbolp->descp->asciis, rhsp->descp->asciis, rhsAlternativep->u.quantified.minimumi ? "+" : "*", ranki, nullRanksHighb ? "high" : "low", grammarBootstrapp->leveli);
    }
#endif
    rulep = _marpaESLIF_bootstrap_check_rulep(marpaESLIFValuep,
                                              marpaESLIFGrammarBootstrapp,
                                              grammarBootstrapp,
                                              (namingp != NULL) ? (char *) MARPAESLIF_UTF8_STRING : NULL, /* descEncodings */
                                              (namingp != NULL) ? namingp->bytep : NULL, /* descs */
                                              (namingp != NULL) ? namingp->bytel : 0, /* descl */
                                              ruledSymbolp->idi,
                                              1, /* nrhsl */
                                              &(rhsp->idi), /* rhsip */
                                              -1, /* exceptioni */
                                              ranki,
                                              nullRanksHighb,
                                              1, /* sequenceb */
                                              rhsAlternativep->u.quantified.minimumi,
                                              (separatorp != NULL) ? separatorp->idi : -1, /* separatori */
                                              properb,
                                              actionp,
                                              hideseparatorb,
                                              NULL, /* skipbp */
                                              declp,
                                              &(rhsAlternativep->u.quantified.rhsPrimaryp->callp),
                                              (separatorRhsPrimaryp != NULL) ? separatorRhsPrimaryp->callp : NULL);
    if (MARPAESLIF_UNLIKELY(rulep == NULL)) {
      goto err;
    }
    GENERICSTACK_SET_PTR(grammarBootstrapp->ruleStackp, rulep, rulep->idi);
    if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(grammarBootstrapp->ruleStackp))) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "ruleStackp set failure, %s", strerror(errno));
      goto err;
    }
    rulep = NULL; /* rulep is in grammarBootstrapp->ruleStackp */
    break;

  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unsupported RHS alternative type (%d)", rhsAlternativep->type);
    goto err;
  }

  goto done;
  
 err:
  symbolp = NULL;

 done:
  _marpaESLIF_rule_freev(rulep);
  return symbolp;
}

/*****************************************************************************/
static inline marpaESLIF_symbol_t  *_marpaESLIF_bootstrap_check_rhsPrimaryp(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_bootstrap_rhs_primary_t *rhsPrimaryp, short createb, short forcecreateb)
/*****************************************************************************/
{
  marpaESLIF_symbol_t                  *symbolp = NULL;
  marpaESLIF_grammar_bootstrap_t       *referencedGrammarp;
  marpaESLIF_symbol_t                  *referencedSymbolp = NULL;
  marpaESLIF_bootstrap_single_symbol_t  singleSymbol; /* Fake single symbol in case of a "referenced-in-any-grammar" symbol */
  genericStack_t                       *alternativesStackp = NULL;
  int                                   ranki = 0;
  marpaESLIF_rule_t                    *rulep  = NULL;
  short                                 nullRanksHighb = 0;
  short                                 properb = 0;
  short                                 hideseparatorb = 0;
  marpaESLIF_lua_functiondecl_t         call2decl;
  marpaESLIF_lua_functiondecl_t        *call2declp;
  marpaESLIF_action_t                  *generatorActionp = NULL;
  marpaESLIF_string_t                  *stringp = NULL;

  switch (rhsPrimaryp->type) {
  case MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_SINGLE_SYMBOL:
    symbolp = _marpaESLIF_bootstrap_check_singleSymbolp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, rhsPrimaryp->u.singleSymbolp, createb, forcecreateb, 0 /* lhsb */, NULL /* declp */, 1 /* rhsb */, rhsPrimaryp->callp);
    if (MARPAESLIF_UNLIKELY(symbolp == NULL)) {
      goto err;
    }
    break;
  case MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_SYMBOL_AND_REFERENCE:
    /* We want to check if referenced grammar is current grammar */
    switch (rhsPrimaryp->u.symbolAndReferencep->grammarReferencep->type) {
    case MARPAESLIF_BOOTSTRAP_GRAMMAR_REFERENCE_TYPE_STRING:
      referencedGrammarp = _marpaESLIF_bootstrap_check_grammarBootstrapp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, -1, rhsPrimaryp->u.symbolAndReferencep->grammarReferencep->u.quotedStringp);
      if (MARPAESLIF_UNLIKELY(referencedGrammarp == NULL)) {
        goto err;
      }
      break;
    case MARPAESLIF_BOOTSTRAP_GRAMMAR_REFERENCE_TYPE_SIGNED_INTEGER:
      referencedGrammarp = _marpaESLIF_bootstrap_check_grammarBootstrapp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp->leveli + rhsPrimaryp->u.symbolAndReferencep->grammarReferencep->u.signedIntegeri, NULL);
      if (MARPAESLIF_UNLIKELY(referencedGrammarp == NULL)) {
        goto err;
      }
      break;
    case MARPAESLIF_BOOTSTRAP_GRAMMAR_REFERENCE_TYPE_UNSIGNED_INTEGER:
      referencedGrammarp = _marpaESLIF_bootstrap_check_grammarBootstrapp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, (int) rhsPrimaryp->u.symbolAndReferencep->grammarReferencep->u.unsignedIntegeri, NULL);
      if (MARPAESLIF_UNLIKELY(referencedGrammarp == NULL)) {
        goto err;
      }
      break;
    default:
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unsupported grammar reference type (%d)", rhsPrimaryp->u.symbolAndReferencep->grammarReferencep->type);
      goto err;
    }

    if (referencedGrammarp != grammarBootstrapp) {
      /* Create a single symbol in the referenced grammar with this number of parameters */
      singleSymbol.type = MARPAESLIF_BOOTSTRAP_SINGLE_SYMBOL_TYPE_SYMBOL;
      singleSymbol.u.symbolp = rhsPrimaryp->u.symbolAndReferencep->symbolp;
      if (rhsPrimaryp->callp != NULL) {
        call2decl.luaparlists  = NULL;
        call2decl.luaparlistcb = 0;
        call2decl.sizei        = rhsPrimaryp->callp->sizei;
        call2declp             = &call2decl;
      } else {
        call2declp = NULL;
      }
    
      referencedSymbolp = _marpaESLIF_bootstrap_check_singleSymbolp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, referencedGrammarp, &singleSymbol, 1 /* createb */, forcecreateb, 1 /* lhsb */, call2declp, 0 /* rhsb */, NULL /* callp */);
      if (MARPAESLIF_UNLIKELY(referencedSymbolp == NULL)) {
        goto err;
      }

      /* Create the symbol in the current grammar */
      singleSymbol.type = MARPAESLIF_BOOTSTRAP_SINGLE_SYMBOL_TYPE_NA;
      singleSymbol.u.symbolp = (marpaESLIF_bootstrap_symbol_t *) malloc(sizeof(marpaESLIF_bootstrap_symbol_t));
      if (MARPAESLIF_UNLIKELY(singleSymbol.u.symbolp == NULL)) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
        goto err;
      }
      singleSymbol.type = MARPAESLIF_BOOTSTRAP_SINGLE_SYMBOL_TYPE_SYMBOL;
      singleSymbol.u.symbolp->symbols = strdup(rhsPrimaryp->u.symbolAndReferencep->symbolp->symbols);
      if (singleSymbol.u.symbolp->symbols == NULL) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "strdup failure, %s", strerror(errno));
        goto err;
      }
      symbolp = _marpaESLIF_bootstrap_check_singleSymbolp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, &singleSymbol, 1 /* createb */, forcecreateb, 0 /* lhsb */, NULL, 1 /* rhsb */, rhsPrimaryp->callp);
      _marpaESLIF_bootstrap_symbol_freev(singleSymbol.u.symbolp);
      if (MARPAESLIF_UNLIKELY(symbolp == NULL)) {
        goto err;
      }
      /* We overwrite reference grammar information */
      symbolp->lookupLevelDeltai = referencedGrammarp->leveli - grammarBootstrapp->leveli;
      /* By definition looked up reference symbol is a meta symbol */
      symbolp->lookupSymbolp     = referencedSymbolp;
    }
    break;
  case MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_GENERATOR_ACTION:
    /* Clone action */
    generatorActionp = _marpaESLIF_action_clonep(marpaESLIFValuep->marpaESLIFp, rhsPrimaryp->u.generatorActionp);
    if (generatorActionp == NULL) {
      goto err;
    }
    /* Note that, by definition, callp is not NULL: this is a parameterized RHS */
    symbolp = _marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, ".", 1 /* createb */, 0 /* forcecreateb */, 0 /* lhsb */, NULL /* declp */, 1 /* rhsb */, rhsPrimaryp->callp);
    if (MARPAESLIF_UNLIKELY(symbolp == NULL)) {
      goto err;
    }
    /* Remember the associated generator action */
    symbolp->generatorActionp = generatorActionp;
    generatorActionp = NULL;
    break;
  case MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_NAME:
    symbolp = _marpaESLIF_bootstrap_find_terminal_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, &(rhsPrimaryp->u.name));
    if (MARPAESLIF_UNLIKELY(symbolp == NULL)) {
      /* Try to get an ASCII string from it */
      stringp = _marpaESLIF_string_newp(marpaESLIFValuep->marpaESLIFp, (char *) MARPAESLIF_UTF8_STRING, rhsPrimaryp->u.name.bytep, rhsPrimaryp->u.name.bytel);
      if (stringp != NULL) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "No terminal previously defined with name %s", stringp->asciis);
      } else {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "No terminal previously defined with name ? (Internal error when computing name for logging)", stringp->asciis);
      }
      goto err;
    }
    break;
  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unsupported RHS primary type (%d)", rhsPrimaryp->type);
    goto err;
  }

  goto done;
  
 err:
  symbolp = NULL;

 done:
  _marpaESLIF_action_freev(generatorActionp);
  _marpaESLIF_string_freev(stringp, 0 /* onStackb */);
  return symbolp;
}

/*****************************************************************************/
static inline short _marpaESLIF_bootstrap_unpack_adverbListItemStackb(marpaESLIFValue_t                            *marpaESLIFValuep,
                                                                      char                                         *contexts,
                                                                      genericStack_t                               *adverbListItemStackp,
                                                                      marpaESLIF_action_t                        **actionpp,
                                                                      short                                        *left_associationbp,
                                                                      short                                        *right_associationbp,
                                                                      short                                        *group_associationbp,
                                                                      marpaESLIF_bootstrap_rhs_primary_t         **separatorRhsPrimarypp,
                                                                      short                                        *properbp,
                                                                      short                                       **verbosebpp,
                                                                      short                                        *hideseparatorbp,
                                                                      int                                          *rankip,
                                                                      short                                        *nullRanksHighbp,
                                                                      int                                         **priorityipp,
                                                                      marpaESLIF_bootstrap_pause_type_t            *pauseip,
                                                                      short                                        *latmbp,
                                                                      short                                        *discardIsFallbackbp,
                                                                      marpaESLIF_bootstrap_utf_string_t           **namingpp,
                                                                      marpaESLIF_action_t                         **symbolactionpp,
                                                                      marpaESLIF_bootstrap_event_initialization_t **eventInitializationpp,
                                                                      marpaESLIF_action_t                         **ifactionpp,
                                                                      marpaESLIF_action_t                         **regexactionpp,
                                                                      marpaESLIF_action_t                         **eventactionpp,
                                                                      char                                        **defaultEncodingsp,
                                                                      char                                        **fallbackEncodingsp
                                                                      )
/*****************************************************************************/
{
  int                                      adverbListItemi;
  marpaESLIF_bootstrap_adverb_list_item_t *adverbListItemp;
  short                                    rcb;

  /* Initialisations */
  if (actionpp != NULL) {
    *actionpp = NULL;
  }
  if (left_associationbp != NULL) {
    *left_associationbp = 0;
  }
  if (right_associationbp != NULL) {
    *right_associationbp = 0;
  }
  if (group_associationbp != NULL) {
    *group_associationbp = 0;
  }
  if (separatorRhsPrimarypp != NULL) {
    *separatorRhsPrimarypp = NULL;
  }
  if (properbp != NULL) {
    *properbp = 0;
  }
  if (verbosebpp != NULL) {
    *verbosebpp = NULL;
  }
  if (hideseparatorbp != NULL) {
    *hideseparatorbp = 0;
  }
  if (rankip != NULL) {
    *rankip = 0;
  }
  if (nullRanksHighbp != NULL) {
    *nullRanksHighbp = 0;
  }
  if (priorityipp != NULL) {
    *priorityipp = NULL;
  }
  if (pauseip != NULL) {
    *pauseip = MARPAESLIF_BOOTSTRAP_PAUSE_TYPE_NA;
  }
  if (latmbp != NULL) {
    *latmbp = 1; /* Default is TRUE! */
  }
  if (discardIsFallbackbp != NULL) {
    *discardIsFallbackbp = 0;
  }
  if (namingpp != NULL) {
    *namingpp = NULL;
  }
  if (symbolactionpp != NULL) {
    *symbolactionpp = NULL;
  }
  if (eventInitializationpp != NULL) {
    *eventInitializationpp = NULL;
  }
  if (ifactionpp != NULL) {
    *ifactionpp = NULL;
  }
  if (regexactionpp != NULL) {
    *regexactionpp = NULL;
  }
  if (eventactionpp != NULL) {
    *eventactionpp = NULL;
  }
  if (defaultEncodingsp != NULL) {
    *defaultEncodingsp = NULL;
  }
  if (fallbackEncodingsp != NULL) {
    *fallbackEncodingsp = NULL;
  }

  if (adverbListItemStackp != NULL) {
    for (adverbListItemi = 0; adverbListItemi < GENERICSTACK_USED(adverbListItemStackp); adverbListItemi++) {
#ifndef MARPAESLIF_NTRACE
      /* Should never happen */
      if (MARPAESLIF_UNLIKELY(! GENERICSTACK_IS_PTR(adverbListItemStackp, adverbListItemi))) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "adverbListItemStackp at indice %d is not PTR (got %s, value %d)", adverbListItemi, _marpaESLIF_genericStack_i_types(adverbListItemStackp, adverbListItemi), GENERICSTACKITEMTYPE(adverbListItemStackp, adverbListItemi));
        goto err;
      }
#endif
      adverbListItemp = (marpaESLIF_bootstrap_adverb_list_item_t *) GENERICSTACK_GET_PTR(adverbListItemStackp, adverbListItemi);
      switch (adverbListItemp->type) {
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_ACTION:
        if (MARPAESLIF_UNLIKELY(actionpp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "action adverb is not allowed in %s context", contexts);
          goto err;
        }
        *actionpp = adverbListItemp->u.actionp;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_LEFT_ASSOCIATION:
        if (MARPAESLIF_UNLIKELY(left_associationbp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "left adverb is not allowed in %s context", contexts);
          goto err;
        }
        *left_associationbp = adverbListItemp->u.left_associationb;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_RIGHT_ASSOCIATION:
        if (MARPAESLIF_UNLIKELY(right_associationbp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "right adverb is not allowed in %s context", contexts);
          goto err;
        }
        *right_associationbp = adverbListItemp->u.right_associationb;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_GROUP_ASSOCIATION:
        if (MARPAESLIF_UNLIKELY(group_associationbp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "group adverb is not allowed in %s context", contexts);
          goto err;
        }
        *group_associationbp = adverbListItemp->u.group_associationb;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_SEPARATOR:
        if (MARPAESLIF_UNLIKELY(separatorRhsPrimarypp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "separator adverb is not allowed in %s context", contexts);
          goto err;
        }
        *separatorRhsPrimarypp = adverbListItemp->u.separatorRhsPrimaryp;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_PROPER:
        if (MARPAESLIF_UNLIKELY(properbp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "proper adverb is not allowed in %s context", contexts);
          goto err;
        }
        *properbp = adverbListItemp->u.properb;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_VERBOSE:
        if (MARPAESLIF_UNLIKELY(verbosebpp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "verbose adverb is not allowed in %s context", contexts);
          goto err;
        }
        *verbosebpp = &(adverbListItemp->u.verboseb);
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_HIDESEPARATOR:
        if (MARPAESLIF_UNLIKELY(hideseparatorbp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "hide-separator adverb is not allowed in %s context", contexts);
          goto err;
        }
        *hideseparatorbp = adverbListItemp->u.hideseparatorb;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_RANK:
        if (MARPAESLIF_UNLIKELY(rankip == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "rank adverb is not allowed in %s context", contexts);
          goto err;
        }
        *rankip = adverbListItemp->u.ranki;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_NULL_RANKING:
        if (MARPAESLIF_UNLIKELY(nullRanksHighbp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "null-ranking adverb is not allowed in %s context", contexts);
          goto err;
        }
        *nullRanksHighbp = adverbListItemp->u.nullRanksHighb;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_PRIORITY:
        if (MARPAESLIF_UNLIKELY(priorityipp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "priority adverb is not allowed in %s context", contexts);
          goto err;
        }
        *priorityipp = &(adverbListItemp->u.priorityi);
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_PAUSE:
        if (MARPAESLIF_UNLIKELY(pauseip == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "pause adverb is not allowed in %s context", contexts);
          goto err;
        }
        *pauseip = adverbListItemp->u.pausei;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_LATM:
        if (MARPAESLIF_UNLIKELY(latmbp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "latm or forgiving adverb is not allowed in %s context", contexts);
          goto err;
        }
        *latmbp = adverbListItemp->u.latmb;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_DISCARD_IS_FALLBACK:
        if (MARPAESLIF_UNLIKELY(discardIsFallbackbp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "discard-is-fallback adverb is not allowed in %s context", contexts);
          goto err;
        }
        *discardIsFallbackbp = adverbListItemp->u.discardIsFallbackb;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_NAMING:
        if (MARPAESLIF_UNLIKELY(namingpp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "name adverb is not allowed in %s context", contexts);
          goto err;
        }
        *namingpp = adverbListItemp->u.namingp;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_SYMBOLACTION:
        if (MARPAESLIF_UNLIKELY(symbolactionpp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "symbol-action adverb is not allowed in %s context", contexts);
          goto err;
        }
        *symbolactionpp = adverbListItemp->u.symbolactionp;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_EVENT_INITIALIZATION:
        if (MARPAESLIF_UNLIKELY(eventInitializationpp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "event adverb is not allowed in %s context", contexts);
          goto err;
        }
        *eventInitializationpp = adverbListItemp->u.eventInitializationp;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_IFACTION:
        if (MARPAESLIF_UNLIKELY(ifactionpp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "if-action adverb is not allowed in %s context", contexts);
          goto err;
        }
        *ifactionpp = adverbListItemp->u.ifactionp;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_REGEXACTION:
        if (MARPAESLIF_UNLIKELY(regexactionpp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "regex-action adverb is not allowed in %s context", contexts);
          goto err;
        }
        *regexactionpp = adverbListItemp->u.regexactionp;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_EVENTACTION:
        if (MARPAESLIF_UNLIKELY(eventactionpp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "event-action adverb is not allowed in %s context", contexts);
          goto err;
        }
        *eventactionpp = adverbListItemp->u.eventactionp;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_DEFAULTENCODING:
        if (MARPAESLIF_UNLIKELY(defaultEncodingsp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "default-encoding adverb is not allowed in %s context", contexts);
          goto err;
        }
        *defaultEncodingsp = adverbListItemp->u.defaultEncodings;
        break;
      case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_FALLBACKENCODING:
        if (MARPAESLIF_UNLIKELY(fallbackEncodingsp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "fallback-encoding adverb is not allowed in %s context", contexts);
          goto err;
        }
        *fallbackEncodingsp = adverbListItemp->u.fallbackEncodings;
        break;
      default:
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "adverbListItemStackp type at indice %d is not supported (value %d)", adverbListItemi, adverbListItemp->type);
        goto err;
      }
    }
  }
  rcb = 1;
  goto done;
 err:
  rcb = 0;
 done:
  return rcb;
}

/*****************************************************************************/
static inline void _marpaESLIF_bootstrap_adverb_list_item_freev(marpaESLIF_bootstrap_adverb_list_item_t *adverbListItemp)
/*****************************************************************************/
{
  if (adverbListItemp != NULL) {
    switch (adverbListItemp->type) {
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_ACTION:
      _marpaESLIF_action_freev(adverbListItemp->u.actionp);
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_LEFT_ASSOCIATION:
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_RIGHT_ASSOCIATION:
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_GROUP_ASSOCIATION:
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_SEPARATOR:
      _marpaESLIF_bootstrap_rhs_primary_freev(adverbListItemp->u.separatorRhsPrimaryp);
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_PROPER:
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_VERBOSE:
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_HIDESEPARATOR:
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_RANK:
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_NULL_RANKING:
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_PRIORITY:
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_PAUSE:
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_LATM:
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_DISCARD_IS_FALLBACK:
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_NAMING:
      _marpaESLIF_bootstrap_utf_string_freev(adverbListItemp->u.namingp, 0 /* onStackb */);
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_SYMBOLACTION:
      _marpaESLIF_action_freev(adverbListItemp->u.symbolactionp);
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_EVENT_INITIALIZATION:
      _marpaESLIF_bootstrap_event_initialization_freev(adverbListItemp->u.eventInitializationp);
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_IFACTION:
      _marpaESLIF_action_freev(adverbListItemp->u.ifactionp);
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_REGEXACTION:
      _marpaESLIF_action_freev(adverbListItemp->u.regexactionp);
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_EVENTACTION:
      _marpaESLIF_action_freev(adverbListItemp->u.eventactionp);
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_DEFAULTENCODING:
      free(adverbListItemp->u.defaultEncodings);
      break;
    case MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_FALLBACKENCODING:
      free(adverbListItemp->u.fallbackEncodings);
      break;
    default:
      break;
    }
    free(adverbListItemp);
  }
}

/*****************************************************************************/
static void _marpaESLIF_bootstrap_freeDefaultActionv(void *userDatavNotUsedp, marpaESLIFValueResult_t *marpaESLIFValueResultp)
/*****************************************************************************/
{
  if      (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_OP_DECLARE                      ) { }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_SYMBOL_NAME                     ) { free(marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_RHS_PRIMARY                     ) { _marpaESLIF_bootstrap_rhs_primary_freev((marpaESLIF_bootstrap_rhs_primary_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_LUA_FUNCTIONCALL                ) { _marpaESLIF_lua_functioncall_freev((marpaESLIF_lua_functioncall_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_LUA_FUNCTIONDECL                ) { _marpaESLIF_lua_functiondecl_freev((marpaESLIF_lua_functiondecl_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_RHS_ALTERNATIVE                 ) { _marpaESLIF_bootstrap_rhs_alternative_freev((marpaESLIF_bootstrap_rhs_alternative_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_RHS                             ) { _marpaESLIF_bootstrap_rhs_freev((genericStack_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_LHS                             ) { _marpaESLIF_bootstrap_lhs_freev((marpaESLIF_bootstrap_lhs_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_START_SYMBOL                    ) { _marpaESLIF_bootstrap_start_symbol_freev((marpaESLIF_bootstrap_start_symbol_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_LUA_SYMBOL                      ) { free(marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_ACTION              ) { free(marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_LEFT_ASSOCIATION    ) { }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_RIGHT_ASSOCIATION   ) { }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_GROUP_ASSOCIATION   ) { }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_SEPARATOR           ) { _marpaESLIF_bootstrap_rhs_primary_freev((marpaESLIF_bootstrap_rhs_primary_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_PROPER              ) { }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_VERBOSE             ) { }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_HIDESEPARATOR       ) { }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_RANK                ) { }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_NULL_RANKING        ) { }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_PRIORITY            ) { }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_PAUSE               ) { }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_LATM                ) { }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_DISCARD_IS_FALLBACK ) { }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_NAMING              ) { _marpaESLIF_bootstrap_utf_string_freev((marpaESLIF_bootstrap_utf_string_t *) marpaESLIFValueResultp->u.p.p, 0 /* onStackb */); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_SYMBOLACTION        ) { free(marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_EVENT_INITIALIZATION) { _marpaESLIF_bootstrap_event_initialization_freev((marpaESLIF_bootstrap_event_initialization_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_IFACTION            ) { free(marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_REGEXACTION         ) { free(marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_EVENTACTION         ) { free(marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_DEFAULTENCODING     ) { free(marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_FALLBACKENCODING    ) { free(marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_LIST_ITEMS               ) { _marpaESLIF_bootstrap_adverb_list_items_freev((genericStack_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ALTERNATIVE                     ) { _marpaESLIF_bootstrap_alternative_freev((marpaESLIF_bootstrap_alternative_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ALTERNATIVES                    ) { _marpaESLIF_bootstrap_alternatives_freev((genericStack_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_PRIORITIES                      ) { _marpaESLIF_bootstrap_priorities_freev((genericStack_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_SINGLE_SYMBOL                   ) { _marpaESLIF_bootstrap_single_symbol_freev((marpaESLIF_bootstrap_single_symbol_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_SYMBOL                          ) { _marpaESLIF_bootstrap_symbol_freev((marpaESLIF_bootstrap_symbol_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_TERMINAL                        ) { _marpaESLIF_bootstrap_terminal_freev((marpaESLIF_bootstrap_terminal_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_GRAMMAR_REFERENCE               ) { _marpaESLIF_bootstrap_grammar_reference_freev((marpaESLIF_bootstrap_grammar_reference_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_INACESSIBLE_TREATMENT           ) { }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ON_OR_OFF                       ) { }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_QUANTIFIER                      ) { }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_EVENT_INITIALIZER               ) { }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_EVENT_INITIALIZATION            ) { _marpaESLIF_bootstrap_event_initialization_freev((marpaESLIF_bootstrap_event_initialization_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ALTERNATIVE_NAME                ) { free(marpaESLIFValueResultp->u.a.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ARRAY                           ) { free(marpaESLIFValueResultp->u.a.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_STRING                          ) { _marpaESLIF_string_freev((marpaESLIF_string_t *) marpaESLIFValueResultp->u.p.p, 0 /* onStackb */); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_LUA_FUNCTION                    ) { _marpaESLIF_bootstrap_lua_function_freev((marpaESLIF_bootstrap_lua_function_t *) marpaESLIFValueResultp->u.p.p); }
  else if (marpaESLIFValueResultp->contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ACTION                          ) { _marpaESLIF_action_freev((marpaESLIF_action_t *) marpaESLIFValueResultp->u.p.p); }
  else                                                                                   { }
}

/*****************************************************************************/
static inline marpaESLIF_bootstrap_utf_string_t *_marpaESLIF_bootstrap_unquote_string_literalp(marpaESLIFValue_t *marpaESLIFValuep, void *bytep, size_t bytel, short allowEmptyStringb)
/*****************************************************************************/
{
  static const char                 *funcs = "_marpaESLIF_bootstrap_unquote_string_literalp";
  marpaESLIF_bootstrap_utf_string_t *rcp   = NULL;
  marpaESLIF_bootstrap_utf_string_t rc;
  unsigned char                     *p;

  if (MARPAESLIF_UNLIKELY((bytep == NULL) || (bytel <= 0))) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Invalid quoted string literal: bytep=%p, bytel=%ld", bytep, (unsigned long) bytel);
    goto err;
  }
  p = (unsigned char *) bytep;

  /* Supported cases are:
     "xxx"   " is \x{22}
     'xxx'   ' is \x{27}
     \x{201C}xxx\x{201D} where \x{201C} is LEFT DOUBLE QUOTATION MARK = \x{E2}\x{80}\x{9C}, \x{201D} is RIGHT DOUBLE QUOTATION MARK = \x{E2}\x{80}\x{9D}
   */
  switch (p[0]) {
  case 0x22:
  case 0x27:
    if (MARPAESLIF_UNLIKELY(p[bytel-1] != p[0])) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Invalid quoted string literal closing character 0x%02x instead of 0x%02x", p[bytel-1], p[0]);
      goto err;
    }
    rc.bytep = (char *) ++p;
    rc.bytel = bytel - 2;
    break;
  case 0xE2:
    if (MARPAESLIF_UNLIKELY(bytel <= 6)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Invalid quoted string literal length: %ld <= 6", (unsigned long) bytel);
      goto err;
    }
    if (MARPAESLIF_UNLIKELY((p[1] != 0x80) || (p[2] != 0x9C) || (p[bytel-3] != 0xE2) || (p[bytel-2] != 0x80) || (p[bytel-1] != 0x9D))) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Invalid quoted string literal quotes: 0x%02x0x%02x0x%02x ... 0x%02x0x%02x0x%02x", p[0], p[1], p[2], p[bytel-3], p[bytel-2], p[bytel-1]);
      goto err;
    }
    rc.bytep = (char *) (p + 3);
    rc.bytel = bytel - 6;
    break;
  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Invalid quoted string first byte: 0x%02x", p[0]);
    goto err;
  }

  if (MARPAESLIF_UNLIKELY((rc.bytel <= 0) && !allowEmptyStringb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Empty string is not allowed");
    goto err;
  }
  
  rcp = _marpaESLIF_bootstrap_utf_string_newp(marpaESLIFValuep->marpaESLIFp);
  if (MARPAESLIF_UNLIKELY(rcp == NULL)) {
    goto err;
  }

  rcp->bytel               = rc.bytel;
  rcp->bytep               = (char *) malloc(rc.bytel + 1); /* NUL byte */
  if (MARPAESLIF_UNLIKELY(rcp->bytep == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  if (rc.bytel > 0) {
    memcpy(rcp->bytep, rc.bytep, rc.bytel);
  }
  rcp->bytep[rc.bytel] = '\0';
  goto done;

 err:
  _marpaESLIF_bootstrap_utf_string_freev(rcp, 0 /* onStackb */);
  rcp = NULL;

 done:
  return rcp;
}

/*****************************************************************************/
static marpaESLIFValueRuleCallback_t _marpaESLIF_bootstrap_ruleActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions)
/*****************************************************************************/
{
  switch (atoi(actions)) {
  case   0: return _marpaESLIF_bootstrap_G1_action_op_declare_1b;
  case   1: return _marpaESLIF_bootstrap_G1_action_op_declare_2b;
  case   2: return _marpaESLIF_bootstrap_G1_action_op_declare_3b;
  case   3: return _marpaESLIF_bootstrap_G1_action_rhsb;
  case   4: return _marpaESLIF_bootstrap_G1_action_adverb_list_itemsb;
  case   5: return _marpaESLIF_bootstrap_G1_action_action_1b;
  case   6: return _marpaESLIF_bootstrap_G1_action_action_2b;
  case   7: return _marpaESLIF_bootstrap_G1_action_action_3b;
  case   8: return _marpaESLIF_bootstrap_G1_action_string_literalb;
  case   9: return _marpaESLIF_bootstrap_G1_action_string_literal_inside_2b;
  case  10: return _marpaESLIF_bootstrap_G1_action_string_literal_inside_3b;
  case  11: return _marpaESLIF_bootstrap_G1_action_string_literal_inside_4b;
  case  12: return _marpaESLIF_bootstrap_G1_action_string_literal_inside_5b;
  case  13: return _marpaESLIF_bootstrap_G1_action_symbolaction_1b;
  case  14: return _marpaESLIF_bootstrap_G1_action_symbolaction_2b;
  case  15: return _marpaESLIF_bootstrap_G1_action_symbolaction_3b;
  case  16: return _marpaESLIF_bootstrap_G1_action_left_associationb;
  case  17: return _marpaESLIF_bootstrap_G1_action_right_associationb;
  case  18: return _marpaESLIF_bootstrap_G1_action_group_associationb;
  case  19: return _marpaESLIF_bootstrap_G1_action_separator_specificationb;
  case  20: return _marpaESLIF_bootstrap_G1_action_symbol_name_1b;
  case  21: return _marpaESLIF_bootstrap_G1_action_symbol_name_2b;
  case  22: return _marpaESLIF_bootstrap_G1_action_rhs_alternative_1b;
  case  23: return _marpaESLIF_bootstrap_G1_action_rhs_alternative_2b;
  case  24: return _marpaESLIF_bootstrap_G1_action_rhs_alternative_3b;
  case  25: return _marpaESLIF_bootstrap_G1_action_rhs_alternative_4b;
  case  26: return _marpaESLIF_bootstrap_G1_action_rhs_alternative_5b;
  case  27: return _marpaESLIF_bootstrap_G1_action_rhs_alternative_6b;
  case  28: return _marpaESLIF_bootstrap_G1_action_rhs_alternative_7b;
  case  29: return _marpaESLIF_bootstrap_G1_action_rhs_alternative_8b;
  case  30: return _marpaESLIF_bootstrap_G1_action_rhs_alternative_9b;
  case  31: return _marpaESLIF_bootstrap_G1_action_rhs_alternative_10b;
  case  32: return _marpaESLIF_bootstrap_G1_action_rhs_primary_no_parameter_1b;
  case  33: return _marpaESLIF_bootstrap_G1_action_rhs_primary_no_parameter_2b;
  case  34: return _marpaESLIF_bootstrap_G1_action_rhs_primary_no_parameter_3b;
  case  35: return _marpaESLIF_bootstrap_G1_action_rhs_primary_2b;
  case  36: return _marpaESLIF_bootstrap_G1_action_rhs_primary_3b;
  case  37: return _marpaESLIF_bootstrap_G1_action_alternativeb;
  case  38: return _marpaESLIF_bootstrap_G1_action_alternativesb;
  case  39: return _marpaESLIF_bootstrap_G1_action_prioritiesb;
  case  40: return _marpaESLIF_bootstrap_G1_action_priority_ruleb;
  case  41: return _marpaESLIF_bootstrap_G1_action_single_symbol_1b;
  case  42: return _marpaESLIF_bootstrap_G1_action_single_symbol_2b;
  case  43: return _marpaESLIF_bootstrap_G1_action_terminal_1b;
  case  44: return _marpaESLIF_bootstrap_G1_action_terminal_2b;
  case  45: return _marpaESLIF_bootstrap_G1_action_terminal_3b;
  case  46: return _marpaESLIF_bootstrap_G1_action_terminal_4b;
  case  47: return _marpaESLIF_bootstrap_G1_action_terminal_5b;
  case  48: return _marpaESLIF_bootstrap_G1_action_terminal_6b;
  case  49: return _marpaESLIF_bootstrap_G1_action_symbolb;
  case  50: return _marpaESLIF_bootstrap_G1_action_grammar_reference_1b;
  case  51: return _marpaESLIF_bootstrap_G1_action_grammar_reference_2b;
  case  52: return _marpaESLIF_bootstrap_G1_action_grammar_reference_3b;
  case  53: return _marpaESLIF_bootstrap_G1_action_inaccessible_treatment_1b;
  case  54: return _marpaESLIF_bootstrap_G1_action_inaccessible_treatment_2b;
  case  55: return _marpaESLIF_bootstrap_G1_action_inaccessible_treatment_3b;
  case  56: return _marpaESLIF_bootstrap_G1_action_inaccessible_statementb;
  case  57: return _marpaESLIF_bootstrap_G1_action_on_or_off_1b;
  case  58: return _marpaESLIF_bootstrap_G1_action_on_or_off_2b;
  case  59: return _marpaESLIF_bootstrap_G1_action_autorank_statementb;
  case  60: return _marpaESLIF_bootstrap_G1_action_quantifier_1b;
  case  61: return _marpaESLIF_bootstrap_G1_action_quantifier_2b;
  case  62: return _marpaESLIF_bootstrap_G1_action_quantified_ruleb;
  case  63: return _marpaESLIF_bootstrap_G1_action_start_ruleb;
  case  64: return _marpaESLIF_bootstrap_G1_action_desc_ruleb;
  case  65: return _marpaESLIF_bootstrap_G1_action_empty_ruleb;
  case  66: return _marpaESLIF_bootstrap_G1_action_default_ruleb;
  case  67: return _marpaESLIF_bootstrap_G1_action_latm_specification_1b;
  case  68: return _marpaESLIF_bootstrap_G1_action_latm_specification_2b;
  case  69: return _marpaESLIF_bootstrap_G1_action_discard_is_fallback_specification_1b;
  case  70: return _marpaESLIF_bootstrap_G1_action_discard_is_fallback_specification_2b;
  case  71: return _marpaESLIF_bootstrap_G1_action_proper_specification_1b;
  case  72: return _marpaESLIF_bootstrap_G1_action_proper_specification_2b;
  case  73: return _marpaESLIF_bootstrap_G1_action_verbose_specification_1b;
  case  74: return _marpaESLIF_bootstrap_G1_action_verbose_specification_2b;
  case  75: return _marpaESLIF_bootstrap_G1_action_hideseparator_specification_1b;
  case  76: return _marpaESLIF_bootstrap_G1_action_hideseparator_specification_2b;
  case  77: return _marpaESLIF_bootstrap_G1_action_rank_specificationb;
  case  78: return _marpaESLIF_bootstrap_G1_action_null_ranking_specification_1b;
  case  79: return _marpaESLIF_bootstrap_G1_action_null_ranking_specification_2b;
  case  80: return _marpaESLIF_bootstrap_G1_action_null_ranking_constant_1b;
  case  81: return _marpaESLIF_bootstrap_G1_action_null_ranking_constant_2b;
  case  82: return _marpaESLIF_bootstrap_G1_action_pause_specification_1b;
  case  83: return _marpaESLIF_bootstrap_G1_action_pause_specification_2b;
  case  84: return _marpaESLIF_bootstrap_G1_action_priority_specificationb;
  case  85: return _marpaESLIF_bootstrap_G1_action_event_initializer_1b;
  case  86: return _marpaESLIF_bootstrap_G1_action_event_initializer_2b;
  case  87: return _marpaESLIF_bootstrap_G1_action_event_initializationb;
  case  88: return _marpaESLIF_bootstrap_G1_action_event_specificationb;
  case  89: return _marpaESLIF_bootstrap_G1_action_lexeme_ruleb;
  case  90: return _marpaESLIF_bootstrap_G1_action_terminal_ruleb;
  case  91: return _marpaESLIF_bootstrap_G1_action_symbol_ruleb;
  case  92: return _marpaESLIF_bootstrap_G1_action_discard_ruleb;
  case  93: return _marpaESLIF_bootstrap_G1_action_completion_event_declaration_1b;
  case  94: return _marpaESLIF_bootstrap_G1_action_completion_event_declaration_2b;
  case  95: return _marpaESLIF_bootstrap_G1_action_nulled_event_declaration_1b;
  case  96: return _marpaESLIF_bootstrap_G1_action_nulled_event_declaration_2b;
  case  97: return _marpaESLIF_bootstrap_G1_action_predicted_event_declaration_1b;
  case  98: return _marpaESLIF_bootstrap_G1_action_predicted_event_declaration_2b;
  case  99: return _marpaESLIF_bootstrap_G1_action_alternative_name_2b;
  case 100: return _marpaESLIF_bootstrap_G1_action_namingb;
  case 101: return _marpaESLIF_bootstrap_G1_action_exception_statementb;
  case 102: return _marpaESLIF_bootstrap_G1_action_luascript_statementb;
  case 103: return _marpaESLIF_bootstrap_G1_action_ifactionb;
  case 104: return _marpaESLIF_bootstrap_G1_action_regexactionb;
  case 105: return _marpaESLIF_bootstrap_G1_action_generatoractionb;
  case 106: return _marpaESLIF_bootstrap_G1_action_eventactionb;
  case 107: return _marpaESLIF_bootstrap_G1_action_defaultencodingb;
  case 108: return _marpaESLIF_bootstrap_G1_action_fallbackencodingb;
  case 109: return _marpaESLIF_bootstrap_G1_action_lua_functionb;
  case 110: return _marpaESLIF_bootstrap_G1_action_lua_functioncallb;
  case 111: return _marpaESLIF_bootstrap_G1_action_lua_functiondeclb;
  case 112: return _marpaESLIF_bootstrap_G1_action_lhs_1b;
  case 113: return _marpaESLIF_bootstrap_G1_action_lhs_2b;
  case 114: return _marpaESLIF_bootstrap_G1_action_start_symbol_1b;
  case 115: return _marpaESLIF_bootstrap_G1_action_start_symbol_2b;
  case 116: return _marpaESLIF_bootstrap_G1_action_terminal_7b;
  case 117: return _marpaESLIF_bootstrap_G1_action_terminal_8b;
  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unsupported action \"%s\"", actions);
    return NULL;
  }
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_symbol_name_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <symbol name>  ::= <bare name> */
  char         *barenames   = NULL;
  char         *asciis; /* bare name is only ASCII letters as per the grammar */
  size_t        asciil;
  short         rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i, asciis, asciil); /* This is a lexeme */

  if (MARPAESLIF_UNLIKELY((asciis == NULL) || (asciil <= 0))) {
    /* Should never happen as per the grammar */
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Null bare name");
    goto err;
  }
  barenames = (char *) malloc(asciil + 1);
  if (MARPAESLIF_UNLIKELY(barenames == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  memcpy(barenames, asciis, asciil);
  barenames[asciil] = '\0';

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_SYMBOL_NAME, barenames);

  rcb = 1;
  goto done;
 err:
  if (barenames != NULL) {
    free(barenames);
  }
  rcb = 0;
 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_symbol_name_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <symbol name>  ::= <bracketed name> */
  char         *bracketednames   = NULL;
  char         *asciis; /* bare name is only ASCII letters as per the grammar */
  size_t        asciil;
  short         rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i, asciis, asciil); /* This is a lexeme */

  if (MARPAESLIF_UNLIKELY((asciis == NULL) || (asciil <= 0))) {
    /* Should never happen as per the grammar */
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Null bare name");
    goto err;
  }
  if (MARPAESLIF_UNLIKELY(asciil < 2)) {
    /* Should never happen neither as per the grammar */
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Length of bare name is %ld", (unsigned long) asciil);
    goto err;
  }
  /* We just remove the '<' and '>' around... */
  bracketednames = (char *) malloc(asciil - 2 + 1);
  if (MARPAESLIF_UNLIKELY(bracketednames == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  strncpy(bracketednames, asciis + 1, asciil - 2);
  bracketednames[asciil - 2] = '\0';

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_SYMBOL_NAME, bracketednames);

  rcb = 1;
  goto done;
 err:
  if (bracketednames != NULL) {
    free(bracketednames);
  }
  rcb = 0;
 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_op_declare_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <op declare> ::= <op declare top grammar> */
  short rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_SET_INT(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_OP_DECLARE, 0 /* ::= is level No 0 */);

  rcb = 1;
  goto done;
 err:
  rcb = 0;
 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_op_declare_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <op declare> ::= <op declare lex grammar> */
  short rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_SET_INT(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_OP_DECLARE, 1 /* ~ is level No 0 */);

  rcb = 1;
  goto done;
 err:
  rcb = 0;
 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_op_declare_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <op declare> ::= <op declare any grammar> */
  char   *asciis; /* <op declare any grammar> is only ASCII letters as per the grammar */
  size_t  asciil;
  short   rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i, asciis, asciil);

  /* <op declare any grammar> lexeme definition is /:\[\d+\]:=/ i.e. start with 2 ASCII characters and end with 3 ASCII characters */
  if (MARPAESLIF_UNLIKELY(asciil < 5)) {
    /* Should never happen as per the grammar */
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "<op declare any grammar> is not long enough");
    goto err;
  }

  /* atoi() will stop at the ']' by definition: no need to allocate a NUL terminated string just for that */
  MARPAESLIF_BOOTSTRAP_SET_INT(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_OP_DECLARE, atoi(asciis + 2));

  rcb = 1;
  goto done;
 err:
  rcb = 0;
 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_rhsb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <rhs> ::= <rhs alternative>+ */
  genericStack_t                         *rhsAlternativeStackp = NULL;
  marpaESLIF_bootstrap_rhs_alternative_t *rhsAlternativep      = NULL;
  int                                     i;
  short                                   rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  GENERICSTACK_NEW(rhsAlternativeStackp);
  if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(rhsAlternativeStackp))) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "rhsAlternativeStackp initialization failure, %s", strerror(errno));
    goto err;
  }

  for (i = arg0i; i <= argni; i++) {
    MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, i, rhsAlternativep);
    if (MARPAESLIF_UNLIKELY(rhsAlternativep == NULL)) {
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "An RHS alternative is NULL");
      goto err;
    }

    GENERICSTACK_PUSH_PTR(rhsAlternativeStackp, rhsAlternativep);
    if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(rhsAlternativeStackp))) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "rhsAlternativeStackp push failure, %s", strerror(errno));
      goto err;
    }
    rhsAlternativep = NULL; /* rhsAlternativep is now in rhsAlternativeStackp */
  }

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_RHS, rhsAlternativeStackp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_rhs_freev(rhsAlternativeStackp);
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_rhs_alternative_freev(rhsAlternativep); /* This is NULL tolerant */
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_adverb_list_itemsb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <adverb list items> ::= <adverb item>* */
  genericStack_t                              *adverbListItemStackp   = NULL;
  marpaESLIF_bootstrap_adverb_list_item_t     *adverbListItemp        = NULL;
  marpaESLIF_action_t                         *actionp                = NULL;
  short                                        left_associationb      = 0;
  short                                        right_associationb     = 0;
  short                                        group_associationb     = 0;
  marpaESLIF_bootstrap_rhs_primary_t          *separatorRhsPrimaryp   = NULL;
  short                                        properb                = 0;
  short                                        verboseb               = 0;
  short                                        hideseparatorb         = 0;
  int                                          ranki                  = 0;
  short                                        nullRanksHighb         = 0;
  int                                          priorityi              = 0;
  int                                          pausei                 = 0;
  short                                        latmb                  = 0;
  short                                        discardIsFallbackb     = 0;
  marpaESLIF_bootstrap_utf_string_t           *namingp                = NULL;
  marpaESLIF_action_t                         *symbolactionp          = NULL;
  marpaESLIF_action_t                         *ifactionp              = NULL;
  marpaESLIF_action_t                         *regexactionp           = NULL;
  marpaESLIF_action_t                         *eventactionp           = NULL;
  char                                        *defaultEncodings       = NULL;
  char                                        *fallbackEncodings      = NULL;
  marpaESLIF_bootstrap_event_initialization_t *eventInitializationp   = NULL;
  void                                        *contextp;
  int                                          i;
  short                                        rcb;
  short                                        undefb;

  GENERICSTACK_NEW(adverbListItemStackp);
  if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(adverbListItemStackp))) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "adverbListItemStackp initialization failure, %s", strerror(errno));
    goto err;
  }

  /* In theory, if we are called, this is because there is something on the stack */
  /* In any case, this is okay to have an empty stack -; */
  if (! nullableb) {
    for (i = arg0i; i <= argni; i++) {
      /* The null adverb is pushing undef */
      MARPAESLIF_BOOTSTRAP_IS_UNDEF(marpaESLIFValuep, i, undefb);
      if (undefb) {
        continue;
      }

      MARPAESLIF_BOOTSTRAP_GET_CONTEXT(marpaESLIFValuep, i, contextp);

      adverbListItemp = (marpaESLIF_bootstrap_adverb_list_item_t *) malloc(sizeof(marpaESLIF_bootstrap_adverb_list_item_t));
      if (MARPAESLIF_UNLIKELY(adverbListItemp == NULL)) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
        goto err;
      }
      adverbListItemp->type = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_NA;

      if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_ACTION) {
        MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, i, actionp);
        if (MARPAESLIF_UNLIKELY(actionp == NULL)) { /* Not possible */
          MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Adverb list item action is NULL");
          goto err;
        }
        adverbListItemp->type      = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_ACTION;
        adverbListItemp->u.actionp = actionp;
        actionp = NULL; /* actionp is now in adverbListItemp */
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_LEFT_ASSOCIATION) {
        MARPAESLIF_BOOTSTRAP_GET_BOOL(marpaESLIFValuep, i, left_associationb);
        adverbListItemp->type                = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_LEFT_ASSOCIATION;
        adverbListItemp->u.left_associationb = left_associationb;
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_RIGHT_ASSOCIATION) {
        MARPAESLIF_BOOTSTRAP_GET_BOOL(marpaESLIFValuep, i, right_associationb);
        adverbListItemp->type                = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_RIGHT_ASSOCIATION;
        adverbListItemp->u.right_associationb = right_associationb;
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_GROUP_ASSOCIATION) {
        MARPAESLIF_BOOTSTRAP_GET_BOOL(marpaESLIFValuep, i, group_associationb);
        adverbListItemp->type                = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_GROUP_ASSOCIATION;
        adverbListItemp->u.group_associationb = group_associationb;
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_SEPARATOR) {
        MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, i, separatorRhsPrimaryp);
        if (MARPAESLIF_UNLIKELY(separatorRhsPrimaryp == NULL)) { /* Not possible */
          MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Adverb list item separator is NULL");
          goto err;
        }
        adverbListItemp->type                   = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_SEPARATOR;
        adverbListItemp->u.separatorRhsPrimaryp = separatorRhsPrimaryp;
        separatorRhsPrimaryp = NULL; /* separatorRhsPrimaryp is now in adverbListItemp */
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_PROPER) {
        MARPAESLIF_BOOTSTRAP_GET_BOOL(marpaESLIFValuep, i, properb);
        adverbListItemp->type      = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_PROPER;
        adverbListItemp->u.properb = properb;
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_VERBOSE) {
        MARPAESLIF_BOOTSTRAP_GET_BOOL(marpaESLIFValuep, i, verboseb);
        adverbListItemp->type      = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_VERBOSE;
        adverbListItemp->u.verboseb = verboseb;
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_HIDESEPARATOR) {
        MARPAESLIF_BOOTSTRAP_GET_BOOL(marpaESLIFValuep, i, hideseparatorb);
        adverbListItemp->type             = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_HIDESEPARATOR;
        adverbListItemp->u.hideseparatorb = hideseparatorb;
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_RANK) {
        MARPAESLIF_BOOTSTRAP_GET_INT(marpaESLIFValuep, i, ranki);
        adverbListItemp->type    = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_RANK;
        adverbListItemp->u.ranki = ranki;
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_NULL_RANKING) {
        MARPAESLIF_BOOTSTRAP_GET_BOOL(marpaESLIFValuep, i, nullRanksHighb);
        adverbListItemp->type             = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_NULL_RANKING;
        adverbListItemp->u.nullRanksHighb = nullRanksHighb;
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_PRIORITY) {
        MARPAESLIF_BOOTSTRAP_GET_INT(marpaESLIFValuep, i, priorityi);
        adverbListItemp->type        = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_PRIORITY;
        adverbListItemp->u.priorityi = priorityi;
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_PAUSE) {
        MARPAESLIF_BOOTSTRAP_GET_INT(marpaESLIFValuep, i, pausei);
        adverbListItemp->type     = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_PAUSE;
        adverbListItemp->u.pausei = pausei;
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_LATM) {
        MARPAESLIF_BOOTSTRAP_GET_BOOL(marpaESLIFValuep, i, latmb);
        adverbListItemp->type    = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_LATM;
        adverbListItemp->u.latmb = latmb;
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_DISCARD_IS_FALLBACK) {
        MARPAESLIF_BOOTSTRAP_GET_BOOL(marpaESLIFValuep, i, discardIsFallbackb);
        adverbListItemp->type    = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_DISCARD_IS_FALLBACK;
        adverbListItemp->u.discardIsFallbackb = discardIsFallbackb;
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_NAMING) {
        MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, i, namingp);
        if (MARPAESLIF_UNLIKELY(namingp == NULL)) { /* Not possible */
          MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Adverb list item name is NULL");
          goto err;
        }
        adverbListItemp->type      = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_NAMING;
        adverbListItemp->u.namingp = namingp;
        namingp = NULL; /* namingp is now in adverbListItemp */
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_SYMBOLACTION) {
        MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, i, symbolactionp);
        if (MARPAESLIF_UNLIKELY(symbolactionp == NULL)) { /* Not possible */
          MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Adverb list item symbol-action is NULL");
          goto err;
        }
        adverbListItemp->type           = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_SYMBOLACTION;
        adverbListItemp->u.symbolactionp = symbolactionp;
        symbolactionp = NULL; /* symbolactionp is now in adverbListItemp */
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_EVENT_INITIALIZATION) {
        MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, i, eventInitializationp);
        if (MARPAESLIF_UNLIKELY(eventInitializationp == NULL)) { /* Not possible */
          MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Adverb list item event is NULL");
          goto err;
        }
        adverbListItemp->type                   = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_EVENT_INITIALIZATION;
        adverbListItemp->u.eventInitializationp = eventInitializationp;
        eventInitializationp = NULL; /* eventInitializationp is now in adverbListItemp */
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_IFACTION) {
        MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, i, ifactionp);
        if (MARPAESLIF_UNLIKELY(ifactionp == NULL)) { /* Not possible */
          MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Adverb list item if-action is NULL");
          goto err;
        }
        adverbListItemp->type        = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_IFACTION;
        adverbListItemp->u.ifactionp = ifactionp;
        ifactionp = NULL; /* ifactionp is now in adverbListItemp */
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_REGEXACTION) {
        MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, i, regexactionp);
        if (MARPAESLIF_UNLIKELY(regexactionp == NULL)) { /* Not possible */
          MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Adverb list item regex-action is NULL");
          goto err;
        }
        adverbListItemp->type           = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_REGEXACTION;
        adverbListItemp->u.regexactionp = regexactionp;
        regexactionp = NULL; /* regexactionp is now in adverbListItemp */
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_EVENTACTION) {
        MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, i, eventactionp);
        if (MARPAESLIF_UNLIKELY(eventactionp == NULL)) { /* Not possible */
          MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Adverb list item event-action is NULL");
          goto err;
        }
        adverbListItemp->type           = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_EVENTACTION;
        adverbListItemp->u.eventactionp = eventactionp;
        eventactionp = NULL; /* eventactionp is now in adverbListItemp */
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_DEFAULTENCODING) {
        MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, i, defaultEncodings);
        if (MARPAESLIF_UNLIKELY(defaultEncodings == NULL)) { /* Not possible */
          MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Adverb list item default-encoding is NULL");
          goto err;
        }
        adverbListItemp->type               = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_DEFAULTENCODING;
        adverbListItemp->u.defaultEncodings = defaultEncodings;
        defaultEncodings = NULL; /* defaultEncodings is now in adverbListItemp */
      } else if (contextp == MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_FALLBACKENCODING) {
        MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, i, fallbackEncodings);
        if (MARPAESLIF_UNLIKELY(fallbackEncodings == NULL)) { /* Not possible */
          MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Adverb list item fallback-encoding is NULL");
          goto err;
        }
        adverbListItemp->type               = MARPAESLIF_BOOTSTRAP_ADVERB_LIST_ITEM_TYPE_FALLBACKENCODING;
        adverbListItemp->u.fallbackEncodings = fallbackEncodings;
        fallbackEncodings = NULL; /* fallbackEncodings is now in adverbListItemp */
      } else {
        /* bootstrap managed marpaESLIF grammar itself, that is independant */
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unsupported adverb list item type %p", contextp);
        goto err;
      }

      GENERICSTACK_PUSH_PTR(adverbListItemStackp, (void *) adverbListItemp);
      if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(adverbListItemStackp))) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "adverbListItemStackp push failure, %s", strerror(errno));
        goto err;
      }
      adverbListItemp = NULL; /* adverbListItemp is now in adverbListItemStackp */
    }
  }

  /* It is possible to do a sanity check here */
  if (MARPAESLIF_UNLIKELY(left_associationb +  right_associationb + group_associationb > 1)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "assoc => left, assoc => right and assoc => group are mutually exclusive");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_LIST_ITEMS, adverbListItemStackp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_action_freev(actionp);
  _marpaESLIF_action_freev(symbolactionp);
  _marpaESLIF_action_freev(ifactionp);
  _marpaESLIF_action_freev(regexactionp);
  _marpaESLIF_action_freev(eventactionp);
  if (defaultEncodings != NULL) {
    free(defaultEncodings);
  }
  if (fallbackEncodings != NULL) {
    free(fallbackEncodings);
  }
  _marpaESLIF_bootstrap_event_initialization_freev(eventInitializationp);
  _marpaESLIF_bootstrap_utf_string_freev(namingp, 0 /* onStackb */);
  _marpaESLIF_bootstrap_rhs_primary_freev(separatorRhsPrimaryp);
  _marpaESLIF_bootstrap_adverb_list_item_freev(adverbListItemp);
  _marpaESLIF_bootstrap_adverb_list_items_freev(adverbListItemStackp);
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_action_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  return _marpaESLIF_bootstrap_G1_action_genericb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, "action", MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_ACTION);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_action_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <action> ::= 'action' '=>' <string literal> */
  marpaESLIF_string_t *stringp     = NULL;
  marpaESLIF_action_t *actionp     = NULL;
  short                rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  /* <string literal> is a PTR */
  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, argni, stringp);
  /* It is a non-sense to not have no string in this case */
  if (MARPAESLIF_UNLIKELY(stringp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "action at indice %d returned NULL", argni);
    goto err;
  }

  actionp = (marpaESLIF_action_t *) malloc(sizeof(marpaESLIF_action_t));
  if (MARPAESLIF_UNLIKELY(actionp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  actionp->type      = MARPAESLIF_ACTION_TYPE_STRING;
  actionp->u.stringp = stringp;
  stringp            = NULL; /* stringp is now in actionp */

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_ACTION, actionp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_action_freev(actionp);
  rcb = 0;

 done:
  _marpaESLIF_string_freev(stringp, 0 /* onStackb */);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_action_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <action> ::= 'action' '=>' <quoted string literal> */
  marpaESLIF_string_t               *stringp       = NULL;
  marpaESLIF_action_t               *actionp       = NULL;
  marpaESLIF_bootstrap_utf_string_t *quotedStringp = NULL;
  void                              *bytep;
  size_t                             bytel;
  short                              rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, argni, bytep, bytel);
  quotedStringp = _marpaESLIF_bootstrap_unquote_string_literalp(marpaESLIFValuep, bytep, bytel, 1 /* allowEmptyStringb */);
  if (MARPAESLIF_UNLIKELY(quotedStringp == NULL)) {
    goto err;
  }

  stringp = _marpaESLIF_string_newp(marpaESLIFValuep->marpaESLIFp, (char *) MARPAESLIF_UTF8_STRING, quotedStringp->bytep, quotedStringp->bytel);
  if (MARPAESLIF_UNLIKELY(stringp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "action at indice %d returned NULL", argni);
    goto err;
  }

  actionp = (marpaESLIF_action_t *) malloc(sizeof(marpaESLIF_action_t));
  if (MARPAESLIF_UNLIKELY(actionp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  actionp->type      = MARPAESLIF_ACTION_TYPE_STRING;
  actionp->u.stringp = stringp;
  stringp            = NULL; /* stringp is now in actionp */

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_ACTION, actionp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_action_freev(actionp);
  rcb = 0;

 done:
  _marpaESLIF_string_freev(stringp, 0 /* onStackb */);
  _marpaESLIF_bootstrap_utf_string_freev(quotedStringp, 0 /* onStackb */);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_string_literalb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <string literal> ::= <string literal unit>+ */
  static const char   *funcs       = "_marpaESLIF_bootstrap_G1_action_string_literalb";
  marpaESLIF_string_t *stringp     = NULL;
  char                *charp       = NULL;
  size_t               charl       = 0;
  char                *converteds  = NULL;
  size_t               convertedl;
  int                  i;
  char                *p;
  void                *bytep;
  size_t               bytel;
  short                undefb;
  short                rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  /* Get total size, take care it is possible that one of the string literal unit is empty (aka undef) */
  for (i = arg0i; i<= argni; i++) {
    MARPAESLIF_BOOTSTRAP_IS_UNDEF(marpaESLIFValuep, i, undefb);
    if (undefb) {
      MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "String literal indice %d is empty\n", i - arg0i);
      continue;
    }
    MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, i, bytep, bytel);
    charl += bytel;
    MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "String literal indice %d size is 0x%ld, total size is now 0x%ld\n", i - arg0i, (unsigned long) bytel, (unsigned long) charl);
  }

  /* Total concatenated size is empty ? */
  if (charl <= 0) {
    stringp = _marpaESLIF_string_newp(marpaESLIFValuep->marpaESLIFp, (char *) MARPAESLIF_UTF8_STRING, NULL, 0); /* Will produce empty string */
  } else {
    charp = (char *) malloc(charl + 1);
    if (MARPAESLIF_UNLIKELY(charp == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
      goto err;
    }
    p = charp;
    for (i = arg0i; i<= argni; i++) {
      MARPAESLIF_BOOTSTRAP_IS_UNDEF(marpaESLIFValuep, i, undefb);
      if (undefb) {
      continue;
      }
      MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, i, bytep, bytel);
      memcpy(p, bytep, bytel);
      p += bytel;
    }
    *p = '\0'; /* For convenience */

    /* Call for conversion in any case, this is a way to validate UTF-8 correctness */
    converteds = _marpaESLIF_charconvb(marpaESLIFValuep->marpaESLIFp,
                                       "UTF-8",
                                       (char *) MARPAESLIF_UTF8_STRING, /* We request that input is an UTF-8 string */
                                       charp,
                                       charl, /* Skip the automatic NUL byte in the source */
                                       &convertedl,
                                       NULL, /* fromEncodingsp */
                                       NULL, /* tconvpp */
                                       1, /* eofb */
                                       NULL, /* byteleftsp */
                                       NULL, /* byteleftlp */
                                       NULL, /* byteleftalloclp */
                                       0, /* tconvsilentb */
                                       NULL, /* defaultEncodings */
                                       NULL /* fallbackEncodings */);
    if (MARPAESLIF_UNLIKELY(converteds == NULL)) {
      goto err;
    }
    stringp = _marpaESLIF_string_newp(marpaESLIFValuep->marpaESLIFp, (char *) MARPAESLIF_UTF8_STRING, charp, charl);
  }

  if (MARPAESLIF_UNLIKELY(stringp == NULL)) {
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_STRING, stringp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_string_freev(stringp, 0 /* onStackb */);
  rcb = 0;

 done:
  if (converteds != NULL) {
    free(converteds);
  }
  if (charp != NULL) {
    free(charp);
  }
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_string_literal_inside_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <string literal inside> ::= '\\' ["'?\\abfnrtve] */
  char         *charp       = NULL;
  size_t        charl       = sizeof(char);
  char          p;
  char          c;
  void         *bytep;
  size_t        bytel;
  short         rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  /* ["\\abfnrtve] is a lexeme of size 1 */
  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, argni, bytep, bytel);
  if (MARPAESLIF_UNLIKELY(bytel != 1)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Escaped character must be of size 1");
    goto err;
  }
  /* We use the \x notation in case the compiler does not support the metacharacter */
  p = * (char *) bytep;
  switch (p) {
  case 'a':
    c = 0x07;
    break;
  case 'b':
    c = 0x08;
    break;
  case 'f':
    c = 0x0C;
    break;
  case 'n':
    c = 0x0A;
    break;
  case 'r':
    c = 0x0D;
    break;
  case 't':
    c = 0x09;
    break;
  case 'v':
    c = 0x0B;
    break;
  case '\\':
    c = 0x5C;
    break;
  case '\'':
    c = 0x27;
    break;
  case '"':
    c = 0x22;
    break;
  case '?':
    c = 0x3F;
    break;
  case 'e':
    c = 0x1B;
    break;
  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unsupported escaped character '%c' (0x%lx)", p, (unsigned long) p);
    goto err;
  }

  charp = (char *) malloc(charl + 1);
  if (MARPAESLIF_UNLIKELY(charp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  charp[0] = c;
  charp[1] = '\0'; /* For convenience */
  MARPAESLIF_BOOTSTRAP_SET_ARRAY(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ARRAY, charp, charl);

  rcb = 1;
  goto done;

 err:
  if (charp != NULL) {
    free(charp);
  }
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_string_literal_inside_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <string literal inside> ::= '\\' /x\{[a-fA-F0-9]{2}\}/ */
  char         *charp       = NULL;
  size_t        charl       = sizeof(char);
  char          c           = 0;
  char         *p;
  void         *bytep;
  size_t        bytel;
  short         rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  /* /x\\{[a-fA-F0-9]{2}\\}/ is a lexeme of size 5 */
  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, argni, bytep, bytel);
  if (MARPAESLIF_UNLIKELY(bytel != 5)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Escaped hex character must be of size 5");
    goto err;
  }
  p = (char *) bytep;
  p += 2;
  MARPAESLIF_BOOTSTRAP_DST_OR_VALCHAR(marpaESLIFValuep, c, *p++);
  c <<= 4;
  MARPAESLIF_BOOTSTRAP_DST_OR_VALCHAR(marpaESLIFValuep, c, *p);
  
  charp = (char *) malloc(charl + 1);
  if (MARPAESLIF_UNLIKELY(charp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  charp[0] = c;
  charp[1] = '\0'; /* For convenience */
  MARPAESLIF_BOOTSTRAP_SET_ARRAY(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ARRAY, charp, charl);
  
  rcb = 1;
  goto done;

 err:
  if (charp != NULL) {
    free(charp);
  }
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_string_literal_inside_4b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <string literal inside> ::= '\\' /u\{[a-fA-F0-9]{4}\}/ */
  char                *charp       = NULL;
  marpaESLIF_uint32_t  uint32      = 0;
  PCRE2_UCHAR          bufferp[6];
  size_t               charl;
  char                *p;
  void                *bytep;
  size_t               bytel;
  short                rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  /* /u\{[a-fA-F0-9]{4}\}/ is a lexeme of size 7 */
  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, argni, bytep, bytel);
  if (MARPAESLIF_UNLIKELY(bytel != 7)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Escaped codepoint must be of size 7");
    goto err;
  }
  p = (char *) bytep;
  p += 2;
  MARPAESLIF_BOOTSTRAP_DST_OR_VALCHAR(marpaESLIFValuep, uint32, *p++);
  uint32 <<= 4;
  MARPAESLIF_BOOTSTRAP_DST_OR_VALCHAR(marpaESLIFValuep, uint32, *p++);
  uint32 <<= 4;
  MARPAESLIF_BOOTSTRAP_DST_OR_VALCHAR(marpaESLIFValuep, uint32, *p++);
  uint32 <<= 4;
  MARPAESLIF_BOOTSTRAP_DST_OR_VALCHAR(marpaESLIFValuep, uint32, *p);

  /* Transform this codepoint into an UTF-8 character - this is copy/pasted from pcre2_ord2utf.c */
  charl = _marpaESLIF_bootstrap_ord2utfb(uint32, bufferp);
  if (MARPAESLIF_UNLIKELY(charl <= 0)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Failed to determine UTF-8 byte size of 0x%ld", (unsigned long) uint32);
    goto err;
  }
  charp = (char *) malloc(charl + 1);
  if (MARPAESLIF_UNLIKELY(charp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  memcpy(charp, bufferp, charl);
  charp[charl] = '\0'; /* For convenience */
  MARPAESLIF_BOOTSTRAP_SET_ARRAY(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ARRAY, charp, charl);

  rcb = 1;
  goto done;

 err:
  if (charp != NULL) {
    free(charp);
  }
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_string_literal_inside_5b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <string literal inside> ::= '\\' /U\{[a-fA-F0-9]{8}\}/ */
  char                *charp       = NULL;
  marpaESLIF_uint32_t  uint32      = 0;
  PCRE2_UCHAR          bufferp[6];
  size_t               charl;
  char                *p;
  void                *bytep;
  size_t               bytel;
  short                rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  /* /U\{[a-fA-F0-9]{8}\}/ is a lexeme of size 11 */
  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, argni, bytep, bytel);
  if (MARPAESLIF_UNLIKELY(bytel != 11)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Escaped codepoint must be of size 11");
    goto err;
  }
  p = (char *) bytep;
  p += 2;
  MARPAESLIF_BOOTSTRAP_DST_OR_VALCHAR(marpaESLIFValuep, uint32, *p++);
  uint32 <<= 4;
  MARPAESLIF_BOOTSTRAP_DST_OR_VALCHAR(marpaESLIFValuep, uint32, *p++);
  uint32 <<= 4;
  MARPAESLIF_BOOTSTRAP_DST_OR_VALCHAR(marpaESLIFValuep, uint32, *p++);
  uint32 <<= 4;
  MARPAESLIF_BOOTSTRAP_DST_OR_VALCHAR(marpaESLIFValuep, uint32, *p++);
  uint32 <<= 4;
  MARPAESLIF_BOOTSTRAP_DST_OR_VALCHAR(marpaESLIFValuep, uint32, *p++);
  uint32 <<= 4;
  MARPAESLIF_BOOTSTRAP_DST_OR_VALCHAR(marpaESLIFValuep, uint32, *p++);
  uint32 <<= 4;
  MARPAESLIF_BOOTSTRAP_DST_OR_VALCHAR(marpaESLIFValuep, uint32, *p++);
  uint32 <<= 4;
  MARPAESLIF_BOOTSTRAP_DST_OR_VALCHAR(marpaESLIFValuep, uint32, *p);

  /* Transform this codepoint into an UTF-8 character - this is copy/pasted from pcre2_ord2utf.c */
  charl = _marpaESLIF_bootstrap_ord2utfb(uint32, bufferp);
  if (MARPAESLIF_UNLIKELY(charl <= 0)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Failed to determine UTF-8 byte size of 0x%ld", (unsigned long) uint32);
    goto err;
  }
  charp = (char *) malloc(charl + 1);
  if (MARPAESLIF_UNLIKELY(charp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  memcpy(charp, bufferp, charl);
  charp[charl] = '\0'; /* For convenience */
  MARPAESLIF_BOOTSTRAP_SET_ARRAY(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ARRAY, charp, charl);

  rcb = 1;
  goto done;

 err:
  if (charp != NULL) {
    free(charp);
  }
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_symbolaction_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <action> ::= 'symbol-action' '=>' <action name> */
  return _marpaESLIF_bootstrap_G1_action_genericb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, "symbol-action", MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_SYMBOLACTION);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_symbolaction_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* action ::= 'symbol-action' '=>' <string literal> */
  marpaESLIF_string_t *stringp       = NULL;
  marpaESLIF_action_t *symbolactionp = NULL;
  short                rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  /* <string literal> is a PTR */
  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, argni, stringp);
  /* It is a non-sense to not have no string in this case */
  if (MARPAESLIF_UNLIKELY(stringp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "action at indice %d returned NULL", argni);
    goto err;
  }

  symbolactionp = (marpaESLIF_action_t *) malloc(sizeof(marpaESLIF_action_t));
  if (MARPAESLIF_UNLIKELY(symbolactionp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  symbolactionp->type      = MARPAESLIF_ACTION_TYPE_STRING;
  symbolactionp->u.stringp = stringp;
  stringp                  = NULL; /* stringp is now in symbolactionp */

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_SYMBOLACTION, symbolactionp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_action_freev(symbolactionp);
  rcb = 0;

 done:
  _marpaESLIF_string_freev(stringp, 0 /* onStackb */);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_symbolaction_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <action> ::= 'symbol-action' '=>' <quoted string literal> */
  marpaESLIF_bootstrap_utf_string_t *quotedStringp = NULL;
  marpaESLIF_string_t               *stringp       = NULL;
  marpaESLIF_action_t               *symbolactionp = NULL;
  void                              *bytep;
  size_t                             bytel;
  short                              rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, argni, bytep, bytel);
  quotedStringp = _marpaESLIF_bootstrap_unquote_string_literalp(marpaESLIFValuep, bytep, bytel, 1 /* allowEmptyStringb */);
  if (MARPAESLIF_UNLIKELY(quotedStringp == NULL)) {
    goto err;
  }

  stringp = _marpaESLIF_string_newp(marpaESLIFValuep->marpaESLIFp, (char *) MARPAESLIF_UTF8_STRING, quotedStringp->bytep, quotedStringp->bytel);
  if (MARPAESLIF_UNLIKELY(stringp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "action at indice %d returned NULL", argni);
    goto err;
  }

  symbolactionp = (marpaESLIF_action_t *) malloc(sizeof(marpaESLIF_action_t));
  if (MARPAESLIF_UNLIKELY(symbolactionp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  symbolactionp->type      = MARPAESLIF_ACTION_TYPE_STRING;
  symbolactionp->u.stringp = stringp;
  stringp                  = NULL; /* stringp is now in symbolactionp */

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_SYMBOLACTION, symbolactionp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_action_freev(symbolactionp);
  rcb = 0;

 done:
  _marpaESLIF_string_freev(stringp, 0 /* onStackb */);
  _marpaESLIF_bootstrap_utf_string_freev(quotedStringp, 0 /* onStackb */);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_separator_specificationb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* 'separator' '=>' <rhs primary> */
  marpaESLIF_bootstrap_rhs_primary_t *rhsPrimaryp  = NULL;
  short                               rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, argni, rhsPrimaryp);
  /* It is a non-sense to not have no action in this case */
  if (MARPAESLIF_UNLIKELY(rhsPrimaryp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "separator at indice %d returned NULL", argni);
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_SEPARATOR, rhsPrimaryp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_rhs_primary_freev(rhsPrimaryp);
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_left_associationb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <left association> ::= 'assoc' '=>' 'left' */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_BOOL(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_LEFT_ASSOCIATION, 1);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_right_associationb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <right association> ::= 'assoc' '=>' 'right' */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_BOOL(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_RIGHT_ASSOCIATION, 1);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_group_associationb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <group association> ::= 'assoc' '=>' 'group' */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_BOOL(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_GROUP_ASSOCIATION, 1);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_rhs_alternative_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <rhs alternative> ::= <rhs primary>' */
  marpaESLIF_bootstrap_rhs_primary_t       *rhsPrimaryp        = NULL;
  marpaESLIF_bootstrap_rhs_alternative_t   *rhsAlternativep    = NULL;
  short                                     rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i, rhsPrimaryp);
  /* It is a non-sense to not have valid information */
  if (MARPAESLIF_UNLIKELY(rhsPrimaryp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "rhsPrimaryp at indice %d is NULL", arg0i);
    goto err;
  }

  /* Make that an rhs alternative structure */
  rhsAlternativep = (marpaESLIF_bootstrap_rhs_alternative_t *) malloc(sizeof(marpaESLIF_bootstrap_rhs_alternative_t));
  if (MARPAESLIF_UNLIKELY(rhsAlternativep == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  rhsAlternativep->type          = MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_RHS_PRIMARY;
  rhsAlternativep->u.rhsPrimaryp = rhsPrimaryp;
  rhsPrimaryp = NULL; /* rhsPrimaryp is in rhsAlternativep */

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_RHS_ALTERNATIVE, rhsAlternativep);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_rhs_alternative_freev(rhsAlternativep);
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_rhs_primary_freev(rhsPrimaryp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_rhs_alternative_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <rhs alternative> ::= '(-' <priorities> '-)' */
  return _marpaESLIF_bootstrap_G1_action_rhs_alternative_prioritiesb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, 1 /* skipb */, 0 /* lookaheadb */);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_rhs_alternative_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <rhs alternative> ::= '(' <priorities> ')' */
  return _marpaESLIF_bootstrap_G1_action_rhs_alternative_prioritiesb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, 0 /* skipb */, 0 /* lookaheadb */);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_rhs_alternative_4b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <rhs alternative> ::= '(-' <rhs primary> '-' <rhs primary> <adverb list> '-)' */
  return _marpaESLIF_bootstrap_G1_action_rhs_alternative_exceptionb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, 1 /* skipb */, 0 /* lookaheadb */);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_rhs_alternative_5b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <rhs alternative> ::= '(' <rhs primary> '-' <rhs primary> <adverb list> ')' */
  return _marpaESLIF_bootstrap_G1_action_rhs_alternative_exceptionb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, 0 /* skipb */, 0 /* lookaheadb */);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_rhs_alternative_6b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <rhs alternative> ::= '(-' <rhs primary> <quantifier> <adverb list> '-)' */
  return _marpaESLIF_bootstrap_G1_action_rhs_alternative_quantifiedb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, 1 /* skipb */, 0 /* lookaheadb */);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_rhs_alternative_7b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <rhs alternative> ::= '(' <rhs primary> <quantifier> <adverb list> ')' */
  return _marpaESLIF_bootstrap_G1_action_rhs_alternative_quantifiedb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, 0 /* skipb */, 0 /* lookaheadb */);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_rhs_primary_no_parameter_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <rhs primary no parameter> ::= <single symbol> */
  /* <single symbol> is on the stack, typed MARPAESLIF_BOOTSTRAP_STACK_TYPE_SINGLE_SYMBOL */
  marpaESLIF_bootstrap_rhs_primary_t   *rhsPrimaryp   = NULL;
  marpaESLIF_bootstrap_single_symbol_t *singleSymbolp = NULL;
  short                                 rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i, singleSymbolp);
  /* It is a non-sense to not have valid information */
  if (MARPAESLIF_UNLIKELY(singleSymbolp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "singleSymbolp at indice %d is NULL", argni);
    goto err;
  }

  /* Make that an rhs primary structure */
  rhsPrimaryp = (marpaESLIF_bootstrap_rhs_primary_t *) malloc(sizeof(marpaESLIF_bootstrap_rhs_primary_t));
  if (MARPAESLIF_UNLIKELY(rhsPrimaryp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  rhsPrimaryp->callp            = NULL;
  rhsPrimaryp->type             = MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_SINGLE_SYMBOL;
  rhsPrimaryp->u.singleSymbolp  = singleSymbolp;
  singleSymbolp = NULL; /* singleSymbolp is now in rhsPrimaryp */

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_RHS_PRIMARY, rhsPrimaryp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_rhs_primary_freev(rhsPrimaryp);
  rcb = 0;

 done:
  if (singleSymbolp != NULL) {
    _marpaESLIF_bootstrap_single_symbol_freev(singleSymbolp);
  }
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_rhs_primary_no_parameter_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <rhs primary no parameter> ::= <symbol> '@' <grammar reference> */
  marpaESLIF_bootstrap_rhs_primary_t       *rhsPrimaryp       = NULL;
  marpaESLIF_bootstrap_symbol_t            *symbolp           = NULL;
  marpaESLIF_bootstrap_grammar_reference_t *grammarReferencep = NULL;
  short                                     rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i, symbolp);
  /* It is a non-sense to not have valid information */
  if (MARPAESLIF_UNLIKELY(symbolp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "symbolp at indice %d is NULL", arg0i);
    goto err;
  }

  /* <grammar reference> is a pointer */
  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i+2, grammarReferencep);
  /* It is a non-sense to not have valid information */
  if (MARPAESLIF_UNLIKELY(grammarReferencep == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "_marpaESLIFValue_stack_getb at indice %d returned NULL", arg0i+2);
    goto err;
  }

  /* Make that an rhs primary structure */
  rhsPrimaryp = (marpaESLIF_bootstrap_rhs_primary_t *) malloc(sizeof(marpaESLIF_bootstrap_rhs_primary_t));
  if (MARPAESLIF_UNLIKELY(rhsPrimaryp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }

  rhsPrimaryp->callp            = NULL;
  rhsPrimaryp->type             = MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_NA;

  rhsPrimaryp->u.symbolAndReferencep = (marpaESLIF_bootstrap_symbol_and_reference_t *) malloc(sizeof(marpaESLIF_bootstrap_symbol_and_reference_t));
  if (MARPAESLIF_UNLIKELY(rhsPrimaryp->u.symbolAndReferencep == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  rhsPrimaryp->type = MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_SYMBOL_AND_REFERENCE;
  rhsPrimaryp->u.symbolAndReferencep->symbolp           = symbolp;
  rhsPrimaryp->u.symbolAndReferencep->grammarReferencep = grammarReferencep;
  symbolp = NULL; /* symbolp is in symbolAndReferencep */
  grammarReferencep = NULL; /* grammarReferencep  is in symbolAndReferencep */

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_RHS_PRIMARY, rhsPrimaryp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_rhs_primary_freev(rhsPrimaryp);
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_symbol_freev(symbolp);
  _marpaESLIF_bootstrap_grammar_reference_freev(grammarReferencep);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_rhs_primary_no_parameter_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <rhs primary no parameter> ::= '$' <alternative name> */
  /* <alternative name> is always an array */
  marpaESLIF_bootstrap_rhs_primary_t       *rhsPrimaryp = NULL;
  void                                     *bytep;
  size_t                                    bytel;
  short                                     rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, argni, bytep, bytel);
  /* It is a non-sense to have a null information */
  if (MARPAESLIF_UNLIKELY((bytep == NULL) || (bytel <= 0))) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "_marpaESLIFValue_stack_getb at indice %d returned {p,%ld}", argni, bytep, (unsigned long) bytel);
    goto err;
  }

  /* Make that an rhs primary structure */
  rhsPrimaryp = (marpaESLIF_bootstrap_rhs_primary_t *) malloc(sizeof(marpaESLIF_bootstrap_rhs_primary_t));
  if (MARPAESLIF_UNLIKELY(rhsPrimaryp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }

  rhsPrimaryp->callp                        = NULL;
  rhsPrimaryp->type                         = MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_NA;
  rhsPrimaryp->u.name.substitutionBytep     = NULL;
  rhsPrimaryp->u.name.substitutionBytel     = 0;
  rhsPrimaryp->u.name.substitutionModifiers = NULL;
  rhsPrimaryp->u.name.bytep                 = NULL;
  rhsPrimaryp->u.name.bytel                 = 0;
  rhsPrimaryp->u.name.modifiers             = NULL;

  rhsPrimaryp->u.name.bytep = (char *) malloc(bytel + 1);
  if (rhsPrimaryp->u.name.bytep == NULL) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  memcpy(rhsPrimaryp->u.name.bytep, bytep, bytel);
  rhsPrimaryp->u.name.bytep[bytel] = '\0';

  rhsPrimaryp->type             = MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_NAME;
  rhsPrimaryp->u.name.bytel     = bytel;

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_RHS_PRIMARY, rhsPrimaryp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_rhs_primary_freev(rhsPrimaryp);
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_rhs_primary_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <rhs primary> ::= <rhs primary no parameter> <lua functioncall> */
  marpaESLIF_bootstrap_rhs_primary_t   *rhsPrimaryp = NULL;
  marpaESLIF_lua_functioncall_t        *callp       = NULL;
  short                                 rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i, rhsPrimaryp);
  /* It is a non-sense to not have valid information */
  if (MARPAESLIF_UNLIKELY(rhsPrimaryp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "rhsPrimaryp at indice %d is NULL", arg0i);
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i + 1, callp);
  /* It is a non-sense to not have valid information */
  if (MARPAESLIF_UNLIKELY(callp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "callp at indice %d is NULL", arg0i + 1);
    goto err;
  }

  rhsPrimaryp->callp = callp;
  callp = NULL;
  
  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_RHS_PRIMARY, rhsPrimaryp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_rhs_primary_freev(rhsPrimaryp);
  rcb = 0;

 done:
  _marpaESLIF_lua_functioncall_freev(callp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_rhs_primary_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <rhs primary> ::= <generator action> <lua functioncall> */
  marpaESLIF_bootstrap_rhs_primary_t       *rhsPrimaryp    = NULL;
  marpaESLIF_action_t                      *generatorActionp = NULL;
  marpaESLIF_lua_functioncall_t            *callp          = NULL;
  short                                     rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i, generatorActionp);
  /* It is a non-sense to not have valid information */
  if (MARPAESLIF_UNLIKELY(generatorActionp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "generatorActionp at indice %d is NULL", arg0i);
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i + 1, callp);
  /* It is a non-sense to not have valid information */
  if (MARPAESLIF_UNLIKELY(callp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "callp at indice %d is NULL", arg0i + 1);
    goto err;
  }

  /* Make that an rhs primary structure */
  rhsPrimaryp = (marpaESLIF_bootstrap_rhs_primary_t *) malloc(sizeof(marpaESLIF_bootstrap_rhs_primary_t));
  if (MARPAESLIF_UNLIKELY(rhsPrimaryp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }

  rhsPrimaryp->callp              = callp;
  rhsPrimaryp->type               = MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_GENERATOR_ACTION;
  rhsPrimaryp->u.generatorActionp = generatorActionp;
  generatorActionp = NULL; /* generatorActionp is in rhsPrimary */
  callp = NULL; /* callp  is in luaSymbolp */

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_RHS_PRIMARY, rhsPrimaryp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_rhs_primary_freev(rhsPrimaryp);
  rcb = 0;

 done:
  _marpaESLIF_action_freev(generatorActionp);
  _marpaESLIF_lua_functioncall_freev(callp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_alternativeb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <alternative> ::= <rhs> <adverb list> */
  marpaESLIF_bootstrap_alternative_t *alternativep         = NULL;
  genericStack_t                     *adverbListItemStackp = NULL;
  genericStack_t                     *rhsAlternativeStackp = NULL;
  short                               undefb;
  short                               rcb;

  /* rhs must be a non-NULL generic stack of the primary */
  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i, rhsAlternativeStackp);
  if (MARPAESLIF_UNLIKELY(rhsAlternativeStackp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "rhsAlternativeStackp is NULL");
    goto err;
  }
  
  /* adverb list may be undef */
  MARPAESLIF_BOOTSTRAP_IS_UNDEF(marpaESLIFValuep, argni, undefb);
  if (! undefb) {
    MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, argni, adverbListItemStackp);
    /* Non-sense to have a NULL stack in this case */
    if (MARPAESLIF_UNLIKELY(adverbListItemStackp == NULL)) {
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "adverbListItemStackp is NULL");
      goto err;
    }
  }

  alternativep = (marpaESLIF_bootstrap_alternative_t *) malloc(sizeof(marpaESLIF_bootstrap_alternative_t));
  if (MARPAESLIF_UNLIKELY(alternativep == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  alternativep->rhsAlternativeStackp = rhsAlternativeStackp;
  alternativep->adverbListItemStackp = adverbListItemStackp;
  alternativep->priorityi            = 0;    /* Used when there is the loosen "||" operator */
  alternativep->forcedLhsp           = NULL; /* Ditto */

  rhsAlternativeStackp = NULL;
  adverbListItemStackp = NULL;

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ALTERNATIVE, alternativep);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_alternative_freev(alternativep);
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_adverb_list_items_freev(adverbListItemStackp);
  _marpaESLIF_bootstrap_rhs_freev(rhsAlternativeStackp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_alternativesb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <alternatives> ::= <alternative>+ separator => <op equal priority> proper => 1 hide-separator => 1*/
  genericStack_t                     *alternativeStackp = NULL;
  marpaESLIF_bootstrap_alternative_t *alternativep      = NULL;
  int                                i;
  short                              rcb;

  GENERICSTACK_NEW(alternativeStackp);
  if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(alternativeStackp))) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "alternativeStackp initialization failure, %s", strerror(errno));
    goto err;
  }

  for (i = arg0i; i <= argni; i++) { /* The separator is skipped from the list of arguments */
    MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, i, alternativep);
    GENERICSTACK_PUSH_PTR(alternativeStackp, (void *) alternativep);
    if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(alternativeStackp))) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "alternativeStackp push failure, %s", strerror(errno));
      goto err;
    }
    alternativep = NULL; /* alternativep is now in alternativeStackp */
  }

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ALTERNATIVES, alternativeStackp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_alternative_freev(alternativep);
  _marpaESLIF_bootstrap_alternatives_freev(alternativeStackp);
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_prioritiesb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <priorities> ::= <alternatives>+ separator => <op loosen> proper => 1 hide-separator => 1*/
  genericStack_t *alternativesStackp = NULL;
  genericStack_t *alternativeStackp  = NULL;
  int             i;
  short           rcb;

  GENERICSTACK_NEW(alternativesStackp);
  if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(alternativesStackp))) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "alternativesStackp initialization failure, %s", strerror(errno));
    goto err;
  }

  for (i = arg0i; i <= argni; i++) { /* The separator is skipped from the list of arguments */
    MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, i, alternativeStackp);
    GENERICSTACK_PUSH_PTR(alternativesStackp, (void *) alternativeStackp);
    if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(alternativesStackp))) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "alternativesStackp push failure, %s", strerror(errno));
      goto err;
    }
    alternativeStackp = NULL; /* alternativeStackp is now in alternativesStackp */
  }

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_PRIORITIES, alternativesStackp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_alternatives_freev(alternativeStackp);
  _marpaESLIF_bootstrap_priorities_freev(alternativesStackp);
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIF_bootstrap_G1_action_priority_loosen_ruleb(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_symbol_t *lhsp, genericStack_t *alternativesStackp, marpaESLIF_lua_functiondecl_t *declp)
/*****************************************************************************/
{
  /* <priority rule> ::= lhs <op declare> priorities */
  /* This method is called when there is more than one priority. It reconstruct a flat list with one priority only */
  static const char                       *funcs                      = "_marpaESLIF_bootstrap_G1_action_priority_loosen_ruleb";
  genericStack_t                          *flatAlternativesStackp     = NULL;
  genericStack_t                          *flatAlternativeStackp      = NULL;
  char                                    *topasciis                  = NULL;
  char                                    *currentasciis              = NULL;
  char                                    *nextasciis                 = NULL;
  int                                     *arityip                    = NULL;
  marpaESLIF_bootstrap_rhs_alternative_t  *prioritizedRhsAlternativep = NULL;
  genericStack_t                          *alternativeStackp;
  genericStack_t                          *rhsAlternativeStackp;
  genericStack_t                          *adverbListItemStackp;
  marpaESLIF_bootstrap_rhs_alternative_t  *rhsAlternativep;
  int                                      priorityCounti;
  int                                      alternativesi;
  int                                      alternativei;
  marpaESLIF_bootstrap_alternative_t      *alternativep;
  marpaESLIF_symbol_t                     *prioritizedLhsp;
  marpaESLIF_symbol_t                     *nextPrioritizedLhsp;
  marpaESLIF_symbol_t                     *rhsp;
  marpaESLIF_rule_t                       *rulep;
  int                                      priorityi;
  int                                      nextPriorityi;
  int                                      arityi;
  int                                      nrhsi;
  int                                      rhsi;
  short                                    rcb;
  char                                     tmps[1024];
  short                                    left_associationb;
  short                                    right_associationb;
  short                                    group_associationb;
  int                                      ranki;
  short                                    nullRanksHighb;
  marpaESLIF_bootstrap_utf_string_t       *namingp;
  marpaESLIF_action_t                     *actionp;
  marpaESLIF_action_t                      action;
  int                                      arityixi;
  marpaESLIF_lua_functioncall_t            decl2call;
  marpaESLIF_lua_functioncall_t           *decl2callp;

  if (declp != NULL) {
    decl2call.luaexplists  = declp->luaparlists;
    decl2call.luaexplistcb = declp->luaparlistcb;
    decl2call.sizei        = declp->sizei;
    decl2callp = &decl2call;
  } else {
    decl2callp = NULL;
  }

  priorityCounti = GENERICSTACK_USED(alternativesStackp);
  MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Processing %d '||' rules", GENERICSTACK_USED(alternativesStackp));
  if (priorityCounti <= 1) {
    /* No loosen operator: go to flat method */
    return _marpaESLIF_bootstrap_G1_action_priority_flat_ruleb(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, lhsp, alternativesStackp, "non-prioritized alternatives rule", declp);
  }

  /* Constant action */
  action.type    = MARPAESLIF_ACTION_TYPE_NAME;
  action.u.names = "::shift";

  /* Create a top-version of the LHS, using symbols not allowed from the external */
  /* Per-def lhsp is a meta symbol */
  topasciis = (char *) malloc(strlen(lhsp->u.metap->asciinames) + 3 /* "[0]" */ + 1 /* NUL byte */);
  if (MARPAESLIF_UNLIKELY(topasciis == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  strcpy(topasciis, lhsp->u.metap->asciinames);
  strcat(topasciis, "[0]");

  /* A symbol must appear once as a prioritized LHS in the whole grammar */
  if (MARPAESLIF_UNLIKELY(_marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, topasciis, 0 /* createb */, 0 /* forcecreateb */, 1 /* lhsb */, NULL /* declp */, 0 /* rhsb */, NULL /* callp */) != NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Symbol %s must appear once in the grammar as the LHS of a a prioritized rule", lhsp->u.metap->asciinames);
    goto err;
  }
  prioritizedLhsp = _marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, topasciis, 1 /* createb */, 0 /* forcecreateb */, 1 /* lhsb */, NULL /* declp */, 0 /* rhsb */, NULL /* callp */);
  if (MARPAESLIF_UNLIKELY(prioritizedLhsp == NULL)) {
    goto err;
  }

  /* Create the rule lhs(declp) := lhs[0](callp = declp) action => ::shift */
  MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Creating priority rule %s ::= %s at grammar level %d", lhsp->descp->asciis, prioritizedLhsp->descp->asciis, grammarBootstrapp->leveli);
  rulep = _marpaESLIF_bootstrap_check_rulep(marpaESLIFValuep,
                                            marpaESLIFGrammarBootstrapp,
                                            grammarBootstrapp,
                                            NULL, /* descEncodings */
                                            NULL, /* descs */
                                            0, /* descl */
                                            lhsp->idi,
                                            1, /* nrhsl */
                                            &(prioritizedLhsp->idi), /* rhsip */
                                            -1, /* exceptioni */
                                            0, /* ranki */
                                            0, /* nullRanksHighb */
                                            0, /* sequenceb */
                                            -1, /* minimumi */
                                            -1, /* separatori */
                                            0, /* properb */
                                            &action,
                                            0 /* hideseparatorb */,
                                            NULL, /* skipbp */
                                            declp,
                                            &decl2callp,
                                            NULL /* separatorcallp */);
  if (MARPAESLIF_UNLIKELY(rulep == NULL)) {
    goto err;
  }
  GENERICSTACK_SET_PTR(grammarBootstrapp->ruleStackp, rulep, rulep->idi);
  if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(grammarBootstrapp->ruleStackp))) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "ruleStackp set failure, %s", strerror(errno));
    goto err;
  }

  /* We construct a new alternativesStackp as if the loosen operator was absent, as if the user would have writen the BNF the old way. */
  GENERICSTACK_NEW(flatAlternativesStackp);
  if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(flatAlternativesStackp))) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "flatAlternativesStackp initialization failure, %s", strerror(errno));
    goto err;
  }
  GENERICSTACK_NEW(flatAlternativeStackp);
  if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(flatAlternativeStackp))) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "flatAlternativeStackp initialization failure, %s", strerror(errno));
    goto err;
  }
  GENERICSTACK_PUSH_PTR(flatAlternativesStackp, flatAlternativeStackp);
  if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(flatAlternativesStackp))) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "flatAlternativesStackp push failure, %s", strerror(errno));
    goto err;
  }

  /* Create transition rules (remember, it is guaranteed that priorityCounti > 1 here */
  for (priorityi = 1; priorityi <= priorityCounti-1; priorityi++) {
    sprintf(tmps, "%d", priorityi - 1);
    if (currentasciis != NULL) {
      free(currentasciis);
    }
    currentasciis = (char *) malloc(strlen(lhsp->u.metap->asciinames) + 1 /* [ */ + strlen(tmps) + 1 /* ] */ + 1 /* NUL */);
    if (MARPAESLIF_UNLIKELY(currentasciis == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
      goto err;
    }
    strcpy(currentasciis, lhsp->u.metap->asciinames);
    strcat(currentasciis, "[");
    strcat(currentasciis, tmps);
    strcat(currentasciis, "]");
    prioritizedLhsp = _marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, currentasciis, 1 /* createb */, 0 /* forcecreateb */, 1 /* lhsb */, NULL /* declp */, 0 /* rhsb */, NULL /* callp */);
    if (MARPAESLIF_UNLIKELY(prioritizedLhsp == NULL)) {
      goto err;
    }

    sprintf(tmps, "%d", priorityi);
    if (nextasciis != NULL) {
      free(nextasciis);
    }
    nextasciis = (char *) malloc(strlen(lhsp->u.metap->asciinames) + 1 /* [ */ + strlen(tmps) + 1 /* ] */ + 1 /* NUL */);
    if (MARPAESLIF_UNLIKELY(nextasciis == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
      goto err;
    }
    strcpy(nextasciis, lhsp->u.metap->asciinames);
    strcat(nextasciis, "[");
    strcat(nextasciis, tmps);
    strcat(nextasciis, "]");
    nextPrioritizedLhsp = _marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, nextasciis, 1 /* createb */, 0 /* forcecreateb */, 1 /* lhsb */, NULL /* declp */, 0 /* rhsb */, NULL /* callp */);
    if (MARPAESLIF_UNLIKELY(nextPrioritizedLhsp == NULL)) {
      goto err;
    }

    /* Create the transition rule lhs[priorityi-1] := lhs[priorityi] action => ::shift */
    MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Creating transition rule %s(declp) ::= %s(callp = declp) at grammar level %d", prioritizedLhsp->descp->asciis, nextPrioritizedLhsp->descp->asciis, grammarBootstrapp->leveli);
    rulep = _marpaESLIF_bootstrap_check_rulep(marpaESLIFValuep,
                                              marpaESLIFGrammarBootstrapp,
                                              grammarBootstrapp,
                                              NULL, /* descEncodings */
                                              NULL, /* descs */
                                              0, /* descl */
                                              prioritizedLhsp->idi,
                                              1, /* nrhsl */
                                              &(nextPrioritizedLhsp->idi), /* rhsip */
                                              -1, /* exceptioni */
                                              0, /* ranki */
                                              0, /* nullRanksHighb */
                                              0, /* sequenceb */
                                              -1, /* minimumi */
                                              -1, /* separatori */
                                              0, /* properb */
                                              &action,
                                              0 /* hideseparatorb */,
                                              NULL, /* skipbp */
                                              declp,
                                              &decl2callp,
                                              NULL /* separatorcallp */);
    if (MARPAESLIF_UNLIKELY(rulep == NULL)) {
      goto err;
    }
    GENERICSTACK_SET_PTR(grammarBootstrapp->ruleStackp, rulep, rulep->idi);
    if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(grammarBootstrapp->ruleStackp))) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "ruleStackp set failure, %s", strerror(errno));
      goto err;
    }
  }

  /* Evaluate current priority of every alternative, change symbols, and push it in the flat version */
  for (alternativesi = 0; alternativesi < priorityCounti; alternativesi++) {
#ifndef MARPAESLIF_NTRACE
    /* Should never happen */
    if (MARPAESLIF_UNLIKELY(! GENERICSTACK_IS_PTR(alternativesStackp, alternativesi))) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "alternativesStackp at indice %d is not PTR (got %s, value %d)", alternativesi, _marpaESLIF_genericStack_i_types(alternativesStackp, alternativesi), GENERICSTACKITEMTYPE(alternativesStackp, alternativesi));
      goto err;
    }
#endif

    priorityi = priorityCounti - (alternativesi + 1);

    /* Rework current LHS to be lhs[priorityi] */
    /* Will an "int" ever have more than 1022 digits ? */
    sprintf(tmps, "%d", priorityi);
    if (currentasciis != NULL) {
      free(currentasciis);
    }
    currentasciis = (char *) malloc(strlen(lhsp->u.metap->asciinames) + 1 /* [ */ + strlen(tmps) + 1 /* ] */ + 1 /* NUL */);
    if (MARPAESLIF_UNLIKELY(currentasciis == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
      goto err;
    }
    strcpy(currentasciis, lhsp->u.metap->asciinames);
    strcat(currentasciis, "[");
    strcat(currentasciis, tmps);
    strcat(currentasciis, "]");
    prioritizedLhsp = _marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, currentasciis, 1 /* createb */, 0 /* forcecreateb */, 1 /* lhsb */, NULL /* declp */, 0 /* rhsb */, NULL /* callp */);
    if (MARPAESLIF_UNLIKELY(prioritizedLhsp == NULL)) {
      goto err;
    }

    /* Rework next LHS to be lhs[nextPriorityi] */
    nextPriorityi = priorityi + 1;
    /* Original Marpa::R2 calculus is $next_priority = 0 if $next_priority >= $priority_count */
    /* And a comment says this is probably a misfeature that the author did not fix for backward */
    /* compatibility issues on a quite rare case. */
    if (nextPriorityi >= priorityCounti) {
      nextPriorityi = priorityi;
    }
    sprintf(tmps, "%d", nextPriorityi);
    if (nextasciis != NULL) {
      free(nextasciis);
    }
    nextasciis = (char *) malloc(strlen(lhsp->u.metap->asciinames) + 1 /* [ */ + strlen(tmps) + 1 /* ] */ + 1 /* NUL */);
    if (MARPAESLIF_UNLIKELY(nextasciis == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
      goto err;
    }
    strcpy(nextasciis, lhsp->u.metap->asciinames);
    strcat(nextasciis, "[");
    strcat(nextasciis, tmps);
    strcat(nextasciis, "]");
    nextPrioritizedLhsp = _marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, nextasciis, 1 /* createb */, 0 /* forcecreateb */, 1 /* lhsb */, NULL /* declp */, 0 /* rhsb */, NULL /* callp */);
    if (MARPAESLIF_UNLIKELY(nextPrioritizedLhsp == NULL)) {
      goto err;
    }

    /* Things separator by the | operator: this is a stack of <alternative> */
    alternativeStackp = GENERICSTACK_GET_PTR(alternativesStackp, alternativesi);
    for (alternativei = 0; alternativei < GENERICSTACK_USED(alternativeStackp); alternativei++) {
#ifndef MARPAESLIF_NTRACE
      /* Should never happen */
      if (MARPAESLIF_UNLIKELY(! GENERICSTACK_IS_PTR(alternativeStackp, alternativei))) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "alternativeStackp at indice %d is not PTR (got %s, value %d)", alternativei, _marpaESLIF_genericStack_i_types(alternativeStackp, alternativei), GENERICSTACKITEMTYPE(alternativeStackp, alternativei));
        goto err;
      }
#endif
      alternativep = (marpaESLIF_bootstrap_alternative_t *) GENERICSTACK_GET_PTR(alternativeStackp, alternativei);
      /* Alternatives is a stack of RHS followed by adverb items */
      alternativep->priorityi = priorityi;

      /* Look for arity */
      arityi = 0;
      if (arityip != NULL) {
        free(arityip);
      }
      rhsAlternativeStackp = alternativep->rhsAlternativeStackp;
      adverbListItemStackp = alternativep->adverbListItemStackp;
      /* As per the grammar, it is not possible that rhsAlternativeStackp is empty */
      nrhsi = GENERICSTACK_USED(rhsAlternativeStackp);
      arityip = (int *) malloc(nrhsi * sizeof(int));
      if (MARPAESLIF_UNLIKELY(arityip == NULL)) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
        goto err;
      }

      /* Every occurence of LHS in the RHS list increases the arity */
      for (rhsi = 0; rhsi < nrhsi; rhsi++) {
#ifndef MARPAESLIF_NTRACE
        /* Should never happen */
        if (MARPAESLIF_UNLIKELY(! GENERICSTACK_IS_PTR(rhsAlternativeStackp, rhsi))) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "rhsAlternativeStackp at indice %d is not PTR (got %s, value %d)", rhsi, _marpaESLIF_genericStack_i_types(rhsAlternativeStackp, rhsi), GENERICSTACKITEMTYPE(rhsAlternativeStackp, rhsi));
          goto err;
        }
#endif
        rhsAlternativep = (marpaESLIF_bootstrap_rhs_alternative_t *) GENERICSTACK_GET_PTR(rhsAlternativeStackp, rhsi);
        rhsp = _marpaESLIF_bootstrap_check_rhsAlternativep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, rhsAlternativep, 1 /* createb */, declp);
        if (MARPAESLIF_UNLIKELY(rhsp == NULL)) {
          goto err;
        }
        if (rhsp == lhsp) {
          arityip[arityi++] = rhsi;
        }
      }

      /* Look to association */
      if (MARPAESLIF_UNLIKELY(! _marpaESLIF_bootstrap_unpack_adverbListItemStackb(marpaESLIFValuep,
                                                                                  "prioritized rule",
                                                                                  adverbListItemStackp,
                                                                                  &actionp,
                                                                                  &left_associationb,
                                                                                  &right_associationb,
                                                                                  &group_associationb,
                                                                                  NULL, /* separatorRhsPrimarypp */
                                                                                  NULL, /* properbp */
                                                                                  NULL, /* verbosebpp */
                                                                                  NULL, /* hideseparatorbp */
                                                                                  &ranki,
                                                                                  &nullRanksHighb,
                                                                                  NULL, /* priorityipp */
                                                                                  NULL, /* pauseip */
                                                                                  NULL, /* latmbp */
                                                                                  NULL, /* discardIsFallbackbp */
                                                                                  &namingp,
                                                                                  NULL, /* symbolactionpp */
                                                                                  NULL, /* eventInitializationpp */
                                                                                  NULL, /* ifactionpp */
                                                                                  NULL, /* regexactionpp */
                                                                                  NULL, /* eventactionpp */
                                                                                  NULL, /* defaultEncodingsp */
                                                                                  NULL /* fallbackEncodingsp */
                                                                                  ))) {
        goto err;
      }

      /* Associations are mutually exclusive */
      if (MARPAESLIF_UNLIKELY((left_associationb + right_associationb + group_associationb) > 1)) {
        MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "assoc => left, assoc => right and assoc => group are mutually exclusive");
        goto err;
      }
      /* Default assocativity is left */
      if ((left_associationb + right_associationb + group_associationb) <= 0) {
        left_associationb = 1;
      }

      /* Rework the RHS list by replacing the symbols matching the LHS */
      MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "alternativesStackp[%d] alternativeStackp[%d] currentLeft=<%s> nextLeft=<%s> priorityi=%d nrhsi=%d arityi=%d assoc=%s", alternativesi, alternativei, currentasciis, nextasciis, priorityi, nrhsi, arityi, left_associationb ? "left" : (right_associationb ? "right" : (group_associationb ? "group" : "unknown")));

      if (arityi > 0) {
        if (MARPAESLIF_UNLIKELY((arityi == 1) && (nrhsi == 1))) {
          /* Something like Expression ::= Expression in a prioritized rule -; */
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unnecessary unit rule <%s> in priority rule", lhsp->u.metap->asciinames);
          goto err;
        }

        /* Do the association by reworking RHS's matching the LHS */
        for (arityixi = 0; arityixi < arityi; arityixi++) {
          rhsi = arityip[arityixi];
#ifndef MARPAESLIF_NTRACE
          /* Should never happen */
          if (MARPAESLIF_UNLIKELY(! GENERICSTACK_IS_PTR(rhsAlternativeStackp, rhsi))) {
            MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "rhsAlternativeStackp at indice %d is not PTR (got %s, value %d)", rhsi, _marpaESLIF_genericStack_i_types(rhsAlternativeStackp, rhsi), GENERICSTACKITEMTYPE(rhsAlternativeStackp, rhsi));
            goto err;
          }
#endif
          rhsAlternativep = (marpaESLIF_bootstrap_rhs_alternative_t *) GENERICSTACK_GET_PTR(rhsAlternativeStackp, rhsi);
          _marpaESLIF_bootstrap_rhs_alternative_freev(prioritizedRhsAlternativep);
          prioritizedRhsAlternativep = (marpaESLIF_bootstrap_rhs_alternative_t *)  malloc(sizeof(marpaESLIF_bootstrap_rhs_alternative_t));
          if (MARPAESLIF_UNLIKELY(prioritizedRhsAlternativep == NULL)) {
            MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
            goto err;
          }
          prioritizedRhsAlternativep->type          = MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_RHS_PRIMARY;
          prioritizedRhsAlternativep->u.rhsPrimaryp = (marpaESLIF_bootstrap_rhs_primary_t *) malloc(sizeof(marpaESLIF_bootstrap_rhs_primary_t));
          if (MARPAESLIF_UNLIKELY(prioritizedRhsAlternativep->u.rhsPrimaryp == NULL)) {
            MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
            goto err;
          }
          prioritizedRhsAlternativep->u.rhsPrimaryp->callp             = NULL;
          prioritizedRhsAlternativep->u.rhsPrimaryp->type              = MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_SINGLE_SYMBOL;
          prioritizedRhsAlternativep->u.rhsPrimaryp->u.singleSymbolp   = (marpaESLIF_bootstrap_single_symbol_t *) malloc(sizeof(marpaESLIF_bootstrap_single_symbol_t));
          if (MARPAESLIF_UNLIKELY(prioritizedRhsAlternativep->u.rhsPrimaryp->u.singleSymbolp == NULL)) {
            MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
            goto err;
          }
          prioritizedRhsAlternativep->u.rhsPrimaryp->u.singleSymbolp->type      = MARPAESLIF_BOOTSTRAP_SINGLE_SYMBOL_TYPE_SYMBOL;
          prioritizedRhsAlternativep->u.rhsPrimaryp->u.singleSymbolp->u.symbolp = (marpaESLIF_bootstrap_symbol_t *) malloc(sizeof(marpaESLIF_bootstrap_symbol_t));
          if (MARPAESLIF_UNLIKELY(prioritizedRhsAlternativep->u.rhsPrimaryp->u.singleSymbolp->u.symbolp == NULL)) {
            MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
            goto err;
          }

          if (declp != NULL) {
            prioritizedRhsAlternativep->u.rhsPrimaryp->callp = _marpaESLIF_lua_functioncall_newp(marpaESLIFValuep->marpaESLIFp);
            if (prioritizedRhsAlternativep->u.rhsPrimaryp->callp == NULL) {
              MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
              goto err;
            }
            prioritizedRhsAlternativep->u.rhsPrimaryp->callp->luaexplistcb = 1; /* Declaration can always be inlined */
            prioritizedRhsAlternativep->u.rhsPrimaryp->callp->luaexplists  = strdup(declp->luaparlists);
            if (prioritizedRhsAlternativep->u.rhsPrimaryp->callp->luaexplists == NULL) {
              MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "strdup failure, %s", strerror(errno));
              goto err;
            }
          }

          if (left_associationb) {
            prioritizedRhsAlternativep->u.rhsPrimaryp->u.singleSymbolp->u.symbolp->symbols = (arityixi == 0)            ? strdup(currentasciis) : strdup(nextasciis);
          } else if (right_associationb) {
            prioritizedRhsAlternativep->u.rhsPrimaryp->u.singleSymbolp->u.symbolp->symbols = (arityixi == (arityi - 1)) ? strdup(currentasciis) : strdup(nextasciis);
          } else if (group_associationb) {
            prioritizedRhsAlternativep->u.rhsPrimaryp->u.singleSymbolp->u.symbolp->symbols = strdup(topasciis);
          } else {
            /* Should never happen */
            MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "No association !?");
            goto err;
          }

          if (MARPAESLIF_UNLIKELY(prioritizedRhsAlternativep->u.rhsPrimaryp->u.singleSymbolp->u.symbolp->symbols == NULL)) {
            MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "strdup failure, %s", strerror(errno));
            goto err;
          }

          /* All is well, we can replace this rhs alternative with the new one */
          GENERICSTACK_SET_PTR(rhsAlternativeStackp, prioritizedRhsAlternativep, rhsi);
          if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(rhsAlternativeStackp))) {
            MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "rhsAlternativeStackp set failure, %s", strerror(errno));
            goto err;
          }
          MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "alternativesStackp[%d] alternativeStackp[%d] ... LHS is %s, RHS[%d] is now %s", alternativesi, alternativei, currentasciis, rhsi, prioritizedRhsAlternativep->u.rhsPrimaryp->u.singleSymbolp->u.symbolp->symbols);
          prioritizedRhsAlternativep = NULL; /* prioritizedRhsAlternativep is in rhsAlternativeStackp */
          /* We can forget the old one */
          _marpaESLIF_bootstrap_rhs_alternative_freev(rhsAlternativep);
        }
      }

      GENERICSTACK_PUSH_PTR(flatAlternativeStackp, alternativep);
      if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(flatAlternativeStackp))) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "flatAlternativeStackp push failure, %s", strerror(errno));
        goto err;
      }

      /* We force the LHS for EVERY alternative */
      alternativep->forcedLhsp = prioritizedLhsp;
    }
  }

  /* Create the prioritized alternatives */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_bootstrap_G1_action_priority_flat_ruleb(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, NULL /* lhsp */, flatAlternativesStackp, "prioritized alternatives", declp))) {
    goto err;
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  if (arityip != NULL) {
    free(arityip);
  }
  if (currentasciis != NULL) {
    free(currentasciis);
  }
  if (nextasciis != NULL) {
    free(nextasciis);
  }
  if (topasciis != NULL) {
    free(topasciis);
  }
  _marpaESLIF_bootstrap_rhs_alternative_freev(prioritizedRhsAlternativep);
  GENERICSTACK_FREE(flatAlternativesStackp);
  GENERICSTACK_FREE(flatAlternativeStackp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIF_bootstrap_G1_action_priority_flat_ruleb(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, marpaESLIF_symbol_t *lhsp, genericStack_t *alternativesStackp, char *contexts, marpaESLIF_lua_functiondecl_t *declp)
/*****************************************************************************/
{
  /* <priority rule> ::= lhs <op declare> priorities */
  /* This method is called when there is no more than one priority. It is ignoring the notion of priority. */
  static const char                       *funcs             = "_marpaESLIF_bootstrap_G1_action_priority_flat_ruleb";
  marpaESLIF_rule_t                       *rulep             = NULL;
  int                                     *rhsip             = NULL;
  marpaESLIF_lua_functioncall_t          **callpp            = NULL;
  short                                   *skipbp            = NULL;
  marpaESLIF_symbol_t                    **rhsp              = NULL;
  short                                    have_skipb;
  int                                      nrhsi;
  genericStack_t                          *alternativeStackp;
  genericStack_t                          *rhsAlternativeStackp;
  genericStack_t                          *adverbListItemStackp;
  int                                      alternativesi;
  int                                      alternativei;
  int                                      rhsAlternativei;
  marpaESLIF_bootstrap_alternative_t      *alternativep;
  marpaESLIF_bootstrap_rhs_alternative_t  *rhsAlternativep;
  short                                    rcb;
  short                                    left_associationb;
  short                                    right_associationb;
  short                                    group_associationb;
  int                                      ranki;
  short                                    nullRanksHighb;
  marpaESLIF_bootstrap_utf_string_t       *namingp;
  marpaESLIF_action_t                     *actionp;
  marpaESLIF_lua_functioncall_t            decl2call;
  marpaESLIF_lua_functioncall_t           *decl2callp;

  if (declp != NULL) {
    decl2call.luaexplists  = declp->luaparlists;
    decl2call.luaexplistcb = declp->luaparlistcb;
    decl2call.sizei        = declp->sizei;
    decl2callp = &decl2call;
  } else {
    decl2callp = NULL;
  }

  /* Priorities (things separated by the || operator) are IGNORED in this method */
  MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Processing %d '|' rules (context: %s)", GENERICSTACK_USED(alternativesStackp), contexts);
  for (alternativesi = 0; alternativesi < GENERICSTACK_USED(alternativesStackp); alternativesi++) {
#ifndef MARPAESLIF_NTRACE
    /* Should never happen */
    if (MARPAESLIF_UNLIKELY(! GENERICSTACK_IS_PTR(alternativesStackp, alternativesi))) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "alternativesStackp at indice %d is not PTR (got %s, value %d)", alternativesi, _marpaESLIF_genericStack_i_types(alternativesStackp, alternativesi), GENERICSTACKITEMTYPE(alternativesStackp, alternativesi));
      goto err;
    }
#endif
    /* Alternatives (things separator by the | operator) is a stack of alternative */
    alternativeStackp = GENERICSTACK_GET_PTR(alternativesStackp, alternativesi);
    for (alternativei = 0; alternativei < GENERICSTACK_USED(alternativeStackp); alternativei++) {
#ifndef MARPAESLIF_NTRACE
      /* Should never happen */
      if (MARPAESLIF_UNLIKELY(! GENERICSTACK_IS_PTR(alternativeStackp, alternativei))) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "alternativeStackp at indice %d is not PTR (got %s, value %d)", alternativei, _marpaESLIF_genericStack_i_types(alternativeStackp, alternativei), GENERICSTACKITEMTYPE(alternativeStackp, alternativei));
        goto err;
      }
#endif
      alternativep = (marpaESLIF_bootstrap_alternative_t *) GENERICSTACK_GET_PTR(alternativeStackp, alternativei);
      /* Alternatives is a stack of RHS followed by adverb items */
      rhsAlternativeStackp = alternativep->rhsAlternativeStackp;
      adverbListItemStackp = alternativep->adverbListItemStackp;

      nrhsi = GENERICSTACK_USED(rhsAlternativeStackp);
      if (nrhsi > 0) {
        rhsip = (int *) malloc(nrhsi * sizeof(int));
        if (MARPAESLIF_UNLIKELY(rhsip == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
          goto err;
        }
        for (rhsAlternativei = 0; rhsAlternativei < nrhsi; rhsAlternativei++) {
          rhsip[rhsAlternativei] = -1;
        }

        callpp = (marpaESLIF_lua_functioncall_t **) malloc(nrhsi * sizeof(marpaESLIF_lua_functioncall_t *));
        if (callpp == NULL) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
          goto err;
        }
        for (rhsAlternativei = 0; rhsAlternativei < nrhsi; rhsAlternativei++) {
          callpp[rhsAlternativei] = NULL;
        }

        rhsp = (marpaESLIF_symbol_t **) malloc(nrhsi * sizeof(marpaESLIF_symbol_t *));
        if (MARPAESLIF_UNLIKELY(rhsp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
          goto err;
        }
        for (rhsAlternativei = 0; rhsAlternativei < nrhsi; rhsAlternativei++) {
          rhsp[rhsAlternativei] = NULL;
        }

        skipbp = (short *) malloc(nrhsi * sizeof(short));
        if (MARPAESLIF_UNLIKELY(skipbp == NULL)) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
          goto err;
        }
        for (rhsAlternativei = 0; rhsAlternativei < nrhsi; rhsAlternativei++) {
          skipbp[rhsAlternativei] = 0;
        }
      } else {
        rhsip = NULL;
        callpp = NULL;
        rhsp = NULL;
        skipbp = NULL;
      }

      /* Analyse alternative list */
      have_skipb = 0;
      for (rhsAlternativei = 0; rhsAlternativei < nrhsi; rhsAlternativei++) {
#ifndef MARPAESLIF_NTRACE
        /* Should never happen */
        if (MARPAESLIF_UNLIKELY(! GENERICSTACK_IS_PTR(rhsAlternativeStackp, rhsAlternativei))) {
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "alternativeStackp at indice %d is not PTR (got %s, value %d)", rhsAlternativei, _marpaESLIF_genericStack_i_types(rhsAlternativeStackp, rhsAlternativei), GENERICSTACKITEMTYPE(rhsAlternativeStackp, rhsAlternativei));
          goto err;
        }
#endif
        rhsAlternativep = (marpaESLIF_bootstrap_rhs_alternative_t *) GENERICSTACK_GET_PTR(rhsAlternativeStackp, rhsAlternativei);
        rhsp[rhsAlternativei] = _marpaESLIF_bootstrap_check_rhsAlternativep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, rhsAlternativep, 1 /* createb */, declp);
        if (MARPAESLIF_UNLIKELY(rhsp[rhsAlternativei] == NULL)) {
          goto err;
        }
        rhsip[rhsAlternativei] = rhsp[rhsAlternativei]->idi;

        /* Two categories: with () and without () */
        switch (rhsAlternativep->type) {
        case MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_RHS_PRIMARY:
          skipbp[rhsAlternativei] = 0;
          callpp[rhsAlternativei] = rhsAlternativep->u.rhsPrimaryp->callp; /* Without (): _marpaESLIF_bootstrap_check_rhsAlternativep returned directly the symbol */
          break;
        case MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_PRIORITIES:
          skipbp[rhsAlternativei] = rhsAlternativep->u.priorities.skipb;
          callpp[rhsAlternativei] = decl2callp; /* With (): _marpaESLIF_bootstrap_check_rhsAlternativep returned an internal symbol */
        break;
        case MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_EXCEPTION:
          skipbp[rhsAlternativei] = rhsAlternativep->u.exception.skipb;
          callpp[rhsAlternativei] = decl2callp; /* With (): _marpaESLIF_bootstrap_check_rhsAlternativep returned an internal symbol */
          break;
        case MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_QUANTIFIED:
          skipbp[rhsAlternativei] = rhsAlternativep->u.quantified.skipb;
          callpp[rhsAlternativei] = decl2callp; /* With (): _marpaESLIF_bootstrap_check_rhsAlternativep returned an internal symbol */
          break;
        default:
          MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Invalid alternative type %d", rhsAlternativep->type);
          goto err;
        }

        if (skipbp[rhsAlternativei]) {
          have_skipb = 1;
        }
      }

      /* Analyse adverb list items - take care this is nullable and we propagate NULL if it is the case */
      /* Same arguments than in the loose version, except that we will ignore association adverbs */
      left_associationb  = 0;
      right_associationb = 0;
      group_associationb = 0;
      ranki              = 0;
      nullRanksHighb     = 0;
      namingp            = NULL;
      actionp            = NULL;
      if (MARPAESLIF_UNLIKELY(! _marpaESLIF_bootstrap_unpack_adverbListItemStackb(marpaESLIFValuep,
                                                                                  contexts,
                                                                                  adverbListItemStackp,
                                                                                  &actionp,
                                                                                  &left_associationb,
                                                                                  &right_associationb,
                                                                                  &group_associationb,
                                                                                  NULL, /* separatorRhsPrimarypp */
                                                                                  NULL, /* properbp */
                                                                                  NULL, /* verbosebpp */
                                                                                  NULL, /* hideseparatorbp */
                                                                                  &ranki,
                                                                                  &nullRanksHighb,
                                                                                  NULL, /* priorityipp */
                                                                                  NULL, /* pauseip */
                                                                                  NULL, /* latmbp */
                                                                                  NULL, /* discardIsFallbackbp */
                                                                                  &namingp,
                                                                                  NULL, /* symbolactionpp */
                                                                                  NULL, /* eventInitializationpp */
                                                                                  NULL, /* ifactionpp */
                                                                                  NULL, /* regexactionpp */
                                                                                  NULL, /* eventactionpp */
                                                                                  NULL, /* defaultEncodingsp */
                                                                                  NULL /* fallbackEncodingsp */
                                                                                  ))) {
        goto err;
      }
#ifndef MARPAESLIF_NTRACE
      MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Creating flat rule %s at grammar level %d", (alternativep->forcedLhsp != NULL) ? alternativep->forcedLhsp->descp->asciis : lhsp->descp->asciis, grammarBootstrapp->leveli);
      MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "... LHS     : %d %s", (alternativep->forcedLhsp != NULL) ? alternativep->forcedLhsp->idi : lhsp->idi, (alternativep->forcedLhsp != NULL) ? alternativep->forcedLhsp->descp->asciis : lhsp->descp->asciis);
      for (rhsAlternativei = 0; rhsAlternativei < nrhsi; rhsAlternativei++) {
        MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "... RHS[%3d]: %d %s", rhsAlternativei, rhsp[rhsAlternativei]->idi, rhsp[rhsAlternativei]->descp->asciis);
      }
#endif
      /* If naming is not NULL, it is guaranteed to be an UTF-8 thingy */
      rulep = _marpaESLIF_bootstrap_check_rulep(marpaESLIFValuep,
                                                marpaESLIFGrammarBootstrapp,
                                                grammarBootstrapp,
                                                (namingp != NULL) ? (char *) MARPAESLIF_UTF8_STRING : NULL, /* descEncodings */
                                                (namingp != NULL) ? namingp->bytep : NULL, /* descs */
                                                (namingp != NULL) ? namingp->bytel : 0, /* descl */
                                                (alternativep->forcedLhsp != NULL) ? alternativep->forcedLhsp->idi : lhsp->idi,
                                                (size_t) nrhsi,
                                                rhsip,
                                                -1, /* exceptioni */
                                                ranki,
                                                nullRanksHighb,
                                                0, /* sequenceb */
                                                -1, /* minimumi */
                                                -1, /* separatori */
                                                0, /* properb */
                                                actionp,
                                                0 /* hideseparatorb */,
                                                have_skipb ? skipbp : NULL,
                                                declp,
                                                callpp,
                                                NULL);
      if (MARPAESLIF_UNLIKELY(rulep == NULL)) {
        goto err;
      }
      if (rhsip != NULL) {
        free(rhsip);
        rhsip = NULL;
      }
      if (callpp != NULL) {
        free(callpp);
        callpp = NULL;
      }
      if (rhsp != NULL) {
        free(rhsp);
        rhsp = NULL;
      }
      if (skipbp != NULL) {
        free(skipbp);
        skipbp = NULL;
      }
      GENERICSTACK_SET_PTR(grammarBootstrapp->ruleStackp, rulep, rulep->idi);
      if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(grammarBootstrapp->ruleStackp))) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "ruleStackp set failure, %s", strerror(errno));
        goto err;
      }
      /* Push is ok: rulep is in grammarBootstrapp->ruleStackp */
      rulep = NULL;
    }
  }
  /* We set nothing in the stack, our parent will return ::undef up to the top-level */
  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  if (rhsip != NULL) {
    free(rhsip);
  }
  if (callpp != NULL) {
    free(callpp);
  }
  if (rhsp != NULL) {
    free(rhsp);
  }
  if (skipbp != NULL) {
    free(skipbp);
  }
  _marpaESLIF_rule_freev(rulep);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_priority_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <priority rule> ::= <lhs> <op declare> priorities */
  /* **** The result will be undef **** */
  /* **** We work on userDatavp, that is a marpaESLIFGrammarBootstrapp **** */
  /* **** In case of failure, the caller that is marpaESLIFGrammar_newp() will call a free on this marpaESLIFGrammarBootstrapp **** */
  marpaESLIFGrammar_bootstrap_t   *marpaESLIFGrammarBootstrapp = (marpaESLIFGrammar_bootstrap_t *) userDatavp;
  marpaESLIF_bootstrap_lhs_t      *bootstrapLhsp               = NULL;
  genericStack_t                  *alternativesStackp          = NULL;
  int                             leveli;
  marpaESLIF_grammar_bootstrap_t *grammarBootstrapp;
  marpaESLIF_symbol_t            *lhsp;
  short                           rcb;

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i, bootstrapLhsp);
  if (MARPAESLIF_UNLIKELY(bootstrapLhsp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "bootstrapLhsp is NULL");
    goto err;
  }
  MARPAESLIF_BOOTSTRAP_GET_INT(marpaESLIFValuep, arg0i+1, leveli);
  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i+2, alternativesStackp);
  if (MARPAESLIF_UNLIKELY(alternativesStackp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "alternativesStackp is NULL");
    goto err;
  }

  /* Check grammar at that level exist */
  grammarBootstrapp = _marpaESLIF_bootstrap_check_grammarBootstrapp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, leveli, NULL);
  if (MARPAESLIF_UNLIKELY(grammarBootstrapp == NULL)) {
    goto err;
  }

  /* Check the lhs exist */
  lhsp = _marpaESLIF_bootstrap_check_lhsp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, bootstrapLhsp);
  if (MARPAESLIF_UNLIKELY(lhsp == NULL)) {
    goto err;
  }

  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_bootstrap_G1_action_priority_loosen_ruleb(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, lhsp, alternativesStackp, bootstrapLhsp->declp))) {
    goto err;
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_lhs_freev(bootstrapLhsp);
  _marpaESLIF_bootstrap_priorities_freev(alternativesStackp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_single_symbol_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <single symbol> ::= <symbol> */
  marpaESLIF_bootstrap_single_symbol_t *singleSymbolp = NULL;
  marpaESLIF_bootstrap_symbol_t        *symbolp       = NULL;
  short                                 rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i, symbolp);
  /* It is a non-sense to have a null symbolp */
  if (MARPAESLIF_UNLIKELY(symbolp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "symbolp at indice %d is NULL", argni);
    goto err;
  }

  singleSymbolp = (marpaESLIF_bootstrap_single_symbol_t *) malloc(sizeof(marpaESLIF_bootstrap_single_symbol_t));
  if (MARPAESLIF_UNLIKELY(singleSymbolp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  singleSymbolp->type      = MARPAESLIF_BOOTSTRAP_SINGLE_SYMBOL_TYPE_SYMBOL;
  singleSymbolp->u.symbolp = symbolp;
  symbolp = NULL; /* symbolp is in singleSymbolp */

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_SINGLE_SYMBOL, singleSymbolp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_single_symbol_freev(singleSymbolp);
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_symbol_freev(symbolp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_single_symbol_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <single symbol> ::= <terminal> */
  marpaESLIF_bootstrap_single_symbol_t *singleSymbolp = NULL;
  marpaESLIF_bootstrap_terminal_t      *terminalp     = NULL;
  short                                 rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i, terminalp);
  /* It is a non-sense to have a null terminalp */
  if (MARPAESLIF_UNLIKELY(terminalp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "terminalp at indice %d is NULL", argni);
    goto err;
  }

  singleSymbolp = (marpaESLIF_bootstrap_single_symbol_t *) malloc(sizeof(marpaESLIF_bootstrap_single_symbol_t));
  if (MARPAESLIF_UNLIKELY(singleSymbolp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  singleSymbolp->type        = MARPAESLIF_BOOTSTRAP_SINGLE_SYMBOL_TYPE_TERMINAL;
  singleSymbolp->u.terminalp = terminalp;
  terminalp = NULL; /* terminalp is in singleSymbolp */

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_SINGLE_SYMBOL, singleSymbolp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_single_symbol_freev(singleSymbolp);
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_terminal_freev(terminalp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_terminal_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <terminal> ::= <character class> */
  /* <character class> is a lexeme. */
  marpaESLIF_bootstrap_terminal_t *terminalp   = NULL;
  void                            *bytep;
  size_t                           bytel;
  short                            rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i, bytep, bytel);

  terminalp = (marpaESLIF_bootstrap_terminal_t *) malloc(sizeof(marpaESLIF_bootstrap_terminal_t));
  if (MARPAESLIF_UNLIKELY(terminalp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  terminalp->type              = MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE_NA;
  terminalp->u.characterClassp = _marpaESLIF_bootstrap_characterClass_to_stringp(marpaESLIFValuep->marpaESLIFp, bytep, bytel);
  if (MARPAESLIF_UNLIKELY(terminalp->u.characterClassp == NULL)) {
    goto err;
  }
  terminalp->type              = MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE_CHARACTER_CLASS;

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_TERMINAL, terminalp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_terminal_freev(terminalp);
  rcb = 0;

 done:
 return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_terminal_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <terminal> ::= <regular expression> */
  /* <regular expression> is a lexeme. */
  marpaESLIF_bootstrap_terminal_t *terminalp   = NULL;
  void                            *bytep;
  size_t                           bytel;
  short                            rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i, bytep, bytel);

  terminalp = _marpaESLIF_bootstrap_regex_to_terminalp(userDatavp, marpaESLIFValuep, bytep, bytel);
  if (MARPAESLIF_UNLIKELY(terminalp == NULL)) {
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_TERMINAL, terminalp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_terminal_freev(terminalp);
  rcb = 0;

 done:
 return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_terminal_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <terminal> ::= <quoted string> */
  marpaESLIF_bootstrap_terminal_t *terminalp = NULL;
  void                            *bytep;
  size_t                           bytel;
  short                            rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  /* action is the result of ::transfer, i.e. a lexeme in any case  */
  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i, bytep, bytel);
  /* It is a non-sense to not have valid information */
  if (MARPAESLIF_UNLIKELY((bytep == NULL) || (bytel <= 0))) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "_marpaESLIFValue_stack_getb at indice %d returned {%p,%ld}", arg0i, bytep, (unsigned long) bytel);
    goto err;
  }

  terminalp = _marpaESLIF_bootstrap_quotedstring_to_terminalp(userDatavp, marpaESLIFValuep, bytep, bytel, marpaESLIFValuep->marpaESLIFp->stringModifiersp);
  if (MARPAESLIF_UNLIKELY(terminalp == NULL)) {
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_TERMINAL, terminalp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_terminal_freev(terminalp);
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_terminal_4b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  return _marpaESLIF_bootstrap_G1_action_terminal_pseudob(userDatavp, marpaESLIFValuep, MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__EOF, resulti);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_terminal_5b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  return _marpaESLIF_bootstrap_G1_action_terminal_pseudob(userDatavp, marpaESLIFValuep, MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__EOL, resulti);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_terminal_6b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  return _marpaESLIF_bootstrap_G1_action_terminal_pseudob(userDatavp, marpaESLIFValuep, MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__SOL, resulti);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_terminal_7b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  return _marpaESLIF_bootstrap_G1_action_terminal_pseudob(userDatavp, marpaESLIFValuep, MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE__EMPTY, resulti);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_terminal_8b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <terminal> ::= <regular expression> '->' <regular substitution> */
  /* <regular expression> and <regular substitution> are lexemes. */
  marpaESLIF_bootstrap_terminal_t *regexTerminalp        = NULL;
  marpaESLIF_bootstrap_terminal_t *substitutionTerminalp = NULL;
  void                            *bytep[2];
  size_t                           bytel[2];
  short                            rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i,     bytep[0], bytel[0]);
  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i + 2, bytep[1], bytel[1]);

  regexTerminalp = _marpaESLIF_bootstrap_regex_to_terminalp(userDatavp, marpaESLIFValuep, bytep[0], bytel[0]);
  if (MARPAESLIF_UNLIKELY(regexTerminalp == NULL)) {
    goto err;
  }

  substitutionTerminalp = _marpaESLIF_bootstrap_quotedstring_to_terminalp(userDatavp, marpaESLIFValuep, bytep[1], bytel[1], marpaESLIFValuep->marpaESLIFp->substitutionModifiersp);
  if (MARPAESLIF_UNLIKELY(substitutionTerminalp == NULL)) {
    goto err;
  }

  /* We move substitution terminal into regex bootstrap terminal */
  regexTerminalp->u.regularExpressionp->substitutionBytep     = substitutionTerminalp->u.stringp->bytep;
  regexTerminalp->u.regularExpressionp->substitutionBytel     = substitutionTerminalp->u.stringp->bytel;
  regexTerminalp->u.regularExpressionp->substitutionModifiers = substitutionTerminalp->u.stringp->modifiers;

  substitutionTerminalp->u.stringp->bytep     = NULL;
  substitutionTerminalp->u.stringp->bytel     = 0;
  substitutionTerminalp->u.stringp->modifiers = NULL;
  _marpaESLIF_bootstrap_terminal_freev(substitutionTerminalp);
  substitutionTerminalp = NULL;

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_TERMINAL, regexTerminalp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_terminal_freev(regexTerminalp);
  _marpaESLIF_bootstrap_terminal_freev(substitutionTerminalp);
  rcb = 0;

 done:
 return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIF_bootstrap_G1_action_terminal_pseudob(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, marpaESLIF_bootstrap_terminal_type_t type, int resulti)
/*****************************************************************************/
{
  marpaESLIF_bootstrap_terminal_t  *terminalp   = NULL;
  short                             rcb;

  terminalp = (marpaESLIF_bootstrap_terminal_t *) malloc(sizeof(marpaESLIF_bootstrap_terminal_t));
  if (MARPAESLIF_UNLIKELY(terminalp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  terminalp->type = type;

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_TERMINAL, terminalp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_terminal_freev(terminalp);
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_symbolb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <symbol> ::= <symbol name> */
  /* <symbol name> is a lexeme. */
  marpaESLIF_bootstrap_symbol_t *symbolp = NULL;
  char                          *symbols = NULL;
  short                          rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  /* symbols is an ASCII string that we pushed to a PTR that we own */
  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i, symbols);

  symbolp = (marpaESLIF_bootstrap_symbol_t *) malloc(sizeof(marpaESLIF_bootstrap_symbol_t));
  if (MARPAESLIF_UNLIKELY(symbolp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  symbolp->symbols = symbols;
  symbols = NULL; /* symbols is in symbolp */

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_SYMBOL, symbolp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_symbol_freev(symbolp);
  rcb = 0;

 done:
  if (symbols != NULL) {
    free(symbols);
  }
 return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_grammar_reference_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <grammar reference> ::= <quoted string literal> */
  marpaESLIF_bootstrap_grammar_reference_t *grammarReferencep = NULL;
  void                                     *bytep;
  size_t                                    bytel;
  marpaESLIF_bootstrap_utf_string_t        *quotedStringp     = NULL;
  short                                     rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i, bytep, bytel);
  quotedStringp = _marpaESLIF_bootstrap_unquote_string_literalp(marpaESLIFValuep, bytep, bytel, 0 /* allowEmptyStringb */);
  if (MARPAESLIF_UNLIKELY(quotedStringp == NULL)) {
    goto err;
  }

  grammarReferencep = (marpaESLIF_bootstrap_grammar_reference_t *) malloc(sizeof(marpaESLIF_bootstrap_grammar_reference_t));
  if (MARPAESLIF_UNLIKELY(grammarReferencep == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  grammarReferencep->type            = MARPAESLIF_BOOTSTRAP_GRAMMAR_REFERENCE_TYPE_STRING;
  grammarReferencep->u.quotedStringp = quotedStringp;
  quotedStringp = NULL; /* it is now in grammarReferencep */

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_GRAMMAR_REFERENCE, grammarReferencep);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_grammar_reference_freev(grammarReferencep);
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_utf_string_freev(quotedStringp, 0 /* onStackb */);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_grammar_reference_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <grammar reference> ::= <signed integer> */
  marpaESLIF_bootstrap_grammar_reference_t *grammarReferencep = NULL;
  char                                     *signedIntegers;
  short                                     rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ASCII(marpaESLIFValuep, arg0i, signedIntegers);
  /* It is a non-sense to have a null information */
  if (MARPAESLIF_UNLIKELY(signedIntegers == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "signedIntegers at indice %d is NULL", arg0i);
    goto err;
  }

  grammarReferencep = (marpaESLIF_bootstrap_grammar_reference_t *) malloc(sizeof(marpaESLIF_bootstrap_grammar_reference_t));
  if (MARPAESLIF_UNLIKELY(grammarReferencep == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  grammarReferencep->type             = MARPAESLIF_BOOTSTRAP_GRAMMAR_REFERENCE_TYPE_SIGNED_INTEGER;
  grammarReferencep->u.signedIntegeri = atoi(signedIntegers);

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_GRAMMAR_REFERENCE, grammarReferencep);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_grammar_reference_freev(grammarReferencep);
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_grammar_reference_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <grammar reference> ::= '=' <unsigned integer> */
  marpaESLIF_bootstrap_grammar_reference_t *grammarReferencep = NULL;
  char                                     *unsignedIntegers;
  short                                     rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ASCII(marpaESLIFValuep, argni, unsignedIntegers);
  /* It is a non-sense to have a null information */
  if (MARPAESLIF_UNLIKELY(unsignedIntegers == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "unsignedIntegers at indice %d is NULL", arg0i);
    goto err;
  }

  grammarReferencep = (marpaESLIF_bootstrap_grammar_reference_t *) malloc(sizeof(marpaESLIF_bootstrap_grammar_reference_t));
  if (MARPAESLIF_UNLIKELY(grammarReferencep == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  grammarReferencep->type               = MARPAESLIF_BOOTSTRAP_GRAMMAR_REFERENCE_TYPE_UNSIGNED_INTEGER;
  grammarReferencep->u.unsignedIntegeri = (unsigned int) atoi(unsignedIntegers);

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_GRAMMAR_REFERENCE, grammarReferencep);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_grammar_reference_freev(grammarReferencep);
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_inaccessible_treatment_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <inaccessible treatment> ::= 'warn' */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_SHORT(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_INACESSIBLE_TREATMENT, MARPAESLIF_BOOTSTRAP_INACCESSIBLE_TREATMENT_TYPE_WARN);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_inaccessible_treatment_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <inaccessible treatment> ::= 'ok' */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_SHORT(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_INACESSIBLE_TREATMENT, MARPAESLIF_BOOTSTRAP_INACCESSIBLE_TREATMENT_TYPE_OK);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_inaccessible_treatment_3b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <inaccessible treatment> ::= 'fatal' */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_SHORT(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_INACESSIBLE_TREATMENT, MARPAESLIF_BOOTSTRAP_INACCESSIBLE_TREATMENT_TYPE_FATAL);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_inaccessible_statementb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <inaccessible statement> ::= 'inaccessible' 'is' <inaccessible treatment> 'by' 'default' */
  marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp = (marpaESLIFGrammar_bootstrap_t *) userDatavp;
  short                inaccessibleTreatmentb;
  short                rcb;

  MARPAESLIF_BOOTSTRAP_GET_SHORT(marpaESLIFValuep, arg0i+2, inaccessibleTreatmentb);

  switch (inaccessibleTreatmentb) {
  case MARPAESLIF_BOOTSTRAP_INACCESSIBLE_TREATMENT_TYPE_WARN:
    marpaESLIFGrammarBootstrapp->warningIsErrorb = 0;
    marpaESLIFGrammarBootstrapp->warningIsIgnoredb = 0;
    break;
  case MARPAESLIF_BOOTSTRAP_INACCESSIBLE_TREATMENT_TYPE_OK:
    marpaESLIFGrammarBootstrapp->warningIsErrorb = 0;
    marpaESLIFGrammarBootstrapp->warningIsIgnoredb = 1;
    break;
  case MARPAESLIF_BOOTSTRAP_INACCESSIBLE_TREATMENT_TYPE_FATAL:
    marpaESLIFGrammarBootstrapp->warningIsErrorb = 1;
    marpaESLIFGrammarBootstrapp->warningIsIgnoredb = 0;
    break;
  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unsupported inaccessible treatment value %d", (int) inaccessibleTreatmentb);
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
static short _marpaESLIF_bootstrap_G1_action_on_or_off_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <on or off>  ::= 'on' */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_SHORT(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ON_OR_OFF, MARPAESLIF_BOOTSTRAP_ON_OR_OFF_TYPE_ON);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_on_or_off_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <on or off>  ::= 'off' */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_SHORT(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ON_OR_OFF, MARPAESLIF_BOOTSTRAP_ON_OR_OFF_TYPE_OFF);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_autorank_statementb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <autorank statement> ::= 'autorank' 'is' <on or off> 'by' 'default' */
  marpaESLIFGrammar_bootstrap_t                   *marpaESLIFGrammarBootstrapp = (marpaESLIFGrammar_bootstrap_t *) userDatavp;
  marpaESLIF_bootstrap_on_or_off_type_t  onOrOffb;
  short                                  rcb;

  MARPAESLIF_BOOTSTRAP_GET_SHORT(marpaESLIFValuep, arg0i+2, onOrOffb);

  switch (onOrOffb) {
  case MARPAESLIF_BOOTSTRAP_ON_OR_OFF_TYPE_ON:
    marpaESLIFGrammarBootstrapp->autorankb = 1;
    break;
  case MARPAESLIF_BOOTSTRAP_ON_OR_OFF_TYPE_OFF:
    marpaESLIFGrammarBootstrapp->autorankb = 0;
    break;
  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unsupported on or off value %d", (int) onOrOffb);
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
static short _marpaESLIF_bootstrap_G1_action_quantifier_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <quantifier> ::= '*' */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_INT(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_QUANTIFIER, 0);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_quantifier_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <quantifier> ::= '+' */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_INT(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_QUANTIFIER, 1);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_quantified_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <quantified rule> ::= <lhs> <op declare> <rhs primary> quantifier <adverb list> */
  static const char                    *funcs                       = "_marpaESLIF_bootstrap_G1_action_quantified_ruleb";
  marpaESLIFGrammar_bootstrap_t        *marpaESLIFGrammarBootstrapp = (marpaESLIFGrammar_bootstrap_t *) userDatavp;
  marpaESLIF_rule_t                    *rulep                       = NULL;
  genericStack_t                       *adverbListItemStackp        = NULL;
  marpaESLIF_bootstrap_lhs_t           *bootstrapLhsp               = NULL;
  marpaESLIF_bootstrap_rhs_primary_t   *rhsPrimaryp                 = NULL;
  int                                   leveli;
  int                                   minimumi;
  short                                 undefb;
  marpaESLIF_symbol_t                  *lhsp;
  marpaESLIF_bootstrap_rhs_primary_t   *separatorRhsPrimaryp;
  marpaESLIF_symbol_t                  *rhsp;
  marpaESLIF_symbol_t                  *separatorp;
  marpaESLIF_grammar_bootstrap_t       *grammarBootstrapp;
  short                                 rcb;
  marpaESLIF_action_t                  *actionp = NULL;
  int                                   ranki = 0;
  short                                 nullRanksHighb = 0;
  short                                 properb = 0;
  short                                 hideseparatorb = 0;
  marpaESLIF_bootstrap_utf_string_t    *namingp;

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i, bootstrapLhsp);
  if (MARPAESLIF_UNLIKELY(bootstrapLhsp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "bootstrapLhsp is NULL");
    goto err;
  }
  MARPAESLIF_BOOTSTRAP_GET_INT(marpaESLIFValuep, arg0i+1, leveli);
  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i+2, rhsPrimaryp);
  if (MARPAESLIF_UNLIKELY(rhsPrimaryp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "rhsPrimaryp is NULL");
    goto err;
  }
  MARPAESLIF_BOOTSTRAP_GET_INT(marpaESLIFValuep, arg0i+3, minimumi);
  /* adverb list may be undef */
  MARPAESLIF_BOOTSTRAP_IS_UNDEF(marpaESLIFValuep, argni, undefb);
  if (! undefb) {
    MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, argni, adverbListItemStackp);
    /* Non-sense to have a NULL stack in this case */
    if (MARPAESLIF_UNLIKELY(adverbListItemStackp == NULL)) {
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "adverbListItemStackp is NULL");
      goto err;
    }
  }
 
  /* Check grammar at that level exist */
  grammarBootstrapp = _marpaESLIF_bootstrap_check_grammarBootstrapp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, leveli, NULL);
  if (MARPAESLIF_UNLIKELY(grammarBootstrapp == NULL)) {
    goto err;
  }

  /* Check the lhs */
  lhsp = _marpaESLIF_bootstrap_check_lhsp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, bootstrapLhsp);
  if (MARPAESLIF_UNLIKELY(lhsp == NULL)) {
    goto err;
  }

  /* Check the rhs primary */
  rhsp = _marpaESLIF_bootstrap_check_rhsPrimaryp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, rhsPrimaryp, 1 /* createb */, 0 /* forcecreateb */);
  if (MARPAESLIF_UNLIKELY(rhsp == NULL)) {
    goto err;
  }

  /* Check the adverb list */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_bootstrap_unpack_adverbListItemStackb(marpaESLIFValuep,
                                                                              "quantified rule",
                                                                              adverbListItemStackp,
                                                                              &actionp,
                                                                              NULL, /* left_associationbp */
                                                                              NULL, /* right_associationbp */
                                                                              NULL, /* group_associationbp */
                                                                              &separatorRhsPrimaryp,
                                                                              &properb,
                                                                              NULL, /* verbosebpp */
                                                                              &hideseparatorb,
                                                                              &ranki,
                                                                              &nullRanksHighb,
                                                                              NULL, /* priorityipp */
                                                                              NULL, /* pauseip */
                                                                              NULL, /* latmbp */
                                                                              NULL, /* discardIsFallbackbp */
                                                                              &namingp,
                                                                              NULL, /* symbolactionpp */
                                                                              NULL, /* eventInitializationpp */
                                                                              NULL, /* ifactionpp */
                                                                              NULL, /* regexactionpp */
                                                                              NULL, /* eventactionpp */
                                                                              NULL, /* defaultEncodingsp */
                                                                              NULL /* fallbackEncodingsp */
                                                                              ))) {
    goto err;
  }

  if (separatorRhsPrimaryp != NULL) {
    /* Check the separator */
    separatorp = _marpaESLIF_bootstrap_check_rhsPrimaryp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, separatorRhsPrimaryp, 1 /* createb */, 0 /* forcecreateb */);
    if (MARPAESLIF_UNLIKELY(separatorp == NULL)) {
      goto err;
    }
  } else {
    separatorp = NULL;
  }

#ifndef MARPAESLIF_NTRACE
  if (separatorp != NULL) {
    MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Creating quantified rule %s ::= %s%s ranki=>%d separator=>%s proper=>%d hide-separator=>%d null-ranking=>%s at grammar level %d", lhsp->descp->asciis, rhsp->descp->asciis, minimumi ? "+" : "*", ranki, separatorp->descp->asciis, (int) properb, (int) hideseparatorb, nullRanksHighb ? "high" : "low", grammarBootstrapp->leveli);
  } else {
    MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Creating quantified rule %s ::= %s%s ranki=>%d null-ranking=>%s at grammar level %d", lhsp->descp->asciis, rhsp->descp->asciis, minimumi ? "+" : "*", ranki, nullRanksHighb ? "high" : "low", grammarBootstrapp->leveli);
  }
#endif
  /* If naming is not NULL, it is guaranteed to be an UTF-8 thingy */
  rulep = _marpaESLIF_bootstrap_check_rulep(marpaESLIFValuep,
                                            marpaESLIFGrammarBootstrapp,
                                            grammarBootstrapp,
                                            (namingp != NULL) ? (char *) MARPAESLIF_UTF8_STRING : NULL, /* descEncodings */
                                            (namingp != NULL) ? namingp->bytep : NULL, /* descs */
                                            (namingp != NULL) ? namingp->bytel : 0, /* descl */
                                            lhsp->idi,
                                            1, /* nrhsl */
                                            &(rhsp->idi), /* rhsip */
                                            -1, /* exceptioni */
                                            ranki,
                                            nullRanksHighb,
                                            1, /* sequenceb */
                                            minimumi,
                                            (separatorp != NULL) ? separatorp->idi : -1, /* separatori */
                                            properb,
                                            actionp,
                                            hideseparatorb,
                                            NULL, /* skipbp */
                                            bootstrapLhsp->declp,
                                            &(rhsPrimaryp->callp),
                                            (separatorRhsPrimaryp != NULL) ? separatorRhsPrimaryp->callp : NULL);
  if (MARPAESLIF_UNLIKELY(rulep == NULL)) {
    goto err;
  }
  GENERICSTACK_SET_PTR(grammarBootstrapp->ruleStackp, rulep, rulep->idi);
  if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(grammarBootstrapp->ruleStackp))) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "ruleStackp set failure, %s", strerror(errno));
    goto err;
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_lhs_freev(bootstrapLhsp);
  _marpaESLIF_bootstrap_rhs_primary_freev(rhsPrimaryp);
  _marpaESLIF_bootstrap_adverb_list_items_freev(adverbListItemStackp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_start_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <start rule>  ::= ':start' <op declare> <start symbol> */
  static const char                   *funcs                       = "_marpaESLIF_bootstrap_G1_action_start_ruleb";
  marpaESLIFGrammar_bootstrap_t       *marpaESLIFGrammarBootstrapp = (marpaESLIFGrammar_bootstrap_t *) userDatavp;
  marpaESLIF_bootstrap_start_symbol_t *startSymbolp                = NULL;
  int                                  leveli;
  marpaESLIF_grammar_bootstrap_t      *grammarBootstrapp;
  marpaESLIF_symbol_t                 *startp;
  marpaESLIF_symbol_t                 *lhsp;
  marpaESLIF_rule_t                   *rulep;
  char                                 tmps[1024];
  marpaESLIF_action_t                  action;
  short                                rcb;

  MARPAESLIF_BOOTSTRAP_GET_INT(marpaESLIFValuep, arg0i+1, leveli);
  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i+2, startSymbolp);
  if (MARPAESLIF_UNLIKELY(startSymbolp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "startSymbolp is NULL");
    goto err;
  }

  /* Check grammar at that level exist */
  grammarBootstrapp = _marpaESLIF_bootstrap_check_grammarBootstrapp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, leveli, NULL);
  if (MARPAESLIF_UNLIKELY(grammarBootstrapp == NULL)) {
    goto err;
  }

  /* Check the symbol */

  if (startSymbolp->callp != NULL) {
    /* A parameterized start symbolp is special - we have to create an internal lhs to make it an RHS */
    startp = _marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, startSymbolp->symbols, 1 /* createb */, 0 /* forcecreateb */, 0 /* lhsb */, NULL /* declp */, 1 /* rhsb */, startSymbolp->callp);
    if (MARPAESLIF_UNLIKELY(startp == NULL)) {
      goto err;
    }
    sprintf(tmps, "Internal[%d]", marpaESLIFGrammarBootstrapp->internalRuleCounti++);
    lhsp = _marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, tmps, 1 /* createb */, 0 /* forcecreateb */, 1 /* lhsb */, NULL /* declp */, 0 /* rhsb */, NULL /* callp */);
    if (MARPAESLIF_UNLIKELY(lhsp == NULL)) {
      goto err;
    }

    /* Constant action */
    action.type    = MARPAESLIF_ACTION_TYPE_NAME;
    action.u.names = "::shift";

    MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Creating start rule %s ::= %s at grammar level %d", lhsp->descp->asciis, startp->descp->asciis, grammarBootstrapp->leveli);
    rulep = _marpaESLIF_bootstrap_check_rulep(marpaESLIFValuep,
                                              marpaESLIFGrammarBootstrapp,
                                              grammarBootstrapp,
                                              lhsp->descp->asciis,
                                              NULL, /* descs */
                                              0, /* descl */
                                              lhsp->idi,
                                              1, /* nrhsl */
                                              &(startp->idi), /* rhsip */
                                              -1,
                                              0, /* ranki */
                                              0, /*nullRanksHighb */
                                              0, /* sequenceb */
                                              0, /* minimumi */
                                              -1, /* separatori */
                                              0, /* properb */
                                              &action,
                                              0 /* hideseparatorb */,
                                              NULL, /* skipbp */
                                              NULL, /* declp */
                                              &(startSymbolp->callp),
                                              NULL /* separatorcallp */);
    if (MARPAESLIF_UNLIKELY(rulep == NULL)) {
      goto err;
    }

    /* Mark it internal */
    rulep->internalb = 1;

    GENERICSTACK_SET_PTR(grammarBootstrapp->ruleStackp, rulep, rulep->idi);
    if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(grammarBootstrapp->ruleStackp))) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "ruleStackp set failure, %s", strerror(errno));
      goto err;
    }

    /* Make it the start symbol */
    MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Marking meta symbol %s in grammar level %d as start symbol", lhsp->descp->asciis, grammarBootstrapp->leveli);
    lhsp->startb = 1;
  } else {
    /* Make it the start symbol */
    startp = _marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, startSymbolp->symbols, 1 /* createb */, 0 /* forcecreateb */, 1 /* lhsb */, NULL /* declp */, 0 /* rhsb */, NULL /* callp */);
    if (MARPAESLIF_UNLIKELY(startp == NULL)) {
      goto err;
    }
    MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Marking meta symbol %s in grammar level %d as start symbol", startp->descp->asciis, grammarBootstrapp->leveli);
    startp->startb = 1;
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_start_symbol_freev(startSymbolp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_desc_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <desc rule> ::= ':desc' <op declare> <quoted string literal> */
  static const char                 *funcs                       = "_marpaESLIF_bootstrap_G1_action_desc_ruleb";
  marpaESLIFGrammar_bootstrap_t     *marpaESLIFGrammarBootstrapp = (marpaESLIFGrammar_bootstrap_t *) userDatavp;
  int                                leveli;
  void                              *bytep;
  size_t                             bytel;
  marpaESLIF_bootstrap_utf_string_t *quotedStringp               = NULL;
  short                              rcb;
  marpaESLIF_grammar_bootstrap_t    *grammarBootstrapp;

  MARPAESLIF_BOOTSTRAP_GET_INT(marpaESLIFValuep, arg0i+1, leveli);
  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i+2, bytep, bytel);
  quotedStringp = _marpaESLIF_bootstrap_unquote_string_literalp(marpaESLIFValuep, bytep, bytel, 0 /* allowEmptyStringb */);
  if (MARPAESLIF_UNLIKELY(quotedStringp == NULL)) {
    goto err;
  }

  /* Check grammar at that level exist */
  grammarBootstrapp = _marpaESLIF_bootstrap_check_grammarBootstrapp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, leveli, NULL);
  if (MARPAESLIF_UNLIKELY(grammarBootstrapp == NULL)) {
    goto err;
  }

  _marpaESLIF_string_freev(grammarBootstrapp->descp, 0 /* onStackb */);
  /* Why hardcoded to UTF-8 ? Because a quote string is implemented as a regexp in unicode mode. */
  /* Therefore it is guaranteed that the match was done on UTF-8 bytes; regardless of the encoding */
  /* of the original input. */
  grammarBootstrapp->descp = _marpaESLIF_string_newp(marpaESLIFValuep->marpaESLIFp, (char *) MARPAESLIF_UTF8_STRING, quotedStringp->bytep, quotedStringp->bytel);
  if (MARPAESLIF_UNLIKELY(grammarBootstrapp->descp == NULL)) {
    goto err;
  }
  grammarBootstrapp->descautob = 0;

  /* Overwrite grammar description */
  MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Grammar level %d description set to %s", grammarBootstrapp->leveli, grammarBootstrapp->descp->asciis);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_utf_string_freev(quotedStringp, 0 /* onStackb */);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_empty_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <empty rule> ::= <lhs> <op declare> <adverb list> */
  static const char                 *funcs                       = "_marpaESLIF_bootstrap_G1_action_empty_ruleb";
  marpaESLIFGrammar_bootstrap_t     *marpaESLIFGrammarBootstrapp = (marpaESLIFGrammar_bootstrap_t *) userDatavp;
  marpaESLIF_rule_t                 *rulep                       = NULL;
  marpaESLIF_bootstrap_lhs_t        *bootstrapLhsp               = NULL;
  genericStack_t                    *adverbListItemStackp        = NULL;
  int                                leveli;
  marpaESLIF_grammar_bootstrap_t    *grammarBootstrapp;
  marpaESLIF_symbol_t               *lhsp;
  short                              undefb;
  marpaESLIF_action_t               *actionp;
  int                                ranki;
  short                              nullRanksHighb;
  marpaESLIF_bootstrap_utf_string_t *namingp;
  short                              rcb;

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i, bootstrapLhsp);
  if (MARPAESLIF_UNLIKELY(bootstrapLhsp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "bootstrapLhsp is NULL");
    goto err;
  }
  MARPAESLIF_BOOTSTRAP_GET_INT(marpaESLIFValuep, arg0i+1, leveli);
  /* adverb list may be undef */
  MARPAESLIF_BOOTSTRAP_IS_UNDEF(marpaESLIFValuep, argni, undefb);
  if (! undefb) {
    MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, argni, adverbListItemStackp);
    /* Non-sense to have a NULL stack in this case */
    if (MARPAESLIF_UNLIKELY(adverbListItemStackp == NULL)) {
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "adverbListItemStackp is NULL");
      goto err;
    }
  }

  /* Check grammar at that level exist */
  grammarBootstrapp = _marpaESLIF_bootstrap_check_grammarBootstrapp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, leveli, NULL);
  if (MARPAESLIF_UNLIKELY(grammarBootstrapp == NULL)) {
    goto err;
  }

  /* Check the lhs exist */
  lhsp = _marpaESLIF_bootstrap_check_lhsp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, bootstrapLhsp);
  if (MARPAESLIF_UNLIKELY(lhsp == NULL)) {
    goto err;
  }

  /* Unpack the adverb list */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_bootstrap_unpack_adverbListItemStackb(marpaESLIFValuep,
                                                                              "empty rule",
                                                                              adverbListItemStackp,
                                                                              &actionp,
                                                                              NULL, /* left_associationbp */
                                                                              NULL, /* right_associationbp */
                                                                              NULL, /* group_associationbp */
                                                                              NULL, /* separatorRhsPrimarypp */
                                                                              NULL, /* properbp */
                                                                              NULL, /* verbosebpp */
                                                                              NULL, /* hideseparatorbp */
                                                                              &ranki,
                                                                              &nullRanksHighb,
                                                                              NULL, /* priorityipp */
                                                                              NULL, /* pauseip */
                                                                              NULL, /* latmbp */
                                                                              NULL, /* discardIsFallbackbp */
                                                                              &namingp,
                                                                              NULL, /* symbolactionpp */
                                                                              NULL, /* eventInitializationpp */
                                                                              NULL, /* ifactionpp */
                                                                              NULL, /* regexactionpp */
                                                                              NULL, /* eventactionpp */
                                                                              NULL, /* defaultEncodingsp */
                                                                              NULL /* fallbackEncodingsp */
                                                                              ))) {
    goto err;
  }

  /* Create the rule */
  /* If there is a name description, then it is UTF-8 compatible (<standard name> or <quoted name>) */
  MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Creating empty rule %s at grammar level %d", lhsp->descp->asciis, grammarBootstrapp->leveli);
  rulep = _marpaESLIF_bootstrap_check_rulep(marpaESLIFValuep,
                                            marpaESLIFGrammarBootstrapp,
                                            grammarBootstrapp,
                                            (namingp != NULL) ? (char *) MARPAESLIF_UTF8_STRING : NULL, /* descEncodings */
                                            (namingp != NULL) ? namingp->bytep : NULL, /* descs */
                                            (namingp != NULL) ? namingp->bytel : 0, /* descl */
                                            lhsp->idi,
                                            0, /* nrhsl */
                                            NULL, /* rhsip */
                                            -1, /* exceptioni */
                                            ranki,
                                            nullRanksHighb,
                                            0, /* sequenceb */
                                            -1, /* minimumi */
                                            -1, /* separatori */
                                            0, /* properb */
                                            actionp,
                                            0 /* hideseparatorb */,
                                            NULL, /* skipbp */
                                            bootstrapLhsp->declp,
                                            NULL, /* callpp */
                                            NULL /* separatorcallp */);
  if (MARPAESLIF_UNLIKELY(rulep == NULL)) {
    goto err;
  }

  GENERICSTACK_SET_PTR(grammarBootstrapp->ruleStackp, rulep, rulep->idi);
  if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(grammarBootstrapp->ruleStackp))) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "ruleStackp set failure, %s", strerror(errno));
    goto err;
  }
  /* Push is ok, rulep is in grammarBootstrapp->ruleStackp */
  rulep = NULL;

  MARPAESLIF_BOOTSTRAP_SET_UNDEF(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_NA /* context not used */);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_lhs_freev(bootstrapLhsp);
  _marpaESLIF_bootstrap_adverb_list_items_freev(adverbListItemStackp);
  _marpaESLIF_rule_freev(rulep);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_default_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <default rule> ::= ':default' <op declare> <adverb list> */
  marpaESLIFGrammar_bootstrap_t     *marpaESLIFGrammarBootstrapp = (marpaESLIFGrammar_bootstrap_t *) userDatavp;
  genericStack_t                    *adverbListItemStackp        = NULL;
  int                                leveli;
  marpaESLIF_grammar_bootstrap_t    *grammarBootstrapp;
  short                              undefb;
  marpaESLIF_action_t               *actionp;
  marpaESLIF_action_t               *symbolactionp;
  short                              latmb;
  short                              discardIsFallbackb;
  marpaESLIF_action_t               *eventactionp;
  marpaESLIF_action_t               *regexactionp;
  char                              *defaultEncodings;
  char                              *fallbackEncodings;
  short                              rcb;

  MARPAESLIF_BOOTSTRAP_GET_INT(marpaESLIFValuep, arg0i+1, leveli);
  /* adverb list may be undef */
  MARPAESLIF_BOOTSTRAP_IS_UNDEF(marpaESLIFValuep, argni, undefb);
  if (! undefb) {
    MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, argni, adverbListItemStackp);
    /* Non-sense to have a NULL stack in this case */
    if (MARPAESLIF_UNLIKELY(adverbListItemStackp == NULL)) {
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "adverbListItemStackp is NULL");
      goto err;
    }
  }

  /* Check grammar at that level exist */
  grammarBootstrapp = _marpaESLIF_bootstrap_check_grammarBootstrapp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, leveli, NULL);
  if (MARPAESLIF_UNLIKELY(grammarBootstrapp == NULL)) {
    goto err;
  }

  /* We restrict :default for a grammar to appear once */
  if (MARPAESLIF_UNLIKELY(grammarBootstrapp->nbupdatei > 0)) {
    if (grammarBootstrapp->descautob) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "The :default rule should appear once for grammar level %d", grammarBootstrapp->leveli);
    } else {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "The :default rule should appear once for grammar level %d (%s)", grammarBootstrapp->leveli, grammarBootstrapp->descp->asciis);
    }
    goto err;
  }
  
  /* Unpack the adverb list */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_bootstrap_unpack_adverbListItemStackb(marpaESLIFValuep,
                                                                              ":default rule",
                                                                              adverbListItemStackp,
                                                                              &actionp,
                                                                              NULL, /* left_associationbp */
                                                                              NULL, /* right_associationbp */
                                                                              NULL, /* group_associationbp */
                                                                              NULL, /* separatorRhsPrimarypp */
                                                                              NULL, /* properbp */
                                                                              NULL, /* verbosebpp */
                                                                              NULL, /* hideseparatorbp */
                                                                              NULL, /* rankip */
                                                                              NULL, /* nullRanksHighbp */
                                                                              NULL, /* priorityipp */
                                                                              NULL, /* pauseip */
                                                                              &latmb,
                                                                              &discardIsFallbackb,
                                                                              NULL, /* namingpp */
                                                                              &symbolactionp,
                                                                              NULL, /* eventInitializationpp */
                                                                              NULL, /* ifactionpp */
                                                                              &regexactionp,
                                                                              &eventactionp,
                                                                              &defaultEncodings,
                                                                              &fallbackEncodings
                                                                              ))) {
    goto err;
  }

  grammarBootstrapp->nbupdatei++;

  /* Overwrite grammar default settings */
  _marpaESLIF_action_freev(grammarBootstrapp->defaultRuleActionp);
  grammarBootstrapp->defaultRuleActionp = NULL;
  if (actionp != NULL) {
    grammarBootstrapp->defaultRuleActionp = _marpaESLIF_action_clonep(marpaESLIFValuep->marpaESLIFp, actionp);
    if (MARPAESLIF_UNLIKELY(grammarBootstrapp->defaultRuleActionp == NULL)) {
      goto err;
    }
  }

  grammarBootstrapp->latmb              = latmb;
  grammarBootstrapp->discardIsFallbackb = discardIsFallbackb;

  _marpaESLIF_action_freev(grammarBootstrapp->defaultSymbolActionp);
  grammarBootstrapp->defaultSymbolActionp = NULL;
  if (symbolactionp != NULL) {
    grammarBootstrapp->defaultSymbolActionp = _marpaESLIF_action_clonep(marpaESLIFValuep->marpaESLIFp, symbolactionp);
    if (MARPAESLIF_UNLIKELY(grammarBootstrapp->defaultSymbolActionp == NULL)) {
      goto err;
    }
  }

  _marpaESLIF_action_freev(grammarBootstrapp->defaultEventActionp);
  grammarBootstrapp->defaultEventActionp = NULL;
  if (eventactionp != NULL) {
    grammarBootstrapp->defaultEventActionp = _marpaESLIF_action_clonep(marpaESLIFValuep->marpaESLIFp, eventactionp);
    if (MARPAESLIF_UNLIKELY(grammarBootstrapp->defaultEventActionp == NULL)) {
      goto err;
    }
  }

  _marpaESLIF_action_freev(grammarBootstrapp->defaultRegexActionp);
  grammarBootstrapp->defaultRegexActionp = NULL;
  if (regexactionp != NULL) {
    grammarBootstrapp->defaultRegexActionp = _marpaESLIF_action_clonep(marpaESLIFValuep->marpaESLIFp, regexactionp);
    if (MARPAESLIF_UNLIKELY(grammarBootstrapp->defaultRegexActionp == NULL)) {
      goto err;
    }
  }

  if (grammarBootstrapp->defaultEncodings != NULL) {
    free(grammarBootstrapp->defaultEncodings);
  }
  if (defaultEncodings != NULL) {
    grammarBootstrapp->defaultEncodings = strdup(defaultEncodings);
    if (MARPAESLIF_UNLIKELY(grammarBootstrapp->defaultEncodings == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "strdup failure, %s", strerror(errno));
      goto err;
    }
  }

  if (grammarBootstrapp->fallbackEncodings != NULL) {
    free(grammarBootstrapp->fallbackEncodings);
  }
  if (fallbackEncodings != NULL) {
    grammarBootstrapp->fallbackEncodings = strdup(fallbackEncodings);
    if (MARPAESLIF_UNLIKELY(grammarBootstrapp->fallbackEncodings == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "strdup failure, %s", strerror(errno));
      goto err;
    }
  }

  MARPAESLIF_BOOTSTRAP_SET_UNDEF(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_NA /* context not used */);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_adverb_list_items_freev(adverbListItemStackp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_latm_specification_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <latm specification> ::= 'latm' '=>' false */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_BOOL(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_LATM, 0);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_latm_specification_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <latm specification> ::= 'latm' '=>' true */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_BOOL(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_LATM, 1);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_discard_is_fallback_specification_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <discard is fallback specification> ::= 'discard-is-fallback' '=>' false */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_BOOL(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_DISCARD_IS_FALLBACK, 0);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_discard_is_fallback_specification_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <discard is fallback specification> ::= 'discard-is-fallback' '=>' true */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_BOOL(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_DISCARD_IS_FALLBACK, 1);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_proper_specification_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <proper specification> ::= 'proper' '=>' false */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_BOOL(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_PROPER, 0);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_proper_specification_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <proper specification> ::= 'proper' '=>' true */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_BOOL(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_PROPER, 1);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_verbose_specification_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <verbose specification> ::= 'verbose' '=>' false */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_BOOL(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_VERBOSE, 0);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_verbose_specification_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <verbose specification> ::= 'verbose' '=>' true */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_BOOL(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_VERBOSE, 1);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_hideseparator_specification_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <hide separator specification> ::= 'hide-separator' '=>' false */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_BOOL(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_HIDESEPARATOR, 0);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_hideseparator_specification_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <hide separator specification> ::= 'hide-separator' '=>' true */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_BOOL(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_HIDESEPARATOR, 1);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_rank_specificationb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <rank specification> ::= 'rank' '=>' <signed integer> */
  char         *signedIntegers;
  short         rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ASCII(marpaESLIFValuep, argni, signedIntegers);
  /* It is a non-sense to have a null information */
  if (MARPAESLIF_UNLIKELY(signedIntegers == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "signedIntegers indice %d is NULL", arg0i);
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_SET_INT(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_RANK, atoi(signedIntegers));

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_null_ranking_specification_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <null ranking specification> ::= 'null-ranking' '=>' <null ranking constant> */
  short         nullRanksHighb;
  short         rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_BOOL(marpaESLIFValuep, argni, nullRanksHighb);

  MARPAESLIF_BOOTSTRAP_SET_BOOL(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_NULL_RANKING, nullRanksHighb);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_null_ranking_specification_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <null ranking specification> ::= 'null' 'rank' '=>' <null ranking constant> */
  short         nullRanksHighb;
  short         rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_BOOL(marpaESLIFValuep, argni, nullRanksHighb);

  MARPAESLIF_BOOTSTRAP_SET_BOOL(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_NULL_RANKING, nullRanksHighb);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_null_ranking_constant_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <null ranking constant> ::= 'low' */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_BOOL(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_NULL_RANKING, 0);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_null_ranking_constant_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <null ranking constant> ::= 'high' */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_BOOL(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_NULL_RANKING, 1);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_pause_specification_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <pause specification> ::= 'pause' '=>' 'before' > */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_INT(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_PAUSE, MARPAESLIF_BOOTSTRAP_PAUSE_TYPE_BEFORE);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_pause_specification_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <pause specification> ::= 'pause' '=>' 'before' > */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_INT(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_PAUSE, MARPAESLIF_BOOTSTRAP_PAUSE_TYPE_AFTER);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_priority_specificationb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <priority specification> ::= 'priority' '=>' <signed integer> */
  char                                     *signedIntegers = NULL;
  short                                     rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ASCII(marpaESLIFValuep, arg0i+2, signedIntegers);
  /* It is a non-sense to have a null information */
  if (MARPAESLIF_UNLIKELY(signedIntegers == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "signedIntegers at indice %d is NULL", arg0i+2);
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_SET_INT(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_PRIORITY, atoi(signedIntegers));

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_event_initializer_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <event initializer> ::= '=' <on or off> */
  marpaESLIF_bootstrap_on_or_off_type_t          onOrOffb;
  marpaESLIF_bootstrap_event_initializer_type_t  eventInitializerb;
  short                                          rcb;

  MARPAESLIF_BOOTSTRAP_GET_SHORT(marpaESLIFValuep, argni, onOrOffb);

  switch (onOrOffb) {
  case MARPAESLIF_BOOTSTRAP_ON_OR_OFF_TYPE_ON:
    eventInitializerb = MARPAESLIF_BOOTSTRAP_EVENT_INITIALIZER_TYPE_ON;
    break;
  case MARPAESLIF_BOOTSTRAP_ON_OR_OFF_TYPE_OFF:
    eventInitializerb = MARPAESLIF_BOOTSTRAP_EVENT_INITIALIZER_TYPE_OFF;
    break;
  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unsupported on or off value %d", (int) onOrOffb);
    goto err;
  }
  
  MARPAESLIF_BOOTSTRAP_SET_SHORT(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_EVENT_INITIALIZER, eventInitializerb);
  
  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_event_initializer_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <event initializer> ::= # empty */
  /* Per def this is a nullable - default event state is on */
  short rcb;

  MARPAESLIF_BOOTSTRAP_SET_SHORT(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_EVENT_INITIALIZER, MARPAESLIF_BOOTSTRAP_EVENT_INITIALIZER_TYPE_ON);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_event_initializationb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <event initialization> ::= <event name> <event initializer> */
  /* <event name> is an ASCII string */
  /* <event initializer> is a boolean */
  marpaESLIF_bootstrap_event_initialization_t  *eventInitializationp  = NULL;
  char                                         *eventNames            = NULL;
  marpaESLIF_bootstrap_event_initializer_type_t eventInitializerb;
  short                                         rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ASCII(marpaESLIFValuep, arg0i, eventNames);
  /* It is a non-sense to not have valid information */
  if (MARPAESLIF_UNLIKELY(eventNames == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "eventNames at indice %d is NULL", argni);
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_SHORT(marpaESLIFValuep, argni, eventInitializerb);

  /* Make that an rhs primary structure */
  eventInitializationp = (marpaESLIF_bootstrap_event_initialization_t *) malloc(sizeof(marpaESLIF_bootstrap_event_initialization_t));
  if (MARPAESLIF_UNLIKELY(eventInitializationp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  eventInitializationp->eventNames  = strdup(eventNames);
  if (MARPAESLIF_UNLIKELY(eventInitializationp->eventNames == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "strdup failure, %s", strerror(errno));
    goto err;
  }
  eventInitializationp->initializerb = eventInitializerb;

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_EVENT_INITIALIZATION, eventInitializationp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_event_initialization_freev(eventInitializationp);
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_event_specificationb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <event specification> ::= 'event' '=>' <event initialization> */
  marpaESLIF_bootstrap_event_initialization_t *eventInitializationp = NULL;
  short                                        rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i+2, eventInitializationp);
  /* It is a non-sense to have a null information */
  if (MARPAESLIF_UNLIKELY(eventInitializationp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "_marpaESLIFValue_stack_getAndForgetb at indice %d returned NULL", arg0i+2);
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_EVENT_INITIALIZATION, eventInitializationp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_event_initialization_freev(eventInitializationp);
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_lexeme_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  return __marpaESLIF_bootstrap_G1_action_symbol_ruleb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, MARPAESLIF_SYMBOL_TYPE_META);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_terminal_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  return __marpaESLIF_bootstrap_G1_action_symbol_ruleb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, MARPAESLIF_SYMBOL_TYPE_TERMINAL);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_symbol_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  return __marpaESLIF_bootstrap_G1_action_symbol_ruleb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, MARPAESLIF_SYMBOL_TYPE_NA);
}

/*****************************************************************************/
static short __marpaESLIF_bootstrap_G1_action_symbol_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb, marpaESLIF_symbol_type_t wantedType)
/*****************************************************************************/
{
  marpaESLIFGrammar_bootstrap_t               *marpaESLIFGrammarBootstrapp = (marpaESLIFGrammar_bootstrap_t *) userDatavp;
  genericStack_t                              *adverbListItemStackp        = NULL;
  marpaESLIF_bootstrap_terminal_t             *terminalp                   = NULL;
  marpaESLIF_bootstrap_rhs_primary_t          *rhsPrimaryp                 = NULL;
  marpaESLIF_string_t                         *stringp                     = NULL;
  marpaESLIF_bootstrap_utf_string_t           *namingp                     = NULL;
  char                                        *lhsTypes;
  char                                        *lhsRuleTypes;
  marpaESLIF_symbol_t                         *symbolp;
  int                                          leveli;
  marpaESLIF_grammar_bootstrap_t              *grammarBootstrapp;
  int                                         *priorityip;
  marpaESLIF_bootstrap_pause_type_t            pausei;
  marpaESLIF_bootstrap_event_initialization_t *eventInitializationp;
  short                                        undefb;
  marpaESLIF_action_t                         *symbolactionp;
  marpaESLIF_action_t                         *ifactionp;
  short                                       *verbosebp;
  marpaESLIF_string_t                         *descp;
  short                                        rcb;

  MARPAESLIF_BOOTSTRAP_GET_INT(marpaESLIFValuep, arg0i+1, leveli);

  /* When the origin is the deprecated :terminal rule, the PTR is a terminalp, not a rhsPrimaryp */
  /* Otherwise, it is like the deprecated :lexeme rule: an rhsPrimaryp */
  switch (wantedType) {
  case MARPAESLIF_SYMBOL_TYPE_TERMINAL:
    MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i+2, terminalp);
    if (MARPAESLIF_UNLIKELY(terminalp == NULL)) {
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "terminalp is NULL");
      goto err;
    }
    break;
  case MARPAESLIF_SYMBOL_TYPE_NA:
  case MARPAESLIF_SYMBOL_TYPE_META:
    MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i+2, rhsPrimaryp);
    if (MARPAESLIF_UNLIKELY(rhsPrimaryp == NULL)) {
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "rhsPrimaryp is NULL");
      goto err;
    }
    break;
  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unknown symbol type %d", wantedType);
    goto err;
  }
  /* adverb list may be undef */
  MARPAESLIF_BOOTSTRAP_IS_UNDEF(marpaESLIFValuep, argni, undefb);
  if (! undefb) {
    MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, argni, adverbListItemStackp);
    /* Non-sense to have a NULL stack in this case */
    if (MARPAESLIF_UNLIKELY(adverbListItemStackp == NULL)) {
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "adverbListItemStackp is NULL");
      goto err;
    }
  }

  /* Check grammar at that level exist */
  grammarBootstrapp = _marpaESLIF_bootstrap_check_grammarBootstrapp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, leveli, NULL);
  if (MARPAESLIF_UNLIKELY(grammarBootstrapp == NULL)) {
    goto err;
  }

  /* Check the symbol exist */
  switch (wantedType) {
  case MARPAESLIF_SYMBOL_TYPE_TERMINAL:
    symbolp = _marpaESLIF_bootstrap_check_terminalp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, terminalp, 1 /* createb */, 0 /* forcecreateb */, 0 /* lhsb */, NULL /* declp */, 1 /* rhsb */, NULL /* callp */);
    break;
  case MARPAESLIF_SYMBOL_TYPE_NA:
  case MARPAESLIF_SYMBOL_TYPE_META:
    symbolp = _marpaESLIF_bootstrap_check_rhsPrimaryp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, rhsPrimaryp, 1 /* createb */, 0 /* forcecreateb */);
    break;
  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unknown symbol type %d", wantedType);
    goto err;
  }
  if (MARPAESLIF_UNLIKELY(symbolp == NULL)) {
    goto err;
  }

  /* Check this is the correct type (backward compatibility for deprecated :lexeme and :terminal rules) */
  switch (wantedType) {
  case MARPAESLIF_SYMBOL_TYPE_NA:
    lhsTypes = ":symbol";
    switch (symbolp->type) {
    case MARPAESLIF_SYMBOL_TYPE_TERMINAL:
      lhsRuleTypes = ":symbol rule on a terminal";
      break;
    case MARPAESLIF_SYMBOL_TYPE_META:
      lhsRuleTypes = ":symbol rule on a meta symbol";
      break;
    default:
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unexpected symbol type %d", symbolp->type);
      goto err;
    }
    break;
  case MARPAESLIF_SYMBOL_TYPE_TERMINAL:
    lhsTypes = ":terminal";
    lhsRuleTypes = ":terminal rule";
    /* Check this is a terminal symbol */
    if (symbolp->type != MARPAESLIF_SYMBOL_TYPE_TERMINAL) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "%s rule on <%s> but this is a lexeme", lhsTypes, symbolp->descp->asciis);
      goto err;
    }
    break;
  case MARPAESLIF_SYMBOL_TYPE_META:
    lhsTypes = ":lexeme";
    lhsRuleTypes = ":lexeme rule";
    if (symbolp->type != MARPAESLIF_SYMBOL_TYPE_META) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "%s rule on <%s> but this is a terminal", lhsTypes, symbolp->descp->asciis);
      goto err;
    }
    break;
  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unknown symbol type %d", wantedType);
    goto err;
  }

  /* Unpack the adverb list - we allow naming on symbols of type MARPAESLIF_SYMBOL_TYPE_TERMINAL */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_bootstrap_unpack_adverbListItemStackb(marpaESLIFValuep,
                                                                              lhsRuleTypes,
                                                                              adverbListItemStackp,
                                                                              NULL, /* actionpp */
                                                                              NULL, /* left_associationbp */
                                                                              NULL, /* right_associationbp */
                                                                              NULL, /* group_associationbp */
                                                                              NULL, /* separatorRhsPrimarypp */
                                                                              NULL, /* properbp */
                                                                              &verbosebp,
                                                                              NULL, /* hideseparatorbp */
                                                                              NULL, /* rankip */
                                                                              NULL, /* nullRanksHighbp */
                                                                              &priorityip,
                                                                              &pausei,
                                                                              NULL, /* latmbp */
                                                                              NULL, /* discardIsFallbackbp */
                                                                              MARPAESLIF_IS_TERMINAL(symbolp) ? &namingp : NULL,
                                                                              &symbolactionp,
                                                                              &eventInitializationp,
                                                                              &ifactionp,
                                                                              NULL, /* regexactionpp */
                                                                              NULL, /* eventactionpp */
                                                                              NULL, /* defaultEncodingsp */
                                                                              NULL /* fallbackEncodingsp */
                                                                              ))) {
    goto err;
  }

  /* Update the symbol */
  if (namingp != NULL) {
    /* By definition this is a terminal - a naming must be unique */
    if (_marpaESLIF_bootstrap_find_terminal_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, namingp) != NULL) {
      stringp = _marpaESLIF_string_newp(marpaESLIFValuep->marpaESLIFp, (char *) MARPAESLIF_UTF8_STRING, namingp->bytep, namingp->bytel);
      if (stringp != NULL) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "A terminal is already defined with name %s", stringp->asciis);
      } else {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "A terminal is already defined with name ? (Internal error when computing name for logging)", stringp->asciis);
      }
      goto err;
    }

    descp = _marpaESLIF_string_newp(marpaESLIFValuep->marpaESLIFp, NULL /* encodingasciis */, namingp->bytep, namingp->bytel);
    if (descp == NULL) {
      goto err;
    }
    switch (symbolp->type) {
    case MARPAESLIF_SYMBOL_TYPE_TERMINAL:
      /* symbolp->descp is then != symbolp->u.terminalp->descp (that is the default) */
      if (symbolp->descp != symbolp->u.terminalp->descp) {
        /* This was already overwriten */
        _marpaESLIF_string_freev(symbolp->descp, 0 /* onStackp */);
      }
      break;
    case MARPAESLIF_SYMBOL_TYPE_META:
      /* symbolp->descp is then != symbolp->u.metap->descp (that is the default) */
      if (symbolp->descp != symbolp->u.metap->descp) {
        /* This was already overwriten */
        _marpaESLIF_string_freev(symbolp->descp, 0 /* onStackp */);
      }
      break;
    default:
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Unknown symbol type %d", wantedType);
      goto err;
    }
    symbolp->descp = descp;
  }

  if (priorityip != NULL) {
    symbolp->priorityi = *priorityip;
  }

  if (verbosebp != NULL) {
    symbolp->verboseb = *verbosebp;
  }

  if (symbolactionp != NULL) {
    _marpaESLIF_action_freev(symbolp->symbolActionp);
    symbolp->symbolActionp = _marpaESLIF_action_clonep(marpaESLIFValuep->marpaESLIFp, symbolactionp);
    if (MARPAESLIF_UNLIKELY(symbolp->symbolActionp == NULL)) {
      goto err;
    }
  }

  if (ifactionp != NULL) {
    _marpaESLIF_action_freev(symbolp->ifActionp);
    symbolp->ifActionp = _marpaESLIF_action_clonep(marpaESLIFValuep->marpaESLIFp, ifactionp);
    if (MARPAESLIF_UNLIKELY(symbolp->ifActionp == NULL)) {
      goto err;
    }
  }

  if (eventInitializationp != NULL) {
    /* It is a non-sense to have an event initialization without pause information */
    if (MARPAESLIF_UNLIKELY(eventInitializationp->eventNames == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "In %s rule for symbol <%s>, event name is NULL", lhsRuleTypes, symbolp->descp->asciis);
      goto err;
    }
    switch (pausei) {
    case MARPAESLIF_BOOTSTRAP_PAUSE_TYPE_BEFORE:
      if (symbolp->eventBefores != NULL) {
        free(symbolp->eventBefores);
      }
      symbolp->eventBefores = strdup(eventInitializationp->eventNames);
      if (MARPAESLIF_UNLIKELY(symbolp->eventBefores == NULL)) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "strdup failure, %s", strerror(errno));
        goto err;
      }
      switch (eventInitializationp->initializerb) {
      case MARPAESLIF_BOOTSTRAP_EVENT_INITIALIZER_TYPE_ON:
        symbolp->eventBeforeb = 1;
        break;
      case MARPAESLIF_BOOTSTRAP_EVENT_INITIALIZER_TYPE_OFF:
        symbolp->eventBeforeb = 0;
        break;
      default:
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "In %s rule for symbol <%s>, unsupported event initializer type %d", lhsTypes, symbolp->descp->asciis, (int) eventInitializationp->initializerb);
        goto err;
        break;
      }
      break;
    case MARPAESLIF_BOOTSTRAP_PAUSE_TYPE_AFTER:
      if (symbolp->eventAfters != NULL) {
        free(symbolp->eventAfters);
      }
      symbolp->eventAfters = strdup(eventInitializationp->eventNames);
      if (MARPAESLIF_UNLIKELY(symbolp->eventAfters == NULL)) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "strdup failure, %s", strerror(errno));
        goto err;
      }
      switch (eventInitializationp->initializerb) {
      case MARPAESLIF_BOOTSTRAP_EVENT_INITIALIZER_TYPE_ON:
        symbolp->eventAfterb = 1;
        break;
      case MARPAESLIF_BOOTSTRAP_EVENT_INITIALIZER_TYPE_OFF:
        symbolp->eventAfterb = 0;
        break;
      default:
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "In %s rule for symbol <%s>, unsupported event initializer type %d", lhsTypes, symbolp->descp->asciis, (int) eventInitializationp->initializerb);
        goto err;
        break;
      }
      break;
    case MARPAESLIF_BOOTSTRAP_PAUSE_TYPE_NA:
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "In %s rule for symbol <%s>, you must supply pause => before, or pause => after, when giving an event name", lhsTypes, symbolp->descp->asciis);
      goto err;
    default:
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "In %s rule for symbol <%s>, Unsupported pause type %d", lhsTypes, symbolp->descp->asciis, pausei);
      goto err;
    }
  } else {
    /* It is a non-sense to have pause information without an event initialization */
    switch (pausei) {
    case MARPAESLIF_BOOTSTRAP_PAUSE_TYPE_BEFORE:
    case MARPAESLIF_BOOTSTRAP_PAUSE_TYPE_AFTER:
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "In %s rule for symbol <%s>, you must supply event => <event initializer> when giving a pause speficiation", lhsTypes, symbolp->descp->asciis);
      goto err;
    default:
      break;
    }
  }

  MARPAESLIF_BOOTSTRAP_SET_UNDEF(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_NA /* context not used */);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_terminal_freev(terminalp);
  _marpaESLIF_bootstrap_rhs_primary_freev(rhsPrimaryp);
  _marpaESLIF_bootstrap_adverb_list_items_freev(adverbListItemStackp);
  _marpaESLIF_string_freev(stringp, 0 /* onStackb */);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_discard_ruleb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <discard rule> ::= ':discard' <op declare> <rhs primary> <adverb list> */
  static const char                           *funcs                       = "_marpaESLIF_bootstrap_G1_action_discard_ruleb";
  marpaESLIFGrammar_bootstrap_t               *marpaESLIFGrammarBootstrapp = (marpaESLIFGrammar_bootstrap_t *) userDatavp;
  marpaESLIF_rule_t                           *rulep                       = NULL;
  marpaESLIF_bootstrap_rhs_primary_t          *rhsPrimaryp                 = NULL;
  genericStack_t                              *adverbListItemStackp        = NULL;
  int                                          leveli;
  short                                        undefb;
  marpaESLIF_symbol_t                         *discardp;
  marpaESLIF_bootstrap_event_initialization_t *eventInitializationp;
  marpaESLIF_symbol_t                         *rhsp;
  marpaESLIF_grammar_bootstrap_t              *grammarBootstrapp;
  short                                        rcb;
  short                                        forcecreateb;
  
  MARPAESLIF_BOOTSTRAP_GET_INT(marpaESLIFValuep, arg0i+1, leveli);
  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i+2, rhsPrimaryp);
  /* adverb list may be undef */
  MARPAESLIF_BOOTSTRAP_IS_UNDEF(marpaESLIFValuep, argni, undefb);
  if (! undefb) {
    MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, argni, adverbListItemStackp);
    /* Non-sense to have a NULL stack in this case */
    if (MARPAESLIF_UNLIKELY(adverbListItemStackp == NULL)) {
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "adverbListItemStackp is NULL");
      goto err;
    }
  }
 
  /* Check grammar at that level exist */
  grammarBootstrapp = _marpaESLIF_bootstrap_check_grammarBootstrapp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, leveli, NULL);
  if (MARPAESLIF_UNLIKELY(grammarBootstrapp == NULL)) {
    goto err;
  }

  /* Check the :discard */
  discardp = _marpaESLIF_bootstrap_check_meta_by_namep(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, ":discard", 1 /* createb */, 0 /* forcecreateb */, 1 /* lhsb */, NULL /* declp */, 0 /* rhsb */, NULL /* callp */);
  if (MARPAESLIF_UNLIKELY(discardp == NULL)) {
    goto err;
  }
  /* Make sure it has the internal discard flag */
  MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Marking meta symbol %s in grammar level %d as :discard symbol", discardp->descp->asciis, grammarBootstrapp->leveli);
  discardp->discardb = 1;

  /* Check the rhs primary */
  /* Note that we always want to explicitely create the symbol if this is a terminal, so that if there is an event for it, it is unique */
  if ((rhsPrimaryp->type == MARPAESLIF_BOOTSTRAP_RHS_PRIMARY_TYPE_SINGLE_SYMBOL) &&
      (rhsPrimaryp->u.singleSymbolp->type == MARPAESLIF_BOOTSTRAP_SINGLE_SYMBOL_TYPE_TERMINAL)) {
    forcecreateb = 1;
  } else {
    forcecreateb = 0;
  }
  rhsp = _marpaESLIF_bootstrap_check_rhsPrimaryp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, rhsPrimaryp, 1 /* createb */, forcecreateb);
  if (MARPAESLIF_UNLIKELY(rhsp == NULL)) {
    goto err;
  }

  /* Check the adverb list */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_bootstrap_unpack_adverbListItemStackb(marpaESLIFValuep,
                                                                              ":discard rule",
                                                                              adverbListItemStackp,
                                                                              NULL, /* actionpp */
                                                                              NULL, /* left_associationbp */
                                                                              NULL, /* right_associationbp */
                                                                              NULL, /* group_associationbp */
                                                                              NULL, /* separatorRhsPrimarypp */
                                                                              NULL, /* properbp */
                                                                              NULL, /* verbosebpp */
                                                                              NULL, /* hideseparatorbp */
                                                                              NULL, /* ranki */
                                                                              NULL, /* nullRanksHighb */
                                                                              NULL, /* priorityipp */
                                                                              NULL, /* pauseip */
                                                                              NULL, /* latmbp */
                                                                              NULL, /* discardIsFallbackbp */
                                                                              NULL, /* namingpp */
                                                                              NULL, /* symbolactionpp */
                                                                              &eventInitializationp,
                                                                              NULL, /* ifactionpp */
                                                                              NULL, /* regexactionpp */
                                                                              NULL, /* eventactionpp */
                                                                              NULL, /* defaultEncodingsp */
                                                                              NULL /* fallbackEncodingsp */
                                                                              ))) {
    goto err;
  }

  MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Creating discard rule %s ::= %s at grammar level %d", discardp->descp->asciis, rhsp->descp->asciis, grammarBootstrapp->leveli);
  /* If naming is not NULL, it is guaranteed to be an UTF-8 thingy */
  rulep = _marpaESLIF_bootstrap_check_rulep(marpaESLIFValuep,
                                            marpaESLIFGrammarBootstrapp,
                                            grammarBootstrapp,
                                            NULL, /* descEncodings */
                                            NULL, /* descs */
                                            0, /* descl */
                                            discardp->idi,
                                            1, /* nrhsl */
                                            &(rhsp->idi), /* rhsip */
                                            -1, /* exceptioni */
                                            0, /* ranki */
                                            0, /* nullRanksHighb */
                                            0, /* sequenceb */
                                            -1, /* minimumi */
                                            -1, /* separatori */
                                            0, /* properb */
                                            NULL, /* actionp */
                                            0 /* hideseparatorb */,
                                            NULL, /* skipbp */
                                            NULL, /* declp */
                                            &(rhsPrimaryp->callp),
                                            NULL /* separatorcallp */);
  if (MARPAESLIF_UNLIKELY(rulep == NULL)) {
    goto err;
  }

  /* Mark it internal */
  rulep->internalb = 1;

  GENERICSTACK_SET_PTR(grammarBootstrapp->ruleStackp, rulep, rulep->idi);
  if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(grammarBootstrapp->ruleStackp))) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "ruleStackp set failure, %s", strerror(errno));
    goto err;
  }

  if (eventInitializationp != NULL) {
    if (MARPAESLIF_UNLIKELY(eventInitializationp->eventNames == NULL)) {
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "In :discard rule, event name is NULL");
      goto err;
    }
    /* Take care, we set the discard event on the RULE - not on the symbol */
    if (rulep->discardEvents != NULL) {
      free(rulep->discardEvents);
    }
    rulep->discardEvents = strdup(eventInitializationp->eventNames);
    if (MARPAESLIF_UNLIKELY(rulep->discardEvents == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "strdup failure, %s", strerror(errno));
      goto err;
    }
    switch (eventInitializationp->initializerb) {
    case MARPAESLIF_BOOTSTRAP_EVENT_INITIALIZER_TYPE_ON:
      rulep->discardEventb = 1;
      break;
    case MARPAESLIF_BOOTSTRAP_EVENT_INITIALIZER_TYPE_OFF:
      rulep->discardEventb = 0;
      break;
    default:
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "In :discard rule, unsupported event initializer type %d", (int) eventInitializationp->initializerb);
      goto err;
      break;
    }
  }

  MARPAESLIF_BOOTSTRAP_SET_UNDEF(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_NA /* context not used */);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_rhs_primary_freev(rhsPrimaryp);
  _marpaESLIF_bootstrap_adverb_list_items_freev(adverbListItemStackp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIF_bootstrap_G1_action_event_declarationb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb, marpaESLIF_bootstrap_event_declaration_type_t type)
/*****************************************************************************/
{
  /* <TYPE event declaration> ::= 'event' <event initialization> {'=' OR <op_declare>} 'TYPE' <lhs> */
  static const char                           *funcs                       = "_marpaESLIF_bootstrap_G1_action_event_declarationb";
  marpaESLIFGrammar_bootstrap_t               *marpaESLIFGrammarBootstrapp = (marpaESLIFGrammar_bootstrap_t *) userDatavp;
  marpaESLIF_bootstrap_event_initialization_t *eventInitializationp        = NULL;
  marpaESLIF_bootstrap_lhs_t                  *bootstrapLhsp               = NULL;
  char                                       **eventsp                     = NULL;
  short                                       *eventbp                     = NULL;
#ifndef MARPAESLIF_NTRACE
  char                                        *types                       = NULL;
#endif
  marpaESLIF_grammar_bootstrap_t              *grammarBootstrapp;
  marpaESLIF_symbol_t                         *lhsp;
  short                                        intb = 0;
  int                                          leveli = 0;
  short                                        rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i+1, eventInitializationp);
  /* It is a non-sense to have a null information */
  if (MARPAESLIF_UNLIKELY(eventInitializationp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "eventInitializationp at indice %d returned NULL", arg0i+2);
    goto err;
  }
  MARPAESLIF_BOOTSTRAP_IS_INT(marpaESLIFValuep, arg0i+2, intb);
  if (intb) {
    MARPAESLIF_BOOTSTRAP_GET_INT(marpaESLIFValuep, arg0i+2, leveli);
  }
  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i+4, bootstrapLhsp);
  if (MARPAESLIF_UNLIKELY(bootstrapLhsp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "bootstrapLhsp at indice %d returned NULL", arg0i+2);
    goto err;
  }

  /* Check grammar at that level exist */
  grammarBootstrapp = _marpaESLIF_bootstrap_check_grammarBootstrapp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, leveli, NULL);
  if (MARPAESLIF_UNLIKELY(grammarBootstrapp == NULL)) {
    goto err;
  }

  /* Check the symbol */
  lhsp = _marpaESLIF_bootstrap_check_lhsp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, bootstrapLhsp);
  if (MARPAESLIF_UNLIKELY(lhsp == NULL)) {
    goto err;
  }

  /* It is a non-sense to have an event initialization without a name */
  if (MARPAESLIF_UNLIKELY(eventInitializationp->eventNames == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "In event declaration for symbol <%s>, event name is NULL", bootstrapLhsp->symbols);
    goto err;
  }

  /* Update symbol */
  switch (type) {
  case MARPAESLIF_BOOTSTRAP_EVENT_DECLARATION_TYPE_PREDICTED:
    eventsp = &(lhsp->eventPredicteds);
    eventbp = &(lhsp->eventPredictedb);
#ifndef MARPAESLIF_NTRACE
    types   = "predicted";
#endif
    break;
  case MARPAESLIF_BOOTSTRAP_EVENT_DECLARATION_TYPE_NULLED:
    eventsp = &(lhsp->eventNulleds);
    eventbp = &(lhsp->eventNulledb);
#ifndef MARPAESLIF_NTRACE
    types   = "nulled";
#endif
    break;
  case MARPAESLIF_BOOTSTRAP_EVENT_DECLARATION_TYPE_COMPLETED:
    eventsp = &(lhsp->eventCompleteds);
    eventbp = &(lhsp->eventCompletedb);
#ifndef MARPAESLIF_NTRACE
    types   = "completion";
#endif
    break;
  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "In event declaration for symbol <%s>, unsupported event type %d", bootstrapLhsp->symbols, type);
    goto err;
    break;
  }
  
  if (*eventsp != NULL) {
    free(*eventsp);
  }
  *eventsp = strdup(eventInitializationp->eventNames);
  if (MARPAESLIF_UNLIKELY(*eventsp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "strdup failure, %s", strerror(errno));
    goto err;
  }
  switch (eventInitializationp->initializerb) {
  case MARPAESLIF_BOOTSTRAP_EVENT_INITIALIZER_TYPE_ON:
    *eventbp = 1;
    break;
  case MARPAESLIF_BOOTSTRAP_EVENT_INITIALIZER_TYPE_OFF:
    *eventbp = 0;
    break;
  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "In completion event declaration for symbol <%s>, unsupported event initializer type %d", bootstrapLhsp->symbols, (int) eventInitializationp->initializerb);
    goto err;
    break;
  }

  _marpaESLIF_lua_functiondecl_freev(lhsp->eventDeclp);
  lhsp->eventDeclp = NULL;
  if (bootstrapLhsp->declp != NULL) {
    lhsp->eventDeclp = _marpaESLIF_lua_functiondecl_clonep(marpaESLIFValuep->marpaESLIFp, bootstrapLhsp->declp);
    if (lhsp->eventDeclp == NULL) {
      goto err;
    }
  }

  MARPAESLIF_BOOTSTRAP_SET_UNDEF(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_NA /* context not used */);

#ifndef MARPAESLIF_NTRACE
  MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Setted %s event %s=%s for symbol <%s> at grammar level %d", types, *eventsp, *eventbp ? "on" : "off", bootstrapLhsp->symbols, leveli);
#endif

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_event_initialization_freev(eventInitializationp);
  _marpaESLIF_bootstrap_lhs_freev(bootstrapLhsp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_completion_event_declaration_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  return _marpaESLIF_bootstrap_G1_action_event_declarationb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, MARPAESLIF_BOOTSTRAP_EVENT_DECLARATION_TYPE_COMPLETED);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_completion_event_declaration_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  return _marpaESLIF_bootstrap_G1_action_event_declarationb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, MARPAESLIF_BOOTSTRAP_EVENT_DECLARATION_TYPE_COMPLETED);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_nulled_event_declaration_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  return _marpaESLIF_bootstrap_G1_action_event_declarationb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, MARPAESLIF_BOOTSTRAP_EVENT_DECLARATION_TYPE_NULLED);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_nulled_event_declaration_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  return _marpaESLIF_bootstrap_G1_action_event_declarationb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, MARPAESLIF_BOOTSTRAP_EVENT_DECLARATION_TYPE_NULLED);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_predicted_event_declaration_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  return _marpaESLIF_bootstrap_G1_action_event_declarationb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, MARPAESLIF_BOOTSTRAP_EVENT_DECLARATION_TYPE_PREDICTED);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_predicted_event_declaration_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  return _marpaESLIF_bootstrap_G1_action_event_declarationb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, MARPAESLIF_BOOTSTRAP_EVENT_DECLARATION_TYPE_PREDICTED);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_alternative_name_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <alternative name> ::= <quoted string literal> */
  void                              *bytep;
  size_t                             bytel;
  marpaESLIF_bootstrap_utf_string_t *quotedStringp = NULL;
  short                              rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i, bytep, bytel);
  quotedStringp = _marpaESLIF_bootstrap_unquote_string_literalp(marpaESLIFValuep, bytep, bytel, 0 /* allowEmptyStringb */);
  if (MARPAESLIF_UNLIKELY(quotedStringp == NULL)) {
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_SET_ARRAY(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ALTERNATIVE_NAME, quotedStringp->bytep, quotedStringp->bytel);
  quotedStringp->bytep = NULL; /* We want to keep this pointer */

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_utf_string_freev(quotedStringp, 0 /* onStackb */);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_namingb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <naming> ::= 'name' '=>' <alternative name> */
  /* <alternative name> is always an array */
  marpaESLIF_bootstrap_utf_string_t *namingp     = NULL;
  void                              *bytep;
  size_t                             bytel;
  short                              rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, argni, bytep, bytel);
  /* It is a non-sense to have a null information */
  if (MARPAESLIF_UNLIKELY((bytep == NULL) || (bytel <= 0))) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "_marpaESLIFValue_stack_getb at indice %d returned {p,%ld}", argni, bytep, (unsigned long) bytel);
    goto err;
  }

  namingp = _marpaESLIF_bootstrap_utf_string_newp(marpaESLIFValuep->marpaESLIFp);
  if (MARPAESLIF_UNLIKELY(namingp == NULL)) {
    goto err;
  }

  /* Duplicate bytep */
  namingp->bytel               = bytel;
  namingp->bytep     = malloc(bytel + 1);
  if (MARPAESLIF_UNLIKELY(namingp->bytep == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  memcpy(namingp->bytep, bytep, bytel);
  namingp->bytep[bytel] = '\0';

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_NAMING, namingp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_utf_string_freev(namingp, 0 /* onStackb */);
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_exception_statementb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <exception statement> ::= <lhs> <op declare> <rhs primary> '-' <rhs primary> <adverb list> */
  static const char                    *funcs                       = "_marpaESLIF_bootstrap_G1_action_exception_statementb";
  marpaESLIFGrammar_bootstrap_t        *marpaESLIFGrammarBootstrapp = (marpaESLIFGrammar_bootstrap_t *) userDatavp;
  marpaESLIF_rule_t                    *rulep                       = NULL;
  genericStack_t                       *adverbListItemStackp        = NULL;
  marpaESLIF_bootstrap_rhs_primary_t   *rhsPrimaryp                 = NULL;
  marpaESLIF_bootstrap_rhs_primary_t   *rhsPrimaryExceptionp        = NULL;
  marpaESLIF_bootstrap_lhs_t           *bootstrapLhsp               = NULL;
  short                                 undefb;
  int                                   leveli;
  marpaESLIF_symbol_t                  *lhsp;
  marpaESLIF_symbol_t                  *rhsp;
  marpaESLIF_symbol_t                  *rhsExceptionp;
  marpaESLIF_grammar_bootstrap_t       *grammarBootstrapp;
  marpaESLIF_action_t                  *actionp = NULL;
  int                                   ranki = 0;
  short                                 nullRanksHighb = 0;
  marpaESLIF_bootstrap_utf_string_t    *namingp;
  short                                 rcb;
  
  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i, bootstrapLhsp);
  if (MARPAESLIF_UNLIKELY(bootstrapLhsp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "bootstrapLhsp is NULL");
    goto err;
  }
  MARPAESLIF_BOOTSTRAP_GET_INT(marpaESLIFValuep, arg0i+1, leveli);
  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i+2, rhsPrimaryp);
  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i+4, rhsPrimaryExceptionp);
  /* adverb list may be undef */
  MARPAESLIF_BOOTSTRAP_IS_UNDEF(marpaESLIFValuep, argni, undefb);
  if (! undefb) {
    MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, argni, adverbListItemStackp);
    /* Non-sense to have a NULL stack in this case */
    if (MARPAESLIF_UNLIKELY(adverbListItemStackp == NULL)) {
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "adverbListItemStackp is NULL");
      goto err;
    }
  }
 
  /* Check grammar at that level exist */
  grammarBootstrapp = _marpaESLIF_bootstrap_check_grammarBootstrapp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, leveli, NULL);
  if (MARPAESLIF_UNLIKELY(grammarBootstrapp == NULL)) {
    goto err;
  }

  /* Check the lhs */
  lhsp = _marpaESLIF_bootstrap_check_lhsp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, bootstrapLhsp);
  if (MARPAESLIF_UNLIKELY(lhsp == NULL)) {
    goto err;
  }

  /* Check the rhs primary - we know it has to be a lexeme, and a lexeme cannot be parameterized. */
  if (rhsPrimaryp->callp != NULL) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Left side of an exception rule cannot be parameterized");
    goto err;
  }
  /* Note that we force the symbol to be unique - this is because the exception is part of the symbol definition */
  rhsp = _marpaESLIF_bootstrap_check_rhsPrimaryp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, rhsPrimaryp, 1 /* createb */, 1 /* forcecreateb */);
  if (MARPAESLIF_UNLIKELY(rhsp == NULL)) {
    goto err;
  }

  /* Check the rhs primary exception. */
  if (rhsPrimaryExceptionp->callp != NULL) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Right side of an exception rule cannot be parameterized");
    goto err;
  }
  /* Check the rhs primary exception */
  rhsExceptionp = _marpaESLIF_bootstrap_check_rhsPrimaryp(marpaESLIFValuep, marpaESLIFGrammarBootstrapp, grammarBootstrapp, rhsPrimaryExceptionp, 1 /* createb */, 0 /* forcecreateb */);
  if (MARPAESLIF_UNLIKELY(rhsExceptionp == NULL)) {
    goto err;
  }

  /* Check the adverb list */
  if (MARPAESLIF_UNLIKELY(! _marpaESLIF_bootstrap_unpack_adverbListItemStackb(marpaESLIFValuep,
                                                                              "exception rule",
                                                                              adverbListItemStackp,
                                                                              &actionp,
                                                                              NULL, /* left_associationbp */
                                                                              NULL, /* right_associationbp */
                                                                              NULL, /* group_associationbp */
                                                                              NULL, /* separatorRhsPrimarypp */
                                                                              NULL, /* properbp */
                                                                              NULL, /* verbosebpp */
                                                                              NULL, /* hideseparatorbp */
                                                                              &ranki,
                                                                              &nullRanksHighb,
                                                                              NULL, /* priorityipp */
                                                                              NULL, /* pauseip */
                                                                              NULL, /* latmbp */
                                                                              NULL, /* discardIsFallbackbp */
                                                                              &namingp,
                                                                              NULL, /* symbolactionpp */
                                                                              NULL, /* eventInitializationpp */
                                                                              NULL, /* ifactionpp */
                                                                              NULL, /* regexactionpp */
                                                                              NULL, /* eventactionpp */
                                                                              NULL, /* defaultEncodingsp */
                                                                              NULL /* fallbackEncodingsp */
                                                                              ))) {
    goto err;
  }

  MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Creating exception rule %s ::= %s - %s", lhsp->descp->asciis, rhsp->descp->asciis, rhsExceptionp->descp->asciis);
  /* If naming is not NULL, it is guaranteed to be an UTF-8 thingy */
  rulep = _marpaESLIF_bootstrap_check_rulep(marpaESLIFValuep,
                                            marpaESLIFGrammarBootstrapp,
                                            grammarBootstrapp,
                                            (namingp != NULL) ? (char *) MARPAESLIF_UTF8_STRING : NULL, /* descEncodings */
                                            (namingp != NULL) ? namingp->bytep : NULL, /* descs */
                                            (namingp != NULL) ? namingp->bytel : 0, /* descl */
                                            lhsp->idi,
                                            1, /* nrhsl */
                                            &(rhsp->idi), /* rhsip */
                                            rhsExceptionp->idi,
                                            ranki,
                                            0, /*nullRanksHighb */
                                            0, /* sequenceb */
                                            0, /* minimumi */
                                            -1, /* separatori */
                                            0, /* properb */
                                            actionp,
                                            0 /* hideseparatorb */,
                                            NULL, /* skipbp */
                                            bootstrapLhsp->declp,
                                            NULL, /* An exception consist only of lexemes, that can never be parameterized */
                                            NULL /* separatorcallp */);
  if (MARPAESLIF_UNLIKELY(rulep == NULL)) {
    goto err;
  }
  GENERICSTACK_SET_PTR(grammarBootstrapp->ruleStackp, rulep, rulep->idi);
  if (MARPAESLIF_UNLIKELY(GENERICSTACK_ERROR(grammarBootstrapp->ruleStackp))) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "ruleStackp set failure, %s", strerror(errno));
    goto err;
  }

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_lhs_freev(bootstrapLhsp);
  _marpaESLIF_bootstrap_rhs_primary_freev(rhsPrimaryp);
  _marpaESLIF_bootstrap_rhs_primary_freev(rhsPrimaryExceptionp);
  _marpaESLIF_bootstrap_adverb_list_items_freev(adverbListItemStackp);
  return rcb;
}

/*****************************************************************************/
static inline marpaESLIF_bootstrap_utf_string_t *_marpaESLIF_bootstrap_regex_to_stringb(marpaESLIF_t *marpaESLIFp, void *bytep, size_t bytel)
/*****************************************************************************/
{
  marpaESLIF_bootstrap_utf_string_t *stringp               = NULL;
  char                              *modifiers             = NULL;
  void                              *newbytep              = NULL;
  marpaESLIFRecognizer_t            *marpaESLIFRecognizerp = NULL; /* Fake recognizer to use the internal regex */
  size_t                             newbytel;
  marpaESLIFValueResult_t            marpaESLIFValueResult;
  size_t                             sizel;
  marpaESLIF_matcher_value_t         rci;
  size_t                             matchedLengthl;

  /* It is a non-sense to have a null lexeme */
  if (MARPAESLIF_UNLIKELY((bytep == NULL) || (bytel <= 0))) {
    MARPAESLIF_ERRORF(marpaESLIFp, "_marpaESLIF_bootstrap_regex_to_stringb called with {bytep,bytel}={%p,%ld}", bytep, (unsigned long) bytel);
    goto err;
  }

  /* Extract opti from the array */
  /* Thre are several methods...: */
  /* - Re-execute the sub-grammar as if it was a top grammar */
  /* - apply a regexp to extract the modifiers. */
  /* - revisit our own top grammar to have two separate lexemes (which I do not like because modifers can then be separated from regex by a discard symbol) */
  /* ... Since we are internal anyway I choose (what I think is) the costless method: the regexp */

  /* Fake a recognizer. EOF flag will be set automatically in fake mode */
  marpaESLIFRecognizerp = __marpaESLIFRecognizer_newp(marpaESLIFp,
                                                      NULL, /* grammarp */
                                                      NULL, /* marpaESLIFRecognizerOptionp */
                                                      0, /* discardb - no effect anway because we are in fake mode */
                                                      1, /* noEventb - no effect anway because we are in fake mode */
                                                      0, /* silentb */
                                                      NULL, /* marpaESLIFRecognizerParentp */
                                                      1, /* fakeb */
                                                      0, /* wantedStartCompletionsi */
                                                      1, /* A grammar is always transformed to valid UTF-8 before being parsed */
                                                      0 /* isLexemeb */);
  if (MARPAESLIF_UNLIKELY(marpaESLIFRecognizerp == NULL)) {
    goto err;
  }
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_terminal_matcherb(marpaESLIFRecognizerp,
                                                                    marpaESLIFRecognizerp->marpaESLIF_streamp,
                                                                    marpaESLIFp->regexModifiersp,
                                                                    bytep,
                                                                    bytel,
                                                                    1, /* eofb */
                                                                    &rci,
                                                                    &marpaESLIFValueResult,
                                                                    &matchedLengthl))) {
    goto err;
  }
  if (rci == MARPAESLIF_MATCH_OK) {
    /* Got modifiers. Per def this is an sequence of ASCII characters. */
    /* For a regular expression it is something like "xxxxx" */
#ifndef MARPAESLIF_NTRACE
    /* Paranoid mode */
    if (MARPAESLIF_UNLIKELY(marpaESLIFValueResult.u.a.sizel <= 0)) {
      MARPAESLIF_ERROR(marpaESLIFp, "Match of character class modifiers returned empty size");
      goto err;
    }
#endif
    /* We want to maintain marpaESLIFValueResult lifetime, so need to unshallow the result of the INTERNAL method _marpaESLIFRecognizer_terminal_matcherb() if necessary */
    if (marpaESLIFValueResult.u.a.shallowb) {
      modifiers = (char *) malloc(marpaESLIFValueResult.u.a.sizel + 1);
      if (MARPAESLIF_UNLIKELY(modifiers == NULL)) {
        MARPAESLIF_ERRORF(marpaESLIFp, "malloc failure, %s", strerror(errno));
        goto err;
      }
      memcpy(modifiers, marpaESLIFValueResult.u.a.p, marpaESLIFValueResult.u.a.sizel);
      modifiers[marpaESLIFValueResult.u.a.sizel] = '\0';
    } else {
      modifiers = (char *) marpaESLIFValueResult.u.a.p;
    }
    sizel = marpaESLIFValueResult.u.a.sizel;
  } else {
    /* Because we use this value just below */
    sizel = 0;
  }

  stringp = _marpaESLIF_bootstrap_utf_string_newp(marpaESLIFp);
  if (MARPAESLIF_UNLIKELY(stringp == NULL)) {
    goto err;
  }

  /* By definition a regular expression is a lexeme in this form: /xxxx/modifiers */
  /* we have already catched the modifiers. But we have to shift the UTF-8 buffer: */
  /* - We know per def that it is starting with the "/" ASCII character (one byte) */
  /* - We know per def that it is ending with "/modifiers", all of them being ASCII characters (one byte each) */
  newbytel = bytel - 2; /* First "/" and last "/" */
  if (MARPAESLIF_UNLIKELY(newbytel <= 0)) {
    /* Empty regex !? */
    MARPAESLIF_ERROR(marpaESLIFp, "Empty regex");
    goto err;
  }
  if (sizel > 0) {
    newbytel -= sizel;  /* "xxxx" */
  }
  if (MARPAESLIF_UNLIKELY(newbytel <= 0)) {
    /* Still Empty regex !? */
    MARPAESLIF_ERROR(marpaESLIFp, "Empty regex");
    goto err;
  }
  newbytep = malloc(newbytel);
  if (MARPAESLIF_UNLIKELY(newbytep == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  memcpy(newbytep, (void *) (((char *) bytep) + 1), newbytel);
  stringp->modifiers = modifiers;
  stringp->bytep     = newbytep;
  stringp->bytel     = newbytel;
  modifiers = NULL; /* modifiers is in singleSymbolp */
  newbytep = NULL; /* newbytep is in singleSymbolp */

  goto done;

 err:
  _marpaESLIF_bootstrap_utf_string_freev(stringp, 0 /* onStackb */);
  stringp = NULL;

 done:
  if (newbytep != NULL) {
    free(newbytep);
  }
  if (modifiers != NULL) {
    free(modifiers);
  }
  marpaESLIFRecognizer_freev(marpaESLIFRecognizerp);
 return stringp;
}

/*****************************************************************************/
static inline marpaESLIF_bootstrap_utf_string_t *_marpaESLIF_bootstrap_characterClass_to_stringp(marpaESLIF_t *marpaESLIFp, void *bytep, size_t bytel)
/*****************************************************************************/
{
  marpaESLIF_bootstrap_utf_string_t *stringp               = NULL;
  char                              *modifiers             = NULL;
  marpaESLIFRecognizer_t            *marpaESLIFRecognizerp = NULL; /* Fake recognizer to use the internal regex */
  void                              *dupp                  = NULL;
  size_t                             dupl;
  marpaESLIFValueResult_t            marpaESLIFValueResult;
  size_t                             sizel;
  marpaESLIF_matcher_value_t         rci;
  char                              *tmps;
  size_t                             matchedLengthl;

  /* It is a non-sense to have a null lexeme */
  if (MARPAESLIF_UNLIKELY((bytep == NULL) || (bytel <= 0))) {
    MARPAESLIF_ERRORF(marpaESLIFp, "_marpaESLIF_bootstrap_characterClass_to_stringp called with {bytep,bytel}={%p,%ld}", bytep, (unsigned long) bytel);
    goto err;
  }

  /* Duplicate bytep in any case */
  tmps = (char *) malloc(bytel + 1);
  if (MARPAESLIF_UNLIKELY(tmps == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  memcpy(tmps, bytep, bytel);
  tmps[bytel] = '\0';
  dupp = tmps;
  dupl = bytel;

  /* Extract options from it */
  /* Thre are several methods...: */
  /* - Re-execute the sub-grammar as if it was a top grammar */
  /* - apply a regexp to extract the modifiers. */
  /* - revisit our own top grammar to have two separate lexemes (which I do not like because modifers can then be separated from regex by a discard symbol) */
  /* ... Since we are internal anyway I choose (what I think is) the costless method: the regexp */

  /* Fake a recognizer. EOF flag will be set automatically in fake mode */
  marpaESLIFRecognizerp = __marpaESLIFRecognizer_newp(marpaESLIFp,
                                                      NULL, /* grammarp */
                                                      NULL, /* marpaESLIFRecognizerOptionp */
                                                      0, /* discardb */
                                                      1, /* noEventb - no effect anway because we are in fake mode */
                                                      0, /* silentb */
                                                      NULL, /* marpaESLIFRecognizerParentp */
                                                      1, /* fakeb */
                                                      0, /* wantedStartCompletionsi */
                                                      1, /* A grammar is always transformed to valid UTF-8 before being parsed */
                                                      0 /* isLexemeb */);
  if (MARPAESLIF_UNLIKELY(marpaESLIFRecognizerp == NULL)) {
    goto err;
  }
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_terminal_matcherb(marpaESLIFRecognizerp,
                                                                    marpaESLIFRecognizerp->marpaESLIF_streamp,
                                                                    marpaESLIFp->characterClassModifiersp,
                                                                    dupp,
                                                                    dupl,
                                                                    1, /* eofb */
                                                                    &rci,
                                                                    &marpaESLIFValueResult,
                                                                    &matchedLengthl))) {
    goto err;
  }
  if (rci == MARPAESLIF_MATCH_OK) {
    /* Got modifiers. Per def this is an sequence of ASCII characters. */
    /* For a character class it is something like ":xxxxx" */
#ifndef MARPAESLIF_NTRACE
    /* Paranoid mode */
    if (MARPAESLIF_UNLIKELY(marpaESLIFValueResult.u.a.sizel <= 0)) {
      MARPAESLIF_ERROR(marpaESLIFp, "Match of character class modifiers returned empty size");
      goto err;
    }
#endif
    /* We want to maintain marpaESLIFValueResult lifetime, so need to unshallow the result of the INTERNAL method _marpaESLIFRecognizer_terminal_matcherb() if necessary */
    if (marpaESLIFValueResult.u.a.shallowb) {
      modifiers = (char *) malloc(marpaESLIFValueResult.u.a.sizel + 1);
      if (MARPAESLIF_UNLIKELY(modifiers == NULL)) {
        MARPAESLIF_ERRORF(marpaESLIFp, "malloc failure, %s", strerror(errno));
        goto err;
      }
      memcpy(modifiers, marpaESLIFValueResult.u.a.p, marpaESLIFValueResult.u.a.sizel);
      modifiers[marpaESLIFValueResult.u.a.sizel] = '\0';
    } else {
      modifiers = (char *) marpaESLIFValueResult.u.a.p;
    }
    sizel = marpaESLIFValueResult.u.a.sizel;
  } else {
    /* Because we use this value just below */
    sizel = 0;
  }

  stringp = _marpaESLIF_bootstrap_utf_string_newp(marpaESLIFp);
  if (MARPAESLIF_UNLIKELY(stringp == NULL)) {
    goto err;
  }

  stringp->modifiers = modifiers;
  stringp->bytep     = dupp;
  stringp->bytel     = dupl;

  modifiers = NULL; /* modifiers is in singleSymbolp */
  dupp      = NULL; /* dupp is in singleSymbolp */

  if (sizel > 0) {
    stringp->bytel -= (sizel + 1);  /* ":xxxx" */
  }

  goto done;

 err:
  _marpaESLIF_bootstrap_utf_string_freev(stringp, 0 /* onStackb */);
  stringp = NULL;

 done:
  if (dupp != NULL) {
    free(dupp);
  }
  if (modifiers != NULL) {
    free(modifiers);
  }
  marpaESLIFRecognizer_freev(marpaESLIFRecognizerp);
 return stringp;
}

/*****************************************************************************/
static inline int _marpaESLIF_bootstrap_ord2utfb(marpaESLIF_uint32_t uint32, PCRE2_UCHAR *bufferp)
/*****************************************************************************/
{
  int i;
  int j;

  for (i = 0; i < utf8_table1_size; i++) {
    if ((int)uint32 <= utf8_table1[i]) {
      break;
    }
  }
  bufferp += i;
  for (j = i; j > 0; j--) {
    *bufferp-- = 0x80 | (uint32 & 0x3f);
    uint32 >>= 6;
  }
  *bufferp = utf8_table2[i] | uint32;
  return i + 1;
}

/*****************************************************************************/
static inline short _marpaESLIF_bootstrap_G1_action_rhs_alternative_prioritiesb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb, short skipb, short lookaheadb)
/*****************************************************************************/
{
  /*  skipb     : <rhs alternative> ::= '(-'  <priorities> '-)' */
  /* !skipb     : <rhs alternative> ::= '('   <priorities>  ')' */
  /*  lookaheadb: <rhs alternative> ::= '(?=' <priorities>  ')' */
  /* !lookaheadb: <rhs alternative> ::= '(?!' <priorities>  ')' */
  genericStack_t                           *alternativesStackp = NULL;
  marpaESLIF_bootstrap_rhs_alternative_t   *rhsAlternativep    = NULL;
  short                                     rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i + 1, alternativesStackp);
  /* It is a non-sense to not have valid information */
  if (MARPAESLIF_UNLIKELY(alternativesStackp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "alternativesStackp at indice %d is NULL", arg0i + 1);
    goto err;
  }

  rhsAlternativep = (marpaESLIF_bootstrap_rhs_alternative_t *) malloc(sizeof(marpaESLIF_bootstrap_rhs_alternative_t));
  if (MARPAESLIF_UNLIKELY(rhsAlternativep == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  rhsAlternativep->type                            = MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_PRIORITIES;
  rhsAlternativep->u.priorities.skipb              = skipb;
  rhsAlternativep->u.priorities.lookaheadb         = lookaheadb;
  rhsAlternativep->u.priorities.alternativesStackp = alternativesStackp;
  alternativesStackp = NULL; /* alternativesStackp is now in rhsAlternativep */

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_RHS_ALTERNATIVE, rhsAlternativep);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_rhs_alternative_freev(rhsAlternativep);
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_priorities_freev(alternativesStackp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_rhs_alternative_8b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /*  <rhs alternative> ::= /\(\?[=!]/ <priorities> ')' */
  short         lookaheadb;
  char         *asciis;
  size_t        asciil;
  short         rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i, asciis, asciil); /* This is a terminal */

  if (MARPAESLIF_UNLIKELY(asciis == NULL)) {
    /* Should never happen */
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Null terminal");
    goto err;
  }
  if (MARPAESLIF_UNLIKELY(asciil < 3)) {
    /* Should never happen as per the grammar */
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Too short terminal \"%s\"", asciis);
    goto err;
  }

  switch (asciis[2]) {
  case '=':
    lookaheadb = 1; /* Positive lookahead */
    break;
  case '!':
    lookaheadb = -1; /* Negative lookahead */
    break;
  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Invalid 3rd character in terminal \"%s\"", asciis);
    goto err;
  }

  rcb = _marpaESLIF_bootstrap_G1_action_rhs_alternative_prioritiesb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, 0 /* skipb */, lookaheadb);
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_rhs_alternative_9b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /*  <rhs alternative> ::= /\(\?[=!]/ <rhs primary> '-' <rhs primary> <adverb list> ')' */
  short         lookaheadb;
  char         *asciis;
  size_t        asciil;
  short         rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i, asciis, asciil); /* This is a terminal */

  if (MARPAESLIF_UNLIKELY(asciis == NULL)) {
    /* Should never happen */
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Null terminal");
    goto err;
  }
  if (MARPAESLIF_UNLIKELY(asciil < 3)) {
    /* Should never happen as per the grammar */
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Too short terminal \"%s\"", asciis);
    goto err;
  }

  switch (asciis[2]) {
  case '=':
    lookaheadb = 1; /* Positive lookahead */
    break;
  case '!':
    lookaheadb = -1; /* Negative lookahead */
    break;
  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Invalid 3rd character in terminal \"%s\"", asciis);
    goto err;
  }

  rcb = _marpaESLIF_bootstrap_G1_action_rhs_alternative_exceptionb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, 0 /* skipb */, lookaheadb);
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_rhs_alternative_10b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <rhs alternative> ::= /\(\?[=!]/ <rhs primary> <quantifier> <adverb list> ')' */
  short         lookaheadb;
  char         *asciis;
  size_t        asciil;
  short         rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i, asciis, asciil); /* This is a terminal */

  if (MARPAESLIF_UNLIKELY(asciis == NULL)) {
    /* Should never happen */
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Null terminal");
    goto err;
  }
  if (MARPAESLIF_UNLIKELY(asciil < 3)) {
    /* Should never happen as per the grammar */
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Too short terminal \"%s\"", asciis);
    goto err;
  }

  switch (asciis[2]) {
  case '=':
    lookaheadb = 1; /* Positive lookahead */
    break;
  case '!':
    lookaheadb = -1; /* Negative lookahead */
    break;
  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Invalid 3rd character in terminal \"%s\"", asciis);
    goto err;
  }

  rcb = _marpaESLIF_bootstrap_G1_action_rhs_alternative_quantifiedb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, 0 /* skipb */, lookaheadb);
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIF_bootstrap_G1_action_rhs_alternative_exceptionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb, short skipb, short lookaheadb)
/*****************************************************************************/
{
  /*  skipb     : <rhs alternative> ::= '(-'  <rhs primary> '-' <rhs primary> <adverb list> '-)' */
  /* !skipb     : <rhs alternative> ::= '('   <rhs primary> '-' <rhs primary> <adverb list>  ')' */
  /*  lookaheadb: <rhs alternative> ::= '(?=' <rhs primary> '-' <rhs primary> <adverb list>  ')' */
  /* !lookaheadb: <rhs alternative> ::= '(?!' <rhs primary> '-' <rhs primary> <adverb list>  ')' */
  marpaESLIF_bootstrap_rhs_primary_t       *rhsPrimaryp          = NULL;
  marpaESLIF_bootstrap_rhs_primary_t       *rhsPrimaryExceptionp = NULL;
  genericStack_t                           *adverbListItemStackp = NULL;
  marpaESLIF_bootstrap_rhs_alternative_t   *rhsAlternativep      = NULL;
  short                                     undefb;
  short                                     rcb;

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i+1, rhsPrimaryp);
  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i+3, rhsPrimaryExceptionp);
  /* adverb list may be undef */
  MARPAESLIF_BOOTSTRAP_IS_UNDEF(marpaESLIFValuep, arg0i+4, undefb);
  if (! undefb) {
    MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i+4, adverbListItemStackp);
    /* Non-sense to have a NULL stack in this case */
    if (MARPAESLIF_UNLIKELY(adverbListItemStackp == NULL)) {
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "adverbListItemStackp is NULL");
      goto err;
    }
  }

  rhsAlternativep = (marpaESLIF_bootstrap_rhs_alternative_t *) malloc(sizeof(marpaESLIF_bootstrap_rhs_alternative_t));
  if (MARPAESLIF_UNLIKELY(rhsAlternativep == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  rhsAlternativep->type                             = MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_EXCEPTION;
  rhsAlternativep->u.exception.skipb                = skipb;
  rhsAlternativep->u.exception.lookaheadb           = lookaheadb;
  rhsAlternativep->u.exception.rhsPrimaryp          = rhsPrimaryp;
  rhsAlternativep->u.exception.rhsPrimaryExceptionp = rhsPrimaryExceptionp;
  rhsAlternativep->u.exception.adverbListItemStackp = adverbListItemStackp;

  rhsPrimaryp = NULL; /* rhsPrimaryp is now in rhsAlternativep */
  rhsPrimaryExceptionp = NULL; /* rhsPrimaryExceptionp is now in rhsAlternativep */
  adverbListItemStackp = NULL; /* adverbListItemStackp is now in rhsAlternativep */

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_RHS_ALTERNATIVE, rhsAlternativep);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_rhs_alternative_freev(rhsAlternativep);
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_rhs_primary_freev(rhsPrimaryp);
  _marpaESLIF_bootstrap_rhs_primary_freev(rhsPrimaryExceptionp);
  _marpaESLIF_bootstrap_adverb_list_items_freev(adverbListItemStackp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIF_bootstrap_G1_action_rhs_alternative_quantifiedb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb, short skipb, short lookaheadb)
/*****************************************************************************/
{
  /*  skipb     : <rhs alternative> ::= '(-'  <rhs primary> <quantifier> <adverb list> '-)' */
  /* !skipb     : <rhs alternative> ::= '('   <rhs primary> <quantifier> <adverb list>  ')' */
  /*  lookaheadb: <rhs alternative> ::= '(?=' <rhs primary> <quantifier> <adverb list>  ')' */
  /* !lookaheadb: <rhs alternative> ::= '(?!' <rhs primary> <quantifier> <adverb list>  ')' */
  marpaESLIF_bootstrap_rhs_primary_t       *rhsPrimaryp          = NULL;
  int                                       minimumi;
  genericStack_t                           *adverbListItemStackp = NULL;
  marpaESLIF_bootstrap_rhs_alternative_t   *rhsAlternativep      = NULL;
  short                                     undefb;
  short                                     rcb;

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i+1, rhsPrimaryp);
  MARPAESLIF_BOOTSTRAP_GET_INT(marpaESLIFValuep, arg0i+2, minimumi);
  /* adverb list may be undef */
  MARPAESLIF_BOOTSTRAP_IS_UNDEF(marpaESLIFValuep, arg0i+3, undefb);
  if (! undefb) {
    MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i+3, adverbListItemStackp);
    /* Non-sense to have a NULL stack in this case */
    if (MARPAESLIF_UNLIKELY(adverbListItemStackp == NULL)) {
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "adverbListItemStackp is NULL");
      goto err;
    }
  }

  rhsAlternativep = (marpaESLIF_bootstrap_rhs_alternative_t *) malloc(sizeof(marpaESLIF_bootstrap_rhs_alternative_t));
  if (MARPAESLIF_UNLIKELY(rhsAlternativep == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  rhsAlternativep->type                              = MARPAESLIF_BOOTSTRAP_RHS_ALTERNATIVE_TYPE_QUANTIFIED;
  rhsAlternativep->u.quantified.skipb                = skipb;
  rhsAlternativep->u.quantified.lookaheadb           = lookaheadb;
  rhsAlternativep->u.quantified.rhsPrimaryp          = rhsPrimaryp;
  rhsAlternativep->u.quantified.minimumi             = minimumi;
  rhsAlternativep->u.quantified.adverbListItemStackp = adverbListItemStackp;

  rhsPrimaryp = NULL; /* rhsPrimaryp is now in rhsAlternativep */
  adverbListItemStackp = NULL; /* adverbListItemStackp is now in rhsPrimaryp */

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_RHS_ALTERNATIVE, rhsAlternativep);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_rhs_alternative_freev(rhsAlternativep);
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_rhs_primary_freev(rhsPrimaryp);
  _marpaESLIF_bootstrap_adverb_list_items_freev(adverbListItemStackp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_luascript_statementb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <external script statement> ::= <external script tag start> <discard off> <external script source> <external script tag end> <discard on>  */
  static const char   *funcs                                 = "_marpaESLIF_bootstrap_G1_action_luascript_statementb";
  marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp = (marpaESLIFGrammar_bootstrap_t *) userDatavp;
  char                *luabytep;
  size_t               luabytel;
  short                rcb;
  char                *tmps;
  size_t               tmpl;
  short                undefb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  /* But source can be nullable */
  MARPAESLIF_BOOTSTRAP_IS_UNDEF(marpaESLIFValuep, arg0i+2, undefb);

  if (! undefb) {
    MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i+2, luabytep, luabytel);
    /* It is a non-sense to not have valid information */
    if (MARPAESLIF_UNLIKELY((luabytep == NULL) || (luabytel <= 0))) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "_marpaESLIFValue_stack_getb at indice %d returned {%p,%ld}", arg0i+2, luabytep, (unsigned long) luabytel);
      goto err;
    }

    if (marpaESLIFGrammarBootstrapp->luabytep == NULL) {
      /* First time: duplicate luabytep */
      marpaESLIFGrammarBootstrapp->luabytep = (char *) malloc(luabytel + 1);
      if (MARPAESLIF_UNLIKELY(marpaESLIFGrammarBootstrapp->luabytep == NULL)) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
        goto err;
      }
      memcpy(marpaESLIFGrammarBootstrapp->luabytep, luabytep, luabytel);
      marpaESLIFGrammarBootstrapp->luabytep[luabytel] = '\0';
      marpaESLIFGrammarBootstrapp->luabytel = luabytel;
      MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Setted lua script of size %ld luabytes", (unsigned long) luabytel);
    } else {
      /* Append bytes - they are guaranteed to be full character bytes, i.e. a raw concat of the buffer is ok */
      tmpl = marpaESLIFGrammarBootstrapp->luabytel + luabytel;
      /* Turnaround ? */
      if (MARPAESLIF_UNLIKELY(tmpl < marpaESLIFGrammarBootstrapp->luabytel)) {
        MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "size_t turnaround detected");
        goto err;
      }
      tmps = (char *) realloc(marpaESLIFGrammarBootstrapp->luabytep, tmpl + 1); /* Hiden NUL byte */
      if (MARPAESLIF_UNLIKELY(tmps == NULL)) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "realloc failure, %s", strerror(errno));
        goto err;
      }
      tmps[tmpl] = '\0';
      marpaESLIFGrammarBootstrapp->luabytep = tmps;
      memcpy(marpaESLIFGrammarBootstrapp->luabytep + marpaESLIFGrammarBootstrapp->luabytel, luabytep, luabytel);
      marpaESLIFGrammarBootstrapp->luabytel = tmpl;
      MARPAESLIF_TRACEF(marpaESLIFValuep->marpaESLIFp, funcs, "Appended lua script of size %ld bytes, full script size is now %ld", (unsigned long) luabytel, (unsigned long) marpaESLIFGrammarBootstrapp->luabytel);
    }
  }

  MARPAESLIF_BOOTSTRAP_SET_UNDEF(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_NA /* context not used */);

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_ifactionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <if action> ::= 'if-action' '=>' <if action name> */
  return _marpaESLIF_bootstrap_G1_action_genericb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, "if-action", MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_IFACTION);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_regexactionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <regex action> ::= 'regex-action' '=>' <regex action name> */
  return _marpaESLIF_bootstrap_G1_action_genericb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, "regex-action", MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_REGEXACTION);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_generatoractionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <generator action> ::= '.' '=>' <generator action name> */
  return _marpaESLIF_bootstrap_G1_action_genericb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, ".", MARPAESLIF_BOOTSTRAP_STACK_TYPE_ACTION);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_eventactionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <event action> ::= 'event-action' '=>' <event action name> */
  return _marpaESLIF_bootstrap_G1_action_genericb(userDatavp, marpaESLIFValuep, arg0i, argni, resulti, nullableb, "event-action", MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_EVENTACTION);
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_defaultencodingb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <default encoding> ::= 'default-encoding' '=>' <default encoding name> */
  char                *defaultEncodings = NULL;
  short                shallowb         = 0;
  char                *tmps;
  short                rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  /* <default encoding name> is an ASCII string, guaranteed to NUL terminated as per the doc  */
  MARPAESLIF_BOOTSTRAP_GETANDFORGET_ASCII(marpaESLIFValuep, argni, defaultEncodings, shallowb);
  /* It is a non-sense to not have no action in this case */
  if (MARPAESLIF_UNLIKELY(defaultEncodings == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "default-encoding at indice %d returned NULL", argni);
    goto err;
  }
  /* Unshallow it if necessary */
  if (shallowb) {
    tmps = strdup(defaultEncodings);
    if (MARPAESLIF_UNLIKELY(tmps == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "strdup failure, %s", strerror(errno));
      goto err;
    }
    defaultEncodings = tmps;
    shallowb = 0;
  }

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_DEFAULTENCODING, defaultEncodings);
  defaultEncodings = NULL;

  rcb = 1;
  goto done;

 err:
  if ((! shallowb) && (defaultEncodings != NULL)) {
    /* This is not possible in theory */
    free(defaultEncodings);
  }
  rcb = 0;

 done:
  return rcb;
}


/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_fallbackencodingb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <fallback encoding> ::= 'fallback-encoding' '=>' <fallback encoding name> */
  char                *fallbackEncodings = NULL;
  short                shallowb          = 0;
  char                *tmps;
  short                rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  /* <fallback encoding name> is an ASCII string  */
  MARPAESLIF_BOOTSTRAP_GETANDFORGET_ASCII(marpaESLIFValuep, argni, fallbackEncodings, shallowb);
  /* It is a non-sense to not have no action in this case */
  if (MARPAESLIF_UNLIKELY(fallbackEncodings == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "fallback-encoding at indice %d returned NULL", argni);
    goto err;
  }
  /* Unshallow it if necessary */
  if (shallowb) {
    tmps = strdup(fallbackEncodings);
    if (MARPAESLIF_UNLIKELY(tmps == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "strdup failure, %s", strerror(errno));
      goto err;
    }
    fallbackEncodings = tmps;
    shallowb = 0;
  }

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_ADVERB_ITEM_FALLBACKENCODING, fallbackEncodings);
  fallbackEncodings = NULL;

  rcb = 1;
  goto done;

 err:
  if ((! shallowb) && (fallbackEncodings != NULL)) {
    /* This is not possible in theory */
    free(fallbackEncodings);
  }
  rcb = 0;

 done:
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_lua_functionb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <lua function> ::= /::luac?\->function\(/ <lua funcbody after lparen>@+2 */
  char                                *luas                  = NULL;
  size_t                               lual                  = 0;
  char                                *actions               = NULL;
  size_t                               actionl               = 0;
  char                                *luacstripp            = NULL;
  size_t                               luacstripl            = 0;
  marpaESLIF_bootstrap_lua_function_t *bootstrapLuaFunctionp = NULL;
  char                                *arg0s;
  size_t                               arg0l;
  char                                *p;
  char                                *luaFuncbodyAfterLparens;
  size_t                               luaFuncbodyAfterLparenl;
  short                                rcb;

  /* By definition, because both '::lua->function(' terminal and             */
  /* <lua funcbody after lparen> lexeme have a :discard[switch] after event  */
  /* the whole content starting at the '(' character of ''::lua->function('' */
  /* must compile inside lua.                                                */
  /* We compile in lua a function that will return the wanted function...:   */
  /* return function( xxxxxxxx                                               */
  /* Here, we are doing grammar validation: we compile a stripped binary.    */
  /* This will NEVER be used at runtime, it is used only for actions         */
  /* comparison (c.f. the case of nulled semantics).                         */

  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i, arg0s, arg0l);
  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i + 1, luaFuncbodyAfterLparens, luaFuncbodyAfterLparenl);

  lual = arg0l;
  lual += luaFuncbodyAfterLparenl;
  luas = (char *) malloc(lual + 1);
  if (luas == NULL) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }

  p = luas;
  memcpy(p, arg0s, arg0l);
  p += arg0l;
  memcpy(p, luaFuncbodyAfterLparens, luaFuncbodyAfterLparenl);
  p += luaFuncbodyAfterLparenl;
  *p = '\0';

  actionl  = strlen(_marpaESLIF_bootstrap_lua_return_function_lparens); /* "return function(" */
  actionl += luaFuncbodyAfterLparenl;

  actions = (char *) malloc(actionl + 1);
  if (MARPAESLIF_UNLIKELY(actions == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  
  p = actions;
  memcpy(p, _marpaESLIF_bootstrap_lua_return_function_lparens, strlen(_marpaESLIF_bootstrap_lua_return_function_lparens));
  p += strlen(_marpaESLIF_bootstrap_lua_return_function_lparens);
  memcpy(p, luaFuncbodyAfterLparens, luaFuncbodyAfterLparenl);
  p += luaFuncbodyAfterLparenl;
  *p = '\0';

  /* We precompile the stripped version */
  if (! _marpaESLIF_lua_value_precompileb(marpaESLIFValuep, actions, actionl, 1 /* stripb */, 1 /* popi */)) {
    goto err;
  }

  bootstrapLuaFunctionp = (marpaESLIF_bootstrap_lua_function_t *) malloc(sizeof(marpaESLIF_bootstrap_lua_function_t));
  if (bootstrapLuaFunctionp == NULL) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  bootstrapLuaFunctionp->luas       = luas;
  bootstrapLuaFunctionp->actions    = actions;
  bootstrapLuaFunctionp->luacb      = (strstr(luas, "::luac->function") == luas) ? 1 : 0;
  bootstrapLuaFunctionp->luacstripp = marpaESLIFValuep->luaprecompiledp;
  bootstrapLuaFunctionp->luacstripl = marpaESLIFValuep->luaprecompiledl;

  luas                              = NULL;
  actions                           = NULL;
  marpaESLIFValuep->luaprecompiledp = NULL;
  marpaESLIFValuep->luaprecompiledl = 0;

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_LUA_FUNCTION, bootstrapLuaFunctionp);
  /* bootstrapLuaFunctionp is in the stack */
  bootstrapLuaFunctionp = NULL;

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  if (luas != NULL) {
    free(luas);
  }
  if (actions != NULL) {
    free(actions);
  }
  _marpaESLIF_bootstrap_lua_function_freev(bootstrapLuaFunctionp);
  return rcb;
}

/*****************************************************************************/
static inline short _marpaESLIF_bootstrap_G1_action_genericb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb, char *contexts, void *contextp)
/*****************************************************************************/
{
  /* ... ::= contexts '=>' <action name> */
  char                                *names                 = NULL;
  marpaESLIF_action_t                 *actionp               = NULL;
  char                                *actions               = NULL;
  marpaESLIF_bootstrap_lua_function_t *bootstrapLuaFunctionp = NULL;
  marpaESLIFValueResult_t             *marpaESLIFValueResultp;
  char                                *tmps;
  short                                luab;
  short                                rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  marpaESLIFValueResultp = _marpaESLIFValue_stack_getp(marpaESLIFValuep, argni);
  if (MARPAESLIF_UNLIKELY(marpaESLIFValueResultp == NULL)) {
    goto err;
  }

  switch (marpaESLIFValueResultp->type) {
  case MARPAESLIF_VALUE_TYPE_STRING:
    /* <action name> is an ASCII string or a PTR (precompiled)  */
    MARPAESLIF_BOOTSTRAP_GET_ASCII(marpaESLIFValuep, argni, names);
    /* It is a non-sense to not have no action in this case */
    if (MARPAESLIF_UNLIKELY(names == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "%s: Indice %d returned NULL", contexts, argni);
      goto err;
    }
    if (strstr(names, LUA_ACTION_PREFIX) == names) {
      /* lua action ? */
      tmps = names + strlen(LUA_ACTION_PREFIX);
      if (MARPAESLIF_UNLIKELY(*tmps == '\0')) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "%: No lua identifier after %s", contexts, LUA_ACTION_PREFIX);
        goto err;
      }
      actions = strdup(tmps);
      if (MARPAESLIF_UNLIKELY(actions == NULL)) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "%s: strdup failure, %s", contexts, strerror(errno));
        goto err;
      }
      luab = 1;
    } else {
      actions = strdup(names);
      if (MARPAESLIF_UNLIKELY(actions == NULL)) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "%s: strdup failure, %s", contexts, strerror(errno));
        goto err;
      }
      luab = 0;
    }

    actionp = (marpaESLIF_action_t *) malloc(sizeof(marpaESLIF_action_t));
    if (MARPAESLIF_UNLIKELY(actionp == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
      goto err;
    }
    if (luab) {
      actionp->type = MARPAESLIF_ACTION_TYPE_LUA;
      actionp->u.luas = actions;
    } else {
      actionp->type = MARPAESLIF_ACTION_TYPE_NAME;
      actionp->u.names = actions;
    }
    actions = NULL; /* actions is now in actionp */
    break;

  case MARPAESLIF_VALUE_TYPE_PTR:
    MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, argni, bootstrapLuaFunctionp);
    /* It is a non-sense to not have no action in this case */
    if (MARPAESLIF_UNLIKELY(bootstrapLuaFunctionp == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "%s: Indice %d returned NULL", contexts, argni);
      goto err;
    }
    actionp = (marpaESLIF_action_t *) malloc(sizeof(marpaESLIF_action_t));
    if (MARPAESLIF_UNLIKELY(actionp == NULL)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
      goto err;
    }

    /* Transfer the content of bootstrapLuaFunctionp */
    actionp->type = MARPAESLIF_ACTION_TYPE_LUA_FUNCTION;
    actionp->u.luaFunction.luas = bootstrapLuaFunctionp->luas;
    actionp->u.luaFunction.actions = bootstrapLuaFunctionp->actions;
    actionp->u.luaFunction.luacb = bootstrapLuaFunctionp->luacb;
    actionp->u.luaFunction.luacp = NULL; /* For runtime only */
    actionp->u.luaFunction.luacl = 0; /* For runtime only */
    actionp->u.luaFunction.luacstripp = bootstrapLuaFunctionp->luacstripp;
    actionp->u.luaFunction.luacstripl = bootstrapLuaFunctionp->luacstripl;

    free(bootstrapLuaFunctionp);
    bootstrapLuaFunctionp = NULL; /* actions is now in actionp */
    break;

  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "marpaESLIFValueResultp->type is not ASCII nor PTR (got %d, %s)", marpaESLIFValueResultp->type, _marpaESLIF_value_types(marpaESLIFValueResultp->type));
    goto err;
  }
    
  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, contextp, actionp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_action_freev(actionp);
  rcb = 0;

 done:
  if (actions != NULL) {
    free(actions);
  }
  _marpaESLIF_bootstrap_lua_function_freev(bootstrapLuaFunctionp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_lua_functioncallb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
/* Note that the action produced here will be reworked by grammar validation */
/* We always produce something like this for RHS->(rhsArgs):                 */
/* return table.pack(rhsArgs)                                                */
/* And in the context of an LHS, e.g. LHS<-(lhsArgs)                         */
/* this will become:                                                         */
/* function(lhsArgs) return table.pack(rhsArgs) end                          */
/* i.e. the LHS arguments are evaluated for this RHS with this final thing.  */
/*****************************************************************************/
{
  /* <lua functioncall> ::= /\-\-?>\(/' <lua args after lparen>@+2 */
  char                          *luaexplists                = NULL;
  size_t                         luaexplistl                = 0;
  marpaESLIF_lua_functioncall_t *callp                      = NULL;
  marpaESLIFRecognizerOption_t   marpaESLIFRecognizerOption = marpaESLIFRecognizerOption_default_template;
  marpaESLIFValueOption_t        marpaESLIFValueOption      = marpaESLIFValueOption_default_template;
  marpaESLIFGrammarOption_t      marpaESLIFGrammarOption;
  marpaESLIF_readerContext_t     marpaESLIF_readerContext;
  char                          *arg0s;
  size_t                         arg0l;
  char                          *p;
  char                          *luaArgsAfterLparens;
  size_t                         luaArgsAfterLparenl;
  short                          rcb;

  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i, arg0s, arg0l);
  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i + 1, luaArgsAfterLparens, luaArgsAfterLparenl);

  luaexplistl = 1; /* '(' */
  luaexplistl += luaArgsAfterLparenl;
  luaexplists = (char *) malloc(luaexplistl + 1);
  if (luaexplists == NULL) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }

  p = luaexplists;
  *p++ = '(';
  memcpy(p, luaArgsAfterLparens, luaArgsAfterLparenl);
  p += luaArgsAfterLparenl;
  *p = '\0';

  callp = _marpaESLIF_lua_functioncall_newp(marpaESLIFValuep->marpaESLIFp);
  if (callp == NULL) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }

  /* Get the number of expressions - by definition this should never fail since we managed to parse it as a lexeme */
  marpaESLIFGrammarOption.bytep     = (void *) luaArgsAfterLparens;
  marpaESLIFGrammarOption.bytel     = luaArgsAfterLparenl;
  marpaESLIFGrammarOption.encodings = NULL;
  marpaESLIFGrammarOption.encodingl = 0;

  marpaESLIF_readerContext.marpaESLIFp              = marpaESLIFValuep->marpaESLIFp;
  marpaESLIF_readerContext.marpaESLIFGrammarOptionp = &marpaESLIFGrammarOption;

  marpaESLIFRecognizerOption.userDatavp        = (void *) &marpaESLIF_readerContext;
  marpaESLIFRecognizerOption.readerCallbackp   = _marpaESLIFReader_grammarReader;

  marpaESLIFValueOption.userDatavp            = &(callp->sizei);
  marpaESLIFValueOption.importerp             = marpaESLIFValueImport;

  if (! marpaESLIFGrammar_parse_by_levelb(marpaESLIFValuep->marpaESLIFp->marpaESLIFGrammarLuapp[MARPAESLIFGRAMMARLUA_FOR_EXPLIST],
                                          &marpaESLIFRecognizerOption,
                                          &marpaESLIFValueOption,
                                          NULL, /* isExhaustedbp */
                                          2, /* leveli */
                                          NULL /* descp */)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Failed to get number of expressions for: %s", luaexplists);
    goto err;
  }
  
  callp->luaexplists  = luaexplists;
  callp->luaexplistcb = (strcmp(arg0s, "-->(") == 0) ? 1 : 0;

  luaexplists = NULL;

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_LUA_FUNCTIONCALL, callp);
  /* callp is in the stack */
  callp = NULL;

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  if (luaexplists != NULL) {
    free(luaexplists);
  }
  _marpaESLIF_lua_functioncall_freev(callp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_lua_functiondeclb(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <lua functiondecl> ::= /<\-\-?\(/' <lua optional parlist after lparen>@+2 */
  char                          *luaparlists                = NULL;
  size_t                         luaparlistl                = 0;
  marpaESLIF_lua_functiondecl_t *declp                      = NULL;
  marpaESLIFRecognizerOption_t   marpaESLIFRecognizerOption = marpaESLIFRecognizerOption_default_template;
  marpaESLIFValueOption_t        marpaESLIFValueOption      = marpaESLIFValueOption_default_template;
  marpaESLIFGrammarOption_t      marpaESLIFGrammarOption;
  marpaESLIF_readerContext_t     marpaESLIF_readerContext;
  char                          *arg0s;
  size_t                         arg0l;
  char                          *p;
  char                          *luaOptionalParlistAfterLparens;
  size_t                         luaOptionalParlistAfterLparenl;
  short                          rcb;

  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i, arg0s, arg0l);
  MARPAESLIF_BOOTSTRAP_GET_ARRAY(marpaESLIFValuep, arg0i + 1, luaOptionalParlistAfterLparens, luaOptionalParlistAfterLparenl);

  luaparlistl = 1; /* '(' */
  luaparlistl += luaOptionalParlistAfterLparenl;
  luaparlists = (char *) malloc(luaparlistl + 1);
  if (luaparlists == NULL) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }

  p = luaparlists;
  *p++ = '(';
  memcpy(p, luaOptionalParlistAfterLparens, luaOptionalParlistAfterLparenl);
  p += luaOptionalParlistAfterLparenl;
  *p = '\0';

  declp = _marpaESLIF_lua_functiondecl_newp(marpaESLIFValuep->marpaESLIFp);
  if (declp == NULL) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }

  /* Get the number of parameters - by definition this should never fail since we managed to parse it as a lexeme */
  marpaESLIFGrammarOption.bytep     = (void *) luaOptionalParlistAfterLparens;
  marpaESLIFGrammarOption.bytel     = luaOptionalParlistAfterLparenl;
  marpaESLIFGrammarOption.encodings = NULL;
  marpaESLIFGrammarOption.encodingl = 0;

  marpaESLIF_readerContext.marpaESLIFp              = marpaESLIFValuep->marpaESLIFp;
  marpaESLIF_readerContext.marpaESLIFGrammarOptionp = &marpaESLIFGrammarOption;

  marpaESLIFRecognizerOption.userDatavp        = (void *) &marpaESLIF_readerContext;
  marpaESLIFRecognizerOption.readerCallbackp   = _marpaESLIFReader_grammarReader;

  marpaESLIFValueOption.userDatavp            = &(declp->sizei);
  marpaESLIFValueOption.importerp             = marpaESLIFValueImport;

  if (! marpaESLIFGrammar_parse_by_levelb(marpaESLIFValuep->marpaESLIFp->marpaESLIFGrammarLuapp[MARPAESLIFGRAMMARLUA_FOR_PARLIST],
                                          &marpaESLIFRecognizerOption,
                                          &marpaESLIFValueOption,
                                          NULL, /* isExhaustedbp */
                                          2, /* leveli */
                                          NULL /* descp */)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Failed to get number of parameters for: %s", luaparlists);
    goto err;
  }
  
  declp->luaparlists  = luaparlists;
  declp->luaparlistcb = (strcmp(arg0s, "<--(") == 0) ? 1 : 0;

  luaparlists   = NULL;

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_LUA_FUNCTIONDECL, declp);
  /* declp is in the stack */
  declp = NULL;

  rcb = 1;
  goto done;

 err:
  rcb = 0;

 done:
  if (luaparlists != NULL) {
    free(luaparlists);
  }
  _marpaESLIF_lua_functiondecl_freev(declp);

  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_lhs_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <lhs> ::= <symbol name> */
  marpaESLIF_bootstrap_lhs_t   *bootstrapLhsp = NULL;
  char                         *symbols       = NULL;
  short                         rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  /* symbolNames is an ASCII string that we pushed into a PTR that we own */
  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i, symbols);
  if (MARPAESLIF_UNLIKELY(symbols == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "symbols is NULL");
    goto err;
  }

  /* Make that an lhs structure */
  bootstrapLhsp = (marpaESLIF_bootstrap_lhs_t *) malloc(sizeof(marpaESLIF_bootstrap_lhs_t));
  if (MARPAESLIF_UNLIKELY(bootstrapLhsp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  bootstrapLhsp->symbols = NULL;
  bootstrapLhsp->declp   = NULL;

  bootstrapLhsp->symbols = strdup(symbols);
  if (bootstrapLhsp->symbols == NULL) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "strdup failure, %s", strerror(errno));
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_LHS, bootstrapLhsp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_lhs_freev(bootstrapLhsp);
  rcb = 0;

 done:
  if (symbols != NULL) {
    free(symbols);
  }
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_lhs_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <lhs> ::= <lhs> <lua functiondecl> */
  marpaESLIF_bootstrap_lhs_t    *lhsp        = NULL;
  marpaESLIF_lua_functiondecl_t *declp       = NULL;
  short                          rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i, lhsp);
  /* It is a non-sense to not have valid information */
  if (MARPAESLIF_UNLIKELY(lhsp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "lhsp at indice %d is NULL", arg0i);
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i + 1, declp);
  /* It is a non-sense to not have valid information */
  if (MARPAESLIF_UNLIKELY(declp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "declp at indice %d is NULL", arg0i + 1);
    goto err;
  }

  lhsp->declp = declp;
  declp = NULL;
  
  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_LHS, lhsp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_lhs_freev(lhsp);
  rcb = 0;

 done:
  _marpaESLIF_lua_functiondecl_freev(declp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_start_symbol_1b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <start symbol> ::= <symbol name> */
  marpaESLIF_bootstrap_start_symbol_t *startSymbolp = NULL;
  char                                *symbols      = NULL;
  marpaESLIF_bootstrap_symbol_t       *symbolp      = NULL;
  short                                rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i, symbolp);
  if (MARPAESLIF_UNLIKELY(symbolp == NULL)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "symbolp is NULL");
    goto err;
  }

  /* Make that a start symbol structure */
  startSymbolp = (marpaESLIF_bootstrap_start_symbol_t *) malloc(sizeof(marpaESLIF_bootstrap_start_symbol_t));
  if (MARPAESLIF_UNLIKELY(startSymbolp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  startSymbolp->symbols          = NULL;
  startSymbolp->callp = NULL;

  startSymbolp->symbols = strdup(symbolp->symbols);
  if (startSymbolp->symbols == NULL) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "strdup failure, %s", strerror(errno));
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_START_SYMBOL, startSymbolp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_start_symbol_freev(startSymbolp);
  rcb = 0;

 done:
  _marpaESLIF_bootstrap_symbol_freev(symbolp);
  return rcb;
}

/*****************************************************************************/
static short _marpaESLIF_bootstrap_G1_action_start_symbol_2b(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, int arg0i, int argni, int resulti, short nullableb)
/*****************************************************************************/
{
  /* <start symbol> ::= <start symbol> <lua functioncall> */
  marpaESLIF_bootstrap_start_symbol_t *startSymbolp     = NULL;
  marpaESLIF_lua_functioncall_t       *callp = NULL;
  short                                rcb;

  /* Cannot be nullable */
  if (MARPAESLIF_UNLIKELY(nullableb)) {
    MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Nullable mode is not supported");
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i, startSymbolp);
  /* It is a non-sense to not have valid information */
  if (MARPAESLIF_UNLIKELY(startSymbolp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "startSymbolp at indice %d is NULL", arg0i);
    goto err;
  }

  MARPAESLIF_BOOTSTRAP_GETANDFORGET_PTR(marpaESLIFValuep, arg0i + 1, callp);
  /* It is a non-sense to not have valid information */
  if (MARPAESLIF_UNLIKELY(callp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "callp at indice %d is NULL", arg0i + 1);
    goto err;
  }

  startSymbolp->callp = callp;
  callp = NULL;
  
  MARPAESLIF_BOOTSTRAP_SET_PTR(marpaESLIFValuep, resulti, MARPAESLIF_BOOTSTRAP_STACK_TYPE_START_SYMBOL, startSymbolp);

  rcb = 1;
  goto done;

 err:
  _marpaESLIF_bootstrap_start_symbol_freev(startSymbolp);
  rcb = 0;

 done:
  _marpaESLIF_lua_functioncall_freev(callp);
  return rcb;
}

/*****************************************************************************/
static inline marpaESLIF_rule_t *_marpaESLIF_bootstrap_check_rulep(marpaESLIFValue_t *marpaESLIFValuep, marpaESLIFGrammar_bootstrap_t *marpaESLIFGrammarBootstrapp, marpaESLIF_grammar_bootstrap_t *grammarBootstrapp, char *descEncodings, char *descs, size_t descl, int lhsi, size_t nrhsl, int *rhsip, int exceptioni, int ranki, short nullRanksHighb, short sequenceb, int minimumi, int separatori, short properb, marpaESLIF_action_t *actionp, short hideseparatorb, short *skipbp, marpaESLIF_lua_functiondecl_t *declp, marpaESLIF_lua_functioncall_t **callpp, marpaESLIF_lua_functioncall_t *separatorcallp)
{
  return _marpaESLIF_rule_newp(marpaESLIFValuep->marpaESLIFp,
                               grammarBootstrapp->symbolStackp,
                               grammarBootstrapp->leveli,
                               grammarBootstrapp->marpaWrapperGrammarStartp,
                               descEncodings,
                               descs,
                               descl,
                               lhsi,
                               nrhsl,
                               rhsip,
                               exceptioni,
                               ranki,
                               nullRanksHighb,
                               sequenceb,
                               minimumi,
                               separatori,
                               properb,
                               actionp,
                               hideseparatorb,
                               skipbp,
                               declp,
                               callpp,
                               separatorcallp);
}

/*****************************************************************************/
static short marpaESLIFValueImport(marpaESLIFValue_t *marpaESLIFValuep, void *userDatavp, marpaESLIFValueResult_t *marpaESLIFValueResultp, short haveUndefb)
/*****************************************************************************/
{
  int          *sizeip      = (int *) userDatavp;
  short         rcb;

  /* We expect a lua integer and nothing else. Note that we do not test if the number is < 0. We own the actions */
  /* (c.f. src/lua.c), we know this cannot happen. We just verify that result fits in a int (which is unsigned btw). */
  switch (marpaESLIFValueResultp->type) {
  case MARPAESLIF_VALUE_TYPE_SHORT:
    if (sizeof(int) < sizeof(short)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Cannot store a short in a int (sizeof(short) is %ld, sizeof(int) is %ld)", (unsigned long) sizeof(short), (unsigned long) sizeof(int));
      goto err;
    }
    *sizeip = (int) marpaESLIFValueResultp->u.b;
    break;
  case MARPAESLIF_VALUE_TYPE_INT:
    if (sizeof(int) < sizeof(int)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Cannot store a short in a int (sizeof(int) is %ld, sizeof(int) is %ld)", (unsigned long) sizeof(int), (unsigned long) sizeof(int));
      goto err;
    }
    *sizeip = (int) marpaESLIFValueResultp->u.i;
    break;
  case MARPAESLIF_VALUE_TYPE_LONG:
    if (sizeof(int) < sizeof(long)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Cannot store a long in a int (sizeof(long) is %ld, sizeof(int) is %ld)", (unsigned long) sizeof(long), (unsigned long) sizeof(int));
      goto err;
    }
    *sizeip = (int) marpaESLIFValueResultp->u.l;
    break;
#ifdef MARPAESLIF_HAVE_LONG_LONG
  case MARPAESLIF_VALUE_TYPE_LONG_LONG:
    if (sizeof(int) < sizeof(long)) {
      MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "Cannot store a long long in a int (sizeof(long long) is %ld, sizeof(int) is %ld)", (unsigned long) sizeof(long long), (unsigned long) sizeof(int));
      goto err;
    }
    *sizeip = (int) marpaESLIFValueResultp->u.ll;
    break;
#endif
  default:
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "marpaESLIFValueResultp->type is invalid (got %d, %s)", marpaESLIFValueResultp->type, _marpaESLIF_value_types(marpaESLIFValueResultp->type));
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
static inline marpaESLIF_bootstrap_terminal_t *_marpaESLIF_bootstrap_quotedstring_to_terminalp(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, void *bytep, size_t bytel, marpaESLIF_terminal_t *modifiersp)
/*****************************************************************************/
{
  marpaESLIF_bootstrap_terminal_t  *rcp                   = NULL;
  marpaESLIFRecognizer_t           *marpaESLIFRecognizerp = NULL; /* Fake recognizer to use the internal regex */
  char                             *modifiers             = NULL;
  char                             *tmps;
  char                             *stringdups;
  marpaESLIFValueResult_t           marpaESLIFValueResult;
  size_t                            modifiersl;
  marpaESLIF_matcher_value_t        rci;
  size_t                            matchedLengthl;

  /* Duplicate bytep */
  tmps = (char *) malloc(bytel + 1);
  if (MARPAESLIF_UNLIKELY(tmps == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  memcpy(tmps, bytep, bytel);
  tmps[bytel] = '\0';
  stringdups = tmps;

  /* Fake a recognizer. EOF flag will be set automatically in fake mode */
  marpaESLIFRecognizerp = __marpaESLIFRecognizer_newp(marpaESLIFValuep->marpaESLIFp,
                                                      NULL, /* grammarp */
                                                      NULL, /* marpaESLIFRecognizerOptionp */
                                                      0, /* discardb - no effect anway because we are in fake mode */
                                                      1, /* noEventb - no effect anway because we are in fake mode */
                                                      0, /* silentb */
                                                      NULL, /* marpaESLIFRecognizerParentp */
                                                      1, /* fakeb */
                                                      0, /* wantedStartCompletionsi */
                                                      1, /* A grammar is always transformed to valid UTF-8 before being parsed */
                                                      0 /* isLexemeb */);
  if (MARPAESLIF_UNLIKELY(marpaESLIFRecognizerp == NULL)) {
    goto err;
  }
  if (MARPAESLIF_UNLIKELY(! _marpaESLIFRecognizer_terminal_matcherb(marpaESLIFRecognizerp,
                                                                    marpaESLIFRecognizerp->marpaESLIF_streamp,
                                                                    modifiersp,
                                                                    stringdups,
                                                                    bytel,
                                                                    1, /* eofb */
                                                                    &rci,
                                                                    &marpaESLIFValueResult,
                                                                    &matchedLengthl))) {
    goto err;
  }
  if (rci == MARPAESLIF_MATCH_OK) {
    /* Got modifiers. Per def this is an sequence of ASCII characters. */
    /* For a character class it is something like ":xxxxx" */
#ifndef MARPAESLIF_NTRACE
    /* Paranoid test */
    if (MARPAESLIF_UNLIKELY(marpaESLIFValueResult.u.a.sizel <= 0)) {
      MARPAESLIF_ERROR(marpaESLIFValuep->marpaESLIFp, "Match of character class modifiers returned empty size");
      goto err;
    }
#endif
    /* We want to maintain marpaESLIFValueResult lifetime, so need to unshallow the result of the INTERNAL method _marpaESLIFRecognizer_terminal_matcherb() if necessary */
    if (marpaESLIFValueResult.u.a.shallowb) {
      modifiers = (char *) malloc(marpaESLIFValueResult.u.a.sizel + 1);
      if (MARPAESLIF_UNLIKELY(modifiers == NULL)) {
        MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
        goto err;
      }
      memcpy(modifiers, marpaESLIFValueResult.u.a.p, marpaESLIFValueResult.u.a.sizel);
      modifiers[marpaESLIFValueResult.u.a.sizel] = '\0';
    } else {
      modifiers = (char *) marpaESLIFValueResult.u.a.p;
    }
    modifiersl = marpaESLIFValueResult.u.a.sizel;
  } else {
    /* Because we use this value just below */
    modifiersl = 0;
  }

  /* We leave the quotes because terminal_newp(), in case of a STRING, removes the surrounding characters. */
  /* Remember that a quoted string is a regexp with enforced unicode mode. Therefore the match is guaranteed to */
  /* have been done on a buffer always pre-converted to UTF-8, regardless of the original encoding of the input. */

  /* Make that a single symbol structure */
  rcp = (marpaESLIF_bootstrap_terminal_t *) malloc(sizeof(marpaESLIF_bootstrap_terminal_t));
  if (MARPAESLIF_UNLIKELY(rcp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  rcp->type = MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE_NA;
  rcp->u.stringp = _marpaESLIF_bootstrap_utf_string_newp(marpaESLIFValuep->marpaESLIFp);
  if (MARPAESLIF_UNLIKELY(rcp->u.stringp == NULL)) {
    goto err;
  }

  rcp->type                 = MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE_QUOTED_STRING;
  rcp->u.stringp->modifiers = modifiers;
  rcp->u.stringp->bytep     = stringdups;
  rcp->u.stringp->bytel     = bytel;
  modifiers = NULL; /* modifiers is in singleSymbolp */
  stringdups = NULL; /* strings is in singleSymbolp */
  if (modifiersl > 0) {
    rcp->u.stringp->bytel -= (modifiersl + 1);  /* ":xxxx" */
  }

  goto done;

 err:
  _marpaESLIF_bootstrap_terminal_freev(rcp);
  rcp = NULL;

 done:
  if (modifiers != NULL) {
    free(modifiers);
  }
  marpaESLIFRecognizer_freev(marpaESLIFRecognizerp);
  return rcp;
}

/*****************************************************************************/
static inline marpaESLIF_bootstrap_terminal_t *_marpaESLIF_bootstrap_regex_to_terminalp(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, void *bytep, size_t bytel)
/*****************************************************************************/
{
  marpaESLIF_bootstrap_terminal_t *rcp;

  rcp = (marpaESLIF_bootstrap_terminal_t *) malloc(sizeof(marpaESLIF_bootstrap_terminal_t));
  if (MARPAESLIF_UNLIKELY(rcp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFValuep->marpaESLIFp, "malloc failure, %s", strerror(errno));
    goto err;
  }
  rcp->type                 = MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE_NA;
  rcp->u.regularExpressionp = _marpaESLIF_bootstrap_regex_to_stringb(marpaESLIFValuep->marpaESLIFp, bytep, bytel);
  if (MARPAESLIF_UNLIKELY(rcp->u.regularExpressionp == NULL)) {
    goto err;
  }
  rcp->type                 = MARPAESLIF_BOOTSTRAP_TERMINAL_TYPE_REGULAR_EXPRESSION;

  goto done;

 err:
  _marpaESLIF_bootstrap_terminal_freev(rcp);
  rcp = NULL;

 done:
 return rcp;
}

/*****************************************************************************/
static inline marpaESLIF_bootstrap_utf_string_t *_marpaESLIF_bootstrap_utf_string_newp(marpaESLIF_t *marpaESLIFp)
/*****************************************************************************/
{
  marpaESLIF_bootstrap_utf_string_t *rcp;

  rcp = (marpaESLIF_bootstrap_utf_string_t *) malloc(sizeof(marpaESLIF_bootstrap_utf_string_t));
  if (MARPAESLIF_UNLIKELY(rcp == NULL)) {
    MARPAESLIF_ERRORF(marpaESLIFp, "malloc failure, %s", strerror(errno));
  } else {
    rcp->substitutionBytep     = NULL;
    rcp->substitutionBytel     = 0;
    rcp->substitutionModifiers = NULL;
    rcp->modifiers             = NULL;
    rcp->bytel                 = 0;
    rcp->bytep                 = NULL;
  }

  return rcp;
}
