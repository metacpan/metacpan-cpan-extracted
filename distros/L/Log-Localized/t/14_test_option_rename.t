#!/usr/local/bin/perl
#################################################################
#
#   $Id: 14_test_option_rename.t,v 1.3 2005/11/07 16:49:09 erwan Exp $
#
#   050919 erwan Created
#   051007 erwan Fix dependencies
#   

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 4;
use lib ("./t/", "../lib/", "./lib/");
use Utils;

BEGIN { 
    Utils::backup_log_settings();
      
      use_ok('Log::Localized','rules',"main:: = 1\nLog::Localized::rename = mylog");
      Utils::set_global_verbosity(1);
}      

my $want_rules = { "main::" => 1 };
my %rules = Log::Localized::_test_verbosity_rules();
is_deeply(\%rules,$want_rules,"checking that rules were properly loaded");	  

mylog(1,\&Utils::mark_log_called);
is(Utils::check_log_called,1,"testing renamed llog");
mylog(2,\&Utils::mark_log_called);
is(Utils::check_log_called,0,"testing renamed llog");

Utils::restore_log_settings();
