###
### $Release: 0.0100 $
### $Copyright: copyright(c) 2009-2011 kuwata-lab.com all rights reserved. $
### $License: MIT License $
###

use strict;
use warnings;


package Kook::Config;

our $VERBOSE             = 1;
our $FORCED              = 0;
our $NOEXEC              = 0;
our $DEBUG_LEVEL         = 0;
our $COMMAND_PROMPT      = '$ ';
our $MESSAGE_PROMPT      = '### ';
our $WARNING_PROMPT      = '*** WARNING: ';
our $DEBUG_PROMPT        = '*** debug: ';
our $COMPARE_CONTENTS    = 1;
our $CMDOPT_PARSER_CLASS = 'Kook::Util::CommandOptionParser';
our $PROPERTIES_FILENAME = 'Properties.pl';
our $COOKBOOK_FILENAME   = 'Kookbook.pl';
#our $STDOUT              = STDOUT;
#our $STDERR              = STDERR;
our $RECIPE_LIST_FORMAT  = "  %-20s : %s\n";
our $RECIPE_OPTS_FORMAT  = "    %-20s   %s\n";
our $SUBCOMMANDS_FORMAT  = "  %-20s : %s\n";
our $OPTION_HELP_FORMAT  = "  %-15s : %s\n";


1;
