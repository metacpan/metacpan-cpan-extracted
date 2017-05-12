#!/usr/bin/perl
#
# $Id: localverbosity.pl,v 1.2 2005/09/20 06:59:41 erwan Exp $
#
# an example of how to alter verbosity from within
# the code, in a local way.
#
# erwan lemonnier - 200509
#

use strict;
use warnings;
use lib "../lib/";
# 'log => 1' required since we want to log but neither rules file nor global vebrosity exists
use Log::Localized log => 1;

# by default $Log::Localized::VERBOSITY = 0

{
    # override global verbosity, locally
    local $Log::Localized::VERBOSITY = 2;
    llog(2,"this will be logged");
}

llog(2,"but this won't");
