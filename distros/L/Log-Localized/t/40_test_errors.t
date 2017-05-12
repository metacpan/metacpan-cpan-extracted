#!/usr/local/bin/perl
#################################################################
#
#   $Id: 40_test_errors.t,v 1.3 2005/11/07 16:49:10 erwan Exp $
#
#   050919 erwan Created
#   

use strict;
use warnings;
use Test::More tests => 10;
use lib ("./t/", "../lib/", "./lib/");
use Utils;

BEGIN { 
    Utils::backup_log_settings();

      # test value check for import parameter 'log'
      use_ok('Log::Localized');
      eval { Log::Localized::import('bla','log',-1); };
      ok($@ =~ /-1 is not a valid value/,"check 'log =>' with invalid value");
      eval { Log::Localized::import('bla','log',2); };
      ok($@ =~ /2 is not a valid value/,"check 'log =>' with invalid value");
      eval { Log::Localized::import('bla','log',3); };
      ok($@ =~ /3 is not a valid value/,"check 'log =>' with invalid value");
      
      # test value check for import parameter 'log'
      my $conf = "main:: = 3\nLog::Localized::rename = lllog";
      Log::Localized::import('bla','rules',$conf);
      eval { Log::Localized::import('bla','rules',$conf); };
#      ok($@ =~ /rules have already been loaded/,"check 'rules =>' cannot be called twice");
      
      # check invalid global verbosity
      eval { 
	  local $Log::Localized::VERBOSITY = 'abc';
	  lllog(1,"test"); 
      };
      ok($@ =~ /BUG: some code has set VERBOSITY/,"check local verbosity must be integer");
      eval { 
	  local $Log::Localized::VERBOSITY = -1;
	  lllog(1,"test"); 
      };
      ok($@ =~ /BUG: some code has set VERBOSITY/,"check local verbosity must be integer");
      
  }

# testing llog()
eval { lllog(1); };
ok($@ =~ /BUG: llog.. expects 2 arguments/,"calling llog with wrong number of arguments");
eval { lllog(1,2,3); };
ok($@ =~ /BUG: llog.. expects 2 arguments/,"calling llog with wrong number of arguments");

my @a = (1,2,3);
eval { lllog(1,\@a); };
ok($@ =~ /BUG: llog.. expects either a string or/,"calling llog without string or coderef");

eval { lllog(1,sub { return [1,2]; }); };
ok($@ =~ /BUG: llog.. was passed a function reference/,"calling llog with coderef not returning string");



Utils::restore_log_settings();
