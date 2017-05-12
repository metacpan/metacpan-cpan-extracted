
require 5.8.1;
use strict;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# The name of your distribution
name		'Dev-Bollocks';

# Get most of the details from the primary module
all_from	'lib/Dev/Bollocks.pm';

requires	'Math::String'	=> 1.27;
requires	'Math::BigInt'	=> 1.77;

build_requires	'Test::More'	=> 0.42;

license		'perl';

author		'Tels <nospam-abuse@bloodgate.com>';

# Generate the Makefile
WriteAll;
