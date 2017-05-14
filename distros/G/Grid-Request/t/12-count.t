#!/usr/bin/perl

# $Id: 11-count.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use File::Basename;
use Log::Log4perl qw(:easy);
use Test::More;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");

my $req = Grid::Request::Test->get_test_request();

# Get the configured temporary directory
my $tempdir = $req->_config()->val($Grid::Request::HTC::config_section, "tempdir");

if (! defined $tempdir || ! -d $tempdir) {
    plan skip_all => 'tempdir not configured or not a directory';
} else {
    plan tests => 2;
}

my $base = basename($0);

my $output = "$tempdir/${base}.out";
my $opsys = "Linux,Solaris";


$req->command("/bin/uname");
$req->output($output);
$req->opsys($opsys);

is($req->command_count(), 1, "Correct count before new_commmand().");
$req->new_command();
is($req->command_count(), 2, "Correct count after new_commmand().");
