
use strict;
use warnings;

use inc::Module::Install;

name            'Device-MegaSquirt';
all_from        'lib/Device/MegaSquirt.pm';
requires        'Device::SerialPort' => 1.00;
requires        'Text::LookUpTable' => 0.05;
test_requires   'Test::More' => 0;

resources (
    'repository'    => 'http://github.com/jmahler/libdevice-megasquirt-perl',
    'homepage'      => 'http://search.cpan.org/dist/Device-Megasquirt/',
);

WriteAll;

