use inc::Module::Install;

name 'Device-WWN';
all_from 'lib/Device/WWN.pm';

requires( $_ ) for qw(
    Moose Carp::Clan::Share Device::OUI Module::Find Sub::Exporter
);
test_requires( $_ ) for qw(
    Test::More Test::Most ok
);

extra_tests();
WriteAll();
