# We don't support ancient Perls anymore
require 5.006;
use strict;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# The name of your distribution
name            'Devel-Size-Report';

# Get most of the details from the primary module
all_from        'lib/Devel/Size/Report.pm';

requires	'Devel::Size'	=> 0.69;
requires        'Scalar::Util'  => 1.13;
requires	'Time::HiRes'	=> 1.86;
requires	'Array::RefElem'=> 1.00;
requires	'Devel::Peek'	=> 1.00;
requires        'perl'          => 5.006;

build_requires  'Test::More'    => 0.62;

license         'perl';		# from v5.8.8

author          'Tels <nospam-abuse@bloodgate.com>';

# Do not index these
no_index        directory       => 'example';

# Generate the Makefile
WriteAll;

