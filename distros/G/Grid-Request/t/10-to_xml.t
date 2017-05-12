#!/usr/bin/perl

# $Id: 10-to_xml.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use File::Basename;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 1;
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

my $xml = $htc->to_xml();
my @lines = split(/\n/, $xml);
like($lines[0], qr/xml/, "to_xml() returned an XML document.");
