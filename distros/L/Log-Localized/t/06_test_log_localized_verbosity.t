#!/usr/local/bin/perl
#################################################################
#
#   $Id: 06_test_log_localized_verbosity.t,v 1.3 2005/11/07 16:49:09 erwan Exp $
#
#   test local verbosity setting via Log::Localized::VERBOSITY
#
#   050914 erwan Created
#   051007 erwan Fix dependencies
#   

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 12;
use lib ("./t/", "../lib/", "./lib/");
use Utils;

BEGIN { 
    # using Log::Localized with global verbosity off, no config file, but log on;
    Utils::backup_log_settings();
    use_ok('Log::Localized','log',1);
    # now: logging is on, but no verbosity is defined anywhere
};

use Foo;
use Foo::Bar;

my $want_rules = {};
my %rules = Log::Localized::_test_verbosity_rules();
is_deeply(\%rules,$want_rules,"checking verbosity rules");

#diag("check that verbosity if off"); 
llog(0,\&Utils::mark_log_called);
is(Utils::check_log_called,1,"main::, verbosity 0");
llog(1,\&Utils::mark_log_called);
is(Utils::check_log_called,0,"main::, verbosity 1");

{
    #diag("set verbosity locally in block"); 
    local $Log::Localized::VERBOSITY = 3;

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
}

#diag("check that verbosity is back to normal after block"); 
llog(0,\&Utils::mark_log_called);
is(Utils::check_log_called,1,"main::, verbosity 0");
llog(1,\&Utils::mark_log_called);
is(Utils::check_log_called,0,"main::, verbosity 1");

Utils::restore_log_settings();
