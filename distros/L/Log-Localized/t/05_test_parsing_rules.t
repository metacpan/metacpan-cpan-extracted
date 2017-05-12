#!/usr/local/bin/perl
#################################################################
#
#   $Id: 05_test_parsing_rules.t,v 1.2 2005/11/07 16:49:09 erwan Exp $
#
#   test rules when rules defined in blocks, per program
#
#   050919 erwan Created
#   051007 erwan Fix dependencies
#   

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 2;
use lib ("./t/", "../lib/", "./lib/");
use Utils;

BEGIN { 
    # using Log::Localized with global verbosity off but config file
    Utils::backup_log_settings();
    my $conf = "".
	"main::* = 1\n".
	" Foo:: = 1\n".
	"Bar::*   = 5\n".
	"\n".
	"# just a comment\n".
	"     # just another comment\n".
	"[05_test_parsing_rules.t]\n".
	"main::test2 =   4\n".
	"  Foo::   =  3  \n".
	"Bar:: = 4\n".
	"Foo::Bar::test1 = 1    \n";
    Utils::write_config($conf);
    use_ok('Log::Localized');
};

my $want_rules = {
    "main::*" => 1,
    "Foo::" => 3,
    "Bar::" => 4,
    "Bar::*" => 5,
    "main::test2" => 4,
    "Foo::Bar::test1" => 1,
};

my %rules = Log::Localized::_test_verbosity_rules();

is_deeply(\%rules,$want_rules,"checking that rules were properly loaded");	  

Utils::remove_config();
Utils::restore_log_settings();
