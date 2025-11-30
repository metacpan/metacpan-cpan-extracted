#!/usr/bin/env perl
use 5.018;
use lib 'lib';
use strict;
use warnings;
use version;
use Test::More;

plan tests => 17;

BEGIN {
    my @modules = qw(
        Disk::SmartTools
    );

    foreach my $module (@modules) {
        use_ok($module) || print "Bail out!\n";

        my $var        = '$' . $module . '::VERSION';
        my $module_ver = eval "$var" or 0;
        my $ver        = version->parse("$module_ver")->numify;
        cmp_ok( $ver, '>', 0, "Version $ver > 0 in $module" );
    }

    # Modules used by above
    my @needed_modules = qw(
        Dev::Util
        Carp
        Data::Dumper::Simple
        Data::Printer
        English
        Exporter
        FindBin
        Getopt::Long
        IPC::Cmd
        Readonly
        Term::ANSIColor
        Term::ReadKey
    );

    foreach my $module (@needed_modules) {
        use_ok($module) || print "Bail out!\n";
    }

    # Moudules used for testing
    my @testing_modules = qw(
        ExtUtils::Manifest
        Test2
        Test::More
    );

    foreach my $module (@testing_modules) {
        use_ok($module) || print "Bail out!\n";
    }
}

my $module_version
    = version->parse(qq($Disk::SmartTools::VERSION))->stringify;
diag("Testing Disk::SmartTools $module_version");
diag("Perl $PERL_VERSION, $EXECUTABLE_NAME");

