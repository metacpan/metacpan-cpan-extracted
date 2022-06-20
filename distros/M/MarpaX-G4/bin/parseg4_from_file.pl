#!/usr/bin/perl -w
# #################################################################################### #
# Program   parseg4grammarfromfile                                                     #
#                                                                                      #
# Author    Axel Zuber                                                                 #
# Created   29.05.2022                                                                 #
#                                                                                      #
# Description   read an ANTLR4 grammar file, convert it to Marpa syntax                #
#               and write it to the output file                                        #
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

package MAIN;

use strict;
use warnings;
use open ":std", ":encoding(UTF-8)";

use lib 'lib';
use Data::Dumper;
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

## -----------------------------------------------------------------------
#  process all input files
#  (if more than 1 file is specified, they are usually Lexer and Parser)
## -----------------------------------------------------------------------

my $translator = MarpaX::G4->new();
$translator->translatefiles( \@ARGV, $options );

exit 0
