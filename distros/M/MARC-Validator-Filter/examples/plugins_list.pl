#!/usr/bin/env perl

use strict;
use warnings;

use MARC::Validator::Filter;

my @plugins = MARC::Validator::Filter->plugins;

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
# - MARC::Validator::Filter::Plugin::AACR2
# - MARC::Validator::Filter::Plugin::Material
# - MARC::Validator::Filter::Plugin::RDA