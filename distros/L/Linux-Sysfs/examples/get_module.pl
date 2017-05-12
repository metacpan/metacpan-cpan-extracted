#!/usr/bin/perl

use strict;
use warnings;
use Linux::Sysfs;

if (scalar @ARGV != 1) {
    print_usage();
    exit 1;
}

my $module = Linux::Sysfs::Module->open($ARGV[0]);
unless ($module) {
    print "Module \"$ARGV[0]\" not found\n";
    exit 1;
}

for my $attr ($module->get_attributes) {
    printf "\t%-20s : %s",
           $attr->name, $attr->value;
}
print "\n";

if (my @parms = $module->get_parms) {
    print "Parameters:\n";
    for my $parm (@parms) {
        printf "\t%-20s : %s",
               $parm->name, $parm->value;
    }
}

if (my @sections = $module->get_sections) {
    print "Sections:\n";
    for my $section (@sections) {
        printf "\t%-20s : %s",
               $section->name, $section->value;
    }
}

$module->close;

sub print_usage {
    print "Usage: $0 [name]\n";
}
