#!/usr/local/bin/perl
#################################################################
#
#   $Id: 01_test_logging_off.t,v 1.4 2005/11/07 16:49:09 erwan Exp $
#
#   050912 erwan Created
#   051007 erwan Fix dependencies
#   

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 16;
use lib ("./t/", "../lib/", "./lib/");
use Utils;

BEGIN { 
    # using Log::Localized with no config file but global verbosity=2
    Utils::backup_log_settings();
    use_ok('Log::Localized');
};

use Foo;
use Foo::Bar;

my $want_rules = {};
my %rules = Log::Localized::_test_verbosity_rules();
is_deeply(\%rules,$want_rules,"checking verbosity rules");

sub test1 {
    my $level = shift;
    llog($level,\&Utils::mark_log_called);
}

sub test2 {
    my $level = shift;
    llog($level,\&Utils::mark_log_called);
}

#diag(" checking that llog() logs everywhere with verbosity 2");

# local
llog(0,\&Utils::mark_log_called);
is(Utils::check_log_called,0,"main::, verbosity 0");
llog(1,\&Utils::mark_log_called);
is(Utils::check_log_called,0,"main::, verbosity 1");

test1(0);
is(Utils::check_log_called,0,"main::test1, verbosity 0");
test1(1);
is(Utils::check_log_called,0,"main::test1, verbosity 1");

test2(0);
is(Utils::check_log_called,0,"main::test2, verbosity 0");
test2(1);
is(Utils::check_log_called,0,"main::test2, verbosity 1");

# Foo
&Foo::test1(0);
is(Utils::check_log_called,0,"Foo::test1, verbosity 0");
&Foo::test1(1);
is(Utils::check_log_called,0,"Foo::test1, verbosity 1");

&Foo::test2(0);
is(Utils::check_log_called,0,"Foo::test2, verbosity 0");
&Foo::test2(1);
is(Utils::check_log_called,0,"Foo::test2, verbosity 1");

# Foo::Bar
&Foo::Bar::test1(0);
is(Utils::check_log_called,0,"Foo::Bar::test1, verbosity 0");
&Foo::Bar::test1(1);
is(Utils::check_log_called,0,"Foo::Bar::test1, verbosity 1");

&Foo::Bar::test2(0);
is(Utils::check_log_called,0,"Foo::Bar::test2, verbosity 0");
&Foo::Bar::test2(1);
is(Utils::check_log_called,0,"Foo::Bar::test2, verbosity 1");

Utils::restore_log_settings();

