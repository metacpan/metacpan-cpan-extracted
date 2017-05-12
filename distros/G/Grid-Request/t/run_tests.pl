#!/usr/bin/perl

use strict;
use File::Find;
use FindBin qw($Bin);
use Getopt::Long;
use Test::Harness;

use vars qw($VERSION);
$VERSION = qw$Revision$[1];

my %opt;
GetOptions(\%opt, "debug", "help", "verbose", "version", "inst=s");

usage() if $opt{help};
version() if $opt{version};

my $inst = ( defined $opt{inst} ) ? $opt{inst} : "dev";
if (($inst ne "dev") && ($inst ne "prod")) {
    usage();
}

# Handle the verbose/debug parameters.
my $verbose = ( $opt{debug} || $opt{verbose} ) ? 1 : 0;
$Test::Harness::verbose = $verbose;

my @test_scripts = ();
find(\&wanted, $Bin);

runtests(sort @test_scripts);

exit;

#############################################################################

sub wanted {
    return unless ($_ =~ m/.+\.t$/);
    my $name = $File::Find::name;
    $name =~ s/^$Bin\///;
    push @test_scripts, $name;
}

sub version {
    print "$VERSION\n\n";
    exit;
}

sub usage {
    my $usage = <<"    _USAGE";

    $0

    This script is a test harness for all the tests included in this
    directory. It will automatically run any executable file having the
    .t perl testing suffix. To see verbose information as the tests are run,
    be sure to pass the --verbose or --debug parameters.

    --help              Print this help message.

    --debug|verbose     Run the tests in verbose mode.
                        Information on individual tests and results
                        will be displayed.

    --version           Print version information

    _USAGE

    print "$usage\n\n";
    exit;
}
