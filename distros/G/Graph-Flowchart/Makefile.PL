
# We need at least Perl 5.8.1 (for Graph::Easy & Unicode support)
require 5.008001;
use strict;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# The name of your distribution
name		'Graph-Flowchart';

# Get most of the details from the primary module
all_from	'lib/Graph/Flowchart.pm';

requires	'Graph::Easy'	=> 0.60,
		'perl'		=> 5.008001;

recommends	'Graph::Easy::Manual'	=> 0.40;
recommends	'Graph::Easy::As_svg'	=> 0.22;

build_requires	'Test::More'	=> 0.62;

license		'gpl';

author		'Tels <nospam-abuse@bloodgate.com>';

# Do not index these
no_index	directory	=>	'examples';

# Auto-install all dependencies from CPAN
auto_install;

# Generate the Makefile
WriteAll;

