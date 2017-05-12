#!/usr/bin/env perl

use strict;
use warnings;

use File::Copy;
use File::HomeDir;

use Path::Tiny; # For path().

# ----------------------------------------

my($module)           = 'GraphViz2::Marpa';
my($module_dir)       = $module;
$module_dir           =~ s/::/-/g;
my($dir_name)         = File::HomeDir -> my_dist_config($module_dir, {create => 1});
my($config_name)      = '.htgraphviz2.marpa.conf';
my($source_file_name) = path('config', $config_name);

if ($dir_name)
{
	File::Copy::copy($source_file_name, $dir_name);

	my($dest_file_name) = path($dir_name, $config_name);

	if (-e $dest_file_name)
	{
		print "Copied $source_file_name to $dir_name\n";
	}
	else
	{
		die "Unable to copy $source_file_name to $dir_name\n";
	}
}
else
{
	print "Unable to create directory using File::HomeDir -> my_dist_config('$module_dir', {create => 1})\n";
	die "for use by File::Copy::copy($source_file_name, \$dir_name)\n";
}
