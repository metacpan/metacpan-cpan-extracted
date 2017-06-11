#ifndef MARPAESLIF_INTERNAL_ESLIF_L0_H
#define MARPAESLIF_INTERNAL_ESLIF_L0_H

#include "marpaESLIF/internal/eslif/L0_join_G1.h"

/* Description of internal L0 grammar */

/* It is very important here to list all the terminals first, and in order compatible */
/* with bootstrap_grammar_L0_terminals[] and bootstrap_grammar_L0_rules[] */
typedef enum bootstrap_grammar_L0_enum {
  L0_TERMINAL_WHITESPACE = 0,
  L0_TERMINAL_PERL_COMMENT,
  L0_TERMINAL_CPLUSPLUS_COMMENT,
  L0_TERMINAL_OP_DECLARE_ANY_GRAMMAR,
  L0_TERMINAL_OP_DECLARE_TOP_GRAMMAR,
  L0_TERMINAL_OP_DECLARE_LEX_GRAMMAR,
  L0_TERMINAL_OP_LOOSEN,
  L0_TERMINAL_OP_EQUAL_PRIORITY,
  L0_TERMINAL_TRUE,
  L0_TERMINAL_FALSE,
  L0_TERMINAL_WORD_CHARACTER,
  L0_TERMINAL_LATIN_ALPHABET_LETTER,
  L0_TERMINAL_LEFT_CURLY,
  L0_TERMINAL_RIGHT_CURLY,
  L0_TERMINAL_BRACKETED_NAME_STRING,
  L0_TERMINAL_COMMA,
  L0_TERMINAL_START, /* Grammatically support for Marpa::R2 compatibility - no effect */
  L0_TERMINAL_LENGTH, /* Grammatically support for Marpa::R2 compatibility - no effect */
  L0_TERMINAL_G1START, /* Grammatically support for Marpa::R2 compatibility - no effect */
  L0_TERMINAL_G1LENGTH, /* Grammatically support for Marpa::R2 compatibility - no effect */
  L0_TERMINAL_NAME,
  L0_TERMINAL_LHS, /* Grammatically support for Marpa::R2 compatibility - no effect */
  L0_TERMINAL_SYMBOL,
  L0_TERMINAL_RULE,
  L0_TERMINAL_VALUE,
  L0_TERMINAL_VALUES,
  L0_TERMINAL_QUOTED_STRING,
  L0_TERMINAL_REGULAR_EXPRESSION,
  L0_TERMINAL_REGULAR_EXPRESSION_MODIFIER,
  L0_TERMINAL_CHARACTER_CLASS_REGEXP,
  L0_TERMINAL_PCRE2_MODIFIERS,
  L0_TERMINAL_STRING_MODIFIERS,
  L0_TERMINAL_RESTRICTED_ASCII_GRAPH_CHARACTERS,
  L0_TERMINAL_SEMICOLON,
  /* ----- Non terminals ------ */
  L0_META_WHITESPACE,
  L0_META_PERL_COMMENT,
  L0_META_CPLUSPLUS_COMMENT,
  L0_META_OP_DECLARE_ANY_GRAMMAR,
  L0_META_OP_DECLARE_TOP_GRAMMAR,
  L0_META_OP_DECLARE_LEX_GRAMMAR,
  L0_META_OP_LOOSEN,
  L0_META_OP_EQUAL_PRIORITY,
  L0_META_TRUE,
  L0_META_FALSE,
  L0_META_WORD_CHARACTER,
  L0_META_ONE_OR_MORE_WORD_CHARACTERS,
  L0_META_ZERO_OR_MORE_WORD_CHARACTERS,
  L0_META_RESTRICTED_ASCII_GRAPH_NAME,
  L0_META_BARE_NAME,
  L0_META_STANDARD_NAME,
  L0_META_BRACKETED_NAME,
  L0_META_BRACKETED_NAME_STRING,
  L0_META_QUOTED_STRING,
  L0_META_QUOTED_NAME,
  L0_META_CHARACTER_CLASS,
  L0_META_REGULAR_EXPRESSION
} bootstrap_grammar_L0_enum_t;

/* All non-terminals are listed here */
bootstrap_grammar_meta_t bootstrap_grammar_L0_metas[] = {
  /* Identifier                           Description                              Start  Discard :discard[on] :discard[off] */
  { L0_META_WHITESPACE,                   L0_JOIN_G1_META_WHITESPACE,                  0,       0,           0,            0 },
  { L0_META_PERL_COMMENT,                 L0_JOIN_G1_META_PERL_COMMENT,                0,       0,           0,            0 },
  { L0_META_CPLUSPLUS_COMMENT,            L0_JOIN_G1_META_CPLUSPLUS_COMMENT,           0,       0,           0,            0 },
  { L0_META_OP_DECLARE_ANY_GRAMMAR,       L0_JOIN_G1_META_OP_DECLARE_ANY_GRAMMAR,      0,       0,           0,            0 },
  { L0_META_OP_DECLARE_TOP_GRAMMAR,       L0_JOIN_G1_META_OP_DECLARE_TOP_GRAMMAR,      0,       0,           0,            0 },
  { L0_META_OP_DECLARE_LEX_GRAMMAR,       L0_JOIN_G1_META_OP_DECLARE_LEX_GRAMMAR,      0,       0,           0,            0 },
  { L0_META_OP_LOOSEN,                    L0_JOIN_G1_META_OP_LOOSEN,                   0,       0,           0,            0 },
  { L0_META_OP_EQUAL_PRIORITY,            L0_JOIN_G1_META_OP_EQUAL_PRIORITY,           0,       0,           0,            0 },
  { L0_META_TRUE,                         L0_JOIN_G1_META_TRUE,                        0,       0,           0,            0 },
  { L0_META_FALSE,                        L0_JOIN_G1_META_FALSE,                       0,       0,           0,            0 },
  { L0_META_WORD_CHARACTER,               "word character",                            0,       0,           0,            0 },
  { L0_META_ONE_OR_MORE_WORD_CHARACTERS,  "one or more word characters",               0,       0,           0,            0 },
  { L0_META_ZERO_OR_MORE_WORD_CHARACTERS, "zero or more word characters",              0,       0,           0,            0 },
  { L0_META_RESTRICTED_ASCII_GRAPH_NAME,  L0_JOIN_G1_META_RESTRICTED_ASCII_GRAPH_NAME, 0,       0,           0,            0 },
  { L0_META_BARE_NAME,                    L0_JOIN_G1_META_BARE_NAME,                   0,       0,           0,            0 },
  { L0_META_STANDARD_NAME,                L0_JOIN_G1_META_STANDARD_NAME,               0,       0,           0,            0 },
  { L0_META_BRACKETED_NAME,               L0_JOIN_G1_META_BRACKETED_NAME,              0,       0,           0,            0 },
  { L0_META_BRACKETED_NAME_STRING,        "bracketed name string",                     0,       0,           0,            0 },
  { L0_META_QUOTED_STRING,                L0_JOIN_G1_META_QUOTED_STRING,               0,       0,           0,            0 },
  { L0_META_QUOTED_NAME,                  L0_JOIN_G1_META_QUOTED_NAME,                 0,       0,           0,            0 },
  { L0_META_CHARACTER_CLASS,              L0_JOIN_G1_META_CHARACTER_CLASS,             0,       0,           0,            0 },
  { L0_META_REGULAR_EXPRESSION,           L0_JOIN_G1_META_REGULAR_EXPRESSION,          0,       0,           0,            0 }
};

/* Here it is very important that all the string constants are UTF-8 compatible - this is the case */

bootstrap_grammar_terminal_t bootstrap_grammar_L0_terminals[] = {
  /* From perl stringified version to C and // versions: */
  /*
#!env perl
use strict;
use diagnostics;
use Regexp::Common 'RE_ALL';

goto pass2;
pass1:
my $r = $RE{delimited}{-delim=>"'"}{-cdelim=>"'"}; # $RE{balanced}{-parens=>'[]'};
print "==> $r\n";
print "... copy/paste that in \$this variable and switch to pass2\n";
exit;

pass2:
my $this = do { local $/; <DATA> };
$this =~ s/\s*$//;
my $copy = $this;

$this =~ s/\\/\\\\/g;
$this =~ s/"/\\"/g;
print "FOR C: $this\n";

$copy =~ s/\//\\\//g;
print "FOR /: $copy\n";

__DATA__
(?:(?|(?:\')(?:[^\\\']*(?:\\.[^\\\']*)*)(?:\')))
  */
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  /*                                                             TERMINALS                                                             */
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_WHITESPACE, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    "[\\s]+",
#ifndef MARPAESLIF_NTRACE
    "\x09\x20xxx", "\x09\x20"
#else
    NULL, NULL
#endif
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  /* Taken from Regexp::Common::comment, $RE{comment}{Perl} */
  /* Perl stringified version is: (?:(?:#)(?:[^\n]*)(?:\n)) */
  /* \z added to match the end of the buffer (ESLIF will ask more data if this is not EOF as well) */
  { L0_TERMINAL_PERL_COMMENT, MARPAESLIF_TERMINAL_TYPE_REGEX, "u",
    "(?:(?:#)(?:[^\\n]*)(?:\\n|\\z))",
#ifndef MARPAESLIF_NTRACE
    "# Comment up to the end of the buffer", "# Again a comment"
#else
    NULL, NULL
#endif
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  /* Taken from Regexp::Common::comment, $RE{comment}{'C++'}, which includes the C language comment */
  /* Perl stringified version is: (?:(?:(?://)(?:[^\n]*)(?:\n))|(?:(?:\/\*)(?:(?:[^\*]+|\*(?!\/))*)(?:\*\/))) */
  /* \z added to match the end of the buffer in the // mode (ESLIF will ask more data if this is not EOF as well) */
  { L0_TERMINAL_CPLUSPLUS_COMMENT, MARPAESLIF_TERMINAL_TYPE_REGEX, "u",
    "(?:(?:(?://)(?:[^\\n]*)(?:\\n|\\z))|(?:(?:/\\*)(?:(?:[^\\*]+|\\*(?!/))*)(?:\\*/)))",
#ifndef MARPAESLIF_NTRACE
    "// Comment up to the end of the buffer", "// Again a comment"
#else
    NULL, NULL
#endif
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_OP_DECLARE_ANY_GRAMMAR, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    ":\\[(\\d+)\\]:=",
#ifndef MARPAESLIF_NTRACE
    ":[0123]:=", ":[0"
#else
    NULL, NULL
#endif
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_OP_DECLARE_TOP_GRAMMAR, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'::='",
#ifndef MARPAESLIF_NTRACE
    "::=", "::"
#else
    NULL, NULL
#endif
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_OP_DECLARE_LEX_GRAMMAR, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'~'",
#ifndef MARPAESLIF_NTRACE
    "~", NULL
#else
    NULL, NULL
#endif
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_OP_LOOSEN, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'||'",
#ifndef MARPAESLIF_NTRACE
    NULL, NULL
#else
    "||", "|"
#endif
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_OP_EQUAL_PRIORITY, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'|'",
#ifndef MARPAESLIF_NTRACE
    NULL, NULL
#else
    "|", NULL
#endif
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_TRUE, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'1'",
#ifndef MARPAESLIF_NTRACE
    "1", ""
#else
    NULL, NULL
#endif
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_FALSE, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'0'",
#ifndef MARPAESLIF_NTRACE
    "0", ""
#else
    NULL, NULL
#endif
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_WORD_CHARACTER, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    "[\\w]",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_LATIN_ALPHABET_LETTER, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    "[a-zA-Z]",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_LEFT_CURLY, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'<'",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_RIGHT_CURLY, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'>'",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_BRACKETED_NAME_STRING, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    "[\\s\\w]+",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_COMMA, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "','",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_START, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'start'",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_LENGTH, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'length'",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_G1START, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'g1start'",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_G1LENGTH, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'g1length'",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_NAME, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'name'",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_LHS, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'lhs'",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_SYMBOL, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'symbol'",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_RULE, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'rule'",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_VALUE, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'value'",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_VALUES, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "'values'",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  /* Taken from Regexp::Common::delimited, $RE{delimited}{-delim=>q{'"\{}}{-cdelim=>q{'"\}}} */
  /* Perl stringified version is: (?:(?|(?:\')(?:[^\\\']*(?:\\.[^\\\']*)*)(?:\')|(?:\")(?:[^\\\"]*(?:\\.[^\\\"]*)*)(?:\"))) */
  { L0_TERMINAL_QUOTED_STRING, MARPAESLIF_TERMINAL_TYPE_REGEX, "su",
    "(?:(?|(?:')(?:[^\\\\']*(?:\\\\.[^\\\\']*)*)(?:')|(?:\")(?:[^\\\\\"]*(?:\\\\.[^\\\\\"]*)*)(?:\")))",
#ifndef MARPAESLIF_NTRACE
    "'A string'", "'"
#else
    NULL, NULL
#endif
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  /* Taken from Regexp::Common::delimited, $RE{delimited}{-delim=>"/"}{-cdelim=>"/"} */
  /* Perl stringified version is: (?:(?|(?:\/)(?:[^\\\/]*(?:\\.[^\\\/]*)*)(?:\/))) */
  /* We add a protection against so that it does not conflict with C++ comments. */
  /* And it appears that is ok because a regexp starting with C comment have no sense, as well */
  /* as an empty regexp starting with // */
  { L0_TERMINAL_REGULAR_EXPRESSION, MARPAESLIF_TERMINAL_TYPE_REGEX, "su",
    "(?:(?|(?:/(?![*/]))(?:[^\\\\/]*(?:\\\\.[^\\\\/]*)*)(?:/)))",
#ifndef MARPAESLIF_NTRACE
    "/a(b)c/", "/a("
#else
    NULL, NULL
#endif
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_REGULAR_EXPRESSION_MODIFIER, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    "[eijmnsxDJUuaN]",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  /* Taken from Regexp::Common::balanced, $RE{balanced}{-parens=>'[]'} */
  /* Perl stringified version is: (?^:((?:\[(?:(?>[^\[\]]+)|(?-1))*\]))) */
  /* Perl stringified version is revisited without the (?^:XXX): ((?:\[(?:(?>[^\[\]]+)|(?-1))*\])) */
  { L0_TERMINAL_CHARACTER_CLASS_REGEXP, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    "((?:\\[(?:(?>[^\\[\\]]+)|(?-1))*\\]))",
#ifndef MARPAESLIF_NTRACE
    "[[:alnum]]","[a-z"
#else
    NULL, NULL
#endif
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_PCRE2_MODIFIERS, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    "[eijmnsxDJUuaNbcA]+",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_STRING_MODIFIERS, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    "ic?",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_RESTRICTED_ASCII_GRAPH_CHARACTERS, MARPAESLIF_TERMINAL_TYPE_REGEX, NULL,
    "[-!#$%&()*+./;<>?@\\[\\\\\\]^_`|~A-Za-z0-9][-!#$%&()*+./:;<>?@\\[\\\\\\]^_`|~A-Za-z0-9]*",
    NULL, NULL
  },
  /* --------------------------------------------------------------------------------------------------------------------------------- */
  { L0_TERMINAL_SEMICOLON, MARPAESLIF_TERMINAL_TYPE_STRING, NULL,
    "':'",
    NULL, NULL
  }
};

bootstrap_grammar_rule_t bootstrap_grammar_L0_rules[] = {
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb  actions
  */
  { L0_META_WHITESPACE,                       "whitespace",                                   MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { L0_TERMINAL_WHITESPACE                       }, -1,                        -1,      -1,             0, NULL },
  { L0_META_PERL_COMMENT,                     "perl comment",                                 MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { L0_TERMINAL_PERL_COMMENT                     }, -1,                        -1,      -1,             0, NULL },
  { L0_META_CPLUSPLUS_COMMENT,                "cplusplus comment",                            MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { L0_TERMINAL_CPLUSPLUS_COMMENT                }, -1,                        -1,      -1,             0, NULL },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb actions
  */
  { L0_META_OP_DECLARE_ANY_GRAMMAR,           "op declare any grammar",                       MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { L0_TERMINAL_OP_DECLARE_ANY_GRAMMAR           }, -1,                        -1,      -1,             0, NULL },
  { L0_META_OP_DECLARE_TOP_GRAMMAR,           "op declare top grammar",                       MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { L0_TERMINAL_OP_DECLARE_TOP_GRAMMAR           }, -1,                        -1,      -1,             0, NULL },
  { L0_META_OP_DECLARE_LEX_GRAMMAR,           "op declare lex grammar",                       MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { L0_TERMINAL_OP_DECLARE_LEX_GRAMMAR           }, -1,                        -1,      -1,             0, NULL },
  { L0_META_OP_LOOSEN,                        "op loosen",                                    MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { L0_TERMINAL_OP_LOOSEN                        }, -1,                        -1,      -1,             0, NULL },
  { L0_META_OP_EQUAL_PRIORITY,                "op equal priority",                            MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { L0_TERMINAL_OP_EQUAL_PRIORITY                }, -1,                        -1,      -1,             0, NULL },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb actions
  */
  { L0_META_TRUE,                             "true",                                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { L0_TERMINAL_TRUE                             }, -1,                        -1,      -1,             0, NULL },
  { L0_META_FALSE,                            "false",                                        MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { L0_TERMINAL_FALSE                            }, -1,                        -1,      -1,             0, NULL },
  { L0_META_WORD_CHARACTER     ,              "word character",                               MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { L0_TERMINAL_WORD_CHARACTER                   }, -1,                        -1,      -1,             0, NULL },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb actions
  */
  { L0_META_ONE_OR_MORE_WORD_CHARACTERS,      "one more word characters",                     MARPAESLIF_RULE_TYPE_SEQUENCE,    1, { L0_META_WORD_CHARACTER                       },  1,                        -1,      -1,             0, NULL },
  { L0_META_ZERO_OR_MORE_WORD_CHARACTERS,     "zero more word characters",                    MARPAESLIF_RULE_TYPE_SEQUENCE,    1, { L0_META_WORD_CHARACTER                       },  0,                        -1,      -1,             0, NULL },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb actions
  */
  { L0_META_RESTRICTED_ASCII_GRAPH_NAME,      "restricted ascii graph name",                  MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { L0_TERMINAL_RESTRICTED_ASCII_GRAPH_CHARACTERS}, -1,                        -1,      -1,             0, NULL },
  { L0_META_BARE_NAME,                        "bare name",                                    MARPAESLIF_RULE_TYPE_SEQUENCE,    1, { L0_META_WORD_CHARACTER                       },  1,                        -1,      -1,             0, NULL },
  { L0_META_STANDARD_NAME,                    "standard name",                                MARPAESLIF_RULE_TYPE_ALTERNATIVE, 2, { L0_TERMINAL_LATIN_ALPHABET_LETTER,
                                                                                                                                     L0_META_ZERO_OR_MORE_WORD_CHARACTERS         }, -1,                        -1,      -1,             0, NULL },
  { L0_META_BRACKETED_NAME,                   "bracketed name",                               MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { L0_TERMINAL_LEFT_CURLY,
                                                                                                                                     L0_META_BRACKETED_NAME_STRING,
                                                                                                                                     L0_TERMINAL_RIGHT_CURLY                      }, -1,                        -1,      -1,             0, NULL },
  { L0_META_BRACKETED_NAME_STRING,            "bracketed name string",                        MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { L0_TERMINAL_BRACKETED_NAME_STRING            }, -1,                        -1,      -1,             0, NULL },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb actions
  */
  { L0_META_QUOTED_STRING,                    "quoted string 1",                              MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { L0_TERMINAL_QUOTED_STRING                    }, -1,                        -1,      -1,             0, NULL },
  { L0_META_QUOTED_STRING,                    "quoted string 2",                              MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { L0_TERMINAL_QUOTED_STRING,
                                                                                                                                     L0_TERMINAL_SEMICOLON,
                                                                                                                                     L0_TERMINAL_STRING_MODIFIERS                 }, -1,                        -1,      -1,             0, NULL },
  { L0_META_QUOTED_NAME,                      "quoted name",                                  MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { L0_TERMINAL_QUOTED_STRING                    }, -1,                        -1,      -1,             0, NULL },
  { L0_META_CHARACTER_CLASS,                  "character class 1",                            MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { L0_TERMINAL_CHARACTER_CLASS_REGEXP           }, -1,                        -1,      -1,             0, NULL },
  { L0_META_CHARACTER_CLASS,                  "character class 2",                            MARPAESLIF_RULE_TYPE_ALTERNATIVE, 3, { L0_TERMINAL_CHARACTER_CLASS_REGEXP,
                                                                                                                                     L0_TERMINAL_SEMICOLON,
                                                                                                                                     L0_TERMINAL_PCRE2_MODIFIERS                  }, -1,                        -1,      -1,             0, NULL },
  /*
    lhsi                                      descs                                           type                          nrhsl  { rhsi }                                       }  minimumi           separatori  properb hideseparatorb actions
  */
  { L0_META_REGULAR_EXPRESSION,               "regular expression 1",                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 1, { L0_TERMINAL_REGULAR_EXPRESSION               }, -1,                        -1,      -1,             0, NULL },
  { L0_META_REGULAR_EXPRESSION,               "regular expression 2",                         MARPAESLIF_RULE_TYPE_ALTERNATIVE, 2, { L0_TERMINAL_REGULAR_EXPRESSION,
                                                                                                                                     L0_TERMINAL_PCRE2_MODIFIERS                  }, -1,                        -1,      -1,             0, NULL }
};

#endif /* MARPAESLIF_INTERNAL_ESLIF_L0_H */
