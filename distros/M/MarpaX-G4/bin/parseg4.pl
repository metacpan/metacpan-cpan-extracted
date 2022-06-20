#!/usr/bin/perl -w
# #################################################################################### #
# Program   parseg4                                                                    #
#                                                                                      #
# Author    Axel Zuber                                                                 #
# Created   29.05.2022                                                                 #
#                                                                                      #
# Description   read an ANTLR4 grammar from a here document,                           #
#               translate it to Marpa syntax and write it to output                    #
#                                                                                      #
# ------------------------------------------------------------------------------------ #
#                                                                                      #
# Input     ANTLR4 grammar                                                             #
#                                                                                      #
# ------------------------------------------------------------------------------------ #
#                                                                                      #
# Output    Marpa grammar file                                                         #
#                                                                                      #
# ------------------------------------------------------------------------------------ #
#                                                                                      #
# Exit code                                                                            #
#        0 : Successful                                                                #
#        4 : Warnings                                                                  #
#        8 : Errors                                                                    #
#                                                                                      #
# ------------------------------------------------------------------------------------ #
#                                                                                      #
# History                                                                              #
# Ver   Date        Name        Description                                            #
# 0.9   29.05.2022  A. Zuber    Initial version                                        #
#                                                                                      #
# #################################################################################### #

use strict;
use warnings FATAL => 'all';

use File::Basename;
use Getopt::Std;
use MarpaX::G4;

use vars qw($scriptName);

# ------------------------------------------------------------------------------------ #
# MAIN                                                                                 #
# ------------------------------------------------------------------------------------ #

BEGIN { $scriptName = basename($0); }

my $options = {};

die 'Invalid option(s) given'            if !getopts( $MarpaX::G4::optstr, $options );
MarpaX::G4::printHelpScreen($scriptName) if exists $options->{h};

my $grammartext =<<'INPUT';
/** Taken from "The Definitive ANTLR 4 Reference" by Terence Parr */

// Derived from http://json.org
grammar JSON;

json
   : value
   ;

obj
   : '{' pair (',' pair)* '}'
   | '{' '}'
   ;

pair
   : STRING ':' value
   ;

arr
   : '[' value (',' value)* ']'
   | '[' ']'
   ;

value
   : STRING
   | NUMBER
   | obj
   | arr
   | 'true'
   | 'false'
   | 'null'
   ;

lexer grammar JSON;

STRING
   : '"' (ESC | SAFECODEPOINT)* '"'
   ;


fragment ESC
   : '\\' (["\\/bfnrt] | UNICODE)
   ;


fragment UNICODE
   : 'u' HEX HEX HEX HEX
   ;


fragment HEX
   : [0-9a-fA-F]
   ;


fragment SAFECODEPOINT
   : ~ ["\\\u0000-\u001F]
   ;


NUMBER
   : '-'? INT ('.' [0-9] +)? EXP?
   ;


fragment INT
   : '0' | [1-9] [0-9]*
   ;

// no leading zeros

fragment EXP
   : [Ee] [+\-]? INT
   ;

// \- since - means "range" inside [...]

WS
   : [ \t\n\r] + -> skip
   ;
INPUT

my $translator = MarpaX::G4->new();
$translator->translatestring( $grammartext, $options );

exit 0
