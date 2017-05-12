# We need at least Perl 5.8.1 for proper Unicode support
require 5.008001;
use strict;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Get most of the details from the primary module
all_from	'lib/Graph/Regexp.pm';

requires	'Scalar::Util'		=> 1.13,
		'Graph::Easy'		=> 0.62;

build_requires  'Test::More'		=> 0.62,
		'Test::Differences'	=> 0.47;

license		'gpl';

author		'Tels <nospam-abuse@bloodgate.com>';

# Do not index these
no_index	directory	=>	'examples';

# Auto-install all dependencies from CPAN
auto_install;

# Generate the Makefile
WriteAll;
