#!/usr/bin/perl

# $Id: 11-count.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use File::Basename;
use Log::Log4perl qw(:easy);
use Test::More tests => 2;
use Grid::Request;
use Grid::Request::Test;

my $project = Grid::Request::Test->get_test_project();


Log::Log4perl->init("$Bin/testlogger.conf");

my $base = basename($0);

my $output = "/usr/local/scratch/${base}.out";
my $opsys = "Linux,Solaris";

my $htc = Grid::Request->new(project => $project );
$htc->command("/bin/uname");
$htc->output($output);
$htc->opsys($opsys);

is($htc->command_count(), 1, "Correct count before new_commmand().");
$htc->new_command();
is($htc->command_count(), 2, "Correct count after new_commmand().");
