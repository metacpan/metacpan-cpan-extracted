#!/usr/bin/perl -w

# vim: set filetype=perl :

use strict;

use Test;

BEGIN { plan tests => 4 };

use Mac::AppleScript::Glue;

##;;$Mac::AppleScript::Glue::Debug{SCRIPT} = 1;
##;;$Mac::AppleScript::Glue::Debug{RESULT} = 1;

######################################################################

my $finder = new Mac::AppleScript::Glue::Application('Finder');

ok(defined $finder)
    or die "can't initialize application object (Finder)\n";

######################################################################

my $version = $finder->version;

ok($version)
    or die "can't find version\n";

######################################################################

my $disks = $finder->disks;

ok($disks)
    or die "can't find disks\n";

for my $disk (ref($disks) eq 'ARRAY' ? @{$disks} : $disks) {
    my $name = $disk->name;
    my $free = int($disk->free_space / 1024 / 1024);

    print "disk \"$name\" has ${free} mb free\n";
}

ok(1);
