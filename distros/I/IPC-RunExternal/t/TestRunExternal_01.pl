#!/usr/bin/perl

# This program is a test executable to be run by IPC::RunExternal::runexternal()
# when testing the function. We need this for testing the timeouts.

use 5.004;
use strict;
use warnings;
use utf8;

my $TRUE = 1;
my $FALSE = 0;
my $EMPTY_STR = q{};
my $NO_TIMEOUT = 0;
my $BASE_YEAR = 1900;

use lib qw{lib};
use IPC::RunExternal;

if(defined $ARGV[0] && $ARGV[0] eq 'loop') {
    my $i = 0;
    my $rounds = $ARGV[1];
    my $run_simple;
    if(defined $ARGV[2] && $ARGV[2] eq 'simple') {
        $run_simple = 1;
    }
    if(!$run_simple) {
        print STDOUT "This program is part of IPC::RunExternal package test suite.\n";
    }
    if(!$run_simple) {
        print STDOUT "Going to run for $rounds secs. Printing to STDOUT and STDERR.\n";
    }
    while($i < $rounds) {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime time;
        my $timestamp = sprintf '%4d-%02d-%02d %02d:%02d:%02d', $year+$BASE_YEAR,$mon+1,$mday,$hour,$min,$sec;
        if(($rounds - $i) % 2 == 0) {
            if(!$run_simple) {
                print STDOUT 'to STDOUT: ' . ($rounds - $i) . ' secs left. ' . $timestamp . "\n";
            }
            else {
                print STDOUT 'STDOUT:' . ($rounds - $i) . "\n";
            }
        }
        else {
            if(!$run_simple) {
                print STDERR 'to STDERR: ' . ($rounds - $i) . ' secs left. ' . $timestamp . "\n";
            }
            else {
                print STDERR 'STDERR:' . ($rounds - $i) . "\n";
            }
        }
        sleep(1);
        $i++;
    }
    if(!$run_simple) {
        print STDOUT "Ending TestRunExternal_01.pl (normally).\n";
    }
}
elsif(defined $ARGV[0] && $ARGV[0] eq 'print') {
    print STDOUT "This program is part of IPC::RunExternal package test suite.\n";
    my $print_out = $ARGV[1];
    print STDOUT 'to STDOUT: ' . $print_out . "\n";
    print STDERR 'to STDERR: ' . $print_out . "\n";
}
elsif(defined $ARGV[0] && $ARGV[0] eq 'myself') {
    my $rounds = $ARGV[1];
    my $run_simple;
    if(defined $ARGV[2] && $ARGV[2] eq 'simple') {
        $run_simple = 1;
    }
    if(!$run_simple) {
        print STDOUT "This program is part of IPC::RunExternal package test suite.\n";
    }
    if(!$run_simple) {
        print STDOUT "Executing myself.\n";
    }

#    my $command = $EMPTY_STR;
#    my $input = $EMPTY_STR;
#    my $timeout = 3;
    my $exit_code = 0;
    my $stdout = $EMPTY_STR;
    my $stderr = $EMPTY_STR;
    my $allout = $EMPTY_STR;
    ($exit_code, $stdout, $stderr, $allout) = runexternal('t/TestRunExternal_01.pl loop 1', $EMPTY_STR, $NO_TIMEOUT,
            { print_progress_indicator => $TRUE,
                progress_indicator_char => '#'
            });
    print "\n";
    ($exit_code, $stdout, $stderr, $allout) = runexternal('t/TestRunExternal_01.pl loop 2', $EMPTY_STR, $NO_TIMEOUT,
            { print_progress_indicator => $TRUE,
                progress_indicator_char => '#'
            });
    print "\n";
    ($exit_code, $stdout, $stderr, $allout) = runexternal('t/TestRunExternal_01.pl loop 3', $EMPTY_STR, $NO_TIMEOUT,
            { print_progress_indicator => $TRUE,
                progress_indicator_char => '#'
            });
    print "\n";
    ($exit_code, $stdout, $stderr, $allout) = runexternal('t/TestRunExternal_01.pl loop 6', $EMPTY_STR, $NO_TIMEOUT,
            { print_progress_indicator => $TRUE,
                progress_indicator_char => q{#}
            });
    print "\n";
    ($exit_code, $stdout, $stderr, $allout) = runexternal('t/TestRunExternal_01.pl loop 6', $EMPTY_STR, 1,
            { print_progress_indicator => $TRUE,
                progress_indicator_char => q{#}
            });
    print "\n";
    ($exit_code, $stdout, $stderr, $allout) = runexternal('t/TestRunExternal_01.pl loop 6', $EMPTY_STR, 2,
            { print_progress_indicator => $TRUE,
                progress_indicator_char => q{#}
            });
    print "\n";

}

exit;

