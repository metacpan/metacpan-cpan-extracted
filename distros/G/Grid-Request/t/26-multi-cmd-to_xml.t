#!/usr/bin/perl

# Test the behavior of multiple commands when ouputting their XML.

# $Id: 25-multi-cmd-to_xml.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use File::Basename;
use File::Which;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 2;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");

my $req = Grid::Request::Test->get_test_request();

# Get the configured temporary directory.
my $tempdir = $req->_config()->val($Grid::Request::HTC::config_section, "tempdir");

my $base = basename($0);

my $output = "$tempdir/${base}.out";
my $opsys = "Linux,Solaris";

$req->command(which("echo"));
$req->output($output);
$req->opsys($opsys);

$req->new_command();

my $xml = $req->to_xml();
my @lines = split(/\n/, $xml);
like($lines[0], qr/xml/, "to_xml() returned an XML document.");

my @command_ends = grep { /<\/command>/ } @lines;
is(scalar(@command_ends), 2, "Correct number of command elements.");
