use inc::Module::Install;

name 'Device-MAC';
all_from 'lib/Device/MAC.pm';

requires( $_ ) for qw(
    Moose Device::OUI Carp Sub::Exporter
);
test_requires( $_ ) for qw(
    Test::Most ok
);

extra_tests();
WriteAll();
