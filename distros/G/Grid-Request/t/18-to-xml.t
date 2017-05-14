#!/usr/bin/perl

# Test script for verifying the to_xml() method.

# $Id: 10-to_xml.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use File::Basename;
use File::Which;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More;
use Grid::Request;
use Grid::Request::Test;

my $req = Grid::Request::Test->get_test_request();

# Get the configured temporary directory
my $tempdir = $req->_config()->val($Grid::Request::HTC::config_section, "tempdir");

if (! defined $tempdir || ! -d $tempdir) {
    plan skip_all => 'tempdir not configured or not a directory.';
} else {
    plan tests => 1;
}

Log::Log4perl->init("$Bin/testlogger.conf");

my $base = basename($0);

my $output = "$tempdir/${base}.out";
my $opsys = "Linux,Solaris";

$req->command(which("uname"));
$req->output($output);
$req->opsys($opsys);

my $xml = $req->to_xml();
my @lines = split(/\n/, $xml);
if (scalar(@lines)) {
    like($lines[0], qr/xml/, "to_xml() returned an XML document.");
} else {
    fail("No output detected from to_xml().");
}
