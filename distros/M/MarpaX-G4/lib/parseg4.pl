#!/usr/bin/perl -w
# #################################################################################### #
# Program   parseg4g                                                                   #
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
    grammar Exp;

    eval        :    additionExp
                ;
    additionExp :    multiplyExp ( '+' multiplyExp | '-' multiplyExp )*
                ;
    multiplyExp :    atomExp ( '*' atomExp | '/' atomExp )*
                ;
    atomExp     :    Number
                |    '(' additionExp ')'
                ;
    Number      :    ('0'..'9')+ ('.' ('0'..'9')+)?
                ;
    /* We're going to ignore all white space characters */
    WS          :   (' ' | '\t' | '\r'| '\n')+ ->HIDDEN
                ;
INPUT

my $translator = MarpaX::G4->new();
$translator->translatestring( $grammartext, $options );

exit 0
