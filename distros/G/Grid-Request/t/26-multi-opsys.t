#!/usr/bin/perl

# $Id: 26-multi-opsys.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use File::Basename;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Log::Log4perl qw(:easy);
use Test::More tests => 6;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");
my $project = Grid::Request::Test->get_test_project();

my $base = basename($0);
my $output = "/usr/local/scratch/${base}.out";
my $opsys = "Linux,Solaris";

cleanup();
ok(! -e $output, "Output file does not exist.");

my $htc = Grid::Request->new(project => $project);
$htc->command("/bin/uname");
$htc->output($output);
$htc->opsys($opsys);

is($htc->output(), $output, "output() got same value that was set.");
is($htc->opsys(), $opsys, "opsys() got same value that was set.");
# Submit the job
my @ids = $htc->submit_serially();
is(scalar(@ids), 1, "Got a single id from submit_serially().");

wait_for_out($output);

ok(-f $output, "Output file was created.");

my $result = "";
eval {
    open(FILE, "<", $output) or die "Could not open the output file $output.";
    $result = <FILE>;
    close FILE;
    chomp($result);
};

ok($result =~ m/^(SunOS|Linux)$/, "Job ran on a correct operating system.");

cleanup();

#############################################################################

sub cleanup {
    eval { unlink $output; };
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
