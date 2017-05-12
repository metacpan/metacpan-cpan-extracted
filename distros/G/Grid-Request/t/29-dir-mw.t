#!/usr/bin/perl

# $Id$

use strict;
use FindBin qw($Bin);
use File::Basename;
use File::Path;
use lib ("$Bin/../lib");
use Test::More;
use Grid::Request;
use Grid::Request::Test;

my $project = Grid::Request::Test->get_test_project();

my $name = basename($0);
my $dir = "$Bin/test_data/test_dir";
my $outdir = "$Bin/test_data/test_out";

cleanup();
# If there is already something there, try removing it
if (-e $outdir) {
    plan skip_all => "Couldn't create a clean test output area.";
} else {
    plan tests => 5;
}

# Create the directories
create_dirs($dir, $outdir);

ok(-d $dir, "Test directory exists.");
ok(-d $outdir, "Test output directory exists.");

my $htc = Grid::Request->new(project => $project);
$htc->command("/bin/echo");
$htc->add_param('$(Name)', $dir, "DIR");
$htc->output($outdir. '/$(Index).out');
$htc->error($outdir. '/$(Index).err');

my @ids = $htc->submit_and_wait();

opendir(DIR, $outdir);
my @files = grep { !/^\./ } readdir DIR;
my @out = grep { /.*\.out$/ } @files;
my @err = grep { /.*\.err$/ } @files;
closedir DIR;

ok(scalar(@ids) > 0, "Retrieved a set of grid IDs.");
ok(scalar(@out) > 0, "Detected output files.");
ok(scalar(@err) > 0, "Detected error files.");

cleanup();

#############################################################################

sub create_dirs {
    my @dirs = @_;
    foreach my $d (@dirs) {
        mkdir $d;
        chmod 0777;
    }
}

sub cleanup {
    eval {
        remove($outdir);
    };
}

sub remove {
    my $item = shift;
    if (-f $item) {
        unlink $item;
    } elsif (-d $item) {
        rmtree($item, 0, 1);
    }
}
