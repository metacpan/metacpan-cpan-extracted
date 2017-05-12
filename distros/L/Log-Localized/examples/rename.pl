#!/usr/bin/perl
#
# $Id: rename.pl,v 1.2 2005/09/20 06:59:41 erwan Exp $
#
# an example of how to export llog() under
# a different name. you may want to do that
# for example if you have a pre-existing
# logging mechanism in your program via a 
# function called 'my_log' that has typically
# the same signature as llog but which does not
# provide log localization, and you want
# to painlessly add localization to your code.
# Well, just silently replace 'my_log' with 'llog'...
#
# erwan lemonnier - 200509
#

use strict;
use warnings;
use lib "../lib/";
use Log::Localized rules => "Log::Localized::rename = my_log";

my_log(0,"logging as usual... but with localization!");

