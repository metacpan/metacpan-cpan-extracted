#!/usr/bin/perl


use strict;
use ExtUtils::Installed;

# $Id$
# Simple script to give details of Lyrics::Fetcher and fetcher modules
# installed, to provide useful information when reporting bugs.


my $report;

$report .= "Installed Lyrics::Fetcher::* modules "
    . "(according to ExtUtils::Installed):\n";
my $installed = ExtUtils::Installed->new();
foreach my $module (grep(/^Lyrics::Fetcher/, $installed->modules())) {
    my $version = $installed->version($module) || "???";
    $report .= " * $module version $version\n";
}





print $report;