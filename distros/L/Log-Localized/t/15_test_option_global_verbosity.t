#!/usr/local/bin/perl
#################################################################
#
#   $Id: 15_test_option_global_verbosity.t,v 1.3 2005/11/07 16:49:09 erwan Exp $
#
#   050919 erwan Created
#   051007 erwan Fix dependencies
#   

use strict;
use warnings;
use Test::More tests => 14;
use lib ("./t/", "../lib/", "./lib/");

use Utils;

BEGIN { 
    Utils::backup_log_settings();

    # change the name of the global verbosity environment variable
    use_ok('Log::Localized','rules',"Log::Localized::global_verbosity = TEST_ENV1");

    $ENV{TEST_ENV1} = 3;
}      

# must be loaded after use_ok
use Foo;
use Foo::Bar;

my $want_rules = {};
my %rules = Log::Localized::_test_verbosity_rules();
is_deeply(\%rules,$want_rules,"checking that rules were properly loaded");	  

# local
llog(0,\&Utils::mark_log_called);
is(Utils::check_log_called,1,"main::, verbosity 0");
llog(1,\&Utils::mark_log_called);
is(Utils::check_log_called,1,"main::, verbosity 1");
llog(2,\&Utils::mark_log_called);
is(Utils::check_log_called,1,"main::, verbosity 2");
llog(3,\&Utils::mark_log_called);
is(Utils::check_log_called,1,"main::, verbosity 3");
llog(4,\&Utils::mark_log_called);
is(Utils::check_log_called,0,"main::, verbosity 4");
llog(5,\&Utils::mark_log_called);
is(Utils::check_log_called,0,"main::, verbosity 5");

# Foo::Bar
&Foo::Bar::test1(0);
is(Utils::check_log_called,1,"Foo::Bar::test1, verbosity 0");
&Foo::Bar::test1(1);
is(Utils::check_log_called,1,"Foo::Bar::test1, verbosity 1");
&Foo::Bar::test1(2);
is(Utils::check_log_called,1,"Foo::Bar::test1, verbosity 2");
&Foo::Bar::test1(3);
is(Utils::check_log_called,1,"Foo::Bar::test1, verbosity 3");
&Foo::Bar::test1(4);
is(Utils::check_log_called,0,"Foo::Bar::test1, verbosity 4");
&Foo::Bar::test1(5);
is(Utils::check_log_called,0,"Foo::Bar::test1, verbosity 5");


Utils::restore_log_settings();
