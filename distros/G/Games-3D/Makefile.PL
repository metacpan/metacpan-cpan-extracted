require 5.8.1;
use strict;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# The name of your distribution
name		'Games-3D';

# Get most of the details from the primary module
all_from	'lib/Games/3D.pm';

build_requires	'Test::More'	=> 0.42;

license		'gpl';		# v2.0 only 

author		'Tels <nospam-abuse@bloodgate.com>';

# Generate the Makefile
WriteAll;
