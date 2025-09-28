#!/usr/bin/env perl

use strict;
use warnings;

use MARC::Validator;

my @plugins = MARC::Validator->plugins;

if (@plugins) {
        print "List of plugins:\n";
        foreach my $plugin (@plugins) {
                print "- $plugin\n";
        }
} else {
        print "No plugins.\n";
}

# Output like:
# List of plugins:
# - MARC::Validator::Plugin::Field008
# - MARC::Validator::Plugin::Field020
# - MARC::Validator::Plugin::Field260
# - MARC::Validator::Plugin::Field264