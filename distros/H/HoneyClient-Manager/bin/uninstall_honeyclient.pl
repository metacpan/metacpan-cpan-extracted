#!/usr/bin/perl -w

# $Id: uninstall_honeyclient.pl 783 2007-07-30 17:43:19Z kindlund $

use strict;
use warnings;
use IO::Dir;
use ExtUtils::Packlist;
use ExtUtils::Installed;
use ExtUtils::MakeMaker qw(prompt);

our $PACKAGE_NAME = "HoneyClient";

sub emptydir($) {
    my ($dir) = @_;
    my $dh = IO::Dir->new($dir) || return(0);
    my @count = $dh->read();
    $dh->close();
    return(@count == 2 ? 1 : 0);
}

# Find all the installed instances.
print "Finding all installed " . $PACKAGE_NAME . " packages...\n";
my $installed = ExtUtils::Installed->new();
my @module_list = grep(/^$PACKAGE_NAME.*/, $installed->modules());

if (scalar(@module_list) <= 0) {
    print "No " . $PACKAGE_NAME . " packages found.\n";
    exit;
}

foreach my $module (@module_list) {
    my $version = $installed->version($module) || "?.?";
    print "\nFound package: " . $module . " v" . $version . "\n";
    my $question = prompt("Do you want to uninstall " . $module . "?", "no");
    if ($question && $question =~ /^y.*/i) {
        # Remove all the files
        foreach my $file (sort($installed->files($module))) {
            print "rm $file\n";
            unlink($file);
        }
        my $pf = $installed->packlist($module)->packlist_file();
        print "rm $pf\n";
        unlink($pf);
        foreach my $dir (sort($installed->directory_tree($module))) {
            if (emptydir($dir)) {
                print "rmdir $dir\n";
                rmdir($dir);
            }
        }
    }
}

print "\nFinished.\n";
