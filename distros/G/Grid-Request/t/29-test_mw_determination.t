#!/usr/bin/perl

# Test that the code properly detects when a Master-Worker execution
# model will be required.

# $Id: 28-test_mw_determination.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use File::Which;
use Log::Log4perl qw(:easy);
use Test::More tests => 5;
use lib ("$Bin/../lib");
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");

my $req = Grid::Request::Test->get_test_request();
my $echo = which("echo");
$req->command($echo);

my $req2 = Grid::Request::Test->get_test_request();
$req2->command($echo);
my $dir = "$Bin/test_data";
ok(-d $dir, "Test directory exists.");
$req2->add_param("mykey", $dir, "DIR");
is($req2->_com_obj->cmd_type(), "mw", "Correct command type (mw).");

my $req3 = Grid::Request::Test->get_test_request();
$req3->command($echo);
my $file = "$Bin/test_data/test_file.txt";
ok(-f $file, "Test file exists.");
$req3->add_param("mykey", $file, "FILE");
is($req3->_com_obj->cmd_type(), "mw", "Correct command type (mw).");

# Test the single argument form of add_param();
my $req4 = Grid::Request::Test->get_test_request();
$req4->command($echo);
$req4->add_param("myparam");
is($req4->_com_obj->cmd_type(), "htc", "Correct command type (htc).");
