#!/usr/bin/perl

# $Id: 07-single-opsys.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use File::Basename;
use File::Which;
use Log::Log4perl;
use Test::More;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");

my $req = Grid::Request::Test::get_test_request();

# Get the configured temporary directory
my $tempdir = $req->_config()->val($Grid::Request::HTC::config_section, "tempdir");
    
if (! defined $tempdir || ! -d $tempdir) {
    plan skip_all => 'tempdir not configured or not a directory.';
} else {
    plan tests => 7;
}

my $name = basename($0);
my $output = "$tempdir/${name}.out";
my $opsys = "Linux";

cleanup();
ok(! -e $output, "Output file does not exist.");

$req->command(which("uname"));
$req->add_param("-a");
$req->output($output);
$req->opsys($opsys);

is($req->output(), $output, "output() got same value that was set.");
is($req->opsys(), $opsys, "opsys() got same value that was set.");

# Submit the job
my @ids;
eval {
    @ids = $req->submit_serially();
};
ok(! $@, "Submission did not trigger an exception.") or
    Grid::Request::Test->diagnose();
is(scalar(@ids), 1, "Got a single id from submit_serially().");

if (scalar(@ids)) {
    wait_for_out($output);

    ok(-f $output, "Output file was created and copied to local area.") or
        diag ("Perhaps NFS caching issues are making it look like the file isn't there. " .
              "Check if $output is there manually.");
    my $result = "";
    eval {
        open(FILE, "<", $output);
        $result = <FILE>;
        close FILE;
        chomp($result);
    };

    like($result, qr/x86_64/, "Job ran on the correct architecture.");
} else {
    fail("No output file created.");
    fail("Job did not run.");
}

cleanup();

############################################################################

sub cleanup {
    eval {
        unlink $output;
    };
}

sub wait_for_out {
    my $output = shift;
    my $n=1;
    while (($n < 10 ) && (! -e $output)) {
        last if (-e $output);
        sleep $n*6;
        $n++;
    }
}
