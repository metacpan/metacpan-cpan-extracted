#!/usr/bin/perl

# Script to check that the output of show_invocations() is escaped for the shell.

# $Id$

use Digest::MD5; # This is  a core Perl module.
use FindBin qw($Bin);
use File::Basename;
use File::Path;
use File::Temp qw/ tempfile /;
use IO::Capture::Stdout;
use Test::More tests => 2;
use lib ("$Bin/../lib");
use Grid::Request;
use Grid::Request::Test;

my $project = Grid::Request::Test->get_test_project();

my $file = "$Bin/test_data/entries_with_whitespace.txt";

single_cmd_escaping();
multi_cmd_escaping();

#############################################################################

# Now compare this to the data in our test file by 
# checksumming the files.
sub get_md5 {
    my $file = shift;
    open (FH, "<", $file) or die "Unable to open $file for reading.";
    my $ctx = Digest::MD5->new();
    $ctx->addfile(*FH);
    $digest = $ctx->digest();
    close FH or die "Unable to close filehandle: $!";
    return $digest;
}

sub single_cmd_escaping {
    my $req = Grid::Request::Test::get_test_request();
    $req->command("/bin/echo");
    $req->add_param('$(Name)', $file, "FILE");

    $capture = IO::Capture::Stdout->new();
    $capture->start();          # STDOUT Output captured
    $req->show_invocations();
    $capture->stop();  

    # Gather all the lines that were captured into an array.
    my @all_lines = $capture->read();
    # Strip the 1st line, because it's the command header.
    @all_lines = @all_lines[1 .. scalar(@all_lines) - 1];

    # Create a temporary file where we can save the output
    # of our shell invocation.
    my ($fh, $filename) = tempfile();

    # Make the shell run the commands we've just extracted
    open (BASH, "|/bin/bash > $filename");
    print BASH @all_lines;
    close BASH;

    my $gold_md5 = get_md5($file);
    my $test_md5 = get_md5($filename);

    is($gold_md5, $test_md5, "Escaping correct for single command requests.");
}

sub multi_cmd_escaping {
    my $req = Grid::Request::Test::get_test_request();
    $req->command("/bin/echo");
    $req->add_param('$(Name)', $file, "FILE");

    $req->new_command();
    $req->command("/bin/echo");
    $req->add_param('$(Name)', $file, "FILE");

    $capture = IO::Capture::Stdout->new();
    $capture->start();          # STDOUT Output captured
    $req->show_invocations();
    $capture->stop();  

    # Gather all the lines that were captured into an array.
    my @all_lines = $capture->read();
    # Strip out header lines
    @all_lines = grep { $_ !~ m/Command #/} @all_lines;

    # Create a temporary file where we can save the output
    # of our shell invocation.
    my ($fh, $bash_output) = tempfile();
    my ($fh2, $concat_file) = tempfile();
    system("cat $file $file > $concat_file");

    # Make the shell run the commands we've just extracted
    open (BASH, "|/bin/bash > $bash_output");
    print BASH @all_lines;
    close BASH;

    my $gold_md5 = get_md5($concat_file);
    my $test_md5 = get_md5($bash_output);

    is($gold_md5, $test_md5, "Escaping correct for multi-cmd requests.");
}
