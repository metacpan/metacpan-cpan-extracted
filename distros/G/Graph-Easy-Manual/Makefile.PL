
# We need at least Perl 5.8.1 for proper Unicode support
require 5.008001;
use strict;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# The name of your distribution
name		'Graph-Easy-Manual';

# Get most of the details from the primary module
all_from	'lib/Graph/Easy/Manual.pm';

requires	'Graph::Easy'	=> 0.63,
		'File::Spec'	=> 3.01,
		'Pod::Simple'	=> 3.04;

recommends	'Graph::Easy::As_svg'	=> 0.22;

build_requires	'Test::More'	=> 0.62;

license		'gpl';

author		'Tels <nospam-abuse@bloodgate.com>';

# Do not index these
no_index	directory	=> 'examples';

# Auto-install all dependencies from CPAN
auto_install;

# Generate the Makefile
WriteAll;
