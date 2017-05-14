#!/usr/bin/perl

# Test if the API supports specifying the specific host/hosts to run
# the command on.

# $Id: 17-hosts.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use File::Which;
use File::Basename;
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");

my $req = Grid::Request::Test->get_test_request();

my $host;
eval {
    # Suppress STDERR while we check that the test host is defined.
    open OLDERR, ">&STDERR";
    open STDERR, ">/dev/null";
    $host = Grid::Request::Test->get_test_host();
    open(STDERR, ">", &OLDERR); 
};

# Get the configured temporary directory
my $tempdir = $req->_config()->val($Grid::Request::HTC::config_section, "tempdir");

if (! defined $tempdir || ! -d $tempdir) {
    plan skip_all => 'tempdir not configured or not a directory.';
} elsif (! defined $host) {
    plan skip_all => "No test host configured. Please define the \"$Grid::Request::Test::GR_HOST_NAME\" environment variable.";
} else {
    plan tests => 4;
}

my $name = basename($0);

my $output = "$tempdir/${name}.out";

cleanup();

$req->command(which("hostname"));
$req->output($output);
$req->hosts($host);

my @ids;
eval {
    @ids = $req->submit_and_wait();
};
ok(! $@, "No exceptions when job submitted.") or
    Grid::Request::Test->diagnose();

is(scalar(@ids), 1, "Got 1 id from submit_and_wait().");

wait_for_out($output);

ok(-f $output, "Output file created.") or
   diag("Might not be visible due to NFS caching issues.");

my $line = read_first_line($output);
chomp($line);
ok($line =~ m/^$host/, "Job ran on the correct host: $host.");

cleanup();

#############################################################################

sub cleanup {
    eval {
        unlink $output;
    };
}

sub read_first_line {
    my $file = shift;
    my $line;
    eval {
        open (FILE, "<", $file) or die "Couldn't open $file for reading.";
        $line = <FILE>;
        close FILE;
    };
    chomp($line) if defined($line);
    return $line;
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
