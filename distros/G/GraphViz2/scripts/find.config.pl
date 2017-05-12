#!/usr/bin/env perl

use strict;
use warnings;

use File::HomeDir;
use File::Spec;

# --------------

my($module)      = 'GraphViz2';
my($module_dir)  = $module;
$module_dir      =~ s/::/-/g;
my($config_name) = '.htgraphviz2.conf';
my($path)        = File::Spec -> catfile(File::HomeDir -> my_dist_config($module_dir), $config_name);

print "Using: File::HomeDir -> my_dist_config('$module_dir', '$config_name'): \n";
print "Found: $path\n";
