#!/usr/bin/perl

# $Id: 28-test_mw_determination.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Test::More tests => 6;
use Grid::Request;
use Grid::Request::Test;

my $project = Grid::Request::Test->get_test_project();

my $htc = Grid::Request->new(project => $project);
$htc->command("/bin/echo");

my $htc2 = Grid::Request->new(project => $project);
$htc2->command("/bin/echo");
my $dir = "$Bin/test_data";
ok(-d $dir, "Test directory exists.");
$htc2->add_param("mykey", $dir, "DIR");
is($htc2->_com_obj->cmd_type(), "mw", "Correct command type (mw).");


my $htc3 = Grid::Request->new(project => $project);
$htc3->command("/bin/echo");
my $file = "$Bin/test_data/test_file.txt";
ok(-f $file, "Test file exists.");
$htc3->add_param("mykey", $file, "FILE");
is($htc3->_com_obj->cmd_type(), "mw", "Correct command type (mw).");

# Test the 2 argument form of add_param();
my $htc4 = Grid::Request->new(project => $project);
$htc4->command("/bin/echo");
$htc4->add_param("mykey", "value");
is($htc4->_com_obj->cmd_type(), "htc", "Correct command type (htc).");

# Test the single argument form of add_param();
my $htc5 = Grid::Request->new(project => $project);
$htc5->command("/bin/echo");
$htc5->add_param("myparam");
is($htc5->_com_obj->cmd_type(), "htc", "Correct command type (htc).");
