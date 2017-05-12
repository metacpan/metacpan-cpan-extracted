use inc::Module::Install;
name 'Device-VFD-GP1022';
all_from 'lib/Device/VFD/GP1022.pm';

requires $_ for (qw/ Encode /);

if ($^O =~ /win/i && $^O !~ /darwin/) {
    requires 'Win32::SerialPort';
} else {
    requires 'Device::SerialPort';
}


build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
