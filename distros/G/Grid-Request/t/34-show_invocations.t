#!/usr/bin/perl

# This test script is used to verify the behavior of the show_invocations()
# method.
#
# $Id$

use Digest::MD5;
use FindBin qw($Bin);
use File::Basename;
use File::Path;
use File::Which;
use File::Temp qw/ tempfile /;
use IO::Capture::Stdout;
use Test::More tests => 17;
use lib ("$Bin/../lib");
use Grid::Request;
use Grid::Request::Test;

my $file = "$Bin/test_data/test_file.txt";
my $echo = which("echo");

single_command();
multi_command();
index_replacement();
multi_cmd_index_replacement();

#############################################################################

sub single_command {
    my $req = Grid::Request::Test::get_test_request();
    $req->command($echo);
    $req->add_param('$(Name)', $file, "FILE");

    $capture = IO::Capture::Stdout->new();
    $capture->start();          # STDOUT captured
    $req->show_invocations();
    $capture->stop();  

    my @lines = $capture->read();
    is(scalar @lines, 101, "Correct number of output lines for singular command."); # includes header

    # Take the headers off
    my @job_lines = grep { $_ !~ m/Command #/ } @lines;

    # Quick check on the number of invocations
    is(scalar @job_lines, 100, "Correct number of job invocations for a singular command.");

    # Check the headers themselves
    my @headers = grep { $_ =~ m/Command #/ } @lines;
    is(scalar @headers, 1, "Correct number of headers given for a singular command.");
}

sub multi_command {
    my $req = Grid::Request::Test::get_test_request();
    $req->command($echo);
    $req->add_param('$(Name)', $file, "FILE");

    # Add a second command to execute
    $req->new_command();
    $req->command($echo);
    $req->add_param('$(Name)', $file, "FILE");

    $capture = IO::Capture::Stdout->new();
    $capture->start();          # STDOUT captured
    $req->show_invocations();
    $capture->stop();  

    my @lines = $capture->read();
    # Take the headers off
    my @job_lines = grep { $_ !~ m/Command #/ } @lines;

    # Quick check on the number of invocations
    is(scalar @job_lines, 200, "Correct number of job invocations for a multi-command.");

    # Check the headers themselves
    my @headers = grep { $_ =~ m/Command #/ } @lines;
    is(scalar @headers, 2, "Correct number of headers for a multi-command.");
}

sub index_replacement {
    my $req = Grid::Request::Test::get_test_request();
    my $blocksize = 50;
    $req->command($echo);
    $req->block_size(50);
    $req->add_param('$(Index)', $file, "FILE");

    $capture = IO::Capture::Stdout->new();
    $capture->start();          # STDOUT captured
    $req->show_invocations();
    $capture->stop();  

    # Gather the output that was produced
    my @lines = $capture->read();
    # Take the headers off
    @lines = grep { $_ !~ m/Command #/ } @lines;
    # Take the newlines off
    @lines = map { chomp; $_ } @lines;

    # Quick check on the number of invocations
    is(scalar @lines, 100, "Correct number of job invocations with index replacement.");

    my @cli = split(/\ /, $lines[$blocksize - 1]);
    is($cli[1], 1, "Correct index for last iteration over the 1st block.");

    @cli = split(/\ /, $lines[$blocksize]);
    is($cli[1], 2, "Correct index for 1st iteration of 2nd block.");
}

sub multi_cmd_index_replacement {
    my $req = Grid::Request::Test::get_test_request();
    my $blocksize = 50;
    $req->command($echo);
    $req->block_size($blocksize);
    $req->add_param('$(Index)', $file, "FILE");

    $req->new_command();
    $req->command($echo);
    $req->block_size($blocksize);
    $req->add_param('$(Index)', $file, "FILE");

    $capture = IO::Capture::Stdout->new();
    $capture->start();          # STDOUT captured
    $req->show_invocations();
    $capture->stop();  

    # Gather the output that was produced
    my @lines = $capture->read();
    # Take the headers off
    @lines = grep { $_ !~ m/Command #/ } @lines;
    # Take the newlines off
    @lines = map { chomp; $_ } @lines;

    # Quick check on the number of invocations
    is(scalar @lines, 200, "Correct number of job invocations.");

    # Get the arguments for the first invocation in the first block
    # of the first command
    my @cli = split(/\ /, $lines[0]);
    is($cli[1], 1, "Correct index for 1st invocation, 1st block, 1st command.");

    # Get the arguments for the last invocation in the first block
    # of the first command
    @cli = split(/\ /, $lines[$blocksize - 1]);
    is($cli[1], 1, "Correct index for last invocation, 1st block, 1st command.");

    # Get the arguments for the 1st invocation in the 2nd block
    # of the first command
    @cli = split(/\ /, $lines[$blocksize]);
    is($cli[1], 2, "Correct index for 1st invocation, 2nd block, 1st command.");

    # Get the arguments for the last invocation in the 2nd block
    # of the first command
    @cli = split(/\ /, $lines[99]);
    is($cli[1], 2, "Correct index for last invocation, 2nd block, 1st command.");

    # Get the arguments for the first invocation in the first block
    # of the 2nd command
    @cli = split(/\ /, $lines[100]);
    is($cli[1], 1, "Correct index for 1st invocation, 1st block, 2nd command.");

    # Get the arguments for the last invocation in the first block
    # of the 2nd command
    @cli = split(/\ /, $lines[149]);
    is($cli[1], 1, "Correct index for last invocation, 1st block, 2nd command.");

    # Get the arguments for the first invocation in the 2nd block
    # of the 2nd command
    @cli = split(/\ /, $lines[150]);
    is($cli[1], 2, "Correct index for 1st invocation, 2nd block, 2nd command.");

    # Get the arguments for the last invocation in the 2nd block
    # of the 2nd command
    @cli = split(/\ /, $lines[199]);
    is($cli[1], 2, "Correct index for last invocation, 2nd block, 2nd command.");
}
