# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Name of your distribution
name            ('HTML-Menu-Select');

# Get most of the details from the primary module
all_from        ('lib/HTML/Menu/Select.pm');

# Modules that this distribution depend on
requires        ('Carp');

# Modules needed for building and testing
build_requires  ('Test::More' => '0.42');

# Auto-installs all dependencies from CPAN.
# You want to use this most of the time, especially
# if you use the 'recommend' or 'feature' commands
auto_install();

# Generate the Makefile
WriteAll();
