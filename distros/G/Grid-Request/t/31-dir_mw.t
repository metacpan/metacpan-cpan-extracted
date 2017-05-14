#!/usr/bin/perl

# $Id$

use strict;
use FindBin qw($Bin);
use File::Basename;
use File::Path;
use File::Which;
use File::Temp qw(tempdir);
use Log::Log4perl qw(:easy);
use Test::More;
use lib ("$Bin/../lib");
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");

my $name = basename($0);
my $dir = "$Bin/test_data/test_dir";

my $req = Grid::Request::Test->get_test_request();

# Get the configured temporary directory
my $tempdir = $req->_config()->val($Grid::Request::HTC::config_section, "tempdir");

if (! defined $tempdir || ! -d $tempdir) {
    plan skip_all => 'tempdir not configured or not a directory';
} else {
    plan tests => 5;
}

my $outdir = tempdir ( DIR => $tempdir );

ok(-d $dir, "Test directory exists.");
ok(-d $outdir, "Test output directory exists.");

$req->command(which("echo"));
$req->add_param('$(Name)', $dir, "DIR");
$req->output($outdir. '/$(Index).out');
$req->error($outdir. '/$(Index).err');

my @ids = $req->submit_and_wait();

opendir(DIR, $outdir);
my @files = grep { !/^\./ } readdir DIR;
my @out = grep { /.*\.out$/ } @files;
my @err = grep { /.*\.err$/ } @files;
closedir DIR;

ok(scalar(@ids) > 0, "Retrieved a set of grid IDs.");
ok(scalar(@out) > 0, "Detected output files.");
ok(scalar(@err) > 0, "Detected error files.");

remove($outdir);

#############################################################################

sub remove {
    my $item = shift;
    if (-f $item) {
        unlink $item;
    } elsif (-d $item) {
        rmtree($item, 0, 1);
    }
}
