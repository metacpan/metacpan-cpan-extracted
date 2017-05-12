#!/usr/bin/perl

# $Id: 07-single-opsys.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use File::Basename;
use Log::Log4perl;
use Test::More tests => 6;
use Grid::Request;
use Grid::Request::Test;

my $project = Grid::Request::Test->get_test_project();


Log::Log4perl->init("$Bin/testlogger.conf");

my $name = basename($0);
my $output = "/usr/local/scratch/${name}.out";
my $opsys = "Opteron";

cleanup();
ok(! -e $output, "Output file does not exist.");

my $htc = Grid::Request->new(project => $project);
$htc->command("/bin/uname");
$htc->add_param("-a");
$htc->output($output);
$htc->opsys($opsys);

is($htc->output(), $output, "output() got same value that was set.");
is($htc->opsys(), $opsys, "opsys() got same value that was set.");
# Submit the job
my @ids = $htc->submit_serially();
is(scalar(@ids), 1, "Got a single id.");

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
cleanup();

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
