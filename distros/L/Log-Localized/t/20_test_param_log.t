#!/usr/local/bin/perl
#################################################################
#
#   $Id: 20_test_param_log.t,v 1.2 2005/11/07 16:49:10 erwan Exp $
#
#   050915 erwan Created
#   051007 erwan Fix dependencies
#   

use strict;
use warnings;
use Test::More tests => 2;
use lib ("./t/", "../lib/", "./lib/");
use Utils;

BEGIN { 
    Utils::backup_log_settings();
    use_ok('Log::Localized','log',1);
};

# level 0 is always logged, if logged is turned on
llog(0,\&Utils::mark_log_called);
is(Utils::check_log_called,1,"check that logging is on after 'log' => 1");

Utils::restore_log_settings();

