# We need at least Perl 5.8.1 for proper Unicode support
require 5.008001;
use strict;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# The name of your distribution
name		'Devel-Graph';

# Get most of the details from the primary module
all_from	'lib/Devel/Graph.pm';

requires	'Scalar::Util'		=> '1.19',
		'PPI'			=> '1.201',
		'Graph::Flowchart'	=> '0.10',
		'Graph::Easy'		=> '0.60',
		'perl'			=> '5.008001';

test_requires	'Test::More'		=> '0.62',
		'Test::Differences'	=> '0.47';

license		'gpl';

author		'Tels <nospam-abuse@bloodgate.com>';

# Do not index these
no_index	directory	=>	'examples';

# Auto-install all dependencies from CPAN
auto_install;

# Generate the Makefile
WriteAll;
