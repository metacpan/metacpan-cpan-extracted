#!/usr/bin/perl
# -*- Mode: cperl; mode: folding; -*-

package TestRunner;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     TestRunner.pm
# Description:  Run test scripts
#
# Date          Change
# -----------------------------------------------------------------------------
# 08/02/2005    Auto generated file
# 08/02/2005    Needed to improve software quality
# 09/02/2005    Added a prompter to stop
# 11/02/2005    Need to run multiple tests in a cronjob arrangement
# 09/08/2005    Added a run method for integration with Goo 2
#
###############################################################################

use strict;

use Object;
use Prompter;
use TestMaker;
use PerlCoder;
use TestLoader;
use base qw(Object);


###############################################################################
#
# run_test - run a single test, interactively
#
###############################################################################

sub run_test {

    my ($this, $filename) = @_;

    my $test = TestLoader::load_test($filename);

    # run the test!!
    $test->do();

    # display the final result
    $test->show_results();

}


###############################################################################
#
# run_all_tests - run all the tests in a given directory
#
###############################################################################

sub run_all_tests {

    my ($directory) = @_;

    my $results = "";
    my $module_count;

    foreach my $filename (FileUtilities::get_file_list($directory . "/*.tpm")) {

        # strip any preceding directory
        $filename =~ s!^.*/!!;

        # print "Testing --- $filename\n";
        $module_count++;

        my $test = TestLoader::load_test($filename);

        # run the test!!
        $test->do();
        $results .= $test->get_results() . "\n";

    }

    # only show module level detail
    my @passes = grep { $_ =~ /passed:/ } split(/\n/, $results);
    my @fails  = grep { $_ =~ /failed:/ } split(/\n/, $results);

    my $pass_report = join("\n", @passes);
    my $fail_report = join("\n", @fails);

    return <<REPORT;
Passed Tests
------------
$pass_report


Failed Tests
------------
$fail_report

REPORT

}


###############################################################################
#
# run - run a test
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    my $filename  = $thing->get_filename();
    my $full_path = $thing->get_full_path();

    # Prompter::notify($thing->to_string());

    if ($filename =~ /\.tpm$/) {

        # this is a test file run it!
        $this->run_test($full_path);
        Prompter::notify("Completed test(s) for $filename. Press a key.");
        return;

    }

    # match parts of the path
    $full_path =~ /(.*)\/(.*)\.pm$/;

    my $test_filename  = $2 . "Test.tpm";
    my $test_full_path = $1 . "/test/" . $test_filename;

    # is there a test file already?
    unless (-e $test_full_path) {

        # Prompter::notify(" making this --- $full_path ");

        # make a new test
        my $maker = TestMaker->new();
        $maker->create_test_for_module($full_path);

        my $pc = PerlCoder->new({ filename => $full_path });
        $pc->add_change_log("Created test file: $test_filename");
        $pc->save();

    }

    # Prompter::notify("goo loader loading ... $test_filename ");

    # switch to this test
    my $test_thing = Goo::Loader::load($test_full_path);

    # show a profile of the test
    $test_thing->do_action("P");

}


1;



__END__

=head1 NAME

TestRunner - Run test scripts

=head1 SYNOPSIS

use TestRunner;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run_test

run a single test, interactively

=item run_all_tests

run all the tests in a given directory

=item run

run a test


=back

=head1 AUTHOR

Nigel Hamilton <nigel@turbo10.com>

=head1 SEE ALSO

