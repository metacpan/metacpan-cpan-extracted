#!/usr/bin/perl
#
# $Id: loglocalizedownlog.pl,v 1.1 2005/09/20 18:31:36 erwan Exp $
#
# Log::Localized logs itself...
# This program displays on stdout the messages logged
# by Log::Localized upon compilation and when 'llog'
# is called.
# it won't work the first time, since 'use' is executed
# before verbosity.conf is created, hence turning off logging
# upon first run. rerun to see result.
#
# erwan lemonnier - 200509
#

use strict;
use warnings;
use lib "../lib/";
use Log::Localized;
   
`echo "Log::Localized:: = 5" >> verbosity.conf`;

llog(1,"calling llog from $0");
