#!perl
# Copyright 2022 Axel Zuber
# This file is part of MarpaX::G4.  MarpaX::G4 is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# MarpaX::G4 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with MarpaX::G4.  If not, see
# http://www.gnu.org/licenses/.

use warnings;
use strict;

use File::Temp;
use Data::Dump;
use Marpa::R2;

use Test::More tests => 3;

## ------------------------------------------------------------------------------------------------------------------
#   test case 1 : verify MarpaX::G4 is installed
## ------------------------------------------------------------------------------------------------------------------

my $EVAL_ERROR;

if (not eval { require MarpaX::G4; 1; })
{
    Test::More::diag($EVAL_ERROR);
    Test::More::BAIL_OUT('Could not load MarpaX::G4');
}

my $marpa_version_ok = defined $MarpaX::G4::VERSION;
my $marpa_version_desc =
    $marpa_version_ok
        ? 'MarpaX::G4 version is ' . $MarpaX::G4::VERSION
        : 'No MarpaX::G4::VERSION';
Test::More::ok( $marpa_version_ok, $marpa_version_desc );

## ------------------------------------------------------------------------------------------------------------------
#   test case 2 : translate antlr4 json grammar
## ------------------------------------------------------------------------------------------------------------------

my $grammartext =<<'INPUT';
grammar JSON;
json                   : value;
obj                    : '{' pair (',' pair)* '}'
                       | '{' '}' ;
pair                   : STRING ':' value;
arr                    : '[' value (',' value)* ']'
                       | '[' ']';
value                  : STRING
                       | NUMBER
                       | obj
                       | arr
                       | 'true'
                       | 'false'
                       | 'null';
lexer grammar JSON;
STRING                 : '"' (ESC | SAFECODEPOINT)* '"';
NUMBER                 : '-'? INT ('.' [0-9] +)? EXP?;
fragment ESC           : '\\' (["\\/bfnrt] | UNICODE);
fragment UNICODE       : 'u' HEX HEX HEX HEX;
fragment HEX           : [0-9a-fA-F];
fragment SAFECODEPOINT : ~ ["\\\u0000-\u001F];
fragment INT           : '0' | [1-9] [0-9]*;
fragment EXP           : [Ee] [+\-]? INT;
WS                     : [ \t\n\r] + -> skip;
INPUT

my $expected_output =<< 'EXPECTED_OUTPUT';
lexeme default = latm => 1

:start         ::= json

# ---
# Discard rule from redirect options :
:discard       ~   <discarded redirects>
<discarded redirects> ~   WS
# ---
json           ::= value

obj            ::= '{' pair obj_002 '}'
               |   '{' '}'
obj_001        ::= ',' pair
obj_002        ::= obj_001*

pair           ::= STRING ':' value

arr            ::= '[' value arr_002 ']'
               |   '[' ']'
arr_001        ::= ',' value
arr_002        ::= arr_001*

value          ::= STRING
               |   NUMBER
               |   obj
               |   arr
               |   'true':i
               |   'false':i
               |   'null':i

STRING         ~   '"' STRING_002 '"'
STRING_001     ~   ESC
               |   SAFECODEPOINT
STRING_002     ~   STRING_001*

NUMBER         ~   opt_NUMBER_001 INT opt_NUMBER_004 opt_NUMBER_005
opt_NUMBER_001 ~
opt_NUMBER_001 ~   '-'
NUMBER_002     ~   [0-9]+
NUMBER_003     ~   '.' NUMBER_002
opt_NUMBER_004 ~
opt_NUMBER_004 ~   NUMBER_003
opt_NUMBER_005 ~
opt_NUMBER_005 ~   EXP

ESC            ~   ESC_002
ESC_001        ~   [\\/bfnrt]:ic
               |   UNICODE
ESC_002        ~   '\\' ESC_001

UNICODE        ~   UNICODE_001
UNICODE_001    ~   'u':i HEX HEX HEX HEX

HEX            ~   [0-9a-f]:ic
SAFECODEPOINT  ~   [^"\\\x00-\x1F]

INT            ~   INT_002
INT_001        ~   [0-9]*
INT_002        ~   '0'
               |   [1-9] INT_001

EXP            ~   EXP_002
opt_EXP_001    ~
opt_EXP_001    ~   [+\-]
EXP_002        ~   [E]:ic opt_EXP_001 INT

WS             ~   [ \t\n\r]+
EXPECTED_OUTPUT

sub canonical_text
{
    my ($string) = @_;
    $string =~ s/[\r\n]+$//g;
    $string =~ s/[\s]+/ /g;
    return $string;
}

my $tmp = File::Temp->new();

my $translator = MarpaX::G4->new();
$translator->translatestring( $grammartext, { f => 1, k => 1, u => 1, o => $tmp->filename } );

my $actual_output = do { local $/; <$tmp> };

my $jsondsl      = $actual_output;

$actual_output   = canonical_text($actual_output);
$expected_output = canonical_text($expected_output);

Test::More::ok( $actual_output eq $expected_output, "\n===\n=== expected Marpa::R2 json grammar\n===\n${expected_output}\n===\n=== does not match actual output\n===\n${actual_output}\n===\n" );

## ------------------------------------------------------------------------------------------------------------------
#   test case 3 : apply generated json grammar to json input
## ------------------------------------------------------------------------------------------------------------------

if (not eval { require Marpa::R2; 1; })
{
    Test::More::diag($EVAL_ERROR);
    Test::More::BAIL_OUT('Could not load Marpa::R2');
}

my $grammar = Marpa::R2::Scanless::G->new({
    source          => \$jsondsl,
    default_action  => '[name, values]',
});
my $parser  = Marpa::R2::Scanless::R->new({ grammar => $grammar });

my $input = <<'__INPUT__';
{
    "glossary": {
        "title": "example glossary",
		"GlossDiv": {
            "title": "S",
			"GlossList": {
                "GlossEntry": {
                    "ID": "SGML",
					"SortAs": "SGML",
					"GlossTerm": "Standard Generalized Markup Language",
					"Acronym": "SGML",
					"Abbrev": "ISO 8879:1986",
					"GlossDef": {
                        "para": "A meta-markup language, used to create markup languages such as DocBook.",
						"GlossSeeAlso": ["GML", "XML"]
                    },
					"GlossSee": "markup"
                }
            }
        }
    }
}
__INPUT__

$parser->read(\$input);

my $value_ref   = $parser->value();

$actual_output = Data::Dump::dump($$value_ref);

$expected_output =<< 'EXPECTED_OUTPUT';
do {
  my $a = [
    "json",
    [
      "value",
      [
        "obj",
        "{",
        [
          "pair",
          "\"glossary\"",
          ":",
          [
            'fix',
            [
              'fix',
              "{",
              ['fix', "\"title\"", ":", ["value", "\"example glossary\""]],
              [
                "obj_002",
                [
                  "obj_001",
                  ",",
                  [
                    'fix',
                    "\"GlossDiv\"",
                    ":",
                    [
                      'fix',
                      [
                        'fix',
                        "{",
                        ['fix', "\"title\"", ":", ['fix', "\"S\""]],
                        [
                          'fix',
                          [
                            'fix',
                            ",",
                            [
                              'fix',
                              "\"GlossList\"",
                              ":",
                              [
                                'fix',
                                [
                                  'fix',
                                  "{",
                                  [
                                    'fix',
                                    "\"GlossEntry\"",
                                    ":",
                                    [
                                      'fix',
                                      [
                                        'fix',
                                        "{",
                                        ['fix', "\"ID\"", ":", ['fix', "\"SGML\""]],
                                        [
                                          'fix',
                                          ['fix', ",", ['fix', "\"SortAs\"", ":", ['fix', "\"SGML\""]]],
                                          [
                                            'fix',
                                            ",",
                                            [
                                              'fix',
                                              "\"GlossTerm\"",
                                              ":",
                                              ['fix', "\"Standard Generalized Markup Language\""],
                                            ],
                                          ],
                                          ['fix', ",", ['fix', "\"Acronym\"", ":", ['fix', "\"SGML\""]]],
                                          [
                                            'fix',
                                            ",",
                                            ['fix', "\"Abbrev\"", ":", ['fix', "\"ISO 8879:1986\""]],
                                          ],
                                          [
                                            'fix',
                                            ",",
                                            [
                                              'fix',
                                              "\"GlossDef\"",
                                              ":",
                                              [
                                                'fix',
                                                [
                                                  'fix',
                                                  "{",
                                                  [
                                                    'fix',
                                                    "\"para\"",
                                                    ":",
                                                    [
                                                      'fix',
                                                      "\"A meta-markup language, used to create markup languages such as DocBook.\"",
                                                    ],
                                                  ],
                                                  [
                                                    'fix',
                                                    [
                                                      'fix',
                                                      ",",
                                                      [
                                                        'fix',
                                                        "\"GlossSeeAlso\"",
                                                        ":",
                                                        [
                                                          "value",
                                                          [
                                                            "arr",
                                                            "[",
                                                            ['fix', "\"GML\""],
                                                            ["arr_002", ["arr_001", ",", ['fix', "\"XML\""]]],
                                                            "]",
                                                          ],
                                                        ],
                                                      ],
                                                    ],
                                                  ],
                                                  "}",
                                                ],
                                              ],
                                            ],
                                          ],
                                          [
                                            'fix',
                                            ",",
                                            ['fix', "\"GlossSee\"", ":", ['fix', "\"markup\""]],
                                          ],
                                        ],
                                        "}",
                                      ],
                                    ],
                                  ],
                                  ['fix'],
                                  "}",
                                ],
                              ],
                            ],
                          ],
                        ],
                        "}",
                      ],
                    ],
                  ],
                ],
              ],
              "}",
            ],
          ],
        ],
        ['fix'],
        "}",
      ],
    ],
  ];
  $a->[1][1][2][3][0] = $a->[1][0];
  $a->[1][1][2][3][1][0] = $a->[1][1][0];
  $a->[1][1][2][3][1][2][0] = $a->[1][1][2][0];
  $a->[1][1][2][3][1][3][1][2][0] = $a->[1][1][2][0];
  $a->[1][1][2][3][1][3][1][2][3][0] = $a->[1][0];
  $a->[1][1][2][3][1][3][1][2][3][1][0] = $a->[1][1][0];
  $a->[1][1][2][3][1][3][1][2][3][1][2][0] = $a->[1][1][2][0];
  $a->[1][1][2][3][1][3][1][2][3][1][2][3][0] = $a->[1][1][2][3][1][2][3][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][0] = $a->[1][1][2][3][1][3][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][0] = $a->[1][1][2][3][1][3][1][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][0] = $a->[1][1][2][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][0] = $a->[1][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][0] = $a->[1][1][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][0] = $a->[1][1][2][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][0] = $a->[1][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][0] = $a->[1][1][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][2][0] = $a->[1][1][2][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][2][3][0] = $a->[1][1][2][3][1][2][3][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][0] = $a->[1][1][2][3][1][3][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][1][0] = $a->[1][1][2][3][1][3][1][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][1][2][0] = $a->[1][1][2][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][1][2][3][0] = $a->[1][1][2][3][1][2][3][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][2][0] = $a->[1][1][2][3][1][3][1][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][2][2][0] = $a->[1][1][2][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][2][2][3][0] = $a->[1][1][2][3][1][2][3][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][3][0] = $a->[1][1][2][3][1][3][1][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][3][2][0] = $a->[1][1][2][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][3][2][3][0] = $a->[1][1][2][3][1][2][3][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][4][0] = $a->[1][1][2][3][1][3][1][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][4][2][0] = $a->[1][1][2][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][4][2][3][0] = $a->[1][1][2][3][1][2][3][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][5][0] = $a->[1][1][2][3][1][3][1][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][5][2][0] = $a->[1][1][2][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][5][2][3][0] = $a->[1][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][5][2][3][1][0] = $a->[1][1][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][5][2][3][1][2][0] = $a->[1][1][2][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][5][2][3][1][2][3][0] = $a->[1][1][2][3][1][2][3][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][5][2][3][1][3][0] = $a->[1][1][2][3][1][3][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][5][2][3][1][3][1][0] = $a->[1][1][2][3][1][3][1][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][5][2][3][1][3][1][2][0] = $a->[1][1][2][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][5][2][3][1][3][1][2][3][1][2][0] = $a->[1][1][2][3][1][2][3][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][5][2][3][1][3][1][2][3][1][3][1][2][0] = $a->[1][1][2][3][1][2][3][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][6][0] = $a->[1][1][2][3][1][3][1][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][6][2][0] = $a->[1][1][2][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][2][3][1][3][6][2][3][0] = $a->[1][1][2][3][1][2][3][0];
  $a->[1][1][2][3][1][3][1][2][3][1][3][1][2][3][1][3][0] = $a->[1][1][2][3][1][3][0];
  $a->[1][1][3][0] = $a->[1][1][2][3][1][3][0];
  $a;
}
EXPECTED_OUTPUT

$actual_output   = canonical_text($actual_output);
$expected_output = canonical_text($expected_output);

Test::More::ok( $actual_output eq $expected_output, "\n===\n=== expected json parse tree\n===\n${expected_output}\n===\n=== does not match actual output\n===\n${actual_output}\n===\n" );

# vim: expandtab shiftwidth=4:
