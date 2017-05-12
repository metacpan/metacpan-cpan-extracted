#!/usr/local/bin/perl
#################################################################
#
#   $Id: 21_test_param_rules.t,v 1.3 2005/11/07 16:49:10 erwan Exp $
#
#   test passing rules via import parameters
#
#   050919 erwan Created
#   051007 erwan Fix dependencies
#   

use strict;
use warnings;
use Test::More tests => 2;
use lib ("./t/", "../lib/", "./lib/");
use Utils;

BEGIN { 
    # using Log::Localized with global verbosity off but a config file
    Utils::backup_log_settings();
    my $conf = "".
	"main:: = 2\n".
	"dolly = 4\n".
	"Man::On::The::Moon  = 3\n".
	"Foo::Bar::*  = 1\n";

    use_ok('Log::Localized','log',1,'rules',$conf);
};

my $want_rules = { 
    "main::" => 2,
    "main::dolly" => 4,
    "Man::On::The::Moon" => 3,
    "Foo::Bar::*" => 1,
};
my %rules = Log::Localized::_test_verbosity_rules();
is_deeply(\%rules,$want_rules,"checking that rules were properly loaded");	  

Utils::restore_log_settings();
