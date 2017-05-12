
# We need at least Perl 5.8.1 for proper Unicode support
require 5.8.1;
use strict;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# The name of your distribution
name		'Mediawiki-POD';

# Get most of the details from the primary module
all_from	'lib/Mediawiki/POD.pm';
abstract	'Convert POD to HTML inside Mediawiki';

requires	'Graph::Easy'		=> 0.55;
requires	'Scalar::Util'		=> 1.13;
requires	'perl'			=> 5.008001;
requires	'Pod::Simple'		=> 3.04;
requires	'Pod::Simple::HTML'	=> 3.03;

build_requires	'Test::More'		=> 0.62;

license		'gpl';

author		'Tels <nospam-abuse@bloodgate.com>';

# Generate the Makefile
WriteAll;
