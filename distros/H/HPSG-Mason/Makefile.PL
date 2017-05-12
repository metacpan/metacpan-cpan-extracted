use inc::Module::Install;
use strict;
use warnings;

# Define metadata
name 'HPSG-Mason';
all_from 'lib/HPSG/Mason.pm';

# Specific dependencies
requires 'HTML::Mason'     => '1.39';
requires 'File::ShareDir'  => '1.0';
test_requires 'Test::More' => '0.42';
install_share 'share';
sign;

WriteAll;
