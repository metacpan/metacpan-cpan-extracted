#!/usr/bin/perl

# $Id$

use strict;
use FindBin qw($Bin);
use File::Basename;
use File::Path;
use lib ("$Bin/../lib");
use Test::More tests => 7;
use Grid::Request::Test;
use_ok("Grid::Request::JobFormulator");

my $blocksize = 100;
my $formulator = Grid::Request::JobFormulator->new();

can_ok($formulator, ("formulate"));

test_dir();
test_file();
test_param_dir();
test_param_file();
test_limiting_files();

sub test_dir {
    my $dir = "$Bin/test_data/test_dir";

    my $executable = "/bin/echo";
    my $dir_param = Grid::Request::Param->new('DIR:' . $dir . ':$(Name)');

    my $dir_param_str = $dir_param->to_string();

    my @invocations = $formulator->formulate($blocksize, $executable, ( $dir_param_str ));

    is(scalar @invocations, 100, "Correct number of jobs for a dir param.");
}

sub test_file {
    my $file = "$Bin/test_data/test_file.txt";

    my $executable = "/bin/echo";
    my $file_param = Grid::Request::Param->new('FILE:' . $file . ':$(Name)');

    my $file_param_str = $file_param->to_string();

    my @invocations = $formulator->formulate($blocksize, $executable, ( $file_param_str ));
    #foreach my $inv (@invocations) { print join(" ", @$inv) . "\n"; }

    is(scalar @invocations, 100, "Correct number of jobs for a file param.");
}

sub test_param_dir {
    my $dir = "$Bin/test_data/test_dir";

    my $executable = "/bin/echo";
    my $regular_param = Grid::Request::Param->new('PARAM:regular');
    my $dir_param = Grid::Request::Param->new('DIR:' . $dir . ':$(Name)');

    my $dir_param_str = $dir_param->to_string();
    my $regular_param_str = $regular_param->to_string();

    my @invocations = $formulator->formulate($blocksize, $executable, ( $regular_param_str, $dir_param_str ));
    #foreach my $inv (@invocations) { print join(" ", @$inv) . "\n"; }

    is(scalar @invocations, 100, "Correct number of jobs for a dir param w/ regular param.");
}

sub test_param_file {
    my $file = "$Bin/test_data/test_file.txt";

    my $executable = "/bin/echo";
    my $regular_param = Grid::Request::Param->new('PARAM:regular');
    my $file_param = Grid::Request::Param->new('FILE:' . $file . ':$(Name)');

    my $file_param_str = $file_param->to_string();
    my $regular_param_str = $regular_param->to_string();

    my @invocations = $formulator->formulate($blocksize, $executable, ( $regular_param_str, $file_param_str ));
    #foreach my $inv (@invocations) { print join(" ", @$inv) . "\n"; }

    is(scalar @invocations, 100, "Correct number of jobs for a file param with regular param.");
}

# This test examines the ability to deal with varying array sizes. We accomplish this by
# specifyng two files, with varying sizes.
sub test_limiting_files {
    my $executable = "/bin/echo";
    my $test_file = "$Bin/test_data/test_file.txt";
    my $smaller_test_file = "$Bin/test_data/smaller_test_file.txt";

    my $smaller_file_param = Grid::Request::Param->new('FILE:' . $smaller_test_file . ':$(Name)');
    my $regular_param = Grid::Request::Param->new('PARAM:regular');
    my $file_param = Grid::Request::Param->new('FILE:' . $test_file . ':$(Name)');

    my $smaller_param_str = $smaller_file_param->to_string();
    my $regular_param_str = $regular_param->to_string();
    my $file_param_str = $file_param->to_string();

    # Gather these param strings into an array for ease of legibility
    my @params = ($smaller_param_str, $regular_param_str, $file_param_str);

    my @invocations = $formulator->formulate($blocksize, $executable, @params);
    #foreach my $inv (@invocations) { print join(" ", @$inv) . "\n"; }

    diag("Number of invocations: " . scalar @invocations);
    ok(scalar @invocations < 100, "Invocation limitation seems to have worked.");
}
